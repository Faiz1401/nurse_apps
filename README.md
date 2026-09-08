# Home Nursing Platform

Complete digital home-care management platform: nurse marketplace + smart matching + booking + live operations + patient digital health record + care plans + vital monitoring + nursing documentation + wound management + family monitoring + chat + payments + incident management + admin analytics + security & audit.

**Stack:** Flutter (mobile + Flutter Web admin) · Supabase (Postgres, Auth, Storage, Realtime, Edge Functions).

## Architecture docs

1. [System Architecture](docs/01-architecture.md)
2. [Module Tree](docs/02-module-tree.md)
3. [Database Schema (SQL)](docs/03-database-schema.sql)
4. [Database ERD / Relationships](docs/04-database-erd.md)
5. [RBAC Matrix](docs/05-rbac-matrix.md)
6. [API Design](docs/06-api-design.md)
7. [Booking State Machine](docs/07-booking-state-machine.md)
8. [Folder Structure](docs/08-folder-structure.md)
9. [Development Roadmap](docs/09-roadmap.md)

Build proceeds module-by-module per the roadmap — no module is implemented without its own migration, RLS policies, Flutter UI, and test/security notes.
