---
type: plan
status: active
owner: BK
created: 2026-08-04
last_reviewed: 2026-08-04
execution_state: in_progress
topic: Replace code-drawn gameplay assets with shared authored PNG assets
scope: Gameplay world surfaces, walls, world-space combat cues, manifests, consumers, workbench evidence, and obsolete gameplay recipe retirement
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/design/visual-replacement-workbench/README.md
---

# Rasterize Code-Drawn Gameplay Assets

## Outcome

Replace reusable gameplay assets currently authored through GDScript draw
commands or procedural visual recipes with ten shared production PNGs. Runtime
code may place, rotate, scale, tint, stretch, crop, fade, batch, and animate
those images from live state. Collision, topology, telegraph dimensions,
readiness, and gameplay values remain code truth.

Existing UI Theme, UI chrome, HUD controls, upgrade UI, minimap UI, report UI,
and their code-native visual implementation are restored and remain unchanged.

## Why / Context

The approved 49-PNG gameplay pack covers persistent actors, pickups,
facilities, projectiles, and EMP, but field presentation, wall presentation,
and several reusable world-space combat cues are still drawn as visible
polygons, lines, circles, or flat meshes. BK directed that these code-created
gameplay assets be recreated as images. An earlier interpretation incorrectly
included UI; that scope was rejected and explicitly removed.

No additional user approval is required during this plan.

## Scope

### In scope

- Update the gameplay media boundary in `docs/design/VISUAL_SYSTEM.md`.
- Add exactly ten shared gameplay PNGs: three world-presentation assets and
  seven world-space combat-cue assets.
- Extend the gameplay manifest from 49 to 59 entries.
- Replace code-drawn gameplay asset identities with raster-backed consumers.
- Remove obsolete gameplay visual recipe code after all real and validator
  consumers migrate.
- Publish rendered AS-IS versus applied TO-BE evidence in the existing visual
  replacement workbench.
- Run import, focused validation, Web export, runtime capture, and a diff-scoped
  quality audit once after the complete switch.

### Non-scope

- Any change to `vehicle_stage_theme.tres`, UI chrome, UI image manifests or
  providers, HUD layout/controls, upgrade cards, minimap UI, report UI, menus,
  modal surfaces, typography, localization, or focus behavior.
- Regenerating the approved 49 gameplay PNGs.
- Gameplay balance, combat rules, encounter logic, collision, navigation,
  input, save data, or small cosmetic effect packs.
- Baking live geometry, text, numbers, coordinates, or state values into PNGs.

## Assumptions

- The mandatory authority pair is `docs/design/VISUAL_SYSTEM.md` plus
  `docs/design/cardborne-universal-art-style-reference.png`, SHA-256
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- The canonical PNG is supplied to ImageGen as the actual image reference.
- The workbench records this preflight as `visual_authority_evidence`.
- One image may serve multiple gameplay roles through runtime tint, scale,
  rotation, and patch stretching.

## Proposed Design

Use one gameplay rule: **fixed visible asset identity is raster; live gameplay
truth is runtime data**.

| Semantic ID | Target path | Canvas | Runtime-owned truth |
| --- | --- | ---: | --- |
| `world/surface_panel_9` | `art/visuals/production/gameplay/world/presentation/world_surface_panel_9.png` | 288×288 | Field topology and cell dimensions |
| `world/service_rail_tile` | `art/visuals/production/gameplay/world/presentation/world_service_rail_tile.png` | 288×48 | Placement, orientation, and length |
| `world/wall_segment_9` | `art/visuals/production/gameplay/world/presentation/world_wall_segment_9.png` | 192×96 | Wall collision, orientation, and length |
| `cue/health_bar_frame_9` | `art/visuals/production/gameplay/effects/cues/cue_health_bar_frame_9.png` | 96×16 | World-space actor health ratio |
| `cue/ring` | `art/visuals/production/gameplay/effects/cues/cue_ring.png` | 128×128 | Radius, role tint, readiness, and alpha |
| `cue/beam_strip_9` | `art/visuals/production/gameplay/effects/cues/cue_beam_strip_9.png` | 128×32 | Corridor length, width, direction, and tint |
| `cue/diamond_marker` | `art/visuals/production/gameplay/effects/cues/cue_diamond_marker.png` | 64×64 | Marker position, rotation, scale, and tint |
| `cue/support_timer_segment` | `art/visuals/production/gameplay/effects/cues/cue_support_timer_segment.png` | 64×64 | Segment count, rotation, readiness, and tint |
| `cue/disk_mask` | `art/visuals/production/gameplay/effects/cues/cue_disk_mask.png` | 128×128 | Live radius, readiness, tint, and alpha |
| `cue/crosshair` | `art/visuals/production/gameplay/effects/cues/cue_crosshair.png` | 96×96 | Aim position, scale, and state tint |

Every image uses broad matte planes, one dark perimeter, at most one restrained
hard inset or highlight, and no gradient, glow, bevel, noise, dots, particles,
nested border, or ornamental corner. The complete ten-asset family is generated
in one batch with the canonical sheet supplied as an actual image reference.

## Milestones

### 1. Authority and exact inventory

- [x] Correct the scope to gameplay assets only and restore all UI files.
- [ ] Update the canonical gameplay media boundary and exact 59-entry manifest
      contract without changing the existing UI contract.
- [ ] Record the ten assets, dimensions, consumers, and retire paths in the
      existing workbench model.

### 2. One gameplay asset-generation batch

- [x] Capture representative rendered AS-IS gameplay surfaces before switching.
- [x] Generate the world/combat family sheet with the canonical reference.
- [x] Reject the first beveled/gradient draft and normalize the flat v2 ten-file
      set with transparent corners and exact canvases.
- [ ] Record source hashes, normalized hashes, prompt, and target mappings.

### 3. Gameplay production switch

- [ ] Extend the gameplay manifest from 49 to 59 assets.
- [ ] Switch field surface, wall presentation, actor health frame, ring, area,
      corridor, beam, timer, crosshair, commit, target, and vulnerability cues
      to raster-backed consumers while preserving live dimensions.
- [ ] Remove stale gameplay recipe IDs and delete recipe-only gameplay visual
      files after `rg` proves no production or validator consumer remains.
- [ ] Verify that no UI file differs from the pre-task HEAD.

### 4. Workbench publication

- [ ] Add one gameplay follow-up unit with rendered AS-IS evidence, ten exact
      TO-BE files, hashes, consumers, and applied status.
- [ ] Rebuild `inventory.json` and `index.html` and confirm all local links.

### 5. One final validation and closeout

- [ ] Validate PNG headers, dimensions, alpha, hashes, manifest count, and
      provider resolution.
- [ ] Run Godot import once, focused world/combat/coverage validators, Web
      export, and the relevant runtime capture matrix.
- [ ] Verify no missing textures, visual corruption, collision drift, or draw
      batch regression.
- [ ] Run the diff-scoped codebase quality audit, commit coherent task-owned
      changes, move durable decisions into the canonical spec/evidence, and
      delete this completed ExecPlan.

## Test Plan

Run only corruption-prevention checks during implementation. After the complete
switch and report build, run the full relevant suite once:

```powershell
.\tools\validation\validate_cardborne_visual_authority.ps1
.\tools\design\build_visual_replacement_workbench.ps1 -Check
.\tools\validation\validate_visual_replacement_workbench.ps1
.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_semantic_asset_provider.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_visual_asset_coverage.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_world_visuals.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_combat_renderer.gd
.\tools\export_web.ps1
```

## Rollback / Safety

- UI files are out of scope and must hash-identically match HEAD.
- Do not delete a gameplay recipe owner until no production or validator
  consumer remains.
- Do not change collision, topology, values, or localization while replacing
  gameplay presentation.
- Keep the rejected and accepted generation sources outside production; only
  the normalized ten PNGs enter the gameplay pack.

## Risks

- Patch-stretched cue textures can distort live geometry; validate supported
  widths and radii in runtime captures.
- Textured retained batches can change performance; preserve shared batching
  and validate draw-call budgets.
- Chroma removal can leave fringe; reject any non-transparent corner or keyed
  edge contamination.

## Open Questions

None. UI is explicitly excluded.

## Decision Notes

- 2026-08-04: The user explicitly corrected the scope to gameplay assets made
  in code. All UI changes and generated UI files were reverted or removed.
- 2026-08-04: Existing 49 gameplay PNGs remain approved and unchanged.
- 2026-08-04: Ten shared assets replace the remaining reusable code-drawn
  gameplay identity without creating per-state duplicates.
- 2026-08-04: No user approval interlock is permitted inside this plan.
