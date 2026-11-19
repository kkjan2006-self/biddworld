-- Bounded keyset pagination for the Admin auction submission moderation queue.
create or replace function public.admin_list_auction_submissions_page(
 p_limit integer default 50,
 p_after_created_at timestamptz default null,
 p_after_id uuid default null
) returns jsonb
language plpgsql stable security definer set search_path=''
as $function$
declare
 v_role text:=coalesce(auth.jwt()->'app_metadata'->>'role','');
 v_rows jsonb;
 v_has_more boolean;
 v_last_created_at timestamptz;
 v_last_id uuid;
begin
 if auth.uid() is null or not(
  v_role='admin' or
  (v_role='admin_staff' and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'auction_submission_review')
 ) then
  raise exception 'Auction submission review permission required' using errcode='42501';
 end if;
 if p_limit is null or p_limit<1 or p_limit>100 then
  raise exception 'Page size must be between 1 and 100' using errcode='22023';
 end if;
 if (p_after_created_at is null)<>(p_after_id is null) then
  raise exception 'Both cursor fields must be supplied together' using errcode='22023';
 end if;
 with page as (
  select s.* from public.auction_submissions s
  where s.status='pending'
   and (p_after_created_at is null or (s.created_at,s.id)>(p_after_created_at,p_after_id))
  order by s.created_at,s.id
  limit p_limit+1
 ), numbered as (
  select page.*,row_number() over(order by created_at,id) as rn from page
 ), kept as (
  select * from numbered where rn<=p_limit
 )
 select
  coalesce((select jsonb_agg(to_jsonb(k)-'rn' order by k.created_at,k.id) from kept k),'[]'::jsonb),
  (select count(*)>p_limit from page),
  (select k.created_at from kept k order by k.created_at desc,k.id desc limit 1),
  (select k.id from kept k order by k.created_at desc,k.id desc limit 1)
 into v_rows,v_has_more,v_last_created_at,v_last_id;
 return jsonb_build_object(
  'items',v_rows,'has_more',coalesce(v_has_more,false),
  'next_created_at',case when coalesce(v_has_more,false) then v_last_created_at else null end,
  'next_id',case when coalesce(v_has_more,false) then v_last_id else null end
 );
end;
$function$;
revoke all on function public.admin_list_auction_submissions_page(integer,timestamptz,uuid) from public,anon;
grant execute on function public.admin_list_auction_submissions_page(integer,timestamptz,uuid) to authenticated;
