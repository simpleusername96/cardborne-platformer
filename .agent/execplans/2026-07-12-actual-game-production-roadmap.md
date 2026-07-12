---
type: plan
status: active
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
- Three deterministic generated Lower Ruins stages from 18 authored rooms.
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
- Current rectangles/colors remain legal short-lived placeholders while gameplay
  timing is built. Presentation milestone must replace them coherently.
- Existing attack/profile values are tuning seeds, not balanced final values.
- The 13 initial enemy Variant values are reviewable tuning seeds; their IDs,
  archetype ownership, safety bounds, and no-random-instance rule are contracts.
- JSON design catalogs are migrated to typed Resources per milestone and are never
  loaded beside those Resources as a second runtime owner.

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
| Boot/flow | `RunDirector`, `Game`, production UI | One scaffold stage jumps directly to result. | Add explicit phases and full stage/reward/boss transitions. |
| Character data | `CharacterProfile`, three `.tres` files | Basic attack seeds only. | Typed kits, attacks, skills, passives, mastery references. |
| Movement | `PlayerController`, `MovementMetrics` | Useful but mixed with attack execution. | Preserve motion; extract combat state; generator consumes limits. |
| Combat | `DamageInfo`, Hitbox/Hurtbox, player attack proof | No shared modifier order, hit result, earned critical, heavy/skills/stagger/effect lifecycle. | Deterministic resolver/critical rules plus Warrior vertical slice. |
| Enemies | Eight behavior scripts plus design catalog v2 | Scripts still own embedded values; no typed archetype/variant/tuning catalog or production scenes. | Promote six archetypes, 13 exact variants, and two special actors through typed definitions/fixtures. |
| Stages | `StageBase`, production scaffold, reusable components | No room templates/planner/assembler/allocator. | Native room contract and data-first generation pipeline. |
| Progression | `RunState`, `PlayerBuild`, design JSON | Counters mostly inert; no reward transaction. | One deterministic build/effect/reward path. |
| Persistence | `ProfileState` settings | No gameplay profile schema/backup/migration. | Versioned profile with wallet/equipment/mastery. |
| Boss | Spec/catalog only | No boss code/scene. | Authored arena, scheduler, patterns, cleanup/settlement. |
| UI/feel | Menu/select/HUD/result shell | No reward/loadout/mastery/forge/skills; placeholders. | Add only states backed by working systems, then presentation pass. |

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
- [x] Canonical fun-focused blueprint and implementation-ready linked specs/catalogs.

### Not credited as finished gameplay

- Production entry rock scaffold.
- Basic attacks without complete kits/encounters.
- Enemy scripts without production scenes and reward integration.
- JSON entries without typed runtime Resources.
- Menu/HUD/result surfaces without the complete run behind them.

## Tasks

### Milestones

#### Milestone 1 - Typed combat and one real Warrior encounter

**Visible result:** Start Warrior from production flow, enter one authored room,
use Basic, Heavy, and Shield Rush against Walker/Charger, clear the room, and exit.

- [ ] **1.1 Add production input actions.**
  - Files: `InputBindings.gd`, project input tests, settings rows.
  - Add Heavy, Skill 1-3, Consumable; keep debug actions absent.
  - Accept: remap and collision tests cover every visible action.
- [ ] **1.2 Add typed character-combat Resources.**
  - Files: `AttackDefinition`, `SkillDefinition`, `CriticalRule`, `CharacterKit`,
    catalogs and Warrior `.tres` data.
  - Reuse `DamageInfo`, Hitbox/Hurtbox, character profiles, effect definitions.
  - Accept: catalog validation catches timings, IDs, hit policy, cooldown, critical
    condition, and refs.
- [ ] **1.3 Implement deterministic `DamageResolver` and `HitResult`.**
  - Fixed direct damage, one final rounding step, no variance/enemy criticals,
    earned player critical x1.5 capped at x2.0.
  - Add fixtures for staggered Breaker, marked full-charge Power Shot, and rear-arc
    Shadow Lunge; secondary hits cannot critical by default.
  - Accept: repeated identical contexts are byte-equivalent and critical effects
    cannot recursively retrigger.
- [ ] **1.4 Extract combat execution from movement.**
  - Add `PlayerCombatController`; leave movement/damage/camera in `PlayerController`.
  - Accept: existing movement and attack-motion validators remain green.
- [ ] **1.5 Implement Warrior Basic, Heavy, passive, and Shield Rush.**
  - Accept: timings/effects match spec and all have readable placeholder feedback.
- [ ] **1.6 Implement typed enemy resolution and promote Ruin Walker/Charger.**
  - Add `EnemyArchetypeDefinition`, `EnemyVariantDefinition`,
    `EnemyTuningProfile`, `EnemyCatalog`, `ResolvedEnemySpec`.
  - Promote `walker_ruin` and `charger_ruin` production scenes/fixtures with exact
    stats, defeat state, presentation key, and drop source ID.
  - Accept: scene behavior reads resolved values and has no stage/variant ID branch.
  - Guard: no auto-reset in production encounter after defeat.
- [ ] **1.7 Author first room `lr_patrol_gallery`.**
  - Native room scene + metadata + safe entry/exit + two anchor variants.
  - Accept: Warrior can clear it from menu without debug narration.
- [ ] **1.8 Fun gate.**
  - Five focused play passes: movement-only, Walker, Charger, Heavy punish,
    Shield Rush spacing; staggered Breaker critical must feel earned and legible.
  - Rework if best strategy is repeated damage trading or attack spam.

*Milestone gate:* one production combat room is enjoyable enough to repeat and
proves the typed kit/enemy/room boundaries.

#### Milestone 2 - Reward transaction and first build decision

**Visible result:** Defeat enemies, gain XP/coins/material, level up, choose one of
three upgrades, clear room, choose one of three working cards, replay with changed
combat behavior.

- [ ] **2.1 Implement run phases/snapshots and legal transitions.**
- [ ] **2.2 Implement EffectDefinition/stack resolver extensions.**
- [ ] **2.3 Implement RewardTable, RewardTransaction, RewardService.**
- [ ] **2.4 Wire Walker/Charger defeat to one idempotent reward path.**
- [ ] **2.5 Implement XP curve and five micro choices.**
- [ ] **2.6 Migrate first five shared cards to typed Resources.**
- [ ] **2.7 Implement level/card choice UI with focus, reroll state, and commit errors.**
- [ ] **2.8 Add focused reward replay, overflow XP, capped offer, and build tests.**
- [ ] **2.9 Fun gate:** selected card must visibly change the next encounter.

*Milestone gate:* one short production loop has combat -> reward -> changed combat.

#### Milestone 3 - Stage 1 generated production route

**Visible result:** A seed produces a six-room Ruin Approach with one optional
branch, valid encounters/rewards, checkpoint, exit, and fallback.

- [ ] **3.1 Implement RoomTemplateData, sockets, anchors, room catalog validation.**
- [ ] **3.2 Author Stage 1 rooms:** start shelf, rise steps, lower/upper choice,
  broken bridge, patrol gallery, charge lane, shooter overlook, optional cache,
  material cavern, exit ascent (eligible subset selected per seed).
- [ ] **3.3 Implement StageProfile, StagePlan, GenerationReport, and enemy catalog references.**
- [ ] **3.4 Implement deterministic graph/template planner with separate encounter and enemy-variant RNG streams.**
- [ ] **3.5 Implement movement/socket/full-plan validator.**
- [ ] **3.6 Implement assembler and allocator:** pressure role -> archetype -> Ruin
  variant -> anchor, then hazard/reward allocation.
- [ ] **3.7 Add curated fallback Stage 1 plan.**
- [ ] **3.8 Promote Shooter and `shooter_ruin` plus static spike/fall-reset content.**
- [ ] **3.9 Add three curated seeds and 1,000-seed property gate, including exact variant reproducibility.**
- [ ] **3.10 All-character route gate:** Warrior, Archer, Assassin base profiles.
- [ ] **3.11 Fun gate:** seeds vary decisions, not just room coordinates.

*Milestone gate:* production Stage 1 is deterministic, varied, valid, clearable,
and enjoyable with every base character.

#### Milestone 4 - Persistent profile, loadout, equipment, mastery

**Visible result:** Discover/equip an item, buy a mastery node, reload the app, and
start a run with an accurately previewed build.

- [ ] **4.1 Define ProfileData v1 and safe save/backup/migration service.**
- [ ] **4.2 Migrate 12 equipment and 18 mastery nodes to typed Resources.**
- [ ] **4.3 Extend PlayerBuild source order and source breakdown.**
- [ ] **4.4 Implement material wallet and equipment unlock/salvage transactions.**
- [ ] **4.5 Implement loadout and mastery command APIs.**
- [ ] **4.6 Implement character/loadout and mastery UI states.**
- [ ] **4.7 Add save round-trip, corrupt-primary fallback, purchase prerequisite,
  respec, and preview/runtime parity tests.**
- [ ] **4.8 Base-loadout guard:** zero mastery remains clearable.

*Milestone gate:* persistent progression provides options without creating a grind
requirement or duplicate stat owner.

#### Milestone 5 - Stage 2, rest/forge, complete Warrior

**Visible result:** Stage 2 teaches poison/crumble/leap, offers a safe rest/forge
decision, and Warrior uses all three skills through two stage cards.

- [ ] **5.1 Complete Warrior Ground Splitter and Rally plus all mastery effects.**
- [ ] **5.2 Migrate Warrior/shared card subset and equipment effects.**
- [ ] **5.3 Author rope shaft, leaper basin, poison timing, crumble crossing,
  rest/forge, and relevant variants.**
- [ ] **5.4 Promote Leaper and Flooded variants:** `walker_flooded`,
  `charger_flooded`, `shooter_flooded`, `leaper_flooded`; add Timed Poison Vent,
  Crumbling Platform, rope recovery.
- [ ] **5.5 Implement shop heal/consumable/reroll commands.**
- [ ] **5.6 Implement deterministic three-choice forge and replacement confirmation.**
- [ ] **5.7 Generate Flooded Works with curated fallback and seed gates.**
- [ ] **5.8 Economy gate:** ordinary play creates a real heal/forge/reroll tradeoff.
- [ ] **5.9 Fun gate:** hazards teach alone before mixed pressure and never create waiting-heavy play.

*Milestone gate:* a Warrior run through Stages 1-2 has combat, cards, economy,
equipment, persistent rewards, and meaningful spending.

#### Milestone 6 - Complete Archer and Assassin

**Visible result:** character selection creates three genuinely different combat
loops across the same Stage 1-2 seeds.

- [ ] **6.1 Implement Archer passive/basic/heavy/three skills.**
- [ ] **6.2 Implement Archer cards, weapons, and six mastery nodes.**
- [ ] **6.3 Implement Assassin passive/basic/heavy/three skills.**
- [ ] **6.4 Implement Assassin cards, weapons, and six mastery nodes.**
- [ ] **6.5 Add all-kit timing, mark/guard/Flow, cooldown, and hit-policy tests.**
- [ ] **6.6 Run all-character, curated-seed, base/equipment/card matrix.**
- [ ] **6.7 Fun gate:** each character produces a distinct dominant decision and no
  character trivializes or loses required route access.

*Milestone gate:* all roster content is complete before Stage 3 complexity grows.

#### Milestone 7 - Stage 3 and complete normal content

**Visible result:** Broken Sanctum tests the finished build with mixed but fair
encounters and leads through the third card reward to the boss.

- [ ] **7.1 Promote Shield Guard/Sentry and all Sanctum variants:**
  `walker_sanctum`, `charger_sanctum`, `shooter_sanctum`,
  `shield_guard_sanctum`, `leaper_sanctum`, `sentry_sanctum`; finalize Summon Node.
- [ ] **7.2 Implement moving platform production component and chest/material nodes.**
- [ ] **7.3 Author shield choke, gate loop, sentry crossfire, remaining optional and
  exit content to complete 18-room catalog.**
- [ ] **7.4 Implement full archetype/variant allocator compatibility, repetition,
  tuning-bound, geometry, and exclusion rules.**
- [ ] **7.5 Generate Broken Sanctum with curated fallback and seed gates.**
- [ ] **7.6 Migrate remaining 15-card catalog and complete equipment/consumable paths.**
- [ ] **7.7 Run multi-seed route/encounter/reward/economy matrix.**
- [ ] **7.8 Fun gate:** Variant changes are recognizable before contact and difficulty
  rises through learned combinations, not longer fights, hidden shots, or unavoidable overlap.

*Milestone gate:* all three normal stages form a varied, coherent complete build arc.

#### Milestone 8 - Giant Slime King and complete run

**Visible result:** Any character can complete three stages, defeat or lose to the
boss, settle rewards, reload, and begin another run.

- [ ] **8.1 Build authored Slime Court and stable camera/intro/lock contract.**
- [ ] **8.2 Implement BossBase, pattern definitions, scheduler, stagger, phase transition.**
- [ ] **8.3 Implement Jump Slam and Body Bump.**
- [ ] **8.4 Implement Poison Bands with safe-floor validation.**
- [ ] **8.5 Implement warned Small Slime Summon and active caps.**
- [ ] **8.6 Implement reviewed Phase 2 chains and scheduler simulation.**
- [ ] **8.7 Implement boss HUD, player/boss death, cleanup, settlement, clear summary.**
- [ ] **8.8 Run every-character base-loadout and representative-build boss matrix.**
- [ ] **8.9 Fun gate:** each pattern has a learned response and punish window; no
  winning strategy is safe off-screen projectile spam or face-tanking.

*Milestone gate:* the first complete production run works end to end.

#### Milestone 9 - Presentation, accessibility, tuning, release candidate

- [ ] **9.1 Approve and import one coherent prototype asset/audio family** through
  the dependency/asset ledger, or create a separately approved original set.
- [ ] **9.2 Replace placeholder actors/terrain while preserving collision readability.**
- [ ] **9.3 Add animation-state timing, hit pause, bounded shake, particles, and
  distinct audio cues with intensity settings.**
- [ ] **9.4 Complete production UI states and keyboard/gamepad prompt switching.**
- [ ] **9.5 Run 1280x720, 1920x1080, and 960x540 robustness inspection.**
- [ ] **9.6 Run economy/card/equipment/mastery balance review over complete runs.**
- [ ] **9.7 Run final seed, save, boss, death, clear, restart, keyboard/gamepad matrix.**
- [ ] **9.8 Reconcile runtime IDs/values with specs and retire migrated design JSON.**
- [ ] **9.9 Produce release notes and one concise player/operator test path.**

*Milestone gate:* a fresh user can understand, enjoy, complete, fail, and replay
the run without debug narration or avoidable confusion.

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

- [ ] No references to retired testbed scenes, inputs, flags, docs, or handoffs.
- [ ] No active Markdown links to deleted files.
- [ ] No character/card/equipment ID branch in shared movement.
- [ ] No UI writes gameplay/save dictionaries.
- [ ] No enemy embeds reward quantities.
- [ ] No room embeds economy or final enemy selection.
- [ ] No generated required transition bypasses movement validation.
- [ ] No checkpoint/entry/exit starts under active pressure.
- [ ] No card offer is incompatible, capped, or dead.
- [ ] No persistent operation destroys the only valid save.
- [ ] No boss pattern/chain bypasses legality and cleanup.
- [ ] No package/asset enters without approval, pin, license, wrapper, and ledger.
- [ ] No milestone is marked complete from docs/JSON alone.

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
| Placeholder presentation hides timing | Combat cannot be judged. | Readable tells now; cohesive asset/animation pass after loop works. |
| External framework captures architecture | Slow integration/removal. | Approval-gated isolated spikes only. |
| Docs drift from runtime | Agents implement conflicting game. | Catalog validators and M9 reconciliation; specs updated only for accepted changes. |

## Open Questions

No unresolved product decision blocks Milestone 1. New questions should be added
here only when they change product scope, save compatibility, dependency adoption,
or a durable content contract. Tuning questions belong to playtest evidence and do
not block implementation.

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

## Next Steps

1. Begin Milestone 1.1 with production input actions and focused remap validation.
2. Add typed combat Resources and Warrior data before editing PlayerController.
3. Deliver Warrior Basic/Heavy/Shield Rush in `lr_patrol_gallery` as the first
   manual fun gate.
4. Update this plan's Progress after each scoped commit; revise specs only when
   implementation/playtest evidence changes an accepted contract.

## Handoff Summary

Read `docs/README.md`, the Game Blueprint, Player Character Systems, encounter spec,
map authoring/generation specs, progression/economy spec, and architecture before
coding. Implement Milestone 1 next. Produce a playable Warrior combat room and its
focused tests last; do not produce another planning-only or menu-only batch.
