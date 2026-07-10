---
name: zoo-release
description: Commit, tag, and release conventions for harbour-zoo — semver tags trigger the CI RPM build + GitHub release across armv7hl/aarch64/i486. Use when committing, cutting a release, or tagging.
---

# Releasing harbour-zoo

## Commit style (owner's global rules)

- **English, one-liner, very concise.** A single short line.
- **No emoji. No "by claude" / co-author trailers.** Nothing auto-generated in the message.
- Present-tense, imperative is fine (e.g. `add habit check-in projection`).
- Commit/push **only when asked**. If on `main` and about to do substantial work, branch first.

## Tags

- **English, very concise, no emoji.**
- Format: `vMAJOR.MINOR.PATCH` (this is what the CI release workflow listens for).
- **Prefer bumping the semver patch.** Most of the time, if a tag shipped with an error, we
  **re-cut the same tag** (delete + recreate) rather than inventing a new version — only move the
  version when the release actually changed.

Re-cutting a bad tag:
```bash
git tag -d vX.Y.Z
git push origin :refs/tags/vX.Y.Z
git tag vX.Y.Z
git push origin vX.Y.Z
```

## What a tag triggers (CI)

`.github/workflows/build.yml` on a `v*.*.*` tag:
1. Runs the engine unit tests (must pass).
2. Builds the RPM for **armv7hl, aarch64, i486** via `R1tschY/sailfish-build-rpm`.
3. Injects the version into `rpm/harbour-zoo.spec`.
4. Creates a GitHub Release with the RPMs attached and an auto changelog from commits.

`.github/workflows/pr-build.yml` on PRs/`main` pushes runs the tests + an armv7hl build check
(no release). Keep both green.

## Release checklist

1. Engine tests pass on desktop (`zoo-build`).
2. Harbour-clean build (no forbidden deps) — the default build must stay Jolla-Store-eligible;
   the llama coach stays behind `CONFIG+=with_llama`.
3. Version bumped only if the release content changed; otherwise re-cut the tag.
4. Tag pushed; watch the run:
   ```bash
   gh run watch
   gh release view vX.Y.Z
   ```

## Version source of truth

The spec file (`rpm/harbour-zoo.spec`) gets its `Version:` from the tag at build time
(`%qmake5 VERSION=%{version}`). Don't hand-edit versions in `.pro`/spec for releases — the tag
drives it.
