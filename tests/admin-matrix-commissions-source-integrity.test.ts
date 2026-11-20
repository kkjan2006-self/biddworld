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
});
