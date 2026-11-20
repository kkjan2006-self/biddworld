-- Serialize Member auction submission writes and reject duplicate pending listings.
-- A trigger protects every insert/update path, not just the current browser form.
create index if not exists auction_submissions_owner_pending_title_idx
 on public.auction_submissions(submitted_by,lower(btrim(title)))
 where status='pending';

create or replace function private.prevent_duplicate_pending_auction_submission()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
begin
 if new.status='pending' then
  perform pg_catalog.pg_advisory_xact_lock(
   pg_catalog.hashtextextended('biddworld.auction_submission:'||new.submitted_by::text,0)
  );
  if exists(
   select 1
   from public.auction_submissions s
   where s.submitted_by=new.submitted_by
    and s.status='pending'
    and lower(btrim(s.title))=lower(btrim(new.title))
    and (tg_op='INSERT' or s.id<>new.id)
  ) then
   raise exception 'A pending auction submission with this title already exists. Edit that submission instead of creating a duplicate.'
    using errcode='23505';
  end if;
 end if;
 return new;
end;
$function$;

revoke all on function private.prevent_duplicate_pending_auction_submission() from public,anon,authenticated;

drop trigger if exists auction_submissions_prevent_duplicate_pending on public.auction_submissions;
create trigger auction_submissions_prevent_duplicate_pending
before insert or update on public.auction_submissions
for each row execute function private.prevent_duplicate_pending_auction_submission();

comment on function private.prevent_duplicate_pending_auction_submission() is
 'Serializes pending auction submission writes per owner and rejects duplicate normalized titles across all insert/update paths.';
