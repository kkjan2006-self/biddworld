import {describe,it,expect} from 'vitest';
import {getSupabaseConfigurationError} from '../src/lib/supabase-environment';
const key='sb_publishable_test_key';
const url=(ref:string)=>'https://'+ref+'.supabase.co';
describe('BiddWorld Supabase environment isolation',()=>{
 it('allows the dedicated TEST project only in test mode',()=>{
  expect(getSupabaseConfigurationError('test',url('yoaauthwejdgaevfvwpo'),key)).toBe('');
  expect(getSupabaseConfigurationError('test',url('hbqatszyzqobgtauyuzy'),key)).toMatch(/Test Mode must connect only/);
  expect(getSupabaseConfigurationError('test',url('another-project'),key)).toMatch(/Test Mode must connect only/);
 });
 it('never allows Production credentials in preview mode',()=>{
  expect(getSupabaseConfigurationError('preview',url('hbqatszyzqobgtauyuzy'),key)).toMatch(/Preview Mode cannot connect/);
  expect(getSupabaseConfigurationError('preview',url('yoaauthwejdgaevfvwpo'),key)).toBe('');
  expect(getSupabaseConfigurationError('preview','','')).toMatch(/not configured/);
 });
 it('allows the Production project only in explicit live mode',()=>{
  expect(getSupabaseConfigurationError('live',url('hbqatszyzqobgtauyuzy'),key)).toBe('');
  expect(getSupabaseConfigurationError('live',url('yoaauthwejdgaevfvwpo'),key)).toMatch(/Live Mode must use/);
 });
 it('rejects malformed URLs, non-HTTPS origins and injected URL credentials',()=>{
  expect(getSupabaseConfigurationError('test','not-a-url',key)).toMatch(/URL is invalid/);
  expect(getSupabaseConfigurationError('test','http://yoaauthwejdgaevfvwpo.supabase.co',key)).toMatch(/URL is invalid/);
  expect(getSupabaseConfigurationError('test','https://user:pass@yoaauthwejdgaevfvwpo.supabase.co',key)).toMatch(/URL is invalid/);
  expect(getSupabaseConfigurationError('test','https://yoaauthwejdgaevfvwpo.supabase.co.evil.example',key)).toMatch(/URL is invalid/);
 });
});
