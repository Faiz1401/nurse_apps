-- ============================================================================
-- Module 7 — Smart Nurse Search
-- View: public_nurse_profiles
--
-- `nurses` itself stays locked to owner-or-admin (Module 4 decision — it
-- carries bank/payout fields). This view is the "public-safe" read path
-- promised back then: it selects only browsable columns, joins in the
-- nurse's display name/photo/gender from `profiles`, aggregates their
-- skills/services as JSON arrays (so a client doesn't need separate access
-- to nurse_skills/nurse_services either), and is filtered to
-- verification_status = 'approved' — an unverified nurse must never surface
-- in client-facing search.
--
-- Views created via the SQL Editor are owned by the `postgres` role, which
-- bypasses RLS on the underlying tables (table owners aren't subject to
-- their own table's RLS unless FORCE ROW LEVEL SECURITY is set, which we
-- haven't done) — so this view legitimately sees all approved nurses
-- regardless of the querying user, while the view's own SELECT list is what
-- keeps bank_name/bank_account_no/bank_account_holder out of reach.
--
-- Deferred: Location/Distance filtering (§5 of the original spec) has no
-- data to filter on yet — nurses don't have any address/service-area/geo
-- field in the schema (nurse_locations, added in a later phase, is a
-- live-visit GPS ping, not a static base location). Real distance search
-- arrives with the Maps integration in Phase 3. "Availability" here means
-- the nurse's global is_available toggle, not a check against a specific
-- requested date/time slot — that needs the Booking wizard's date/time
-- step, which doesn't exist yet.
-- ============================================================================

create view public_nurse_profiles as
select
  n.id,
  p.full_name,
  p.photo_url,
  p.gender,
  n.qualification,
  n.experience_years,
  n.bio,
  n.rating_avg,
  n.jobs_completed,
  n.is_available,
  n.verification_status,
  coalesce(
    (
      select jsonb_agg(jsonb_build_object('id', s.id, 'name', s.name, 'category', s.category))
      from nurse_skills ns
      join skills s on s.id = ns.skill_id
      where ns.nurse_id = n.id
    ),
    '[]'::jsonb
  ) as skills,
  coalesce(
    (
      select jsonb_agg(jsonb_build_object(
        'id', sv.id,
        'name', sv.name,
        'category_id', sv.category_id,
        'price', coalesce(nsv.custom_price, sv.base_price)
      ))
      from nurse_services nsv
      join services sv on sv.id = nsv.service_id
      where nsv.nurse_id = n.id
    ),
    '[]'::jsonb
  ) as services
from nurses n
join profiles p on p.id = n.id
where n.verification_status = 'approved';

grant select on public_nurse_profiles to authenticated;
