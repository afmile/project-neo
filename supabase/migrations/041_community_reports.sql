-- =============================================
-- Migration: 041_community_reports.sql
-- Purpose: Community-scoped reports for content moderation
-- Date: 2026-01-10
-- =============================================

-- ============================================================================
-- 1. CREATE community_reports TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.community_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Community context
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    
    -- People involved
    reporter_id UUID REFERENCES public.users_global(id) ON DELETE SET NULL,
    accused_id UUID REFERENCES public.users_global(id) ON DELETE SET NULL,
    
    -- Reported content (at least one must be non-null)
    post_id UUID REFERENCES public.community_wall_posts(id) ON DELETE SET NULL,
    comment_id UUID REFERENCES public.wall_post_comments(id) ON DELETE SET NULL,
    
    -- Report details
    reason TEXT NOT NULL,
    description TEXT,
    
    -- Status workflow
    status TEXT NOT NULL DEFAULT 'pending',
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- ===========================================
    -- CONSTRAINTS
    -- ===========================================
    
    -- Constraint: Must report either a post OR a comment (at least one)
    CONSTRAINT report_has_target CHECK (
        post_id IS NOT NULL OR comment_id IS NOT NULL
    ),
    
    -- Constraint: Valid standardized reasons
    CONSTRAINT valid_reason CHECK (reason IN (
        'spam',
        'harassment',
        'hate_speech',
        'violence',
        'nudity',
        'misinformation',
        'self_harm',
        'illegal_content',
        'impersonation',
        'other'
    )),
    
    -- Constraint: Valid status values
    CONSTRAINT valid_status CHECK (status IN (
        'pending',
        'reviewed',
        'dismissed',
        'action_taken'
    ))
);

-- ============================================================================
-- 2. INDEXES
-- ============================================================================

-- Index for fetching reports by community (most common query for moderation dashboard)
CREATE INDEX IF NOT EXISTS idx_community_reports_community 
ON public.community_reports(community_id, created_at DESC);

-- Index for filtering by status
CREATE INDEX IF NOT EXISTS idx_community_reports_status 
ON public.community_reports(community_id, status);

-- Index for looking up reports by accused user
CREATE INDEX IF NOT EXISTS idx_community_reports_accused 
ON public.community_reports(accused_id);

-- Index for looking up reports by reporter
CREATE INDEX IF NOT EXISTS idx_community_reports_reporter 
ON public.community_reports(reporter_id);

-- ============================================================================
-- 3. ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE public.community_reports ENABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------
-- Policy 1: CREATE - Authenticated users can submit reports
-- ---------------------------------------------------------
CREATE POLICY "community_reports_insert_authenticated"
ON public.community_reports
FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() = reporter_id
    AND reporter_id IS NOT NULL
);

-- ---------------------------------------------------------
-- Policy 2: VIEW - Only staff (owner, leader, mod/curator) can view reports
-- ---------------------------------------------------------
CREATE POLICY "community_reports_select_staff"
ON public.community_reports
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 
        FROM public.community_members cm
        WHERE cm.community_id = community_reports.community_id
          AND cm.user_id = auth.uid()
          AND cm.role IN ('owner', 'leader', 'curator', 'mod', 'moderator')
    )
);

-- ---------------------------------------------------------
-- Policy 3: UPDATE - Only staff can update reports (change status)
-- ---------------------------------------------------------
CREATE POLICY "community_reports_update_staff"
ON public.community_reports
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 
        FROM public.community_members cm
        WHERE cm.community_id = community_reports.community_id
          AND cm.user_id = auth.uid()
          AND cm.role IN ('owner', 'leader', 'curator', 'mod', 'moderator')
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 
        FROM public.community_members cm
        WHERE cm.community_id = community_reports.community_id
          AND cm.user_id = auth.uid()
          AND cm.role IN ('owner', 'leader', 'curator', 'mod', 'moderator')
    )
);

-- ---------------------------------------------------------
-- Policy 4: God mode for super admins
-- ---------------------------------------------------------
CREATE POLICY "god_mode_community_reports"
ON public.community_reports
FOR ALL
TO authenticated
USING (public.is_god_mode())
WITH CHECK (public.is_god_mode());

-- ============================================================================
-- 4. GRANTS
-- ============================================================================

GRANT SELECT, INSERT, UPDATE ON public.community_reports TO authenticated;

-- ============================================================================
-- 5. COMMENTS
-- ============================================================================

COMMENT ON TABLE public.community_reports IS 
    'Community-scoped content reports for moderation. Reports are against posts or comments within a specific community.';

COMMENT ON COLUMN public.community_reports.reason IS 
    'Standardized reason: spam, harassment, hate_speech, violence, nudity, misinformation, self_harm, illegal_content, impersonation, other';

COMMENT ON COLUMN public.community_reports.status IS 
    'Report status: pending (new), reviewed (being looked at), dismissed (no action needed), action_taken (moderation applied)';

-- ============================================================================
-- 6. VERIFICATION
-- ============================================================================

-- Verify table was created
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'community_reports'
ORDER BY ordinal_position;
