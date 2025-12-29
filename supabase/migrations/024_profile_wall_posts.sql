-- ============================================================================
-- 024_profile_wall_posts.sql
-- Separate table for user profile wall posts (distinct from community wall)
-- ============================================================================

-- ============================================================================
-- 1. CREATE PROFILE_WALL_POSTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.profile_wall_posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- The user whose profile wall this post is on
    profile_user_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    -- The community context (for scoping and local profiles)
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    -- The author who wrote the post
    author_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    -- Post content
    content TEXT NOT NULL,
    likes_count INT DEFAULT 0 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    -- Constraints
    CONSTRAINT profile_wall_posts_content_not_empty CHECK (LENGTH(TRIM(content)) > 0),
    CONSTRAINT profile_wall_posts_content_max_length CHECK (LENGTH(content) <= 2000)
);

-- ============================================================================
-- 2. CREATE INDEXES
-- ============================================================================

-- Primary query: posts on a user's profile wall within a community
CREATE INDEX IF NOT EXISTS idx_profile_wall_posts_profile_community 
ON public.profile_wall_posts(profile_user_id, community_id, created_at DESC);

-- Index for author lookups
CREATE INDEX IF NOT EXISTS idx_profile_wall_posts_author 
ON public.profile_wall_posts(author_id);

-- Index for community-scoped queries
CREATE INDEX IF NOT EXISTS idx_profile_wall_posts_community 
ON public.profile_wall_posts(community_id);

-- ============================================================================
-- 3. ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE public.profile_wall_posts ENABLE ROW LEVEL SECURITY;

-- Policy: SELECT - Visible if user is member of community OR community is public
CREATE POLICY "profile_wall_posts_select_scoped" ON public.profile_wall_posts
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.communities c
            WHERE c.id = profile_wall_posts.community_id
            AND (c.is_private = FALSE OR EXISTS (
                SELECT 1 FROM public.community_members m
                WHERE m.community_id = c.id AND m.user_id = auth.uid() AND m.is_active = TRUE
            ))
        )
    );

-- Policy: INSERT - Must be authenticated and member of community
CREATE POLICY "profile_wall_posts_insert_member" ON public.profile_wall_posts
    FOR INSERT WITH CHECK (
        auth.uid() = author_id
        AND auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM public.community_members m
            WHERE m.community_id = community_id AND m.user_id = auth.uid() AND m.is_active = TRUE
        )
    );

-- Policy: UPDATE - Only author can update
CREATE POLICY "profile_wall_posts_update_own" ON public.profile_wall_posts
    FOR UPDATE USING (auth.uid() = author_id);

-- Policy: DELETE - Author OR profile wall owner can delete
CREATE POLICY "profile_wall_posts_delete_own_or_owner" ON public.profile_wall_posts
    FOR DELETE USING (
        auth.uid() = author_id 
        OR auth.uid() = profile_user_id
    );

-- Policy: God mode for admins
CREATE POLICY "god_mode_profile_wall_posts" ON public.profile_wall_posts
    FOR ALL USING (public.is_god_mode()) 
    WITH CHECK (public.is_god_mode());

-- ============================================================================
-- 4. CREATE LIKES TABLE FOR PROFILE WALL POSTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.profile_wall_post_likes (
    post_id UUID NOT NULL REFERENCES public.profile_wall_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    PRIMARY KEY (post_id, user_id)
);

-- Index for checking if user liked a post
CREATE INDEX IF NOT EXISTS idx_profile_wall_post_likes_user 
ON public.profile_wall_post_likes(user_id);

-- RLS for likes
ALTER TABLE public.profile_wall_post_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profile_wall_post_likes_select" ON public.profile_wall_post_likes
    FOR SELECT USING (TRUE);

CREATE POLICY "profile_wall_post_likes_insert" ON public.profile_wall_post_likes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "profile_wall_post_likes_delete" ON public.profile_wall_post_likes
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- 5. CREATE COMMENTS TABLE FOR PROFILE WALL POSTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.profile_wall_post_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES public.profile_wall_posts(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    CONSTRAINT profile_wall_post_comments_content_not_empty CHECK (LENGTH(TRIM(content)) > 0)
);

CREATE INDEX IF NOT EXISTS idx_profile_wall_post_comments_post 
ON public.profile_wall_post_comments(post_id, created_at ASC);

-- RLS for comments
ALTER TABLE public.profile_wall_post_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profile_wall_post_comments_select" ON public.profile_wall_post_comments
    FOR SELECT USING (TRUE);

CREATE POLICY "profile_wall_post_comments_insert" ON public.profile_wall_post_comments
    FOR INSERT WITH CHECK (
        auth.uid() = author_id
        AND EXISTS (
            SELECT 1 FROM public.community_members m
            WHERE m.community_id = community_id AND m.user_id = auth.uid() AND m.is_active = TRUE
        )
    );

CREATE POLICY "profile_wall_post_comments_delete" ON public.profile_wall_post_comments
    FOR DELETE USING (auth.uid() = author_id);

-- ============================================================================
-- 6. TRIGGER: Update likes_count on profile_wall_posts
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_profile_wall_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.profile_wall_posts
        SET likes_count = likes_count + 1
        WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.profile_wall_posts
        SET likes_count = likes_count - 1
        WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_profile_wall_post_likes_count ON public.profile_wall_post_likes;
CREATE TRIGGER trigger_profile_wall_post_likes_count
    AFTER INSERT OR DELETE ON public.profile_wall_post_likes
    FOR EACH ROW EXECUTE FUNCTION public.update_profile_wall_post_likes_count();

-- ============================================================================
-- 7. TRIGGER: updated_at timestamp
-- ============================================================================

DROP TRIGGER IF EXISTS set_profile_wall_posts_updated_at ON public.profile_wall_posts;
CREATE TRIGGER set_profile_wall_posts_updated_at
    BEFORE UPDATE ON public.profile_wall_posts
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

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

SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('profile_wall_posts', 'profile_wall_post_likes', 'profile_wall_post_comments');
