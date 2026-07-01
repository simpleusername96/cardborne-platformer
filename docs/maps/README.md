# Map Preview Guide

Map preview SVGs are generated from `data/design/first_slice/stage_layouts.json`.

Run:

```powershell
python tools/generate_map_previews.py
```

Generated previews are written to `docs/maps/generated/`.

The SVG files are the canonical generated previews. PNG files in the same folder are review-friendly exports from the SVGs, kept so the maps can be previewed in tools that do not render SVG directly.

These previews are design aids. Godot `.tscn` scenes become the runtime source once stages are implemented.
