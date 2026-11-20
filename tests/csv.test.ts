import { describe, expect, it } from 'vitest';
import { csvCell, csvDocument } from '../src/lib/csv';

describe('safe CSV serialization', () => {
  it('quotes cells and escapes embedded quotes', () => {
    expect(csvCell('A "quoted" name')).toBe('"A ""quoted"" name"');
  });

  it.each(['=1+1', '+SUM(A1:A2)', '-2+3', '@HYPERLINK("x")', '  =1+1', '\t=1+1'])(
    'neutralizes spreadsheet formulas beginning with %s',
    value => {
      expect(csvCell(value).startsWith('"\'')).toBe(true);
    },
  );

  it('preserves ordinary values and empty cells', () => {
    expect(csvCell('BID-100')).toBe('"BID-100"');
    expect(csvCell(null)).toBe('""');
  });

  it('creates a UTF-8 BOM document with CRLF row separators', () => {
    expect(csvDocument([['ID', 'Name'], ['1', 'Member']])).toBe(
      '\ufeff"ID","Name"\r\n"1","Member"',
    );
  });
});
