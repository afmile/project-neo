-- Migration: Profile Header Data Function
-- Adds staff role columns and creates function to fetch profile header data

-- ============================================
-- 1. Add staff role columns to community_members
-- ============================================

ALTER TABLE community_members 
  ADD COLUMN IF NOT EXISTS is_leader BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS is_moderator BOOLEAN DEFAULT false;

-- Update existing community owners/leaders as is_leader
UPDATE community_members
SET is_leader = true
WHERE role IN ('owner', 'leader')
  AND is_active = true;

-- ============================================
-- 2. Create function to get profile header data
-- ============================================

CREATE OR REPLACE FUNCTION get_profile_header_data(
  p_user_id UUID,
  p_community_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_staff_role TEXT;
  v_titles JSON;
  v_followers_count INT;
  v_following_count INT;
  v_result JSON;
BEGIN
  -- 1. Obtain staff role
  SELECT 
    CASE 
      WHEN cm.is_leader THEN 'LÍDER'
      WHEN cm.is_moderator THEN 'MOD'
      ELSE NULL
    END
  INTO v_staff_role
  FROM community_members cm
  WHERE cm.user_id = p_user_id 
    AND cm.community_id = p_community_id
    AND cm.is_active = true;

  -- 2. Get custom titles (max 3, ordered by priority)
  SELECT json_agg(t.*)
  INTO v_titles
  FROM (
    SELECT 
      ct.text,
      ct.text_color,
      ct.background_color,
      ct.priority
    FROM community_titles ct
    JOIN user_community_titles uct ON ct.id = uct.title_id
    WHERE uct.user_id = p_user_id 
      AND ct.community_id = p_community_id
      AND uct.is_active = true
    ORDER BY ct.priority ASC
    LIMIT 3
  ) t;

  -- 3. Count followers
  SELECT COUNT(*)
  INTO v_followers_count
  FROM community_follows cf
  WHERE cf.followed_id = p_user_id
    AND cf.community_id = p_community_id
    AND cf.is_active = true;

  -- 4. Count following
  SELECT COUNT(*)
  INTO v_following_count
  FROM community_follows cf
  WHERE cf.follower_id = p_user_id
    AND cf.community_id = p_community_id
    AND cf.is_active = true;

  -- 5. Build JSON response
  v_result := json_build_object(
    'staff_role', v_staff_role,
    'titles', COALESCE(v_titles, '[]'::json),
    'followers_count', COALESCE(v_followers_count, 0),
    'following_count', COALESCE(v_following_count, 0)
  );

  RETURN v_result;
END;
$$;

-- ============================================
-- 3. Grant permissions
-- ============================================

GRANT EXECUTE ON FUNCTION get_profile_header_data(UUID, UUID) TO authenticated;

-- ============================================
-- 4. Add comments for documentation
-- ============================================

COMMENT ON FUNCTION get_profile_header_data(UUID, UUID) IS 
'Returns profile header data including staff role, titles, and follower counts';

COMMENT ON COLUMN community_members.is_leader IS 
'True if user is the community leader (creator or promoted)';

COMMENT ON COLUMN community_members.is_moderator IS 
'True if user is a community moderator';
