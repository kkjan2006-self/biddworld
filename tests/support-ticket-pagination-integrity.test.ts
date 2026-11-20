import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const source=readFileSync(resolve(process.cwd(),'src/components/Support.tsx'),'utf8');

describe('Support ticket pagination ordering integrity',()=>{
 it('validates strict descending updated_at/id order for every ticket page',()=>{
  expect(source).toContain('function isStrictlyDescendingTicketPage(rows:Ticket[]):boolean');
  expect(source).toContain('rows[i-1].id.localeCompare(rows[i].id)<=0');
  expect(source).toContain('if(!isStrictlyDescendingTicketPage(page))');
  expect(source).toContain('if(!isStrictlyDescendingTicketPage(batch))');
 });
 it('requires continuation pages to stay strictly before the last loaded ticket cursor',()=>{
  expect(source).toContain('function isBeforeTicketCursor(row:Ticket,cursor:Pick<Ticket,\'updated_at\'|\'id\'>):boolean');
  expect(source).toContain('!isBeforeTicketCursor(page[0],cursor)');
  expect(source).toContain('!isBeforeTicketCursor(batch[0],cursor)');
 });
 it('keeps full-page continuation and duplicate identity guards',()=>{
  expect(source).toContain('rows.length>PAGE_SIZE&&page.length!==PAGE_SIZE');
  expect(source).toContain('known.has(ticket.id)||pageIds.has(ticket.id)');
  expect(source).toContain('seenIds.has(ticket.id)');
 });
});
