-- Migration: Fix member_count trigger to handle soft deletes (is_active)
-- Date: 2025-12-27

-- 1. Drop existing trigger and function to start clean
DROP TRIGGER IF EXISTS on_membership_change ON public.community_members;
DROP FUNCTION IF EXISTS update_member_count();

-- 2. Create improved function that handles INSERT, DELETE, and UPDATE (soft delete)
CREATE OR REPLACE FUNCTION update_member_count()
RETURNS TRIGGER AS $$
BEGIN
  -- Handle INSERT: New member added
  IF (TG_OP = 'INSERT') THEN
    IF (NEW.is_active = true) THEN
        UPDATE public.communities
        SET member_count = member_count + 1
        WHERE id = NEW.community_id;
    END IF;
    RETURN NEW;

  -- Handle DELETE: Hard delete (should rarely happen, but good safety)
  ELSIF (TG_OP = 'DELETE') THEN
    UPDATE public.communities
    SET member_count = GREATEST(member_count - 1, 0)
    WHERE id = OLD.community_id;
    RETURN OLD;

  -- Handle UPDATE: Soft delete / Activation
  ELSIF (TG_OP = 'UPDATE') THEN
    -- Case A: User left (Active -> Inactive)
    IF (OLD.is_active = true AND NEW.is_active = false) THEN
        UPDATE public.communities
        SET member_count = GREATEST(member_count - 1, 0)
        WHERE id = NEW.community_id;
    
    -- Case B: User re-joined (Inactive -> Active)
    ELSIF (OLD.is_active = false AND NEW.is_active = true) THEN
        UPDATE public.communities
        SET member_count = member_count + 1
        WHERE id = NEW.community_id;
    END IF;
    
    RETURN NEW;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 3. Re-create trigger with UPDATE support
CREATE TRIGGER on_membership_change
AFTER INSERT OR DELETE OR UPDATE OF is_active ON public.community_members
FOR EACH ROW EXECUTE FUNCTION update_member_count();

-- 4. Notify PostgREST to reload schema
NOTIFY pgrst, 'reload schema';
