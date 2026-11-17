/** Detect PostgREST/PostgreSQL errors that indicate the deployed RPC signature is missing or stale. */
export function isRpcContractUnavailable(error: unknown): boolean {
  if (!error || typeof error !== 'object') return false;
  const value = error as { code?: unknown; message?: unknown; details?: unknown };
  const code = typeof value.code === 'string' ? value.code : '';
  const message = [value.message, value.details].filter((part): part is string => typeof part === 'string').join(' ');
  return code === 'PGRST202' || code === '42883' || /could not find the function .* in the schema cache|function .* does not exist/i.test(message);
}
