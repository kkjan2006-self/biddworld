import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const source=readFileSync('src/components/Admin.tsx','utf8');
describe('Admin package and referral plan directory integrity',()=>{
 it('validates package fields and rejects duplicate package IDs',()=>{expect(source).toContain('function parseAdminPackages(value:unknown)');expect(source).toContain('Package list contains malformed or duplicate records.');expect(source).toContain('setPackages(parseAdminPackages(packageResult.data??[]))');});
 it('validates referral plan package identity and sequential reward rules',()=>{expect(source).toContain('function parseReferralPlans(value:unknown)');expect(source).toContain('Referral plan metadata is inconsistent.');expect(source).toContain('Referral plan levels must be sequential.');expect(source).toContain('setReferralPlans(parseReferralPlans(referralResult.data??[]))');});
 it('surfaces invalid responses as module errors',()=>{expect(source).toContain('Package list could not be loaded:');expect(source).toContain('Referral plan list could not be loaded:');});
});