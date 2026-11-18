import { useEffect, useRef, useState } from 'react';
import { Gift, RefreshCw, ShieldCheck } from 'lucide-react';
import { configured, supabase } from '../lib/supabase';
import { money } from '../lib/format';

type PackageItem = {
  id: string;
  name: string;
  description: string | null;
  price: number;
  currency: string;
  bid_wallet_credit: number;
};

// Keep package activation disabled until the owner enables the reviewed package workflow.
const PACKAGE_ACTIVATION_LOCKED = true;

export default function Packages() {
  const [items, setItems] = useState<PackageItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedPackage,setSelectedPackage]=useState('');
  const [paymentReference,setPaymentReference]=useState('');
  const [receiptFile,setReceiptFile]=useState<File|null>(null);
  const [activationBusy,setActivationBusy]=useState(false);
  const [activationMessage,setActivationMessage]=useState('');
  const mountedRef = useRef(false);
  const requestIdRef = useRef(0);

  async function load() {
    const requestId = ++requestIdRef.current;
    const isCurrent = () => mountedRef.current && requestIdRef.current === requestId;
    setLoading(true);
    setError('');
    if (!supabase) {
      if (isCurrent()) {
        setItems([]);
        setLoading(false);
      }
      return;
    }
    try {
      const { data, error: queryError } = await supabase
        .from('packages')
        .select('id,name,description,price,currency,bid_wallet_credit')
        .eq('is_active', true)
        .order('price', { ascending: true });
      if (!isCurrent()) return;
      if (queryError) {
        setItems([]);
        setError('Packages could not be loaded. Please try again later.');
      } else setItems((data ?? []) as PackageItem[]);
    } catch {
      if (!isCurrent()) return;
      setItems([]);
      setError('A network error prevented packages from loading. Please retry.');
    } finally {
      if (isCurrent()) setLoading(false);
    }
  }

  async function submitActivation(){
    if(!supabase||activationBusy)return;
    const reference=paymentReference.trim();
    if(!selectedPackage){setActivationMessage('Select a package.');return;}
    if(reference.length<6||reference.length>80||!/^[A-Za-z0-9./_-]+$/.test(reference)){setActivationMessage('Enter a valid payment reference (6 to 80 letters or numbers).');return;}
    if(receiptFile&&(!['image/jpeg','image/png','application/pdf'].includes(receiptFile.type)||receiptFile.size>5*1024*1024)){setActivationMessage('Receipt must be JPG, PNG or PDF and no larger than 5 MB.');return;}
    setActivationBusy(true);setActivationMessage('');
    try{
      const{data:authData,error:authError}=await supabase.auth.getUser();
      if(authError)throw authError;
      if(!authData.user){setActivationMessage('Please sign in before submitting a package activation request.');return;}
      let receiptPath:string|null=null;
      if(receiptFile){
        const safeName=receiptFile.name.toLowerCase().replace(/[^a-z0-9._-]+/g,'-').slice(-90)||'payment-receipt';
        receiptPath=authData.user.id+'/'+crypto.randomUUID()+'-'+safeName;
        const{error:uploadError}=await supabase.storage.from('package-receipts').upload(receiptPath,receiptFile,{contentType:receiptFile.type,upsert:false});
        if(uploadError)throw uploadError;
      }
      const{error}=await supabase.rpc('submit_package_activation_with_receipt',{p_package_id:selectedPackage,p_payment_reference:reference,p_receipt_path:receiptPath});
      if(error)throw error;
      setActivationMessage('Package activation request submitted for Admin verification.');
      setPaymentReference('');setReceiptFile(null);setSelectedPackage('');
    }catch(e){setActivationMessage(e instanceof Error?e.message:'Package activation request could not be completed. Check your connection and retry.');}
    finally{setActivationBusy(false);}
  }

  useEffect(() => {
    mountedRef.current = true;
    void load();
    return () => {
      mountedRef.current = false;
      requestIdRef.current += 1;
    };
  }, []);

  return <section className="packageWorkspace">
    <div className="packageIntro"><span className="workspaceIcon"><Gift /></span>
      <div><h3>Membership packages</h3><p>Free member registration is available. Paid package activation is not currently open.</p></div>
    </div>
    {!configured && <div className="notice"><b>Database not connected:</b> Configure the intended Preview or separate Test environment to view package information. Do not connect Production for testing.</div>}
    {PACKAGE_ACTIVATION_LOCKED && <div className="notice" role="status"><ShieldCheck size={16}/> <b>Package activation is temporarily locked.</b> Payment references, activation requests and wallet credits are unavailable while this feature remains disabled.</div>}
    {!PACKAGE_ACTIVATION_LOCKED&&<section className="packageActivationForm"><h3>Request Package Activation</h3><p>Select an available package and submit your payment reference. A receipt is optional.</p><label>Package<select value={selectedPackage} onChange={e=>setSelectedPackage(e.target.value)}><option value="">Select package</option>{items.map(item=><option key={item.id} value={item.id}>{item.name} · {money(Number(item.price),item.currency||'INR')}</option>)}</select></label><label>Payment Reference / UTR<input value={paymentReference} onChange={e=>setPaymentReference(e.target.value)} maxLength={80} placeholder="Enter payment reference"/></label><label>Payment Receipt (JPG, PNG or PDF · max 5 MB)<input type="file" accept="image/jpeg,image/png,application/pdf" onChange={e=>setReceiptFile(e.target.files?.[0]??null)}/></label><button type="button" className="primary" disabled={activationBusy||!selectedPackage} onClick={()=>void submitActivation()}>{activationBusy?'Submitting…':'Submit Activation Request'}</button>{activationMessage&&<div className="notice" role="status">{activationMessage}</div>}</section>}
    {loading ? <p className="packageState">Loading package information…</p> : error ? <div className="notice">{error} <button className="outline small" onClick={() => void load()}><RefreshCw size={14}/> Retry</button></div> :
      items.length === 0 ? <div className="empty packageEmpty">No packages are currently published. Free registration remains available.</div> :
      <div className="packageGrid">{items.map(item => <article className="packageCard" key={item.id}>
        <div className="category">BIDDWORLD MEMBERSHIP</div><h4>{item.name}</h4>
        <strong className="packagePrice">{money(Number(item.price), item.currency || 'INR')}</strong>
        <p>{item.description || 'Package benefits will be published after the owner-approved rules are finalized.'}</p>
        <div className="packageCredit"><span>Proposed Bid Wallet credit (not issued)</span><b>{money(Number(item.bid_wallet_credit), item.currency || 'INR')}</b></div>
        <div className="notice">View-only information. Package payments and activation are currently unavailable.</div>
      </article>)}</div>}
  </section>;
}
