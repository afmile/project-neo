-- Migration to verify and fix RLS for notification_settings updates
-- This ensures users can update their own notification preferences

-- Recreate the UPDATE policy to be absolutely sure it works
DROP POLICY IF EXISTS "community_members_update_self" ON public.community_members;

CREATE POLICY "community_members_update_self" ON public.community_members
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Verify RLS is enabled
ALTER TABLE public.community_members ENABLE ROW LEVEL SECURITY;

-- Add a comment to document the notification_settings column
COMMENT ON COLUMN public.community_members.notification_settings IS 
'JSONB object storing user notification preferences for this community. Structure: {enabled: bool, chat: bool, mentions: bool, announcements: bool, wall_posts: bool, reactions: bool}';

-- Reload schema
NOTIFY pgrst, 'reload schema';
