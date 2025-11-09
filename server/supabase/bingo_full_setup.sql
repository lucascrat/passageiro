begin;

-- Extensão necessária para gen_random_uuid()
create extension if not exists pgcrypto;

-- Tabela de admins (armazena auth.users.id)
create table if not exists public.admin_users (
  user_id uuid primary key
);
alter table public.admin_users enable row level security;

-- Política para leitura própria
drop policy if exists "self read" on public.admin_users;
create policy "self read" on public.admin_users
  for select using (auth.uid() = user_id);

-- Política para gerenciamento de admins
drop policy if exists "admin manage" on public.admin_users;
create policy "admin manage" on public.admin_users
  for all using (true) with check (true);

-- Tabelas principais do Bingo
create table if not exists public.games (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  status text not null default 'active' check (status in ('active','archived'))
);

create table if not exists public.prizes (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null references public.games(id) on delete cascade,
  title text not null,
  image_url text not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.drawn_numbers (
  id bigserial primary key,
  game_id uuid not null references public.games(id) on delete cascade,
  number int not null check (number between 1 and 75),
  drawn_at timestamptz not null default now(),
  unique (game_id, number)
);

create table if not exists public.winners (
  id bigserial primary key,
  game_id uuid not null references public.games(id) on delete cascade,
  name text not null,
  announced_at timestamptz not null default now()
);

-- Índices úteis
create index if not exists idx_prizes_game_id on public.prizes(game_id);
create index if not exists idx_drawn_numbers_game_id on public.drawn_numbers(game_id);
create index if not exists idx_winners_game_id on public.winners(game_id);

-- Habilitar RLS
alter table public.games enable row level security;
alter table public.prizes enable row level security;
alter table public.drawn_numbers enable row level security;
alter table public.winners enable row level security;

-- Políticas de leitura (abertas para todos, inclusive usuários anônimos)
-- Para exigir login, troque "using (true)" por "using (auth.uid() is not null)".
drop policy if exists "read games" on public.games;
create policy "read games" on public.games for select using (true);

drop policy if exists "read prizes" on public.prizes;
create policy "read prizes" on public.prizes for select using (true);

drop policy if exists "read nums" on public.drawn_numbers;
create policy "read nums" on public.drawn_numbers for select using (true);

drop policy if exists "read winners" on public.winners;
create policy "read winners" on public.winners for select using (true);

-- Políticas de escrita: somente admins (presentes em admin_users)
drop policy if exists "admin write games" on public.games;
create policy "admin write games" on public.games for all
  using (exists(select 1 from public.admin_users au where au.user_id = auth.uid()))
  with check (exists(select 1 from public.admin_users au where au.user_id = auth.uid()));

drop policy if exists "admin write prizes" on public.prizes;
create policy "admin write prizes" on public.prizes for all
  using (exists(select 1 from public.admin_users au where au.user_id = auth.uid()))
  with check (exists(select 1 from public.admin_users au where au.user_id = auth.uid()));

drop policy if exists "admin write nums" on public.drawn_numbers;
create policy "admin write nums" on public.drawn_numbers for all
  using (exists(select 1 from public.admin_users au where au.user_id = auth.uid()))
  with check (exists(select 1 from public.admin_users au where au.user_id = auth.uid()));

drop policy if exists "admin write winners" on public.winners;
create policy "admin write winners" on public.winners for all
  using (exists(select 1 from public.admin_users au where au.user_id = auth.uid()))
  with check (exists(select 1 from public.admin_users au where au.user_id = auth.uid()));

-- Trigger para atualizar updated_at em prizes
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists prizes_set_updated_at on public.prizes;
create trigger prizes_set_updated_at
before update on public.prizes
for each row
execute function public.set_updated_at();

-- Publicação Realtime (permite onPostgresChanges)
do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    execute 'create publication supabase_realtime';
  end if;
end
$$;

alter publication supabase_realtime add table public.games;
alter publication supabase_realtime add table public.prizes;
alter publication supabase_realtime add table public.drawn_numbers;
alter publication supabase_realtime add table public.winners;

commit;

-- Para promover um usuário a admin (substitua pelo user_id do Auth > Users):
-- insert into public.admin_users (user_id) values ('<user_id>') on conflict (user_id) do nothing;