import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const workflow=readFileSync('.github/workflows/deploy-pages.yml','utf8');
describe('Production deployment approval gate',()=>{
 it('removes automatic deployment on pushes to main',()=>{
  expect(workflow).not.toContain('  push:');
  expect(workflow).toContain('workflow_dispatch:');
 });
 it('requires explicit boolean approval and the protected main branch for both jobs',()=>{
  expect(workflow).toContain('confirm_production_deployment:');
  expect(workflow).toContain('required: true');
  expect(workflow).toContain('type: boolean');
  expect(workflow).toContain("if: github.ref == 'refs/heads/main' && inputs.confirm_production_deployment == true");
 });
 it('does not allow overlapping production deployment runs',()=>{
  expect(workflow).toContain('group: biddworld-production-deployment');
  expect(workflow).toContain('cancel-in-progress: false');
 });
});
