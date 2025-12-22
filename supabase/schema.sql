-- ============================================================================
-- PROJECT NEO - SCHEMA SQL COMPLETO
-- Red Social SaaS Híbrida con Supabase (PostgreSQL)
-- Enfoque: Seguridad Financiera, Auditoría y Permisos Jerárquicos
-- ============================================================================

-- ============================================================================
-- EXTENSIONES REQUERIDAS
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- FUNCIÓN HELPER PARA GOD MODE (clearance_level = 99)
-- ============================================================================

-- Función para obtener el clearance_level del usuario actual desde JWT
CREATE OR REPLACE FUNCTION public.get_user_clearance_level()
RETURNS INT
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT COALESCE(
    (auth.jwt() -> 'user_metadata' ->> 'clearance_level')::INT,
    (SELECT clearance_level FROM public.security_profile WHERE user_id = auth.uid()),
    1 -- Default level
  );
$$;

-- Función para verificar si el usuario tiene GOD MODE activo
-- Nota: Si is_incognito = true, el Owner se ve como Nivel 1
CREATE OR REPLACE FUNCTION public.is_god_mode()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 
    FROM public.security_profile 
    WHERE user_id = auth.uid() 
      AND clearance_level = 99 
      AND is_incognito = FALSE
  );
$$;

-- Función para obtener el clearance_level visible (respeta incógnito)
CREATE OR REPLACE FUNCTION public.get_visible_clearance_level()
RETURNS INT
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT CASE
    WHEN (SELECT is_incognito FROM public.security_profile WHERE user_id = auth.uid()) = TRUE
    THEN 1
    ELSE COALESCE(
      (SELECT clearance_level FROM public.security_profile WHERE user_id = auth.uid()),
      1
    )
  END;
$$;

-- ============================================================================
-- 1. NÚCLEO DE USUARIOS & GOD MODE
-- ============================================================================

-- Tabla principal de usuarios globales
CREATE TABLE public.users_global (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) NOT NULL,
    avatar_global_url TEXT,
    display_name VARCHAR(100),
    bio TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    CONSTRAINT users_global_username_format CHECK (username ~ '^[a-zA-Z0-9_]{3,50}$'),
    CONSTRAINT users_global_email_format CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Índices para búsquedas frecuentes
CREATE INDEX idx_users_global_username ON public.users_global(username);
CREATE INDEX idx_users_global_email ON public.users_global(email);
CREATE INDEX idx_users_global_created_at ON public.users_global(created_at DESC);

-- Trigger para updated_at automático
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_users_global_updated_at
    BEFORE UPDATE ON public.users_global
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Perfil de seguridad con niveles de clearance jerárquicos
CREATE TABLE public.security_profile (
    user_id UUID PRIMARY KEY REFERENCES public.users_global(id) ON DELETE CASCADE,
    clearance_level INT DEFAULT 1 NOT NULL,
    is_incognito BOOLEAN DEFAULT FALSE NOT NULL,
    last_security_review TIMESTAMPTZ,
    two_factor_enabled BOOLEAN DEFAULT FALSE NOT NULL,
    security_questions_set BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- Nivel 99 = OWNER/GOD MODE
    -- Niveles intermedios para moderadores, admins, etc.
    CONSTRAINT security_profile_clearance_range CHECK (clearance_level >= 1 AND clearance_level <= 99)
);

COMMENT ON COLUMN public.security_profile.clearance_level IS 
    'Nivel de autorización: 1=Usuario normal, 50=Moderador, 75=Admin, 99=OWNER/GOD MODE';
COMMENT ON COLUMN public.security_profile.is_incognito IS 
    'Si TRUE, el Owner (99) aparece como usuario Nivel 1 para observación encubierta';

CREATE TRIGGER set_security_profile_updated_at
    BEFORE UPDATE ON public.security_profile
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Wallets para economía interna (NeoCoins)
CREATE TABLE public.wallets (
    user_id UUID PRIMARY KEY REFERENCES public.users_global(id) ON DELETE CASCADE,
    neocoins_balance DECIMAL(18, 8) DEFAULT 0.00000000 NOT NULL,
    is_vip BOOLEAN DEFAULT FALSE NOT NULL,
    vip_expiry TIMESTAMPTZ,
    total_earned DECIMAL(18, 8) DEFAULT 0.00000000 NOT NULL,
    total_spent DECIMAL(18, 8) DEFAULT 0.00000000 NOT NULL,
    last_transaction_at TIMESTAMPTZ,
    frozen BOOLEAN DEFAULT FALSE NOT NULL,
    frozen_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    CONSTRAINT wallets_balance_non_negative CHECK (neocoins_balance >= 0),
    CONSTRAINT wallets_totals_non_negative CHECK (total_earned >= 0 AND total_spent >= 0)
);

COMMENT ON COLUMN public.wallets.frozen IS 
    'Si TRUE, el wallet está congelado y no puede realizar transacciones';

CREATE INDEX idx_wallets_vip ON public.wallets(is_vip) WHERE is_vip = TRUE;
CREATE INDEX idx_wallets_frozen ON public.wallets(frozen) WHERE frozen = TRUE;

CREATE TRIGGER set_wallets_updated_at
    BEFORE UPDATE ON public.wallets
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================================
-- 2. MOTOR DE COMUNIDADES (CMS)
-- ============================================================================

-- Tipo ENUM para estados de comunidad
CREATE TYPE community_status AS ENUM ('active', 'shadowbanned', 'suspended', 'archived');

-- Comunidades principales
CREATE TABLE public.communities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE RESTRICT,
    title VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    theme_config JSONB DEFAULT '{"primary_color": "#6366f1", "secondary_color": "#8b5cf6", "accent_color": "#a855f7", "dark_mode": true}'::jsonb,
    icon_url TEXT,
    banner_url TEXT,
    is_nsfw_flag BOOLEAN DEFAULT FALSE NOT NULL,
    status community_status DEFAULT 'active' NOT NULL,
    member_count INT DEFAULT 0 NOT NULL,
    is_private BOOLEAN DEFAULT FALSE NOT NULL,
    invite_only BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    CONSTRAINT communities_slug_format CHECK (slug ~ '^[a-z0-9-]{3,100}$'),
    CONSTRAINT communities_member_count_non_negative CHECK (member_count >= 0)
);

COMMENT ON COLUMN public.communities.theme_config IS 
    'Configuración de tema JSON: primary_color, secondary_color, accent_color, dark_mode, font_family';
COMMENT ON COLUMN public.communities.status IS 
    'active=visible, shadowbanned=oculta en búsquedas, suspended=acceso bloqueado, archived=solo lectura';

CREATE INDEX idx_communities_owner ON public.communities(owner_id);
CREATE INDEX idx_communities_slug ON public.communities(slug);
CREATE INDEX idx_communities_status ON public.communities(status);
CREATE INDEX idx_communities_nsfw ON public.communities(is_nsfw_flag);
CREATE INDEX idx_communities_created_at ON public.communities(created_at DESC);

CREATE TRIGGER set_communities_updated_at
    BEFORE UPDATE ON public.communities
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Tipo ENUM para roles de membresía
CREATE TYPE membership_role AS ENUM ('owner', 'agent', 'leader', 'curator', 'member');

-- Membresías de usuarios en comunidades
CREATE TABLE public.memberships (
    user_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    role membership_role DEFAULT 'member' NOT NULL,
    nickname VARCHAR(50),
    custom_title VARCHAR(50),
    joined_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    is_muted BOOLEAN DEFAULT FALSE NOT NULL,
    muted_until TIMESTAMPTZ,
    is_banned BOOLEAN DEFAULT FALSE NOT NULL,
    banned_reason TEXT,
    xp_points INT DEFAULT 0 NOT NULL,
    last_active_at TIMESTAMPTZ DEFAULT NOW(),
    
    PRIMARY KEY (user_id, community_id),
    CONSTRAINT memberships_xp_non_negative CHECK (xp_points >= 0)
);

COMMENT ON COLUMN public.memberships.role IS 
    'owner=creador, agent=moderador avanzado, leader=moderador, curator=curador de contenido, member=miembro';

CREATE INDEX idx_memberships_community ON public.memberships(community_id);
CREATE INDEX idx_memberships_role ON public.memberships(community_id, role);
CREATE INDEX idx_memberships_joined_at ON public.memberships(joined_at DESC);

-- Tipo ENUM para tipos de canal
CREATE TYPE channel_type AS ENUM ('text', 'voice', 'stage', 'announcement', 'media');

-- Canales dentro de comunidades
CREATE TABLE public.channels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    type channel_type DEFAULT 'text' NOT NULL,
    is_private BOOLEAN DEFAULT FALSE NOT NULL,
    position INT DEFAULT 0 NOT NULL,
    slowmode_seconds INT DEFAULT 0 NOT NULL,
    is_nsfw BOOLEAN DEFAULT FALSE NOT NULL,
    parent_category_id UUID REFERENCES public.channels(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    CONSTRAINT channels_slowmode_range CHECK (slowmode_seconds >= 0 AND slowmode_seconds <= 21600)
);

COMMENT ON COLUMN public.channels.type IS 
    'text=chat, voice=llamada, stage=evento en vivo, announcement=anuncios, media=galería';

CREATE INDEX idx_channels_community ON public.channels(community_id);
CREATE INDEX idx_channels_type ON public.channels(community_id, type);
CREATE INDEX idx_channels_position ON public.channels(community_id, position);

CREATE TRIGGER set_channels_updated_at
    BEFORE UPDATE ON public.channels
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Configuracion de pestañas de comunidad
CREATE TABLE public.community_tabs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    label VARCHAR(50) NOT NULL,
    type VARCHAR(20) NOT NULL, -- 'feed', 'chat', 'members', 'about', 'custom'
    sort_order INT DEFAULT 0 NOT NULL,
    is_visible BOOLEAN DEFAULT TRUE NOT NULL,
    config JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_community_tabs_community ON public.community_tabs(community_id);
CREATE INDEX idx_community_tabs_order ON public.community_tabs(community_id, sort_order);

CREATE TRIGGER set_community_tabs_updated_at
    BEFORE UPDATE ON public.community_tabs
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Publicaciones de comunidad
CREATE TABLE public.community_posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    title VARCHAR(200),
    content TEXT,
    content_rich JSONB, -- Para contenido estructurado (bloques)
    media_urls TEXT[] DEFAULT '{}',
    is_pinned BOOLEAN DEFAULT FALSE NOT NULL,
    pin_size VARCHAR(20) DEFAULT 'normal', -- 'normal', 'large', 'hero'
    reactions_count INT DEFAULT 0 NOT NULL,
    comments_count INT DEFAULT 0 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_community_posts_community ON public.community_posts(community_id);
CREATE INDEX idx_community_posts_author ON public.community_posts(author_id);
CREATE INDEX idx_community_posts_pinned ON public.community_posts(community_id, is_pinned) WHERE is_pinned = TRUE;
CREATE INDEX idx_community_posts_created ON public.community_posts(created_at DESC);

CREATE TRIGGER set_community_posts_updated_at
    BEFORE UPDATE ON public.community_posts
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================================
-- 3. ECONOMÍA & STREAMING (Modelo de Negocio)
-- ============================================================================

-- Boosts activos para canales (habilita servidor SFU)
CREATE TABLE public.active_boosts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_id UUID NOT NULL REFERENCES public.channels(id) ON DELETE CASCADE,
    payer_user_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE RESTRICT,
    tier VARCHAR(20) DEFAULT 'basic' NOT NULL,
    starts_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    max_viewers INT DEFAULT 50 NOT NULL,
    neocoins_paid DECIMAL(18, 8) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    cancelled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    CONSTRAINT active_boosts_max_viewers_range CHECK (max_viewers >= 10 AND max_viewers <= 10000),
    CONSTRAINT active_boosts_dates_valid CHECK (expires_at > starts_at),
    CONSTRAINT active_boosts_payment_positive CHECK (neocoins_paid > 0)
);

COMMENT ON TABLE public.active_boosts IS 
    'Si existe un registro activo aquí, el canal usa Servidor SFU. Sin registro = P2P gratuito limitado';
COMMENT ON COLUMN public.active_boosts.tier IS 
    'Niveles: basic (50 viewers), pro (100), business (500), enterprise (10000)';

CREATE INDEX idx_active_boosts_channel ON public.active_boosts(channel_id);
CREATE INDEX idx_active_boosts_payer ON public.active_boosts(payer_user_id);
CREATE INDEX idx_active_boosts_active ON public.active_boosts(is_active, expires_at) WHERE is_active = TRUE;
CREATE INDEX idx_active_boosts_expires ON public.active_boosts(expires_at) WHERE is_active = TRUE;

-- Función para verificar si un canal tiene boost activo
CREATE OR REPLACE FUNCTION public.channel_has_active_boost(p_channel_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 
        FROM public.active_boosts 
        WHERE channel_id = p_channel_id 
          AND is_active = TRUE 
          AND NOW() BETWEEN starts_at AND expires_at
    );
$$;

-- Logs de sesiones de streaming (vital para cálculo de costos)
CREATE TABLE public.streaming_logs (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_id UUID NOT NULL REFERENCES public.channels(id) ON DELETE CASCADE,
    streamer_user_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    boost_id UUID REFERENCES public.active_boosts(id) ON DELETE SET NULL,
    started_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    ended_at TIMESTAMPTZ,
    minutes_streamed DECIMAL(10, 2) DEFAULT 0 NOT NULL,
    bandwidth_used_mb DECIMAL(12, 4) DEFAULT 0 NOT NULL,
    peak_viewers INT DEFAULT 0 NOT NULL,
    avg_viewers DECIMAL(8, 2) DEFAULT 0 NOT NULL,
    is_sfu BOOLEAN DEFAULT FALSE NOT NULL,
    quality_profile VARCHAR(20) DEFAULT '720p' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    CONSTRAINT streaming_logs_minutes_non_negative CHECK (minutes_streamed >= 0),
    CONSTRAINT streaming_logs_bandwidth_non_negative CHECK (bandwidth_used_mb >= 0),
    CONSTRAINT streaming_logs_viewers_non_negative CHECK (peak_viewers >= 0 AND avg_viewers >= 0)
);

COMMENT ON TABLE public.streaming_logs IS 
    'Registro detallado de cada sesión de streaming. Vital para calcular costos operativos';
COMMENT ON COLUMN public.streaming_logs.is_sfu IS 
    'TRUE = usó servidor SFU (pagado), FALSE = P2P gratuito';

CREATE INDEX idx_streaming_logs_channel ON public.streaming_logs(channel_id);
CREATE INDEX idx_streaming_logs_streamer ON public.streaming_logs(streamer_user_id);
CREATE INDEX idx_streaming_logs_started ON public.streaming_logs(started_at DESC);
CREATE INDEX idx_streaming_logs_sfu ON public.streaming_logs(is_sfu) WHERE is_sfu = TRUE;

-- Tipo ENUM para tipos de transacción
CREATE TYPE transaction_type AS ENUM (
    'buy_coins',           -- Compra de NeoCoins
    'buy_boost',           -- Compra de boost para canal
    'buy_frame',           -- Compra de marco de perfil
    'buy_badge',           -- Compra de insignia
    'buy_vip',             -- Compra de membresía VIP
    'tip_user',            -- Propina a usuario
    'tip_community',       -- Donación a comunidad
    'refund',              -- Reembolso
    'admin_credit',        -- Crédito por admin
    'admin_debit',         -- Débito por admin
    'subscription_charge', -- Cargo de suscripción
    'withdrawal'           -- Retiro
);

-- Log de transacciones financieras (auditoría completa)
CREATE TABLE public.transactions_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE RESTRICT,
    amount DECIMAL(18, 8) NOT NULL,
    currency VARCHAR(10) DEFAULT 'NEO' NOT NULL,
    type transaction_type NOT NULL,
    platform_fee_percent DECIMAL(5, 2) DEFAULT 30.00 NOT NULL,
    platform_fee_amount DECIMAL(18, 8) GENERATED ALWAYS AS (amount * platform_fee_percent / 100) STORED,
    net_amount DECIMAL(18, 8) GENERATED ALWAYS AS (amount - (amount * platform_fee_percent / 100)) STORED,
    reference_id UUID,
    reference_type VARCHAR(50),
    description TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    ip_address INET,
    user_agent TEXT,
    status VARCHAR(20) DEFAULT 'completed' NOT NULL,
    processed_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    CONSTRAINT transactions_log_fee_range CHECK (platform_fee_percent >= 0 AND platform_fee_percent <= 100)
);

COMMENT ON TABLE public.transactions_log IS 
    'Registro inmutable de todas las transacciones financieras. Auditoría completa para compliance';
COMMENT ON COLUMN public.transactions_log.platform_fee_percent IS 
    'Comisión de la plataforma (default 30%). Se guarda por transacción para histórico';

CREATE INDEX idx_transactions_log_user ON public.transactions_log(user_id);
CREATE INDEX idx_transactions_log_type ON public.transactions_log(type);
CREATE INDEX idx_transactions_log_created ON public.transactions_log(created_at DESC);
CREATE INDEX idx_transactions_log_status ON public.transactions_log(status);
CREATE INDEX idx_transactions_log_reference ON public.transactions_log(reference_type, reference_id);

-- ============================================================================
-- 4. CONTABILIDAD DE COSTOS (Para el Admin Panel)
-- ============================================================================

-- Configuración de costos unitarios
CREATE TABLE public.unit_costs_config (
    key VARCHAR(100) PRIMARY KEY,
    value DECIMAL(18, 8) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD' NOT NULL,
    description TEXT,
    last_updated_by UUID REFERENCES public.users_global(id),
    effective_from TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

COMMENT ON TABLE public.unit_costs_config IS 
    'Configuración de costos unitarios para cálculo de costos operativos';

-- Insertar costos base
INSERT INTO public.unit_costs_config (key, value, description) VALUES
    ('cost_per_gb_storage', 0.023, 'Costo por GB de almacenamiento mensual (AWS S3 estándar)'),
    ('cost_per_minute_sfu', 0.004, 'Costo por minuto de streaming SFU'),
    ('cost_per_1k_ai_tokens', 0.002, 'Costo por 1000 tokens de IA (Gemini)'),
    ('cost_per_gb_bandwidth', 0.085, 'Costo por GB de ancho de banda'),
    ('cost_per_1k_emails', 0.100, 'Costo por 1000 emails transaccionales'),
    ('cost_per_1k_sms', 7.500, 'Costo por 1000 SMS'),
    ('cost_per_auth_mau', 0.00325, 'Costo por MAU de autenticación (Supabase)'),
    ('sfu_server_hourly', 0.50, 'Costo por hora de servidor SFU activo')
ON CONFLICT (key) DO NOTHING;

CREATE TRIGGER set_unit_costs_config_updated_at
    BEFORE UPDATE ON public.unit_costs_config
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Métricas de uso diario para análisis de costos
CREATE TABLE public.daily_usage_metrics (
    date DATE PRIMARY KEY,
    total_storage_gb DECIMAL(12, 4) DEFAULT 0 NOT NULL,
    total_ai_tokens BIGINT DEFAULT 0 NOT NULL,
    total_minutes_sfu DECIMAL(12, 2) DEFAULT 0 NOT NULL,
    total_bandwidth_gb DECIMAL(12, 4) DEFAULT 0 NOT NULL,
    total_emails_sent INT DEFAULT 0 NOT NULL,
    total_sms_sent INT DEFAULT 0 NOT NULL,
    active_users INT DEFAULT 0 NOT NULL,
    new_users INT DEFAULT 0 NOT NULL,
    total_streams INT DEFAULT 0 NOT NULL,
    peak_concurrent_streams INT DEFAULT 0 NOT NULL,
    total_transactions INT DEFAULT 0 NOT NULL,
    total_revenue_neocoins DECIMAL(18, 8) DEFAULT 0 NOT NULL,
    calculated_cost_usd DECIMAL(12, 4),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

COMMENT ON TABLE public.daily_usage_metrics IS 
    'Métricas agregadas diarias para cálculo de costos y análisis de negocio';

CREATE INDEX idx_daily_usage_metrics_date ON public.daily_usage_metrics(date DESC);

CREATE TRIGGER set_daily_usage_metrics_updated_at
    BEFORE UPDATE ON public.daily_usage_metrics
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Función para calcular costo diario estimado
CREATE OR REPLACE FUNCTION public.calculate_daily_cost(p_date DATE)
RETURNS DECIMAL(12, 4)
LANGUAGE plpgsql
AS $$
DECLARE
    v_cost DECIMAL(12, 4) := 0;
    v_metrics RECORD;
    v_costs RECORD;
BEGIN
    -- Obtener métricas del día
    SELECT * INTO v_metrics FROM public.daily_usage_metrics WHERE date = p_date;
    
    IF NOT FOUND THEN
        RETURN 0;
    END IF;
    
    -- Calcular costos
    SELECT 
        (SELECT value FROM public.unit_costs_config WHERE key = 'cost_per_gb_storage') as storage,
        (SELECT value FROM public.unit_costs_config WHERE key = 'cost_per_minute_sfu') as sfu,
        (SELECT value FROM public.unit_costs_config WHERE key = 'cost_per_1k_ai_tokens') as ai,
        (SELECT value FROM public.unit_costs_config WHERE key = 'cost_per_gb_bandwidth') as bandwidth
    INTO v_costs;
    
    v_cost := (v_metrics.total_storage_gb * COALESCE(v_costs.storage, 0)) +
              (v_metrics.total_minutes_sfu * COALESCE(v_costs.sfu, 0)) +
              ((v_metrics.total_ai_tokens / 1000.0) * COALESCE(v_costs.ai, 0)) +
              (v_metrics.total_bandwidth_gb * COALESCE(v_costs.bandwidth, 0));
    
    -- Actualizar el costo calculado
    UPDATE public.daily_usage_metrics 
    SET calculated_cost_usd = v_cost 
    WHERE date = p_date;
    
    RETURN v_cost;
END;
$$;

-- ============================================================================
-- 5. TABLAS AUXILIARES DE AUDITORÍA
-- ============================================================================

-- Log de auditoría para acciones sensibles
CREATE TABLE public.audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users_global(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(100),
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    clearance_level_at_action INT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

COMMENT ON TABLE public.audit_log IS 
    'Log inmutable de todas las acciones sensibles para auditoría y compliance';

CREATE INDEX idx_audit_log_user ON public.audit_log(user_id);
CREATE INDEX idx_audit_log_action ON public.audit_log(action);
CREATE INDEX idx_audit_log_table ON public.audit_log(table_name, record_id);
CREATE INDEX idx_audit_log_created ON public.audit_log(created_at DESC);

-- ============================================================================
-- 6. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE public.users_global ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.active_boosts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.streaming_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.unit_costs_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_usage_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_tabs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- POLÍTICAS GOD MODE (clearance_level = 99) - ACCESO TOTAL
-- ============================================================================

-- GOD MODE: Acceso total a users_global
CREATE POLICY "god_mode_users_global" ON public.users_global
    FOR ALL
    USING (public.is_god_mode())
    WITH CHECK (public.is_god_mode());

-- GOD MODE: Acceso total a security_profile
CREATE POLICY "god_mode_security_profile" ON public.security_profile
    FOR ALL
    USING (public.is_god_mode())
    WITH CHECK (public.is_god_mode());

-- GOD MODE: Acceso total a wallets
CREATE POLICY "god_mode_wallets" ON public.wallets
    FOR ALL
    USING (public.is_god_mode())
    WITH CHECK (public.is_god_mode());

-- GOD MODE: Acceso total a communities
CREATE POLICY "god_mode_communities" ON public.communities
    FOR ALL
    USING (public.is_god_mode())
    WITH CHECK (public.is_god_mode());

-- GOD MODE: Acceso total a memberships
CREATE POLICY "god_mode_memberships" ON public.memberships
    FOR ALL
    USING (public.is_god_mode())
    WITH CHECK (public.is_god_mode());

-- GOD MODE: Acceso total a channels
CREATE POLICY "god_mode_channels" ON public.channels
    FOR ALL
    USING (public.is_god_mode())
    WITH CHECK (public.is_god_mode());

-- GOD MODE: Acceso total a active_boosts
CREATE POLICY "god_mode_active_boosts" ON public.active_boosts
    FOR ALL
    USING (public.is_god_mode())
    WITH CHECK (public.is_god_mode());

-- GOD MODE: Acceso total a streaming_logs
CREATE POLICY "god_mode_streaming_logs" ON public.streaming_logs
    FOR ALL
    USING (public.is_god_mode())
    WITH CHECK (public.is_god_mode());

-- GOD MODE: Acceso total a transactions_log
CREATE POLICY "god_mode_transactions_log" ON public.transactions_log
    FOR ALL
    USING (public.is_god_mode())
    WITH CHECK (public.is_god_mode());

-- GOD MODE: Acceso total a unit_costs_config
CREATE POLICY "god_mode_unit_costs_config" ON public.unit_costs_config
    FOR ALL
    USING (public.is_god_mode())
    WITH CHECK (public.is_god_mode());

-- GOD MODE: Acceso total a daily_usage_metrics
CREATE POLICY "god_mode_daily_usage_metrics" ON public.daily_usage_metrics
    FOR ALL
    USING (public.is_god_mode())
    WITH CHECK (public.is_god_mode());

-- GOD MODE: Acceso total a audit_log
CREATE POLICY "god_mode_audit_log" ON public.audit_log
    FOR ALL
    USING (public.is_god_mode())
    WITH CHECK (public.is_god_mode());

-- ============================================================================
-- POLÍTICAS ESTÁNDAR PARA USUARIOS NORMALES
-- ============================================================================

-- users_global: Usuarios pueden ver todos, pero solo editar el suyo
CREATE POLICY "users_global_select_all" ON public.users_global
    FOR SELECT
    USING (TRUE);

CREATE POLICY "users_global_update_own" ON public.users_global
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "users_global_insert_own" ON public.users_global
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- security_profile: Solo el usuario puede ver/editar su perfil de seguridad
CREATE POLICY "security_profile_select_own" ON public.security_profile
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "security_profile_update_own" ON public.security_profile
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (
        auth.uid() = user_id 
        -- No puede auto-elevarse a GOD MODE
        AND NEW.clearance_level <= (SELECT clearance_level FROM public.security_profile WHERE user_id = auth.uid())
    );

CREATE POLICY "security_profile_insert_own" ON public.security_profile
    FOR INSERT
    WITH CHECK (auth.uid() = user_id AND clearance_level <= 1);

-- wallets: Solo el usuario puede ver su wallet
CREATE POLICY "wallets_select_own" ON public.wallets
    FOR SELECT
    USING (auth.uid() = user_id);

-- wallets: Usuarios no pueden modificar directamente (solo via funciones)
CREATE POLICY "wallets_insert_own" ON public.wallets
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- communities: Usuarios pueden ver comunidades públicas y activas
CREATE POLICY "communities_select_public" ON public.communities
    FOR SELECT
    USING (
        (status = 'active' AND is_private = FALSE)
        OR owner_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.memberships 
            WHERE community_id = communities.id 
            AND user_id = auth.uid()
        )
    );

-- communities: Dueños pueden actualizar sus comunidades
CREATE POLICY "communities_update_owner" ON public.communities
    FOR UPDATE
    USING (owner_id = auth.uid())
    WITH CHECK (owner_id = auth.uid());

-- communities: Cualquier usuario autenticado puede crear comunidades
CREATE POLICY "communities_insert_authenticated" ON public.communities
    FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

-- communities: Solo el dueño puede eliminar
CREATE POLICY "communities_delete_owner" ON public.communities
    FOR DELETE
    USING (owner_id = auth.uid());

-- memberships: Usuarios pueden ver membresías de comunidades donde son miembros
CREATE POLICY "memberships_select_member" ON public.memberships
    FOR SELECT
    USING (
        user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.memberships m2 
            WHERE m2.community_id = memberships.community_id 
            AND m2.user_id = auth.uid()
        )
    );

-- memberships: Usuarios pueden unirse a comunidades públicas
CREATE POLICY "memberships_insert_public" ON public.memberships
    FOR INSERT
    WITH CHECK (
        user_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM public.communities 
            WHERE id = community_id 
            AND is_private = FALSE 
            AND status = 'active'
        )
    );

-- memberships: Usuarios pueden actualizar su propia membresía (nickname, etc)
CREATE POLICY "memberships_update_own" ON public.memberships
    FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- memberships: Usuarios pueden salir de comunidades
CREATE POLICY "memberships_delete_own" ON public.memberships
    FOR DELETE
    USING (user_id = auth.uid());

-- channels: Usuarios pueden ver canales de sus comunidades
CREATE POLICY "channels_select_member" ON public.channels
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.memberships 
            WHERE community_id = channels.community_id 
            AND user_id = auth.uid()
        )
        AND (
            is_private = FALSE
            OR EXISTS (
                SELECT 1 FROM public.memberships 
                WHERE community_id = channels.community_id 
                AND user_id = auth.uid()
                AND role IN ('owner', 'agent', 'leader')
            )
        )
    );

-- channels: Moderadores pueden crear/editar canales
CREATE POLICY "channels_insert_moderator" ON public.channels
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.memberships 
            WHERE community_id = channels.community_id 
            AND user_id = auth.uid()
            AND role IN ('owner', 'agent', 'leader')
        )
    );

CREATE POLICY "channels_update_moderator" ON public.channels
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.memberships 
            WHERE community_id = channels.community_id 
            AND user_id = auth.uid()
            AND role IN ('owner', 'agent', 'leader')
        )
    );

CREATE POLICY "channels_delete_owner" ON public.channels
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.communities 
            WHERE id = channels.community_id 
            AND owner_id = auth.uid()
        )
    );

-- active_boosts: Usuarios pueden ver boosts de canales donde son miembros
CREATE POLICY "active_boosts_select_member" ON public.active_boosts
    FOR SELECT
    USING (
        payer_user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.channels c
            JOIN public.memberships m ON m.community_id = c.community_id
            WHERE c.id = active_boosts.channel_id
            AND m.user_id = auth.uid()
        )
    );

-- active_boosts: Usuarios pueden comprar boosts
CREATE POLICY "active_boosts_insert_own" ON public.active_boosts
    FOR INSERT
    WITH CHECK (payer_user_id = auth.uid());

-- community_tabs: Visible para todos (público)
CREATE POLICY "community_tabs_select_public" ON public.community_tabs
    FOR SELECT
    USING (TRUE);
    
-- community_tabs: Solo dueños pueden editar
CREATE POLICY "community_tabs_all_owner" ON public.community_tabs
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.communities 
            WHERE id = community_tabs.community_id 
            AND owner_id = auth.uid()
        )
    );

-- community_posts: Visible para todos si la comunidad es pública o si es miembro
CREATE POLICY "community_posts_select_viewable" ON public.community_posts
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.communities c
            WHERE c.id = community_posts.community_id
            AND (
                c.is_private = FALSE
                OR c.owner_id = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM public.memberships m
                    WHERE m.community_id = c.id
                    AND m.user_id = auth.uid()
                )
            )
        )
    );

-- community_posts: Miembros pueden crear posts
CREATE POLICY "community_posts_insert_member" ON public.community_posts
    FOR INSERT
    WITH CHECK (
        auth.uid() = author_id
        AND EXISTS (
             SELECT 1 FROM public.memberships m
             WHERE m.community_id = community_id
             AND m.user_id = auth.uid()
        )
    );

-- community_posts: Autor puede editar sus posts
CREATE POLICY "community_posts_update_own" ON public.community_posts
    FOR UPDATE
    USING (auth.uid() = author_id);
    
-- community_posts: Autor y Admins pueden eliminar posts
CREATE POLICY "community_posts_delete_own_or_admin" ON public.community_posts
    FOR DELETE
    USING (
        auth.uid() = author_id
        OR EXISTS (
             SELECT 1 FROM public.memberships m
             WHERE m.community_id = community_posts.community_id
             AND m.user_id = auth.uid()
             AND m.role IN ('owner', 'agent', 'leader')
        )
    );
    WITH CHECK (payer_user_id = auth.uid());

-- streaming_logs: Usuarios ven sus propios logs
CREATE POLICY "streaming_logs_select_own" ON public.streaming_logs
    FOR SELECT
    USING (streamer_user_id = auth.uid());

CREATE POLICY "streaming_logs_insert_own" ON public.streaming_logs
    FOR INSERT
    WITH CHECK (streamer_user_id = auth.uid());

-- transactions_log: Usuarios solo ven sus transacciones
CREATE POLICY "transactions_log_select_own" ON public.transactions_log
    FOR SELECT
    USING (user_id = auth.uid());

-- transactions_log: Inserción controlada (normalmente via funciones seguras)
CREATE POLICY "transactions_log_insert_own" ON public.transactions_log
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- unit_costs_config: Solo lectura para admins (nivel 75+)
CREATE POLICY "unit_costs_config_select_admin" ON public.unit_costs_config
    FOR SELECT
    USING (public.get_user_clearance_level() >= 75);

-- daily_usage_metrics: Solo lectura para admins (nivel 75+)
CREATE POLICY "daily_usage_metrics_select_admin" ON public.daily_usage_metrics
    FOR SELECT
    USING (public.get_user_clearance_level() >= 75);

-- audit_log: Solo GOD MODE puede ver (ya cubierto por política god_mode)
-- No agregamos política estándar - solo existe la de god_mode

-- ============================================================================
-- FUNCIONES SEGURAS PARA TRANSACCIONES DE WALLET
-- ============================================================================

-- Función para transferir NeoCoins (con auditoría)
CREATE OR REPLACE FUNCTION public.transfer_neocoins(
    p_to_user_id UUID,
    p_amount DECIMAL(18, 8),
    p_description TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_from_user_id UUID := auth.uid();
    v_transaction_id UUID;
    v_from_balance DECIMAL(18, 8);
BEGIN
    -- Validaciones
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'El monto debe ser positivo';
    END IF;
    
    IF v_from_user_id = p_to_user_id THEN
        RAISE EXCEPTION 'No puedes transferirte a ti mismo';
    END IF;
    
    -- Verificar wallet no congelado
    SELECT neocoins_balance INTO v_from_balance
    FROM public.wallets
    WHERE user_id = v_from_user_id AND frozen = FALSE
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tu wallet está congelado o no existe';
    END IF;
    
    IF v_from_balance < p_amount THEN
        RAISE EXCEPTION 'Saldo insuficiente';
    END IF;
    
    -- Verificar que el destinatario existe y no está congelado
    IF NOT EXISTS (
        SELECT 1 FROM public.wallets 
        WHERE user_id = p_to_user_id AND frozen = FALSE
    ) THEN
        RAISE EXCEPTION 'Destinatario no encontrado o wallet congelado';
    END IF;
    
    -- Ejecutar transferencia
    UPDATE public.wallets 
    SET neocoins_balance = neocoins_balance - p_amount,
        total_spent = total_spent + p_amount,
        last_transaction_at = NOW()
    WHERE user_id = v_from_user_id;
    
    UPDATE public.wallets 
    SET neocoins_balance = neocoins_balance + p_amount,
        total_earned = total_earned + p_amount,
        last_transaction_at = NOW()
    WHERE user_id = p_to_user_id;
    
    -- Registrar transacción (para el remitente)
    INSERT INTO public.transactions_log (
        user_id, amount, type, platform_fee_percent, 
        reference_id, reference_type, description
    ) VALUES (
        v_from_user_id, -p_amount, 'tip_user', 0,
        p_to_user_id, 'user', p_description
    ) RETURNING id INTO v_transaction_id;
    
    -- Registrar para el destinatario
    INSERT INTO public.transactions_log (
        user_id, amount, type, platform_fee_percent,
        reference_id, reference_type, description
    ) VALUES (
        p_to_user_id, p_amount, 'tip_user', 0,
        v_from_user_id, 'user', p_description
    );
    
    RETURN v_transaction_id;
END;
$$;

-- Función para comprar boost
CREATE OR REPLACE FUNCTION public.purchase_boost(
    p_channel_id UUID,
    p_tier VARCHAR(20),
    p_duration_hours INT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_boost_id UUID;
    v_cost DECIMAL(18, 8);
    v_max_viewers INT;
    v_balance DECIMAL(18, 8);
BEGIN
    -- Determinar costo y viewers según tier
    CASE p_tier
        WHEN 'basic' THEN v_cost := 100 * p_duration_hours; v_max_viewers := 50;
        WHEN 'pro' THEN v_cost := 200 * p_duration_hours; v_max_viewers := 100;
        WHEN 'business' THEN v_cost := 500 * p_duration_hours; v_max_viewers := 500;
        WHEN 'enterprise' THEN v_cost := 1000 * p_duration_hours; v_max_viewers := 10000;
        ELSE RAISE EXCEPTION 'Tier inválido';
    END CASE;
    
    -- Verificar balance
    SELECT neocoins_balance INTO v_balance
    FROM public.wallets
    WHERE user_id = v_user_id AND frozen = FALSE
    FOR UPDATE;
    
    IF v_balance < v_cost THEN
        RAISE EXCEPTION 'Saldo insuficiente. Necesitas % NeoCoins', v_cost;
    END IF;
    
    -- Verificar que el canal existe y el usuario es miembro
    IF NOT EXISTS (
        SELECT 1 FROM public.channels c
        JOIN public.memberships m ON m.community_id = c.community_id
        WHERE c.id = p_channel_id AND m.user_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'Canal no encontrado o no eres miembro';
    END IF;
    
    -- Descontar balance
    UPDATE public.wallets 
    SET neocoins_balance = neocoins_balance - v_cost,
        total_spent = total_spent + v_cost,
        last_transaction_at = NOW()
    WHERE user_id = v_user_id;
    
    -- Crear boost
    INSERT INTO public.active_boosts (
        channel_id, payer_user_id, tier, 
        starts_at, expires_at, max_viewers, neocoins_paid
    ) VALUES (
        p_channel_id, v_user_id, p_tier,
        NOW(), NOW() + (p_duration_hours || ' hours')::INTERVAL,
        v_max_viewers, v_cost
    ) RETURNING id INTO v_boost_id;
    
    -- Registrar transacción
    INSERT INTO public.transactions_log (
        user_id, amount, type, platform_fee_percent,
        reference_id, reference_type, description
    ) VALUES (
        v_user_id, v_cost, 'buy_boost', 30,
        v_boost_id, 'boost', 
        'Boost ' || p_tier || ' para canal por ' || p_duration_hours || ' horas'
    );
    
    RETURN v_boost_id;
END;
$$;

-- ============================================================================
-- TRIGGER PARA CREAR PERFIL Y WALLET AL REGISTRARSE
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Crear registro en users_global
    INSERT INTO public.users_global (id, username, email)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || LEFT(NEW.id::TEXT, 8)),
        NEW.email
    );
    
    -- Crear perfil de seguridad (nivel 1 por defecto)
    INSERT INTO public.security_profile (user_id, clearance_level)
    VALUES (NEW.id, 1);
    
    -- Crear wallet vacío
    INSERT INTO public.wallets (user_id)
    VALUES (NEW.id);
    
    RETURN NEW;
EXCEPTION
    WHEN unique_violation THEN
        -- Si el username ya existe, agregar sufijo aleatorio
        INSERT INTO public.users_global (id, username, email)
        VALUES (
            NEW.id,
            'user_' || LEFT(NEW.id::TEXT, 8) || '_' || FLOOR(RANDOM() * 1000)::TEXT,
            NEW.email
        );
        
        INSERT INTO public.security_profile (user_id, clearance_level)
        VALUES (NEW.id, 1);
        
        INSERT INTO public.wallets (user_id)
        VALUES (NEW.id);
        
        RETURN NEW;
END;
$$;

-- Trigger en auth.users
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- FUNCIÓN PARA ELEVAR A GOD MODE (solo ejecutable desde consola admin)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.elevate_to_god_mode(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Esta función solo debe ejecutarse desde la consola de Supabase
    -- No verificamos auth.uid() porque se ejecuta como superuser
    
    UPDATE public.security_profile 
    SET clearance_level = 99,
        is_incognito = FALSE,
        last_security_review = NOW()
    WHERE user_id = p_user_id;
    
    -- Registrar en audit log
    INSERT INTO public.audit_log (
        user_id, action, table_name, record_id, 
        new_values, clearance_level_at_action
    ) VALUES (
        p_user_id, 'ELEVATED_TO_GOD_MODE', 'security_profile', p_user_id,
        '{"clearance_level": 99}'::jsonb, 99
    );
END;
$$;

-- ============================================================================
-- ÍNDICES ADICIONALES PARA PERFORMANCE
-- ============================================================================

-- Índice compuesto para búsqueda de boosts activos por canal
CREATE INDEX idx_active_boosts_channel_active_time 
    ON public.active_boosts(channel_id, is_active, starts_at, expires_at);

-- Índice para membresías por rol en comunidad
CREATE INDEX idx_memberships_community_role 
    ON public.memberships(community_id, role);

-- Índice parcial para usuarios VIP
CREATE INDEX idx_wallets_vip_active 
    ON public.wallets(user_id, vip_expiry) 
    WHERE is_vip = TRUE AND vip_expiry > NOW();

-- ============================================================================
-- GRANTS PARA SERVICE ROLE (funciones backend)
-- ============================================================================

-- El service_role necesita bypass para operaciones de backend
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO service_role;

-- Usuarios autenticados tienen permisos básicos (RLS controla acceso real)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Usuarios anónimos solo pueden ver datos públicos
GRANT SELECT ON public.users_global TO anon;
GRANT SELECT ON public.communities TO anon;

-- ============================================================================
-- FIN DEL SCHEMA
-- ============================================================================

COMMENT ON SCHEMA public IS 'Schema principal de Project Neo - Red Social SaaS Híbrida';
