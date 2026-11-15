import {useEffect,useState} from 'react';
import {UserRound,RefreshCw,ShieldCheck,IdCard,Wallet,PackageCheck} from 'lucide-react';
import {supabase} from '../lib/supabase';
import {money} from '../lib/format';
import Referrals from './Referrals';
import WalletHistory from './WalletHistory';
type Member={id:string;member_code:string;id_type:string;status:string;created_at:string};
type Activation={id:string;activation_number:number;amount_paid:number;currency:string;payment_status:string;activation_status:string;submitted_at:string;package:{name:string}|null};
type WalletRow={wallet_type:string;balance:number;currency:string};
type WithdrawalRow={request_id:string;amount:number;currency:string;status:string;requested_at:string;reviewed_at:string|null;rejection_reason:string|null};
export default function Account(){
 const [profile,setProfile]=useState<{display_name:string|null;phone:string|null;status:string;main_member_id:string|null}|null>(null);
 const [members,setMembers]=useState<Member[]>([]);const [activations,setActivations]=useState<Activation[]>([]);const [wallets,setWallets]=useState<WalletRow[]>([]);
 const [loading,setLoading]=useState(true);const [error,setError]=useState('');
 const [withdrawals,setWithdrawals]=useState<WithdrawalRow[]>([]);const [withdrawAmount,setWithdrawAmount]=useState('');const [payoutDetails,setPayoutDetails]=useState('');const [withdrawMessage,setWithdrawMessage]=useState('');const [withdrawBusy,setWithdrawBusy]=useState(false);
 async function load(){
  setLoading(true);setError('');
  if(!supabase){setError('Connect the production database to view account details.');setLoading(false);return;}
  const {data:{user}}=await supabase.auth.getUser();
  if(!user){setError('Sign in to view your member account.');setLoading(false);return;}
  const {data:p,error:pe}=await supabase.from('profiles').select('display_name,phone,status,main_member_id').eq('id',user.id).maybeSingle();
  if(pe||!p){setError('Your member profile is not available yet.');setLoading(false);return;}
  setProfile(p);
  if(p.main_member_id){
   const [m,a,w,wr]=await Promise.all([
    supabase.from('member_ids').select('id,member_code,id_type,status,created_at').eq('owner_user_id',user.id).order('created_at'),
    supabase.from('package_activations').select('id,activation_number,amount_paid,currency,payment_status,activation_status,submitted_at,package:packages(name)').eq('member_id',p.main_member_id).order('submitted_at',{ascending:false}).limit(50),
    supabase.from('wallet_accounts').select('wallet_type,balance,currency').eq('member_id',p.main_member_id),
    supabase.rpc('member_list_my_withdrawals')
   ]);
   if(m.error||a.error||w.error||wr.error)setError('Some account history is hidden by current database permissions.');
   setMembers((m.data??[]) as Member[]);setActivations((a.data??[]) as unknown as Activation[]);setWallets((w.data??[]) as WalletRow[]);setWithdrawals((wr.data??[]) as WithdrawalRow[]);
  }
  setLoading(false);
 }
 useEffect(()=>{void load()},[]);
 if(loading)return <div className="workspace">Loading your account…</div>;
 return <section className="accountWorkspace memberDashboard"><div className="memberConsoleHeader"><div><span>MY BIDDWORLD</span><h2>Member Dashboard</h2><p>Your account, wallets, packages and activity in one place</p></div><span className="memberConsoleBadge"><ShieldCheck size={15}/> Member Workspace</span></div><div className="memberDashboardLayout"><aside className="memberDashboardNav"><b>MY WORKSPACE</b><span className="memberNavGroup">OVERVIEW</span><a href="#member-overview">Dashboard Home</a><span className="memberNavGroup">MY ACCOUNT</span><a href="#member-profile">My Profile</a><a href="#member-ids">Member IDs</a><a href="#member-network">My Network</a><span className="memberNavGroup">MY MONEY</span><a href="#member-wallets">Wallet Balances</a><a href="#member-transactions">Transactions</a><a href="#member-withdrawals">Withdrawals</a><span className="memberNavGroup">MY ACTIVITY</span><a href="#member-activations">Packages</a><a href="#member-auctions">Auctions</a><a href="#member-fixedbid">Fixed Bid</a><a href="#member-reports">My Reports</a></aside><div className="memberDashboardContent">
  <div className="packageIntro" id="member-overview"><span className="workspaceIcon"><UserRound/></span><div><h3>My account</h3><p>Your registered member details, IDs, wallet balances and activation history.</p></div><button className="outline small accountRefresh" onClick={()=>void load()}><RefreshCw size={14}/> Refresh</button></div>
  {error&&<div className="notice">{error}</div>}
  <div className="accountProfile" id="member-profile"><div className="accountAvatar"><UserRound/></div><div><b>{profile?.display_name||'BiddWorld member'}</b><small>{profile?.phone||'Phone not added'} · {profile?.status||'Status unavailable'}</small></div><span className="accountVerified"><ShieldCheck size={15}/> Account</span></div>
  <div className="accountSection" id="member-ids"><h4><IdCard size={17}/> Member IDs</h4>{members.length?<div className="accountIdGrid">{members.map(m=><article key={m.id}><small>{m.id_type==='main'?'MAIN MEMBER ID':'DUPLICATE MEMBER ID'}</small><b>{m.member_code}</b><span className="statusText">{m.status}</span></article>)}</div>:<div className="empty">No member ID is linked to this profile yet.</div>}</div>
  <div className="accountSection" id="member-wallets"><h4><Wallet size={17}/> Wallet balances</h4><div className="accountWalletGrid">{['bid','income'].map(type=>{const w=wallets.find(x=>x.wallet_type===type);return <article key={type}><small>{type==='bid'?'Bid Wallet':'Income Wallet'}</small><b>{money(Number(w?.balance??0),w?.currency||'INR')}</b><span>{type==='bid'?'Bidding only · Non-withdrawable':'Referral income and permitted payments'}</span></article>})}</div></div>
  <div className="accountSection" id="member-network"><h4>My Network & Genealogy</h4><Referrals/></div>
  <div className="accountSection" id="member-transactions"><h4>Wallet Transactions</h4><WalletHistory/></div>
  <div className="accountSection" id="member-activations"><h4><PackageCheck size={17}/> Package activation history</h4>{activations.length?<div className="activationList">{activations.map(a=><article key={a.id}><div><b>{a.package?.name||'Membership package'} · #{a.activation_number}</b><small>{new Date(a.submitted_at).toLocaleDateString()} · {money(Number(a.amount_paid),a.currency||'INR')}</small></div><div><span>{a.payment_status}</span><small>{a.activation_status}</small></div></article>)}</div>:<div className="empty">No package activation requests found.</div>}</div>
  <div className="accountSection" id="member-auctions"><h4>Auction Activity</h4><p className="memberModuleHint">Your bids, auction participation, current bid status and completed auction history.</p><small className="memberModuleState">No member auction history is available yet.</small></div>
  <div className="accountSection" id="member-fixedbid"><h4>Fixed Bid Activity</h4><p className="memberModuleHint">Fixed Bid campaign entries, participation status and campaign results.</p><small className="memberModuleState">Fixed Bid result rules are pending Admin configuration.</small></div>
  <div className="accountSection" id="member-withdrawals"><h4>Withdrawal Requests</h4><p className="memberModuleHint">Submit a request from your Income Wallet. Admin review and payout are separate steps.</p><form className="memberWithdrawalForm" onSubmit={async e=>{e.preventDefault();if(!supabase||withdrawBusy)return;setWithdrawBusy(true);setWithdrawMessage('');let details:Record<string,string>;try{details=JSON.parse(payoutDetails);if(!details||typeof details!=='object'||Array.isArray(details))throw new Error();}catch{setWithdrawMessage('Enter payout details as valid JSON, for example bank name and account number.');setWithdrawBusy(false);return;}const{error}=await supabase.rpc('member_create_withdrawal_request',{p_amount:Number(withdrawAmount),p_payout_details:details});if(error)setWithdrawMessage(error.message);else{setWithdrawMessage('Withdrawal request submitted for Admin review.');setWithdrawAmount('');setPayoutDetails('');await load();}setWithdrawBusy(false);}}><label>Amount (INR)<input type="number" min="1" step="0.01" required value={withdrawAmount} onChange={e=>setWithdrawAmount(e.target.value)} placeholder="Enter amount"/></label><label>Bank / UPI payout details (JSON)<textarea required rows={3} value={payoutDetails} onChange={e=>setPayoutDetails(e.target.value)} placeholder='{"method":"UPI","upi_id":"name@bank"}'/></label><button className="primary" type="submit" disabled={withdrawBusy}>{withdrawBusy?'Submitting…':'Submit withdrawal request'}</button>{withdrawMessage&&<small role="status">{withdrawMessage}</small>}</form>{withdrawals.length?<div className="activationList">{withdrawals.map(w=><article key={w.request_id}><div><b>{money(Number(w.amount),w.currency||'INR')}</b><small>{new Date(w.requested_at).toLocaleString()}</small></div><div><span>{w.status}</span>{w.rejection_reason&&<small>{w.rejection_reason}</small>}</div></article>)}</div>:<div className="empty">No withdrawal requests yet.</div>}</div>
  <div className="accountSection" id="member-reports"><h4>My Reports</h4><p className="memberModuleHint">Joining date, referrals, team levels, package activations, commissions and wallet statement reports.</p><small className="memberModuleState">Detailed report exports are being implemented.</small></div>
 </div></div></section>;
}