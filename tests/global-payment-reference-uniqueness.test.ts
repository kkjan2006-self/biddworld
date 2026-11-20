import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261120170000_global_payment_reference_uniqueness.sql'),'utf8');
const packageSubmit=readFileSync(resolve(process.cwd(),'supabase/migrations/20261116200000_lock_package_activation_submission.sql'),'utf8');
const walletSubmit=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119060000_member_wallet_funding_requests.sql'),'utf8');

describe('Global payment reference uniqueness across activation and wallet funding',()=>{
 it('serializes each normalized UTR using one shared transaction advisory lock',()=>{
  expect(migration).toContain("'biddworld.payment-reference:'||upper(btrim(new.payment_reference))");
  expect(migration).toContain('pg_catalog.pg_advisory_xact_lock');
  expect(migration).toContain('pg_catalog.hashtextextended');
 });
 it('checks the opposite payment workflow from both insert/update triggers',()=>{
  expect(migration).toContain('from public.wallet_fund_requests r');
  expect(migration).toContain('from public.package_activations a');
  expect(migration).toContain('guard_package_activation_global_payment_reference');
  expect(migration).toContain('guard_wallet_funding_global_payment_reference');
  expect(migration).toContain('before insert or update of payment_reference on public.package_activations');
  expect(migration).toContain('before insert or update of payment_reference on public.wallet_fund_requests');
 });
 it('keeps existing workflow preflight checks and same-table uniqueness in place',()=>{
  expect(packageSubmit).toContain('where lower(btrim(payment_reference)) = lower(v_reference)');
  expect(walletSubmit).toContain('wallet_fund_requests_utr_unique unique(payment_reference_normalized)');
  expect(walletSubmit).toContain('from public.package_activations where upper(btrim(payment_reference))=upper(v_reference)');
  expect(migration).toContain("using errcode='23505'");
 });
 it('does not expose the SECURITY DEFINER trigger routine to client roles',()=>{
  expect(migration).toContain('security definer');
  expect(migration).toContain("set search_path=''");
  expect(migration).toContain('revoke all on function private.guard_global_payment_reference_uniqueness() from public,anon,authenticated');
 });
});
