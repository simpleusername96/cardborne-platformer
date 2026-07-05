---
type: evidence
status: active
created: 2026-07-05
source: Local validation of ./raw/pasted-text.txt
topic: chatgpt-pro-rock-mass-map-review
related:
  - ./README.md
  - ./external-review-raw.md
  - ./codex-goal-checklist.md
  - ../../design/testbed-plan/07_rock_mass_generated_routes.md
  - ../../../scripts/stages/MotionTestStage.gd
---

# External Review Validation

Validated local baseline: `8803796fe454d7aa5ad802cb4e452cf92bc27185`

Overall verdict: the ChatGPT Pro response is largely valid. The strongest findings are confirmed by local code: the generated route is still a seeded hard-coded segment list, validation only reasons over generated surface records, the start socket is visual-only but participates in validation, generated/authored duplicate collision is not checked, and an invalid generated route status can be overwritten back to ready during startup.

## Verdict Table

| External claim or recommendation | Local evidence checked | Verdict | Local interpretation |
| --- | --- | --- | --- |
| The goal is side-view dungeon terrain with filled rock masses, movement space, and deterministic constrained random generation. | `07_rock_mass_generated_routes.md` phases 5-8 and the latest map implementation. | Accept | This matches the current task framing and should remain the feature target. |
| The first pass broadly moved toward the intent but is incomplete. | `_add_terrain_mass()` is now used across authored/generated terrain, while phase 5 generator work remains unchecked. | Accept | The work is a first pass, not the final generator. |
| The generated route is still a hard-coded segment list with jitter. | `MotionTestStage.gd:303-309` defines `segments` inline and then jitters them in `MotionTestStage.gd:336-348`. | Accept | Template/profile extraction should stay planned, but the next fix should make current validation honest first. |
| Filled rock mass is often visual-only because collision remains a thin old-style surface. | `MotionTestStage.gd:501-504` uses full visual depth only when `solid_fill` is true. | Modify | This was an intentional safe first pass for control feel, but it can mislead players if visible rock implies collision. The next pass must make collision/visual intent explicit. |
| The generated-start socket is visual-only but participates in generated route validation. | `generated_start_socket` is recorded with `solid: false` at `MotionTestStage.gd:318-320`; its visible mass is added without collision at `MotionTestStage.gd:330`; validation loops include it for width and link checks at `MotionTestStage.gd:606-624`. | Accept | Validator should validate the actual support surface or mark visual-only records as non-support. |
| Duplicate validation does not compare generated surfaces against authored collision. | `_validate_generated_route()` receives only `generated_surfaces` at `MotionTestStage.gd:379`; duplicate checks only compare entries inside that array at `MotionTestStage.gd:626-640`. | Accept | Add a route-surface registry that includes authored and generated collision-bearing bounds. |
| Invalid generated route status can be overwritten to ready. | `_build_generated_route()` emits ready/invalid at `MotionTestStage.gd:398`; `_ready()` then calls `_publish_testbed_context()` at `MotionTestStage.gd:69`; `_publish_testbed_context()` always emits ready at `MotionTestStage.gd:406-410`. | Accept | This is a real status consistency bug. The status publisher should preserve the generated route validity state. |
| Generated route validation failure has no retry or fallback. | `_build_generated_route()` stores `valid` and `failure_reason` at `MotionTestStage.gd:379-392`, but no retry/fallback path is present. Plan item 5.9 and 6.12 remain open. | Accept | It is acceptable for a debug pass, but not for required clear flow. |
| Add a generated route contract or route-surface registry before larger generator extraction. | Same evidence as duplicate/status/visual-only findings. | Accept with scope control | Implement as a narrow `MotionTestStage.gd` validation helper first. Avoid broad architecture until it proves useful. |
| Deterministic seed replay and template/profile generation should be owned by local code, not the external model. | Plan phase 5 explicitly requires deterministic seed/profile behavior. | Accept | External models can review artifacts; local code must enforce passability and determinism. |
| Seed matrix, headroom, fall recovery, and least-mobile traversal checks are needed. | Plan phase 6 and phase 8 already list these checks as open. | Accept / needs local verification | The recommendation is directionally correct, but exact metrics must be verified against player controller and `RunState`. |
| Screenshots are secondary evidence. | Current issues are mostly collision, route-status, and validator-contract problems. | Accept | Screenshot review is useful after mechanical validation is more truthful. |

## Rejected Claims

None. No external claim was clearly false against the current local code. A few claims need narrowed implementation scope rather than rejection.

## Next Local Focus

The smallest useful next change is to harden the current generated-route contract:

- Register authored and generated route surfaces with collision/visual bounds, support role, one-way/solid state, and source.
- Validate required links using only support-capable collision surfaces.
- Compare generated surfaces against authored collision surfaces.
- Preserve invalid route status instead of publishing ready unconditionally.
- Keep retry/fallback and broader template extraction as the next layer after validation is trustworthy.
