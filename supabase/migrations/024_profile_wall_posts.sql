-- ============================================================================
-- PROJECT NEO - PROFILE WALL POSTS (SEPARATE FROM COMMUNITY WALL)
-- Posts written on user profile walls, distinct from community feed
-- ============================================================================
-- 
-- IMPORTANT: This migration documents the schema that already exists in Supabase.
-- The tables were created manually. This file ensures repo consistency.
--
-- Architecture:
-- - wall_posts -> Community feed (posts by users in community wall)
-- - profile_wall_posts -> User profile walls (posts on someone's profile)
-- ============================================================================

-- ============================================================================
-- 1. CREATE PROFILE_WALL_POSTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.profile_wall_posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_user_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    likes_count INT DEFAULT 0 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    CONSTRAINT profile_wall_posts_content_not_empty CHECK (LENGTH(TRIM(content)) > 0),
    CONSTRAINT profile_wall_posts_content_max_length CHECK (LENGTH(content) <= 2000)
);

-- ============================================================================
-- 2. CREATE PROFILE_WALL_POST_LIKES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.profile_wall_post_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES public.profile_wall_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    CONSTRAINT profile_wall_post_likes_unique UNIQUE (post_id, user_id)
);

-- ============================================================================
-- 3. CREATE PROFILE_WALL_POST_COMMENTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.profile_wall_post_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES public.profile_wall_posts(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    CONSTRAINT profile_wall_post_comments_content_not_empty CHECK (LENGTH(TRIM(content)) > 0),
    CONSTRAINT profile_wall_post_comments_content_max_length CHECK (LENGTH(content) <= 1000)
);

-- ============================================================================
-- 4. CREATE INDEXES
-- ============================================================================

-- Index for fetching posts by profile user + community (most common query)
CREATE INDEX IF NOT EXISTS idx_profile_wall_posts_profile_community 
ON public.profile_wall_posts(profile_user_id, community_id, created_at DESC);

-- Index for fetching posts by author
CREATE INDEX IF NOT EXISTS idx_profile_wall_posts_author 
ON public.profile_wall_posts(author_id);

-- Index for fetching likes by post
CREATE INDEX IF NOT EXISTS idx_profile_wall_post_likes_post 
ON public.profile_wall_post_likes(post_id);

-- Index for fetching likes by user
CREATE INDEX IF NOT EXISTS idx_profile_wall_post_likes_user 
ON public.profile_wall_post_likes(user_id);

-- Index for fetching comments by post
CREATE INDEX IF NOT EXISTS idx_profile_wall_post_comments_post 
ON public.profile_wall_post_comments(post_id, created_at DESC);

-- ============================================================================
-- 5. ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE public.profile_wall_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_wall_post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_wall_post_comments ENABLE ROW LEVEL SECURITY;

-- ───────────────────────────────────────────────────────────────────────────
-- PROFILE_WALL_POSTS POLICIES
-- ───────────────────────────────────────────────────────────────────────────

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profile_wall_posts' 
        AND policyname = 'profile_wall_posts_select_public'
    ) THEN
        CREATE POLICY "profile_wall_posts_select_public" ON public.profile_wall_posts
            FOR SELECT USING (TRUE);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profile_wall_posts' 
        AND policyname = 'profile_wall_posts_insert_auth'
    ) THEN
        CREATE POLICY "profile_wall_posts_insert_auth" ON public.profile_wall_posts
            FOR INSERT WITH CHECK (
                auth.uid() = author_id
                AND auth.uid() IS NOT NULL
            );
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profile_wall_posts' 
        AND policyname = 'profile_wall_posts_update_own'
    ) THEN
        CREATE POLICY "profile_wall_posts_update_own" ON public.profile_wall_posts
            FOR UPDATE USING (auth.uid() = author_id);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profile_wall_posts' 
        AND policyname = 'profile_wall_posts_delete_own_or_owner'
    ) THEN
        CREATE POLICY "profile_wall_posts_delete_own_or_owner" ON public.profile_wall_posts
            FOR DELETE USING (
                auth.uid() = author_id 
                OR auth.uid() = profile_user_id
            );
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profile_wall_posts' 
        AND policyname = 'god_mode_profile_wall_posts'
    ) THEN
        CREATE POLICY "god_mode_profile_wall_posts" ON public.profile_wall_posts
            FOR ALL USING (public.is_god_mode()) 
            WITH CHECK (public.is_god_mode());
    END IF;
END $$;

-- ───────────────────────────────────────────────────────────────────────────
-- PROFILE_WALL_POST_LIKES POLICIES
-- ───────────────────────────────────────────────────────────────────────────

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profile_wall_post_likes' 
        AND policyname = 'profile_wall_post_likes_select_public'
    ) THEN
        CREATE POLICY "profile_wall_post_likes_select_public" ON public.profile_wall_post_likes
            FOR SELECT USING (TRUE);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profile_wall_post_likes' 
        AND policyname = 'profile_wall_post_likes_insert_auth'
    ) THEN
        CREATE POLICY "profile_wall_post_likes_insert_auth" ON public.profile_wall_post_likes
            FOR INSERT WITH CHECK (
                auth.uid() = user_id
                AND auth.uid() IS NOT NULL
            );
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profile_wall_post_likes' 
        AND policyname = 'profile_wall_post_likes_delete_own'
    ) THEN
        CREATE POLICY "profile_wall_post_likes_delete_own" ON public.profile_wall_post_likes
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profile_wall_post_likes' 
        AND policyname = 'god_mode_profile_wall_post_likes'
    ) THEN
        CREATE POLICY "god_mode_profile_wall_post_likes" ON public.profile_wall_post_likes
            FOR ALL USING (public.is_god_mode()) 
            WITH CHECK (public.is_god_mode());
    END IF;
END $$;

-- ───────────────────────────────────────────────────────────────────────────
-- PROFILE_WALL_POST_COMMENTS POLICIES
-- ───────────────────────────────────────────────────────────────────────────

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profile_wall_post_comments' 
        AND policyname = 'profile_wall_post_comments_select_public'
    ) THEN
        CREATE POLICY "profile_wall_post_comments_select_public" ON public.profile_wall_post_comments
            FOR SELECT USING (TRUE);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profile_wall_post_comments' 
        AND policyname = 'profile_wall_post_comments_insert_auth'
    ) THEN
        CREATE POLICY "profile_wall_post_comments_insert_auth" ON public.profile_wall_post_comments
            FOR INSERT WITH CHECK (
                auth.uid() = author_id
                AND auth.uid() IS NOT NULL
            );
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profile_wall_post_comments' 
        AND policyname = 'profile_wall_post_comments_update_own'
    ) THEN
        CREATE POLICY "profile_wall_post_comments_update_own" ON public.profile_wall_post_comments
            FOR UPDATE USING (auth.uid() = author_id);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profile_wall_post_comments' 
        AND policyname = 'profile_wall_post_comments_delete_own'
    ) THEN
        CREATE POLICY "profile_wall_post_comments_delete_own" ON public.profile_wall_post_comments
            FOR DELETE USING (auth.uid() = author_id);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profile_wall_post_comments' 
        AND policyname = 'god_mode_profile_wall_post_comments'
    ) THEN
        CREATE POLICY "god_mode_profile_wall_post_comments" ON public.profile_wall_post_comments
            FOR ALL USING (public.is_god_mode()) 
            WITH CHECK (public.is_god_mode());
    END IF;
END $$;

-- ============================================================================
-- 6. TRIGGERS
-- ============================================================================

-- Trigger for updated_at timestamp on profile_wall_posts
DROP TRIGGER IF EXISTS set_profile_wall_posts_updated_at ON public.profile_wall_posts;
CREATE TRIGGER set_profile_wall_posts_updated_at
    BEFORE UPDATE ON public.profile_wall_posts
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Trigger for updated_at timestamp on profile_wall_post_comments
DROP TRIGGER IF EXISTS set_profile_wall_post_comments_updated_at ON public.profile_wall_post_comments;
CREATE TRIGGER set_profile_wall_post_comments_updated_at
    BEFORE UPDATE ON public.profile_wall_post_comments
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================================
-- 7. FUNCTION TO UPDATE LIKES COUNT
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_profile_wall_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.profile_wall_posts
        SET likes_count = likes_count + 1
        WHERE id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.profile_wall_posts
        SET likes_count = GREATEST(0, likes_count - 1)
        WHERE id = OLD.post_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_profile_wall_post_likes_count ON public.profile_wall_post_likes;
CREATE TRIGGER trigger_update_profile_wall_post_likes_count
    AFTER INSERT OR DELETE ON public.profile_wall_post_likes
    FOR EACH ROW EXECUTE FUNCTION public.update_profile_wall_post_likes_count();

-- ============================================================================
-- 8. GRANTS
-- ============================================================================

GRANT ALL ON public.profile_wall_posts TO authenticated;
GRANT SELECT ON public.profile_wall_posts TO anon;

GRANT ALL ON public.profile_wall_post_likes TO authenticated;
GRANT SELECT ON public.profile_wall_post_likes TO anon;

GRANT ALL ON public.profile_wall_post_comments TO authenticated;
GRANT SELECT ON public.profile_wall_post_comments TO anon;

-- ============================================================================
-- 9. VERIFICATION
-- ============================================================================

SELECT 'profile_wall_posts' AS table_name, COUNT(*) AS column_count
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'profile_wall_posts'
UNION ALL
SELECT 'profile_wall_post_likes' AS table_name, COUNT(*) AS column_count
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'profile_wall_post_likes'
UNION ALL
SELECT 'profile_wall_post_comments' AS table_name, COUNT(*) AS column_count
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'profile_wall_post_comments';
