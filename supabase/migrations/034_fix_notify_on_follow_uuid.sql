-- ============================================================================
-- Migration: 034_fix_notify_on_follow_uuid.sql
-- Fixes: entity_id UUID type mismatch in notify_on_follow trigger
-- ============================================================================

-- Drop and recreate the function with corrected type casting
CREATE OR REPLACE FUNCTION public.notify_on_follow()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Only notify on new active follows (not unfollows/re-follows)
    IF NEW.is_active = TRUE AND (OLD IS NULL OR OLD.is_active = FALSE) THEN
        INSERT INTO public.community_notifications (
            community_id,
            recipient_id,
            actor_id,
            type,
            entity_type,
            entity_id,  -- This is UUID, not TEXT
            title,
            body,
            data
        ) VALUES (
            NEW.community_id,
            NEW.followed_id,
            NEW.follower_id,
            'follow',
            'community_follow',
            NEW.id,  -- UUID directly, no casting to TEXT
            'Nuevo seguidor',
            (SELECT username FROM public.users_global WHERE id = NEW.follower_id) || ' te ha seguido',
            jsonb_build_object('follower_id', NEW.follower_id)
        );
    END IF;
    
    RETURN NEW;
END;
$$;

-- Verify the trigger is attached
DROP TRIGGER IF EXISTS trigger_notify_on_follow ON public.community_follows;
CREATE TRIGGER trigger_notify_on_follow
    AFTER INSERT OR UPDATE ON public.community_follows
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_on_follow();
