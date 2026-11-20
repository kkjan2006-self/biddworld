import {useEffect,useRef,useState} from 'react';
import {RefreshCw,ShieldCheck,PackageCheck} from 'lucide-react';
import {supabase} from '../lib/supabase';
import AdminWalletFundingReview from './AdminWalletFundingReview';
import AdminAuctionSubmissionReview from './AdminAuctionSubmissionReview';
import Support from './Support';

type Permission='package_activation_review'|'wallet_funding_review'|'auction_submission_review'|'support_ticket_review';
type Activation={id:string;activation_number:number;member_code:string;member_name:string|null;package_name:string;amount_paid:number;currency:string;bid_wallet_credit:number;payment_reference:string;receipt_path:string|null;submitted_at:string};
type ActivationCursor={submitted_at:string;id:string};
const UUID_PATTERN=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
function validActivationReceiptPath(value:unknown):value is string{
 if(typeof value!=='string'||value.length>300)return false;
 const parts=value.split('/');
 return parts.length===2&&UUID_PATTERN.test(parts[0])&&/^[a-f0-9]{32}-[a-z0-9._-]{1,90}$/i.test(parts[1]);
}
function validActivation(value:unknown):value is Activation{
 if(!value||typeof value!=='object'||Array.isArray(value))return false;
 const row=value as Record<string,unknown>;
 return typeof row.id==='string'&&UUID_PATTERN.test(row.id)
  &&typeof row.activation_number==='number'&&Number.isSafeInteger(row.activation_number)&&row.activation_number>=1
  &&typeof row.member_code==='string'&&row.member_code.trim().length>0&&row.member_code.length<=80
  &&(row.member_name===null||(typeof row.member_name==='string'&&row.member_name.length<=200))
  &&typeof row.package_name==='string'&&row.package_name.trim().length>0&&row.package_name.length<=120
  &&typeof row.amount_paid==='number'&&Number.isFinite(row.amount_paid)&&row.amount_paid>0&&row.amount_paid<=100000000
  &&typeof row.currency==='string'&&/^[A-Z]{3}$/.test(row.currency)
  &&typeof row.bid_wallet_credit==='number'&&Number.isFinite(row.bid_wallet_credit)&&row.bid_wallet_credit>=0&&row.bid_wallet_credit<=100000000
  &&typeof row.payment_reference==='string'&&/^[A-Za-z0-9./_-]{6,80}$/.test(row.payment_reference)
  &&(row.receipt_path===null||validActivationReceiptPath(row.receipt_path))
  &&typeof row.submitted_at==='string'&&Number.isFinite(Date.parse(row.submitted_at));
}
export default function AdminStaff(){
 const[permissions,setPermissions]=useState<Permission[]>([]),[accessReady,setAccessReady]=useState(false),[accessError,setAccessError]=useState(''),[accessAttempt,setAccessAttempt]=useState(0);
 const[rows,setRows]=useState<Activation[]>([]),[urls,setUrls]=useState<Record<string,string>>({}),[receiptErrors,setReceiptErrors]=useState<Record<string,string>>({}),[busy,setBusy]=useState(''),[message,setMessage]=useState(''),[queueLoading,setQueueLoading]=useState(false),[loadingMore,setLoadingMore]=useState(false),[hasMore,setHasMore]=useState(false);
 const reviewInFlight=useRef(false),loadSequence=useRef(0),pageLock=useRef(false),cursor=useRef<ActivationCursor|null>(null);

 async function load(reset=true){
  if(!supabase||!permissions.includes('package_activation_review'))return;
  if(!reset&&pageLock.current)return;
  const after=reset?null:cursor.current;
  if(!reset&&!after){setHasMore(false);return;}
  if(reset){pageLock.current=false;cursor.current=null;}else pageLock.current=true;
  const seq=reset?++loadSequence.current:loadSequence.current;
  if(reset){setQueueLoading(true);setLoadingMore(false);setHasMore(false);setRows([]);setUrls({});setReceiptErrors({});}
  else setLoadingMore(true);
  setMessage('');
  try{
   const{data,error}=await supabase.rpc('admin_list_pending_activations_page',{p_limit:50,p_after_submitted_at:after?.submitted_at??null,p_after_id:after?.id??null});
   if(error)throw error;
   if(!data||typeof data!=='object'||Array.isArray(data))throw new Error('The package activation queue returned an invalid response.');
   const payload=data as Record<string,unknown>;
   if(!Array.isArray(payload.items)||payload.items.length>50||typeof payload.has_more!=='boolean')throw new Error('The package activation queue returned an invalid page.');
   if(payload.has_more&&(typeof payload.next_submitted_at!=='string'||!Number.isFinite(Date.parse(payload.next_submitted_at))||typeof payload.next_id!=='string'||!UUID_PATTERN.test(payload.next_id)))throw new Error('The package activation queue cursor was incomplete.');
   if(!payload.has_more&&(payload.next_submitted_at!==null||payload.next_id!==null))throw new Error('The completed package activation page returned an unexpected cursor.');
   const items=payload.items as unknown[];
   if(!items.every(validActivation))throw new Error('The package activation queue contains malformed activation records.');
   const page=items as Activation[];
   if(payload.has_more&&(page.length!==50||page[page.length-1].id!==payload.next_id||page[page.length-1].submitted_at!==payload.next_submitted_at))throw new Error('The package activation queue cursor does not match the final record on this page.');
   for(let index=1;index<page.length;index++){const previous=page[index-1],current=page[index];if(Date.parse(previous.submitted_at)<Date.parse(current.submitted_at)||(previous.submitted_at===current.submitted_at&&previous.id.localeCompare(current.id)<0))throw new Error('The package activation queue is not in descending keyset order.');}
   const known=new Set(reset?[]:rows.map(row=>row.id));
   for(const item of page){if(known.has(item.id))throw new Error('The next package activation page contains duplicate or overlapping requests. Refresh the queue.');known.add(item.id);}
   const next:Record<string,string>={},failures:Record<string,string>={};
   await Promise.all((items as Activation[]).map(async item=>{
    if(!item.receipt_path){failures[item.id]='No payment receipt is attached.';return;}
    const{data:signed,error:signedError}=await supabase!.storage.from('package-receipts').createSignedUrl(item.receipt_path,300);
    if(signedError||!signed?.signedUrl){failures[item.id]=signedError?.message||'Receipt link could not be generated.';return;}
    next[item.id]=signed.signedUrl;
   }));
   if(seq!==loadSequence.current)return;
   setRows(current=>reset?items as Activation[]:[...current,...items as Activation[]]);
   setUrls(current=>({... (reset?{}:current),...next}));
   setReceiptErrors(current=>({... (reset?{}:current),...failures}));
   setHasMore(payload.has_more);
   cursor.current=payload.has_more?{submitted_at:payload.next_submitted_at as string,id:payload.next_id as string}:null;
  }catch(e){if(seq===loadSequence.current)setMessage('Package activation queue could not be loaded: '+(e instanceof Error?e.message:'Please retry.'));}
  finally{
   if(seq===loadSequence.current){setQueueLoading(false);setLoadingMore(false);}
   pageLock.current=false;
  }
 }

 useEffect(()=>{let active=true;setAccessReady(false);setAccessError('');void (async()=>{try{if(!supabase)throw new Error('Supabase is not configured for this environment.');const{data,error}=await supabase.auth.getUser();if(error)throw error;if(!active)return;const user=data.user;if(!user)throw new Error('Your Staff session could not be verified. Please sign in again.');const allowed=user.app_metadata?.role==='admin_staff'&&Array.isArray(user.app_metadata?.permissions)?user.app_metadata.permissions.filter((p):p is Permission=>['package_activation_review','wallet_funding_review','auction_submission_review','support_ticket_review'].includes(p as string)):[];setPermissions(allowed);}catch(e){if(active){setPermissions([]);setAccessError(e instanceof Error?e.message:'Staff access could not be verified. Please retry.');}}finally{if(active)setAccessReady(true);}})();return()=>{active=false};},[accessAttempt]);
 useEffect(()=>{if(accessReady&&permissions.includes('package_activation_review'))void load();},[accessReady,permissions.join('|')]);

 async function review(id:string,approve:boolean){
  if(!supabase||reviewInFlight.current)return;
  if(approve&&!urls[id]){setMessage('Open and verify the payment receipt before approving this activation.');return;}
  if(!window.confirm(approve?'Approve this verified package payment and activate the package?':'Reject this package payment?'))return;
  reviewInFlight.current=true;setBusy(id);setMessage('');
  try{const{data,error}=await supabase.rpc('admin_review_package_activation',{p_activation_id:id,p_approve:approve});if(error)throw error;const result=data as Record<string,unknown>|null;if(!result||typeof result!=='object'||Array.isArray(result)||result.success!==true||result.status!==(approve?'approved':'rejected')||(approve&&(typeof result.bid_wallet_credit!=='number'||!Number.isFinite(result.bid_wallet_credit)||result.bid_wallet_credit<0||typeof result.wallet_balance!=='number'||!Number.isFinite(result.wallet_balance)||result.wallet_balance<0)))throw new Error('The server returned a package activation result that does not match this review action. Refresh the activation queue before retrying.');setMessage(approve?'Package payment approved. Package activation and Bid Wallet credit completed.':'Package payment rejected. No wallet credit was issued.');await load();}
  catch(e){setMessage(e instanceof Error?e.message:'The package payment could not be reviewed.');}
  finally{reviewInFlight.current=false;setBusy('');}
 }

 return <main className="adminDashboard" style={{padding:'18px 12px',maxWidth:1000,margin:'0 auto'}}>
  <header style={{display:'flex',alignItems:'center',gap:10,flexWrap:'wrap'}}>
   <ShieldCheck/><div><h2>Staff Workspace</h2><p>Only the review permissions assigned to this Staff account are available here.</p></div>
   {permissions.includes('package_activation_review')&&<button className="outline small" onClick={()=>void load()} disabled={queueLoading}><RefreshCw size={14}/> Refresh</button>}
  </header>
  {!accessReady?<div className="empty">Checking your assigned review permissions…</div>:accessError?<div className="notice" role="alert">Staff access could not be verified: {accessError} <button type="button" className="outline small" onClick={()=>setAccessAttempt(value=>value+1)}>Retry access check</button></div>:permissions.length===0?<div className="empty">No review permissions are assigned to this Staff account. Contact the Primary Admin.</div>:null}
  {message&&<div className="notice" role="status">{message}</div>}
  {permissions.includes('package_activation_review')&&<section className="adminModuleDetail" style={{marginTop:18}}>
   <h3><PackageCheck size={18}/> Package Activation Reviews ({rows.length})</h3>
   <p>Verify the UTR and payment receipt before approving. Approval activates the package and applies the configured Bid Wallet credit.</p>
   {queueLoading?<div className="empty">Loading package activation requests…</div>:message.startsWith('Package activation queue could not be loaded:')?<div className="notice" role="alert">{message} <button type="button" className="outline small" onClick={()=>void load()}>Retry queue</button></div>:rows.length===0?<div className="empty">No pending package payment requests.</div>:<div className="referralList">{rows.map(item=><article key={item.id} style={{display:'flex',flexDirection:'column',gap:7,padding:14}}>
    <b>{item.member_code} · {item.member_name||'Member'}</b><span>{item.package_name} · ₹{Number(item.amount_paid).toLocaleString('en-IN')}</span>
    <small>Activation: {item.activation_number} · UTR: {item.payment_reference}</small><small>Bid Wallet credit: ₹{Number(item.bid_wallet_credit).toLocaleString('en-IN')}</small>
    <small>Submitted: {new Date(item.submitted_at).toLocaleString()}</small>
    {urls[item.id]?<a href={urls[item.id]} target="_blank" rel="noreferrer">Open payment receipt</a>:<small>{receiptErrors[item.id]||'Receipt link unavailable. Refresh to retry.'}</small>}
    <div style={{display:'flex',gap:8,flexWrap:'wrap'}}><button className="primary small" disabled={!!busy||!urls[item.id]} onClick={()=>void review(item.id,true)}>{busy===item.id?'Processing…':'Approve & Activate'}</button><button className="outline small" disabled={!!busy} onClick={()=>void review(item.id,false)}>Reject</button></div>
   </article>)}</div>}
   {hasMore&&<div style={{display:'flex',justifyContent:'center',padding:12}}><button className="outline small" type="button" disabled={loadingMore||queueLoading} onClick={()=>void load(false)}>{loadingMore?'Loading…':'Load more requests'}</button></div>}
  </section>}
  {permissions.includes('wallet_funding_review')&&<AdminWalletFundingReview/>}
  {permissions.includes('auction_submission_review')&&<AdminAuctionSubmissionReview/>}
  {permissions.includes('support_ticket_review')&&<section className="adminModuleDetail" style={{marginTop:18}}><h3>Support Ticket Reviews</h3><Support isStaffSupport/></section>}
 </main>;
}
