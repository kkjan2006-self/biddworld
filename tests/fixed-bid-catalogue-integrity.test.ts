import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const root=process.cwd();
const component=readFileSync(resolve(root,'src/components/FixedBid.tsx'),'utf8');
const projection=readFileSync(resolve(root,'supabase/migrations/20261120100000_public_fixed_bid_card_details_and_progress.sql'),'utf8');

describe('Fixed Bid public catalogue integrity',()=>{
 it('validates bounded unique campaign identities and supported lifecycle states',()=>{
  expect(component).toContain('function parseCampaignPage(value:unknown)');
  expect(component).toContain('value.length>PAGE_SIZE');
  expect(component).toContain('ids.has(row.id)');
  expect(component).toContain("['scheduled','live','ended'].includes(String(row.status))");
  expect(component).toContain('Number.isFinite(Date.parse(row.created_at))');
 });
 it('validates numeric campaign rules and percentage-only progress',()=>{
  expect(component).toContain("for(const key of ['entry_amount','winner_payment_amount']");
  expect(component).toContain('config.progress_percent');
  expect(component).toContain('Number(config.progress_percent)>100');
  expect(projection).toContain("'progress_percent'");
  expect(projection).toContain('least(100,greatest(0,round(');
  expect(projection).not.toContain("'entry_count',");
 });
 it('validates the approved product gallery and string-valued product attributes',()=>{
  expect(component).toContain('product.image_paths.length>8');
  expect(component).toContain('product.product_details');
  expect(component).toContain("Object.values(product.product_details as Record<string,unknown>).every(item=>typeof item==='string')");
  expect(projection).toContain("'image_paths'");
  expect(projection).toContain("'product_details'");
 });
});
