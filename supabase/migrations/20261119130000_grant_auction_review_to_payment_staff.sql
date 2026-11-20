-- Add auction moderation to the restricted Staff role without granting unrelated Admin privileges.
update auth.users
set raw_app_meta_data=jsonb_set(
 coalesce(raw_app_meta_data,'{}'::jsonb),
 '{permissions}',
 (case when jsonb_typeof(raw_app_meta_data->'permissions')='array' then raw_app_meta_data->'permissions' else '[]'::jsonb end)
 || case when coalesce(raw_app_meta_data->'permissions','[]'::jsonb) ? 'auction_submission_review'
  then '[]'::jsonb else '["auction_submission_review"]'::jsonb end,
 true)
where raw_app_meta_data->>'role'='admin_staff';
