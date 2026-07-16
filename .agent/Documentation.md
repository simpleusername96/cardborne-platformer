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
- Stage V6 composition is validated at Ruin `8 enemies / 784px`, Flooded
  `10 / 896px`, and Sanctum `12 / 736px`, with 13/16/15 meaningful elevation
  changes and 2/3/4 multi-elevation combat rooms respectively.
- The fixed-stage enhancement pass has locked source-linked construction
  blueprints for all three normal stages. They preserve current room counts and
  stable IDs while defining forward rejoins, distinct height waveforms,
  stage-specific terminal policies, and the assembled-plan minimap contract.
- Ruin Approach now closes the pilot geometry milestone at `8 enemies / 784px`
  with two meaningful descents, two direction reversals, one forward rejoin,
  and zero near-limit required transitions. Its production runtime fixture
  continuously clears the required route with actual movement/jump input,
  drops into and climbs out of the optional cache, observes Walker/Shooter/
  Charger cycles, preserves minimap knowledge on fall recovery, and unlocks the
  exit after only the terminal encounter.
- Flooded Works now closes its basin/pump milestone at `10 enemies / 896px`
  with twelve meaningful descents, four meaningful ascents, one forward rejoin,
  and zero near-limit chains. Its production runtime fixture continuously
  traverses the route, crosses the required rope in both directions, resets a
  real poison hazard on retry, exercises multi-destination Leaper and Pump
  Gallery combat, preserves minimap knowledge, and unlocks the shelter exit only
  after actual terminal-room arrival while earlier enemies remain alive.
- Broken Sanctum now closes its distributed-route milestone at
  `12 enemies / 736px` with three meaningful descents, four direction reversals,
  two forward rejoins, and zero near-limit transitions. Its production runtime
  fixture opens the gate shortcut, continuously clears the required supports,
  traverses both optional routes, preserves the active Cloister checkpoint on
  the minimap, exercises Charger/Leaper/Shooter/Sentry terrain roles, and opens
  the exit after only the terminal encounter.
- The cross-stage cohesion pass assigns an authored terrain relation to all 30
  active enemy placements, preserves a 240 px recovery-backed entry buffer for
  every combat room, and confirms distinct assembled collision silhouettes.
  Shooter/Sentry warnings remain 96 px, Charger warnings are 128 px, and no
  ordinary enemy uses an activation-range trajectory overlay.
- Normal-stage completion now follows typed terminal policy: Ruin and Sanctum
  require only their terminal-room encounter, while Flooded Works uses shelter
  arrival. Earlier and optional enemies no longer own the exit or HUD objective.
- The normal-stage HUD now renders a top-right fog-of-war minimap from the
  accepted StagePlan/assembly snapshot. Visited knowledge persists across a
  same-stage retry, while reward, checkpoint, gate, and exit state remain live
  stage facts.
- Shared traversal/combat terrain contracts now cover centered bidirectional
  rope use through one-way tops, solid-cover projectile termination,
  destination-selected Leaper movement, and wall/ledge response for mobile
  patrol enemies. Ordinary-enemy warnings use local direction/destination cues
  instead of full trajectories.
- All three normal stages, six committed-return fixtures, enemy/hazard families,
  card rewards, boss flow, retry/settlement, intermission, and profile restart
  recovery are in the active release matrix.
- The minimum equipment-progression and master UI-overhaul ExecPlans are complete.
  The production set provides 6 structural masks, 22 semantic glyphs, 5 reviewed
  shell backgrounds, 19 detailed illustrations, and one bundled bilingual font
  under `art/ui/production/`. The runtime uses the shared 16/18/20/22/32 type
  scale, 48px targets, English/Korean locale selection, centered merchant/Forge
  shells, responsive shell/HUD/preparation/reward screens, and context-sensitive
  backdrops. Forge and in-run Settings preserve the live stage.
- The integrated UI now has one project-level flat Theme with fifteen
  semantic variations for buttons, surfaces, meters, and recurring text roles.
  `ProductionUIStyles.gd` owns only semantic tokens and dynamic flat-state helpers;
  focus and selection use a stable inside-left marker rather than a perimeter
  outline. Noto Sans KR Variable is the deterministic desktop/Web Theme font and
  ships with its OFL-1.1 text and exact provenance record.
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
.\tools\godot.ps1 --path . --headless --script res://tools/validate_ruin_stage_runtime.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_flooded_stage_runtime.gd
```

The accepted historical evidence is `68/68` Full checks on 2026-07-14 and `70/70`
core checks on 2026-07-15. The current integrated evidence is `77/77` Full checks
on 2026-07-16 (`RELEASE_CANDIDATE_MATRIX_OK checks=77 full=True seconds=634.6`),
plus rendered inspection at `960x540`, `1280x720`, and `1920x1080`.

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
Hero Preparation and reward captures cover English and Korean.

The 2026-07-16 Theme foundation pass added
`tools/validate_production_ui_theme.gd` to the release matrix. It checks the
project Theme path, all fifteen semantic variations, zero-radius/no-perimeter
styleboxes, the reserved inside-left marker, flat meters, helper semantics, modal
ownership, and 48 px button targets. Shell, preparation, reward, HUD, Forge,
Merchant, intermission, result, boss, receipt, remap, pause, and production-boot
focused gates passed; rendered evidence covers English and Korean at all three
supported viewports.

The 2026-07-16 final integration passed the full release matrix and the Godot 4.7
production Web export. The build was served through the canonical codex-lane port;
all observed resources returned HTTP 200 and the browser reported no warning or
error. Real browser interaction covered Main Menu, Hero Preparation, Settings,
language/remap persistence, Trial/skip, stage launch, pause/resume, and live
Canvas movement/jump/attack. Deterministic validators and captures cover the full
three-stage, reward, intermission, retry/end, boss, result, locale, and viewport
path. The served build also exposed and verified the fix for missing Korean host
fallback by bundling Noto Sans KR Variable in the project Theme.

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

The gameplay-validity and master UI-overhaul plans are complete. Their runtime,
UI, `77/77` full release, production Web export, and served-browser evidence are
landed on the validated integration line. World-presentation requirements remain
measured from runtime bounds instead of conversation-chosen image counts.
The active map-composition follow-on is
`.agent/execplans/2026-07-15-fixed-stage-map-enhancement.md`: preserve the fixed
authored-room pipeline while replacing metric-only height with meaningful route,
combat, camera, and pacing verticality. Its existing progress remains independent
of this completed UI migration.
Random map re-entry, larger equipment/content catalogs, multiple save slots, and
the remaining nine panorama panels, broader terrain rollout, actor animation,
native-HD shell replacements, and final world art remain separate decisions.
