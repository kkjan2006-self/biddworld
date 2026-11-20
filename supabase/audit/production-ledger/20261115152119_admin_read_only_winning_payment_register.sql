create or replace function public.admin_list_winning_item_payments(p_limit integer default 100,p_offset integer default 0)
returns table(payment_id uuid,winner_member_code text,winner_name text,auction_title text,fixed_bid_title text,amount numeric,status text,paid_at timestamptz,created_at timestamptz)
language plpgsql security definer set search_path=''
as $$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then raise exception 'Administrator access required' using errcode='42501'; end if;
 if p_limit is null or p_limit<1 or p_limit>200 or p_offset is null or p_offset<0 or p_offset>1000000 then raise exception 'Invalid pagination values' using errcode='22023'; end if;
 return query
 select w.id,m.member_code,p.display_name,a.title,fc.title,w.amount,w.status,w.paid_at,w.created_at
 from public.winning_item_payments w
 join public.member_ids m on m.id=w.winner_member_id
 left join public.profiles p on p.id=m.owner_user_id
 left join public.auctions a on a.id=w.auction_id
 left join public.fixed_bid_campaigns fc on fc.id=w.fixed_bid_campaign_id
 order by w.created_at desc,w.id desc limit p_limit offset p_offset;
end; $$;
revoke all on function public.admin_list_winning_item_payments(integer,integer) from public,anon;
grant execute on function public.admin_list_winning_item_payments(integer,integer) to authenticated;
