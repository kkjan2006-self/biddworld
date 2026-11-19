export type BiddWorldMode = 'preview' | 'test' | 'live';

export const BIDDWORLD_PRODUCTION_PROJECT_REF = 'hbqatszyzqobgtauyuzy';
export const BIDDWORLD_TEST_PROJECT_REF = 'yoaauthwejdgaevfvwpo';

export function getSupabaseConfigurationError(mode:BiddWorldMode,projectUrl:string,publishableKey:string):string{
  if(!projectUrl||!publishableKey)return 'Supabase is not configured. Add the URL and public publishable key for the selected environment.';
  let parsed:URL;
  try{parsed=new URL(projectUrl);}catch{return 'The Supabase URL is invalid. Use the HTTPS project URL from Supabase settings.';}
  if(parsed.protocol!=='https:'||!/^([a-z0-9-]+)\.supabase\.co$/i.test(parsed.hostname)||parsed.username||parsed.password||parsed.port||parsed.pathname!=='/'&&parsed.pathname!==''||parsed.search||parsed.hash){
    return 'The Supabase URL is invalid. Use the HTTPS project URL from Supabase settings.';
  }
  const projectRef=parsed.hostname.split('.')[0].toLowerCase();
  if(mode==='test'&&projectRef!==BIDDWORLD_TEST_PROJECT_REF)return 'Safety block: Test Mode must connect only to the dedicated BiddWorld Test project.';
  if(mode==='live'&&projectRef!==BIDDWORLD_PRODUCTION_PROJECT_REF)return 'Safety block: Live Mode must use the approved BiddWorld-Production project.';
  if(mode==='preview'&&projectRef===BIDDWORLD_PRODUCTION_PROJECT_REF)return 'Safety block: Preview Mode cannot connect to BiddWorld-Production.';
  return '';
}
