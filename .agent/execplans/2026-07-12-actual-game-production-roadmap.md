---
type: plan
status: done
owner: BK
created: 2026-07-12
last_reviewed: 2026-07-12
topic: First complete Cardborne run production
scope: Ordered implementation from current production scaffold to a fun complete run
source: Owner direction through 2026-07-12 and active Cardborne specifications
related:
  - ../../docs/README.md
  - ../../docs/product/2d_platform_action_card_game_prd.md
  - ../../docs/design/PLAYER_CHARACTER_SYSTEMS.md
  - ../../docs/design/PROCEDURAL_REGION_GENERATION.md
  - ../../docs/design/MAP_AUTHORING_PIPELINE_CONTRACT.md
  - ../../docs/design/ENEMIES_TRAPS_GIMMICKS.md
  - ../../docs/design/PROGRESSION_EQUIPMENT_ECONOMY.md
  - ../../docs/design/PLAYER_FACING_FLOW.md
  - ../../docs/architecture/FIRST_SLICE_ARCHITECTURE.md
---

# Cardborne Actual Game Production Roadmap

## Purpose

Implement the first complete Cardborne run from the current Godot foundation.
Every batch after the first contract work must extend a player-testable path. The
unit of progress is not a class or JSON entry; it is a visible game decision that
works in context and passes its focused checks.

## Why / Context

The integrated testbed proved movement, combat payloads, enemy behaviors, hazards,
checkpoints, inputs, and map failure modes. It was retired because it became a
parallel product and encouraged more diagnostics instead of a game.

Current production code has a menu, character selection, HUD shell, safe entry
stage, and result screen. It does not yet have complete character kits, authored
room templates, generated stages, rewards, persistence, or a boss. This plan turns
existing foundations and accepted design catalogs into one complete run.

## Scope / Non-Scope

### In scope

- Warrior, Archer, Assassin with shared traversal and complete combat kits.
- Three deterministic generated regions from 30 stage-specific authored rooms.
- Six normal enemies, two special actors, four core hazards, stage gimmicks.
- Run levels, 15 cards, coins, shops, temporary forge, consumables.
- Twelve persistent equipment items, shared materials, 18 mastery nodes, safe save.
- Authored Giant Slime King arena with four patterns and two phases.
- Production UI, feedback, input, death/clear/settlement, fun/balance evidence.

### Non-scope

- Recreating an integrated testbed or generic platformer framework.
- Additional biomes, bosses, characters, story, quests, online systems, grid
  inventory, durability, final art, or arbitrary tile generation.
- External packages/assets without explicit approval and the repository adoption
  gate.

## Proposed Design

### Locked Decisions

| Decision | Status |
| --- | --- |
| Canonical product/content/architecture specs are those indexed by `docs/README.md`. | Locked. |
| The integrated testbed, debug HUD, flags, inputs, plans, handoffs, fixed maps, and wireframes are retired; Git history is the archive. | Locked. |
| Reusable movement, combat, enemies, hazards, checkpoints, input, stage, and build components remain. | Locked. |
| Native Godot room scenes plus typed Resource metadata are the first map-authoring pipeline. | Locked until an approved editor spike beats it. |
| Required routes work for the least-mobile base profile and all characters have double jump, dash, crouch, and climb. | Locked. |
| Character identity comes from combat, not exclusive route access. | Locked. |
| Common materials/equipment unlocks persist on pickup; Boss Core requires victory. | Locked. |
| Temporary forge offers three deterministic choices and cannot fail/downgrade/destroy. | Locked. |
| All three active skills are available; no separate mana meter in the first run. | Locked. |
| Normal enemies resolve as `EnemyArchetype` + exact stage `EnemyVariant`; `EnemyTuningProfile` validates authored bounds and is not a runtime multiplier. | Locked. |
| Direct damage has no random spread. First-run critical hits are deterministic, player-earned conditions; enemies/hazards cannot critical. | Locked. |
| Death ends the run; boss victory settles rewards and ends the run. | Locked. |

### Assumptions

- Godot 4.7 stable and GDScript remain the engine/language.
- Project-original procedural vectors and synthesized cues are the accepted RC1
  presentation family; they remain replaceable by final commercial assets.
- Attack/profile values are accepted RC1 tuning and stay reviewable through the
  focused combat and complete-run balance matrices.
- The 13 enemy Variant values, IDs, archetype ownership, safety bounds, and
  no-random-instance rule are accepted runtime contracts.
- Typed Resources are the sole catalog owners; provisional design JSON is retired.

### Implementation Invariant

> Authored intent defines valid possibilities; deterministic systems select and
> resolve them; runtime validation rejects unsafe outcomes; playtests decide
> whether technically valid content is fun.

Additional invariants:

1. No profile/card/equipment ID branches in shared movement.
2. No UI or enemy directly edits run/profile currency or effective stats.
3. No free-coordinate critical geometry/content placement.
4. No accepted stage without safe entry, recovery, checkpoint, and exit.
5. No damaging boss action without startup, active, recovery, and counterplay.
6. No consecutive foundation-only batches after the first combat slice exists.
7. No feature is complete until it is reachable from the production flow.
8. No enemy behavior script branches on stage/variant ID to invent combat values;
   it consumes one immutable `ResolvedEnemySpec`.
9. No damage or critical test depends on an unrecorded lucky roll.

## Current-State Evidence Map

| Concern | As-is owner/evidence | Gap | Target handling |
| --- | --- | --- | --- |
| Boot/flow | `RunDirector`, `Game`, production UI | Closed for RC1. | Preserve with production boot, settlement, and restart validators. |
| Character data | Three complete typed profiles/kits and character runtimes | Closed for RC1. | Preserve identities without changing shared traversal. |
| Movement | `PlayerController`, `MovementMetrics`, generated-route validators | Closed for RC1. | Preserve the least-mobile common traversal envelope. |
| Combat | Deterministic resolver/result and complete Warrior/Archer/Assassin fixtures | Closed for RC1. | Keep earned criticals and deterministic hit ownership intact. |
| Enemies | Six normal archetypes, 13 exact variants, Summon Node, and Small Slime | Closed for RC1. | Preserve archetype/variant bounds in new combinations. |
| Stages | Three deterministic authored/generated stages plus authored Slime Court | Closed for RC1. | Keep boss geometry separate from normal-stage generation. |
| Progression | Transaction-safe rewards, levels, 15 cards, rest/shop/forge, consumables | Closed for RC1. | Avoid a second stat or currency owner during expansion. |
| Persistence | Profile v1, recovery, wallet, loadouts, mastery, exactly-once settlement | Closed for RC1. | Preserve `ProfileState` as the public profile facade. |
| Boss | Authored court, four exact patterns, two phases, HUD, cleanup, settlement | Closed for RC1. | Tune only through reviewed pattern and scheduler contracts. |
| UI/feel | Complete flow, pause/settings, prompts, procedural feedback/presentation | Final commercial assets are outside RC1. | Preserve readability at all three validated resolutions. |

## As-Is / To-Be Delta Checklist

- **Run flow**
  - As-is: menu -> select -> one scaffold -> result.
  - To-be: loadout -> 3 stages with level/card/rest transitions -> boss -> settlement.
  - Accept: phase validator rejects illegal transitions and one clean run path works.
  - Guard: no developer route or retired scene reference.
- **Player**
  - As-is: movement plus profile-specific basic attack inside one controller.
  - To-be: movement owner consumes build snapshot; combat owner executes typed kit.
  - Accept: Warrior basic/heavy/Skill 1 works before further extraction.
  - Guard: no character ID switch in movement.
- **Combat resolution**
  - As-is: attacks construct integer `DamageInfo` directly; conditional bonuses are
    distributed across kit descriptions.
  - To-be: `DamageResolver` returns one `HitResult` with deterministic modifier
    order, earned critical state, rounding, mitigation, stagger, and tags.
  - Accept: identical build/target/context yields identical result; three character
    critical fixtures pass; enemy damage never criticals.
  - Guard: no `randf`/`randi` in damage resolution and no recursive critical procs.
- **Enemy generation**
  - As-is: behavior scripts and old design entries imply one concrete Walker,
    Charger, or Shooter.
  - To-be: allocator chooses pressure role -> archetype -> exact stage variant ->
    validated anchor; scene consumes `ResolvedEnemySpec`.
  - Accept: all 13 variants resolve, satisfy safety/tuning bounds, reproduce by
    seed, and appear in focused fixtures.
  - Guard: no blanket stage multiplier, hidden instance roll, or stage-ID branch in AI.
- **Maps**
  - As-is: safe programmatic rock scaffold.
  - To-be: authored room scenes -> Stage Plan -> validation -> assembly -> allocation.
  - Accept: three Stage 1 seeds differ and all characters clear them.
  - Guard: no arbitrary critical platform or unsupported marker.
- **Rewards**
  - As-is: counters reset; no acquisition path.
  - To-be: transaction-safe XP/coin/material/card/equipment flow.
  - Accept: one enemy defeat reaches UI/build/save exactly once.
  - Guard: replayed transaction applies nothing.
- **Boss**
  - As-is: no runtime owner.
  - To-be: scheduler and four legal patterns in authored arena.
  - Accept: each character can win/lose fairly; simulation finds no illegal overlap.

## Progress

### Landed

- [x] Production menu, character selection, HUD shell, entry-stage scaffold, result.
- [x] Three character profiles and deterministic base-build validation.
- [x] Shared movement including double jump, dash, crouch input, one-way drop, and
  climb foundation.
- [x] Damage payload, hitbox, hurtbox, projectile, enemy, hazard, checkpoint, gate,
  destructible, interactable, and exit foundations.
- [x] Persistent keyboard remapping and focused validators.
- [x] Integrated testbed/runtime/docs retirement.
- [x] Deterministic damage and earned-critical resolution, typed Warrior kit,
  Ruin Walker/Charger variants, and a two-room curated production encounter.
- [x] Runtime fixtures for movement, Warrior attack/stagger/guard behavior, enemy
  catalogs, room traversal contracts, encounter completion, and exit unlock.
- [x] Canonical fun-focused blueprint and implementation-ready linked specs/catalogs.
- [x] Idempotent enemy/stage rewards, overflow-safe run levels, micro-upgrade
  choices, five typed cards with working event effects, card reroll, and replay.
- [x] Deterministic generated Ruin Approach with one optional branch, typed
  Shooter/hazards/rewards, geometry validation, fallback, and 1,000-seed gate.
- [x] Persistent profile v1, 12 equipment items, 18 mastery nodes, per-character
  loadouts, material settlement, backup recovery/migration, and loadout/mastery UI.
- [x] Complete Warrior kit, deterministic Flooded Works, four exact Flooded enemy
  variants, poison/crumble/rope content, and the Rest & Forge economy transition.
- [x] Complete Archer and Assassin kits, cards, equipment, mastery, and all-character
  generated-stage matrices.
- [x] Deterministic Broken Sanctum, complete normal enemy roster, moving platform,
  switch gate, equipment discoveries, and final 15-card runtime catalog.
- [x] Authored two-phase Slime King encounter, warned patterns, boss HUD, death,
  victory, exactly-once settlement, and replay flow.
- [x] Coherent procedural actor/terrain/feedback family, pause/settings flow,
  keyboard/gamepad prompts, complete-run tuning, and multi-resolution QA.
- [x] Typed-catalog reconciliation, retired design JSON, and 75-validator release
  candidate matrix.

### Not credited as finished gameplay

- Production entry rock scaffold.
- Basic attacks without complete kits/encounters.
- Enemy scripts without production scenes and reward integration.
- JSON entries without typed runtime Resources.
- Menu/HUD/result surfaces without the complete run behind them.

## Tasks

### Milestones

#### Milestone 1 - Typed combat and one real Warrior encounter

**Visible result:** Start Warrior from production flow, cross two linked authored
rooms, use Basic, Heavy, and Shield Rush against Walker/Charger, clear the route,
and exit.

- [x] **1.1 Add production input actions.**
  - Files: `InputBindings.gd`, project input tests, settings rows.
  - Add Heavy, Skill 1-3, Consumable; keep debug actions absent.
  - Accept: remap and collision tests cover every visible action.
- [x] **1.2 Add typed character-combat Resources.**
  - Files: `AttackDefinition`, `SkillDefinition`, `CriticalRule`, `CharacterKit`,
    catalogs and Warrior `.tres` data.
  - Reuse `DamageInfo`, Hitbox/Hurtbox, character profiles, effect definitions.
  - Accept: catalog validation catches timings, IDs, hit policy, cooldown, critical
    condition, and refs.
- [x] **1.3 Implement deterministic `DamageResolver` and `HitResult`.**
  - Fixed direct damage, one final rounding step, no variance/enemy criticals,
    earned player critical x1.5 capped at x2.0.
  - Add fixtures for staggered Breaker, marked full-charge Power Shot, and rear-arc
    Shadow Lunge; secondary hits cannot critical by default.
  - Accept: repeated identical contexts are byte-equivalent and critical effects
    cannot recursively retrigger.
- [x] **1.4 Extract combat execution from movement.**
  - Add `PlayerCombatController`; leave movement/damage/camera in `PlayerController`.
  - Accept: existing movement and attack-motion validators remain green.
- [x] **1.5 Implement Warrior Basic, Heavy, passive, and Shield Rush.**
  - Accept: timings/effects match spec and all have readable placeholder feedback.
- [x] **1.6 Implement typed enemy resolution and promote Ruin Walker/Charger.**
  - Add `EnemyArchetypeDefinition`, `EnemyVariantDefinition`,
    `EnemyTuningProfile`, `EnemyCatalog`, `ResolvedEnemySpec`.
  - Promote `walker_ruin` and `charger_ruin` production scenes/fixtures with exact
    stats, defeat state, presentation key, and drop source ID.
  - Accept: scene behavior reads resolved values and has no stage/variant ID branch.
  - Guard: no auto-reset in production encounter after defeat.
- [x] **1.7 Author `lr_patrol_gallery` and `lr_charge_lane`.**
  - Native room scenes + metadata + contiguous safe entry/exit + enemy anchors.
  - Patrol Gallery owns Walker teaching space; Charge Lane owns the required 520 px
    lane and two escape ledges for Charger counterplay.
  - Accept: Warrior can clear both from menu without debug narration.
- [x] **1.8 Fun gate.**
  - Five focused play passes: movement-only, Walker, Charger, Heavy punish,
    Shield Rush spacing; staggered Breaker critical must feel earned and legible.
  - Rework if best strategy is repeated damage trading or attack spam.

*Milestone gate:* the two-room production combat route is enjoyable enough to
repeat and proves the typed kit/enemy/room boundaries.

#### Milestone 2 - Reward transaction and first build decision

**Visible result:** Defeat enemies, gain XP/coins/material, level up, choose one of
three upgrades, clear room, choose one of three working cards, replay with changed
combat behavior.

- [x] **2.1 Implement run phases/snapshots and legal transitions.**
- [x] **2.2 Implement EffectDefinition/stack resolver extensions.**
- [x] **2.3 Implement RewardTable, RewardTransaction, RewardService.**
- [x] **2.4 Wire Walker/Charger defeat to one idempotent reward path.**
- [x] **2.5 Implement XP curve and five micro choices.**
- [x] **2.6 Migrate first five shared cards to typed Resources.**
- [x] **2.7 Implement level/card choice UI with focus, reroll state, and commit errors.**
- [x] **2.8 Add focused reward replay, overflow XP, capped offer, and build tests.**
- [x] **2.9 Fun gate:** selected card must visibly change the next encounter.

*Milestone gate:* one short production loop has combat -> reward -> changed combat.

#### Milestone 3 - Stage 1 generated production route

**Visible result:** A seed produces a six-room Ruin Approach with one optional
branch, valid encounters/rewards, checkpoint, exit, and fallback.

- [x] **3.1 Implement RoomTemplateData, sockets, anchors, room catalog validation.**
- [x] **3.2 Author Stage 1 rooms:** start shelf, rise steps, lower/upper choice,
  broken bridge, patrol gallery, charge lane, shooter overlook, optional cache,
  material cavern, exit ascent (eligible subset selected per seed).
- [x] **3.3 Implement StageProfile, StagePlan, GenerationReport, and enemy catalog references.**
- [x] **3.4 Implement deterministic graph/template planner with separate encounter and enemy-variant RNG streams.**
- [x] **3.5 Implement movement/socket/full-plan validator.**
- [x] **3.6 Implement assembler and allocator:** pressure role -> archetype -> Ruin
  variant -> anchor, then hazard/reward allocation.
- [x] **3.7 Add curated fallback Stage 1 plan.**
- [x] **3.8 Promote Shooter and `shooter_ruin` plus static spike/fall-reset content.**
- [x] **3.9 Add three curated seeds and 1,000-seed property gate, including exact variant reproducibility.**
- [x] **3.10 All-character route gate:** Warrior, Archer, Assassin base profiles.
- [x] **3.11 Fun gate:** seeds vary decisions, not just room coordinates.
  - Evidence: the 1,000-seed gate produced 24 authored topology signatures and
    414 exact encounter signatures with zero fallbacks; curated seeds also pass
    every base character movement envelope.

*Milestone gate:* production Stage 1 is deterministic, varied, valid, clearable,
and enjoyable with every base character.

#### Milestone 4 - Persistent profile, loadout, equipment, mastery

**Visible result:** Discover/equip an item, buy a mastery node, reload the app, and
start a run with an accurately previewed build.

- [x] **4.1 Define ProfileData v1 and safe save/backup/migration service.**
- [x] **4.2 Migrate 12 equipment and 18 mastery nodes to typed Resources.**
- [x] **4.3 Extend PlayerBuild source order and source breakdown.**
- [x] **4.4 Implement material wallet and equipment unlock/salvage transactions.**
- [x] **4.5 Implement loadout and mastery command APIs.**
- [x] **4.6 Implement character/loadout and mastery UI states.**
- [x] **4.7 Add save round-trip, corrupt-primary fallback, purchase prerequisite,
  respec, and preview/runtime parity tests.**
- [x] **4.8 Base-loadout guard:** zero mastery remains clearable.
  - Evidence: profile/catalog/persistence/run-integration validators pass; Broad
    Guard has a runtime fixture; Stage 1's all-character base route gate remains
    green; 1280x720 and 960x540 loadout/mastery captures have no overlap or clipping.

*Milestone gate:* persistent progression provides options without creating a grind
requirement or duplicate stat owner.

#### Milestone 5 - Stage 2, rest/forge, complete Warrior

**Visible result:** Stage 2 teaches poison/crumble/leap, offers a safe rest/forge
decision, and Warrior uses all three skills through two stage cards.

- [x] **5.1 Complete Warrior Ground Splitter and Rally plus all mastery effects.**
- [x] **5.2 Migrate Warrior/shared card subset and equipment effects.**
- [x] **5.3 Author rope shaft, leaper basin, poison timing, crumble crossing,
  rest/forge, and relevant variants.**
- [x] **5.4 Promote Leaper and Flooded variants:** `walker_flooded`,
  `charger_flooded`, `shooter_flooded`, `leaper_flooded`; add Timed Poison Vent,
  Crumbling Platform, rope recovery.
- [x] **5.5 Implement shop heal/consumable/reroll commands.**
- [x] **5.6 Implement deterministic three-choice forge and replacement confirmation.**
- [x] **5.7 Generate Flooded Works with curated fallback and seed gates.**
- [x] **5.8 Economy gate:** ordinary play creates a real heal/forge/reroll tradeoff.
- [x] **5.9 Fun gate:** hazards teach alone before mixed pressure and never create waiting-heavy play.
  - Evidence: poison/crumble rooms have zero encounter budget and authored recovery;
    deterministic timing fixtures and rendered hazard/rope/safe-room captures show
    readable windows without blocking the critical route. Milestone 9's complete-run
    matrix later confirmed the accepted pacing and economy bands.

*Milestone gate:* a Warrior run through Stages 1-2 has combat, cards, economy,
equipment, persistent rewards, and meaningful spending.

Gate evidence: all 36 focused validators pass; Flooded Works produces four
assembled topology signatures and 47 exact encounter signatures over 300 seeds;
the production-flow fixture clears both stages into Rest & Forge; exact Flooded
variant scenes, Leaper arc clearance, consumable scope, forge replacement, and
free-reroll prevention have runtime coverage. The 1280x720 and 960x540 UI captures
show no clipping or overlap.

#### Milestone 6 - Complete Archer and Assassin

**Visible result:** character selection creates three genuinely different combat
loops across the same Stage 1-2 seeds.

- [x] **6.1 Implement Archer passive/basic/heavy/three skills.**
- [x] **6.2 Implement Archer cards, weapons, and six mastery nodes.**
- [x] **6.3 Implement Assassin passive/basic/heavy/three skills.**
- [x] **6.4 Implement Assassin cards, weapons, and six mastery nodes.**
- [x] **6.5 Add all-kit timing, mark/guard/Flow, cooldown, and hit-policy tests.**
- [x] **6.6 Run all-character, curated-seed, base/equipment/card matrix.**
- [x] **6.7 Fun gate:** each character produces a distinct dominant decision and no
  character trivializes or loses required route access.

*Milestone gate:* all roster content is complete before Stage 3 complexity grows.

Gate evidence: all three profiles now require typed five-action kits and isolated
character runtimes. Focused Archer/Assassin kit, combat, progression, equipment,
mastery, and card validators pass; blocked damage cannot advance Flow; fixed
secondary damage remains exact. The roster matrix assembled Stage 1-2 for all
three characters across two curated seeds and proved identical plans per seed.
Rendered 1280x720 and 960x540 captures show complete action/state HUDs without
clipping. The automated fun proxy confirms three different dominant loops:
Warrior guard/stagger, Archer mark/charge control, and Assassin verb/Flow chaining.

#### Milestone 7 - Stage 3 and complete normal content

**Visible result:** Broken Sanctum tests the finished build with mixed but fair
encounters and leads through the third card reward to the boss.

- [x] **7.1 Promote Shield Guard/Sentry and all Sanctum variants:**
  `walker_sanctum`, `charger_sanctum`, `shooter_sanctum`,
  `shield_guard_sanctum`, `leaper_sanctum`, `sentry_sanctum`; finalize Summon Node.
- [x] **7.2 Implement moving platform production component and chest/material nodes.**
- [x] **7.3 Author shield choke, gate loop, sentry crossfire, remaining optional and
  exit content to complete the stage-specific normal-room catalogs.**
- [x] **7.4 Implement full archetype/variant allocator compatibility, repetition,
  tuning-bound, geometry, and exclusion rules.**
- [x] **7.5 Generate Broken Sanctum with curated fallback and seed gates.**
- [x] **7.6 Migrate remaining 15-card catalog and complete equipment/consumable paths.**
- [x] **7.7 Run multi-seed route/encounter/reward/economy matrix.**
- [x] **7.8 Fun gate:** Variant changes are recognizable before contact and difficulty
  rises through learned combinations, not longer fights, hidden shots, or unavoidable overlap.

*Milestone gate:* all three normal stages form a varied, coherent complete build arc.

Gate evidence: 11 Broken Sanctum rooms enforce filled-mass terrain, safe sockets,
two independent branches, flank/cover contracts, moving-platform wait pads, and a
terminal checkpoint. A 120-seed sweep produced six required-route topologies and
all six archetypes with complete plan/assembly validation. Production runtime
setup, typed content spawning, and exit unlock passed for all three characters.
Rendered 1280x720 and 960x540 captures showed coherent traversal space without HUD
overlap. The complete 15-card catalog and Stage 3 reward sources pass focused and
existing progression regressions. `Treasure Instinct` is production-reachable
through optional chests: its modal commits either the resolved cache or one
compatible equipment/free-forge replacement under the same transaction ID.

#### Milestone 8 - Giant Slime King and complete run

**Visible result:** Any character can complete three stages, defeat or lose to the
boss, settle rewards, reload, and begin another run.

- [x] **8.1 Build authored Slime Court and stable camera/intro/lock contract.**
- [x] **8.2 Implement BossBase, pattern definitions, scheduler, stagger, phase transition.**
- [x] **8.3 Implement Jump Slam and Body Bump.**
- [x] **8.4 Implement Poison Bands with safe-floor validation.**
- [x] **8.5 Implement warned Small Slime Summon and active caps.**
- [x] **8.6 Implement reviewed Phase 2 chains and scheduler simulation.**
- [x] **8.7 Implement boss HUD, player/boss death, cleanup, settlement, clear summary.**
- [x] **8.8 Run every-character base-loadout and representative-build boss matrix.**
- [x] **8.9 Fun gate:** each pattern has a learned response and punish window; no
  winning strategy is safe off-screen projectile spam or face-tanking.

*Milestone gate:* the first complete production run works end to end.

Gate evidence: Slime Court keeps the full 1280x720 authored arena visible at
1280x720, 960x540, and 1920x1080. Exact runtime tests cover all four pattern
timelines, one-hit windows, 50% poison-safe floor plus side platforms, two-add cap,
both reviewed Phase 2 chains, 100-point stagger and 1.40 s punish, player death,
scene exit, and exactly-once defeat cleanup. The boss HUD and result summary pass
compact rendered inspection without panel or actor occlusion. A six-build matrix
uses each character's real damage pipeline to defeat both phases, and three death
paths grant no Boss Core. Production boot, boss flow, reward settlement, and restart
tests pass with the real Slime Court and registered clear reward.

#### Milestone 9 - Presentation, accessibility, tuning, release candidate

- [x] **9.1 Approve and import one coherent prototype asset/audio family** through
  the dependency/asset ledger, or create a separately approved original set.
- [x] **9.2 Replace placeholder actors/terrain while preserving collision readability.**
- [x] **9.3 Add animation-state timing, hit pause, bounded shake, particles, and
  distinct audio cues with intensity settings.**
- [x] **9.4 Complete production UI states and keyboard/gamepad prompt switching.**
- [x] **9.5 Run 1280x720, 1920x1080, and 960x540 robustness inspection.**
- [x] **9.6 Run economy/card/equipment/mastery balance review over complete runs.**
- [x] **9.7 Run final seed, save, boss, death, clear, restart, keyboard/gamepad matrix.**
- [x] **9.8 Reconcile runtime IDs/values with specs and retire migrated design JSON.**
- [x] **9.9 Produce release notes and one concise player/operator test path.**

*Milestone gate:* a fresh user can understand, enjoy, complete, fail, and replay
the run without debug narration or avoidable confusion.

Gate evidence: one repository-original procedural family now owns player/enemy
silhouettes, regional terrain, hit feedback, and ten synthesized cues; the adoption
ledger records its origin and validation. Production flow includes pause, abandon
confirmation, settings return, keyboard remapping, fixed gamepad controls, and
automatic prompt switching. Rendered 960x540, 1280x720, and 1920x1080 captures show
no clipping or incoherent overlap, including the exclusive optional-chest reward
modal and three reviewed safe-entry rooms. Fifty-four deterministic complete-run
scenarios
cover three characters, six seeds, and three play styles; all finish at level 5-6,
exercise meaningful spending, and leave equipment/mastery progress. The final
matrix passes all 75 focused validators, including 1,000 generated seeds with zero
fallbacks, save recovery, boss victory/death, settlement, restart, and input paths.

## Test Plan

### Inner loop

- `git diff --check`.
- Godot headless import after script/Resource/scene changes.
- Design catalog validation after seed catalog or ID changes.
- Narrow validator or scene test owned by the current batch.
- One focused manual room/combat/reward path.

### Batch gates

- All validators for touched owners.
- Short production boot.
- Rendered inspection for changed UI/gameplay.
- One start-to-finish visible path for the batch.
- Updated catalog/spec only when a durable contract or accepted tuning changed.

### Expensive gates

- 1,000-seed sweeps only at generator milestones/final handoff.
- Full all-character/build matrix at roster, Stage 3, boss, and final gates.
- Complete-run playtests after the loop exists, not after every helper change.

Rerun a slow failed check only after a concrete change or new hypothesis. Record
known environment warnings instead of rediscovering them.

## Fun Evidence

### Milestone 1

- Movement-only: shared double jump, dash, crouch, climb, and collision recovery
  passed the runtime movement fixture without debug-only assistance.
- Walker: Cleave pressure and two-hit stagger setup passed the live enemy fixture.
- Charger: warning, charge, brown recovery tell, and +20 recovery stagger window
  completed one deterministic behavior cycle.
- Heavy punish: staggered Breaker dealt the earned 1.5x critical and outperformed
  uninterrupted Cleave damage per committed action time.
- Shield Rush: crossed 180 px, blocked frontal contact during active frames, and
  retained a cooldown that prevents it replacing normal spacing decisions.

### Milestone 2

- Seed `93117`, Warrior: three-card initial and rerolled offers reproduced exactly;
  reroll spent 12 coins only after a different complete offer was available.
- All first five cards changed runtime behavior in focused fixtures: delayed Heavy
  echo, one-hit dash trail, consumed extra-jump opener, recovery damage/cooldown
  punish, and skill-kill area burst.
- The visible path completed stage clear -> level choice -> card choice -> Continue
  -> next stage with the selected card stack retained.
- Level/Card Reward screens passed rendered inspection at 1280x720 and 960x540
  with keyboard focus, disabled/error states, and no clipping or overlap.

For each playable milestone, record seed/character/build, selected enemy archetype
and variant IDs, critical trigger/result, duration, damage sources, room/encounter
duration, reward offers/selections, unused verbs, spending, death reason, and tester
comments against the five fun pillars.

Rework before widening content when:

- movement alone is not enjoyable;
- an enemy lacks a distinct response/punish window;
- damage trading beats reading;
- a card is described only as a bigger number;
- procedural rooms feel like shuffled blocks without pacing;
- optional routes are ignored because reward/risk is unclear;
- a death cannot be explained from visible information;
- a Variant feels like an unexplained health/speed change or color-only reskin;
- critical feedback looks lucky rather than earned from a visible condition;
- a boss pattern has no reliable response or punish.

## Guard Checks

- [x] No production runtime dependency on retired testbed scenes, inputs, flags,
  docs, or handoffs; historical retirement records remain explicit.
- [x] No active Markdown links to deleted files.
- [x] No character/card/equipment ID branch in shared movement.
- [x] No UI writes gameplay/save dictionaries.
- [x] No enemy embeds reward quantities.
- [x] No room embeds economy or final enemy selection.
- [x] No generated required transition bypasses movement validation.
- [x] No checkpoint/entry/exit starts under active pressure.
- [x] No card offer is incompatible, capped, or dead.
- [x] No persistent operation destroys the only valid save.
- [x] No boss pattern/chain bypasses legality and cleanup.
- [x] No package/asset enters without approval, pin, license, wrapper, and ledger.
- [x] No milestone is marked complete from docs/JSON alone.

## Rollback / Safety

- Keep scoped commits per milestone/batch.
- Preserve reusable foundations unless a working replacement and focused tests land
  in the same change.
- Keep known-good Stage Plan fixtures for every profile before widening randomness.
- Preserve previous valid profile before save replacement/migration.
- External packages stay isolated and removable.
- If a gameplay extraction regresses movement, restore the last passing movement
  owner and narrow the extraction; do not resurrect the integrated testbed.

## Error Handling

- Missing content reference: fail catalog validation before run start.
- Invalid Stage Plan: deterministic retry, then curated fallback with report.
- Partial assembly: unload and show readable failure; never spawn into broken stage.
- Invalid reward transaction: keep UI/state unchanged and report exact source ID.
- Save failure: preserve in-memory state and previous valid file; allow retry.
- GUI automation failure twice: use scene/input tests and saved screenshots; do not
  turn tool debugging into the milestone.
- Fun failure: change the smallest content/timing rule that explains evidence before
  adding more content.

## Risks

| Risk | Consequence | Mitigation |
| --- | --- | --- |
| Building every system broadly before one loop works | New collection of unfinished parts. | Milestones 1-2 prove combat/reward loop before generation breadth. |
| Technically valid but arbitrary maps | Playable yet boring runs. | Authored room promises, pacing rules, curated seeds, fun gate. |
| Three-character multiplication | Content/test matrix explodes. | Warrior proves contracts; roster breadth only at M6. |
| Progression layers overlap | Rewards feel like invisible stat noise. | Distinct responsibilities and behavior-first cards/equipment/mastery. |
| Persistent power creates grind | Base game feels unfair. | Base-loadout gates and bounded option unlocks. |
| Placeholder presentation hides timing | Combat cannot be judged. | Coherent procedural tells, effects, and cues passed rendered/runtime checks. |
| External framework captures architecture | Slow integration/removal. | Approval-gated isolated spikes only. |
| Docs drift from runtime | Agents implement conflicting game. | Typed catalog validators and RC1 reconciliation keep one runtime owner. |

## Open Questions

No unresolved product decision blocks RC1. Future questions belong to a new plan
when they change product scope, save compatibility, dependency adoption, or a
durable content contract. Tuning questions belong to owner playtest evidence.

## Decision Notes

- 2026-07-12: Production work replaces integrated-testbed expansion.
- 2026-07-12: Integrated testbed/runtime/docs are retired; focused fixtures remain
  allowed when owned by one subsystem.
- 2026-07-12: Existing PRD/scope/expansion content is consolidated into one
  canonical Game Blueprint.
- 2026-07-12: Native Godot room scenes are the default authoring path; LDtk remains
  evidence/spike candidate, not a dependency.
- 2026-07-12: Fun contract and playtest gates are completion requirements alongside
  automated correctness.
- 2026-07-12: Random no-change forging is rejected in favor of deterministic choice.
- 2026-07-12: Milestone 1 uses linked Patrol Gallery and Charge Lane rooms because
  Walker occupancy and Charger's 520 px lane/two-escape contract need distinct
  teaching geometry.
- 2026-07-12: Milestone 2 closes one production combat-to-build loop before stage
  generation grows; cards execute generic trigger/effect types rather than ID
  branches in shared player code.

## Success Criteria

Complete only when all required milestones and final gates pass, documentation and
runtime IDs agree, and a fresh user can choose any character, complete three valid
seeded stages, make visible build/economy decisions, defeat or lose fairly to the
boss, settle/reload persistent rewards, and begin another run.

## Stop Conditions

- Do not mark this plan done while any required milestone remains.
- Ask the owner before changing engine, first-run scope, save economy, external
  dependency/asset adoption, or destructive replacement of reusable foundations.
- Split a large milestone into smaller playable batches rather than stopping at
  infrastructure.
- Mark blocked only after the same external condition prevents progress for three
  consecutive turns and no unaffected task remains.

## Post-RC Opportunities

This plan has no remaining required work. Future work should begin from owner
playtest feedback and a new scoped plan. Likely directions are final commercial
art/audio, onboarding improvements, broader content, and deeper feel/balance tuning;
none is part of this completed first-run roadmap.

## Handoff Summary

The first complete-run roadmap is finished. Read `docs/README.md`, the canonical
specs, and `docs/release/FIRST_COMPLETE_RUN_RC1.md` before changing released
behavior. Use `tools/validate_release_candidate.ps1` for the core gate and add
`-Full` before a new release handoff.
