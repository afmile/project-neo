-- ============================================================================
-- 021_fix_chat_channels_owner_id_to_creator_id.sql
-- Fix chat_channels RLS policies that incorrectly reference 'owner_id'
-- when the actual column name is 'creator_id'
-- 
-- ROOT CAUSE: Migration 020 fixed memberships → community_members but
-- introduced a new bug by using 'owner_id' instead of 'creator_id'
-- ============================================================================

-- ============================================================================
-- FIX CHAT_CHANNELS RLS POLICIES
-- ============================================================================

-- Drop existing policies (from migration 020)
DROP POLICY IF EXISTS "chat_channels_insert_member" ON public.chat_channels;
DROP POLICY IF EXISTS "chat_channels_update_owner_or_mod" ON public.chat_channels;

-- Recreate with CORRECT column name: creator_id (not owner_id)
CREATE POLICY "chat_channels_insert_member" ON public.chat_channels
    FOR INSERT WITH CHECK (
        auth.uid() = creator_id  -- FIXED: was owner_id
        AND EXISTS (
            SELECT 1 FROM public.community_members 
            WHERE community_id = chat_channels.community_id 
              AND user_id = auth.uid()
              AND is_active = true
        )
    );

CREATE POLICY "chat_channels_update_creator_or_mod" ON public.chat_channels
    FOR UPDATE USING (
        creator_id = auth.uid()  -- FIXED: was owner_id
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
-- RELOAD SCHEMA
-- ============================================================================

NOTIFY pgrst, 'reload schema';
