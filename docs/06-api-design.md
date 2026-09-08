# API Design

Two layers, both reachable identically from the Flutter mobile app and the Flutter Web admin build — satisfying "future mobile app uses the same backend/API" by construction (there's only ever been one client architecture).

1. **Direct Postgrest/Realtime calls** via `supabase_flutter` for anything RLS can safely gate (the majority of CRUD).
2. **Edge Functions** (called via `supabase.functions.invoke(...)`, which is just an authenticated HTTPS POST) for anything needing atomicity, secrets, or heavy computation.

This replaces your original §48 REST endpoint list. Below is the equivalent surface expressed in Supabase terms.

## Auth (Supabase Auth — no custom endpoint needed)

| Action | Call |
|---|---|
| Register | `supabase.auth.signUp(email, password)` → trigger creates `profiles` row |
| Login | `supabase.auth.signInWithPassword(...)` |
| OTP verification | `supabase.auth.verifyOTP(...)` |
| Logout | `supabase.auth.signOut()` |
| Forgot/reset password | `supabase.auth.resetPasswordForEmail(...)` |
| Session | `supabase.auth.currentSession`, auto-refreshed by SDK |

## Direct table access (Postgrest, RLS-gated) — representative set

```
GET/POST   patients                         list/create own patients
GET/PATCH  patients/{id}
GET/POST   family_members, patient_access
GET        services, service_categories, service_prices   (public read)
GET        nurses (search/browse, filtered client-side + server filters)
GET/POST   bookings                         create booking, list own/assigned
GET/PATCH  bookings/{id}
GET/POST   care_plans, care_plan_interventions
GET/POST   vital_signs
GET/POST   nursing_notes, visit_assessments
GET/POST   wounds, wound_assessments, wound_photos
GET/POST   medications, medication_records
GET/POST   chat_messages (+ Realtime subscription on chat_room_id)
GET        notifications (+ Realtime subscription on profile_id)
GET/POST   ratings, complaints
GET/POST   incidents, incident_actions, incident_evidence
```

All of these are ordinary `supabase.from('table').select/insert/update()` calls — no bespoke backend code, just RLS policies (see [05-rbac-matrix.md](05-rbac-matrix.md)) and, where needed, Postgres views (e.g. `patient_timeline`, `nurse_search_view` with computed distance).

## Edge Functions (the only "real" backend code)

| Function | Purpose | Auth |
|---|---|---|
| `POST /functions/v1/match-nurses` | Given a draft booking (service, datetime, location), returns scored/ranked nurse candidates (§6) | Client (own booking only) |
| `POST /functions/v1/create-booking-offer` | Creates the booking + fans out `booking_assignments` to matched/preferred nurse(s) | Client |
| `POST /functions/v1/accept-booking/{assignment_id}` | Atomically accepts a job: `UPDATE booking_assignments SET status='accepted' WHERE id=$1 AND status='offered'` inside a transaction that also locks `bookings` — guarantees only one nurse wins (§11) | Nurse |
| `POST /functions/v1/reject-booking/{assignment_id}` | Marks offer rejected, triggers re-matching if no other pending offers | Nurse |
| `POST /functions/v1/compute-price` | Applies `service_prices` fee rules (distance/night/weekend/emergency/platform) to produce a quote | Client |
| `POST /functions/v1/visits/{id}/transition` | Validates + applies a visit status transition (§13), stamps timestamps/GPS, writes `booking_status_history` | Nurse |
| `POST /functions/v1/visits/{id}/complete` | Validates signatures exist, marks visit + booking completed, triggers report generation + rating prompt | Nurse |
| `POST /functions/v1/generate-visit-report` | Renders PDF from visit + notes + vitals + signatures, uploads to Storage, writes `visit_reports` | System (triggered by above) |
| `POST /functions/v1/payments/checkout` | Creates a payment intent with the abstracted gateway | Client |
| `POST /functions/v1/payments/webhook` | Gateway calls back here; updates `payments`/`bookings.payment_status` | Gateway (signature-verified, no user JWT) |
| `POST /functions/v1/payments/refund` | Admin-triggered refund | Admin |
| `POST /functions/v1/sos` | Records `sos_events`, notifies emergency contact + admin ops, escalates to incident if needed | Patient/Nurse |
| `POST /functions/v1/send-notification` | Internal helper other functions call; also drives templated push/email/SMS from `notification_templates` | System |
| `GET  /functions/v1/reports/{type}` | Business/nurse/clinical report generation with CSV/PDF export (§39) | Admin |
| Scheduled: `nightly-doc-expiry-check` | Cron (Supabase scheduled function) scans `nurse_documents.expiry_date`, notifies nurse + admin | System |
| Scheduled: `compute-nurse-performance` | Weekly aggregation into `nurse_performance_snapshots` (§31) | System |

## Realtime channels

| Channel | Subscribers | Payload |
|---|---|---|
| `nurse_locations:nurse_id=eq.{id}` | Client on active booking with that nurse; Admin (all) | lat/lng/status |
| `chat_messages:chat_room_id=eq.{id}` | Room participants only (RLS) | new message |
| `notifications:profile_id=eq.{id}` | Owning profile | new notification row |
| `bookings:id=eq.{id}` | Patient/family/nurse on that booking | status change |

## Authorization

Every call — Postgrest or Edge Function — carries the Supabase session JWT. Edge Functions re-derive `auth.uid()` from the JWT server-side (never trust a client-supplied user id) and re-check role/ownership before acting, even though RLS already guards the underlying tables — defense in depth for the functions that bypass RLS via the service-role key internally (e.g. payment webhook, matching engine reading across all nurses).
