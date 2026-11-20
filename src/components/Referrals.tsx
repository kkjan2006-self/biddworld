import { useEffect, useRef, useState } from 'react';
import type { CSSProperties } from 'react';
import { Users, RefreshCw, Network, UserCheck, Wallet, Gift, Search, ChevronDown } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { money } from '../lib/format';
import { csvDocument } from '../lib/csv';
import { rpcContractUnavailableMessage } from '../lib/rpc-errors';

type TreeMember={member_code:string;display_name:string;status:string;created_at:string;depth:number;sponsor_code:string|null};
type Dashboard={main_member_code:string;direct_referrals:number;total_downline:number;active_members:number;active_activations:number;commission_total:number;bid_wallet:number;income_wallet:number;tree:TreeMember[];tree_total:number;has_more:boolean};
type MatrixSummary={credited_total:number;pending_total:number;reversed_total:number;credited_count:number;pending_count:number};
function parseDashboard(value:unknown):Dashboard{
 if(!value||typeof value!=='object'||Array.isArray(value))throw new Error('The team dashboard response was malformed.');
 const row=value as Record<string,unknown>;
 const numeric=['direct_referrals','total_downline','active_members','active_activations','commission_total','bid_wallet','income_wallet','tree_total'];
 if(typeof row.main_member_code!=='string'||!row.main_member_code.trim()||numeric.some(key=>typeof row[key]!=='number'||!Number.isFinite(row[key])||Number(row[key])<0)||!Number.isInteger(row.tree_total)||typeof row.has_more!=='boolean'||!Array.isArray(row.tree)||row.tree.length>50||Number(row.tree_total)<row.tree.length)throw new Error('The team dashboard returned invalid totals or pagination metadata.');
 const seen=new Set<string>();
 const tree=row.tree.map(raw=>{if(!raw||typeof raw!=='object'||Array.isArray(raw))throw new Error('The team dashboard contains a malformed member.');const member=raw as Record<string,unknown>;if(typeof member.member_code!=='string'||!member.member_code.trim()||seen.has(member.member_code)||typeof member.display_name!=='string'||typeof member.status!=='string'||typeof member.created_at!=='string'||!Number.isFinite(Date.parse(member.created_at))||!Number.isInteger(member.depth)||Number(member.depth)<1||(member.sponsor_code!==null&&typeof member.sponsor_code!=='string'))throw new Error('The team dashboard contains an invalid or duplicate member.');seen.add(member.member_code);return member as unknown as TreeMember;});
 if(row.has_more&&tree.length===0)throw new Error('The team dashboard pagination cursor cannot continue from an empty page.');
 return {...row,tree} as unknown as Dashboard;
}
function parseMatrixSummary(value:unknown):MatrixSummary{
 if(!value||typeof value!=='object'||Array.isArray(value))throw new Error('The Matrix commission summary was malformed.');
 const row=value as Record<string,unknown>;const keys=['credited_total','pending_total','reversed_total','credited_count','pending_count'];
 if(keys.some(key=>typeof row[key]!=='number'||!Number.isFinite(row[key])||Number(row[key])<0))throw new Error('The Matrix commission summary contains invalid totals.');
 if(!Number.isInteger(row.credited_count)||!Number.isInteger(row.pending_count))throw new Error('The Matrix commission summary contains invalid counts.');
 return row as unknown as MatrixSummary;
}

export default function Referrals(){
 const [userId,setUserId]=useState<string|null>(null),[data,setData]=useState<Dashboard|null>(null),[matrixSummary,setMatrixSummary]=useState<MatrixSummary|null>(null),[loading,setLoading]=useState(true),[loadingMore,setLoadingMore]=useState(false),[error,setError]=useState(''),[refresh,setRefresh]=useState(0),[query,setQuery]=useState(''),[depth,setDepth]=useState('all'),[exportBusy,setExportBusy]=useState(false),[exportMessage,setExportMessage]=useState('');
 const request=useRef(0),loadMoreBusy=useRef(false);
 useEffect(()=>{if(!supabase){setLoading(false);return}let active=true,authEventObserved=false;const{data:{subscription}}=supabase.auth.onAuthStateChange((_e,s)=>{authEventObserved=true;if(active)setUserId(s?.user?.id??null)});void supabase.auth.getUser().then(({data,error})=>{if(active&&!authEventObserved){if(error)throw error;setUserId(data.user?.id??null)}}).catch(()=>{if(active&&!authEventObserved){setError('Your sign-in session could not be verified. Please sign in again.');setLoading(false)}});return()=>{active=false;subscription.unsubscribe()}},[]);
 useEffect(()=>{
  let active=true;
  const seq=++request.current;loadMoreBusy.current=false;
  setData(null);setMatrixSummary(null);setError('');setLoading(true);setLoadingMore(false);
  const timer=window.setTimeout(async()=>{
   if(!supabase||!userId){if(active)setLoading(false);return;}
   try{
    const [{data:result,error:loadError},{data:matrix,error:matrixError}]=await Promise.all([
     supabase.rpc('get_my_mlm_dashboard_page',{p_limit:50,p_offset:0,p_search:query.trim()||null,p_depth:depth==='all'?null:Number(depth)}),
     supabase.rpc('member_get_my_matrix_commission_summary')
    ]);
    if(!active||seq!==request.current)return;
    if(loadError)throw loadError;
    setData(parseDashboard(result));
    if(!matrixError&&matrix)setMatrixSummary(parseMatrixSummary(matrix));
   }catch(e){if(active&&seq===request.current)setError(rpcContractUnavailableMessage(e,'Your team dashboard')??(e instanceof Error?e.message:'Your team dashboard could not be loaded. Please retry.'));}
   finally{if(active&&seq===request.current)setLoading(false);}
  },query.trim()||depth!=='all'?250:0);
  return()=>{active=false;window.clearTimeout(timer);};
 },[userId,refresh,query,depth]);
 async function exportTeam(){
  const client=supabase;if(!client||!userId||exportBusy)return;setExportBusy(true);setExportMessage('');
  try{
   const all:TreeMember[]=[];const seen=new Set<string>();let offset=0;let pages=0;
   for(;;){
    pages+=1;if(pages>10000)throw new Error('The team report exceeded the safe export limit. Please narrow the filters and retry.');
    const {data:result,error:loadError}=await client.rpc('get_my_mlm_dashboard_page',{p_limit:50,p_offset:offset,p_search:query.trim()||null,p_depth:depth==='all'?null:Number(depth)});
    if(loadError)throw loadError;
    const page=parseDashboard(result);
    const fresh=page.tree.filter(member=>{if(seen.has(member.member_code))return false;seen.add(member.member_code);return true;});
    if(fresh.length!==page.tree.length)throw new Error('The team report returned duplicate member IDs. Export stopped to prevent an incomplete CSV. Please refresh and retry.');
    all.push(...fresh);offset+=page.tree.length;
    if(!page.has_more)break;
    if(page.tree.length===0||fresh.length===0)throw new Error('The team report repeated a page and could not continue safely. Please narrow the filters and retry.');
   }
   if(!all.length){setExportMessage('No matching team members are available to export.');return;}
   const rows=[['Member Name','Member ID','Sponsor ID','Account Status','Level','Joined Date'],...all.map(member=>[member.display_name,member.member_code,member.sponsor_code??'',member.status,member.depth,member.created_at])];
   const url=URL.createObjectURL(new Blob([csvDocument(rows)],{type:'text/csv;charset=utf-8'}));const link=document.createElement('a');link.href=url;link.download='biddworld-team-genealogy.csv';document.body.appendChild(link);link.click();link.remove();URL.revokeObjectURL(url);
   setExportMessage('Exported '+all.length+' team member records matching the current search and level filters.');
  }catch(e){setExportMessage(e instanceof Error?e.message:'The team report could not be exported. Please retry.');}
  finally{setExportBusy(false);}
 }
 async function loadMore(){
  const client=supabase;if(!client||!data?.has_more||loadMoreBusy.current||loadingMore||loading)return;
  loadMoreBusy.current=true;const seq=request.current;setLoadingMore(true);setError('');
  try{
   const offset=data.tree.length;
   const {data:next,error:loadError}=await client.rpc('get_my_mlm_dashboard_page',{p_limit:50,p_offset:offset,p_search:query.trim()||null,p_depth:depth==='all'?null:Number(depth)});
   if(seq!==request.current)return;
   if(loadError)throw loadError;
   const page=parseDashboard(next);
   const knownCodes=new Set(data.tree.map(member=>member.member_code));
   const fresh=page.tree.filter(member=>{if(knownCodes.has(member.member_code))return false;knownCodes.add(member.member_code);return true;});
   const repeatedRows=fresh.length!==page.tree.length;
   if(repeatedRows)setError('The team list returned duplicate member IDs. Refresh the dashboard before loading more.');
   setData(current=>{if(!current)return page;const currentCodes=new Set(current.tree.map(member=>member.member_code));const additions=fresh.filter(member=>!currentCodes.has(member.member_code));return {...page,tree:[...current.tree,...additions],has_more:page.has_more&&additions.length>0&&!repeatedRows};});
  }catch(e){if(seq===request.current)setError(rpcContractUnavailableMessage(e,'Your team dashboard')??(e instanceof Error?e.message:'More team members could not be loaded. Please retry.'));}
  finally{if(seq===request.current){loadMoreBusy.current=false;setLoadingMore(false);}}
 }
 const cards=data?[['My Main ID',data.main_member_code,Users],['Direct Referrals',data.direct_referrals,UserCheck],['Total Team',data.total_downline,Network],['Active Members',data.active_members,UserCheck],['Package Activations',data.active_activations,Gift],['Sponsor Referral Income',money(Number(data.commission_total)),Wallet],...(matrixSummary?[['Matrix Commission Income',money(Number(matrixSummary.credited_total)),Gift] as const]:[]),['Bid Wallet',money(Number(data.bid_wallet)),Wallet],['Main Wallet',money(Number(data.income_wallet)),Wallet]] as const:[];
 return <section className="referralWorkspace">
  <div className="packageIntro"><span className="workspaceIcon"><Network/></span><div><h3>My Team Dashboard</h3><p>Your Sponsor team structure, placement-independent Matrix commission summary, team members and wallets.</p></div><button className="outline small" onClick={()=>setRefresh(v=>v+1)}><RefreshCw size={14}/> Refresh</button></div>
  {loading&&!data?<p className="packageState">Loading your team dashboard…</p>:error?<div className="notice">{error} <button className="outline small" onClick={()=>setRefresh(v=>v+1)}>Retry</button></div>:data&&<>
   <div className="mlmCards">{cards.map(([label,value,Icon])=><article key={label}><Icon size={19}/><small>{label}</small><b>{value}</b></article>)}</div>
   <div className="genealogyHead"><div><h4>My Team Structure</h4><p>Members are grouped under the Sponsor Main ID recorded at registration or last admin correction.</p></div><span>{data.tree_total} matching members</span><button className="outline small" type="button" onClick={()=>void exportTeam()} disabled={exportBusy||loading}><RefreshCw size={14}/>{exportBusy?"Preparing report…":"Export Team CSV"}</button></div>{exportMessage&&<p className="memberModuleState" role="status">{exportMessage}</p>}
   <div className="genealogyTools"><label className="search"><Search size={16}/><input value={query} onChange={e=>setQuery(e.target.value)} placeholder="Search all team members"/></label><label className="depthSelect">Level <select value={depth} onChange={e=>setDepth(e.target.value)}><option value="all">All levels</option>{Array.from({length:20},(_,i)=><option key={i+1} value={String(i+1)}>Level {i+1}</option>)}</select><ChevronDown size={14}/></label></div>
   {loading?<p className="packageState">Updating team results…</p>:data.tree.length===0?<div className="empty">No team members match this view yet.</div>:<div className="genealogyList">{data.tree.map(m=><article className="genealogyMember" key={m.member_code} style={{'--tree-depth':Math.min(m.depth,8)} as CSSProperties}><span className="genealogyLine"/><div className="genealogyAvatar"><Users size={16}/></div><div className="genealogyInfo"><b>{m.display_name}</b><small>{m.member_code} · Joined {new Date(m.created_at).toLocaleDateString('en-IN')}</small><small>Sponsor: {m.sponsor_code??'Not assigned'}</small></div><span className="genealogyLevel">Level {m.depth}</span><span className={m.status==='active'?'memberActive':'memberStatus'}>{m.status}</span></article>)}</div>}
   {data.has_more&&<button className="outline small" disabled={loadingMore||loading} onClick={()=>void loadMore()}>{loadingMore?'Loading…':'Load more team members'}</button>}
   <p className="genealogyNote">This genealogy follows the recorded Sponsor Referral relationship. Duplicate IDs and placement-tree positions are not counted as separate people.</p>
  </>}
 </section>
}
