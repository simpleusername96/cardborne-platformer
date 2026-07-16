---
type: record
status: active
owner: BK
last_reviewed: 2026-07-16
topic: Current Cardborne implementation state and verification entry points
source: Active specs, current Godot runtime, release gates, and rendered QA evidence
related:
  - ../docs/product/2d_platform_action_card_game_prd.md
  - ../docs/design/COMBAT_EQUIPMENT_CRAFTING.md
  - ../docs/design/PRODUCTION_UI_CONTRACT.md
  - ../docs/design/2D_PLATFORMER_MAP_DESIGN_GUIDELINE.md
  - ../docs/research/2d_platformer_map_design_research_2026-07-15.md
  - ../docs/architecture/FIRST_SLICE_ARCHITECTURE.md
  - ../docs/release/TRAVELER_EQUIPMENT_VERTICAL_SLICE.md
  - ./execplans/2026-07-15-gameplay-validity-repair.md
  - ./execplans/2026-07-15-master-ui-overhaul.md
  - ./execplans/2026-07-15-fixed-stage-map-enhancement.md
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
- Ruin Approach, Flooded Works, and Broken Sanctum use approved fixed layout V6
  plans. Slime Court remains the authored two-phase boss stage.
- Runtime-random topology is dormant until a separate re-entry plan proves broad
  route, recovery, and player-acceptance gates.
- The production card catalog contains five shared cards with no retired skill or
  class dependency.
- The active product contract specifies remappable keyboard actions: arrow keys
  move, `Space` jumps, `Left Shift` dashes, `X` attacks, `C` guards, `E`
  interacts, `A` uses a potion, and `Escape` pauses or goes back. Menus accept
  keyboard and mouse.
- The current product contract has no active skill, active-skill key, slot, or bar.

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
- Class selection, the former RestForge implementation, temporary affixes,
  generated equipment discovery,
  class HUD state, active skill slots, Spirit Arts, and resonance are retired.
- The integrated testbed remains deleted; focused validators and capture scripts
  own subsystem evidence.

## Current Status

- Main Menu enters Hero Preparation, Arsenal Trial, or a production expedition.
- Arrow/`Space`/`Left Shift`/`X`/`C`/`E`/`A`/`Escape` defaults, remapping,
  browser focus-loss release, and current-key prompts are implemented without a
  gameplay gamepad path.
- Lethal damage enters Retry Decision. Retry restores the current stage/boss entry
  snapshot; End Expedition is the only death settlement path.
- Held `C` reaches the production guard path with distinct normal block, precise
  block, guard break, condition/stability cost, and hurt feedback.
- Hero Preparation and Safe Intermission Forge expose six loadout slots, exact
  costs, current-versus-result values, command availability, and persistence state.
- Every normal-stage card reward enters the enemy-free Safe Intermission. Its
  merchant buys potions or sells run salvage; its Forge owns craft/recraft/repair/
  equip interaction, and neither appears in monster stages.
- The gameplay HUD shows health, objective/boss state, contextual attack pair,
  shield condition/stability, passive Spirit progress, potion charges,
  interactions, and reward receipts.
- Authored pickups cover healing, potion refill, arrows, cartridges, coins, and
  all active material grades. Fixed rewards unlock the Stage 1 alternatives and
  Frost Spirit Stone.
- Stage V6 composition is validated at Ruin `8 enemies / 720px`, Flooded
  `10 / 760px`, and Sanctum `12 / 740px`, with 9/9/11 meaningful elevation
  changes and 2/3/4 multi-elevation combat rooms respectively.
- All three normal stages, six committed-return fixtures, enemy/hazard families,
  card rewards, boss flow, retry/settlement, intermission, and profile restart
  recovery are in the active release matrix.
- The minimum equipment-progression ExecPlan is complete. The original SVG UI
  starter set now provides 6 structural masks and 22 semantic glyphs under
  `art/ui/production/`, with a rendered adoption catalog and Godot capture tool.
  The UI branch now owns the shared 16/18/20/22/32 type scale, 48px targets,
  English/Korean locale selection, centered merchant/Forge shells, and responsive
  shell/HUD/preparation/reward screens. The current visual batch adds the selected
  raster source set and production copies; Main Menu, shell Settings, Hero
  Preparation, and Run Result use an aspect-preserving cover renderer, while
  Forge preserves the live stage behind its centered modal. The larger UI
  migration remains active in the master UI overhaul plan.
- The UI overhaul branch now has one project-level flat Theme with fifteen
  semantic variations for buttons, surfaces, meters, and recurring text roles.
  `ProductionUIStyles.gd` owns only semantic tokens and dynamic flat-state helpers;
  focus and selection use a stable inside-left marker rather than a perimeter
  outline. Main Menu, Hero Preparation, Settings, Card Reward, and gameplay HUD
  provide the Milestone 2 representative proof.
- The first detailed UI illustration pack now provides 19 independent `512x512`
  RGBA assets for the Traveler, all active equipment and loadout items, the five
  active shared cards, Slime King, and the large Boss Core reward. The manifest,
  SVG fallbacks, prompts, and alpha-validation record are complete. The first
  runtime pass now shows them in Hero Preparation, Card Reward, and Run Result
  through one 52-ID asset registry; every retained asset has an explicit
  runtime, fallback, contextual, or deferred disposition.

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

# Active release gates: 72 core checks, 77 with persistence/runtime extensions
.\tools\validate_release_candidate.ps1
.\tools\validate_release_candidate.ps1 -Full

# Rendered evidence; run without --headless
.\tools\godot.ps1 --path . --script res://tools/capture_ui_screenshots.gd
.\tools\godot.ps1 --path . --script res://scripts/ui/validation/CaptureGameplayHUD.gd
.\tools\godot.ps1 --path . --script res://scripts/ui/validation/CaptureShellUI.gd
.\tools\godot.ps1 --path . --script res://tools/capture_fixed_stage_screenshots.gd
```

The accepted historical evidence is `68/68` Full checks on 2026-07-14. The current
2026-07-15 evidence is `70/70` core checks in 437.1 seconds plus rendered inspection
at `960x540`, `1280x720`, and `1920x1080` where applicable. The five extended
persistence/runtime checks were not rerun in that current pass.

The 2026-07-15 shell-background pass additionally passed the focused Shell UI,
Hero Preparation, Forge, and Run Result validators plus real OpenGL captures at
all three viewports. The core release suite was attempted but stopped at the
unchanged Arsenal Trial source-text guard: this UI worktree checks out CRLF while
the guard compares an LF-only literal. The relevant Git blobs match main and the
same validator passes in the main worktree, so this is checkout/test-harness
debt rather than a shell-background regression.

The 2026-07-16 easy-adoption pass added `validate_production_ui_assets.gd` to the
release matrix and passed the asset, Shell UI, Hero Preparation, Card Reward, and
Run Result gates. Real OpenGL captures cover all three supported viewports;
Hero Preparation and reward captures additionally cover English and Korean. The
full release suite and production Web export remain later plan gates.

The 2026-07-16 Theme foundation pass added
`tools/validate_production_ui_theme.gd` to the release matrix. It checks the
project Theme path, all fifteen semantic variations, zero-radius/no-perimeter
styleboxes, the reserved inside-left marker, flat meters, helper semantics, modal
ownership, and 48 px button targets. Shell, preparation, reward, HUD, Forge,
Merchant, intermission, result, boss, receipt, remap, pause, and production-boot
focused gates passed; rendered evidence covers English and Korean at all three
supported viewports. The full release suite and production Web export remain
Milestone 7 gates.

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

## Next Steps

The active cross-module implementation plan is
`.agent/execplans/2026-07-15-gameplay-validity-repair.md`. Its implemented runtime,
UI, and 70-check release-matrix work is complete; matching Godot 4.7 Web export
templates are still required before served-browser QA can close Milestone H.
The active visual follow-on is
`.agent/execplans/2026-07-15-master-ui-overhaul.md`: implement the visual migration
in the isolated `codex/master-ui-overhaul` worktree, selectively adopt existing
production UI assets, then integrate scoped UI commits onto the latest `master`.
World-presentation requirements are measured from runtime bounds instead of
conversation-chosen image counts.
The active map-composition follow-on is
`.agent/execplans/2026-07-15-fixed-stage-map-enhancement.md`: preserve the fixed
authored-room pipeline while replacing metric-only height with meaningful route,
combat, camera, and pacing verticality. Research and the canonical guideline are
complete; runtime map implementation begins with diagnostic strengthening and a
Ruin pilot pass.
Random map re-entry, larger equipment/content catalogs, multiple save slots, and
final world art remain separate decisions.
