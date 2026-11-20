import {describe,expect,it} from 'vitest';
import {getEligibleUnderIds,normalizeMemberCode,validateDistinctDuplicatePlacement} from '../src/lib/duplicate-id-placement';

describe('Duplicate ID placement selection',()=>{
 it('normalizes member codes without changing stored values',()=>{
  expect(normalizeMemberCode('  main01 ')).toBe('MAIN01');
 });
 it('excludes inactive IDs and the owner Main ID from placement candidates',()=>{
  const rows=[{member_code:'MAIN01',status:'active'},{member_code:'UNDER01',status:'active'},{member_code:'UNDER02',status:'pending'}];
  expect(getEligibleUnderIds(rows,' main01 ')).toEqual([{member_code:'UNDER01',status:'active'}]);
 });
 it('rejects identical owner and placement IDs case-insensitively',()=>{
  expect(()=>validateDistinctDuplicatePlacement(' Main01 ','main01')).toThrow(/different/i);
  expect(()=>validateDistinctDuplicatePlacement('','under01')).toThrow(/Main ID/i);
  expect(()=>validateDistinctDuplicatePlacement('main01','')).toThrow(/Under/i);
 });
 it('accepts distinct Main and Under IDs',()=>{
  expect(()=>validateDistinctDuplicatePlacement('main01','under01')).not.toThrow();
 });
});
