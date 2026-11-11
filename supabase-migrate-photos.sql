-- Migration: allow repair requests to include one optional evidence photo.
-- Run this in Supabase SQL Editor after the existing SchoolCare schema/migration.

alter table public.repair_requests
  add column if not exists image_url text;

-- Public bucket: images are intentionally viewable by anyone who can see a matching request.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('repair-photos', 'repair-photos', true, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = array['image/jpeg','image/png','image/webp'];

-- Anonymous users may upload only into a folder named with a request number.
-- No public update/delete permission is granted.
drop policy if exists "public upload repair evidence" on storage.objects;
create policy "public upload repair evidence"
on storage.objects for insert to anon, authenticated
with check (
  bucket_id = 'repair-photos'
  and array_length(storage.foldername(name), 1) = 1
  and length(storage.filename(name)) between 5 and 100
);

drop policy if exists "public read repair evidence" on storage.objects;
create policy "public read repair evidence"
on storage.objects for select to anon, authenticated
using (bucket_id = 'repair-photos');

-- Replace lookup function to return the optional image URL.
drop function if exists public.lookup_repair_request(text, text);
create function public.lookup_repair_request(p_request_number text, p_phone text)
returns table(
  request_number text, reporter text, phone text, category text, location text,
  subject text, details text, priority text, status text, created_at timestamptz,
  updated_at timestamptz, image_url text
)
language sql security definer set search_path=public as $$
  select r.request_number, r.reporter, r.phone, r.category, r.location,
         r.subject, r.details, r.priority, r.status, r.created_at,
         r.updated_at, r.image_url
  from public.repair_requests r
  where upper(r.request_number)=upper(trim(p_request_number))
    and regexp_replace(r.phone, '[^0-9]', '', 'g') = regexp_replace(trim(p_phone), '[^0-9]', '', 'g')
  limit 1;
$$;
revoke all on function public.lookup_repair_request(text,text) from public;
grant execute on function public.lookup_repair_request(text,text) to anon, authenticated;

notify pgrst, 'reload schema';
