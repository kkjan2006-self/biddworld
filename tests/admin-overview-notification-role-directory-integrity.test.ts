import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const source=readFileSync('src/components/Admin.tsx','utf8');
describe('Admin overview, structure, notification and role directory integrity',()=>{
 it('validates overview counters before updating dashboard totals',()=>{
  expect(source).toContain('function parseMlmOverview(value:unknown)');
  expect(source).toContain('MLM overview count fields must be whole numbers.');
  expect(source).toContain('overviewData=parseMlmOverview(overviewResult.data)');
  expect(source).toContain('members:overviewData?overviewData.total_members:current.members');
 });
 it('validates member structure identities and summary collections',()=>{
  expect(source).toContain('function parseMemberStructure(value:unknown)');
  expect(source).toContain('Member structure summary does not match its ID records.');
  expect(source).toContain('Duplicate ID is missing its owner Main ID.');
  expect(source).toContain('setStructure(parseMemberStructure(structureResult.data))');
 });
 it('validates notification template channels, content and timestamps',()=>{
  expect(source).toContain('function parseNotificationTemplates(value:unknown)');
  expect(source).toContain("!['in_app','email','sms'].includes(String(row.channel))");
  expect(source).toContain('Notification template list contains malformed or duplicate records.');
  expect(source).toContain('setNotificationTemplates(parseNotificationTemplates(notificationResult.data??[]))');
 });
 it('validates Admin account identity, role and timestamps',()=>{
  expect(source).toContain('function parseAdminAccounts(value:unknown)');
  expect(source).toContain('Admin account list contains malformed or duplicate records.');
  expect(source).toContain('setAdminAccounts(parseAdminAccounts(adminAccountsResult.data??[]))');
 });
 it('isolates malformed responses and does not change role mutation RPCs',()=>{
  expect(source).toContain("setLoadWarnings(current=>[...current,'Member structure: '");
  expect(source).toContain("setTemplateMessage(issue instanceof Error?issue.message:'Notification template list returned invalid records.')");
  expect(source).toContain("supabase.rpc('admin_set_user_admin_role'");
 });
});
