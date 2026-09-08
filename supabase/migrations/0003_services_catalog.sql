-- ============================================================================
-- Module 3 — Service Catalog
-- Tables: skills, service_categories, services
--
-- `skills` is created here (not in the Nurse module, which comes later) since
-- `services.required_skill_id` needs to reference it and forward-referencing
-- a nonexistent table isn't possible. It's a tiny, dependency-free lookup
-- table — no nurse UI is built here, just the shared reference data.
--
-- Fee-type pricing (distance/night/weekend/emergency/platform fees via
-- `service_prices`) is deliberately deferred to Phase 3 (docs/09-roadmap.md
-- #32, "Admin Service & Pricing") — this module only needs a service's own
-- base_price to unblock the booking wizard later in Phase 1.
--
-- Not audited: these are public catalog/reference tables, not patient or
-- financial records — see docs/04-database-erd.md's audit-spine note.
-- ============================================================================

create table skills (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  category text
);

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

-- ----------------------------------------------------------------------------
-- RLS: catalog data is readable by any signed-in user (clients need it to
-- browse/book, nurses need it to see what they're qualified for); writable
-- by admins only.
-- ----------------------------------------------------------------------------

alter table skills enable row level security;
alter table service_categories enable row level security;
alter table services enable row level security;

create policy skills_select_authenticated on skills
  for select using (auth.role() = 'authenticated');
create policy skills_write_admin_only on skills
  for all using (is_admin()) with check (is_admin());

create policy service_categories_select_authenticated on service_categories
  for select using (auth.role() = 'authenticated');
create policy service_categories_write_admin_only on service_categories
  for all using (is_admin()) with check (is_admin());

create policy services_select_authenticated on services
  for select using (auth.role() = 'authenticated');
create policy services_write_admin_only on services
  for all using (is_admin()) with check (is_admin());
