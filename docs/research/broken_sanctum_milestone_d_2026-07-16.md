---
type: evidence
status: active
owner: BK
created: 2026-07-16
source: Milestone D implementation on master and Godot 4.7 runtime validation
topic: Broken Sanctum distributed branches, forward rejoins, tactical cover, minimap state, and terminal-local completion proof
related:
  - ../../.agent/execplans/2026-07-15-fixed-stage-map-enhancement.md
  - ../design/STAGE_MAP_BLUEPRINTS.md
  - ./fixed_stage_baseline_2026-07-16.md
---

# Broken Sanctum Milestone D Evidence — 2026-07-16

## Outcome

Broken Sanctum now uses two distributed optional routes instead of concentrating
both rewards in the old Twin Reliquary hub. The Gate Switch Loop drops into the
Material Crypt and rejoins at Volatile Nave. Recovery Cloister climbs into the
Reliquary Cache and drops forward into Sentry Crossfire.

The required route retains the stage's ascent identity while adding release
descents, a readable transfer room, low traversal-safe cover, a three-role
Fractured Gallery encounter, and a terminal-local final ascent. Earlier enemies
may remain alive when the final-room enemy is cleared.

## Before / After

| Metric | Baseline | Milestone D |
| --- | ---: | ---: |
| required rooms | 9 | 9 |
| required-route enemies | 12 | 12 |
| vertical range | 740 px | 736 px |
| cumulative ascent | 980 px | 1,048 px |
| cumulative descent | 240 px | 312 px |
| meaningful descents | 1 | 3 |
| direction reversals | not targeted | 4 |
| same-hub optional returns | 2 | 0 |
| forward rejoins | 0 | 2 |
| near-limit required transitions | 10 | 0 |
| maximum near-limit chain | 3 | 0 |
| multi-elevation combat rooms | 4 | 4 |

## Authored Room Results

- `bs_shield_choke` uses a main lane, one readable flank level, and an open exit
  recovery instead of a tall blocking wall.
- `bs_gate_switch_loop` keeps the shared switch/gate behavior and adds a visible
  branch cover after the seal. Opening the gate removes the direct-route
  collision and updates the minimap marker.
- `bs_material_crypt` has a gate-entry shelf, reward basin, local recovery rope,
  and a seam-cleared forward rope into `bs_volatile_nave`. The legacy return rope
  remains only for dormant procedural compatibility.
- `bs_volatile_nave` owns the one-way forward-rejoin landing.
- `bs_twin_reliquary_choice` is now a required-route transfer rather than the
  owner of both fixed optional branches.
- `bs_fractured_gallery` deterministically combines Charger, Leaper, and Shooter.
  Its solid line-break cover is low enough for routine traversal, the Leaper
  selects multiple reachable destinations, and the Shooter relation remains
  terrain-readable.
- `bs_recovery_cloister` remains enemy-free, activates its checkpoint, and owns
  the late Reliquary rope.
- `bs_reliquary_cache` has a continuous upper landing and a seam-safe one-way
  hatch that drops inside `bs_sentry_crossfire`.
- `bs_sentry_crossfire` uses two low solid covers, staggered Sentries, transfer
  levels, and projectiles that stop on authored terrain. Sentry startup uses a
  96 px local direction cue rather than a screen-wide trajectory line.
- `bs_exit_ascent` uses four 72 px ascent bands and only its local enemy controls
  the terminal exit.

All changed room resources and the Sanctum catalog/profile use incremented
content versions. The fixed plan resolves twelve enemies. The dormant procedural
catalog still validates across 120 seeds and six observed topologies.

## Continuous Runtime Proof

`tools/validate_broken_sanctum_runtime.gd` instantiates the production stage and
uses the actual `PlayerController`.

- It opens and crosses the authored gate shortcut with real input.
- It continuously traverses every required critical support.
- It drops into Material Crypt, walks its shelves, climbs the seam-cleared rope,
  and updates the minimap at the Nave forward rejoin.
- It activates the Cloister checkpoint, climbs into Reliquary Cache, naturally
  dismounts, crosses the continuous upper platform, and drops inside Sentry
  Crossfire.
- It observes Charger startup/active/recovery, two Leaper destinations, Shooter
  cover relation, Sentry warning/fire, and projectile termination at solid cover.
- It verifies discovered rewards, the active non-terminal checkpoint, gate state,
  current/visited rooms, and player position on the minimap.
- It clears only the Exit Ascent encounter while earlier enemies remain alive
  and confirms the exit changes from locked to ready.

The navigation snapshot builder now includes all authored `StageCheckpoint`
nodes, not only the terminal checkpoint spawned by the runtime content result.
This keeps the active Cloister checkpoint visible after the late optional route.

## Rendered Evidence

The captures are runtime artifacts under
`.codex-runtime/uiux/fixed_stage/` and remain outside source control.

```text
45f04b6602484aa72b4285972b6c202ff31481de737e76c332e0ad93854cf627  sanctum_shield_flank.png
dd57ab9465270fc1583f6683f39c6c87aa84a6964f762d0dfd8f99ce3106862e  sanctum_gate_closed.png
83ceb21104e4922dc14a2a695584552d302264223be83888562566ae01aac146  sanctum_gate_open.png
717df7c97b4ea0f0e1bd8e53cb3c101935f06e8e93012842d4794b8ad72cf5aa  sanctum_material_forward_rejoin.png
c35c8af39552d83b3ca8774e4132478c9d445773fee20ba167ad317e3ac871af  sanctum_transfer.png
cc71bba108b484128e88c2bbdb88c0a97a220c723f94b67ef3c0072aeb5866b3  sanctum_fractured_roles.png
e7dbe42e1ff926fcf96b18bdc6ae33e06b702b0d0757e00fdd1c4cad5922e434  sanctum_recovery_branch.png
fb4a3d57ec32ec697e5375e14fcb58727d15440345332ad35b6e6e5a047db3d9  sanctum_reliquary_forward_rejoin.png
641a39ec9087171fb5cb18f2ea7d50a0d97658eae4d8ca8e17c241e8329b2aa0  sanctum_sentry_crossfire.png
66ef69628ef9337e8d5dfbb55a46f27c51be00cd5bf11bf6251fb83c144c15df  sanctum_sentry_crossfire_compact.png
f6328af2925dd704984a9d73117b90c49abdb91745a3050ee5af87df7dfeecc1  sanctum_exit_ascent.png
```

Rendered inspection confirms that the gate visibly changes state, both optional
routes read as distinct vertical commitments, Sentry warnings remain local,
the final ascent and exit are visible together, and the minimap remains legible
at both 1280×720 and 960×540.

## Verification

```powershell
.\tools\godot.ps1 --path . --headless --import
$env:CARDBORNE_INCLUDE_RANDOM_PLANNER='1'
.\tools\godot.ps1 --path . --headless --script res://tools/validate_broken_sanctum_rooms.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_broken_sanctum_generation.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_broken_sanctum_runtime.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_sanctum_enemy_sentry.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_room_templates.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_curated_stage_plans.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_stage_composition.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_stage_progression_policy.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_stage_minimap_runtime.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_shooter_runtime.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_production_stage.gd
```

## Limitations

- Deterministic fixtures prove traversal and state contracts, not final human
  pacing or commercial-art quality.
- Terrain and actors remain the approved prototype presentation.
- Cross-stage pacing, complete release-matrix validation, production export, and
  final three-stage continuous evidence remain Milestones E and F.
