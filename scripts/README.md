# scripts/

Reproducible generators for the assets and translations that live in the repo. Run from the repo
root with Python 3 + Pillow (`pip install Pillow`).

## Art (`scripts/art/`)

Pixel-art is generated procedurally, then committed as PNGs.

- `gen_biomes.py` — top-down biome ground textures → `qml/images/biomes/*.png`.
- `gen_props.py` — prop + decoration sprites (outlined, transparent) → `qml/images/props/*.png`.
- `preview_blobs.py` — contact sheet of blob styles (design tool; no repo output).

```bash
python3 scripts/art/gen_biomes.py
python3 scripts/art/gen_props.py
```

The blobs themselves are not PNGs — they're drawn at runtime from the seed in
`qml/specimens/BlobSpecimen.qml` (see the `zoo-specimen` skill).

## Translations (`scripts/translations/`)

The six `.ts` files are generated from a translation table (we can't run `lupdate` on all setups).

- `qml_strings.json` — extracted `qsTr()` source strings per QML file (regenerate with `extract.py`
  when strings change — or run `lupdate` in the SDK for the canonical extraction).
- `translations.json` — the source→[fr,de,it,es,fi] table (edit this to fix/add translations).
- `maketrans.py` — writes `translations.json` from an in-script table.
- `gen_ts.py` — emits `translations/harbour-zoo-{fr,de,it,es,fi}.ts` (correct contexts).

```bash
python3 scripts/translations/maketrans.py     # rebuild translations.json
python3 scripts/translations/gen_ts.py         # rebuild the .ts files
```

> The C++ user-facing strings live under the `ZooController` context; QML strings under each file's
> base name. Keep the goofy, dry-British voice when translating (see the `zoo-i18n` / `zoo-voice`
> skills). A native pass is still recommended, especially for `fi`.
