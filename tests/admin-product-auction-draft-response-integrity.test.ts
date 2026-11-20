import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const read=(path:string)=>readFileSync(resolve(process.cwd(),path),'utf8');
const ui=read('src/components/Admin.tsx');
const product=read('supabase/migrations/20261116020000_admin_product_management_and_media.sql');
const auction=read('supabase/migrations/20261116040000_admin_auction_draft_management.sql');
describe('Admin Product and Auction draft mutation response integrity',()=>{
 it('validates Product draft UUID and preserves the edited Product identity',()=>{
  expect(ui).toContain("typeof data!=='string'||!data.trim()||(editingProductId&&data!==editingProductId)");
  expect(product).toContain('admin_save_product_draft(');
  expect(product).toContain(') returns uuid');
 });
 it('validates Product publication identity and published/draft state',()=>{
  expect(ui).toContain('result.product_id!==productId');
  expect(ui).toContain("const expectedStatus=active?'published':'draft'");
  expect(product).toContain("'success',true,'product_id',p_product_id,'status',v_status");
 });
 it('validates Auction draft UUID and preserves the edited Auction identity',()=>{
  expect(ui).toContain("typeof data!=='string'||!data.trim()||(wasEditing&&data!==editingAuctionId)");
  expect(auction).toContain('admin_save_auction_draft(');
  expect(auction).toContain('returns uuid');
 });
});
