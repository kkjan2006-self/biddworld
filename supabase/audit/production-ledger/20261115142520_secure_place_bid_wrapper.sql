-- Repair the invoker-wrapper privilege gap in the original bid RPC.
-- The private implementation independently validates auth.uid(), member ownership,
-- auction state, and wallet balances. This wrapper only bridges authenticated callers
-- to that implementation; direct execution of the private function stays revoked.

create or replace function public.place_bid(p_auction_id uuid)
returns jsonb
language sql
security definer
set search_path = pg_catalog, public, private
as $function$
  select private.place_bid(p_auction_id);
$function$;

revoke all on function public.place_bid(uuid) from public, anon;
grant execute on function public.place_bid(uuid) to authenticated;
revoke all on function private.place_bid(uuid) from public, anon, authenticated;

comment on function public.place_bid(uuid) is
  'Authenticated bid entry point; private implementation validates auth.uid() and performs the atomic wallet debit.';
