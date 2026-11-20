import {useEffect,useRef,useState} from 'react';
import type {FormEvent} from 'react';
import {QrCode,Upload,RefreshCw,Clock3} from 'lucide-react';
import {supabase} from '../lib/supabase';
import {money} from '../lib/format';
type RequestRow={id:string;amount:number;currency:string;payment_reference:string;status:string;review_note:string|null;created_at:string;reviewed_at:string|null;has_more:boolean};
const PAGE_SIZE=50;
function validRequest(value:unknown):value is RequestRow{if(!value||typeof value!=='object'||Array.isArray(value))return false;const row=value as Record<string,unknown>;return typeof row.id==='string'&&row.id.trim().length>0&&typeof row.amount==='number'&&Number.isFinite(row.amount)&&row.amount>0&&typeof row.currency==='string'&&/^[A-Z]{3}$/.test(row.currency)&&typeof row.payment_reference==='string'&&row.payment_reference.trim().length>=6&&typeof row.status==='string'&&['pending','approved','rejected'].includes(row.status)&&(row.review_note===null||typeof row.review_note==='string')&&typeof row.created_at==='string'&&Number.isFinite(Date.parse(row.created_at))&&(row.reviewed_at===null||(typeof row.reviewed_at==='string'&&Number.isFinite(Date.parse(row.reviewed_at))))&&typeof row.has_more==='boolean';}
const WALLET_RECEIPT_CLEANUP_LIMIT=20;
function validWalletReceiptCleanupPath(value:unknown,userId:string):value is string{
 if(typeof value!=='string'||value.length>300||!value.startsWith(userId+'/wallet-funding/'))return false;
 const parts=value.split('/');
 return parts.length===3&&parts[0]===userId&&parts[1]==='wallet-funding'&&/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}-[a-z0-9._-]{1,90}$/i.test(parts[2]);
}
function readWalletReceiptCleanupQueue(userId:string):string[]{
 try{const raw=localStorage.getItem('biddworld.wallet-funding-cleanup.v1.'+userId);if(!raw)return [];const value:unknown=JSON.parse(raw);if(!Array.isArray(value))return [];return [...new Set(value.filter((path):path is string=>validWalletReceiptCleanupPath(path,userId)))].slice(0,WALLET_RECEIPT_CLEANUP_LIMIT);}catch{return [];}
}
function persistWalletReceiptCleanupPath(userId:string,path:string):boolean{
 if(!validWalletReceiptCleanupPath(path,userId))return false;
 try{const queue=readWalletReceiptCleanupQueue(userId);if(!queue.includes(path)&&queue.length>=WALLET_RECEIPT_CLEANUP_LIMIT)return false;localStorage.setItem('biddworld.wallet-funding-cleanup.v1.'+userId,JSON.stringify([...new Set([...queue,path])]));return true;}catch{return false;}
}
function clearWalletReceiptCleanupQueue(userId:string):void{try{localStorage.removeItem('biddworld.wallet-funding-cleanup.v1.'+userId);}catch{/* Retry on the next visit. */}}

export default function WalletFunding(){
 const [open,setOpen]=useState(false),[amount,setAmount]=useState(''),[utr,setUtr]=useState(''),[receipt,setReceipt]=useState<File|null>(null);
 const [busy,setBusy]=useState(false),[message,setMessage]=useState(''),[cleanupCount,setCleanupCount]=useState(0),[cleanupBusy,setCleanupBusy]=useState(false),[rows,setRows]=useState<RequestRow[]>([]),[historyLoading,setHistoryLoading]=useState(true),[historyError,setHistoryError]=useState(''),[userId,setUserId]=useState<string|null>(null),[historyLoadingMore,setHistoryLoadingMore]=useState(false),[historyHasMore,setHistoryHasMore]=useState(false);
 const inFlight=useRef(false),historyRequest=useRef(0),pageBusy=useRef(false),cleanupInFlight=useRef(false);
 useEffect(()=>{if(!supabase){setUserId(null);setHistoryLoading(false);return;}let active=true,authEventObserved=false;const{data:{subscription}}=supabase.auth.onAuthStateChange((_event,session)=>{authEventObserved=true;if(active)setUserId(session?.user?.id??null);});void supabase.auth.getUser().then(({data,error})=>{if(!active||authEventObserved)return;if(error)throw error;setUserId(data.user?.id??null);}).catch(()=>{if(active&&!authEventObserved){setUserId(null);setHistoryError('Your sign-in session could not be verified. Please sign in again.');setHistoryLoading(false);}});return()=>{active=false;subscription.unsubscribe();historyRequest.current++;};},[]);
 async function retryReceiptCleanup(ownerId:string){
  if(!supabase||cleanupInFlight.current)return;
  const paths=readWalletReceiptCleanupQueue(ownerId);setCleanupCount(paths.length);if(!paths.length)return;
  cleanupInFlight.current=true;setCleanupBusy(true);
  try{const{error}=await supabase.storage.from('wallet-funding-receipts').remove(paths);if(error)throw error;clearWalletReceiptCleanupQueue(ownerId);setCleanupCount(0);setMessage('Previously uploaded orphaned Add Money receipts were cleaned up successfully.');}
  catch(e){setCleanupCount(readWalletReceiptCleanupQueue(ownerId).length);setMessage('Some uploaded Add Money receipts still need cleanup: '+(e instanceof Error?e.message:'Storage cleanup failed. Please retry.'));}
  finally{cleanupInFlight.current=false;setCleanupBusy(false);}
 }
 async function load(reset=true){if(reset)pageBusy.current=false;if(!supabase||!userId){setRows([]);setHistoryHasMore(false);setHistoryLoading(false);setHistoryLoadingMore(false);return;}if(!reset&&pageBusy.current)return;if(!reset&&!rows.length)return;const seq=reset?++historyRequest.current:historyRequest.current;const cursor=reset?null:rows[rows.length-1];if(!reset&&!cursor)return;pageBusy.current=true;if(reset){setHistoryLoading(true);setRows([]);setHistoryHasMore(false);}else setHistoryLoadingMore(true);setHistoryError('');try{const{data,error}=await supabase.rpc('member_list_my_wallet_fund_requests_page',{p_limit:PAGE_SIZE,p_before_created_at:cursor?.created_at??null,p_before_id:cursor?.id??null});if(error)throw error;if(!Array.isArray(data)||data.length>PAGE_SIZE||!data.every(validRequest))throw new Error('The Add Money history returned an invalid page.');const page=data as RequestRow[];if(page.some(row=>row.has_more!==page[0]?.has_more))throw new Error('The Add Money history returned inconsistent pagination metadata. Refresh the list.');const known=new Set(reset?[]:rows.map(row=>row.id));for(const row of page){if(known.has(row.id))throw new Error('The Add Money history returned duplicate or overlapping requests. Refresh the list.');known.add(row.id);}if(seq===historyRequest.current){setRows(current=>reset?page:[...current,...page]);setHistoryHasMore(page.length===PAGE_SIZE&&page[page.length-1]?.has_more===true);}}catch(e){if(seq===historyRequest.current)setHistoryError(e instanceof Error?e.message:'Add Money requests could not be loaded. Please retry.');}finally{if(seq===historyRequest.current){pageBusy.current=false;setHistoryLoading(false);setHistoryLoadingMore(false);}}}
 useEffect(()=>{setRows([]);setHistoryError('');setHistoryHasMore(false);setHistoryLoading(Boolean(userId));if(userId)void retryReceiptCleanup(userId);void load(true);return()=>{historyRequest.current++;};},[userId]);
 async function submit(e:FormEvent){
  e.preventDefault();if(!supabase||busy||inFlight.current)return;
  const value=Number(amount),reference=utr.trim();
  if(!Number.isFinite(value)||value<=0||value>10000000||!/^\d+(?:\.\d{1,2})?$/.test(amount.trim())){setMessage('Enter a valid amount with up to two decimal places.');return;}
  if(!/^[A-Za-z0-9./_-]{6,80}$/.test(reference)){setMessage('Enter a valid UTR / payment reference (6–80 characters).');return;}
  if(!receipt){setMessage('Upload your payment screenshot or receipt.');return;}
  if(!['image/jpeg','image/png','application/pdf'].includes(receipt.type)||receipt.size>5*1024*1024){setMessage('Choose a JPG, PNG or PDF file up to 5 MB.');return;}
  inFlight.current=true;setBusy(true);setMessage('');let uploadedReceiptPath:string|null=null;let receiptOwnerId:string|null=null;let rpcAttempted=false;let rpcDefinitelyRejected=false;
  try{
   const{data:{user},error:userError}=await supabase.auth.getUser();if(userError||!user)throw new Error('Please sign in again.');receiptOwnerId=user.id;
   const safe=receipt.name.toLowerCase().replace(/[^a-z0-9._-]+/g,'-').slice(-80)||'receipt';
   const path=user.id+'/wallet-funding/'+crypto.randomUUID()+'-'+safe;
   const{error:uploadError}=await supabase.storage.from('wallet-funding-receipts').upload(path,receipt,{contentType:receipt.type,upsert:false});
   if(uploadError)throw uploadError;uploadedReceiptPath=path;
   rpcAttempted=true;const{data,error}=await supabase.rpc('member_submit_wallet_fund_request',{p_amount:value,p_payment_reference:reference,p_receipt_path:path});
   if(error){rpcDefinitelyRejected=typeof (error as {code?:unknown}).code==='string';throw error;}
   const result=data as Record<string,unknown>|null;if(!result||typeof result!=='object'||Array.isArray(result)||result.success!==true||typeof result.request_id!=='string'||!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(result.request_id)||result.status!=='pending')throw new Error('The server returned an invalid Add Money request result. The uploaded receipt is preserved; refresh your history before retrying.');
   setAmount('');setUtr('');setReceipt(null);
   const input=document.getElementById('wallet-funding-receipt') as HTMLInputElement|null;if(input)input.value='';
   setMessage('Request submitted. Your Income Wallet will be credited after Admin verifies the payment.');
   await load();
  }catch(err){const message=(err instanceof Error?err.message:'Your request could not be submitted. Please retry.').replace(/Main Wallet/gi,'Income Wallet');if(uploadedReceiptPath&&rpcAttempted&&rpcDefinitelyRejected){let cleanupFailed=false;try{const{error:cleanupError}=await supabase.storage.from('wallet-funding-receipts').remove([uploadedReceiptPath]);cleanupFailed=!!cleanupError;}catch{cleanupFailed=true;}if(cleanupFailed){const queued=!!receiptOwnerId&&persistWalletReceiptCleanupPath(receiptOwnerId,uploadedReceiptPath);if(queued)setCleanupCount(readWalletReceiptCleanupQueue(receiptOwnerId!).length);setMessage(queued?message+' The orphaned receipt was saved in a private retry queue. Use Retry receipt cleanup or revisit Add Money.':message+' Receipt cleanup could not be queued; please contact support.');}else setMessage(message);}else setMessage(message);}
  finally{inFlight.current=false;setBusy(false);}
 }
 return <section className="walletFunding">
  <button type="button" className="primary" onClick={()=>setOpen(v=>!v)}><QrCode size={17}/> {open?'Close Add Money':'Add Money'}</button>
  {open&&<div className="walletFundingPanel">
   <h5>Add Money to Income Wallet</h5><p>Scan this QR code with any UPI app, make your payment, then enter the UTR number and upload the payment receipt.</p>
   <div className="walletFundingQr"><img src="/payment/biddworld-main-wallet-qr.svg" alt="KRFSI UPI payment QR code"/><b>KRFSI</b><span>UPI ID: krindia@bpunity</span><small>Scan to pay with any UPI app</small></div>
   <form onSubmit={submit} className="memberWithdrawalForm">
    <label>Amount (INR)<input type="number" min="1" max="10000000" step="0.01" required value={amount} onChange={e=>setAmount(e.target.value)} placeholder="Enter amount"/></label>
    <label>UTR / Payment Reference<input required minLength={6} maxLength={80} value={utr} onChange={e=>setUtr(e.target.value)} placeholder="Enter UTR number"/></label>
    <label>Payment Screenshot / Receipt (JPG, PNG or PDF · Max 5 MB)<input id="wallet-funding-receipt" type="file" accept="image/jpeg,image/png,application/pdf" onChange={e=>setReceipt(e.target.files?.[0]??null)}/></label>
    <button type="submit" className="primary" disabled={busy}>{busy?'Submitting…':'Submit Payment for Review'}</button>
    {message&&<small role="status">{message}</small>}
    {cleanupCount>0&&<small role="status">{cleanupCount} orphaned receipt(s) await cleanup. <button type="button" className="outline small" disabled={cleanupBusy||!userId} onClick={()=>userId&&void retryReceiptCleanup(userId)}>{cleanupBusy?'Retrying…':'Retry receipt cleanup'}</button></small>}
   </form>
  </div>}
  <div className="walletFundingHistory"><h5><Clock3 size={16}/> Add Money Requests</h5>{historyLoading?<small>Loading Add Money requests…</small>:historyError?<small role="alert">{historyError} <button type="button" className="outline small" onClick={()=>void load()}>Retry requests</button></small>:rows.length?rows.map(row=><article key={row.id}><div><b>{money(Number(row.amount),row.currency||'INR')}</b><small>UTR: {row.payment_reference} · {new Date(row.created_at).toLocaleString('en-IN')}</small>{row.review_note&&<small>Admin note: {row.review_note}</small>}</div><strong className={row.status==='approved'?'memberActive':row.status==='rejected'?'memberStatus':''}>{row.status.toUpperCase()}</strong></article>):<small>No Add Money requests yet.</small>}{historyHasMore&&<button type="button" className="outline small" disabled={historyLoadingMore||historyLoading} onClick={()=>void load(false)}>{historyLoadingMore?'Loading more…':'Load more requests'}</button>}<button type="button" className="outline small" disabled={historyLoading||historyLoadingMore} onClick={()=>void load(true)}><RefreshCw size={14}/> Refresh requests</button></div>
 </section>;
}