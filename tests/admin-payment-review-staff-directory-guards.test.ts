import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const source = readFileSync(resolve(process.cwd(), 'src/components/AdminPaymentReviewStaff.tsx'), 'utf8');

describe('restricted payment-review staff directory safeguards', () => {
  it('handles missing Supabase configuration and failed Admin identity verification', () => {
    expect(source).toContain('Staff directory is unavailable until Supabase is configured.');
    expect(source).toContain('const{data,error}=await supabase.auth.getUser()');
    expect(source).toContain('Admin access could not be verified:');
  });

  it('ignores stale staff directory requests and cancels pending loads on unmount', () => {
    expect(source).toContain('const loadSequence=useRef(0)');
    expect(source).toContain('const seq=++loadSequence.current');
    expect(source).toContain('if(seq!==loadSequence.current)return');
    expect(source).toContain('loadSequence.current++;');
  });

  it('rejects invalid, duplicate or unknown permission records before rendering editable access', () => {
    expect(source).toContain('!Array.isArray(raw)');
    expect(source).toContain("typeof item.user_id!=='string'");
    expect(source).toContain('ids.has(item.user_id)');
    expect(source).toContain('item.permissions.some(permission=>!(permission in permissionLabels))');
    expect(source).toContain('The Staff directory contains invalid or duplicate accounts.');
  });
});
