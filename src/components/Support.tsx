import {useCallback,useEffect,useRef,useState} from 'react';
import {MessageCircle,Send,RefreshCw,ShieldCheck} from 'lucide-react';
import {supabase} from '../lib/supabase';

type Ticket={id:string;user_id:string;subject:string;message:string;status:'open'|'in_progress'|'resolved'|'closed';admin_response:string|null;created_at:string;updated_at:string};
const PAGE_SIZE=100;

export default function Support({isAdmin=false}:{isAdmin?:boolean}){
 const requestSeq=useRef(0),loadMoreBusy=useRef(false);
 const [tickets,setTickets]=useState<Ticket[]>([]);
 const [subject,setSubject]=useState('');
 const [message,setMessage]=useState('');
 const [response,setResponse]=useState<Record<string,string>>({});
 const [status,setStatus]=useState<Record<string,Ticket['status']>>({});
 const [busy,setBusy]=useState(false);
 const [saving,setSaving]=useState('');
 const [notice,setNotice]=useState('');
 const [error,setError]=useState('');
 const [hasMore,setHasMore]=useState(false);
 const [search,setSearch]=useState('');
 const [statusFilter,setStatusFilter]=useState<'all'|Ticket['status']>('all');

 const load=useCallback(async()=>{
  const seq=++requestSeq.current;loadMoreBusy.current=false;
  if(!supabase){setError('Support is unavailable until the BiddWorld database is configured.');setTickets([]);setHasMore(false);return;}
  setBusy(true);setError('');
  try{
   const {data,error:loadError}=await supabase.from('support_tickets').select('id,user_id,subject,message,status,admin_response,created_at,updated_at').order('updated_at',{ascending:false}).order('id',{ascending:false}).range(0,PAGE_SIZE-1);
   if(loadError)throw loadError;
   if(seq!==requestSeq.current)return;
   const rows=(data??[]) as Ticket[];
   setTickets(rows);setHasMore(rows.length===PAGE_SIZE);
   setStatus(Object.fromEntries(rows.map(row=>[row.id,row.status])));
   setResponse(Object.fromEntries(rows.map(row=>[row.id,row.admin_response??''])));
  }catch(e){if(seq===requestSeq.current)setError(e instanceof Error?e.message:'Support requests could not be loaded. Please retry.');}
  finally{if(seq===requestSeq.current)setBusy(false);}
 },[]);
 const loadMore=useCallback(async()=>{
  if(!supabase||loadMoreBusy.current||busy||!hasMore)return;
  loadMoreBusy.current=true;const seq=requestSeq.current;setBusy(true);setError('');
  try{
   const from=tickets.length;
   const {data,error:loadError}=await supabase.from('support_tickets').select('id,user_id,subject,message,status,admin_response,created_at,updated_at').order('updated_at',{ascending:false}).order('id',{ascending:false}).range(from,from+PAGE_SIZE-1);
   if(loadError)throw loadError;
   if(seq!==requestSeq.current)return;
   const rows=(data??[]) as Ticket[];
   setTickets(current=>[...current,...rows]);setHasMore(rows.length===PAGE_SIZE);
   setStatus(current=>({...current,...Object.fromEntries(rows.map(row=>[row.id,row.status]))}));
   setResponse(current=>({...current,...Object.fromEntries(rows.map(row=>[row.id,row.admin_response??'']))}));
  }catch(e){if(seq===requestSeq.current)setError(e instanceof Error?e.message:'More support requests could not be loaded. Please retry.');}
  finally{if(seq===requestSeq.current){loadMoreBusy.current=false;setBusy(false);}}
 },[busy,hasMore,tickets.length]);
 useEffect(()=>{void load()},[load]);

 async function submit(e:React.FormEvent<HTMLFormElement>){
  e.preventDefault();if(!supabase||busy)return;
  if(subject.trim().length<4||subject.trim().length>120){setError('Subject must contain 4–120 characters.');return;}
  if(message.trim().length<10||message.trim().length>5000){setError('Describe your issue in 10–5,000 characters.');return;}
  setBusy(true);setError('');setNotice('');
  try{
   const {data:{user},error:userError}=await supabase.auth.getUser();
   if(userError||!user)throw new Error('Please sign in again to submit a support request.');
   const {error:insertError}=await supabase.from('support_tickets').insert({user_id:user.id,subject:subject.trim(),message:message.trim()});
   if(insertError)throw insertError;
   setSubject('');setMessage('');setNotice('Your support request has been submitted.');
   await load();
  }catch(e){setError(e instanceof Error?e.message:'Your support request could not be submitted. Please retry.');}
  finally{setBusy(false);}
 }
 async function saveTicket(id:string){
  if(!supabase||saving)return;
  const nextStatus=status[id]??'open';
  const nextResponse=(response[id]??'').trim();
  if(nextResponse.length>5000){setError('Admin response must be 5,000 characters or fewer.');return;}
  setSaving(id);setError('');setNotice('');
  try{
   const {error:updateError}=await supabase.from('support_tickets').update({status:nextStatus,admin_response:nextResponse||null}).eq('id',id);
   if(updateError)throw updateError;
   setNotice('Support ticket updated.');await load();
  }catch(e){setError(e instanceof Error?e.message:'Support ticket could not be updated. Please retry.');}
  finally{setSaving('');}
 }
 const date=(value:string)=>new Date(value).toLocaleString('en-IN');
 const visibleTickets=tickets.filter(ticket=>(statusFilter==='all'||ticket.status===statusFilter)&&(!search.trim()||[ticket.subject,ticket.message,ticket.admin_response??''].some(value=>value.toLowerCase().includes(search.trim().toLowerCase()))));
 return <section className="accountSection" style={{display:'block',maxWidth:980,margin:'0 auto'}}>
  <h3><MessageCircle size={20}/> {isAdmin?'Member Support Queue':'Support & Help'}</h3>
  <p className="memberModuleHint">{isAdmin?'Review member requests and record a status and response.':'Send a private request to the BiddWorld support team and follow its status here.'}</p>
  {error&&<div className="notice" role="alert">{error}</div>}{notice&&<div className="notice" role="status">{notice}</div>}
  {!isAdmin&&<form className="memberWithdrawalForm" onSubmit={submit}>
   <label>Subject<input required minLength={4} maxLength={120} value={subject} onChange={e=>setSubject(e.target.value)} placeholder="Briefly describe the issue"/></label>
   <label>Message<textarea required minLength={10} maxLength={5000} rows={5} value={message} onChange={e=>setMessage(e.target.value)} placeholder="Include the details needed to help resolve your issue."/></label>
   <button className="primary" type="submit" disabled={busy||!supabase}><Send size={16}/> {busy?'Submitting…':'Submit support request'}</button>
  </form>}
  <div className="memberReportHeading"><h4>{isAdmin?'Recent member requests':'My support requests'} ({tickets.length}{hasMore?' loaded':''})</h4><button className="outline small" type="button" onClick={()=>void load()} disabled={busy}><RefreshCw size={14}/> Refresh</button></div>
  <div className="sponsorAdminForm" style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(190px,1fr))',gap:10,marginBottom:12}}><label>Search loaded requests<input type="search" value={search} onChange={e=>setSearch(e.target.value)} placeholder="Subject or message"/></label><label>Filter by status<select value={statusFilter} onChange={e=>setStatusFilter(e.target.value as typeof statusFilter)}><option value="all">All statuses</option><option value="open">Open</option><option value="in_progress">In progress</option><option value="resolved">Resolved</option><option value="closed">Closed</option></select></label></div>
  <div className="memberModuleHint">Showing {visibleTickets.length} matching requests from {tickets.length} loaded records. Search and status filters do not change records on the server.</div>
  {busy&&tickets.length===0?<div className="empty">Loading support requests…</div>:tickets.length===0?<div className="empty">No support requests found.</div>:visibleTickets.length===0?<div className="empty">No loaded support requests match these filters.</div>:<div className="activationList">{visibleTickets.map(ticket=><article key={ticket.id} style={{display:'block'}}>
   <div style={{display:'flex',justifyContent:'space-between',gap:12,flexWrap:'wrap'}}><b>{ticket.subject}</b><span className="protected">{ticket.status.replace('_',' ').toUpperCase()}</span></div>
   {isAdmin&&<small>Ticket {ticket.id.slice(0,8).toUpperCase()} · Member {ticket.user_id.slice(0,8)} </small>}
   <p style={{whiteSpace:'pre-wrap'}}>{ticket.message}</p><small>Submitted: {date(ticket.created_at)} · Updated: {date(ticket.updated_at)}</small>
   {ticket.admin_response&&<div className="notice"><b>Support response</b><p style={{whiteSpace:'pre-wrap'}}>{ticket.admin_response}</p></div>}
   {isAdmin&&<div className="sponsorAdminForm" style={{display:'grid',gap:8,marginTop:12}}>
    <label>Status<select value={status[ticket.id]??ticket.status} onChange={e=>setStatus(current=>({...current,[ticket.id]:e.target.value as Ticket['status']}))}><option value="open">Open</option><option value="in_progress">In progress</option><option value="resolved">Resolved</option><option value="closed">Closed</option></select></label>
    <label>Response<textarea rows={3} maxLength={5000} value={response[ticket.id]??''} onChange={e=>setResponse(current=>({...current,[ticket.id]:e.target.value}))} placeholder="Reply to the member"/></label>
    <button className="primary small" type="button" disabled={saving!==''} onClick={()=>void saveTicket(ticket.id)}><ShieldCheck size={15}/>{saving===ticket.id?'Saving…':'Save response & status'}</button>
   </div>}
  </article>)}</div>}
  {hasMore&&<button className="outline small" type="button" onClick={()=>void loadMore()} disabled={busy}>{busy?'Loading…':'Load 100 more requests'}</button>}
  <small className="memberModuleState">Privacy: members can access only their own requests. Admin access is checked by database policies. Records load 100 at a time.</small>
 </section>;
}
