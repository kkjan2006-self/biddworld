-- In-app notifications for important member-owned workflow state changes.
-- This migration extends the existing inbox; it does not add email/SMS providers.
-- Source-only until the owner authorizes the consolidated TEST migration phase.

create or replace function private.notify_member_workflow_status_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid;
  v_title text;
  v_message text;
  v_category text := 'account';
  v_status text;
  v_member_code text;
begin
  if tg_table_name = 'package_activations' then
    if old.payment_status is not distinct from new.payment_status
       and old.activation_status is not distinct from new.activation_status then
      return new;
    end if;
    select owner_user_id into v_user_id
      from public.member_ids where id = new.member_id;
    if new.payment_status = 'approved' and new.activation_status = 'active' then
      v_title := 'Package activation approved';
      v_message := 'Your package activation request has been approved and your package is now active.';
    elsif new.payment_status = 'rejected' or new.activation_status = 'rejected' then
      v_title := 'Package activation update';
      v_message := 'Your package activation request was rejected. Please contact support if you need help.';
    else
      return new;
    end if;

  elsif tg_table_name = 'member_ids' then
    if old.status is not distinct from new.status then
      return new;
    end if;
    v_user_id := new.owner_user_id;
    v_member_code := new.member_code;
    if new.id_type = 'duplicate' then
      v_title := 'Duplicate ID status updated';
      v_message := 'Your Duplicate ID ' || v_member_code || ' status is now ' ||
        replace(new.status, '_', ' ') || '.';
    elsif new.id_type = 'main' then
      v_title := 'Main ID account status updated';
      v_message := 'Your Main ID ' || v_member_code || ' account status is now ' ||
        replace(new.status, '_', ' ') || '.';
    else
      return new;
    end if;

  elsif tg_table_name = 'wallet_fund_requests' then
    if old.status is not distinct from new.status then
      return new;
    end if;
    v_user_id := new.submitted_by;
    if new.status = 'approved' then
      v_title := 'Wallet funding approved';
      v_message := 'Your wallet funding request has been approved and the wallet update has been processed.';
    elsif new.status = 'rejected' then
      v_title := 'Wallet funding request update';
      v_message := 'Your wallet funding request was rejected.' ||
        case when nullif(btrim(new.review_note), '') is not null
          then ' Review note: ' || left(btrim(new.review_note), 300)
          else '' end;
    else
      return new;
    end if;

  elsif tg_table_name = 'auction_submissions' then
    if old.status is not distinct from new.status then
      return new;
    end if;
    v_user_id := new.submitted_by;
    if new.status = 'approved' then
      v_title := 'Auction listing approved';
      v_message := 'Your auction listing "' || left(new.title, 150) || '" has been approved and published.';
    elsif new.status = 'rejected' then
      v_title := 'Auction listing needs attention';
      v_message := 'Your auction listing "' || left(new.title, 150) || '" was not approved.' ||
        case when nullif(btrim(new.review_note), '') is not null
          then ' Review note: ' || left(btrim(new.review_note), 300)
          else ' Please contact support if you need clarification.' end;
    else
      return new;
    end if;

  elsif tg_table_name = 'withdrawal_requests' then
    if old.status is not distinct from new.status then
      return new;
    end if;
    select owner_user_id into v_user_id
      from public.member_ids where id = new.member_id;
    v_status := new.status::text;
    if v_status = 'approved' then
      v_title := 'Withdrawal request approved';
      v_message := 'Your withdrawal request has been approved and is awaiting payout confirmation.';
    elsif v_status = 'rejected' then
      v_title := 'Withdrawal request update';
      v_message := 'Your withdrawal request was rejected.' ||
        case when nullif(btrim(new.rejection_reason), '') is not null
          then ' Reason: ' || left(btrim(new.rejection_reason), 300)
          else '' end;
    elsif v_status = 'paid' then
      v_title := 'Withdrawal marked as paid';
      v_message := 'Your withdrawal request has been marked as paid by the administrator.';
    else
      return new;
    end if;

  elsif tg_table_name = 'delivery_tracking' then
    if old.status is not distinct from new.status then
      return new;
    end if;
    select m.owner_user_id into v_user_id
      from public.winning_item_payments p
      join public.member_ids m on m.id = p.winner_member_id
     where p.id = new.winning_item_payment_id;
    v_status := replace(new.status, '_', ' ');
    v_title := 'Delivery status updated';
    v_message := 'Your winning item delivery status is now: ' || v_status || '.' ||
      case when nullif(btrim(new.carrier), '') is not null
        then ' Carrier: ' || left(btrim(new.carrier), 100) || '.' else '' end ||
      case when nullif(btrim(new.tracking_number), '') is not null
        then ' Tracking number: ' || left(btrim(new.tracking_number), 120) || '.' else '' end;
  else
    return new;
  end if;

  if v_user_id is null or v_title is null or v_message is null then
    return new;
  end if;

  insert into public.member_notifications(user_id, title, message, category)
  values (v_user_id, left(v_title, 120), left(v_message, 2000), v_category);

  return new;
end;
$function$;

revoke all on function private.notify_member_workflow_status_change() from public, anon, authenticated;

drop trigger if exists notify_member_package_activation_status on public.package_activations;
create trigger notify_member_package_activation_status
after update of payment_status, activation_status on public.package_activations
for each row execute function private.notify_member_workflow_status_change();

drop trigger if exists notify_member_duplicate_id_status on public.member_ids;
create trigger notify_member_duplicate_id_status
after update of status on public.member_ids
for each row when (old.status is distinct from new.status and new.id_type in ('main','duplicate'))
execute function private.notify_member_workflow_status_change();

drop trigger if exists notify_member_wallet_funding_status on public.wallet_fund_requests;
create trigger notify_member_wallet_funding_status
after update of status on public.wallet_fund_requests
for each row when (old.status is distinct from new.status)
execute function private.notify_member_workflow_status_change();

drop trigger if exists notify_member_auction_submission_status on public.auction_submissions;
create trigger notify_member_auction_submission_status
after update of status on public.auction_submissions
for each row when (old.status is distinct from new.status)
execute function private.notify_member_workflow_status_change();

drop trigger if exists notify_member_withdrawal_status on public.withdrawal_requests;
create trigger notify_member_withdrawal_status
after update of status on public.withdrawal_requests
for each row when (old.status is distinct from new.status)
execute function private.notify_member_workflow_status_change();

drop trigger if exists notify_member_delivery_status on public.delivery_tracking;
create trigger notify_member_delivery_status
after update of status on public.delivery_tracking
for each row when (old.status is distinct from new.status)
execute function private.notify_member_workflow_status_change();
