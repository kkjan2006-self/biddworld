import {useEffect,useRef,useState} from 'react';
import {supabase} from '../lib/supabase';
import {csvDocument} from '../lib/csv';

type AuctionBidReportRow={
 bid_id:string;auction_id:string;auction_title:string;currency:string;member_code:string;
 member_name:string|null;bid_amount:number;bid_wallet_debit:number;income_wallet_debit:number;
 status:string;created_at:string;
};
type Filters={search:string;status:string;from:string;to:string};
function parseAuctionBidRows(value:unknown):AuctionBidReportRow[]{
 if(!Array.isArray(value)||value.length>PAGE_SIZE+1)throw new Error('Auction bid report page is invalid.');
 const ids=new Set<string>();
 return value.map(raw=>{if(!raw||typeof raw!=='object'||Array.isArray(raw))throw new Error('Auction bid report row is malformed.');const row=raw as Record<string,unknown>;
 if(typeof row.bid_id!=='string'||!row.bid_id.trim()||ids.has(row.bid_id)||typeof row.auction_id!=='string'||!row.auction_id.trim()||typeof row.auction_title!=='string'||!row.auction_title.trim()||typeof row.currency!=='string'||!row.currency.trim()||typeof row.member_code!=='string'||!row.member_code.trim()||(row.member_name!==null&&typeof row.member_name!=='string')||!Number.isFinite(Number(row.bid_amount))||Number(row.bid_amount)<=0||!Number.isFinite(Number(row.bid_wallet_debit))||Number(row.bid_wallet_debit)<0||!Number.isFinite(Number(row.income_wallet_debit))||Number(row.income_wallet_debit)<0||Number(row.bid_wallet_debit)+Number(row.income_wallet_debit)>Number(row.bid_amount)+0.000001||typeof row.status!=='string'||!row.status.trim()||typeof row.created_at!=='string'||!Number.isFinite(Date.parse(row.created_at)))throw new Error('Auction bid report contains malformed or duplicate records.');
 ids.add(row.bid_id);return row as unknown as AuctionBidReportRow;});
}
const PAGE_SIZE=100;
function isStrictlyDescendingAuctionBidPage(rows:AuctionBidReportRow[]):boolean{
 for(let index=1;index<rows.length;index++){
  const previous=rows[index-1],current=rows[index],previousTime=Date.parse(previous.created_at),currentTime=Date.parse(current.created_at);
  if(previousTime<currentTime||(previousTime===currentTime&&previous.bid_id.toLowerCase().localeCompare(current.bid_id.toLowerCase())<=0))return false;
 }
 return true;
}
function isBeforeAuctionBidCursor(row:AuctionBidReportRow,cursor:{created_at:string;id:string}):boolean{
 const rowTime=Date.parse(row.created_at),cursorTime=Date.parse(cursor.created_at);
 return rowTime<cursorTime||(rowTime===cursorTime&&row.bid_id.toLowerCase().localeCompare(cursor.id.toLowerCase())<0);
}
function boundary(date:string,end:boolean):string|null{
 if(!date)return null;
 const value=new Date(date+(end?'T23:59:59.999':'T00:00:00'));
 return Number.isNaN(value.getTime())?null:value.toISOString();
}
function money(value:number,currency:string):string{
 try{return new Intl.NumberFormat('en-IN',{style:'currency',currency:currency||'INR'}).format(Number(value||0));}
 catch{return '₹'+Number(value||0).toFixed(2);}
}
function appendUnique(current:AuctionBidReportRow[],next:AuctionBidReportRow[]):AuctionBidReportRow[]{
 const seen=new Set(current.map(row=>row.bid_id));
 return [...current,...next.filter(row=>!seen.has(row.bid_id))];
}
export default function AdminAuctionBidReport(){
 const [search,setSearch]=useState(''),[status,setStatus]=useState('all'),[from,setFrom]=useState(''),[to,setTo]=useState('');
 const [applied,setApplied]=useState<Filters>({search:'',status:'all',from:'',to:''});
 const [rows,setRows]=useState<AuctionBidReportRow[]>([]),[hasMore,setHasMore]=useState(false);
 const [loading,setLoading]=useState(false),[loadingMore,setLoadingMore]=useState(false),[exporting,setExporting]=useState(false),[error,setError]=useState('');
 const request=useRef(0),pageLock=useRef(false),cursorRef=useRef<{created_at:string;id:string}|null>(null);
 async function loadPage(reset:boolean,filters:Filters){
  if(!supabase){setError('Admin database connection is unavailable.');return;}
  if(!reset&&pageLock.current)return;
  if(reset){pageLock.current=false;cursorRef.current=null;}else pageLock.current=true;
  const requestId=++request.current,cursor=reset?null:cursorRef.current;
  if(reset){setLoading(true);setLoadingMore(false);}else setLoadingMore(true);
  setError('');
  try{
   const{data,error:rpcError}=await supabase.rpc('admin_list_auction_bids_cursor_page',{
    p_search:filters.search||null,p_status:filters.status==='all'?null:filters.status,
    p_from:boundary(filters.from,false),p_to:boundary(filters.to,true),
    p_limit:PAGE_SIZE+1,p_after_created_at:cursor?.created_at??null,p_after_id:cursor?.id??null
   });
   if(rpcError)throw rpcError;
   if(requestId!==request.current)return;
   if(!Array.isArray(data??[]))throw new Error('The auction bid report response was invalid. Refresh and retry.');
   const fetched=parseAuctionBidRows(data??[]);
   if(!isStrictlyDescendingAuctionBidPage(fetched))throw new Error('The Auction bid report page is not in strict descending (created_at,bid_id) order. Refresh and retry.');
   if(cursor&&fetched.some(row=>!isBeforeAuctionBidCursor(row,cursor)))throw new Error('The Auction bid report page crossed or repeated its previous keyset cursor. Refresh and retry.');
   const batch=fetched.slice(0,PAGE_SIZE),pageIds=new Set<string>(),knownIds=new Set(reset?[]:rows.map(row=>row.bid_id));
   for(const row of batch){

    if(pageIds.has(row.bid_id)||knownIds.has(row.bid_id))throw new Error('The auction bid report returned duplicate record IDs. Refresh before loading more.');
    pageIds.add(row.bid_id);
   }
   cursorRef.current=batch.length?{created_at:batch[batch.length-1].created_at,id:batch[batch.length-1].bid_id}:cursor;
   const added=batch.length;
   setRows(current=>reset?batch:appendUnique(current,batch));
   if(fetched.length>PAGE_SIZE&&added===0){
    setHasMore(false);
    setError('The auction bid report returned a repeated page. Refresh the report before loading more.');
   }else setHasMore(fetched.length>PAGE_SIZE);
  }catch(e){
   if(requestId===request.current)setError(e instanceof Error?e.message:'Auction bid report could not be loaded. Please retry.');
  }finally{
   if(requestId===request.current){setLoading(false);setLoadingMore(false);pageLock.current=false;}
  }
 }
 useEffect(()=>{
  void loadPage(true,{search:'',status:'all',from:'',to:''});
  return()=>{request.current+=1;};
 },[]);
 async function exportAll(){
  if(!supabase||exporting)return;
  if(applied.from&&applied.to&&applied.from>applied.to){setError('From date must be on or before To date. Apply a valid date range before exporting.');return;}
  setExporting(true);setError('');
  try{
   const all:AuctionBidReportRow[]=[];
   const seenIds=new Set<string>(),seenPages=new Set<string>();
   let cursor:{created_at:string;id:string}|null=null;
   for(let pages=0;;){
    pages+=1;
    if(pages>10000)throw new Error('The report exceeds the safe export limit.');
    const{data,error:rpcError}=await supabase.rpc('admin_list_auction_bids_cursor_page',{
     p_search:applied.search||null,p_status:applied.status==='all'?null:applied.status,
     p_from:boundary(applied.from,false),p_to:boundary(applied.to,true),
     p_limit:PAGE_SIZE,p_after_created_at:cursor?.created_at??null,p_after_id:cursor?.id??null
    });
    if(rpcError)throw rpcError;
    if(!Array.isArray(data??[]))throw new Error('The report response was invalid. Export stopped. Please retry.');
    const batch=parseAuctionBidRows(data??[]);
    if(!isStrictlyDescendingAuctionBidPage(batch))throw new Error('The Auction bid export page is not in strict descending (created_at,bid_id) order. Export stopped.');
    if(cursor&&batch.some(row=>!isBeforeAuctionBidCursor(row,cursor!)))throw new Error('The Auction bid export page crossed or repeated its previous keyset cursor. Export stopped.');
    if(batch.length===PAGE_SIZE){
     const fingerprint=JSON.stringify(batch.map(row=>row.bid_id));
     if(seenPages.has(fingerprint))throw new Error('The report repeated a page. Export stopped to avoid duplicate or incomplete records. Please retry.');
     seenPages.add(fingerprint);
    }
    for(const row of batch){

     if(seenIds.has(row.bid_id))throw new Error('The report returned duplicate records. Export stopped to avoid an inaccurate CSV. Please retry.');
     seenIds.add(row.bid_id);all.push(row);
    }
    if(batch.length<PAGE_SIZE)break;
    cursor={created_at:batch[batch.length-1].created_at,id:batch[batch.length-1].bid_id};
   }
   const csv=csvDocument([
    ['Bid ID','Auction ID','Auction','Member Main ID','Member Name','Bid Amount','Currency','Bid Wallet Debit','Income Wallet Debit','Status','Created At'],
    ...all.map(row=>[row.bid_id,row.auction_id,row.auction_title,row.member_code,row.member_name||'',row.bid_amount,row.currency,row.bid_wallet_debit,row.income_wallet_debit,row.status,row.created_at])
   ]);
   const url=URL.createObjectURL(new Blob([csv],{type:'text/csv;charset=utf-8;'}));
   const anchor=document.createElement('a');anchor.href=url;anchor.download='biddworld-auction-bids-complete.csv';
   document.body.appendChild(anchor);anchor.click();anchor.remove();URL.revokeObjectURL(url);
  }catch(e){setError(e instanceof Error?e.message:'Auction bid CSV export failed. Please retry.');}
  finally{setExporting(false);}
 }
 function applyFilters(){if(from&&to&&from>to){setError('From date must be on or before To date.');return;}const filters={search:search.trim(),status,from,to};setApplied(filters);void loadPage(true,filters);}
 return <section className="sponsorAdmin">
  <h4>6. Auction Bid History</h4>
  <p>Complete Admin-only bid history with server-side search, status/date filters and paginated CSV export. Idempotency keys are never exposed.</p>
  <div className="sponsorAdminForm">
   <input type="search" value={search} onChange={e=>setSearch(e.target.value)} placeholder="Auction, Main ID or member name"/>
   <select value={status} onChange={e=>setStatus(e.target.value)}><option value="all">All statuses</option><option value="accepted">Accepted</option><option value="voided">Voided</option><option value="cancelled">Cancelled</option><option value="rejected">Rejected</option></select>
   <label>From <input type="date" value={from} onChange={e=>setFrom(e.target.value)}/></label>
   <label>To <input type="date" value={to} onChange={e=>setTo(e.target.value)}/></label>
   <button className="secondary small" onClick={applyFilters} disabled={loading||Boolean(from&&to&&from>to)}>Apply filters</button>
   <button className="secondary small" onClick={()=>void exportAll()} disabled={exporting||Boolean(applied.from&&applied.to&&applied.from>applied.to)}>{exporting?'Preparing CSV…':'Export Complete Auction Bids CSV'}</button>
  </div>
  {error&&<p role="alert">{error} <button className="secondary small" onClick={()=>void loadPage(true,applied)}>Retry</button></p>}
  {loading?<p>Loading auction bid history…</p>:rows.length===0?<p>No auction bids match these filters.</p>:
   <div className="referralList">{rows.map(row=><div className="referralRow" key={row.bid_id}>
    <div><b>{row.auction_title}</b><small>{row.member_code} · {row.member_name||'Member'} · {new Date(row.created_at).toLocaleString()}</small></div>
    <div><b>{money(row.bid_amount,row.currency)}</b><small>{row.status}</small></div>
    <small>Bid Wallet {money(row.bid_wallet_debit,row.currency)} · Income Wallet {money(row.income_wallet_debit,row.currency)}</small>
   </div>)}</div>}
  <div className="sponsorAdminForm"><small>{rows.length} bid records loaded</small>
   {hasMore&&<button className="secondary small" onClick={()=>void loadPage(false,applied)} disabled={loadingMore}>{loadingMore?'Loading…':'Load more bids'}</button>}
  </div>
 </section>;
}
