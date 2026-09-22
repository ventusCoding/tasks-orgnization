-- =====================================================================================================
-- T1.2.08 — Private Storage bucket `attachments` and path-scoped policies (arch §6.7, §7.4).
-- Object paths: `{user_id}/{attachment_id}/{file}` — the first folder must be the caller's uid.
--   upload = INSERT · download = SELECT · overwrite (upsert) = SELECT + UPDATE · delete = DELETE
-- Guarded: environments without the storage schema (plain Postgres) skip this migration's effects.
-- =====================================================================================================

do $$
begin
  if to_regclass('storage.buckets') is null or to_regclass('storage.objects') is null then
    raise notice 'storage schema not present: attachments bucket and policies skipped';
    return;
  end if;

  insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  values (
    'attachments', 'attachments', false,
    26214400,                                   -- 25 MB (Free plan maximum is 50 MB)
    array[
      'image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif', 'image/gif',
      'application/pdf', 'text/plain', 'text/markdown', 'text/csv', 'application/json',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.ms-powerpoint',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'application/zip',
      'audio/mpeg', 'audio/mp4', 'audio/aac', 'audio/wav', 'audio/x-m4a',
      'video/mp4', 'video/quicktime'
    ]::text[])
  on conflict (id) do update
    set public = excluded.public,
        file_size_limit = excluded.file_size_limit,
        allowed_mime_types = excluded.allowed_mime_types;

  drop policy if exists attachments_select_own on storage.objects;
  create policy attachments_select_own on storage.objects
    for select to authenticated
    using (bucket_id = 'attachments' and (storage.foldername(name))[1] = (select auth.uid())::text);

  drop policy if exists attachments_insert_own on storage.objects;
  create policy attachments_insert_own on storage.objects
    for insert to authenticated
    with check (bucket_id = 'attachments' and (storage.foldername(name))[1] = (select auth.uid())::text);

  drop policy if exists attachments_update_own on storage.objects;
  create policy attachments_update_own on storage.objects
    for update to authenticated
    using (bucket_id = 'attachments' and (storage.foldername(name))[1] = (select auth.uid())::text)
    with check (bucket_id = 'attachments' and (storage.foldername(name))[1] = (select auth.uid())::text);

  drop policy if exists attachments_delete_own on storage.objects;
  create policy attachments_delete_own on storage.objects
    for delete to authenticated
    using (bucket_id = 'attachments' and (storage.foldername(name))[1] = (select auth.uid())::text);
end
$$;
