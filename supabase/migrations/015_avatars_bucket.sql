-- ============================================================================
-- 015_AVATARS_BUCKET.sql
--
-- Ensures 'avatars' storage bucket exists and is public to allow user uploads.
-- ============================================================================

-- 1. Create Bucket if not exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO UPDATE
SET public = true;

-- 2. Policy: Public Access (Select)
-- Allow anyone to view avatars
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'avatars' );

-- 3. Policy: User Upload (Insert)
-- Allow authenticated users to upload to 'avatars'
DROP POLICY IF EXISTS "User Upload" ON storage.objects;
CREATE POLICY "User Upload"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'avatars' 
    AND auth.role() = 'authenticated'
);

-- 4. Policy: User Update (Update)
-- Allow users to update their own files (optional, depending on file naming strategy)
DROP POLICY IF EXISTS "User Update" ON storage.objects;
CREATE POLICY "User Update"
ON storage.objects FOR UPDATE
USING ( bucket_id = 'avatars' AND auth.uid() = owner )
WITH CHECK ( bucket_id = 'avatars' AND auth.uid() = owner );

-- 5. Policy: User Delete (Delete)
-- Allow users to delete their own files
DROP POLICY IF EXISTS "User Delete" ON storage.objects;
CREATE POLICY "User Delete"
ON storage.objects FOR DELETE
USING ( bucket_id = 'avatars' AND auth.uid() = owner );
