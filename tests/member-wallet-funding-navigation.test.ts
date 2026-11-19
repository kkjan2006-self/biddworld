import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const app=readFileSync(resolve(process.cwd(),'src/App.tsx'),'utf8');

describe('Member wallet funding navigation',()=>{
 it('lazy-loads the wallet funding workspace',()=>{
  expect(app).toContain("const WalletFunding=lazy(()=>import('./components/WalletFunding'))");
 });
 it('renders Add Money in the authenticated member Wallet workspace',()=>{
  const wallet=app.slice(app.indexOf("tab==='Wallet'?"),app.indexOf("tab==='Account'?"));
  expect(wallet).toContain('<WalletFunding/>');
  expect(wallet).toContain('<WalletHistory/>');
 });
});
