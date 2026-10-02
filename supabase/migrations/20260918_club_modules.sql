-- Apply once to enable shared tournaments, court rotation and treasury.
-- The client retains local records until this migration is installed.
create table if not exists public.club_module_documents (
  module text primary key,
  revision integer not null default 1,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id)
);
alter table public.club_module_documents enable row level security;
create policy "Active members read club modules" on public.club_module_documents
  for select to authenticated using (exists (
    select 1 from public.players where auth_user_id = auth.uid() and is_active = true
  ));

create or replace function public.save_club_module(p_module text, p_expected_revision integer, p_data jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare current_doc public.club_module_documents; result_doc public.club_module_documents;
begin
  if not exists (select 1 from public.players where auth_user_id = auth.uid()
      and is_active = true and role in ('captain','admin')) then
    raise exception 'Captain access required' using errcode = '42501';
  end if;
  if p_module not in ('tournaments', 'court_queue', 'treasury') then
    raise exception 'Unknown module' using errcode = '22023';
  end if;
  if jsonb_typeof(p_data) <> 'object' then
    raise exception 'Invalid module data' using errcode = '22023';
  end if;
  perform pg_advisory_xact_lock(hashtext('club_module:' || p_module));
  select * into current_doc from public.club_module_documents where module = p_module;
  if coalesce(current_doc.revision, 0) <> p_expected_revision then
    raise exception 'Club record changed on another device' using errcode = '40001';
  end if;
  insert into public.club_module_documents(module, revision, data, updated_by)
    values (p_module, p_expected_revision + 1, p_data, auth.uid())
    on conflict(module) do update set revision = excluded.revision, data = excluded.data,
      updated_at = now(), updated_by = auth.uid()
    returning * into result_doc;
  return to_jsonb(result_doc);
end; $$;
revoke all on function public.save_club_module(text, integer, jsonb) from public;
grant execute on function public.save_club_module(text, integer, jsonb) to authenticated;
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime'
    and tablename = 'club_module_documents') then
    alter publication supabase_realtime add table public.club_module_documents;
  end if;
end $$;
