import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const read = (path: string) => readFileSync(resolve(process.cwd(), path), 'utf8');
const manifest = JSON.parse(read('docs/FRONTEND_RPC_INVENTORY.json')) as {
  rpc_calls: { name: string; ui: string }[];
};
const surfaces = [
  'src/App.tsx',
  ...readdirSync(resolve(root,'src/components')).filter(path=>path.endsWith('.tsx')).map(path=>'src/components/'+path),
];

describe('Frontend RPC inventory completeness', () => {
  it('has one explicit manifest entry for every literal RPC call on every React surface', () => {
    const discovered = new Map<string, Set<string>>();
    for (const path of surfaces) {
      const source = read(path);
      const pattern = /\.rpc(?:<[^>]+>)?\s*\(\s*['"\x60]([a-zA-Z0-9_]+)['"\x60]/g;
      for (const match of source.matchAll(pattern)) {
        const files = discovered.get(match[1]) ?? new Set<string>();
        files.add(path);
        discovered.set(match[1], files);
      }
    }
    const declared = new Map<string, Set<string>>();
    for (const item of manifest.rpc_calls) {
      const files = declared.get(item.name) ?? new Set<string>();
      files.add(item.ui);
      declared.set(item.name, files);
    }
    expect([...declared.keys()].sort()).toEqual([...discovered.keys()].sort());
    for (const [name, files] of discovered) {
      expect([...declared.get(name) ?? []].sort(), name).toEqual([...files].sort());
    }
  });

  it('contains no duplicate RPC-and-surface entries and only references known UI surfaces', () => {
    const keys = manifest.rpc_calls.map(item => item.name + '|' + item.ui);
    expect(new Set(keys).size).toBe(keys.length);
    for (const item of manifest.rpc_calls) {
      expect(surfaces).toContain(item.ui);
    }
  });

  it('records the snapshot limitation so source inventory is not mistaken for live Production verification', () => {
    expect(manifest.note).toContain('does not certify live Production');
    expect(manifest.snapshot_commit).toMatch(/^[0-9a-f]{40}$/);
  });
});
