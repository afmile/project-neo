-- =============================================
-- Migration: 042_federal_moderation_architecture.sql
-- Purpose: Federal Moderation System - Global Admins, Forensic Logs, Reports, Blocking
-- Author: Senior Backend Architect
-- Date: 2026-01-10
-- =============================================

-- ============================================================================
-- REQUIREMENT 1: HIERARCHY UPDATES (The Federal Model)
-- ============================================================================

-- ----------------------------------------
-- 1.1 Add Global Admin & Ban Flags to users_global
-- ----------------------------------------

ALTER TABLE public.users_global 
ADD COLUMN IF NOT EXISTS is_global_admin BOOLEAN DEFAULT FALSE;

ALTER TABLE public.users_global 
ADD COLUMN IF NOT EXISTS is_global_banned BOOLEAN DEFAULT FALSE;

COMMENT ON COLUMN public.users_global.is_global_admin IS 
    'Platform-wide "God Mode" - grants universal access to all communities and moderation tools';

COMMENT ON COLUMN public.users_global.is_global_banned IS 
    'Platform-wide ban - denies access to the entire application';

-- ----------------------------------------
-- 1.2 Add Suspension Flag to Communities
-- ----------------------------------------

ALTER TABLE public.communities 
ADD COLUMN IF NOT EXISTS is_suspended BOOLEAN DEFAULT FALSE;

COMMENT ON COLUMN public.communities.is_suspended IS 
    'Community suspension flag - allows Global Admins to hide toxic communities';

-- ----------------------------------------
-- 1.3 Performance Indexes for Hierarchy
-- ----------------------------------------

CREATE INDEX IF NOT EXISTS idx_users_global_admin 
ON public.users_global(is_global_admin) 
WHERE is_global_admin = TRUE;

CREATE INDEX IF NOT EXISTS idx_users_global_banned 
ON public.users_global(is_global_banned) 
WHERE is_global_banned = TRUE;

CREATE INDEX IF NOT EXISTS idx_communities_suspended 
ON public.communities(is_suspended) 
WHERE is_suspended = TRUE;

-- ============================================================================
-- REQUIREMENT 2: CENTRALIZED REPORTING (The Universal Inbox)
-- ============================================================================

-- ----------------------------------------
-- 2.1 Upgrade Community Reports Table (Migration 041 Compatibility)
-- ----------------------------------------

-- Create table if it doesn't exist (for fresh installs)
CREATE TABLE IF NOT EXISTS public.community_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- Context
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    
    -- People Involved
    reporter_id UUID REFERENCES public.users_global(id) ON DELETE SET NULL,
    accused_id UUID REFERENCES public.users_global(id) ON DELETE SET NULL,
    
    -- Reported Content
    post_id UUID REFERENCES public.community_wall_posts(id) ON DELETE SET NULL,
    comment_id UUID REFERENCES public.wall_post_comments(id) ON DELETE SET NULL,
    
    -- Report Details
    reason TEXT NOT NULL,
    description TEXT,
    
    -- Status
    status TEXT NOT NULL DEFAULT 'pending'
);

-- Add missing columns if they don't exist (for migration 041 compatibility)
ALTER TABLE public.community_reports 
ADD COLUMN IF NOT EXISTS priority TEXT NOT NULL DEFAULT 'normal';

ALTER TABLE public.community_reports 
ADD COLUMN IF NOT EXISTS resolution_note TEXT;

-- Update accused_id to NOT NULL if it was nullable
DO $$ 
BEGIN
    -- Only alter if the column exists and is nullable
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'community_reports' 
          AND column_name = 'accused_id' 
          AND is_nullable = 'YES'
    ) THEN
        -- First delete any rows with NULL accused_id (shouldn't exist but just in case)
        DELETE FROM public.community_reports WHERE accused_id IS NULL;
        
        -- Then set NOT NULL constraint
        ALTER TABLE public.community_reports 
        ALTER COLUMN accused_id SET NOT NULL;
    END IF;
END $$;

-- ===========================================
-- CONSTRAINTS (Drop existing, recreate)
-- ===========================================

-- Drop existing constraints that might conflict
ALTER TABLE public.community_reports DROP CONSTRAINT IF EXISTS report_has_target;
ALTER TABLE public.community_reports DROP CONSTRAINT IF EXISTS valid_priority;
ALTER TABLE public.community_reports DROP CONSTRAINT IF EXISTS valid_status;
ALTER TABLE public.community_reports DROP CONSTRAINT IF EXISTS valid_reason;

-- At least one content target must be specified
ALTER TABLE public.community_reports 
ADD CONSTRAINT report_has_target CHECK (
    post_id IS NOT NULL OR comment_id IS NOT NULL
);

-- Valid priority levels
ALTER TABLE public.community_reports 
ADD CONSTRAINT valid_priority CHECK (priority IN ('normal', 'high', 'critical'));

-- Valid status values
ALTER TABLE public.community_reports 
ADD CONSTRAINT valid_status CHECK (status IN ('pending', 'resolved', 'dismissed'));

-- ----------------------------------------
-- 2.2 Indexes for Report Queries
-- ----------------------------------------

CREATE INDEX IF NOT EXISTS idx_community_reports_community 
ON public.community_reports(community_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_community_reports_status 
ON public.community_reports(community_id, status, priority DESC);

CREATE INDEX IF NOT EXISTS idx_community_reports_accused 
ON public.community_reports(accused_id);

CREATE INDEX IF NOT EXISTS idx_community_reports_reporter 
ON public.community_reports(reporter_id) 
WHERE reporter_id IS NOT NULL;

-- ----------------------------------------
-- 2.3 Helper Function: Check Community Staff
-- ----------------------------------------

CREATE OR REPLACE FUNCTION public.is_community_staff(p_community_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM public.community_members
        WHERE community_id = p_community_id
          AND user_id = auth.uid()
          AND role IN ('owner', 'leader', 'mod', 'moderator', 'curator')
    );
END;
$$;

-- ----------------------------------------
-- 2.4 Helper Function: Check Global Admin
-- ----------------------------------------

CREATE OR REPLACE FUNCTION public.is_global_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM public.users_global
        WHERE id = auth.uid()
          AND is_global_admin = TRUE
    );
END;
$$;

-- ----------------------------------------
-- 2.5 RLS Policies for Reports (FEDERAL LOGIC)
-- ----------------------------------------

ALTER TABLE public.community_reports ENABLE ROW LEVEL SECURITY;

-- Drop existing policies from migration 041 if they exist
DROP POLICY IF EXISTS "community_reports_insert_authenticated" ON public.community_reports;
DROP POLICY IF EXISTS "community_reports_select_staff" ON public.community_reports;
DROP POLICY IF EXISTS "community_reports_update_staff" ON public.community_reports;
DROP POLICY IF EXISTS "god_mode_community_reports" ON public.community_reports;
DROP POLICY IF EXISTS "community_reports_select_federal" ON public.community_reports;
DROP POLICY IF EXISTS "community_reports_update_federal" ON public.community_reports;

-- INSERT: Authenticated users can create reports
CREATE POLICY "community_reports_insert_authenticated"
ON public.community_reports
FOR INSERT
TO authenticated
WITH CHECK (
    -- Reporter must be the current user (or NULL for system reports)
    (reporter_id = auth.uid() OR reporter_id IS NULL)
);

-- SELECT: Local Staff OR Global Admins (FEDERAL ACCESS)
CREATE POLICY "community_reports_select_federal"
ON public.community_reports
FOR SELECT
TO authenticated
USING (
    -- Local Staff: Can see reports for their community
    public.is_community_staff(community_id)
    OR
    -- Global Admins: Can see ALL reports from ANY community
    public.is_global_admin()
);

-- UPDATE: Local Staff OR Global Admins (for resolution)
CREATE POLICY "community_reports_update_federal"
ON public.community_reports
FOR UPDATE
TO authenticated
USING (
    public.is_community_staff(community_id)
    OR
    public.is_global_admin()
)
WITH CHECK (
    public.is_community_staff(community_id)
    OR
    public.is_global_admin()
);

-- ----------------------------------------
-- 2.6 Grants
-- ----------------------------------------

GRANT SELECT, INSERT, UPDATE ON public.community_reports TO authenticated;

COMMENT ON TABLE public.community_reports IS 
    'Centralized reporting system with federal access - Local Staff see their community, Global Admins see everything';

-- ============================================================================
-- REQUIREMENT 3: FORENSIC AUDIT LOG (The Black Box)
-- ============================================================================

-- ----------------------------------------
-- 3.1 Create Activity Logs Table
-- ----------------------------------------

CREATE TABLE IF NOT EXISTS public.community_activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- Context
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    
    -- Who & What
    actor_id UUID REFERENCES public.users_global(id) ON DELETE SET NULL,  -- NULL = System
    target_user_id UUID REFERENCES public.users_global(id) ON DELETE SET NULL,
    
    -- Action Details
    action_type TEXT NOT NULL,  -- e.g., 'POST_DELETE', 'GLOBAL_BAN', 'REPORT_RESOLVED'
    entity_type TEXT NOT NULL,  -- e.g., 'post', 'comment', 'user'
    entity_id UUID,
    
    -- Forensic Snapshot (CRITICAL for evidence retention)
    metadata JSONB DEFAULT '{}'::jsonb
);

-- ----------------------------------------
-- 3.2 Indexes for Audit Queries
-- ----------------------------------------

CREATE INDEX IF NOT EXISTS idx_activity_logs_community 
ON public.community_activity_logs(community_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_activity_logs_actor 
ON public.community_activity_logs(actor_id) 
WHERE actor_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_activity_logs_target 
ON public.community_activity_logs(target_user_id) 
WHERE target_user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_activity_logs_action_type 
ON public.community_activity_logs(action_type);

CREATE INDEX IF NOT EXISTS idx_activity_logs_entity 
ON public.community_activity_logs(entity_type, entity_id);

-- ----------------------------------------
-- 3.3 Trigger Functions: Content Capture
-- ----------------------------------------

-- Trigger Function: Capture Post Deletion
CREATE OR REPLACE FUNCTION public.log_post_deletion()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.community_activity_logs (
        community_id,
        actor_id,
        target_user_id,
        action_type,
        entity_type,
        entity_id,
        metadata
    ) VALUES (
        OLD.community_id,
        auth.uid(),  -- Current user (or NULL if system)
        OLD.author_id,
        'CONTENT_REMOVED',
        'post',
        OLD.id,
        jsonb_build_object(
            'body', OLD.body,
            'image_url', OLD.image_url,
            'author_id', OLD.author_id,
            'created_at', OLD.created_at,
            'like_count', OLD.like_count,
            'comment_count', OLD.comment_count,
            'deleted_at', now()
        )
    );
    
    RETURN OLD;
END;
$$;

-- Trigger Function: Capture Comment Deletion
CREATE OR REPLACE FUNCTION public.log_comment_deletion()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.community_activity_logs (
        community_id,
        actor_id,
        target_user_id,
        action_type,
        entity_type,
        entity_id,
        metadata
    ) VALUES (
        (SELECT community_id FROM public.community_wall_posts WHERE id = OLD.post_id),
        auth.uid(),
        OLD.author_id,
        'CONTENT_REMOVED',
        'comment',
        OLD.id,
        jsonb_build_object(
            'body', OLD.body,
            'post_id', OLD.post_id,
            'author_id', OLD.author_id,
            'created_at', OLD.created_at,
            'like_count', OLD.like_count,
            'deleted_at', now()
        )
    );
    
    RETURN OLD;
END;
$$;

-- ----------------------------------------
-- 3.4 Attach Triggers to Tables
-- ----------------------------------------

DROP TRIGGER IF EXISTS trigger_log_post_deletion ON public.community_wall_posts;
CREATE TRIGGER trigger_log_post_deletion
    BEFORE DELETE ON public.community_wall_posts
    FOR EACH ROW
    EXECUTE FUNCTION public.log_post_deletion();

DROP TRIGGER IF EXISTS trigger_log_comment_deletion ON public.wall_post_comments;
CREATE TRIGGER trigger_log_comment_deletion
    BEFORE DELETE ON public.wall_post_comments
    FOR EACH ROW
    EXECUTE FUNCTION public.log_comment_deletion();

-- ----------------------------------------
-- 3.5 RLS for Activity Logs
-- ----------------------------------------

ALTER TABLE public.community_activity_logs ENABLE ROW LEVEL SECURITY;

-- SELECT: Local Staff OR Global Admins (read-only forensic access)
CREATE POLICY "activity_logs_select_federal"
ON public.community_activity_logs
FOR SELECT
TO authenticated
USING (
    public.is_community_staff(community_id)
    OR
    public.is_global_admin()
);

-- INSERT: Only via triggers (no direct user inserts)
-- No INSERT policy = only SECURITY DEFINER functions can insert

GRANT SELECT ON public.community_activity_logs TO authenticated;

COMMENT ON TABLE public.community_activity_logs IS 
    'Immutable forensic audit log - captures content snapshots before deletion for legal/compliance purposes';

-- ============================================================================
-- REQUIREMENT 4: USER BLOCKING (App Store Compliance)
-- ============================================================================

-- ----------------------------------------
-- 4.1 Create User Blocks Table
-- ----------------------------------------

CREATE TABLE IF NOT EXISTS public.user_blocks (
    blocker_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- Composite Primary Key
    PRIMARY KEY (blocker_id, blocked_id),
    
    -- Prevent Self-Blocking
    CONSTRAINT no_self_block CHECK (blocker_id != blocked_id)
);

-- ----------------------------------------
-- 4.2 Indexes for Block Lookups
-- ----------------------------------------

CREATE INDEX IF NOT EXISTS idx_user_blocks_blocker 
ON public.user_blocks(blocker_id);

CREATE INDEX IF NOT EXISTS idx_user_blocks_blocked 
ON public.user_blocks(blocked_id);

-- ----------------------------------------
-- 4.3 RLS for User Blocks
-- ----------------------------------------

ALTER TABLE public.user_blocks ENABLE ROW LEVEL SECURITY;

-- Users can manage their own blocks
CREATE POLICY "user_blocks_manage_own"
ON public.user_blocks
FOR ALL
TO authenticated
USING (blocker_id = auth.uid())
WITH CHECK (blocker_id = auth.uid());

GRANT SELECT, INSERT, DELETE ON public.user_blocks TO authenticated;

COMMENT ON TABLE public.user_blocks IS 
    'User blocking system for App Store compliance - allows users to block other users';

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Verify hierarchy columns
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'users_global' 
  AND column_name IN ('is_global_admin', 'is_global_banned')
ORDER BY column_name;

-- Verify reports table
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'community_reports'
ORDER BY ordinal_position;

-- Verify activity logs table
SELECT column_name, data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'community_activity_logs'
ORDER BY ordinal_position;

-- Verify user blocks table
SELECT column_name, data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'user_blocks'
ORDER BY ordinal_position;

-- Verify triggers are attached
SELECT 
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND trigger_name IN ('trigger_log_post_deletion', 'trigger_log_comment_deletion')
ORDER BY event_object_table, trigger_name;
