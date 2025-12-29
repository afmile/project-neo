-- =============================================================================
-- OBJECTIVE 0.5: CLOSED BETA INFRASTRUCTURE - Supabase SQL
-- =============================================================================
-- Run these commands in Supabase SQL Editor
-- Dashboard: https://supabase.com/dashboard → SQL Editor

-- -----------------------------------------------------------------------------
-- 1. APP_CONFIG TABLE (Feature Flags + Version Control)
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.app_config (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Allow authenticated users to read config
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated to read app_config" ON public.app_config
  FOR SELECT TO authenticated USING (true);

-- Insert feature flags
INSERT INTO public.app_config (key, value) VALUES
('feature_flags', '{
  "enableFeed": false,
  "enablePosts": false,
  "enableChats": true,
  "enableQuizzes": false,
  "enableEconomy": false,
  "enableInvites": false
}'::jsonb)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW();

-- Insert minimum app version
INSERT INTO public.app_config (key, value) VALUES
('min_app_version', '{
  "version": "0.5.0",
  "message": "Por favor actualiza la app para continuar"
}'::jsonb)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW();

-- -----------------------------------------------------------------------------
-- 2. USERS_GLOBAL: Add beta user flag
-- -----------------------------------------------------------------------------

ALTER TABLE public.users_global 
ADD COLUMN IF NOT EXISTS is_beta_user BOOLEAN DEFAULT FALSE;

-- Optional: Add some test beta users
-- UPDATE public.users_global SET is_beta_user = TRUE WHERE id = 'your-user-id';

-- -----------------------------------------------------------------------------
-- 3. FEEDBACK_REPORTS TABLE
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.feedback_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  feedback_type TEXT NOT NULL CHECK (feedback_type IN ('bug', 'suggestion', 'other')),
  message TEXT NOT NULL CHECK (char_length(message) <= 2000),
  context JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS: Users can only INSERT their own feedback, cannot read others
ALTER TABLE public.feedback_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert own feedback" ON public.feedback_reports
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

-- Prevent users from reading feedback (admin only via service role)
CREATE POLICY "No client read on feedback" ON public.feedback_reports
  FOR SELECT TO authenticated USING (false);

-- -----------------------------------------------------------------------------
-- VERIFICATION QUERIES
-- -----------------------------------------------------------------------------

-- Check app_config was created
SELECT * FROM public.app_config;

-- Check is_beta_user column exists
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users_global' AND column_name = 'is_beta_user';

-- Check feedback_reports table
SELECT * FROM information_schema.tables WHERE table_name = 'feedback_reports';
