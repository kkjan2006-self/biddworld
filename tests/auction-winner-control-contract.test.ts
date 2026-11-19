import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const admin=readFileSync('src/components/Admin.tsx','utf8');
const settings=readFileSync('supabase/migrations/20261119530000_remove_email_verification_switch.sql','utf8');
const auction=readFileSync('supabase/migrations/20261118110000_auction_lifecycle_winner_settlement.sql','utf8');
describe('auction winner selection control contract',()=>{
 it('does not expose a non-actionable winner-readiness toggle',()=>{
  expect(admin).not.toContain('winner_selection_configured');
  expect(settings).not.toContain("'winner_selection_configured'");
 });
 it('keeps winner determination in the server-side auction finalization workflow',()=>{
  expect(auction).toContain('public.admin_finalize_auction');
  expect(auction).toContain('winning_bid');
 });
});
