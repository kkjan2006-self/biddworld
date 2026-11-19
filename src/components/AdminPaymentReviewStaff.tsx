import {useEffect,useState} from 'react';
import {ShieldCheck,UserPlus,UserMinus,RefreshCw} from 'lucide-react';
import {supabase} from '../lib/supabase';
type Staff={user_id:string;email:string|null;created_at:string;last_sign_in_at:string|null;permissions:string[]};
export default function AdminPaymentReviewStaff(){
 const[rows,setRows]=useState<Staff[]>([]),[email,setEmail]=useState(''),[reason,setReason]=useState(''),[message,setMessage]=useState(''),[busy,setBusy]=useState(false);
 async function load(){if(!supabase)return;const{data,error}=await supabase.rpc('admin_list_payment_review_staff');if(error){setMessage(error.message);return;}setRows((data??[]) as Staff[]);}
 useEffect(()=>{void load();},[]);
 async function change(target:string,enabled:boolean,why:string){if(!supabase||busy)return;if(!window.confirm((enabled?'Grant restricted payment-review staff access to ':'Revoke staff access from ')+target+'?'))return;setBusy(true);setMessage('');try{const{error}=await supabase.rpc('admin_set_payment_review_staff',{p_email:target,p_enabled:enabled,p_reason:why});if(error)throw error;setMessage('Staff role updated. The user must sign out and sign in again.');setEmail('');setReason('');await load();}catch(e){setMessage(e instanceof Error?e.message:'Staff role could not be updated.');}finally{setBusy(false);}}
 return <section style={{display:'flex',flexDirection:'column',gap:10,marginTop:18,padding:12,border:'1px solid var(--border,#ddd)',borderRadius:10}}>
  <h5>Restricted Payment Review Staff</h5><p>Staff can only view and approve/reject Package Activation payments and Main Wallet Add Money requests. They cannot access other Admin modules, adjust balances, manage roles or change settings.</p>
  {message&&<div className="notice" role="status">{message}</div>}
  <form onSubmit={e=>{e.preventDefault();void change(email.trim(),true,reason.trim());}} style={{display:'flex',flexDirection:'column',gap:8}}>
   <label>Existing member account email<input type="email" required value={email} onChange={e=>setEmail(e.target.value)} placeholder="staff@example.com"/></label>
   <label>Reason<input required minLength={5} maxLength={500} value={reason} onChange={e=>setReason(e.target.value)} placeholder="Reason for granting restricted access"/></label>
   <button className="primary small" type="submit" disabled={busy||!email.trim()||reason.trim().length<5}><UserPlus size={15}/>{busy?'Updating…':'Grant Payment Review Staff'}</button>
  </form>
  <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',gap:8}}><b>Current staff ({rows.length})</b><button className="outline small" type="button" onClick={()=>void load()}><RefreshCw size={14}/> Refresh</button></div>
  {rows.length===0?<p>No restricted payment-review staff accounts.</p>:rows.map(row=><article key={row.user_id} style={{border:'1px solid var(--border,#ddd)',borderRadius:9,padding:10,display:'flex',flexDirection:'column',gap:5}}><b>{row.email||'Email unavailable'}</b><small>Permissions: Package payment review · Main Wallet funding review</small><small>Last sign-in: {row.last_sign_in_at?new Date(row.last_sign_in_at).toLocaleString():'Never recorded'}</small><button className="outline small" type="button" disabled={busy||!row.email} onClick={()=>{const why=(window.prompt('Reason for revoking staff access (at least 5 characters):')??'').trim();if(why.length<5){setMessage('Provide a reason of at least 5 characters.');return;}void change(row.email!,false,why);}}><UserMinus size={14}/> Revoke Staff Access</button></article>)}
  <small><ShieldCheck size={13}/> Only the designated Primary Admin can grant or revoke this role. Every change is audited.</small>
 </section>;
}
