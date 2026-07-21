---
type: evidence
status: active
owner: BK
created: 2026-07-21
topic: Validation of ChatGPT Pro vehicle Stage 1 pull request
related:
  - README.md
  - ../../execplans/2026-07-20-vehicle-stage-one.md
  - ../../../docs/product/vehicle_stage_one_experimental_spec.md
  - ../../../reports/vehicle-stage-one/README.md
---

# External Review Validation

## Purpose

Validate GitHub pull request 3 (`agent/vehicle-stage-one`) against the current repository, repair small high-confidence defects, and record what the branch does and does not prove before local integration.

## Sources

- Pull request head `a544b6ed8ec5d2f9b586384351a94939560e8e81` and merge base `302ca2a6815735bf2d9fc7e154577a6aed4d3f89`.
- The vehicle pivot handoff, experimental specification, execution plan, implementation, CI workflow, and rendered evidence instructions.
- Local Godot 4.7 stable headless validation, native 1280×720 capture review, Web release export, and HTTP boot check.

## Findings

| External claim or implementation | Verdict | Local evidence and disposition |
| --- | --- | --- |
| The branch is ready to validate as delivered. | Modified | The initial head did not parse in Godot 4.7 stable, so it was not mergeable without repair. |
| The active runtime is a complete vehicle Stage 1 experiment. | Accepted | The main scene boots the vehicle stage and the scripted route covers deployment, continuous combat space, generators, a card choice, optional field boss, stage boss, result, garage, and replay reset. |
| Ordinary enemies do not gate progression. | Accepted | The focused validator reaches boss entry with ordinary enemies alive and completes the result flow. |
| Projectile cover and passive line of sight are consistent. | Modified | The original passive check bypassed the production target scan. It now exercises the actual target-selection path; both hostile and player projectile cover checks pass. |
| Authored landmarks and spawns are reachable. | Modified | The Dredge Warden and its landmark overlapped cover at the submitted coordinates. The spawn was moved to a reachable clear position and the blueprint validator now passes. |
| HUD and modal surfaces are usable. | Modified | A deployment string parse error prevented HUD creation, an aimed-target anchor produced a layout warning, and transient boss text overlapped the boss meter. These were repaired and the eight native capture states were reviewed again. |
| Validation exits cleanly. | Modified | Runtime-generated audio streams remained referenced after the test scene was freed. Stage teardown now stops players and releases streams; validation exits without ObjectDB leak warnings. |
| The automated run proves the game is enjoyable and fully playable. | Rejected | It uses debug damage and teleport helpers. It proves state transitions and combat contracts, not input feel, encounter pacing, difficulty, or replay pull. Direct owner play remains required. |
| The stage uses an external resource pack for the vehicle presentation. | Rejected | The implementation explicitly uses project-owned geometric primitives. This is valid prototype art but does not satisfy a resource-pack-backed or production-quality vehicle presentation. |
| The implementation is ready as a long-term architecture. | Needs local verification | `vehicle_stage_one.gd` remains a roughly 2,800-line experimental orchestrator containing player, enemy, boss, reward, audio, and drawing behavior. It is acceptable only as a bounded product experiment and must be decomposed before further content expansion. |

## Local Verification Result

- Focused vehicle validator: 62 checks passed, 0 failed, no leaked ObjectDB instances.
- Native rendered evidence: 8 captures completed; objective, boss, notification, minimap, and action-dock layering were visually reviewed at 1280×720.
- Web release export: completed with `index.html`, JavaScript, pack, and WebAssembly outputs.
- Built artifact HTTP boot: `index.html` returned HTTP 200 and contained the Godot bootstrap.
- Legacy Tiled generated-room check: passes in the existing master worktree. A newly created Windows worktree exposes a pre-existing raw-newline hash portability issue; the vehicle PR does not change those sources.

## Integration Verdict

The repaired branch is technically safe to fast-forward into the current local master as an explicit experimental replacement. The merge must not be described as final visual completion or proven fun. External vehicle art, direct play balancing, and decomposition of the monolithic runtime remain follow-up acceptance decisions rather than hidden completion claims.
