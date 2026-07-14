# .agent/Documentation.md

## Current Status

- The released code is still the three-profile Warrior/Archer/Assassin v1 runtime.
  The active product target changed on 2026-07-14 to one persistent hero whose two
  weapons and complete equipment loadout define combat. No code migration should be
  reported complete until the active arsenal ExecPlan batch gates pass.

- Cardborne boots into a production menu, character/loadout/mastery selection,
  three versioned approved fixed normal stages, stage rewards, cards, and the Rest
  & Forge transition.
- Fixed layout V3 is the active normal-stage contract. Six committed-return
  scenarios are statically validated and replayed with Warrior, Archer, and
  Assassin; the random planner remains dormant in production and the default
  release matrix.
- Fixed field pickups now provide authored healing, consumable, cooldown, coin, and
  material beats. The live HUD exposes six action slots, consumable charges, class
  state, objective/boss state, and non-modal prompt/reward receipts.
- Character/loadout, reward choices, Rest & Forge, pause/settings, and result screens
  now expose authoritative availability and current-versus-result information.
  Loadout and Rest & Forge also rebuild between compact and regular layouts after a
  live window resize while preserving screen state and focus intent.
- The integrated `MotionTestStage`, debug HUD, testbed inputs/flags, historical
  handoff package, fixed-grid maps, and generated wireframe prototype were retired
  on 2026-07-12. Git history preserves them if a focused investigation needs them.
- Warrior, Archer, and Assassin each have a typed Basic, Heavy, three skills, six
  mastery effects, two character cards, and character-compatible weapon behavior.
  Broken Sanctum completes the six-archetype normal roster and adds two branches,
  shield/flank and sentry/cover encounters, a gate loop, moving platform, chest,
  material node, and constrained mixed pressure.
- Persistent profile v1, twelve equipment items, eighteen mastery nodes, material
  settlement, loadouts, save recovery, temporary forge, and scoped consumables are
  active production systems.
- All fifteen cards are production-reachable. `Treasure Instinct` pauses an
  optional chest on an exclusive normal-versus-equipment/free-forge choice whose
  single transaction ID prevents duplicate settlement.
- Slime Court completes the run with four exact warned patterns, two phases,
  stagger, two capped adds, boss HUD, exactly-once Boss Core settlement, and a
  final build/material summary. Fixed gamepad controls and automatic prompt
  switching are active alongside keyboard remapping.
- A project-original procedural presentation family supplies distinct actor
  silhouettes, regional terrain, hit feedback, bounded camera response, and ten
  synthesized gameplay cues. Pause, settings return, and abandon confirmation are
  complete production states.
- `docs/product/2d_platform_action_card_game_prd.md` is the canonical product and
  first-complete-run blueprint. `docs/design/ARSENAL_EQUIPMENT_PROGRESSION.md` is
  the canonical target for the one-hero arsenal, full equipment, onboarding, and
  save continuity.
- The old character and progression/equipment specs are superseded v1 migration
  evidence. Active content specs continue to own terrain, rooms, generation,
  enemies, hazards, boss, and player-facing flow.
- `docs/architecture/FIRST_SLICE_ARCHITECTURE.md` defines runtime ownership and
  implementation boundaries.
- `.agent/execplans/2026-07-14-single-hero-arsenal-migration.md` is the active plan.
  The 2026-07-13 refinement plan is superseded; its unfinished traversal and UI
  gates are carried forward.
- `.agent/execplans/2026-07-12-actual-game-production-roadmap.md` remains the completed
  first-run implementation record.
- Provisional design JSON was retired after all runtime owners moved to typed Godot
  Resources. Git history remains the archive.

## Authority

Read in this order:

1. Root and nearest `AGENTS.md`.
2. `docs/README.md`.
3. Canonical product blueprint.
4. Active design and architecture specs.
5. A new active ExecPlan, when one exists, for execution order.
6. Current code/tests as implementation evidence.
7. Research/reference documents as advisory evidence.

## Durable Decisions

- Use Godot 4.7 stable and GDScript.
- Build a 28-38 minute first run: three approved fixed normal stages and one
  authored two-phase boss. Keep procedural selection dormant until the complete
  gameplay loop and fixed-stage baselines are accepted.
- Use one persistent hero with a shared baseline movement envelope. Reclassify the
  existing Warrior, Archer, and Assassin kits as Sword & Shield, Bow, and Twin
  Blades before authoring Spear, Great Axe, or Matchlock.
- Assemble versioned Stage Plans from authored native Godot room scenes and typed
  metadata; do not scatter arbitrary platforms or content coordinates.
- Use `MovementMetrics` and full-stage validation before stage load.
- Model normal enemies as stable behavior archetypes plus exact stage variants;
  tuning profiles validate authored bounds and never multiply runtime stats again.
- Keep direct damage deterministic. Player critical hits require declared earned
  conditions; enemies, hazards, and secondary hits do not critical by default.
- Keep rewards and persistent writes transaction-safe and idempotent.
- Use run levels for small support choices, cards for run-local behavior changes,
  coins for tactical spending, two weapons plus support equipment for preparation,
  deterministic enhancement for item investment, and mastery for persistent
  discipline variants.
- Persistent profile v1 autosave/backup exists. Player-facing profile slots,
  checkpoint run suspension, Save & Return, and Continue do not exist yet and are
  owned by the active migration plan.
- Temporary forging offers a deterministic choice; it has no failure, downgrade,
  or destruction result.
- Do not adopt an external package/asset without explicit approval, version/license
  record, isolated spike, wrapper/removal boundary, and acceptance evidence.
- Every implementation batch after the first combat contract must extend a visible
  playable run path and be evaluated against the fun contract.

## Current Risks

- Presentation is a coherent project-original prototype family, not final
  commercial art or recorded audio.
- Automated balance covers deterministic complete-run simulations; human feel and
  onboarding feedback should drive the next tuning plan.
- Full production-style v1 runs remain migration baselines. Fresh-player UI
  recognition, pickup audio, reduced-motion polish, and broad clearance fixtures
  are carried into the active arsenal plan's release gates.
- Current return replay begins from stable post-drop recovery. Full
  branch-entry-to-return collision sweeps and invalid ceiling/wall/hazard fixtures
  remain required before authored traversal coverage is complete.
- Broadening room, enemy, card, or boss content will expand the approved-plan and
  weapon-pair matrices and must preserve the shared hero traversal contract.

## Run / Verify

- Godot version: `./tools/godot.ps1 --version`
- Import: `./tools/godot.ps1 --path . --headless --import`
- Short boot: `./tools/godot.ps1 --path . --headless --quit-after 2`
- Production flow: `./tools/godot.ps1 --path . --headless --script res://tools/validate_production_boot.gd`
- Production stage: `./tools/godot.ps1 --path . --headless --script res://tools/validate_production_stage.gd`
- Approved Stage Plans: `./tools/godot.ps1 --path . --headless --script res://tools/validate_curated_stage_plans.gd`
- Fixed committed returns: `./tools/godot.ps1 --path . --headless --script res://tools/validate_fixed_drop_runtime.gd`
- Fixed field pickups: `./tools/godot.ps1 --path . --headless --script res://tools/validate_fixed_field_pickup_manifest.gd`
- Gameplay HUD: `./tools/godot.ps1 --path . --headless --script res://tools/validate_gameplay_hud.gd`
- Production shell UI: `./tools/godot.ps1 --path . --headless --script res://tools/validate_shell_ui.gd`
- Flooded generation: `./tools/godot.ps1 --path . --headless --script res://tools/validate_flooded_generation.gd`
- Flooded runtime: `./tools/godot.ps1 --path . --headless --script res://tools/validate_flooded_stage_runtime.gd`
- Sanctum generation: `./tools/godot.ps1 --path . --headless --script res://tools/validate_broken_sanctum_generation.gd`
- Sanctum runtime: `./tools/godot.ps1 --path . --headless --script res://tools/validate_broken_sanctum_runtime.gd`
- Warrior combat: `./tools/godot.ps1 --path . --headless --script res://tools/validate_warrior_combat_runtime.gd`
- Complete Warrior: `./tools/godot.ps1 --path . --headless --script res://tools/validate_warrior_m5_runtime.gd`
- Roster matrix: `./tools/godot.ps1 --path . --headless --script res://tools/validate_roster_stage_matrix.gd`
- Boss runtime: `./tools/godot.ps1 --path . --headless --script res://tools/validate_slime_king_patterns_runtime.gd`
- Boss roster: `./tools/godot.ps1 --path . --headless --script res://tools/validate_boss_roster_matrix.gd`
- Enemy catalog: `./tools/godot.ps1 --path . --headless --script res://tools/validate_enemy_catalog.gd`
- Design catalogs: `./tools/godot.ps1 --path . --headless --script res://tools/validate_design_catalogs.gd`
- Remaining card runtime: `./tools/godot.ps1 --path . --headless --script res://tools/validate_remaining_cards_runtime.gd`
- Release candidate core matrix: `./tools/validate_release_candidate.ps1` (180-second
  watchdog per Godot process; random planner dormant)
- Full focused regression matrix: `./tools/validate_release_candidate.ps1 -Full`
  (includes dormant random-planner coverage)
- Focused validators: `Get-ChildItem tools/validate_*.gd`
- Git status: `git status --short`

## Next Implementation Entry

Start Phase A of
`.agent/execplans/2026-07-14-single-hero-arsenal-migration.md`: freeze representative
v1 profile fixtures, introduce target resources/adapters without switching
production, and keep all current release checks green. Preserve fixed layout V3,
the retired testbed, and the dormant random production path throughout migration.
