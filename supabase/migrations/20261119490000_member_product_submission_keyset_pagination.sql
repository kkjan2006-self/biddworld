-- Paginate the authenticated member's own private product submission history.
create or replace function public.member_list_own_product_submissions_page(
 p_limit integer default 50,
 p_before_created_at timestamptz default null,
 p_before_id uuid default null
) returns table(
 id uuid,name text,description text,category text,image_paths text[],status text,
 review_note text,created_at timestamptz,optional_details jsonb,has_more boolean
) language plpgsql stable security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid();v_limit integer:=coalesce(p_limit,50);
begin
 if v_uid is null then raise exception 'Sign in is required' using errcode='42501';end if;
 if v_limit<1 or v_limit>100 then raise exception 'Page size must be between 1 and 100' using errcode='22023';end if;
 if (p_before_created_at is null)<>(p_before_id is null) then
  raise exception 'Both pagination cursor fields must be supplied together' using errcode='22023';
 end if;
 return query
 with page as (
  select s.id,s.name,s.description,s.category,s.image_paths,s.status,s.review_note,
   s.created_at,s.optional_details,count(*) over() as total_count
  from public.product_submissions s
  where s.submitted_by=v_uid
   and (p_before_created_at is null or (s.created_at,s.id)<(p_before_created_at,p_before_id))
  order by s.created_at desc,s.id desc
  limit v_limit+1
 )
 select page.id,page.name,page.description,page.category,page.image_paths,page.status,
  page.review_note,page.created_at,page.optional_details,(page.total_count>v_limit)
 from page order by page.created_at desc,page.id desc limit v_limit;
end;
$function$;
revoke all on function public.member_list_own_product_submissions_page(integer,timestamptz,uuid) from public,anon;
grant execute on function public.member_list_own_product_submissions_page(integer,timestamptz,uuid) to authenticated;
