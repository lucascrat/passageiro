-- Supabase Payments Schema (Stripe)
-- Run this in Supabase Studio > SQL Editor

-- Extensions
create extension if not exists pgcrypto;

-- Admin users table (optional, for admin write access beyond service role)
create table if not exists public.admin_users (
  user_id uuid primary key
);

-- Core payment intents
create table if not exists public.payment_intents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  amount integer not null check (amount > 0),
  currency text not null default 'BRL',
  status text not null,
  stripe_payment_intent_id text unique not null,
  client_secret text,
  description text,
  metadata jsonb,
  created_at timestamptz not null default now()
);

create index if not exists payment_intents_user_idx on public.payment_intents(user_id);
create index if not exists payment_intents_created_idx on public.payment_intents(created_at);

alter table public.payment_intents enable row level security;

-- Read: owner can read their own intents
create policy if not exists "read own payment_intents" on public.payment_intents
  for select using (auth.uid() = user_id);

-- Insert/Update: allowed to admin users; service role bypasses RLS
create policy if not exists "admin insert payment_intents" on public.payment_intents
  for insert with check (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

create policy if not exists "admin update payment_intents" on public.payment_intents
  for update using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

-- Payment transactions (charges/refunds)
create table if not exists public.payment_transactions (
  id uuid primary key default gen_random_uuid(),
  payment_intent_id uuid not null references public.payment_intents(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  amount integer not null check (amount > 0),
  currency text not null,
  type text not null check (type in ('charge','refund')),
  stripe_charge_id text,
  status text not null,
  created_at timestamptz not null default now()
);

create index if not exists payment_tx_intent_idx on public.payment_transactions(payment_intent_id);
create index if not exists payment_tx_user_idx on public.payment_transactions(user_id);

alter table public.payment_transactions enable row level security;

create policy if not exists "read own payment_transactions" on public.payment_transactions
  for select using (auth.uid() = user_id);

create policy if not exists "admin insert payment_transactions" on public.payment_transactions
  for insert with check (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

create policy if not exists "admin update payment_transactions" on public.payment_transactions
  for update using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

-- Optional: realtime enablement hints (configure in Studio > Database > Replication)
-- Enable Realtime for public.payment_intents and public.payment_transactions if you want live updates