import {readdirSync,readFileSync,statSync} from 'node:fs';
import {join,relative,extname} from 'node:path';
import {describe,expect,it} from 'vitest';

const roots=['src','tests'];
const textExtensions=new Set(['.ts','.tsx','.js','.jsx','.json','.css','.html','.md']);
function collectFiles(directory:string):string[]{
 const files:string[]=[];
 for(const name of readdirSync(directory)){
  const path=join(directory,name),info=statSync(path);
  if(info.isDirectory())files.push(...collectFiles(path));
  else if(textExtensions.has(extname(name)))files.push(path);
 }
 return files;
}

describe('English-only project source policy',()=>{
 it('keeps application source and automated tests free of Telugu characters',()=>{
  const violations=roots.flatMap(root=>collectFiles(root)).filter(path=>/[\u0C00-\u0C7F]/u.test(readFileSync(path,'utf8')));
  expect(violations.map(path=>relative(process.cwd(),path))).toEqual([]);
 });
});
