-- Correct the image extension regexes in the expected-price auction RPCs.
-- The prior migration stored a doubled backslash in SQL regex literals, which
-- made valid uploaded image paths fail the ownership/path validation.
do $fix$
declare
 v_signature regprocedure;
 v_definition text;
 v_fixed text;
 v_signatures regprocedure[] := array[
  'public.member_submit_auction(text,text,text,text[],numeric,numeric,numeric,timestamp with time zone,jsonb)'::regprocedure,
  'public.admin_review_auction_submission(uuid,text,text,text,text,text[],numeric,numeric,numeric,timestamp with time zone,jsonb,text)'::regprocedure
 ];
begin
 foreach v_signature in array v_signatures loop
  select pg_catalog.pg_get_functiondef(v_signature) into v_definition;
  v_fixed := replace(v_definition, pg_catalog.chr(92)||pg_catalog.chr(92)||'.', '[.]');
  if v_fixed = v_definition then
   raise exception 'Expected doubled-backslash image extension pattern was not found in %', v_signature;
  end if;
  execute v_fixed;
 end loop;
end;
$fix$;
