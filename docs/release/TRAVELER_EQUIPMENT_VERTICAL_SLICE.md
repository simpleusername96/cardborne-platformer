---
type: record
status: active
owner: BK
created: 2026-07-14
last_reviewed: 2026-07-15
topic: One-Traveler equipment-progression vertical slice
scope: Implemented production flow, validation evidence, and retained limitations
source: Completed minimum equipment-progression ExecPlan and validated Godot runtime
supersedes: ./FIRST_COMPLETE_RUN_RC1.md
related:
  - ../product/2d_platform_action_card_game_prd.md
  - ../design/COMBAT_EQUIPMENT_CRAFTING.md
  - ../design/PRODUCTION_UI_CONTRACT.md
  - ../../.agent/execplans/2026-07-14-minimum-equipment-progression-vertical-slice.md
---

# Traveler Equipment-Progression Vertical Slice

## Context

The former three-class RC1 proved that the movement, encounter, card, stage, and
boss components could complete a run, but it did not deliver the intended
persistent equipment loop. This release record closes that migration around one
Traveler and approved fixed stages.

## Decision

The active production run now contains:

- one persistent Traveler with double jump, dash, contextual attack, and a
  dedicated shield guard;
- six combat-tool models, two armor models, two passive Spirit Stones, one potion,
  six active material IDs, and two deterministic material grades;
- blueprint unlocks, craft, Grade 2 recraft, repair, condition, arrows,
  cartridges/reload, stage-entry maintenance, and automatic profile v2 saving;
- a skippable five-room Arsenal Trial whose completion and skip paths apply the
  same idempotent baseline transaction;
- three approved fixed normal stages, guaranteed recovery paths and supplies,
  authored enemy/hazard/reward placements, and the two-phase Slime King fight;
- Hero Preparation, deterministic Forge, contextual equipment HUD, field pickup
  and permanent reward receipts, shared card rewards, pause/settings, and run
  results at all three target viewport sizes under Godot render checks;
- five production cards that do not depend on retired class skills or cooldowns.

Runtime-random topology remains dormant. Historical class catalogs and v1 profile
fields remain only as migration and focused fixture evidence; production does not
offer class selection, class skills, temporary affixes, or random equipment drops.

## Rationale

The first playable baseline should prove one complete decision loop before adding
more content: fight and explore, obtain a visible blueprint or material, make a
deterministic equipment decision, use the changed behavior in the next encounter,
and recover that state after restarting the app. Fixed authored maps isolate
combat, reward, and progression quality from procedural-topology risk.

## Verification

- `validate_release_candidate.ps1 -Full -SkipImport` passed `68/68` active checks
  on 2026-07-14.
- The matrix covers Traveler movement/combat, equipment data and commands, profile
  v2 migration/persistence, Trial parity, all three fixed stages, drops and fall
  recovery, enemies/hazards, UI, cards/rewards, boss flow, and settlement.
- Progression, shell, gameplay HUD, and fixed-stage capture scripts rendered with
  Godot 4.7 at `960x540`, `1280x720`, and `1920x1080` where applicable.
- Browser export remains unverified because the repository has no export preset.
- `git diff --check`, Godot import, short boot, and task-scoped legacy-term guards
  are the final handoff gates.

## Consequences

- New gameplay work starts from one Traveler and the typed
  `EquipmentProgressionCatalog`; selectable classes are not a production extension
  point.
- New equipment behavior requires a model, blueprint/recipe, runtime resolver
  support, acquisition source, truthful UI preview, and focused validation.
- A later random-map re-entry needs a separate plan, broad seed properties, full
  route and recovery checks, and player acceptance against these fixed baselines.
- Placeholder geometry, vector actors, and synthesized audio remain prototype
  presentation rather than final commercial assets.

## Alternatives

- Keeping the three-class RC1 as production was rejected because it split combat,
  equipment, and mastery ownership and did not support the requested crafting loop.
- Re-enabling random topology now was rejected because it would confound combat
  and progression tuning with traversal-generation failures.

## Related

- `FIRST_COMPLETE_RUN_RC1.md` remains the superseded three-class baseline.
- Rendered evidence is reproducible under `.codex-runtime/uiux/` and is not tracked.
