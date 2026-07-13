# Zoo — The Utility Spine (why you open it, every day, several times)

> Decided with the owner: the useful daily spine is **Habit tracking + Focus/streak timer +
> Daily challenge**, with an **opt-in offline coach**. This is the fuel. The living zoo
> (`zoo-meta.md`) is the fire. Neither works without the other.

The test every feature here must pass: **if you deleted the whole zoo, would this still be worth
opening?** If no, it's decoration, not spine.

## 1. Habits — the several-times-a-day driver

The single biggest reason to reopen. You define recurring habits; you check them in *when you do
them*, across the day.

- **Model:** `{ id, name, icon, cadence (daily | x-per-day | days-of-week), target, tags }`.
  A habit can be "once a day" (read) or "N times a day" (drink water ×6) — the ×N ones are what
  create multiple daily opens.
- **Check-in** emits `habit_logged { habit_id, date }`; the projection folds it into per-habit
  progress and a gentle per-habit streak (same grace mechanic as the global streak — a missed day
  spends grace before breaking, never shames).
- **Earns:** a few Crumbs + a little Keeper XP per check-in (diminishing within a day so it can't
  be farmed — the reward is for *doing the habit*, not for tapping).
- **Gentle by law:** no red "you missed it," no guilt push. A lapsed habit is shown as "resting,"
  ready whenever. The coach may offer a warm nudge (opt-in), never a scold.

Why it's useful *without* the zoo: it's a genuine, private, offline habit tracker. The zoo just
makes you *want* to check in.

## 2. Focus / streak timer — time on your own goals

A tiny focus session you run against *your* thing (study, gym, deep work, practice).

- **Start** a session (pick a length or open-ended) → `focus_started`. **Finish** → `focus_completed
  { minutes }`. Abandoning is fine and costs nothing — no punishment for a short session.
- **Earns:** Crumbs + XP proportional to minutes, with a soft cap per day (so it rewards real
  focus, not leaving it running).
- Optional: link a session to a habit ("30 min guitar" counts toward the guitar habit).
- Presented calmly: a breathing, un-stressful timer; the cover shows it ticking. No aggressive
  countdown; finishing early is a win, not a fail.

Why it's useful *without* the zoo: it's a clean, offline focus timer that logs your effort.

## 3. Daily challenge — the novelty anchor

One small, slightly absurd micro-challenge per day (see `data/challenges.json`, creative-direction
§6). This is the *spark*, not the meal — it keeps the daily open delightful even on a day you have
no habits due. Deterministic selection, warm voice, tags feed combo secrets.

## 4. The Coach (opt-in, offline ML — decided: "helper" role)

An **optional** local model that genuinely *helps*, with a static fallback so the app is fully
functional without it (spec §5.6 architecture — same `FlavorProvider`-style seam, extended).

- **Break down a goal:** you type "learn guitar" → it proposes 3–5 concrete micro-habits /
  first steps you can turn into tracked habits with one tap.
- **Suggest & tune habits:** gently proposes a cadence, or suggests easing a habit that keeps
  "resting" rather than dropping it.
- **Warm nudges & reflections:** short, kind, never nagging; e.g. an end-of-week "here's what you
  actually did" that celebrates, never audits.
- **Constraints:** entirely offline, opt-in, off by default, only enabled if a model is present
  (llama.cpp backend from Sailcat, GBNF-grammar-constrained). Distributed via OpenRepos/Chum only
  (not Harbour-clean). The **static fallback** provides canned-but-warm breakdowns and nudges so
  the coach experience degrades gracefully to "helpful enough."
- **It never gates anything.** The app is complete and useful with the coach off.

## 5. Everything funnels into one economy

Every useful action mints **Crumbs** (fast, spendable) and **Keeper XP** (slow, progression):

| Action                         | Crumbs        | XP     |
|--------------------------------|---------------|--------|
| Complete daily challenge       | 10 (+streak)  | small  |
| Habit check-in                 | few (diminish)| tiny   |
| Focus session                  | ∝ minutes cap | ∝ min  |
| Secret / milestone unlock      | bonus         | bonus  |

Crumbs → hatch creatures + small zoo purchases. XP → Keeper level & the big zoo upgrades
(`zoo-meta.md`). Crucially, **you cannot grind the zoo by tapping** — the only way to grow it is
to actually do your habits, focus, and daily thing. That is the whole trick: the game is played
by living your day, and the zoo is the scoreboard you *want* to look at.

## Events added to the log for the spine

Extends spec §4.2 (append-only, projectable, testable):
- `habit_created` — { habit_id, name, cadence, target, tags }
- `habit_logged` — { habit_id, date }        (already reserved in spec for v2 — now v1 spine)
- `habit_archived` — { habit_id }             (never "deleted" in the log; hidden in UI)
- `focus_started` — { session_id, planned_min? , habit_id? }
- `focus_completed` — { session_id, minutes, habit_id? }
- `xp_earned` — { amount, reason }

All fold into the projection; per-habit streaks and Keeper level are derived state, never
authoritative — reproducible by replay (DoD §9.8).

## The evidence base (why the spine is shaped this way)

The utility spine is not vibes — it tracks the behaviour-change literature. This section is the
reference the features answer to; keep new features aligned with it.

**What makes a habit stick**
- **Lally et al. (2010)** — automaticity takes a *median 66 days* (18–254), not "21." Crucially,
  *missing one occasion does not derail formation.* → streak grace, "never miss twice," lapse
  tolerance are evidence-based, not just kind.
- **Wendy Wood — context + friction.** ~43% of daily acts are context-cued automaticity. The
  strongest levers are **context stability, repetition, friction** (make good easy / bad hard),
  and **reward**. → implementation intentions & anchoring; friction/replacement for bad habits.
- **Gollwitzer — implementation intentions.** "If [situation], then I will [action]" reliably
  lifts follow-through (robust meta-analytic effect). → the habit **cue** field.
- **Immediate reward beats delayed** (temporal discounting). → crumbs/blob mint *now*, on the spot.
- **Clear — identity-based habits** ("become someone who…") persist longest. → the Almanac's fil
  rouge ("you are becoming someone who shows up") is the durability lever, not a decoration.
- **Fogg — Tiny Habits** (B=MAP): start tiny, anchor to an existing routine, celebrate at once.

**Why we pick up bad habits**
- **Reward-timing asymmetry**: the "bad" soothes *immediately*; the cost is *deferred*.
- **Stress + depleted self-control** → fallback to automaticity (Wood). Cue-rich environments and
  **intermittent/variable reward** (Skinner) are the stickiest. A bad habit usually *serves a
  function* (emotion regulation) — it's a flawed solution, not a moral failing.

**How we get out of them**
- **You replace, you don't erase** (Duhigg's golden rule): keep the cue & reward, swap the routine.
  → bad habits carry a **replacement**.
- **Add friction**; **change context / fresh start** (Milkman's fresh-start effect). → fresh-start
  prompts at week/month boundaries.
- **Self-compassion beats shame** (Neff; Marlatt's relapse prevention). Shame *predicts* relapse.
  The **abstinence-violation effect** ("one slip = I've blown it") is the real enemy. → "never miss
  twice," warm reframes, no red counts.

**Is a mild bad habit OK for a while?**
- Yes: **rigid** restraint does *worse* than **flexible** restraint (eating research); all-or-
  nothing is a risk factor, not a virtue. Lapses are tolerated by formation. **Harm reduction**
  (reduce/bound) is often more durable than eradication. The trap is *unbounded self-licensing*,
  not the indulgence itself. → **bounded indulgence**: a bad habit can be marked *tolerated for
  now* — still tracked, but it doesn't tint the zoo mood. Conscious & bounded beats hidden & shamed.

**Readiness (the emotional check-in)**
- Self-control and habit follow-through collapse under low mood / stress (Wood; ego-depletion
  debates aside, the direction holds). So a light **smiley mood check-in** senses whether *now* is
  a push day or a be-gentle day, and the app adapts its ask accordingly — never diagnostic, never
  stored as anything but a private valence.

### The five levers, mapped to features
1. **Implementation intentions + anchoring** — a `cue` on each habit ("after coffee, at my desk").
2. **Never miss twice** — a gentle nudge only after a *single* missed day (never a scold, never
   after a long absence — that gets an even warmer "welcome back").
3. **Friction / replacement** — bad habits carry a `replacement` swap surfaced on a slip.
4. **Fresh start** — week/month boundaries are framed as clean pages to renegotiate a habit.
5. **Bounded indulgence** — a bad habit can be `tolerated`; slips still count for the person, but
   don't tint the zoo mood.

New events for the above (append-only, projectable, testable):
- `mood_logged` — { date, valence } (1–5 smiley; latest of the day wins)
- `habit_created` gains { cue, replacement, tolerated } (all optional, back-compatible)
