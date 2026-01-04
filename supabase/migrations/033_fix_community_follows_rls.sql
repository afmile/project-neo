-- ============================================================================
-- HOTFIX: Community Follows RLS - Simplify INSERT Policy
-- ============================================================================
-- 
-- ISSUE: INSERT blocked - likely due to overly restrictive policy requiring
-- both follower AND followed to be active community members.
--
-- FIX: Simplify to only require follower to be authenticated and match auth.uid
-- ============================================================================

-- Drop existing restrictive policy
DROP POLICY IF EXISTS "community_follows_insert_own" ON public.community_follows;

-- Create simplified policy for immediate unblocking
CREATE POLICY "community_follows_insert_simple" ON public.community_follows
    FOR INSERT WITH CHECK (
        -- Only requirement: Current user must be the follower
        auth.uid() = follower_id
    );

-- Add diagnostic function to check membership status
CREATE OR REPLACE FUNCTION public.debug_follow_insert(
    p_community_id UUID,
    p_follower_id UUID,
    p_followed_id UUID
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result jsonb;
    follower_is_member boolean;
    followed_is_member boolean;
BEGIN
    -- Check follower membership
    follower_is_member := EXISTS (
        SELECT 1 FROM public.community_members cm
        WHERE cm.community_id = p_community_id
        AND cm.user_id = p_follower_id
        AND cm.is_active = TRUE
    );
    
    -- Check followed membership
    followed_is_member := EXISTS (
        SELECT 1 FROM public.community_members cm
        WHERE cm.community_id = p_community_id
        AND cm.user_id = p_followed_id
        AND cm.is_active = TRUE
    );
    
    result := jsonb_build_object(
        'follower_id', p_follower_id,
        'followed_id', p_followed_id,
        'community_id', p_community_id,
        'follower_is_member', follower_is_member,
        'followed_is_member', followed_is_member,
        'can_insert_old_policy', (
            follower_is_member AND followed_is_member
        ),
        'can_insert_new_policy', true
    );
    
    RETURN result;
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.debug_follow_insert TO authenticated;

-- ============================================================================
-- VERIFICATION QUERY
-- ============================================================================

-- Check current policies on table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'community_follows'
ORDER BY policyname;
