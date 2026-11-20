import {useCallback,useEffect,useRef,useState} from 'react';
import {RefreshCw,ExternalLink} from 'lucide-react';
import {supabase} from '../lib/supabase';
import {money} from '../lib/format';
type Row={id:string;member_code:string;member_name:string|null;amount:number;currency:string;payment_reference:string;receipt_path:string;created_at:string};
type Cursor={created_at:string;id:string};
type Page={items:Row[];has_more:boolean;next_created_at:string|null;next_id:string|null};
const FUNDING_UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
function isFundingReceiptPath(value:unknown):value is string{
 return typeof value==='string'&&value.length<=300
  &&new RegExp('^'+FUNDING_UUID.source.slice(1,-1)+'/wallet-funding/'+FUNDING_UUID.source.slice(1,-1)+'-[a-z0-9._-]{1,80}$','i').test(value);
}
function isRow(value:unknown):value is Row{
 if(!value||typeof value!=='object'||Array.isArray(value))return false;
 const row=value as Record<string,unknown>;
 return typeof row.id==='string'&&FUNDING_UUID.test(row.id)
  &&typeof row.member_code==='string'&&row.member_code.trim().length>0&&row.member_code.length<=80
  &&(row.member_name===null||(typeof row.member_name==='string'&&row.member_name.length<=200))
  &&isFundingReceiptPath(row.receipt_path)
  &&typeof row.payment_reference==='string'&&/^[A-Za-z0-9./_-]{6,80}$/.test(row.payment_reference)
  &&row.currency==='INR'
  &&typeof row.amount==='number'&&Number.isFinite(row.amount)&&row.amount>0&&row.amount<=10000000
  &&typeof row.created_at==='string'&&Number.isFinite(Date.parse(row.created_at))
  ;
}
export default function AdminWalletFundingReview(){
const client=supabase;
 const [rows,setRows]=useState<Row[]>([]),[urls,setUrls]=useState<Record<string,string>>({}),[receiptErrors,setReceiptErrors]=useState<Record<string,string>>({}),[note,setNote]=useState<Record<string,string>>({});
 const [busy,setBusy]=useState(''),[loading,setLoading]=useState(true),[loadingMore,setLoadingMore]=useState(false),[hasMore,setHasMore]=useState(false),[error,setError]=useState(''),[message,setMessage]=useState('');
 const requestSeq=useRef(0),reviewBusy=useRef(false),pageBusy=useRef(false),cursor=useRef<Cursor|null>(null),seenIds=useRef<Set<string>>(new Set());
 const load=useCallback(async(append=false)=>{
  if(append&&pageBusy.current)return;
  if(append)pageBusy.current=true;else pageBusy.current=false;
  const seq=++requestSeq.current;
  if(!client){pageBusy.current=false;setRows([]);setUrls({});setError('Supabase is not configured for this environment.');setLoading(false);setLoadingMore(false);return;}
  if(append){setLoadingMore(true);}else{cursor.current=null;seenIds.current=new Set();setRows([]);setUrls({});setReceiptErrors({});setHasMore(false);setLoading(true);}
  setError('');
  try{
   const{data,error:loadError}=await client.rpc('admin_list_pending_wallet_fund_requests_page',{
    p_limit:50,p_cursor_created_at:append?cursor.current?.created_at??null:null,p_cursor_id:append?cursor.current?.id??null:null
   });
   if(loadError)throw loadError;
   if(!data||typeof data!=='object'||!Array.isArray((data as Page).items)||typeof (data as Page).has_more!=='boolean')throw new Error('The wallet funding review page was invalid. Please retry.');
   const page=data as Page,items=page.items;
   if(items.length>50||!items.every(isRow))throw new Error('The wallet funding review page contains invalid records. Refresh and retry.');
   const pageIds=new Set<string>();
   for(const row of items){if(pageIds.has(row.id)||seenIds.current.has(row.id))throw new Error('Duplicate wallet funding request IDs were returned. Refresh the queue.');pageIds.add(row.id);}
   if(page.has_more&&(!items.length||typeof page.next_created_at!=='string'||!Number.isFinite(Date.parse(page.next_created_at))||typeof page.next_id!=='string'||!page.next_id.trim()))throw new Error('The wallet funding page cursor was invalid. Refresh and retry.');
   if(page.has_more){const last=items[items.length-1];if(page.next_created_at!==last.created_at||page.next_id!==last.id)throw new Error('The wallet funding page cursor does not match its final row. Refresh and retry.');const previous=append?cursor.current:null;if(previous&&(page.next_created_at<previous.created_at||(page.next_created_at===previous.created_at&&page.next_id<=previous.id)))throw new Error('The wallet funding page cursor did not advance. Refresh and retry.');}
   else if(page.next_created_at!==null||page.next_id!==null)throw new Error('The final wallet funding page unexpectedly included a continuation cursor. Refresh and retry.');
   if(seq!==requestSeq.current)return;
   const next:Record<string,string>={},failures:Record<string,string>={};
   await Promise.all(items.map(async row=>{
    const{data:signed,error:signedError}=await client.storage.from('wallet-funding-receipts').createSignedUrl(row.receipt_path,300);
    if(signedError||!signed?.signedUrl)failures[row.id]=signedError?.message||'Receipt link could not be created. Refresh and retry.';
    else next[row.id]=signed.signedUrl;
   }));
   if(seq!==requestSeq.current)return;
   items.forEach(row=>seenIds.current.add(row.id));
   setRows(current=>append?[...current,...items]:items);
   setUrls(current=>append?({...current,...next}):next);
   setReceiptErrors(current=>append?({...current,...failures}):failures);
   setHasMore(page.has_more);
   cursor.current=page.has_more?{created_at:page.next_created_at as string,id:page.next_id as string}:null;
   if(Object.keys(failures).length)setError('One or more receipts could not be opened. Refresh the queue before approving those requests.');
  }catch(e){if(seq===requestSeq.current)setError(e instanceof Error?e.message:'Wallet funding requests could not be loaded. Please retry.');}
  finally{if(seq===requestSeq.current){setLoading(false);setLoadingMore(false);if(append)pageBusy.current=false;}}
 },[]);
 useEffect(()=>{void load();return()=>{requestSeq.current++;};},[load]);
 async function review(id:string,approve:boolean){
  if(!client||reviewBusy.current)return;
  if(approve&&!urls[id]){setError('Open and verify the payment receipt before approving this request. Refresh the queue to retry the receipt link.');return;}
  reviewBusy.current=true;setBusy(id);setError('');setMessage('');
  try{
   const{data:reviewResult,error:reviewError}=await client.rpc('admin_review_wallet_fund_request',{p_request_id:id,p_approve:approve,p_review_note:note[id]??null});
   if(reviewError)throw reviewError;
   const result=reviewResult as Record<string,unknown>|null;if(!result||typeof result!=='object'||Array.isArray(result)||result.success!==true||result.status!==(approve?'approved':'rejected')||(approve&&(result.wallet_type!=='income'||typeof result.balance_after!=='number'||!Number.isFinite(result.balance_after)||result.balance_after<0)))throw new Error('The server returned a wallet funding review result that does not match this request. Refresh the queue before retrying.');
   setMessage(approve?'Payment approved. The amount has been credited to the member Income Wallet.':'Payment request rejected. No wallet credit was made.');
   await load();
  }catch(e){setError((e instanceof Error?e.message:'The request could not be reviewed. Please retry.').replace(/Main Wallet/gi,'Income Wallet'));}
  finally{reviewBusy.current=false;setBusy('');}
 }
 return <section className="adminModuleDetail" style={{marginTop:18}}>
  <h4>Income Wallet Add Money Reviews</h4><p>Check the UTR and payment receipt before approving. Approval credits the member Income Wallet and records the wallet ledger entry.</p>
  {error&&<div className="notice" role="alert">{error} <button type="button" className="outline small" onClick={()=>void load()} disabled={loading||loadingMore}>Retry</button></div>}
  {message&&<div className="notice" role="status">{message}</div>}
  {loading?<div className="empty">Loading pending Add Money requests…</div>:error&&!rows.length?null:rows.length===0?<div className="empty">No pending Add Money requests.</div>:<div className="referralList">{rows.map(row=><article key={row.id} style={{display:'flex',flexDirection:'column',gap:8,padding:14}}>
   <b>{row.member_code} · {row.member_name||'Member'}</b><strong>{money(Number(row.amount),row.currency||'INR')}</strong><small>UTR: {row.payment_reference}</small><small>Submitted: {new Date(row.created_at).toLocaleString('en-IN')}</small>
   {urls[row.id]?<a href={urls[row.id]} target="_blank" rel="noreferrer"><ExternalLink size={14}/> View payment receipt</a>:<small role="alert">{receiptErrors[row.id]||'Preparing secure receipt link…'}</small>}
   <label>Review note (optional)<input value={note[row.id]??''} maxLength={500} onChange={e=>setNote(v=>({...v,[row.id]:e.target.value}))}/></label>
   <div style={{display:'flex',gap:8,flexWrap:'wrap'}}><button type="button" className="primary small" disabled={busy!==''||!urls[row.id]} onClick={()=>void review(row.id,true)}>{busy===row.id?'Saving…':'Approve & Credit Income Wallet'}</button><button type="button" className="outline small" disabled={busy!==''} onClick={()=>void review(row.id,false)}>Reject</button></div>
  </article>)}</div>}
  {hasMore&&<button type="button" className="outline small" onClick={()=>void load(true)} disabled={loading||loadingMore||busy!==''}><RefreshCw size={14}/>{loadingMore?'Loading more…':'Load more requests'}</button>}
  <button type="button" className="outline small" onClick={()=>void load(false)} disabled={loading||loadingMore||busy!==''}><RefreshCw size={14}/> Refresh queue</button>
 </section>;
}
