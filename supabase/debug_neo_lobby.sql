-- ============================================================================
-- DIAGNOSTIC QUERIES - Neo Lobby Not Appearing in Home VIVO
-- Run these queries in Supabase SQL Editor to diagnose the issue
-- ============================================================================

-- ============================================================================
-- 1. VERIFY NEO LOBBY EXISTS
-- ============================================================================
SELECT 
    id,
    community_id,
    creator_id,
    title,
    description,
    member_count,
    is_pinned,
    voice_enabled,
    video_enabled,
    projection_enabled,
    created_at
FROM chat_channels
WHERE title ILIKE '%lobby%'
ORDER BY created_at DESC;

-- Expected: Should return at least 1 row for "Neo Lobby"

-- ============================================================================
-- 2. CHECK YOUR CURRENT USER ID
-- ============================================================================
SELECT auth.uid() as my_user_id;

-- Copy this UUID for next queries

-- ============================================================================
-- 3. CHECK IF YOU'RE A MEMBER OF THE COMMUNITY
-- ============================================================================
-- Replace 'USER_ID_HERE' with the UUID from query #2
-- Replace 'COMMUNITY_ID_HERE' with the community_id from Neo Lobby (query #1)

SELECT 
    cm.user_id,
    cm.community_id,
    cm.role,
    cm.is_active,
    cm.nickname,
    c.title as community_name
FROM community_members cm
JOIN communities c ON c.id = cm.community_id
WHERE cm.user_id = auth.uid()  -- This should work automatically
  AND cm.community_id = 'COMMUNITY_ID_HERE';  -- Replace with actual ID

-- Expected: 1 row with is_active = true

-- ============================================================================
-- 4. TEST THE EXACT QUERY FROM HOME VIVO PROVIDER
-- ============================================================================
-- Replace 'COMMUNITY_ID_HERE' with the community_id from Neo Lobby

SELECT 
    id, 
    title, 
    description, 
    background_image_url, 
    member_count, 
    is_pinned
FROM chat_channels
WHERE community_id = 'COMMUNITY_ID_HERE'  -- Replace with actual ID
ORDER BY is_pinned DESC, created_at DESC
LIMIT 5;

-- Expected: Should return Neo Lobby and other channels
-- If this returns empty, it's an RLS issue
-- If this returns data, it's a Flutter/provider issue

-- ============================================================================
-- 5. TEST QUERY WITH RLS DISABLED (service_role)
-- ============================================================================
-- Run this in Supabase Dashboard with "Show row level security" toggle OFF
-- OR use service_role connection

SELECT 
    id, 
    title, 
    description, 
    community_id,
    creator_id,
    member_count, 
    is_pinned
FROM chat_channels
ORDER BY created_at DESC;

-- This should show ALL channels regardless of RLS
-- If Neo Lobby appears here but not in query #4, it's definitely RLS

-- ============================================================================
-- 6. CHECK RLS POLICIES ON chat_channels
-- ============================================================================
SELECT 
    policyname,
    cmd,
    qual::text as using_check,
    with_check::text
FROM pg_policies
WHERE tablename = 'chat_channels'
ORDER BY policyname;

-- Look for:
-- - chat_channels_select_member should reference community_members (not memberships)
-- - Should check is_active = true

-- ============================================================================
-- 7. VERIFY NO POLICIES REFERENCE 'owner_id'
-- ============================================================================
SELECT 
    policyname,
    cmd,
    qual::text as using_check,
    with_check::text
FROM pg_policies
WHERE tablename = 'chat_channels'
  AND (qual::text LIKE '%owner_id%' OR with_check::text LIKE '%owner_id%');

-- Expected: 0 rows (all should use creator_id)

-- ============================================================================
-- DIAGNOSIS GUIDE
-- ============================================================================

/*
CASE 1: Query #1 returns empty
  → Neo Lobby doesn't exist in database
  → Need to create it or import data

CASE 2: Query #1 returns data, Query #3 returns empty
  → You're not a member of the community
  → Need to join the community first

CASE 3: Query #1 returns data, Query #3 returns data, Query #4 returns empty
  → RLS is blocking the query
  → Check policies in Query #6
  → Apply migration 021 if not done yet

CASE 4: Query #4 returns data but Flutter shows empty
  → Provider caching or Flutter issue
  → Check Flutter logs for errors
  → Verify provider is actually executing

CASE 5: Query #7 returns rows
  → Migration 021 not applied
  → Policies still reference owner_id instead of creator_id
*/
