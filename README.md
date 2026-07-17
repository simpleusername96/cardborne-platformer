# Cardborne

Godot 4.7 GDScript project being rebuilt as an isometric action RPG: a
two-dimensional top-down combat simulation presented with the existing
flat-color drowned-ruin art direction.

## Current State

The former action-platform runtime was deliberately removed. The project boots an
empty reset scene while the first combat proof is implemented. The accepted art,
font, UI shapes, illustrations, backgrounds, and visual references remain under
`art/` and `docs/design/references/`.

The active implementation plan is
`.agent/execplans/2026-07-17-isometric-action-rpg-pivot.md`. The removed runtime is
recoverable from Git commit `7cc069c` for targeted reference only.

## Local Godot

```powershell
.\tools\godot.ps1 --version
.\tools\godot.ps1 --path . --editor
.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --quit-after 2
```

Use `docs/README.md` for current document authority and retained references.
