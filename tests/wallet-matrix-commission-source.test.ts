import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const wallet=readFileSync('src/components/WalletHistory.tsx','utf8');
const sql=readFileSync('supabase/migrations/20261119320000_member_matrix_commission_summary.sql','utf8');
describe('wallet Matrix commission source attribution',()=>{
 it('looks up source details only through the member-scoped RPC',()=>{expect(wallet).toContain("member_get_my_matrix_commission_sources");expect(sql).toContain('c.credited_main_member_id=v_main_id and c.id=any(p_commission_ids)');});
 it('shows source Main/Duplicate ID and level in history and CSV',()=>{expect(wallet).toContain('Matrix source:');expect(wallet).toContain('Commission Source ID');expect(wallet).toContain('Source ID Type');expect(wallet).toContain('Matrix Level');});
 it('keeps caller scope tied to auth.uid and the linked Main ID',()=>{expect(sql).toContain('where p.id=v_uid and m.owner_user_id=v_uid and m.id_type=\'main\'');});

 it('includes Matrix reference fields in the complete CSV export query',()=>{const exportBlock=wallet.slice(wallet.indexOf('async function exportTransactions'));expect(exportBlock).toContain('created_at,reference_type,reference_id,wallet_account:wallet_accounts');expect(exportBlock).toContain("row.reference_type==='matrix_commission'&&row.reference_id");expect(exportBlock).toContain('member_get_my_matrix_commission_sources');});
});
