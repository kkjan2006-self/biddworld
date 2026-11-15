import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const readSource = (path: string) => readFileSync(resolve(process.cwd(), path), 'utf8');

describe('dashboard navigation integrity', () => {
  const admin = readSource('src/components/Admin.tsx');
  const account = readSource('src/components/Account.tsx');

  it('keeps every Admin navigation link connected to exactly one section', () => {
    const ids = [...admin.matchAll(/\\bid="([^"]+)"/g)].map((match) => match[1]);
    const targets = [...admin.matchAll(/href="#(admin-[^"]+)"/g)].map((match) => match[1]);

    expect(new Set(ids).size).toBe(ids.length);
    expect(targets.length).toBeGreaterThan(10);
    for (const target of targets) {
      expect(ids.filter((id) => id === target), `Admin navigation target #${target}`).toHaveLength(1);
    }
  });

  it('keeps each Member Dashboard menu section connected to its section container', () => {
    const ids = [...account.matchAll(/\\bid="(member-[^"]+)"/g)].map((match) => match[1]);
    const menuKeys = [...account.matchAll(/setActiveSection\\('((?:member)-[^']+)'\\)/g)].map((match) => match[1]);

    expect(new Set(ids).size).toBe(ids.length);
    expect(menuKeys.length).toBeGreaterThan(8);
    for (const key of new Set(menuKeys)) {
      expect(ids, `Member navigation target #${key}`).toContain(key);
    }
  });

  it('exposes the paginated member wallet history control when more rows exist', () => {
    const walletHistory = readSource('src/components/WalletHistory.tsx');
    expect(walletHistory).toMatch(/hasMore\s*&&\s*<button/i);
    expect(walletHistory).toMatch(/Load 100 more transactions/);
    expect(walletHistory).toMatch(/setPage\(current\s*=>\s*current\s*\+\s*1\)/);
  });
});
