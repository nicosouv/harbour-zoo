---
name: zoo-voice
description: The Curator/Keeper's voice — copy and flavor guidelines for every user-visible string in harbour-zoo (challenges, specimen names/lore, empty states, streak wobble, level-ups, reminders). Use when writing UI copy, flavor pool entries, notification text, or reviewing tone.
---

# The voice of the Zoo

One warm narrator runs through every string: challenge text, specimen names and lore, proverbs,
empty states, level-up ceremonies, badges, the (opt-in, off-by-default) reminder. Consistency of
voice is what makes the zoo feel like a *place with a personality* rather than a form with fields.

## The three rules

1. **Warm.** Always on the player's side. Delighted they're here; mildly delighted by everything
   else too. The narrator likes you and likes the creatures.
2. **A little absurd.** Deadpan about strange things, sincere about small things. The comedy is in
   treating a pet rock's feelings as a serious matter and a 30-day streak as a quiet miracle.
3. **Never a scold.** **There is no failure state in this app, only weather.** No guilt, no shame,
   no "you broke it," no anxiety countdowns, no red debt. A missed day is met with a shrug and an
   open hand.

## The prime directive: reward returning, never punish leaving

The single most important tone rule. Every lapse-related string must make coming back feel easy
and welcome. We celebrate the return; we never audit the absence.

## Canon copy (reuse these; don't reinvent per-screen)

- **Empty zoo:** "Your zoo is a field of potential and one very optimistic sign. Do one small
  thing and watch something move in."
- **Streak wobble (grace spent):** "You missed a day. The zoo kept your seat warm. Nothing was
  lost — pick it back up whenever."
- **Streak reset (grace exhausted):** "We're starting the count fresh, no ceremony. The creatures
  don't keep grudges; neither do we."
- **Habit resting (missed):** "This one's resting. It'll be right here when you're ready."
- **Common hatch:** "Something small and content just moved in."
- **Rare hatch:** "Wait. *What* is that. (It's yours now.)"
- **Mythic hatch:** "...okay. Okay. You should probably sit down for this one."
- **Focus session done:** "Nice. That time was yours and you spent it well."
- **Keeper level-up:** "The Zoological Society has noticed. You're a %1 now. Wear it lightly."
- **Enclosure a bit crowded:** "Cozy in here. The blobs don't mind, but they'd stretch out in
  something roomier."
- **Reminder (only if enabled):** "The zoo made a small noise. Might be nothing. Might be a little
  thing worth doing."

## House style for the daily challenge (data/challenges.json)

- Second person, imperative, warm. Doable in under 2 minutes, no equipment, no spending, no other
  people *required*.
- **A little wrong.** The best ones make you smile before you've done them ("Introduce yourself to
  a cloud. Keep it professional.").
- Never chore-coded. "Drink water" is out. Make even a healthy nudge strange and inviting.

## Flavor pools (data/flavor/)

`names.json` (specimen names) and `proverbs.json` (one-line lore) are picked deterministically by
seed and cached at mint, so a creature's name/lore is stable forever. When adding entries: keep
each self-contained, evocative, and in-voice; avoid topical or dated references (they live forever).
The narrator names things "like a slightly unwell museum" and writes proverbs that are *present*
rather than wise.

## What to avoid

- Guilt, urgency, FOMO, streak-shaming, red numbers, "don't lose your…", aggressive countdowns.
- Corporate cheer ("Great job, superstar!!!"). Keep it dry and genuine.
- Over-explaining the joke. State the absurd thing plainly and move on.
- Long strings — most UI copy is one sentence. The reminder is one gentle line.
