import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const migration = readFileSync(
  resolve(process.cwd(), 'supabase/migrations/20261116041000_member_support_tickets.sql'),
  'utf8',
);

describe('member support ticket migration security contract', () => {
  it('enables RLS and limits member reads to their own tickets', () => {
    expect(migration).toMatch(/alter table public\.support_tickets enable row level security/i);
    expect(migration).toMatch(/user_id = \(select auth\.uid\(\)\)/i);
    expect(migration).toMatch(/auth\.jwt\(\)->'app_metadata'->>'role'.*'admin'/is);
  });

  it('allows member inserts only for their own new open tickets', () => {
    expect(migration).toMatch(/create policy support_tickets_insert_owner[\s\S]*?with check \([\s\S]*?user_id = \(select auth\.uid\(\)\)[\s\S]*?status = 'open'[\s\S]*?admin_response is null/i);
    expect(migration).toMatch(/grant insert \(user_id, subject, message\) on public\.support_tickets to authenticated/i);
  });

  it('restricts updates to trusted admins and only exposes intended columns', () => {
    expect(migration).toMatch(/grant update \(status, admin_response\) on public\.support_tickets to authenticated/i);
    expect(migration).toMatch(/create policy support_tickets_update_admin[\s\S]*?using[\s\S]*?auth\.jwt\(\)->'app_metadata'->>'role'[\s\S]*?'admin'/i);
  });

  it('writes the Production audit_logs.details column', () => {
    expect(migration).toMatch(/insert into public\.audit_logs\(actor_user_id, action, entity_type, entity_id, details\)/i);
    expect(migration).not.toMatch(/insert into public\.audit_logs\([^)]*metadata/i);
  });

  it('bounds user-controlled content and updates timestamps server-side', () => {
    expect(migration).toMatch(/char_length\(btrim\(subject\)\) between 4 and 120/i);
    expect(migration).toMatch(/char_length\(btrim\(message\)\) between 10 and 5000/i);
    expect(migration).toMatch(/before update on public\.support_tickets/i);
  });
});
