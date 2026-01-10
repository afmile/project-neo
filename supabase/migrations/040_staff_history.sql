-- Migration: 040_staff_history.sql
-- Description: Adds previous_role column to track staff history

ALTER TABLE public.community_members 
ADD COLUMN IF NOT EXISTS previous_role TEXT;

COMMENT ON COLUMN public.community_members.previous_role IS 'Stores the last significant role (leader/moderator) held by the user for reinstatement history.';
