import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';

describe('signup status and public product catalogue migration',()=>{
 const sql=readFileSync('supabase/migrations/20261119220000_signup_status_and_public_product_select.sql','utf8');

 it('creates new profiles and Main IDs in the allowed pending state',()=>{
  expect(sql).toContain("'pending'");
  expect(sql).not.toMatch(/values\([\s\S]*?'inactive'[\s\S]*?\)/i);
  expect(sql).toContain("insert into public.profiles(id,display_name,phone,status)");
  expect(sql).toContain("insert into public.member_ids(owner_user_id,member_code,id_type,status)");
 });

 it('preserves free signup defaults and optional sponsor validation',()=>{
  expect(sql).toContain("coalesce((setting_value #>> '{}')::boolean, true)");
  expect(sql).toContain("New member registration is currently disabled");
  expect(sql).toContain("sponsor_referrals_enabled");
  expect(sql).toContain("Invalid Sponsor Referral ID");
 });

 it('grants catalogue reads while retaining the published-only RLS boundary',()=>{
  expect(sql).toContain('grant select on table public.products to anon, authenticated');
  expect(sql).toContain('products_public_published_read');
 });
});
