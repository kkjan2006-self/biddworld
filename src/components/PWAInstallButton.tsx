import {useEffect,useState} from 'react';
import {Download, Smartphone} from 'lucide-react';

type BeforeInstallPromptEvent=Event&{
 prompt:()=>Promise<void>;
 userChoice:Promise<{outcome:'accepted'|'dismissed';platform?:string}>;
};

export default function PWAInstallButton(){
 const[promptEvent,setPromptEvent]=useState<BeforeInstallPromptEvent|null>(null);
 const[installed,setInstalled]=useState(false);
 const[showHelp,setShowHelp]=useState(false);
 const userAgent=typeof navigator==='undefined'?'':navigator.userAgent;
 const isAppleMobile=/iPad|iPhone|iPod/.test(userAgent)||(typeof navigator!=='undefined'&&navigator.platform==='MacIntel'&&navigator.maxTouchPoints>1);
 const isAndroid=/Android/i.test(userAgent);

 useEffect(()=>{
  const standaloneQuery=window.matchMedia('(display-mode: standalone)');
  const syncInstalled=()=>{
   const appleStandalone='standalone' in navigator&&Boolean((navigator as Navigator&{standalone?:boolean}).standalone);
   setInstalled(standaloneQuery.matches||appleStandalone);
  };
  const onBeforeInstall=(event:Event)=>{
   event.preventDefault();
   setPromptEvent(event as BeforeInstallPromptEvent);
  };
  const onInstalled=()=>{
   setInstalled(true);
   setPromptEvent(null);
   setShowHelp(false);
  };
  syncInstalled();
  standaloneQuery.addEventListener?.('change',syncInstalled);
  window.addEventListener('beforeinstallprompt',onBeforeInstall as EventListener);
  window.addEventListener('appinstalled',onInstalled);
  return()=>{
   standaloneQuery.removeEventListener?.('change',syncInstalled);
   window.removeEventListener('beforeinstallprompt',onBeforeInstall as EventListener);
   window.removeEventListener('appinstalled',onInstalled);
  };
 },[]);

 async function install(){
  const current=promptEvent;
  if(!current){
   setShowHelp(value=>!value);
   return;
  }
  try{
   await current.prompt();
   const choice=await current.userChoice;
   if(choice.outcome==='accepted')setShowHelp(false);
  }catch{
   // The browser owns the install prompt and may reject a dismissed or stale event.
  }finally{
   setPromptEvent(null);
  }
 }

 if(installed)return null;
 return <div className="pwaInstallControl">
  <button type="button" className="outline small" onClick={()=>void install()} aria-label={promptEvent?'Install BiddWorld app':'How to install BiddWorld app'} aria-expanded={showHelp}>
   <Download size={15}/> {promptEvent?'Install App':'How to install'}
  </button>
  {showHelp&&<div className="notice pwaInstallHelp" role="status">
   <b><Smartphone size={15}/> Add BiddWorld to your phone</b>
   <p>{isAppleMobile?'In Safari on iPhone or iPad, tap Share, choose “Add to Home Screen”, then tap “Add”.':isAndroid?'In Chrome on Android, open the browser menu (⋮) and choose “Install app” or “Add to Home screen”. If that option is not shown, open this page in Chrome and try again later.':'Open your browser menu and look for “Install app” or “Add to Home screen”. On iPhone or iPad, open this page in Safari, tap Share, then choose “Add to Home Screen”.'}</p>
   <button type="button" className="switchAuth" onClick={()=>setShowHelp(false)}>Close</button>
  </div>}
 </div>;
}
