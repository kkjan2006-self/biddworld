import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const component=readFileSync(resolve(process.cwd(),'src/components/Packages.tsx'),'utf8');
const sql=readFileSync(resolve(process.cwd(),'supabase/migrations/20261118300000_public_package_catalogue_page.sql'),'utf8');

describe('public package catalogue',()=>{
 it('loads published packages through the public RPC rather than direct table SELECT',()=>{
  expect(component).toContain("rpc('public_list_active_packages_page',{p_limit:PACKAGE_PAGE_SIZE,p_offset:0})");
  expect(component).toContain("rpc('public_list_active_packages_page',{p_limit:PACKAGE_PAGE_SIZE,p_offset:offset})");
  expect(component).toContain('Load more packages');
  expect(component).not.toContain(".from('packages')");
 });
 it('returns only active package catalogue fields in stable price order',()=>{
  expect(sql).toContain('where p.is_active = true');
  expect(sql).toContain('order by p.price asc,p.id asc');
  expect(sql).toContain('p.name');
  expect(sql).toContain('p.description');
  expect(sql).toContain('p.price');
  expect(sql).toContain('p.bid_wallet_credit');
  expect(sql).not.toContain('payment_reference');
  expect(sql).not.toContain('receipt_path');
 });
 it('keeps draft packages private and pagination bounded',()=>{
  expect(sql).toContain('p_limit > 100');
  expect(sql).toContain('p_offset > 1000000');
  expect(sql).toContain('limit p_limit offset p_offset');
  expect(sql).toContain('security definer');
  expect(sql).toContain("set search_path = ''");
  expect(sql).toContain('grant execute on function public.public_list_active_packages_page(integer,integer) to anon,authenticated');
 });
 it('checks the activation setting only for authenticated sessions and fails closed',()=>{
  expect(component).toContain('supabase.auth.getSession()');
  expect(component).toContain('if(!sessionData.session){setActivationEnabled(false);return;}');
  expect(component).toContain("setting_key','package_activations_enabled");
  expect(component).toContain('setActivationEnabled(!activationSettingError&&activationSetting?.setting_value===true)');
 });
});
