import {useCallback,useEffect,useState} from 'react';
import {MessageCircle,Send,RefreshCw,ShieldCheck} from 'lucide-react';
import {supabase} from '../lib/supabase';

type Ticket={id:string;user_id:string;subject:string;message:string;status:'open'|'in_progress'|'resolved'|'closed';admin_response:string|null;created_at:string;updated_at:string};

export default function Support({isAdmin=false}:{isAdmin?:boolean}){
 const [tickets,setTickets]=useState<Ticket[]>([]);
 const [subject,setSubject]=useState('');
 const [message,setMessage]=useState('');
 const [response,setResponse]=useState<Record<string,string>>({});
 const [status,setStatus]=useState<Record<string,Ticket['status']>>({});
 const [busy,setBusy]=useState(false);
 const [saving,setSaving]=useState('');
 const [notice,setNotice]=useState('');
 const [error,setError]=useState('');

 const load=useCallback(async()=>{
  if(!supabase){setError('Support is unavailable until the BiddWorld database is configured.');return;}
  setBusy(true);setError('');
  const query=supabase.from('support_tickets').select('id,user_id,subject,message,status,admin_response,created_at,updated_at').order('updated_at',{ascending:false}).limit(100);
  const {data,error:loadError}=await query;
  setBusy(false);
  if(loadError){setError(loadError.message);return;}
  const rows=(data??[]) as Ticket[];
  setTickets(rows);
  setStatus(Object.fromEntries(rows.map(row=>[row.id,row.status])));
  setResponse(Object.fromEntries(rows.map(row=>[row.id,row.admin_response??''])));
 },[]);
 useEffect(()=>{void load()},[load]);

 async function submit(e:React.FormEvent<HTMLFormElement>){
  e.preventDefault();if(!supabase||busy)return;
  if(subject.trim().length<4||subject.trim().length>120){setError('Subject must contain 4–120 characters.');return;}
  if(message.trim().length<10||message.trim().length>5000){setError('Describe your issue in 10–5,000 characters.');return;}
  setBusy(true);setError('');setNotice('');
  const {data:{user},error:userError}=await supabase.auth.getUser();
  if(userError||!user){setBusy(false);setError('Please sign in again to submit a support request.');return;}
  const {error:insertError}=await supabase.from('support_tickets').insert({user_id:user.id,subject:subject.trim(),message:message.trim()});
  setBusy(false);
  if(insertError){setError(insertError.message);return;}
  setSubject('');setMessage('');setNotice('Your support request has been submitted.');await load();
 }
 async function saveTicket(id:string){
  if(!supabase||saving)return;
  const nextStatus=status[id]??'open';
  const nextResponse=(response[id]??'').trim();
  if(nextResponse.length>5000){setError('Admin response must be 5,000 characters or fewer.');return;}
  setSaving(id);setError('');setNotice('');
  const {error:updateError}=await supabase.from('support_tickets').update({status:nextStatus,admin_response:nextResponse||null}).eq('id',id);
  setSaving('');
  if(updateError){setError(updateError.message);return;}
  setNotice('Support ticket updated.');await load();
 }
 const date=(value:string)=>new Date(value).toLocaleString('en-IN');
 return <section className="accountSection" style={{display:'block',maxWidth:980,margin:'0 auto'}}>
  <h3><MessageCircle size={20}/> {isAdmin?'Member Support Queue':'Support & Help'}</h3>
  <p className="memberModuleHint">{isAdmin?'Review member requests and record a status and response.':'Send a private request to the BiddWorld support team and follow its status here.'}</p>
  {error&&<div className="notice" role="alert">{error}</div>}{notice&&<div className="notice" role="status">{notice}</div>}
  {!isAdmin&&<form className="memberWithdrawalForm" onSubmit={submit}>
   <label>Subject<input required minLength={4} maxLength={120} value={subject} onChange={e=>setSubject(e.target.value)} placeholder="Briefly describe the issue"/></label>
   <label>Message<textarea required minLength={10} maxLength={5000} rows={5} value={message} onChange={e=>setMessage(e.target.value)} placeholder="Include the details needed to help resolve your issue."/></label>
   <button className="primary" type="submit" disabled={busy||!supabase}><Send size={16}/> {busy?'Submitting…':'Submit support request'}</button>
  </form>}
  <div className="memberReportHeading"><h4>{isAdmin?'Recent member requests':'My support requests'} ({tickets.length})</h4><button className="outline small" type="button" onClick={()=>void load()} disabled={busy}><RefreshCw size={14}/> Refresh</button></div>
  {busy&&tickets.length===0?<div className="empty">Loading support requests…</div>:tickets.length===0?<div className="empty">No support requests found.</div>:<div className="activationList">{tickets.map(ticket=><article key={ticket.id} style={{display:'block'}}>
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
  <small className="memberModuleState">Privacy: members can access only their own requests. Admin access is checked by database policies. The list currently displays the latest 100 records.</small>
 </section>;
}
