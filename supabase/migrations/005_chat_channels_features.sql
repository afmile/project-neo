-- ============================================================================
-- PROJECT NEO - CHAT CHANNELS ENHANCEMENT
-- Adds icon, voice, video, and projection features to chat_channels
-- ============================================================================

-- Add icon URL for room icon (1:1 square format)
ALTER TABLE public.chat_channels ADD COLUMN IF NOT EXISTS
  icon_url TEXT;

-- Add feature toggles for LiveKit integration (future)
ALTER TABLE public.chat_channels ADD COLUMN IF NOT EXISTS
  voice_enabled BOOLEAN DEFAULT FALSE NOT NULL;

ALTER TABLE public.chat_channels ADD COLUMN IF NOT EXISTS
  video_enabled BOOLEAN DEFAULT FALSE NOT NULL;

ALTER TABLE public.chat_channels ADD COLUMN IF NOT EXISTS
  projection_enabled BOOLEAN DEFAULT FALSE NOT NULL;

-- Comments for documentation
COMMENT ON COLUMN public.chat_channels.icon_url IS 
    'Room icon in 1:1 square format for display in lists';
COMMENT ON COLUMN public.chat_channels.voice_enabled IS 
    'If TRUE, voice chat is enabled for this room (LiveKit)';
COMMENT ON COLUMN public.chat_channels.video_enabled IS 
    'If TRUE, video chat is enabled for this room (LiveKit)';
COMMENT ON COLUMN public.chat_channels.projection_enabled IS 
    'If TRUE, screen projection/sharing is enabled for this room (LiveKit)';
