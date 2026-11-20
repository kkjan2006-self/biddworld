import {useEffect,useMemo,useRef,useState} from 'react';
import {supabase} from '../lib/supabase';

type PackageOption={id:string;name:string;is_active:boolean};
type MatrixRule={level:number;enabled:boolean;reward_type:'fixed'|'percentage';reward_value:string;eligibility_rule:string};
type MatrixPlan={id:string;package_id:string;version_number:number;matrix_width:number;placement_depth:number;matrix_depth:number;is_active:boolean;created_at:string;levels:{level:number;enabled:boolean;reward_type:'fixed'|'percentage';reward_value:number;eligibility_rule:Record<string,unknown>}[]};

const makeRules=(depth:number):MatrixRule[]=>Array.from({length:depth},(_,i)=>({level:i+1,enabled:false,reward_type:'fixed',reward_value:'0',eligibility_rule:'{}'}));
function parseMatrixPlans(value:unknown,packageId:string):MatrixPlan[]{
 if(!Array.isArray(value)||value.length>200)throw new Error('Matrix plan response is invalid or exceeds the safety limit.');
 const ids=new Set<string>(),versions=new Set<number>();let activeCount=0;
 return value.map(raw=>{
  if(!raw||typeof raw!=='object'||Array.isArray(raw))throw new Error('Matrix plan record is malformed.');
  const row=raw as Record<string,unknown>;
  if(typeof row.id!=='string'||!row.id.trim()||ids.has(row.id)||row.package_id!==packageId||!Number.isInteger(row.version_number)||Number(row.version_number)<1||versions.has(Number(row.version_number))||!Number.isInteger(row.matrix_width)||Number(row.matrix_width)<2||Number(row.matrix_width)>100||!Number.isInteger(row.placement_depth)||Number(row.placement_depth)<1||Number(row.placement_depth)>50||!Number.isInteger(row.matrix_depth)||Number(row.matrix_depth)<1||Number(row.matrix_depth)>50||typeof row.is_active!=='boolean'||typeof row.created_at!=='string'||!Number.isFinite(Date.parse(row.created_at))||!Array.isArray(row.levels)||row.levels.length!==row.matrix_depth)throw new Error('Matrix plan record contains invalid fields.');
  const levels=new Set<number>();
  for(const rawLevel of row.levels){
   if(!rawLevel||typeof rawLevel!=='object'||Array.isArray(rawLevel))throw new Error('Matrix plan level is malformed.');
   const level=rawLevel as Record<string,unknown>;
   if(!Number.isInteger(level.level)||Number(level.level)<1||Number(level.level)>Number(row.matrix_depth)||levels.has(Number(level.level))||typeof level.enabled!=='boolean'||!['fixed','percentage'].includes(String(level.reward_type))||!Number.isFinite(Number(level.reward_value))||Number(level.reward_value)<0||(level.reward_type==='percentage'&&Number(level.reward_value)>100)||!level.eligibility_rule||typeof level.eligibility_rule!=='object'||Array.isArray(level.eligibility_rule))throw new Error('Matrix plan level contains invalid fields.');
   levels.add(Number(level.level));
  }
  if(levels.size!==Number(row.matrix_depth))throw new Error('Matrix plan levels are incomplete.');
  ids.add(row.id);versions.add(Number(row.version_number));if(row.is_active){activeCount++;if(activeCount>1)throw new Error('A package cannot have more than one active Matrix plan.');}return row as unknown as MatrixPlan;
 });
}

export default function AdminMatrixPlans({packages}:{packages:PackageOption[]}){
 const [packageId,setPackageId]=useState('');
 const [width,setWidth]=useState('5');
 const [placementDepth,setPlacementDepth]=useState('5');
 const [depth,setDepth]=useState('5');
 const [rules,setRules]=useState<MatrixRule[]>(makeRules(5));
 const [plans,setPlans]=useState<MatrixPlan[]>([]);
 const [busy,setBusy]=useState(false);
 const [message,setMessage]=useState('');
 const [loading,setLoading]=useState(false);
 const requestGeneration=useRef(0);
 const selectedPackage=packages.find(p=>p.id===packageId);
 const depthNumber=Math.max(1,Math.min(50,Number(depth)||1));
 const activePlan=useMemo(()=>plans.find(p=>p.is_active),[plans]);

 useEffect(()=>{
  setRules(current=>Array.from({length:depthNumber},(_,i)=>current[i]??makeRules(depthNumber)[i]));
 },[depthNumber]);

 async function loadPlans(id=packageId){
  const request=++requestGeneration.current;
  if(!supabase||!id){setPlans([]);setLoading(false);return;}
  setLoading(true);setMessage('');
  try{const{data,error}=await supabase.rpc('admin_list_matrix_plans',{p_package_id:id});if(error)throw error;const parsed=parseMatrixPlans(data,id);if(request!==requestGeneration.current)return;setPlans(parsed);}
  catch(e){if(request===requestGeneration.current){setPlans([]);setMessage(e instanceof Error?e.message:'Matrix plans could not be loaded. Apply the Matrix plan migration before using this module.');}}
  finally{if(request===requestGeneration.current)setLoading(false);}
 }
 useEffect(()=>{if(packageId){setPlans([]);void loadPlans(packageId);}else{requestGeneration.current++;setPlans([]);setLoading(false);}return()=>{requestGeneration.current++;};},[packageId]);

 function updateRule(index:number,patch:Partial<MatrixRule>){
  setRules(current=>current.map((rule,i)=>i===index?{...rule,...patch}:rule));
 }
 async function saveDraft(){
  if(!supabase||busy)return;
  const w=Number(width),pd=Number(placementDepth),d=Number(depth);
  if(!packageId){setMessage('Select a package first.');return;}
  if(!Number.isInteger(w)||w<2||w>100){setMessage('Matrix width must be a whole number from 2 to 100.');return;}
  if(!Number.isInteger(pd)||pd<1||pd>50){setMessage('Placement depth must be a whole number from 1 to 50.');return;}
  if(!Number.isInteger(d)||d<1||d>50){setMessage('Commission depth must be a whole number from 1 to 50.');return;}
  if(rules.length!==d){setMessage('The level rules do not match the configured depth.');return;}
  const payload=[];
  try{
   for(let i=0;i<d;i++){
    const rule=rules[i],value=Number(rule.reward_value);
    if(rule.level!==i+1||!Number.isFinite(value)||value<0||(rule.reward_type==='percentage'&&value>100)){throw new Error('Check the reward value and sequential level '+(i+1)+'.');}
    const eligibility=JSON.parse(rule.eligibility_rule||'{}');
    if(!eligibility||typeof eligibility!=='object'||Array.isArray(eligibility))throw new Error('Eligibility for Level '+(i+1)+' must be a JSON object.');
    payload.push({level:rule.level,enabled:rule.enabled,reward_type:rule.reward_type,reward_value:value,eligibility_rule:eligibility});
   }
  }catch(e){setMessage(e instanceof Error?e.message:'Invalid Matrix level configuration.');return;}
  setBusy(true);setMessage('');
  try{const{data,error}=await supabase.rpc('admin_save_matrix_plan_draft',{p_package_id:packageId,p_matrix_width:w,p_placement_depth:Number(placementDepth),p_matrix_depth:d,p_rules:payload});if(error)throw error;if(!data||typeof data!=='object'||Array.isArray(data))throw new Error('The server returned an invalid Matrix draft result.');const result=data as Record<string,unknown>;if(typeof result.plan_id!=='string'||!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(result.plan_id)||!Number.isInteger(result.version_number)||Number(result.version_number)<1||result.matrix_width!==w||result.placement_depth!==pd||result.matrix_depth!==d||result.is_active!==false)throw new Error('The saved Matrix draft result did not match the submitted package configuration. Refresh the plan directory before retrying.');setMessage('Matrix plan draft v'+result.version_number+' saved. It is not active.');await loadPlans(packageId);}
  catch(e){setMessage(e instanceof Error?e.message:'Matrix plan draft could not be saved.');}
  finally{setBusy(false);}
 }
 async function activate(plan:MatrixPlan){
  if(!supabase||busy)return;
  if(selectedPackage?.is_active){setMessage('This package is already published. The backend prevents changing its Matrix plan.');return;}
  if(!window.confirm('Activate Matrix plan v'+plan.version_number+' for this package?'))return;
  setBusy(true);setMessage('');
  try{const{data,error}=await supabase.rpc('admin_activate_matrix_plan',{p_package_id:packageId,p_plan_version_id:plan.id});if(error)throw error;if(!data||typeof data!=='object'||Array.isArray(data))throw new Error('The server returned an invalid Matrix activation result.');const result=data as Record<string,unknown>;if(result.success!==true||result.plan_id!==plan.id||result.matrix_width!==plan.matrix_width||result.matrix_depth!==plan.matrix_depth)throw new Error('The Matrix activation result did not match the selected plan. Refresh the plan directory before retrying.');setMessage('Matrix plan v'+plan.version_number+' is now active for this package.');await loadPlans(packageId);}
  catch(e){setMessage(e instanceof Error?e.message:'Matrix plan could not be activated.');}
  finally{setBusy(false);}
 }
 return <section className="sponsorAdmin" aria-label="Matrix plan configuration">
  <h3>Package Matrix Plans</h3>
  <p>Configure placement width independently from commission depth. Sponsor Referral plans remain separate. Saving creates a new inactive version; activating is available only while the package is unpublished.</p>
  {message&&<div className="notice" role="status">{message}</div>}
  <div className="adminModuleDetail">
   <label>Package<select value={packageId} disabled={busy} onChange={e=>{setPackageId(e.target.value);setMessage('');}}><option value="">Select a package</option>{packages.map(p=><option key={p.id} value={p.id}>{p.name}{p.is_active?' · Published':''}</option>)}</select></label>
   {selectedPackage?.is_active&&<div className="notice">This package is published. Existing Matrix plan history is read-only.</div>}
   <div className="sponsorAdminForm">
    <label>Matrix Width (1:X)<input type="number" min="2" max="100" step="1" value={width} onChange={e=>setWidth(e.target.value)}/><small>Predefined widths: 1:3, 1:4, 1:5, 1:6, 1:7. Custom width: any whole number from 2 to 100.</small></label>
    <label>Placement Depth<input type="number" min="1" max="50" step="1" value={placementDepth} onChange={e=>setPlacementDepth(e.target.value)}/><small>Maximum levels for automatic Matrix placement.</small></label>
    <label>Commission Depth (levels)<input type="number" min="1" max="50" step="1" value={depth} onChange={e=>setDepth(e.target.value)}/><small>Number of Matrix commission levels; independent of placement depth.</small></label>
   </div>
   <h4>Level-wise Matrix Commission Rules</h4>
   {rules.slice(0,depthNumber).map((rule,index)=><article className="adminModuleDetail" key={rule.level}>
    <div className="memberReportHeading"><b>Level {rule.level}</b><label><input type="checkbox" checked={rule.enabled} onChange={e=>updateRule(index,{enabled:e.target.checked})}/> Enable commission</label></div>
    <div className="sponsorAdminForm">
     <label>Commission Type<select value={rule.reward_type} onChange={e=>updateRule(index,{reward_type:e.target.value as MatrixRule['reward_type']})}><option value="fixed">Fixed Amount (₹)</option><option value="percentage">Percentage (%)</option></select></label>
     <label>Reward Value<input type="number" min="0" max={rule.reward_type==='percentage'?'100':'10000000'} step="0.01" value={rule.reward_value} onChange={e=>updateRule(index,{reward_value:e.target.value})}/></label>
    </div>
    <label>Eligibility Rules (JSON object)<textarea rows={2} value={rule.eligibility_rule} onChange={e=>updateRule(index,{eligibility_rule:e.target.value})} placeholder='{}'/></label>
   </article>)}
   <button type="button" className="primary small" disabled={busy||loading||!packageId||selectedPackage?.is_active} onClick={()=>void saveDraft()}>{busy?'Saving…':'Save New Matrix Plan Draft'}</button>
   <small>Matrix width accepts 2–100 child positions; depth accepts 1–50 commission levels. A commission rule is stored separately for each level. Eligibility JSON is validated before saving.</small>
  </div>
  <div className="adminModuleDetail">
   <div className="memberReportHeading"><h4>Saved Plan Versions</h4><button type="button" className="outline small" disabled={loading||!packageId} onClick={()=>void loadPlans()}>{loading?'Loading…':'Refresh'}</button></div>
   {!packageId?<div className="empty">Select a package to view its Matrix plan versions.</div>:loading?<div className="packageState">Loading Matrix plans…</div>:plans.length===0?<div className="empty">No Matrix plan versions found for this package.</div>:<div className="referralList">{plans.map(plan=><article key={plan.id}>
    <div className="memberReportHeading"><b>Version {plan.version_number}</b><span>{plan.is_active?'Active':'Draft'}</span></div>
    <small>Width 1:{plan.matrix_width} · Placement depth {plan.placement_depth} · Commission depth {plan.matrix_depth} · Created {new Date(plan.created_at).toLocaleString('en-IN')}</small>
    <small>{plan.levels.filter(level=>level.enabled).length} of {plan.matrix_depth} commission levels enabled</small>
    {!plan.is_active&&<button type="button" className="outline small" disabled={busy||selectedPackage?.is_active} onClick={()=>void activate(plan)}>Activate this plan</button>}
   </article>)}</div>}
   {activePlan&&<small>Current active plan: v{activePlan.version_number} · Width 1:{activePlan.matrix_width} · Placement depth {activePlan.placement_depth} · Commission depth {activePlan.matrix_depth}</small>}
  </div>
 </section>;
}
