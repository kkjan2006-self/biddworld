import { useEffect, useState } from 'react';
import { Gift, RefreshCw, Send } from 'lucide-react';
import { configured, supabase } from '../lib/supabase';
import { money } from '../lib/format';
import { normalizePaymentReference } from '../lib/payment-reference';

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
  const [references, setReferences] = useState<Record<string, string>>({});
  const [submitting, setSubmitting] = useState('');
  const [messages, setMessages] = useState<Record<string, string>>({});

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

  async function submitRequest(item: PackageItem) {
    if (!supabase) return;
    const reference = normalizePaymentReference(references[item.id] ?? '');
    if (!reference) {
      setMessages(current => ({ ...current, [item.id]: 'Enter a valid payment reference (6–80 letters or numbers).' }));
      return;
    }
    setSubmitting(item.id);
    setMessages(current => ({ ...current, [item.id]: '' }));
    try {
      const { data, error: requestError } = await supabase.rpc('submit_package_activation', {
        p_package_id: item.id,
        p_payment_reference: reference,
      });
      if (requestError) {
        setMessages(current => ({ ...current, [item.id]: requestError.message.includes('already been submitted')
          ? 'This payment reference has already been submitted.'
          : requestError.message.includes('Authentication')
            ? 'Please sign in before submitting an activation request.'
            : requestError.message }));
      } else {
        const result = data as { activation_number?: number; payment_status?: string } | null;
        setReferences(current => ({ ...current, [item.id]: '' }));
        setMessages(current => ({ ...current, [item.id]: `Request #${result?.activation_number ?? ''} submitted. Payment is pending administrator verification.` }));
      }
    } catch {
      setMessages(current => ({ ...current, [item.id]: 'Network error. Please try again.' }));
    } finally {
      setSubmitting('');
    }
  }

  return <section className="packageWorkspace">
    <div className="packageIntro"><span className="workspaceIcon"><Gift /></span>
      <div><h3>Membership packages</h3><p>Registration is free. Submit your payment reference for administrator verification.</p></div>
    </div>
    {!configured && <div className="notice"><b>Preview mode:</b> Connect the production database to view active packages.</div>}
    {loading ? <p className="packageState">Loading available packages…</p> : error ? <div className="notice">{error} <button className="outline small" onClick={() => void load()}><RefreshCw size={14}/> Retry</button></div> :
      items.length === 0 ? <div className="empty packageEmpty">No active packages are published yet. Please check again later.</div> :
      <div className="packageGrid">{items.map(item => <article className="packageCard" key={item.id}>
        <div className="category">BIDDWORLD MEMBERSHIP</div><h4>{item.name}</h4>
        <strong className="packagePrice">{money(Number(item.price), item.currency || 'INR')}</strong>
        <p>{item.description || 'Membership package benefits are subject to the published package rules.'}</p>
        <div className="packageCredit"><span>Bid Wallet credit after approval</span><b>{money(Number(item.bid_wallet_credit), item.currency || 'INR')}</b></div>
        <label htmlFor={`payment-reference-${item.id}`}>Payment reference / UTR</label>
        <input id={`payment-reference-${item.id}`} value={references[item.id] ?? ''} maxLength={80}
          onChange={event => setReferences(current => ({ ...current, [item.id]: event.target.value }))}
          placeholder="Enter your UTR or transaction reference" />
        <button className="primary small" disabled={!configured || submitting !== ''} onClick={() => void submitRequest(item)}>
          <Send size={14}/>{submitting === item.id ? 'Submitting…' : 'Submit activation request'}
        </button>
        {messages[item.id] && <div className="notice" role="status">{messages[item.id]}</div>}
        <small>Submitting a request does not activate the package or credit your Bid Wallet. Both remain pending until an administrator verifies the payment.</small>
      </article>)}</div>}
  </section>;
}
