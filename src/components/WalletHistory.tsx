import { useEffect, useState } from 'react';
import { History, RefreshCw } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { money } from '../lib/format';
import { csvDocument } from '../lib/csv';

type Tx={id:string;transaction_type:string;direction:string;amount:number;balance_after:number;description:string|null;created_at:string;wallet_account:{wallet_type:string;currency:string}[];};
export default function WalletHistory(){
 const [userId,setUserId]=useState<string|null>(null);
 const [rows,setRows]=useState<Tx[]>([]);
 const [loading,setLoading]=useState(true);
 const [error,setError]=useState('');
 const [kind,setKind]=useState('all');
 const [walletKind,setWalletKind]=useState('all');
 const [refresh,setRefresh]=useState(0);
 const [page,setPage]=useState(0);
 const [hasMore,setHasMore]=useState(false);
 const [loadingMore,setLoadingMore]=useState(false);

 useEffect(()=>{
  if(!supabase){setLoading(false);return;}
  let active=true;
  const {data:{subscription}}=supabase.auth.onAuthStateChange((_event,session)=>{
   if(active)setUserId(session?.user?.id??null);
  });
  void supabase.auth.getUser().then(({data:{user}})=>{if(active)setUserId(user?.id??null);});
  return()=>{active=false;subscription.unsubscribe();};
 },[]);

 useEffect(()=>{
  let active=true;
  if(page===0){setRows([]);setLoading(true);}else setLoadingMore(true);setError('');
  async function load(){
   if(!supabase||!userId){if(active)setLoading(false);return;}
   const {data:profile,error:pError}=await supabase.from('profiles').select('main_member_id').eq('id',userId).maybeSingle();
   if(!active)return;
   if(pError||!profile?.main_member_id){setError('Sign in with an account linked to a Main ID to view transactions.');setLoading(false);return;}
   const {data,error:qError}=await supabase.from('wallet_transactions').select('id,transaction_type,direction,amount,balance_after,description,created_at,wallet_account:wallet_accounts(wallet_type,currency)').eq('member_id',profile.main_member_id).order('created_at',{ascending:false}).order('id',{ascending:false}).range(page*100,page*100+99);
   if(!active)return;
   if(qError)setError('Transaction history is unavailable for this account.');
   else {const batch=(data??[]) as Tx[];setRows(current=>page===0?batch:[...current,...batch]);setHasMore(batch.length===100);}
   setLoading(false);setLoadingMore(false);
  }
  void load();return()=>{active=false;};
 },[userId,refresh,page]);

 const visible=rows.filter(r=>(kind==='all'||r.direction===kind)&&(walletKind==='all'||r.wallet_account?.[0]?.wallet_type===walletKind));
 function exportTransactions(){const data=[['Date','Wallet','Type','Direction','Amount','Currency','Balance After','Description'],...visible.map(r=>[r.created_at,r.wallet_account?.[0]?.wallet_type||'',r.transaction_type,r.direction,String(r.amount),r.wallet_account?.[0]?.currency||'INR',String(r.balance_after),r.description||''])];const csv=csvDocument(data);const url=URL.createObjectURL(new Blob([csv],{type:'text/csv;charset=utf-8'}));const a=document.createElement('a');a.href=url;a.download='biddworld-wallet-transactions.csv';document.body.appendChild(a);a.click();a.remove();URL.revokeObjectURL(url);}
 return <section className="walletHistory">
  <div className="packageIntro"><span className="workspaceIcon"><History/></span><div><h3>Wallet transaction history</h3><p>Transactions across your Main ID wallets, loaded 100 at a time. Filter by wallet or direction and export the visible rows.</p></div></div>
  <div className="historyToolbar"><label>Direction <select value={kind} onChange={e=>setKind(e.target.value)}><option value="all">All transactions</option><option value="credit">Credits</option><option value="debit">Debits</option></select></label><label>Wallet <select value={walletKind} onChange={e=>setWalletKind(e.target.value)}><option value="all">Both wallets</option><option value="bid">Bid Wallet</option><option value="income">Income Wallet</option></select></label><button className="outline small" onClick={()=>{setPage(0);setRefresh(v=>v+1)}}><RefreshCw size={14}/> Refresh</button><button className="outline small" onClick={exportTransactions} disabled={!visible.length}>Export CSV</button></div>
  {loading?<p className="packageState">Loading transactions…</p>:error?<div className="notice">{error}</div>:visible.length===0?<div className="empty">No wallet transactions found.</div>:
   <div className="transactionList">{visible.map(r=><article key={r.id}><div><b>{(r.transaction_type||'Transaction').replaceAll('_',' ')}</b><small>{r.description||'Wallet transaction'} · {new Date(r.created_at).toLocaleString()}</small></div><div className="transactionAmount"><b className={r.direction==='credit'?'credit':'debit'}>{r.direction==='credit'?'+':'−'}{money(Number(r.amount))}</b><small>Balance: {money(Number(r.balance_after))}</small></div></article>)}</div>}
  {!loading&&!error&&hasMore&&<button className="outline small" type="button" disabled={loadingMore} onClick={()=>setPage(current=>current+1)}>{loadingMore?"Loading…":"Load 100 more transactions"}</button>}
 </section>;
}
