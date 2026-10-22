-- SchoolCare: repair the public tracking lookup function
-- Run this in Supabase Dashboard > SQL Editor > New query.
-- This does not delete or recreate repair_requests and preserves existing data.

create or replace function public.lookup_repair_request(
  p_request_number text,
  p_phone text
)
returns table(
  request_number text,
  reporter text,
  phone text,
  category text,
  location text,
  subject text,
  details text,
  priority text,
  status text,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
security definer
set search_path = public
as $function$
  select
    r.request_number,
    r.reporter,
    r.phone,
    r.category,
    r.location,
    r.subject,
    r.details,
    r.priority,
    r.status,
    r.created_at,
    r.updated_at
  from public.repair_requests as r
  where upper(r.request_number) = upper(trim(p_request_number))
    and regexp_replace(coalesce(r.phone, ''), '[^0-9]', '', 'g')
      = regexp_replace(coalesce(trim(p_phone), ''), '[^0-9]', '', 'g')
  limit 1;
$function$;

revoke all on function public.lookup_repair_request(text, text) from public;
grant usage on schema public to anon, authenticated;
grant execute on function public.lookup_repair_request(text, text) to anon, authenticated;

notify pgrst, 'reload schema';
