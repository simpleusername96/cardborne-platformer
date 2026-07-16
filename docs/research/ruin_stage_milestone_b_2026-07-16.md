---
type: evidence
status: active
owner: BK
created: 2026-07-16
source: Milestone B implementation on master and Godot 4.7 runtime validation
topic: Ruin Approach authored blockout, traversal, encounter, forward-rejoin, minimap, and terminal-policy proof
related:
  - ../../.agent/execplans/2026-07-15-fixed-stage-map-enhancement.md
  - ../design/STAGE_MAP_BLUEPRINTS.md
  - ./fixed_stage_baseline_2026-07-16.md
---

# Ruin Approach Milestone B Evidence — 2026-07-16

## Outcome

Ruin Approach is no longer a monotonic 80 px staircase. The authored route now
alternates 40 px routine transfers with 64 px challenge transfers, reaches an
early shooter peak, descends twice through the broken bridge, and rebuilds
height through the charge lane and terminal ascent.

The cache route now climbs into `lr_broken_bridge` instead of returning to the
choice hub. The bridge-side one-way landing also fills the main-route seam, so
the same spatial opening supports both the required jump and the optional rope
without collision overlap.

## Before / After

| Metric | Baseline | Milestone B |
| --- | ---: | ---: |
| required rooms | 8 | 8 |
| required-route enemies | 8 | 8 |
| vertical range | 720 px | 784 px |
| cumulative ascent | 720 px | 944 px |
| cumulative descent | 0 px | 160 px |
| meaningful descents | 0 | 2 |
| direction reversals | 0 | 2 |
| same-hub optional returns | 1 | 0 |
| forward rejoins | 0 | 1 |
| near-limit required transitions | 9 | 0 |
| maximum near-limit chain | 3 | 0 |
| multi-elevation combat rooms | 2 | 2 |

## Authored Room Results

- `lr_rise_steps`: five broad supports create two elevation bands with
  alternating 40/64 px transfers and three recovery anchors.
- `lr_patrol_gallery`: the same comfort language is transformed into a
  multi-height Walker/Shooter encounter instead of a single raised floor.
- `lr_shooter_overlook`: safe lower entry, solid hanging cover, and an exposed
  upper response are separate collision lanes. The cover ray resolves to
  `CoverWall`; the upper ray remains open.
- `lr_lower_upper_choice`: the lower route is a flat enemy lane; the upper route
  is precision movement with the visible reward. The right edge remains an open
  shaft for the forward rope.
- `lr_destructible_cache`: controlled drop, reward pocket, and a 720 px return
  rope terminate at the next required room.
- `lr_broken_bridge`: two 80 px downward transfers, a recovery basin, a visible
  landing, and the optional one-way rejoin replace the prior upward gap.
- `lr_charge_lane`: the fixed seed now allocates a Charger. Two reachable side
  ledges interrupt the charge and lead back to the 64 px re-engage landing.
- `lr_exit_ascent`: three known 64 px transfers lead to the gate; only the two
  terminal-room enemies control exit eligibility.

All changed room resources incremented `content_version`, and the Lower Ruins
catalog incremented from version 3 to 4.

## Continuous Runtime Proof

`tools/validate_ruin_stage_runtime.gd` uses the production stage and the actual
`PlayerController`.

- It presses `move_right` and `jump` continuously from the start shelf through
  all nineteen required support transitions to the exit room.
- It performs the optional route with actual crouch+jump one-way drop input,
  traverses the cache floor, enters climb mode from below, climbs the complete
  rope, and dismounts in `lr_broken_bridge`.
- It observes Walker movement and reversal plus a complete Charger
  warning/charge/recovery cycle.
- It verifies the Shooter lower ray is blocked, the upper response is exposed,
  a shot is emitted, and the covered player takes no damage. The shared
  `validate_shooter_runtime.gd` fixture separately proves the projectile emits
  exactly one terrain contact and terminates.
- It visits choice, cache, and bridge in sequence and verifies minimap current,
  visited, and discovered-reward state.
- It defeats only the terminal-room enemies, leaves earlier enemies alive, and
  verifies that the exit becomes eligible.

## Rendered Evidence

The captures are runtime artifacts under
`.codex-runtime/uiux/fixed_stage/` and remain outside source control.

```text
1865a3fcf6027ca27b2548f5221e466b0c960cad97b6f16923e1df6eccceeade  ruin_shooter_split.png
c037b3fa55b0147dee420bca2d406231053de257dadb6c2cbaad2dfd56eb3e9b  ruin_route_choice.png
c815ea4476e801c4539cc1396605a9f1e18a84946436ededa3fb3fcdf88c0634  ruin_optional_forward_rejoin.png
a8428c970489f1b3ef77be80c91eb4f5938a531f79f55710533de61aad2e002a  ruin_broken_descent.png
b5e29d5bf5548913c5b89b97ccafd30761e6d087e708d6d061c98d1dfac4a329  ruin_charge_reengage.png
fb17e6847a9b2ac9f3ad167a17b1c07d76044fd9580cec559856d655132e340f  ruin_exit_release.png
```

Rendered inspection confirms:

- the shooter staircase and upper/lower response fit one default-camera view;
- the cache rope visibly continues into the next room instead of folding back
  into the choice hub;
- the broken descent and its recovery landing are visible before commitment;
- the Charger lane shows both side ledges and the re-engage floor;
- the exit ascent contains no new mechanic or safe-intermission facility;
- the minimap offsets follow the assembled room waveform.

## Verification

```powershell
.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --script res://tools/validate_room_templates.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_curated_stage_plans.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_stage_composition.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_ruin_stage_runtime.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_shooter_runtime.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_stage_progression_policy.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_production_stage.gd
```

Focused optional-route rerun:

```powershell
$env:RUIN_RUNTIME_CASE = "optional"
.\tools\godot.ps1 --path . --headless --script res://tools/validate_ruin_stage_runtime.gd
Remove-Item Env:RUIN_RUNTIME_CASE
```

## Limitations

- This proves deterministic input traversal and runtime contracts, not a human
  fun or final tuning verdict.
- Terrain and actors remain the approved prototype presentation rather than
  final commercial world art.
- Flooded Works and Broken Sanctum still retain their baseline target failures
  until Milestones C and D.
