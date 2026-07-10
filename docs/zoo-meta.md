# Zoo — The Living Zoo & Keeper Progression (the long game)

> Owner direction: **it's a zoo** — creatures live in **enclosures**, animated together, roaming;
> the player has **gamification stats/status**; and **as you use the app you buy upgrades for your
> zoo.** This is the meta-layer that turns "collect specimens" into "run a zoo you're proud of,"
> and it's the real answer to *why come back for weeks, not days.*

The metaphor shifts from *cabinet of curiosities* → **a small, strange, living zoo** and **you are
its Keeper.** Same gentle soul (never shaming), bigger horizon.

## 1. Enclosures — the zoo is alive, not a grid

The old flat grid becomes a set of **living enclosures**. An enclosure is a small animated
diorama where several specimens of a kind **coexist, roam, and interact** — a blob enclosure with
a dozen blobs bumping and blinking; a garden biome that grows; a kinetics hall of swinging things.

- **Model:** `enclosure { id, biome, capacity, decorations[], residents[instance_id], happiness }`.
- **Residents** are the specimen instances you've hatched, *placed* into a compatible enclosure.
  In the enclosure they run in a lightweight "ambient mode" (LOD): reduced particle counts, shared
  ticker, simple wander/flock so N of them stay at 60fps (see `specimen-taxonomy.md` perf budget).
- **Interactions between residents** are cheap and delightful: blobs nuzzle, orbitals sync, pets
  form little cliques. Emergent, seeded, never scripted-per-pair.
- **Tap a resident** → zoom to its full-screen `SpecimenPage` (the rich single-specimen experience).
- **Biomes** match archetypes: Ooze Pen (blobs), Orrery (orbitals), Glasshouse (gardens),
  Contraption Shed (machines), Tide Pool (fluids), Aviary (swarms), etc. A creature is happiest in
  its biome; mixing is allowed but "happiness" is highest at home.

## 2. Happiness (gentle, never a fail-state)

Each enclosure has a soft **happiness** that rises with space, matching biome, decorations, and
*your* activity (an active Keeper = a lively zoo). Happiness only ever **adds** delight:

- High happiness → more animated ambient behaviour, occasional bonus Crumbs ("the blobs are
  thrilled"), prettier idle.
- Low happiness is **never** shown as suffering or guilt. A crowded pen reads "cozy, could be
  roomier," nudging you toward an upgrade — an *aspiration*, not a punishment. Creatures never get
  sad, sick, or die. This is a no-cruelty zoo, by design pillar.

## 3. Zoo upgrades — the currency sink & long-term goal

The reason XP and Crumbs matter over weeks. You spend to **build out your zoo**:

- **New enclosures / biomes** — unlock an Orrery, an Aviary… (also gates which archetypes you can
  comfortably house).
- **Capacity expansions** — bigger pens hold more residents happily.
- **Decorations** — cosmetic props that raise happiness and personalise a biome (a tiny fountain,
  weird signage, mood lighting). Pure joy + light stat boost.
- **Habitat tiers** — upgrade an enclosure's fidelity (better ambient behaviours, richer shaders
  unlocked at higher tiers).
- **Zoo-wide upgrades** — a nicer entrance, paths, a gift shop that passively trickles Crumbs, an
  info kiosk that shows a visiting creature of the day.

**Two earned currencies (proposed), never purchasable — no IAP, ever (spec pillar):**
- **Crumbs** — fast, from every check-in/challenge/focus. Hatching + small decorations.
- **Renown** (⭐) — slow, from milestones, Keeper level-ups, streak anniversaries, rare hatches.
  Gates the big structural upgrades (new biomes, tiers). Renown is *prestige you earned by living
  well*, so the marquee upgrades feel like genuine achievements, not grind.

> Single-currency is also viable (spec §5.2 says one soft currency). Renown is a recommended
> addition for pacing the long game; it stays behind the same `Economy` service and event log.

## 4. Keeper progression — the gamification status the player wears

The player is **the Keeper**, with visible, *celebratory* status. A stats/identity screen:

- **Keeper Level** (from XP): each level-up is a small ceremony + Renown + sometimes a new
  enclosure slot or decoration. Titles per band: *Volunteer → Junior Keeper → Keeper → Head
  Keeper → Curator → Director → Legendary Director.*
- **Zoo Rating** (★–★★★★★): a warm aggregate of variety, happiness, and care. It **only rises or
  holds** — it never drops to shame you for a quiet week. It's a trophy, not a leash.
- **Prestige stats** (the "status" dashboard): creatures collected / of each rarity, species
  discovered (X / 310), biomes unlocked, longest & current streaks, lifetime focus hours, habits
  kept, rarest resident, days as Keeper, mythics seen.
- **Badges / commendations** — earned for milestones (first mythic, 30-day streak, a full biome,
  100 focus hours). Framed as commendations from the (fictional) Zoological Society — warm flavor,
  never a checklist of obligations.

All of this is **derived from the event log** (spec §4) — Keeper level, rating, stats, badges are
projections, reproducible by replay. Adding a badge is a data-driven rule (like `UnlockRules`).

## 5. New surfaces (UI)

- **ZooPage** becomes the **zoo map / enclosure browser**: pick an enclosure → watch its living
  diorama. Empty state is warm ("your zoo is a field of potential and one very optimistic sign").
- **EnclosurePage** — the animated diorama; place/remove residents, buy decorations, see happiness.
- **KeeperPage** — the status dashboard (level, rating, stats, badges). This is the "flex" screen.
- **ShopPage / Upgrades** — spend Crumbs & Renown on enclosures, capacity, decor, tiers.
- **CoverPage** — now shows Keeper level + a peek of the liveliest enclosure animating.

## 6. How this defends the core question ("why keep coming back?")

- **Short term (today):** habits/focus/challenge give a reason to open several times a day.
- **Medium term (this week):** Crumbs accumulate → hatch → a new resident moves into an enclosure
  you watch come alive.
- **Long term (weeks/months):** Renown + XP build toward the *next enclosure*, the *next Keeper
  title*, a *fuller Zoo Rating*, and the hunt for 310 species. There's always a visible next thing
  — and every bit of it was bought by actually living your days well.

## 7. Events added for the meta-layer

Extends the append-only log (spec §4.2 / `utility-spine.md`):
- `enclosure_built` — { enclosure_id, biome }
- `enclosure_upgraded` — { enclosure_id, upgrade }
- `resident_placed` / `resident_removed` — { enclosure_id, instance_id }
- `decoration_bought` — { enclosure_id, decoration_id }
- `renown_earned` / `renown_spent` — { amount, reason }
- `keeper_leveled` — { level }
- `badge_granted` — { badge_id }   (grant-once, like unlock rules)

Projection derives: Keeper level, Zoo Rating, per-enclosure happiness, unlocked biomes, badge set.
Everything replayable, testable, deterministic.
