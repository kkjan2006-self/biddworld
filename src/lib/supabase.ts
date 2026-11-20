import { createClient, type SupabaseClient } from '@supabase/supabase-js';

// Never silently connect a preview build to the live Production database.
// Each deployment must explicitly supply its project URL and publishable key.
import {getSupabaseConfigurationError} from './supabase-environment';

export type BiddWorldMode = 'preview' | 'test' | 'live';
const requestedMode = (import.meta.env.VITE_BIDDWORLD_MODE || 'preview').trim().toLowerCase();
export const appMode: BiddWorldMode = requestedMode === 'test' || requestedMode === 'live' ? requestedMode : 'preview';
const projectUrl = (import.meta.env.VITE_SUPABASE_URL || '').trim();
const publishableKey = (import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || import.meta.env.VITE_SUPABASE_ANON_KEY || '').trim();
export const configurationError = getSupabaseConfigurationError(appMode,projectUrl,publishableKey);
export const configured = !configurationError;

export const supabase: SupabaseClient | null = configured
  ? createClient(projectUrl, publishableKey, {
      auth: {
        autoRefreshToken: true,
        persistSession: true,
        detectSessionInUrl: true,
      },
    })
  : null;
