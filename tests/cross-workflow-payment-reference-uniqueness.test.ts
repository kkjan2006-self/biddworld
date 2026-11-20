import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119070000_prevent_cross_workflow_payment_reference_reuse.sql'),'utf8');
describe('Cross-workflow payment reference protection',()=>{
 it('uses one transaction-scoped lock for both payment workflows',()=>{
  expect(migration).toContain("pg_advisory_xact_lock(pg_catalog.hashtextextended('biddworld-payment-reference:'||v_reference,0))");
  expect(migration).toContain("tg_table_name='package_activations'");
  expect(migration).toContain("tg_table_name='wallet_fund_requests'");
 });
 it('rejects a UTR already used in the other payment workflow',()=>{
  expect(migration).toContain('public.wallet_fund_requests r');
  expect(migration).toContain('public.package_activations a');
  expect(migration).toContain("using errcode='23505'");
 });
 it('attaches guards to both insert paths',()=>{
  expect(migration).toContain('before insert on public.package_activations');
  expect(migration).toContain('before insert on public.wallet_fund_requests');
 });
});
