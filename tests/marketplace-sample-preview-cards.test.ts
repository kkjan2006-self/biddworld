import {describe,expect,it} from 'vitest';
import {readFileSync} from 'node:fs';
const app=readFileSync('src/App.tsx','utf8');
const fixed=readFileSync('src/components/FixedBid.tsx','utf8');
const css=readFileSync('src/style.css','utf8');
describe('Marketplace sample preview cards',()=>{
 it('provides three Fixed Bid preview fixtures with display-only status',()=>{
  expect(fixed).toContain('sampleFixedCampaigns');
  expect(fixed).toContain('sample-fixed-1');
  expect(fixed).toContain('sample-fixed-2');
  expect(fixed).toContain('sample-fixed-3');
  expect(fixed).toContain('SAMPLE PREVIEW');
  expect(fixed).toMatch(/!showingSamples&&r\.status==='live'/);
 });
 it('shows auction examples when live catalogue is empty or only local demo fixtures exist',()=>{
  expect(app).toContain("items.every(a=>a.id.startsWith('demo-'))");
  expect(app).toContain('displayAuctionItems');
  expect(app).toContain('samplePreviewNotice');
  expect(app).toContain('SAMPLE PREVIEW');
 });
 it('distinguishes sample cards visually',()=>{
  expect(css).toContain('.samplePreviewCard');
 });
});
