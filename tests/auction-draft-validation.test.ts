import {describe,expect,it} from 'vitest';
import {validateAuctionDraftInput} from '../src/lib/auction-draft';

const valid={
  productId:'product-1',title:'Weekend Auction',
  startingPrice:'0',minimumIncrement:'1',
  startsAt:'2026-11-18T10:00',endsAt:'2026-11-18T11:00'
};

describe('auction draft input validation',()=>{
  it('accepts valid draft data including a zero starting price',()=>{
    expect(validateAuctionDraftInput(valid)).toBe('');
  });
  it('requires a selected draft product and a 3–180 character title',()=>{
    expect(validateAuctionDraftInput({...valid,productId:''})).toContain('select a draft product');
    expect(validateAuctionDraftInput({...valid,title:'ab'})).toContain('3 and 180');
    expect(validateAuctionDraftInput({...valid,title:'x'.repeat(181)})).toContain('3 and 180');
  });
  it('rejects invalid prices and non-positive increments',()=>{
    expect(validateAuctionDraftInput({...valid,startingPrice:'NaN'})).toContain('Starting price');
    expect(validateAuctionDraftInput({...valid,startingPrice:'-1'})).toContain('Starting price');
    expect(validateAuctionDraftInput({...valid,minimumIncrement:'0'})).toContain('Starting price');
  });
  it('rejects invalid dates and end times that do not follow start times',()=>{
    expect(validateAuctionDraftInput({...valid,startsAt:'not-a-date'})).toContain('valid auction start');
    expect(validateAuctionDraftInput({...valid,endsAt:valid.startsAt})).toContain('after its start');
    expect(validateAuctionDraftInput({...valid,endsAt:'2026-11-18T09:00'})).toContain('after its start');
  });
  it('rejects impossible calendar dates and out-of-range times',()=>{
    expect(validateAuctionDraftInput({...valid,startsAt:'2026-02-30T10:00'})).toContain('valid auction start');
    expect(validateAuctionDraftInput({...valid,endsAt:'2026-11-18T25:00'})).toContain('valid auction start');
    expect(validateAuctionDraftInput({...valid,startsAt:'2026-11-18'})).toContain('valid auction start');
  });
  it('accepts valid seconds and fractional seconds in local date-time values',()=>{
    expect(validateAuctionDraftInput({...valid,startsAt:'2026-11-18T10:00:05',endsAt:'2026-11-18T10:00:06.250'})).toBe('');
  });
  it('rejects blank numeric values instead of treating them as zero',()=>{
    expect(validateAuctionDraftInput({...valid,startingPrice:''})).toContain('Starting price');
    expect(validateAuctionDraftInput({...valid,minimumIncrement:''})).toContain('Starting price');
  });
  it('allows an optional start or end date when only one is supplied',()=>{
    expect(validateAuctionDraftInput({...valid,startsAt:'',endsAt:''})).toBe('');
    expect(validateAuctionDraftInput({...valid,startsAt:'2026-11-18T10:00',endsAt:''})).toBe('');
  });
});
