import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const source=readFileSync('src/components/AdminStaff.tsx','utf8');
describe('Admin Staff permission-gated JSX structure',()=>{
 it('closes the auction submission review permission branch before the main layout closes',()=>{
  expect(source).toContain("{permissions.includes('auction_submission_review')&&<AdminAuctionSubmissionReview/>}");
  expect(source).not.toContain("{permissions.includes('auction_submission_review')&&<AdminAuctionSubmissionReview/>\n </main>;");
 });
 it('keeps the review component behind its assigned permission',()=>{
  expect(source).toContain("{permissions.includes('wallet_funding_review')&&<AdminWalletFundingReview/>}");
  expect(source).toContain("{permissions.includes('auction_submission_review')&&<AdminAuctionSubmissionReview/>}");
 });
});
