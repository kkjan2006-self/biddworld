import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const sql = readFileSync(
  resolve(process.cwd(), 'supabase/migrations/20261116020000_admin_product_management_and_media.sql'),
  'utf8',
);

describe('admin product catalogue migration security contract', () => {
  it('restricts product media writes to trusted administrators', () => {
    expect(sql).toMatch(/values\s*\('product-media','product-media',true,5242880,array\['image\/jpeg','image\/png','image\/webp'\]\)/i);
    expect(sql).toMatch(/create policy product_media_public_read[\s\S]*?for select to anon,authenticated using\(bucket_id='product-media'\)/i);
    for (const operation of ['insert', 'update', 'delete']) {
      expect(sql).toMatch(new RegExp(`create policy product_media_admin_${operation}[\\s\\S]*?for ${operation}[\\s\\S]*?bucket_id='product-media'[\\s\\S]*?app_metadata.*?role.*?admin`, 'i'));
    }
  });

  it('requires trusted Admin claims inside every privileged product RPC', () => {
    for (const fn of ['admin_list_auction_products', 'admin_save_product_draft', 'admin_set_product_active']) {
      const start = sql.indexOf('create or replace function public.' + fn);
      expect(start).toBeGreaterThanOrEqual(0);
      const body = sql.slice(start, sql.indexOf('$$;', start) + 3);
      expect(body).toMatch(/auth\.uid\(\) is null/i);
      expect(body).toMatch(/auth\.jwt\(\)->'app_metadata'->>'role'.*admin/is);
    }
  });

  it('keeps new products as drafts and bounds user-controlled product fields', () => {
    expect(sql).toMatch(/values\([\s\S]*?'draft'\)\s*returning id into v_id/i);
    expect(sql).toMatch(/length\(trim\(coalesce\(p_name,''\)\)\) < 2/i);
    expect(sql).toMatch(/length\(coalesce\(p_description,''\)\) > 5000/i);
    expect(sql).toMatch(/only existing draft products can be edited/i);
  });

  it('does not expose privileged RPC execution to anonymous users', () => {
    expect(sql).toMatch(/revoke all on function public\.admin_list_auction_products\(\) from public,anon/i);
    expect(sql).toMatch(/revoke all on function public\.admin_save_product_draft\(uuid,text,text,text,text\) from public,anon/i);
    expect(sql).toMatch(/revoke all on function public\.admin_set_product_active\(uuid,boolean\) from public,anon/i);
  });
});
