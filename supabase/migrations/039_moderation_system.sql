-- Migration: 039_moderation_system.sql
-- Description: Adds banning capabilities to community members

-- Add is_banned column
ALTER TABLE public.community_members 
ADD COLUMN IF NOT EXISTS is_banned BOOLEAN DEFAULT FALSE;

-- Add banned_at column
ALTER TABLE public.community_members 
ADD COLUMN IF NOT EXISTS banned_at TIMESTAMP WITH TIME ZONE;

-- Create index for faster banned user lookups
CREATE INDEX IF NOT EXISTS idx_community_members_banned 
ON public.community_members(community_id, is_banned);

-- Comment
COMMENT ON COLUMN public.community_members.is_banned IS 'Indicates if the member is banned from the community';
COMMENT ON COLUMN public.community_members.banned_at IS 'Timestamp when the member was banned';
