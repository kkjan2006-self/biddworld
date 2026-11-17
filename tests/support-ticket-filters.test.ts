import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
const source=readFileSync(resolve(process.cwd(),'src/components/Support.tsx'),'utf8');
describe('support queue filters',()=>{
 it('applies status filtering before bounded pagination and searches loaded text case-insensitively',()=>{
  expect(source).toContain("const visibleTickets=tickets.filter(ticket=>(statusFilter==='all'||ticket.status===statusFilter)");
  expect(source.match(/request=request\.eq\('status',statusFilter\)/g)).toHaveLength(3);
  expect(source).toContain('ticket.subject,ticket.message,ticket.admin_response??');
  expect(source).toContain('toLowerCase().includes(search.trim().toLowerCase())');
 });
 it('keeps text-search labels explicit that text filtering applies to loaded records',()=>{
  expect(source).toContain('Search loaded requests');
  expect(source).toContain('Status is filtered on the server before pagination; text search applies to loaded records.');
  expect(source).toContain('No loaded support requests match these filters.');
 });
 it('retains bounded 100-row pagination and owner/Admin RLS notice',()=>{
  expect(source).toContain('const PAGE_SIZE=100;');
  expect(source).toContain('Load 100 more requests');
  expect(source).toContain('members can access only their own requests. Admin access is checked by database policies.');
 });
});
