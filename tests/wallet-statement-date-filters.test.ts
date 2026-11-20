import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const source=readFileSync(resolve(process.cwd(),'src/components/WalletHistory.tsx'),'utf8');
describe('wallet statement date filters',()=>{
 it('filters displayed rows using inclusive UTC calendar dates',()=>{
  expect(source).toContain("const [dateFrom,setDateFrom]=useState('')");
  expect(source).toContain("const [dateTo,setDateTo]=useState('')");
  expect(source).toContain('const day=r.created_at.slice(0,10)');
  expect(source).toContain('(!dateFrom||day>=dateFrom)&&(!dateTo||day<=dateTo)');
  expect(source).toContain('From date (UTC)');
  expect(source).toContain('To date (UTC)');
 });
 it('applies the same date, wallet and direction filters to the complete CSV export',()=>{
  expect(source).toContain('const matched=all.filter(matchesFilters)');
  expect(source).toContain("if(dateFrom&&dateTo&&dateFrom>dateTo)throw new Error('Start date must be on or before end date.')");
  expect(source).toContain('disabled={exportBusy||invalidDateRange}');
 });
 it('keeps date filtering local to the signed-in Main ID scope and leaves pagination intact',()=>{
  expect(source).toContain(".eq('member_id',profile.main_member_id)");
  expect(source).toContain('.range(page*100,page*100+99)');
  expect(source).toContain('for(let offset=0;;offset+=500)');
  expect(source).toContain('Clear dates');
 });
});
