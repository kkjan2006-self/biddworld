-- Public marketplace may display published catalogue entries without requiring sign-in.
-- Draft products remain hidden; the live production schema uses products.status.
drop policy if exists products_public_active_read on public.products;
drop policy if exists products_public_published_read on public.products;
create policy products_public_published_read
on public.products
for select
to anon, authenticated
using (status = 'published');
