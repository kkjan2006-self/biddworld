import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const ui=readFileSync('src/components/Referrals.tsx','utf8');
describe('member Sponsor and Matrix dashboard response validation',()=>{
 it('validates dashboard counters, page metadata and unique member identities',()=>{
  expect(ui).toContain('function parseDashboard(value:unknown):Dashboard');
  expect(ui).toContain('row.tree.length>50');
  expect(ui).toContain('seen.has(member.member_code)');
  expect(ui).toContain('row.has_more&&tree.length===0');
 });
 it('validates Matrix commission summary totals before rendering',()=>{
  expect(ui).toContain('function parseMatrixSummary(value:unknown):MatrixSummary');
  expect(ui).toContain("'credited_total','pending_total','reversed_total','credited_count','pending_count'");
 });
 it('applies the same dashboard parser to initial, export and load-more RPC pages',()=>{
  expect(ui).toContain('setData(parseDashboard(result))');
  expect(ui).toContain('const page=parseDashboard(result)');
  expect(ui).toContain('const page=parseDashboard(next)');
 });
});
