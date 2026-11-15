import {useEffect,useMemo,useState} from 'react';
import {ShieldCheck,Users,PackageCheck,Gavel,Wallet,RefreshCw,AlertCircle,Network,UserCheck} from 'lucide-react';
import {supabase} from '../lib/supabase';
import {csvDocument} from '../lib/csv';
import {filterAuditEntries} from '../lib/audit';
type Counts={members:number;packages:number;pendingActivations:number;pendingWithdrawals:number;auctions:number;campaigns:number};
type SponsorMember={member_code:string;display_name:string;phone:string;sponsor_code:string;created_at:string};
type MlmOverview={total_members:number;active_members:number;direct_relationships:number;pending_activations:number;verified_activations:number;commission_total:number;withdrawal_pending:number};
type StructureId={member_code:string;id_type:string;status:string;display_name:string|null;main_member_code:string|null;placement_parent_code:string|null;placement_position:string|null;created_at:string};
type StructureReport={total_ids:number;main_ids:number;duplicate_ids:number;placement_assigned:number;ids:StructureId[];sponsor_levels:{level:number;members:number}[]};
type AuditEntry={id:number;actor_user_id:string|null;actor_name:string;action:string;entity_type:string;entity_id:string|null;details:Record<string,unknown>;created_at:string};
type PendingActivation={id:string;activation_number:number;member_code:string;member_name:string|null;package_name:string;amount_paid:number;currency:string;bid_wallet_credit:number;payment_reference:string;submitted_at:string};

function PlacementBranch({row,all,path=[]}:{row:StructureId;all:StructureId[];path?:string[]}){
 const cycle=path.includes(row.member_code);
 const nextPath=[...path,row.member_code];
 const children=cycle?[]:all.filter(item=>item.placement_parent_code===row.member_code);
 return <div className="placementNode" style={{marginLeft:path.length?18:0,paddingLeft:12,borderLeft:path.length?'1px solid var(--border, #d1d5db)':undefined,marginTop:8}}><div><b>{row.member_code}</b> <small>· {row.display_name||'Member'} · {row.id_type} · {row.status}</small></div>{row.placement_position&&<small>Position: {row.placement_position}</small>}{children.map(child=><PlacementBranch key={child.member_code} row={child} all={all} path={nextPath}/>)}</div>;
}
const empty:Counts={members:0,packages:0,pendingActivations:0,pendingWithdrawals:0,auctions:0,campaigns:0};
export default function Admin(){
 const [role,setRole]=useState(''),[counts,setCounts]=useState(empty),[loading,setLoading]=useState(true),[error,setError]=useState('');
 const [refresh,setRefresh]=useState(0);
 const [overview,setOverview]=useState<MlmOverview|null>(null),[structure,setStructure]=useState<StructureReport|null>(null),[members,setMembers]=useState<SponsorMember[]>([]),[memberSearch,setMemberSearch]=useState(''),[defaultSponsor,setDefaultSponsor]=useState(''),[memberCode,setMemberCode]=useState(''),[sponsorCode,setSponsorCode]=useState(''),[sponsorMessage,setSponsorMessage]=useState(''),[savingSponsor,setSavingSponsor]=useState(false);
 const [pendingActivations,setPendingActivations]=useState<PendingActivation[]>([]);
 const [auditLogs,setAuditLogs]=useState<AuditEntry[]>([]),[auditSearch,setAuditSearch]=useState('');
 const [reviewingActivation,setReviewingActivation]=useState('');
 const [activationMessage,setActivationMessage]=useState('');
 useEffect(()=>{
  if(!supabase){setLoading(false);return;}
  let active=true;
  const applyRole=(session:{user?:{app_metadata?:Record<string,unknown>} }|null)=>setRole(String(session?.user?.app_metadata?.role??''));
  const {data:{subscription}}=supabase.auth.onAuthStateChange((_event,session)=>{
   if(active)applyRole(session);
  });
  void supabase.auth.getSession().then(({data:{session}})=>{if(active)applyRole(session);});
  return()=>{active=false;subscription.unsubscribe();};
 },[]);
 useEffect(()=>{
  let active=true;
  setCounts(empty);setError('');setLoading(true);
  async function load(){
   if(!supabase||role!=='admin'){if(active)setLoading(false);return;}
   const specs=[['members','profiles',null],['packages','packages',null],['pendingActivations','package_activations','payment_status'],['pendingWithdrawals','withdrawal_requests','status'],['auctions','auctions',null],['campaigns','fixed_bid_campaigns',null]] as const;
   const [results,memberResult,overviewResult,structureResult,pendingResult,auditResult]=await Promise.all([Promise.all(specs.map(async ([key,table,column])=>{
    let q=supabase!.from(table).select('id',{count:'exact',head:true});
    if(column)q=q.eq(column,'pending');
    const result=await q;
    return {key,count:result.count,error:result.error};
   })),supabase.rpc('admin_list_members_sponsors'),supabase.rpc('admin_get_mlm_overview'),supabase.rpc('admin_get_member_structure'),supabase.rpc('admin_list_pending_activations'),supabase.rpc('admin_list_audit_logs',{p_limit:100})]);
   if(!active)return;
   if(!memberResult.error)setMembers((memberResult.data??[]) as SponsorMember[]);
   if(!overviewResult.error)setOverview(overviewResult.data as MlmOverview);
   if(!structureResult.error)setStructure(structureResult.data as StructureReport);
   if(!pendingResult.error)setPendingActivations((pendingResult.data??[]) as PendingActivation[]);
   if(!auditResult.error)setAuditLogs((auditResult.data??[]) as AuditEntry[]);
   if(results.some(x=>x.error))setError('Some totals are hidden by current database permissions or unavailable.');
   setCounts(Object.fromEntries(results.map(x=>[x.key,x.count??0])) as unknown as Counts);
   setLoading(false);
  }
  void load();return()=>{active=false;};
 },[role,refresh]);
 async function reviewActivation(id:string,approve:boolean){
  if(!supabase)return;
  setReviewingActivation(id);setActivationMessage('');
  const {error}=await supabase.rpc('admin_review_package_activation',{p_activation_id:id,p_approve:approve});
  setReviewingActivation('');
  if(error){setActivationMessage(error.message);return;}
  setActivationMessage(approve?'Payment approved. Package activated and Bid Wallet credit posted.':'Payment rejected. No wallet credit was issued.');
  setRefresh(v=>v+1);
 }
 function exportMembersCsv(){const rows=[['Member Main ID','Name','Phone','Sponsor Main ID','Joined At'],...filteredMembers.map(m=>[m.member_code,m.display_name,m.phone,m.sponsor_code,m.created_at])];const csv=csvDocument(rows);const blob=new Blob([csv],{type:'text/csv;charset=utf-8;'});const url=URL.createObjectURL(blob);const a=document.createElement('a');a.href=url;a.download='biddworld-members-report.csv';a.click();URL.revokeObjectURL(url);}
 async function exportAuditCsv(){const rows=[['Audit ID','Actor','Action','Entity Type','Entity ID','Created At','Details'],...filteredAuditLogs.map(item=>[item.id,item.actor_name,item.action,item.entity_type,item.entity_id,item.created_at,JSON.stringify(item.details??{})])];const blob=new Blob([csvDocument(rows)],{type:'text/csv;charset=utf-8;'});const url=URL.createObjectURL(blob);const a=document.createElement('a');a.href=url;a.download='biddworld-audit-log-latest-100.csv';a.click();URL.revokeObjectURL(url);}
 async function saveDefaultSponsor(){if(!supabase)return;setSavingSponsor(true);const{error}=await supabase.rpc('admin_set_default_sponsor',{p_member_code:defaultSponsor.trim()});setSavingSponsor(false);setSponsorMessage(error?.message??'Default sponsor saved.');}
 async function changeSponsor(){if(!supabase)return;if(!memberCode.trim()||!sponsorCode.trim()){setSponsorMessage('Enter both member and new sponsor Main IDs.');return;}setSavingSponsor(true);const{error}=await supabase.rpc('admin_set_member_sponsor',{p_member_code:memberCode.trim(),p_sponsor_code:sponsorCode.trim()});setSavingSponsor(false);setSponsorMessage(error?.message??'Member sponsor updated. Existing commission records remain unchanged.');if(!error){setMemberCode('');setSponsorCode('');setRefresh(v=>v+1);}}
 const filteredAuditLogs=useMemo(()=>filterAuditEntries(auditLogs,auditSearch),[auditLogs,auditSearch]);
  const filteredMembers=useMemo(()=>{const q=memberSearch.trim().toLowerCase();return members.filter(m=>(m.member_code+' '+m.display_name+' '+m.phone+' '+(m.sponsor_code??'')).toLowerCase().includes(q));},[members,memberSearch]);
 if(loading)return <div className="workspace">Loading administrator overview…</div>;
 if(role!=='admin')return <div className="workspace"><div className="workspaceIcon"><ShieldCheck/></div><h3>Administrator access required</h3><p>This area is restricted to accounts with the administrator role. Ask the system owner to assign the role securely in Supabase Auth app_metadata.</p></div>;
 const tiles=[['Registered Profiles',counts.members,Users],['Packages',counts.packages,PackageCheck],['Pending activations',counts.pendingActivations,AlertCircle],['Pending withdrawals',counts.pendingWithdrawals,Wallet],['Auctions',counts.auctions,Gavel],['Fixed Bid campaigns',counts.campaigns,PackageCheck]] as const;
 return <section className="adminPanel adminConsole"><div className="adminConsoleHeader"><div><span className="adminEyebrow">BID WORLD · CONTROL CENTER</span><h2>Admin Dashboard</h2><p>Manage members, payments, network and platform activity.</p></div><span className="adminSecure"><ShieldCheck size={15}/> Secure Admin</span></div><div className="adminDashboardLayout"><nav className="adminQuickNav" aria-label="Admin sections">
<b>MAIN MENU</b>
<a href="#admin-overview">Overview</a>
<span className="adminNavGroup">MEMBERS & NETWORK</span>
<a href="#admin-members">Members & Duplicate IDs</a>
<a href="#admin-sponsors">Sponsors & Team</a>
<span className="adminNavGroup">MONEY & PACKAGES</span>
<a href="#admin-payments">Payment Approvals</a>
<a href="#admin-packages">Packages & Benefits</a>
<a href="#admin-commission">Commissions</a>
<a href="#admin-wallets">Wallets</a>
<a href="#admin-withdrawals">Withdrawals</a>
<span className="adminNavGroup">BIDDING</span>
<a href="#admin-auctions">Auctions</a>
<a href="#admin-fixedbid">Fixed Bid</a>
<a href="#admin-winning">Winner & Payment</a>
<a href="#admin-delivery">Delivery</a>
<span className="adminNavGroup">SYSTEM</span>
<a href="#admin-reports">Reports</a>
<a href="#admin-notifications">Notifications</a>
<a href="#admin-roles">Admin Access</a>
<a href="#admin-settings">Settings</a>
<a href="#admin-audit">Activity Log</a>
</nav><div className="adminDashboardContent"><div id="admin-overview" className="packageIntro"><span className="workspaceIcon"><ShieldCheck/></span><div><h3>Administrator overview</h3><p>Operational overview with audited sponsor controls. Financial approvals and money movement remain disabled until their secure workflows are configured.</p></div><button className="outline small" onClick={()=>setRefresh(v=>v+1)}><RefreshCw size={14}/> Refresh</button></div>{error&&<div className="notice">{error}</div>}<div className="adminStats">{tiles.map(([label,value,Icon])=><article key={label}><Icon size={20}/><small>{label}</small><b>{value.toLocaleString('en-IN')}</b></article>)}</div><div className="adminSimpleGuide"><b>Start here</b><span>Use the menu to open one section at a time. Pending payments need review first; member and sponsor tools are grouped together. Items marked “Not enabled” are not active yet.</span></div><div className="adminModuleDetail" id="admin-packages"><h4>Package Management</h4><p>Package catalogue, price, description, Bid Wallet activation credit, visibility and activation rules. Package editing is not yet connected to a secure Admin RPC.</p><span>Not enabled · no changes can be made here yet.</span></div>
<div className="adminModuleDetail" id="admin-commission"><h4>Referral Commission Plan</h4><p>Configure per-package and per-level fixed or percentage commissions, eligibility, effective dates and immutable rule versions. Duplicate-ID commissions must credit the Main ID Income Wallet.</p><span>Not enabled · commission rules must be implemented and tested server-side.</span></div>
<div className="adminModuleDetail" id="admin-wallets"><h4>Wallet Management</h4><p>Separate Bid Wallet and Income Wallet balances, ledger history, idempotency references and reconciliation. Bid Wallet remains bidding-only; no manual balance editing is exposed.</p><span>Read-only until secure wallet administration is implemented.</span></div>
<div className="adminModuleDetail" id="admin-withdrawals"><h4>Withdrawal Management</h4><p>Review requests, eligibility, minimum/maximum limits, fees, bank verification, payout reference and approval history.</p><span>Not enabled · withdrawals remain locked.</span></div>
<div className="adminModuleDetail" id="admin-auctions"><h4>Auction Management</h4><p>Create and manage auction listings, product details, images, start/end schedule, reserve price, bid increment and status.</p><span>Bidding is disabled in Production. No live bids can be placed.</span></div>
<div className="adminModuleDetail" id="admin-fixedbid"><h4>Fixed Bid Campaign Management</h4><p>Campaign products, entry limits, pricing, start/end times, participant list and result configuration.</p><span>Not enabled · fixed-bid winner rules have not been approved.</span></div>
<div className="adminModuleDetail" id="admin-winning"><h4>Winner & Winning Payment</h4><p>Winner confirmation, payment due date, Income Wallet eligibility, payment receipt and settlement status.</p><span>Not enabled · winner and settlement rules are still undecided.</span></div>
<div className="adminModuleDetail" id="admin-delivery"><h4>Delivery Tracking</h4><p>Collect delivery address, assign courier, save tracking ID, dispatch date and delivered/returned status.</p><span>Not enabled · delivery workflow is not connected.</span></div>
<div className="adminModuleDetail" id="admin-reports"><h4>Reports & Exports</h4><p>Member directory, sponsor genealogy, placement tree, duplicate IDs, activations, commissions, wallet transactions, withdrawals, auction and fixed-bid reports with date filters and CSV/PDF/print exports.</p><span>Current member and audit CSV exports are available; other reports need implementation.</span></div>
<div className="adminModuleDetail" id="admin-notifications"><h4>Notifications & Templates</h4><p>In-app notices, email/SMS templates, activation updates, withdrawal updates and delivery notifications with delivery logs.</p><span>Not enabled · provider integration required.</span></div>
<div className="adminModuleDetail" id="admin-roles"><h4>Roles & Permissions</h4><p>Admin account assignment, granular permissions, privileged action checks and access audit. The primary Admin email requested is kkjan2006@gmail.com; role assignment must remain server-side.</p><span>Protected · no client-side role editing.</span></div>
<div className="adminModuleDetail" id="admin-settings"><h4>Platform Settings</h4><p>Default sponsor, bidding enable/disable switch, wallet policies, package rules, withdrawal rules, referral settings and platform-wide preferences.</p><span>Default sponsor tools are available. Bidding remains disabled.</span></div>
<div id="admin-payments" className="sponsorAdmin"><div className="memberReportHeading"><h4>Pending Package Payment Verification ({pendingActivations.length})</h4><small>Approve only after independently confirming the payment in your bank/payment account.</small></div>{activationMessage&&<div className="notice" role="status">{activationMessage}</div>}{pendingActivations.length===0?<div className="empty">No pending package activation requests.</div>:<div className="referralList">{pendingActivations.map(item=><div key={item.id} className="activationReviewRow"><span><b>{item.member_code}</b> · {item.member_name||'Member'} · {item.package_name}<br/><small>Request #{item.activation_number} · Ref: {item.payment_reference} · {new Date(item.submitted_at).toLocaleString('en-IN')}</small><br/><small>Paid: {item.amount_paid} {item.currency} · Bid Wallet credit after approval: {item.bid_wallet_credit} {item.currency}</small></span><span className="activationReviewActions"><button className="primary small" disabled={reviewingActivation!==''} onClick={()=>void reviewActivation(item.id,true)}>{reviewingActivation===item.id?'Processing…':'Approve & Credit'}</button><button className="outline small" disabled={reviewingActivation!==''} onClick={()=>void reviewActivation(item.id,false)}>Reject</button></span></div>)}</div>}</div>{structure&&<div id="admin-members" className="sponsorAdmin"><h4>Member ID & Placement Report</h4><div className="mlmCards"><article><Users size={19}/><small>Total IDs</small><b>{structure.total_ids}</b></article><article><UserCheck size={19}/><small>Main IDs</small><b>{structure.main_ids}</b></article><article><Users size={19}/><small>Duplicate IDs</small><b>{structure.duplicate_ids}</b></article><article><Network size={19}/><small>Placement assigned</small><b>{structure.placement_assigned}</b></article></div><h4>Sponsor Level-wise Report</h4>{structure.sponsor_levels.length?<div className="referralList">{structure.sponsor_levels.map(row=><div key={row.level}><span><b>Level {row.level}</b></span><small>{row.members} members</small></div>)}</div>:<div className="empty">No sponsor downline records are available yet.</div>}<h4>Placement Hierarchy</h4>{structure.ids.some(row=>row.placement_parent_code)?<div className="placementTree">{structure.ids.filter(row=>row.id_type==='main'&&!row.placement_parent_code).map(row=><PlacementBranch key={row.member_code} row={row} all={structure.ids}/>)}{structure.ids.filter(row=>row.placement_parent_code&&!structure.ids.some(parent=>parent.member_code===row.placement_parent_code)).map(row=><PlacementBranch key={row.member_code} row={row} all={structure.ids}/>)}</div>:<div className="empty">No placement links have been assigned yet. The hierarchy will appear here when valid parent-child placement records exist.</div>}{structure.ids.some(row=>row.id_type==='duplicate'&&!row.placement_parent_code)&&<><h4>Duplicate IDs awaiting placement</h4><div className="referralList">{structure.ids.filter(row=>row.id_type==='duplicate'&&!row.placement_parent_code).map(row=><div key={row.member_code}><span><b>{row.member_code}</b> · {row.display_name||'Member'}</span><small>Main ID: {row.main_member_code||'—'} · {row.status}</small></div>)}</div></>}</div>}<div id="admin-audit" className="sponsorAdmin"><div className="memberReportHeading"><h4>Security & Activity Audit Log</h4><button className="outline small" onClick={exportAuditCsv} disabled={!filteredAuditLogs.length}>Export CSV</button></div><div className="sponsorAdminForm"><input value={auditSearch} onChange={e=>setAuditSearch(e.target.value)} placeholder="Search action, admin, entity ID or details"/></div>{filteredAuditLogs.length===0?<div className="empty">{auditLogs.length===0?'No audit events are available yet.':'No audit events match this search.'}</div>:<div className="referralList">{filteredAuditLogs.map(item=><div key={item.id}><span><b>{item.action.replaceAll('_',' ')}</b> · {item.entity_type}</span><small>{item.actor_name} · {new Date(item.created_at).toLocaleString('en-IN')} · {item.entity_id||'No entity reference'}</small><small>{Object.keys(item.details??{}).length?JSON.stringify(item.details):'No additional details'}</small></div>)}</div>}</div>{overview&&<div id="admin-mlm"><h4 className="referralHeading">MLM Network Overview</h4><div className="mlmCards"><article><Users size={19}/><small>Total Main IDs</small><b>{overview.total_members}</b></article><article><UserCheck size={19}/><small>Active Members</small><b>{overview.active_members}</b></article><article><Network size={19}/><small>Sponsor Relationships</small><b>{overview.direct_relationships}</b></article><article><PackageCheck size={19}/><small>Verified Activations</small><b>{overview.verified_activations}</b></article><article><AlertCircle size={19}/><small>Pending Activations</small><b>{overview.pending_activations}</b></article><article><Wallet size={19}/><small>Pending Withdrawals</small><b>{overview.withdrawal_pending}</b></article></div></div>}<div id="admin-sponsors" className="sponsorAdmin"><h4>Referral Sponsor Settings</h4><p>Set the Admin Default Sponsor ID used when a new member leaves the Sponsor field blank.</p><div className="sponsorAdminForm"><input value={defaultSponsor} onChange={e=>setDefaultSponsor(e.target.value)} placeholder="Admin Default Sponsor Main ID"/><button className="primary small" disabled={savingSponsor} onClick={()=>void saveDefaultSponsor()}>Save Default Sponsor</button></div><p>Correct a member's sponsor after registration. Past commission entries are retained as historical records.</p><div className="sponsorAdminForm"><input value={memberCode} onChange={e=>setMemberCode(e.target.value)} placeholder="Member Main ID"/><input value={sponsorCode} onChange={e=>setSponsorCode(e.target.value)} placeholder="Correct Sponsor Main ID"/><button className="outline small" disabled={savingSponsor} onClick={()=>void changeSponsor()}>Update Sponsor</button></div>{sponsorMessage&&<div className="notice">{sponsorMessage}</div>}<div className="memberReportHeading"><h4>Members and Current Sponsors ({filteredMembers.length})</h4><button className="outline small" onClick={exportMembersCsv}>Export CSV</button></div><div className="sponsorAdminForm"><input value={memberSearch} onChange={e=>setMemberSearch(e.target.value)} placeholder="Search name, member ID, phone or sponsor ID"/></div><div className="referralList">{filteredMembers.map(m=><div key={m.member_code}><span><b>{m.display_name}</b> · {m.member_code}</span><small>Phone: {m.phone||'Not available'} · Sponsor: {m.sponsor_code||'Not assigned'}</small></div>)}</div></div><div className="notice"><ShieldCheck size={17}/> Sponsor changes are server-validated and recorded in the audit log. Financial actions remain locked until their workflows are implemented.</div></div></div></section>;
}
