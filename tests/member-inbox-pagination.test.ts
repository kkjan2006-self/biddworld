import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const support = readFileSync(resolve(process.cwd(), 'src/components/Support.tsx'), 'utf8');
const notifications = readFileSync(resolve(process.cwd(), 'src/components/Notifications.tsx'), 'utf8');

describe('member support and notification pagination', () => {
  it('loads support requests in bounded pages with deterministic ordering', () => {
    expect(support).toMatch(/const PAGE_SIZE\s*=\s*100/);
    expect(support).toMatch(/order\('updated_at',[\s\S]*?order\('id',[\s\S]*?range\(0,PAGE_SIZE-1\)/);
    expect(support).toMatch(/range\(from,from\+PAGE_SIZE-1\)/);
    expect(support).toMatch(/Load 100 more requests/);
  });

  it('loads notifications in bounded pages and clarifies the visible unread count', () => {
    expect(notifications).toMatch(/const PAGE_SIZE\s*=\s*100/);
    expect(notifications).toMatch(/order\('created_at',[\s\S]*?order\('id',[\s\S]*?range\(0,PAGE_SIZE-1\)/);
    expect(notifications).toMatch(/range\(from,from\+PAGE_SIZE-1\)/);
    expect(notifications).toMatch(/unread shown/);
    expect(notifications).toMatch(/Load 100 more notifications/);
  });
});
