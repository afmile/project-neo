-- DEBUG QUERY: Verify chat_channels data
-- Run this in Supabase SQL Editor to check what's in the table

-- 1. Check all chat_channels regardless of RLS
SELECT 
    id,
    community_id,
    creator_id,
    title,
    description,
    member_count,
    is_pinned,
    created_at
FROM public.chat_channels
ORDER BY created_at DESC;

-- 2. Check if Neo Lobby exists
SELECT * FROM public.chat_channels WHERE title ILIKE '%lobby%';

-- 3. Check community_members for current user
SELECT 
    m.community_id,
    c.title as community_title,
    m.user_id,
    m.role,
    m.is_active
FROM public.community_members m
JOIN public.communities c ON c.id = m.community_id
WHERE m.user_id = auth.uid();

-- 4. Test the exact query from chatChannelsProvider
SELECT 
    id, 
    title, 
    description, 
    background_image_url, 
    member_count, 
    is_pinned
FROM chat_channels
WHERE community_id = (SELECT id FROM communities LIMIT 1)
ORDER BY is_pinned DESC, created_at DESC
LIMIT 5;
