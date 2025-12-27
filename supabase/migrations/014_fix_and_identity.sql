-- ============================================================================
-- 014_FIX_AND_IDENTITY.sql
--
-- 1. Fix Foreign Keys (Repair PGRST200 Crash)
-- 2. Implement Persistent Identity (Local Profiles)
-- 3. Backfill Data
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. REPAIR FOREIGN KEYS
-- ----------------------------------------------------------------------------
-- Eliminate potentially broken or unnamed constraints from the rename
-- We use DO block to avoid errors if they don't exist by name, 
-- but explicit DROP CONSTRAINT IF EXISTS is safer if we know names.
-- Since names might be auto-generated like 'memberships_user_id_fkey', we try standard names.

ALTER TABLE public.community_members 
DROP CONSTRAINT IF EXISTS memberships_user_id_fkey,
DROP CONSTRAINT IF EXISTS memberships_community_id_fkey,
DROP CONSTRAINT IF EXISTS community_members_user_id_fkey,
DROP CONSTRAINT IF EXISTS community_members_community_id_fkey;

-- Re-establish explicit Foreign Keys with CASCADE to ensure clean relations
ALTER TABLE public.community_members
ADD CONSTRAINT community_members_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES public.users_global(id)
    ON DELETE CASCADE,
ADD CONSTRAINT community_members_community_id_fkey
    FOREIGN KEY (community_id)
    REFERENCES public.communities(id)
    ON DELETE CASCADE;

-- ----------------------------------------------------------------------------
-- 2. IMPLEMENT IDENTITY COLUMNS
-- ----------------------------------------------------------------------------
ALTER TABLE public.community_members
ADD COLUMN IF NOT EXISTS nickname TEXT,
ADD COLUMN IF NOT EXISTS avatar_url TEXT,
ADD COLUMN IF NOT EXISTS bio TEXT,
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE NOT NULL,
ADD COLUMN IF NOT EXISTS left_at TIMESTAMPTZ;

-- ----------------------------------------------------------------------------
-- 3. BACKFILL DATA (Populate Local Profiles)
-- ----------------------------------------------------------------------------
-- For every member, copy their current global profile to their local profile
-- Only if local profile is empty (to avoid overwriting if run multiple times)
UPDATE public.community_members cm
SET 
    nickname = ug.username,
    avatar_url = ug.avatar_global_url,
    bio = ug.bio
FROM public.users_global ug
WHERE cm.user_id = ug.id
  AND cm.nickname IS NULL;

-- ----------------------------------------------------------------------------
-- 4. RELOAD SCHEMA CACHE
-- ----------------------------------------------------------------------------
-- Necessary for Supabase API to recognize the new FK relations immediately
NOTIFY pgrst, 'reload config';
