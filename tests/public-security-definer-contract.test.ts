import { readdirSync, readFileSync, statSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const root = resolve(process.cwd(), 'supabase/migrations');
const migrations: string[] = [];
const walk = (directory: string) => {
  for (const entry of readdirSync(directory)) {
    const full = resolve(directory, entry);
    const stat = statSync(full);
    if (stat.isDirectory()) walk(full);
    else if (entry.endsWith('.sql')) migrations.push(full);
  }
};
walk(root);

describe('public SECURITY DEFINER migration contract', () => {
  it('pins search_path and revokes default client execution for every public SECURITY DEFINER definition', () => {
    const findings: string[] = [];
    for (const path of migrations) {
      const sql = readFileSync(path, 'utf8');
      const definitions = /create\s+(?:or\s+replace\s+)?function\s+(public\.[a-z0-9_]+)\s*\(([^)]*)\)/gi;
      for (const match of sql.matchAll(definitions)) {
        const name = match[1];
        const headerStart = match.index! + match[0].length;
        const bodyStart = sql.indexOf('$function$', headerStart);
        if (bodyStart < 0) continue;
        const header = sql.slice(headerStart, bodyStart);
        if (!/security\s+definer/i.test(header)) continue;
        if (!/set\s+search_path\s*(?:to\s*)?=/i.test(header)) {
          findings.push(`${path}: ${name} has no fixed search_path`);
        }
        const revokePattern = new RegExp('revoke\\s+all\\s+on\\s+function\\s+' + name.replace('.', '\\.') + '\\s*\\(', 'i');
        if (!revokePattern.test(sql)) {
          findings.push(`${path}: ${name} has no explicit EXECUTE revocation`);
        }
      }
    }
    expect(findings, findings.join('\n')).toEqual([]);
  });
});
