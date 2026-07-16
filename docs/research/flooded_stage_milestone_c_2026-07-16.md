---
type: evidence
status: active
owner: BK
created: 2026-07-16
source: Milestone C implementation on master and Godot 4.7 runtime validation
topic: Flooded Works basin descent, pump ascent, forward rejoin, hazard reset, minimap, and arrival-policy proof
related:
  - ../../.agent/execplans/2026-07-15-fixed-stage-map-enhancement.md
  - ../design/STAGE_MAP_BLUEPRINTS.md
  - ./fixed_stage_baseline_2026-07-16.md
---

# Flooded Works Milestone C Evidence — 2026-07-16

## Outcome

Flooded Works now forms a readable descent-and-recovery waveform: the entrance
previews the pump landmark, the required route descends through a bidirectional
rope shaft, poison timing floor, and leaper basin, then rebuilds height through
the pump gallery before releasing into an enemy-free shelter.

The Sunken Cache no longer folds back into the route-choice hub. Its return rope
rejoins at the next required Pump Gallery room. A separate compatibility socket
keeps the dormant procedural generator valid without changing the fixed-stage
topology.

## Before / After

| Metric | Baseline | Milestone C |
| --- | ---: | ---: |
| required rooms | 7 | 7 |
| required-route enemies | 10 | 10 |
| vertical range | 760 px | 896 px |
| cumulative ascent | 800 px | 256 px |
| cumulative descent | 40 px | 896 px |
| meaningful ascents | 8 | 4 |
| meaningful descents | 1 | 12 |
| same-hub optional returns | 1 | 0 |
| forward rejoins | 0 | 1 |
| maximum near-limit chain | 3 | 0 |
| multi-elevation combat rooms | 3 | 3 |

## Authored Room Results

- `fw_flooded_entry` presents a high safe shelf and the distant pump silhouette
  before the first committed descent.
- `fw_rope_shaft` uses one required rope that supports actual top-to-bottom and
  bottom-to-top input, one-way mounting, dismounting, and lateral drift.
- `fw_poison_timing` provides a stable wait pad and shows the next safe landing
  before the hazard window.
- `fw_leaper_basin` previews the drop and gives the Leaper multiple reachable
  landing surfaces rather than one repeated synthetic arc.
- `fw_lower_upper_choice` separates a dry precision/reward line from a slower
  wet-management line.
- `fw_sunken_cache` has a controlled basin, reward pocket, recovery supports,
  and a forward rope into `fw_pump_gallery`.
- `fw_pump_gallery` combines three 64 px ascent bands with Walker, Charger,
  Leaper, Shooter, solid projectile cover, and recovery floors.
- `fw_exit_shelter` remains facility-free. Its exit starts locked and becomes
  ready only after the player actually enters the shelter; earlier enemies may
  remain alive.

All changed room resources and the Flooded catalog/profile use incremented
content versions. Fixed-stage content resolves to ten enemies, while the
procedural 7+1 graph still validates across 300 deterministic seeds.

## Continuous Runtime Proof

`tools/validate_flooded_stage_runtime.gd` instantiates the production stage and
uses the actual `PlayerController`.

- It continuously traverses all required supports using movement and jump input.
- It crosses the required rope in both directions and checks one-way top
  mount/dismount behavior.
- It enters the optional cache, reaches its rewards, climbs the complete return
  rope, and rejoins the Pump Gallery.
- It drives a real poison vent active, triggers checkpoint retry, and verifies
  the hazard returns to its deterministic non-damaging warning state.
- It observes Pump Gallery mobile-enemy cycles, multiple Leaper destinations,
  and a real Shooter projectile stopping at the authored cover.
- It visits the choice, cache, pump, and shelter rooms and verifies minimap
  current/visited/reward/checkpoint state.
- It confirms the shelter exit is locked at stage start, then unlocks on
  terminal-room arrival while prior enemies remain alive.

## Rendered Evidence

The captures are runtime artifacts under
`.codex-runtime/uiux/fixed_stage/` and remain outside source control.

```text
a56500d14fc1b7d39181a53143a9c8541fb15694c7a34dd7ace2099482f96138  flooded_descent_preview.png
f7723e91bf6f01abc6670ed90dd5ccbdb480bebd691fd91cf9626145b87e75c2  flooded_rope_descent.png
3504212e8abcd72aa6a02077aa937747e96175573dc8cceb119515f6469696a9  flooded_leaper_commitment.png
c49fc0a951ed7eba3e53665bb2fc18fbfa00ea15517010bdaca3b6681d2e58c5  flooded_route_choice.png
d0280b7c82f60a8b96672481c7cbdc6ae5a0fc6a9b3a3a10eda338c3b0f73e2e  flooded_optional_cache.png
c879de4e4de993fe4382f1bb6f2d43bdb8d2394f386d48a8f1645924e55212d1  flooded_pump_ascent.png
41b93c52e7aa9c2761eb0382a8b6feb748d4a61907a1948b7cdc030cff93d023  flooded_exit_release.png
```

Rendered inspection confirms that the entry HUD remains in navigation state,
the route split and optional reward are legible in one view, the pump combines
multiple elevations and threat roles, and the shelter capture contains both the
release vista and ready exit.

## Verification

```powershell
.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --script res://tools/validate_flooded_works_rooms.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_flooded_generation.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_flooded_stage_runtime.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_flooded_hazard_runtime.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_flooded_enemy_runtime.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_stage_progression_policy.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_stage_minimap_runtime.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_shooter_runtime.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_production_stage.gd
```

## Limitations

- Deterministic fixtures prove traversal and state contracts, not final human
  pacing or commercial-art quality.
- Terrain and actors remain the approved prototype presentation.
- Broken Sanctum still retains its baseline same-hub branches and near-limit
  chains until Milestone D.
