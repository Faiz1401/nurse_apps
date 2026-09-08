# Development Roadmap

Carried over from your original §49, unchanged in intent, re-scoped to Supabase + Flutter. Each module, when we build it, follows the same 10-step delivery your prompt specifies (§50): purpose → DB changes → SQL/migration → backend (RLS + Edge Function if needed) → Flutter UI → file locations → integration notes → how to test → security notes → confirmation it doesn't break prior modules.

## Phase 1 — MVP (build order)

1. Supabase project setup + `profiles`/RBAC foundation + Flutter project scaffold (`flutter create`, Android Studio emulator running, Supabase client wired)
2. Auth (register/login/logout/forgot-reset password/OTP/session)
3. Client profile + Patient management
4. Service catalog (categories, services, admin CRUD)
5. Nurse registration + profile
6. Nurse verification (documents, status)
7. Nurse availability
8. Smart nurse search (filters, no scoring yet)
9. Booking wizard (steps 1–7: patient/service/description/date/time/duration/location)
10. Booking assignment + job marketplace + atomic accept (steps 8–10, without scoring — direct preferred-nurse or "open to any" first)
11. Booking status machine + history
12. Admin dashboard v1 (counts, basic tables)
13. Payment foundation (checkout stub with one real gateway wired via Edge Function)
14. Notifications foundation (in-app + push via FCM)

## Phase 2 — Clinical

15. Patient digital health profile (conditions/allergies/history/mobility/instructions)
16. Care plans + interventions
17. Vital signs
18. Nursing notes
19. Visit workflow (accepted → completed state machine, GPS-consented timestamps)
20. Digital signatures
21. Visit report generation (PDF)
22. Wound management (assessments + photo timeline)
23. Medication records
24. Patient health timeline (aggregating view)

## Phase 3 — Advanced

25. Live nurse tracking (Realtime + privacy controls)
26. Smart nurse matching engine (scored recommendations, configurable weights via `settings`)
27. Family/caregiver module (invites, granular `patient_access`)
28. Chat (booking-scoped, Realtime)
29. Incident management
30. SOS/emergency
31. Nurse performance scoring
32. Admin: booking control center, live operations map, nurse management, service & pricing config
33. Reports & analytics + audit logs UI

## Phase 4 — Premium (post-launch, not part of initial build)

34. Telehealth
35. Subscription packages
36. Advanced analytics
37. AI documentation assistant (assistive only — never autonomous diagnosis/prescribing, per §19/§20)
38. Corporate/hospital accounts
39. Third-party API integrations

---

## Immediate next step

With architecture approved, Module 1 ("Supabase project setup + RBAC foundation + Flutter scaffold") is the first implementation unit. That will produce:
- The actual Supabase project (or local `supabase init` + Docker for local dev)
- `supabase/migrations/0001_init_identity_rbac.sql` (the identity/RBAC portion of [03-database-schema.sql](03-database-schema.sql), with full RLS policies)
- `flutter create app`, wired to `supabase_flutter`, running on your Android Studio emulator with a working login screen

Say the word and I'll start on Module 1.
