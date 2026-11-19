import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const source=readFileSync(resolve(process.cwd(),'src/components/WalletFunding.tsx'),'utf8');

describe('Wallet funding history session isolation',()=>{
 it('tracks the authenticated user and listens for auth changes',()=>{
  expect(source).toContain("supabase.auth.onAuthStateChange");
  expect(source).toContain('setUserId(session?.user?.id??null)');
  expect(source).toContain('supabase.auth.getUser()');
 });
 it('clears prior-member request rows and invalidates in-flight loads on session changes',()=>{
  expect(source).toContain('setRows([]);setHistoryError(\'\');setHistoryLoading(Boolean(userId))');
  expect(source).toContain('historyRequest.current++');
  expect(source).toContain('if(seq===historyRequest.current)setRows');
 });
 it('shows request-history loading and retrieval errors instead of silently hiding failures',()=>{
  expect(source).toContain('Loading Add Money requests…');
  expect(source).toContain('Add Money requests could not be loaded. Please retry.');
 });
});
