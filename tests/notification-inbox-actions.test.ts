import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
const source=readFileSync(resolve(process.cwd(),'src/components/Notifications.tsx'),'utf8');
describe('member notification inbox actions',()=>{
 it('offers an unread-only view over explicitly loaded rows',()=>{
  expect(source).toContain('unreadOnly');
  expect(source).toContain('items.filter(item=>!item.read_at)');
  expect(source).toContain('No unread notifications among the loaded records.');
 });
 it('marks all currently unread member notifications read through the owner-scoped RLS policy',()=>{
  expect(source).toContain(".update({read_at:readAt}).is('read_at',null)");
  expect(source).toContain('async function markAllRead()');
  expect(source).toContain('setItems(rows=>rows.map(row=>row.read_at?row:{...row,read_at:readAt}))');
 });
 it('keeps the bulk-read action out of Admin authoring mode',()=>{
  expect(source).toContain("!isAdmin&&<><button className=\"outline small\" type=\"button\" onClick={()=>setUnreadOnly");
 });
});
