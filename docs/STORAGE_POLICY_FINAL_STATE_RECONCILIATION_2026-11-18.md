# Package receipt and product media Storage policy reconciliation — 2026-11-18

## Package receipts: ordered policy changes

Reviewed the complete relevant source chain:

1. `20261118150000_package_receipt_uploads.sql` creates the private `package-receipts` bucket, a member-folder INSERT policy, and an initial SELECT policy allowing the owner or an Admin. It adds `package_activations.receipt_path`, a member submission RPC that validates the signed-in user's folder and object existence, and an Admin pending queue.
2. `20261118350000_private_package_receipt_storage.sql` reasserts the bucket as private, sets the 5 MiB and JPEG/PNG/PDF restrictions, replaces the upload policy, and replaces SELECT with Admin-only access.
3. `20261118360000_admin_pending_activation_receipt_path.sql` replaces the pending-queue RPC to include `receipt_path`, joins the Auth user row, and orders newest pending submissions first.
4. `20261118370000_restrict_package_receipt_reads_to_admin.sql` removes legacy owner-read policy names and recreates the member-folder INSERT and Admin-only SELECT policies.

### Expected final package-receipt access

- Bucket: private (`public=false`).
- Member: INSERT only under the first path segment equal to `auth.uid()`.
- Admin: SELECT only when `app_metadata.role='admin'`.
- Member SELECT, public SELECT, UPDATE and DELETE are not granted by this migration chain.
- Admin pending queue returns the receipt path for signed-URL generation by the Admin UI.

Static review confirms the later policy replacements remove the earlier owner-read policy and leave the intended Admin-only SELECT rule. This does not prove effective access after replay; Storage policy names and OR-composition must still be checked in isolated TEST during final validation.

## Product media

`20261116020000_admin_product_management_and_media.sql` creates/reasserts the `product-media` bucket as public, with a 5 MiB limit and JPEG/PNG/WebP MIME allow-list. It grants public SELECT and Admin-only INSERT/UPDATE/DELETE. This is separate from the private package receipt bucket and should remain so.

## Outstanding verification

- Confirm the Admin UI uses `admin_list_pending_activations()` and generates signed URLs only for Admin review.
- Confirm the Member upload flow uses the `package-receipts/<auth.uid()>/...` object path and does not depend on member SELECT after upload.
- In final TEST replay, inspect all effective policies on `storage.objects` for both buckets, including any policies predating this chain; policies are OR-composed.
- No migrations were applied and no Production or TEST data/schema was changed during this review.
- No tests or build were run; all conclusions are source-level.
