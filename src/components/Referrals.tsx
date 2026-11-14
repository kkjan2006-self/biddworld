import { useEffect, useState } from 'react';
import { Users, RefreshCw } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { money } from '../lib/format';

type ReferralRow = { id:string; created_at:string; referred_member_id:string };
type CommissionRow = { id:string; amount:number; level_number:number; status:string; created_at:string };

export default function Referrals() {
  const [loading,setLoading]=useState(true);
  const [error,setError]=useState('');
  const [members,setMembers]=useState<ReferralRow[]>([]);
  const [commissions,setCommissions]=useState<CommissionRow[]>([]);
  const [code,setCode]=useState('');
  useEffect(()=>{ let active=true;
    async function load(){
      if(!supabase){setLoading(false);return;}
      const {data:{user}}=await supabase.auth.getUser();
      if(!user){setLoading(false);return;}
      const {data:profile}=await supabase.from('profiles').select('main_member_id').eq('id',user.id).maybeSingle();
      if(!profile?.main_member_id){if(active)setLoading(false);return;}
      const memberId=profile.main_member_id;
      const [memberResult,commissionResult,codeResult]=await Promise.all([
        supabase.from('referrals').select('id,created_at,referred_member_id').eq('referrer_member_id',memberId).order('created_at',{ascending:false}).limit(100),
        supabase.from('referral_commissions').select('id,amount,level_number,status,created_at').eq('credited_main_member_id',memberId).order('created_at',{ascending:false}).limit(100),
        supabase.from('member_ids').select('member_code').eq('id',memberId).maybeSingle()
      ]);
      if(!active)return;
      if(memberResult.error||commissionResult.error||codeResult.error)setError('Referral details are not available for this account yet.');
      setMembers((memberResult.data??[]) as ReferralRow[]);
      setCommissions((commissionResult.data??[]) as CommissionRow[]);
      setCode(codeResult.data?.member_code??'');
      setLoading(false);
    }
    void load(); return()=>{active=false};
  },[]);
  const total=commissions.filter(c=>c.status==='credited'||c.status==='paid').reduce((sum,c)=>sum+Number(c.amount),0);
  return <section className="referralWorkspace">
    <div className="packageIntro"><span className="workspaceIcon"><Users/></span><div><h3>My referrals</h3><p>Track members referred by your Main ID and commissions credited to your Income Wallet.</p></div></div>
    {loading?<p className="packageState">Loading referral details…</p>:error?<div className="notice">{error} <button className="outline small" onClick={()=>location.reload()}><RefreshCw size={14}/> Retry</button></div>:<>
      <div className="referralStats"><div><small>Your Main ID</small><b>{code||'Not available'}</b></div><div><small>Direct referrals</small><b>{members.length}</b></div><div><small>Credited commissions</small><b>{money(total)}</b></div></div>
      <h4 className="referralHeading">Recent direct referrals</h4>
      {members.length===0?<div className="empty">No direct referrals recorded yet.</div>:<div className="referralList">{members.map((m,i)=><div key={m.id}><span>Member {i+1}</span><small>{new Date(m.created_at).toLocaleDateString()}</small></div>)}</div>}
      <h4 className="referralHeading">Commission history</h4>
      {commissions.length===0?<div className="empty">No referral commissions recorded yet.</div>:<div className="referralList">{commissions.map(c=><div key={c.id}><span>Level {c.level_number} · {c.status}</span><b>{money(Number(c.amount))}</b></div>)}</div>}
    </>}
  </section>;
}