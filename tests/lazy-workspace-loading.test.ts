import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const app = readFileSync(resolve(process.cwd(), 'src/App.tsx'), 'utf8');

describe('lazy-loaded workspace modules', () => {
  const modules = [
    'Packages',
    'Referrals',
    'WalletHistory',
    'FixedBid',
    'Admin',
    'Support',
    'Notifications',
    'Account',
    'DashboardPreview',
  ];

  it('keeps secondary workspaces out of the initial eager module graph', () => {
    expect(app).toMatch(/import\s*\{\s*lazy\s*,\s*Suspense/);
    for (const name of modules) {
      expect(app).toMatch(new RegExp('const\\s+' + name + '\\s*=\\s*lazy\\('));
      expect(app).toContain(`import('./components/${name}')`);
    }
  });

  it('provides an accessible loading fallback for each lazy workspace render', () => {
    expect(app).toContain('function WorkspaceFallback()');
    expect(app).toContain('role="status"');
    expect(app).toContain('aria-live="polite"');
    expect(app).toContain('<Suspense fallback={<WorkspaceFallback/>}>');
    expect((app.match(/<Suspense fallback=\{<WorkspaceFallback\/>\}>/g) ?? []).length).toBeGreaterThanOrEqual(9);
  });
});
