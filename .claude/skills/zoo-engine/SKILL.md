---
name: zoo-engine
description: Architecture and conventions for the harbour-zoo C++ engine — event-sourced core, deterministic RNG, state projection, economy, challenge/specimen/unlock services. Use when writing or changing any C++ under src/engine, designing events, or touching persistence and determinism.
---

# The Zoo engine

The engine is **UI-agnostic, deterministic, and unit-tested on desktop**. QML never touches it
except through one thin facade. If you're tempted to put logic in QML or call `time()` in a
service, stop — it belongs here, injectable and tested.

## Layering (hard rule)

```
QML  →  ZooController (thin QObject facade)  →  engine services  →  EventStore (SQLite)
```

- QML **never** touches SQLite. The engine **never** imports Qt Quick (`QtQuick`, `QtGui`).
- `ZooController` is a thin translator: it exposes Q_PROPERTYs/Q_INVOKABLEs, forwards to
  services, and emits change signals. No business logic lives in it.

## Event sourcing is the spine

`events` is an **append-only log** — the single source of truth. **Never UPDATE or DELETE** a
row in `events`. Everything else (`projection_snapshot`, `specimen_instances`) is derived and
safe to drop and rebuild by replaying the log. A key invariant, tested (DoD §9.8): dropping
`projection_snapshot` and replaying `events` reproduces **identical** state.

Adding a feature usually means: define an event type → append it → let `StateProjection` fold it
into state → let `UnlockRules` query the stream. Combos/secrets are trivial because they're just
queries over the log (e.g. "two tagged completions on one `local_date`").

Event types (payloads in spec §4.2): `app_opened`, `challenge_issued`, `challenge_completed`,
`challenge_skipped`, `currency_earned`, `currency_spent`, `egg_hatched`, `specimen_interacted`,
`rule_granted`. Every event carries `ts_utc`, `local_date`, `local_hour`.

**The concept has grown past the original spec** — see `docs/utility-spine.md` and
`docs/zoo-meta.md`. These add first-class events to the same append-only log (all projectable,
testable, replayable):
- **Utility spine (now v1):** `habit_created`, `habit_logged`, `habit_archived`, `focus_started`,
  `focus_completed`, `xp_earned`.
- **Living-zoo meta:** `enclosure_built`, `enclosure_upgraded`, `resident_placed`,
  `resident_removed`, `decoration_bought`, `renown_earned`, `renown_spent`, `keeper_leveled`,
  `badge_granted`.
The projection now also derives: per-habit progress + gentle per-habit streaks, focus totals,
Keeper level & Zoo Rating, per-enclosure happiness, unlocked biomes, and the badge set. New
services follow the same rules as below (single responsibility, deterministic, desktop-tested):
`HabitService`, `FocusService`, `EnclosureService`, `KeeperService` (XP/level/rating/badges), and
a `CoachProvider` seam (opt-in offline model, static fallback) analogous to `FlavorProvider`.

## Determinism (the whole thing rests on this)

All randomness goes through `Rng` (splitmix64 seed → PCG32 stream). **Seeds are derived, never
`time()`:**
- daily challenge: `mix(install_salt, ordinal(local_date))`
- hatch rarity roll: `mix(install_salt, total_hatched_counter)` — this is also what makes the
  pity counter (creative §3) reproducible and testable
- specimen params: the instance `seed` stored at mint time (so a specimen looks/behaves the
  same forever)

The **only** two impure things in the engine are (1) a `Clock` abstraction and (2) an
install-salt generator — **both injectable**, so tests pin them and assert exact outputs. If any
other service reads wall-clock time or `rand()`, that's a bug.

## The services (single responsibilities)

- **EventStore** — append + read the log; owns the SQLite connection and schema/`install_meta`
  bootstrap. Nothing else writes SQLite.
- **StateProjection** — folds the event stream into projected state (wallet, streak+grace,
  today, owned, counters, granted_rules). Streak logic is the trickiest: increment on first
  `challenge_completed` of a new `local_date`; a missed day spends one `grace_remaining` before
  breaking; grace replenishes +1 per N completed (cap 2); reset to 0 only when grace is
  exhausted — with warm copy, never shaming (spec §4.3). Cover the edge cases in tests.
- **Economy** — reads the projection, rejects spends it can't afford, emits `currency_earned` /
  `currency_spent`. No hard currency, no IAP, ever.
- **ChallengeService** — loads `data/challenges.json`, selects the day's challenge from the date
  seed, avoids recent repeats (track last K issued in the projection).
- **SpecimenRegistry** — loads `data/specimens.json`, does the seeded rarity roll (+ pity) →
  picks an eligible catalog entry → mints an instance (`egg_hatched` + `specimen_instances`
  row), caching requested flavor strings into `state_json` so they're stable forever.
- **UnlockRules** — evaluates `data/unlock_rules.json` predicates against the projection after
  every event; grants **at most once** (guarded by `granted_rules` → `rule_granted`). v1
  predicate types only: `streak_at_least`, `total_completed_at_least`, `total_hatched_at_least`,
  `completed_between_hours`, `combo_same_day`. No full DSL in v1.
- **FlavorProvider** — interface; `StaticFlavorProvider` (curated pools in `data/flavor/`) is the
  only v1 impl and must be safe offline. `LlamaFlavorProvider` is v2, opt-in, behind a build flag.

## Conventions

- C++17. English identifiers and comments. Small services, one responsibility each.
- One constant module `AppId.h` for every name/app-id/service string, so a rename is one place.
- No logic in QML beyond presentation. No network calls anywhere in the app.
- Write the test alongside the service; the desktop test loop (see `zoo-build`) is the contract.
