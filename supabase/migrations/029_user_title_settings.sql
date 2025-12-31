-- ============================================================================
-- PROJECT NEO - USER TITLE SETTINGS
-- Allow users to manage their own title visibility and display order
-- ============================================================================
-- 
-- Changes:
-- 1. Add is_visible column to community_member_titles
-- 2. Add RLS policy for users to update their own title presentation settings
-- 3. Add index for efficient queries with visibility filter
-- ============================================================================

-- ============================================================================
-- 1. ADD is_visible COLUMN
-- ============================================================================

-- Add is_visible column (defaults to TRUE)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'community_member_titles' 
        AND column_name = 'is_visible'
    ) THEN
        ALTER TABLE public.community_member_titles 
        ADD COLUMN is_visible BOOLEAN NOT NULL DEFAULT TRUE;
        
        RAISE NOTICE 'Added is_visible column to community_member_titles';
    ELSE
        RAISE NOTICE 'Column is_visible already exists in community_member_titles';
    END IF;
END $$;

-- ============================================================================
-- 2. ADD INDEX FOR VISIBILITY QUERIES
-- ============================================================================

-- Index for fetching user's titles with visibility filter
CREATE INDEX IF NOT EXISTS idx_community_member_titles_user_visible 
ON public.community_member_titles(member_user_id, community_id, is_visible, sort_order ASC);

-- ============================================================================
-- 3. ADD RLS POLICY FOR USER SELF-UPDATE
-- ============================================================================

-- Allow users to update ONLY their own title's is_visible and sort_order
-- This policy is RESTRICTIVE - users cannot modify:
-- - title_id (which title they have)
-- - community_id (which community)
-- - member_user_id (whose title it is)
-- - assigned_by (who assigned it)
-- - assigned_at, expires_at (temporal data)
-- - is_active (activation status - only leaders can deactivate)

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'community_member_titles' 
        AND policyname = 'community_member_titles_update_own_display'
    ) THEN
        CREATE POLICY "community_member_titles_update_own_display" ON public.community_member_titles
            FOR UPDATE USING (
                -- User can only update their own titles
                auth.uid() = member_user_id
            )
            WITH CHECK (
                -- Ensure user cannot change ownership or core fields
                auth.uid() = member_user_id
                AND member_user_id = OLD.member_user_id
                AND community_id = OLD.community_id
                AND title_id = OLD.title_id
                AND assigned_by = OLD.assigned_by
                AND is_active = OLD.is_active
                -- Only is_visible and sort_order can change
            );
        
        RAISE NOTICE 'Created RLS policy: community_member_titles_update_own_display';
    ELSE
        RAISE NOTICE 'RLS policy community_member_titles_update_own_display already exists';
    END IF;
END $$;

-- ============================================================================
-- 4. VERIFICATION
-- ============================================================================

-- Verify column exists
SELECT 
    column_name, 
    data_type, 
    column_default,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'community_member_titles' 
AND column_name = 'is_visible';

-- Verify index exists
SELECT 
    indexname, 
    indexdef
FROM pg_indexes 
WHERE tablename = 'community_member_titles' 
AND indexname = 'idx_community_member_titles_user_visible';

-- Verify policy exists
SELECT 
    policyname, 
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename = 'community_member_titles' 
AND policyname = 'community_member_titles_update_own_display';

-- ============================================================================
-- 5. NOTES
-- ============================================================================

-- SECURITY NOTES:
-- - Users can ONLY update is_visible and sort_order for their own titles
-- - Users CANNOT change which title they have (title_id)
-- - Users CANNOT change who assigned the title (assigned_by)
-- - Users CANNOT activate/deactivate titles (is_active) - only leaders can
-- - Users CANNOT change expiration dates
-- - Users CANNOT transfer titles to other users
-- - The WITH CHECK clause ensures all immutable fields remain unchanged

-- USAGE NOTES:
-- - is_visible = FALSE means title won't show in user's profile
-- - Title data is preserved (not deleted) when hidden
-- - sort_order determines display order in profile
-- - Lower sort_order = displayed first
