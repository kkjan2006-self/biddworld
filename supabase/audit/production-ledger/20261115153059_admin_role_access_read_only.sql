create or replace function public.admin_list_admin_accounts()
returns table(user_id uuid,email text,created_at timestamptz,last_sign_in_at timestamptz,app_role text)
language plpgsql security definer set search_path=''
as $$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Admin access required' using errcode='42501';
 end if;
 return query
 select u.id,u.email,u.created_at,u.last_sign_in_at,coalesce(u.raw_app_meta_data->>'role','member')
 from auth.users u
 where coalesce(u.raw_app_meta_data->>'role','')='admin'
 and u.deleted_at is null
 order by u.created_at;
end;
$$;
revoke all on function public.admin_list_admin_accounts() from public,anon;
grant execute on function public.admin_list_admin_accounts() to authenticated;
