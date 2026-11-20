import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';

describe('Admin workspace loading diagnostics',()=>{
 const source=readFileSync('src/components/Admin.tsx','utf8');

 it('collects failures from every independently loaded Admin section',()=>{
  expect(source).toContain("['Member directory',memberResult.error]");
  expect(source).toContain("['Feature settings',settingsResult.error]");
  expect(source).toContain("['Wallet ledger',walletTransactionResult.error]");
  expect(source).toContain("['Admin accounts',adminAccountsResult.error]");
  expect(source).toContain('setLoadWarnings(loadIssues)');
 });

 it('shows actionable section errors and a retry control to the Admin',()=>{
  expect(source).toContain('Some Admin sections could not load.');
  expect(source).toContain('{loadWarnings.map((issue,index)=><li key={index}>{issue}</li>)}');
  expect(source).toContain('Retry failed sections');
 });
});
