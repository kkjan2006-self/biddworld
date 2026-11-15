import {useEffect,useState} from 'react';
import {UserRound,RefreshCw,ShieldCheck,IdCard,Wallet,PackageCheck} from 'lucide-react';
import {supabase} from '../lib/supabase';
import {money} from '../lib/format';
type Member={id:string;member_code:string;id_type:string;status:string;created_at:string};
type Activation={id:string;activation_number:number;amount_paid:number;currency:string;payment_status:string;activation_status:string;submitted_at:string;package:{name:string}|null};
type WalletRow={wallet_type:string;balance:number;currency:string};
export default function Account(){
 const [profile,setProfile]=useState<{display_name:string|null;phone:string|null;status:string;main_member_id:string|null}|null>(null);
 const [members,setMembers]=useState<Member[]>([]);const [activations,setActivations]=useState<Activation[]>([]);const [wallets,setWallets]=useState<WalletRow[]>([]);
 const [loading,setLoading]=useState(true);const [error,setError]=useState('');
 async function load(){
  setLoading(true);setError('');
  if(!supabase){setError('Connect the production database to view account details.');setLoading(false);return;}
  const {data:{user}}=await supabase.auth.getUser();
  if(!user){setError('Sign in to view your member account.');setLoading(false);return;}
  const {data:p,error:pe}=await supabase.from('profiles').select('display_name,phone,status,main_member_id').eq('id',user.id).maybeSingle();
  if(pe||!p){setError('Your member profile is not available yet.');setLoading(false);return;}
  setProfile(p);
  if(p.main_member_id){
   const [m,a,w]=await Promise.all([
    supabase.from('member_ids').select('id,member_code,id_type,status,created_at').eq('owner_user_id',user.id).order('created_at'),
    supabase.from('package_activations').select('id,activation_number,amount_paid,currency,payment_status,activation_status,submitted_at,package:packages(name)').eq('member_id',p.main_member_id).order('submitted_at',{ascending:false}).limit(50),
    supabase.from('wallet_accounts').select('wallet_type,balance,currency').eq('member_id',p.main_member_id)
   ]);
   if(m.error||a.error||w.error)setError('Some account history is hidden by current database permissions.');
   setMembers((m.data??[]) as Member[]);setActivations((a.data??[]) as unknown as Activation[]);setWallets((w.data??[]) as WalletRow[]);
  }
  setLoading(false);
 }
 useEffect(()=>{void load()},[]);
 if(loading)return <div className="workspace">Loading your account…</div>;
 return <section className="accountWorkspace memberDashboard"><div className="memberDashboardLayout"><aside className="memberDashboardNav"><b>MEMBER MENU</b><a href="#member-overview">Dashboard Overview</a><a href="#member-profile">My Profile</a><a href="#member-ids">Main & Duplicate IDs</a><a href="#member-network">My Network & Genealogy</a><a href="#member-wallets">Bid / Income Wallets</a><a href="#member-transactions">Wallet Transactions</a><a href="#member-activations">Packages & Activations</a><a href="#member-auctions">Auction Activity</a><a href="#member-fixedbid">Fixed Bid Activity</a><a href="#member-withdrawals">Withdrawal History</a><a href="#member-reports">My Reports</a></aside><div className="memberDashboardContent">
  <div className="packageIntro" id="member-overview"><span className="workspaceIcon"><UserRound/></span><div><h3>My account</h3><p>Your registered member details, IDs, wallet balances and activation history.</p></div><button className="outline small accountRefresh" onClick={()=>void load()}><RefreshCw size={14}/> Refresh</button></div>
  {error&&<div className="notice">{error}</div>}
  <div className="accountProfile" id="member-profile"><div className="accountAvatar"><UserRound/></div><div><b>{profile?.display_name||'BiddWorld member'}</b><small>{profile?.phone||'Phone not added'} · {profile?.status||'Status unavailable'}</small></div><span className="accountVerified"><ShieldCheck size={15}/> Account</span></div>
  <div className="accountSection" id="member-ids"><h4><IdCard size={17}/> Member IDs</h4>{members.length?<div className="accountIdGrid">{members.map(m=><article key={m.id}><small>{m.id_type==='main'?'MAIN MEMBER ID':'DUPLICATE MEMBER ID'}</small><b>{m.member_code}</b><span className="statusText">{m.status}</span></article>)}</div>:<div className="empty">No member ID is linked to this profile yet.</div>}</div>
  <div className="accountSection" id="member-wallets"><h4><Wallet size={17}/> Wallet balances</h4><div className="accountWalletGrid">{['bid','income'].map(type=>{const w=wallets.find(x=>x.wallet_type===type);return <article key={type}><small>{type==='bid'?'Bid Wallet':'Income Wallet'}</small><b>{money(Number(w?.balance??0),w?.currency||'INR')}</b><span>{type==='bid'?'Bidding only · Non-withdrawable':'Referral income and permitted payments'}</span></article>})}</div></div>
  <div className="accountSection" id="member-network"><h4>My Network & Genealogy</h4><p className="memberModuleHint">Sponsor referral genealogy, direct referrals, team members, level-wise counts and placement tree.</p><div className="memberModuleGrid"><article><b>Direct Referrals</b><small>People registered under your Sponsor ID</small></article><article><b>Full Sponsor Genealogy</b><small>View your referral team by levels</small></article><article><b>Placement Tree</b><small>View only Admin-assigned placement links</small></article></div><small className="memberModuleState">Network report data is being connected to secure member RPCs.</small></div>
  <div className="accountSection" id="member-transactions"><h4>Wallet Transactions</h4><p className="memberModuleHint">Separate Bid Wallet and Income Wallet credit/debit ledger, transaction reference, date and balance after each transaction.</p><small className="memberModuleState">Use Wallet History in the main navigation for currently available ledger entries.</small></div>
  <div className="accountSection" id="member-activations"><h4><PackageCheck size={17}/> Package activation history</h4>{activations.length?<div className="activationList">{activations.map(a=><article key={a.id}><div><b>{a.package?.name||'Membership package'} · #{a.activation_number}</b><small>{new Date(a.submitted_at).toLocaleDateString()} · {money(Number(a.amount_paid),a.currency||'INR')}</small></div><div><span>{a.payment_status}</span><small>{a.activation_status}</small></div></article>)}</div>:<div className="empty">No package activation requests found.</div>}</div>
  <div className="accountSection" id="member-auctions"><h4>Auction Activity</h4><p className="memberModuleHint">Your bids, auction participation, current bid status and completed auction history.</p><small className="memberModuleState">No member auction history is available yet.</small></div>
  <div className="accountSection" id="member-fixedbid"><h4>Fixed Bid Activity</h4><p className="memberModuleHint">Fixed Bid campaign entries, participation status and campaign results.</p><small className="memberModuleState">Fixed Bid result rules are pending Admin configuration.</small></div>
  <div className="accountSection" id="member-withdrawals"><h4>Withdrawal History</h4><p className="memberModuleHint">Income Wallet withdrawal requests, approval status, payout reference and history.</p><small className="memberModuleState">Withdrawals are not enabled yet.</small></div>
  <div className="accountSection" id="member-reports"><h4>My Reports</h4><p className="memberModuleHint">Joining date, referrals, team levels, package activations, commissions and wallet statement reports.</p><small className="memberModuleState">Detailed report exports are being implemented.</small></div>
 </div></div></section>;
}