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
  it('checks the latest public SECURITY DEFINER definition for fixed search_path and explicit EXECUTE revocation', () => {
    const latest = new Map<string, { path: string; header: string; sql: string; name: string }>();
    for (const path of migrations.sort()) {
      const sql = readFileSync(path, 'utf8');
      const definitions = /create\\s+(?:or\\s+replace\\s+)?function\\s+(public\\.[a-z0-9_]+)\\s*\\(([^)]*)\\)/gi;
      for (const match of sql.matchAll(definitions)) {
        const name = match[1];
        const signature = match[2].replace(/\\s+/g, '').toLowerCase();
        const headerStart = match.index! + match[0].length;
        const bodyStart = sql.indexOf('$function$', headerStart);
        if (bodyStart < 0) continue;
        latest.set(name + '(' + signature + ')', {
          path, name, sql, header: sql.slice(headerStart, bodyStart),
        });
      }
    }
    const findings: string[] = [];
    for (const item of latest.values()) {
      if (!/security\\s+definer/i.test(item.header)) continue;
      if (!/set\\s+search_path\\s*(?:(?:to\\s+)?|(?:=\\s*))['"]?[^;\\n]+/i.test(item.header)) {
        findings.push(`${item.path}: ${item.name} has no fixed search_path`);
      }
      const revokePattern = new RegExp('revoke\\\\s+all\\\\s+on\\\\s+function\\\\s+' + item.name.replace('.', '\\\\.') + '\\\\s*\\\\(', 'i');
      const allSql = migrations.map(path => readFileSync(path, 'utf8')).join('\\n');
      if (!revokePattern.test(allSql)) {
        findings.push(`${item.path}: ${item.name} has no explicit EXECUTE revocation`);
      }
    }
    expect(findings, findings.join('\\n')).toEqual([]);
  });
});
