-- SchoolCare central database (Supabase / PostgreSQL)
-- Run in Supabase SQL Editor. Keep RLS enabled. Never expose service_role key in browser code.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  role text not null default 'requester' check (role in ('requester','staff')),
  created_at timestamptz not null default now()
);

create table if not exists public.repair_requests (
  id uuid primary key default gen_random_uuid(),
  request_number text not null unique,
  reporter text not null,
  phone text not null default '',
  category text not null,
  location text not null,
  subject text not null,
  details text not null,
  priority text not null default 'ปกติ' check (priority in ('ปกติ','เร่งด่วน','เร่งด่วนมาก')),
  status text not null default 'รอรับเรื่อง' check (status in ('รอรับเรื่อง','กำลังตรวจสอบ','กำลังดำเนินการซ่อม','ซ่อมเสร็จแล้ว','ไม่สามารถซ่อมได้')),
  assigned_to uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists repair_requests_created_at_idx on public.repair_requests(created_at desc);
create index if not exists repair_requests_status_idx on public.repair_requests(status);
create index if not exists repair_requests_request_number_idx on public.repair_requests(request_number);

create or replace function public.touch_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;
drop trigger if exists repair_requests_touch_updated_at on public.repair_requests;
create trigger repair_requests_touch_updated_at before update on public.repair_requests for each row execute function public.touch_updated_at();

alter table public.profiles enable row level security;
alter table public.repair_requests enable row level security;

-- SECURITY DEFINER helper avoids recursive RLS policy checks on profiles.
create or replace function public.is_schoolcare_staff(uid uuid default auth.uid())
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.profiles p where p.id=uid and p.role='staff');
$$;
revoke all on function public.is_schoolcare_staff(uuid) from public;
grant execute on function public.is_schoolcare_staff(uuid) to authenticated;

drop policy if exists "profile self or staff read" on public.profiles;
create policy "profile self or staff read" on public.profiles for select to authenticated
using (id = auth.uid() or public.is_schoolcare_staff(auth.uid()));
drop policy if exists "staff update profiles" on public.profiles;
create policy "staff update profiles" on public.profiles for update to authenticated
using (public.is_schoolcare_staff(auth.uid()))
with check (public.is_schoolcare_staff(auth.uid()));

drop policy if exists "public can submit repair requests" on public.repair_requests;
create policy "public can submit repair requests" on public.repair_requests for insert to anon, authenticated
with check (length(trim(reporter)) between 2 and 120 and length(trim(subject)) between 2 and 180 and length(trim(details)) between 2 and 5000);
drop policy if exists "staff read repair requests" on public.repair_requests;
create policy "staff read repair requests" on public.repair_requests for select to authenticated
using (exists(select 1 from public.profiles me where me.id=auth.uid() and me.role='staff'));
drop policy if exists "staff update repair requests" on public.repair_requests;
create policy "staff update repair requests" on public.repair_requests for update to authenticated
using (exists(select 1 from public.profiles me where me.id=auth.uid() and me.role='staff'))
with check (exists(select 1 from public.profiles me where me.id=auth.uid() and me.role='staff'));

-- Public lookup reveals only the exact matching request when request number AND phone match.
create or replace function public.lookup_repair_request(p_request_number text, p_phone text)
returns table(request_number text, reporter text, phone text, category text, location text, subject text, details text, priority text, status text, created_at timestamptz, updated_at timestamptz)
language sql security definer set search_path=public as $$
  select r.request_number, r.reporter, r.phone, r.category, r.location, r.subject, r.details, r.priority, r.status, r.created_at, r.updated_at
  from public.repair_requests r
  where upper(r.request_number)=upper(trim(p_request_number)) and regexp_replace(r.phone, '[^0-9]', '', 'g')=regexp_replace(trim(p_phone), '[^0-9]', '', 'g')
  limit 1;
$$;
revoke all on function public.lookup_repair_request(text,text) from public;
grant execute on function public.lookup_repair_request(text,text) to anon, authenticated;

-- Only aggregate totals are exposed on the public home page; no request details.
create or replace function public.public_repair_stats()
returns table(total bigint, pending bigint, done bigint)
language sql security definer set search_path=public as $$
  select count(*)::bigint,
    count(*) filter (where status not in ('ซ่อมเสร็จแล้ว','ไม่สามารถซ่อมได้'))::bigint,
    count(*) filter (where status='ซ่อมเสร็จแล้ว')::bigint
  from public.repair_requests;
$$;
revoke all on function public.public_repair_stats() from public;
grant execute on function public.public_repair_stats() to anon, authenticated;

grant usage on schema public to anon, authenticated;
grant insert on public.repair_requests to anon, authenticated;
grant select, update on public.repair_requests to authenticated;
grant select, update on public.profiles to authenticated;
-- For realtime dashboard updates, enable repair_requests in Database > Publications > supabase_realtime if not already enabled.
