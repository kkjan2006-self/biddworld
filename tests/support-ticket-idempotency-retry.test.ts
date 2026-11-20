import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const source = readFileSync(resolve(process.cwd(), 'src/components/Support.tsx'), 'utf8');

describe('support ticket idempotent retry behavior', () => {
  it('reuses the same request key for retries with identical content', () => {
    expect(source).toContain("submitKeyPayload=useRef('')");
    expect(source).toContain("const submissionPayload=JSON.stringify([subject.trim(),message.trim()])");
    expect(source).toContain("p_idempotency_key:submitKey.current");
  });

  it('generates a fresh request key when the member changes the subject or message', () => {
    expect(source).toContain("if(submitKeyPayload.current!==submissionPayload){submitKey.current='';submitKeyPayload.current=submissionPayload;}");
    expect(source).toContain("if(!submitKey.current){const bytes=new Uint8Array(16);window.crypto.getRandomValues(bytes);");
  });

  it('clears the payload fingerprint after a successful submission', () => {
    expect(source).toContain("submitKey.current='';submitKeyPayload.current='';setSubject('');setMessage('')");
  });
  it('validates support ticket submit and admin update RPC result identity before showing success', () => {
    expect(source).toContain('result.success!==true');
    expect(source).toContain('result.ticket_id!==id');
    expect(source).toContain('result.status!==nextStatus');
    expect(source).toContain('typeof result.replayed!==\'boolean\'');
    expect(source).toContain('same request key is retained');
  });
});
