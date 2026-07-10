# Zoo — Build Specification (for Claude Code)

> Working title: **Zoo** (app id `harbour-zoo`). The name may change (see Naming note);
> keep the RPM name, app id, and D-Bus/service names behind a single constant so it can be
> renamed in one place. All code comments and identifiers in **English**.

A cabinet-of-curiosities habit/challenge companion for Sailfish OS. Offline-first.
A tiny daily loop (accept a goofy micro-challenge, optionally track habits) mints
**specimens** — small self-contained interactive QML programs — into a growing collection
(the *Zoo*). The reward *is* the app: procedurally generated and hand-authored oddities you
want to collect and poke at.

---

## 1. Design pillars (non-negotiable)

1. **Delight, not dread.** No streak-shaming, no guilt notifications, no artificial timers or
   scarcity pressure. Broken streaks decay gently and recover; copy stays warm and playful.
2. **The unlockables are the point.** Specimens are real little programs (animation, behavior,
   generative art), never static PNG badges.
3. **Offline-first, local-only.** No network required for any core feature. No telemetry.
4. **Deterministic core, optional flavor.** All *structure* (challenge selection, specimen
   generation, rarity rolls, unlock conditions) is seeded and reproducible. A local LLM is used
   only for open-ended *flavor text*, and is entirely optional with a static fallback.
5. **Testable engine.** Domain logic lives in C++, decoupled from QML, unit-tested on desktop.
   QML is presentation only.

---

## 2. Scope & phasing

Ship **v1** first. Do not build v2/v3 systems until v1 meets its Definition of Done (§9).

**v1 — the loop + the cabinet (no ML dependency)**
- One daily challenge, drawn from a seeded static pool.
- Soft currency ("Seeds") earned on completion, with a gentle streak.
- "Hatch an egg": spend Seeds → seeded rarity roll → mint a specimen instance.
- Collection view (the Zoo) + full-screen specimen view with persisted interaction state.
- 4 hand-authored specimens + 1 procedural generator.
- `StaticFlavorProvider` (curated pools) — architected so ML slots in later.
- Local SQLite persistence via an append-only event log.
- Harbour-clean (no forbidden deps) so v1 *could* go to the Jolla Store.

**v2 — habits + ML flavor + secrets**
- Habit tracking as an additional Seeds source.
- `LlamaFlavorProvider` reusing Sailcat's llama.cpp backend + GBNF grammars (opt-in, model must
  be present). Distributed via OpenRepos/Chum (llama.cpp is not Harbour-allowed).
- Secret / combo unlock rules (streak milestones, odd-hour completions, same-day combos).
- Expanded specimen roster.

**v3 — projects + sharing**
- "Projects I have in mind" mode as a third currency source.
- Richer specimen behaviors; optional export/share of a specimen snapshot.

---

## 3. Architecture & module layout

```
harbour-zoo/
├── harbour-zoo.pro                  # qmake project (SFOS uses qmake + sailfishapp)
├── rpm/harbour-zoo.spec
├── src/                             # C++ engine — no QML dependency, desktop-testable
│   ├── main.cpp
│   └── engine/
│       ├── AppId.h                  # single place for name/app-id/service constants
│       ├── EventStore.{h,cpp}       # append-only event log over SQLite
│       ├── StateProjection.{h,cpp}  # derives current state from the event stream
│       ├── Economy.{h,cpp}          # currency balances & costs
│       ├── ChallengeService.{h,cpp} # seeded daily-challenge selection
│       ├── SpecimenRegistry.{h,cpp} # catalog load + instance minting
│       ├── UnlockRules.{h,cpp}      # data-driven rule evaluation over projection
│       ├── FlavorProvider.{h,cpp}   # interface + StaticFlavorProvider (Llama impl in v2)
│       ├── Rng.{h,cpp}              # seedable PRNG (splitmix64/PCG32)
│       └── ZooController.{h,cpp}    # QObject facade exposed to QML (thin)
├── qml/
│   ├── harbour-zoo.qml              # ApplicationWindow
│   ├── cover/CoverPage.qml
│   ├── pages/
│   │   ├── TodayPage.qml            # daily challenge + streak + hatch action
│   │   ├── ZooPage.qml             # collection grid
│   │   ├── SpecimenPage.qml        # full-screen specimen host
│   │   ├── SettingsPage.qml
│   │   └── AboutPage.qml
│   ├── specimens/                   # each specimen = one self-contained Component
│   │   ├── Specimen.qml             # base interface (properties + signals)
│   │   ├── BlobSpecimen.qml         # procedural
│   │   ├── UselessMachine.qml       # authored
│   │   ├── PetRock.qml              # authored, persists mood
│   │   └── BauhausGarden.qml        # authored, grows with logged days
│   └── components/                  # shared Silica bits (cards, currency pill, etc.)
├── data/
│   ├── challenges.json              # static challenge pool
│   ├── specimens.json               # authored specimen manifests
│   ├── flavor/                      # curated flavor pools (names, proverbs, lore)
│   └── grammars/                    # GBNF grammars (used by Llama provider in v2)
├── tests/                           # QtTest unit tests, run on desktop
├── translations/
└── icons/
```

**Layering rule:** QML → `ZooController` (thin QObject facade) → engine services → `EventStore`.
QML never touches SQLite directly. The engine never imports Qt Quick.

---

## 4. Data model — event-sourced

Rationale: an append-only event log makes secret/combo unlock conditions trivial (they are just
queries over the stream), makes the whole engine reproducible and testable, and gives a clean
audit of everything the app has ever done. Current state is a **projection** of the log.

### 4.1 Tables (SQLite)

```sql
-- The single source of truth. Never UPDATE or DELETE rows here.
CREATE TABLE events (
    seq         INTEGER PRIMARY KEY AUTOINCREMENT,
    type        TEXT    NOT NULL,       -- see event types below
    ts_utc      TEXT    NOT NULL,       -- ISO-8601 UTC
    local_date  TEXT    NOT NULL,       -- YYYY-MM-DD in device local time (streak logic)
    local_hour  INTEGER NOT NULL,       -- 0..23 local (odd-hour secrets)
    payload     TEXT    NOT NULL        -- JSON, event-specific
);

-- Optional projection snapshot to avoid replaying the whole log on every launch.
-- Safe to drop and rebuild from `events` at any time.
CREATE TABLE projection_snapshot (
    id          INTEGER PRIMARY KEY CHECK (id = 1),
    as_of_seq   INTEGER NOT NULL,
    state_json  TEXT    NOT NULL
);

-- Minted specimen instances (denormalized for the collection grid; also reconstructible).
CREATE TABLE specimen_instances (
    instance_id TEXT PRIMARY KEY,       -- uuid
    catalog_id  TEXT NOT NULL,
    seed        INTEGER NOT NULL,       -- drives all procedural params (reproducible)
    rarity      TEXT NOT NULL,
    minted_seq  INTEGER NOT NULL,       -- event seq that minted it
    state_json  TEXT NOT NULL DEFAULT '{}' -- persisted interaction state (mood, growth…)
);

-- One row; the install salt seeds all deterministic RNG for this device.
CREATE TABLE install_meta (
    id          INTEGER PRIMARY KEY CHECK (id = 1),
    install_salt INTEGER NOT NULL,
    schema_ver  INTEGER NOT NULL
);
```

### 4.2 Event types (payload shape in comments)

- `app_opened`            — {}
- `challenge_issued`      — { challenge_id, date, text }
- `challenge_completed`   — { challenge_id, date }
- `challenge_skipped`     — { challenge_id, date }        (no penalty; just recorded)
- `currency_earned`       — { currency: "seeds", amount, reason }
- `currency_spent`        — { currency: "seeds", amount, reason }
- `egg_hatched`           — { instance_id, catalog_id, rarity, seed }
- `specimen_interacted`   — { instance_id, kind, delta }  (drives growth/mood, secrets)
- `rule_granted`          — { rule_id, grant }            (idempotency guard for unlock rules)
- `habit_logged`          — { habit_id, date }            (v2)

### 4.3 Projected state (derived, never authoritative)

```
wallet: { seeds: int }
streak: { current: int, longest: int, last_active_local_date: str, grace_remaining: int }
today:  { date, challenge_id, text, status: issued|completed|skipped }
owned:  [ instance_id... ]              -- count + ids; details from specimen_instances
counters: { total_completed, total_hatched, ... }  -- cheap denormals for unlock predicates
granted_rules: set<rule_id>            -- so a secret is granted at most once
```

**Streak logic (gentle):** streak increments on the first `challenge_completed` of a new
`local_date`. A missed day consumes one `grace_remaining` token instead of breaking the streak;
grace replenishes at +1 per N completed days (N configurable, e.g. 5), capped (e.g. 2). Only when
grace is exhausted does the streak reset to 0 — with encouraging copy, never shaming.

---

## 5. Core systems

### 5.1 RNG (deterministic)
`Rng` wraps splitmix64 (seed) → PCG32-quality stream. All randomness in the engine goes through
it. Seeds are derived, never `time()`:
- daily challenge:  `seed = mix(install_salt, ordinal(local_date))`
- hatch rarity roll: `seed = mix(install_salt, total_hatched_counter)`
- specimen params:   the instance `seed` stored at mint time
This guarantees the same specimen always looks/behaves the same, and lets tests assert exact
outputs.

### 5.2 Economy
Single soft currency **Seeds** (rename freely — one constant). Earn on `challenge_completed`
(base reward, small gentle streak bonus). Spend on `egg_hatched`. All balance changes go through
events; `Economy` reads the projection and rejects spends it can't afford. No hard currency, no
IAP, ever.

### 5.3 ChallengeService
Loads `challenges.json` (pool of templated micro-challenges — some deliberately WTF, e.g.
"photograph three triangular things", "compliment an inanimate object", "walk somewhere you've
never walked"). Selects the day's challenge deterministically from the date seed, avoiding
recent repeats (track last K issued in projection). In v2, if a model-backed FlavorProvider is
enabled, some challenges are freshly generated instead of drawn from the pool.

### 5.4 SpecimenRegistry & minting
`specimens.json` declares **catalog entries**:
```json
{
  "id": "blob",
  "kind": "procedural",           // procedural | authored
  "qml": "BlobSpecimen.qml",
  "rarities": ["common","uncommon","rare"],   // which rolls can produce it
  "flavor": ["name","proverb"]    // flavor kinds this specimen requests
}
```
Hatching: roll rarity (weighted, seeded) → pick an eligible catalog entry → generate an instance
`seed` → request any flavor strings (cached into `state_json` at mint so they're stable) → write
`egg_hatched` + insert `specimen_instances` row. Authored specimens may also be **granted
directly** by unlock rules (not purchasable).

**Specimen QML contract** (`Specimen.qml` base):
```qml
// Base interface every specimen implements. The host passes a reproducible seed and any
// persisted state; the specimen renders/behaves purely from these. State changes are emitted
// back to the host, which persists them via the engine (never write storage from QML).
Item {
    property int    seed: 0
    property string instanceId: ""
    property var    state: ({})           // parsed from state_json
    signal stateChanged(var newState)     // host persists on emit
}
```

### 5.5 UnlockRules (data-driven)
Rules in JSON, evaluated against the projection after every event. Each rule grants a specimen
or currency **at most once** (guarded by `granted_rules`). v1 ships a couple; adding a secret is
a JSON entry, not code. Use typed predicates (no full DSL in v1):
```json
{
  "id": "night_owl",
  "predicate": { "type": "completed_between_hours", "from": 2, "to": 4 },
  "grant": { "specimen": "pet_rock" }
}
```
v1 predicate types: `streak_at_least`, `total_completed_at_least`, `total_hatched_at_least`,
`completed_between_hours`, `combo_same_day` (two named challenge tags on one local_date).

### 5.6 FlavorProvider (ML is optional flavor, not the spine)
```cpp
// Produces open-ended flavor text (specimen names, one-line lore, goofy proverbs, WTF daily
// challenges). MUST be safe to call offline. Results are cached by the caller at mint time so a
// given specimen's flavor is stable forever.
class FlavorProvider {
public:
    virtual ~FlavorProvider() = default;
    virtual QString generate(FlavorKind kind, quint64 seed) = 0;
    virtual bool    isModelBacked() const = 0;
};
```
- **v1 `StaticFlavorProvider`** (default, zero deps): deterministic pick from curated pools in
  `data/flavor/`. Ships as the only provider in v1.
- **v2 `LlamaFlavorProvider`** (opt-in): reuses Sailcat's llama.cpp `ChatBackend` + a **GBNF
  grammar** per `FlavorKind` (grammars in `data/grammars/`) so a small model (e.g. Qwen2.5-1.5B)
  emits well-formed goofy output instead of rambling. Enabled only if a model file is present and
  the user opts in. A small model "getting it weird" is a *feature* here.

---

## 6. UI (Sailfish Silica)

- **CoverPage** — streak state, today's status, and the "specimen of the day" thumbnail.
- **TodayPage** — the home page. Today's challenge card (flavor text), gentle streak indicator,
  Seeds pill, `Complete` / `Skip` actions, and `Hatch an egg` (enabled when affordable). Pull-down
  menu → Zoo, Settings, About.
- **ZooPage** — responsive grid of owned specimens (live thumbnails preferred over static).
  Inviting empty state. Tap → SpecimenPage.
- **SpecimenPage** — full-screen interactive specimen, its name + one-line lore + rarity.
  Interactions persist via `stateChanged`.
- **SettingsPage** — toggle gentle daily reminder (Nemo.Notifications, **off by default**);
  in v2, toggle ML flavor (only shown if a model is present); reset-with-confirm.

**Copy guidelines:** warm, playful, a little absurd. Never shame. A broken streak reads like an
encouraging shrug, not a failure state. No countdowns designed to create anxiety.

---

## 7. Tech stack & packaging

- **Platform:** Sailfish OS SDK (`sfdk`), qmake + `sailfishapp`, Qt 5 / QtQuick 2 + `Sailfish.Silica`.
  Mind the older Qt baseline; avoid APIs newer than the SFOS Qt version.
- **Language:** C++17 for the engine, QML/JS for UI.
- **Persistence:** SQLite via `QtSql` in C++ (not QML `LocalStorage`).
- **No background service** is required (pull-open app) — this deliberately avoids Sailfish's
  hardest area. The optional reminder is a scheduled notification, not a running daemon.
- **Distribution:**
  - v1 (StaticFlavorProvider only) is Harbour-clean → can target the Jolla Store *and* OpenRepos/Chum.
  - v2 with `LlamaFlavorProvider` links llama.cpp → **not** Harbour-allowed → OpenRepos/Chum only.
  Keep the ML provider behind a build flag (e.g. `CONFIG+=with_llama`) so the Harbour build stays clean.

---

## 8. Coding conventions

- All comments and identifiers in **English**.
- Engine is **UI-agnostic and unit-tested** (`tests/` with QtTest, runnable on desktop with no
  device). Aim for full coverage of: EventStore round-trip, StateProjection (esp. streak+grace),
  Economy (earn/spend/reject), ChallengeService determinism, Rng reproducibility, UnlockRules
  (grant-once semantics), SpecimenRegistry minting.
- Keep it maintainable, clear, concise: small services with single responsibilities, no logic in
  QML beyond presentation, one constant module (`AppId.h`) for all name/id strings.
- Deterministic by construction: nothing in the engine calls wall-clock time or system RNG except
  one clock abstraction and one salt generator, both injectable for tests.

---

## 9. v1 Definition of Done

1. Fresh install seeds `install_meta`, opens TodayPage with a deterministic first challenge.
2. Completing the challenge emits events, awards Seeds, advances the streak; state survives restart.
3. Missing a day consumes grace before breaking; copy is gentle; behavior matches unit tests.
4. Hatching spends Seeds, rolls rarity deterministically, mints a specimen visible in the Zoo.
5. At least 4 authored + 1 procedural specimen render and persist interaction state.
6. Two unlock rules fire correctly and grant exactly once.
7. StaticFlavorProvider supplies names/lore/proverbs deterministically; no network calls anywhere.
8. Dropping `projection_snapshot` and replaying `events` reproduces identical state.
9. Engine unit tests pass on desktop; app builds and runs on a Sailfish target/emulator.
10. Harbour-clean build (no forbidden dependencies).

---

## 10. First tasks for Claude Code (ordered)

1. Scaffold `harbour-zoo` (qmake + sailfishapp + rpm spec), `AppId.h`, empty ApplicationWindow.
2. `EventStore` + schema (§4.1) + install-salt bootstrap; QtTest round-trip test.
3. `StateProjection` incl. streak+grace; tests covering streak edge cases.
4. `Economy` (earn/spend/reject) over events; tests.
5. `Rng` (splitmix64→PCG32); reproducibility test.
6. `ChallengeService` + `challenges.json`; deterministic-selection + no-recent-repeat tests.
7. `SpecimenRegistry` + `specimens.json` + minting (`egg_hatched`); minting test.
8. `UnlockRules` + 2 rules with grant-once; tests.
9. `ZooController` facade; expose the above to QML.
10. QML shell: TodayPage → ZooPage → SpecimenPage; wire complete/skip/hatch.
11. `Specimen.qml` base + BlobSpecimen (procedural) + 3 authored specimens; persist `state`.
12. `StaticFlavorProvider` + `data/flavor/`; wire names/lore/proverbs, cache at mint.
13. CoverPage, SettingsPage (reminder toggle off by default), AboutPage; polish + empty states.

---

## 11. Open decisions for the owner (Nico)

- Final name / app id (Zoo vs Vivarium/Bestiaire/Cabinet — see Naming note).
- Currency name (Seeds? Bits? Grains?) and exact reward/cost numbers.
- Rarity tiers and weights; which specimen kinds are gated to which tiers.
- Initial specimen roster (which 4 authored + which procedural generator ships first).
- Whether v1 includes a minimal habit source or defers all habits to v2.
- Minimum SFOS version to target; Harbour + OpenRepos, or OpenRepos/Chum only from the start.
```
