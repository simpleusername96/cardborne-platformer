---
type: plan
status: active
owner: BK
created: 2026-07-22
topic: Vehicle combat performance recovery and reference-led threat indicators
scope: Vehicle-stage active simulation budgets, shield assignment, static/dynamic drawing, threat indicator semantics, validation, rendered evidence, and Web build verification
related:
  - ../../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_content_expansion_spec.md
  - ./2026-07-22-threat-radar-combat-pressure.md
---

# Combat Performance and Threat Arcs ExecPlan

This plan preserves the three-times-larger stage populations while making combat responsive on the current Intel Iris Xe laptop and replacing the dense dot radar with reference-led, off-screen threat arcs. Two implementation phases cover the performance recovery and the HUD redesign, followed by production evidence.

## Why / Context

The owner reports severe lag after simultaneous active caps were tripled to 72/78/84. A measured 84-enemy pressure sample spent about 38.5 ms per simulation step; repeated whole-roster shield searches were the dominant defect. The current 24-sector dot ring also duplicates enemies already visible in the playfield and reads as a miniature radar rather than a glanceable direction cue.

## Purpose

- Objective: restore responsive combat without deleting the larger authored populations, and make unseen threat direction legible without cluttering the player silhouette.
- Final artifact: three stages with 204/228/252 total enemies, hard active caps of 48/54/60, cached static drawing, bounded dynamic drawing, and a 12-sector off-screen threat-arc HUD.
- Completion state: deterministic contracts, measured pressure profile, Korean/English renders, Web export, canonical local boot, scoped commits, and this plan marked `done`.

## Pre-plan Evidence Already Verified

| Source or path | Verified fact | Decision affected | Recheck boundary |
| --- | --- | --- | --- |
| `vehicle_stage_one.gd:_update_enemy_shield` and local Godot timing | Every active ordinary enemy repeated full support/candidate searches. At 84 active enemies, the original pressure sample was ~38.5 ms/step and the shield pass ~52.7 ms; a one-pass assignment prototype reduced these to ~4.8 ms and ~0.39 ms. | Compute shield assignments once per physics step. | Re-run the same local profiler after final integration. |
| `vehicle_stage_one.gd:_draw` | Static world, floor motifs, water, and cover are regenerated whenever the dynamic stage queues a redraw; all active enemies/projectiles/effects are submitted even off-screen. | Move static drawing to a cached CanvasItem and cull dynamic drawing to the camera rect. | Recheck after stage changes and at camera boundaries. |
| [Epic Games: Visualize Sound Effects](https://www.epicgames.com/help/c-202300000001636/c-202300000001721/a202300000009892?lang=en-US), accessed 2026-07-22 | Fortnite exposes a radial directional indicator for selected nearby sound sources. | Use radial direction cues rather than a literal mini-map around the player. | Recheck only if the product HUD direction changes. |
| [Accessibility Labs: Fortnite Sound Visualizer](https://accessibility-labs.com/feature-highlight-fortnites-sound-visualizer/), accessed 2026-07-22 | The visualizer uses directional icon/arc semantics and source priority, not one persistent dot per entity. | Aggregate off-screen threats into short semantic arcs; keep on-screen enemies out of the overlay. | Secondary visual reference; implementation remains original and project-styled. |
| [Godot general optimization](https://docs.godotengine.org/en/4.6/tutorials/performance/general_optimization.html) and [custom 2D drawing](https://docs.godotengine.org/en/4.0/tutorials/2d/custom_drawing_in_2d.html), accessed 2026-07-22 | Godot recommends measuring bottlenecks, removing nested work, and relying on cached draw commands until `queue_redraw()` is needed. | Optimize the measured nested loop and isolate static custom drawing from per-frame redraw. | Godot 4.7 compatibility is verified through local import/build. |

## Locked Decisions

| Topic | Final decision | Rationale |
| --- | --- | --- |
| Population | Keep exact total populations 204/228/252. | The larger stage population remains a product requirement; performance is recovered through scheduling and drawing. |
| Active simulation | Hard caps become 48/54/60 mobile enemies. Committed attackers are retained first, then nearest enemies; excess distant enemies become dormant without being deleted. | This remains roughly twice the original visible density while preventing accumulated groups from exceeding the budget. |
| Shield support | Build generator coverage and each escort's closest protected target once per physics step, then apply by enemy ID. | Removes the measured nested-loop bottleneck without changing shield behavior. |
| Rendering | A new cached backdrop CanvasItem owns world/floor/water/cover. The dynamic stage draws only camera-near enemies, projectiles, and effects. | Uses Godot's cached custom drawing instead of rebuilding static geometry every frame. |
| Threat indicator | 208 px diameter, 12 angular sectors, 1,200 px range. Only enemies outside a safe viewport inset appear. Short arcs encode direction and density; coral is ordinary, mustard priority, ivory plus mustard chevron is current target. | Adapts the Fortnite directional-cue principle to this flat-color top-down game without cloning its assets. |
| Radar update cost | Rebuild contacts at 10 Hz; update the player screen center every rendered HUD update. | Direction tolerates 100 ms sampling while the indicator remains visually attached to the player. |
| Dependencies/assets | Add no package or external asset. | The cue is project-native custom drawing. |

## Rejected Alternatives

| Alternative | Why rejected |
| --- | --- |
| Delete the added enemies | It would erase the requested stage-density expansion instead of fixing scheduling. |
| Keep 72/78/84 active after the owner-reported lag | The current laptop is the acceptance hardware; simultaneous count is not worth unstable input/render latency. |
| Keep the 24-sector distance-dot radar | It duplicates visible enemies and becomes visual noise in dense combat. |
| Adopt MultiMesh immediately | Current enemy silhouettes and states are heterogeneous and below the scale where a renderer migration is justified; cached static drawing and culling address the measured path first. |

## Current State

Already true or landed:

- Three-times-larger total stage populations and stronger enemy tuning are committed.
- A local one-pass shield-assignment prototype has demonstrated the expected CPU improvement but is not yet finalized or committed.

Remaining implementation:

- Enforce the new hard active caps, cache static drawing, cull dynamic drawing, redesign and throttle threat cues, align contracts, and complete rendered/production verification.

## Scope / Non-scope

In scope:

- Vehicle combat simulation/drawing performance, active-cap scheduling, threat indicator component and snapshot, active spec/test alignment, captures, Web build, and scoped commits.

Out of scope:

- Total population reduction, new enemy roles, map layout, controls, weapon balance, assets, dependencies, save schema, remote push, and unrelated `.import` changes.

Destructive or irreversible actions: none.

Exact actions requiring owner/user approval: none; dependencies, remote operations, and scope expansion remain unapproved.

## Assumptions

No material assumption remains. The current laptop and 1280×720 native compatibility renderer are the acceptance environment.

## Proposed Design

| Concern | Owner | Contract |
| --- | --- | --- |
| Active scheduling and shield assignments | `scripts/vehicle/vehicle_stage_one.gd` | Never simulate more capped mobile enemies than the stage cap; shield semantics are computed once and applied by ID. |
| Population/cap constants | `scripts/encounters/vehicle_encounter_director.gd` | Totals stay 204/228/252; active caps are 48/54/60. |
| Cached background | `scripts/vehicle/vehicle_stage_backdrop.gd` | Draws static stage geometry once per stage configuration and never reads combat state. |
| Threat cue rendering | `scripts/ui/vehicle_threat_radar.gd` | Input-transparent custom drawing from a copied semantic snapshot; no gameplay-node access. |
| Threat cue sampling | `vehicle_stage_one.gd:_update_threat_contacts` | Samples eligible off-screen threats at 10 Hz; center projection remains current. |

## Milestones / Tasks

### Phase 1: Performance recovery

- [ ] **1.1 Finalize one-pass shield assignments and enforce hard active caps.**
  - Accept: active capped enemies never exceed 48/54/60; committed attackers remain active; shield contract remains unchanged; pressure profile stays below 8 ms/step at the maximum cap.
  - Guard: total populations, enemy damage/speed, progression bypass, and boss/installation behavior remain unchanged.
- [ ] **1.2 Cache static custom drawing and cull camera-external dynamic drawing.**
  - Accept: backdrop redraws only on stage configuration; off-screen enemies/projectiles/effects are not submitted; all camera-edge captures remain visually complete.
  - Guard: water, motifs, cover, boss gate, pickups, telegraphs, and collisions remain intact.

### Phase 2: Reference-led threat arcs

- [ ] **2.1 Replace the dot radar with 12-sector off-screen threat arcs.**
  - Accept: on-screen enemies create no redundant indicator; off-screen density/direction, priority, and current target remain distinguishable at both supported widths.
  - Guard: no full opaque disc, labels, input capture, minimap replacement, or non-project asset.
- [ ] **2.2 Throttle contact sampling and align product/test contracts.**
  - Accept: contact scans run at 10 Hz while the ring remains centered each frame; active documentation and validators contain the new cap/arc contracts.
  - Guard: modal hiding, localization, action rail, and target panel remain unchanged.

### Phase 3: Evidence and lifecycle

- [ ] **3.1 Run full validators, pressure profile, bilingual native captures, quality pass, Web export, and canonical port 13029 boot.**
- [ ] **3.2 Commit only task-owned files, record evidence, and mark this plan `done`.**

## Test Plan

Inner-loop:

- `./tools/godot.ps1 --path . --headless --quit-after 2`
- `./tools/godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_one.gd`
- `./tools/godot.ps1 --path . --headless --script res://tools/validation/profile_vehicle_pressure.gd`
- `git diff --check`

Final gates:

- All primary, upgrade, stage, reward/UI/audio, and settings validators exit zero.
- Korean 1280×720 and English 960×540 captures include dense combat and camera-boundary threat arcs without clipping.
- Web release export succeeds and HTML/JS/WASM/PCK return HTTP 200 on canonical Codex port 13029 before its exact task-owned process is stopped.
- Staging contains no unrelated `.import` churn.

Predetermined contingencies:

- If pressure remains above 8 ms/step, retain totals and caps but move radar sampling from 10 Hz to 8 Hz before considering broader architecture; escalate before any further active-cap reduction.
- If a threat arc overlaps fixed HUD at a camera boundary, clamp its center to a gameplay safe rect above the action rail without moving the player projection in normal camera space.

## Rollback / Safety

- The backdrop and threat indicator are isolated components; the stage owns their snapshots/configuration.
- No data migration, dependency, destructive filesystem operation, or unrelated worktree cleanup occurs.
- Reverting the task commits restores the prior radar and scheduling without affecting save data.

## Risks

- Dormant enemies can pop in if the hard-cap selector ignores viewport proximity; selection therefore retains committed enemies, then nearest enemies, and captures check camera boundaries.
- Static/dynamic drawing separation can miss stateful geometry; the boss gate remains dynamic in the stage and is explicitly validated.

## Open Questions

No material question remains. Changes to total population, map/controls, dependencies, save data, or remote operations require owner change control.

## Decision Notes

- 2026-07-22: owner reported severe lag and requested external-reference-led enemy-position UI correction.
- 2026-07-22: selected Fortnite-style directional cue semantics, one-pass shield assignment, cached static drawing, and 48/54/60 hard active caps after local timing and code inspection.

## Progress

- [ ] Phase 1: performance recovery.
- [ ] Phase 2: reference-led threat arcs.
- [ ] Phase 3: evidence and lifecycle.
- [ ] Final gates.

## Next Steps

1. Finalize simulation scheduling and cached/culling rendering.
2. Implement off-screen threat arcs and 10 Hz contact sampling.
3. Validate, render, export/boot, commit scoped changes, and close this plan.

## Completion Criteria

- [ ] Every milestone acceptance and regression guard passes.
- [ ] Pressure profile, rendered evidence, and production build all pass on the current environment.
- [ ] Only task-owned files are committed and this plan is `done`.

## Stop Conditions

Complete when all tasks and final gates pass, task-owned changes are committed, and this plan is done.

Escalate only if the 8 ms pressure budget cannot be met without reducing totals, changing controls/maps, adding a dependency, or expanding save/runtime architecture.

Do not stop while a task-scoped performance, UI, validation, capture, build, or lifecycle correction remains.

## Handoff

```text
Goal: Recover vehicle combat performance and replace the dot radar with reference-led off-screen threat arcs.

Read first: AGENTS.md, this plan, vehicle_stage_one.gd, vehicle_encounter_director.gd, vehicle_threat_radar.gd, and vehicle_content_expansion_spec.md.

Execute exactly: phases 1 through 3 with the locked totals, caps, one-pass shield assignment, cached backdrop, culling, and 12-sector arc contract.

Validate with: all vehicle validators, the pressure profiler, bilingual captures, Web export, canonical 13029 boot, diff check, and staged-file audit.

Stop when: every checklist item passes, this plan is done, and only task-owned changes are committed locally.
```
