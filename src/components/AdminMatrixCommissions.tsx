import {useCallback,useEffect,useMemo,useRef,useState} from 'react';
import {ArrowDownToLine,CheckCircle,RefreshCw,RotateCcw,Search} from 'lucide-react';
import {supabase} from '../lib/supabase';
import {csvDocument} from '../lib/csv';

type MatrixCommissionRow={
 commission_id:string;activation_id:string;activated_member_code:string;
 level_number:number;source_member_code:string;source_id_type:string;
 credited_main_member_code:string;credited_main_name:string|null;
 amount:number;status:'pending'|'credited'|'reversed';created_at:string;has_more?:boolean;
};
const PAGE_SIZE=100;
type MatrixSummary={total_count:number;total_amount:number;pending_count:number;pending_amount:number;credited_count:number;credited_amount:number;reversed_count:number;reversed_amount:number};
const emptySummary:MatrixSummary={total_count:0,total_amount:0,pending_count:0,pending_amount:0,credited_count:0,credited_amount:0,reversed_count:0,reversed_amount:0};
function validSummary(value:unknown):value is MatrixSummary{if(!value||typeof value!=='object'||Array.isArray(value))return false;const row=value as Record<string,unknown>;if(!Object.keys(emptySummary).every(key=>typeof row[key]==='number'&&Number.isFinite(row[key])&&Number(row[key])>=0))return false;const counts=['total_count','pending_count','credited_count','reversed_count'];if(!counts.every(key=>Number.isSafeInteger(row[key])))return false;return Number(row.total_count)===Number(row.pending_count)+Number(row.credited_count)+Number(row.reversed_count)&&Math.abs(Number(row.total_amount)-(Number(row.pending_amount)+Number(row.credited_amount)+Number(row.reversed_amount)))<0.01;}
const formatINR=(value:number)=>'₹'+Number(value).toLocaleString('en-IN',{minimumFractionDigits:2,maximumFractionDigits:2});
const validStatuses=['pending','credited','reversed'] as const;
function validRow(value:unknown):value is MatrixCommissionRow{
 if(!value||typeof value!=='object')return false;
 const r=value as Record<string,unknown>;
 const uuid=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
 return typeof r.commission_id==='string'&&uuid.test(r.commission_id)
  &&typeof r.activation_id==='string'&&uuid.test(r.activation_id)
  &&typeof r.activated_member_code==='string'&&r.activated_member_code.trim().length>0
  &&Number.isInteger(r.level_number)&&Number(r.level_number)>=1&&Number(r.level_number)<=50
  &&typeof r.source_member_code==='string'&&r.source_member_code.length>0
  &&typeof r.source_id_type==='string'&&['main','duplicate'].includes(r.source_id_type)
  &&typeof r.credited_main_member_code==='string'&&r.credited_main_member_code.length>0
  &&(r.credited_main_name===null||typeof r.credited_main_name==='string')
  &&typeof r.amount==='number'&&Number.isFinite(r.amount)&&r.amount>0
  &&typeof r.status==='string'&&(validStatuses as readonly string[]).includes(r.status)
  &&typeof r.created_at==='string'&&Number.isFinite(Date.parse(r.created_at))&&typeof r.has_more==='boolean';
}
export default function AdminMatrixCommissions(){
 const [rows,setRows]=useState<MatrixCommissionRow[]>([]);
 const [status,setStatus]=useState('all'),[level,setLevel]=useState('all'),[search,setSearch]=useState('');
 const [loading,setLoading]=useState(false),[more,setMore]=useState(false),[hasMore,setHasMore]=useState(false),[reloadToken,setReloadToken]=useState(0);
  const reportRequest=useRef(0),loadMoreBusy=useRef(false);
 const [message,setMessage]=useState(''),[exportBusy,setExportBusy]=useState(false),[actionBusy,setActionBusy]=useState('');
 const [summary,setSummary]=useState<MatrixSummary>(emptySummary),[summaryLoading,setSummaryLoading]=useState(true),[summaryError,setSummaryError]=useState('');
 const loadSummary=useCallback(async()=>{if(!supabase){setSummaryError('Supabase is not configured.');setSummaryLoading(false);return;}setSummaryLoading(true);setSummaryError('');try{const {data,error}=await supabase.rpc('admin_get_matrix_commission_summary');if(error)throw error;if(!validSummary(data))throw new Error('The Matrix summary response was invalid.');setSummary(data);}catch(e){setSummaryError(e instanceof Error?e.message:'Could not load the overall Matrix summary.');}finally{setSummaryLoading(false);}},[]);
 useEffect(()=>{void loadSummary();},[loadSummary]);
 const fetchPage=useCallback(async(offset:number,filterStatus:string,filterLevel:string)=>{
  if(!supabase)throw new Error('Supabase is not configured for this environment.');
  const {data,error}=await supabase.rpc('admin_list_matrix_commissions_page',{
   p_limit:PAGE_SIZE,p_offset:offset,p_status:filterStatus==='all'?null:filterStatus,
   p_level:filterLevel==='all'?null:Number(filterLevel)
  });
  if(error)throw error;
  if(!Array.isArray(data)||data.length>PAGE_SIZE||!data.every(validRow))throw new Error('The Matrix commission report returned an invalid or oversized page. Refresh before continuing.');
  if(data.length&&data.some(row=>row.has_more!==data[0].has_more))throw new Error('The Matrix commission page returned inconsistent continuation metadata. Refresh the report.');
  if(data.length<PAGE_SIZE&&data.some(row=>row.has_more))throw new Error('The Matrix commission page returned an invalid continuation flag. Refresh the report.');
  const ids=new Set<string>();
  for(const row of data as MatrixCommissionRow[]){if(ids.has(row.commission_id))throw new Error('The Matrix report returned duplicate commission IDs.');ids.add(row.commission_id);}
  return data as MatrixCommissionRow[];
 },[]);
 useEffect(()=>{
  const request=++reportRequest.current;
  let active=true;
  setRows([]);setHasMore(false);setLoading(true);setMore(false);setMessage('');
  void fetchPage(0,status,level).then(batch=>{
   if(!active||request!==reportRequest.current)return;
   setRows(batch);
   setHasMore(batch.length===PAGE_SIZE&&batch[batch.length-1]?.has_more===true);
  }).catch(e=>{
   if(active&&request===reportRequest.current)setMessage(e instanceof Error?e.message:'Could not load Matrix commission report.');
  }).finally(()=>{
   if(active&&request===reportRequest.current)setLoading(false);
  });
  return ()=>{active=false;};
 },[fetchPage,status,level,reloadToken]);
 async function loadMore(){
  if(loadMoreBusy.current||loading||more||!hasMore)return;
  loadMoreBusy.current=true;setMore(true);setMessage('');
  const request=reportRequest.current;
  try{
   const batch=await fetchPage(rows.length,status,level);
   if(request!==reportRequest.current)return;
   const known=new Set(rows.map(r=>r.commission_id));
   if(batch.some(r=>known.has(r.commission_id)))throw new Error('The next Matrix report page overlaps records already loaded. Refresh the report.');
   setRows(current=>[...current,...batch]);
   setHasMore(batch.length===PAGE_SIZE&&batch[batch.length-1]?.has_more===true);
  }catch(e){
   if(request===reportRequest.current)setMessage(e instanceof Error?e.message:'Could not load Matrix commission report.');
  }finally{
   loadMoreBusy.current=false;
   if(request===reportRequest.current)setMore(false);
  }
 }
const filtered=useMemo(()=>{
  const q=search.trim().toLowerCase();
  return rows.filter(r=>!q||[r.commission_id,r.activation_id,r.activated_member_code,r.source_member_code,r.source_id_type,r.credited_main_member_code,r.credited_main_name].filter(Boolean).join(' ').toLowerCase().includes(q));
 },[rows,search]);
 async function exportAll(){
  if(exportBusy)return;setExportBusy(true);setMessage('');
  try{
   const all:MatrixCommissionRow[]=[];const ids=new Set<string>();
   for(let offset=0;offset<100000;offset+=PAGE_SIZE){
    const batch=await fetchPage(offset,status,level);
    if(!batch.length)break;
    for(const row of batch){if(ids.has(row.commission_id))throw new Error('Duplicate report rows detected. Export stopped.');ids.add(row.commission_id);all.push(row);}
    if(all.length>=100000)throw new Error('Export safety limit reached (100,000 rows). Narrow the filters and retry.');
    if(batch.length<PAGE_SIZE||batch[batch.length-1]?.has_more!==true)break;
   }
   const q=search.trim().toLowerCase();
   const selected=all.filter(r=>!q||[r.commission_id,r.activation_id,r.activated_member_code,r.source_member_code,r.source_id_type,r.credited_main_member_code,r.credited_main_name].filter(Boolean).join(' ').toLowerCase().includes(q));
   if(!selected.length){setMessage('No Matrix commission records match the current filters.');return;}
   const records=[
    ['Commission ID','Activation ID','Activated Member Main ID','Level','Source ID','Source ID Type','Credited Main ID','Credited Main Name','Amount','Status','Created At'],
    ...selected.map(r=>[r.commission_id,r.activation_id,r.activated_member_code,r.level_number,r.source_member_code,r.source_id_type,r.credited_main_member_code,r.credited_main_name,r.amount,r.status,r.created_at])
   ];
   const blob=new Blob([csvDocument(records)],{type:'text/csv;charset=utf-8;'});
   const url=URL.createObjectURL(blob);const a=document.createElement('a');a.href=url;a.download='biddworld-matrix-commissions-complete.csv';a.click();URL.revokeObjectURL(url);
   setMessage('Exported '+selected.length+' Matrix commission records.');
  }catch(e){setMessage(e instanceof Error?e.message:'Could not export Matrix commissions.');}
  finally{setExportBusy(false);}
 }
 async function postActivation(activationId:string){
  if(!supabase||actionBusy)return;
  if(!window.confirm('Post all pending Matrix commissions for this package activation to eligible Main ID Income Wallets?'))return;
  setActionBusy(activationId);setMessage('');
  try{const{data,error}=await supabase.rpc('admin_post_matrix_commissions',{p_activation_id:activationId});if(error)throw error;if(!data||typeof data!=='object'||Array.isArray(data))throw new Error('The server returned an invalid Matrix commission posting result. Refresh the register before retrying.');const result=data as {success?:unknown;activation_id?:unknown;posted_count?:unknown};if(result.success!==true||result.activation_id!==activationId||typeof result.posted_count!=='number'||!Number.isInteger(result.posted_count)||result.posted_count<0)throw new Error('The Matrix commission posting result did not match this activation. Refresh the register to confirm its recorded state.');setMessage('Posted '+result.posted_count+' Matrix commission(s).');setReloadToken(value=>value+1);await loadSummary();}
  catch(e){setMessage(e instanceof Error?e.message:'Matrix commissions could not be posted.');}
  finally{setActionBusy('');}
 }
 async function reverseCommission(commissionId:string){
  if(!supabase||actionBusy)return;
  const reason=window.prompt('Enter the reason for reversing this Matrix commission (at least 5 characters):');
  if(reason===null)return;
  if(reason.trim().length<5){setMessage('Enter a reversal reason of at least 5 characters.');return;}
  if(!window.confirm('Reverse this Matrix commission and its matching Income Wallet ledger credit?'))return;
  setActionBusy(commissionId);setMessage('');
  try{const{data,error}=await supabase.rpc('admin_reverse_matrix_commission',{p_commission_id:commissionId,p_reason:reason.trim()});if(error)throw error;if(!data||typeof data!=='object'||Array.isArray(data))throw new Error('The server returned an invalid Matrix commission reversal result. Refresh the register before retrying.');const result=data as {success?:unknown;commission_id?:unknown;status?:unknown;replayed?:unknown};const replayMatches=result.replayed===true?(result.commission_id===undefined||result.commission_id===commissionId):result.commission_id===commissionId;if(result.success!==true||!replayMatches||result.status!=='reversed')throw new Error('The Matrix commission reversal result did not match the selected record. Refresh the register to confirm its state.');setMessage(result.replayed===true?'Matrix commission was already reversed; existing ledger state confirmed.':'Matrix commission reversed.');setReloadToken(value=>value+1);await loadSummary();}
  catch(e){setMessage(e instanceof Error?e.message:'Matrix commission could not be reversed.');}
  finally{setActionBusy('');}
 }
 const total=filtered.reduce((sum,row)=>sum+Number(row.amount),0);
 return <section className="sponsorAdmin" aria-label="Matrix commission report">
  <div className="memberReportHeading"><div><h3>Matrix Commission Register</h3><small>Independent Under ID placement-chain commissions. Duplicate IDs remain visible as source IDs; their linked Main ID receives the Income Wallet credit.</small></div>
   <div style={{display:'flex',gap:8,flexWrap:'wrap'}}><button type="button" className="outline small" disabled={loading||more} onClick={()=>{setReloadToken(value=>value+1);void loadSummary();}}><RefreshCw size={14}/> Refresh</button><button type="button" className="outline small" disabled={exportBusy||loading||rows.length===0} onClick={()=>void exportAll()}><ArrowDownToLine size={14}/>{exportBusy?'Preparing…':'Export complete CSV'}</button></div>
  </div>
  {message&&<div className="notice" role="status">{message}</div>}
  <div className="sponsorAdminForm">
   <label>Search commission, activation, activated Main ID, source ID or credited Main ID<input type="search" value={search} onChange={e=>setSearch(e.target.value)} placeholder="Search IDs or member name"/></label>
   <label>Status<select value={status} onChange={e=>setStatus(e.target.value)}><option value="all">All statuses</option><option value="pending">Pending</option><option value="credited">Credited</option><option value="reversed">Reversed</option></select></label>
   <label>Matrix level<select value={level} onChange={e=>setLevel(e.target.value)}><option value="all">All levels</option>{Array.from({length:50},(_,i)=><option key={i+1} value={String(i+1)}>Level {i+1}</option>)}</select></label>
  </div>
  {summaryError&&<div className="notice" role="alert">Overall summary: {summaryError}</div>}
  <div className="mlmCards"><article><small>All Matrix commissions</small><b>{summaryLoading?'…':summary.total_count.toLocaleString('en-IN')}</b><small>{formatINR(summary.total_amount)} total</small></article><article><small>Pending</small><b>{summaryLoading?'…':summary.pending_count.toLocaleString('en-IN')}</b><small>{formatINR(summary.pending_amount)}</small></article><article><small>Credited</small><b>{summaryLoading?'…':summary.credited_count.toLocaleString('en-IN')}</b><small>{formatINR(summary.credited_amount)}</small></article><article><small>Reversed</small><b>{summaryLoading?'…':summary.reversed_count.toLocaleString('en-IN')}</b><small>{formatINR(summary.reversed_amount)}</small></article></div>
  <small>Overall totals cover all Matrix commission records, independent of the filters and loaded pages below. Current filtered page: {filtered.length} records · {formatINR(total)}.</small>
  {loading?<div className="packageState">Loading Matrix commissions…</div>:filtered.length===0?<div className="empty">{rows.length?'No Matrix commissions match these filters.':'No Matrix commission records are available yet.'}</div>:
   <div className="referralList">{filtered.map(row=><article key={row.commission_id} style={{display:'flex',flexDirection:'column',gap:6,overflowWrap:'anywhere'}}>
    <div className="memberReportHeading"><b>Level {row.level_number} · {row.source_member_code} ({row.source_id_type==='duplicate'?'Duplicate ID':'Main ID'})</b><strong>{row.status.toUpperCase()}</strong></div>
    <small>Activation: {row.activation_id} · Activated member: {row.activated_member_code}</small>
    <small>Credited Main ID: <b>{row.credited_main_member_code}</b> · {row.credited_main_name||'Member'}</small>
    <b>₹{Number(row.amount).toLocaleString('en-IN',{minimumFractionDigits:2,maximumFractionDigits:2})}</b>
    <small>{new Date(row.created_at).toLocaleString('en-IN')} · Commission ID: {row.commission_id}</small>
    <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>{row.status==='pending'&&<button type="button" className="primary small" disabled={actionBusy!==''||loading} onClick={()=>void postActivation(row.activation_id)}><CheckCircle size={14}/>{actionBusy===row.activation_id?'Posting…':'Post activation commissions'}</button>}{row.status==='credited'&&<button type="button" className="outline small" disabled={actionBusy!==''||loading} onClick={()=>void reverseCommission(row.commission_id)}><RotateCcw size={14}/>{actionBusy===row.commission_id?'Reversing…':'Reverse commission'}</button>}</div>
   </article>)}</div>}
  {hasMore&&<button type="button" className="outline small" disabled={more||loading} onClick={()=>void loadMore()}>{more?'Loading…':'Load 100 more Matrix commissions'}</button>}
  <small>Totals shown are for the currently loaded and filtered rows. Complete CSV export fetches every page from the server using the selected status and level filters.</small>
 </section>;
}
