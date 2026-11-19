-- Notify the winner when an Auction or Fixed Bid winner payment is created or completed.
create or replace function private.notify_member_winning_item_payment_status()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
declare
 v_user_id uuid;
 v_title text;
 v_message text;
 v_item_title text;
 v_notifications_enabled boolean:=false;
begin
 select coalesce((setting_value#>>'{}')::boolean,false) into v_notifications_enabled
 from public.app_settings where setting_key='notifications_enabled';
 if not coalesce(v_notifications_enabled,false) then return new;end if;
 select owner_user_id into v_user_id from public.member_ids where id=new.winner_member_id;
 if v_user_id is null then return new;end if;
 if tg_op='INSERT' then
  if new.status<>'pending' then return new;end if;
  if new.auction_id is not null then
   select title into v_item_title from public.auctions where id=new.auction_id;
   v_title:='You won an Auction';
  elsif new.fixed_bid_campaign_id is not null then
   select title into v_item_title from public.fixed_bid_campaigns where id=new.fixed_bid_campaign_id;
   v_title:='You won a Fixed Bid campaign';
  else
   v_title:='You have been selected as a winner';
  end if;
  v_message:='You have been selected as a winner'||case when nullif(btrim(v_item_title),'') is not null then ' for "'||left(v_item_title,150)||'"' else '' end||'. Complete the winning payment from your Main Wallet.';
 elsif tg_op='UPDATE' then
  if old.status is not distinct from new.status then return new;end if;
  if new.status='paid' then
   v_title:='Winning payment confirmed';
   v_message:='Your winning payment of '||new.amount::text||' has been completed from your Main Wallet.';
  elsif new.status='refunded' then
   v_title:='Winning payment refunded';
   v_message:='Your winning payment has been refunded to your Main Wallet.';
  else
   return new;
  end if;
 else
  return new;
 end if;
 insert into public.member_notifications(user_id,title,message,category)
 values(v_user_id,left(v_title,120),left(v_message,2000),'account');
 return new;
end;
$function$;
revoke all on function private.notify_member_winning_item_payment_status() from public,anon,authenticated;
drop trigger if exists notify_member_winning_item_payment_status on public.winning_item_payments;
create trigger notify_member_winning_item_payment_status
after insert or update of status on public.winning_item_payments
for each row execute function private.notify_member_winning_item_payment_status();
