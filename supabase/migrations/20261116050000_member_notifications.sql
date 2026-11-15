-- BiddWorld in-app member notifications. Non-financial, additive and not applied to Production by this commit.
create table if not exists public.member_notifications (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 title text not null check (char_length(btrim(title)) between 3 and 120),
 message text not null check (char_length(btrim(message)) between 5 and 2000),
 category text not null default 'general' check (category in ('general','account','support','security')),
 read_at timestamptz,
 created_at timestamptz not null default now()
);
create index if not exists member_notifications_user_created_idx
 on public.member_notifications(user_id,created_at desc);
create index if not exists member_notifications_unread_idx
 on public.member_notifications(user_id,created_at desc) where read_at is null;
alter table public.member_notifications enable row level security;
revoke all on public.member_notifications from public,anon,authenticated;
grant select on public.member_notifications to authenticated;
grant insert (user_id,title,message,category) on public.member_notifications to authenticated;
grant update (read_at) on public.member_notifications to authenticated;
drop policy if exists member_notifications_read_owner_or_admin on public.member_notifications;
create policy member_notifications_read_owner_or_admin on public.member_notifications
 for select to authenticated using (
  user_id=(select auth.uid()) or coalesce((select auth.jwt()->'app_metadata'->>'role'),'')='admin'
);
drop policy if exists member_notifications_insert_admin on public.member_notifications;
create policy member_notifications_insert_admin on public.member_notifications
 for insert to authenticated with check (
  coalesce((select auth.jwt()->'app_metadata'->>'role'),'')='admin'
);
drop policy if exists member_notifications_mark_read_owner on public.member_notifications;
create policy member_notifications_mark_read_owner on public.member_notifications
 for update to authenticated using (user_id=(select auth.uid()))
 with check (user_id=(select auth.uid()));
