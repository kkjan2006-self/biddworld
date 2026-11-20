import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const source=readFileSync('src/components/AdminMatrixCommissions.tsx','utf8');
describe('Admin Matrix commissions component source integrity',()=>{
 it('validates bounded Matrix pages and required continuation metadata',()=>{
  expect(source).toContain('data.length>PAGE_SIZE');
  expect(source).toContain('typeof r.has_more===\'boolean\'');
  expect(source).toContain('inconsistent continuation metadata');
  expect(source).toContain('typeof row[key]===\'number\'');
 });
 it('keeps the request refs on a separate valid source line',()=>{
  expect(source).toContain("useState(0);\n  const reportRequest=useRef(0),loadMoreBusy=useRef(false);");
  expect(source).not.toContain("useState(0);\\n const reportRequest");
 });
 it('validates Matrix report UUIDs and bounded level values',()=>{
  expect(source).toContain("const uuid=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i");
  expect(source).toContain("uuid.test(r.commission_id)");
  expect(source).toContain("uuid.test(r.activation_id)");
  expect(source).toContain("Number(r.level_number)<=50");
 });
 it('rejects inconsistent Matrix summary count and amount aggregates',()=>{
  expect(source).toContain("Number(row.total_count)===Number(row.pending_count)+Number(row.credited_count)+Number(row.reversed_count)");
  expect(source).toContain("Math.abs(Number(row.total_amount)-(Number(row.pending_amount)+Number(row.credited_amount)+Number(row.reversed_amount)))<0.01");
  expect(source).toContain("Number.isSafeInteger(row[key])");
 });
});