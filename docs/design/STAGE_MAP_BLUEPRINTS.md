---
type: spec
status: active
owner: BK
created: 2026-07-16
last_reviewed: 2026-07-16
canonical_for: Construction topology, height waveform, terminal policy, and minimap layer for the three fixed normal stages
source: Active fixed-stage ExecPlan, current curated plans, room resources/scenes, baseline metrics, and approved visual direction
related:
  - ../../.agent/execplans/2026-07-15-fixed-stage-map-enhancement.md
  - ./2D_PLATFORMER_MAP_DESIGN_GUIDELINE.md
  - ./MAP_AUTHORING_PIPELINE_CONTRACT.md
  - ../research/fixed_stage_baseline_2026-07-16.md
---

# Fixed Stage Construction Blueprints

## Purpose

Translate the approved dense, folded side-view direction into source-linked
construction targets. These blueprints own stage topology, room sequence, macro
height waveform, branch/rejoin placement, terminal policy, landmarks, and the
coarse minimap layer. Room scenes and resources still own collision, sockets,
anchors, and runtime content.

Rendered construction views:

- [Ruin Approach](./visuals/stage-map-blueprint-ruin-approach.png)
- [Flooded Works](./visuals/stage-map-blueprint-flooded-works.png)
- [Broken Sanctum](./visuals/stage-map-blueprint-broken-sanctum.png)

Regenerate them with:

```powershell
.\tools\godot.ps1 --path . --script res://tools/generate_fixed_stage_blueprints.gd
```

## Scope

- the active 8/7/9 required-room fixed plans;
- the active 1/1/2 optional rooms;
- forward rejoin and intra-room shortcut targets;
- target height waveform and room rhythm;
- terminal completion policy;
- minimap envelope and marker reveal rules.

## Non-Goals

- adding runtime rooms merely to match concept-art chamber counts;
- defining final world illustration or terrain asset count;
- changing player movement values, enemy roster, reward IDs, or run cadence;
- creating a second collision representation for the minimap.

## Requirements

### Shared construction rules

1. Preserve current stable room IDs and first-pass room counts.
2. Keep the required route clearable by the baseline Traveler.
3. Optional paths forward-rejoin; a complete return to the origin needs explicit
   evidence and is not used in these targets.
4. `required_route` means main traversal, not mandatory enemy defeat.
5. Ruin and Sanctum exits use `terminal_encounter`; Flooded uses `arrival`.
6. Every room contains two to four named gameplay beats without automatically
   becoming multiple runtime rooms.
7. Every stage has at least three landmarks that are visible again from a later
   height or direction.
8. The minimap derives room envelopes and edges from the assembled plan. All
   room envelopes start dark, visited rooms brighten, the current room/player
   receive a shape-plus-accent state, and hidden reward markers reveal only after
   room discovery.

### Landmark recurrence

| Stage | Landmark | First read | Later changed read |
| --- | --- | --- | --- |
| Ruin | broken arch | `lr_start_shelf` | below and behind the player from `lr_broken_bridge` |
| Ruin | shooter watchtower | `lr_patrol_gallery` | crossed at equal height from `lr_lower_upper_choice` |
| Ruin | gate beacon | `lr_shooter_overlook` | dominant foreground target in `lr_exit_ascent` |
| Flooded | flooded intake | `fw_flooded_entry` | high overhead after the basin descent |
| Flooded | pump spine | `fw_rope_shaft` | crossed vertically inside `fw_pump_gallery` |
| Flooded | shelter lamp | `fw_lower_upper_choice` | close navigation target after the final climb |
| Sanctum | seal gate | `bs_breach_entry` | opened shortcut seen from `bs_volatile_nave` |
| Sanctum | fractured rose window | `bs_gate_switch_loop` | crossed from below in `bs_fractured_gallery` |
| Sanctum | reliquary crown | `bs_twin_reliquary_choice` | reached from the opposite side through the late branch |

### Room-count decision

The target topology is achievable with the current active templates by adding
sub-chambers and gameplay beats inside their existing boundaries. No new runtime
room, stable ID, or active-room-count increase is approved by this blueprint
pass. Any future increase requires measured timing or traversal evidence and a
separate owner decision.

### Terminal policies

| Stage | Policy | Blocking fact | Explicitly not blocking |
| --- | --- | --- | --- |
| Ruin Approach | `terminal_encounter` | enemies allocated to `lr_exit_ascent` | patrol, shooter, charge, optional enemies |
| Flooded Works | `arrival` | physical interaction at `fw_exit_shelter` | every normal-stage enemy count |
| Broken Sanctum | `terminal_encounter` | enemies allocated to `bs_exit_ascent` | shield, gate, gallery, crossfire, optional enemies |

## Ruin Approach

Spatial thesis: climb through exposed ruins, read cover and height, descend
through the broken gallery, then rebuild height toward the gate.

Target waveform:

> safe shelf ↑ teach climb ↑ patrol transform ↑ shooter peak ↓ choice
> ↓ broken-gallery release ↑ charge combine ↑ terminal ascent

Target time: 6–8 minutes. Landmarks: broken arch, shooter watchtower, gate
beacon.

### Pre-enhancement baseline

```text
start → rise → patrol → shooter → choice → broken bridge → charge → exit
                                     ↓
                                  cache
                                     ↑
                                  choice
```

### Implemented graph (fixed V6)

```text
start → rise → patrol → shooter → choice → broken bridge → charge → exit
                                     ↘           ↑
                                       cache ────┘
```

### Target edges

| Role | From | To | Source owners |
| --- | --- | --- | --- |
| critical | `lr_start_shelf` | `lr_rise_steps` | `lr_start_shelf.tres`, `lr_rise_steps.tres` |
| critical | `lr_rise_steps` | `lr_patrol_gallery` | `lr_rise_steps.tres`, `lr_patrol_gallery.tres` |
| critical | `lr_patrol_gallery` | `lr_shooter_overlook` | `lr_patrol_gallery.tres`, `lr_shooter_overlook.tres` |
| critical | `lr_shooter_overlook` | `lr_lower_upper_choice` | `lr_shooter_overlook.tres`, `lr_lower_upper_choice.tres` |
| critical | `lr_lower_upper_choice` | `lr_broken_bridge` | `lr_lower_upper_choice.tres`, `lr_broken_bridge.tres` |
| optional | `lr_lower_upper_choice` | `lr_destructible_cache` | choice/cache branch sockets |
| return | `lr_destructible_cache` | `lr_broken_bridge` | new bridge optional-rejoin socket |
| critical | `lr_broken_bridge` | `lr_charge_lane` | bridge/charge sockets |
| critical | `lr_charge_lane` | `lr_exit_ascent` | charge/exit sockets |

### Room construction matrix

| Room/source | Rhythm | Gameplay beats | Marker/reveal |
| --- | --- | --- | --- |
| `lr_start_shelf` — `scenes/rooms/lower_ruins/LrStartShelf.tscn` | preview | safe spawn, landmark preview | start/current at entry |
| `lr_rise_steps` — `LrRiseSteps.tscn` | teach | approach, two-band climb, lower recovery | room visit |
| `lr_patrol_gallery` — `LrPatrolGallery.tscn` | transform | observe, upper/lower transfer, punish | NPC/reward only after visit |
| `lr_shooter_overlook` — `LrShooterOverlook.tscn` | first peak | safe entry, lower cover, exposed flank | room visit |
| `lr_lower_upper_choice` — `LrLowerUpperChoice.tscn` | decision | route preview, choose, commit | branch edge after visit |
| `lr_destructible_cache` — `LrDestructibleCache.tscn` | optional | controlled drop, blocker, reward, forward exit | cache after visit; dim after claim |
| `lr_broken_bridge` — `LrBrokenBridge.tscn` | release/transform | vista, controlled descent, optional rejoin, recovery | room visit |
| `lr_charge_lane` — `LrChargeLane.tscn` | combine | read charge, side escape, re-engage | room visit |
| `lr_exit_ascent` — `LrExitAscent.tscn` | final test | known climb, local priority, recovery, gate | exit always; lock badge until local clear |

## Flooded Works

Spatial thesis: descend into the flooded pressure floor, survive timing and
leaper control, then climb the pump spine into a safe shelter.

Target waveform:

> safe intake ↓ rope teach ↓ poison timing ↓ leaper basin ↑ route decision
> ↘ sunken risk ↑ pump combine ↑ shelter

Target time: 7–9 minutes. Landmarks: flooded intake, pump spine, shelter lamp.

### Pre-enhancement baseline

```text
entry → rope → poison → leaper → choice → pump → shelter
                                  ↓
                               sunken cache
                                  ↑
                                choice
```

### Implemented graph (fixed V6)

```text
entry → rope → poison → leaper → choice → pump → shelter
                                  ↘       ↑
                                  cache ──┘
```

### Target edges

| Role | From | To | Source owners |
| --- | --- | --- | --- |
| critical | `fw_flooded_entry` | `fw_rope_shaft` | entry/rope sockets |
| critical | `fw_rope_shaft` | `fw_poison_timing` | rope/poison sockets |
| critical | `fw_poison_timing` | `fw_leaper_basin` | poison/basin sockets |
| critical | `fw_leaper_basin` | `fw_lower_upper_choice` | basin/choice sockets |
| critical | `fw_lower_upper_choice` | `fw_pump_gallery` | choice/pump sockets |
| optional | `fw_lower_upper_choice` | `fw_sunken_cache` | choice/cache branch sockets |
| return | `fw_sunken_cache` | `fw_pump_gallery` | new pump optional-rejoin socket |
| critical | `fw_pump_gallery` | `fw_exit_shelter` | pump/shelter sockets |

### Room construction matrix

| Room/source | Rhythm | Gameplay beats | Marker/reveal |
| --- | --- | --- | --- |
| `fw_flooded_entry` — `FwFloodedEntry.tscn` | preview | safe intake, basin/pump preview | start/current |
| `fw_rope_shaft` — `FwRopeShaft.tscn` | teach | mount, descend, reverse, dismount | room visit |
| `fw_poison_timing` — `FwPoisonTiming.tscn` | transform | safe wait, timed crossing, recovery | room visit |
| `fw_leaper_basin` — `FwLeaperBasin.tscn` | first peak | previewed drop, moving landing threat, two exits | room visit |
| `fw_lower_upper_choice` — `FwLowerUpperChoice.tscn` | decision | dry precision, wet management, commit | branch edge after visit |
| `fw_sunken_cache` — `FwSunkenCache.tscn` | optional | hazard management, rewards, pump rejoin | reward markers after visit |
| `fw_pump_gallery` — `FwPumpGallery.tscn` | combine/test | cover, climb, pressure, mid recovery | room visit |
| `fw_exit_shelter` — `FwExitShelter.tscn` | release | safe vista, shelter exit | exit always ready |

## Broken Sanctum

Spatial thesis: open the seal, revisit the nave from changed heights, distribute
two optional loops across the stage, and use cover/flank knowledge at the final
crossfire.

Target waveform:

> breach ↑ shield flank ↑ gate loop ↓ crypt branch/rejoin ↑ nave
> ↑ transfer ↓ fractured combine → recovery ↗ upper reliquary/rejoin
> ↑ sentry test ↑ terminal ascent

Target time: 8–10 minutes. Landmarks: seal gate, fractured rose window,
reliquary crown.

### Pre-enhancement baseline

```text
breach → shield → gate → nave → twin hub → gallery → recovery → sentry → exit
                                  ↙     ↘
                               crypt   reliquary
                                  ↖     ↗
                                  twin hub
```

### Implemented graph (fixed V6)

```text
breach → shield → gate → nave → transfer → gallery → recovery → sentry → exit
                    ↘     ↑                          ↘          ↑
                     crypt ┘                           reliquary ┘
```

The gate room also opens an intra-room upper shortcut. It is a runtime gate state,
not a duplicate StagePlan edge.

### Target edges

| Role | From | To | Source owners |
| --- | --- | --- | --- |
| critical | `bs_breach_entry` | `bs_shield_choke` | breach/shield sockets |
| critical | `bs_shield_choke` | `bs_gate_switch_loop` | shield/gate sockets |
| critical | `bs_gate_switch_loop` | `bs_volatile_nave` | gate/nave sockets |
| optional | `bs_gate_switch_loop` | `bs_material_crypt` | new gate branch socket |
| return | `bs_material_crypt` | `bs_volatile_nave` | new nave optional-rejoin socket |
| critical | `bs_volatile_nave` | `bs_twin_reliquary_choice` | nave/transfer sockets |
| critical | `bs_twin_reliquary_choice` | `bs_fractured_gallery` | transfer/gallery sockets |
| critical | `bs_fractured_gallery` | `bs_recovery_cloister` | gallery/recovery sockets |
| critical | `bs_recovery_cloister` | `bs_sentry_crossfire` | recovery/sentry sockets |
| optional | `bs_recovery_cloister` | `bs_reliquary_cache` | new recovery branch socket |
| return | `bs_reliquary_cache` | `bs_sentry_crossfire` | new sentry optional-rejoin socket |
| critical | `bs_sentry_crossfire` | `bs_exit_ascent` | sentry/exit sockets |

### Room construction matrix

| Room/source | Rhythm | Gameplay beats | Marker/reveal |
| --- | --- | --- | --- |
| `bs_breach_entry` — `BsBreachEntry.tscn` | preview | safe breach, seal/nave preview | start/current |
| `bs_shield_choke` — `BsShieldChoke.tscn` | teach | read front, flank elevation, punish | room visit |
| `bs_gate_switch_loop` — `BsGateSwitchLoop.tscn` | transform | closed gate, switch route, opened shortcut | gate/shortcut after visit |
| `bs_material_crypt` — `BsMaterialCrypt.tscn` | early optional | controlled drop, material reward, nave rejoin | reward after visit |
| `bs_volatile_nave` — `BsVolatileNave.tscn` | hazard peak | reused landmark, timing, safe recovery | room visit |
| `bs_twin_reliquary_choice` — `BsTwinReliquaryChoice.tscn` | transfer | unambiguous vertical transfer, no branch hub | room visit |
| `bs_fractured_gallery` — `BsFracturedGallery.tscn` | combine | threat priority, elevation transfer, escape | room visit |
| `bs_recovery_cloister` — `BsRecoveryCloister.tscn` | release/clue | safe checkpoint, upper clue | active checkpoint; late branch edge |
| `bs_reliquary_cache` — `BsReliquaryCache.tscn` | late optional | mastery line, reward, crossfire rejoin | reward after visit |
| `bs_sentry_crossfire` — `BsSentryCrossfire.tscn` | tactical test | cover bands, transfer window, flank | room visit |
| `bs_exit_ascent` — `BsExitAscent.tscn` | final test | known transfer, local priority, gate | exit always; lock badge until local clear |

## Cross-stage implementation review

| Stage | Signature verb | Teach → transform → test → release |
| --- | --- | --- |
| Ruin Approach | broken ascent | stepped climb → cover/exposure → charge and terminal ascent → broken-gallery/exit release |
| Flooded Works | descend then pump up | bidirectional rope → poison/leaper basin → pump combine → shelter |
| Broken Sanctum | distributed reversal | shield flank → gate and two forward loops → fractured/crossfire/exit test → cloister and terminal release |

The fixed V6 implementation preserves three distinct collision silhouettes and
height waveforms: Ruin is ascent-led with a controlled descent, Flooded is
descent-led before its pump recovery, and Sanctum uses four direction reversals
with two distributed optional routes. The runtime minimap uses one uniform scale
per stage, so these differences are not created by independent-axis stretching.

Every one of the 30 active enemy placements now has an authored
`terrain_relation` on its scene anchor. Combat rooms also retain an entry
recovery inside the first 240 px. Shared Shooter, Sentry, Charger, Shield Guard,
and Leaper warnings are local facing or destination cues; ordinary enemies no
longer use an activation-range trajectory line. Boss startup warnings remain
separate because their visible startup/active/recovery contract is mandatory.

The production camera remains the default player-owned camera. Active rooms have
no `camera_id` metadata; preview/read/recovery geometry and the fixed capture
set prove irreversible drops and encounter commitments without a second
room-specific camera system.

No normal-stage room contains Forge or Merchant interactables. The global
required-enemy count remains a diagnostics/test fact only; HUD copy and exit
eligibility use navigation, arrival, or terminal-local encounter state.

## Acceptance Criteria

1. Each rendered blueprint is a standalone PNG and includes every active room ID.
2. Current and target topology are both documented.
3. Every target edge names source owners and has a corresponding implementation
   task in the active ExecPlan.
4. Stage silhouettes and height waveforms remain visibly distinct.
5. Optional branches forward-rejoin and do not duplicate rewards.
6. Terminal policy is explicit and never inferred from `required_route`.
7. The minimap layer identifies room discovery, current position, exit,
   checkpoint, discovered reward, and gate/shortcut state without enemy radar.
8. No room count, mechanic, asset dependency, or stable ID is added by the
   blueprint alone.
