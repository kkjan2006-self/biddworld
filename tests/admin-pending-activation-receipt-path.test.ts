import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261118360000_admin_pending_activation_receipt_path.sql'),'utf8');
const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');

describe('Admin pending activation receipt integration',()=>{
 it('returns the private receipt object path in the Admin-only pending queue',()=>{
  expect(migration).toContain("'receipt_path', a.receipt_path");
  expect(migration).toContain("coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin'");
  expect(migration).toContain('revoke all on function public.admin_list_pending_activations() from public, anon');
  expect(migration).toContain('grant execute on function public.admin_list_pending_activations() to authenticated');
 });
 it('connects the pending queue path to the existing signed-URL receipt viewer',()=>{
  expect(admin).toContain("supabase.rpc('admin_list_pending_activations')");
  expect(admin).toContain("storage.from('package-receipts').createSignedUrl(item.receipt_path,300)");
  expect(admin).toContain('item.receipt_path&&');
  expect(admin).toContain('expiresAt:Date.now()+300000');
  expect(admin).toContain('Refresh receipt link');
  expect(admin).toContain('Date.now()<activationReceiptUrls[item.id].expiresAt');
 });
});
