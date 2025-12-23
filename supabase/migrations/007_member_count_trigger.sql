-- =====================================================================
-- Migration: Auto-update member count trigger
-- Description: Automatically updates community member_count when 
--              memberships are added or removed
-- =====================================================================

-- FUNCIÓN: Actualizar contador de miembros automáticamente
CREATE OR REPLACE FUNCTION update_member_count()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    UPDATE public.communities
    SET member_count = member_count + 1
    WHERE id = NEW.community_id;
  ELSIF (TG_OP = 'DELETE') THEN
    UPDATE public.communities
    SET member_count = member_count - 1
    WHERE id = OLD.community_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER: Disparar la función cuando alguien entra o sale de 'memberships'
DROP TRIGGER IF EXISTS on_membership_change ON public.memberships;
CREATE TRIGGER on_membership_change
AFTER INSERT OR DELETE ON public.memberships
FOR EACH ROW EXECUTE FUNCTION update_member_count();

-- COMENTARIOS
COMMENT ON FUNCTION update_member_count() IS 
  'Actualiza automáticamente el contador de miembros de una comunidad';
