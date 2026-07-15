---
type: spec
status: active
owner: BK
last_reviewed: 2026-07-14
canonical_for: First complete run runtime ownership, state transitions, persistence, and failure boundaries
source: Current Godot 4.7 runtime, active product and equipment specs, and fixed-stage release evidence through 2026-07-14
related:
  - ../product/2d_platform_action_card_game_prd.md
  - ../design/COMBAT_EQUIPMENT_CRAFTING.md
  - ../design/PRODUCTION_UI_CONTRACT.md
  - ../design/PROCEDURAL_REGION_GENERATION.md
  - ../design/MAP_AUTHORING_PIPELINE_CONTRACT.md
  - ../design/ENEMIES_TRAPS_GIMMICKS.md
  - ../data/RUNTIME_CATALOG_INDEX.md
  - ../../.agent/execplans/2026-07-15-gameplay-validity-repair.md
---

# First Complete Run Architecture

## Purpose

Define the responsibility and failure boundaries of the current playable
Cardborne vertical slice. Future work should extend these owners instead of
putting combat, progression, save, map, and UI rules into one controller.

## Scope

This architecture covers one persistent Traveler, the Arsenal Trial, three
approved fixed normal stages, stage rewards and Forge transitions, and Slime
Court. It describes the implemented runtime rather than a future migration.

Historical Warrior, Archer, Assassin, mastery, skill, and equipment-item owners
remain only for v1 save migration and focused fixtures. They are not production
extension points.

## Runtime Owners

| Owner | Responsibility | Must not own |
| --- | --- | --- |
| `Game.gd` | Scene load/unload, overlay roots, pause/settings bridge | Run rules, rewards, equipment values |
| `RunDirector.gd` | Legal phase transitions and production scene orchestration | Combat math, recipes, room geometry, save payloads |
| `RunState.gd` | Mutable facts for one attempt, cards, level choices, stage progress, reward application, terminal settlement | Persistent file I/O, UI layout |
| `ProfileState.gd` | One in-memory profile facade, atomic persistent commands, settings, copy-safe snapshots | Recipe calculation, combat target selection |
| `ProfileData.gd` / `ProfileSaveService.gd` | Schema v2 validation, v1 migration, staged writes, backup recovery | Player-facing formatting, run state |
| `PlayerController.gd` | Movement, collision, damage response, fall-recovery respawn, camera hooks | Equipment recipes, reward resolution |
| `PlayerCombatController.gd` | Attack state machine and committed tool execution | Persistent ownership, UI prediction |
| `AttackIntentResolver.gd` | Deterministic melee/ranged choice from target, range, obstruction, resource, and prior intent | Applying damage, drawing previews |
| `ShieldCombatRuntime.gd` | Guard phases, angle, stability, precise guard, condition use | General attack selection |
| `SpiritStoneCombatRuntime.gd` | One equipped passive trigger and deduplication | Inputs, active Arts, resonance |
| `EquipmentProgressionCatalog` | Immutable models, blueprints, materials, grades, and Spirit Stones | Profile mutation, UI state |
| `EquipmentProgressionService` | Pure craft, recraft, repair, and stage-maintenance previews | Saving, focus, combat targeting |
| `EquipmentRuntimeResolver` / `HeroCombatLoadoutResolver` | Effective equipment and hero combat snapshots | Craft costs, persistence |
| `RewardService` / `RunSettlementService` | Typed deterministic transactions and terminal settlement | Loot visuals, menu flow |
| `ProductionStageHost.gd` | Load approved stage data, assemble rooms, spawn typed content, gate exit | Inventing coordinates or bypassing validation |
| Enemy and hazard actors | Consume resolved definitions and own local behavior/timing | Stage-wide progression or profile writes |
| `scripts/ui/production/` | Render snapshots, preserve focus, emit narrow commands | Direct mutation of run/profile/reward dictionaries |
| `FeedbackDirector.gd` | Bounded audio, shake, pause, and hit-burst presentation | Gameplay outcomes or timing authority |

## Runtime State Machine

`RunPhase` is the sole phase vocabulary:

The graph below records the implemented runtime as of 2026-07-15. It is not the
target death/intermission flow: the active gameplay-validity plan owns the pending
Retry Decision, Stage Attempt Snapshot, and Safe Intermission deltas. Update this
graph only when those runtime transitions land so architecture evidence stays
truthful.

```text
BOOT -> MAIN_MENU -> PREPARATION
PREPARATION -> TRIAL_LOADING -> TRIAL_ACTIVE -> PREPARATION
PREPARATION -> LOADOUT -> STAGE_LOADING -> STAGE_ACTIVE
STAGE_ACTIVE -> LEVEL_REWARD -> STAGE_ACTIVE
STAGE_ACTIVE -> STAGE_CARD_REWARD
STAGE_CARD_REWARD -> STAGE_LOADING | FORGE | BOSS_LOADING
FORGE -> STAGE_LOADING
BOSS_LOADING -> BOSS_ACTIVE -> RUN_CLEAR
active gameplay -> RUN_DEATH
RUN_DEATH | RUN_CLEAR -> MAIN_MENU | PREPARATION
```

`LOADOUT` is an internal launch gate retained in the enum; it does not present a
class or loadout-selection screen. `RunDirector` rejects illegal transitions and
returns to a stable preparation, menu, or result state after a load failure.

## Information-Hiding Contracts

### Run And Profile State

- `RunState.start_new_run(0, seed)` accepts only the Traveler profile index. Run
  seeds affect deterministic rewards and evidence, not approved map topology.
- UI and actors consume duplicate snapshots. Mutable dictionaries stay private to
  their owner.
- Persistent commands clone `ProfileData`, validate the result, stage the write,
  verify it, rotate the backup, and only then publish the new in-memory state.
- Profile commands include blueprint/Spirit unlock, craft, recraft, repair, equip,
  ranged supply, condition use, tutorial resolution, materials, and settings.
- Every permanent reward and tutorial baseline uses an idempotent transaction ID.

### Context Attack And Defense

```text
AttackIntentResolver.resolve(context) -> AttackIntent
HeroCombatLoadoutResolver.resolve(profile) -> combat loadout snapshot
PlayerCombatController.commit(intent, loadout) -> attack state
ShieldCombatRuntime.try_guard(input, shield snapshot) -> guard state
```

- A valid close target selects melee. Otherwise the equipped ranged policy checks
  target, line, range, ammunition/reload, and fallback legality.
- Preview and execution consume the same committed intent and geometry.
- Empty ranged supply or an invalid distant target falls back to melee; it never
  creates an unplayable input state.
- Guard is a separate input and always uses the equipped shield. It owns frontal
  legality, startup/active/recovery, stability, precise timing, and condition use.
- Damage is deterministic. Player critical hits require an explicit earned rule;
  enemies, hazards, and secondary passive hits do not gain random critical chance.

### Equipment Progression

```text
EquipmentProgressionService.preview_craft|recraft|repair(catalog, profile, model)
 -> immutable result/cost/shortage snapshot
ProfileCommandService.commit(candidate, preview)
 -> validated atomic profile result
EquipmentRuntimeResolver.resolve(model, crafted state)
 -> combat values
```

- Blueprints unlock a model; they do not grant a completed item.
- Craft creates Grade 1. Recraft consumes the declared Grade 2 recipe and replaces
  the same model at its new maximum condition.
- Repair restores a deterministic fraction and cannot fail randomly, downgrade,
  or destroy equipment.
- Melee tools and shields use condition. Condition zero remains usable and stage
  entry restores a playable floor.
- Bows consume arrows. Matchlocks consume cartridges and obey reload policy.
  Stage entry and authored pickups guarantee a playable minimum.
- Spirit Stones are passive equipment with one declared trigger. They own no
  action input, cooldown button, charge gauge, or resonance state.

### Reward Economy

```text
RewardService.resolve(table, transaction_id, run_seed) -> RewardTransaction
RunState.apply_reward_transaction(transaction) -> RewardResult
ProfileState.settle_progression_reward(...) -> persisted permanent changes
RewardReceiptPresenter.present(result) -> non-authoritative feedback
```

- Reward tables may grant run currency, persistent materials, blueprints, and
  Spirit Stones. Active tables do not generate random equipment discoveries.
- A transaction validates all contents before applying any portion. Reusing the ID
  returns a duplicate result and grants nothing twice.
- Enemy drops, field pickups, chests, NPC requests, shrines, stage clear, and boss
  settlement each keep their declared source and transaction identity.
- Presentation can delay, merge, or recover visible loot but never creates a
  second currency or profile owner.

### Fixed Stage Pipeline

```text
CuratedStagePlanBuilder.build(room catalog, profile, fixed seed, layout version)
 -> StagePlan
StageGeometryValidator.validate(plan, movement limits) -> errors
StageAssembler.assemble(plan, room catalog) -> room hosts and world bounds
StageRuntimeContentSpawner.spawn(plan, typed catalogs) -> actors and interactables
```

- Production always uses `FIXED_LAYOUT_SEED_V1` and the approved layout version.
- Rooms own native terrain, collision, anchors, recovery, and authored content
  sockets. The host does not scatter arbitrary geometry.
- Invalid catalogs, plans, assembly, geometry, or required anchors fail closed.
- Required routes fit the shared Traveler movement envelope. Optional drops either
  return through authored geometry/rope/platform recovery or hit a reset zone that
  respawns at the latest fall-recovery point.
- The random planner remains testable but dormant. It cannot be selected by a run
  seed or production setting.

### UI And Presentation

- Production screens use `ProductionUIStyles` and responsibility-shaped reusable
  components. Domain calculations remain in resolvers and services.
- HUD receives run, combat, equipment, objective, interaction, reward, and boss
  snapshots. It does not query class kits or hidden skill actions.
- Player-facing command failures keep the prior valid state and show a concise
  reason. Persistence failure is visible before stage start.
- Screen shake and damage flash respect profile settings. Disabling either clears
  its active transient immediately.

## Data Ownership

| Domain | Active paths |
| --- | --- |
| Hero | `data/hero/`, `scripts/player/HeroDefinition.gd` |
| Combat | `data/attacks/`, `scripts/player/AttackIntent*.gd`, `PlayerCombatController.gd`, shield/Spirit runtimes |
| Equipment | `data/equipment/models/`, `data/equipment/blueprints/`, `data/materials/`, `data/spirit_stones/`, `scripts/progression/Equipment*.gd` |
| Profile | `scripts/profile/`, `scripts/autoload/ProfileState.gd` |
| Run/cards/rewards | `scripts/run/`, `scripts/cards/`, `scripts/progression/Reward*.gd`, `data/cards/`, `data/rewards/`, `data/progression/` |
| Stages | `scripts/generation/`, `scripts/stages/`, `data/generation/`, `data/rooms/`, `scenes/rooms/`, `scenes/stages/` |
| Enemies/hazards/boss | `scripts/enemies/`, `scripts/hazards/`, `scripts/bosses/`, corresponding `data/` and `scenes/` paths |
| UI/presentation | `scripts/ui/`, `scenes/ui/`, `scripts/presentation/`, `scripts/visuals/` |

## Compatibility Boundary

- `ProfileSaveService` may read v1 character equipment and mastery fields, convert
  known equipment through fixed salvage rules, and record migration IDs.
- `ProfileData` and `ProfileState` keep compatibility fields/facades only so those
  payloads and focused historical fixtures remain verifiable.
- `PlayerCombatController` retains a non-shared action branch for historical combat
  fixtures. Production always enters shared-hero mode first.
- Compatibility catalogs cannot appear in production preparation, rewards, HUD,
  cards, input actions, or stage requirements.

## Failure Behavior

- **Invalid catalog:** block the affected run or command and report exact errors.
- **Invalid approved stage:** unload partial state and return to a stable screen;
  never load the bad plan as a warning-only fallback.
- **Invalid or duplicate reward:** apply nothing and return a typed reason.
- **Craft/equip/save failure:** preserve the last valid profile and expose retryable
  feedback; do not spend materials partially.
- **Corrupt primary save:** load the valid backup, preserving the original files
  when migration cannot validate.
- **World fall:** reset to the latest fall-recovery point; never leave the player
  below the playable world.
- **Missing presentation asset:** use the declared placeholder without changing
  collision, timing, or rewards.

## Requirements

- Shared owners remain narrow and domain named.
- Content definitions validate before gameplay and stable IDs resolve through one
  typed catalog owner.
- UI and presentation remain non-authoritative.
- Side effects occur only at declared scene, transaction, and persistence
  boundaries.
- No external runtime package or asset becomes a dependency without explicit
  approval, pinned version/license, isolated evaluation, and removal boundary.
- Every new system batch must produce a player-visible run path and focused
  validation before expanding content count.

## Acceptance Criteria

1. Production boots to Main Menu, then one-Traveler preparation or Arsenal Trial;
   no class selection or skill bar is reachable.
2. The same intent drives contextual attack preview and execution; guard remains a
   separate shield action.
3. Profile v2 round-trips, migrates representative v1 payloads, and recovers a
   valid backup without duplicate permanent rewards.
4. Craft, recraft, repair, equip, condition, ranged supply, and passive Spirit
   behavior use typed snapshots and atomic commands.
5. Three approved fixed stages and Slime Court fail closed on invalid content and
   provide no-soft-lock required routes and recovery.
6. Reward, UI, input, boss, settlement, import, boot, and full active release
   matrices pass under Godot 4.7.

## Non-Goals

- Runtime-random normal-stage topology, random equipment stats, or random affixes.
- Selectable classes, active skill trees, Spirit Arts, resonance, or weapon wheels.
- Multiple save slots, cloud saves, or mid-run suspension/Continue.
- Final commercial art or broad content expansion.

## Related

- `../release/TRAVELER_EQUIPMENT_VERTICAL_SLICE.md` records the validated current
  outcome.
- The completed implementation ExecPlan is historical evidence, not active
  architecture authority.
