import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const sql = readFileSync(
  resolve(process.cwd(), 'supabase/migrations/20261116060000_support_ticket_notifications.sql'),
  'utf8',
);

describe('support ticket to member notification integration', () => {
  it('runs only after ticket updates and only for trusted Admin claims', () => {
    expect(sql).toMatch(/after update on public\.support_tickets[\s\S]*?execute function public\.notify_member_on_support_ticket_update\(\)/i);
    expect(sql).toMatch(/auth\.jwt\(\)->'app_metadata'->>'role'.*'admin'/is);
  });

  it('notifies the ticket owner only when status or response changes', () => {
    expect(sql).toMatch(/old\.status is distinct from new\.status[\s\S]*?old\.admin_response is distinct from new\.admin_response/i);
    expect(sql).toMatch(/insert into public\.member_notifications\(user_id, title, message, category\)[\s\S]*?new\.user_id[\s\S]*?'support'/i);
  });

  it('bounds notification text and prevents direct function execution', () => {
    expect(sql).toMatch(/left\([\s\S]*?2000\s*\)/i);
    expect(sql).toMatch(/revoke all on function public\.notify_member_on_support_ticket_update\(\) from public, anon, authenticated/i);
  });
});
