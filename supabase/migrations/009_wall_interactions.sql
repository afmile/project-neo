-- ============================================================================
-- PROJECT NEO - WALL POST INTERACTIONS (LIKES & COMMENTS)
-- Enables users to like and comment on wall posts
-- ============================================================================

-- ============================================================================
-- 1. CREATE WALL_POST_LIKES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.wall_post_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES public.wall_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- Composite unique constraint: user can only like a post once
    CONSTRAINT wall_post_likes_unique UNIQUE (post_id, user_id)
);

-- ============================================================================
-- 2. CREATE WALL_POST_COMMENTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.wall_post_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES public.wall_posts(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    CONSTRAINT wall_post_comments_content_not_empty CHECK (LENGTH(TRIM(content)) > 0),
    CONSTRAINT wall_post_comments_content_max_length CHECK (LENGTH(content) <= 1000)
);

-- ============================================================================
-- 3. CREATE INDEXES
-- ============================================================================

-- Index for fetching likes by post (most common query)
CREATE INDEX IF NOT EXISTS idx_wall_post_likes_post 
ON public.wall_post_likes(post_id);

-- Index for fetching likes by user
CREATE INDEX IF NOT EXISTS idx_wall_post_likes_user 
ON public.wall_post_likes(user_id);

-- Index for fetching comments by post (most common query)
CREATE INDEX IF NOT EXISTS idx_wall_post_comments_post 
ON public.wall_post_comments(post_id, created_at DESC);

-- Index for fetching comments by author
CREATE INDEX IF NOT EXISTS idx_wall_post_comments_author 
ON public.wall_post_comments(author_id);

-- ============================================================================
-- 4. ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE public.wall_post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wall_post_comments ENABLE ROW LEVEL SECURITY;

-- ───────────────────────────────────────────────────────────────────────────
-- WALL_POST_LIKES POLICIES
-- ───────────────────────────────────────────────────────────────────────────

-- Policy: Anyone can view likes (public)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'wall_post_likes' 
        AND policyname = 'wall_post_likes_select_public'
    ) THEN
        CREATE POLICY "wall_post_likes_select_public" ON public.wall_post_likes
            FOR SELECT USING (TRUE);
    END IF;
END $$;

-- Policy: Authenticated users can create likes
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'wall_post_likes' 
        AND policyname = 'wall_post_likes_insert_auth'
    ) THEN
        CREATE POLICY "wall_post_likes_insert_auth" ON public.wall_post_likes
            FOR INSERT WITH CHECK (
                auth.uid() = user_id
                AND auth.uid() IS NOT NULL
            );
    END IF;
END $$;

-- Policy: Users can delete their own likes
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'wall_post_likes' 
        AND policyname = 'wall_post_likes_delete_own'
    ) THEN
        CREATE POLICY "wall_post_likes_delete_own" ON public.wall_post_likes
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Policy: God mode for admins
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'wall_post_likes' 
        AND policyname = 'god_mode_wall_post_likes'
    ) THEN
        CREATE POLICY "god_mode_wall_post_likes" ON public.wall_post_likes
            FOR ALL USING (public.is_god_mode()) 
            WITH CHECK (public.is_god_mode());
    END IF;
END $$;

-- ───────────────────────────────────────────────────────────────────────────
-- WALL_POST_COMMENTS POLICIES
-- ───────────────────────────────────────────────────────────────────────────

-- Policy: Anyone can view comments (public)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'wall_post_comments' 
        AND policyname = 'wall_post_comments_select_public'
    ) THEN
        CREATE POLICY "wall_post_comments_select_public" ON public.wall_post_comments
            FOR SELECT USING (TRUE);
    END IF;
END $$;

-- Policy: Authenticated users can create comments
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'wall_post_comments' 
        AND policyname = 'wall_post_comments_insert_auth'
    ) THEN
        CREATE POLICY "wall_post_comments_insert_auth" ON public.wall_post_comments
            FOR INSERT WITH CHECK (
                auth.uid() = author_id
                AND auth.uid() IS NOT NULL
            );
    END IF;
END $$;

-- Policy: Authors can update their own comments
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'wall_post_comments' 
        AND policyname = 'wall_post_comments_update_own'
    ) THEN
        CREATE POLICY "wall_post_comments_update_own" ON public.wall_post_comments
            FOR UPDATE USING (auth.uid() = author_id);
    END IF;
END $$;

-- Policy: Authors can delete their own comments
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'wall_post_comments' 
        AND policyname = 'wall_post_comments_delete_own'
    ) THEN
        CREATE POLICY "wall_post_comments_delete_own" ON public.wall_post_comments
            FOR DELETE USING (auth.uid() = author_id);
    END IF;
END $$;

-- Policy: God mode for admins
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'wall_post_comments' 
        AND policyname = 'god_mode_wall_post_comments'
    ) THEN
        CREATE POLICY "god_mode_wall_post_comments" ON public.wall_post_comments
            FOR ALL USING (public.is_god_mode()) 
            WITH CHECK (public.is_god_mode());
    END IF;
END $$;

-- ============================================================================
-- 5. TRIGGERS
-- ============================================================================

-- Trigger for updated_at timestamp on comments
DROP TRIGGER IF EXISTS set_wall_post_comments_updated_at ON public.wall_post_comments;
CREATE TRIGGER set_wall_post_comments_updated_at
    BEFORE UPDATE ON public.wall_post_comments
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================================
-- 6. FUNCTION TO UPDATE LIKES COUNT
-- ============================================================================

-- Function to automatically update likes_count on wall_posts
CREATE OR REPLACE FUNCTION public.update_wall_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.wall_posts
        SET likes_count = likes_count + 1
        WHERE id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.wall_posts
        SET likes_count = GREATEST(0, likes_count - 1)
        WHERE id = OLD.post_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update likes_count when likes are added/removed
DROP TRIGGER IF EXISTS trigger_update_wall_post_likes_count ON public.wall_post_likes;
CREATE TRIGGER trigger_update_wall_post_likes_count
    AFTER INSERT OR DELETE ON public.wall_post_likes
    FOR EACH ROW EXECUTE FUNCTION public.update_wall_post_likes_count();

-- ============================================================================
-- 7. GRANTS
-- ============================================================================

GRANT ALL ON public.wall_post_likes TO authenticated;
GRANT SELECT ON public.wall_post_likes TO anon;

GRANT ALL ON public.wall_post_comments TO authenticated;
GRANT SELECT ON public.wall_post_comments TO anon;

-- ============================================================================
-- 8. VERIFICATION
-- ============================================================================

-- Verify tables were created
SELECT 'wall_post_likes' AS table_name, COUNT(*) AS column_count
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'wall_post_likes'
UNION ALL
SELECT 'wall_post_comments' AS table_name, COUNT(*) AS column_count
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'wall_post_comments';
