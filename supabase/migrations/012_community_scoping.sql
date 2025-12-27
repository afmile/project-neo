-- ============================================================================
-- 012_community_scoping.sql
-- Add community_id to wall tables for data isolation
-- ============================================================================

-- 1. Add community_id to wall_posts
-- We make it nullable first to avoid errors with existing data, 
-- but in a real scenario we should backfill or delete orphans.
ALTER TABLE public.wall_posts 
ADD COLUMN IF NOT EXISTS community_id UUID REFERENCES public.communities(id) ON DELETE CASCADE;

-- Create index for filtering posts by community
CREATE INDEX IF NOT EXISTS idx_wall_posts_community 
ON public.wall_posts(community_id);

-- Composite index for community + author (common query for profiles)
CREATE INDEX IF NOT EXISTS idx_wall_posts_community_author 
ON public.wall_posts(community_id, author_id);

-- 2. Add community_id to wall_post_comments (as requested)
-- Even if redundant (can be joined via post), user explicitly requested it
ALTER TABLE public.wall_post_comments 
ADD COLUMN IF NOT EXISTS community_id UUID REFERENCES public.communities(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_wall_comments_community 
ON public.wall_post_comments(community_id);

-- 3. Update RLS Policies for Wall Posts to enforce Community Scope

-- Drop old policies if they conflict or need tightening
DROP POLICY IF EXISTS "wall_posts_select_public" ON public.wall_posts;
DROP POLICY IF EXISTS "wall_posts_insert_auth" ON public.wall_posts;

-- New Select Policy: Visible if user is member of community OR community is public
CREATE POLICY "wall_posts_select_scoped" ON public.wall_posts
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.communities c
            WHERE c.id = wall_posts.community_id
            AND (c.is_private = FALSE OR EXISTS (
                SELECT 1 FROM public.memberships m
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
            SELECT 1 FROM public.memberships m
            WHERE m.community_id = community_id AND m.user_id = auth.uid()
        )
    );

-- 4. Validation
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'wall_posts' AND column_name = 'community_id';
