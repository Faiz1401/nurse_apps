-- ============================================================================
-- Module 4 — Nurse Registration + Profile
-- Tables: nurses, nurse_skills, nurse_services
--
-- Scope note: this module is profile data only. Document verification
-- (nurse_documents) is Module 5, and working-hours availability
-- (nurse_availability/nurse_time_off) is Module 6 — see docs/09-roadmap.md.
--
-- Security note: `nurses` carries bank/payout fields, so unlike the Module 3
-- catalog tables, this is NOT open to "any authenticated" read. For now,
-- select is owner-or-admin only — client-facing nurse search (Module 8,
-- "Smart nurse search") will expose a separate public-safe view/columns
-- rather than opening this table's SELECT policy wholesale, so bank details
-- never become reachable by a browsing client.
-- ============================================================================

create type verification_status as enum ('pending','approved','rejected','suspended','expired');

create table nurses (
  id uuid primary key references profiles(id) on delete cascade,
  qualification text,
  experience_years numeric(4,1) default 0,
  bio text,
  bank_name text,
  bank_account_no text,
  bank_account_holder text,
  verification_status verification_status not null default 'pending',
  rating_avg numeric(3,2) default 0,
  jobs_completed integer not null default 0,
  is_available boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create trigger trg_nurses_updated before update on nurses
  for each row execute function set_updated_at();

-- Guards data integrity: a `nurses` row can only ever belong to a profile
-- whose role is actually 'nurse' — RLS's `id = auth.uid()` insert check alone
-- wouldn't stop a patient-role account from inserting one directly.
create or replace function ensure_nurse_role()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from profiles where id = new.id and role = 'nurse') then
    raise exception 'Only accounts with role=nurse can have a nurses profile';
  end if;
  return new;
end;
$$;

create trigger trg_ensure_nurse_role before insert on nurses
  for each row execute function ensure_nurse_role();

create table nurse_skills (
  nurse_id uuid not null references nurses(id) on delete cascade,
  skill_id uuid not null references skills(id) on delete cascade,
  certificate_url text,
  certified_at date,
  primary key (nurse_id, skill_id)
);

create table nurse_services (
  nurse_id uuid not null references nurses(id) on delete cascade,
  service_id uuid not null references services(id) on delete cascade,
  custom_price numeric(10,2),
  primary key (nurse_id, service_id)
);

-- ----------------------------------------------------------------------------
-- RLS
-- ----------------------------------------------------------------------------
alter table nurses enable row level security;
alter table nurse_skills enable row level security;
alter table nurse_services enable row level security;

create policy nurses_select_owner_or_admin on nurses
  for select using (id = auth.uid() or is_admin());

create policy nurses_insert_owner_or_admin on nurses
  for insert with check (id = auth.uid() or is_admin());

create policy nurses_update_owner_or_admin on nurses
  for update using (id = auth.uid() or is_admin());

-- No delete policy: a nurse profile is never hard-deleted (booking/visit
-- history may reference it); deactivation is handled via verification_status
-- ('suspended') in Module 5, not row deletion.

create policy nurse_skills_all_via_owner on nurse_skills
  for all using (
    exists (select 1 from nurses n where n.id = nurse_skills.nurse_id and (n.id = auth.uid() or is_admin()))
  )
  with check (
    exists (select 1 from nurses n where n.id = nurse_skills.nurse_id and (n.id = auth.uid() or is_admin()))
  );

create policy nurse_services_all_via_owner on nurse_services
  for all using (
    exists (select 1 from nurses n where n.id = nurse_services.nurse_id and (n.id = auth.uid() or is_admin()))
  )
  with check (
    exists (select 1 from nurses n where n.id = nurse_services.nurse_id and (n.id = auth.uid() or is_admin()))
  );

-- nurses carries financial (bank) fields, so it joins the audit spine
-- alongside patients — see docs/04-database-erd.md.
create trigger trg_audit_nurses
  after insert or update or delete on nurses
  for each row execute function log_audit();
