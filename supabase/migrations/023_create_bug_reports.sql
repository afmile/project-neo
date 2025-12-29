-- Create bug_reports table for user-submitted issues
-- RLS enabled with INSERT-only access from client
-- Admin access via Supabase Dashboard or direct SQL queries

create table public.bug_reports (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users(id) on delete set null,
  community_id uuid references public.communities(id) on delete set null,
  route text not null,
  description text not null,
  app_version text not null,
  build_number text not null,
  platform text not null,
  device_info jsonb not null default '{}'::jsonb,
  sentry_event_id text,
  feature text,
  extra jsonb default '{}'::jsonb
);

-- Enable Row Level Security
alter table public.bug_reports enable row level security;

-- Policy: Only authenticated users can insert bug reports
-- user_id must match the authenticated user
create policy "Authenticated users can insert bug reports"
  on public.bug_reports
  for insert
  to authenticated
  with check (auth.uid() = user_id);

-- Policy: Block SELECT from client (admin-only access)
-- No SELECT policy = no client access
-- Admins can view via Supabase Dashboard → Table Editor or direct SQL queries

-- Indexes for admin queries and performance
create index bug_reports_user_id_idx on public.bug_reports(user_id);
create index bug_reports_created_at_idx on public.bug_reports(created_at desc);
create index bug_reports_community_id_idx on public.bug_reports(community_id) 
  where community_id is not null;

-- Table documentation
comment on table public.bug_reports is 
  'User-submitted bug reports and issues. Client can INSERT only. Admins view via Dashboard → Table Editor or SQL queries.';

comment on column public.bug_reports.user_id is 
  'User who submitted the report. Nullable for anonymous reports.';

comment on column public.bug_reports.community_id is 
  'Community context if applicable. Nullable for global issues.';

comment on column public.bug_reports.device_info is 
  'Device information (model, OS version, etc.) without sensitive PII.';

comment on column public.bug_reports.sentry_event_id is 
  'Sentry event ID if the report is linked to a crash/error.';
