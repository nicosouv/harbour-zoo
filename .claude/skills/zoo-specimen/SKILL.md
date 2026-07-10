---
name: zoo-specimen
description: How to author a specimen (or a whole generative archetype) for harbour-zoo to the "hyper bien pensé" quality bar. Covers the base QML contract, the archetype-not-one-off strategy for reaching 300+, the 7-gate quality rubric, LOD/enclosure ambient mode, and species registration. Use when creating or reviewing anything under qml/specimens.
---

# Authoring specimens

Read `docs/specimen-taxonomy.md` first — it's the strategy. This skill is the how-to. **The bar is
non-negotiable: every specimen must be genuinely, carefully thought out.** No filler, no recolors
masquerading as content.

## Golden rule: build archetypes, not one-offs

The target is **300+ specimens at quality**, which is impossible by hand-authoring 300 files.
Instead: build **~15 hand-crafted generative _engines_ (archetypes)** — each a single, deeply
parameterised QML program — and curate **20–40 distinct _species_** per archetype from its seed
space. **Never copy-paste a QML file per creature.** Add a species = add a data entry, not a file.

A species must differ from its siblings in **at least two** of: morphology/structure, idle
behaviour, touch reaction, locomotion, or a unique trick. If the only difference is colour, it's
the *same* species at two rarities.

## The base contract (`Specimen.qml`)

Every specimen — authored or generated — implements this. The host passes a reproducible seed and
persisted state; the specimen renders/behaves **purely** from these and **never writes storage**.

```qml
// Base interface. Pure function of (seed, memory). Emits changes; host persists them.
// NOTE the persisted-state members are `memory` / `persist`, NOT `state` / `stateChanged` —
// QML's Item already defines `state` (string) and `stateChanged()`, so those names would clash.
Item {
    property int    seed: 0            // drives ALL procedural params — same seed, same creature
    property string instanceId: ""
    property var    memory: ({})       // parsed from state_json (mood, growth, battles…)
    property int    lodLevel: 0        // 0 = full-screen; 1 = enclosure ambient; 2 = grid thumbnail
    property string rarity: "common"   // flourish tier: common | uncommon | rare | mythic
    signal persist(var newMemory)      // host persists on emit (never write storage from QML)
}
```

- Derive everything from `seed` via a local seeded PRNG helper (e.g. mulberry32 seeded by `seed`)
  — **never** `Math.random()`, never `Date`/wall-clock for the *look*. Determinism is testable and
  is what makes "the same specimen forever" true. (Ephemeral animation phase/idle wander may use
  the animation clock — it isn't persisted and doesn't change the creature's identity.)
- Persist only through `persist(...)`. Keep `memory` small and JSON-serialisable.

## The 7-gate quality rubric (all must pass to ship)

1. **Alive at rest** — gentle idle motion when untouched. No static specimens, ever.
2. **Answers touch** — tap/drag/swipe → immediate, physical response (`SpringAnimation`,
   `Behavior`), never a linear `Timer` tween.
3. **Has a secret** — a threshold / Easter egg rewards attention (Blob's 50-poke burp, Fan's
   liftoff). Depth for the curious.
4. **Reads at thumbnail** — recognisable & appealing at ~120px in the grid. Silhouette first.
5. **Has personality** — a one-line "who is this." Generic = not done.
6. **Performs** — 60fps on armv7hl. Bounded particles (≤ ~300, pooled), cheap shaders, pause
   off-screen. Respect `lodLevel`.
7. **Deterministic** — pure function of `seed` + `state`; test asserts exact output for a fixed
   seed.

## LOD & enclosure ambient mode (`docs/zoo-meta.md`)

Specimens live two lives: full-screen (`lodLevel 0`) and as **residents roaming an enclosure**
alongside many peers (`lodLevel 1`), plus grid thumbnails (`lodLevel 2`). Implement all three:

- `lodLevel 1/2`: cut particle counts, slow or share the ticker, simplify shaders, and add a cheap
  wander/idle so N residents animate together at 60fps. When fully off-screen, stop the ticker.
- Enclosure inter-resident reactions (blobs nuzzle, orbitals sync) must be cheap and seeded —
  emergent, never scripted per-pair.

## Rendering technology — how specimens are drawn (NOT asset files)

Specimens are **procedurally rendered at runtime from the seed**, never pre-made PNG/SVG files
(300+ deterministic, animated, seed-varied creatures can't be assets). Choose per archetype:

1. **GPU fragment shader (`ShaderEffect`)** — the default for organic/continuous looks (blobs,
   fluids, op-art, auras). Seed → uniforms; a `time` uniform animates it; renders on the GPU at
   60fps and scales to many enclosure residents cheaply. **This is the primary blob tech.**
2. **QML `Canvas`** (JS 2D context) — good for prototyping and archetypes drawn as paths, single
   full-screen. CPU-bound — don't run many at once.
3. **Custom C++ `QQuickItem` + `QSGGeometry`** — for heavy archetypes needing many animated
   vertices/particles at LOD (swarms, big kinetics, crowded enclosures).

**Qt 5.6 constraints (SFOS baseline):** no `QtQuick.Shapes` (needs 5.10+) — use shaders/Canvas/
scene-graph geometry instead. Shaders are **GLSL ES 1.00** style (`varying`, `gl_FragColor`,
`qt_Matrix`/`qt_TexCoord0`) — no `#version 330`, no `in/out`. Verify the target's exact Qt with
the SDK; if it's newer, `Shapes` becomes an option.

## The blob look (canonical — match the app icon)

The app icon defines the house style for creatures. Every Blob should feel like family with it:

- **Silhouette:** soft, rounded, slightly organic body (an SDF metaball, not a circle). Gentle
  wobble at rest.
- **Eyes are the soul.** Big cream googly eyes with a dark pupil and a tiny highlight. They
  **blink, track the finger, and react** (go wide on poke, cross when spun, droop when idle-long).
  Most of a blob's personality/fun is in the eyes — cheap to do, huge payoff.
- **Physics:** poke → `SpringAnimation` recoil + jiggle. Never a linear tween.
- **Palette (from `icons/harbour-zoo.svg`):** body `#282C3D`, eye whites `#F6EFDD`, pupils
  `#1A1C26`, warm field `#F2C85C`→`#E1A42C`, accent teal `#2A9D8F`. Common blobs stay near this
  palette; rarer rolls unlock iridescence, extra eyes, glow (mythic = it hums/winks unprompted).
- **Fun per seed:** lopsided bodies, 1–3 eyes, tiny vs. huge, a wonky grin, an occasional
  unprompted blink or hiccup. Distinct *personalities*, not colour swaps (the "two-of" rule).

### The blob genome (why no two are identical)

The seed is read as a **genome** — a set of genes, each shifting something *structural*, so blobs
vary widely instead of being recolors. The engine maps seed → these genes deterministically:

- **Body:** lobe count (2–6 metaballs), radii, lopsidedness, size, tall/wide squash, edge
  softness (gooey↔firm), surface lumps.
- **Motion:** idle wobble amplitude/frequency, breathing rate, poke-jiggle stiffness, enclosure
  gait (hop/drift/scoot), rare hiccup/shiver.
- **Eyes:** count (1–3), size, spacing, height, pupil size, googliness (physical pupil jiggle),
  blink rate/style (slow / rapid / one-eye wink), gaze (tracks finger / wanders / cross-eyed /
  sleepy droop).
- **Face:** optional tiny grin / wobbly line / gap / none.
- **Skin:** flat matte (common) → gradient → speckled → iridescent (rare) → glow+hum (mythic).
- **Palette:** hue family (common stays near the icon navy; rarer unlock wider palettes) + accent.
- **Temperament:** folds the above into a readable personality (shy / hyper / sleepy / smug /
  nervous / zen) that drives idle behaviour and reaction style — the "who is this" one-liner.
- **Quirk:** a rare seeded trait (extra independently-blinking eye, a sneeze that puffs a
  particle, an expression that changes when you look away).

**Variation works at three levels:** (1) *across species* — curated named regions of the genome
that are far apart (e.g. "The Nervous Trio" vs "Big Sleepy"), clearly different animals; (2)
*within a species* — small seed jitter gives siblings, not clones; (3) *rarity* — the skin/quirk
tiers layer on top. A species is a named genome region that passes the two-of distinctness test;
register species in `data/specimens.json` per archetype.

## Archetype authoring template

1. **Design the engine:** enumerate the parameters that make species *structurally* different
   (not just palette). Write the single QML program that renders any point in that space.
2. **Wire the 7 gates** into the engine so *every* species inherits them.
3. **Map rarity → flourish** (creative-direction §3): common = base; uncommon = +1 behaviour;
   rare = shader/particle flourish + bonus interaction; mythic = the showpiece variant.
4. **Curate species:** pick seed-anchored configs that pass the "two-of" distinctness test; give
   each a name (from `data/flavor/names.json` or a curated per-archetype list) and register it.
5. **Register** in `data/specimens.json` (see below) with its archetype, rarities, and flavor
   kinds. `SpecimenRegistry` rolls rarity (seeded + pity) → picks eligible entry → mints instance
   → caches flavor into `state_json`.

## Species / catalog entry (data/specimens.json)

```json
{
  "id": "blob",
  "kind": "procedural",            // procedural (archetype engine) | authored (hero one-off)
  "qml": "BlobSpecimen.qml",
  "archetype": "blobs",
  "rarities": ["common","uncommon","rare","mythic"],
  "flavor": ["name","proverb"],
  "grantOnly": false               // true = never rolled, only granted by UnlockRules
}
```

## v1 scope (don't try to build 310 at once)

v1 proves the pipeline with **3 archetypes fully built** (Blobs, Fidgets, Gardens) + the authored
heroes in `data/specimens.json`. That already yields dozens of real species and satisfies DoD
§9.5. Each later archetype is a self-contained PR that can't regress the others. Quality gates the
count — never ship a species that fails the rubric to hit a number.
