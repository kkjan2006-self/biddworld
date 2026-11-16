import {useEffect,useRef,useState} from 'react';
import {Gavel,Package,RefreshCw} from 'lucide-react';
import {supabase} from '../lib/supabase';
type Campaign={id:string;title:string;description:string|null;status:string;created_at:string;product: {name:string;description:string|null;category:string|null;image_path:string|null}|null};
const PAGE_SIZE=50;
export default function FixedBid(){
 const [rows,setRows]=useState<Campaign[]>([]),[loading,setLoading]=useState(true),[loadingMore,setLoadingMore]=useState(false),[hasMore,setHasMore]=useState(false),[error,setError]=useState('');
 const [search,setSearch]=useState(''),[statusFilter,setStatusFilter]=useState<'all'|'scheduled'|'active'|'ended'>('all');
 const mounted=useRef(true),requestId=useRef(0),requestInFlight=useRef(false);
 async function load(reset=true){
  if(requestInFlight.current)return;
  if(!reset&&(loadingMore||!hasMore))return;
  requestInFlight.current=true;
  const request=++requestId.current;
  if(reset){setLoading(true);setError('');setRows([]);setHasMore(false);}else{setLoadingMore(true);setError('');}
  try {
   if(!supabase){if(mounted.current&&request===requestId.current){setRows([]);setHasMore(false);}return;}
   const offset=reset?0:rows.length;
   const {data,error}=await supabase.from('fixed_bid_campaigns').select('id,title,description,status,created_at,product:products(name,description,category,image_path)').in('status',['scheduled','active','ended']).order('created_at',{ascending:false}).order('id',{ascending:false}).range(offset,offset+PAGE_SIZE-1);
   if(error)throw error;
   if(!mounted.current||request!==requestId.current)return;
   const batch=(data??[]) as unknown as Campaign[];
   setRows(current=>reset?batch:[...current,...batch]);
   setHasMore(batch.length===PAGE_SIZE);
  } catch {
   if(mounted.current&&request===requestId.current)setError(reset?'Fixed Bid campaigns are not available yet.':'More campaigns could not be loaded. Please retry.');
  } finally {
   requestInFlight.current=false;
   if(mounted.current&&request===requestId.current){setLoading(false);setLoadingMore(false);}
  }
 }
 useEffect(()=>{mounted.current=true;void load(true);return()=>{mounted.current=false;requestId.current+=1}},[]);
 const visibleRows=rows.filter(row=>(statusFilter==='all'||row.status===statusFilter)&&(!search.trim()||[row.title,row.description??'',row.product?.name??'',row.product?.category??''].some(value=>value.toLowerCase().includes(search.trim().toLowerCase()))));
 return <section className="fixedBidList"><div className="packageIntro"><span className="workspaceIcon"><Gavel/></span><div><h3>Fixed Bid campaigns</h3><p>Scheduled, live and ended campaigns are shown. Campaign information is read-only; no entries or payments are processed here.</p></div><button className="outline small" onClick={()=>void load(true)} disabled={loading||loadingMore}><RefreshCw size={14}/> Refresh</button></div>
 {loading?<p className="packageState">Loading campaigns…</p>:error&&rows.length===0?<div className="notice">{error} <button className="outline small" onClick={()=>void load(true)}>Retry</button></div>:rows.length===0?<div className="empty">No scheduled, live or ended Fixed Bid campaigns are available.</div>:
 <><div className="sponsorAdminForm" style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(190px,1fr))',gap:10,marginBottom:14}}><label>Search loaded campaigns<input type="search" value={search} onChange={e=>setSearch(e.target.value)} placeholder="Campaign or product name"/></label><label>Campaign status<select value={statusFilter} onChange={e=>setStatusFilter(e.target.value as typeof statusFilter)}><option value="all">All statuses</option><option value="scheduled">Scheduled</option><option value="active">Live</option><option value="ended">Ended</option></select></label></div>
 <div className="memberModuleHint">{visibleRows.length} matching campaigns from {rows.length} loaded records. Search and status filters apply to loaded campaigns.</div><button className="outline small" type="button" onClick={()=>{setSearch('');setStatusFilter('all')}}>Clear filters</button>{visibleRows.length===0?<div className="empty">No loaded campaigns match these filters.</div>:<div className="fixedBidGrid">{visibleRows.map(r=><article className="fixedBidCard" key={r.id}><div className="fixedBidVisual">{r.product?.image_path?<img src={r.product.image_path} alt={r.product.name}/>:<Package size={34}/>}<span>{r.product?.category??'FIXED BID'}</span></div><div className="fixedBidBody"><span className="status">{r.status==='active'?'LIVE':r.status.toUpperCase()}</span><h3>{r.title}</h3>{r.product?.name&&<b>{r.product.name}</b>}<p>{r.description||r.product?.description||'Campaign details will be published by the administrator.'}</p><small>Published {new Date(r.created_at).toLocaleDateString()}</small></div></article>)}</div>}
 {error&&<div className="notice">{error}</div>}
 {hasMore&&<div className="marketPagination"><button className="outline darkOutline" disabled={loadingMore} onClick={()=>void load(false)}>{loadingMore?'Loading…':'Load more campaigns'}</button><span>{rows.length} campaigns loaded</span></div>}</>}
 </section>;
}
