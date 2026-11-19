import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const sql=readFileSync('supabase/migrations/20261119540000_support_ticket_keyset_indexes.sql','utf8');
const ui=readFileSync('src/components/Support.tsx','utf8');
describe('Support keyset query indexes',()=>{
 it('indexes the exact Admin and member ordering tuples',()=>{
  expect(sql).toContain('support_tickets_updated_id_idx');
  expect(sql).toContain('on public.support_tickets(updated_at desc,id desc)');
  expect(sql).toContain('support_tickets_user_updated_id_idx');
  expect(sql).toContain('on public.support_tickets(user_id,updated_at desc,id desc)');
 });
 it('keeps the UI query ordering aligned with the indexed keyset',()=>{
  expect(ui).toContain("order('updated_at',{ascending:false}).order('id',{ascending:false})");
  expect(ui).toContain('cursor.updated_at');
  expect(ui).toContain('cursor.id');
 });
});
