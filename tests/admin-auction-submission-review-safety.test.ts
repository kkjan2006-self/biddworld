import {readFileSync} from 'node:fs';
import {describe,it} from 'node:test';
import assert from 'node:assert/strict';
const review=readFileSync('src/components/AdminAuctionSubmissionReview.tsx','utf8');
describe('Admin member-auction review safety',()=>{
 it('validates edited listing details before uploading public media',()=>{
  const validation=review.indexOf("if(title.length<3");
  const upload=review.indexOf("from('product-media').upload");
  assert.ok(validation>=0&&upload>validation);
  assert.match(review,/Expected Price must be equal to or greater than Starting Price/);
  assert.match(review,/Minimum Bid Increment must be greater than zero/);
  assert.match(review,/Choose a valid auction start date and time/);
  assert.match(review,/1 to 8 item images/);
 });
 it('serializes review actions and avoids duplicate submissions',()=>{
  assert.match(review,/reviewInFlight\.current/);
  assert.match(review,/reviewInFlight\.current=true/);
  assert.match(review,/reviewInFlight\.current=false/);
 });
 it('cleans uploaded public images after pre-RPC failure or definite RPC rejection only',()=>{
  assert.match(review,/rpcDefinitelyRejected=typeof \(error as \{code\?:unknown\}\)\.code==='string'/);
  assert.match(review,/publishedPaths\.length>0&&\(!rpcAttempted\|\|rpcDefinitelyRejected\)/);
  assert.match(review,/from\('product-media'\)\.remove\(publishedPaths\)/);
 });
 it('preserves published images when the RPC outcome is ambiguous',()=>{
  assert.match(review,/publishedPaths\.length>0&&\(!rpcAttempted\|\|rpcDefinitelyRejected\)/);
 });
});
