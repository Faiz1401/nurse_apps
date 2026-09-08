-- ============================================================================
-- Module 2 — Client Profile + Patient Management
-- Tables: patients, emergency_contacts
-- Also: generic audit_logs infrastructure (patients is our first sensitive
-- health-data table, so this is where the audit trail promised in
-- docs/01-architecture.md starts — the trigger is generic and reusable, so
-- future modules just add one `create trigger ... execute function log_audit()`
-- line rather than rebuilding this).
--
-- Client Profile itself needs no new table — it's the `profiles` row created
-- in Module 1; the Flutter app just gets an edit screen for it.
--
-- Family/caregiver access (patient_access, family_members) is NOT part of
-- this module — that's Phase 3 (see docs/09-roadmap.md #27). For now, a
-- patient row is visible only to its owner and admins.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- patients
-- ----------------------------------------------------------------------------
create table patients (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  full_name text not null,
  ic_passport text,
  dob date,
  gender text check (gender in ('male','female','other')),
  relationship_to_owner text not null default 'self'
    check (relationship_to_owner in ('self','father','mother','child','other')),
  address text,
  photo_url text,
  medical_conditions text,
  allergies text,
  mobility_status text check (mobility_status in ('independent','assisted','wheelchair','bedridden')),
  special_instructions text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index idx_patients_owner on patients(owner_id);
create trigger trg_patients_updated before update on patients
  for each row execute function set_updated_at();

create table emergency_contacts (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references patients(id) on delete cascade,
  name text not null,
  relationship text,
  phone text not null,
  is_primary boolean not null default false,
  created_at timestamptz not null default now()
);
create index idx_emergency_contacts_patient on emergency_contacts(patient_id);

-- ----------------------------------------------------------------------------
-- RLS: patients — owner-only (or admin), soft-deleted rows invisible to owner
-- ----------------------------------------------------------------------------
alter table patients enable row level security;

create policy patients_select_owner_or_admin on patients
  for select using ((owner_id = auth.uid() and deleted_at is null) or is_admin());

create policy patients_insert_owner_or_admin on patients
  for insert with check (owner_id = auth.uid() or is_admin());

create policy patients_update_owner_or_admin on patients
  for update using (owner_id = auth.uid() or is_admin());

-- No delete policy for regular clients: "removing" a patient is a soft-delete
-- (UPDATE deleted_at = now()) done through the update policy above, never a
-- hard DELETE — clinical/booking history may still reference this patient.
create policy patients_delete_admin_only on patients
  for delete using (is_admin());

-- ----------------------------------------------------------------------------
-- RLS: emergency_contacts — inherits access from the parent patient
-- ----------------------------------------------------------------------------
alter table emergency_contacts enable row level security;

create policy emergency_contacts_all_via_patient on emergency_contacts
  for all using (
    exists (
      select 1 from patients p
      where p.id = emergency_contacts.patient_id
        and (p.owner_id = auth.uid() or is_admin())
    )
  )
  with check (
    exists (
      select 1 from patients p
      where p.id = emergency_contacts.patient_id
        and (p.owner_id = auth.uid() or is_admin())
    )
  );

-- ============================================================================
-- Generic audit trail
-- ============================================================================

create table audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references profiles(id),
  action text not null,
  entity_type text not null,
  entity_id uuid,
  patient_id uuid references patients(id),
  metadata jsonb,
  ip_address inet,
  user_agent text,
  created_at timestamptz not null default now()
);
create index idx_audit_logs_actor on audit_logs(actor_id);
create index idx_audit_logs_entity on audit_logs(entity_type, entity_id);
create index idx_audit_logs_patient on audit_logs(patient_id);
create index idx_audit_logs_created on audit_logs(created_at);

alter table audit_logs enable row level security;

-- Only admins can ever read the audit trail; nobody (not even the actor) can
-- write to it directly — all writes go through the SECURITY DEFINER trigger
-- function below, so a compromised/buggy client can't forge or erase entries.
create policy audit_logs_select_admin_only on audit_logs
  for select using (is_admin());

-- ----------------------------------------------------------------------------
-- Generic audit trigger. NEW/OLD are resolved to the invoking table's actual
-- row type at runtime, so this one function can be attached to any table.
-- `patient_id` extraction: the `patients` table IS the patient (entity_id);
-- every other clinically-relevant table is expected to carry its own
-- `patient_id` column, which is pulled out via jsonb — absent on tables that
-- don't have one, where it's simply left null.
-- ----------------------------------------------------------------------------
create or replace function log_audit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_entity_id uuid;
  v_patient_id uuid;
begin
  v_entity_id := coalesce(new.id, old.id);

  if tg_table_name = 'patients' then
    v_patient_id := v_entity_id;
  else
    v_patient_id := (to_jsonb(coalesce(new, old)) ->> 'patient_id')::uuid;
  end if;

  insert into audit_logs (actor_id, action, entity_type, entity_id, patient_id, metadata)
  values (
    auth.uid(),
    lower(tg_op) || '_' || tg_table_name,
    tg_table_name,
    v_entity_id,
    v_patient_id,
    jsonb_build_object('old', to_jsonb(old), 'new', to_jsonb(new))
  );

  return coalesce(new, old);
end;
$$;

create trigger trg_audit_patients
  after insert or update or delete on patients
  for each row execute function log_audit();

create trigger trg_audit_emergency_contacts
  after insert or update or delete on emergency_contacts
  for each row execute function log_audit();
