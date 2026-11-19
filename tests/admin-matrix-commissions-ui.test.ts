import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const read=(p:string)=>readFileSync(resolve(process.cwd(),p),'utf8');
const admin=read('src/components/Admin.tsx');
const component=read('src/components/AdminMatrixCommissions.tsx');
const migration=read('supabase/migrations/20261119310000_matrix_commission_engine.sql');

describe('Admin Matrix commission register UI contract',()=>{
 it('adds a separate Admin navigation section without merging Sponsor commissions',()=>{
  expect(admin).toContain("setActiveSection('matrix-commissions')");
  expect(admin).toContain('<AdminMatrixCommissions/>');
  expect(admin).toContain("setActiveSection('commission')");
 });
 it('loads the server-paginated Matrix commission report with status and level filters',()=>{
  expect(component).toContain("admin_list_matrix_commissions_page");
  expect(component).toContain('p_status:filterStatus');
  expect(component).toContain('p_level:filterLevel');
  expect(component).toContain('Load 100 more Matrix commissions');
 });
 it('displays source Duplicate ID and credited Main ID as separate fields',()=>{
  expect(component).toContain('source_member_code');
  expect(component).toContain('source_id_type');
  expect(component).toContain('credited_main_member_code');
  expect(component).toContain('Duplicate ID');
  expect(component).toContain('Credited Main ID');
 });
 it('validates page records and refuses duplicate commission IDs',()=>{
  expect(component).toContain('validRow');
  expect(component).toContain('Number.isFinite(Date.parse(r.created_at))');
  expect(component).toContain('duplicate commission IDs');
  expect(component).toContain('overlaps records already loaded');
 });
 it('exports every filtered server page with complete source attribution',()=>{
  expect(component).toContain('Export complete CSV');
  expect(component).toContain('biddworld-matrix-commissions-complete.csv');
  expect(component).toContain('Source ID Type');
  expect(component).toContain('Credited Main ID');
  expect(component).toContain('100000');
 });
 it('uses the dedicated backend RPC and the engine has separate source-aware columns',()=>{
  expect(migration).toContain('admin_list_matrix_commissions_page');
  expect(migration).toContain('source_member_code');
  expect(migration).toContain('credited_main_member_code');
  expect(migration).toContain('has_more');
 });
});
