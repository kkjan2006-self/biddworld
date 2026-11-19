import {describe,expect,it} from 'vitest';
import {validateAuctionDraftInput} from '../src/lib/auction-draft';

const valid={
  productId:'product-1',title:'Weekend Auction',
  startingPrice:'100',expectedPrice:'250',minimumIncrement:'1',
  startsAt:'2026-11-18T10:00'
};

describe('auction draft input validation',()=>{
  it('accepts positive starting price and expected price at or above it',()=>{
    expect(validateAuctionDraftInput(valid)).toBe('');
    expect(validateAuctionDraftInput({...valid,expectedPrice:'100'})).toBe('');
  });
  it('requires a selected draft product and a 3–180 character title',()=>{
    expect(validateAuctionDraftInput({...valid,productId:''})).toContain('select a draft product');
    expect(validateAuctionDraftInput({...valid,title:'ab'})).toContain('3 and 180');
    expect(validateAuctionDraftInput({...valid,title:'x'.repeat(181)})).toContain('3 and 180');
  });
  it('rejects non-positive starting price, expected price below start and invalid increment',()=>{
    expect(validateAuctionDraftInput({...valid,startingPrice:'NaN'})).toContain('Starting Price');
    expect(validateAuctionDraftInput({...valid,startingPrice:'0'})).toContain('Starting Price');
    expect(validateAuctionDraftInput({...valid,expectedPrice:'99'})).toContain('Expected Price');
    expect(validateAuctionDraftInput({...valid,minimumIncrement:'0'})).toContain('increment');
  });
  it('validates optional start date without requiring an end date',()=>{
    expect(validateAuctionDraftInput({...valid,startsAt:''})).toBe('');
    expect(validateAuctionDraftInput({...valid,startsAt:'not-a-date'})).toContain('valid auction start');
    expect(validateAuctionDraftInput({...valid,startsAt:'2026-02-30T10:00'})).toContain('valid auction start');
    expect(validateAuctionDraftInput({...valid,startsAt:'2026-11-18'})).toContain('valid auction start');
  });
  it('rejects blank numeric values',()=>{
    expect(validateAuctionDraftInput({...valid,startingPrice:''})).toContain('Starting Price');
    expect(validateAuctionDraftInput({...valid,expectedPrice:''})).toContain('Expected Price');
    expect(validateAuctionDraftInput({...valid,minimumIncrement:''})).toContain('increment');
  });
});
