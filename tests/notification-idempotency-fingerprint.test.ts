import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const source = readFileSync(resolve(process.cwd(), 'src/components/Notifications.tsx'), 'utf8');

describe('Admin notification idempotency fingerprint', () => {
  it('encodes recipient and message fields as an unambiguous tuple', () => {
    expect(source).toContain('const fingerprint=JSON.stringify([target,title.trim(),message.trim(),category]);');
    expect(source).not.toContain("const fingerprint=[target,title.trim(),message.trim(),category].join('|')");
  });

  it('reuses a key only when the complete notification payload is unchanged', () => {
    expect(source).toContain('sendKey.current.fingerprint!==fingerprint');
    expect(source).toContain('sendKey.current={key:Array.from(bytes,b=>b.toString(16).padStart(2,\'0\')).join(\'\'),fingerprint}');
    expect(source).toContain('sendKey.current=null;');
  });
});
