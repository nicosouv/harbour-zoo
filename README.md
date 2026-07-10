# Zoo

A small, strange, **living zoo** for Sailfish OS. Offline-first, local-only, no telemetry.

Do one little (often absurd) thing a day, keep your habits, run a focus session — and in return
grow a zoo of odd little creatures that live in animated enclosures. Gentle by design: no
streak-shaming, no anxiety timers, no guilt. **As fun as it is useful** — the tracking is the
fuel, the zoo is the fire.

> Status: early scaffold. The engine, unit tests, CI, the app shell and the first procedural
> **Blob** specimen are in place; habits/focus/challenge services and the wider specimen roster
> are next.

## Highlights

- **Useful daily loop** — habit check-ins, a focus timer, and a daily micro-challenge.
- **Procedural specimens** — creatures are real little programs generated from a seed, not PNG
  badges. No two blobs are alike (an SDF-metaball body + reactive googly eyes, all seed-driven).
- **A living zoo** — creatures roam animated enclosures; you're the Keeper, with levels, stats and
  upgrades earned only by actually living your days.
- **Deterministic, event-sourced core** — an append-only log makes the whole engine reproducible
  and unit-testable on desktop.
- **Offline & private** — no network calls anywhere. An optional on-device coach (v2) is opt-in.
- **Six languages** — EN, FR, DE, IT, ES, FI.

## Design docs

The vision lives in [`docs/`](docs/):

- [`creative-direction.md`](docs/creative-direction.md) — the fun bible (start here).
- [`utility-spine.md`](docs/utility-spine.md) — habits + focus + challenge + coach.
- [`specimen-taxonomy.md`](docs/specimen-taxonomy.md) — reaching 300+ specimens with quality.
- [`zoo-meta.md`](docs/zoo-meta.md) — enclosures, Keeper progression, upgrades.
- [`ui-ux-system.md`](docs/ui-ux-system.md) — the harmonised design system.
- [`zoo-spec.md`](docs/zoo-spec.md) — the original build spec (engine, data model, DoD).

## Build

Requires the Sailfish OS SDK (`sfdk`) or the platform SDK Docker image. CI builds against the
4.5.0.18 baseline for the widest device coverage (the RPM still runs on 5.1 devices).

```bash
# App RPM (SDK)
sfdk config target=SailfishOS-4.5.0.18-armv7hl
sfdk build

# Engine unit tests on plain desktop Qt5 (no device needed)
export PATH=/usr/lib/qt5/bin:$PATH
cd tests && qmake tests.pro && make -j2 && ./tst_zoo
```

Releases are cut from semver tags (`vX.Y.Z`); CI builds RPMs for armv7hl / aarch64 / i486 and
publishes a GitHub release.

## Install

Grab the RPM for your device from the [Releases](https://github.com/nicosouv/harbour-zoo/releases)
page, then:

```bash
devel-su
pkcon install-local harbour-zoo-*.rpm
```

Or tap the RPM in File Browser.

## License

[MIT](LICENSE) © Nicolas Souveton
