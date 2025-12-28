-- ============================================================================
-- 022_add_missing_creator_id_to_chat_channels.sql
-- Adds creator_id column if it doesn't exist (migration 004 may not have run)
-- ============================================================================

-- Check current schema first - uncomment to verify
-- SELECT column_name, data_type 
-- FROM information_schema.columns 
-- WHERE table_name = 'chat_channels'
-- ORDER BY ordinal_position;

-- Add creator_id if it doesn't exist
ALTER TABLE public.chat_channels 
ADD COLUMN IF NOT EXISTS creator_id UUID REFERENCES public.users_global(id) ON DELETE SET NULL;

-- If the column already exists but without the FK constraint, add it
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'chat_channels_creator_id_fkey'
          AND table_name = 'chat_channels'
    ) THEN
        ALTER TABLE public.chat_channels
        ADD CONSTRAINT chat_channels_creator_id_fkey
        FOREIGN KEY (creator_id) REFERENCES public.users_global(id) ON DELETE SET NULL;
    END IF;
END $$;

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_chat_channels_creator 
ON public.chat_channels(creator_id);

-- Update existing rows to set a creator_id (optional - use community owner as fallback)
UPDATE public.chat_channels cc
SET creator_id = c.owner_id
FROM public.communities c
WHERE cc.community_id = c.id
  AND cc.creator_id IS NULL;

-- Reload schema
NOTIFY pgrst, 'reload schema';
