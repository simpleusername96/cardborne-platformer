---
type: plan
status: active
owner: BK
created: 2026-07-20
topic: Vehicle-led Stage 1 experimental replacement
scope: Implement, validate, build, and publish one complete manually targeted vehicle shooter stage
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../handoffs/2026-07-21-vehicle-shooter-pivot/README.md
  - ../../docs/product/vehicle_stage_one_experimental_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
---

# Vehicle Stage One Execution Plan

## Why / Context

The checked-in humanoid proof established useful Godot, collision, settings, and UI infrastructure but retained melee, guard, potion, sprite-animation, and encounter assumptions that do not test the latest owner direction. This feature branch is an explicitly authorized experiment: one complete vehicle-led stage whose core decision is manual target priority under readable moving and fixed pressure.

## Scope / Non-scope

In scope: one continuous authored Stage 1; direct keyboard movement and mouse/right-stick aim; rapid manual primary fire; passive auto-seeker support; Space dash; one `Z` area skill; four temporary pickup families; ten behavior-changing run upgrades; role-based enemies and installations; an optional elite; a two-phase stage boss; deployment, HUD, pause/settings, result, and compact garage; minimal persistent module unlocks; focused validators; Web export; rendered evidence; and a PR.

Out of scope: humanoid melee/guard/potion compatibility, crafting, rarity tiers, a skill tree, procedural maps, exploration puzzles, multiple vehicles, a walkable base, story content, or external asset dependencies.

## Assumptions

- Flat top-down 2D is the bounded perspective decision for this experiment because manual aim, projectile/cover agreement, and threat attribution are the highest-risk questions.
- The accepted drowned-foundry palette and flat, borderless, low-noise presentation remain authoritative.
- Project-owned Godot drawing primitives and generated waveforms are sufficient for this proof; no third-party art or audio is required.
- Ordinary route progress may depend on explicit installations and reward activation, but never on exterminating all living enemies. Only the stage boss arena locks.

## Proposed Design

`VehicleStageOne` owns the authored stage runtime and delegates immutable stage constants, authored geometry, upgrade definitions, and reusable collision/reachability helpers to `VehicleStageRules`. `VehicleStageUI` owns live HUD and modal composition. The existing `PivotRoot` keeps input registration and settings continue through the existing autoload.

The world is one 5,200 × 2,200 ground plane. Deployment and tutorial occupy the west end; an open combat yard leads to an installation fork with upper and lower routes; two support generators expose the relay cache; the northern route contains a bypassable Dredge Warden; the eastern basin is a dedicated Foundry Colossus arena. A grid reachability validator checks authored traversal around cover, and all ordinary projectiles use the same segment-versus-cover truth.

## Milestones

1. Replace the boot path and humanoid controls with the vehicle input contract.
2. Implement vehicle movement, hull/turret feedback, primary/passive/skill/dash, collision, feedback, and temporary field states.
3. Author the continuous world, role-based roster, installations, route choice, optional elite, cache cards, boss, objectives, and non-extermination flow.
4. Add deployment, HUD, minimap fog, upgrade, pause/settings, result, and garage surfaces.
5. Add focused headless validation, capture automation, Web export, built-browser boot evidence, and artifact upload.
6. Record concrete playtest findings and publish the feature branch and PR.

## Test Plan

- Headless project import.
- Blueprint and reachability validation for entrances, routes, live spawns, generators, cache, and boss gate.
- Exact input-map checks for arrows/WASD, mouse/Shift primary, Space dash, `Z` skill, right-stick aim, and Escape.
- Projectile-versus-cover checks for player and hostile projectiles.
- Passive-secondary line-of-sight and cadence checks.
- Dash displacement, cooldown, invulnerability, and offensive-upgrade checks.
- Four pickup-state checks.
- Upgrade idempotency, reset, and immediately visible behavior checks.
- Full scripted route with ordinary enemies alive at boss entry, boss completion, result, and replay reset.
- Layout checks at 960×540, 1280×720, and 1920×1080.
- Web release export, local HTTP boot, browser-render screenshot, and native rendered capture set.

## Rollback / Safety

All work remains on `agent/vehicle-stage-one`. Master is never rewritten or force-pushed. The branch changes the main scene and input contract but does not delete the prior 3D runtime, so reverting the branch restores the humanoid proof. No generated/import churn is staged. Save data uses a new isolated `vehicle-stage-one.cfg` path.

## Risks

- A custom-drawn runtime can be mechanically complete while still needing later bespoke raster art.
- A single large script is acceptable for a bounded proof but should be decomposed if the experiment is accepted.
- Automated routes verify contracts, not enjoyment; concrete rendered review and direct play observations remain required.
- Browser GPU availability can affect screenshot capture even when export succeeds; CI records the exact boot method and artifact.

## Open Questions

None block this branch. Longer-term view, content, and progression choices belong in the separate future-directions document after Stage 1 evidence exists.

## Decision Notes

- 2026-07-20: selected flat top-down 2D to maximize aiming, collision, cover, scale, and threat readability.
- 2026-07-20: selected a responsive hover skiff with direct strafe movement, movement-following hull, and independently aimed turret.
- 2026-07-20: selected project-owned geometry and procedural audio, avoiding all third-party adoption work.
- 2026-07-20: kept the garage compact and menu-based so combat implementation remains the primary slice.
