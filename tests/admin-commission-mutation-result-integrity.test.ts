import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';

const admin=readFileSync('src/components/Admin.tsx','utf8');
const matrix=readFileSync('src/components/AdminMatrixCommissions.tsx','utf8');
const referralSql=readFileSync('supabase/migrations/20261118090000_package_publication_and_referral_commission_engine.sql','utf8');
const matrixSql=readFileSync('supabase/migrations/20261119310000_matrix_commission_engine.sql','utf8');
const matrixReplaySql=readFileSync('supabase/migrations/20261120240000_matrix_commission_reversal_replay_identity.sql','utf8');
const referralReplaySql=readFileSync('supabase/migrations/20261120260000_referral_commission_reversal_replay_identity.sql','utf8');

describe('Referral and Matrix commission mutation response integrity',()=>{
 it('validates referral posting identity and a non-negative integer count',()=>{
  expect(admin).toContain("result.success!==true||result.activation_id!==activationId||typeof result.posted_count!=='number'||!Number.isInteger(result.posted_count)||result.posted_count<0");
  expect(referralSql).toContain("jsonb_build_object('success',true,'activation_id',p_activation_id,'posted_count',v_posted)");
 });
 it('validates referral reversal identity and final status',()=>{
  expect(admin).toContain("const replayMatches=result.commission_id===commissionId");
  expect(admin).toContain("result.replayed===true?'Referral commission was already reversed; existing ledger state confirmed.'");
  expect(referralSql).toContain("jsonb_build_object('success',true,'commission_id',p_commission_id,'status','reversed','replayed',false)");
  expect(referralReplaySql).toContain("jsonb_build_object('success',true,'commission_id',p_commission_id,'status','reversed','replayed',true)");
 });
 it('validates Matrix posting identity and a non-negative integer count',()=>{
  expect(matrix).toContain("result.success!==true||result.activation_id!==activationId||typeof result.posted_count!=='number'||!Number.isInteger(result.posted_count)||result.posted_count<0");
  expect(matrixSql).toContain("jsonb_build_object('success',true,'activation_id',p_activation_id,'posted_count',v_posted)");
 });
 it('validates Matrix reversal identity and final status',()=>{
  expect(matrix).toContain("const replayMatches=result.commission_id===commissionId");
  expect(matrix).toContain("result.replayed===true?'Matrix commission was already reversed; existing ledger state confirmed.'");
  expect(matrixSql).toContain("jsonb_build_object('success',true,'commission_id',p_commission_id,'status','reversed','replayed',false)");
  expect(matrixReplaySql).toContain("jsonb_build_object('success',true,'commission_id',p_commission_id,'status','reversed','replayed',true)");
 });
});
