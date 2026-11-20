import { afterEach, describe, expect, it, vi } from 'vitest';
import { left, money } from '../src/lib/format';

describe('money', () => {
  it('formats INR using Indian digit grouping', () => {
    expect(money(1250)).toContain('1,250');
  });

  it('safely formats non-finite amounts as zero', () => {
    expect(money(Number.NaN)).toContain('0');
    expect(money(Number.POSITIVE_INFINITY)).toContain('0');
  });

  it('falls back to INR for malformed currency codes', () => {
    expect(() => money(100, 'not-a-currency')).not.toThrow();
    expect(money(100, 'INR')).toBe(money(100, 'bad'));
  });
});

describe('auction time remaining', () => {
  afterEach(() => vi.useRealTimers());

  it('marks past auctions ended', () => {
    expect(left('2000-01-01T00:00:00.000Z')).toBe('Ended');
  });

  it('reports remaining days and hours', () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-01-01T00:00:00.000Z'));
    expect(left('2026-01-02T03:00:00.000Z')).toBe('1d 3h left');
  });

  it('reports remaining hours and minutes', () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-01-01T00:00:00.000Z'));
    expect(left('2026-01-01T02:15:00.000Z')).toBe('2h 15m left');
  });

  it('handles invalid timestamps without displaying NaN', () => {
    expect(left('not-a-date')).toBe('Unavailable');
  });
});
