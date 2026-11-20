import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const ui=readFileSync('src/components/Admin.tsx','utf8');
const sql=readFileSync('supabase/migrations/20261119530000_remove_email_verification_switch.sql','utf8');
const engine=readFileSync('supabase/migrations/20261119310000_matrix_commission_engine.sql','utf8');
describe('Matrix commission feature switch readiness',()=>{
 it('exposes Matrix posting only after the implemented workflow is marked ready',()=>{
  expect(ui).toContain("backendPendingFeatureKeys=new Set(['automatic_placement_enabled','winner_selection_configured'])");
  expect(ui).toContain("'referral_commissions_enabled','matrix_commissions_enabled','bid_wallet_enabled'");
  expect(ui).toContain("serverConditionFeatureKeys=new Set(['package_activations_enabled','referral_commissions_enabled','matrix_commissions_enabled'");
 });
 it('allows Admin to enable Matrix only through the server-side condition and preserves duplicate-ID serialization',()=>{
  expect(sql).toContain("'referral_commissions_enabled','matrix_commissions_enabled'");
  expect(sql).toContain("'package_activations_enabled','referral_commissions_enabled','matrix_commissions_enabled'");
  expect(sql).toContain("pg_catalog.hashtextextended('biddworld.member_id_graph_mutation',0)");
 });
 it('retains protected automatic commission posting and explicit Admin posting/reversal RPCs',()=>{
  expect(engine).toContain("setting_key='matrix_commissions_enabled'");
  expect(engine).toContain('public.admin_post_matrix_commissions(new.id)');
  expect(engine).toContain('public.admin_reverse_matrix_commission');
 });
});
