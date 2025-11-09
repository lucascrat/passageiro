-- Supabase Bingo schema
create table if not exists public.games (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  status text not null default 'active' -- active, archived
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

-- RLS policies (example; adjust for your roles)
alter table public.games enable row level security;
alter table public.prizes enable row level security;
alter table public.drawn_numbers enable row level security;
alter table public.winners enable row level security;

-- Allow read to all authenticated, write only admin role (replace 'service_role' with custom if needed)
create policy "read all" on public.games for select using (true);
create policy "read all" on public.prizes for select using (true);
create policy "read all" on public.drawn_numbers for select using (true);
create policy "read all" on public.winners for select using (true);

-- Example write policy: require is_admin boolean on auth.jwt() (customize)
-- create policy "write admin" on public.drawn_numbers for insert with check (auth.jwt() ->> 'is_admin' = 'true');