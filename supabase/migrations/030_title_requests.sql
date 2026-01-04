-- Migration: Title Requests System
-- Description: Add title_requests table for member-proposed custom titles
-- Date: 2025-12-30

-- ============================================================================
-- CLEANUP (in case of partial previous attempt)
-- ============================================================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "title_requests_select_own" ON public.title_requests;
DROP POLICY IF EXISTS "title_requests_select_leaders" ON public.title_requests;
DROP POLICY IF EXISTS "title_requests_insert_members" ON public.title_requests;
DROP POLICY IF EXISTS "title_requests_update_leaders" ON public.title_requests;
DROP POLICY IF EXISTS "title_requests_delete_own_pending" ON public.title_requests;

-- Drop trigger if exists
DROP TRIGGER IF EXISTS trigger_update_title_requests_updated_at ON public.title_requests;

-- Drop function if exists
DROP FUNCTION IF EXISTS update_title_requests_updated_at();

-- Drop table if exists
DROP TABLE IF EXISTS public.title_requests CASCADE;

-- ============================================================================
-- TABLE: title_requests
-- ============================================================================

CREATE TABLE public.title_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    member_user_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    title_text TEXT NOT NULL CHECK (char_length(title_text) >= 1 AND char_length(title_text) <= 30),
    text_color TEXT NOT NULL CHECK (text_color ~ '^[0-9A-Fa-f]{6}$'),
    background_color TEXT NOT NULL CHECK (background_color ~ '^[0-9A-Fa-f]{6}$'),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    reviewed_by UUID REFERENCES public.users_global(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT title_requests_reviewed_consistency CHECK (
        (status = 'pending' AND reviewed_by IS NULL AND reviewed_at IS NULL) OR
        (status IN ('approved', 'rejected') AND reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL)
    )
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Index for fetching pending requests by community
CREATE INDEX IF NOT EXISTS idx_title_requests_community_status 
    ON public.title_requests(community_id, status);

-- Index for fetching user's requests
CREATE INDEX IF NOT EXISTS idx_title_requests_user_community 
    ON public.title_requests(member_user_id, community_id);

-- Index for fetching by status and creation date
CREATE INDEX IF NOT EXISTS idx_title_requests_status_created 
    ON public.title_requests(status, created_at DESC);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_title_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_title_requests_updated_at
    BEFORE UPDATE ON public.title_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_title_requests_updated_at();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE public.title_requests ENABLE ROW LEVEL SECURITY;

-- Policy: Members can view their own requests
CREATE POLICY "title_requests_select_own" ON public.title_requests
    FOR SELECT USING (
        auth.uid() = member_user_id
    );

-- Policy: Leaders can view all requests in their community
CREATE POLICY "title_requests_select_leaders" ON public.title_requests
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.community_members cm
            WHERE cm.community_id = title_requests.community_id
            AND cm.user_id = auth.uid()
            AND cm.role IN ('leader', 'curator', 'mod')
            AND cm.is_active = TRUE
        )
    );

-- Policy: Authenticated members can create requests
CREATE POLICY "title_requests_insert_members" ON public.title_requests
    FOR INSERT WITH CHECK (
        auth.uid() = member_user_id
        AND EXISTS (
            SELECT 1 FROM public.community_members cm
            WHERE cm.community_id = title_requests.community_id
            AND cm.user_id = auth.uid()
            AND cm.is_active = TRUE
        )
    );

-- Policy: Only leaders can update (approve/reject) requests
CREATE POLICY "title_requests_update_leaders" ON public.title_requests
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.community_members cm
            WHERE cm.community_id = title_requests.community_id
            AND cm.user_id = auth.uid()
            AND cm.role IN ('leader', 'curator', 'mod')
            AND cm.is_active = TRUE
        )
    )
    WITH CHECK (
        -- Leaders can only update status, reviewed_by, and reviewed_at
        -- Cannot modify the request content itself
        title_text = (SELECT title_text FROM public.title_requests WHERE id = title_requests.id)
        AND text_color = (SELECT text_color FROM public.title_requests WHERE id = title_requests.id)
        AND background_color = (SELECT background_color FROM public.title_requests WHERE id = title_requests.id)
        AND member_user_id = (SELECT member_user_id FROM public.title_requests WHERE id = title_requests.id)
        AND community_id = (SELECT community_id FROM public.title_requests WHERE id = title_requests.id)
    );

-- Policy: Members can delete their own pending requests
CREATE POLICY "title_requests_delete_own_pending" ON public.title_requests
    FOR DELETE USING (
        auth.uid() = member_user_id
        AND status = 'pending'
    );

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE public.title_requests IS 'Stores member requests for custom titles that require leader approval';
COMMENT ON COLUMN public.title_requests.title_text IS 'Requested title text (1-30 characters, supports emojis)';
COMMENT ON COLUMN public.title_requests.text_color IS 'Hex color for title text (6 chars, no #)';
COMMENT ON COLUMN public.title_requests.background_color IS 'Hex color for title background (6 chars, no #)';
COMMENT ON COLUMN public.title_requests.status IS 'Request status: pending, approved, or rejected';
COMMENT ON COLUMN public.title_requests.reviewed_by IS 'Leader who approved/rejected the request';
COMMENT ON COLUMN public.title_requests.reviewed_at IS 'Timestamp when request was reviewed';

-- ============================================================================
-- GRANTS
-- ============================================================================

-- Grant access to authenticated users (RLS policies will control actual access)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.title_requests TO authenticated;
