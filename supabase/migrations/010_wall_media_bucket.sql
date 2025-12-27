-- Create a customized storage bucket for wall media
insert into storage.buckets (id, name, public)
values ('wall_media', 'wall_media', true);

-- Policy to allow anyone to view media (images in wall posts are public/visible to app users)
create policy "Media Global View"
  on storage.objects for select
  using ( bucket_id = 'wall_media' );

-- Policy to allow authenticated users to upload media
create policy "Media User Upload"
  on storage.objects for insert
  with check ( bucket_id = 'wall_media' and auth.role() = 'authenticated' );

-- Policy to allow users to update their own media (rarely used but good practice)
create policy "Media User Update"
  on storage.objects for update
  using ( bucket_id = 'wall_media' and auth.uid() = owner );

-- Policy to allow users to delete their own media
create policy "Media User Delete"
  on storage.objects for delete
  using ( bucket_id = 'wall_media' and auth.uid() = owner );
