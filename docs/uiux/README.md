# UI/UX Wireframes

UI/UX skeleton data lives in `data/design/first_slice/ui_screen_skeletons.json`.

Run:

```powershell
python tools/generate_uiux_wireframes.py
```

Generated SVG wireframes are written to `docs/uiux/generated/`.

The SVG files are the canonical deterministic skeletons. PNG files in the same folder are review-friendly exports from the SVGs, kept so the screens can be previewed in tools that do not render SVG directly.
