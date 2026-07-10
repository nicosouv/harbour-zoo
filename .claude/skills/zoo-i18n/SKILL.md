---
name: zoo-i18n
description: Translation and internationalisation for harbour-zoo — the 6 target locales (en/fr/de/it/es/fi), the qmake sailfishapp_i18n setup, the lupdate/lrelease workflow, and the rule that the Keeper's voice must survive translation. Use when adding user-visible strings, updating .ts files, or reviewing translations.
---

# Internationalising the Zoo

The app ships in **six languages**: **English (source)**, **French**, **German**, **Italian**,
**Spanish**, **Finnish**. Zoo is a copy-heavy app — the Keeper's warmth and absurdity *are* the
product — so translation is a first-class feature, not a bolt-on.

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
                translations/harbour-zoo-fi.ts
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

## Workflow (regenerate & fill)

```bash
# 1. Extract/update source strings from qml + src into every .ts
lupdate harbour-zoo.pro          # or: lupdate qml src -ts translations/harbour-zoo-*.ts

# 2. Translate: fill each .ts (Qt Linguist, or edit XML), keeping the voice (see prime rule).

# 3. Compile (also done automatically by sailfishapp_i18n at build)
lrelease translations/harbour-zoo-*.ts
```

- Run `lupdate` after adding/changing any `qsTr`. Never hand-add `<message>` blocks — let
  `lupdate` manage them so line numbers/contexts stay correct.
- Leave `-en.ts` present as the source-locale baseline (strings == source); the others carry
  real translations.
- A `scripts/merge_translations.py`-style helper (see sibling harbour-sailcat) can batch-apply a
  translation map across locales if machine-assisting — but every result still gets a
  voice-preserving human pass before shipping.

## Definition of done for i18n

- All six `.ts` files present and non-empty; no `type="unfinished"` left for a shipped release.
- Voice preserved per locale (a native-ish reader smiles, not cringes).
- No truncation/overflow in DE/FI on cover, pills, buttons.
- App runs and reads correctly with device language set to each of the six.
