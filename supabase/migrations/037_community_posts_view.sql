-- ============================================================================
-- 037_COMMUNITY_POSTS_VIEW.sql
--
-- Creates a view that joins community posts with community members
-- to correctly display community-specific nicknames and avatars.
-- ============================================================================

-- 1. Create the view
CREATE OR REPLACE VIEW public.community_posts_view AS
SELECT 
    cp.*,
    jsonb_build_object(
        'username', COALESCE(cm.nickname, ug.username),
        'avatar_global_url', COALESCE(cm.avatar_url, ug.avatar_global_url),
        'id', cp.author_id
    ) as author
FROM 
    public.community_posts cp
JOIN 
    public.users_global ug ON cp.author_id = ug.id
LEFT JOIN 
    public.community_members cm ON cp.author_id = cm.user_id AND cp.community_id = cm.community_id;

-- 2. Grant permissions
GRANT SELECT ON public.community_posts_view TO authenticated;
GRANT SELECT ON public.community_posts_view TO anon;

-- 3. Comment
COMMENT ON VIEW public.community_posts_view IS 
    'View that enriches posts with community-specific author profiles (nickname/avatar)';
