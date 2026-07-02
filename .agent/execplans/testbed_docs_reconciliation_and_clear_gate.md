---
type: plan
status: done
created: 2026-07-03
source: User request to proceed with recommended next step after checkpoint recovery
scope: Motion testbed plan reconciliation and final-clear validation gate
related:
  - ../../AGENTS.md
  - ../PLANS.md
  - ../../docs/design/testbed-plan/FEATURE_PRIORITY.md
  - ../../docs/design/testbed-plan/00_foundation_contracts.md
  - ../../docs/design/testbed-plan/01_authored_lanes.md
  - ../../docs/design/testbed-plan/02_combat_damage.md
  - ../../docs/design/testbed-plan/03_interaction_input_ui.md
  - ../../docs/design/testbed-plan/04_generated_landscape.md
  - ../../docs/design/testbed-plan/05_qa_and_handoff.md
---

# Testbed Docs Reconciliation And Clear Gate

## Why / Context

The motion testbed now includes most immediate foundation, movement, combat, interaction, UI, generated route, and checkpoint recovery behavior, but the split plan documents still contain stale unchecked tasks. The playable stage also still allows the exit portal to clear without proving the required testbed interactions.

## Scope / Non-scope

In scope:

- Add a stage-owned validation checklist for final clear gating.
- Use existing signals and HUD route status to show missing required checks.
- Record destructible completion with a small local signal.
- Reconcile the split testbed plan documents so completed, partial, deferred, and open work are clear.
- Validate Godot import/runtime smoke, rendered UI evidence, and diff hygiene.

Out of scope:

- Production stages, card rewards, shop/rest rooms, or boss content.
- Full persistent key remapping.
- Full wall traversal implementation.
- Full procedural segment-template architecture.
- Full enemy/destructible reset loops after every respawn.

## Assumptions

- "Do this" refers to the recommended next step: reconcile plan docs, then implement final clear gating.
- Final clear should be blocked until movement, combat, destructible, hazard, interaction, generated-start, and generated-exit checks are satisfied.
- The testbed should expose missing checks through existing HUD/status surfaces rather than adding a new large UI panel.

## Proposed Design

- `MotionTestStage` owns validation state because it knows which authored/generated lanes prove the testbed contract.
- `ExitPortal` remains a generic interactable; `MotionTestStage.complete_stage()` decides whether clear is allowed.
- Checkpoints, enemy defeat, hazard hit, destructible destroyed, and NPC interaction mark individual validations.
- The HUD keeps consuming `SignalBus.testbed_route_status_changed`; it does not learn validation internals.

## Milestones

1. [x] Add final-clear validation state and event hooks.
2. [x] Reconcile feature-priority and split phase docs.
3. [x] Run Godot smoke checks, UI evidence capture, quality pass, and diff checks.
4. [x] Mark this ExecPlan done after validation and commit.

## Test Plan

- [x] `.\tools\godot.ps1 --path . --headless --import`
- [x] `.\tools\godot.ps1 --path . --headless --quit-after 3`
- [x] Render/check HUD with `res://tools/capture_ui_screenshots.gd`.
- [x] UI/UX gate hook after rendered evidence.
- [x] `git diff --check`

## Rollback / Safety

- Final-clear gating is isolated to `MotionTestStage.complete_stage()`. Reverting that override restores previous clear behavior.
- Destructible destroyed signal is additive and does not change combat damage semantics.
- Documentation updates are status reconciliation only; they do not redefine the PRD.

## Risks

- Some checks may be too strict for manual testing if they require taking hazard damage or defeating an enemy before exit.
- Generated route still uses a simplified deterministic builder rather than a full production generator.
- Plan docs may still contain granular unchecked manual QA items after reconciliation.

## Open Questions

- Decision: hazard contact remains required for the current final clear because the testbed is supposed to prove damage recovery.
- Decision: enemy/destructible reset remains deferred until the next combat-loop pass.

## Decision Notes

- Keep gate labels compact in the HUD to avoid a larger overlay redesign.
- Treat wall traversal as explicitly deferred, while rope climb and double jump remain testbed/debug abilities.
