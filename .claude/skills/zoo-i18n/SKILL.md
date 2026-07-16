---
name: zoo-i18n
description: Translation and internationalisation for harbour-zoo — the 8 target locales (en/fr/de/it/es/fi/zh_CN/zh_TW), the qmake sailfishapp_i18n setup, the lupdate/lrelease workflow, and the rule that the Keeper's voice must survive translation. Use when adding user-visible strings, updating .ts files, or reviewing translations.
---

# Internationalising the Zoo

The app ships in **eight languages**: **English (source)**, **French**, **German**, **Italian**,
**Spanish**, **Finnish**, **Chinese (Simplified)**, **Chinese (Traditional)**. Zoo is a copy-heavy
app — the Keeper's warmth and absurdity *are* the product — so translation is a first-class
feature, not a bolt-on.

## The prime rule: translate the feeling, not the words

Every string carries `zoo-voice` tone (warm, a little absurd, never a scold). A literal
translation that loses the joke or the gentleness is a **bug**. Translate for a native speaker who
should feel the same *delight*, using local idiom — not the same syntax.

- "Introduce yourself to a cloud. Keep it professional." → find the equivalently deadpan line in
  each language, not a word-for-word calque.
- The never-shaming rule holds in every locale: no guilt, no "you failed," even if the target
  language's habit-app clichés lean that way.
- Keep strings short (mobile). Watch German/Finnish length in tight UI (pills, cover, buttons) —
  prefer a shorter in-voice phrasing over truncation.
- Flavor pools (`data/flavor/*.json`, `data/challenges.json`) are **content, not UI strings** —
  they are *not* in the .ts files. If localised flavor is wanted, add per-locale pool files
  (`challenges.fr.json`, …) loaded by locale; otherwise they stay in the source language. Decide
  per pool; default: localise `challenges.json` (the daily-seen copy), keep names/proverbs source
  for v1.

## qmake setup

In `harbour-zoo.pro`:

```pro
CONFIG += sailfishapp_i18n

TRANSLATIONS += translations/harbour-zoo-en.ts \
                translations/harbour-zoo-fr.ts \
                translations/harbour-zoo-de.ts \
                translations/harbour-zoo-it.ts \
                translations/harbour-zoo-es.ts \
                translations/harbour-zoo-fi.ts \
                translations/harbour-zoo-zh_CN.ts \
                translations/harbour-zoo-zh_TW.ts
```

`sailfishapp_i18n` compiles the `.ts` → `.qm` at build and installs them; the app picks the locale
from the system automatically. No runtime language picker needed (Sailfish convention).

## Marking strings

- **Every** user-visible string uses `qsTr("...")` in QML and `tr("...")` / `qsTr` (via a
  `QT_TR_NOOP`-tagged table) in C++. If it can appear on screen, it's translatable.
- Use `%1` placeholders + `.arg()`, never string concatenation, so word order can differ per
  language ("You're a %1 now").
- Use `qsTr("...", "context")` disambiguation and `%n` plural forms where count matters
  (`qsTr("%n creature(s)", "", count)`).
- Keep engine (C++) mostly string-free; surface user copy in QML where possible so translators
  work in one place.

## Workflow — use the repo's Python pipeline (NOT lupdate)

`lupdate`/`lrelease` need a Qt toolchain that isn't on every setup (macOS dev box, CI runs only
`lrelease` at RPM build). So the `.ts` files here are **generated from a Python translation table**
in `scripts/translations/` — this is the canonical workflow. Never hand-edit the `.ts` files and
never hand-add `<message>` blocks; regenerate them.

The four files (`scripts/translations/`):
- **`maketrans.py`** — the master table `T = { source: [fr, de, it, es, fi, zh_CN, zh_TW] }`. **Edit
  this** to add or fix a translation. Running it writes `translations.json`.
- **`gen_ts.py`** — emits `translations/harbour-zoo-{fr,de,it,es,fi,zh_CN,zh_TW}.ts`. QML contexts come from
  `qml_strings.json`; **C++ (`tr()`) source strings are listed by hand in its `zc_src` array**
  under the `zoo::ZooController` context (the metaobject className includes the namespace). Add any
  new C++ user-facing string to `zc_src`.
- **`extract.py`** — rescans `qml/**` for `qsTr()` into `qml_strings.json`, then prints every
  source not yet in `translations.json` (`MISSING`). Run it after changing QML strings.
- **`translations.json` / `qml_strings.json`** — generated caches; don't edit by hand.

```bash
# From repo root, after adding/changing any qsTr() (QML) or tr()/QT_TR_NOOP (C++):
python3 scripts/translations/extract.py        # refresh qml_strings.json + list MISSING sources
#   → add new C++ strings to gen_ts.py `zc_src`; add every MISSING source to maketrans.py `T`
python3 scripts/translations/maketrans.py       # rebuild translations.json from the table
python3 scripts/translations/gen_ts.py          # rebuild the 7 .ts; prints "OK, all translated." or MISSING
```

Iterate until `gen_ts.py` prints **`OK, all translated.`** (zero MISSING). `lrelease` (→ `.qm`)
runs automatically via `sailfishapp_i18n` at RPM build; you don't run it locally.

- `-en.ts` stays the source-locale baseline (strings == source, Qt falls back to source); `gen_ts.py`
  only writes the other seven.
- **No em-dashes (`—`) or en-dashes (`–`) in any user-facing copy** — the owner's house style.
  Use a comma, colon, or full stop. This holds for the English source *and* every translation.

## Definition of done for i18n

- All eight `.ts` files present and non-empty; no `type="unfinished"` left for a shipped release.
- Voice preserved per locale (a native-ish reader smiles, not cringes).
- No truncation/overflow in DE/FI on cover, pills, buttons.
- App runs and reads correctly with device language set to each of the eight.
