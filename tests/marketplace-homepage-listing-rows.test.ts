import {readFileSync} from 'node:fs';
import {describe,it} from 'node:test';
import assert from 'node:assert/strict';
const app=readFileSync('src/App.tsx','utf8');
const fixed=readFileSync('src/components/FixedBid.tsx','utf8');
const css=readFileSync('src/style.css','utf8');
describe('Marketplace homepage listing rows',()=>{
 it('places compact Fixed Bids and Auctions sections on the same home view',()=>{
  const home=app.slice(app.indexOf(":tab==='Auctions'?"),app.indexOf(":<div className=\"workspace\"><div className=\"workspaceIcon\"><ShieldCheck/></div><h3>{tab}"));
  assert.match(home,/<FixedBid compact\/>/);
  assert.match(home,/homeAuctionGrid/);
  assert.ok(home.indexOf('FixedBid compact')<home.indexOf('homeAuctionGrid'));
 });
 it('uses horizontally scrollable card rows with responsive card widths',()=>{
  assert.match(css,/\.fixedBidCompact \.fixedBidGrid\{display:flex;flex-wrap:nowrap;overflow-x:auto/);
  assert.match(css,/\.homeAuctionGrid\{display:flex;flex-wrap:nowrap;overflow-x:auto/);
  assert.match(css,/@media\(max-width:700px\)/);
 });
 it('keeps full Fixed Bid filters and details outside compact homepage mode',()=>{
  assert.match(fixed, /!compact&&<div className="sponsorAdminForm"/);
 });
});
