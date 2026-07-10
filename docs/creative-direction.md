# Zoo — Creative Direction (the fun bible)

> This is the companion to `zoo-spec.md`. The spec says *how the machine works*; this says
> *why anyone would come back to it*. It resolves the open decisions in spec §11 with
> opinionated, changeable defaults. Everything here is renameable behind one constant
> (`AppId.h`) — nothing below is load-bearing except the feeling.

> **Evolution note (read this first).** Since the first draft, the concept grew with the owner from
> a once-a-day "cabinet of curiosities" into a **living zoo you keep**. Three companion docs now
> carry the load and take precedence where they expand on this file:
> - **`utility-spine.md`** — the *useful* daily engine: habit tracking + focus timer + daily
>   challenge + an opt-in offline coach. This is why you open it (several times a day).
> - **`specimen-taxonomy.md`** — how we reach **300+ specimens** with quality: ~15 hand-crafted
>   generative *archetypes* × curated species, all passing a strict quality rubric.
> - **`zoo-meta.md`** — the long game: creatures live in animated **enclosures**, you're the
>   **Keeper** with levels/stats/rating, and you spend earned currency on **zoo upgrades**.
>
> Where this file still says "cabinet," read "zoo"; where it names a single "Curator," that voice
> lives on as the zoo's warm narrator. The soul below (gentle delight, never shaming, the
> unlockables *are* the point) is unchanged and still governs everything.

---

## 0. The one-sentence pitch

**You do one small, slightly absurd thing each day, and in return a cabinet of tiny living
programs slowly fills up with creatures you can poke.** The reward is not a badge. The reward
is *the weird little thing itself*.

The app is a **cabinet of curiosities that feeds on your curiosity.** Useful because the daily
loop nudges you outward (move, notice, be kind, make). Fun because what you unlock is genuinely
strange and alive.

---

## 1. The feeling we are protecting

Every decision defends **one emotion: gentle delight.** If a feature could make someone feel
watched, nagged, guilty, or behind — we cut it or soften it. This is the north star. Concretely:

- No red badges of shame. No "you broke your streak!" No countdown timers built to spike anxiety.
- A missed day is met with a shrug and a warm hand, never a scold. (See streak grace, spec §4.3.)
- The app never asks for more than one small thing a day. Doing *more* is allowed, never demanded.
- Surprise is rationed and earned, so it stays surprising. Hatching is the dopamine; we don't
  give it away for free, but we never gate it behind grind either.

---

## 2. Names & words (spec §11)

- **App name:** keep **Zoo** (`harbour-zoo`). It's short, warm, and slightly wrong for what it
  is (a cabinet, not a zoo) — which is exactly the tone. Display subtitle: *"a cabinet of small
  living things."*
- **The collection** is **the Zoo**. Individual unlockables are **specimens**.
- **The NPC/host** is **the Curator** — an ambient, unseen personality who writes the flavor
  text, reacts to your collection, and hands you the daily challenge. The Curator is warm,
  eccentric, and a little unreliable. All flavor copy is "in the Curator's voice."
- **Currency:** **Crumbs.** You earn Crumbs by doing the day's thing; you feed Crumbs to the
  Curator and something crawls, hatches, or sprouts out of the cabinet. "Crumbs" is small,
  humble, and funny — it keeps the economy from feeling like a bank. *(Renameable; the spec's
  placeholder "Seeds" also works if a garden metaphor is preferred.)*
- **The unlock action** is **"Feed the cabinet"** (mechanically: hatch an egg / roll a specimen).

### Number defaults (tune freely)
- Daily completion reward: **10 Crumbs.**
- Gentle streak bonus: **+1 Crumb per streak day, capped at +5.** (So a warm week tops out at 15.)
- Feed-the-cabinet cost: **25 Crumbs.** (≈ two-to-three days of showing up. Feels earned, never
  grindy.)
- Grace tokens: start with **1**, replenish **+1 per 5 completed days**, cap **2** (spec §4.3).

---

## 3. Rarity & the humane gacha

Four tiers. Weights are the base roll; a **pity counter** nudges the odds so a run of bad luck
self-corrects (deterministic — driven by `total_hatched` counter, spec §5.1).

| Tier      | Base weight | Feeling                                   |
|-----------|-------------|-------------------------------------------|
| common    | 64%         | "oh, a friend."                           |
| uncommon  | 26%         | "ooh, a nicer friend."                    |
| rare      | 9%          | "wait, *what* is that."                   |
| mythic    | 1%          | "I need to show someone this immediately."|

**Pity:** track hatches since last rare-or-better. At **8**, guarantee ≥ rare on the next feed;
reset on any rare+. This keeps the long tail humane without ever feeling random-in-a-bad-way.
Because it's counter-seeded, tests can assert the exact pull.

**What each tier changes** for a given specimen: palette richness, extra limbs/eyes, animation
complexity, and whether a shader/particle flourish is enabled. A rare Blob has iridescence and
an extra blinking eye; a mythic one hums.

---

## 4. The specimen roster

Each specimen is a real, self-contained QML program (spec §5.4 contract). "State" is what
persists between visits (mood, growth, battle count). See the `zoo-specimen` skill for the
authoring contract.

### v1 ships these five (4 authored + 1 procedural — satisfies DoD §9.5)

1. **Blob** — *procedural* — `common | uncommon | rare | mythic`
   A seeded gooey creature. Seed drives palette, eye count (1–3), wobble frequency, blink
   rhythm. Poke → it squishes and giggles (scale spring). Rare: iridescent gradient + extra eye.
   Mythic: it hums (subtle pulsing glow) and very occasionally winks at you unprompted.
   *State:* `pokes` (int). Every 50 pokes it "burps" a single free Crumb (a tiny secret).

2. **Pet Rock** — *authored* — `common`
   A rock. It has a mood that drifts on a slow, always-gentle spectrum (never sad — pet rocks
   are zen). Tap to pet; petting nudges mood toward "content". Leave it a week and it becomes
   "contemplative" and offers a googly-eyed proverb (from the flavor pool). The point is that
   it asks nothing of you and is fine.
   *State:* `mood` (0..1), `lastPetDate`.

3. **Useless Machine** — *authored* — `uncommon`
   The classic: a box with a switch. You flip it on; a little arm reaches out and flips it back
   off. Always. It counts your battles. After 100 battles it lets out a tiny animated sigh and
   gives up *once* — leaving the switch on — and gifts you a Crumb for your persistence, then
   goes back to being useless forever.
   *State:* `battles` (int), `hasSighed` (bool).

4. **Bauhaus Garden** — *authored* — `rare`
   A generative geometric garden. It gains **one new primitive shape per active day** (any day
   you completed the challenge). This is the "useful" hook made visible: your consistency
   literally builds a small, beautiful, ever-more-crowded composition. Tap to reshuffle the
   arrangement (never destroys shapes). Seed drives the palette and shape vocabulary.
   *State:* `shapes` (int, = active days since mint), `arrangementSeed`.

5. **Desk Fan** — *authored* — `common`
   A tiny oscillating fan you can spin with a drag; it has momentum and coasts to a stop. Pure
   fidget, zero purpose — which is the purpose. Spin it *fast* (past a velocity threshold) 100
   times total and it **achieves liftoff**: it detaches, becomes a little balloon-fan, and
   drifts. That's a secret variant, granted once.
   *State:* `spins` (int), `hasLiftoff` (bool).

### v2+ roster (idea bank — do not build yet, but the pool should smell like this)

Lava Lamp · Worry Stone (swipe-to-rub, satisfying haptic) · Magic 8-Rock (ask yes/no, it
answers in proverbs) · Sea-Monkey Jar (particles multiply with your streak) · Toast (gets
progressively, lovingly more buttered the more you return; peak butter is a rare state) · Ant
Farm (tunnels grow with lifetime challenges completed) · Snow Globe (tap to shake, seeded scene
inside) · Metronome (tap-tempo; secret if you nail 120 BPM) · The Curator's Business Card
(mythic; a card that redraws its own title every time you look).

---

## 5. Secret & combo unlocks (spec §5.5)

Secrets are the app's mischief. They reward *how* and *when* you show up, not just *that* you
did. Every grant is one-time (guarded by `granted_rules`). Adding one is a JSON entry.

**v1 ships two** (both use v1 predicate types, DoD §9.6):

- **`night_owl`** — completed between **02:00–04:00** → grants **Pet Rock**.
  *Curator note:* "Only the sleepless get rocks. It's a whole thing."
- **`persistent`** — `streak_at_least: 7` → grants **Bauhaus Garden**.
  *Curator note:* "Seven days. The garden noticed you first."

**Designed for v2 (idea bank):**

- **`early_bird`** — completed before 06:00 → Desk Fan.
- **`combo_curious_kind`** — a `curiosity`-tagged *and* a `kindness`-tagged challenge on the
  same local date → Useless Machine. (Doing a weird thing *and* a kind thing in one day.)
- **`the_return`** — come back and complete after grace has been spent (i.e. after a wobble) →
  a warm "welcome back" specimen. **We reward returning, never punish leaving.** This is the
  most important secret in the whole design: the app's arms are always open.

---

## 6. The daily challenge — the actual soul

The challenge is the one thing we ask. It has to be small enough to do on a bus and strange
enough to want to tell someone about. Tags let secrets and variety work: `curiosity`,
`kindness`, `movement`, `creative`, `mindful`, `absurd`.

The starter pool lives in `data/challenges.json`. House style:
- **Doable in under 2 minutes**, no equipment, no spending money, no other people *required*.
- **A little wrong.** The best ones make you smile before you've done them.
- **Never chore-coded.** "Drink water" is out. "Introduce yourself to a cloud" is in.
- **Warm, second person, imperative.** The Curator is talking to you.

---

## 7. The Curator's voice (flavor & copy)

One voice runs through every string in the app: challenge text, specimen names and lore,
proverbs, empty states, the streak-wobble message, the (opt-in, off-by-default) reminder. See
the `zoo-voice` skill for full guidance and the pools in `data/flavor/`.

Three rules:
1. **Warm.** Always on your side. The Curator is delighted you're here and mildly delighted by
   everything else too.
2. **A little absurd.** Deadpan about strange things; sincere about small things.
3. **Never a scold.** There is no failure state in this app, only weather.

Sample copy (canon):
- **Empty Zoo:** "The cabinet is empty and slightly embarrassed about it. Feed it once and see
  what wakes up."
- **Streak wobble (grace spent):** "You missed a day. The cabinet kept your seat warm. Nothing
  was lost — pick it back up whenever."
- **Streak reset (grace exhausted):** "We're starting the count fresh, no ceremony. The
  specimens don't keep grudges; neither do we."
- **A common hatch:** "Something small and content just moved in."
- **A mythic hatch:** "...okay. Okay. You should probably sit down for this one."
- **Reminder (if ever enabled):** "The cabinet made a small noise. Might be nothing. Might be a
  little thing worth doing."

---

## 8. Why you come back (the loop, honestly)

1. **Tiny obligation, met.** One small strange task; the friction to complete is near zero.
2. **Immediate warmth.** Crumbs, a gentle streak tick, kind words — no math homework.
3. **Anticipation.** Crumbs accumulate toward the next feed. You *know* something odd is coming.
4. **The pull.** Feeding the cabinet is a genuine surprise: which specimen, which rarity, which
   flavor name the Curator invents.
5. **The slow reveal.** Some specimens (Bauhaus Garden, Toast, Ant Farm) visibly grow with your
   consistency — so the collection quietly becomes a portrait of your last few weeks.
6. **The mischief.** Secrets you didn't know existed fire at odd hours and reward your quirks.

Useful and fun aren't in tension here: the *useful* part (show up, do a small outward-facing
thing) is the fuel, and the *fun* part (the cabinet) is the fire. Neither works without the
other, which is the whole point.
