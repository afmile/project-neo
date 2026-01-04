-- ============================================================================
-- PROJECT NEO - COMMUNITY NOTIFICATIONS SYSTEM (MVP)
-- Community-scoped notifications with actionable support
-- ============================================================================
--
-- Architecture:
-- - Each community has its own inbox of notifications
-- - Supports actionable notifications (accept/reject for friendship requests)
-- - Extensible for future notification types (likes, comments, mentions, etc.)
-- - Auto-generated via triggers (no manual insert needed)
-- ============================================================================

-- ============================================================================
-- 1. CREATE COMMUNITY_NOTIFICATIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.community_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Community scope (notifications are per-community)
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    
    -- Recipient (who receives the notification)
    recipient_id UUID NOT NULL REFERENCES public.users_global(id) ON DELETE CASCADE,
    
    -- Actor (who triggered the notification, optional)
    actor_id UUID REFERENCES public.users_global(id) ON DELETE SET NULL,
    
    -- Notification type (extensible)
    -- Examples: 'friendship_request', 'follow', 'wall_post_like', 'comment', 'mention'
    type TEXT NOT NULL,
    
    -- Related entity (for linking to the source)
    entity_type TEXT,  -- 'friendship_request', 'wall_post', 'comment', etc.
    entity_id UUID,    -- ID of the related entity
    
    -- Display content
    title TEXT NOT NULL,
    body TEXT,
    
    -- Flexible payload for additional data
    data JSONB NOT NULL DEFAULT '{}'::jsonb,
    
    -- For actionable notifications
    action_status TEXT,  -- 'pending', 'accepted', 'rejected', NULL for non-actionable
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    read_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT notification_type_valid CHECK (
        type IN ('friendship_request', 'follow', 'wall_post_like', 'comment_like', 
                 'comment', 'mention', 'mod_action', 'system', 'announcement')
    ),
    CONSTRAINT action_status_valid CHECK (
        action_status IS NULL OR action_status IN ('pending', 'accepted', 'rejected')
    )
);

-- ============================================================================
-- 2. CREATE INDEXES
-- ============================================================================

-- Primary query: get notifications for user in community
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_community
ON public.community_notifications(recipient_id, community_id, created_at DESC);

-- Unread notifications count
CREATE INDEX IF NOT EXISTS idx_notifications_unread
ON public.community_notifications(recipient_id, community_id)
WHERE read_at IS NULL;

-- Pending actionable notifications
CREATE INDEX IF NOT EXISTS idx_notifications_pending
ON public.community_notifications(recipient_id, community_id)
WHERE action_status = 'pending';

-- By entity (for deduplication and linking)
CREATE INDEX IF NOT EXISTS idx_notifications_entity
ON public.community_notifications(entity_type, entity_id);

-- ============================================================================
-- 3. ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE public.community_notifications ENABLE ROW LEVEL SECURITY;

-- SELECT: Users can only see their own notifications
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'community_notifications' 
        AND policyname = 'notifications_select_own'
    ) THEN
        CREATE POLICY "notifications_select_own" ON public.community_notifications
            FOR SELECT USING (recipient_id = auth.uid());
    END IF;
END $$;

-- UPDATE: Users can only update their own notifications (mark read, resolve actions)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'community_notifications' 
        AND policyname = 'notifications_update_own'
    ) THEN
        CREATE POLICY "notifications_update_own" ON public.community_notifications
            FOR UPDATE USING (recipient_id = auth.uid()) 
            WITH CHECK (recipient_id = auth.uid());
    END IF;
END $$;

-- INSERT: Only service role (via triggers) or actor creating their own notification
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'community_notifications' 
        AND policyname = 'notifications_insert_actor'
    ) THEN
        CREATE POLICY "notifications_insert_actor" ON public.community_notifications
            FOR INSERT WITH CHECK (actor_id = auth.uid());
    END IF;
END $$;

-- God mode policy
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'community_notifications' 
        AND policyname = 'god_mode_notifications'
    ) THEN
        CREATE POLICY "god_mode_notifications" ON public.community_notifications
            FOR ALL USING (public.is_god_mode()) 
            WITH CHECK (public.is_god_mode());
    END IF;
END $$;

-- ============================================================================
-- 4. TRIGGER: AUTO-CREATE NOTIFICATION ON FRIENDSHIP REQUEST
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_on_friendship_request()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_requester_name TEXT;
BEGIN
    -- Get requester's name
    SELECT COALESCE(username, 'Alguien') INTO v_requester_name
    FROM public.users_global
    WHERE id = NEW.requester_id;

    -- Create notification for the recipient
    INSERT INTO public.community_notifications (
        community_id,
        recipient_id,
        actor_id,
        type,
        entity_type,
        entity_id,
        title,
        body,
        action_status,
        data
    ) VALUES (
        NEW.community_id,
        NEW.recipient_id,
        NEW.requester_id,
        'friendship_request',
        'friendship_request',
        NEW.id,
        'Nueva solicitud de amistad',
        v_requester_name || ' quiere ser tu amigo',
        'pending',
        jsonb_build_object(
            'requester_id', NEW.requester_id,
            'recipient_id', NEW.recipient_id,
            'requester_name', v_requester_name
        )
    );

    RETURN NEW;
END;
$$;

-- Drop existing trigger if exists, then create
DROP TRIGGER IF EXISTS trigger_notify_friendship_request ON public.friendship_requests;

CREATE TRIGGER trigger_notify_friendship_request
    AFTER INSERT ON public.friendship_requests
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_on_friendship_request();

-- ============================================================================
-- 5. TRIGGER: UPDATE NOTIFICATION WHEN FRIENDSHIP REQUEST RESOLVED
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_on_friendship_resolved()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_recipient_name TEXT;
BEGIN
    -- Only trigger when status changes from pending to accepted/rejected
    IF OLD.status = 'pending' AND NEW.status IN ('accepted', 'rejected') THEN
        
        -- Update the original notification's action_status
        UPDATE public.community_notifications
        SET 
            action_status = NEW.status,
            read_at = COALESCE(read_at, NOW())
        WHERE entity_type = 'friendship_request'
        AND entity_id = NEW.id;

        -- Get recipient's name (they are the one who accepted/rejected)
        SELECT COALESCE(username, 'Alguien') INTO v_recipient_name
        FROM public.users_global
        WHERE id = NEW.recipient_id;

        -- Notify the original requester about the decision
        INSERT INTO public.community_notifications (
            community_id,
            recipient_id,
            actor_id,
            type,
            entity_type,
            entity_id,
            title,
            body,
            data
        ) VALUES (
            NEW.community_id,
            NEW.requester_id,  -- Notify the requester
            NEW.recipient_id,  -- Actor is who accepted/rejected
            'friendship_request',
            'friendship_request',
            NEW.id,
            CASE 
                WHEN NEW.status = 'accepted' THEN '¡Solicitud aceptada!'
                ELSE 'Solicitud rechazada'
            END,
            CASE 
                WHEN NEW.status = 'accepted' THEN v_recipient_name || ' aceptó tu solicitud de amistad'
                ELSE v_recipient_name || ' rechazó tu solicitud de amistad'
            END,
            jsonb_build_object(
                'requester_id', NEW.requester_id,
                'recipient_id', NEW.recipient_id,
                'recipient_name', v_recipient_name,
                'status', NEW.status
            )
        );
    END IF;

    RETURN NEW;
END;
$$;

-- Drop existing trigger if exists, then create
DROP TRIGGER IF EXISTS trigger_notify_friendship_resolved ON public.friendship_requests;

CREATE TRIGGER trigger_notify_friendship_resolved
    AFTER UPDATE ON public.friendship_requests
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION public.notify_on_friendship_resolved();

-- ============================================================================
-- 6. HELPER FUNCTIONS
-- ============================================================================

-- Count unread notifications for a user in a community
CREATE OR REPLACE FUNCTION public.count_unread_notifications(
    p_community_id UUID,
    p_user_id UUID
) RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)::INTEGER
        FROM public.community_notifications
        WHERE community_id = p_community_id
        AND recipient_id = p_user_id
        AND read_at IS NULL
    );
END;
$$;

-- Mark all notifications as read for a user in a community
CREATE OR REPLACE FUNCTION public.mark_all_notifications_read(
    p_community_id UUID
) RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_count INTEGER;
BEGIN
    UPDATE public.community_notifications
    SET read_at = NOW()
    WHERE community_id = p_community_id
    AND recipient_id = auth.uid()
    AND read_at IS NULL;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$;

-- ============================================================================
-- 7. GRANTS
-- ============================================================================

GRANT ALL ON public.community_notifications TO authenticated;
GRANT SELECT ON public.community_notifications TO anon;

-- ============================================================================
-- 8. VERIFICATION
-- ============================================================================

SELECT 'community_notifications' AS table_name, COUNT(*) AS column_count
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'community_notifications';
