import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const source=readFileSync('src/components/Admin.tsx','utf8');
describe('Admin workspace delivery queue block structure',()=>{
 it('closes the delivery-generation guard before wallet account loading',()=>{
  expect(source).toContain("else setDeliveryMessage('Delivery tracking could not be loaded: '+deliveryResult.error.message);}\n   if(walletAccountsGeneration");
 });
 it('keeps the Admin workspace catch and finally aligned after delivery processing',()=>{
  const start=source.indexOf('async function load(){',source.indexOf('useEffect(()=>{',source.indexOf('const [featureMessage')));
  const end=source.indexOf('void load();return()=>{active=false;};',start);
  const block=source.slice(start,end);
  expect(block).toContain('}catch(loadError){');
  expect(block).toContain('}finally{');
  expect(block.indexOf('if(deliveryGeneration')).toBeLessThan(block.indexOf('if(walletAccountsGeneration'));
  expect(block.indexOf('if(walletAccountsGeneration')).toBeLessThan(block.indexOf('}catch(loadError){'));
 });
});
