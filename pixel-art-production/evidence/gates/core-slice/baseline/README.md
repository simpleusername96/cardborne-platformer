---
type: evidence
status: archived
owner: BK
created: 2026-07-27
last_reviewed: 2026-07-28
scope: Pre-pixel runtime, renderer, Web export, and representative gameplay baseline
related:
  - ../../../../../docs/product/vehicle_game_spec.md
  - ../../../../../docs/design/UI_VISUAL_SYSTEM.md
---

# Pre-Pixel Core-Slice Baseline

## Purpose

Preserve the current procedural presentation before any production pixel asset,
atlas, catalog, shader, or runtime switch is added. Later core-slice captures
must use the same viewport, locale, layout seed, gameplay fixtures, and
collision truth.

## Baseline Contract

- Source commit: `672765e99ab378f293a8b28aa8d87223276c0268`
- Source branch: `master`
- Worktree at baseline start: clean
- Godot: `4.7.stable.official.5b4e0cb0f`
- Renderer: `gl_compatibility`
- Viewport: `1280x720`
- Locale: Korean
- Layout seed: `12886704`
- Retained combat batches: `50`
- Capacity: `128` actors, `240` player projectiles, `120` hostile projectiles,
  `192` experience shards, and `96` repeated effects

`baseline.json` records the machine, GPU, validator set, Web-export hashes,
capture dimensions, and capture hashes.

## Validation Result

The following focused validators passed before pixel runtime work:

- combat renderer;
- stage layouts and navigation clearance;
- terrain runtime;
- projectile store and secondary weapons;
- guidebook;
- stage UI layout and Korean/English localization;
- deterministic performance scenarios; and
- connected vehicle run.

The production Web export produced `index.html`, `index.js`, `index.pck`, and
`index.wasm`.

## Capture Set

| Capture | Baseline purpose |
| --- | --- |
| `02-safe-arrival.png` | calm local-camera field and compact HUD |
| `04-three-cycles-threat-radar.png` | ordinary mixed combat ownership |
| `03-maximum-pressure-xp.png` | maximum ordinary pressure and XP saturation |
| `07-stage-boss-startup.png` | boss startup and exact telegraph ownership |
| `20-collision-01-stage-1-default.png` | visual geometry against collision truth |

`baseline-contact-sheet.png` is review convenience only. The five individual
captures and hashes are the comparison authority.

## Boundary

This evidence does not approve the existing art direction. It preserves current
behavior, density, geometry, UI, and renderer cost so the pixel migration cannot
quietly improve its result by changing gameplay or reducing workload.
