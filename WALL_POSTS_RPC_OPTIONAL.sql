-- ============================================================================
-- WALL POSTS RPC FUNCTIONS (OPTIONAL)
-- ============================================================================
-- These functions atomically increment/decrement likes_count on wall_posts.
-- If these don't exist, the app will still work (fallback mode).

-- Function: increment_wall_post_likes
CREATE OR REPLACE FUNCTION increment_wall_post_likes(post_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE wall_posts 
  SET likes_count = likes_count + 1 
  WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: decrement_wall_post_likes
CREATE OR REPLACE FUNCTION decrement_wall_post_likes(post_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE wall_posts 
  SET likes_count = GREATEST(likes_count - 1, 0) 
  WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- RLS POLICIES FOR WALL_POSTS (verify these exist)
-- ============================================================================

-- Allow authenticated users to INSERT their own posts
-- CREATE POLICY "Users can insert own wall posts" ON wall_posts
-- FOR INSERT WITH CHECK (auth.uid() = author_id);

-- Allow authenticated users to DELETE their own posts
-- CREATE POLICY "Users can delete own wall posts" ON wall_posts
-- FOR DELETE USING (auth.uid() = author_id);

-- ============================================================================
-- VERIFY QUERIES
-- ============================================================================

-- Check if RPC functions exist:
-- SELECT proname FROM pg_proc WHERE proname LIKE '%wall_post%';

-- Test creating a post:
-- INSERT INTO wall_posts (community_id, author_id, content) 
-- VALUES ('community-uuid', 'user-uuid', 'Test post');

-- Test deleting your own post:
-- DELETE FROM wall_posts WHERE id = 'post-uuid' AND author_id = 'your-user-id';
