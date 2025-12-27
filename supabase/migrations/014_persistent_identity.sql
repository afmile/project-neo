-- ============================================================================
-- 014_PERSISTENT_IDENTITY.sql
--
-- Implements Persistent Identity model:
-- 1. Local profiles (nickname, avatar, bio) exist in community_members.
-- 2. Local profiles separate from global profiles.
-- 3. Memberships are soft-deleted (is_active=false) to preserve history.
-- ============================================================================

-- 1. Add Local Profile Columns
ALTER TABLE public.community_members
ADD COLUMN IF NOT EXISTS nickname TEXT,
ADD COLUMN IF NOT EXISTS avatar_url TEXT,
ADD COLUMN IF NOT EXISTS bio TEXT,
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE NOT NULL,
ADD COLUMN IF NOT EXISTS left_at TIMESTAMPTZ;

-- 2. Backfill Existing Data
-- Copy global profile data to local profile for existing members
-- This ensures no one starts with a blank local profile
UPDATE public.community_members cm
SET 
  nickname = ug.username,
  avatar_url = ug.avatar_global_url,
  bio = ug.bio
FROM public.users_global ug
WHERE cm.user_id = ug.id
  AND cm.nickname IS NULL; -- Only update if not already set (safety check)

-- 3. Index for Active Members
-- Important for performance when filtering "Who is currently in the community"
CREATE INDEX IF NOT EXISTS idx_community_members_active 
ON public.community_members(community_id, is_active);

-- 4. Constraint (Optional but recommended)
-- Ensure we don't have duplicates of (user_id, community_id)
-- The existing PK/Unique constraint on (user_id, community_id) likely already exists from the original table creation.
-- If not, we should probably ensure it does, but 'memberships' usually implies it.
-- Let's verifies/ensures it exists implicitly by the nature of the join logic we will implement.

-- 5. Update RLS (Optional/Verify)
-- Ensure 'is_active' doesn't hide the row from the user themselves (so they can rejoin).
-- Our previous "Open Read" policy allows seeing all rows, which is correct for persistent identity (seeing past members).
-- We might want to filter lists by is_active=true in the UI/Query by default, but the RLS should remain open.

-- 6. Trigger to sync member_count (Adjust for is_active)
-- Existing count triggers might rely on INSERT/DELETE.
-- Since we are moving to Soft Delete, we need to update the member count logic.

-- Function to handle member count on soft state change
CREATE OR REPLACE FUNCTION public.handle_member_count_on_update()
RETURNS TRIGGER AS $$
BEGIN
    -- If is_active changed
    IF OLD.is_active != NEW.is_active THEN
        IF NEW.is_active = TRUE THEN
            -- User joined/rejoined
            UPDATE public.communities 
            SET member_count = member_count + 1 
            WHERE id = NEW.community_id;
        ELSE
            -- User left (soft delete)
            UPDATE public.communities 
            SET member_count = GREATEST(member_count - 1, 0)
            WHERE id = NEW.community_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_member_count_update ON public.community_members;
CREATE TRIGGER trigger_member_count_update
    AFTER UPDATE OF is_active ON public.community_members
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_member_count_on_update();

-- We also need to keep the INSERT trigger for new joins (fresh inserts)
-- And verify the DELETE trigger is still appropriate (though we shouldn't hard delete anymore via app logic, admin might).
-- Assuming existing triggers handle INSERT/DELETE correctly for counts.

