import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const source=readFileSync(resolve(process.cwd(),'src/components/MemberProductSubmission.tsx'),'utf8');

describe('Member product structured details integrity',()=>{
 it('keeps the validated numeric Price field protected from arbitrary extra attributes',()=>{
  expect(source).toContain('Price:String(numericPrice)');
  expect(source).toContain("new Set(['brand','model','condition','age','location','price','warranty','ownership'])");
  expect(source).toContain('!reservedDetailKeys.has(k.toLowerCase())');
 });
});
