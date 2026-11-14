# Security notes
- Browser uses only Supabase public anon/publishable key.
- All application tables enable RLS; client-side insert/update/delete grants are revoked in the baseline migration.
- User-visible reads are scoped by `auth.uid()` or active catalogue status.
- Financial operations must be implemented as audited transactional RPCs or Edge Functions.
- Never trust client-provided balances, roles, commission values, payment status or winner identity.
- Admin roles must be assigned only by a trusted server-side process.
- Configure Auth redirect URLs, password policy, email confirmation, storage policies, rate limits, backups and monitoring before launch.
