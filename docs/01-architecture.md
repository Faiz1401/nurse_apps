# Home Nursing Platform — System Architecture

**Stack decision (locked in):**
- **Client app:** Flutter (Dart) — single codebase, three role-based shells (Patient/Family, Nurse, Admin) inside one app, gated by role after login. Runs on the Android Studio emulator during development; same codebase compiles to a real Android device and, later, iOS.
- **Admin dashboard:** same Flutter codebase compiled to **Flutter Web**, so "the same backend/API" requirement (your §0 goal) is met with zero duplicated logic. Desktop-first responsive layout for that shell only, per §46.
- **Backend:** Supabase (hosted Postgres + Auth + Storage + Realtime + Edge Functions). No separate PHP/Node server. This replaces §41-43 of your original spec entirely.
- **Business logic that can't live in RLS/client code** (payment gateway calls, nurse-matching score computation, PDF report generation, scheduled jobs like document-expiry checks) → **Supabase Edge Functions** (Deno/TypeScript).

This is a deliberate substitution for your original PHP+MySQL+Bootstrap stack (§43), which you approved when choosing "Supabase-native design."

---

## 1. High-level component diagram

```
┌─────────────────────────────── Flutter App (single codebase) ───────────────────────────────┐
│                                                                                                 │
│   Patient/Family shell   │   Nurse shell            │   Admin shell (compiled as Flutter Web)  │
│   (mobile-first)         │   (mobile-first)         │   (desktop-first, responsive)            │
│                                                                                                 │
└───────────────┬─────────────────────────┬──────────────────────────┬─────────────────────────┘
                 │                         │                          │
                 │         supabase_flutter SDK (Auth, Postgrest, Realtime, Storage)
                 │                         │                          │
┌────────────────▼─────────────────────────▼──────────────────────────▼────────────────────────┐
│                                      SUPABASE PROJECT                                          │
│                                                                                                 │
│  ┌───────────────┐  ┌──────────────┐  ┌───────────────┐  ┌────────────────────────────────┐  │
│  │  Auth          │  │  Postgres    │  │  Storage       │  │  Realtime                       │  │
│  │  (email/OTP,   │  │  (RLS on     │  │  (docs, wound  │  │  (chat, live nurse tracking,    │  │
│  │  session mgmt) │  │  every table)│  │  photos, sigs) │  │  notifications, booking status) │  │
│  └───────────────┘  └──────────────┘  └───────────────┘  └────────────────────────────────┘  │
│                                                                                                 │
│  ┌─────────────────────────────── Edge Functions (Deno/TS) ────────────────────────────────┐  │
│  │  match-nurses · create-booking-offer · accept-booking (atomic lock) · compute-price       │  │
│  │  payment-webhook · generate-visit-report-pdf · send-notification · nightly-doc-expiry-check│  │
│  │  compute-nurse-performance · sos-dispatch                                                  │  │
│  └────────────────────────────────────────────────────────────────────────────────────────┘  │
└───────────────┬─────────────────────────────────────────────────┬────────────────────────────┘
                 │                                                 │
     ┌───────────▼───────────┐                         ┌──────────▼───────────┐
     │  Payment gateway       │                         │  Push / Email / SMS   │
     │  (abstracted — Stripe  │                         │  (FCM push, Resend/   │
     │  or local MY gateway   │                         │  Supabase SMTP email, │
     │  e.g. ToyyibPay/Billplz│                         │  Twilio SMS optional) │
     │  behind one interface) │                         └───────────────────────┘
     └────────────────────────┘
     ┌────────────────────────┐
     │  Maps (Google Maps SDK  │
     │  for Flutter, abstracted│
     │  behind a MapProvider   │
     │  interface)             │
     └────────────────────────┘
```

## 2. Why Edge Functions instead of "just RLS + client"

Most CRUD (read patient, create booking, post chat message, log vital signs) is safe to do directly from the Flutter client via Postgrest, protected by RLS. A few operations must NOT run on the client because they require atomicity, a secret key, or cross-user side effects:

| Operation | Why it needs an Edge Function |
|---|---|
| Accepting a job (§11) | Must lock the row so two nurses can't both accept — client-side "check then update" has a race condition. Uses `SELECT ... FOR UPDATE` inside a Postgres function called via RPC, or a Postgres `UPDATE ... WHERE status='pending' RETURNING *` atomic guard. |
| Smart matching score (§6) | Reads across nurse availability, distance, workload, ratings — a server-side scoring function keeps the algorithm out of the client and configurable via `settings` table without an app release. |
| Payment charge/refund | Needs the gateway's secret API key — never ship that in the Flutter app. |
| Visit report PDF (§23) | PDF generation is heavier than a mobile client should do reliably; also needs to be identical regardless of which device requests it. |
| Notification fan-out (§26) | Needs FCM server key / SMTP credentials. |
| Nightly document-expiry check (§10) | Scheduled job, no user triggers it. |
| Nurse performance snapshot (§31) | Aggregation job, run on a schedule, not per-request. |

Everything else (viewing bookings, posting vitals, sending chat messages, browsing services) goes straight from Flutter to Postgres through RLS.

## 3. RBAC model

Supabase Auth issues a JWT containing `auth.uid()`. We do **not** use Supabase's raw `auth.users` for role storage — instead:

- `public.profiles` (1:1 with `auth.users`) has a `role` column (`patient | family | nurse | admin | super_admin`).
- Every RLS policy joins back to `profiles.role` via `auth.uid()`.
- `public.permissions` + `public.role_permissions` exist for the **granular, admin-configurable** permissions your spec asks for (§33 "assign roles, manage permissions") — these drive in-app feature gating (e.g., hide the "override booking status" button) on top of the hard RLS boundary. RLS is the security boundary; the permissions table is the UX/feature-flag layer — never rely on the latter alone for anything sensitive.
- Patient-level access for family members is **not** a role — it's a row-level grant in `patient_access` (§3), checked in RLS policies on `patients`, `vital_signs`, `wounds`, `visits`, etc.

Full matrix: see [05-rbac-matrix.md](05-rbac-matrix.md).

## 4. Real-time / live tracking (§14)

- Nurse app writes its GPS point (only while a visit is in an active travelling/in-progress state, and only if `gps_consent = true` on that visit) to a lightweight `nurse_locations` table (latest point per nurse, upserted, not a full history table — avoids unbounded growth and matches "privacy-aware" requirement).
- Client/family and Admin subscribe via **Supabase Realtime** to that row filtered by `nurse_id` (client) or unfiltered for Admin's live ops map, gated by RLS so a client can only subscribe to the nurse on *their own* active booking.
- Location stops being broadcast the moment the visit leaves an active state (trigger clears/ignores the row), enforcing "tracking must require consent and stop appropriately."

## 5. Offline / mobile-first considerations

- Nurse app must tolerate poor connectivity in-home (rural visits). Use a local queue (e.g. `sqflite` or `Isar`) for vitals/nursing notes/wound entries drafted offline, synced to Supabase when connectivity returns. This isn't in your original spec but is a hard requirement for any real home-visit app — flagging it now so it's designed in from Phase 2, not retrofitted.

## 6. Security posture (maps to §45)

| Original PHP requirement | Supabase equivalent |
|---|---|
| Password hashing | Handled entirely by Supabase Auth (bcrypt), never touched by us |
| Prepared statements / SQL injection | Postgrest + parameterized RPC calls; no raw SQL string building anywhere in the client |
| CSRF | N/A — mobile app uses bearer JWT, not cookies |
| XSS | N/A for Flutter native; Flutter Web escapes by default, but sanitize any user-generated HTML-like text before rendering |
| RBAC | RLS policies (server-enforced, not just UI-hidden) |
| File upload validation | Storage bucket policies restrict MIME type + size per bucket (`wound-photos`, `nurse-documents`, `signatures`, `chat-attachments`) |
| Session timeout | Supabase Auth session expiry + refresh token rotation |
| Audit logging | Postgres trigger-based audit log (§40) on all clinically-sensitive tables, not reliant on the client remembering to log |
| Least privilege | RLS default-deny; every table starts with RLS enabled and no policies, then explicit policies added per role |

---

Next docs: [02-module-tree.md](02-module-tree.md) · [03-database-schema.sql](03-database-schema.sql) · [04-database-erd.md](04-database-erd.md) · [05-rbac-matrix.md](05-rbac-matrix.md) · [06-api-design.md](06-api-design.md) · [07-booking-state-machine.md](07-booking-state-machine.md) · [08-folder-structure.md](08-folder-structure.md) · [09-roadmap.md](09-roadmap.md)
