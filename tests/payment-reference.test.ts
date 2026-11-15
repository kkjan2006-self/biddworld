import { describe, expect, it } from 'vitest';
import { normalizePaymentReference } from '../src/lib/payment-reference';

describe('payment reference validation', () => {
  it('trims surrounding whitespace', () => {
    expect(normalizePaymentReference('  UPI123456  ')).toBe('UPI123456');
  });

  it('accepts allowed letters, numbers and separators', () => {
    expect(normalizePaymentReference('abC123./_-')).toBe('abC123./_-');
  });

  it('rejects references shorter than six characters', () => {
    expect(normalizePaymentReference('12345')).toBeNull();
  });

  it('rejects references longer than eighty characters', () => {
    expect(normalizePaymentReference('a'.repeat(81))).toBeNull();
  });

  it.each(['ABC 123', 'ABC@123', 'ABC#123', 'ABC\n123', ''])(
    'rejects unsupported characters or blank input: %s',
    value => expect(normalizePaymentReference(value)).toBeNull(),
  );
});
