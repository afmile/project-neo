-- Migration: Add notification settings to community members
-- Date: 2025-12-27

-- 1. Add JSONB column for granular notification settings
-- Uses JSONB for flexibility and efficient indexing
ALTER TABLE public.community_members
ADD COLUMN IF NOT EXISTS notification_settings JSONB DEFAULT '{
  "enabled": true,
  "chat": true,
  "mentions": true,
  "announcements": true,
  "wall_posts": false,
  "reactions": true
}'::jsonb NOT NULL;

-- 2. Create GIN index for efficient querying of JSON keys
-- Allows queries like: WHERE notification_settings->>'enabled' = 'true'
CREATE INDEX IF NOT EXISTS idx_community_members_notification_settings 
ON public.community_members USING GIN (notification_settings);

-- 3. Add column comment
COMMENT ON COLUMN public.community_members.notification_settings IS 
'Stores granular notification preferences per user per community: enabled (master), chat, mentions, announcements, wall_posts, reactions';

-- 4. Notify PostgREST to reload schema
NOTIFY pgrst, 'reload schema';

-- ROLLBACK COMMAND (Run in SQL Editor if needed):
-- DROP INDEX IF EXISTS idx_community_members_notification_settings;
-- ALTER TABLE public.community_members DROP COLUMN IF EXISTS notification_settings;
