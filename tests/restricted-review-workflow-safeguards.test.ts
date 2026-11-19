import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const staff=readFileSync(resolve(process.cwd(),'src/components/AdminStaff.tsx'),'utf8');
const auction=readFileSync(resolve(process.cwd(),'src/components/AdminAuctionSubmissionReview.tsx'),'utf8');
const manager=readFileSync(resolve(process.cwd(),'src/components/AdminPaymentReviewStaff.tsx'),'utf8');

describe('Restricted review workflow safeguards',()=>{
 it('keeps package activation queue errors distinct from a genuine empty queue',()=>{
  expect(staff).toContain('Package activation queue could not be loaded:');
  expect(staff).toContain('Loading package activation requests…');
  expect(staff).toContain('No pending package payment requests.');
  expect(staff).toContain('Retry queue');
 });
 it('requires a signed package receipt before activation approval',()=>{
  expect(staff).toContain('Open and verify the payment receipt before approving this activation.');
  expect(staff).toContain('disabled={!!busy||!urls[item.id]}');
  expect(staff).toContain('reviewInFlight.current');
 });
 it('does not present a failed auction queue as an empty queue',()=>{
  expect(auction).toContain('Auction submission queue could not be loaded:');
  expect(auction).toContain('Loading auction submissions…');
  expect(auction).toContain('Retry queue');
  expect(auction).toContain('Image preview issue:');
 });
 it('blocks auction approval until every submitted image has a signed preview URL',()=>{
  expect(auction).toContain('disabled={!!busy||(r.image_paths??[]).length<1||(urls[r.id]??[]).length!==(r.image_paths??[]).length}');
 });
 it('uses a consistent string busy token for Staff permission mutations',()=>{
  expect(manager).toContain('[busy,setBusy]=useState(\'\')');
  expect(manager).not.toContain('setBusy(true)');
  expect(manager).toContain('setBusy(\'saving\')');
  expect(manager).toContain('Staff directory could not be loaded:');
 });
});
