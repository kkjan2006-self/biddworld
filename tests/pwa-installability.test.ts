import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const read = (path: string) => readFileSync(resolve(process.cwd(), path), 'utf8');

describe('BiddWorld installable PWA foundation', () => {
  const html = read('index.html');
  const entry = read('src/main.tsx');
  const manifest = JSON.parse(read('public/manifest.webmanifest')) as {
    start_url: string; scope: string; display: string; icons: Array<{ src: string; sizes: string; type: string; purpose?: string }>;
  };
  const worker = read('public/sw.js');

  it('declares a standalone app with relative scope for Pages and root hosting', () => {
    expect(manifest.start_url).toBe('./');
    expect(manifest.scope).toBe('./');
    expect(manifest.display).toBe('standalone');
    expect(manifest.icons).toEqual([
      { src: './icons/biddworld-192.png', sizes: '192x192', type: 'image/png', purpose: 'any' },
      { src: './icons/biddworld-512.png', sizes: '512x512', type: 'image/png', purpose: 'any maskable' },
    ]);
    const icon192 = readFileSync(resolve(process.cwd(), 'public/icons/biddworld-192.png'));
    const icon512 = readFileSync(resolve(process.cwd(), 'public/icons/biddworld-512.png'));
    const pngSignature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
    expect(icon192.subarray(0, 8)).toEqual(pngSignature);
    expect(icon512.subarray(0, 8)).toEqual(pngSignature);
    expect(icon192.readUInt32BE(16)).toBe(192);
    expect(icon192.readUInt32BE(20)).toBe(192);
    expect(icon512.readUInt32BE(16)).toBe(512);
    expect(icon512.readUInt32BE(20)).toBe(512);
    expect(html).toContain('%BASE_URL%icons/biddworld-192.png');
    expect(html).toContain('%BASE_URL%manifest.webmanifest');
    expect(html).toContain('name="theme-color" content="#101827"');
  });

  it('registers the worker only in production and scopes it to Vite BASE_URL', () => {
    expect(entry).toContain("import.meta.env.PROD && 'serviceWorker' in navigator");
    expect(entry).toContain("import.meta.env.BASE_URL + 'sw.js'");
    expect(entry).toContain('scope: import.meta.env.BASE_URL');
  });

  it('provides an offline navigation fallback and versioned cache cleanup', () => {
    expect(worker).toContain("request.mode === 'navigate'");
    expect(worker).toContain('cache.match(APP_ROOT.href)');
    expect(worker).toContain("new URL('icons/biddworld-192.png', APP_ROOT).href");
    expect(worker).toContain("new URL('icons/biddworld-512.png', APP_ROOT).href");
    expect(worker).toContain("const CACHE_NAME = CACHE_PREFIX + 'v3'");
    expect(worker).toContain('key.startsWith(CACHE_PREFIX)');
    expect(worker).toContain('key !== CACHE_NAME');
  });

  it('never intercepts cross-origin requests or non-GET financial/API requests', () => {
    expect(worker).toContain("if (request.method !== 'GET') return;");
    expect(worker).toContain('url.origin !== self.location.origin');
    expect(worker).toContain('!url.href.startsWith(APP_ROOT.href)');
  });
});
