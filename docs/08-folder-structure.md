# Project Folder Structure

Single Flutter project. One codebase, three role-based shells, compiled to Android/iOS (mobile) and Web (admin). Feature-first structure — mirrors the module tree in [02-module-tree.md](02-module-tree.md), not a giant `screens/`+`models/` split.

```
nurse_apps/
├── docs/                          ← architecture docs (this set)
│
├── supabase/
│   ├── migrations/                ← SQL migrations (numbered, one per module as built)
│   │   └── 0001_init_identity_rbac.sql, 0002_patients_family.sql, ...
│   ├── functions/                 ← Edge Functions (Deno/TS), one folder per function
│   │   ├── match-nurses/
│   │   ├── accept-booking/
│   │   ├── compute-price/
│   │   ├── payments-webhook/
│   │   ├── generate-visit-report/
│   │   └── ...
│   ├── seed.sql                   ← dev seed data (services, skills, demo users)
│   └── config.toml
│
└── app/                           ← the Flutter project (flutter create app)
    ├── android/                   ← native Android project (opened/run via Android Studio)
    ├── ios/
    ├── web/
    ├── lib/
    │   ├── main.dart
    │   ├── app.dart                       ← MaterialApp, role-based router
    │   ├── core/
    │   │   ├── supabase_client.dart
    │   │   ├── router/                    ← go_router config, role guards
    │   │   ├── theme/                     ← shared design system (§46)
    │   │   ├── widgets/                   ← shared cards, status badges, timeline, step forms
    │   │   └── utils/
    │   ├── shells/
    │   │   ├── patient_shell/             ← bottom nav: Dashboard, Book, Patients, Bookings, Records, Messages, Payments, Notifications, Profile
    │   │   ├── nurse_shell/               ← Dashboard, Jobs, My Jobs, Calendar, Patients, Documentation, Messages, Earnings, Verification, Profile
    │   │   └── admin_shell/               ← desktop-first side nav (Flutter Web build target)
    │   ├── features/
    │   │   ├── auth/
    │   │   ├── client_profile/
    │   │   ├── patients/
    │   │   ├── family_access/
    │   │   ├── services_catalog/
    │   │   ├── nurse_profile/
    │   │   ├── nurse_verification/
    │   │   ├── nurse_availability/
    │   │   ├── search_matching/
    │   │   ├── booking/
    │   │   │   ├── wizard/                ← the 11-step booking flow
    │   │   │   ├── job_marketplace/
    │   │   │   └── status_tracking/
    │   │   ├── visit_workflow/
    │   │   ├── live_tracking/
    │   │   ├── care_plans/
    │   │   ├── vital_signs/
    │   │   ├── nursing_notes/
    │   │   ├── wound_management/
    │   │   ├── medication_records/
    │   │   ├── signatures/
    │   │   ├── visit_reports/
    │   │   ├── health_timeline/
    │   │   ├── chat/
    │   │   ├── notifications/
    │   │   ├── payments/
    │   │   ├── ratings_reviews/
    │   │   ├── incidents/
    │   │   ├── sos/
    │   │   ├── nurse_performance/
    │   │   └── admin/
    │   │       ├── dashboard/
    │   │       ├── user_management/
    │   │       ├── patient_oversight/
    │   │       ├── nurse_management/
    │   │       ├── booking_control_center/
    │   │       ├── live_operations/
    │   │       ├── service_pricing/
    │   │       ├── reports_analytics/
    │   │       ├── audit_logs/
    │   │       └── settings/
    │   └── data/
    │       ├── models/                    ← one .dart per table, hand-written or generated
    │       └── repositories/              ← wraps Postgrest/RPC calls per feature, no raw supabase calls inside widgets
    ├── test/                              ← mirrors lib/features structure
    └── pubspec.yaml
```

Each `features/<name>/` folder internally follows: `presentation/` (screens+widgets), `application/` (state — Riverpod/Bloc, TBD when we scaffold), `data/` (repository implementation for that feature). This is decided per-module when we implement it, not pre-built empty now, per the project's own rule not to generate files ahead of need.

**Why `docs/` and `supabase/` sit outside `app/`:** the Supabase project (schema, functions, policies) is the shared backend contract — it shouldn't live inside the Flutter project's own version/build lifecycle, and keeping migrations in `supabase/migrations/` lets you run `supabase db push`/`supabase functions deploy` independently of Flutter builds.
