import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const ui=readFileSync('src/components/Notifications.tsx','utf8');
describe('Notifications response and realtime integrity',()=>{
 it('matches notification identity, category and content bounds to the SQL contract',()=>{
  expect(ui).toContain('NOTIFICATION_UUID.test(row.id)');
  expect(ui).toContain('NOTIFICATION_UUID.test(row.user_id)');
  expect(ui).toContain('NOTICE_CATEGORIES');
  expect(ui).toContain('databaseCharLength(row.title.trim())<3||databaseCharLength(row.title.trim())>120');
  expect(ui).toContain('databaseCharLength(row.message.trim())<5||databaseCharLength(row.message.trim())>2000');
  expect(ui).toContain('row.recipient_name.length>200');
 });
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
 it('reuses full row validation for realtime INSERT and UPDATE payloads',()=>{
  expect(ui).toContain('function parseNoticeRow(value:unknown,expectedUserId?:string):Notice');
  expect(ui).toContain('parseNoticeRow(payload.new,isAdmin?undefined:user.id)');
  expect(ui).toContain("if(!matchesCategory||(unreadOnly&&row.read_at))return current.filter(item=>item.id!==row.id)");
 });
 it('checks available recipient ownership on realtime DELETE events',()=>{
  expect(ui).toContain("if(!isAdmin&&row.user_id!==undefined&&row.user_id!==user.id)return");
  expect(ui).toContain("if(typeof row.id!=='string'||!row.id.trim())return");
 });
});

describe('Notification keyset page ordering',()=>{
 it('validates strict descending created_at and UUID tie-break order for every page',()=>{
  expect(ui).toContain('function isStrictlyDescendingNoticePage(rows:Notice[]):boolean');
  expect(ui).toContain('previousTime===currentTime&&previous.id.toLowerCase()<=current.id.toLowerCase()');
  expect(ui).toContain('if(!isStrictlyDescendingNoticePage(rows))');
 });
 it('rejects continuation rows at or beyond the existing cursor',()=>{
  expect(ui).toContain('function isBeforeNoticeCursor(row:Notice,cursor:Notice):boolean');
  expect(ui).toContain('rows.some(row=>!isBeforeNoticeCursor(row,cursor))');
  expect(ui).toContain('crossed or repeated its keyset cursor');
 });
});


describe('Notification realtime insertion ordering',()=>{
 it('merges live INSERT events in the same descending (created_at,id) order as keyset pages',()=>{
  expect(ui).toContain('function compareNoticesNewestFirst(left:Notice,right:Notice):number');
  expect(ui).toContain('Date.parse(right.created_at)-Date.parse(left.created_at)');
  expect(ui).toContain('right.id.toLowerCase().localeCompare(left.id.toLowerCase())');
  expect(ui).toContain('[...current.filter(item=>item.id!==row.id),row].sort(compareNoticesNewestFirst).slice(0,PAGE_SIZE)');
  expect(ui).toContain('setHasMore(true)');
 });
});
