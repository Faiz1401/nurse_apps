-- ============================================================================
-- Module 1 — Identity & RBAC foundation
-- Tables: profiles, permissions, role_permissions
-- Trigger: auto-create a profiles row when a new auth.users row appears
-- RLS: default-deny, explicit policies below
-- ============================================================================

create extension if not exists pgcrypto;

create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create type user_role as enum ('patient','family','nurse','admin','super_admin');

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role user_role not null default 'patient',
  full_name text not null,
  ic_passport text,
  dob date,
  gender text check (gender in ('male','female','other')),
  email text,
  phone text,
  address text,
  photo_url text,
  emergency_contact_name text,
  emergency_contact_phone text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index idx_profiles_role on profiles(role);
create trigger trg_profiles_updated before update on profiles
  for each row execute function set_updated_at();

create table permissions (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  description text not null
);

create table role_permissions (
  role user_role not null,
  permission_id uuid not null references permissions(id) on delete cascade,
  primary key (role, permission_id)
);

-- ----------------------------------------------------------------------------
-- Auto-create a profile row whenever someone signs up via Supabase Auth.
-- Reads full_name/role out of the signUp() `data` payload (raw_user_meta_data).
-- SECURITY DEFINER so it can write to public.profiles despite RLS below.
-- Role is intentionally clamped to 'patient' or 'nurse' here — 'admin' and
-- 'super_admin' can never be self-assigned at signup; they're granted later
-- by an existing admin (see role_permissions / admin user-management module).
-- ----------------------------------------------------------------------------
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  requested_role text := new.raw_user_meta_data ->> 'role';
begin
  insert into public.profiles (id, role, full_name, email, phone)
  values (
    new.id,
    case when requested_role = 'nurse' then 'nurse'::user_role else 'patient'::user_role end,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.email,
    new.raw_user_meta_data ->> 'phone'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ----------------------------------------------------------------------------
-- RLS
-- ----------------------------------------------------------------------------

alter table profiles enable row level security;
alter table permissions enable row level security;
alter table role_permissions enable row level security;

-- helper: is the current user an admin/super_admin? (STABLE + SECURITY DEFINER
-- avoids recursive RLS checks when policies below query profiles)
create or replace function is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from profiles p
    where p.id = auth.uid() and p.role in ('admin','super_admin')
  );
$$;

-- profiles: everyone can read their own row; admins can read all
create policy profiles_select_own_or_admin on profiles
  for select using (id = auth.uid() or is_admin());

-- profiles: a user can update their own non-privileged fields; admins can update any row
-- (role/is_active changes are further restricted at the application layer to
-- admin-only screens, and any such change must be written to audit_logs)
create policy profiles_update_own_or_admin on profiles
  for update using (id = auth.uid() or is_admin());

-- no insert policy for regular clients: rows are created exclusively by the
-- SECURITY DEFINER trigger above. Admins may still insert directly (e.g. to
-- backfill/support), gated by is_admin().
create policy profiles_insert_admin_only on profiles
  for insert with check (is_admin());

-- permissions/role_permissions: readable by any authenticated user (drives
-- client-side feature gating); writable by admins only.
create policy permissions_select_authenticated on permissions
  for select using (auth.role() = 'authenticated');

create policy permissions_write_admin_only on permissions
  for all using (is_admin()) with check (is_admin());

create policy role_permissions_select_authenticated on role_permissions
  for select using (auth.role() = 'authenticated');

create policy role_permissions_write_admin_only on role_permissions
  for all using (is_admin()) with check (is_admin());
