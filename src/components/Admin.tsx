import {useEffect,useMemo,useState} from 'react';
import {ShieldCheck,Users,PackageCheck,Gavel,Wallet,RefreshCw,AlertCircle,Network,UserCheck} from 'lucide-react';
import {supabase} from '../lib/supabase';
type Counts={members:number;packages:number;pendingActivations:number;pendingWithdrawals:number;auctions:number;campaigns:number};
type SponsorMember={member_code:string;display_name:string;phone:string;sponsor_code:string;created_at:string};
type MlmOverview={total_members:number;active_members:number;direct_relationships:number;pending_activations:number;verified_activations:number;commission_total:number;withdrawal_pending:number};
const empty:Counts={members:0,packages:0,pendingActivations:0,pendingWithdrawals:0,auctions:0,campaigns:0};
export default function Admin(){
 const [role,setRole]=useState(''),[counts,setCounts]=useState(empty),[loading,setLoading]=useState(true),[error,setError]=useState('');
 const [refresh,setRefresh]=useState(0);
 const [overview,setOverview]=useState<MlmOverview|null>(null),[members,setMembers]=useState<SponsorMember[]>([]),[memberSearch,setMemberSearch]=useState(''),[defaultSponsor,setDefaultSponsor]=useState(''),[memberCode,setMemberCode]=useState(''),[sponsorCode,setSponsorCode]=useState(''),[sponsorMessage,setSponsorMessage]=useState(''),[savingSponsor,setSavingSponsor]=useState(false);
 useEffect(()=>{
  if(!supabase){setLoading(false);return;}
  let active=true;
  const applyRole=(session:{user?:{app_metadata?:Record<string,unknown>} }|null)=>setRole(String(session?.user?.app_metadata?.role??''));
  const {data:{subscription}}=supabase.auth.onAuthStateChange((_event,session)=>{
   if(active)applyRole(session);
  });
  void supabase.auth.getSession().then(({data:{session}})=>{if(active)applyRole(session);});
  return()=>{active=false;subscription.unsubscribe();};
 },[]);
 useEffect(()=>{
  let active=true;
  setCounts(empty);setError('');setLoading(true);
  async function load(){
   if(!supabase||role!=='admin'){if(active)setLoading(false);return;}
   const specs=[['members','profiles',null],['packages','packages',null],['pendingActivations','package_activations','payment_status'],['pendingWithdrawals','withdrawal_requests','status'],['auctions','auctions',null],['campaigns','fixed_bid_campaigns',null]] as const;
   const [results,memberResult,overviewResult]=await Promise.all([Promise.all(specs.map(async ([key,table,column])=>{
    let q=supabase!.from(table).select('id',{count:'exact',head:true});
    if(column)q=q.eq(column,'pending');
    const result=await q;
    return {key,count:result.count,error:result.error};
   })),supabase.rpc('admin_list_members_sponsors'),supabase.rpc('admin_get_mlm_overview')]);
   if(!active)return;
   if(!memberResult.error)setMembers((memberResult.data??[]) as SponsorMember[]);
   if(!overviewResult.error)setOverview(overviewResult.data as MlmOverview);
   if(results.some(x=>x.error))setError('Some totals are hidden by current database permissions or unavailable.');
   setCounts(Object.fromEntries(results.map(x=>[x.key,x.count??0])) as unknown as Counts);
   setLoading(false);
  }
  void load();return()=>{active=false;};
 },[role,refresh]);
 function exportMembersCsv(){const rows=[['Member Main ID','Name','Phone','Sponsor Main ID','Joined At'],...filteredMembers.map(m=>[m.member_code,m.display_name,m.phone,m.sponsor_code,m.created_at])];const csv=rows.map(row=>row.map(value=>'"'+String(value??'').replace(/"/g,'""')+'"').join(',')).join('\\r\\n');const blob=new Blob(['\\ufeff'+csv],{type:'text/csv;charset=utf-8;'});const url=URL.createObjectURL(blob);const a=document.createElement('a');a.href=url;a.download='biddworld-members-report.csv';a.click();URL.revokeObjectURL(url);}
 async function saveDefaultSponsor(){if(!supabase)return;setSavingSponsor(true);const{error}=await supabase.rpc('admin_set_default_sponsor',{p_member_code:defaultSponsor.trim()});setSavingSponsor(false);setSponsorMessage(error?.message??'Default sponsor saved.');}
 async function changeSponsor(){if(!supabase)return;if(!memberCode.trim()||!sponsorCode.trim()){setSponsorMessage('Enter both member and new sponsor Main IDs.');return;}setSavingSponsor(true);const{error}=await supabase.rpc('admin_set_member_sponsor',{p_member_code:memberCode.trim(),p_sponsor_code:sponsorCode.trim()});setSavingSponsor(false);setSponsorMessage(error?.message??'Member sponsor updated. Existing commission records remain unchanged.');if(!error){setMemberCode('');setSponsorCode('');setRefresh(v=>v+1);}}
 if(loading)return <div className="workspace">Loading administrator overview…</div>;
 if(role!=='admin')return <div className="workspace"><div className="workspaceIcon"><ShieldCheck/></div><h3>Administrator access required</h3><p>This area is restricted to accounts with the administrator role. Ask the system owner to assign the role securely in Supabase Auth app_metadata.</p></div>;
 const filteredMembers=useMemo(()=>{const q=memberSearch.trim().toLowerCase();return members.filter(m=>(m.member_code+' '+m.display_name+' '+m.phone+' '+(m.sponsor_code??'')).toLowerCase().includes(q));},[members,memberSearch]);
 const tiles=[['Registered Profiles',counts.members,Users],['Packages',counts.packages,PackageCheck],['Pending activations',counts.pendingActivations,AlertCircle],['Pending withdrawals',counts.pendingWithdrawals,Wallet],['Auctions',counts.auctions,Gavel],['Fixed Bid campaigns',counts.campaigns,PackageCheck]] as const;
 return <section className="adminPanel"><div className="packageIntro"><span className="workspaceIcon"><ShieldCheck/></span><div><h3>Administrator overview</h3><p>Read-only operational summary. No financial approvals or settings changes are exposed here.</p></div><button className="outline small" onClick={()=>setRefresh(v=>v+1)}><RefreshCw size={14}/> Refresh</button></div>{error&&<div className="notice">{error}</div>}<div className="adminStats">{tiles.map(([label,value,Icon])=><article key={label}><Icon size={20}/><small>{label}</small><b>{value.toLocaleString('en-IN')}</b></article>)}</div>{overview&&<><h4 className="referralHeading">MLM Network Overview</h4><div className="mlmCards"><article><Users size={19}/><small>Total Main IDs</small><b>{overview.total_members}</b></article><article><UserCheck size={19}/><small>Active Members</small><b>{overview.active_members}</b></article><article><Network size={19}/><small>Sponsor Relationships</small><b>{overview.direct_relationships}</b></article><article><PackageCheck size={19}/><small>Verified Activations</small><b>{overview.verified_activations}</b></article><article><AlertCircle size={19}/><small>Pending Activations</small><b>{overview.pending_activations}</b></article><article><Wallet size={19}/><small>Pending Withdrawals</small><b>{overview.withdrawal_pending}</b></article></div></>}<div className="sponsorAdmin"><h4>Referral Sponsor Settings</h4><p>Set the Admin Default Sponsor ID used when a new member leaves the Sponsor field blank.</p><div className="sponsorAdminForm"><input value={defaultSponsor} onChange={e=>setDefaultSponsor(e.target.value)} placeholder="Admin Default Sponsor Main ID"/><button className="primary small" disabled={savingSponsor} onClick={()=>void saveDefaultSponsor()}>Save Default Sponsor</button></div><p>Correct a member's sponsor after registration. Past commission entries are retained as historical records.</p><div className="sponsorAdminForm"><input value={memberCode} onChange={e=>setMemberCode(e.target.value)} placeholder="Member Main ID"/><input value={sponsorCode} onChange={e=>setSponsorCode(e.target.value)} placeholder="Correct Sponsor Main ID"/><button className="outline small" disabled={savingSponsor} onClick={()=>void changeSponsor()}>Update Sponsor</button></div>{sponsorMessage&&<div className="notice">{sponsorMessage}</div>}<div className="memberReportHeading"><h4>Members and Current Sponsors ({filteredMembers.length})</h4><button className="outline small" onClick={exportMembersCsv}>Export CSV</button></div><div className="sponsorAdminForm"><input value={memberSearch} onChange={e=>setMemberSearch(e.target.value)} placeholder="Search name, member ID, phone or sponsor ID"/></div><div className="referralList">{filteredMembers.map(m=><div key={m.member_code}><span><b>{m.display_name}</b> · {m.member_code}</span><small>Phone: {m.phone||'Not available'} · Sponsor: {m.sponsor_code||'Not assigned'}</small></div>)}</div></div><div className="notice"><ShieldCheck size={17}/> Sponsor changes are server-validated and recorded in the audit log. Financial actions remain locked until their workflows are implemented.</div></section>;
}
