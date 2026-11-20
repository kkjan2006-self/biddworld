-- Owner-scoped bounded keyset pagination for the Member auction submission history.
create or replace function public.member_list_own_auction_submissions_page(
 p_limit integer default 50,
 p_before_created_at timestamptz default null,
 p_before_id uuid default null
) returns table(
 id uuid,title text,description text,category text,image_paths text[],
 starting_price numeric,expected_price numeric,minimum_increment numeric,
 starts_at timestamptz,ends_at timestamptz,status text,review_note text,
 created_at timestamptz,optional_details jsonb,has_more boolean
) language plpgsql stable security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid();v_limit integer:=coalesce(p_limit,50);
begin
 if v_uid is null then raise exception 'Authentication required' using errcode='42501';end if;
 if v_limit<1 or v_limit>100 then raise exception 'Page size must be between 1 and 100' using errcode='22023';end if;
 if (p_before_created_at is null)<>(p_before_id is null) then
  raise exception 'Both pagination cursor fields must be supplied together' using errcode='22023';
 end if;
 return query
 with page as (
  select s.id,s.title,s.description,s.category,s.image_paths,s.starting_price,s.expected_price,
   s.minimum_increment,s.starts_at,s.ends_at,s.status,s.review_note,s.created_at,s.optional_details,
   count(*) over() as total_count
  from public.auction_submissions s
  where s.submitted_by=v_uid
   and (p_before_created_at is null or (s.created_at,s.id)<(p_before_created_at,p_before_id))
  order by s.created_at desc,s.id desc
  limit v_limit+1
 )
 select page.id,page.title,page.description,page.category,page.image_paths,page.starting_price,
  page.expected_price,page.minimum_increment,page.starts_at,page.ends_at,page.status,page.review_note,
  page.created_at,page.optional_details,(page.total_count>v_limit)
 from page order by page.created_at desc,page.id desc limit v_limit;
end;
$function$;
revoke all on function public.member_list_own_auction_submissions_page(integer,timestamptz,uuid) from public,anon;
grant execute on function public.member_list_own_auction_submissions_page(integer,timestamptz,uuid) to authenticated;
comment on function public.member_list_own_auction_submissions_page(integer,timestamptz,uuid) is
 'Member-only bounded keyset history for auction submissions; rows are scoped to auth.uid().';
