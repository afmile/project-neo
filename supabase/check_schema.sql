-- ============================================================================
-- EMERGENCY DIAGNOSTIC - Check ACTUAL schema of chat_channels
-- ============================================================================

-- 1. See ALL columns in chat_channels table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'chat_channels'
ORDER BY ordinal_position;

-- 2. Simple query without creator_id
SELECT * FROM chat_channels LIMIT 3;

-- 3. Check if there's an 'owner_id' column instead
SELECT 
    column_name
FROM information_schema.columns
WHERE table_name = 'chat_channels'
  AND column_name IN ('creator_id', 'owner_id', 'user_id', 'author_id');
