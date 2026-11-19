import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const review=readFileSync(resolve(process.cwd(),'src/components/AdminAuctionSubmissionReview.tsx'),'utf8');
const app=readFileSync(resolve(process.cwd(),'src/App.tsx'),'utf8');
const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119140000_approved_auction_public_media_delivery.sql'),'utf8');
describe('Approved auction public media delivery',()=>{
 it('copies private submission images into public product media only during approval',()=>{
  expect(review).toContain("storage.from('auction-submission-media').download(privatePath)");
  expect(review).toContain("storage.from('product-media').upload(publicPath");
  expect(review).toContain("if(decision==='approve')");
  expect(review).toContain('p_image_paths:approvedImagePaths');
 });
 it('resolves public media object paths for catalogue cards and detail views',()=>{
  expect(app).toContain("storage.from('product-media').getPublicUrl(path)");
  expect(app).toContain('publicAuctionMediaUrl(a.image_url)');
  expect(app).toContain('publicAuctionMediaUrl(p.image_path)');
  expect(app).toContain('publicAuctionMediaUrl(detail.image_url)');
 });
 it('allows public reads and only Admin or auction-review Staff uploads',()=>{
  expect(migration).toContain("values('product-media','product-media',true");
  expect(migration).toContain("role','')='admin'");
  expect(migration).toContain("? 'auction_submission_review'");
 });
});
