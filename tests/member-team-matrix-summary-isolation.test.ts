import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const source=readFileSync('src/components/Referrals.tsx','utf8');
describe('My Team and Matrix summary RPC isolation',()=>{
 it('settles the required team dashboard and optional Matrix summary independently',()=>{
  expect(source).toContain('const [dashboardResult,matrixResult]=await Promise.allSettled([');
  expect(source).toContain("if(dashboardResult.status==='rejected')throw dashboardResult.reason");
  expect(source).toContain('if(dashboardResult.value.error)throw dashboardResult.value.error');
  expect(source).toContain("if(matrixResult.status==='fulfilled'&&!matrixResult.value.error&&matrixResult.value.data!==null)");
 });
 it('keeps team data visible when only the Matrix summary RPC fails',()=>{
  expect(source).toContain('setData(parseDashboard(dashboardResult.value.data))');
  expect(source).toContain('setMatrixSummaryError(true)');
  expect(source).toContain('Your Sponsor team data is still available');
  expect(source).toContain('setMatrixSummaryError(false)');
 });
 it('keeps the Matrix summary tied to its own validated response',()=>{
  expect(source).toContain('setMatrixSummary(parseMatrixSummary(matrixResult.value.data))');
  expect(source).toContain('function parseMatrixSummary(value:unknown):MatrixSummary');
 });
});
