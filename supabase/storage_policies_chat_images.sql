-- =====================================================================
-- Storage Policies for community-media bucket (chat images)
-- Description: Allow users to upload and view chat images
-- =====================================================================

-- IMPORTANT: Execute these policies in Supabase Dashboard → Storage → community-media → Policies

-- Policy 1: Allow authenticated users to upload images to chat_uploads/
CREATE POLICY "Authenticated users can upload chat images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'community-media' 
  AND (storage.foldername(name))[1] = 'chat_uploads'
);

-- Policy 2: Allow everyone to view chat images (public read)
CREATE POLICY "Anyone can view chat images"
ON storage.objects FOR SELECT
TO public
USING (
  bucket_id = 'community-media' 
  AND (storage.foldername(name))[1] = 'chat_uploads'
);

-- Policy 3: Allow users to delete their own uploaded images (optional)
CREATE POLICY "Users can delete their own chat images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'community-media' 
  AND (storage.foldername(name))[1] = 'chat_uploads'
  AND auth.uid()::text = (storage.foldername(name))[2]
);
