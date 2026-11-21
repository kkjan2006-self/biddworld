import { useEffect, useRef, useState } from 'react';
import { Gift, RefreshCw, ShieldCheck } from 'lucide-react';
import { configured, supabase } from '../lib/supabase';
import { money } from '../lib/format';

const PACKAGE_PAGE_SIZE=100;
type PackageItem = {
  id: string;
  name: string;
  description: string | null;
  price: number;
  currency: string;
  bid_wallet_credit: number;
};
function parsePackageCatalogue(value:unknown):PackageItem[]{
  if(!Array.isArray(value)||value.length>100)throw new Error('Package catalogue response is invalid or exceeds the 100-item page limit.');
  const ids=new Set<string>();
  return value.map(raw=>{
    if(!raw||typeof raw!=='object'||Array.isArray(raw))throw new Error('Package catalogue contains a malformed record.');
    const row=raw as Record<string,unknown>;
    if(typeof row.id!=='string'||!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(row.id)||ids.has(row.id)
      ||typeof row.name!=='string'||!row.name.trim()||row.name.length>120
      ||(row.description!==null&&typeof row.description!=='string')
      ||typeof row.price!=='number'||!Number.isFinite(row.price)||row.price<0
      ||typeof row.currency!=='string'||!row.currency.trim()||row.currency.length>8
      ||typeof row.bid_wallet_credit!=='number'||!Number.isFinite(row.bid_wallet_credit)||row.bid_wallet_credit<0){
      throw new Error('Package catalogue contains invalid or duplicate package fields.');
    }
    ids.add(row.id);return row as unknown as PackageItem;
  });
}

function isPackageAfter(previous:PackageItem,current:PackageItem):boolean{
 return current.price>previous.price||(current.price===previous.price&&current.id.toLowerCase()>previous.id.toLowerCase());
}
function isStrictlyOrderedPackagePage(rows:PackageItem[]):boolean{
 for(let index=1;index<rows.length;index++)if(!isPackageAfter(rows[index-1],rows[index]))return false;
 return true;
}

const RECEIPT_CLEANUP_LIMIT=20;
function validReceiptCleanupPath(value:unknown,userId:string):value is string{
 if(typeof value!=='string'||value.length>300||!value.startsWith(userId+'/'))return false;
 const parts=value.split('/');
 return parts.length===2&&parts[0]===userId&&/^[a-f0-9]{32}-[a-z0-9._-]{1,110}$/i.test(parts[1]);
}
function readReceiptCleanupQueue(userId:string):string[]{
 try{
  const raw=localStorage.getItem('biddworld.package-receipt-cleanup.v1.'+userId);
  if(!raw)return [];
  const value:unknown=JSON.parse(raw);
  if(!Array.isArray(value))return [];
  return [...new Set(value.filter((path):path is string=>validReceiptCleanupPath(path,userId)))].slice(0,RECEIPT_CLEANUP_LIMIT);
 }catch{return [];}
}
function persistReceiptCleanupPath(userId:string,path:string):boolean{
 if(!validReceiptCleanupPath(path,userId))return false;
 try{
  const queue=readReceiptCleanupQueue(userId);
  if(!queue.includes(path)&&queue.length>=RECEIPT_CLEANUP_LIMIT)return false;
  localStorage.setItem('biddworld.package-receipt-cleanup.v1.'+userId,JSON.stringify([...new Set([...queue,path])]));
  return true;
 }catch{return false;}
}
function clearReceiptCleanupQueue(userId:string):void{
 try{localStorage.removeItem('biddworld.package-receipt-cleanup.v1.'+userId);}catch{/* Retry on the next visit if storage is unavailable. */}
}

export default function Packages() {
  const [items, setItems] = useState<PackageItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingMore,setLoadingMore]=useState(false);
  const [hasMore,setHasMore]=useState(false);
  const [activationEnabled,setActivationEnabled]=useState(false);
  const [error, setError] = useState('');
  const [selectedPackage,setSelectedPackage]=useState('');
  const [paymentReference,setPaymentReference]=useState('');
  const [receiptFile,setReceiptFile]=useState<File|null>(null);
  const [activationBusy,setActivationBusy]=useState(false);
  const [activationMessage,setActivationMessage]=useState('');
  const [receiptCleanupCount,setReceiptCleanupCount]=useState(0);
  const [receiptCleanupBusy,setReceiptCleanupBusy]=useState(false);
  const receiptCleanupInFlight=useRef(false);
  const mountedRef = useRef(false);
  const requestIdRef = useRef(0);
  const activationInFlight = useRef(false);
  const catalogueOffset=useRef(0);
  const cataloguePageBusy=useRef(false);

  async function retryReceiptCleanup(userId:string){
    if(!supabase||receiptCleanupInFlight.current)return;
    const paths=readReceiptCleanupQueue(userId);
    setReceiptCleanupCount(paths.length);
    if(!paths.length)return;
    receiptCleanupInFlight.current=true;setReceiptCleanupBusy(true);
    try{
      const{error:cleanupError}=await supabase.storage.from('package-receipts').remove(paths);
      if(cleanupError)throw cleanupError;
      clearReceiptCleanupQueue(userId);setReceiptCleanupCount(0);
      setActivationMessage('Previously uploaded orphaned receipt files were cleaned up successfully.');
    }catch(e){
      setReceiptCleanupCount(readReceiptCleanupQueue(userId).length);
      setActivationMessage('Some previously uploaded receipt files still need cleanup: '+(e instanceof Error?e.message:'Storage cleanup failed. Please retry.'));
    }finally{receiptCleanupInFlight.current=false;setReceiptCleanupBusy(false);}
  }

  async function load() {
    const requestId = ++requestIdRef.current;
    cataloguePageBusy.current=true;catalogueOffset.current=0;setHasMore(false);setLoadingMore(false);
    const isCurrent = () => mountedRef.current && requestIdRef.current === requestId;
    setLoading(true);
    setError('');
    if (!supabase) {
      if (isCurrent()) {
        setItems([]);
        setHasMore(false);cataloguePageBusy.current=false;
        setLoading(false);
      }
      return;
    }
    try {
      const { data, error: queryError } = await supabase.rpc('public_list_active_packages_page',{p_limit:PACKAGE_PAGE_SIZE,p_offset:0});
      if (!isCurrent()) return;
      if (queryError) {
        setItems([]);setHasMore(false);
        setError('Packages could not be loaded. Please try again later.');
      } else {
        const page=parsePackageCatalogue(data);
        if(!isStrictlyOrderedPackagePage(page))throw new Error('Package catalogue page is not in strict price/id order. Refresh and retry.');
        setItems(page);catalogueOffset.current=page.length;setHasMore(page.length===PACKAGE_PAGE_SIZE);
      }
      const {data:sessionData}=await supabase.auth.getSession();
      if(!isCurrent())return;
      if(!sessionData.session){setActivationEnabled(false);setReceiptCleanupCount(0);return;}
      await retryReceiptCleanup(sessionData.session.user.id);
      if(!isCurrent())return;
      const{data:activationSetting,error:activationSettingError}=await supabase.from('app_settings').select('setting_value').eq('setting_key','package_activations_enabled').maybeSingle();
      if(!isCurrent())return;
      setActivationEnabled(!activationSettingError&&activationSetting?.setting_value===true);
      if(activationSettingError)setError('Package activation availability could not be verified. Activation requests remain unavailable.');
    } catch (e) {
      if (!isCurrent()) return;
      setItems([]);setHasMore(false);
      setError(e instanceof Error&&e.message.startsWith('Package catalogue')?e.message:'A network error prevented packages from loading. Please retry.');
    } finally {
      if (isCurrent()){cataloguePageBusy.current=false;setLoading(false);}
    }
  }

  async function loadMorePackages(){
    if(!supabase||cataloguePageBusy.current||loading||loadingMore||!hasMore)return;
    cataloguePageBusy.current=true;setLoadingMore(true);setError('');
    const requestId=requestIdRef.current,offset=catalogueOffset.current;
    const isCurrent=()=>mountedRef.current&&requestIdRef.current===requestId;
    try{
      const{data,error:queryError}=await supabase.rpc('public_list_active_packages_page',{p_limit:PACKAGE_PAGE_SIZE,p_offset:offset});
      if(queryError)throw queryError;
      if(!isCurrent())return;
      const page=parsePackageCatalogue(data);
      if(!isStrictlyOrderedPackagePage(page))throw new Error('The next package catalogue page is not in strict price/id order. Refresh and retry.');
      const existing=new Set(items.map(item=>item.id));
      if(page.some(item=>existing.has(item.id)))throw new Error('The next package catalogue page overlaps previously loaded packages. Refresh the catalogue.');
      const previous=items[items.length-1];
      if(previous&&page.length&&!isPackageAfter(previous,page[0]))throw new Error('The next package catalogue page did not continue after the previous price/id cursor. Refresh and retry.');
      setItems(current=>[...current,...page]);
      catalogueOffset.current=offset+page.length;
      setHasMore(page.length===PACKAGE_PAGE_SIZE);
    }catch(e){if(isCurrent())setError(e instanceof Error?e.message:'More packages could not be loaded. Please retry.');}
    finally{if(isCurrent()){cataloguePageBusy.current=false;setLoadingMore(false);}}
  }

  async function submitActivation(){
    if(!supabase||activationBusy||activationInFlight.current)return;
    const reference=paymentReference.trim();
    if(!selectedPackage){setActivationMessage('Select a package.');return;}
    if(reference.length<6||reference.length>80||!/^[A-Za-z0-9./_-]+$/.test(reference)){setActivationMessage('Enter a valid payment reference (6 to 80 letters or numbers).');return;}
    if(!receiptFile){setActivationMessage('Upload your payment receipt before submitting the activation request.');return;}
    if(!['image/jpeg','image/png','application/pdf'].includes(receiptFile.type)||receiptFile.size>5*1024*1024){setActivationMessage('Receipt must be JPG, PNG or PDF and no larger than 5 MB.');return;}
    activationInFlight.current=true;setActivationBusy(true);setActivationMessage('');
    let uploadedReceiptPath:string|null=null;
    let receiptOwnerId:string|null=null;
    let activationSubmitted=false;
    let activationRpcAttempted=false;
    let activationRpcRejected=false;
    try{
      const{data:authData,error:authError}=await supabase.auth.getUser();
      if(authError)throw authError;
      if(!authData.user){setActivationMessage('Please sign in before submitting a package activation request.');return;}
      receiptOwnerId=authData.user.id;
      let receiptPath:string|null=null;
      if(receiptFile){
        const safeName=receiptFile.name.toLowerCase().replace(/[^a-z0-9._-]+/g,'-').slice(-90)||'payment-receipt';
        const bytes=new Uint8Array(16);window.crypto.getRandomValues(bytes);const fileId=Array.from(bytes,b=>b.toString(16).padStart(2,'0')).join('');receiptPath=authData.user.id+'/'+fileId+'-'+safeName;
        uploadedReceiptPath=receiptPath;
        const{error:uploadError}=await supabase.storage.from('package-receipts').upload(receiptPath,receiptFile,{contentType:receiptFile.type,upsert:false});
        if(uploadError)throw uploadError;
      }
      activationRpcAttempted=true;
      const{data:activationResult,error}=await supabase.rpc('submit_package_activation_with_receipt',{p_package_id:selectedPackage,p_payment_reference:reference,p_receipt_path:receiptPath});
      if(error){activationRpcRejected=typeof (error as {code?:unknown}).code==='string';throw error;}
      const result=activationResult as Record<string,unknown>|null;
      if(!result||typeof result!=='object'||Array.isArray(result)||result.success!==true||typeof result.activation_id!=='string'||!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(result.activation_id)||!Number.isInteger(result.activation_number)||Number(result.activation_number)<1||result.payment_status!=='pending'||result.activation_status!=='pending'||result.receipt_path!==receiptPath){
        throw new Error('The server response did not confirm the exact pending package activation and receipt. The request may already have been recorded; refresh your activation history before retrying.');
      }
      activationSubmitted=true;
      setActivationMessage('Package activation request submitted for Admin verification.');
      setPaymentReference('');setReceiptFile(null);setSelectedPackage('');const receiptInput=document.getElementById('package-activation-receipt') as HTMLInputElement|null;if(receiptInput)receiptInput.value='';
    }catch(e){
      const message=e instanceof Error?e.message:'Package activation request could not be completed. Check your connection and retry.';
      if(uploadedReceiptPath&&!activationSubmitted&&(!activationRpcAttempted||activationRpcRejected)){
        let cleanupFailed=false;
        try{
          const{error:cleanupError}=await supabase.storage.from('package-receipts').remove([uploadedReceiptPath]);
          cleanupFailed=!!cleanupError;
        }catch{cleanupFailed=true;}
        if(cleanupFailed){
          const queued=!!receiptOwnerId&&persistReceiptCleanupPath(receiptOwnerId,uploadedReceiptPath);
          if(queued)setReceiptCleanupCount(readReceiptCleanupQueue(receiptOwnerId!).length);
          setActivationMessage(queued?message+' The orphaned receipt was saved in a private retry queue. Use Retry receipt cleanup or revisit this page.':message+' Receipt cleanup could not be queued; please contact support.');
        }else setActivationMessage(message);
      }else setActivationMessage(message);
    }
    finally{activationInFlight.current=false;setActivationBusy(false);}
  }

  useEffect(() => {
    mountedRef.current = true;
    void load();
    return () => {
      mountedRef.current = false;
      requestIdRef.current += 1;
      cataloguePageBusy.current=false;
    };
  }, []);

  return <section className="packageWorkspace">
    <div className="packageIntro"><span className="workspaceIcon"><Gift /></span>
      <div><h3>Membership packages</h3><p>Free member registration is available. {activationEnabled?'Published packages are available for activation requests.':'Paid package activation is currently locked.'}</p></div>
    </div>
    {receiptCleanupCount>0&&<div className="notice" role="status">{receiptCleanupCount} uploaded receipt file(s) still need cleanup. <button className="outline small" type="button" disabled={receiptCleanupBusy} onClick={async()=>{const{data}=await supabase!.auth.getUser();if(data.user)await retryReceiptCleanup(data.user.id);}}>{receiptCleanupBusy?'Retrying…':'Retry receipt cleanup'}</button></div>}
    {!configured && <div className="notice"><b>Database not connected:</b> Configure the intended Preview or separate Test environment to view package information. Do not connect Production for testing.</div>}
    {!activationEnabled && <div className="notice" role="status"><ShieldCheck size={16}/> <b>Package activation is temporarily locked.</b> Payment references, activation requests and wallet credits are unavailable while this feature remains disabled.</div>}
    {activationEnabled&&<section className="packageActivationForm"><h3>Request Package Activation</h3><p>Select a package, scan the KRFSI UPI QR, pay the displayed package amount, then submit your UTR and payment receipt.</p><div className="walletFundingQr"><img src="/payment/biddworld-main-wallet-qr.svg" alt="KRFSI UPI payment QR code"/><b>Payee: KRFSI</b><span>UPI ID: krindia@bpunity</span><small>Scan with any UPI app. Enter the selected package amount before paying.</small></div><label>Package<select value={selectedPackage} onChange={e=>setSelectedPackage(e.target.value)}><option value="">Select package</option>{items.map(item=><option key={item.id} value={item.id}>{item.name} · {money(Number(item.price),item.currency||'INR')}</option>)}</select></label><label>Payment Reference / UTR<input value={paymentReference} onChange={e=>setPaymentReference(e.target.value)} maxLength={80} placeholder="Enter payment reference"/></label><label>Payment Screenshot / Receipt (JPG, PNG or PDF · max 5 MB)<input id="package-activation-receipt" type="file" required accept="image/jpeg,image/png,application/pdf" onChange={e=>setReceiptFile(e.target.files?.[0]??null)}/></label><button type="button" className="primary" disabled={activationBusy||!selectedPackage} onClick={()=>void submitActivation()}>{activationBusy?'Submitting…':'Submit Activation Request'}</button>{activationMessage&&<div className="notice" role="status">{activationMessage}</div>}</section>}
    {loading ? <p className="packageState">Loading package information…</p> : error ? <div className="notice">{error} <button className="outline small" onClick={() => void load()}><RefreshCw size={14}/> Retry</button></div> :
      items.length === 0 ? <div className="empty packageEmpty">No packages are currently published. Free registration remains available.</div> :
      <div className="packageGrid">{items.map(item => <article className="packageCard" key={item.id}>
        <div className="category">BIDDWORLD MEMBERSHIP</div><h4>{item.name}</h4>
        <strong className="packagePrice">{money(Number(item.price), item.currency || 'INR')}</strong>
        <p>{item.description || 'Package benefits will be published after the owner-approved rules are finalized.'}</p>
        <div className="packageCredit"><span>Proposed Bid Wallet credit (not issued)</span><b>{money(Number(item.bid_wallet_credit), item.currency || 'INR')}</b></div>
        <div className="notice">{activationEnabled?'Use the activation form above to submit payment details for Admin verification.':'View-only information. Package payments and activation are currently unavailable.'}</div>
      </article>)}</div>}
    {!loading&&!error&&hasMore&&<div style={{display:'flex',justifyContent:'center',padding:12}}><button type="button" className="outline small" onClick={()=>void loadMorePackages()} disabled={loadingMore}><RefreshCw size={14}/>{loadingMore?'Loading more packages…':'Load more packages'}</button></div>}
  </section>;
}
