# OpenRepos publication assets

Ready-to-paste copy for the OpenRepos listing. Screenshots are taken on-device (see the shot list).
House style: dry and unserious for the pitch, straight for privacy. No em-dashes.

## Title

**Zoo** (package: `harbour-zoo`) · tagline: *A tiny living zoo for the small things you do.*

## Full description (paste this)

Zoo is a small, strange, living zoo for the little things you do.

What is this, and what is it for? It is a habit tracker that refused to look like a habit tracker.
You do one little (often absurd) thing a day, keep a few habits, run the odd focus session, and in
return a cabinet of pixel creatures slowly fills up with blobs, potted sprouts and other oddities
that live in animated enclosures you can theme and poke. The useful part (habits, focus, a daily
challenge) is the fuel. The zoo is the fire. It is as unserious as it is useful.

There is no shaming here. No streak-guilt, no red numbers, no timers built to spike your anxiety.
Miss a day and you get a shrug and a warm hand, never a scold. It is entirely offline and private:
no accounts, no network, no trackers, no ads, and no in-app purchases, ever. Nothing leaves your
device, because the app never once asks the internet for anything.

This is an early public release. It works, it speaks six languages, and it will still have rough
edges. Bring a Tuesday.

Source code: https://github.com/nicosouv/harbour-zoo

Features

The daily loop (the useful bit):
- A daily challenge: one small, slightly absurd, under-two-minutes thing.
- Habits: good ones with a times-per-day target, and bad ones you gently starve. Each can carry a
  cue ("after my morning coffee"); a bad habit can carry a kinder swap to do instead, and a
  "tolerate it for now" two-week amnesty so a single slip does not sour everything.
- A "never miss twice" nudge that only appears after one missed day, never a scold.
- Quests: one-off tasks with an optional deadline. Leave one overdue too long and the Quest Beast
  turns up to deal with it.
- A calm focus timer (pomodoro) that keeps running while you wander the app.
- An optional emotional check-in: tap a smiley and the app right-sizes what it asks of you today.
  It never gates anything; a low day just means "go tiny, and tiny counts".
- Gentle fresh-start nudges at the start of a week or month.

The zoo (the reward):
- Earn crumbs by doing the useful things; spend them to hatch creatures, buy decorations, and
  unlock biomes.
- Procedural pixel creatures: no two blobs are alike (seeded bodies, eyes, wobble and quirks; four
  rarities up to a humming mythic), plus potted Sprout plants that bloom if you fuss over them.
  Poke them and they react.
- A living enclosure: theme it, decorate it, and watch the foliage sway and tiny insects wander.
  The whole scene warms or cools with how your habits are going.
- Keeper progression: levels, titles, commendation badges, a seven-day activity graph, and weekly
  and monthly stats.

The story and the ceremonies:
- The Keeper's Almanac: a quiet story that unfolds at real milestones and arrives as a gentle
  full-screen reveal. It turns out the zoo was a portrait of you all along.
- In-place ceremonies over a blurred zoo: a creature shoulders a little bindle and wanders off, a
  birthday, a milestone, a national holiday, and the occasional Quest Beast eating a blob.
- Confetti. A generous amount of confetti.

The rest:
- A living-zoo onboarding, with a free first creature handed to you on the way in.
- Six languages: English, French, German, Italian, Spanish, Finnish.
- An optional, gentle daily reminder (off by default; the zoo waits for you, it never nags).
- Hidden easter eggs and dubious "fun facts".

About this project

Written by a human developer with an LLM (Claude). The engine is event-sourced and deterministic:
everything you see is a fold of an append-only local log, so your zoo is reproducible and unit
tested, and the app contains no network code whatsoever.

Privacy and data

- Everything is stored locally: an append-only SQLite log plus a small preferences file, on your
  device only. Nothing is ever uploaded; the app makes no network requests at runtime.
- No accounts, no trackers, no analytics, no ads, no in-app purchases.
- No intrusive permissions: Zoo does not read your photos, contacts, or location.
- One-tap "Erase all data" (in Settings, with a confirmation) wipes everything and drops you back
  at the start.

Feedback

This is an early version. If it does not work for you, or you dislike something, I am genuinely
open to constructive criticism. Issues and ideas: https://github.com/nicosouv/harbour-zoo/issues

## Description courte (français, si besoin)

Zoo est un petit zoo vivant et étrange pour les petites choses que tu fais. Un tracker d'habitudes
qui refuse d'en avoir l'air : fais un petit truc par jour, tiens quelques habitudes, et de drôles
de créatures en pixel-art emménagent dans des enclos animés. Hors ligne, privé, jamais moralisateur.
Code : https://github.com/nicosouv/harbour-zoo

## Category and tags

- Category: **Games** (a toy first; Applications also works if you prefer the tracker angle).
- Tags: `habit tracker`, `habits`, `focus`, `pomodoro`, `productivity`, `offline`, `privacy`,
  `pixel art`, `creatures`, `gentle`, `sailfish`.

## Changelog (v0.5.3)

- New onboarding: a living-zoo preview that reacts to your choices, confetti, and a free first creature.
- Add habits and quests on their own tidy pages; Today stays an uncluttered glance.
- Sprout creatures join the blobs; the enclosure sways and hosts a few wandering insects.
- Confetti properly arcs up and falls back down.
- Development shortcuts hidden.

## Screenshot shot list (on-device, portrait, 4 to 5)

1. The zoo page with creatures roaming and a tree swaying. The hero shot.
2. Onboarding: the living preview with confetti (the "into the zoo" moment).
3. A ceremony or an Almanac chapter reveal (blurred zoo, foreground scene).
4. Today: the daily challenge, a habit or two, the focus timer.
5. A Sprout or a rare blob full-screen on the specimen page.

## Upload form notes

- Version 0.5.3. Attach all three RPMs (aarch64, armv7hl, i486) from the GitHub release.
- License: MIT. Source: https://github.com/nicosouv/harbour-zoo
