-- 모바일 초대장 DB 스키마 (Supabase → SQL Editor에 통째로 붙여넣고 Run)

-- 초대장: 만든 사람(owner)만 읽고 쓴다. 참석자는 아래 get_invite 함수로 '공개 중인 한 장'만 받는다.
create table if not exists public.invites (
  id          uuid primary key default gen_random_uuid(),
  owner       uuid not null references auth.users(id) on delete cascade,
  slug        text not null unique check (slug ~ '^[A-Za-z0-9]{4,16}$'),
  tpl         text not null default 'homeparty',
  tier        text not null default 'free' check (tier in ('free','basic','premium')),
  period      text not null default '0',
  data        jsonb not null default '{}'::jsonb,
  published   boolean not null default false,
  expires_at  timestamptz,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index if not exists invites_owner_idx on public.invites(owner, updated_at desc);

-- 참석 응답: 기기마다 한 줄(같은 기기에서 다시 응답하면 덮어씀)
create table if not exists public.rsvps (
  id          uuid primary key default gen_random_uuid(),
  invite_id   uuid not null references public.invites(id) on delete cascade,
  device_id   text not null check (char_length(device_id) between 4 and 64),
  name        text not null check (char_length(name) between 1 and 40),
  status      text not null check (status in ('yes','no')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (invite_id, device_id)
);

alter table public.invites enable row level security;
alter table public.rsvps   enable row level security;

drop policy if exists "owner manages own invites" on public.invites;
create policy "owner manages own invites" on public.invites
  for all to authenticated using (owner = auth.uid()) with check (owner = auth.uid());

drop policy if exists "owner reads own rsvps" on public.rsvps;
create policy "owner reads own rsvps" on public.rsvps
  for select to authenticated
  using (exists (select 1 from public.invites i where i.id = invite_id and i.owner = auth.uid()));
-- rsvps에는 insert/update 정책이 없음 → 참석자는 아래 upsert_rsvp 함수로만 응답 가능

-- 참석자: 공개 중이고 기간이 남은 초대장 한 장만 slug로 조회 (목록 조회는 불가)
create or replace function public.get_invite(p_slug text)
returns table (tpl text, tier text, data jsonb, expires_at timestamptz)
language sql stable security definer set search_path = public as $$
  select i.tpl, i.tier, i.data, i.expires_at from public.invites i
  where i.slug = p_slug and i.published and (i.expires_at is null or i.expires_at > now());
$$;

-- 참석자: 응답 저장/수정
create or replace function public.upsert_rsvp(p_slug text, p_device text, p_name text, p_status text)
returns void language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  select id into v_id from public.invites
   where slug = p_slug and published and (expires_at is null or expires_at > now());
  if v_id is null then raise exception 'invite_not_available'; end if;
  insert into public.rsvps (invite_id, device_id, name, status)
  values (v_id, p_device, left(btrim(p_name), 40), p_status)
  on conflict (invite_id, device_id)
  do update set name = excluded.name, status = excluded.status, updated_at = now();
end $$;

-- 참석자: 참석/미참석 인원 수만 공개 (이름은 초대자만 봄)
create or replace function public.rsvp_counts(p_slug text)
returns table (yes bigint, no bigint)
language sql stable security definer set search_path = public as $$
  select count(*) filter (where r.status = 'yes'), count(*) filter (where r.status = 'no')
  from public.rsvps r join public.invites i on i.id = r.invite_id
  where i.slug = p_slug and i.published and (i.expires_at is null or i.expires_at > now());
$$;

revoke all on function public.get_invite(text) from public;
revoke all on function public.upsert_rsvp(text, text, text, text) from public;
revoke all on function public.rsvp_counts(text) from public;
grant execute on function public.get_invite(text) to anon, authenticated;
grant execute on function public.upsert_rsvp(text, text, text, text) to anon, authenticated;
grant execute on function public.rsvp_counts(text) to anon, authenticated;
