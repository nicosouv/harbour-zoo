---
name: zoo-silica
description: Silica/QML UI conventions for harbour-zoo — page structure, the Curator's tone in UI copy, CoverPage, gentle (never-shaming) presentation of streak and economy, and how QML talks to the engine. Use when writing or reviewing any QML under qml/.
---

# Zoo UI (Sailfish Silica)

QML is **presentation only**. It reads state and calls actions on `ZooController`; it never
touches SQLite, never runs business logic, never calls the clock or RNG. If a QML file needs a
decision made, that decision belongs in the engine (see `zoo-engine`).

**Follow `docs/ui-ux-system.md` — it's the design system of record.** The essentials it mandates:

- **Utility in the body, delight in the frame.** The useful trackers (habits/focus/challenge) own
  the central, uncluttered content; the zoo, goofy stats, and gamification live in the frame
  (header pill, cover, pull-down, dedicated pages) — glanceable, never crowding the tracking.
  Home-screen budget ≈ 60% tracking · 25% reward · 15% status. The home page is a tracker first.
- **One component kit.** Build every screen from the shared `qml/components/` kit (SectionHeader,
  UtilityCard, HabitRow, ProgressRing/Blob, CurrencyPill, StatChip, BlobThumb, KeeperBadge). Never
  inline a one-off layout — if it's missing, add it to the kit.
- **Palette split.** Chrome & body text follow `Theme.*` (ambience — native & legible). The brand
  palette from the icon (ink `#282C3D`, cream `#F6EFDD`, field `#F2C85C`→`#E1A42C`, teal `#2A9D8F`)
  carries personality on specimen/zoo surfaces and playful accents only — not on body text.
- **One shape, one rhythm, one motion.** Single corner-radius token (~`Theme.paddingMedium`);
  spacing only from `Theme.paddingSmall/Medium/Large`; **all** motion is springy
  (`SpringAnimation`/`Behavior`), never linear — this is what makes the whole app feel of a piece.
- **Goofy stats, warmly framed** ("7 days, and the garden noticed"), one number per StatChip with a
  spring count-up; they live on KeeperPage with a rotating teaser elsewhere — never a wall of
  numbers on a tracking screen, never a red/shaming figure.
- **The test:** could I do the useful thing in two seconds, and did it make me smile?

## Design rule #1: protect the feeling

Every screen defends **gentle delight** (creative-direction §1). Practically, in the UI:
- No red counts, no "streak broken!" banners, no anxiety countdowns. A wobble reads like an
  encouraging shrug (use the canon copy in `zoo-voice`).
- The streak indicator is soft and celebratory, not a debt tracker. Grace is shown as warmth
  ("the cabinet kept your seat"), not as a life bar draining.
- The one action we ask for (today's challenge) is front and centre and frictionless; everything
  else is optional and quiet.

## Pages (spec §6)

- **`harbour-zoo.qml`** — `ApplicationWindow`, initial page `TodayPage`, cover `CoverPage`.
- **TodayPage** — home. Today's challenge card (Curator flavor text), gentle streak indicator,
  Crumbs pill, `Complete` / `Skip` actions, and **Feed the cabinet** (enabled only when
  affordable). `PullDownMenu` → Zoo, Settings, About.
- **ZooPage** — the **zoo map / enclosure browser** (see `docs/zoo-meta.md`). Not a flat grid: a
  list of living **enclosures**. Inviting empty state (canon copy). Tap an enclosure → EnclosurePage.
- **EnclosurePage** — an animated **diorama** where residents roam and interact together
  (specimens in `lodLevel 1` ambient mode). Place/remove residents, buy decorations, see happiness.
  Tap a resident → `SpecimenPage`. Budget hard for 60fps with many residents (see `zoo-specimen`).
- **SpecimenPage** — full-screen interactive specimen host + its name, one-line lore, rarity.
  Interactions persist via the specimen's `stateChanged` signal → controller → engine.
- **SettingsPage** — gentle daily reminder toggle (`Nemo.Notifications`, **off by default**);
  reset-with-confirm (`RemorseAction`/`RemorsePopup`); in v2, ML-flavor toggle (shown only if a
  model is present).
- **KeeperPage** — the gamification/status dashboard: Keeper level & title, Zoo Rating (★, only
  ever rises/holds — never shame), prestige stats, and commendation badges. The "flex" screen.
- **ShopPage** — spend Crumbs & Renown on enclosures, capacity, decorations, habitat tiers.
  Upgrades read as aspiration, never FOMO.
- **HabitsPage / FocusPage** — the utility spine (`docs/utility-spine.md`): quick habit check-ins
  (the several-times-a-day surface) and a calm focus timer. Gentle throughout — a lapsed habit is
  "resting," never a red failure.
- **CoverPage** — Keeper level + today's status + a peek of the liveliest enclosure animating
  (a live mini-diorama if cheap; else a still). Cover actions stay minimal.

## Talking to the engine

- `ZooController` is registered as a context property or QML type; QML binds to its Q_PROPERTYs
  and calls Q_INVOKABLEs (`completeChallenge()`, `skipChallenge()`, `feedCabinet()`, etc.).
- Specimens receive a reproducible `seed`, `instanceId`, and parsed `state`; they emit
  `stateChanged(var newState)` and the **host** persists it. QML never writes storage.
- Prefer declarative bindings over imperative `on*` handlers that duplicate engine state.

## Silica hygiene

- `Theme.*` for all sizes/colors/fonts — respect the system ambience, light and dark.
- Touch targets ≥ `Theme.itemSizeSmall`; padding via `Theme.paddingMedium`/`Large`.
- Destructive/irreversible actions use `RemorseAction` (spec calls for reset-with-confirm).
- `qsTr()` every user-visible string (translations are wired via `CONFIG += sailfishapp_i18n`).
- Long lists/grids: real delegates + `SilicaGridView`/`SilicaListView`, lazy-load specimen
  thumbnails so scrolling the Zoo stays smooth on constrained devices.

## Copy in the UI

All user-visible strings are in **the Curator's voice** — see `zoo-voice`. Reuse the canon lines
for empty states, wobble, reset, and hatch reveals rather than inventing new ones ad hoc, so the
personality stays consistent.
