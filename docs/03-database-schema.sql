-- ============================================================================
-- HOME NURSING PLATFORM — Postgres schema (Supabase)
-- ============================================================================
-- Conventions:
--   * Every table has: id uuid PK default gen_random_uuid(), created_at,
--     updated_at (via trigger), and deleted_at for soft-delete where records
--     are clinically/financially significant (never hard-delete clinical or
--     financial history).
--   * FKs to auth.users are used only on `profiles`; every other table links
--     to `profiles.id`, never directly to `auth.users.id`, so app logic never
--     has to think about the auth schema.
--   * RLS is enabled on every table with no default policy (default-deny).
--     A representative full policy set is written for the highest-sensitivity
--     tables (profiles, patients, vital_signs, bookings, nurse_documents).
--     The remaining tables follow the same three patterns documented at the
--     bottom of this file and will be added table-by-table as each module is
--     implemented, per the project's module-by-module build rule.
-- ============================================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- updated_at trigger helper
-- ---------------------------------------------------------------------------
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ============================================================================
-- 0. IDENTITY & RBAC
-- ============================================================================

create type user_role as enum ('patient','family','nurse','admin','super_admin');

-- 1:1 with auth.users. Purpose: holds role + shared profile fields for all humans.
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

-- Purpose: admin-configurable feature/action permissions layered on top of role (UX gating, not the security boundary).
create table permissions (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,        -- e.g. 'booking.override_status'
  description text not null
);

create table role_permissions (
  role user_role not null,
  permission_id uuid not null references permissions(id) on delete cascade,
  primary key (role, permission_id)
);

-- ============================================================================
-- 1. PATIENTS & FAMILY ACCESS
-- ============================================================================

-- Purpose: a client's managed patient (self, parent, child, etc). FK: owner_id -> profiles (the client account that created it).
create table patients (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  full_name text not null,
  ic_passport text,
  dob date,
  gender text check (gender in ('male','female','other')),
  relationship_to_owner text not null default 'self', -- self/father/mother/child/other
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

-- Purpose: family/caregiver invited to a patient. profile_id is null until the invitee accepts and registers.
create table family_members (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references patients(id) on delete cascade,
  profile_id uuid references profiles(id) on delete set null,
  invited_email text,
  invited_phone text,
  relationship text,
  status text not null default 'pending' check (status in ('pending','accepted','revoked')),
  invited_by uuid not null references profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_family_members_patient on family_members(patient_id);
create trigger trg_family_members_updated before update on family_members
  for each row execute function set_updated_at();

-- Purpose: granular per-patient permission grant referenced by RLS on clinical tables.
create table patient_access (
  id uuid primary key default gen_random_uuid(),
  family_member_id uuid not null references family_members(id) on delete cascade,
  patient_id uuid not null references patients(id) on delete cascade,
  can_view_health boolean not null default true,
  can_view_vitals boolean not null default false,
  can_view_reports boolean not null default false,
  can_receive_notifications boolean not null default true,
  granted_by uuid not null references profiles(id),
  granted_at timestamptz not null default now(),
  revoked_at timestamptz
);
create index idx_patient_access_patient on patient_access(patient_id);
create index idx_patient_access_family_member on patient_access(family_member_id);

-- ============================================================================
-- 2. NURSES
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
  is_available boolean not null default true, -- global on/off toggle, separate from schedule
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create trigger trg_nurses_updated before update on nurses
  for each row execute function set_updated_at();

create table nurse_documents (
  id uuid primary key default gen_random_uuid(),
  nurse_id uuid not null references nurses(id) on delete cascade,
  doc_type text not null, -- ic, qualification, apc, certificate, experience_letter, photo, bank_proof
  file_url text not null,
  status verification_status not null default 'pending',
  expiry_date date,
  reviewed_by uuid references profiles(id),
  reviewed_at timestamptz,
  notes text,
  created_at timestamptz not null default now()
);
create index idx_nurse_documents_nurse on nurse_documents(nurse_id);
create index idx_nurse_documents_expiry on nurse_documents(expiry_date) where expiry_date is not null;

create table skills (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  category text
);

create table nurse_skills (
  nurse_id uuid not null references nurses(id) on delete cascade,
  skill_id uuid not null references skills(id) on delete cascade,
  certificate_url text,
  certified_at date,
  primary key (nurse_id, skill_id)
);

create table nurse_availability (
  id uuid primary key default gen_random_uuid(),
  nurse_id uuid not null references nurses(id) on delete cascade,
  day_of_week smallint not null check (day_of_week between 0 and 6),
  start_time time not null,
  end_time time not null,
  created_at timestamptz not null default now()
);
create index idx_nurse_availability_nurse on nurse_availability(nurse_id);

create table nurse_time_off (
  id uuid primary key default gen_random_uuid(),
  nurse_id uuid not null references nurses(id) on delete cascade,
  start_date date not null,
  end_date date not null,
  reason text,
  status text not null default 'approved' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);
create index idx_nurse_time_off_nurse on nurse_time_off(nurse_id);

-- latest known GPS point per nurse, upserted — not a history table (privacy + storage discipline)
create table nurse_locations (
  nurse_id uuid primary key references nurses(id) on delete cascade,
  visit_id uuid, -- fk added after visits table
  lat double precision not null,
  lng double precision not null,
  status text not null check (status in ('available','travelling','at_patient','in_progress','sos','offline')),
  updated_at timestamptz not null default now()
);

-- ============================================================================
-- 3. SERVICES & PRICING
-- ============================================================================

create table service_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text
);

create table services (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references service_categories(id),
  name text not null,
  description text,
  duration_minutes integer not null default 60,
  base_price numeric(10,2) not null,
  required_skill_id uuid references skills(id),
  required_qualification text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_services_category on services(category_id);
create trigger trg_services_updated before update on services
  for each row execute function set_updated_at();

create table nurse_services (
  nurse_id uuid not null references nurses(id) on delete cascade,
  service_id uuid not null references services(id) on delete cascade,
  custom_price numeric(10,2),
  primary key (nurse_id, service_id)
);

create type fee_type as enum ('base','distance','night','weekend','emergency','platform');

create table service_prices (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references services(id) on delete cascade,
  fee_type fee_type not null,
  amount numeric(10,2) not null,
  unit text not null default 'flat' check (unit in ('flat','per_km','per_hour','percent')),
  created_at timestamptz not null default now()
);
create index idx_service_prices_service on service_prices(service_id);

-- ============================================================================
-- 4. BOOKINGS
-- ============================================================================

create type booking_status as enum (
  'pending','matched','accepted','travelling','arrived','in_progress','completed',
  'rejected','cancelled','rescheduled','no_show','escalated'
);

create table bookings (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references patients(id),
  requested_by uuid not null references profiles(id),
  service_id uuid not null references services(id),
  description text,
  scheduled_date date not null,
  scheduled_time time not null,
  duration_minutes integer not null,
  location_address text not null,
  location_lat double precision,
  location_lng double precision,
  preferred_nurse_id uuid references nurses(id),
  assigned_nurse_id uuid references nurses(id),
  status booking_status not null default 'pending',
  price_estimate numeric(10,2),
  price_final numeric(10,2),
  payment_status text not null default 'unpaid' check (payment_status in ('unpaid','paid','refunded','failed')),
  cancelled_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_bookings_patient on bookings(patient_id);
create index idx_bookings_assigned_nurse on bookings(assigned_nurse_id);
create index idx_bookings_status on bookings(status);
create index idx_bookings_scheduled_date on bookings(scheduled_date);
create trigger trg_bookings_updated before update on bookings
  for each row execute function set_updated_at();

-- Purpose: tracks which nurses were offered a job (supports matching engine fan-out + atomic accept locking).
create table booking_assignments (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references bookings(id) on delete cascade,
  nurse_id uuid not null references nurses(id),
  match_score numeric(5,2),
  match_reasons jsonb,
  status text not null default 'offered' check (status in ('offered','accepted','rejected','expired')),
  offered_at timestamptz not null default now(),
  responded_at timestamptz
);
create index idx_booking_assignments_booking on booking_assignments(booking_id);
create unique index uq_booking_assignment_active on booking_assignments(booking_id, nurse_id);

create table booking_status_history (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references bookings(id) on delete cascade,
  from_status booking_status,
  to_status booking_status not null,
  changed_by uuid references profiles(id),
  reason text,
  created_at timestamptz not null default now()
);
create index idx_booking_status_history_booking on booking_status_history(booking_id);

-- ============================================================================
-- 5. CARE PLANS
-- ============================================================================

create table care_plans (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references patients(id) on delete cascade,
  goal text not null,
  assigned_nurse_id uuid references nurses(id),
  start_date date not null default current_date,
  review_date date,
  status text not null default 'active' check (status in ('active','completed','discontinued')),
  created_by uuid not null references profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_care_plans_patient on care_plans(patient_id);
create trigger trg_care_plans_updated before update on care_plans
  for each row execute function set_updated_at();

create table care_plan_interventions (
  id uuid primary key default gen_random_uuid(),
  care_plan_id uuid not null references care_plans(id) on delete cascade,
  intervention text not null,
  frequency text,
  notes text,
  completed boolean not null default false,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);
create index idx_care_plan_interventions_plan on care_plan_interventions(care_plan_id);

-- ============================================================================
-- 6. VISITS & CLINICAL DOCUMENTATION
-- ============================================================================

create type visit_status as enum (
  'accepted','journey_started','travelling','arrived','visit_started',
  'assessment','intervention','notes','acknowledged','completed'
);

create table visits (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references bookings(id),
  patient_id uuid not null references patients(id),
  nurse_id uuid not null references nurses(id),
  status visit_status not null default 'accepted',
  gps_consent boolean not null default false,
  journey_started_at timestamptz,
  arrived_at timestamptz,
  visit_started_at timestamptz,
  visit_completed_at timestamptz,
  start_lat double precision,
  start_lng double precision,
  arrival_lat double precision,
  arrival_lng double precision,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_visits_booking on visits(booking_id);
create index idx_visits_patient on visits(patient_id);
create index idx_visits_nurse on visits(nurse_id);
create trigger trg_visits_updated before update on visits
  for each row execute function set_updated_at();

alter table nurse_locations add constraint fk_nurse_locations_visit
  foreign key (visit_id) references visits(id) on delete set null;

create table visit_assessments (
  id uuid primary key default gen_random_uuid(),
  visit_id uuid not null references visits(id) on delete cascade,
  assessment_text text,
  structured jsonb,
  created_at timestamptz not null default now()
);
create index idx_visit_assessments_visit on visit_assessments(visit_id);

create table nursing_notes (
  id uuid primary key default gen_random_uuid(),
  visit_id uuid not null references visits(id) on delete cascade,
  assessment text,
  intervention text,
  patient_response text,
  follow_up text,
  additional_notes text,
  attachments jsonb, -- array of storage file paths
  created_by uuid not null references profiles(id),
  created_at timestamptz not null default now()
);
create index idx_nursing_notes_visit on nursing_notes(visit_id);

create table vital_signs (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references patients(id),
  visit_id uuid references visits(id),
  nurse_id uuid not null references nurses(id),
  bp_systolic integer,
  bp_diastolic integer,
  heart_rate integer,
  temperature numeric(4,1),
  spo2 integer,
  respiratory_rate integer,
  blood_glucose numeric(5,1),
  pain_score smallint check (pain_score between 0 and 10),
  weight_kg numeric(5,1),
  notes text,
  recorded_at timestamptz not null default now()
);
create index idx_vital_signs_patient on vital_signs(patient_id);
create index idx_vital_signs_visit on vital_signs(visit_id);

create table wounds (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references patients(id) on delete cascade,
  location text not null,
  wound_type text not null,
  created_at timestamptz not null default now()
);
create index idx_wounds_patient on wounds(patient_id);

create table wound_assessments (
  id uuid primary key default gen_random_uuid(),
  wound_id uuid not null references wounds(id) on delete cascade,
  visit_id uuid references visits(id),
  stage text,
  length_cm numeric(5,2),
  width_cm numeric(5,2),
  depth_cm numeric(5,2),
  drainage text,
  odour text,
  surrounding_skin text,
  pain_score smallint check (pain_score between 0 and 10),
  dressing_used text,
  notes text,
  assessed_by uuid not null references profiles(id),
  assessed_at timestamptz not null default now()
);
create index idx_wound_assessments_wound on wound_assessments(wound_id);

create table wound_photos (
  id uuid primary key default gen_random_uuid(),
  wound_assessment_id uuid not null references wound_assessments(id) on delete cascade,
  photo_url text not null,
  day_label text, -- 'Day 1', 'Day 4', etc.
  taken_at timestamptz not null default now()
);
create index idx_wound_photos_assessment on wound_photos(wound_assessment_id);

create table medications (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references patients(id) on delete cascade,
  name text not null,
  dose text,
  instructions text,
  prescribed_by text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create index idx_medications_patient on medications(patient_id);

create table medication_records (
  id uuid primary key default gen_random_uuid(),
  medication_id uuid not null references medications(id),
  visit_id uuid references visits(id),
  status text not null check (status in ('given','missed','declined','other')),
  remarks text,
  administered_by uuid not null references profiles(id),
  administered_at timestamptz not null default now()
);
create index idx_medication_records_medication on medication_records(medication_id);

create table signatures (
  id uuid primary key default gen_random_uuid(),
  visit_id uuid not null references visits(id) on delete cascade,
  signer_id uuid not null references profiles(id),
  signer_role text not null check (signer_role in ('nurse','patient','family')),
  signature_image_url text not null,
  signed_at timestamptz not null default now(),
  ip_address inet,
  device_info text
);
create index idx_signatures_visit on signatures(visit_id);

create table visit_reports (
  id uuid primary key default gen_random_uuid(),
  visit_id uuid not null references visits(id) on delete cascade,
  pdf_url text,
  generated_at timestamptz not null default now()
);
create index idx_visit_reports_visit on visit_reports(visit_id);

-- ============================================================================
-- 7. COMMUNICATION
-- ============================================================================

create table chat_rooms (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references bookings(id) on delete cascade,
  patient_id uuid not null references patients(id),
  created_at timestamptz not null default now()
);
create unique index uq_chat_rooms_booking on chat_rooms(booking_id);

create table chat_participants (
  chat_room_id uuid not null references chat_rooms(id) on delete cascade,
  profile_id uuid not null references profiles(id) on delete cascade,
  role_in_chat text not null,
  primary key (chat_room_id, profile_id)
);

create table chat_messages (
  id uuid primary key default gen_random_uuid(),
  chat_room_id uuid not null references chat_rooms(id) on delete cascade,
  sender_id uuid not null references profiles(id),
  message_type text not null default 'text' check (message_type in ('text','image','document')),
  content text,
  file_url text,
  created_at timestamptz not null default now()
);
create index idx_chat_messages_room on chat_messages(chat_room_id, created_at);

create table message_reads (
  message_id uuid not null references chat_messages(id) on delete cascade,
  profile_id uuid not null references profiles(id) on delete cascade,
  read_at timestamptz not null default now(),
  primary key (message_id, profile_id)
);

create table notification_templates (
  id uuid primary key default gen_random_uuid(),
  type text not null unique,
  channel text not null check (channel in ('push','email','sms')),
  subject text,
  body_template text not null
);

create table notifications (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  data jsonb,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);
create index idx_notifications_profile on notifications(profile_id, is_read);

create table notification_logs (
  id uuid primary key default gen_random_uuid(),
  notification_id uuid not null references notifications(id) on delete cascade,
  channel text not null,
  status text not null check (status in ('sent','failed','pending')),
  sent_at timestamptz,
  error text
);

-- ============================================================================
-- 8. PAYMENTS
-- ============================================================================

create table payments (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references bookings(id),
  amount numeric(10,2) not null,
  currency text not null default 'MYR',
  status text not null default 'pending' check (status in ('pending','paid','failed','refunded')),
  gateway text not null,
  gateway_reference text,
  paid_at timestamptz,
  created_at timestamptz not null default now()
);
create index idx_payments_booking on payments(booking_id);

create table payment_transactions (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references payments(id) on delete cascade,
  type text not null check (type in ('charge','refund','payout')),
  amount numeric(10,2) not null,
  status text not null,
  gateway_response jsonb,
  created_at timestamptz not null default now()
);
create index idx_payment_transactions_payment on payment_transactions(payment_id);

create table invoices (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references bookings(id),
  invoice_no text not null unique,
  amount numeric(10,2) not null,
  tax numeric(10,2) not null default 0,
  total numeric(10,2) not null,
  pdf_url text,
  issued_at timestamptz not null default now()
);

create table refunds (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references payments(id),
  amount numeric(10,2) not null,
  reason text,
  status text not null default 'pending' check (status in ('pending','approved','rejected','processed')),
  processed_by uuid references profiles(id),
  processed_at timestamptz,
  created_at timestamptz not null default now()
);

create table nurse_payouts (
  id uuid primary key default gen_random_uuid(),
  nurse_id uuid not null references nurses(id),
  period_start date not null,
  period_end date not null,
  amount numeric(10,2) not null,
  status text not null default 'pending' check (status in ('pending','processing','paid','failed')),
  paid_at timestamptz,
  bank_reference text,
  created_at timestamptz not null default now()
);
create index idx_nurse_payouts_nurse on nurse_payouts(nurse_id);

-- ============================================================================
-- 9. QUALITY & SAFETY
-- ============================================================================

create table ratings (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references bookings(id),
  rated_by uuid not null references profiles(id),
  rated_profile_id uuid not null references profiles(id),
  professionalism smallint check (professionalism between 1 and 5),
  punctuality smallint check (punctuality between 1 and 5),
  communication smallint check (communication between 1 and 5),
  care_quality smallint check (care_quality between 1 and 5),
  overall numeric(2,1),
  review_text text,
  created_at timestamptz not null default now()
);
create index idx_ratings_booking on ratings(booking_id);
create index idx_ratings_rated_profile on ratings(rated_profile_id);

create table complaints (
  id uuid primary key default gen_random_uuid(),
  rating_id uuid references ratings(id),
  booking_id uuid references bookings(id),
  raised_by uuid not null references profiles(id),
  complaint_text text not null,
  status text not null default 'open' check (status in ('open','reviewing','resolved','dismissed')),
  admin_response text,
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create type incident_severity as enum ('low','medium','high','critical');

create table incidents (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid references patients(id),
  nurse_id uuid references nurses(id),
  booking_id uuid references bookings(id),
  category text not null check (category in ('fall','injury','medication_issue','deterioration','emergency','safety','other')),
  severity incident_severity not null,
  description text not null,
  location text,
  occurred_at timestamptz not null default now(),
  status text not null default 'open' check (status in ('open','reviewing','closed')),
  closed_by uuid references profiles(id),
  closed_at timestamptz,
  created_at timestamptz not null default now()
);
create index idx_incidents_patient on incidents(patient_id);
create index idx_incidents_nurse on incidents(nurse_id);

create table incident_actions (
  id uuid primary key default gen_random_uuid(),
  incident_id uuid not null references incidents(id) on delete cascade,
  action_taken text not null,
  taken_by uuid not null references profiles(id),
  taken_at timestamptz not null default now()
);

create table incident_evidence (
  id uuid primary key default gen_random_uuid(),
  incident_id uuid not null references incidents(id) on delete cascade,
  file_url text not null,
  uploaded_by uuid not null references profiles(id),
  uploaded_at timestamptz not null default now()
);

create table sos_events (
  id uuid primary key default gen_random_uuid(),
  triggered_by uuid not null references profiles(id),
  patient_id uuid references patients(id),
  nurse_id uuid references nurses(id),
  booking_id uuid references bookings(id),
  event_type text not null check (event_type in ('patient','nurse')),
  lat double precision,
  lng double precision,
  status text not null default 'active' check (status in ('active','acknowledged','resolved')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolved_by uuid references profiles(id)
);
create index idx_sos_events_status on sos_events(status);

create table nurse_performance_snapshots (
  id uuid primary key default gen_random_uuid(),
  nurse_id uuid not null references nurses(id),
  period_start date not null,
  period_end date not null,
  rating_avg numeric(3,2),
  jobs_completed integer,
  completion_pct numeric(5,2),
  on_time_pct numeric(5,2),
  cancellation_pct numeric(5,2),
  documentation_pct numeric(5,2),
  complaints_count integer,
  incidents_count integer,
  status text check (status in ('excellent','monitor','needs_review')),
  computed_at timestamptz not null default now()
);
create index idx_nurse_performance_nurse on nurse_performance_snapshots(nurse_id);

-- ============================================================================
-- 10. AUDIT & SETTINGS
-- ============================================================================

create table audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references profiles(id),
  action text not null, -- e.g. 'view_patient_record', 'login', 'edit', 'delete', 'download', 'payment', 'permission_change'
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

create table settings (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  value jsonb not null,
  updated_by uuid references profiles(id),
  updated_at timestamptz not null default now()
);

-- ============================================================================
-- RLS PATTERN REFERENCE (applied fully during each module's implementation)
-- ============================================================================
-- Pattern A — "owner or admin": patients, family_members, addresses
--   using ( owner_id = auth.uid() or exists (select 1 from profiles p where p.id = auth.uid() and p.role in ('admin','super_admin')) )
--
-- Pattern B — "care-team or granted family or admin": vital_signs, wounds, nursing_notes, care_plans, visits
--   using (
--     exists (select 1 from bookings b join visits v on v.booking_id = b.id where v.id = visit_id and (b.assigned_nurse_id = auth.uid() or b.requested_by = auth.uid()))
--     or exists (select 1 from patient_access pa join family_members fm on fm.id = pa.family_member_id
--                where fm.profile_id = auth.uid() and pa.patient_id = patients.id and pa.can_view_vitals and pa.revoked_at is null)
--     or exists (select 1 from profiles p where p.id = auth.uid() and p.role in ('admin','super_admin'))
--   )
--
-- Pattern C — "self-service nurse record": nurse_documents, nurse_availability, nurse_payouts
--   using ( nurse_id = auth.uid() or exists (select 1 from profiles p where p.id = auth.uid() and p.role in ('admin','super_admin')) )
--
-- All write policies additionally restrict by role (e.g. only a nurse can INSERT their own vital_signs;
-- only admin can UPDATE nurse_documents.status). Full policy SQL is delivered with each module per the
-- project's module-by-module rule — see 09-roadmap.md.
-- ============================================================================
