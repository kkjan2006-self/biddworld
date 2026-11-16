import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const client=readFileSync(resolve(process.cwd(),'src/lib/supabase.ts'),'utf8');
const env=readFileSync(resolve(process.cwd(),'.env.example'),'utf8');
describe('browser Supabase client security contract',()=>{
 it('uses only public publishable or legacy anon credentials in browser configuration',()=>{
  expect(client).toContain('VITE_SUPABASE_PUBLISHABLE_KEY');
  expect(client).toContain('VITE_SUPABASE_ANON_KEY');
  expect(client).not.toMatch(/VITE_[A-Z0-9_]*(SERVICE_ROLE|SECRET)/i);
  expect(env).toContain('VITE_SUPABASE_PUBLISHABLE_KEY=');
  expect(env).toContain('Never add service_role or secret keys to VITE_ variables.');
 });
 it('keeps Supabase session refresh and persistence enabled',()=>{
  expect(client).toContain('autoRefreshToken: true');
  expect(client).toContain('persistSession: true');
  expect(client).toContain('detectSessionInUrl: true');
 });
 it('does not expose a service-role credential or secret in the browser client',()=>{
  expect(client).not.toMatch(/service_role|sb_secret_[A-Za-z0-9_-]{8,}/i);
  expect(client).toContain('createClient(projectUrl, publishableKey');
 });
});
