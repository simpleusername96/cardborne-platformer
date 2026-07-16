---
type: evidence
status: active
owner: BK
created: 2026-07-16
source: Fixed V6 room scenes, curated plans, production runtime validators, and real OpenGL captures
topic: Cross-stage encounter, camera, pacing, silhouette, warning, minimap, and facility-separation review
related:
  - ../../.agent/execplans/2026-07-15-fixed-stage-map-enhancement.md
  - ../design/STAGE_MAP_BLUEPRINTS.md
  - ./ruin_stage_milestone_b_2026-07-16.md
  - ./flooded_stage_milestone_c_2026-07-16.md
  - ./broken_sanctum_milestone_d_2026-07-16.md
---

# Cross-stage Map Cohesion Evidence — 2026-07-16

## Outcome

The three normal stages now share the same traversal, projectile, mobile-enemy,
completion, minimap, and facility-separation contracts without converging on one
map shape.

| Stage | Spatial verb | Range | Ascent | Descent | Reversals | Forward rejoins |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Ruin Approach | broken ascent | 784 px | 944 px | 160 px | 2 | 1 |
| Flooded Works | basin then pump up | 896 px | 256 px | 896 px | 1 | 1 |
| Broken Sanctum | distributed reversal | 736 px | 1,048 px | 312 px | 4 | 2 |

All three have zero same-hub optional returns, zero near-limit required
transitions, and distinct collision silhouettes.

## Encounter And Terrain Audit

`tools/validate_cross_stage_map_cohesion.gd` generates and assembles all three
accepted plans, then checks only encounter anchors that are actually allocated
in production.

- All 30 active enemy placements have a non-empty `terrain_relation`.
- Every active combat room has an authored recovery inside its first 240 px.
- No active enemy anchor enters that protected entry buffer.
- Every active room remains free of Forge and Merchant interactables.
- No active room retains dead `camera_id` metadata.
- Ruin remains ascent-led, Flooded remains descent-led, and Sanctum retains four
  reversals and two distributed optional routes.

The room-intention and rhythm matrix is current in
`docs/design/STAGE_MAP_BLUEPRINTS.md`. It records a teach/transform/test/release
sequence for each stage without adding runtime schema fields for design prose.

## Warning And Projectile Audit

Ordinary enemy startup now communicates facing or destination without drawing a
full attack path.

| Enemy | Runtime cue |
| --- | --- |
| Shooter | 96 px locked-direction cue |
| Sentry | 96 px locked-direction cue |
| Charger | 128 px local direction cue |
| Shield Guard | 118 px local attack cue |
| Leaper | 48 px destination marker at the selected landing |
| Summon Node | local spawn-position marker |

Shooter and Sentry projectiles still use their complete authored range, but the
visual warning no longer exposes that range. Solid terrain and declared cover
terminate basic projectiles. Boss attacks keep their separate
startup/active/recovery warning contract.

## Camera And Commitment Audit

The production camera remains player-owned and unchanged. The authored room
geometry, preview/read markers, safe entry bands, and recovery anchors make
irreversible drops and encounter commitments visible with the default camera.
There is no parallel room-camera system or inactive focus metadata.

Representative evidence includes Ruin's broken descent and charge re-engage,
Flooded's basin preview and pump ascent, and Sanctum's gate, optional rejoins,
crossfire, and terminal ascent.

## Pacing Note

The generated required sequences have maximum consecutive non-combat spans of
two rooms in Ruin, one in Flooded, and two in Sanctum. These spans are not empty
walkways:

- Ruin uses climb teaching, route choice, controlled descent, or release.
- Flooded uses hazard timing, rope transfer, route choice, or shelter arrival.
- Sanctum uses gate interaction, hazard timing, transfer, recovery, or branch
  clues.

The deterministic traversal fixtures hold active movement input rather than
waiting through authored dead time. They report zero repeated near-limit chains,
failed required walls, stuck mobile-enemy cycles, and projectile-through-cover
cases. Exact human hesitation and perceived fun remain observational tuning, not
a value that can be honestly inferred from scripted frame counts.

## Completion, Minimap, And Facility Boundary

- HUD copy does not consume `get_remaining_enemy_count()` and contains no global
  “Defeat N remaining” objective.
- Ruin and Sanctum use terminal-local encounter state; Flooded uses actual
  shelter arrival.
- The minimap excludes enemies and hazards, keeps hidden rewards undiscovered,
  updates gate/checkpoint/reward/exit state, and uses a single uniform scale per
  stage.
- Same-stage retry preserves exploration knowledge; new stage/run signatures
  reset it.
- Normal stages contain no Forge or Merchant. Safe Intermission retains exactly
  one of each.

## Rendered Evidence

The following runtime artifacts remain outside source control:

```text
3311d9774db171a8ab04783ef380de3256a05c3fc2a8f6d4669ade04f4080e68  stage_silhouette_comparison.png
70f332a25afe43f159139a87ff823115c4066050e3991bd6b0acc68db3cf9570  ruin_charge_reengage.png
65a7c1b5c00715967b3210f3df0ee945e141ebb67a3b97498a47450f48a54b2a  flooded_pump_ascent.png
cc2ab2e81dd7a7fed3fac43f657282ddfb0e1cc0be793c0c2777e01ec4c90432  sanctum_fractured_roles.png
641a39ec9087171fb5cb18f2ea7d50a0d97658eae4d8ca8e17c241e8329b2aa0  sanctum_sentry_crossfire.png
```

The collision comparison is projected from the actual assembled room bodies,
not from the concept blueprint. It shows Ruin's broken climb, Flooded's deep
basin, and Sanctum's two distributed vertical branches.

## Verification

```powershell
.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --script res://tools/validate_cross_stage_map_cohesion.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_stage_composition.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_curated_stage_plans.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_ruin_stage_runtime.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_flooded_stage_runtime.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_broken_sanctum_runtime.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_shooter_runtime.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_sanctum_enemy_sentry.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_stage_progression_policy.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_stage_minimap_runtime.gd
```

## Remaining Release Work

Milestone F still owns the complete release matrix, production build/export,
built-app interaction, final capture inventory, and release-level completion
record.
