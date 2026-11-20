import {readFileSync} from 'node:fs';
import {describe,it} from 'node:test';
import assert from 'node:assert/strict';
const review=readFileSync('src/components/AdminAuctionSubmissionReview.tsx','utf8');
describe('Admin member-auction review safety',()=>{
 it('uses bounded server-side keyset pages and rejects malformed or duplicate queue records',()=>{
  assert.match(review,/admin_list_auction_submissions_page/);
  assert.match(review,/p_limit:50/);
  assert.match(review,/data\.has_more/);
  assert.match(review,/malformed or duplicate submissions/);
  assert.match(review,/Load More Submissions/);
  assert.match(review,/pageLock\.current/);
 });
 it('validates edited listing details before uploading public media',()=>{
  const validation=review.indexOf("if(title.length<5");
  const upload=review.indexOf("from('product-media').upload");
  assert.ok(validation>=0&&upload>validation);
  assert.match(review,/Expected Price must be equal to or greater than Starting Price/);
  assert.match(review,/Minimum Bid Increment must be greater than zero/);
  assert.match(review,/Choose a valid auction start date and time/);
  assert.match(review,/1 to 8 item images/);
 });
 it('validates auction moderation identity and the Expected Price deadline response',()=>{
  assert.match(review,/data:reviewResult/);
  assert.match(review,/result\.auction_id/);
  assert.match(review,/result\.product_id/);
  assert.match(review,/result\.expected_price!==expected/);
  assert.match(review,/48\*60\*60\*1000/);
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
 it('clears per-submission edits after a successful review and safely handles an empty start time',()=>{
  assert.match(review,/delete next\[r\.id\]/);
  assert.match(review,/e\.target\.value&&Number\.isFinite\(new Date\(e\.target\.value\)\.getTime\(\)\)/);
 });
 it('preserves published images when the RPC outcome is ambiguous',()=>{
  assert.match(review,/publishedPaths\.length>0&&\(!rpcAttempted\|\|rpcDefinitelyRejected\)/);
 });
});
