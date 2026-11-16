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

// Fail closed: the owner has not approved the financial/legal model and the
// Production interlock migration has not been reconciled or applied.
const PACKAGE_ACTIVATION_LOCKED = true;

export default function Packages() {
  const [items, setItems] = useState<PackageItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
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
    {PACKAGE_ACTIVATION_LOCKED && <div className="notice" role="status"><ShieldCheck size={16}/> <b>Package activation is temporarily locked.</b> No payment references, activation requests or wallet credits can be submitted until the owner approves the financial and legal model and the database safeguards are independently verified.</div>}
    {loading ? <p className="packageState">Loading package information…</p> : error ? <div className="notice">{error} <button className="outline small" onClick={() => void load()}><RefreshCw size={14}/> Retry</button></div> :
      items.length === 0 ? <div className="empty packageEmpty">No packages are currently published. Free registration remains available.</div> :
      <div className="packageGrid">{items.map(item => <article className="packageCard" key={item.id}>
        <div className="category">BIDDWORLD MEMBERSHIP</div><h4>{item.name}</h4>
        <strong className="packagePrice">{money(Number(item.price), item.currency || 'INR')}</strong>
        <p>{item.description || 'Package benefits will be published after the owner-approved rules are finalized.'}</p>
        <div className="packageCredit"><span>Proposed Bid Wallet credit (not issued)</span><b>{money(Number(item.bid_wallet_credit), item.currency || 'INR')}</b></div>
        <div className="notice">Not accepting payments or activation requests. This package is informational only while financial approval is pending.</div>
      </article>)}</div>}
  </section>;
}
