# Booking State Machine

Two independent state machines, deliberately not merged (see [04-database-erd.md](04-database-erd.md) for why).

## A. Booking status (`bookings.status`) — client/admin-facing

```
                 ┌──────────┐
                 │ pending  │  (created, awaiting nurse match/offer)
                 └────┬─────┘
                      │ match-nurses + create booking_assignments
                      ▼
                 ┌──────────┐
                 │ matched  │  (offered to ≥1 nurse, awaiting response)
                 └────┬─────┘
            ┌─────────┼──────────────┐
            │ accept  │              │ all reject / timeout
            ▼         │              ▼
      ┌──────────┐    │        ┌───────────┐
      │ accepted │    │        │ rejected  │──▶ (re-match or client cancels)
      └────┬─────┘    │        └───────────┘
           │ nurse starts journey
           ▼
     ┌────────────┐
     │ travelling │
     └────┬───────┘
          │ nurse marks arrived
          ▼
     ┌──────────┐
     │ arrived  │
     └────┬─────┘
          │ nurse starts visit
          ▼
   ┌──────────────┐
   │ in_progress  │
   └──────┬───────┘
          │ visit completed + signed
          ▼
    ┌────────────┐
    │ completed  │  (terminal)
    └────────────┘

Side transitions, reachable from most non-terminal states:
  pending/matched/accepted  ──▶ cancelled     (client or admin, reason required)
  accepted/travelling       ──▶ rescheduled   (client or admin; creates new scheduled_date/time, logs history)
  arrived (no nurse contact)──▶ no_show       (admin adjudicated, reason required)
  any state                 ──▶ escalated     (SOS or incident triggers this; admin must resolve before further transitions)
```

**Rules enforced in the `visits/{id}/transition` Edge Function, not just the UI:**
- Transitions only move forward (or into the explicit side states) — no skipping `pending → in_progress`.
- Every transition writes a `booking_status_history` row with `changed_by` and, for cancel/reschedule/no_show/admin overrides, a mandatory `reason`.
- `accepted` can only be reached by exactly one `booking_assignments` row flipping to `accepted` — enforced by the atomic accept function (§11), preventing double-booking.
- `escalated` freezes further nurse-driven transitions until an admin resolves it (checked in the transition function, not just RLS).

## B. Visit workflow status (`visits.status`) — nurse-facing, inside `in_progress`

```
accepted → journey_started → travelling → arrived → visit_started
   → assessment → intervention → notes → acknowledged → completed
```

Each step stamps its own timestamp column on `visits` (journey_started_at, arrived_at, visit_started_at, visit_completed_at) and, where consented, GPS lat/lng. `acknowledged` requires a `signatures` row from the patient/family before `completed` is reachable — enforces §22's "signature then visit completed" rule at the data layer, not just the UI flow.

## Mapping between the two

| visits.status | corresponding bookings.status |
|---|---|
| accepted | accepted |
| journey_started, travelling | travelling |
| arrived | arrived |
| visit_started, assessment, intervention, notes, acknowledged | in_progress |
| completed | completed |

A Postgres trigger on `visits` keeps `bookings.status` in sync automatically whenever `visits.status` changes — so the client/admin-facing booking status is always derived, never manually kept in two places.
