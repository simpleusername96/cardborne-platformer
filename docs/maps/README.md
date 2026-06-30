# Map Preview Guide

Map preview SVGs are generated from `data/design/first_slice/stage_layouts.json`.

Run:

```powershell
python tools/generate_map_previews.py
```

Generated previews are written to `docs/maps/generated/`.

These previews are design aids. Godot `.tscn` scenes become the runtime source once stages are implemented.
