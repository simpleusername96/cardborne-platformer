# .agent/Documentation.md

## Current Status

- Cardborne boots into a production menu, character/loadout/mastery selection,
  deterministic Ruin Approach and Flooded Works stages, stage rewards, cards, and
  the Rest & Forge transition that prepares Stage 3.
- The integrated `MotionTestStage`, debug HUD, testbed inputs/flags, historical
  handoff package, fixed-grid maps, and generated wireframe prototype were retired
  on 2026-07-12. Git history preserves them if a focused investigation needs them.
- Warrior, Archer, and Assassin each have a typed Basic, Heavy, three skills, six
  mastery effects, two character cards, and character-compatible weapon behavior.
  Flooded Works adds exact Walker, Charger, Shooter, and Leaper variants plus
  poison/crumble/rope content.
- Persistent profile v1, twelve equipment items, eighteen mastery nodes, material
  settlement, loadouts, save recovery, temporary forge, and scoped consumables are
  active production systems.
- `docs/product/2d_platform_action_card_game_prd.md` is the canonical product and
  first-complete-run blueprint.
- Active content specs under `docs/design/` define characters, progression,
  equipment, economy, terrain, rooms, generation, enemies, hazards, boss, and
  player-facing flow.
- `docs/architecture/FIRST_SLICE_ARCHITECTURE.md` defines runtime ownership and
  implementation boundaries.
- `.agent/execplans/2026-07-12-actual-game-production-roadmap.md` is the only active
  ExecPlan.
- JSON under `data/design/first_slice/` is accepted migration input for future typed
  Godot Resources, not a runtime schema.

## Authority

Read in this order:

1. Root and nearest `AGENTS.md`.
2. `docs/README.md`.
3. Canonical product blueprint.
4. Active design and architecture specs.
5. Active production roadmap for execution order.
6. Current code/tests as implementation evidence.
7. Research/reference documents as advisory evidence.

## Durable Decisions

- Use Godot 4.7 stable and GDScript.
- Build a 28-38 minute first run: three generated normal stages and one authored
  two-phase boss.
- Preserve one shared baseline movement envelope for Warrior, Archer, and Assassin.
- Generate Stage Plans from authored native Godot room scenes and typed metadata;
  do not scatter arbitrary platforms or content coordinates.
- Use `MovementMetrics` and full-stage validation before stage load.
- Model normal enemies as stable behavior archetypes plus exact stage variants;
  tuning profiles validate authored bounds and never multiply runtime stats again.
- Keep direct damage deterministic. Player critical hits require declared earned
  conditions; enemies, hazards, and secondary hits do not critical by default.
- Keep rewards and persistent writes transaction-safe and idempotent.
- Use run levels for small support choices, cards for behavior changes, coins for
  tactical spending, equipment for loadout tradeoffs, and mastery for persistent
  kit variants.
- Temporary forging offers a deterministic choice; it has no failure, downgrade,
  or destruction result.
- Do not adopt an external package/asset without explicit approval, version/license
  record, isolated spike, wrapper/removal boundary, and acceptance evidence.
- Every implementation batch after the first combat contract must extend a visible
  playable run path and be evaluated against the fun contract.

## Current Risks

- Archer and Assassin rules are isolated behind character combat runtimes. The
  shared controller still retains legacy Warrior helper implementation and should
  shed it during the final structural quality pass rather than absorb new rules.
- Broken Sanctum, remaining normal content, the boss, and end-to-end settlement do
  not exist yet.
- Flooded Works has deterministic geometry/runtime coverage, but complete-run
  difficulty and pacing still need Milestone 9 playtest tuning.
- JSON design catalogs remain migration inputs until all typed runtime content lands.

## Run / Verify

- Godot version: `./tools/godot.ps1 --version`
- Import: `./tools/godot.ps1 --path . --headless --import`
- Short boot: `./tools/godot.ps1 --path . --headless --quit-after 2`
- Production flow: `./tools/godot.ps1 --path . --headless --script res://tools/validate_production_boot.gd`
- Production stage: `./tools/godot.ps1 --path . --headless --script res://tools/validate_production_stage.gd`
- Flooded generation: `./tools/godot.ps1 --path . --headless --script res://tools/validate_flooded_generation.gd`
- Flooded runtime: `./tools/godot.ps1 --path . --headless --script res://tools/validate_flooded_stage_runtime.gd`
- Warrior combat: `./tools/godot.ps1 --path . --headless --script res://tools/validate_warrior_combat_runtime.gd`
- Complete Warrior: `./tools/godot.ps1 --path . --headless --script res://tools/validate_warrior_m5_runtime.gd`
- Roster matrix: `./tools/godot.ps1 --path . --headless --script res://tools/validate_roster_stage_matrix.gd`
- Enemy catalog: `./tools/godot.ps1 --path . --headless --script res://tools/validate_enemy_catalog.gd`
- Design catalogs: `./tools/godot.ps1 --path . --headless --script res://tools/validate_design_catalogs.gd`
- Focused validators: `Get-ChildItem tools/validate_*.gd`
- Git status: `git status --short`

## Next Implementation Entry

Start Milestone 7 by generalizing normal-stage planning for an 8+2 Broken Sanctum
graph, then land Sanctum enemies, special actors, moving platforms, reward sources,
rooms, remaining shared cards, and the Stage 3-to-boss loading seam. Keep aggregate
catalog and run-flow edits under one integration owner.
