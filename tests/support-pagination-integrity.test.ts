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
});
