-- ============================================================================
-- PROJECT NEO - MIGRACIÓN A PRODUCCIÓN
-- Ejecutar en el Editor SQL de Supabase Dashboard
-- Fecha: 2025-12-22
-- ============================================================================

-- ============================================================================
-- 0. PREREQUISITOS - Crear funciones si no existen
-- ============================================================================

-- Crear tabla security_profile si no existe (para god_mode)
CREATE TABLE IF NOT EXISTS public.security_profile (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    clearance_level INT DEFAULT 1 NOT NULL,
    is_incognito BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    UNIQUE(user_id)
);

-- Función para verificar si el usuario tiene GOD MODE activo
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

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 1. MODIFICAR community_posts PARA SOPORTE DE TIPOS
-- ============================================================================

-- Añadir columnas necesarias
ALTER TABLE public.community_posts 
ADD COLUMN IF NOT EXISTS post_type VARCHAR(20) DEFAULT 'blog' NOT NULL;

ALTER TABLE public.community_posts 
ADD COLUMN IF NOT EXISTS cover_image_url TEXT;

-- Índice para filtrar por tipo
CREATE INDEX IF NOT EXISTS idx_community_posts_type 
ON public.community_posts(community_id, post_type);

-- ============================================================================
-- 2. TABLA DE REACCIONES (Likes/Love/etc)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.post_reactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES public.community_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    type VARCHAR(20) DEFAULT 'like' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    UNIQUE(post_id, user_id)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_post_reactions_post ON public.post_reactions(post_id);
CREATE INDEX IF NOT EXISTS idx_post_reactions_user ON public.post_reactions(user_id);
CREATE INDEX IF NOT EXISTS idx_post_reactions_type ON public.post_reactions(post_id, type);

-- RLS
ALTER TABLE public.post_reactions ENABLE ROW LEVEL SECURITY;

-- Políticas RLS para reacciones
DO $$ 
BEGIN
    -- Select: Cualquiera puede ver reacciones
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'post_reactions' AND policyname = 'reactions_select_public') THEN
        CREATE POLICY "reactions_select_public" ON public.post_reactions
            FOR SELECT USING (TRUE);
    END IF;
    
    -- Insert: Solo usuarios autenticados pueden reaccionar
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'post_reactions' AND policyname = 'reactions_insert_auth') THEN
        CREATE POLICY "reactions_insert_auth" ON public.post_reactions
            FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    
    -- Delete: Solo el usuario puede quitar su reacción
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'post_reactions' AND policyname = 'reactions_delete_own') THEN
        CREATE POLICY "reactions_delete_own" ON public.post_reactions
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
    
    -- God mode
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'post_reactions' AND policyname = 'god_mode_reactions') THEN
        CREATE POLICY "god_mode_reactions" ON public.post_reactions
            FOR ALL USING (public.is_god_mode()) WITH CHECK (public.is_god_mode());
    END IF;
END $$;

-- Trigger para actualizar contador automáticamente
CREATE OR REPLACE FUNCTION public.update_reactions_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.community_posts 
        SET reactions_count = reactions_count + 1 
        WHERE id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.community_posts 
        SET reactions_count = GREATEST(reactions_count - 1, 0)
        WHERE id = OLD.post_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS reactions_count_trigger ON public.post_reactions;
CREATE TRIGGER reactions_count_trigger
    AFTER INSERT OR DELETE ON public.post_reactions
    FOR EACH ROW EXECUTE FUNCTION public.update_reactions_count();

-- ============================================================================
-- 3. TABLA DE COMENTARIOS
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.post_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES public.community_posts(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES public.post_comments(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_edited BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    CONSTRAINT comments_content_not_empty CHECK (LENGTH(TRIM(content)) > 0)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_comments_post ON public.post_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_author ON public.post_comments(author_id);
CREATE INDEX IF NOT EXISTS idx_comments_parent ON public.post_comments(parent_id);
CREATE INDEX IF NOT EXISTS idx_comments_created ON public.post_comments(post_id, created_at DESC);

-- RLS
ALTER TABLE public.post_comments ENABLE ROW LEVEL SECURITY;

-- Políticas RLS para comentarios
DO $$ 
BEGIN
    -- Select: Ver comentarios de posts accesibles
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'post_comments' AND policyname = 'comments_select_viewable') THEN
        CREATE POLICY "comments_select_viewable" ON public.post_comments
            FOR SELECT USING (
                EXISTS (
                    SELECT 1 FROM public.community_posts p
                    JOIN public.communities c ON c.id = p.community_id
                    WHERE p.id = post_comments.post_id
                    AND (c.is_private = FALSE OR EXISTS (
                        SELECT 1 FROM public.memberships m
                        WHERE m.community_id = c.id AND m.user_id = auth.uid()
                    ))
                )
            );
    END IF;
    
    -- Insert: Miembros pueden comentar
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'post_comments' AND policyname = 'comments_insert_member') THEN
        CREATE POLICY "comments_insert_member" ON public.post_comments
            FOR INSERT WITH CHECK (
                auth.uid() = author_id
                AND EXISTS (
                    SELECT 1 FROM public.community_posts p
                    JOIN public.memberships m ON m.community_id = p.community_id
                    WHERE p.id = post_id AND m.user_id = auth.uid()
                )
            );
    END IF;
    
    -- Update: Solo el autor
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'post_comments' AND policyname = 'comments_update_own') THEN
        CREATE POLICY "comments_update_own" ON public.post_comments
            FOR UPDATE USING (auth.uid() = author_id);
    END IF;
    
    -- Delete: Autor o moderadores
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'post_comments' AND policyname = 'comments_delete_own_or_mod') THEN
        CREATE POLICY "comments_delete_own_or_mod" ON public.post_comments
            FOR DELETE USING (
                auth.uid() = author_id
                OR EXISTS (
                    SELECT 1 FROM public.community_posts p
                    JOIN public.memberships m ON m.community_id = p.community_id
                    WHERE p.id = post_id 
                    AND m.user_id = auth.uid()
                    AND m.role IN ('owner', 'agent', 'leader')
                )
            );
    END IF;
    
    -- God mode
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'post_comments' AND policyname = 'god_mode_comments') THEN
        CREATE POLICY "god_mode_comments" ON public.post_comments
            FOR ALL USING (public.is_god_mode()) WITH CHECK (public.is_god_mode());
    END IF;
END $$;

-- Trigger para contador de comentarios
CREATE OR REPLACE FUNCTION public.update_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.community_posts 
        SET comments_count = comments_count + 1 
        WHERE id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.community_posts 
        SET comments_count = GREATEST(comments_count - 1, 0)
        WHERE id = OLD.post_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS comments_count_trigger ON public.post_comments;
CREATE TRIGGER comments_count_trigger
    AFTER INSERT OR DELETE ON public.post_comments
    FOR EACH ROW EXECUTE FUNCTION public.update_comments_count();

-- Trigger para updated_at
DROP TRIGGER IF EXISTS set_comments_updated_at ON public.post_comments;
CREATE TRIGGER set_comments_updated_at
    BEFORE UPDATE ON public.post_comments
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================================
-- 4. SISTEMA DE ENCUESTAS (Polls) - SEPARADO DE LIKES
-- ============================================================================

-- Opciones de encuesta
CREATE TABLE IF NOT EXISTS public.poll_options (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES public.community_posts(id) ON DELETE CASCADE,
    text VARCHAR(200) NOT NULL,
    position INT DEFAULT 0 NOT NULL,
    votes_count INT DEFAULT 0 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    CONSTRAINT poll_options_text_not_empty CHECK (LENGTH(TRIM(text)) > 0)
);

CREATE INDEX IF NOT EXISTS idx_poll_options_post ON public.poll_options(post_id, position);

-- Votos de encuesta (separado de likes!)
CREATE TABLE IF NOT EXISTS public.poll_votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    option_id UUID NOT NULL REFERENCES public.poll_options(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    UNIQUE(option_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_poll_votes_option ON public.poll_votes(option_id);
CREATE INDEX IF NOT EXISTS idx_poll_votes_user ON public.poll_votes(user_id);

-- Constraint: Un usuario solo puede votar UNA opción por encuesta (usando trigger)
CREATE OR REPLACE FUNCTION public.check_single_vote_per_poll()
RETURNS TRIGGER AS $$
DECLARE
    v_post_id UUID;
    v_existing_vote_count INT;
BEGIN
    -- Obtener el post_id de la opción
    SELECT post_id INTO v_post_id 
    FROM public.poll_options 
    WHERE id = NEW.option_id;
    
    -- Verificar si ya existe un voto del usuario en cualquier opción de esta encuesta
    SELECT COUNT(*) INTO v_existing_vote_count
    FROM public.poll_votes pv
    JOIN public.poll_options po ON pv.option_id = po.id
    WHERE po.post_id = v_post_id 
    AND pv.user_id = NEW.user_id
    AND pv.id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::UUID);
    
    IF v_existing_vote_count > 0 THEN
        RAISE EXCEPTION 'El usuario ya votó en esta encuesta. Elimina el voto anterior primero.';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_single_vote_trigger ON public.poll_votes;
CREATE TRIGGER check_single_vote_trigger
    BEFORE INSERT ON public.poll_votes
    FOR EACH ROW EXECUTE FUNCTION public.check_single_vote_per_poll();

-- RLS para poll_options y poll_votes
ALTER TABLE public.poll_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.poll_votes ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    -- Poll options: Visible si el post es visible
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'poll_options' AND policyname = 'poll_options_select') THEN
        CREATE POLICY "poll_options_select" ON public.poll_options
            FOR SELECT USING (TRUE);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'poll_options' AND policyname = 'poll_options_insert') THEN
        CREATE POLICY "poll_options_insert" ON public.poll_options
            FOR INSERT WITH CHECK (
                EXISTS (
                    SELECT 1 FROM public.community_posts p
                    WHERE p.id = post_id AND p.author_id = auth.uid()
                )
            );
    END IF;
    
    -- Poll votes
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'poll_votes' AND policyname = 'poll_votes_select') THEN
        CREATE POLICY "poll_votes_select" ON public.poll_votes
            FOR SELECT USING (TRUE);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'poll_votes' AND policyname = 'poll_votes_insert') THEN
        CREATE POLICY "poll_votes_insert" ON public.poll_votes
            FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'poll_votes' AND policyname = 'poll_votes_delete') THEN
        CREATE POLICY "poll_votes_delete" ON public.poll_votes
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Trigger para contador de votos
CREATE OR REPLACE FUNCTION public.update_poll_votes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.poll_options 
        SET votes_count = votes_count + 1 
        WHERE id = NEW.option_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.poll_options 
        SET votes_count = GREATEST(votes_count - 1, 0)
        WHERE id = OLD.option_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS poll_votes_count_trigger ON public.poll_votes;
CREATE TRIGGER poll_votes_count_trigger
    AFTER INSERT OR DELETE ON public.poll_votes
    FOR EACH ROW EXECUTE FUNCTION public.update_poll_votes_count();

-- ============================================================================
-- 5. GRANTS
-- ============================================================================

GRANT ALL ON public.post_reactions TO authenticated;
GRANT ALL ON public.post_comments TO authenticated;
GRANT ALL ON public.poll_options TO authenticated;
GRANT ALL ON public.poll_votes TO authenticated;

GRANT SELECT ON public.post_reactions TO anon;
GRANT SELECT ON public.post_comments TO anon;
GRANT SELECT ON public.poll_options TO anon;
GRANT SELECT ON public.poll_votes TO anon;

-- ============================================================================
-- FIN DE LA MIGRACIÓN
-- ============================================================================

-- Verificación: Listar nuevas tablas
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('post_reactions', 'post_comments', 'poll_options', 'poll_votes');
