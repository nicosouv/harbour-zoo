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
