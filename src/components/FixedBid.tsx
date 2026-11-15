import {useEffect,useState} from 'react';
import {Gavel,Package,RefreshCw} from 'lucide-react';
import {supabase} from '../lib/supabase';
type Campaign={id:string;title:string;description:string|null;status:string;created_at:string;product: {name:string;description:string|null;category:string|null;image_path:string|null}|null};
export default function FixedBid(){
 const [rows,setRows]=useState<Campaign[]>([]),[loading,setLoading]=useState(true),[error,setError]=useState('');
 async function load(){setLoading(true);setError('');if(!supabase){setRows([]);setLoading(false);return;}
 try {
  const {data,error}=await supabase.from('fixed_bid_campaigns').select('id,title,description,status,created_at,product:products(name,description,category,image_path)').in('status',['published','active','open']).order('created_at',{ascending:false}).limit(100);
  if(error){setRows([]);setError('Fixed Bid campaigns are not available yet.');}else setRows((data??[]) as unknown as Campaign[]);
 } catch {
  setRows([]);setError('A network error prevented Fixed Bid campaigns from loading.');
 } finally {setLoading(false);}
 }
 useEffect(()=>{void load()},[]);
 return <section className="fixedBidList"><div className="packageIntro"><span className="workspaceIcon"><Gavel/></span><div><h3>Fixed Bid campaigns</h3><p>Only published or open campaigns are shown. Campaign information is read-only; no entries or payments are processed here.</p></div><button className="outline small" onClick={()=>void load()}><RefreshCw size={14}/> Refresh</button></div>
 {loading?<p className="packageState">Loading campaigns…</p>:error?<div className="notice">{error} <button className="outline small" onClick={()=>void load()}><RefreshCw size={14}/> Retry</button></div>:rows.length===0?<div className="empty">No Fixed Bid campaigns are currently published or open.</div>:
 <div className="fixedBidGrid">{rows.map(r=><article className="fixedBidCard" key={r.id}><div className="fixedBidVisual"><Package size={34}/><span>{r.product?.category??'FIXED BID'}</span></div><div className="fixedBidBody"><span className="status">{r.status.toUpperCase()}</span><h3>{r.title}</h3>{r.product?.name&&<b>{r.product.name}</b>}<p>{r.description||r.product?.description||'Campaign details will be published by the administrator.'}</p><small>Published {new Date(r.created_at).toLocaleDateString()}</small></div></article>)}</div>}
 </section>;
}