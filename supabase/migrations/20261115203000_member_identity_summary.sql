-- Return only the authenticated member's own identity and sponsor details.
-- No member-supplied user ID is accepted; sponsor and identity fields are read-only.
create or replace function public.member_get_my_identity()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'created_at', p.created_at,
    'main_member_code', main_id.member_code,
    'sponsor_member_code', sponsor.member_code,
    'sponsor_display_name', coalesce(sponsor_profile.display_name, '')
  )
  from public.profiles p
  left join public.member_ids main_id
    on main_id.id = p.main_member_id
   and main_id.owner_user_id = p.id
   and main_id.id_type = 'main'
  left join public.referrals r
    on r.referred_member_id = main_id.id
  left join public.member_ids sponsor
    on sponsor.id = r.referrer_member_id
   and sponsor.id_type = 'main'
  left join public.profiles sponsor_profile
    on sponsor_profile.id = sponsor.owner_user_id
  where p.id = auth.uid()
  limit 1;
$$;

revoke all on function public.member_get_my_identity() from public, anon;
grant execute on function public.member_get_my_identity() to authenticated;
