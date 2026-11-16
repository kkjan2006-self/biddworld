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

 it('scans tracked browser and deployment configuration for private Supabase credentials',()=>{
  const {readdirSync,statSync}=require('node:fs');
  const roots=['src','public','.github/workflows','supabase/functions'];
  const files:string[]=[];
  const walk=(path:string)=>{
   let entries:string[]=[];
   try{entries=readdirSync(path);}catch{return;}
   for(const entry of entries){
    const full=resolve(path,entry);
    let stat;
    try{stat=statSync(full);}catch{continue;}
    if(stat.isDirectory())walk(full);
    else if(stat.isFile()&&/\\.(?:[cm]?[jt]sx?|ya?ml|html)$/i.test(entry))files.push(full);
   }
  };
  roots.forEach(walk);
  const forbidden=/(?:VITE_)?SUPABASE_(?:SERVICE_ROLE|SECRET)_KEY\\s*[:=]|sb_secret_[A-Za-z0-9_-]{8,}/i;
  for(const path of files){
   const content=readFileSync(path,'utf8');
   expect(content, path).not.toMatch(forbidden);
  }
 });
