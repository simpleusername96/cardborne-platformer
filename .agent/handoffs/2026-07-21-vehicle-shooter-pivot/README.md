---
type: handoff
status: done
owner: BK
created: 2026-07-21
last_reviewed: 2026-07-22
expires: 2026-08-21
source: Codex session 019f5f8c-1961-7fb0-950e-4adda7545294 and repository state at 4884ff4
related:
  - ../../../docs/research/vehicle_led_isometric_action_reference_analysis.md
  - ../../../docs/product/isometric_action_rpg_product_brief.md
  - ../../execplans/2026-07-18-flooded-works-floor1-map-enemies.md
---

# Cardborne Direction Handoff

## Current State

This folder preserves the complete product-direction thread from the UI/art work
through the side-view retirement, humanoid isometric proof, connected Flooded
Works implementation, sprite-production concern, and latest vehicle-shooter
hypothesis.

The most important state distinction is:

- The checked-in runtime and active product documents still describe a humanoid
  Traveler isometric action-RPG proof.
- The owner's latest discussion prefers testing a simpler vehicle-led shooter
  with manual targeting, rapid primary fire, passive secondary fire, Space dash,
  one `Z` area skill, field power-ups, fixed hazards, and card/equipment rewards.
- The vehicle direction has **not** been accepted as a replacement product spec
  and has not been implemented. It must not be represented as completed work.
- Isometric presentation versus flat top-down 2D remains an owner decision.

Do not resume the old Floor 1 plan automatically. First consume this handoff and
reconcile the latest product direction with the current active spec and policy.

## Read Order

1. [01-owner-feedback-history.md](./01-owner-feedback-history.md) — chronological
   record of all substantive owner feedback and direction changes.
2. [02-current-repository-state.md](./02-current-repository-state.md) — what is
   actually implemented, reusable, stale, dirty, or unverified.
3. [03-latest-product-hypothesis.md](./03-latest-product-hypothesis.md) — the
   latest vehicle-shooter idea, including confirmed preferences and open choices.
4. [04-art-assets-and-ui.md](./04-art-assets-and-ui.md) — retained visual rules,
   asset locations, production lessons, and cleanup state.
5. [05-resumption-checklist.md](./05-resumption-checklist.md) — the bounded steps
   for the next session before any broad implementation.

## Next Steps

- Have the owner accept or revise the vehicle-shooter hypothesis, especially the
  perspective, aiming input, base-stage scope, and defense/resource model.
- If accepted, replace or supersede the humanoid proof spec and active Floor 1
  plan through an explicit lifecycle change; do not silently edit their meaning.
- Build one graybox vertical slice before adding meta progression, exploration
  puzzles, broad content, or additional vehicles.
- Reuse only repository systems that match the accepted vehicle contract.

## Risks

- The active policy/spec/plan and the latest owner direction currently disagree.
- Existing assets and gameplay code can create false momentum toward the retired
  humanoid design.
- The project is 27 local commits ahead of the pre-handoff `origin/master`; this
  handoff is being added as the next scoped commit and the full local history is
  intended to be pushed at the owner's request.
- Many Godot `.import` files are modified and one is untracked. They predate this
  handoff and are deliberately excluded from its commit.
- Visual fidelity was repeatedly mistaken for gameplay progress. The next proof
  must validate movement, aiming, target priority, dash, and threat readability
  before producing broad UI or art sets.

## Files Touched

Only this handoff folder is owned by the handoff task. No runtime, asset, active
spec, policy, plan, or unrelated `.import` file is changed.

## Verification

- Compare this folder against session `019f5f8c-1961-7fb0-950e-4adda7545294`.
- Validate links and whitespace with `git diff --check`.
- Confirm the staged set contains only `.agent/handoffs/2026-07-21-vehicle-shooter-pivot/`.
