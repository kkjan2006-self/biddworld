import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const app=readFileSync('src/App.tsx','utf8');
describe('live auction catalogue error and empty states',()=>{
 it('shows sample auctions only when the backend is intentionally unconfigured',()=>{
  expect(app).toContain('const showingAuctionSamples=items.length===0&&!auctionError&&!configured;');
  expect(app).toContain("[user,setUser]=useState<User|null>(null),[items,setItems]=useState<Auction[]>([])");
 });
 it('does not disguise a configured RPC failure as sample auction inventory',()=>{
  expect(app).toContain("catch(caught){if(live&&requestId===auctionPageRequest.current)");
  expect(app).toContain('isRpcContractUnavailable(caught)');
  expect(app).not.toContain('isRpcContractUnavailable(error)?');
 });
});
