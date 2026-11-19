import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const member=readFileSync(resolve(process.cwd(),'src/components/MemberPlaceAuction.tsx'),'utf8');
const review=readFileSync(resolve(process.cwd(),'src/components/AdminAuctionSubmissionReview.tsx'),'utf8');
const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');

describe('OLX-style auction classified fields and role boundaries',()=>{
 it('collects category, brand/model, condition, age, warranty, ownership and complete location details',()=>{
  for(const field of ['Brand','Model','Condition','Age','Warranty','Ownership','Location','City','State','Pincode']) expect(member).toContain(field);
  expect(member).toContain("p_optional_details:optional");
  expect(member).toContain('pattern="[0-9]{6}"');
 });
 it('passes classified attributes through the review workflow and exposes them for Admin editing',()=>{
  expect(review).toContain('r.optional_details');
  expect(review).toContain('p_optional_details:v.optional_details??r.optional_details');
 });
 it('keeps Fixed Bid campaign creation in the Admin workspace while member-facing auction submission remains separate',()=>{
  expect(admin).toContain('Save Fixed Bid Draft');
  expect(member).toContain('Place an Auction');
  expect(member).toContain('Pending Admin Approval');
 });
});
