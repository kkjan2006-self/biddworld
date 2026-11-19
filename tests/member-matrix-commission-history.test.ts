import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const sql=readFileSync('supabase/migrations/20261119320000_member_matrix_commission_summary.sql','utf8');
const account=readFileSync('src/components/Account.tsx','utf8');
describe('member Matrix commission history',()=>{
 it('derives the credited Main ID from the authenticated profile',()=>{expect(sql).toContain('where p.id=v_uid and m.owner_user_id=v_uid and m.id_type=\'main\'');expect(sql).toContain('c.credited_main_member_id=v_main_id');});
 it('returns source ID type and member code for duplicate attribution',()=>{expect(sql).toContain('source.member_code,source.id_type');expect(account).toContain('Source ID: {x.source_member_code}');expect(account).toContain("x.source_id_type==='duplicate'");});
 it('keeps Sponsor and Matrix history as separate sections',()=>{expect(account).toContain('Sponsor Referral Commissions');expect(account).toContain('Matrix Commissions (Under ID Chain)');expect(account).toContain("member_list_my_matrix_commissions_page" );});
});
