# The Keeper's Almanac — authoring the story

The Almanac is the game's red thread. Its chapters live **here, in data** (not in code), so you can
write the next arc without touching C++ or rebuilding the engine's logic. Edit the JSON, ship it, done.

The player never sees the word "season" or "arc" — the Almanac just keeps growing, one page at a time.
`arc` below is your private label for a batch of chapters (your implicit season).

## Files

- **`almanac.json`** — the English **source of truth**. Holds every chapter's `id`, `arc`, `unlock`,
  `after`, and the English `title` / `body`.
- **`almanac.<lang>.json`** — one per locale (`fr`, `de`, `it`, `es`, `fi`). Each holds only
  `id` + translated `title` / `body`. Anything missing falls back to the English source.

The engine loads `almanac.json`, then overlays the current device language by `id`. It reloads when
the language changes. No rebuild needed to change the story text.

## A chapter

```json
{
  "id": "the_seat",              // stable, unique, never reused (used to remember "read")
  "arc": "founding",             // your grouping / implicit season; not shown to the player
  "unlock": { "streak": 7 },     // when the chapter becomes available (see below)
  "after": "companions",         // optional: stays hidden until this chapter is unlocked
  "title": "The seat, kept warm",
  "body": "Seven days you turned up. ..."
}
```

Chapters reveal **in array order**: the app surfaces the earliest unlocked-but-unread one. Put a new
arc's chapters after the existing ones.

## `unlock` conditions

An object of thresholds — **all must hold** (AND). Available keys, each a minimum:

| key | meaning |
|-----|---------|
| `deeds` | lifetime useful actions (challenges + habit check-ins + quests + focus) |
| `streak` | consecutive active days |
| `blobs` | current residents |
| `retired` | lifetime farewells (blobs that have left) |
| `habits` | lifetime habit check-ins |
| `quests` | lifetime quests completed |
| `focus` | lifetime focus sessions |
| `keeperLevel` | Keeper level (derived from `deeds`) |

For an **OR**, use `anyOf` (at least one sub-condition must hold):

```json
"unlock": { "anyOf": [ { "deeds": 100 }, { "blobs": 20 } ] }
```

You can combine: top-level keys are ANDed, and an `anyOf` is ANDed in too. Unknown keys are ignored,
so it's safe to add new ones later.

## Sequencing a new arc (the "season" feel)

To make a second arc begin only **after** the first one lands, give its opening chapter an `after`
pointing at the last chapter of the previous arc (plus its own `unlock`):

```json
{ "id": "s2_opening", "arc": "the_return", "after": "the_promise",
  "unlock": { "streak": 14 },
  "title": "...", "body": "..." }
```

`after` must reference a chapter defined **earlier** in the array.

## Voice & style

Keep the Curator's voice (see the `zoo-voice` skill): warm, a little absurd, never a scold.
**No em-dashes (—) or en-dashes (–)** — use a comma, colon, or full stop. This holds for the English
source and every translation.

## After editing

Nothing to compile for the copy. The files ship via `data.files` in `harbour-zoo.pro`. If you add a
brand-new chapter, also add its `id` + translated `title`/`body` to each `almanac.<lang>.json`
(missing ones fall back to English).
