-- =============================================
-- Migration: 011_reports_system.sql
-- Purpose: Polymorphic reports table for moderation
-- =============================================

-- Create reports table
CREATE TABLE IF NOT EXISTS public.reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
  target_type TEXT NOT NULL,
  target_id UUID NOT NULL,
  reason TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- Constraint: Valid target types
  CONSTRAINT valid_target_type CHECK (target_type IN ('post', 'comment', 'chat', 'user')),
  
  -- Constraint: Valid reasons (Spanish)
  CONSTRAINT valid_reason CHECK (reason IN (
    'Simplemente no me gusta',
    'Bullying o contacto no deseado',
    'Suicidio, autolesión o trastornos alimentarios',
    'Violencia, odio o explotación',
    'Venta o promoción de artículos restringidos',
    'Desnudos o actividad sexual',
    'Estafa, fraude o spam',
    'Información falsa',
    'Propiedad intelectual'
  )),
  
  -- Constraint: Valid statuses
  CONSTRAINT valid_status CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed')),
  
  -- Prevent duplicate reports from same user on same target
  CONSTRAINT unique_report UNIQUE (reporter_id, target_type, target_id)
);

-- Index for faster lookups by target
CREATE INDEX IF NOT EXISTS idx_reports_target ON public.reports(target_type, target_id);

-- Index for moderation dashboard queries
CREATE INDEX IF NOT EXISTS idx_reports_status ON public.reports(status, created_at DESC);

-- =============================================
-- Row Level Security
-- =============================================

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- Policy: Users can create reports
CREATE POLICY "Users can create reports"
  ON public.reports
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = reporter_id);

-- Policy: Users can view their own reports
CREATE POLICY "Users can view own reports"
  ON public.reports
  FOR SELECT
  TO authenticated
  USING (auth.uid() = reporter_id);

-- Policy: Moderators/Admins can view all reports (future)
-- CREATE POLICY "Moderators can view all reports"
--   ON public.reports
--   FOR ALL
--   TO authenticated
--   USING (
--     EXISTS (
--       SELECT 1 FROM public.community_memberships
--       WHERE user_id = auth.uid() AND role = 'leader'
--     )
--   );

-- Grant permissions
GRANT SELECT, INSERT ON public.reports TO authenticated;
