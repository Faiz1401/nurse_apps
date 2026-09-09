-- ============================================================================
-- Module 6 — Nurse Availability
-- Tables: nurse_availability (recurring weekly working hours), nurse_time_off
-- (leave/blocked dates)
--
-- Conflict detection scope: this module only guards internal consistency —
-- a nurse can't add two overlapping working-hour blocks on the same day, or
-- two overlapping time-off ranges. Checking availability against actual
-- bookings is deferred until the Booking module exists (Phase 1 roadmap
-- steps 9-11) — there's nothing to conflict with yet.
--
-- Self-service, no approval gate: unlike nurse_documents (Module 5), a
-- nurse's own availability/leave is theirs to manage directly — status on
-- nurse_time_off defaults to 'approved' and there's no guard trigger locking
-- it, since there's no review workflow being modeled here.
-- ============================================================================

create table nurse_availability (
  id uuid primary key default gen_random_uuid(),
  nurse_id uuid not null references nurses(id) on delete cascade,
  day_of_week smallint not null check (day_of_week between 0 and 6),
  start_time time not null,
  end_time time not null,
  created_at timestamptz not null default now()
);
create index idx_nurse_availability_nurse on nurse_availability(nurse_id);

create or replace function check_availability_overlap()
returns trigger
language plpgsql
as $$
begin
  if new.start_time >= new.end_time then
    raise exception 'start_time must be before end_time';
  end if;
  if exists (
    select 1 from nurse_availability
    where nurse_id = new.nurse_id
      and day_of_week = new.day_of_week
      and id <> new.id
      and new.start_time < end_time and start_time < new.end_time
  ) then
    raise exception 'This time range overlaps an existing availability slot for that day';
  end if;
  return new;
end;
$$;

create trigger trg_check_availability_overlap
  before insert or update on nurse_availability
  for each row execute function check_availability_overlap();

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

create or replace function check_time_off_overlap()
returns trigger
language plpgsql
as $$
begin
  if new.start_date > new.end_date then
    raise exception 'start_date must be on or before end_date';
  end if;
  if exists (
    select 1 from nurse_time_off
    where nurse_id = new.nurse_id
      and id <> new.id
      and status <> 'rejected'
      and new.start_date <= end_date and new.end_date >= start_date
  ) then
    raise exception 'This date range overlaps existing time off';
  end if;
  return new;
end;
$$;

create trigger trg_check_time_off_overlap
  before insert or update on nurse_time_off
  for each row execute function check_time_off_overlap();

-- ----------------------------------------------------------------------------
-- RLS — standard self-service pattern (owner or admin)
-- ----------------------------------------------------------------------------
alter table nurse_availability enable row level security;
alter table nurse_time_off enable row level security;

create policy nurse_availability_all_via_owner on nurse_availability
  for all using (nurse_id = auth.uid() or is_admin())
  with check (nurse_id = auth.uid() or is_admin());

create policy nurse_time_off_all_via_owner on nurse_time_off
  for all using (nurse_id = auth.uid() or is_admin())
  with check (nurse_id = auth.uid() or is_admin());
