-- Execute este script em uma consulta NOVA, separado do SQL principal.
-- Ele prepara as tabelas que o SQL principal precisa encontrar.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  email text not null,
  role text not null default 'user'
    check (role in ('user', 'admin')),
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now()
);

create unique index if not exists profiles_email_lower_unique
  on public.profiles (lower(email));

create table if not exists public.cases (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.case_members (
  case_id uuid not null references public.cases(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (case_id, user_id)
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  case_id uuid references public.cases(id) on delete cascade,
  kind text not null check (kind in ('personal', 'case')),
  title text not null default 'Nova conversa',
  created_at timestamptz not null default now(),
  constraint conversations_kind_case_check check (
    (kind = 'personal' and case_id is null)
    or
    (kind = 'case' and case_id is not null)
  )
);
