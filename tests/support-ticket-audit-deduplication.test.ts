import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const migration = readFileSync(
  resolve(process.cwd(), 'supabase/migrations/20261119030000_deduplicate_support_ticket_audit_events.sql'),
  'utf8',
);

describe('support ticket audit event deduplication', () => {
  it('keeps the row trigger as the single audit writer with member context', () => {
    expect(migration).toMatch(/create or replace function public\.support_tickets_audit_admin_update\(\)/i);
    expect(migration).toMatch(/insert into public\.audit_logs\(actor_user_id, action, entity_type, entity_id, details\)/i);
    expect(migration).toMatch(/'member_user_id', new\.user_id/i);
    expect(migration).toMatch(/'old_status', old\.status/i);
    expect(migration).toMatch(/'new_status', new\.status/i);
  });

  it('removes the second audit insert from the Admin update RPC', () => {
    const rpc = migration.slice(migration.indexOf('create or replace function public.admin_update_support_ticket'));
    expect(rpc).toContain('update public.support_tickets');
    expect(rpc).toContain("return jsonb_build_object('success',true,'ticket_id',p_ticket_id,'status',p_status)");
    expect(rpc).not.toMatch(/insert into public\.audit_logs/i);
    expect(rpc).toMatch(/revoke all on function public\.admin_update_support_ticket\(uuid,text,text\) from public,anon/i);
    expect(rpc).toMatch(/grant execute on function public\.admin_update_support_ticket\(uuid,text,text\) to authenticated/i);
  });
});
