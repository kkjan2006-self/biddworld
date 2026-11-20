import {useEffect,useRef,useState} from 'react';
import {Gavel,Package,RefreshCw,ShieldCheck,X,ChevronLeft,ChevronRight,Images} from 'lucide-react';
import {supabase} from '../lib/supabase';
import {money} from '../lib/format';

type CampaignConfig={
 entry_amount?:number|string;
 winner_payment_amount?:number|string;
 max_entries_per_member?:number;
 max_entries_total?:number;
 winner_count?:number;
 starts_at?:string;
 ends_at?:string;
 refund_non_winners?:boolean;
 progress_percent?:number;
};
type Campaign={
 id:string;title:string;description:string|null;status:string;created_at:string;
 configuration:CampaignConfig|null;
 product:{name:string;description:string|null;category:string|null;image_path:string|null;image_paths?:string[];product_details?:Record<string,string>}|null
};
const PAGE_SIZE=50;
function isCampaignBefore(left:Campaign,right:Campaign):boolean{const leftTime=Date.parse(left.created_at),rightTime=Date.parse(right.created_at);return leftTime<rightTime||(leftTime===rightTime&&left.id<right.id);}
function isStrictlyDescendingCampaignPage(items:Campaign[]):boolean{for(let index=1;index<items.length;index+=1){if(!isCampaignBefore(items[index],items[index-1]))return false;}return true;}
function parseCampaignPage(value:unknown):Campaign[]{
 if(!Array.isArray(value)||value.length>PAGE_SIZE)throw new Error('The campaign catalogue returned an invalid page. Refresh before continuing.');
 const ids=new Set<string>();
 const items=value.map(raw=>{
  if(!raw||typeof raw!=='object'||Array.isArray(raw))throw new Error('The campaign catalogue contains a malformed record.');
  const row=raw as Record<string,unknown>;
  if(typeof row.id!=='string'||!row.id.trim()||ids.has(row.id)||typeof row.title!=='string'||!row.title.trim()
   ||(row.description!==null&&typeof row.description!=='string')
   ||!['scheduled','live','ended'].includes(String(row.status))
   ||typeof row.created_at!=='string'||!Number.isFinite(Date.parse(row.created_at))
   ||(row.configuration!==null&&(typeof row.configuration!=='object'||Array.isArray(row.configuration)))
   ||(row.product!==null&&(typeof row.product!=='object'||Array.isArray(row.product))))
   throw new Error('The campaign catalogue contains invalid identity or status fields.');
  if(row.configuration&&typeof row.configuration==='object'){
   const config=row.configuration as Record<string,unknown>;
   for(const key of ['entry_amount','winner_payment_amount'] as const){
    const item=config[key];
    if(item!==null&&item!==undefined&&(!Number.isFinite(Number(item))||Number(item)<=0))throw new Error('The campaign catalogue contains an invalid '+key+'.');
   }
   for(const key of ['max_entries_per_member','max_entries_total','winner_count'] as const){
    const item=config[key];
    if(item!==null&&item!==undefined&&(!Number.isInteger(Number(item))||Number(item)<=0))throw new Error('The campaign catalogue contains an invalid '+key+'.');
   }
   if(config.progress_percent!==null&&config.progress_percent!==undefined&&(!Number.isInteger(Number(config.progress_percent))||Number(config.progress_percent)<0||Number(config.progress_percent)>100))throw new Error('The campaign catalogue contains an invalid progress percentage.');
   for(const key of ['starts_at','ends_at'] as const){
    const item=config[key];
    if(item!==null&&item!==undefined&&(typeof item!=='string'||!Number.isFinite(Date.parse(item))))throw new Error('The campaign catalogue contains an invalid '+key+'.');
   }
   if(config.refund_non_winners!==null&&config.refund_non_winners!==undefined&&typeof config.refund_non_winners!=='boolean')throw new Error('The campaign catalogue contains an invalid refund rule.');
  }
  if(row.product&&typeof row.product==='object'){
   const product=row.product as Record<string,unknown>;
   if(typeof product.name!=='string'||!product.name.trim()
    ||(product.description!==null&&typeof product.description!=='string')
    ||(product.category!==null&&typeof product.category!=='string')
    ||(product.image_path!==null&&typeof product.image_path!=='string')
    ||(product.image_paths!==undefined&&(!Array.isArray(product.image_paths)||product.image_paths.length>8||!product.image_paths.every(path=>typeof path==='string'&&path.trim().length>0)))
    ||(product.product_details!==undefined&&(!product.product_details||typeof product.product_details!=='object'||Array.isArray(product.product_details)||!Object.values(product.product_details as Record<string,unknown>).every(item=>typeof item==='string'))))
    throw new Error('The campaign catalogue contains invalid product details.');
  }
  ids.add(row.id);
  return row as unknown as Campaign;
 });
 if(!isStrictlyDescendingCampaignPage(items))throw new Error('The campaign catalogue is not in strict descending (created_at,id) order. Refresh before continuing.');
 return items;
}
const sampleFixedCampaigns:Campaign[]=[
{id:'sample-fixed-1',title:'Smartphone Mega Fixed Bid',description:'Sample campaign preview with entry amount, winner payment and campaign limits. Display-only; no entry or payment is processed.',status:'preview',created_at:new Date().toISOString(),configuration:{entry_amount:50,winner_payment_amount:12000,max_entries_per_member:3,max_entries_total:500,winner_count:1,starts_at:new Date(Date.now()-3600000).toISOString(),ends_at:new Date(Date.now()+5*86400000).toISOString(),refund_non_winners:false},product:{name:'5G Smartphone · 128 GB',description:'Sample product details.',category:'Electronics',image_path:import.meta.env.BASE_URL+'sample-products/smartphone.webp',image_paths:[import.meta.env.BASE_URL+'sample-products/smartphone.webp'],product_details:{Brand:'Sample brand',Condition:'New',Storage:'128 GB'}}},
{id:'sample-fixed-2',title:'Home Appliances Fixed Bid',description:'Sample campaign preview with a different product and entry limit. No payment or entry is processed.',status:'preview',created_at:new Date().toISOString(),configuration:{entry_amount:25,winner_payment_amount:6500,max_entries_per_member:5,max_entries_total:800,winner_count:2,starts_at:new Date(Date.now()-7200000).toISOString(),ends_at:new Date(Date.now()+7*86400000).toISOString(),refund_non_winners:true},product:{name:'Smart Mixer Grinder',description:'Sample product details.',category:'Home & Kitchen',image_path:import.meta.env.BASE_URL+'sample-products/mixer-grinder.webp',image_paths:[import.meta.env.BASE_URL+'sample-products/mixer-grinder.webp'],product_details:{Condition:'New'}}},
{id:'sample-fixed-3',title:'Lifestyle Accessories Fixed Bid',description:'Sample campaign preview showing multiple winner slots and compact product details.',status:'preview',created_at:new Date().toISOString(),configuration:{entry_amount:30,winner_payment_amount:3000,max_entries_per_member:2,max_entries_total:300,winner_count:3,starts_at:new Date(Date.now()+86400000).toISOString(),ends_at:new Date(Date.now()+9*86400000).toISOString(),refund_non_winners:false},product:{name:'Premium Smartwatch',description:'Sample product details.',category:'Lifestyle',image_path:import.meta.env.BASE_URL+'sample-products/smartwatch.webp',image_paths:[import.meta.env.BASE_URL+'sample-products/smartwatch.webp'],product_details:{Condition:'New'}}}
];
type CampaignStatus='all'|'scheduled'|'live'|'ended';
function productImageUrl(path:string|null|undefined){if(!path)return '';if(/^https?:\/\//i.test(path)||path.startsWith(import.meta.env.BASE_URL))return path;return supabase?.storage.from('product-media').getPublicUrl(path).data.publicUrl??'';}
function requestKey(){const bytes=new Uint8Array(16);window.crypto.getRandomValues(bytes);return Array.from(bytes,b=>b.toString(16).padStart(2,'0')).join('');}

export default function FixedBid({compact=false}:{compact?:boolean}){
 const [rows,setRows]=useState<Campaign[]>([]),[loading,setLoading]=useState(true),[loadingMore,setLoadingMore]=useState(false),[hasMore,setHasMore]=useState(false),[error,setError]=useState('');
 const [search,setSearch]=useState(''),[statusFilter,setStatusFilter]=useState<CampaignStatus>('all');
 const [message,setMessage]=useState(''),[joining,setJoining]=useState('');
 const [detailCampaign,setDetailCampaign]=useState<Campaign|null>(null),[galleryIndex,setGalleryIndex]=useState(0);
 const showingSamples=rows.length===0&&!error;
 const displayRows=rows.length?rows:showingSamples?sampleFixedCampaigns:[];
 const mounted=useRef(true),requestId=useRef(0),requestInFlight=useRef(false),entryKeys=useRef(new Map<string,string>());
 async function load(reset=true,searchTerm=search,status=statusFilter){
  if(!reset&&(requestInFlight.current||loadingMore||!hasMore))return;
  if(!reset)requestInFlight.current=true;
  const request=++requestId.current;
  if(reset){requestInFlight.current=false;setLoading(true);setError('');setRows([]);setHasMore(false);}else{setLoadingMore(true);setError('');}
  try {
   if(!supabase){if(mounted.current&&request===requestId.current){setRows([]);setHasMore(false);setError('Supabase is not configured.');}return;}
   const offset=reset?0:rows.length;
   const {data,error}=await supabase.rpc('public_list_fixed_bid_campaigns_page',{p_search:searchTerm.trim()||null,p_status:status,p_limit:PAGE_SIZE,p_offset:offset});
   if(error)throw error;
   if(!mounted.current||request!==requestId.current)return;
   if(!Array.isArray(data??[]))throw new Error('The campaign catalogue response was invalid. Please refresh.');
   const batch=parseCampaignPage(data??[]);
   const knownIds=new Set(reset?[]:rows.map(row=>row.id));
   if(batch.some(campaign=>knownIds.has(campaign.id)))throw new Error('The campaign catalogue returned duplicate campaign IDs. Refresh before loading more.');
   if(!reset&&rows.length>0&&batch.length>0&&!isCampaignBefore(batch[0],rows[rows.length-1]))throw new Error('The campaign catalogue continuation page crossed or repeated its previous (created_at,id) boundary. Refresh before loading more.');
   let added=batch.length;
   setRows(current=>{if(reset)return batch;added=batch.length;return [...current,...batch];});
   setHasMore(batch.length===PAGE_SIZE&&(reset||added>0));
  } catch {
   if(mounted.current&&request===requestId.current)setError(reset?'Fixed Bid campaigns could not be loaded. Please retry.':'More campaigns could not be loaded. Please retry.');
  } finally {
   if(!reset&&request===requestId.current)requestInFlight.current=false;
   if(mounted.current&&request===requestId.current){setLoading(false);setLoadingMore(false);}
  }
 }
 useEffect(()=>{mounted.current=true;const timer=window.setTimeout(()=>void load(true,search,statusFilter),search.trim()?250:0);return()=>{window.clearTimeout(timer);requestId.current+=1;};},[search,statusFilter]);
 useEffect(()=>()=>{mounted.current=false;requestId.current+=1;requestInFlight.current=false;},[]);
 async function joinCampaign(campaign:Campaign){
  if(!supabase||joining)return;
  setJoining(campaign.id);setMessage('');
  try{
   const {data:authData,error:authError}=await supabase.auth.getUser();
   if(authError)throw authError;
   if(!authData.user){setMessage('Please sign in from the website header before entering a campaign.');return;}
   let key=entryKeys.current.get(campaign.id);
   if(!key){key=requestKey();entryKeys.current.set(campaign.id,key);}
   const {data,error}=await supabase.rpc('member_join_fixed_bid_campaign',{p_campaign_id:campaign.id,p_idempotency_key:key});
   if(error){
    const raw=String(error.message||'');
    if(/insufficient/i.test(raw))throw new Error('Insufficient Funds – Please Add Funds');
    throw error;
   }
   const result=data as Record<string,unknown>|null;const entryAmount=Number(result?.entry_amount),bidDebit=Number(result?.bid_wallet_debit),incomeDebit=Number(result?.income_wallet_debit);
   if(!result||typeof result!=='object'||Array.isArray(result)||result.success!==true||typeof result.entry_id!=='string'||!result.entry_id.trim()||!Number.isFinite(entryAmount)||entryAmount<=0||!Number.isFinite(bidDebit)||bidDebit<0||!Number.isFinite(incomeDebit)||incomeDebit<0||Math.abs(bidDebit+incomeDebit-entryAmount)>0.001||typeof result.replayed!=='boolean')throw new Error('The server returned a Fixed Bid entry result that does not match the campaign entry. The same request key is retained; refresh your entry history before retrying.');
   entryKeys.current.delete(campaign.id);
   setMessage(result.replayed?'Your previous entry request was already recorded. No second entry was created.':`Entry confirmed. Entry ID: ${result.entry_id} · Amount: ${money(entryAmount,'INR')} (Bid Wallet: ${money(bidDebit,'INR')}, Income Wallet: ${money(incomeDebit,'INR')}).`);
  }catch(e){setMessage(e instanceof Error?e.message:'Campaign entry could not be confirmed. Retry safely; the same request key will be reused.');}
  finally{setJoining('');}
 }
 return <section className={`fixedBidList${compact?" fixedBidCompact":""}`}>
  <div className="packageIntro"><span className="workspaceIcon"><Gavel/></span><div><h3>Fixed Bids</h3>{!compact&&<p>Review campaign rules, entry limits and schedules before participating. Entries are recorded by the secure server workflow.</p>}</div><button className="outline small" onClick={()=>void load(true)} disabled={loading||loadingMore}><RefreshCw size={14}/> Refresh</button></div>
  {message&&<div className="notice" role="status" aria-live="polite">{message}</div>}
  {!compact&&<div className="sponsorAdminForm" style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(190px,1fr))',gap:10,marginBottom:14}}><label>Search campaign title<input type="search" value={search} onChange={e=>setSearch(e.target.value)} placeholder="Enter campaign title"/></label><label>Campaign status<select value={statusFilter} onChange={e=>setStatusFilter(e.target.value as CampaignStatus)}><option value="all">All statuses</option><option value="scheduled">Scheduled</option><option value="live">Live</option><option value="ended">Ended</option></select></label></div>}
  {loading?<p className="packageState">Loading campaigns…</p>:
  <>{error&&<div className="notice" role="status">{error} <button className="outline small" onClick={()=>void load(true)}>Retry</button></div>}{showingSamples&&<div className="memberModuleHint">SAMPLE PREVIEW · Example cards only. Published campaigns automatically replace these samples.</div>}
  {!compact&&<><div className="memberModuleHint">{showingSamples?'3 sample campaigns shown':rows.length+' matching campaigns loaded'+(hasMore?' · more results are available':'')}</div><button className="outline small" type="button" onClick={()=>{setSearch('');setStatusFilter('all');}}>Clear filters</button></>}
  <div className="fixedBidGrid">{displayRows.map(r=>{const config=r.configuration??{};const canJoin=!showingSamples&&r.status==='live'&&Number(config.entry_amount)>0&&Boolean(config.starts_at)&&Boolean(config.ends_at);const images=(r.product?.image_paths??[]).length?r.product!.image_paths!:r.product?.image_path?[r.product.image_path]:[];const progress=Math.max(0,Math.min(100,Number(config.progress_percent??0)));return <article className={showingSamples?"fixedBidCard samplePreviewCard":"fixedBidCard"} key={r.id}>
   <div className="fixedBidVisual">{images[0]?<img src={productImageUrl(images[0])} alt={r.product?.name||'Campaign product'} loading="lazy"/>:<Package size={34}/>}<span>{r.product?.category??'FIXED BID'}</span></div>
   <div className="fixedBidBody"><span className="status">{showingSamples?'SAMPLE PREVIEW':r.status.toUpperCase()}</span><h3 title={r.title}>{r.title}</h3>{r.product?.name&&<b className="fixedBidSubtitle" title={r.product.name}>{r.product.name}</b>}
    <button className="fixedBidDetailsLink" type="button" onClick={()=>{setDetailCampaign(r);setGalleryIndex(0);}}>Product Details <span aria-hidden="true">→</span></button>
    {Number(config.entry_amount)>0&&<div className="fixedBidEntry"><small>Entry amount</small><strong>{money(Number(config.entry_amount),'INR')}</strong></div>}
    <div className="fixedBidProgress" aria-label={`Campaign progress ${progress}%`}><div className="fixedBidProgressTrack"><span style={{width:progress+'%'}}/></div><small>{progress}% filled</small></div>
    <button className="fixedBidBidButton" type="button" disabled={!canJoin||joining!==''} onClick={()=>void joinCampaign(r)}>{joining===r.id?'Processing…':canJoin?'BID NOW':showingSamples?'Preview only':r.status==='live'?'Currently unavailable':r.status==='scheduled'?'Coming soon':'Campaign closed'}<Gavel size={19}/></button>
   </div></article>;})}</div>
  {hasMore&&<div className="marketPagination"><button className="outline darkOutline" disabled={loadingMore} onClick={()=>void load(false)}>{loadingMore?'Loading…':'Load more campaigns'}</button><span>{rows.length} campaigns loaded</span></div>}</>}
  {!compact&&<p className="memberModuleHint"><ShieldCheck size={14}/> Each entry uses a unique retry key and is processed with server-side limits and wallet-ledger checks.</p>}
  {detailCampaign&&(()=>{const product=detailCampaign.product;const paths=(product?.image_paths??[]).length?product!.image_paths!:product?.image_path?[product.image_path]:[];const urls=paths.map(productImageUrl).filter(Boolean);const config=detailCampaign.configuration??{};const details=product?.product_details??{};return <div className="modalShade fixedBidModalShade" role="presentation" onClick={()=>setDetailCampaign(null)}><section className="fixedBidDetailModal" role="dialog" aria-modal="true" aria-label={detailCampaign.title+" details"} onClick={e=>e.stopPropagation()}><button className="modalClose" type="button" onClick={()=>setDetailCampaign(null)} aria-label="Close details"><X/></button><div className="fixedBidGallery">{urls.length?<><img src={urls[Math.min(galleryIndex,urls.length-1)]} alt={(product?.name||detailCampaign.title)+" image "+(galleryIndex+1)}/>{urls.length>1&&<><button type="button" aria-label="Previous image" onClick={()=>setGalleryIndex(i=>(i-1+urls.length)%urls.length)}><ChevronLeft/></button><button type="button" aria-label="Next image" onClick={()=>setGalleryIndex(i=>(i+1)%urls.length)}><ChevronRight/></button></>}</>:<div className="fixedBidNoImage"><Images size={42}/><span>No product images available</span></div>}</div>{urls.length>1&&<div className="fixedBidThumbnails">{urls.map((url,i)=><button type="button" key={url} className={galleryIndex===i?'active':''} onClick={()=>setGalleryIndex(i)}><img src={url} alt={"View image "+(i+1)}/></button>)}</div>}<span className="category">{product?.category||'FIXED BID'}</span><h2>{detailCampaign.title}</h2>{product?.name&&<h3>{product.name}</h3>}<p>{detailCampaign.description||product?.description||'No additional description has been provided.'}</p>{Object.keys(details).length>0&&<><h4>Product details</h4><div className="fixedBidDetailFacts">{Object.entries(details).map(([key,value])=><div key={key}><small>{key}</small><b>{value}</b></div>)}</div></> }<h4>Campaign details</h4><div className="fixedBidDetailFacts"><div><small>Entry amount</small><b>{money(Number(config.entry_amount??0),'INR')}</b></div><div><small>Winner payment</small><b>{money(Number(config.winner_payment_amount??0),'INR')}</b></div><div><small>Winner count</small><b>{config.winner_count??'—'}</b></div><div><small>Entries per member</small><b>{config.max_entries_per_member??'—'}</b></div><div><small>Non-winner refunds</small><b>{typeof config.refund_non_winners==='boolean'?(config.refund_non_winners?'Included':'Not included'):'—'}</b></div><div><small>Campaign status</small><b>{detailCampaign.status.toUpperCase()}</b></div><div><small>Starts</small><b>{config.starts_at?new Date(config.starts_at).toLocaleString('en-IN'):'—'}</b></div><div><small>Closes</small><b>{config.ends_at?new Date(config.ends_at).toLocaleString('en-IN'):'—'}</b></div><div><small>Published</small><b>{new Date(detailCampaign.created_at).toLocaleDateString('en-IN')}</b></div></div></section></div>})()}
 </section>;
}
