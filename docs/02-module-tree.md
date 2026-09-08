# Module Tree

```
Home Nursing Platform
│
├── 00. Platform Foundation
│   ├── Supabase project (Auth, DB, Storage, Realtime, Edge Functions)
│   ├── RBAC (profiles, permissions, role_permissions, patient_access)
│   └── Audit logging (triggers on sensitive tables)
│
├── 01. Auth & Identity
│   ├── Register / Login / Logout
│   ├── Forgot / Reset password
│   ├── Email/OTP verification
│   ├── Session management
│   └── Biometric unlock (local, device-level — gates access to an already-valid Supabase session)
│
├── 02. Client/Patient Module
│   ├── Client profile
│   ├── Patient management (multi-patient per client)
│   └── Patient digital health profile (conditions, allergies, history, mobility, instructions)
│
├── 03. Family/Caregiver Module
│   ├── Invite family member
│   ├── Granular patient-access permissions
│   └── Revoke access
│
├── 04. Service Catalog
│   ├── Service categories
│   ├── Services (admin-configurable, not hard-coded)
│   └── Pricing rules (base/distance/night/weekend/emergency/platform fee)
│
├── 05. Nurse Module
│   ├── Nurse registration & profile
│   ├── Skills & qualifications
│   ├── Nurse verification (documents, expiry tracking)
│   └── Nurse availability (working hours, leave, blocked dates)
│
├── 06. Search & Matching
│   ├── Smart nurse search (filters)
│   └── Smart nurse matching engine (scored recommendations)
│
├── 07. Booking Module
│   ├── Multi-step booking wizard
│   ├── Booking state machine
│   ├── Nurse job marketplace (accept/reject, atomic locking)
│   └── Booking status history
│
├── 08. Visit & Clinical Workflow
│   ├── Nurse visit workflow (journey → arrival → visit → completion)
│   ├── Live nurse tracking (privacy-aware)
│   ├── Care plans & interventions
│   ├── Vital signs
│   ├── Nursing notes (structured)
│   ├── Wound management (assessments + photo timeline)
│   ├── Medication records
│   ├── Digital signature / acknowledgement
│   └── Visit report generation (PDF)
│
├── 09. Patient Health Timeline
│   └── Aggregated view: visits + vitals + notes + wounds + care-plan + incidents
│
├── 10. Communication
│   ├── Booking-scoped chat (text/image/document)
│   └── Notifications (push/email/SMS, template-driven)
│
├── 11. Payments
│   ├── Client checkout, history, invoices, receipts
│   ├── Nurse earnings & payouts
│   └── Admin transactions, fees, refunds, reconciliation
│
├── 12. Quality & Safety
│   ├── Ratings & reviews
│   ├── Incident management
│   ├── SOS / emergency
│   └── Nurse performance scoring (transparent, configurable)
│
├── 13. Admin
│   ├── Dashboard (KPIs, charts)
│   ├── User management
│   ├── Patient management (read + oversight)
│   ├── Nurse management (verification, skills, services, payouts)
│   ├── Booking control center (assign/reassign/override with reason)
│   ├── Live operations map
│   ├── Service & pricing configuration
│   ├── Reports & analytics (business/nurse/clinical, CSV/PDF export)
│   ├── Audit logs
│   └── Settings (notification templates, fee config, feature flags)
│
└── 14. Cross-cutting
    ├── Security (RLS, storage policies, session mgmt)
    ├── Audit trail
    └── API surface (shared by Flutter mobile + Flutter Web admin — see 06-api-design.md)
```

This tree maps directly to the Postgres schema in [03-database-schema.sql](03-database-schema.sql) and the Flutter feature folders in [08-folder-structure.md](08-folder-structure.md) — one module here = roughly one `lib/features/<module>/` package.
