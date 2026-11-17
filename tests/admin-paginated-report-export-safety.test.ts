import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');

describe('Admin paginated report export safety',()=>{
 it('stops when the server repeats a full page instead of advancing offsets',()=>{
  expect(admin).toContain('const seenPages=new Set<string>();');
  expect(admin).toContain('const fingerprint=JSON.stringify(batch);');
  expect(admin).toContain('if(seenPages.has(fingerprint))throw new Error');
  expect(admin).toContain('The server repeated a report page.');
 });

 it('bounds report exports to 100,000 rows and reports a recoverable filter hint',()=>{
  expect(admin).toContain('for(let offset=0;offset<100000;offset+=100)');
  expect(admin).toContain('if(all.length>100000)throw new Error');
  expect(admin).toContain('The report exceeds the 100,000-row export safety limit.');
  expect(admin).toContain('The report reached the 100,000-row export safety limit.');
 });

 it('does not create a download until every requested page has passed the safety checks',()=>{
  const helper=admin.slice(admin.indexOf('async function exportPagedReport'),admin.indexOf('function exportWithdrawalsCsv'));
  expect(helper.indexOf('seenPages.has(fingerprint)')).toBeLessThan(helper.indexOf('downloadReport(filename,headers,rows)'));
  expect(helper.indexOf('all.length>100000')).toBeLessThan(helper.indexOf('downloadReport(filename,headers,rows)'));
 });
});
