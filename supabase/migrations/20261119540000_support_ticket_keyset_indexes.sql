-- Support ticket keyset pages sort by updated_at and id; cover member and Admin queues.
create index if not exists support_tickets_updated_id_idx
 on public.support_tickets(updated_at desc,id desc);
create index if not exists support_tickets_user_updated_id_idx
 on public.support_tickets(user_id,updated_at desc,id desc);
