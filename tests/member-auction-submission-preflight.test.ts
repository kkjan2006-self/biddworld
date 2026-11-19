import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';

const source = readFileSync('src/components/MemberPlaceAuction.tsx', 'utf8');

describe('member auction submission preflight', () => {
  it('prevents duplicate submissions with a synchronous in-flight guard', () => {
    expect(source).toContain('const submitInFlight=useRef(false)');
    expect(source).toContain('if(!supabase||submitInFlight.current)return;submitInFlight.current=true');
    expect(source).toContain('finally{submitInFlight.current=false;setBusy(false)}');
  });

  it('validates trimmed title and description before uploading any media', () => {
    const titleValidation = source.indexOf('const cleanTitle=title.trim(),cleanDescription=description.trim()');
    const firstUpload = source.indexOf("supabase.storage.from('auction-submission-media').upload");
    expect(titleValidation).toBeGreaterThan(-1);
    expect(firstUpload).toBeGreaterThan(titleValidation);
    expect(source).toContain('cleanTitle.length<5||cleanTitle.length>180');
    expect(source).toContain('cleanDescription.length<20||cleanDescription.length>10000');
    expect(source).toContain('p_title:cleanTitle,p_description:cleanDescription');
  });

  it('preflights every selected image type and size before the first upload', () => {
    const preflight = source.indexOf("for(const file of files){if(!['image/jpeg','image/png','image/webp'].includes(file.type)||file.size>5*1024*1024)");
    const firstUpload = source.indexOf("supabase.storage.from('auction-submission-media').upload");
    expect(preflight).toBeGreaterThan(-1);
    expect(firstUpload).toBeGreaterThan(preflight);
  });
});
