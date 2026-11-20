import { useEffect, useRef, useState } from 'react';
import { History, RefreshCw } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { money } from '../lib/format';
import { csvDocument } from '../lib/csv';

type Tx={id:string;transaction_type:string;direction:string;amount:number;balance_after:number;description:string|null;created_at:string;reference_type:string|null;reference_id:string|null;wallet_account:{wallet_type:'bid'|'income';currency:string}[];};
type MatrixSource={commission_id:string;source_member_code:string;source_id_type:string;level_number:number};
function validTransaction(value:unknown):value is Tx{
 if(!value||typeof value!=='object'||Array.isArray(value))return false;
 const row=value as Record<string,unknown>;
 if(typeof row.id!=='string'||!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(row.id)
  ||typeof row.transaction_type!=='string'||!row.transaction_type.trim()
  ||!['credit','debit'].includes(String(row.direction))
  ||typeof row.amount!=='number'||!Number.isFinite(row.amount)||row.amount<=0
  ||typeof row.balance_after!=='number'||!Number.isFinite(row.balance_after)||row.balance_after<0
  ||(row.description!==null&&typeof row.description!=='string')
  ||typeof row.created_at!=='string'||!Number.isFinite(Date.parse(row.created_at))
  ||(row.reference_type!==null&&typeof row.reference_type!=='string')
  ||(row.reference_id!==null&&typeof row.reference_id!=='string')
  ||!Array.isArray(row.wallet_account)||row.wallet_account.length!==1)return false;
 const wallet=row.wallet_account[0];if(!wallet||typeof wallet!=='object'||Array.isArray(wallet))return false;const walletRow=wallet as Record<string,unknown>;
 return ['bid','income'].includes(String(walletRow.wallet_type))&&typeof walletRow.currency==='string'&&/^[A-Z]{3}$/.test(walletRow.currency);
}
function isStrictlyDescendingWalletPage(rows:Tx[]):boolean{
 for(let index=1;index<rows.length;index++){
  const previous=rows[index-1],current=rows[index],previousTime=Date.parse(previous.created_at),currentTime=Date.parse(current.created_at);
  if(previousTime<currentTime||(previousTime===currentTime&&previous.id.toLowerCase()<=current.id.toLowerCase()))return false;
 }
 return true;
}
function isBeforeWalletCursor(row:Tx,cursor:{created_at:string;id:string}):boolean{
 const rowTime=Date.parse(row.created_at),cursorTime=Date.parse(cursor.created_at);
 return rowTime<cursorTime||(rowTime===cursorTime&&row.id.toLowerCase()<cursor.id.toLowerCase());
}
function validMatrixSource(value:unknown):value is MatrixSource{
 if(!value||typeof value!=='object'||Array.isArray(value))return false;
 const row=value as Record<string,unknown>;
 return typeof row.commission_id==='string'&&/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(row.commission_id)
  &&typeof row.source_member_code==='string'&&!!row.source_member_code.trim()
  &&['main','duplicate'].includes(String(row.source_id_type))
  &&Number.isInteger(row.level_number)&&Number(row.level_number)>=1&&Number(row.level_number)<=50;
}

export default function WalletHistory(){
 const [userId,setUserId]=useState<string|null>(null);
 const [rows,setRows]=useState<Tx[]>([]);
 const [matrixSources,setMatrixSources]=useState<Record<string,MatrixSource>>({});
 const [loading,setLoading]=useState(true);
 const [error,setError]=useState('');
 const [kind,setKind]=useState('all');
 const [walletKind,setWalletKind]=useState('all');
 const [transactionType,setTransactionType]=useState('all');
 const [search,setSearch]=useState('');
 const [dateFrom,setDateFrom]=useState('');
 const [dateTo,setDateTo]=useState('');
 const [refresh,setRefresh]=useState(0);
 const [page,setPage]=useState(0);
 const [hasMore,setHasMore]=useState(false);
 const [loadingMore,setLoadingMore]=useState(false);
 const [retryPage,setRetryPage]=useState<number|null>(null);
 const [retryRequest,setRetryRequest]=useState(0);
 const [exportBusy,setExportBusy]=useState(false);
 const [exportMessage,setExportMessage]=useState('');
 const loadMoreBusy=useRef(false),userScopeRef=useRef<string|null>(null),pageCursor=useRef<{created_at:string;id:string}|null>(null);

 useEffect(()=>{
  if(!supabase){setLoading(false);return;}
  let active=true;let authEventObserved=false;
  const applyUserScope=(nextUserId:string|null)=>{
   if(userScopeRef.current!==nextUserId){userScopeRef.current=nextUserId;pageCursor.current=null;setPage(0);setRetryPage(null);setRows([]);setMatrixSources({});setHasMore(false);setError('');}
   setUserId(nextUserId);
  };
  const {data:{subscription}}=supabase.auth.onAuthStateChange((_event,session)=>{
   authEventObserved=true;if(active)applyUserScope(session?.user?.id??null);
  });
  void supabase.auth.getUser().then(({data:{user},error})=>{if(active&&!authEventObserved){if(error)throw error;applyUserScope(user?.id??null);}}).catch(()=>{if(active&&!authEventObserved)setError('Your sign-in session could not be verified. Please sign in again.');});
  return()=>{active=false;subscription.unsubscribe();};
 },[]);

 useEffect(()=>{
  let active=true;
  if(page===0){loadMoreBusy.current=false;pageCursor.current=null;setRetryPage(null);}
  if(page===0){setRows([]);setLoading(true);}else setLoadingMore(true);setError('');
  async function load(){
   if(!supabase||!userId){if(active){loadMoreBusy.current=false;setLoading(false);setLoadingMore(false);}return;}
   try{
    const {data:profile,error:pError}=await supabase.from('profiles').select('main_member_id').eq('id',userId).maybeSingle();
    if(!active)return;
    if(pError||!profile?.main_member_id)throw new Error('Sign in with an account linked to a Main ID to view transactions.');
    let query=supabase.from('wallet_transactions').select('id,transaction_type,direction,amount,balance_after,description,created_at,reference_type,reference_id,wallet_account:wallet_accounts(wallet_type,currency)').eq('member_id',profile.main_member_id).order('created_at',{ascending:false}).order('id',{ascending:false});
    const cursor=pageCursor.current;
    if(page>0&&cursor)query=query.or(`created_at.lt.${cursor.created_at},and(created_at.eq.${cursor.created_at},id.lt.${cursor.id})`);
    const {data,error:qError}=await query.limit(100);
    if(!active)return;
    if(qError)throw qError;
    if(!Array.isArray(data)||data.length>100||!data.every(validTransaction))throw new Error('The wallet history response contains malformed or oversized transaction records. Refresh and retry.');
    const batch=data as Tx[];
    if(!isStrictlyDescendingWalletPage(batch))throw new Error('The wallet history page is not in strict descending (created_at,id) order. Refresh and retry.');
    if(page>0&&cursor&&batch.some(row=>!isBeforeWalletCursor(row,cursor!)))throw new Error('The wallet history page crossed or repeated its previous keyset cursor. Refresh before continuing.');
    const commissionIds=[...new Set(batch.filter(row=>row.reference_type==='matrix_commission'&&row.reference_id).map(row=>row.reference_id as string))];
    if(commissionIds.length){const {data:sourceRows,error:sourceError}=await supabase.rpc('member_get_my_matrix_commission_sources',{p_commission_ids:commissionIds});if(sourceError)throw new Error('Matrix commission source details could not be verified. Refresh and retry.');if(!Array.isArray(sourceRows)||sourceRows.length!==commissionIds.length||!sourceRows.every(validMatrixSource))throw new Error('Matrix commission source details were incomplete or malformed. Refresh and retry.');const mapped:Record<string,MatrixSource>={};for(const item of sourceRows as MatrixSource[]){if(!commissionIds.includes(item.commission_id)||mapped[item.commission_id])throw new Error('Matrix commission source response exceeded the requested transaction scope.');mapped[item.commission_id]=item;}if(!active)return;setMatrixSources(current=>({...current,...mapped}));}
    if(!active)return;
    const pageIds=new Set<string>(),knownIds=new Set(page===0?[]:rows.map(row=>row.id));
    for(const row of batch){
     if(!row||typeof row.id!=='string'||!row.id.trim()||typeof row.created_at!=='string'||!Number.isFinite(Date.parse(row.created_at)))throw new Error('The wallet history contains an invalid transaction record. Refresh before continuing.');
     if(pageIds.has(row.id)||knownIds.has(row.id))throw new Error('The wallet history returned duplicate transaction IDs. Refresh before loading more.');
     pageIds.add(row.id);
    }
    let added=batch.length;
    if(batch.length){const last=batch[batch.length-1];pageCursor.current={created_at:last.created_at,id:last.id};}
    setRows(current=>page===0?batch:[...current,...batch]);setHasMore(batch.length===100&&(page===0||added>0));setRetryPage(null);
   }catch(e){if(active){if(page>0)setRetryPage(page);setError(e instanceof Error?e.message:'Transaction history could not be loaded. Please retry.');}}
   finally{if(active){loadMoreBusy.current=false;setLoading(false);setLoadingMore(false);}}
  }
  void load();return()=>{active=false;};
 },[userId,refresh,page,retryRequest]);

 function loadNextPage(){if(loadMoreBusy.current||loading||(retryPage===null&&!hasMore))return;loadMoreBusy.current=true;if(retryPage!==null){setRetryRequest(current=>current+1);return;}setPage(current=>current+1);}

 const invalidDateRange=Boolean(dateFrom&&dateTo&&dateFrom>dateTo);
 const transactionTypes=[...new Set(rows.map(r=>r.transaction_type).filter(Boolean))].sort();
 const sourceFor=(r:Tx,sourceMap:Record<string,MatrixSource>=matrixSources)=>r.reference_type==='matrix_commission'&&r.reference_id?sourceMap[r.reference_id]:undefined;
 const matchesFilters=(r:Tx,sourceMap:Record<string,MatrixSource>=matrixSources)=>{const day=r.created_at.slice(0,10),q=search.trim().toLowerCase(),source=sourceFor(r,sourceMap);return (kind==='all'||r.direction===kind)&&(walletKind==='all'||r.wallet_account?.[0]?.wallet_type===walletKind)&&(transactionType==='all'||r.transaction_type===transactionType)&&(!dateFrom||day>=dateFrom)&&(!dateTo||day<=dateTo)&&(!q||[r.transaction_type,r.description??'',r.id,source?.source_member_code??'',source?.source_id_type??''].some(value=>value.toLowerCase().includes(q)));};
 const visible=invalidDateRange?[]:rows.filter(row=>matchesFilters(row));
 async function exportTransactions(){if(!supabase||!userId||exportBusy)return;setExportBusy(true);setExportMessage('');try{const {data:profile,error:pError}=await supabase.from('profiles').select('main_member_id').eq('id',userId).maybeSingle();if(pError||!profile?.main_member_id)throw new Error('Member wallet scope could not be confirmed.');const all:Tx[]=[];const exportSources:Record<string,MatrixSource>={};const seen=new Set<string>();let cursor:{created_at:string;id:string}|null=null;let pages=0;for(;;){pages+=1;if(pages>10000)throw new Error('The wallet statement exceeded the safe export limit. Narrow the date range and retry.');let query=supabase.from('wallet_transactions').select('id,transaction_type,direction,amount,balance_after,description,created_at,reference_type,reference_id,wallet_account:wallet_accounts(wallet_type,currency)').eq('member_id',profile.main_member_id).order('created_at',{ascending:false}).order('id',{ascending:false});if(cursor)query=query.or(`created_at.lt.${cursor.created_at},and(created_at.eq.${cursor.created_at},id.lt.${cursor.id})`);const {data,error}=await query.limit(500);if(error)throw error;if(!Array.isArray(data)||data.length>500||!data.every(validTransaction))throw new Error('The wallet statement returned malformed or oversized transaction records. Export stopped.');const batch=data as Tx[];if(!isStrictlyDescendingWalletPage(batch))throw new Error('The wallet statement page is not in strict descending (created_at,id) order. Export stopped.');if(cursor&&batch.some(row=>!isBeforeWalletCursor(row,cursor!)))throw new Error('The wallet statement page crossed or repeated its previous keyset cursor. Export stopped.');const ids=[...new Set(batch.filter(row=>row.reference_type==='matrix_commission'&&row.reference_id).map(row=>row.reference_id as string))];for(let offset=0;offset<ids.length;offset+=200){const chunk=ids.slice(offset,offset+200);const {data:sourceRows,error:sourceError}=await supabase.rpc('member_get_my_matrix_commission_sources',{p_commission_ids:chunk});if(sourceError)throw new Error('Matrix commission source details could not be verified for the full statement.');if(!Array.isArray(sourceRows)||sourceRows.length!==chunk.length||!sourceRows.every(validMatrixSource))throw new Error('Matrix source lookup returned incomplete or malformed export details.');for(const item of sourceRows as MatrixSource[]){if(!chunk.includes(item.commission_id)||exportSources[item.commission_id])throw new Error('Matrix source lookup exceeded the requested export scope.');exportSources[item.commission_id]=item;}}for(const row of batch){if(seen.has(row.id))throw new Error('The wallet statement returned duplicate transaction IDs. Export stopped to prevent an inaccurate CSV. Narrow the date range and retry.');seen.add(row.id);all.push(row);}if(batch.length<500)break;const last=batch[batch.length-1];cursor={created_at:last.created_at,id:last.id};}if(dateFrom&&dateTo&&dateFrom>dateTo)throw new Error('Start date must be on or before end date.');const matched=all.filter(row=>matchesFilters(row,exportSources));if(!matched.length){setExportMessage('No matching wallet transactions to export.');return;}const data=[['Date','Wallet','Type','Direction','Amount','Currency','Balance After','Description','Commission Source ID','Source ID Type','Matrix Level'],...matched.map(r=>{const source=sourceFor(r,exportSources);return [r.created_at,r.wallet_account?.[0]?.wallet_type||'',r.transaction_type,r.direction,String(r.amount),r.wallet_account?.[0]?.currency||'INR',String(r.balance_after),r.description||'',source?.source_member_code||'',source?.source_id_type||'',source?.level_number?String(source.level_number):''];})];const csv=csvDocument(data);const url=URL.createObjectURL(new Blob([csv],{type:'text/csv;charset=utf-8'}));const a=document.createElement('a');a.href=url;a.download='biddworld-complete-wallet-statement.csv';document.body.appendChild(a);a.click();a.remove();URL.revokeObjectURL(url);setExportMessage('Exported '+matched.length+' matching transactions.');}catch(e){setExportMessage(e instanceof Error?e.message:'Wallet statement export failed.');}finally{setExportBusy(false);}}
 return <section className="walletHistory">
  <div className="packageIntro"><span className="workspaceIcon"><History/></span><div><h3>Wallet transaction history</h3><p>Transactions across your Main ID wallets, loaded 100 at a time. Filter by wallet, direction, transaction type, description/reference or UTC date range. On-screen filters apply to loaded records; CSV export retrieves all matching records for your Main ID.</p></div></div>
  <div className="historyToolbar"><label>Search description / reference<input type="search" value={search} onChange={e=>setSearch(e.target.value)} placeholder="Search loaded transactions"/></label><label>Transaction type <select value={transactionType} onChange={e=>setTransactionType(e.target.value)}><option value="all">All types</option>{transactionTypes.map(type=><option key={type} value={type}>{type.replaceAll("_"," ")}</option>)}</select></label><label>Direction <select value={kind} onChange={e=>setKind(e.target.value)}><option value="all">All transactions</option><option value="credit">Credits</option><option value="debit">Debits</option></select></label><label>Wallet <select value={walletKind} onChange={e=>setWalletKind(e.target.value)}><option value="all">Both wallets</option><option value="bid">Bid Wallet</option><option value="income">Income Wallet</option></select></label><label>From date (UTC)<input type="date" value={dateFrom} max={dateTo||undefined} onChange={e=>setDateFrom(e.target.value)}/></label><label>To date (UTC)<input type="date" value={dateTo} min={dateFrom||undefined} onChange={e=>setDateTo(e.target.value)}/></label><button className="outline small" onClick={()=>{loadMoreBusy.current=false;setRetryPage(null);setPage(0);setRefresh(v=>v+1)}}><RefreshCw size={14}/> Refresh</button><button className="outline small" onClick={()=>void exportTransactions()} disabled={exportBusy||invalidDateRange}>{exportBusy?'Preparing…':'Export Full CSV'}</button>{(dateFrom||dateTo)&&<button className="outline small" type="button" onClick={()=>{setDateFrom('');setDateTo('')}}>Clear dates</button>}<button className="outline small" type="button" onClick={()=>{setSearch('');setTransactionType('all');setKind('all');setWalletKind('all');setDateFrom('');setDateTo('')}}>Clear filters</button><small>{visible.length} matching loaded records</small></div>{invalidDateRange&&<small role="alert">Start date must be on or before end date.</small>}{exportMessage&&<small role="status">{exportMessage}</small>}
  {loading?<p className="packageState">Loading transactions…</p>:error?<div className="notice" role="alert">{error} <button className="outline small" type="button" onClick={()=>{loadMoreBusy.current=false;setRetryPage(null);setPage(0);setRefresh(v=>v+1);}}>Retry transaction history</button></div>:visible.length===0?<div className="empty">No wallet transactions found.</div>:
   <div className="transactionList">{visible.map(r=><article key={r.id}><div><b>{(r.transaction_type||'Transaction').replaceAll('_',' ')}</b><small>{r.description||'Wallet transaction'} · {new Date(r.created_at).toLocaleString()}</small>{sourceFor(r)&&<small>Matrix source: {sourceFor(r)?.source_member_code} ({sourceFor(r)?.source_id_type==='duplicate'?'Duplicate ID':'Main ID'}) · Level {sourceFor(r)?.level_number} · credited to your Main ID</small>}</div><div className="transactionAmount"><b className={r.direction==='credit'?'credit':'debit'}>{r.direction==='credit'?'+':'−'}{money(Number(r.amount))}</b><small>Balance: {money(Number(r.balance_after))}</small></div></article>)}</div>}
  {!loading&&(hasMore||retryPage!==null)&&<button className="outline small" type="button" disabled={loadingMore} onClick={loadNextPage}>{loadingMore?"Loading…":retryPage!==null?"Retry failed page":"Load 100 more transactions"}</button>}
 </section>;
}
