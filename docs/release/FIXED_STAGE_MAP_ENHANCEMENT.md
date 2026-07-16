---
type: record
status: active
owner: BK
created: 2026-07-16
last_reviewed: 2026-07-16
source: Completed fixed-stage map ExecPlan, Godot 4.7 release matrix, production runtime fixtures, real OpenGL captures, and served Web export
topic: Release closure for the Ruin Approach, Flooded Works, and Broken Sanctum map enhancement
scope: Authored topology, traversal, completion policy, minimap, terrain-aware encounters, release validation, and retained limitations
related:
  - ../../.agent/execplans/2026-07-15-fixed-stage-map-enhancement.md
  - ../design/2D_PLATFORMER_MAP_DESIGN_GUIDELINE.md
  - ../design/STAGE_MAP_BLUEPRINTS.md
  - ../research/cross_stage_map_cohesion_2026-07-16.md
---

# Fixed Stage Map Enhancement

## Outcome

The three normal stages now use distinct authored height profiles, forward
optional rejoins, recovery-backed commitments, terrain-aware encounters, typed
completion policies, and one assembled-plan fog-of-war minimap.

| Stage | Enemies | Range | Ascent | Descent | Reversals | Forward rejoins | Completion |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| Ruin Approach | 8 | 784 px | 944 px | 160 px | 2 | 1 | terminal encounter |
| Flooded Works | 10 | 896 px | 256 px | 896 px | 1 | 1 | shelter arrival |
| Broken Sanctum | 12 | 736 px | 1,048 px | 312 px | 4 | 2 | terminal encounter |

Earlier and optional enemies no longer form a stage-wide kill gate. Ruin and
Sanctum require only their authored terminal-room encounter; Flooded completes
on actual shelter arrival. The minimap shows current position, visited and
unvisited rooms, exit, active checkpoint, discovered rewards, and discovered
gate state without tracking ordinary enemies or hazards.

## Traversal And Encounter Closure

- Required transitions are derived from the baseline Traveler movement envelope.
- Six committed-return fixtures exercise local basin ropes, three cross-room
  return ropes, and one forward drop onto the authored support.
- Cross-room climbables are activated only for socket IDs selected by the accepted
  `StagePlan`; compatibility routes stay disabled and invisible.
- Room validation rejects cross-room rope metadata that does not name a declared
  exit socket.
- Basic Shooter and Sentry projectiles terminate on authored solid cover.
- Leapers select reachable local destinations instead of replaying one fixed arc.
- Mobile patrols respond to walls and ledges inside their authored lanes.
- All 30 active enemy placements have an explicit terrain relation and every
  combat room preserves a recovery-backed 240 px entry buffer.
- Ordinary enemies use local startup direction or destination cues rather than
  full-range trajectory overlays.

The release matrix found and closed late integration regressions in Ruin pickup
overlap, optional rejoin support, dormant random-room compatibility, selected
cross-room route activation, Leaper role allocation, and equipment-aware health
reward preview.

## Continuous Runtime Evidence

The stage fixtures use actual movement, jump, climb, crouch, and interaction
actions over physics frames rather than teleport-only assertions.

| Evidence | Covered behavior |
| --- | --- |
| `validate_ruin_stage_runtime.gd` | required clear, cache drop/return, terminal-only lock, skipped enemy, minimap retry knowledge, Shooter/Charger/Walker cycles |
| `validate_flooded_stage_runtime.gd` | basin descent, rope reversal, optional cache/rejoin, poison retry reset, repeated Leaper destinations, arrival completion with earlier enemies alive |
| `validate_broken_sanctum_runtime.gd` | gate shortcut, both optional routes, checkpoint state, crossfire/cover roles, terminal-only lock with skipped enemies |
| `validate_fixed_drop_runtime.gd` | six recovery, drop, rope-entry, climb, dismount, and support-containment fixtures |
| Full release matrix | damage, guard, fall recovery, retry, rewards, intermission, boss, profile, HUD, input, and all stage contracts |

These deterministic fixtures close the technical continuous-play gate. They do
not claim to measure subjective fun; encounter pacing and feel still require
future human tuning against the shipped geometry.

## Release Verification

The complete release implementation matrix passed:

```text
RELEASE_CANDIDATE_MATRIX_OK checks=81 full=True seconds=632.7
```

The post-audit focused pass also exited 0:

```text
ROOM_TEMPLATE_VALIDATION_OK
FIXED_DROP_RUNTIME_VALIDATION_OK heroes=1 fixtures=6
CURATED_STAGE_PLAN_VALIDATION_OK stages=3 run_seeds=2
```

The Godot 4.7 production export completed with nine Web files totaling
69,178,445 bytes. It was served on the fastrun manager's `codex` lane at
`127.0.0.1:13029`; the document returned HTTP 200. Headless Chrome reported:

```text
title=Cardborne Platformer
activeElement=canvas
canvas=1280x720
browser_errors=0
```

Real built-app interaction covered Main Menu, Hero Preparation, Stage 1 launch,
rightward movement, the live minimap/HUD, and pause. The full matrix remains the
repeatable authority for jump, dash, attack, guard, interaction, retry, optional
routes, and non-terminal enemy bypass.

## Rendered Evidence

Reproducible artifacts remain outside source control under
`.codex-runtime/uiux/`.

```text
e5d491089405021d35f43610271890a8ab07d644297fcb7bc8d43acb68851526  stage_silhouette_comparison.png
b6a513dd03c8d882bb7d0ef6a1e590cf95a074d97c0b11d564b88c326a4c446c  ruin_charge_reengage.png
553fc7f46feeadfa48a663420a1afa963bd0fd2f8c9877673c0b2230fb617724  flooded_pump_ascent.png
3c67b5e240988f408c903ad1a291af8518ed7953216c7c316c0253fecfec2636  sanctum_fractured_roles.png
493b46099896ef69b643cc48fce4c66003f819112886fbc956155cf41c19837e  sanctum_sentry_crossfire.png
9312800509e9a83e09820776018d1a0bc5b5275ad8413bf7585f78939803eefd  01_main_menu.png
95bb10366999f58a65198f68496cd9c272299573ad35a2c04f1068345c3106d4  02_hero_preparation.png
8c5198edae8d4c41c9e189694c1aff08673639348ac4eb3ca73a4b446281d6c2  03_stage_one_start.png
9c50809c09144792c0f8060a90a91c5ca943b470b1ac5f97764f03947f191f81  04_stage_one_moved.png
e225f0acb5efef604c9007619e58bde34e48c7736ce7028a8d5ef89756149232  06_pause_menu.png
```

The fixed capture inventory contains teach, route choice, combat peak, optional
rejoin, and release views for all three stages, with the minimap visible.

## Guideline Acceptance

| # | Criterion | Result |
| ---: | --- | --- |
| 1 | Baseline Traveler validates every required transition | Pass |
| 2 | Every required room has intention, safe entry, commitment, consequence, and recovery | Pass |
| 3 | Every stage has one spatial verb and teach/transform/test/release arc | Pass |
| 4 | Macro height profile expresses theme and pacing | Pass |
| 5 | Route splits differ on at least two of movement, risk, time, and reward | Pass |
| 6 | Optional routes are readable and justify their cost through reward or shortcut | Pass |
| 7 | Every combat room has a validated enemy-terrain relation | Pass |
| 8 | Critical landing, threat, and goal are visible before commitment | Pass |
| 9 | Geometry vocabulary and collision silhouette differ without labels | Pass |
| 10 | Headless, rendered, continuous-input, and real-combat evidence pass | Pass |

## Retained Limits

- World geometry and actors remain coherent prototype presentation rather than
  final commercial art.
- Runtime-random topology remains dormant; the compatibility routes only preserve
  its future re-entry surface.
- Scripted evidence cannot determine whether the complete run is fun. Human
  playtesting should tune pacing, enemy density, rewards, and equipment pressure
  without weakening the movement and no-soft-lock contracts closed here.
