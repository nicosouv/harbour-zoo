# Zoo — UI/UX Design System

> Goal (owner): a **harmonised, beautiful** interface that still shows **enough information and
> goofy stats**, and — above all — **leaves prime room for the useful things you track.** This doc
> is the single source of truth for look, layout, and information architecture. The `zoo-silica`
> skill enforces it.

## The governing principle: utility in the body, delight in the frame

Every screen splits into two zones with different jobs:

- **The body (center, scrollable): utility.** Habits due, focus, today's challenge. This is prime
  real estate and it is never crowded out by cute things. If a decoration competes with a tracker
  for attention, the decoration loses.
- **The frame (header, cover, pull-down, dedicated pages): delight + status.** Crumbs/XP pill, a
  blob peeking, goofy stats, the zoo, the Keeper dashboard. Always glanceable, one gesture away,
  never in the way.

Rough home-screen attention budget: **~60% useful tracking · ~25% reward/delight surfacing ·
~15% goofy status.** Beauty comes from restraint and rhythm, not from filling space.

## Visual language

Harmonised = everything shares one palette, one shape language, one spacing scale, one motion feel.

**Palette — reconcile brand with Silica ambience.**
- **Chrome & text follow `Theme.*`** (ambience-driven) so the app feels native and stays legible
  in light/dark: `Theme.primaryColor`, `secondaryColor`, `highlightColor`, `Theme.*Background`.
- **The brand palette (from the app icon) carries the personality**, used on *specimen/zoo
  surfaces and playful accents*, not on body text: ink `#282C3D`, cream `#F6EFDD`, pupil `#1A1C26`,
  warm field `#F2C85C`→`#E1A42C`, accent teal `#2A9D8F`. So: native and legible in the frame,
  warm and characterful where the creatures live.

**Shape:** soft, rounded, Bauhaus-minimal — echo the blob. One corner-radius token
(~`Theme.paddingMedium`) for all cards/pills. No hard rectangles, no heavy borders; use gentle
fills and the grounding-shadow motif from the icon for depth.

**Type:** Silica type ramp only (`Theme.fontSizeHuge…Tiny`). Big warm numbers for stats, small
quiet labels. Never more than 2 sizes competing in one card.

**Spacing & rhythm:** one scale — `Theme.paddingSmall / Medium / Large`. Consistent vertical
rhythm between sections is 80% of what makes it "look designed." Generous breathing room.

**Motion:** **one easing feel across the whole app — springy, like the blobs.** All appear/press/
value-change animations use `SpringAnimation`/`Behavior`, never linear tweens. Numbers count up,
cards settle, pills bounce a little. This single choice is what makes the app feel *alive and of a
piece* rather than a form.

## The component kit (build everything from these)

Harmonisation is mechanical: every screen is assembled from one small shared kit in
`qml/components/`. No bespoke one-off layouts.

- **SectionHeader** — a titled divider ("Today", "Habits", "Your Zoo") in the Curator's voice.
- **UtilityCard** — the base card for a tracker (challenge / focus). Soft fill, rounded, one action.
- **HabitRow** — a single habit: icon, name, a **ProgressRing** (for ×N/day), a satisfying tap-to-
  check-in with spring feedback. The workhorse of the useful body.
- **ProgressRing / ProgressBlob** — gentle progress; a blob that fills up is on-brand.
- **CurrencyPill** — Crumbs 🟡 / Renown ⭐ with count-up animation; lives in the header, small.
- **StatChip** — one goofy stat, playfully labelled (see below). Used in grids on KeeperPage and as
  teasers elsewhere.
- **BlobThumb** — a live mini-specimen (LOD 2) for grids/cover; the reward made visible.
- **KeeperBadge** — level/title + rating stars.

If a new screen needs something not in the kit, add it *to the kit* — never inline a variant.

## Information architecture (page map)

```
CoverPage ......... Keeper level · today's status · a live peek of the liveliest enclosure
│
TodayPage (HOME) .. UTILITY-FIRST. header: CurrencyPill + Keeper chip
│   ├─ Today's challenge (compact UtilityCard)
│   ├─ Habits due today (HabitRow list) ........ the prime, largest zone
│   └─ Focus quick-start (UtilityCard)
│   pull-down menu ↓
├─ HabitsPage ..... manage/add habits (the coach can suggest here)
├─ ZooPage ........ enclosure browser → EnclosurePage (the living diorama)
├─ KeeperPage ..... goofy stats grid + badges + rating (the "flex")
├─ ShopPage ....... spend Crumbs/Renown on zoo upgrades
└─ SettingsPage ... reminder (off by default), coach toggle, reset-with-confirm
```

**The home page is a tracker first, a game second.** The zoo/stats/shop are all one pull-down
away — present, tempting, but never sitting on top of the useful stuff.

## Home screen layout (the balance, sketched)

```
┌───────────────────────────────────────────┐
│  Zoo            🟡 128   ⭐ 4   ◐ Keeper 5  │  ← frame: status, small
├───────────────────────────────────────────┤
│  Today                                      │  ← SectionHeader
│  ┌───────────────────────────────────────┐ │
│  │ "Introduce yourself to a cloud.       │ │  ← challenge (compact)
│  │  Keep it professional."   [Done][Skip]│ │
│  └───────────────────────────────────────┘ │
│                                             │
│  Habits                                     │  ← the PRIME zone, most space
│   💧 Water        ●●●○○○   (tap to log)     │
│   📖 Read         ○         (tap to log)    │
│   🏋 Move         ✓ done                     │
│                                             │
│  Focus                                      │
│  ┌───────────────────────────────────────┐ │
│  │  ▷ Start a focus session               │ │
│  └───────────────────────────────────────┘ │
│                                             │
│   …a blob peeks up from the bottom edge 👀  │  ← delight, subtle, in the frame
└───────────────────────────────────────────┘
        (pull down → Zoo · Keeper · Shop · Settings)
```

## Goofy stats — informative *and* fun, without clutter

Stats are real information dressed in the Keeper's voice. They live mainly on **KeeperPage** as a
grid of **StatChips**, with a rotating one or two teased on the cover/home — never a wall of
numbers on the tracking screens.

- Frame every stat warmly: not "Sessions: 12" but **"12 focus sessions survived."** Not "Streak:
  7" but **"7 days, and the garden noticed."**
- Mix useful and absurd: *days as Keeper · longest focus · habits kept this week · mythics
  witnessed · blobs currently thrilled · weirdest challenge done · total pokes delivered.*
- One number per chip, big and warm; a tiny label under it; a spring count-up on change.
- Ratings and streaks only ever celebrate — **never a red number, never a "you're behind."**

## Beauty rules (do / don't)

**Do:** lots of negative space; one accent per screen; consistent radius/spacing/motion; live
blobs over static icons where cheap; respect ambience; let the useful content breathe.

**Don't:** stack three font sizes in a card; put stats on the habit list; use hard borders or
drop-shadows that fight the flat style; animate with linear tweens; gate the useful trackers
behind the game; ever shame with colour (no red debt, no angry badges).

## The one-line test for any new screen

*"Could I do the useful thing in two seconds, and did the app make me smile while I did it?"* If a
design buries the tracker or adds cuteness that slows the useful action, it fails.
