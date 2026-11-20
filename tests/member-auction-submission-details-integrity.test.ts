import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const source=readFileSync(resolve(process.cwd(),'src/components/MemberPlaceAuction.tsx'),'utf8');

describe('Member auction structured details integrity',()=>{
 it('prevents Additional Features from overriding structured listing fields',()=>{
  expect(source).toContain("const reservedDetailKeys=new Set(['brand','model','condition','age','warranty','ownership','location','city','state','pincode'])");
  expect(source).toContain('!reservedDetailKeys.has(k.toLowerCase())');
 });
});
