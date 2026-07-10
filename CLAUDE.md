# CLAUDE.md

Guidance for Claude Code working in this repository.

## What Zoo is

A small, strange, **living zoo** for Sailfish OS. Offline-first, local-only, no telemetry. You do
one little (often absurd) thing a day, keep habits, and run focus sessions — and in return you
grow a zoo of odd creatures that live in animated enclosures. It must be **as fun as it is
useful**: the utility (habits/focus/challenge) is the fuel; the zoo is the fire.

**Design pillars (non-negotiable): gentle delight, never shaming; the unlockables are real little
programs (not badges); offline-first; deterministic core with optional flavor; testable C++ engine
decoupled from QML.**

## Read these first (the design)

- `docs/zoo-spec.md` — the original build spec (engine, event-sourcing, tech stack, DoD).
- `docs/creative-direction.md` — the fun bible; start at its "Evolution note."
- `docs/utility-spine.md` — habits + focus timer + daily challenge + opt-in offline coach (the
  reason to open it, several times a day).
- `docs/specimen-taxonomy.md` — how we reach **300+ specimens** with quality (archetypes, rubric).
- `docs/zoo-meta.md` — living enclosures, Keeper progression/stats, zoo upgrades (the long game).
- `docs/ui-ux-system.md` — the harmonised design system & information architecture: utility in the
  body, delight in the frame; the component kit; palette; goofy-stats treatment.

## Skills (invoke the matching one before working)

- **zoo-build** — build/test/deploy (desktop engine tests, sfdk, Docker, RPM, Harbour cleanliness).
- **zoo-engine** — C++ engine architecture: event-sourced, deterministic, unit-tested.
- **zoo-specimen** — authoring specimens/archetypes to the quality bar.
- **zoo-silica** — Silica/QML UI conventions and the gentle-never-shaming presentation.
- **zoo-voice** — the narrator's voice for all copy and flavor.
- **zoo-i18n** — translation to the 6 locales (en/fr/de/it/es/fi), preserving the voice.
- **zoo-release** — commit/tag/release conventions and CI.

## Architecture (one line)

`QML → ZooController (thin facade) → engine services → EventStore (SQLite, append-only)`. QML never
touches SQLite; the engine never imports Qt Quick. Current state is a **projection** of an
append-only event log — reproducible by replay, which makes the whole engine testable on desktop.

## Build commands

```bash
# Fast loop: engine unit tests on plain desktop Qt5 (no device/SDK needed)
export PATH=/usr/lib/qt5/bin:$PATH
cd tests && qmake tests.pro && make -j2 && ./tst_zoo

# App RPM via SDK
sfdk config target=SailfishOS-5.1.0.11-armv7hl
sfdk build

# App RPM via Docker (no SDK)
docker run --rm -it -v $(pwd):/home/sailfish/src -w /home/sailfish/src \
  coderus/sailfishos-platform-sdk:5.1.0.11 mb2 -t SailfishOS-5.1.0.11-armv7hl build
```

## Release

Semver tag `vX.Y.Z` → CI runs tests, builds RPMs (armv7hl/aarch64/i486), publishes a GitHub
release. See the `zoo-release` skill. Commits: English, one-liner, concise, no emoji, no
co-author trailers. Tags: English, concise; prefer bumping the patch, and re-cut a bad tag rather
than inventing a new version.

## Hard rules

- Keep v1 **Harbour-clean** (Jolla-Store-eligible). The optional llama coach (v2) stays behind
  `CONFIG+=with_llama` so the default build never links forbidden deps.
- No network calls anywhere. No IAP, ever. Determinism: the engine never calls wall-clock time or
  system RNG except one injectable `Clock` and one injectable install-salt.
- English identifiers and comments. One constant module `AppId.h` for all name/id strings.
