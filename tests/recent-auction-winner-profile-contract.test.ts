import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const root=process.cwd();
const baseline=readFileSync(resolve(root,'supabase/clean-install/production_schema_baseline_candidate.sql'),'utf8');
const award=readFileSync(resolve(root,'supabase/migrations/20261120110000_auction_item_awards_and_homepage_winners.sql'),'utf8');
const repair=readFileSync(resolve(root,'supabase/migrations/20261120120000_fix_recent_auction_winner_profile_join.sql'),'utf8');
const app=readFileSync(resolve(root,'src/App.tsx'),'utf8');

describe('Recent auction winner public projection contract',()=>{
 it('uses the canonical member ownership column from the schema baseline',()=>{
  expect(baseline).toContain('create table public.member_ids');
  expect(baseline).toContain('owner_user_id uuid not null');
  const memberIdsDefinition=baseline.match(/create table public\.member_ids\s*\(([\s\S]*?)\);/)?.[1]??'';
  expect(memberIdsDefinition).not.toMatch(/\buser_id\b/);
  expect(repair).toContain('pr.id=m.owner_user_id');
  expect(repair).not.toContain('m.user_id');
 });
 it('replaces the earlier invalid projection and preserves the public bounded RPC contract',()=>{
  expect(award).toContain('public_list_recent_auction_winners(p_limit integer default 8)');
  expect(repair).toContain('public_list_recent_auction_winners(p_limit integer default 8)');
  expect(repair).toContain('p_limit<1 or p_limit>12');
  expect(repair).toContain('grant execute on function public.public_list_recent_auction_winners(integer) to anon,authenticated');
 });
 it('keeps auction item awards separate from Fixed Bid winner-payment processing',()=>{
  expect(award).toContain('Auctions award the listed item');
  expect(award).toContain('if new.auction_id is not null then return new; end if;');
  expect(award).not.toContain('insert into public.winning_item_payments(auction_id');
  expect(app).toContain('public_list_recent_auction_winners');
  expect(app).toContain('Recent Winners');
 });
});
