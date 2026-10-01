-- =====================================================================================================
-- T2.2.12 / T2.2.13 / T2.2.14 — media attachments: short videos (≤ 50 MB, ≤ 60 s), voice notes and
-- scanned PDFs. The bucket limit rises to 50 MB (the Free plan maximum); the app keeps 25 MB for every
-- other type (`AttachmentLimits.maxBytesFor`). More video/audio containers the platform recorders and
-- pickers produce join the allow-list.
-- =====================================================================================================

do $$
begin
  if to_regclass('storage.buckets') is null then
    raise notice 'storage schema not present: attachments bucket limits skipped';
    return;
  end if;

  update storage.buckets
     set file_size_limit = 52428800,             -- 50 MB
         allowed_mime_types = (
           select array_agg(distinct m order by m)
             from unnest(allowed_mime_types || array[
               'video/mp4', 'video/quicktime', 'video/3gpp', 'video/webm',
               'audio/mp4', 'audio/x-m4a', 'audio/aac', 'audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/webm',
               'audio/3gpp'
             ]::text[]) as m
         )
   where id = 'attachments';
end
$$;
