-- Fuel Ledger — Supabase schema
-- Run this once in your Supabase project's SQL Editor (Dashboard → SQL Editor → New query → Run).

-- Profiles: public username tied to each account
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  terms_version text,
  terms_accepted_at timestamptz,
  created_at timestamptz default now()
);
alter table public.profiles enable row level security;
create policy "profiles_select_all" on public.profiles for select using (true);
create policy "profiles_insert_own" on public.profiles for insert with check (auth.uid() = id);
create policy "profiles_update_own" on public.profiles for update using (auth.uid() = id);

-- If you already ran this schema before adding terms_version/terms_accepted_at,
-- run this instead of re-creating the table:
-- alter table public.profiles add column if not exists terms_version text;
-- alter table public.profiles add column if not exists terms_accepted_at timestamptz;

-- Goals: private targets per user
create table if not exists public.goals (
  user_id uuid primary key references auth.users(id) on delete cascade,
  calories numeric default 2400,
  protein numeric default 160,
  carbs numeric default 260,
  fat numeric default 75,
  water_oz numeric default 100,
  micros jsonb default '{}'::jsonb,
  supplements jsonb default '[]'::jsonb,
  updated_at timestamptz default now()
);
alter table public.goals enable row level security;
create policy "goals_all_own" on public.goals for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Logs: private per-day entries per user
create table if not exists public.logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  log_date date not null,
  foods jsonb default '[]'::jsonb,
  water_oz numeric default 0,
  supplements jsonb default '[]'::jsonb,
  updated_at timestamptz default now(),
  unique(user_id, log_date)
);
alter table public.logs enable row level security;
create policy "logs_all_own" on public.logs for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Leaderboard: readable by everyone, writable only by the row's own owner
create table if not exists public.leaderboard (
  user_id uuid references auth.users(id) on delete cascade,
  log_date date not null,
  username text not null,
  score int not null,
  updated_at timestamptz default now(),
  primary key (user_id, log_date)
);
alter table public.leaderboard enable row level security;
create policy "leaderboard_select_all" on public.leaderboard for select using (true);
create policy "leaderboard_insert_own" on public.leaderboard for insert with check (auth.uid() = user_id);
create policy "leaderboard_update_own" on public.leaderboard for update using (auth.uid() = user_id);
