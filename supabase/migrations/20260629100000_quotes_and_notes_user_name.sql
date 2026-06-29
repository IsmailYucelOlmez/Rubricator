-- Store author display names on quotes and book notes (same pattern as reviews).

alter table public.quotes
  add column if not exists user_name text;

drop trigger if exists trg_quotes_fill_user_name on public.quotes;
create trigger trg_quotes_fill_user_name
before insert or update on public.quotes
for each row
execute function public.fill_actor_name_from_auth();

update public.quotes q
set user_name = public.profile_display_name(q.user_id)
where user_name is null
   or char_length(trim(user_name)) = 0;

alter table public.book_notes
  add column if not exists user_name text;

drop trigger if exists trg_book_notes_fill_user_name on public.book_notes;
create trigger trg_book_notes_fill_user_name
before insert or update on public.book_notes
for each row
execute function public.fill_actor_name_from_auth();

update public.book_notes n
set user_name = public.profile_display_name(n.user_id)
where user_name is null
   or char_length(trim(user_name)) = 0;
