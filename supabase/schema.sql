-- Schema for the yeet-trip-dates Supabase project.
-- Replace <ADMIN_PASSWORD_SHA256> with the hex SHA-256 of Adeev's password before running.

create table public.availability (
  name text primary key check (name in ('Aarav','Adeev','Aryan','Darseel','Prithvi','Rajveer','Vivan')),
  dates date[] not null default '{}',
  updated_at timestamptz not null default now()
);
alter table public.availability enable row level security;
-- no policies: the table is unreachable directly from the public API; all access goes through the functions below
revoke all on public.availability from anon, authenticated;

create or replace function public._is_admin(p_password text) returns boolean
language sql immutable set search_path = '' as $$
  select coalesce(encode(sha256(convert_to(p_password,'UTF8')),'hex') = '<ADMIN_PASSWORD_SHA256>', false)
$$;

create or replace function public.check_admin(p_password text) returns boolean
language sql security definer set search_path = '' as $$ select public._is_admin(p_password) $$;

create or replace function public.get_dates(p_name text, p_password text default null) returns text[]
language plpgsql security definer set search_path = '' as $$
declare r text[];
begin
  if p_name = 'Adeev' and not public._is_admin(p_password) then raise exception 'wrong password'; end if;
  select array(select to_char(d,'YYYY-MM-DD') from unnest(a.dates) d order by d) into r
  from public.availability a where a.name = p_name;
  return coalesce(r, '{}');
end $$;

create or replace function public.save_dates(p_name text, p_dates text[], p_password text default null) returns void
language plpgsql security definer set search_path = '' as $$
declare clean date[];
begin
  if p_name not in ('Aarav','Adeev','Aryan','Darseel','Prithvi','Rajveer','Vivan') then raise exception 'unknown name'; end if;
  if p_name = 'Adeev' and not public._is_admin(p_password) then raise exception 'wrong password'; end if;
  select coalesce(array_agg(distinct d order by d), '{}') into clean
  from unnest(coalesce(p_dates,'{}')) s, lateral (select s::date d) x
  where d between date '2026-12-12' and date '2027-01-10';
  insert into public.availability(name, dates, updated_at) values (p_name, clean, now())
  on conflict (name) do update set dates = excluded.dates, updated_at = now();
end $$;

create or replace function public.get_all(p_password text)
returns table(name text, dates text[], updated_at timestamptz)
language plpgsql security definer set search_path = '' as $$
begin
  if not public._is_admin(p_password) then raise exception 'wrong password'; end if;
  return query select a.name, array(select to_char(d,'YYYY-MM-DD') from unnest(a.dates) d order by d), a.updated_at
    from public.availability a order by a.name;
end $$;

revoke all on function public._is_admin(text) from public, anon, authenticated;
revoke all on function public.check_admin(text) from public;
revoke all on function public.get_dates(text,text) from public;
revoke all on function public.save_dates(text,text[],text) from public;
revoke all on function public.get_all(text) from public;
grant execute on function public.check_admin(text) to anon, authenticated;
grant execute on function public.get_dates(text,text) to anon, authenticated;
grant execute on function public.save_dates(text,text[],text) to anon, authenticated;
grant execute on function public.get_all(text) to anon, authenticated;
