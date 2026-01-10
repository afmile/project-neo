-- ============================================================================
-- ROLE INVITATION SYSTEM
-- Flow: Admin promotes Member -> Member gets 'pending_role' + Notification -> Member Accepts -> Role Applied
-- ============================================================================

-- 1. Add pending_role column to community_members
-- This stores the role offered e.g. 'leader', 'moderator' until accepted
ALTER TABLE public.community_members 
ADD COLUMN IF NOT EXISTS pending_role TEXT CHECK (pending_role IN ('leader', 'moderator', 'member'));

-- 2. Update Notification Type Check Constraint
-- We need to drop and re-add the constraint to include 'role_invitation'
ALTER TABLE public.community_notifications 
DROP CONSTRAINT IF EXISTS notification_type_valid;

ALTER TABLE public.community_notifications 
ADD CONSTRAINT notification_type_valid CHECK (
    type IN ('friendship_request', 'follow', 'wall_post_like', 'comment_like', 
             'comment', 'mention', 'mod_action', 'system', 'announcement', 'role_invitation')
);

-- 3. Trigger Function: Notify on Role Invitation
CREATE OR REPLACE FUNCTION public.notify_on_role_invitation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_actor_id UUID;
    v_community_name TEXT;
    v_role_display TEXT;
BEGIN
    -- Only trigger when pending_role changes and is NOT NULL (i.e. an invitation is sent)
    IF (OLD.pending_role IS DISTINCT FROM NEW.pending_role) AND (NEW.pending_role IS NOT NULL) THEN
        
        -- Get Actor ID (who sent the invite). 
        -- Since this is an UPDATE trigger run by the user making the change, auth.uid() is the actor.
        v_actor_id := auth.uid();
        
        -- Get Community Name for the body
        SELECT title INTO v_community_name FROM public.communities WHERE id = NEW.community_id;
        
        -- Format Role Display Name
        CASE NEW.pending_role
            WHEN 'leader' THEN v_role_display := 'Líder';
            WHEN 'moderator' THEN v_role_display := 'Moderador';
            ELSE v_role_display := NEW.pending_role;
        END CASE;

        -- Create Notification
        INSERT INTO public.community_notifications (
            community_id,
            recipient_id,
            actor_id,
            type,
            entity_type,
            entity_id, -- We use the community_id itself or member_id as reference, let's use community_id implies general
            title,
            body,
            action_status,
            data
        ) VALUES (
            NEW.community_id,
            NEW.user_id, -- The member receiving the role
            v_actor_id,
            'role_invitation',
            'role_invitation',
            NEW.community_id, -- entity_id points to community context
            'Propuesta de Ascenso',
            'Te han invitado a ser ' || v_role_display || ' en ' || COALESCE(v_community_name, 'la comunidad'),
            'pending',
            jsonb_build_object(
                'role', NEW.pending_role,
                'community_name', v_community_name
            )
        );
    END IF;

    -- Handle Rejections/Clear (Optional hook if we wanted to notify admin of rejection, keeping it simple for now)
    
    RETURN NEW;
END;
$$;

-- 4. Create Trigger
DROP TRIGGER IF EXISTS trigger_notify_role_invitation ON public.community_members;

CREATE TRIGGER trigger_notify_role_invitation
    AFTER UPDATE ON public.community_members
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_on_role_invitation();
