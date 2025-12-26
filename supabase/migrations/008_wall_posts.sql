-- ============================================================================
-- PROJECT NEO - WALL POSTS FEATURE
-- User profile wall posts for community interaction
-- ============================================================================

-- ============================================================================
-- 1. CREATE WALL_POSTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.wall_posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_user_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    likes_count INT DEFAULT 0 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    CONSTRAINT wall_posts_content_not_empty CHECK (LENGTH(TRIM(content)) > 0),
    CONSTRAINT wall_posts_content_max_length CHECK (LENGTH(content) <= 2000)
);

-- ============================================================================
-- 2. CREATE INDEXES
-- ============================================================================

-- Index for fetching posts by profile user (most common query)
CREATE INDEX IF NOT EXISTS idx_wall_posts_profile 
ON public.wall_posts(profile_user_id, created_at DESC);

-- Index for fetching posts by author
CREATE INDEX IF NOT EXISTS idx_wall_posts_author 
ON public.wall_posts(author_id);

-- ============================================================================
-- 3. ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE public.wall_posts ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can view wall posts (public walls)
-- TODO: Add privacy level checks when privacy feature is implemented
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'wall_posts' 
        AND policyname = 'wall_posts_select_public'
    ) THEN
        CREATE POLICY "wall_posts_select_public" ON public.wall_posts
            FOR SELECT USING (TRUE);
    END IF;
END $$;

-- Policy: Authenticated users can create posts
-- TODO: Add privacy level checks (friendsOnly, closed, etc.)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'wall_posts' 
        AND policyname = 'wall_posts_insert_auth'
    ) THEN
        CREATE POLICY "wall_posts_insert_auth" ON public.wall_posts
            FOR INSERT WITH CHECK (
                auth.uid() = author_id
                AND auth.uid() IS NOT NULL
            );
    END IF;
END $$;

-- Policy: Author can update their own posts
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'wall_posts' 
        AND policyname = 'wall_posts_update_own'
    ) THEN
        CREATE POLICY "wall_posts_update_own" ON public.wall_posts
            FOR UPDATE USING (auth.uid() = author_id);
    END IF;
END $$;

-- Policy: Author OR wall owner can delete posts
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'wall_posts' 
        AND policyname = 'wall_posts_delete_own_or_owner'
    ) THEN
        CREATE POLICY "wall_posts_delete_own_or_owner" ON public.wall_posts
            FOR DELETE USING (
                auth.uid() = author_id 
                OR auth.uid() = profile_user_id
            );
    END IF;
END $$;

-- Policy: God mode for admins
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'wall_posts' 
        AND policyname = 'god_mode_wall_posts'
    ) THEN
        CREATE POLICY "god_mode_wall_posts" ON public.wall_posts
            FOR ALL USING (public.is_god_mode()) 
            WITH CHECK (public.is_god_mode());
    END IF;
END $$;

-- ============================================================================
-- 4. TRIGGERS
-- ============================================================================

-- Trigger for updated_at timestamp
DROP TRIGGER IF EXISTS set_wall_posts_updated_at ON public.wall_posts;
CREATE TRIGGER set_wall_posts_updated_at
    BEFORE UPDATE ON public.wall_posts
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================================
-- 5. GRANTS
-- ============================================================================

GRANT ALL ON public.wall_posts TO authenticated;
GRANT SELECT ON public.wall_posts TO anon;

-- ============================================================================
-- 6. VERIFICATION
-- ============================================================================

-- Verify table was created
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'wall_posts'
ORDER BY ordinal_position;
