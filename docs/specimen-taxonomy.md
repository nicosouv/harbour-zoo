# Zoo — Specimen Taxonomy (how we reach 300+ without lazy filler)

> Requirement (owner): **at least 300 specimens, and every animation / mini-game / oddity must be
> genuinely, carefully thought out.** This document is the strategy that makes both true at once.

## The core idea: archetypes, not one-offs

Hand-authoring 300 distinct QML programs is not achievable at quality — the tail would rot into
recolors. Instead we build **~15 hand-crafted specimen _engines_ (archetypes)**. Each archetype is
a single, deeply-designed, reusable QML program with a **rich parameter space**. A **species** is a
named, curated point in that space that is *structurally and behaviourally distinct* — not a
palette swap.

- One archetype, done with real love, yields **20–40 species**.
- 15 archetypes × ~20 species ≈ **300+**, and every one inherits a hand-crafted engine, so every
  one is "hyper bien pensé" by construction.
- The `seed` (spec §5.1) drives the parameters; a species is a seed-range + curated overrides with
  a name, so the same species always looks/behaves the same forever.

**A species must differ from its siblings in at least TWO of:** morphology/structure, idle
behaviour, reaction-to-touch, locomotion, or a unique "trick." If two candidates differ only in
colour, they are the **same** species with two rarities — not two species.

## The quality rubric (every specimen must pass all seven)

No specimen ships — authored or generated — unless it passes this. It's the gate.

1. **Alive at rest.** It does something gently interesting when untouched (idle animation, drift,
   breathing). No static specimens, ever. A specimen is a *program*, not a sticker.
2. **Answers touch.** Tapping/dragging/swiping does something satisfying and immediate (spring,
   ripple, squish, spin) with real physics/easing — never a linear tween.
3. **Has a secret.** Some rarer interaction, threshold, or Easter egg rewards attention
   (the Blob's 50-poke burp, the Fan's liftoff). Depth for the curious.
4. **Reads at thumbnail size.** Recognisable and appealing in the Zoo grid at ~120px, not just
   full-screen. Silhouette-first design.
5. **Has personality.** A one-line "who is this" you could say out loud. If it's generic, it's not
   done.
6. **Performs.** 60fps target on constrained SFOS hardware (armv7hl). Budget: no unbounded
   particle counts, cheap shaders only, pause when off-screen. See performance notes below.
7. **Deterministic.** Renders/behaves purely from `seed` + persisted `state`. Same seed → same
   creature, forever (testable).

## The 15 archetypes (North-star roster → 310 species)

Each archetype is one QML engine + a curated species list. Counts are targets; quality gates the
count, never the reverse.

| # | Archetype        | Species | What varies between species (the "two of" rule)                         |
|---|------------------|--------:|-------------------------------------------------------------------------|
| 1 | **Blobs**        | 40 | body morphology, eye count/placement, idle wobble, poke reaction, appendages |
| 2 | **Orbitals**     | 20 | number & size of bodies, orbit eccentricity, tap-to-perturb physics, trails |
| 3 | **Gardens**      | 24 | growth ruleset (L-system/geometric), shape vocabulary, how it grows w/ active days |
| 4 | **Machines**     | 24 | contraption topology (gears/levers/switches), the "useless" behaviour, sound-of-motion |
| 5 | **Fluids**       | 18 | sim type (lava/ferrofluid/sand), viscosity, how it responds to tilt/drag  |
| 6 | **Automata**     | 20 | cellular rule (life-like), seeding pattern, colour-mapping, tap-to-seed behaviour |
| 7 | **Swarms**       | 18 | agent behaviour (boids/fireflies/ants), flock size, how it reacts to your finger |
| 8 | **Fidgets**      | 24 | object (spinner/switch/slider/worry-stone), the physics "feel," the satisfying threshold |
| 9 | **Weather-jars** | 16 | scene inside, precipitation type, shake behaviour, day/night drift        |
| 10| **Chimes**       | 14 | generative scale, trigger (tap/idle), visual↔sound coupling (subtle, offline) |
| 11| **Op-art**       | 24 | pattern family (moiré/spirograph/tiling), animation, parallax-on-tilt      |
| 12| **Pets**         | 20 | character morphology, temperament, need-loop (never guilt-based), tricks   |
| 13| **Kinetics**     | 16 | mechanism (pendulum/cradle/mobile), damping, how a flick propagates        |
| 14| **Mini-games**   | 20 | the actual toy-game (one-tap, fling, catch, timing), win-feel, variants    |
| 15| **Curios**       | 12 | hero one-offs; fully authored, no shared engine (the mythic showpieces)     |

**Total ≈ 310.** Ship order and rarity mapping below.

## Rarity within an archetype (creative-direction §3)

Rarity is **not** a separate species; it's a flourish tier layered on the roll:
- **common** → the clean base form.
- **uncommon** → +1 behaviour or a richer palette.
- **rare** → a shader/particle flourish + a bonus interaction.
- **mythic** → the showpiece variant (hums, winks, redraws itself) — or a Curio.

So a single "Blob" species can mint as common→mythic; the rarity roll (seeded, with pity) decides
the flourish tier at hatch. This multiplies perceived variety on top of the 310 base species.

## v1 is a vertical slice, not all 310

The 300+ is the **content North Star**, reached over v1→v3. v1's job is to **prove the pipeline
end-to-end** so scaling is "add a species entry," not "write an engine":

- **v1 ships 3 archetypes fully built** (Blobs, Fidgets, Gardens are the best proof: procedural
  creature, physics toy, growth-tied-to-consistency) → already ~30–50 real species.
- v1 also ships the authored heroes named in `data/specimens.json` (Pet Rock, Useless Machine,
  Desk Fan, Bauhaus Garden) as the first Curios/archetype seeds.
- v2/v3 add archetypes 4–15. Each new archetype is a self-contained PR that can't regress the rest.

This keeps DoD §9.5 honest (≥4 authored + 1 procedural render & persist) while the taxonomy above
guarantees we *can* reach 300 without ever shipping filler.

## Performance budget (rubric #6, expanded)

Constrained hardware is the real constraint. Per specimen, full-screen:
- Particles: hard cap (e.g. ≤ 300), pooled, no per-frame allocation.
- Shaders: prefer `ShaderEffect` with cheap fragment math; no multi-pass unless mythic and short.
- Off-screen (in the grid): render a cheap "thumbnail mode" (lower particle count, slower tick)
  and **pause** when not visible. The engine passes a `lodLevel` hint to the specimen.
- Everything springs/eases with `Behavior`/`SpringAnimation`, never `Timer`-driven linear steps.

## Authoring workflow

See the `zoo-specimen` skill for the base QML contract, the per-archetype template, and the
species-registration format. Rule of thumb: **build the engine once, obsess over its parameter
space, then curate species — never copy-paste a new file per creature.**
