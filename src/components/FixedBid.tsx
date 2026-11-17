import {useEffect,useRef,useState} from 'react';
import {Gavel,Package,RefreshCw} from 'lucide-react';
import {supabase} from '../lib/supabase';
import {escapeLikePattern} from '../lib/like-pattern';
type Campaign={id:string;title:string;description:string|null;status:string;created_at:string;product: {name:string;description:string|null;category:string|null;image_path:string|null}|null};
const PAGE_SIZE=50;
type CampaignStatus='all'|'scheduled'|'live'|'ended';
export default function FixedBid(){
 const [rows,setRows]=useState<Campaign[]>([]),[loading,setLoading]=useState(true),[loadingMore,setLoadingMore]=useState(false),[hasMore,setHasMore]=useState(false),[error,setError]=useState('');
 const [search,setSearch]=useState(''),[statusFilter,setStatusFilter]=useState<CampaignStatus>('all');
 const mounted=useRef(true),requestId=useRef(0),requestInFlight=useRef(false);
 async function load(reset=true,searchTerm=search,status=statusFilter){
  if(!reset&&(requestInFlight.current||loadingMore||!hasMore))return;
  if(!reset)requestInFlight.current=true;
  const request=++requestId.current;
  if(reset){setLoading(true);setError('');setRows([]);setHasMore(false);}else{setLoadingMore(true);setError('');}
  try {
   if(!supabase){if(mounted.current&&request===requestId.current){setRows([]);setHasMore(false);}return;}
   let query=supabase.from('fixed_bid_campaigns').select('id,title,description,status,created_at,product:products(name,description,category,image_path)').in('status',['scheduled','live','ended']).order('created_at',{ascending:false}).order('id',{ascending:false});
   if(status!=='all')query=query.eq('status',status);
   if(searchTerm.trim())query=query.ilike('title',`%${escapeLikePattern(searchTerm.trim())}%`);
   const offset=reset?0:rows.length;
   const {data,error}=await query.range(offset,offset+PAGE_SIZE-1);
   if(error)throw error;
   if(!mounted.current||request!==requestId.current)return;
   const batch=(data??[]) as unknown as Campaign[];
   setRows(current=>reset?batch:[...current,...batch]);
   setHasMore(batch.length===PAGE_SIZE);
  } catch {
   if(mounted.current&&request===requestId.current)setError(reset?'Fixed Bid campaigns are not available yet.':'More campaigns could not be loaded. Please retry.');
  } finally {
   if(!reset)requestInFlight.current=false;
   if(mounted.current&&request===requestId.current){setLoading(false);setLoadingMore(false);}
  }
 }
 useEffect(()=>{
  mounted.current=true;
  const timer=window.setTimeout(()=>void load(true,search,statusFilter),search.trim()?250:0);
  return()=>{window.clearTimeout(timer);requestId.current+=1;};
 },[search,statusFilter]);
 useEffect(()=>()=>{mounted.current=false;requestId.current+=1;requestInFlight.current=false;},[]);
 const visibleRows=rows;
 return <section className="fixedBidList"><div className="packageIntro"><span className="workspaceIcon"><Gavel/></span><div><h3>Fixed Bid campaigns</h3><p>Scheduled, live and ended campaigns are shown. Campaign information is read-only; no entries or payments are processed here.</p></div><button className="outline small" onClick={()=>void load(true)} disabled={loading||loadingMore}><RefreshCw size={14}/> Refresh</button></div>
 <div className="sponsorAdminForm" style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(190px,1fr))',gap:10,marginBottom:14}}><label>Search campaign title<input type="search" value={search} onChange={e=>setSearch(e.target.value)} placeholder="Enter campaign title"/></label><label>Campaign status<select value={statusFilter} onChange={e=>setStatusFilter(e.target.value as CampaignStatus)}><option value="all">All statuses</option><option value="scheduled">Scheduled</option><option value="live">Live</option><option value="ended">Ended</option></select></label></div>
 {loading?<p className="packageState">Loading campaigns…</p>:error&&rows.length===0?<div className="notice">{error} <button className="outline small" onClick={()=>void load(true)}>Retry</button></div>:rows.length===0?<div className="empty">{search.trim()||statusFilter!=='all'?'No campaigns match these filters.':'No scheduled, live or ended Fixed Bid campaigns are available.'}</div>:
 <><div className="memberModuleHint">{rows.length} matching campaigns loaded{hasMore?' · more results are available':''}.</div><button className="outline small" type="button" onClick={()=>{setSearch('');setStatusFilter('all')}}>Clear filters</button><div className="fixedBidGrid">{visibleRows.map(r=><article className="fixedBidCard" key={r.id}><div className="fixedBidVisual">{r.product?.image_path?<img src={r.product.image_path} alt={r.product.name}/>:<Package size={34}/>}<span>{r.product?.category??'FIXED BID'}</span></div><div className="fixedBidBody"><span className="status">{r.status.toUpperCase()}</span><h3>{r.title}</h3>{r.product?.name&&<b>{r.product.name}</b>}<p>{r.description||r.product?.description||'Campaign details will be published by the administrator.'}</p><small>Published {new Date(r.created_at).toLocaleDateString()}</small></div></article>)}</div>
 {error&&<div className="notice">{error}</div>}
 {hasMore&&<div className="marketPagination"><button className="outline darkOutline" disabled={loadingMore} onClick={()=>void load(false)}>{loadingMore?'Loading…':'Load more campaigns'}</button><span>{rows.length} campaigns loaded</span></div>}</>}
 </section>;
}
