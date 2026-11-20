import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';

const migration=readFileSync('supabase/migrations/20261119690000_prevent_duplicate_pending_auction_submissions.sql','utf8');
const member=readFileSync('src/components/MemberPlaceAuction.tsx','utf8');
const edit=readFileSync('supabase/migrations/20261119430000_member_auction_submission_editing.sql','utf8');

describe('database duplicate pending auction submission guard',()=>{
 it('serializes per-owner writes before checking the normalized pending title',()=>{
  expect(migration).toContain("pg_advisory_xact_lock");
  expect(migration).toContain("biddworld.auction_submission:");
  expect(migration).toContain("lower(btrim(s.title))=lower(btrim(new.title))");
  expect(migration).toContain("using errcode='23505'");
 });
 it('protects both new submissions and edited/resubmitted pending listings at the database boundary',()=>{
  expect(migration).toContain('before insert or update on public.auction_submissions');
  expect(migration).toContain("if new.status='pending' then");
  expect(edit).toContain("status='pending'");
  expect(member).toContain("if(!supabase||submitInFlight.current)return");
 });
 it('uses an index for the owner-scoped pending-title duplicate lookup',()=>{
  expect(migration).toContain('auction_submissions_owner_pending_title_idx');
  expect(migration).toContain("where status='pending'");
 });
});
