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
 it('applies unread and category filters in both database queries before pagination',()=>{
  expect(source).toContain("if(unreadOnly)request=request.is('read_at',null)");
  expect(source.match(/categoryFilter!=='all'/g)).toHaveLength(2);
  expect(source).toContain('[isAdmin,unreadOnly,categoryFilter]');
  expect(source).toContain('[busy,hasMore,items.length,isAdmin,unreadOnly,categoryFilter]');
 });
 it('marks all currently unread member notifications read through the owner-scoped RLS policy',()=>{
  expect(source).toContain(".update({read_at:readAt}).eq('id',id).is('read_at',null)");
  expect(source).toContain(".update({read_at:readAt}).eq('user_id',user.id).is('read_at',null)");
  expect(source).toContain('async function markAllRead()');
  expect(source).toContain('setItems(rows=>rows.map(row=>row.read_at?row:{...row,read_at:readAt}))');
 });
 it('loads Admin history through the Admin-only recipient projection and shows member identity rather than Auth UUIDs',()=>{
  expect(source).toContain('admin_list_member_notifications_keyset_page');
  expect(source).toContain('recipient_member_code');
  expect(source).toContain('recipient_name');
  expect(source).not.toContain('{item.user_id}');
 });
 it('distinguishes an initial inbox load failure from a genuinely empty inbox and offers retry',()=>{
  expect(source).toContain('error&&items.length===0');
  expect(source).toContain('Retry loading notifications');
  expect(source).toContain('admin_list_member_notifications_keyset_page');
 });
 it('keeps the bulk-read action out of Admin authoring mode',()=>{
  expect(source).toContain("!isAdmin&&<><button className=\"outline small\" type=\"button\" onClick={()=>setUnreadOnly");
 });
});
