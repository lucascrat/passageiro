-- RLS policies for Bingo write access based on admin users

-- Admin users table (store auth.users.id)
create table if not exists public.admin_users (
  user_id uuid primary key
);

alter table public.admin_users enable row level security;
create policy "self read" on public.admin_users for select using (auth.uid() = user_id);
create policy "admin manage" on public.admin_users for all using (true) with check (true);

-- Enable RLS on bingo tables
alter table public.games enable row level security;
alter table public.prizes enable row level security;
alter table public.drawn_numbers enable row level security;
alter table public.winners enable row level security;

-- Read policies: allow all authenticated users to read
create policy "read games" on public.games for select using (true);
create policy "read prizes" on public.prizes for select using (true);
create policy "read nums" on public.drawn_numbers for select using (true);
create policy "read winners" on public.winners for select using (true);

-- Write policies: only admins can insert/update/delete
create policy "admin write games" on public.games for all
  using (exists(select 1 from public.admin_users au where au.user_id = auth.uid()))
  with check (exists(select 1 from public.admin_users au where au.user_id = auth.uid()));

create policy "admin write prizes" on public.prizes for all
  using (exists(select 1 from public.admin_users au where au.user_id = auth.uid()))
  with check (exists(select 1 from public.admin_users au where au.user_id = auth.uid()));
  with check (exists(select 1 from public.admin_users au where au.user_id = auth.uid()));

create policy "admin write nums" on public.drawn_numbers for all
  using (exists(select 1 from public.admin_users au where au.user_id = auth.uid()))
  with check (exists(select 1 from public.admin_users au where au.user_id = auth.uid()));

create policy "admin write winners" on public.winners for all
  using (exists(select 1 from public.admin_users au where au.user_id = auth.uid()))
  with check (exists(select 1 from public.admin_users au where au.user_id = auth.uid()));

-- Helper: add current user as admin (run after login)
-- insert into public.admin_users(user_id) values (auth.uid());