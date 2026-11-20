import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
const referrals=readFileSync(resolve(process.cwd(),'src/components/Referrals.tsx'),'utf8');
const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261116100000_member_genealogy_pagination.sql'),'utf8');
describe('member genealogy pagination',()=>{
 it('uses a bounded searchable page RPC and server-side level filter',()=>{
  expect(referrals).toContain("'get_my_mlm_dashboard_page'");
  expect(referrals).toContain('p_limit:50');
  expect(referrals).toContain('p_search:query.trim()||null');
  expect(referrals).toContain("p_depth:depth==='all'?null:Number(depth)");
  expect(referrals).toContain('Load more team members');
 });
 it('enforces authenticated access, bounded page sizes and cycle-safe traversal',()=>{
  expect(migration).toContain('auth.uid()');
  expect(migration).toContain('p_limit>100');
  expect(migration).toContain('not r.referred_member_id=any(d.path)');
  expect(migration).toContain("grant execute on function public.get_my_mlm_dashboard_page");
  expect(migration).toContain('tree_total');
  expect(migration).toContain('has_more');
 });
});
