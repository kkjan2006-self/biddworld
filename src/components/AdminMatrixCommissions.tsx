import {useCallback,useEffect,useMemo,useState} from 'react';
import {ArrowDownToLine,RefreshCw,Search} from 'lucide-react';
import {supabase} from '../lib/supabase';
import {csvDocument} from '../lib/csv';

type MatrixCommissionRow={
 commission_id:string;activation_id:string;activated_member_code:string;
 level_number:number;source_member_code:string;source_id_type:string;
 credited_main_member_code:string;credited_main_name:string|null;
 amount:number;status:'pending'|'credited'|'reversed';created_at:string;has_more?:boolean;
};
const PAGE_SIZE=100;
const validStatuses=['pending','credited','reversed'] as const;
function validRow(value:unknown):value is MatrixCommissionRow{
 if(!value||typeof value!=='object')return false;
 const r=value as Record<string,unknown>;
 return typeof r.commission_id==='string'&&r.commission_id.length>0
  &&typeof r.activation_id==='string'&&r.activation_id.length>0
  &&typeof r.activated_member_code==='string'&&r.activated_member_code.length>0
  &&Number.isInteger(r.level_number)&&Number(r.level_number)>0
  &&typeof r.source_member_code==='string'&&r.source_member_code.length>0
  &&typeof r.source_id_type==='string'&&['main','duplicate'].includes(r.source_id_type)
  &&typeof r.credited_main_member_code==='string'&&r.credited_main_member_code.length>0
  &&(r.credited_main_name===null||typeof r.credited_main_name==='string')
  &&Number.isFinite(Number(r.amount))&&Number(r.amount)>0
  &&typeof r.status==='string'&&(validStatuses as readonly string[]).includes(r.status)
  &&typeof r.created_at==='string'&&Number.isFinite(Date.parse(r.created_at));
}
export default function AdminMatrixCommissions(){
 const [rows,setRows]=useState<MatrixCommissionRow[]>([]);
 const [status,setStatus]=useState('all'),[level,setLevel]=useState('all'),[search,setSearch]=useState('');
 const [loading,setLoading]=useState(false),[more,setMore]=useState(false),[hasMore,setHasMore]=useState(false);
 const [message,setMessage]=useState(''),[exportBusy,setExportBusy]=useState(false);
 const fetchPage=useCallback(async(offset:number,filterStatus:string,filterLevel:string)=>{
  if(!supabase)throw new Error('Supabase is not configured for this environment.');
  const {data,error}=await supabase.rpc('admin_list_matrix_commissions_page',{
   p_limit:PAGE_SIZE,p_offset:offset,p_status:filterStatus==='all'?null:filterStatus,
   p_level:filterLevel==='all'?null:Number(filterLevel)
  });
  if(error)throw error;
  if(!Array.isArray(data)||!data.every(validRow))throw new Error('The Matrix commission report returned an invalid or incomplete page. Refresh before continuing.');
  const ids=new Set<string>();
  for(const row of data as MatrixCommissionRow[]){if(ids.has(row.commission_id))throw new Error('The Matrix report returned duplicate commission IDs.');ids.add(row.commission_id);}
  return data as MatrixCommissionRow[];
 },[]);
 const load=useCallback(async(reset=true)=>{
  if(loading||more)return;
  setLoading(reset);setMore(!reset);setMessage('');
  try{
   const offset=reset?0:rows.length;
   const batch=await fetchPage(offset,status,level);
   if(reset)setRows(batch);
   else{
    const known=new Set(rows.map(r=>r.commission_id));
    if(batch.some(r=>known.has(r.commission_id)))throw new Error('The next Matrix report page overlaps records already loaded. Refresh the report.');
    setRows(current=>[...current,...batch]);
   }
   setHasMore(batch.length===PAGE_SIZE&&batch[batch.length-1]?.has_more===true);
  }catch(e){setMessage(e instanceof Error?e.message:'Could not load Matrix commission report.');}
  finally{setLoading(false);setMore(false);}
 },[fetchPage,status,level,rows,loading,more]);
 useEffect(()=>{void load(true);},[status,level]);
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
 const total=filtered.reduce((sum,row)=>sum+Number(row.amount),0);
 return <section className="sponsorAdmin" aria-label="Matrix commission report">
  <div className="memberReportHeading"><div><h3>Matrix Commission Register</h3><small>Independent Under ID placement-chain commissions. Duplicate IDs remain visible as source IDs; their linked Main ID receives the Income Wallet credit.</small></div>
   <div style={{display:'flex',gap:8,flexWrap:'wrap'}}><button type="button" className="outline small" disabled={loading||more} onClick={()=>void load(true)}><RefreshCw size={14}/> Refresh</button><button type="button" className="outline small" disabled={exportBusy||loading||rows.length===0} onClick={()=>void exportAll()}><ArrowDownToLine size={14}/>{exportBusy?'Preparing…':'Export complete CSV'}</button></div>
  </div>
  {message&&<div className="notice" role="status">{message}</div>}
  <div className="sponsorAdminForm">
   <label>Search commission, activation, activated Main ID, source ID or credited Main ID<input type="search" value={search} onChange={e=>setSearch(e.target.value)} placeholder="Search IDs or member name"/></label>
   <label>Status<select value={status} onChange={e=>setStatus(e.target.value)}><option value="all">All statuses</option><option value="pending">Pending</option><option value="credited">Credited</option><option value="reversed">Reversed</option></select></label>
   <label>Matrix level<select value={level} onChange={e=>setLevel(e.target.value)}><option value="all">All levels</option>{Array.from({length:50},(_,i)=><option key={i+1} value={String(i+1)}>Level {i+1}</option>)}</select></label>
  </div>
  <div className="mlmCards"><article><small>Loaded records</small><b>{filtered.length}</b></article><article><small>Loaded commission total</small><b>₹{total.toLocaleString('en-IN',{minimumFractionDigits:2,maximumFractionDigits:2})}</b></article><article><small>Pending</small><b>{filtered.filter(r=>r.status==='pending').length}</b></article><article><small>Credited</small><b>{filtered.filter(r=>r.status==='credited').length}</b></article></div>
  {loading?<div className="packageState">Loading Matrix commissions…</div>:filtered.length===0?<div className="empty">{rows.length?'No Matrix commissions match these filters.':'No Matrix commission records are available yet.'}</div>:
   <div className="referralList">{filtered.map(row=><article key={row.commission_id} style={{display:'flex',flexDirection:'column',gap:6,overflowWrap:'anywhere'}}>
    <div className="memberReportHeading"><b>Level {row.level_number} · {row.source_member_code} ({row.source_id_type==='duplicate'?'Duplicate ID':'Main ID'})</b><strong>{row.status.toUpperCase()}</strong></div>
    <small>Activation: {row.activation_id} · Activated member: {row.activated_member_code}</small>
    <small>Credited Main ID: <b>{row.credited_main_member_code}</b> · {row.credited_main_name||'Member'}</small>
    <b>₹{Number(row.amount).toLocaleString('en-IN',{minimumFractionDigits:2,maximumFractionDigits:2})}</b>
    <small>{new Date(row.created_at).toLocaleString('en-IN')} · Commission ID: {row.commission_id}</small>
   </article>)}</div>}
  {hasMore&&<button type="button" className="outline small" disabled={more||loading} onClick={()=>void load(false)}>{more?'Loading…':'Load 100 more Matrix commissions'}</button>}
  <small>Totals shown are for the currently loaded and filtered rows. Complete CSV export fetches every page from the server using the selected status and level filters.</small>
 </section>;
}
