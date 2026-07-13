---
type: spec
status: active
owner: BK
last_reviewed: 2026-07-13
canonical_for: First complete run runtime ownership, data boundaries, state transitions, and implementation contracts
source: Current Godot code, retired testbed lessons, active game blueprint, content specs, and fixed-stage decision through 2026-07-13
related:
  - ../product/2d_platform_action_card_game_prd.md
  - ../design/PLAYER_CHARACTER_SYSTEMS.md
  - ../design/PROCEDURAL_REGION_GENERATION.md
  - ../design/MAP_AUTHORING_PIPELINE_CONTRACT.md
  - ../design/ENEMIES_TRAPS_GIMMICKS.md
  - ../design/PROGRESSION_EQUIPMENT_ECONOMY.md
  - ../design/PLAYER_FACING_FLOW.md
  - ../../.agent/execplans/2026-07-12-actual-game-production-roadmap.md
---

# First Complete Run Architecture

## Purpose

Turn the product/content specifications into clear Godot ownership boundaries so a
coding session can add one playable slice without rebuilding foundations or placing
rules in UI, enemies, or a monolithic stage script.

## Scope

This architecture applies through the first complete run. It defines public
responsibilities and target file ownership, not an abstract framework. Concrete
class names may change only when the same boundary and acceptance tests remain.

## Domain Brief

- Run Flow owns phase transitions and scene orchestration.
- Run State owns temporary facts for one attempt.
- Profile State owns versioned persistent facts and settings.
- Content Catalogs own immutable definitions and cross-reference validation.
- Player Build resolves all stat/effect sources into one snapshot.
- Player Movement consumes movement values and owns physical traversal only.
- Player Combat executes attacks/skills and owns their state/timing.
- Combat Resolution converts one declared hit context into a deterministic result,
  including earned critical state, rounding, mitigation, and tags.
- Stage Planning chooses validated room/encounter/reward data.
- Stage Assembly instantiates an accepted plan.
- Enemy Catalog owns archetypes, exact stage variants, and tuning validation.
- Encounter Actors consume a resolved enemy specification, own behavior, and emit
  combat/defeat facts.
- Reward Economy resolves and applies idempotent transactions.
- UI renders snapshots and sends narrow commands.

This is not simple CRUD. State scopes, deterministic generation, combat timing,
reward idempotency, save safety, and scene lifecycles interact.

## Current Reusable Foundation

| Existing owner | Keep | Immediate correction/extension |
| --- | --- | --- |
| `RunDirector.gd` | Production menu/select/run/result orchestration. | Expand explicit phases; never absorb content rules. |
| `Game.gd` | Scene load/unload and settings pause bridge. | Keep as technical scene service. |
| `RunState.gd` | Profiles, health, initial run counters. | Narrow to run facts/commands; remove persistent concerns. |
| `ProfileState.gd` | Settings persistence foundation. | Add versioned wallet, equipment, mastery, backup/migration. |
| `PlayerBuild*.gd` | Deterministic base-stat resolution and validation. | Add typed source layers and effect breakdown. |
| `CharacterProfile.gd` / `.tres` | Three movement profiles; Warrior references a typed kit. | Add complete Archer/Assassin kits; no profile-ID branches. |
| `PlayerController.gd` | Movement, damage response, camera hooks. | Keep combat execution and presentation in their extracted owners. |
| `MovementMetrics.gd` | Shared movement-envelope calculation. | Make generator tests consume it directly. |
| `DamageInfo`, `Hitbox`, `Hurtbox`, resolver/result | Deterministic damage, earned critical, stagger, and shared hit path. | Add effect/source transaction IDs when reward/effect lifecycle lands. |
| `EnemyBase` + typed enemy catalog | Ruin Walker/Charger production variants plus remaining prototypes. | Promote the remaining archetypes/variants and connect reward cleanup. |
| Stage components + native room contract | Two linked production rooms plus reusable checkpoint/hazard/gate parts. | Expand the reviewed room catalog, then add planning and assembly. |
| `StageBase.gd` | Player spawn, checkpoint, clear signal. | Consume Stage Plan/report and own stage lifecycle only. |
| Production UI | Menu, character selection, live combat/objective HUD, result shell. | Add only reward/build states backed by working systems. |

The deleted integrated testbed is not an architecture owner. Focused test scenes
may be created per subsystem when they are smaller than a production workflow.

## Runtime State Machine

Target phases:

```text
BOOT
MAIN_MENU
CHARACTER_SELECT
LOADOUT
STAGE_LOADING
STAGE_ACTIVE
LEVEL_REWARD
STAGE_CARD_REWARD
REST_FORGE
BOSS_LOADING
BOSS_ACTIVE
RUN_DEATH
RUN_CLEAR
```

Allowed transitions:

- Main Menu -> Character Select -> Loadout -> Stage Loading.
- Stage Loading -> Stage Active only after generation/assembly validation succeeds.
- Stage Active -> Level Reward -> Stage Active for queued level choices.
- Stage Active -> Stage Card Reward after normal-stage completion.
- Stage Card Reward -> next Stage Loading, except Stage 2 may pass through Rest/Forge.
- Stage 3 reward -> Boss Loading -> Boss Active.
- Any active gameplay -> Run Death at zero health.
- Boss Active -> Run Clear on one boss settlement transaction.
- Death/Clear -> Main Menu or a fresh new-run flow; no production stage retry that
  preserves the failed run.

`RunDirector` validates transitions and coordinates owners. It does not calculate
rewards, stats, rooms, or save payloads.

## Information Hiding Contracts

### Run State

Public commands:

- `start_run(profile_id, loadout, seed)`
- `apply_damage`, `heal`, `grant_xp`, `spend_coin`
- `advance_stage`, `record_card`, `set_temporary_affix`
- `end_run_death`, `end_run_clear`
- snapshot getters returning copies/read-only Resources

Hidden: dictionaries, RNG stream construction, transaction history layout.

### Profile State

Public commands:

- `load_or_create_profile`
- `grant_material`, `unlock_equipment`, `equip_item`
- `purchase_mastery`, `respec_character`
- `set_setting`, `save_profile`

Hidden: file path, ConfigFile/JSON choice, backup rotation, migration internals.

### Player Build

Public contract:

```text
resolve(character, mastery, equipment, run_levels, cards, temporary_effects)
 -> PlayerBuildSnapshot(values, sources, abilities, validation_errors)
```

Consumers ask for effective values/abilities. They never inspect card, equipment,
or mastery IDs.

### Combat Resolution

```text
DamageResolver.resolve(hit_payload, source_build, target_snapshot, hit_context)
 -> HitResult(final_damage, critical, stagger, knockback, tags, validation_errors)
```

`DamageResolver` owns modifier order, earned-critical evaluation, one final integer
round, mitigation, and result tags. It hides effect storage and presentation. The
first run has zero per-hit damage variance, zero enemy critical chance, and a 1.5
default player critical multiplier capped at 2.0.

### Enemy Catalog

```text
EnemyCatalog.resolve(archetype_id, variant_id, stage_id)
 -> ResolvedEnemySpec
```

- `EnemyArchetypeDefinition` owns behavior owner, pressure roles, tell/response/
  punish invariants, geometry needs, and safety bounds.
- `EnemyVariantDefinition` owns exact stats, presentation key, stage eligibility,
  budget, and drop source.
- `EnemyTuningProfile` validates stage bounds; it is never applied as a second
  runtime multiplier.
- Enemy scenes consume `ResolvedEnemySpec`. They do not branch on stage or variant
  IDs to calculate combat values.

### Content Catalogs

Each catalog exposes focused lookup, eligibility, and validation APIs. Runtime and
tests read typed Resources only; retired preimplementation JSON remains available
through Git history, not as a parallel authority.

### Stage Pipeline

```text
StagePlanner.plan(profile, seed, catalogs) -> StagePlan
StagePlanValidator.validate(plan, room_catalog, movement_limits) -> ValidationReport
StageAssembler.assemble(plan) -> StageBase instance
EncounterAllocator.allocate(plan, room anchors, catalogs) -> archetype/variant entries
```

Planning and validation remain data-only where possible. Assembly owns scene-tree
details. A validation failure cannot be converted into a warning and loaded.
Production currently enters this pipeline through the explicit curated-plan path
with one versioned fixed layout seed per approved stage. `StagePlanner` remains a
dormant, testable future path and cannot be selected implicitly by production.

### Reward Economy

```text
RewardService.resolve(source_id, context, rng_stream) -> RewardTransaction
RewardService.apply(transaction, run_state, profile_state) -> RewardResult
TreasureChoiceService.build_choice(transaction, card_effect, context) -> two previews
RunState.commit_optional_chest_choice(request_id, choice_id) -> one RewardResult
```

Transactions carry a unique ID and applied state. UI presents choices but calls
the service to commit one result. An optional-chest replacement and its normal
reward deliberately share the chest transaction ID, so the ledger cannot apply
both branches.

## Target Code And Data Ownership

### Run/profile

- `scripts/autoload/RunDirector.gd`
- `scripts/autoload/RunState.gd`
- `scripts/autoload/ProfileState.gd`
- `scripts/run/RunSnapshot.gd`
- `scripts/run/RunPhase.gd` if enum/resource extraction becomes useful
- `scripts/profile/ProfileData.gd`, `ProfileSaveService.gd`

### Character/combat

- `scripts/player/PlayerController.gd`: movement/damage/camera only
- `scripts/player/PlayerCombatController.gd`, `PlayerAttackPresenter.gd`
- `scripts/player/CharacterKit.gd`
- `scripts/player/AttackDefinition.gd`
- `scripts/player/SkillDefinition.gd`
- `scripts/combat/DamageResolver.gd`, `HitResult.gd`, `CriticalRule.gd`
- `scripts/content/ContentId.gd`: shared durable content-ID syntax validation
- `scripts/player/PlayerBuild.gd`, `PlayerBuildSnapshot.gd`
- `data/characters/`, `data/attacks/`, `data/skills/`, `data/mastery/`

### Cards/progression/economy

- `scripts/cards/CardDefinition.gd`, `CardCatalog.gd`, `CardEffectApplier.gd`
- `scripts/progression/EffectDefinition.gd`, `EquipmentDefinition.gd`
- `scripts/progression/RewardService.gd`, `RewardTransaction.gd`,
  `TreasureChoiceService.gd`
- `scripts/progression/EquipmentCatalog.gd`, `MasteryCatalog.gd`
- `data/cards/`, `data/equipment/`, `data/rewards/`, `data/mastery/`

### Stages/generation

- `scripts/stages/RoomTemplateHost.gd`, `RoomTemplateData.gd`
- `scripts/stages/generation/StagePlan.gd`
- `StagePlanner.gd`, `StagePlanValidator.gd`, `StageAssembler.gd`
- `EncounterAllocator.gd`, `GenerationReport.gd`
- `data/rooms/lower_ruins/`, `data/stages/`
- `scenes/rooms/lower_ruins/`, `scenes/stages/production/`

### Enemies/bosses

- Existing `scripts/enemies/` behavior owners plus
  `EnemyArchetypeDefinition.gd`, `EnemyVariantDefinition.gd`,
  `EnemyTuningProfile.gd`, `EnemyCatalog.gd`, `ResolvedEnemySpec.gd`
- production enemy scenes under `scenes/enemies/`
- `scripts/bosses/BossBase.gd`, `BossPatternDefinition.gd`,
  `BossPatternScheduler.gd`, `SlimeKing.gd`
- `data/enemies/`, `data/bosses/`, `scenes/bosses/`

### UI

- `scripts/ui/production/` owns screens/components only
- reward/loadout/mastery/forge views consume snapshots and issue commands
- no UI script mutates stats, currencies, inventory dictionaries, stage plans, or
  save payloads directly

## Content Resource Minimum Fields

All definitions include `id`, `display_name`, `content_version`, tags,
presentation references, and `validate_definition()`.

- Attack/Skill: timings, cooldown, damage/stagger/effects, earned-critical rule, hit
  policy, cancellation, movement impulse, compatibility.
- Card: rarity, compatibility, trigger, effects, max stacks, offer rules.
- Equipment: slot, compatibility, persistent source, effects, tradeoffs, salvage.
- Enemy archetype: behavior owner, pressure roles, tell/response/punish contract,
  safety bounds, room requirements.
- Enemy variant: archetype, stage, exact stats, presentation key, budget cost, drop
  source; no per-instance random stat range.
- Enemy tuning profile: stage-bound authoring ranges and allowed damage values.
- Hazard: scene, budget cost, warning/active/recovery, safe-zone requirement.
- Room: scene, role, sockets, anchors, budgets, stage tags, expected duration.
- Boss pattern: phases, timing, legality tags, cleanup owner, counterplay metadata.

## Event Rules

- Signals announce completed facts, not requests to mutate unrelated owners.
- State-changing commands return success/result objects rather than assuming the
  signal listener succeeded.
- Combat signals may announce hit, damage, stagger, defeat, or pattern phase.
- Reward signals announce presented/applied results after transaction state is safe.
- UI disconnects automatically with scene lifetime; autoloads do not connect the
  same listener more than once.

## Save Safety

- Profile schema starts at version 1 when persistent gameplay data lands.
- Write a temporary file, validate it, preserve last valid backup, then replace.
- Migration is explicit per version and never runs in UI code.
- Corrupt primary save falls back to backup and reports a readable error.
- Run-local state is not silently restored as persistent state in the first run.

## Error And Failure Behavior

- Invalid content catalog: block run start and list exact IDs/errors.
- Invalid approved stage: fail closed and return to a stable flow state. The
  dormant random path may still retry and use curated fallback in focused tests.
- Assembly mismatch: unload partial stage and return to a readable failure surface;
  never leave the player in a broken map.
- Invalid reward choice: keep the choice screen open and do not spend/apply.
- Save failure: retain in-memory state and previous valid save; allow retry.
- Missing presentation asset: use declared placeholder without changing gameplay.

## Implementation Sequence

The completed first-run roadmap records the detailed checklists. The architecture
dependency order used for RC1 was:

1. Lock typed content/effect contracts and state scopes.
2. Complete deterministic damage/earned critical resolution and Warrior
   basic/heavy/Skill 1 against Ruin Walker/Charger variants across the linked
   Patrol Gallery and Charge Lane authored rooms.
3. Implement reward transaction, one level choice, and three cards end to end.
4. Build RoomTemplate contract, six Stage 1 rooms, planner, validator, assembler,
   allocator, fallback, and seed report.
5. Complete Warrior skills, Stage 1 card flow, one rest/forge choice, and persistence.
6. Promote six enemy archetypes, 13 variants, hazards, and Stages 2-3.
7. Complete Archer and Assassin using the proven shared contracts.
8. Build boss scheduler, four patterns, settlement, and full-run flow.
9. Replace placeholders, tune fun, and run release matrices.

After step 2, every batch must extend a player-visible run path; do not create
multiple consecutive infrastructure-only milestones.

## Test Architecture

### Focused validators

- catalog IDs/references/effect compatibility;
- player build source ordering and clamps;
- attack/skill state timing and target hit policy;
- deterministic damage order, earned critical conditions, and critical proc guards;
- reward idempotency and economy bounds;
- room/socket/anchor schema;
- known valid/invalid movement transitions;
- enemy archetype/variant/tuning references, support/clearance, and boss legality;
- profile save round trip/migration/fallback.

### Scene tests

- one room per terrain/encounter lesson;
- each character kit against representative enemies;
- stage assembly and cleanup;
- UI focus/pause/choice commit;
- boss phase and death cleanup.

### Batch/final gates

- 1,000-seed property sweep when changing the dormant planner or preparing its
  future re-entry, not every fixed-stage edit;
- approved-plan all-character play matrix;
- complete run death/clear/save paths;
- rendered gameplay/UI at 1280x720 and 1920x1080, with 960x540 robustness where
  practical;
- playtest evidence against the fun contract.

## Requirements

- Shared owners stay narrow and domain-named.
- No new monolithic stage/player/autoload absorbs unrelated rules.
- Content definitions are validated before gameplay.
- Side effects live at scene/save boundaries; rules remain testable.
- Existing reusable components are extended before equivalent code is rebuilt.
- External packages require explicit approval, pinned version/license, wrapper,
  spike acceptance, and removal boundary.

## Acceptance Criteria

- A future coding session can identify the owner, target files, public contract,
  data path, and test type for every first-run feature.
- Run/profile/build/reward/stage/UI responsibilities have no competing write owner.
- Stage planning can be tested without rendering and assembly can be tested from a
  saved Stage Plan fixture.
- Every persistent or reward mutation is idempotent or transaction-guarded.
- The production run contains no dependency on the retired integrated testbed.
- Code, catalogs, specs, and roadmap use the same canonical terms and IDs.
- Enemy scenes have no stage-ID stat branches, and every spawned normal enemy
  resolves through one archetype plus one exact variant.

## Non-Goals

- Enterprise service layers, repositories, ECS migration, or framework-style base
  classes without current pressure.
- Adopting LDtk, a state-machine plugin, test framework, or menu framework before a
  separate approved spike.
- Designing final save compatibility beyond the first complete-run profile.

## Related

- `docs/product/2d_platform_action_card_game_prd.md`
- `docs/design/PLAYER_CHARACTER_SYSTEMS.md`
- `docs/design/PROCEDURAL_REGION_GENERATION.md`
- `docs/design/MAP_AUTHORING_PIPELINE_CONTRACT.md`
- `docs/design/ENEMIES_TRAPS_GIMMICKS.md`
- `docs/design/PROGRESSION_EQUIPMENT_ECONOMY.md`
- `docs/design/PLAYER_FACING_FLOW.md`
- `.agent/execplans/2026-07-12-actual-game-production-roadmap.md`
