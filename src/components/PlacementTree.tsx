import {useEffect,useState} from 'react';
import {Network,RefreshCw,Users} from 'lucide-react';
import {supabase} from '../lib/supabase';

type PlacementMember={member_code:string;id_type:'main'|'duplicate';main_member_code:string;display_name:string;status:string;depth:number;placement_position:string|null;placement_parent_code:string|null;created_at:string};
type PlacementResult={root_member_code:string;tree:PlacementMember[]};
const PLACEMENT_MEMBER_STATUSES=['pending','active','suspended','closed'] as const;
function parsePlacementTree(value:unknown):PlacementResult{
 if(!value||typeof value!=='object'||Array.isArray(value))throw new Error('The placement tree response is malformed. Refresh and retry.');
 const payload=value as Record<string,unknown>;
 if(typeof payload.root_member_code!=='string'||!payload.root_member_code.trim()||payload.root_member_code.length>80||!Array.isArray(payload.tree)||payload.tree.length<1||payload.tree.length>10000)throw new Error('The placement tree response has invalid root or node data. Refresh and retry.');
 const seen=new Map<string,PlacementMember>();
 const rows:PlacementMember[]=[];
 for(const raw of payload.tree){
  if(!raw||typeof raw!=='object'||Array.isArray(raw))throw new Error('The placement tree contains a malformed member. Refresh and retry.');
  const row=raw as Record<string,unknown>;
  if(typeof row.member_code!=='string'||!row.member_code.trim()||row.member_code.length>80||seen.has(row.member_code)
   ||!['main','duplicate'].includes(String(row.id_type))
   ||typeof row.main_member_code!=='string'||!row.main_member_code.trim()||row.main_member_code.length>80
   ||typeof row.display_name!=='string'||!row.display_name.trim()||row.display_name.length>200
   ||!PLACEMENT_MEMBER_STATUSES.includes(row.status as typeof PLACEMENT_MEMBER_STATUSES[number])
   ||typeof row.depth!=='number'||!Number.isSafeInteger(row.depth)||row.depth<0||row.depth>20
   ||(row.placement_position!==null&&(typeof row.placement_position!=='string'||row.placement_position.length>50))
   ||(row.placement_parent_code!==null&&(typeof row.placement_parent_code!=='string'||!row.placement_parent_code.trim()||row.placement_parent_code.length>80))
   ||typeof row.created_at!=='string'||!Number.isFinite(Date.parse(row.created_at)))throw new Error('The placement tree contains invalid or duplicate member fields. Refresh and retry.');
  const member=row as unknown as PlacementMember;
  if(member.depth===0){
   if(rows.length!==0||member.member_code!==payload.root_member_code||member.id_type!=='main'||member.main_member_code!==payload.root_member_code)throw new Error('The placement tree root identity is inconsistent. Refresh and retry.');
  }else{
   if(!member.placement_parent_code)throw new Error('A placement member is missing its parent identity. Refresh and retry.');
   const parent=seen.get(member.placement_parent_code);
   if(!parent||parent.depth+1!==member.depth)throw new Error('The placement tree contains a missing or incorrectly ordered parent. Refresh and retry.');
  }
  seen.set(member.member_code,member);
  rows.push(member);
 }
 if(rows[0]?.depth!==0)throw new Error('The placement tree root is missing. Refresh and retry.');
 return {root_member_code:payload.root_member_code,tree:rows};
}

export default function PlacementTree(){
 const [data,setData]=useState<PlacementResult|null>(null);
 const [loading,setLoading]=useState(true);
 const [error,setError]=useState('');
 const [refresh,setRefresh]=useState(0);
 useEffect(()=>{
  let active=true;
  async function load(){
   setLoading(true);setError('');
   try{
    if(!supabase)throw new Error('Database connection is unavailable. Configure the intended Preview or Test environment.');
    const {data,error:loadError}=await supabase.rpc('get_my_placement_tree');
    if(!active)return;
    if(loadError)throw loadError;
    setData(parsePlacementTree(data));
   }catch(e){if(active)setError(e instanceof Error?e.message:'Placement tree could not be loaded. Please retry.');}
   finally{if(active)setLoading(false);}
  }
  void load();
  return()=>{active=false};
 },[refresh]);
 return <section className="referralWorkspace">
  <div className="packageIntro"><span className="workspaceIcon"><Network/></span><div><h3>My Placement Tree</h3><p>Placement positions are shown separately from Sponsor Referral genealogy.</p></div><button className="outline small" onClick={()=>setRefresh(v=>v+1)}><RefreshCw size={14}/> Refresh</button></div>
  {loading?<p className="packageState">Loading placement tree…</p>:error?<div className="notice" role="alert">{error} <button className="outline small" type="button" onClick={()=>setRefresh(v=>v+1)}>Retry</button></div>:data&&<>
   <div className="genealogyHead"><div><h4>Placement Network</h4><p>Main ID: {data.root_member_code}</p></div><span>{data.tree.length} positions</span></div>
   {data.tree.length===0?<div className="empty">No placement positions are recorded yet.</div>:<div className="genealogyList">{data.tree.map(m=><article className="genealogyMember" key={m.member_code} style={{'--tree-depth':Math.min(m.depth,8)} as React.CSSProperties}><span className="genealogyLine"/><div className="genealogyAvatar"><Users size={16}/></div><div className="genealogyInfo"><b>{m.display_name}</b><small>{m.member_code} · {m.id_type==='duplicate'?'Duplicate ID':'Main ID'} · Joined {new Date(m.created_at).toLocaleDateString('en-IN')}</small>{m.id_type==='duplicate'&&<small>Owned by Main ID: {m.main_member_code}</small>}<small>Under ID: {m.placement_parent_code||'Root placement'}</small><small>Position: {m.placement_position||'Not assigned'}</small></div><span className="genealogyLevel">{m.depth===0?'Root':'Level '+m.depth}</span><span className={m.status==='active'?'memberActive':'memberStatus'}>{m.status}</span></article>)}</div>}
   <p className="genealogyNote">The tree starts from your Main ID and includes both Main IDs and Duplicate IDs in their actual placement positions.</p>
  </>}
 </section>;
}
