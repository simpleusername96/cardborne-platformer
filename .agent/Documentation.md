---
type: record
status: active
owner: BK
last_reviewed: 2026-07-15
topic: Current Cardborne implementation state and verification entry points
source: Active specs, current Godot runtime, release gates, and rendered QA evidence
related:
  - ../docs/product/2d_platform_action_card_game_prd.md
  - ../docs/design/COMBAT_EQUIPMENT_CRAFTING.md
  - ../docs/design/PRODUCTION_UI_CONTRACT.md
  - ../docs/architecture/FIRST_SLICE_ARCHITECTURE.md
  - ../docs/release/TRAVELER_EQUIPMENT_VERTICAL_SLICE.md
---

# Project Documentation Memory

## Context

Cardborne is a compact 2D action-platform roguelite vertical slice. The former
three-class RC1 was migrated to one persistent Traveler whose combat behavior
changes through deterministic equipment, blueprints, material grades, and one
passive Spirit Stone.

## Decision

- Production has one Traveler with shared movement, contextual melee/ranged
  attack, and a separate shield guard.
- The active equipment scope is 6 combat tools, 2 armor models, 2 passive Spirit
  Stones, 1 potion, 3 material families, and 2 material grades.
- Blueprint unlock, craft, Grade 2 recraft, repair, condition, arrows,
  cartridges/reload, stage-entry maintenance, and profile v2 persistence are
  active production systems.
- The Arsenal Trial is fixed and skippable. Complete and skip apply the same
  idempotent mechanical baseline.
- Ruin Approach, Flooded Works, and Broken Sanctum use approved fixed layout V5
  plans. Slime Court remains the authored two-phase boss stage.
- Runtime-random topology is dormant until a separate re-entry plan proves broad
  route, recovery, and player-acceptance gates.
- The production card catalog contains five shared cards with no retired skill or
  class dependency.
- The active product contract specifies remappable keyboard actions, with `J`
  context attack, `K` guard, `E` world interaction, `R` consumable, `Space` jump,
  and `Left Shift` dash as defaults. Menus accept keyboard and mouse.
- The current active-skill count is zero. A later playtest-backed experiment is
  capped at one and may not create a multi-slot skill bar.

## Rationale

Fixed stages and one hero isolate the quality of movement, combat, rewards, and
equipment progression from procedural-map failures and class-owned duplication.
The slice proves the full acquire, craft, equip, use, save, and reload loop before
adding more content or random topology.

## Consequences

- `data/hero/traveler.tres` and
  `data/equipment/equipment_progression_catalog.tres` are the active hero and
  equipment roots.
- Character, skill, mastery, and old equipment-item data remain only for v1 save
  migration and focused historical fixtures. They must not re-enter production
  screens, inputs, rewards, or stage requirements.
- Class selection, RestForge, temporary affixes, generated equipment discovery,
  class HUD state, active skill slots, Spirit Arts, and resonance are retired.
- The integrated testbed remains deleted; focused validators and capture scripts
  own subsystem evidence.

## Current Status

- Main Menu enters Hero Preparation, Arsenal Trial, or a production expedition.
- Hero Preparation and Forge expose six loadout slots, exact costs,
  current-versus-result values, command availability, and persistence state.
- The gameplay HUD shows health, objective/boss state, contextual attack pair,
  shield condition/stability, passive Spirit progress, potion charges,
  interactions, and reward receipts.
- Authored pickups cover healing, potion refill, arrows, cartridges, coins, and
  all active material grades. Fixed rewards unlock the Stage 1 alternatives and
  Frost Spirit Stone.
- All three normal stages, six committed-return fixtures, enemy/hazard families,
  card rewards, boss flow, settlement, and profile restart recovery are in the
  active release matrix.
- The minimum equipment-progression ExecPlan is complete. The original SVG UI
  starter set now provides 6 structural masks and 22 semantic glyphs under
  `art/ui/production/`, with a rendered adoption catalog and Godot capture tool.
  No production screen has adopted the assets yet, and there is no active
  implementation plan after this bounded pass.

## Authority

Read in this order:

1. Root and nearest `AGENTS.md`.
2. `docs/README.md`.
3. `docs/product/2d_platform_action_card_game_prd.md`.
4. Active design and architecture specs.
5. A new active ExecPlan, when the owner starts another cross-module milestone.
6. Current code, typed Resources, validators, and the release record as
   implementation evidence.
7. Superseded plans and research only as historical or advisory evidence.

## Compatibility Boundary

- `ProfileSaveService` reads representative v1 saves and converts known old
  equipment through fixed salvage rules before validating schema v2.
- Compatibility fields and facades in `ProfileData`, `ProfileState`, reward
  transactions, and non-shared combat fixtures are not production authorities.
- Active reward tables leave legacy equipment-pool fields empty.
- Dormant random-planner scripts remain available for focused research but are not
  part of the production launch path or default release authority.

## Verification

```powershell
# Runtime and import
.\tools\godot.ps1 --version
.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --quit-after 2

# Active release gates: 63 core checks, 68 with persistence/runtime extensions
.\tools\validate_release_candidate.ps1
.\tools\validate_release_candidate.ps1 -Full

# Rendered evidence; run without --headless
.\tools\godot.ps1 --path . --script res://tools/capture_ui_screenshots.gd
.\tools\godot.ps1 --path . --script res://scripts/ui/validation/CaptureGameplayHUD.gd
.\tools\godot.ps1 --path . --script res://scripts/ui/validation/CaptureShellUI.gd
.\tools\godot.ps1 --path . --script res://tools/capture_fixed_stage_screenshots.gd
```

The accepted 2026-07-14 evidence is `68/68` active Full checks plus rendered
inspection at `960x540`, `1280x720`, and `1920x1080` where applicable.

## Risks

- Actor, terrain, UI icon, audio, and effects are coherent prototype presentation,
  not final commercial assets.
- Automated gates prove contracts and deterministic scenarios; human playtesting
  must still tune attack intent, encounter pacing, material totals, and condition
  drain against the fun contract.
- A dedicated global reduced-motion mode is deferred. Screen shake and damage
  flash are independently switchable, and current production panels avoid large
  spatial transitions.
- Compatibility code increases maintenance surface until v1 migration support is
  intentionally retired in a separate owner-approved cleanup.
- Current runtime input still contains `F/G/H` defaults, fixed gamepad behavior,
  Settings presentation, and validators from the former contract. These are
  implementation drift, not current product requirements.

## Next Steps

No task from the completed migration or SVG asset catalog plans remains. The next
cross-module feature should start with a new ExecPlan grounded in owner feedback.
Production-screen SVG adoption, random map re-entry, active skills, larger
equipment/content catalogs, multiple save slots, and final world art remain
separate decisions rather than implied continuation work.
