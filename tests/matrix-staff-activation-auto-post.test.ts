import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261120160000_matrix_staff_activation_auto_post.sql'),'utf8');
const matrixEngine=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119310000_matrix_commission_engine.sql'),'utf8');
const staffReview=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119640000_staff_package_activation_review.sql'),'utf8');

describe('Matrix auto-post during restricted Staff package approval',()=>{
 it('uses a private internal posting routine from the activation trigger',()=>{
  expect(migration).toContain('create or replace function private.post_matrix_commissions_for_activation(p_activation_id uuid,p_actor_id uuid)');
  expect(migration).toContain('perform private.post_matrix_commissions_for_activation(new.id,auth.uid());');
  expect(migration).toContain('revoke all on function private.post_matrix_commissions_for_activation(uuid,uuid) from public,anon,authenticated');
 });
 it('preserves Admin-only authorization on the public manual posting RPC',()=>{
  expect(matrixEngine).toContain("coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin'");
  expect(migration).not.toContain('grant execute on function private.post_matrix_commissions_for_activation');
 });
 it('keeps the Staff approval permission scoped to package activation review',()=>{
  expect(staffReview).toContain("v_permissions ? 'package_activation_review'");
  expect(migration).toContain("'matrix_commissions.posted'");
  expect(migration).toContain('jsonb_build_object(v_uid');
 });
 it('preserves the existing atomic wallet ledger, idempotency and activation lock behavior',()=>{
  for(const token of ['matrix-activation:','matrix-commission:','idempotency_key=v_key','wallet_transactions','balance_after','for update'])expect(migration).toContain(token);
 });
});
