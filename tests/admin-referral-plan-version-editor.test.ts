import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const source=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');
describe('Admin referral plan version editor',()=>{
 it('can load an existing inactive fixed-reward plan as a new version draft',()=>{
  expect(source).toContain('function loadReferralPlanAsNewDraft(plan:ReferralPlan)');
  expect(source).toContain('setSelectedPlanPackage(plan.package_id)');
  expect(source).toContain('setLevelValues(sorted.map(rule=>String(rule.reward_value)))');
  expect(source).toContain('Saving creates a new inactive version.');
  expect(source).toContain('Use as starting point for new version');
 });
 it('refuses active packages, unsupported reward types and non-sequential levels',()=>{
  expect(source).toContain('if(plan.package_active)');
  expect(source).toContain("!['fixed','percentage'].includes(rule.reward_type)");
  expect(source).toContain('sorted.some((rule,index)=>rule.level!==index+1)');
 });
 it('matches the database reward bounds before saving the inactive plan',()=>{
  expect(source).toContain("levelValues.some((v,i)=>!Number.isFinite(Number(v))||Number(v)<=0||Number(v)>(levelTypes[i]==='percentage'?100:100000))");
  expect(source).toContain("max={levelTypes[i]==='percentage'?100:100000}");
 });
});
