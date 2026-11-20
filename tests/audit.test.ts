import { describe, expect, it } from 'vitest';
import { filterAuditEntries } from '../src/lib/audit';

const entries = [
  { id: 1, action: 'package_approved', actor_name: 'Admin One', entity_type: 'package_activation', entity_id: 'abc-123', details: { amount: 500, note: 'UPI verified' } },
  { id: 2, action: 'member_updated', actor_name: 'Admin Two', entity_type: 'profile', entity_id: 'xyz-789', details: { field: 'phone' } },
];

describe('audit log search', () => {
  it('returns all entries for an empty query', () => {
    expect(filterAuditEntries(entries, ' ')).toEqual(entries);
  });
  it('matches action, actor, entity type and entity id without case sensitivity', () => {
    for (const query of ['PACKAGE_APPROVED', 'admin one', 'PACKAGE_ACTIVATION', 'ABC-123']) {
      expect(filterAuditEntries(entries, query).map(x => x.id)).toEqual([1]);
    }
  });
  it('searches serialized details', () => {
    expect(filterAuditEntries(entries, 'upi verified').map(x => x.id)).toEqual([1]);
    expect(filterAuditEntries(entries, '500').map(x => x.id)).toEqual([1]);
  });
  it('returns no entries for unmatched queries', () => {
    expect(filterAuditEntries(entries, 'not-found')).toEqual([]);
  });
});
