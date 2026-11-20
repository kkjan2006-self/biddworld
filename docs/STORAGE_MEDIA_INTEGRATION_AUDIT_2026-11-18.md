# Storage and Media Integration Audit — 2026-11-18

## Scope and safety
- Inspected the Admin product-media upload flow, member package-receipt upload flow, Admin receipt preview flow, and their source migrations.
- Queried Production Storage catalogue metadata only.
- No Storage bucket, object, policy, database, or auth changes were made. No tests/build were run.

## Live Production Storage state
The read-only Production catalogue query returned:
- Storage buckets: 0
- Storage object policies: 0
- Storage objects: 0
- `storage.objects` RLS enabled: yes

This confirms that neither source-defined bucket is present in live Production at the time of this audit. The Storage feature paths are therefore not live-ready in Production until the intended migration chain is deployed in an explicitly authorized release phase.

## Product media integration
Source migration: `20261116020000_admin_product_management_and_media.sql`

- Defines public `product-media` bucket.
- Maximum file size 5 MB; MIME allowlist JPG, PNG, WebP.
- Public read policy; authenticated Admin-only insert, update and delete policies.
- Admin UI validates MIME type and size before upload.
- Uploads a unique object path, obtains its public URL, and stores that URL in the product draft.
- Allows an Admin to discard an unattached staged image and attempts to remove a previously staged image after a replacement upload.

The upload flow and bucket policy are aligned at the source level. Runtime Storage behavior remains unverified because no bucket/policies exist in Production and TEST baseline is not yet ready.

## Package receipt integration
Source migration: `20261118150000_package_receipt_uploads.sql`

- Defines private `package-receipts` bucket.
- Maximum file size 5 MB; MIME allowlist JPG, PNG, PDF.
- Member insert and read are restricted to the authenticated user's UID folder.
- Admin can read receipts.
- Members do not receive a delete policy after upload.
- Server RPC verifies that the submitted receipt path belongs to the signed-in user and that the object exists before associating it with the activation.

Frontend integration:
- `Packages.tsx` validates type and size, uploads under the authenticated user's UID folder, then calls `submit_package_activation_with_receipt`.
- `Admin.tsx` creates a short-lived signed URL (300 seconds) for an Admin to preview a receipt.

The source path conventions and policies match. Runtime upload, RLS, signed URL and RPC behavior still require isolated TEST validation after clean-install bootstrap.

## Deployment and validation dependencies
1. Include both bucket definitions and policies in the canonical clean-install migration sequence.
2. Apply only to the isolated TEST project after its baseline is proven clean and complete.
3. Verify Admin-only product upload, public product image read, member own receipt upload/read, cross-member denial, Admin receipt signed URL, and member delete denial.
4. Do not use Production as a test environment. Keep Production untouched until an explicitly authorized release phase.

## Conclusion
Both Storage workflows are implemented in checked-in frontend/source migrations, but live Production currently has no buckets or Storage object policies. This is a documented deployment dependency, not a completed runtime verification.
