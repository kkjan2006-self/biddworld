import { describe, expect, it } from 'vitest';
import { isRpcContractUnavailable } from '../src/lib/rpc-errors';

describe('RPC deployment mismatch detection', () => {
  it('recognizes PostgREST missing/stale function signatures', () => {
    expect(isRpcContractUnavailable({ code: 'PGRST202', message: 'Could not find the function in the schema cache' })).toBe(true);
    expect(isRpcContractUnavailable({ code: '42883', message: 'function does not exist' })).toBe(true);
    expect(isRpcContractUnavailable({ message: 'Could not find the function public.place_bid in the schema cache' })).toBe(true);
  });
  it('does not classify authorization, validation or network errors as deployment mismatches', () => {
    expect(isRpcContractUnavailable({ code: '42501', message: 'Administrator access required' })).toBe(false);
    expect(isRpcContractUnavailable({ code: '22023', message: 'Invalid input' })).toBe(false);
    expect(isRpcContractUnavailable(new Error('Network request failed'))).toBe(false);
    expect(isRpcContractUnavailable(null)).toBe(false);
  });
});


import { rpcContractUnavailableMessage } from '../src/lib/rpc-errors';

describe('RPC deployment guidance', () => {
  it('returns actionable guidance for a missing member dashboard RPC', () => {
    expect(rpcContractUnavailableMessage({ code: 'PGRST202' }, 'Your team dashboard')).toContain('database RPC update has not been installed');
  });
  it('returns actionable guidance for a missing profile RPC', () => {
    expect(rpcContractUnavailableMessage({ code: '42883' }, 'Profile updates')).toContain('Please contact the administrator');
  });
  it('preserves ordinary server errors instead of mislabeling them as deployment problems', () => {
    expect(rpcContractUnavailableMessage({ code: '42501', message: 'permission denied' }, 'Profile updates')).toBeNull();
  });
});
