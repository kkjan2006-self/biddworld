-- Public marketplace may display active catalogue entries without requiring sign-in.
-- Admin/draft product rows remain hidden; this policy grants read access only.
drop policy if exists products_public_active_read on public.products;
create policy products_public_active_read
on public.products
for select
to anon, authenticated
using (is_active = true);
