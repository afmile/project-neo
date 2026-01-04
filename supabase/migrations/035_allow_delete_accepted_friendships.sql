-- Migration to allow deleting accepted friendship requests
-- This enables "Unfriend" functionality

DO $$ 
BEGIN
    -- Drop existing policy
    DROP POLICY IF EXISTS "friendship_requests_delete_own" ON public.friendship_requests;

    -- Re-create policy without status restriction
    CREATE POLICY "friendship_requests_delete_own" ON public.friendship_requests
        FOR DELETE USING (
            auth.uid() = requester_id OR auth.uid() = recipient_id
        );
END $$;
