import { createClient, type SupabaseClient } from '@supabase/supabase-js';

// Public browser configuration. Build-time variables may override these values,
// but the GitHub Pages preview remains configured even if its build environment
// omits Vite variables.
const projectUrl = (
  import.meta.env.VITE_SUPABASE_URL || 'https://hbqatszyzqobgtauyuzy.supabase.co'
).trim();
const publishableKey = (
  import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY ||
  import.meta.env.VITE_SUPABASE_ANON_KEY ||
  'sb_publishable_hdgI3LooDiX9yf91dcYQ_qSI8AqoY'
).trim();

export const configured = Boolean(projectUrl && publishableKey);

export const supabase: SupabaseClient | null = configured
  ? createClient(projectUrl, publishableKey, {
      auth: {
        autoRefreshToken: true,
        persistSession: true,
        detectSessionInUrl: true,
      },
    })
  : null;
