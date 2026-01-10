-- ============================================================================
-- DATABASE VERIFICATION SCRIPT
-- Run this in Supabase SQL Editor to check current schema state
-- ============================================================================

-- 1. Check which post tables exist
SELECT 
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('wall_posts', 'community_posts', 'profile_wall_posts')
ORDER BY table_name;

-- 2. Check if community_posts_view exists (it's a view, not a table)
SELECT 
    table_name AS view_name,
    view_definition
FROM information_schema.views
WHERE table_schema = 'public'
AND table_name LIKE '%community_posts%';

-- 3. Check wall_posts structure (should have community_id column)
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'wall_posts'
ORDER BY ordinal_position;

-- 4. Check wall_post_comments structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'wall_post_comments'
ORDER BY ordinal_position;
