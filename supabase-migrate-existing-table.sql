-- SchoolCare migration for an EXISTING repair_requests table
-- Run this in Supabase SQL Editor. It preserves existing requests.
begin;

do $$
begin
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='repair_requests' and column_name='request_no')
     and not exists (select 1 from information_schema.columns where table_schema='public' and table_name='repair_requests' and column_name='request_number') then
    alter table public.repair_requests rename column request_no to request_number;
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='repair_requests' and column_name='reporter_name')
     and not exists (select 1 from information_schema.columns where table_schema='public' and table_name='repair_requests' and column_name='reporter') then
    alter table public.repair_requests rename column reporter_name to reporter;
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='repair_requests' and column_name='contact')
     and not exists (select 1 from information_schema.columns where table_schema='public' and table_name='repair_requests' and column_name='phone') then
    alter table public.repair_requests rename column contact to phone;
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='repair_requests' and column_name='equipment')
     and not exists (select 1 from information_schema.columns where table_schema='public' and table_name='repair_requests' and column_name='category') then
    alter table public.repair_requests rename column equipment to category;
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='repair_requests' and column_name='department')
     and not exists (select 1 from information_schema.columns where table_schema='public' and table_name='repair_requests' and column_name='location') then
    alter table public.repair_requests rename column department to location;
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='repair_requests' and column_name='problem')
     and not exists (select 1 from information_schema.columns where table_schema='public' and table_name='repair_requests' and column_name='subject') then
    alter table public.repair_requests rename column problem to subject;
  end if;
end $$;

alter table public.repair_requests
  add column if not exists phone text not null default '',
  add column if not exists details text not null default '',
  add column if not exists priority text not null default 'ปกติ';

-- Fill any old records with safe values so the new form can read them.
update public.repair_requests set
  request_number = coalesce(nullif(request_number, ''), 'SC-OLD-' || id::text),
  reporter = coalesce(nullif(reporter, ''), 'ไม่ระบุ'),
  category = coalesce(nullif(category, ''), 'ไม่ระบุ'),
  location = coalesce(nullif(location, ''), 'ไม่ระบุ'),
  subject = coalesce(nullif(subject, ''), 'ไม่ระบุ'),
  details = coalesce(nullif(details, ''), coalesce(subject, '')),
  phone = coalesce(phone, ''),
  priority = coalesce(priority, 'ปกติ')
where request_number is null or reporter is null or category is null or location is null or subject is null or details is null or phone is null or priority is null;

create unique index if not exists repair_requests_request_number_unique_idx
  on public.repair_requests(request_number);

notify pgrst, 'reload schema';
commit;
