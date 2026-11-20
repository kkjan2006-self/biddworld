-- Minimize public sponsor lookup disclosure: return only a validity boolean.
-- The Auth signup trigger independently revalidates the sponsor before linking.
-- Source-only; do not apply until full Production migration reconciliation.
drop function if exists public.lookup_sponsor(text);

create function public.lookup_sponsor(p_member_code text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1
    from public.member_ids m
    where upper(m.member_code) = upper(trim(p_member_code))
      and m.id_type = 'main'
      and m.status = 'active'
  );
$function$;

revoke all on function public.lookup_sponsor(text) from public, anon, authenticated;
grant execute on function public.lookup_sponsor(text) to anon, authenticated;

comment on function public.lookup_sponsor(text) is
  'Public signup helper; returns only whether an exact active Main ID exists. Signup trigger independently validates and links the sponsor. IP-based rate limiting remains an edge/API gateway responsibility.';
