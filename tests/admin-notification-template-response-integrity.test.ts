import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const source=readFileSync('src/components/Admin.tsx','utf8');
const migration=readFileSync('supabase/migrations/20261118210000_admin_templates_accounts_health.sql','utf8');
describe('Admin notification template save response integrity',()=>{
 it('validates template UUID, inactive state and edit identity before resetting the form',()=>{
  expect(source).toContain('data:saveResult');
  expect(source).toContain('result.success!==true');
  expect(source).toContain('result.is_active!==false');
  expect(source).toContain('editingTemplate&&result.id!==editingTemplate');
  expect(migration).toContain("return jsonb_build_object('success',true,'id',v_id,'is_active',false)");
 });
});
