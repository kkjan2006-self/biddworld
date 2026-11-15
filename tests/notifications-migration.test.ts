import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const sql = readFileSync(resolve(process.cwd(), 'supabase/migrations/20261116050000_member_notifications.sql'), 'utf8');

describe('member notifications migration security contract', () => {
 it('enables RLS and limits member reads to their own notifications', () => {
  expect(sql).toMatch(/alter table public\.member_notifications enable row level security/i);
  expect(sql).toMatch(/user_id=\(select auth\.uid\(\)\)/i);
  expect(sql).toMatch(/auth\.jwt\(\)->'app_metadata'->>'role'.*'admin'/is);
 });
 it('allows inserts only to trusted administrators', () => {
  expect(sql).toMatch(/grant insert \(user_id,title,message,category\) to authenticated/i);
  expect(sql).toMatch(/create policy member_notifications_insert_admin[\s\S]*?with check[\s\S]*?auth\.jwt\(\)->'app_metadata'->>'role'[\s\S]*?'admin'/i);
 });
 it('limits member updates to read receipts only', () => {
  expect(sql).toMatch(/grant update \(read_at\) on public\.member_notifications to authenticated/i);
  expect(sql).toMatch(/create policy member_notifications_mark_read_owner[\s\S]*?using \(user_id=\(select auth\.uid\(\)\)\)/i);
 });
 it('constrains notification content and categories', () => {
  expect(sql).toMatch(/char_length\(btrim\(title\)\) between 3 and 120/i);
  expect(sql).toMatch(/char_length\(btrim\(message\)\) between 5 and 2000/i);
  expect(sql).toMatch(/category in \('general','account','support','security'\)/i);
 });
});
