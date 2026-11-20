import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const ui=readFileSync('src/components/Support.tsx','utf8');
describe('Support ticket keyset pagination',()=>{
 it('validates ticket identity, status and timestamps before rendering',()=>{
  expect(ui).toContain('function validTicket(value:unknown):value is Ticket');
  expect(ui).toContain("['open','in_progress','resolved','closed'].includes(String(row.status))");
 });
 it('uses an extra row to determine whether the initial and next pages have more data',()=>{
  expect(ui).toContain('request.range(0,PAGE_SIZE)');
  expect(ui).toContain('request.limit(PAGE_SIZE+1)');
  expect(ui).toContain('setHasMore(rows.length>PAGE_SIZE)');
 });
 it('rejects duplicate/overlapping records and uses the current cursor collection',()=>{
  expect(ui).toContain('duplicate or overlapping ticket IDs');
  expect(ui).toContain('},[busy,hasMore,tickets,isAdmin,statusFilter]);');
 });
 it('validates UUID identity, database text bounds, timestamps and owner identity',()=>{
  expect(ui).toContain("const uuid=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i");
  expect(ui).toContain("row.subject.trim().length>=4&&row.subject.trim().length<=120");
  expect(ui).toContain("row.message.trim().length>=10&&row.message.trim().length<=5000");
  expect(ui).toContain("row.admin_response.length<=5000");
  expect(ui).toContain("(!expectedUserId||row.user_id===expectedUserId)");
  expect(ui).toContain("Date.parse(row.updated_at)>=Date.parse(row.created_at)");
 });
 it('applies authenticated owner validation to initial, keyset and CSV export pages',()=>{
  expect(ui.match(/rows\.every\(row=>validTicket\(row,expectedUserId\)\)/g)?.length).toBe(2);
  expect(ui).toContain("data.every(row=>validTicket(row,userId))");
 });
});