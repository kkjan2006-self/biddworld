import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const component=readFileSync(resolve(process.cwd(),'src/components/Notifications.tsx'),'utf8');
const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119110000_admin_notification_history_keyset_pagination.sql'),'utf8');
describe('Notification inbox keyset pagination',()=>{
 it('uses bounded keyset pages for Admin history',()=>{
  expect(component).toContain('admin_list_member_notifications_keyset_page');
  expect(component).toContain('p_cursor_created_at:cursor.created_at');
  expect(component).toContain('p_cursor_id:cursor.id');
  expect(component).toContain('p_limit:PAGE_SIZE+1');
  expect(component).not.toContain('p_offset:from');
  expect(component).not.toContain('admin_list_member_notifications_page');
 });
 it('uses stable cursor filtering and descending tuple order',()=>{
  expect(migration).toContain('(n.created_at,n.id)<(p_cursor_created_at,p_cursor_id)');
  expect(migration).toContain('order by n.created_at desc,n.id desc');
  expect(migration).toContain('limit p_limit');
 });
 it('keeps the Admin history RPC role restricted and validates cursor pairs',()=>{
  expect(migration).toContain("coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin'");
  expect(migration).toContain("(p_cursor_created_at is null)<>(p_cursor_id is null)");
  expect(migration).toContain("set search_path=''");
  expect(migration).toContain('revoke all on function');
  expect(migration).toContain('grant execute on function');
 });
 it('uses member-owned RLS queries and keyset pagination for member inbox pages',()=>{
  expect(component).toContain(".eq('user_id',user.id)");
  expect(component).toContain('created_at.lt.${cursor.created_at},and(created_at.eq.${cursor.created_at},id.lt.${cursor.id})');
  expect(component).toContain('request.limit(PAGE_SIZE+1)');
  expect(component).toContain("request=request.is('read_at',null)");
 });
});
