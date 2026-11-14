import { useEffect, useState } from 'react';
import { History, RefreshCw } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { money } from '../lib/format';

type Tx={id:string;transaction_type:string;direction:string;amount:number;balance_after:number;description:string|null;created_at:string;};
export default function WalletHistory(){
 const [rows,setRows]=useState<Tx[]>([]),[loading,setLoading]=useState(true),[error,setError]=useState(''),[kind,setKind]=useState('all');
 async function load(){
  setLoading(true);setError('');
  if(!supabase){setRows([]);setLoading(false);return;}
  const {data:{user}}=await supabase.auth.getUser();
  if(!user){setRows([]);setLoading(false);return;}
  const {data:profile,error:pError}=await supabase.from('profiles').select('main_member_id').eq('id',user.id).maybeSingle();
  if(pError||!profile?.main_member_id){setError('Sign in to view wallet transactions.');setLoading(false);return;}
  const {data,error:qError}=await supabase.from('wallet_transactions').select('id,transaction_type,direction,amount,balance_after,description,created_at').eq('member_id',profile.main_member_id).order('created_at',{ascending:false}).limit(100);
  if(qError)setError('Transaction history is unavailable for this account.');
  else setRows((data??[]) as Tx[]);
  setLoading(false);
 }
 useEffect(()=>{void load()},[]);
 const visible=rows.filter(r=>kind==='all'||r.direction===kind);
 return <section className="walletHistory">
  <div className="packageIntro"><span className="workspaceIcon"><History/></span><div><h3>Wallet transaction history</h3><p>Latest 100 transactions across your Main ID wallets. Entries are read-only.</p></div></div>
  <div className="historyToolbar"><label>Show <select value={kind} onChange={e=>setKind(e.target.value)}><option value="all">All transactions</option><option value="credit">Credits</option><option value="debit">Debits</option></select></label><button className="outline small" onClick={()=>void load()}><RefreshCw size={14}/> Refresh</button></div>
  {loading?<p className="packageState">Loading transactions…</p>:error?<div className="notice">{error}</div>:visible.length===0?<div className="empty">No wallet transactions found.</div>:
   <div className="transactionList">{visible.map(r=><article key={r.id}><div><b>{(r.transaction_type||'Transaction').replaceAll('_',' ')}</b><small>{r.description||'Wallet transaction'} · {new Date(r.created_at).toLocaleString()}</small></div><div className="transactionAmount"><b className={r.direction==='credit'?'credit':'debit'}>{r.direction==='credit'?'+':'−'}{money(Number(r.amount))}</b><small>Balance: {money(Number(r.balance_after))}</small></div></article>)}</div>}
 </section>;
}