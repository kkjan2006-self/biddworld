import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const source=readFileSync(resolve(process.cwd(),'src/components/FixedBid.tsx'),'utf8');
describe('Fixed Bid catalogue pagination',()=>{
 it('uses bounded stable pages for published campaign states',()=>{
  expect(source).toContain('const PAGE_SIZE=50');
  expect(source).toContain(".in('status',['scheduled','live','ended'])");
  expect(source).toContain(".order('created_at',{ascending:false}).order('id',{ascending:false}).range(offset,offset+PAGE_SIZE-1)");
 });
 it('offers continuation while keeping the campaign surface read-only',()=>{
  expect(source).toContain('Load more campaigns');
  expect(source).toContain('no entries or payments are processed here');
  expect(source).not.toMatch(/\.rpc\(/);
  expect(source).not.toMatch(/\.insert\(|\.update\(|\.upsert\(/);
 });
});

describe('Fixed Bid catalogue filtering',()=>{
 it('filters loaded campaigns by status and case-insensitive campaign or product text',()=>{
  expect(source).toContain("const [search,setSearch]=useState(''),[statusFilter,setStatusFilter]=useState<'all'|'scheduled'|'live'|'ended'>('all')");
  expect(source).toContain('const visibleRows=rows.filter(row=>(statusFilter===\'all\'||row.status===statusFilter)');
  expect(source).toContain('row.title,row.description??\'\',row.product?.name??\'\',row.product?.category??\'\'');
  expect(source).toContain('No loaded campaigns match these filters.');
 });
});
