-- Admin-only member profile editing. Account status and ID lifecycle are intentionally excluded.
create or replace function public.admin_update_member_profile(
 p_member_code text,
 p_display_name text,
 p_phone text default null
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $function$
declare
 v_uid uuid := auth.uid();
 v_member_code text := upper(trim(coalesce(p_member_code,'')));
 v_display_name text := trim(coalesce(p_display_name,''));
 v_phone text := nullif(trim(coalesce(p_phone,'')),'');
 v_owner_user_id uuid;
 v_old_name text;
 v_old_phone text;
 v_updated_at timestamptz;
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if v_member_code='' or length(v_member_code)>100 then
  raise exception 'A valid Main Member ID is required' using errcode='22023';
 end if;
 if v_display_name='' or length(v_display_name)>120 or (v_phone is not null and length(v_phone)>32) then
  raise exception 'Invalid member profile values' using errcode='22023';
 end if;
 select m.owner_user_id,p.display_name,p.phone,p.updated_at
 into v_owner_user_id,v_old_name,v_old_phone,v_updated_at
 from public.member_ids m
 join public.profiles p on p.id=m.owner_user_id
 where upper(m.member_code)=v_member_code and m.id_type='main'
 for update of p;
 if not found then
  raise exception 'Member Main ID or profile not found' using errcode='P0002';
 end if;
 if v_old_name is not distinct from v_display_name and v_old_phone is not distinct from v_phone then
  return jsonb_build_object('member_code',v_member_code,'display_name',v_display_name,'phone',v_phone,'updated_at',v_updated_at,'changed',false);
 end if;
 update public.profiles
 set display_name=v_display_name,phone=v_phone,updated_at=now()
 where id=v_owner_user_id
 returning updated_at into v_updated_at;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'member_profile_updated','profiles',v_owner_user_id,
  jsonb_build_object('member_code',v_member_code,
   'display_name_changed',v_old_name is distinct from v_display_name,
   'phone_changed',v_old_phone is distinct from v_phone));
 return jsonb_build_object('member_code',v_member_code,'display_name',v_display_name,'phone',v_phone,'updated_at',v_updated_at,'changed',true);
end;
$function$;
revoke all on function public.admin_update_member_profile(text,text,text) from public,anon;
grant execute on function public.admin_update_member_profile(text,text,text) to authenticated;
