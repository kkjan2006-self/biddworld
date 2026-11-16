import { useEffect, useRef, useState } from 'react';
import type { CSSProperties } from 'react';
import { Users, RefreshCw, Network, UserCheck, Wallet, Gift, Search, ChevronDown } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { money } from '../lib/format';

type TreeMember={member_code:string;display_name:string;status:string;created_at:string;depth:number;sponsor_code:string|null};
type Dashboard={main_member_code:string;direct_referrals:number;total_downline:number;active_members:number;active_activations:number;commission_total:number;bid_wallet:number;income_wallet:number;tree:TreeMember[];tree_total:number;has_more:boolean};

export default function Referrals(){
 const [userId,setUserId]=useState<string|null>(null),[data,setData]=useState<Dashboard|null>(null),[loading,setLoading]=useState(true),[loadingMore,setLoadingMore]=useState(false),[error,setError]=useState(''),[refresh,setRefresh]=useState(0),[query,setQuery]=useState(''),[depth,setDepth]=useState('all');
 const request=useRef(0);
 useEffect(()=>{if(!supabase){setLoading(false);return}let active=true;const{data:{subscription}}=supabase.auth.onAuthStateChange((_e,s)=>{if(active)setUserId(s?.user?.id??null)});void supabase.auth.getUser().then(({data})=>{if(active)setUserId(data.user?.id??null)});return()=>{active=false;subscription.unsubscribe()}},[]);
 useEffect(()=>{
  let active=true;
  const seq=++request.current;
  setData(null);setError('');setLoading(true);setLoadingMore(false);
  const timer=window.setTimeout(async()=>{
   if(!supabase||!userId){if(active)setLoading(false);return;}
   try{
    const {data:result,error:loadError}=await supabase.rpc('get_my_mlm_dashboard_page',{p_limit:50,p_offset:0,p_search:query.trim()||null,p_depth:depth==='all'?null:Number(depth)});
    if(!active||seq!==request.current)return;
    if(loadError)throw loadError;
    setData(result as Dashboard);
   }catch(e){if(active&&seq===request.current)setError(e instanceof Error?e.message:'Your team dashboard could not be loaded. Please retry.');}
   finally{if(active&&seq===request.current)setLoading(false);}
  },query.trim()||depth!=='all'?250:0);
  return()=>{active=false;window.clearTimeout(timer);};
 },[userId,refresh,query,depth]);
 async function loadMore(){
  const client=supabase;if(!client||!data?.has_more||loadingMore||loading)return;
  const seq=request.current;setLoadingMore(true);setError('');
  try{
   const offset=data.tree.length;
   const {data:next,error:loadError}=await client.rpc('get_my_mlm_dashboard_page',{p_limit:50,p_offset:offset,p_search:query.trim()||null,p_depth:depth==='all'?null:Number(depth)});
   if(seq!==request.current)return;
   if(loadError)throw loadError;
   setData(current=>current?({...next,tree:[...current.tree,...(next as Dashboard).tree]} as Dashboard):next as Dashboard);
  }catch(e){if(seq===request.current)setError(e instanceof Error?e.message:'More team members could not be loaded. Please retry.');}
  finally{if(seq===request.current)setLoadingMore(false);}
 }
 const cards=data?[['My Main ID',data.main_member_code,Users],['Direct Referrals',data.direct_referrals,UserCheck],['Total Team',data.total_downline,Network],['Active Members',data.active_members,UserCheck],['Package Activations',data.active_activations,Gift],['Referral Income',money(Number(data.commission_total)),Wallet],['Bid Wallet',money(Number(data.bid_wallet)),Wallet],['Income Wallet',money(Number(data.income_wallet)),Wallet]] as const:[];
 return <section className="referralWorkspace">
  <div className="packageIntro"><span className="workspaceIcon"><Network/></span><div><h3>My MLM Dashboard</h3><p>Your sponsor genealogy, team members, wallet and referral summary.</p></div><button className="outline small" onClick={()=>setRefresh(v=>v+1)}><RefreshCw size={14}/> Refresh</button></div>
  {loading&&!data?<p className="packageState">Loading your team dashboard…</p>:error?<div className="notice">{error} <button className="outline small" onClick={()=>setRefresh(v=>v+1)}>Retry</button></div>:data&&<>
   <div className="mlmCards">{cards.map(([label,value,Icon])=><article key={label}><Icon size={19}/><small>{label}</small><b>{value}</b></article>)}</div>
   <div className="genealogyHead"><div><h4>My Team Genealogy</h4><p>Members are grouped under the Sponsor Main ID recorded at registration or last admin correction.</p></div><span>{data.tree_total} matching members</span></div>
   <div className="genealogyTools"><label className="search"><Search size={16}/><input value={query} onChange={e=>setQuery(e.target.value)} placeholder="Search all team members"/></label><label className="depthSelect">Level <select value={depth} onChange={e=>setDepth(e.target.value)}><option value="all">All levels</option>{Array.from({length:20},(_,i)=><option key={i+1} value={String(i+1)}>Level {i+1}</option>)}</select><ChevronDown size={14}/></label></div>
   {loading?<p className="packageState">Updating team results…</p>:data.tree.length===0?<div className="empty">No team members match this view yet.</div>:<div className="genealogyList">{data.tree.map(m=><article className="genealogyMember" key={m.member_code} style={{'--tree-depth':Math.min(m.depth,8)} as CSSProperties}><span className="genealogyLine"/><div className="genealogyAvatar"><Users size={16}/></div><div className="genealogyInfo"><b>{m.display_name}</b><small>{m.member_code} · Joined {new Date(m.created_at).toLocaleDateString('en-IN')}</small><small>Sponsor: {m.sponsor_code??'Not assigned'}</small></div><span className="genealogyLevel">Level {m.depth}</span><span className={m.status==='active'?'memberActive':'memberStatus'}>{m.status}</span></article>)}</div>}
   {data.has_more&&<button className="outline small" disabled={loadingMore||loading} onClick={()=>void loadMore()}>{loadingMore?'Loading…':'Load more team members'}</button>}
   <p className="genealogyNote">This genealogy follows the recorded Sponsor Referral relationship. Duplicate IDs and placement-tree positions are not counted as separate people.</p>
  </>}
 </section>
}
