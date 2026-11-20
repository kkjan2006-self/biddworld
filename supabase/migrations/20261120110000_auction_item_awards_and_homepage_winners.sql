-- Auctions award the listed item to the highest eligible bidder; no separate winner-payment record is created.
-- Fixed Bid campaign winner-payment workflows remain unchanged.
create or replace function public.admin_finalize_auction(p_auction_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid();
 v_auction public.auctions%rowtype;
 v_bid public.bids%rowtype;
 v_result public.auction_winner_results%rowtype;
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 select * into v_auction from public.auctions where id=p_auction_id for update;
 if not found then raise exception 'Auction not found' using errcode='P0002'; end if;
 if v_auction.status<>'ended' or v_auction.ends_at is null or now()<v_auction.ends_at then
  raise exception 'Only a fully ended auction can be finalized' using errcode='55000';
 end if;
 select * into v_result from public.auction_winner_results where auction_id=p_auction_id;
 if found then
  return jsonb_build_object('success',true,'auction_id',p_auction_id,'winner_member_id',v_result.winner_member_id,
   'winning_bid_id',v_result.winning_bid_id,'winning_amount',v_result.winning_amount,'replayed',true);
 end if;
 select * into v_bid from public.bids
 where auction_id=p_auction_id and status='accepted'
 order by bid_amount desc,created_at asc,id asc limit 1 for update;
 insert into public.auction_winner_results(auction_id,winning_bid_id,winner_member_id,winning_amount,finalized_by)
 values(p_auction_id,case when found then v_bid.id else null end,
  case when found then v_bid.member_id else null end,
  case when found then v_bid.bid_amount else null end,v_uid)
 returning * into v_result;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'auction.finalized','auctions',p_auction_id,
  jsonb_build_object('winner_member_id',v_result.winner_member_id,'winning_bid_id',v_result.winning_bid_id,
   'winning_amount',v_result.winning_amount,'item_awarded',v_result.winner_member_id is not null));
 return jsonb_build_object('success',true,'auction_id',p_auction_id,'winner_member_id',v_result.winner_member_id,
  'winning_bid_id',v_result.winning_bid_id,'winning_amount',v_result.winning_amount,
  'item_awarded',v_result.winner_member_id is not null,'replayed',false);
end;
$function$;
revoke all on function public.admin_finalize_auction(uuid) from public,anon;
grant execute on function public.admin_finalize_auction(uuid) to authenticated;

create or replace function public.public_list_recent_auction_winners(p_limit integer default 8)
returns table(
 auction_id uuid,
 auction_title text,
 image_url text,
 winner_name text,
 winning_amount numeric,
 finalized_at timestamptz
)
language plpgsql
stable
security definer
set search_path=''
as $function$
begin
 if p_limit is null or p_limit<1 or p_limit>12 then
  raise exception 'Winner card limit must be between 1 and 12' using errcode='22023';
 end if;
 return query
 select a.id,a.title,a.image_url,
  coalesce(nullif(left(btrim(pr.display_name),60),''),'BiddWorld Member')::text,
  wr.winning_amount,wr.finalized_at
 from public.auction_winner_results wr
 join public.auctions a on a.id=wr.auction_id
 join public.products p on p.id=a.product_id and p.status='published'
 join public.member_ids m on m.id=wr.winner_member_id and m.id_type='main'
 join public.profiles pr on pr.id=m.user_id and pr.status='active'
 where wr.winner_member_id is not null
  and wr.winning_amount is not null
  and a.status='ended'
 order by wr.finalized_at desc,wr.auction_id desc
 limit p_limit;
end;
$function$;
revoke all on function public.public_list_recent_auction_winners(integer) from public,anon,authenticated;
grant execute on function public.public_list_recent_auction_winners(integer) to anon,authenticated;

-- Keep winner-payment notifications exclusive to Fixed Bid campaigns.
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
 if new.auction_id is not null then return new; end if;
 select coalesce((setting_value#>>'{}')::boolean,false) into v_notifications_enabled
 from public.app_settings where setting_key='notifications_enabled';
 if not coalesce(v_notifications_enabled,false) then return new;end if;
 select owner_user_id into v_user_id from public.member_ids where id=new.winner_member_id;
 if v_user_id is null then return new;end if;
 if tg_op='INSERT' then
  if new.status<>'pending' then return new;end if;
  if new.fixed_bid_campaign_id is not null then
   select title into v_item_title from public.fixed_bid_campaigns where id=new.fixed_bid_campaign_id;
   v_title:='You won a Fixed Bid campaign';
  else
   return new;
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
