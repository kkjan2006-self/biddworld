-- Correct the Recent Winners profile join to the canonical member_ids.owner_user_id column.
-- The baseline has no member_ids.user_id column; keep the public projection bounded and privacy-limited.
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
 join public.profiles pr on pr.id=m.owner_user_id and pr.status='active'
 where wr.winner_member_id is not null
  and wr.winning_amount is not null
  and a.status='ended'
 order by wr.finalized_at desc,wr.auction_id desc
 limit p_limit;
end;
$function$;
revoke all on function public.public_list_recent_auction_winners(integer) from public,anon,authenticated;
grant execute on function public.public_list_recent_auction_winners(integer) to anon,authenticated;
