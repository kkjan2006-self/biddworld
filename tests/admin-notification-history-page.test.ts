import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const sql=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119020000_admin_notification_history_recipient_labels.sql'),'utf8');

describe('Admin notification history recipient projection',()=>{
 it('requires a trusted Admin claim and exposes no public/anonymous execution',()=>{
  expect(sql).toMatch(/auth\.uid\(\) is null[\s\S]*?auth\.jwt\(\)->'app_metadata'->>'role'[\s\S]*?'admin'/i);
  expect(sql).toMatch(/revoke all on function public\.admin_list_member_notifications_page\(integer,integer,text\) from public,anon/i);
  expect(sql).toMatch(/grant execute on function public\.admin_list_member_notifications_page\(integer,integer,text\) to authenticated/i);
 });
 it('bounds pagination and validates supported category filters',()=>{
  expect(sql).toMatch(/p_limit < 1 or p_limit > 100/i);
  expect(sql).toMatch(/p_offset < 0 or p_offset > 1000000/i);
  expect(sql).toMatch(/p_category not in \('all','general','account','support','security'\)/i);
  expect(sql).toMatch(/limit p_limit offset p_offset/i);
 });
 it('returns member identity labels using Main IDs and stable notification ordering',()=>{
  expect(sql).toMatch(/left join public\.profiles profile on profile\.id=n\.user_id/i);
  expect(sql).toMatch(/m\.owner_user_id=n\.user_id and m\.id_type='main'/i);
  expect(sql).toMatch(/order by n\.created_at desc,n\.id desc/i);
  expect(sql).toMatch(/recipient_member_code|member\.member_code/i);
 });
});
