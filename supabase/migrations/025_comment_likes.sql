-- ============================================================================
-- PROJECT NEO - COMMENT LIKES TABLES
-- Tables for tracking likes on wall post comments
-- ============================================================================

-- ============================================================================
-- 1. WALL_POST_COMMENT_LIKES (for community wall comments)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.wall_post_comment_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    comment_id UUID NOT NULL REFERENCES public.wall_post_comments(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    CONSTRAINT wall_post_comment_likes_unique UNIQUE (comment_id, user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_wall_post_comment_likes_comment 
ON public.wall_post_comment_likes(comment_id);

CREATE INDEX IF NOT EXISTS idx_wall_post_comment_likes_user 
ON public.wall_post_comment_likes(user_id);

-- RLS
ALTER TABLE public.wall_post_comment_likes ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'wall_post_comment_likes' 
        AND policyname = 'wall_post_comment_likes_select_public'
    ) THEN
        CREATE POLICY "wall_post_comment_likes_select_public" ON public.wall_post_comment_likes
            FOR SELECT USING (TRUE);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'wall_post_comment_likes' 
        AND policyname = 'wall_post_comment_likes_insert_auth'
    ) THEN
        CREATE POLICY "wall_post_comment_likes_insert_auth" ON public.wall_post_comment_likes
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
        WHERE tablename = 'wall_post_comment_likes' 
        AND policyname = 'wall_post_comment_likes_delete_own'
    ) THEN
        CREATE POLICY "wall_post_comment_likes_delete_own" ON public.wall_post_comment_likes
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Grants
GRANT ALL ON public.wall_post_comment_likes TO authenticated;
GRANT SELECT ON public.wall_post_comment_likes TO anon;

-- ============================================================================
-- 2. PROFILE_WALL_POST_COMMENT_LIKES (for profile wall comments)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.profile_wall_post_comment_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    comment_id UUID NOT NULL REFERENCES public.profile_wall_post_comments(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    CONSTRAINT profile_wall_post_comment_likes_unique UNIQUE (comment_id, user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_profile_wall_post_comment_likes_comment 
ON public.profile_wall_post_comment_likes(comment_id);

CREATE INDEX IF NOT EXISTS idx_profile_wall_post_comment_likes_user 
ON public.profile_wall_post_comment_likes(user_id);

-- RLS
ALTER TABLE public.profile_wall_post_comment_likes ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profile_wall_post_comment_likes' 
        AND policyname = 'profile_wall_post_comment_likes_select_public'
    ) THEN
        CREATE POLICY "profile_wall_post_comment_likes_select_public" ON public.profile_wall_post_comment_likes
            FOR SELECT USING (TRUE);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profile_wall_post_comment_likes' 
        AND policyname = 'profile_wall_post_comment_likes_insert_auth'
    ) THEN
        CREATE POLICY "profile_wall_post_comment_likes_insert_auth" ON public.profile_wall_post_comment_likes
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
        WHERE tablename = 'profile_wall_post_comment_likes' 
        AND policyname = 'profile_wall_post_comment_likes_delete_own'
    ) THEN
        CREATE POLICY "profile_wall_post_comment_likes_delete_own" ON public.profile_wall_post_comment_likes
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Grants
GRANT ALL ON public.profile_wall_post_comment_likes TO authenticated;
GRANT SELECT ON public.profile_wall_post_comment_likes TO anon;
