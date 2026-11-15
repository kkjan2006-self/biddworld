import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const admin = readFileSync(resolve(process.cwd(), 'src/components/Admin.tsx'), 'utf8');
const migration = readFileSync(resolve(process.cwd(), 'supabase/migrations/20261116070000_delivery_tracking_backend.sql'), 'utf8');

describe('delivery tracking feature gate', () => {
  it('uses the server-side feature switch instead of an obsolete missing-source UI lock', () => {
    expect(admin).not.toMatch(/backendPendingFeatureKeys\s*=\s*new Set\(\[[\s\S]*?['"]delivery_tracking_enabled['"]/);
    expect(migration).toMatch(/private\.enforce_feature_gate\(\)/);
    expect(migration).toMatch(/delivery_tracking_enabled/);
  });
});
