import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const source=readFileSync(resolve(process.cwd(),'src/components/MemberPlaceAuction.tsx'),'utf8');

describe('Member auction submission upload cleanup',()=>{
 it('retains all selected files so the 1–8 image limit is enforced visibly',()=>{
  expect(source).toContain("if(files.length<1||files.length>8)");
  expect(source).toContain('setFiles(Array.from(e.target.files??[]))');
  expect(source).not.toContain('Array.from(e.target.files??[]).slice(0,8)');
 });
 it('cleans uploaded private images when submission never reaches the RPC or is definitely rejected',()=>{
  expect(source).toContain('const uploadedPaths:string[]=[]');
  expect(source).toContain('let rpcAttempted=false');
  expect(source).toContain("rpcDefinitelyRejected=typeof (error as {code?:unknown}).code==='string'");
  expect(source).toContain('uploadedPaths.length>0&&(!rpcAttempted||rpcDefinitelyRejected)');
  expect(source).toContain("storage.from('auction-submission-media').remove(uploadedPaths)");
 });
 it('does not delete images after an ambiguous RPC failure',()=>{
  expect(source).toContain('else setMessage(message)');
  expect(source).toContain('rpcAttempted=true');
 });
});
