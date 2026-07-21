---
type: plan
status: active
owner: BK
created: 2026-07-22
topic: Player-centered threat radar and triple-density combat pressure
scope: Vehicle-stage threat radar, enemy population and activation density, enemy speed/damage/cadence tuning, validation, rendered evidence, and production build verification
related:
  - ../../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_content_expansion_spec.md
  - ./2026-07-21-high-density-combat-upgrade-loop.md
---

# Threat Radar and Triple-Density Combat Pressure ExecPlan

This plan adds a player-centered circular threat radar and makes all three vehicle stages materially harder through exactly triple authored populations and active caps, bounded higher attack pressure, faster enemies, and stronger attacks. Three phases deliver the radar, combat tuning, and final production evidence without changing maps, controls, progression, or art direction.

## Why / Context

The current run has 68/76/84 pre-boss enemies and 24/26/28 active-cap enemies, but the owner reports that it still feels too easy and wants roughly three times more enemies. Dense combat also makes threats outside the immediate aim cone hard to read, so a compact circular UI around the player must show where nearby enemies are without drawing every enemy as an overlapping point.

## Purpose

- Objective: make surrounding threats readable while raising population and combat pressure enough to demand movement, dash timing, target priority, and upgrades.
- Final artifact: a production-buildable Godot run with a 156 px player-centered threat radar, 204/228/252 authored pre-boss enemies, 72/78/84 active caps, and the locked enemy tuning multipliers.
- Completion state: gameplay/data/UI validators, Korean and English renders, Web export, canonical local boot, staged-file audit, and this plan lifecycle all pass.

## Pre-plan Evidence Already Verified

| Source or path | Verified fact | Decision affected | Recheck boundary |
| --- | --- | --- | --- |
| `scripts/encounters/vehicle_encounter_director.gd` | Population is 68/76/84, active caps are 24/26/28, threat budget is 4.0, ranged cap is 2, and denial cap is 1. | Triple populations and active caps; raise but continue bounding attack commits. | Recheck if encounter constants change before implementation. |
| `scripts/vehicle/vehicle_stage_catalog.gd` | Seven/eight/eight deterministic swarm groups own most of each stage population. | Increase group counts to exact total targets; preserve authored anchors and deterministic IDs. | Recheck after formation validation. |
| `scripts/enemies/vehicle_enemy_archetypes.gd` | Role speed is centralized; attack damage and hard-coded lunge/projectile speed remain in the stage runtime. | Keep role data ownership and add shared tuning multipliers in the encounter director. | Recheck if damage becomes per-archetype data. |
| `scripts/ui/vehicle_stage_ui.gd` and `vehicle_stage_one.gd:_build_hud_snapshot` | HUD consumes snapshots; the stage already owns world-to-HUD data, minimap, and target state. | Add a snapshot-only threat radar component; UI must not inspect gameplay nodes. | Recheck if HUD ownership changes. |
| `tools/validation/validate_vehicle_stage_one.gd` | Population, layout, reachability, UI bounds, ordinary-enemy bypass, cover, and full-run contracts are deterministic. | Extend existing validation instead of creating a duplicate test harness. | Recheck after source changes. |

## Locked Decisions

| Topic | Final decision | Rationale / source |
| --- | --- | --- |
| Total populations | Flooded Works 204, Tidal Archive 228, Storm Drydock 252 pre-boss enemies. | Exact 3× of the current accepted totals, matching the owner request. |
| Active caps | 72/78/84 capped mobile enemies. Priority installations and bosses remain outside this cap. | Exact 3× current caps so the increase is visible, not only stored offscreen. |
| Formation packing | Ten slots per ring, first radius 48 px, +36 px per ring, stable group IDs/angles. | Holds 27–31 swarm units around existing anchors without overlapping units or extending the former ring radius. |
| Combat tuning | Enemy movement ×1.15, hostile projectile speed ×1.12, enemy damage ×1.25, ordinary attack recovery divided by 1.20. | Raises pressure without shrinking readable startup warnings. |
| Attack coordination | Threat budget 6.5, at most 3 ranged commits and 2 denial commits. | More simultaneous danger while retaining deterministic upper bounds. |
| Threat radar | New full-HUD `VehicleThreatRadar`; 156 px diameter centered on the actual projected player position, 1,200 px scan range, 24 angular sectors. Each sector shows the nearest distance, aggregate count through pip size, and priority/target semantic color. | Conveys direction and density without drawing up to 84 overlapping markers. |
| Radar visibility | Visible only with gameplay HUD. No text, input, tooltip, setting, or minimap replacement. | It is glanceable combat feedback, not another panel or control. |

## Rejected Alternatives

| Alternative | Why it was viable | Why it was rejected |
| --- | --- | --- |
| Put every enemy on the ring | Exact one-dot-per-enemy position. | Up to 84 active contacts would become illegible and violate the request's usefulness. |
| Increase total population but retain current active caps | Lowest performance risk. | The user would see almost the same combat density. |
| Triple attack budget with population | Direct numeric interpretation. | It would create unavoidable simultaneous attacks and undermine telegraph readability. |

## Scope

In scope:

- Player-centered threat radar, exact triple populations/caps, deterministic formation packing, enemy speed/projectile/damage/recovery multipliers, active spec alignment, validators, captures, Web export, local boot, and scoped commits.

Out of scope:

- Map geometry, new enemy roles, boss pattern redesign, player weapon/upgrade rebalance, new assets/dependencies, persistent settings, remote push, and unrelated `.import` changes.

Destructive or irreversible actions: none.

Exact actions requiring owner/user approval: none within this plan; remote push and dependency adoption remain unapproved.

## Architecture and Ownership

| Concern | Final owner | Interface or invariant | Existing owner to reuse or retire |
| --- | --- | --- | --- |
| Radar rendering | `scripts/ui/vehicle_threat_radar.gd` | Receives a copied snapshot and draws only screen-space feedback. | Reuse `VehicleStageUI`; retire nothing. |
| Radar contacts | `vehicle_stage_one.gd:_threat_radar_snapshot` | Active, alive, local enemies only; world-to-screen center and semantic contact fields. | Reuse HUD snapshot path. |
| Population/pressure | `vehicle_encounter_director.gd` | Exact target counts, caps, multipliers, and commit ceilings. | Replace current constants. |
| Formation data | `vehicle_stage_catalog.gd` plus director expansion | Exact total counts and cover-safe deterministic positions. | Reuse authored anchors/groups. |
| Enemy tuning application | `vehicle_stage_one.gd` | Central multipliers apply once; environmental damage stays unscaled. | Reuse `_make_enemy`, projectile, recovery, and damage paths. |

## Tasks

### Phase 1: Player-centered threat radar

Goal: show nearby threat direction and density without obscuring combat.

- [ ] **1.1 Add the snapshot-driven radar component.**
  - Accept: 24 or fewer stable contacts draw inside a 156 px ring around the projected player; target and priority threats are distinct.
  - Guard: no gameplay-node reads, input surface, text, panel, or minimap regression.
- [ ] **1.2 Wire radar contacts and responsive HUD state.**
  - Accept: radar follows the player near map/camera bounds, hides with modals, and fits 960×540, 1280×720, and 1920×1080.
  - Guard: action rail, target panel, boss strip, and notifications do not overlap or become hidden.

Batch acceptance: a dense combat capture makes attacks from every direction legible at a glance.

### Phase 2: Triple density and higher pressure

Goal: make the run materially harder while preserving readable telegraphs and progression bypass.

- [ ] **2.1 Set exact population, active-cap, and formation contracts.**
  - Accept: stages contain exactly 204/228/252 pre-boss enemies and active caps are exactly 72/78/84; every spawn remains cover-safe and every required route remains reachable.
  - Guard: IDs stay unique, ordinary enemies still do not gate exit/rewards, and boss/installation counts do not multiply.
- [ ] **2.2 Apply the locked speed, damage, projectile, recovery, and threat-budget tuning.**
  - Accept: runtime/debug snapshots prove ×1.15 movement, ×1.12 hostile projectile speed, ×1.25 enemy damage, ÷1.20 recovery, budget 6.5, ranged 3, denial 2.
  - Guard: startup telegraph duration, cover blocking, dash defense, projectile caps, environment damage, and boss warning windows remain intact.
- [ ] **2.3 Align active specs and validators.**
  - Accept: active product text and deterministic tests contain no retired 68/76/84 or 24/26/28 contract.
  - Guard: completed historical plans remain historical and are not rewritten.

Batch acceptance: all three stage blueprints and an automated full run pass at the new counts.

### Phase 3: Render, quality, production, and lifecycle

Goal: prove the HUD and higher-density run in the shipped configuration.

- [ ] **3.1 Capture Korean 1280×720 and English 960×540 combat, including camera-boundary radar placement and all three stage densities.**
- [ ] **3.2 Run the task-scoped quality pass, focused/full validators, Web release export, canonical port 13029 boot, `git diff --check`, and staged-file audit.**
- [ ] **3.3 Record final evidence, mark this plan `done`, and commit only task-owned changes.**

Batch acceptance: radar remains readable under the maximum visible pressure and the production build boots locally.

## Validation Cadence

Inner-loop commands:

- `./tools/godot.ps1 --path . --headless --quit-after 2`
- `./tools/godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_one.gd`
- `git diff --check`

Final gates:

- All vehicle primary, upgrade, stage, reward/UI/audio, and settings validators exit zero.
- Korean 1280×720 and English 960×540 Godot captures show radar and stage densities without overlap or clipping.
- `./tools/godot.ps1 --path . --headless --export-release Web build/web/index.html` produces non-empty HTML/JS/WASM/PCK.
- Built export returns HTTP 200 for all four files on canonical Codex-lane port 13029, then releases the exact task-owned process.
- Staged files contain no pre-existing unrelated `.import` churn.

## Predetermined Error Handling and Contingencies

| Trigger | Required response | Limit / escalation point |
| --- | --- | --- |
| A packed spawn overlaps cover | Adjust deterministic ring spacing/angle for the affected group and rerun every stage blueprint; never random-relocate at runtime. | Escalate only if existing anchors cannot hold exact totals. |
| Radar contact clutter remains unreadable | Keep 24 sectors; increase aggregation/pip-size contrast and reduce non-priority opacity. | Do not increase marker count. |
| Frame stability degrades | Preserve exact totals; reduce active caps only after measured native capture instability, with the smallest reduction and a recorded deviation. | Escalate before going below 60/66/72. |
| Combat becomes unavoidable | Preserve enemy totals/speed/damage; reduce threat budget in 0.5 steps, never below 5.0. | Keep startup warnings and cover collision unchanged. |

## Progress

- [ ] Phase 1: player-centered threat radar.
- [ ] Phase 2: triple density and higher pressure.
- [ ] Phase 3: rendered/production validation and lifecycle completion.
- [ ] Final gates.

## Next Steps

1. Implement and validate the radar vertical slice.
2. Apply exact population and pressure tuning, then validate all stage blueprints/full-run progression.
3. Capture both locales, export/boot the production build, close lifecycle, and commit scoped changes.

## Risks

- Exact triple active caps can expose CPU pressure from enemy-to-enemy support scans. Native capture is the acceptance boundary; totals remain exact even if the predetermined active-cap fallback is needed.
- More enemies can make individual health bars noisy. Existing conditional health visibility remains unchanged and the radar aggregates instead of duplicating bars.
- A ring around the player can obscure close collision cues. The radar uses translucent strokes and stays outside the vehicle silhouette.

## Open Questions

No material question remains. Changes to the exact triple totals, map geometry, controls, new enemy roles, dependencies, or remote operations require owner change control.

## Decision Notes

- 2026-07-22: owner requested a circular enemy-position UI around the character, roughly three times more enemies, and higher enemy attack/speed because the run remains too easy.

## Stop Conditions

Complete when all tasks and final gates pass, this plan is `done`, and task-owned changes are committed locally.

Escalate only when exact totals cannot fit existing authored anchors, native performance requires falling below the specified fallback caps, or completion requires map/dependency/remote scope.

Do not stop while a task-scoped tuning, layout, validator, capture, build, or safe quality correction remains.

## Rollback / Safety

- The radar is isolated to one UI component and one snapshot field; combat tuning is centralized in encounter constants.
- No save schema or dependency changes occur.
- Never stage, revert, or clean pre-existing `.import` changes.

## Handoff

```text
Goal: Add a player-centered aggregated threat radar and exact triple-density, higher-pressure vehicle combat.

Read first: AGENTS.md, this plan, vehicle_content_expansion_spec.md, vehicle_stage_ui.gd, vehicle_encounter_director.gd, vehicle_stage_catalog.gd, and vehicle_stage_one.gd.

Execute exactly: phases 1 through 3 with the locked counts, multipliers, radar contract, and contingencies.

Validate with: all vehicle validators, bilingual native captures, Web export, canonical 13029 boot, diff check, and staged-file audit.

Stop when: every checklist item passes, the plan is done, and only task-owned changes are committed locally.
```
