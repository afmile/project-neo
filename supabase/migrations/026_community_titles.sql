-- ============================================================================
-- PROJECT NEO - COMMUNITY TITLES (Amino-Style Tags)
-- User titles/tags assigned by community leaders to members
-- ============================================================================
-- 
-- Architecture:
-- - community_titles: Template/definition of titles per community
-- - community_member_titles: Assignment of titles to specific members
-- 
-- Features:
-- - Community-specific titles (each community has own set)
-- - Leader/Mod assignment only
-- - Priority-based ordering for display
-- - Style customization (color, icon)
-- - Optional expiration dates
-- - Soft delete support (is_active flag)
-- ============================================================================

-- ============================================================================
-- 1. CREATE COMMUNITY_TITLES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.community_titles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    slug TEXT,
    description TEXT,
    
    -- Style configuration stored as JSONB
    -- Example: {"bg": "#1337EC", "fg": "#FFFFFF", "icon": "star"}
    style JSONB NOT NULL DEFAULT '{}'::jsonb,
    
    -- Display priority (higher = shown first)
    priority INT NOT NULL DEFAULT 0,
    
    -- Active/inactive flag for soft delete
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    
    -- Audit fields
    created_by UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT community_titles_name_not_empty CHECK (LENGTH(TRIM(name)) > 0),
    CONSTRAINT community_titles_name_max_length CHECK (LENGTH(name) <= 50),
    CONSTRAINT community_titles_unique_name UNIQUE (community_id, name)
);

-- ============================================================================
-- 2. CREATE COMMUNITY_MEMBER_TITLES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.community_member_titles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    
    -- User who has this title
    member_user_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    
    -- The title being assigned
    title_id UUID NOT NULL REFERENCES public.community_titles(id) ON DELETE CASCADE,
    
    -- Who assigned this title
    assigned_by UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    
    -- When assigned and optional expiration
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    
    -- Active/inactive flag
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    
    -- Manual sort order (allows custom ordering beyond priority)
    sort_order INT NOT NULL DEFAULT 0,
    
    -- Constraints
    CONSTRAINT community_member_titles_unique UNIQUE (community_id, member_user_id, title_id)
);

-- ============================================================================
-- 3. CREATE INDEXES
-- ============================================================================

-- Fetch all titles for a community (for admin/selection UI)
CREATE INDEX IF NOT EXISTS idx_community_titles_community 
ON public.community_titles(community_id, is_active, priority DESC);

-- Lookup specific title
CREATE INDEX IF NOT EXISTS idx_community_titles_id 
ON public.community_titles(id) WHERE is_active = TRUE;

-- Fetch all assigned titles for a user in a community (most common query)
CREATE INDEX IF NOT EXISTS idx_community_member_titles_user 
ON public.community_member_titles(community_id, member_user_id, is_active);

-- Fetch all users with a specific title
CREATE INDEX IF NOT EXISTS idx_community_member_titles_title 
ON public.community_member_titles(community_id, title_id, is_active);

-- Sort by sort_order and assigned_at
CREATE INDEX IF NOT EXISTS idx_community_member_titles_sort 
ON public.community_member_titles(member_user_id, community_id, sort_order ASC, assigned_at DESC);

-- ============================================================================
-- 4. ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE public.community_titles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_member_titles ENABLE ROW LEVEL SECURITY;

-- ───────────────────────────────────────────────────────────────────────────
-- COMMUNITY_TITLES POLICIES
-- ───────────────────────────────────────────────────────────────────────────

-- SELECT: Members of the community can view titles
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'community_titles' 
        AND policyname = 'community_titles_select_members'
    ) THEN
        CREATE POLICY "community_titles_select_members" ON public.community_titles
            FOR SELECT USING (
                -- Community members can see titles
                EXISTS (
                    SELECT 1 FROM public.community_members cm
                    WHERE cm.community_id = community_titles.community_id
                    AND cm.user_id = auth.uid()
                    AND cm.is_active = TRUE
                )
            );
    END IF;
END $$;

-- INSERT: Only leaders/curators/mods can create titles
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'community_titles' 
        AND policyname = 'community_titles_insert_leaders'
    ) THEN
        CREATE POLICY "community_titles_insert_leaders" ON public.community_titles
            FOR INSERT WITH CHECK (
                auth.uid() = created_by
                AND EXISTS (
                    SELECT 1 FROM public.community_members cm
                    WHERE cm.community_id = community_titles.community_id
                    AND cm.user_id = auth.uid()
                    AND cm.role IN ('leader', 'curator', 'mod')
                    AND cm.is_active = TRUE
                )
            );
    END IF;
END $$;

-- UPDATE: Only leaders/curators/mods can update titles
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'community_titles' 
        AND policyname = 'community_titles_update_leaders'
    ) THEN
        CREATE POLICY "community_titles_update_leaders" ON public.community_titles
            FOR UPDATE USING (
                EXISTS (
                    SELECT 1 FROM public.community_members cm
                    WHERE cm.community_id = community_titles.community_id
                    AND cm.user_id = auth.uid()
                    AND cm.role IN ('leader', 'curator', 'mod')
                    AND cm.is_active = TRUE
                )
            );
    END IF;
END $$;

-- DELETE: Only leaders/curators/mods can delete titles
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'community_titles' 
        AND policyname = 'community_titles_delete_leaders'
    ) THEN
        CREATE POLICY "community_titles_delete_leaders" ON public.community_titles
            FOR DELETE USING (
                EXISTS (
                    SELECT 1 FROM public.community_members cm
                    WHERE cm.community_id = community_titles.community_id
                    AND cm.user_id = auth.uid()
                    AND cm.role IN ('leader', 'curator', 'mod')
                    AND cm.is_active = TRUE
                )
            );
    END IF;
END $$;

-- God mode policy
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'community_titles' 
        AND policyname = 'god_mode_community_titles'
    ) THEN
        CREATE POLICY "god_mode_community_titles" ON public.community_titles
            FOR ALL USING (public.is_god_mode()) 
            WITH CHECK (public.is_god_mode());
    END IF;
END $$;

-- ───────────────────────────────────────────────────────────────────────────
-- COMMUNITY_MEMBER_TITLES POLICIES
-- ───────────────────────────────────────────────────────────────────────────

-- SELECT: Members of the community can view title assignments
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'community_member_titles' 
        AND policyname = 'community_member_titles_select_members'
    ) THEN
        CREATE POLICY "community_member_titles_select_members" ON public.community_member_titles
            FOR SELECT USING (
                -- Community members can see assignments
                EXISTS (
                    SELECT 1 FROM public.community_members cm
                    WHERE cm.community_id = community_member_titles.community_id
                    AND cm.user_id = auth.uid()
                    AND cm.is_active = TRUE
                )
            );
    END IF;
END $$;

-- INSERT: Only leaders/curators/mods can assign titles
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'community_member_titles' 
        AND policyname = 'community_member_titles_insert_leaders'
    ) THEN
        CREATE POLICY "community_member_titles_insert_leaders" ON public.community_member_titles
            FOR INSERT WITH CHECK (
                auth.uid() = assigned_by
                AND EXISTS (
                    SELECT 1 FROM public.community_members cm
                    WHERE cm.community_id = community_member_titles.community_id
                    AND cm.user_id = auth.uid()
                    AND cm.role IN ('leader', 'curator', 'mod')
                    AND cm.is_active = TRUE
                )
            );
    END IF;
END $$;

-- UPDATE: Only leaders/curators/mods can update assignments
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'community_member_titles' 
        AND policyname = 'community_member_titles_update_leaders'
    ) THEN
        CREATE POLICY "community_member_titles_update_leaders" ON public.community_member_titles
            FOR UPDATE USING (
                EXISTS (
                    SELECT 1 FROM public.community_members cm
                    WHERE cm.community_id = community_member_titles.community_id
                    AND cm.user_id = auth.uid()
                    AND cm.role IN ('leader', 'curator', 'mod')
                    AND cm.is_active = TRUE
                )
            );
    END IF;
END $$;

-- DELETE: Only leaders/curators/mods can remove assignments
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'community_member_titles' 
        AND policyname = 'community_member_titles_delete_leaders'
    ) THEN
        CREATE POLICY "community_member_titles_delete_leaders" ON public.community_member_titles
            FOR DELETE USING (
                EXISTS (
                    SELECT 1 FROM public.community_members cm
                    WHERE cm.community_id = community_member_titles.community_id
                    AND cm.user_id = auth.uid()
                    AND cm.role IN ('leader', 'curator', 'mod')
                    AND cm.is_active = TRUE
                )
            );
    END IF;
END $$;

-- God mode policy
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'community_member_titles' 
        AND policyname = 'god_mode_community_member_titles'
    ) THEN
        CREATE POLICY "god_mode_community_member_titles" ON public.community_member_titles
            FOR ALL USING (public.is_god_mode()) 
            WITH CHECK (public.is_god_mode());
    END IF;
END $$;

-- ============================================================================
-- 5. TRIGGERS
-- ============================================================================

-- Trigger for updated_at timestamp on community_titles
DROP TRIGGER IF EXISTS set_community_titles_updated_at ON public.community_titles;
CREATE TRIGGER set_community_titles_updated_at
    BEFORE UPDATE ON public.community_titles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================================
-- 6. GRANTS
-- ============================================================================

GRANT ALL ON public.community_titles TO authenticated;
GRANT SELECT ON public.community_titles TO anon;

GRANT ALL ON public.community_member_titles TO authenticated;
GRANT SELECT ON public.community_member_titles TO anon;

-- ============================================================================
-- 7. VERIFICATION
-- ============================================================================

SELECT 'community_titles' AS table_name, COUNT(*) AS column_count
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'community_titles'
UNION ALL
SELECT 'community_member_titles' AS table_name, COUNT(*) AS column_count
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'community_member_titles';

-- ============================================================================
-- 8. SAMPLE DATA (Optional - for testing)
-- ============================================================================
-- Uncomment to insert sample titles for testing
/*
-- Example: Insert a sample title for a community
INSERT INTO public.community_titles (community_id, name, description, style, priority, created_by)
VALUES (
    'YOUR_COMMUNITY_ID',
    '⭐ Elite Member',
    'Outstanding contributor',
    '{"bg": "#FFD700", "fg": "#000000", "icon": "star"}'::jsonb,
    100,
    'YOUR_USER_ID'
);

-- Example: Assign the title to a user
INSERT INTO public.community_member_titles (community_id, member_user_id, title_id, assigned_by)
VALUES (
    'YOUR_COMMUNITY_ID',
    'MEMBER_USER_ID',
    (SELECT id FROM public.community_titles WHERE name = '⭐ Elite Member' LIMIT 1),
    'YOUR_USER_ID'
);
*/
