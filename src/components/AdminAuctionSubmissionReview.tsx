import {useEffect,useRef,useState} from 'react';
import {RefreshCw,CheckCircle2,XCircle,Save} from 'lucide-react';
import {supabase} from '../lib/supabase';
type Row={id:string;title:string;description:string;category:string|null;image_paths:string[];starting_price:number;expected_price:number;minimum_increment:number;starts_at:string;ends_at:string|null;optional_details:Record<string,string>;created_at:string;submitted_by:string};
function validRow(value:unknown):value is Row{
 if(!value||typeof value!=='object'||Array.isArray(value))return false;
 const row=value as Record<string,unknown>;
 return typeof row.id==='string'&&row.id.trim().length>0
  &&typeof row.title==='string'&&row.title.trim().length>=5&&row.title.length<=180
  &&typeof row.description==='string'&&row.description.trim().length>=20&&row.description.length<=10000
  &&(row.category===null||typeof row.category==='string')
  &&Array.isArray(row.image_paths)&&row.image_paths.length>=1&&row.image_paths.length<=8&&row.image_paths.every(path=>typeof path==='string'&&path.trim().length>0)
  &&typeof row.starting_price==='number'&&Number.isFinite(row.starting_price)&&row.starting_price>0
  &&typeof row.expected_price==='number'&&Number.isFinite(row.expected_price)&&row.expected_price>=row.starting_price
  &&typeof row.minimum_increment==='number'&&Number.isFinite(row.minimum_increment)&&row.minimum_increment>0
  &&typeof row.starts_at==='string'&&Number.isFinite(Date.parse(row.starts_at))
  &&(row.ends_at===null||(typeof row.ends_at==='string'&&Number.isFinite(Date.parse(row.ends_at))))
  &&!!row.optional_details&&typeof row.optional_details==='object'&&!Array.isArray(row.optional_details)
  &&Object.entries(row.optional_details as Record<string,unknown>).every(([key,item])=>key.trim().length>0&&typeof item==='string')
  &&typeof row.created_at==='string'&&Number.isFinite(Date.parse(row.created_at))
  &&typeof row.submitted_by==='string'&&row.submitted_by.trim().length>0;
}
type PendingMediaCleanup={bucket:'auction-submission-media'|'product-media';path:string};
function validCleanupPath(value:unknown):value is string{return typeof value==='string'&&value.length<=500&&!value.split('/').some(part=>!part||part==='.'||part==='..')&&/^[0-9a-f-]{36}\//i.test(value);}
export default function AdminAuctionSubmissionReview(){
 const[rows,setRows]=useState<Row[]>([]),[urls,setUrls]=useState<Record<string,string[]>>({}),[edit,setEdit]=useState<Record<string,Partial<Row>>>({}),[notes,setNotes]=useState<Record<string,string>>({}),[busy,setBusy]=useState(''),[message,setMessage]=useState(''),[queueLoading,setQueueLoading]=useState(true),[loadingMore,setLoadingMore]=useState(false),[hasMore,setHasMore]=useState(false),[imageErrors,setImageErrors]=useState<Record<string,string>>({}),[orphanedMedia,setOrphanedMedia]=useState<PendingMediaCleanup[]>([]),[cleanupOwner,setCleanupOwner]=useState('');const reviewInFlight=useRef(false),loadSequence=useRef(0),pageLock=useRef(false),cursor=useRef<{created_at:string;id:string}|null>(null);
 async function load(reset=true){
  if(!supabase)return;
  if(!reset&&pageLock.current)return;
  if(reset){pageLock.current=false;cursor.current=null;}else pageLock.current=true;
  const seq=++loadSequence.current,after=reset?null:cursor.current;
  if(reset){setQueueLoading(true);setLoadingMore(false);}else setLoadingMore(true);
  setMessage('');
  try{
   const{data,error}=await supabase.rpc('admin_list_auction_submissions_page',{p_limit:50,p_after_created_at:after?.created_at??null,p_after_id:after?.id??null});
   if(error)throw error;
   if(!data||typeof data!=='object'||!Array.isArray(data.items)||typeof data.has_more!=='boolean')throw new Error('The auction review page response was invalid.');
   if(data.has_more&&(!data.next_created_at||!Number.isFinite(Date.parse(data.next_created_at))||typeof data.next_id!=='string'||!data.next_id.trim()))throw new Error('The auction review cursor was incomplete.');
   const list=data.items as unknown[];if(list.length>50||!list.every(validRow))throw new Error('The auction review page contains malformed submissions.');const ids=new Set<string>(),existing=new Set(reset?[]:rows.map(row=>row.id));
   for(const item of list){if(ids.has(item.id)||existing.has(item.id))throw new Error('The auction review page contains duplicate or overlapping submissions.');ids.add(item.id);}
   const next:Record<string,string[]>={},failures:Record<string,string>={};
   await Promise.all(list.map(async r=>{const signed=await Promise.all(r.image_paths.map(async path=>{const{data:signedData,error:signedError}=await supabase!.storage.from('auction-submission-media').createSignedUrl(path,300);if(signedError||!signedData?.signedUrl){failures[r.id]=signedError?.message||'One or more submitted images could not be opened.';return null;}return signedData.signedUrl;}));next[r.id]=signed.filter((url):url is string=>Boolean(url));}));
   if(seq!==loadSequence.current)return;
   setRows(current=>reset?list:[...current,...list]);setUrls(current=>reset?next:{...current,...next});setImageErrors(current=>reset?failures:{...current,...failures});
   setHasMore(data.has_more);cursor.current=data.has_more?{created_at:data.next_created_at,id:data.next_id}:null;
  }catch(e){if(seq===loadSequence.current)setMessage('Auction submission queue could not be loaded: '+(e instanceof Error?e.message:'Please retry.'));}
  finally{if(seq===loadSequence.current){setQueueLoading(false);setLoadingMore(false);pageLock.current=false;}}
 }
 useEffect(()=>{void load();let active=true;void supabase?.auth.getUser().then(({data,error})=>{if(!active||error||!data.user)return;const owner=data.user.id;setCleanupOwner(owner);try{const raw=localStorage.getItem('biddworld:admin-auction-media-cleanup:'+owner);if(raw){const parsed:unknown=JSON.parse(raw);if(Array.isArray(parsed))setOrphanedMedia(parsed.filter((item):item is PendingMediaCleanup=>!!item&&typeof item==='object'&&!Array.isArray(item)&&['auction-submission-media','product-media'].includes(String((item as Record<string,unknown>).bucket))&&validCleanupPath((item as Record<string,unknown>).path)).slice(0,100));}}catch{/* In-memory retry remains available. */}});return()=>{active=false;};},[]);
 useEffect(()=>{if(!cleanupOwner)return;try{const key='biddworld:admin-auction-media-cleanup:'+cleanupOwner;if(orphanedMedia.length)localStorage.setItem(key,JSON.stringify(orphanedMedia.slice(0,100)));else localStorage.removeItem(key);}catch{/* Persistent recovery is best-effort. */}},[cleanupOwner,orphanedMedia]);
 async function retryOrphanedMediaCleanup(){if(!supabase||!orphanedMedia.length||busy)return;const pending=[...orphanedMedia],failed:PendingMediaCleanup[]=[];setBusy('cleanup');setMessage('');for(const bucket of ['auction-submission-media','product-media'] as const){const paths=pending.filter(item=>item.bucket===bucket).map(item=>item.path);if(!paths.length)continue;try{const{error}=await supabase.storage.from(bucket).remove(paths);if(error)failed.push(...pending.filter(item=>item.bucket===bucket));}catch{failed.push(...pending.filter(item=>item.bucket===bucket));}}setOrphanedMedia(current=>[...current.filter(item=>!pending.some(done=>done.bucket===item.bucket&&done.path===item.path)),...failed].slice(0,100));setMessage(failed.length?'Some temporary auction images still need cleanup. Retry when Storage is available.':'Temporary auction image cleanup completed.');setBusy('');}
 function val(r:Row,key:keyof Row){return (edit[r.id]?.[key]??r[key]) as never}
 async function decide(r:Row,decision:'approve'|'reject'){
  if(!supabase||reviewInFlight.current||busy)return;
  if(!window.confirm(decision==='approve'?'Approve and publish this auction with the edited details?':'Reject this auction submission?'))return;
  reviewInFlight.current=true;setBusy(r.id);setMessage('');
  const publishedPaths:string[]=[];let rpcAttempted=false;let rpcDefinitelyRejected=false;
  try{
   const v=edit[r.id]??{};
   const title=String(v.title??r.title).trim(),description=String(v.description??r.description).trim();
   const starting=Number(v.starting_price??r.starting_price),expected=Number(v.expected_price??r.expected_price),increment=Number(v.minimum_increment??r.minimum_increment);
   const startsAt=String(v.starts_at??r.starts_at);
   if(decision==='approve'){
    if(title.length<5||title.length>180)throw new Error('Auction title must be 5 to 180 characters.');
    if(description.length<20||description.length>10000)throw new Error('Description must be 20 to 10,000 characters.');
    if(!Number.isFinite(starting)||starting<=0)throw new Error('Starting Price must be greater than zero.');
    if(!Number.isFinite(expected)||expected<starting)throw new Error('Expected Price must be equal to or greater than Starting Price.');
    if(!Number.isFinite(increment)||increment<=0)throw new Error('Minimum Bid Increment must be greater than zero.');
    if(!startsAt||!Number.isFinite(new Date(startsAt).getTime()))throw new Error('Choose a valid auction start date and time.');
    if(!Array.isArray(r.image_paths)||r.image_paths.length<1||r.image_paths.length>8)throw new Error('The submission must contain 1 to 8 item images.');
   }
   let approvedImagePaths=v.image_paths??r.image_paths;
   if(decision==='approve'){
    for(const privatePath of r.image_paths){
     const{data:blob,error:downloadError}=await supabase.storage.from('auction-submission-media').download(privatePath);
     if(downloadError||!blob)throw downloadError??new Error('Could not read submitted item image.');
     const filename=privatePath.split('/').pop()??crypto.randomUUID()+'.jpg';
     const publicPath=r.submitted_by+'/'+crypto.randomUUID()+'-'+filename;
     publishedPaths.push(publicPath);
     const{error:uploadError}=await supabase.storage.from('product-media').upload(publicPath,blob,{upsert:false,contentType:blob.type||'image/jpeg'});
     if(uploadError)throw uploadError;
    }
    approvedImagePaths=publishedPaths;
   }
   rpcAttempted=true;
   const{data:reviewResult,error}=await supabase.rpc('admin_review_auction_submission',{p_submission_id:r.id,p_decision:decision,p_title:title,p_description:description,p_category:v.category??r.category,p_image_paths:approvedImagePaths,p_starting_price:starting,p_expected_price:expected,p_minimum_increment:increment,p_starts_at:startsAt,p_optional_details:v.optional_details??r.optional_details,p_review_note:notes[r.id]??null});
   if(error){rpcDefinitelyRejected=typeof (error as {code?:unknown}).code==='string';throw error;}
   const result=reviewResult as Record<string,unknown>|null;const expectedStatus=decision==='approve'?'approved':'rejected';
   if(!result||typeof result!=='object'||Array.isArray(result)||result.success!==true||result.status!==expectedStatus)throw new Error('The auction review response did not match the requested moderation action. Refresh the queue before retrying.');
   if(decision==='approve'){
    const validUuid=(value:unknown)=>typeof value==='string'&&/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
    const target=result.target_reached_at===null?null:typeof result.target_reached_at==='string'&&Number.isFinite(Date.parse(result.target_reached_at))?result.target_reached_at:null;
    const deadline=result.ends_at===null?null:typeof result.ends_at==='string'&&Number.isFinite(Date.parse(result.ends_at))?result.ends_at:null;
    if(!validUuid(result.auction_id)||!validUuid(result.product_id)||typeof result.expected_price!=='number'||!Number.isFinite(result.expected_price)||result.expected_price!==expected||(expected===starting?(!target||!deadline||Date.parse(deadline)-Date.parse(target)!==48*60*60*1000):(result.target_reached_at!==null||result.ends_at!==null)))throw new Error('The auction approval response did not match the submitted listing or 48-hour Expected Price lifecycle. Refresh the queue before retrying.');
   }
   setEdit(current=>{const next={...current};delete next[r.id];return next;});setNotes(current=>{const next={...current};delete next[r.id];return next;});
   let cleanupWarning='';if(decision==='approve'&&r.image_paths.length){try{const{error:cleanupError}=await supabase.storage.from('auction-submission-media').remove(r.image_paths);if(cleanupError){cleanupWarning=' Original private images need cleanup; use Retry image cleanup.';setOrphanedMedia(current=>[...current,...r.image_paths.map(path=>({bucket:'auction-submission-media' as const,path}))].filter((item,index,array)=>array.findIndex(other=>other.bucket===item.bucket&&other.path===item.path)===index).slice(0,100));}}catch{cleanupWarning=' Original private images need cleanup; use Retry image cleanup.';setOrphanedMedia(current=>[...current,...r.image_paths.map(path=>({bucket:'auction-submission-media' as const,path}))].filter((item,index,array)=>array.findIndex(other=>other.bucket===item.bucket&&other.path===item.path)===index).slice(0,100));}}setMessage((decision==='approve'?'Auction approved and published.':'Auction rejected.')+cleanupWarning);
   await load();
  }catch(e){
   const reason=e instanceof Error?e.message:'Review action failed.';
   if(publishedPaths.length>0&&(!rpcAttempted||rpcDefinitelyRejected)){
    try{const{error:cleanupError}=await supabase.storage.from('product-media').remove(publishedPaths);if(cleanupError){setOrphanedMedia(current=>[...current,...publishedPaths.map(path=>({bucket:'product-media' as const,path}))].filter((item,index,array)=>array.findIndex(other=>other.bucket===item.bucket&&other.path===item.path)===index).slice(0,100));setMessage(reason+' Some temporary public images need cleanup; use Retry image cleanup.');}else setMessage(reason);}
    catch{setOrphanedMedia(current=>[...current,...publishedPaths.map(path=>({bucket:'product-media' as const,path}))].filter((item,index,array)=>array.findIndex(other=>other.bucket===item.bucket&&other.path===item.path)===index).slice(0,100));setMessage(reason+' Some temporary public images need cleanup; use Retry image cleanup.');}
   }else setMessage(reason);
  }finally{reviewInFlight.current=false;setBusy('');}
 }
 return <section className="adminModuleDetail" style={{marginTop:18}}><header style={{display:'flex',alignItems:'center',justifyContent:'space-between',gap:8,flexWrap:'wrap'}}><div><h3>Member Auction Submissions ({rows.length})</h3><p>Review and edit member listings. Only approved auctions enter the public catalogue. End time is automatic: 48 hours after the expected price is reached.</p></div><button className="outline small" onClick={()=>void load(true)}><RefreshCw size={14}/> Refresh</button></header>{message&&<div className="notice" role="status">{message}</div>}{orphanedMedia.length>0&&<div className="notice" role="status">{orphanedMedia.length} temporary auction image(s) still need cleanup. <button type="button" className="outline small" disabled={!!busy} onClick={()=>void retryOrphanedMediaCleanup()}><RefreshCw size={14}/> Retry image cleanup</button></div>}
 {queueLoading?<div className="empty">Loading auction submissions…</div>:message.startsWith('Auction submission queue could not be loaded:')?<div className="notice" role="alert">{message} <button type="button" className="outline small" onClick={()=>void load(true)}>Retry queue</button></div>:rows.length===0?<div className="empty">No auction submissions are pending review.</div>:rows.map(r=><article key={r.id} style={{display:'grid',gap:9,padding:14,borderTop:'1px solid var(--border,#ddd)'}}>
 <b>Submitted: {new Date(r.created_at).toLocaleString()}</b>{imageErrors[r.id]&&<small role="alert">Image preview issue: {imageErrors[r.id]} Refresh before approval.</small>}<div style={{display:'flex',gap:8,overflowX:'auto'}}>{(urls[r.id]??[]).map((url,i)=><img key={url} src={url} alt={'Auction item '+(i+1)} style={{width:112,height:92,objectFit:'cover',borderRadius:8}}/>)}</div>
 <label>Title<input minLength={5} maxLength={180} value={val(r,'title')} onChange={e=>setEdit(s=>({...s,[r.id]:{...s[r.id],title:e.target.value}}))}/></label>
 <label>Description<textarea rows={4} value={val(r,'description')} onChange={e=>setEdit(s=>({...s,[r.id]:{...s[r.id],description:e.target.value}}))}/></label>
 <label>Category<input value={String(val(r,'category')??'')} onChange={e=>setEdit(s=>({...s,[r.id]:{...s[r.id],category:e.target.value}}))}/></label><div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(150px,1fr))',gap:8}}>{Object.entries(r.optional_details??{}).map(([key,value])=><label key={key}>{key}<input value={String((edit[r.id]?.optional_details??r.optional_details)?.[key]??value)} onChange={e=>setEdit(s=>({...s,[r.id]:{...s[r.id],optional_details:{...(s[r.id]?.optional_details??r.optional_details),[key]:e.target.value}}}))}/></label>)}</div>
 <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(160px,1fr))',gap:8}}><label>Starting Price<input type="number" min="0.01" step="0.01" value={val(r,'starting_price')} onChange={e=>setEdit(s=>({...s,[r.id]:{...s[r.id],starting_price:Number(e.target.value)}}))}/></label><label>Expected Price<input type="number" min="0.01" step="0.01" value={val(r,'expected_price')} onChange={e=>setEdit(s=>({...s,[r.id]:{...s[r.id],expected_price:Number(e.target.value)}}))}/></label><label>Bid Increment<input type="number" min="0.01" step="0.01" value={val(r,'minimum_increment')} onChange={e=>setEdit(s=>({...s,[r.id]:{...s[r.id],minimum_increment:Number(e.target.value)}}))}/></label><label>Starts At<input type="datetime-local" value={String(val(r,'starts_at')).slice(0,16)} onChange={e=>setEdit(s=>({...s,[r.id]:{...s[r.id],starts_at:e.target.value&&Number.isFinite(new Date(e.target.value).getTime())?new Date(e.target.value).toISOString():''}}))}/></label></div>
 <label>Review Note (Optional)<textarea rows={2} maxLength={500} value={notes[r.id]??''} onChange={e=>setNotes(s=>({...s,[r.id]:e.target.value}))}/></label>
 <div style={{display:'flex',gap:8,flexWrap:'wrap'}}><button className="primary small" disabled={!!busy||(r.image_paths??[]).length<1||(urls[r.id]??[]).length!==(r.image_paths??[]).length} onClick={()=>void decide(r,'approve')}><CheckCircle2 size={15}/> Approve & Publish</button><button className="outline small" disabled={!!busy} onClick={()=>void decide(r,'reject')}><XCircle size={15}/> Reject</button></div>
 </article>)}{hasMore&&!queueLoading&&<button type="button" className="outline small" disabled={loadingMore||!!busy} onClick={()=>void load(false)}>{loadingMore?'Loading…':'Load More Submissions'}</button>}</section>;
}
