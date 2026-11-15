import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
const account=readFileSync(resolve(process.cwd(),'src/components/Account.tsx'),'utf8');
describe('member dashboard history pagination',()=>{
 it('uses bounded deterministic first-page queries for member histories',()=>{
  expect(account).toContain(".range(0,49)");
  expect((account.match(/\\.range\\(0,99\\)/g)??[]).length).toBeGreaterThanOrEqual(4);
  expect(account).toContain(".order('id',{ascending:false})");
 });
 it('provides paginated continuation for activations, bids, commissions and winner records',()=>{
  for(const name of ['loadMoreActivations','loadMoreAuctionBids','loadMoreFixedBids','loadMoreCommissions','loadMoreWinningPayments'])expect(account).toContain(name);
  for(const label of ['Load more package history','Load more auction history','Load more Fixed Bid history','Load more commission history','Load more winner history'])expect(account).toContain(label);
  expect(account).toContain('range(from,to)');
 });
});
