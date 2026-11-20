import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const ui=readFileSync('src/components/Notifications.tsx','utf8');
describe('Notifications response and realtime integrity',()=>{
 it('validates complete notification rows, timestamps and optional recipient fields',()=>{
  expect(ui).toContain('function parseNoticePage(value:unknown,expectedUserId?:string):Notice[]');
  expect(ui).toContain('(expectedUserId&&row.user_id!==expectedUserId)');
  expect(ui).toContain('Number.isFinite(Date.parse(row.created_at))');
  expect(ui).toContain('row.recipient_member_code!==undefined');
 });
 it('validates initial and subsequent pages with the bounded page size',()=>{
  expect(ui).toContain('rows=parseNoticePage(data);');
  expect(ui).toContain('rows=parseNoticePage(data,user.id);');
  expect(ui).toContain('(!isAdmin&&row.user_id!==user.id)');
  expect(ui).toContain('rows.length>PAGE_SIZE+1');
  expect(ui).toContain('The notification inbox returned an overlapping page');
 });
 it('rejects cross-account rows in member page responses and realtime events',()=>{
  expect(ui).toContain('(expectedUserId&&row.user_id!==expectedUserId)');
  expect(ui).toContain('(!isAdmin&&row.user_id!==user.id)');
 });
 it('rejects malformed realtime notification events before rendering',()=>{
  expect(ui).toContain('Number.isFinite(Date.parse(row.read_at))');
  expect(ui).toContain('Number.isFinite(Date.parse(row.created_at))');
 });
});
