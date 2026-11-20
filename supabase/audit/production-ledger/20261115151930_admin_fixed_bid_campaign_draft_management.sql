create or replace function public.admin_list_fixed_bid_campaigns()
returns table(campaign_id uuid,product_id uuid,product_name text,title text,description text,status text,configuration jsonb,created_at timestamptz,updated_at timestamptz)
language plpgsql security definer set search_path=''
as $$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then raise exception 'Administrator access required' using errcode='42501'; end if;
 return query select c.id,c.product_id,p.name,c.title,c.description,c.status,c.configuration,c.created_at,c.updated_at
 from public.fixed_bid_campaigns c join public.products p on p.id=c.product_id order by c.created_at desc;
end; $$;

create or replace function public.admin_save_fixed_bid_campaign_draft(p_campaign_id uuid,p_product_id uuid,p_title text,p_description text)
returns uuid language plpgsql security definer set search_path=''
as $$
declare v_id uuid;
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then raise exception 'Administrator access required' using errcode='42501'; end if;
 if p_product_id is null or not exists(select 1 from public.products where id=p_product_id and status='draft') then raise exception 'Select a draft product' using errcode='22023'; end if;
 if length(trim(coalesce(p_title,'')))<3 or length(trim(p_title))>180 then raise exception 'Campaign title must be 3 to 180 characters' using errcode='22023'; end if;
 if length(coalesce(p_description,''))>5000 then raise exception 'Description is too long' using errcode='22023'; end if;
 if p_campaign_id is null then
  insert into public.fixed_bid_campaigns(product_id,title,description,status,configuration)
  values(p_product_id,trim(p_title),nullif(trim(coalesce(p_description,'')),''),'draft','{}'::jsonb) returning id into v_id;
 else
  update public.fixed_bid_campaigns set product_id=p_product_id,title=trim(p_title),description=nullif(trim(coalesce(p_description,'')),''),updated_at=now()
  where id=p_campaign_id and status='draft' returning id into v_id;
  if v_id is null then raise exception 'Only existing draft campaigns can be edited' using errcode='22023'; end if;
 end if;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(auth.uid(),case when p_campaign_id is null then 'fixed_bid_campaign.draft_created' else 'fixed_bid_campaign.draft_updated' end,'fixed_bid_campaign',v_id,jsonb_build_object('title',trim(p_title),'status','draft'));
 return v_id;
end; $$;

revoke all on function public.admin_list_fixed_bid_campaigns() from public,anon;
revoke all on function public.admin_save_fixed_bid_campaign_draft(uuid,uuid,text,text) from public,anon;
grant execute on function public.admin_list_fixed_bid_campaigns() to authenticated;
grant execute on function public.admin_save_fixed_bid_campaign_draft(uuid,uuid,text,text) to authenticated;
