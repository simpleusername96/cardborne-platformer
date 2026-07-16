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
e5d491089405021d35f43610271890a8ab07d644297fcb7bc8d43acb68851526  stage_silhouette_comparison.png
b6a513dd03c8d882bb7d0ef6a1e590cf95a074d97c0b11d564b88c326a4c446c  ruin_charge_reengage.png
553fc7f46feeadfa48a663420a1afa963bd0fd2f8c9877673c0b2230fb617724  flooded_pump_ascent.png
3c67b5e240988f408c903ad1a291af8518ed7953216c7c316c0253fecfec2636  sanctum_fractured_roles.png
493b46099896ef69b643cc48fce4c66003f819112886fbc956155cf41c19837e  sanctum_sentry_crossfire.png
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

## Release Closure

Milestone F is complete. The full `81/81` release matrix, final capture inventory,
Godot 4.7 Web export, fastrun `codex`-lane built-app interaction, and retained
limits are recorded in
[Fixed Stage Map Enhancement](../release/FIXED_STAGE_MAP_ENHANCEMENT.md).
