import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const previous=readFileSync(resolve(process.cwd(),'supabase/migrations/20261115230000_duplicate_under_id_placement_attribution.sql'),'utf8');
const current=readFileSync(resolve(process.cwd(),'supabase/migrations/20261118200000_member_identity_ids_rpc.sql'),'utf8');

describe('Member identity RPC migration compatibility',()=>{
 it('replaces the earlier table-return function by dropping its exact signature first',()=>{
  const drop=current.indexOf('drop function if exists public.member_list_my_ids();');
  const create=current.indexOf('create or replace function public.member_list_my_ids()');
  expect(drop).toBeGreaterThanOrEqual(0);
  expect(create).toBeGreaterThan(drop);
  expect(previous).toContain('main_member_code text');
 });
 it('preserves the seven-column member Account identity contract and authenticated-only access',()=>{
  const declaration=current.slice(current.indexOf('returns table('),current.indexOf(')\nlanguage sql'));
  expect(declaration).toContain('placement_parent_code text');
  expect(declaration).not.toContain('main_member_code');
  expect(current).toContain('grant execute on function public.member_list_my_ids() to authenticated');
  expect(current).toContain('revoke all on function public.member_list_my_ids() from public,anon');
 });
});
