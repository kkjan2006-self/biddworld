import {describe,expect,it} from 'vitest';
import {parseDuplicateIdCreationResult} from '../src/lib/duplicate-id-result';

describe('Duplicate ID creation RPC response contract',()=>{
 it('accepts the complete pending-placement result',()=>{
  expect(parseDuplicateIdCreationResult({id:'id-1',member_code:'BWD123',main_member_code:'MAIN1',under_member_code:'MAIN2',status:'pending'})).toEqual({id:'id-1',member_code:'BWD123',main_member_code:'MAIN1',under_member_code:'MAIN2',status:'pending'});
 });
 it('rejects null, arrays, and incomplete or unexpected RPC payloads',()=>{
  for(const value of [null,[],{}, {member_code:'BWD123'}, {id:'id-1',member_code:'BWD123',main_member_code:'MAIN1',under_member_code:'MAIN2',status:'active'}]){
   expect(()=>parseDuplicateIdCreationResult(value)).toThrow(/response|contract/i);
  }
 });
});
