import { useEffect, useState } from 'react';
import { Gift, RefreshCw } from 'lucide-react';
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

export default function Packages() {
  const [items, setItems] = useState<PackageItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  async function load() {
    setLoading(true);
    setError('');
    if (!supabase) {
      setItems([]);
      setLoading(false);
      return;
    }
    try {
      const { data, error: queryError } = await supabase
        .from('packages')
        .select('id,name,description,price,currency,bid_wallet_credit')
        .eq('is_active', true)
        .order('price', { ascending: true });
      if (queryError) setError('Packages could not be loaded. Please try again later.');
      else setItems((data ?? []) as PackageItem[]);
    } catch {
      setItems([]);
      setError('A network error prevented packages from loading. Please retry.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { void load(); }, []);

  return <section className="packageWorkspace">
    <div className="packageIntro"><span className="workspaceIcon"><Gift /></span>
      <div><h3>Membership packages</h3><p>Registration is free. Package activation is a separate, admin-verified process.</p></div>
    </div>
    {!configured && <div className="notice"><b>Preview mode:</b> Connect the production database to view active packages.</div>}
    {loading ? <p className="packageState">Loading available packages…</p> : error ? <div className="notice">{error} <button className="outline small" onClick={() => void load()}><RefreshCw size={14}/> Retry</button></div> :
      items.length === 0 ? <div className="empty packageEmpty">No active packages are published yet. Please check again later.</div> :
      <div className="packageGrid">{items.map(item => <article className="packageCard" key={item.id}>
        <div className="category">BIDDWORLD MEMBERSHIP</div><h4>{item.name}</h4>
        <strong className="packagePrice">{money(Number(item.price), item.currency || 'INR')}</strong>
        <p>{item.description || 'Membership package benefits are subject to the published package rules.'}</p>
        <div className="packageCredit"><span>Bid Wallet credit</span><b>{money(Number(item.bid_wallet_credit), item.currency || 'INR')}</b></div>
        <small>Activation requires payment reference submission and administrator verification.</small>
      </article>)}</div>}
  </section>;
}
