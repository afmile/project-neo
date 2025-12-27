-- Migration to fix missing UPDATE policy for community_members
-- This enables users to update their own local profile (nickname, bio, etc.)

-- Create Update Policy
DROP POLICY IF EXISTS "community_members_update_self" ON public.community_members;

CREATE POLICY "community_members_update_self" ON public.community_members
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Ensure the table has RLS enabled (should be already, but harmless to repeat)
ALTER TABLE public.community_members ENABLE ROW LEVEL SECURITY;

-- Reload schema cache to apply changes immediately
NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- FIX MISSING SCHEMA COLUMNS (If 012 failed or was skipped)
-- ============================================================================

-- Ensure community_id exists in wall_posts
ALTER TABLE public.wall_posts 
ADD COLUMN IF NOT EXISTS community_id UUID REFERENCES public.communities(id) ON DELETE CASCADE;

-- Ensure community_id exists in wall_post_comments
ALTER TABLE public.wall_post_comments 
ADD COLUMN IF NOT EXISTS community_id UUID REFERENCES public.communities(id) ON DELETE CASCADE;

-- Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_wall_posts_community ON public.wall_posts(community_id);
CREATE INDEX IF NOT EXISTS idx_wall_posts_community_author ON public.wall_posts(community_id, author_id);
CREATE INDEX IF NOT EXISTS idx_wall_comments_community ON public.wall_post_comments(community_id);

-- ============================================================================
-- FIX WALL POSTS RLS (References renamed table 'memberships' -> 'community_members')
-- ============================================================================

-- Drop old policies that might reference the renamed 'memberships' table
DROP POLICY IF EXISTS "wall_posts_select_scoped" ON public.wall_posts;
DROP POLICY IF EXISTS "wall_posts_insert_scoped" ON public.wall_posts;

-- New Select Policy: Visible if user is member of community OR community is public
-- References public.community_members properly
CREATE POLICY "wall_posts_select_scoped" ON public.wall_posts
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.communities c
            WHERE c.id = wall_posts.community_id
            AND (c.is_private = FALSE OR EXISTS (
                SELECT 1 FROM public.community_members m
                WHERE m.community_id = c.id AND m.user_id = auth.uid()
            ))
        )
    );

-- New Insert Policy: Must specify community_id and be a member
CREATE POLICY "wall_posts_insert_scoped" ON public.wall_posts
    FOR INSERT WITH CHECK (
        auth.uid() = author_id
        AND community_id IS NOT NULL
        AND EXISTS (
             SELECT 1 FROM public.community_members m
             WHERE m.community_id = community_id AND m.user_id = auth.uid()
        )
    );

