-- ============================================================================
-- PROJECT NEO - COMMUNITY WIZARD MIGRATION
-- Adds category and module_config to communities table
-- ============================================================================

-- Add category column for community type
ALTER TABLE public.communities 
ADD COLUMN IF NOT EXISTS category VARCHAR(50) DEFAULT 'custom';

-- Add module_config for toggling features
ALTER TABLE public.communities 
ADD COLUMN IF NOT EXISTS module_config JSONB DEFAULT '{
  "chat": true,
  "posts": true,
  "wiki": true,
  "polls": true,
  "quizzes": false,
  "voice": false,
  "rankings": true
}'::jsonb;

-- Add comments
COMMENT ON COLUMN public.communities.category IS 
    'Community type: amigos, rol, gamers, arte, custom';
COMMENT ON COLUMN public.communities.module_config IS 
    'JSON config for enabled modules: chat, posts, wiki, polls, quizzes, voice, rankings';

-- Index for category filtering
CREATE INDEX IF NOT EXISTS idx_communities_category ON public.communities(category);
