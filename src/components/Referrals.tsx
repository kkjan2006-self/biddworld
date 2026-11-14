import { useEffect, useMemo, useState } from 'react';
import { Users, RefreshCw, Network, UserCheck, Wallet, Gift, Search, ChevronDown } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { money } from '../lib/format';

type TreeMember={member_code:string;display_name:string;status:string;created_at:string;depth:number;sponsor_code:string|null};
type Dashboard={main_member_code:string;direct_referrals:number;total_downline:number;active_members:number;active_activations:number;commission_total:number;bid_wallet:number;income_wallet:number;tree:TreeMember[]};

export default function Referrals(){
 const [userId,setUserId]=useState<string|null>(null),[data,setData]=useState<Dashboard|null>(null),[loading,setLoading]=useState(true),[error,setError]=useState(''),[refresh,setRefresh]=useState(0),[query,setQuery]=useState(''),[depth,setDepth]=useState('all');
 useEffect(()=>{if(!supabase){setLoading(false);return}let active=true;const{data:{subscription}}=supabase.auth.onAuthStateChange((_e,s)=>{if(active)setUserId(s?.user?.id??null)});void supabase.auth.getUser().then(({data})=>{if(active)setUserId(data.user?.id??null)});return()=>{active=false;subscription.unsubscribe()}},[]);
 useEffect(()=>{let active=true;setData(null);setError('');setLoading(true);async function load(){if(!supabase||!userId){if(active)setLoading(false);return}const{data,error}=await supabase.rpc('get_my_mlm_dashboard');if(!active)return;if(error)setError(error.message);else setData(data as Dashboard);setLoading(false)}void load();return()=>{active=false}},[userId,refresh]);
 const tree=useMemo(()=>{const q=query.trim().toLowerCase();return(data?.tree??[]).filter(m=>(depth==='all'||m.depth===Number(depth))&&(!q||(m.member_code+' '+m.display_name+' '+(m.sponsor_code??'')).toLowerCase().includes(q)))},[data,query,depth]);
 const cards=data?[['My Main ID',data.main_member_code,Users],['Direct Referrals',data.direct_referrals,UserCheck],['Total Team',data.total_downline,Network],['Active Members',data.active_members,UserCheck],['Package Activations',data.active_activations,Gift],['Referral Income',money(Number(data.commission_total)),Wallet],['Bid Wallet',money(Number(data.bid_wallet)),Wallet],['Income Wallet',money(Number(data.income_wallet)),Wallet]] as const:[];
 return <section className="referralWorkspace">
  <div className="packageIntro"><span className="workspaceIcon"><Network/></span><div><h3>My MLM Dashboard</h3><p>Your sponsor genealogy, team members, wallet and referral summary.</p></div><button className="outline small" onClick={()=>setRefresh(v=>v+1)}><RefreshCw size={14}/> Refresh</button></div>
  {loading?<p className="packageState">Loading your team dashboard…</p>:error?<div className="notice">{error} <button className="outline small" onClick={()=>setRefresh(v=>v+1)}>Retry</button></div>:data&&<>
   <div className="mlmCards">{cards.map(([label,value,Icon])=><article key={label}><Icon size={19}/><small>{label}</small><b>{value}</b></article>)}</div>
   <div className="genealogyHead"><div><h4>My Team Genealogy</h4><p>Members are grouped under the Sponsor Main ID recorded at registration or last admin correction.</p></div><span>{data.total_downline} members</span></div>
   <div className="genealogyTools"><label className="search"><Search size={16}/><input value={query} onChange={e=>setQuery(e.target.value)} placeholder="Search name or member ID"/></label><label className="depthSelect">Level <select value={depth} onChange={e=>setDepth(e.target.value)}><option value="all">All levels</option>{Array.from({length:20},(_,i)=><option key={i+1} value={String(i+1)}>Level {i+1}</option>)}</select><ChevronDown size={14}/></label></div>
   {tree.length===0?<div className="empty">No team members match this view yet.</div>:<div className="genealogyList">{tree.map(m=><article className="genealogyMember" key={m.member_code} style={{'--tree-depth':Math.min(m.depth,8)} as React.CSSProperties}><span className="genealogyLine"/><div className="genealogyAvatar"><Users size={16}/></div><div className="genealogyInfo"><b>{m.display_name}</b><small>{m.member_code} · Joined {new Date(m.created_at).toLocaleDateString('en-IN')}</small><small>Sponsor: {m.sponsor_code??'Not assigned'}</small></div><span className="genealogyLevel">Level {m.depth}</span><span className={m.status==='active'?'memberActive':'memberStatus'}>{m.status}</span></article>)}</div>}
   <p className="genealogyNote">This genealogy follows the recorded Sponsor Referral relationship. Duplicate IDs and placement-tree positions are not counted as separate people.</p>
  </>}
 </section>
}