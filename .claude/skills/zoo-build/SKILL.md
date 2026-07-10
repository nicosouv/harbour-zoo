---
name: zoo-build
description: Build, test, and deploy harbour-zoo — the Sailfish OS build loop (sfdk, Docker/mb2, desktop QtTest for the engine, RPM). Use when building the app, running engine unit tests, deploying to emulator/device, or debugging the SFOS toolchain.
---

# Building harbour-zoo

Sailfish OS app: qmake + `sailfishapp`, Qt 5 / QtQuick 2 + `Sailfish.Silica`. C++17 engine
(desktop-testable, no Qt Quick dependency) + QML/Silica UI. SQLite via `QtSql`. Mind the older
Qt baseline — avoid APIs newer than the target SFOS Qt version.

## The two things you build

1. **The engine unit tests** (`tests/`, QtTest) — run on plain desktop Qt5, no device or SDK
   needed. This is the fast inner loop. **Always run these before considering a change done.**
2. **The app RPM** — needs the Sailfish toolchain (SDK or Docker). Slower; for real device/emulator.

## Engine tests on desktop (fast loop)

```bash
sudo apt-get install -y --no-install-recommends qtbase5-dev qtbase5-dev-tools qt5-qmake make g++
export PATH=/usr/lib/qt5/bin:$PATH
cd tests
qmake tests.pro
make -j2
./tst_zoo
```

`tests/tests.pro` compiles the engine sources directly (`../src/engine/*.cpp`) with
`QT += core sql testlib`, `CONFIG += c++17 console`, `CONFIG -= app_bundle`. The engine must
compile and pass here **without QtQuick** — if a test needs Qt Quick, the logic is in the wrong
layer (move it out of the engine, spec §3 layering rule).

Target for coverage (spec §8): EventStore round-trip · StateProjection (esp. streak+grace) ·
Economy (earn/spend/reject) · ChallengeService determinism · Rng reproducibility · UnlockRules
(grant-once) · SpecimenRegistry minting. Determinism means tests assert **exact** outputs —
inject the clock and the install-salt; never call wall-clock time or system RNG in the engine.

## App build with the Sailfish SDK (local)

```bash
sfdk config target=SailfishOS-5.1.0.11-armv7hl
sfdk build
sfdk emulator start
sfdk deploy --manual          # emulator
# device:
sfdk device set <device-ip>
sfdk deploy
```

## App build with Docker (no SDK)

```bash
docker run --rm -it \
  -v $(pwd):/home/sailfish/src -w /home/sailfish/src \
  coderus/sailfishos-platform-sdk:5.1.0.11 \
  mb2 -t SailfishOS-5.1.0.11-armv7hl build
# RPMs land in RPMS/
```

## Target SFOS release

Current target: **Sailfish OS 5.1.0.11 "Pispala"** (the 5.1 series). This is the string used by
`sfdk`, the coderus Docker image tag, and the CI `SAILFISH_RELEASE`. When a newer 5.1.0.x ships,
bump it in one place per surface: both `.github/workflows/*.yml`, this skill, and `CLAUDE.md`. If a
CI build fails at the "Build RPM" step with a release/image-not-found error, the pinned version
isn't published for `R1tschY/sailfish-build-rpm` yet — drop to the latest one that is.

## Harbour cleanliness (non-negotiable for v1)

v1 must be **Harbour-clean** so it can target the Jolla Store: no forbidden deps, no private
APIs. The optional llama.cpp `LlamaFlavorProvider` (v2) is NOT Harbour-allowed — keep it behind a
build flag (`CONFIG+=with_llama`) so the default build stays clean. Verify with `rpmvalidator`
in the SDK before release.

## When something breaks

- QML import errors on device but not desktop → an API newer than the target Qt. Check the SFOS
  Qt version for the target release.
- Test binary won't link → the engine pulled in a Qt Quick/GUI symbol. Keep engine GUI-free.
- RPM validation fails → a forbidden dependency crept in; check the `.pro` and spec `Requires`.
