-- Notify the submitting member when an Admin approves or rejects a product listing.
create or replace function private.notify_member_product_submission_status_change()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
declare
 v_title text;
 v_message text;
 v_notifications_enabled boolean:=false;
begin
 select coalesce((setting_value#>>'{}')::boolean,false) into v_notifications_enabled
 from public.app_settings where setting_key='notifications_enabled';
 if not coalesce(v_notifications_enabled,false) then return new;end if;
 if old.status is not distinct from new.status then return new;end if;
 if new.status='approved' then
  v_title:='Product listing approved';
  v_message:='Your product listing "'||left(new.name,150)||'" has been approved and published.';
 elsif new.status='rejected' then
  v_title:='Product listing needs attention';
  v_message:='Your product listing "'||left(new.name,150)||'" was not approved.'||
   case when nullif(btrim(new.review_note),'') is not null
    then ' Review note: '||left(btrim(new.review_note),300)
    else ' Please review the submission and contact support if you need clarification.' end;
 else
  return new;
 end if;
 if new.submitted_by is not null then
  insert into public.member_notifications(user_id,title,message,category)
  values(new.submitted_by,left(v_title,120),left(v_message,2000),'account');
 end if;
 return new;
end;
$function$;
revoke all on function private.notify_member_product_submission_status_change() from public,anon,authenticated;
drop trigger if exists notify_member_product_submission_status on public.product_submissions;
create trigger notify_member_product_submission_status
after update of status on public.product_submissions
for each row when(old.status is distinct from new.status)
execute function private.notify_member_product_submission_status_change();
