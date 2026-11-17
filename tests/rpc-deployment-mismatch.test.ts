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
