-- ============================================================================
-- PROJECT NEO - SECURITY PATCH (AI Moderation Prep)
-- Ejecutar DESPUÉS de 001_production_migration.sql
-- Fecha: 2025-12-22
-- ============================================================================

-- ============================================================================
-- 1. AGREGAR COLUMNAS DE MODERACIÓN A community_posts
-- ============================================================================

-- Estado de moderación: 'pending', 'approved', 'rejected'
ALTER TABLE public.community_posts 
ADD COLUMN IF NOT EXISTS moderation_status VARCHAR(20) DEFAULT 'approved' NOT NULL;

-- Razón de rechazo por IA (para revisión manual)
ALTER TABLE public.community_posts 
ADD COLUMN IF NOT EXISTS ai_flagged_reason TEXT;

-- Índice para filtrar por estado
CREATE INDEX IF NOT EXISTS idx_posts_moderation_status 
ON public.community_posts(community_id, moderation_status);

-- ============================================================================
-- 2. ACTUALIZAR POLÍTICA RLS PARA FILTRAR POSTS NO APROBADOS
-- ============================================================================

-- Eliminar política existente si existe
DROP POLICY IF EXISTS "posts_select_viewable" ON public.community_posts;
DROP POLICY IF EXISTS "select_viewable" ON public.community_posts;
DROP POLICY IF EXISTS "community_posts_select" ON public.community_posts;

-- Nueva política: Solo ver posts aprobados O los propios del usuario
CREATE POLICY "posts_select_viewable" ON public.community_posts
    FOR SELECT USING (
        -- Post está aprobado
        moderation_status = 'approved'
        -- O el usuario es el autor (puede ver sus propios posts pendientes/rechazados)
        OR author_id = auth.uid()
        -- O tiene god_mode
        OR public.is_god_mode()
    );

-- ============================================================================
-- 3. AGREGAR MODERACIÓN A COMENTARIOS (Futuro)
-- ============================================================================

ALTER TABLE public.post_comments 
ADD COLUMN IF NOT EXISTS moderation_status VARCHAR(20) DEFAULT 'approved' NOT NULL;

ALTER TABLE public.post_comments 
ADD COLUMN IF NOT EXISTS ai_flagged_reason TEXT;

-- Actualizar política de comentarios
DROP POLICY IF EXISTS "comments_select_viewable" ON public.post_comments;

CREATE POLICY "comments_select_viewable" ON public.post_comments
    FOR SELECT USING (
        moderation_status = 'approved'
        OR author_id = auth.uid()
        OR public.is_god_mode()
        OR EXISTS (
            SELECT 1 FROM public.community_posts p
            JOIN public.communities c ON c.id = p.community_id
            WHERE p.id = post_comments.post_id
            AND (c.is_private = FALSE OR EXISTS (
                SELECT 1 FROM public.memberships m
                WHERE m.community_id = c.id AND m.user_id = auth.uid()
            ))
        )
    );

-- ============================================================================
-- 4. FUNCIÓN HELPER PARA MODERADORES (Futuro uso)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.moderate_post(
    p_post_id UUID,
    p_status VARCHAR(20),
    p_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Solo permitir a moderadores/owners
    IF NOT EXISTS (
        SELECT 1 FROM public.community_posts p
        JOIN public.memberships m ON m.community_id = p.community_id
        WHERE p.id = p_post_id 
        AND m.user_id = auth.uid()
        AND m.role IN ('owner', 'agent', 'leader')
    ) AND NOT public.is_god_mode() THEN
        RAISE EXCEPTION 'Sin permisos de moderación';
    END IF;
    
    UPDATE public.community_posts
    SET moderation_status = p_status,
        ai_flagged_reason = p_reason,
        updated_at = NOW()
    WHERE id = p_post_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FIN DEL PATCH
-- ============================================================================

-- Verificación
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'community_posts' 
AND column_name IN ('moderation_status', 'ai_flagged_reason');
