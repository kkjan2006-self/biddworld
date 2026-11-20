import { describe, expect, it } from 'vitest';
import { isSponsorLookupValid } from '../src/lib/sponsor-lookup';

describe('Sponsor lookup response compatibility', () => {
  it('accepts the privacy-minimized boolean contract', () => {
    expect(isSponsorLookupValid(true, 'BW1234567890')).toBe(true);
    expect(isSponsorLookupValid(false, 'BW1234567890')).toBe(false);
  });

  it('accepts the legacy table response only when the exact requested Main ID is returned', () => {
    expect(isSponsorLookupValid([{ member_code: 'BW1234567890', display_name: 'Ignored' }], 'bw1234567890')).toBe(true);
    expect(isSponsorLookupValid([{ member_code: 'BW0000000000', display_name: 'Ignored' }], 'BW1234567890')).toBe(false);
  });

  it('rejects empty, malformed and unrelated response shapes', () => {
    expect(isSponsorLookupValid([], 'BW1234567890')).toBe(false);
    expect(isSponsorLookupValid(null, 'BW1234567890')).toBe(false);
    expect(isSponsorLookupValid({ member_code: 'BW1234567890' }, 'BW1234567890')).toBe(false);
    expect(isSponsorLookupValid([{ display_name: 'No code' }], 'BW1234567890')).toBe(false);
    expect(isSponsorLookupValid([{ member_code: 'BW1234567890' }], '')).toBe(false);
  });
});
