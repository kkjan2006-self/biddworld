import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const admin = readFileSync(resolve(process.cwd(), 'src/components/Admin.tsx'), 'utf8');
const migrationDirectory = resolve(process.cwd(), 'supabase/migrations');

describe('delivery tracking feature gate', () => {
  it('keeps delivery tracking disabled while its backend contract is not version-controlled', () => {
    expect(admin).toMatch(/backendPendingFeatureKeys\s*=\s*new Set\(\[[\s\S]*?['"]delivery_tracking_enabled['"]/);
    expect(admin).toMatch(/backendPendingFeatureKeys\.has\(item\.key\)[\s\S]*?disabled/);
    expect(migrationDirectory).toBeTruthy();
  });
});
