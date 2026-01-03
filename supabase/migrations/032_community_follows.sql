-- ============================================================================
-- PROJECT NEO - COMMUNITY FOLLOWS SYSTEM
-- Community-scoped user following
-- ============================================================================
-- 
-- This table enables users to follow each other within communities.
-- Required for mutual follow detection before friendship requests.
-- ============================================================================

-- ============================================================================
-- 1. CREATE COMMUNITY_FOLLOWS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.community_follows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Community scope
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    
    -- Follow relationship
    follower_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    followed_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    
    -- Active status (for soft deletes)
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT community_follows_no_self 
        CHECK (follower_id != followed_id),
    CONSTRAINT community_follows_unique 
        UNIQUE (community_id, follower_id, followed_id)
);

-- ============================================================================
-- 2. CREATE INDEXES
-- ============================================================================

-- Find followers of a user
CREATE INDEX IF NOT EXISTS idx_community_follows_followed
ON public.community_follows(community_id, followed_id, is_active)
WHERE is_active = TRUE;

-- Find who a user follows
CREATE INDEX IF NOT EXISTS idx_community_follows_follower
ON public.community_follows(community_id, follower_id, is_active)
WHERE is_active = TRUE;

-- Check mutual follow quickly
CREATE INDEX IF NOT EXISTS idx_community_follows_mutual
ON public.community_follows(community_id, follower_id, followed_id, is_active)
WHERE is_active = TRUE;

-- ============================================================================
-- 3. ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE public.community_follows ENABLE ROW LEVEL SECURITY;

-- SELECT: Anyone can see follows in communities they're members of
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'community_follows' 
        AND policyname = 'community_follows_select_members'
    ) THEN
        CREATE POLICY "community_follows_select_members" ON public.community_follows
            FOR SELECT USING (
                EXISTS (
                    SELECT 1 FROM public.community_members cm
                    WHERE cm.community_id = community_follows.community_id
                    AND cm.user_id = auth.uid()
                    AND cm.is_active = TRUE
                )
            );
    END IF;
END $$;

-- INSERT: User must be the follower and a community member
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'community_follows' 
        AND policyname = 'community_follows_insert_own'
    ) THEN
        CREATE POLICY "community_follows_insert_own" ON public.community_follows
            FOR INSERT WITH CHECK (
                auth.uid() = follower_id
                AND EXISTS (
                    SELECT 1 FROM public.community_members cm
                    WHERE cm.community_id = community_follows.community_id
                    AND cm.user_id = auth.uid()
                    AND cm.is_active = TRUE
                )
                -- Target user must also be a member
                AND EXISTS (
                    SELECT 1 FROM public.community_members cm
                    WHERE cm.community_id = community_follows.community_id
                    AND cm.user_id = community_follows.followed_id
                    AND cm.is_active = TRUE
                )
            );
    END IF;
END $$;

-- UPDATE: User can only toggle their own follows
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'community_follows' 
        AND policyname = 'community_follows_update_own'
    ) THEN
        CREATE POLICY "community_follows_update_own" ON public.community_follows
            FOR UPDATE USING (
                auth.uid() = follower_id
            ) WITH CHECK (
                auth.uid() = follower_id
            );
    END IF;
END $$;

-- DELETE: User can only delete their own follows
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'community_follows' 
        AND policyname = 'community_follows_delete_own'
    ) THEN
        CREATE POLICY "community_follows_delete_own" ON public.community_follows
            FOR DELETE USING (
                auth.uid() = follower_id
            );
    END IF;
END $$;

-- God mode policy
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'community_follows' 
        AND policyname = 'god_mode_community_follows'
    ) THEN
        CREATE POLICY "god_mode_community_follows" ON public.community_follows
            FOR ALL USING (public.is_god_mode()) 
            WITH CHECK (public.is_god_mode());
    END IF;
END $$;

-- ============================================================================
-- 4. HELPER FUNCTIONS
-- ============================================================================

-- Function to check if user A follows user B
CREATE OR REPLACE FUNCTION public.is_following(
    p_community_id UUID,
    p_follower_id UUID,
    p_followed_id UUID
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.community_follows
        WHERE community_id = p_community_id
        AND follower_id = p_follower_id
        AND followed_id = p_followed_id
        AND is_active = TRUE
    );
END;
$$;

-- Function to count followers
CREATE OR REPLACE FUNCTION public.count_followers(
    p_community_id UUID,
    p_user_id UUID
) RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)::INTEGER
        FROM public.community_follows
        WHERE community_id = p_community_id
        AND followed_id = p_user_id
        AND is_active = TRUE
    );
END;
$$;

-- Function to count following
CREATE OR REPLACE FUNCTION public.count_following(
    p_community_id UUID,
    p_user_id UUID
) RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)::INTEGER
        FROM public.community_follows
        WHERE community_id = p_community_id
        AND follower_id = p_user_id
        AND is_active = TRUE
    );
END;
$$;

-- ============================================================================
-- 5. TRIGGERS FOR NOTIFICATIONS
-- ============================================================================

-- Create notification when someone follows you
CREATE OR REPLACE FUNCTION public.notify_on_follow()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Only notify on new active follows (not unfollows/re-follows)
    IF NEW.is_active = TRUE AND (OLD IS NULL OR OLD.is_active = FALSE) THEN
        INSERT INTO public.community_notifications (
            community_id,
            recipient_id,
            actor_id,
            type,
            entity_type,
            entity_id,
            title,
            body,
            data
        ) VALUES (
            NEW.community_id,
            NEW.followed_id,
            NEW.follower_id,
            'follow',
            'community_follow',
            NEW.id::TEXT,
            'Nuevo seguidor',
            (SELECT username FROM public.users_global WHERE id = NEW.follower_id) || ' te ha seguido',
            jsonb_build_object('follower_id', NEW.follower_id)
        );
    END IF;
    
    RETURN NEW;
END;
$$;

-- Attach trigger
DROP TRIGGER IF EXISTS trigger_notify_on_follow ON public.community_follows;
CREATE TRIGGER trigger_notify_on_follow
    AFTER INSERT OR UPDATE ON public.community_follows
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_on_follow();

-- ============================================================================
-- 6. GRANTS
-- ============================================================================

GRANT ALL ON public.community_follows TO authenticated;
GRANT SELECT ON public.community_follows TO anon;

-- ============================================================================
-- 7. VERIFICATION
-- ============================================================================

SELECT 'community_follows' AS table_name, COUNT(*) AS column_count
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'community_follows';
