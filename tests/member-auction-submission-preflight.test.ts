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

  it('records generated image paths before upload so ambiguous upload failures can be cleaned',()=>{
    const tracked=source.indexOf('uploadedPaths.push(path)');
    const upload=source.indexOf("supabase.storage.from('auction-submission-media').upload");
    expect(tracked).toBeGreaterThan(-1);
    expect(upload).toBeGreaterThan(tracked);
  });

  it('preflights every selected image type and size before the first upload', () => {
    const preflight = source.indexOf("for(const file of files){if(!['image/jpeg','image/png','image/webp'].includes(file.type)||file.size>5*1024*1024)");
    const firstUpload = source.indexOf("supabase.storage.from('auction-submission-media').upload");
    expect(preflight).toBeGreaterThan(-1);
    expect(firstUpload).toBeGreaterThan(preflight);
  });
  it('matches the server 30-minute start-time lead requirement before uploading', () => {
    const startValidation = source.indexOf('startsAt.getTime()<Date.now()+30*60*1000');
    const firstUpload = source.indexOf("supabase.storage.from('auction-submission-media').upload");
    expect(startValidation).toBeGreaterThan(-1);
    expect(firstUpload).toBeGreaterThan(startValidation);
    expect(source).toContain('at least 30 minutes in the future');
    expect(source).toContain('p_starts_at:startsAt.toISOString()');
  });

  it('does not leave a literal escaped newline between form sections', () => {
    expect(source).not.toContain('</select></label>\\n <div');
  });

  it('distinguishes loading, empty and failed submission history and supports retry', () => {
    expect(source).toContain('const[queueLoading,setQueueLoading]=useState(true)');
    expect(source).toContain('const[queueError,setQueueError]=useState(\'\')');
    expect(source).toContain('Loading your auction submissions…');
    expect(source).toContain('You have not submitted any auctions yet.');
    expect(source).toContain('Retry submissions');
    expect(source).toContain('loadSequence.current++');
  });

  it('rejects malformed or duplicate submission history rows', () => {
    expect(source).toContain('typeof row.id!==\'string\'');
    expect(source).toContain('ids.has(row.id)');
    expect(source).toContain('invalid or duplicate records');
  });

  it('round-trips optional detail lines as actual newlines and enforces the required Expected Price', () => {
    expect(source).toContain(".join('\\n')");
    expect(source).toContain("expected_price:number");
    expect(source).not.toContain('expected_price:number|null');
    expect(source).toContain("typeof row.expected_price==='number'&&Number.isFinite(row.expected_price)&&row.expected_price>=row.starting_price");
  });

});