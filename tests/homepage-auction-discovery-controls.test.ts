import {describe,expect,it} from 'vitest';
import {readFileSync} from 'node:fs';

const app=readFileSync('src/App.tsx','utf8');
const css=readFileSync('src/style.css','utf8');

describe('Homepage auction discovery controls',()=>{
 it('exposes the existing category and sort state as visible controls',()=>{
  const home=app.slice(app.indexOf(":tab==='Auctions'?"),app.indexOf(':<div className="workspace"><div className="workspaceIcon"><ShieldCheck/></div><h3>{tab}'));
  expect(home).toContain('homeMarketFilters');
  expect(home).toMatch(/value={category} onChange={e=>setCategory\(e\.target\.value\)}/);
  expect(home).toMatch(/value={sort} onChange={e=>setSort\(e\.target\.value\)}/);
  expect(home).toContain('Price: low to high');
  expect(home).toContain('Price: high to low');
  expect(home).toContain('Ending soon');
  expect(app).toContain('aria-expanded={mobileNav}');
  expect(app).toContain('aria-controls="primary-navigation"');
  expect(app).toContain("aria-label={tab==='Auctions'?'Search auctions':'Search products'}");
 });
 it('provides visible keyboard focus and respects reduced-motion preferences',()=>{
  expect(css).toMatch(/:where\(button,a,input,select,textarea,summary,\[tabindex\]\):focus-visible/);
  expect(css).toMatch(/@media\(prefers-reduced-motion:reduce\)/);
 });
});
