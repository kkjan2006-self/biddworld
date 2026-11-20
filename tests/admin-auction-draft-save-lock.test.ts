import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');
describe('Admin auction draft save concurrency',()=>{
 it('acquires a synchronous in-flight lock before the RPC call',()=>{
  expect(admin).toContain('auctionSaveInFlight=useRef(false)');
  expect(admin).toContain('if(!supabase||auctionSaveInFlight.current)return');
  expect(admin).toContain("auctionSaveInFlight.current=true;setAuctionBusy(true)");
  expect(admin).toContain("supabase.rpc('admin_save_auction_draft'");
 });
 it('releases the lock in finally after success or failure',()=>{
  expect(admin).toContain('finally{auctionSaveInFlight.current=false;setAuctionBusy(false);}');
 });
});
