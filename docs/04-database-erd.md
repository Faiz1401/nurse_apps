# Database Relationships (ERD description)

Full DDL is in [03-database-schema.sql](03-database-schema.sql). This doc explains *why* tables connect the way they do — read it alongside the SQL, not instead of it.

## Identity spine

```
auth.users (Supabase-managed)
   └─1:1─ profiles (role, shared fields for every human: patient/family/nurse/admin)
             ├─1:N─ patients (owner_id)            "a client owns N patients"
             ├─1:1─ nurses (id = profiles.id)       "a nurse profile extends a profile"
             └─N:M─ role_permissions (via role)     "admin-configurable feature gates"
```

`nurses.id` reuses `profiles.id` rather than a separate surrogate key — a nurse *is* a profile with role='nurse' plus extra columns, not a separate entity. This avoids a dangling nurse row with no login and keeps every FK that points "at a nurse" also valid as "at a profile" (useful for chat, notifications, ratings which are profile-generic).

## Patient ownership & family access

```
patients ──1:N── emergency_contacts
patients ──1:N── family_members ──1:N── patient_access (per-patient granular grants)
                     └─0:1─ profiles   (null until invite accepted)
```

`patient_access` is the row-level permission table — it, not the `family` role itself, is what RLS checks on `vital_signs`, `wounds`, `visits`, `care_plans`, `visit_reports`. This is what makes access "granular" (§3 requirement): a family member can be granted `can_view_vitals` without `can_view_reports`, etc.

## Nurse capability graph

```
nurses ──N:M── skills (via nurse_skills, with certificate_url + certified_at)
nurses ──N:M── services (via nurse_services, optional custom_price override)
nurses ──1:N── nurse_availability (recurring weekly slots)
nurses ──1:N── nurse_time_off (leave/blocked dates)
nurses ──1:N── nurse_documents (verification, each with its own expiry + status)
nurses ──1:1── nurse_locations (latest GPS point only, upserted)
```

Availability conflict detection (§12) is computed, not stored: at booking time, an Edge Function checks `nurse_availability` minus `nurse_time_off` minus overlapping `bookings.scheduled_date/time+duration` for that nurse.

## Booking → Visit → Clinical chain

```
bookings ─1:N─ booking_assignments   (fan-out offers to matched nurses; unique index prevents double-accept)
bookings ─1:N─ booking_status_history (every transition audited)
bookings ─1:1─ visits                (created once a nurse is accepted)
bookings ─1:1─ chat_rooms
bookings ─1:1─ payments ─1:N─ payment_transactions
bookings ─1:N─ ratings

visits ─1:N─ visit_assessments
visits ─1:N─ nursing_notes
visits ─1:N─ vital_signs
visits ─0:N─ wound_assessments      (a visit may touch multiple existing wounds)
visits ─0:N─ medication_records
visits ─1:N─ signatures             (nurse signs + patient/family signs = 2 rows)
visits ─0:1─ visit_reports          (generated once, after signatures exist)
```

`bookings.status` (the client/admin-facing state machine, §8) and `visits.status` (the nurse's in-visit workflow, §13) are deliberately **two separate enums on two separate tables**. A booking reaching `in_progress` corresponds to a visit somewhere between `visit_started` and `acknowledged` — collapsing them into one status column would conflate "is this job happening" with "which clinical step is the nurse on," which have different audiences (client sees booking status; nurse app drives off visit status).

## Patient clinical record (independent of any single visit)

```
patients ─1:N─ care_plans ─1:N─ care_plan_interventions
patients ─1:N─ vital_signs        (visit_id nullable — a reading can exist without a full visit context, though normally set)
patients ─1:N─ wounds ─1:N─ wound_assessments ─1:N─ wound_photos
patients ─1:N─ medications ─1:N─ medication_records
patients ─1:N─ incidents ─1:N─ incident_actions / incident_evidence
```

The **Patient Health Timeline** (§18) is not a stored table — it's a view/query that unions `visits + vital_signs + nursing_notes + wound_assessments + care_plan_interventions + incidents` filtered by `patient_id` and ordered by timestamp, built as a Postgres view (`patient_timeline`) once the clinical modules exist.

## Audit spine

```
every sensitive table ──logged into──▶ audit_logs (actor_id, action, entity_type, entity_id, patient_id)
```

Implemented as Postgres triggers (`AFTER INSERT/UPDATE/DELETE`) on: `patients`, `vital_signs`, `nursing_notes`, `wound_assessments`, `medication_records`, `visits`, `payments`, `nurse_documents`, `role_permissions`, `patient_access` — i.e. every table where "who looked at / changed this" has clinical, financial, or access-control weight. Non-sensitive tables (e.g. `service_categories`) are not audited.
