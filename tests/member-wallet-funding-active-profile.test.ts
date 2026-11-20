import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261120180000_require_active_profile_for_wallet_funding.sql'),'utf8');

describe('Income Wallet Add Money member eligibility',()=>{
 it('requires the authenticated owner profile and Main ID to both be active',()=>{
  expect(migration).toContain('p.id=v_uid and p.status=\'active\'');
  expect(migration).toContain('m.owner_user_id=v_uid and m.id_type=\'main\' and m.status=\'active\'');
  expect(migration).toContain('for update of p,m');
 });
 it('preserves receipt ownership, wallet feature gate and global UTR protection',()=>{
  expect(migration).toContain("(storage.foldername(p_receipt_path))[1]<>v_uid::text");
  expect(migration).toContain("setting_key='income_wallet_enabled'");
  expect(migration).toContain('from public.package_activations where upper(btrim(payment_reference))=upper(v_reference)');
  expect(migration).toContain('insert into public.wallet_fund_requests');
 });
 it('keeps the authenticated-only RPC grant',()=>{
  expect(migration).toContain('revoke all on function public.member_submit_wallet_fund_request(numeric,text,text) from public,anon');
  expect(migration).toContain('grant execute on function public.member_submit_wallet_fund_request(numeric,text,text) to authenticated');
 });
});
