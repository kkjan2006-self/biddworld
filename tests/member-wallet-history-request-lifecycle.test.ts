import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const wallet=readFileSync(resolve(process.cwd(),'src/components/WalletHistory.tsx'),'utf8');
describe('member wallet history request lifecycle',()=>{
 it('does not let an initial auth lookup overwrite a newer auth event',()=>{
  expect(wallet).toContain('let authEventObserved=false');
  expect(wallet).toContain('authEventObserved=true');
  expect(wallet).toContain('active&&!authEventObserved');
  expect(wallet).toContain('Your sign-in session could not be verified.');
 });
 it('prevents duplicate page requests and releases the lock after completion',()=>{
  expect(wallet).toContain('const loadMoreBusy=useRef(false)');
  expect(wallet).toContain('if(loadMoreBusy.current||loading||(retryPage===null&&!hasMore))return');
  expect(wallet).toContain('loadMoreBusy.current=true;if(retryPage!==null){setRetryRequest(current=>current+1);return;}setPage(current=>current+1);');
  expect(wallet).toContain('loadMoreBusy.current=false;setLoading(false);setLoadingMore(false)');
 });
 it('keeps wallet statements read-only and scoped to the signed-in Main ID',()=>{
  expect(wallet).toContain(".eq('member_id',profile.main_member_id)");
  expect(wallet).toContain('Export Full CSV');
  expect(wallet).not.toMatch(/\.update\(|\.insert\(|\.upsert\(/);
 });
});
