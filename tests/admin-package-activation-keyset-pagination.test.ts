import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const migration=readFileSync('supabase/migrations/20261119410000_admin_pending_activation_keyset_pagination.sql','utf8');
const component=readFileSync('src/components/Admin.tsx','utf8');
describe('Admin pending package activation keyset pagination',()=>{
 it('bounds pages and requires a paired stable descending cursor',()=>{
  expect(migration).toContain('p_limit>100');
  expect(migration).toContain('(p_after_submitted_at is null)<>(p_after_id is null)');
  expect(migration).toContain('(a.submitted_at,a.id)<(p_after_submitted_at,p_after_id)');
  expect(migration).toContain('limit p_limit+1');
 });
 it('retains Admin-only authorization and private receipt path data',()=>{
  expect(migration).toContain("auth.jwt()->'app_metadata'->>'role'");
  expect(migration).toContain("'receipt_path',receipt_path");
  expect(migration).toContain("'next_submitted_at'");
  expect(migration).toContain("'next_id'");
  expect(migration).toContain('revoke all on function public.admin_list_pending_activations_page');
 });
 it('uses bounded pages and validates records and cursor before appending',()=>{
  expect(component).toContain("admin_list_pending_activations_page',{p_limit:50");
  expect(component).toContain('parsePendingActivationPage');
  expect(component).toContain('page.items.some(item=>seen.has(item.id))');
  expect(component).toContain('Load 50 more pending activations');
 });
 it('keeps receipt viewing and approval on the existing secured workflows',()=>{
  expect(component).toContain("createSignedUrl(item.receipt_path,300)");
  expect(component).toContain("admin_review_package_activation");
 });
});
