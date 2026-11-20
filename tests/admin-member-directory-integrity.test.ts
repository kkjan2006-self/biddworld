import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const source=readFileSync('src/components/Admin.tsx','utf8');
describe('Admin member directory page integrity',()=>{
 it('uses one strict page parser for initial, searched and subsequent results',()=>{
  expect(source).toContain('function parseSponsorMemberPage(value:unknown)');
  expect(source).toContain('Invalid member directory page.');
  expect(source).toContain('Malformed or duplicate member directory records.');
  expect(source.match(/parseSponsorMemberPage\(data\)/g)?.length).toBeGreaterThanOrEqual(3);
  expect(source).toContain('parseSponsorMemberPage(memberResult.data)');
 });
 it('rejects overlapping pages rather than silently filtering them',()=>{
  expect(source).toContain('Member directory page overlaps records already loaded.');
  expect(source).toContain('setMembers(current=>[...current,...batch])');
 });
 it('retains request-generation checks for member search and pagination',()=>{
  expect(source).toContain('memberSearchRequest.current');
  expect(source).toContain('memberPageInFlight.current');
 });
});
