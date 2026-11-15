import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
const sql = readFileSync(resolve(process.cwd(), 'supabase/migrations/20261116070000_delivery_tracking_backend.sql'), 'utf8');
describe('delivery tracking backend migration security contract', () => {
 it('enables owner-scoped RLS and minimal member read grants', () => {
  expect(sql).toMatch(/alter table public\.delivery_tracking enable row level security/i);
  expect(sql).toMatch(/delivery_tracking_select_own[\s\S]*?m\.owner_user_id=\(select auth\.uid\(\)\)/i);
  expect(sql).toMatch(/grant select\(id,winning_item_payment_id,carrier,tracking_number,status,shipped_at,delivered_at,updated_at\)/i);
 });
 it('requires trusted Admin claims and restricts RPC execution', () => {
  expect(sql.match(/auth\.jwt\(\)->'app_metadata'->>'role'/g)?.length).toBeGreaterThanOrEqual(2);
  expect(sql).toMatch(/revoke all on function public\.admin_list_delivery_tracking\(integer,integer\) from public,anon/i);
  expect(sql).toMatch(/revoke all on function public\.admin_save_delivery_tracking\(uuid,uuid,text,text,text\) from public,anon/i);
 });
 it('requires paid winner payments and prevents concurrent duplicate tracking creation', () => {
  expect(sql).toMatch(/status='paid'/i);
  expect(sql).toMatch(/pg_advisory_xact_lock\(hashtextextended\(p_payment_id::text,0\)\)/i);
  expect(sql).toMatch(/create unique index if not exists delivery_tracking_one_row_per_payment_uidx/i);
 });
 it('bounds user input and audits against Production audit_logs.details', () => {
  expect(sql).toMatch(/length\(coalesce\(p_carrier,''\)\)>120/i);
  expect(sql).toMatch(/length\(coalesce\(p_tracking_number,''\)\)>180/i);
  expect(sql).toMatch(/insert into public\.audit_logs\(actor_user_id,action,entity_type,entity_id,details\)/i);
 });
});
