-- ============================================================================
-- PROJECT NEO - FRIENDSHIP SYSTEM (Phase 1)
-- Community-scoped friendship requests and relationships
-- ============================================================================
-- 
-- Architecture:
-- - friendship_requests: Stores friend requests within a community
-- - Friends are users who have both followed each other AND accepted friendship
-- 
-- Flow:
-- 1. User A follows User B
-- 2. User B follows User A (mutual follow)
-- 3. Either user can send a friendship request
-- 4. Recipient accepts/rejects via notification
-- 5. If accepted: friendship established
-- 6. If rejected: remains mutual follow, request closed
-- ============================================================================

-- ============================================================================
-- 1. CREATE FRIENDSHIP_REQUESTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.friendship_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Community scope (friendships are per-community)
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    
    -- Request parties
    requester_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    
    -- Status: pending, accepted, rejected
    status TEXT NOT NULL DEFAULT 'pending',
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    responded_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT friendship_requests_status_valid 
        CHECK (status IN ('pending', 'accepted', 'rejected')),
    CONSTRAINT friendship_requests_no_self 
        CHECK (requester_id != recipient_id),
    CONSTRAINT friendship_requests_unique 
        UNIQUE (community_id, requester_id, recipient_id)
);

-- ============================================================================
-- 2. CREATE INDEXES
-- ============================================================================

-- Find pending requests for a user (notifications)
CREATE INDEX IF NOT EXISTS idx_friendship_requests_pending
ON public.friendship_requests(recipient_id, community_id, status)
WHERE status = 'pending';

-- Find all requests involving a user
CREATE INDEX IF NOT EXISTS idx_friendship_requests_user
ON public.friendship_requests(community_id, requester_id);

CREATE INDEX IF NOT EXISTS idx_friendship_requests_recipient
ON public.friendship_requests(community_id, recipient_id);

-- Find accepted friendships (for friend lists)
CREATE INDEX IF NOT EXISTS idx_friendship_requests_accepted
ON public.friendship_requests(community_id, status)
WHERE status = 'accepted';

-- ============================================================================
-- 3. ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE public.friendship_requests ENABLE ROW LEVEL SECURITY;

-- SELECT: Users can see their own requests (sent or received)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'friendship_requests' 
        AND policyname = 'friendship_requests_select_own'
    ) THEN
        CREATE POLICY "friendship_requests_select_own" ON public.friendship_requests
            FOR SELECT USING (
                auth.uid() = requester_id OR auth.uid() = recipient_id
            );
    END IF;
END $$;

-- INSERT: User must be the requester and must be a community member
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'friendship_requests' 
        AND policyname = 'friendship_requests_insert_requester'
    ) THEN
        CREATE POLICY "friendship_requests_insert_requester" ON public.friendship_requests
            FOR INSERT WITH CHECK (
                auth.uid() = requester_id
                AND EXISTS (
                    SELECT 1 FROM public.community_members cm
                    WHERE cm.community_id = friendship_requests.community_id
                    AND cm.user_id = auth.uid()
                    AND cm.is_active = TRUE
                )
            );
    END IF;
END $$;

-- UPDATE: Only recipient can update (accept/reject)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'friendship_requests' 
        AND policyname = 'friendship_requests_update_recipient'
    ) THEN
        CREATE POLICY "friendship_requests_update_recipient" ON public.friendship_requests
            FOR UPDATE USING (
                auth.uid() = recipient_id
            ) WITH CHECK (
                auth.uid() = recipient_id
            );
    END IF;
END $$;

-- DELETE: Either party can delete (only pending requests)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'friendship_requests' 
        AND policyname = 'friendship_requests_delete_own'
    ) THEN
        CREATE POLICY "friendship_requests_delete_own" ON public.friendship_requests
            FOR DELETE USING (
                (auth.uid() = requester_id OR auth.uid() = recipient_id)
                AND status = 'pending'
            );
    END IF;
END $$;

-- God mode policy
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'friendship_requests' 
        AND policyname = 'god_mode_friendship_requests'
    ) THEN
        CREATE POLICY "god_mode_friendship_requests" ON public.friendship_requests
            FOR ALL USING (public.is_god_mode()) 
            WITH CHECK (public.is_god_mode());
    END IF;
END $$;

-- ============================================================================
-- 4. HELPER FUNCTIONS
-- ============================================================================

-- Function to check if two users are friends in a community
CREATE OR REPLACE FUNCTION public.are_friends(
    p_community_id UUID,
    p_user_a UUID,
    p_user_b UUID
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.friendship_requests
        WHERE community_id = p_community_id
        AND status = 'accepted'
        AND (
            (requester_id = p_user_a AND recipient_id = p_user_b)
            OR (requester_id = p_user_b AND recipient_id = p_user_a)
        )
    );
END;
$$;

-- Function to check if users have mutual follow
CREATE OR REPLACE FUNCTION public.have_mutual_follow(
    p_community_id UUID,
    p_user_a UUID,
    p_user_b UUID
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN (
        -- A follows B
        EXISTS (
            SELECT 1 FROM public.community_follows
            WHERE community_id = p_community_id
            AND follower_id = p_user_a
            AND followed_id = p_user_b
            AND is_active = TRUE
        )
        AND
        -- B follows A
        EXISTS (
            SELECT 1 FROM public.community_follows
            WHERE community_id = p_community_id
            AND follower_id = p_user_b
            AND followed_id = p_user_a
            AND is_active = TRUE
        )
    );
END;
$$;

-- ============================================================================
-- 5. GRANTS
-- ============================================================================

GRANT ALL ON public.friendship_requests TO authenticated;
GRANT SELECT ON public.friendship_requests TO anon;

-- ============================================================================
-- 6. VERIFICATION
-- ============================================================================

SELECT 'friendship_requests' AS table_name, COUNT(*) AS column_count
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'friendship_requests';
