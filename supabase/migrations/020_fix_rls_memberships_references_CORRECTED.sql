-- ============================================================================
-- 020_fix_rls_memberships_references.sql
-- Fix all remaining RLS policies and functions that reference the renamed
-- 'memberships' table (should be 'community_members' since migration 013)
-- 
-- CRITICAL: This migration resolves a security blocker identified in audit
-- Date: 2025-12-27
-- ============================================================================

-- ============================================================================
-- POLICIES AFFECTED (from audit):
-- 
-- 1. post_comments (001_production_migration.sql)
--    - comments_select_viewable (line 171) ❌ References memberships
--    - comments_insert_member (line 185) ❌ References memberships
--    - comments_delete_own_or_mod (line 204) ❌ References memberships
--
-- 2. post_comments (002_security_patch.sql)
--    - comments_select_viewable (line 66) ❌ References memberships
--
-- 3. chat_channels (004_chat_channels.sql)
--    - chat_channels_select_member (line 67) ❌ References memberships
--    - chat_channels_insert_member (line 79) ❌ References memberships
--    - chat_channels_update_creator_or_mod (line 91) ❌ References memberships
--
-- 4. chat_messages (006_chat_messages.sql)
--    - "Ver mensajes" (line 33) ❌ References memberships
--    - "Enviar mensajes" (line 44) ❌ References memberships
--
-- 5. moderate_post function (002_security_patch.sql)
--    - Line 86: References memberships in check
--
-- ALREADY FIXED in 016:
-- - wall_posts_select_scoped ✅
-- - wall_posts_insert_scoped ✅
-- ============================================================================

-- ============================================================================
-- 1. FIX POST_COMMENTS POLICIES
-- ============================================================================

-- Drop all existing policies that may reference 'memberships'
DROP POLICY IF EXISTS "comments_select_viewable" ON public.post_comments;
DROP POLICY IF EXISTS "comments_insert_member" ON public.post_comments;
DROP POLICY IF EXISTS "comments_delete_own_or_mod" ON public.post_comments;

-- Recreate with correct table reference: community_members + is_active check
CREATE POLICY "comments_select_viewable" ON public.post_comments
    FOR SELECT USING (
        -- Approved or own or god mode
        moderation_status = 'approved'
        OR author_id = auth.uid()
        OR public.is_god_mode()
        OR EXISTS (
            SELECT 1 FROM public.community_posts p
            JOIN public.communities c ON c.id = p.community_id
            WHERE p.id = post_comments.post_id
            AND (c.is_private = FALSE OR EXISTS (
                SELECT 1 FROM public.community_members m
                WHERE m.community_id = c.id 
                  AND m.user_id = auth.uid()
                  AND m.is_active = true  -- Respect soft delete
            ))
        )
    );

CREATE POLICY "comments_insert_member" ON public.post_comments
    FOR INSERT WITH CHECK (
        auth.uid() = author_id
        AND EXISTS (
            SELECT 1 FROM public.community_posts p
            JOIN public.community_members m ON m.community_id = p.community_id
            WHERE p.id = post_id 
              AND m.user_id = auth.uid()
              AND m.is_active = true  -- Only active members can comment
        )
    );

CREATE POLICY "comments_delete_own_or_mod" ON public.post_comments
    FOR DELETE USING (
        auth.uid() = author_id
        OR EXISTS (
            SELECT 1 FROM public.community_posts p
            JOIN public.community_members m ON m.community_id = p.community_id
            WHERE p.id = post_id 
            AND m.user_id = auth.uid()
            AND m.is_active = true
            AND m.role IN ('owner', 'agent', 'leader')
        )
    );

-- ============================================================================
-- 2. FIX CHAT_CHANNELS POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "chat_channels_select_member" ON public.chat_channels;
DROP POLICY IF EXISTS "chat_channels_insert_member" ON public.chat_channels;
DROP POLICY IF EXISTS "chat_channels_update_owner_or_mod" ON public.chat_channels;
DROP POLICY IF EXISTS "Dueño o Staff gestiona chat" ON public.chat_channels;
DROP POLICY IF EXISTS "Miembros crean chats" ON public.chat_channels;
DROP POLICY IF EXISTS "Ver chats públicos" ON public.chat_channels;


CREATE POLICY "chat_channels_select_member" ON public.chat_channels
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.community_members 
            WHERE community_id = chat_channels.community_id 
              AND user_id = auth.uid()
              AND is_active = true
        )
        OR public.is_god_mode()
    );

CREATE POLICY "chat_channels_insert_member" ON public.chat_channels
    FOR INSERT WITH CHECK (
        auth.uid() = owner_id
        AND EXISTS (
            SELECT 1 FROM public.community_members 
            WHERE community_id = chat_channels.community_id 
              AND user_id = auth.uid()
              AND is_active = true
        )
    );

CREATE POLICY "chat_channels_update_owner_or_mod" ON public.chat_channels
    FOR UPDATE USING (
        owner_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.community_members 
            WHERE community_id = chat_channels.community_id 
              AND user_id = auth.uid()
              AND is_active = true
              AND role IN ('owner', 'agent', 'leader')
        )
        OR public.is_god_mode()
    );

-- ============================================================================
-- 3. FIX CHAT_MESSAGES POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Ver mensajes" ON public.chat_messages;
DROP POLICY IF EXISTS "Enviar mensajes" ON public.chat_messages;

CREATE POLICY "Ver mensajes" ON public.chat_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.chat_channels c
            JOIN public.community_members m ON m.community_id = c.community_id
            WHERE c.id = chat_messages.channel_id 
              AND m.user_id = auth.uid()
              AND m.is_active = true
        )
        OR public.is_god_mode()
    );

CREATE POLICY "Enviar mensajes" ON public.chat_messages
    FOR INSERT WITH CHECK (
        auth.uid() = user_id 
        AND EXISTS (
            SELECT 1 FROM public.chat_channels c
            JOIN public.community_members m ON m.community_id = c.community_id
            WHERE c.id = channel_id 
              AND m.user_id = auth.uid()
              AND m.is_active = true
        )
    );

-- ============================================================================
-- 4. FIX moderate_post FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION public.moderate_post(
    p_post_id UUID,
    p_status VARCHAR(20),
    p_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Only allow moderators/owners (using community_members, not memberships)
    IF NOT EXISTS (
        SELECT 1 FROM public.community_posts p
        JOIN public.community_members m ON m.community_id = p.community_id
        WHERE p.id = p_post_id 
          AND m.user_id = auth.uid()
          AND m.is_active = true
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
-- 5. UPDATE WALL_POSTS POLICIES (Add is_active check if missing)
-- ============================================================================

-- Ensure wall_posts policies also respect is_active
DROP POLICY IF EXISTS "wall_posts_select_scoped" ON public.wall_posts;
DROP POLICY IF EXISTS "wall_posts_insert_scoped" ON public.wall_posts;

CREATE POLICY "wall_posts_select_scoped" ON public.wall_posts
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.communities c
            WHERE c.id = wall_posts.community_id
            AND (c.is_private = FALSE OR EXISTS (
                SELECT 1 FROM public.community_members m
                WHERE m.community_id = c.id 
                  AND m.user_id = auth.uid()
                  AND m.is_active = true  -- Added: respect soft delete
            ))
        )
    );

CREATE POLICY "wall_posts_insert_scoped" ON public.wall_posts
    FOR INSERT WITH CHECK (
        auth.uid() = author_id
        AND community_id IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM public.community_members m
            WHERE m.community_id = community_id 
              AND m.user_id = auth.uid()
              AND m.is_active = true  -- Added: only active members can post
        )
    );

-- ============================================================================
-- 6. VERIFICATION QUERY
-- ============================================================================

-- This SELECT will help verify no policies still reference 'memberships'
-- Run manually in Supabase SQL Editor after applying migration
-- SELECT policyname, tablename, qual, with_check 
-- FROM pg_policies 
-- WHERE qual::text LIKE '%memberships%' 
--    OR with_check::text LIKE '%memberships%';

-- ============================================================================
-- 7. RELOAD SCHEMA CACHE
-- ============================================================================

NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
-- All policies and functions now reference:
-- - public.community_members (NOT memberships)
-- - is_active = true check (respects soft delete/persistent identity)
-- ============================================================================
