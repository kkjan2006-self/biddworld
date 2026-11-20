-- Bound the Admin product moderation queue and provide deterministic keyset pagination.
create or replace function public.admin_list_product_submissions_page(
 p_limit integer default 50,
 p_before_created_at timestamptz default null,
 p_before_id uuid default null
) returns table(
 id uuid,submitted_by uuid,member_id uuid,name text,description text,category text,
 image_paths text[],optional_details jsonb,status text,review_note text,reviewed_by uuid,
 reviewed_at timestamptz,product_id uuid,created_at timestamptz,updated_at timestamptz,
 has_more boolean
) language plpgsql stable security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid();v_limit integer:=coalesce(p_limit,50);
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if v_limit<1 or v_limit>100 then
  raise exception 'Page size must be between 1 and 100' using errcode='22023';
 end if;
 if (p_before_created_at is null)<>(p_before_id is null) then
  raise exception 'Both pagination cursor fields must be supplied together' using errcode='22023';
 end if;
 return query
 with page as (
  select s.*,count(*) over() as total_count
  from public.product_submissions s
  where s.status='pending'
   and (p_before_created_at is null or (s.created_at,s.id)>(p_before_created_at,p_before_id))
  order by s.created_at,s.id
  limit v_limit+1
 )
 select page.id,page.submitted_by,page.member_id,page.name,page.description,page.category,
  page.image_paths,page.optional_details,page.status,page.review_note,page.reviewed_by,
  page.reviewed_at,page.product_id,page.created_at,page.updated_at,(page.total_count>v_limit)
 from page order by page.created_at,page.id limit v_limit;
end;
$function$;
revoke all on function public.admin_list_product_submissions_page(integer,timestamptz,uuid) from public,anon;
grant execute on function public.admin_list_product_submissions_page(integer,timestamptz,uuid) to authenticated;
