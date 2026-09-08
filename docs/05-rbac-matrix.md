# RBAC Matrix

Enforced primarily via **Postgres RLS** (server-side, cannot be bypassed by a modified client). The Flutter app additionally reads `permissions`/`role_permissions` to hide UI it has no access to — a UX nicety, never the security boundary.

Legend: **F** = full access · **O** = own records only · **G** = granted records only (via `patient_access`) · **R** = read-only · **–** = no access

| Module / Table | Patient (Client) | Family/Caregiver | Nurse | Admin | Super Admin |
|---|---|---|---|---|---|
| Own profile | F (own) | F (own) | F (own) | F (own) | F |
| Other profiles | – | – | – | R | F |
| Patients | F (own, owner_id) | R (G) | R (assigned booking only) | F | F |
| Family members / patient_access | F (own patients) | R (own grant) | – | F | F |
| Nurse profile/documents | R (browse verified) | R (browse) | F (own) | F (verify/reject) | F |
| Skills / Services / Pricing | R | R | R | F | F |
| Nurse availability | R (for search) | – | F (own) | R | F |
| Booking — create | F (own patients) | F (if granted) | – | F (on behalf, with reason) | F |
| Booking — view | O | G | O (assigned/offered) | F | F |
| Booking — status change | Cancel own (pre-accept) | – | Accept/reject/progress own | F (override w/ reason) | F |
| Booking assignments (job marketplace) | – | – | R/F (own offers) | F | F |
| Care plans | R (G) | R (G) | F (assigned patient) | R/F | F |
| Vital signs | R (own patient) | R (if can_view_vitals) | F (create, own visit) | R | F |
| Nursing notes | R (own patient, if permitted) | R (if permitted) | F (own visit) | R | F |
| Wound records + photos | R (own patient) | R (if permitted) | F (own visit) | R | F |
| Medication records | R (own patient) | R (if permitted) | F (own visit) | R | F |
| Signatures | Sign own visit | Sign if authorized | Sign own visit | R | F |
| Visit reports | R (own patient) | R (if can_view_reports) | R (own visit) | F | F |
| Chat | Participant only | Participant only (if in room) | Participant only | R (support/dispute) | F |
| Notifications | O | O | O | F (templates) | F |
| Payments (client side) | F (own) | R (if permitted) | – | R | F |
| Nurse earnings/payouts | – | – | O | F | F |
| Ratings/reviews | Create after own booking | – | Create after own booking (rate client) | F (moderate) | F |
| Incidents | Create for own patient; R own | R (if permitted) | Create for own visit; R own | F | F |
| SOS events | Trigger own | Trigger for own patient | Trigger own | F (dispatch/resolve) | F |
| Nurse performance | – | – | R (own) | F | F |
| Admin dashboard / analytics | – | – | – | F | F |
| Audit logs | – | – | – | R | F |
| Settings (fees, templates, flags) | – | – | – | F (scoped) | F |
| User management (create/suspend/assign role) | – | – | – | F (below super_admin) | F |

## Notes

- **Admin vs Super Admin split:** Admin manages day-to-day operations (verification, bookings, support). Only **super_admin** can create other admins, change platform-wide settings that affect fees/compliance, or hard-delete anything (soft-delete only, everywhere else). Enforce via a `role = 'super_admin'` check on those specific RLS policies/Edge Functions, not a blanket "admin can do everything."
- **Nurse visibility into patient data is visit-scoped, not blanket:** a nurse only sees a patient's clinical history for a patient they have an active or past assigned booking with — never the whole patient database. RLS policy joins `bookings.assigned_nurse_id = auth.uid()`.
- **Family access is always additive and revocable**, never a role upgrade — a family member's `profiles.role` stays `family`; what they can see is entirely driven by rows in `patient_access`, which can be revoked instantly (`revoked_at`) without touching their account.
- Every row marked **F/O/G** for a role that also allows admin override should have that override going through the **Admin Booking Control Center / Admin Patient Management** paths with a mandatory `reason` field logged to `audit_logs` — never a silent direct table edit.
