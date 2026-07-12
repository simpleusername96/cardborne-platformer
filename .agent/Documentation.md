# .agent/Documentation.md

## Current Status

- Cardborne boots into a production menu, character selection, and a safe authored
  entry-stage scaffold.
- The integrated `MotionTestStage`, debug HUD, testbed inputs/flags, historical
  handoff package, fixed-grid maps, and generated wireframe prototype were retired
  on 2026-07-12. Git history preserves them if a focused investigation needs them.
- Shared movement, movement metrics, damage, hit/hurt, enemy, checkpoint, hazard,
  interactable, stage, input-remap, character-profile, and player-build foundations
  remain available for production work.
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

- The production entry stage is only a safe scaffold, not credited Stage 1 content.
- Character profiles have basic-attack seeds but heavy attacks, skills, passives,
  cards, progression, and persistence are not implemented.
- Enemy scripts are behavior prototypes; design catalog v2 now defines six
  archetypes and 13 variants, but typed Resources, production scenes, and allocator
  integration remain unimplemented.
- JSON catalogs and docs are implementation-ready inputs but not runtime owners.
- Fun remains unproven until real room/combat/reward playtests begin.

## Run / Verify

- Godot version: `./tools/godot.ps1 --version`
- Import: `./tools/godot.ps1 --path . --headless --import`
- Short boot: `./tools/godot.ps1 --path . --headless --quit-after 2`
- Production flow: `./tools/godot.ps1 --path . --headless --script res://tools/validate_production_boot.gd`
- Production stage: `./tools/godot.ps1 --path . --headless --script res://tools/validate_production_stage.gd`
- Design catalogs: `./tools/godot.ps1 --path . --headless --script res://tools/validate_design_catalogs.gd`
- Focused validators: `Get-ChildItem tools/validate_*.gd`
- Git status: `git status --short`

## Next Implementation Entry

Start from Milestone 1 in the active production roadmap: deterministic damage and
earned critical resolution, typed character combat, Ruin Walker/Charger variants,
and a Warrior combat slice in one authored production room. Do not spend another
batch on menu polish or generic foundations.
