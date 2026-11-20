import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';

const source=readFileSync('src/components/Notifications.tsx','utf8');

describe('notification read action persistence reconciliation',()=>{
 it('uses the persisted single-row update result before changing local inbox state',()=>{
  expect(source).toContain("request.select('id,read_at').maybeSingle()");
  expect(source).toContain("updated.id!==id");
  expect(source).toContain("setItems(rows=>rows.map(row=>row.id===id?{...row,read_at:updated.read_at}:row))");
  expect(source).toContain('else{await load();}');
 });
 it('reconciles bulk mark-read state only from rows actually returned by the database',()=>{
  expect(source).toContain(".is('read_at',null).select('id,read_at')");
  expect(source).toContain('const changed=new Map<string,string>()');
  expect(source).toContain('changed.has(row.id)');
  expect(source).toContain('const persistedAt=changed.get(row.id)');
  expect(source).not.toContain("setItems(rows=>rows.map(row=>row.read_at?row:{...row,read_at:readAt}))");
 });
 it('rejects malformed persisted read timestamps and duplicate bulk identities',()=>{
  expect(source).toContain("!Number.isFinite(Date.parse(updated.read_at))");
  expect(source).toContain("!Number.isFinite(Date.parse(row.read_at))||changed.has(row.id)");
  expect(source).toContain('invalid bulk read-status records');
 });
});
