-- ============================================================================
-- PROJECT NEO - CHAT CHANNELS MIGRATION
-- Creates the chat_channels table for community chat rooms
-- ============================================================================

-- ============================================================================
-- CHAT CHANNELS TABLE
-- ============================================================================

CREATE TABLE public.chat_channels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    creator_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE SET NULL,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    background_image_url TEXT,
    member_count INT DEFAULT 0 NOT NULL,
    is_pinned BOOLEAN DEFAULT FALSE NOT NULL,
    pinned_order INT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    CONSTRAINT chat_channels_title_not_empty CHECK (LENGTH(TRIM(title)) > 0),
    CONSTRAINT chat_channels_member_count_non_negative CHECK (member_count >= 0)
);

COMMENT ON TABLE public.chat_channels IS 
    'Chat rooms within communities. Each room can have a background image and description.';
COMMENT ON COLUMN public.chat_channels.background_image_url IS 
    'URL to background image stored in Supabase Storage (bucket: chat-backgrounds)';

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX idx_chat_channels_community ON public.chat_channels(community_id);
CREATE INDEX idx_chat_channels_creator ON public.chat_channels(creator_id);
CREATE INDEX idx_chat_channels_pinned ON public.chat_channels(community_id, is_pinned) WHERE is_pinned = TRUE;
CREATE INDEX idx_chat_channels_created ON public.chat_channels(created_at DESC);

-- ============================================================================
-- TRIGGER FOR updated_at
-- ============================================================================

CREATE TRIGGER set_chat_channels_updated_at
    BEFORE UPDATE ON public.chat_channels
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE public.chat_channels ENABLE ROW LEVEL SECURITY;

-- GOD MODE: Full access
CREATE POLICY "god_mode_chat_channels" ON public.chat_channels
    FOR ALL
    USING (public.is_god_mode())
    WITH CHECK (public.is_god_mode());

-- Members can view chat channels in their communities
CREATE POLICY "chat_channels_select_member" ON public.chat_channels
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.memberships 
            WHERE community_id = chat_channels.community_id 
            AND user_id = auth.uid()
        )
    );

-- Members can create chat channels in their communities
CREATE POLICY "chat_channels_insert_member" ON public.chat_channels
    FOR INSERT
    WITH CHECK (
        auth.uid() = creator_id
        AND EXISTS (
            SELECT 1 FROM public.memberships 
            WHERE community_id = chat_channels.community_id 
            AND user_id = auth.uid()
        )
    );

-- Creators and moderators can update chat channels
CREATE POLICY "chat_channels_update_creator_or_mod" ON public.chat_channels
    FOR UPDATE
    USING (
        creator_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.memberships 
            WHERE community_id = chat_channels.community_id 
            AND user_id = auth.uid()
            AND role IN ('owner', 'agent', 'leader')
        )
    );

-- Creators and community owners can delete chat channels
CREATE POLICY "chat_channels_delete_creator_or_owner" ON public.chat_channels
    FOR DELETE
    USING (
        creator_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.communities 
            WHERE id = chat_channels.community_id 
            AND owner_id = auth.uid()
        )
    );

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.chat_channels TO authenticated;
GRANT ALL ON public.chat_channels TO service_role;
