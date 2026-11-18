import {readFileSync,readdirSync} from 'node:fs';
import {resolve,join} from 'node:path';
import {describe,expect,it} from 'vitest';
const root=process.cwd();
const read=(p:string)=>readFileSync(resolve(root,p),'utf8');
const frontend=[read('src/App.tsx'),...readdirSync(resolve(root,'src/components')).filter(p=>p.endsWith('.tsx')).map(p=>readFileSync(join(root,'src/components',p),'utf8'))].join('\n');
const contracts=[{"name":"admin_activate_referral_plan","migration":"20261118090000_package_publication_and_referral_commission_engine.sql","security":"definer"},{"name":"admin_adjust_member_wallet","migration":"20261118120000_admin_wallet_adjustments.sql","security":"definer"},{"name":"admin_draw_fixed_bid_winners","migration":"20261118080000_fixed_bid_campaign_entry_draw_settlement.sql","security":"definer"},{"name":"admin_finalize_auction","migration":"20261118110000_auction_lifecycle_winner_settlement.sql","security":"definer"},{"name":"admin_get_minimum_withdrawal_amount","migration":"20261118130000_withdrawal_minimum_and_server_validation.sql","security":"definer"},{"name":"admin_list_auction_bids_page","migration":"20261118310000_admin_auction_bid_reporting.sql","security":"definer"},{"name":"admin_list_auctions_page","migration":"20261118330000_admin_complete_auction_fixed_bid_reports.sql","security":"definer"},{"name":"admin_list_duplicate_ids_page","migration":"20261116110000_admin_duplicate_id_pagination.sql","security":"definer"},{"name":"admin_list_fixed_bid_campaigns_page","migration":"20261118330000_admin_complete_auction_fixed_bid_reports.sql","security":"definer"},{"name":"admin_list_fixed_bid_entries_page","migration":"20261118320000_admin_fixed_bid_entry_reporting.sql","security":"definer"},{"name":"admin_list_members_sponsors_page","migration":"20261116090000_admin_members_sponsors_pagination.sql","security":"definer"},{"name":"admin_list_package_activations_page","migration":"20261118190000_package_activation_history_reporting.sql","security":"definer"},{"name":"admin_list_referral_commissions_page","migration":"20261118090000_package_publication_and_referral_commission_engine.sql","security":"definer"},{"name":"admin_post_referral_commissions","migration":"20261118090000_package_publication_and_referral_commission_engine.sql","security":"definer"},{"name":"admin_publish_package","migration":"20261118090000_package_publication_and_referral_commission_engine.sql","security":"definer"},{"name":"admin_reverse_referral_commission","migration":"20261118090000_package_publication_and_referral_commission_engine.sql","security":"definer"},{"name":"admin_review_withdrawal_request","migration":"20261118100000_admin_withdrawal_review_workflow.sql","security":"definer"},{"name":"admin_save_fixed_bid_campaign","migration":"20261118080000_fixed_bid_campaign_entry_draw_settlement.sql","security":"definer"},{"name":"admin_send_member_notification","migration":"20261118180000_notification_delivery_idempotency.sql","security":"definer"},{"name":"admin_set_auction_status","migration":"20261118110000_auction_lifecycle_winner_settlement.sql","security":"definer"},{"name":"admin_set_fixed_bid_campaign_status","migration":"20261118080000_fixed_bid_campaign_entry_draw_settlement.sql","security":"definer"},{"name":"admin_set_main_member_status","migration":"20261118140000_admin_main_member_lifecycle.sql","security":"definer"},{"name":"admin_set_minimum_withdrawal_amount","migration":"20261118130000_withdrawal_minimum_and_server_validation.sql","security":"definer"},{"name":"admin_set_product_active","migration":"20261116020000_admin_product_management_and_media.sql","security":"definer"},{"name":"admin_set_user_admin_role","migration":"20261118160000_primary_admin_role_management.sql","security":"definer"},{"name":"admin_update_member_profile","migration":"20261117120000_admin_update_member_profile.sql","security":"definer"},{"name":"admin_update_support_ticket","migration":"20261118170000_support_ticket_idempotency_admin_audit.sql","security":"definer"},{"name":"get_my_mlm_dashboard_page","migration":"20261118250000_member_mlm_dashboard_pagination.sql","security":"definer"},{"name":"member_get_my_identity","migration":"20261115203000_member_identity_summary.sql","security":"definer"},{"name":"member_join_fixed_bid_campaign","migration":"20261118080000_fixed_bid_campaign_entry_draw_settlement.sql","security":"definer"},{"name":"member_list_my_ids","migration":"20261118200000_member_identity_ids_rpc.sql","security":"definer"},{"name":"member_pay_winning_item_payment","migration":"20261118080000_fixed_bid_campaign_entry_draw_settlement.sql","security":"definer"},{"name":"member_submit_support_ticket","migration":"20261118170000_support_ticket_idempotency_admin_audit.sql","security":"definer"},{"name":"member_update_my_profile","migration":"20261115190000_member_profile_self_service.sql","security":"definer"},{"name":"public_list_active_auctions_page","migration":"20261118280000_public_auction_catalogue_page.sql","security":"definer"},{"name":"public_list_active_packages_page","migration":"20261118300000_public_package_catalogue_page.sql","security":"definer"},{"name":"public_list_active_products_page","migration":"20261116120000_public_product_catalogue_search.sql","security":"invoker"},{"name":"public_list_fixed_bid_campaigns_page","migration":"20261118290000_public_fixed_bid_catalogue_page.sql","security":"definer"},{"name":"submit_package_activation_with_receipt","migration":"20261118150000_package_receipt_uploads.sql","security":"definer"}];
describe('Frontend RPC coverage in the source-only forward migration chain',()=>{
 it.each(contracts)('$name is called by the UI and defined in its forward migration',({name,migration,security})=>{
  expect(frontend).toContain(name);
  const sql=read('supabase/migrations/'+migration);
  expect(sql.toLowerCase()).toContain('create or replace function public.'+name);
  expect(sql).toMatch(new RegExp('security\\s+'+security,'i'));
  expect(sql).toMatch(/set\s+search_path/i);
 });
 it('wires the Admin auction bid report to its protected paginated RPC and CSV export',()=>{
  const report=read('src/components/AdminAuctionBidReport.tsx');
  const admin=read('src/components/Admin.tsx');
  const sql=read('supabase/migrations/20261118310000_admin_auction_bid_reporting.sql');
  expect(report).toContain("rpc('admin_list_auction_bids_page'");
  expect(report).toContain('p_from:boundary(filters.from,false)');
  expect(report).toContain('p_to:boundary(filters.to,true)');
  expect(report).toContain('Load more bids');
  expect(report).toContain('Export Complete Auction Bids CSV');
  expect(admin).toContain('AdminAuctionBidReport');
  expect(sql).toContain("auth.jwt()->'app_metadata'->>'role'");
  expect(sql).toContain('security definer');
  expect(sql).toContain("set search_path=''");
  expect(sql).toContain('order by b.created_at desc,b.id desc');
  expect(sql).not.toContain('idempotency_key');
 });
 it('wires the Admin Fixed Bid entry report to its protected paginated RPC and complete CSV export',()=>{
  const report=read('src/components/AdminFixedBidEntryReport.tsx');
  const admin=read('src/components/Admin.tsx');
  const sql=read('supabase/migrations/20261118320000_admin_fixed_bid_entry_reporting.sql');
  expect(report).toContain("rpc('admin_list_fixed_bid_entries_page'");
  expect(report).toContain('p_from:boundary(filters.from,false)');
  expect(report).toContain('p_to:boundary(filters.to,true)');
  expect(report).toContain('Load more entries');
  expect(report).toContain('Export Complete Fixed Bid Entries CSV');
  expect(admin).toContain('AdminFixedBidEntryReport');
  expect(sql).toContain("auth.jwt()->'app_metadata'->>'role'");
  expect(sql).toContain('security definer');
  expect(sql).toContain("set search_path=''");
  expect(sql).toContain('order by fb.created_at desc,fb.id desc');
  expect(sql).not.toContain('idempotency_key');
 });
 it('exports complete filtered auction and Fixed Bid campaign histories through paginated Admin RPCs',()=>{
  const admin=read('src/components/Admin.tsx');
  const sql=read('supabase/migrations/20261118330000_admin_complete_auction_fixed_bid_reports.sql');
  expect(admin).toContain("rpc('admin_list_auctions_page'");
  expect(admin).toContain("rpc('admin_list_fixed_bid_campaigns_page'");
  expect(admin).toContain('exportPagedReport<AuctionRow>');
  expect(admin).toContain('exportPagedReport<FixedBidCampaign>');
  expect(admin).toContain('Export Complete Filtered Auctions CSV');
  expect(admin).toContain('Export Complete Filtered Fixed Bid CSV');
  expect(sql).toContain('create or replace function public.admin_list_auctions_page');
  expect(sql).toContain('create or replace function public.admin_list_fixed_bid_campaigns_page');
  expect(sql).toContain('security definer');
  expect(sql).toContain("set search_path=''");
  expect(sql).toContain('limit p_limit offset p_offset');
 });
 it('keeps the final seven-column Member ID list separate from Main ID/sponsor identity summary',()=>{
  const ids=read('supabase/migrations/20261118200000_member_identity_ids_rpc.sql');
  const account=read('src/components/Account.tsx');
  expect(ids).toContain('placement_parent_code text');
  expect(ids).not.toContain('main_member_code text');
  expect(account).toContain("client.rpc('member_get_my_identity')");
  expect(account).toContain("client.rpc('member_list_my_ids')");
 });
 it('supports boolean-only source sponsor lookup and legacy Production array response during the migration window',()=>{
  const helper=read('src/lib/sponsor-lookup.ts');
  const migration=read('supabase/migrations/20261116160000_minimize_public_sponsor_lookup.sql');
  expect(helper).toContain('if (data === true) return true;');
  expect(helper).toContain('if (!Array.isArray(data)) return false;');
  expect(migration).toContain('returns boolean');
  expect(migration).toContain('grant execute on function public.lookup_sponsor(text) to anon, authenticated');
 });
 it('matches the two-argument idempotent place_bid contract used by the public auction UI',()=>{
  const app=read('src/App.tsx');
  const migration=read('supabase/migrations/20261116190000_bid_request_idempotency.sql');
  expect(app).toContain("supabase.rpc('place_bid',{p_auction_id:id,p_idempotency_key:requestKey})");
  expect(migration).toContain('drop function if exists public.place_bid(uuid);');
  expect(migration).toContain('p_idempotency_key text');
  expect(migration).toContain('create or replace function public.place_bid(');
 });
});
