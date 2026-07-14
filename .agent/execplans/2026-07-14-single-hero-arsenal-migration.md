---
type: plan
status: superseded
owner: BK
created: 2026-07-14
last_reviewed: 2026-07-14
superseded_by: ../../docs/design/COMBAT_EQUIPMENT_CRAFTING.md
topic: Single-hero arsenal, full equipment, onboarding, and save/continue migration
scope: Product documents, combat identity, progression catalogs, profile schema, run suspension, production UI, tutorial, and compatibility validation
supersedes: 2026-07-13-player-experience-refinement.md
source: Owner direction through 2026-07-14 and inspected production code/docs
related:
  - ../../docs/product/2d_platform_action_card_game_prd.md
  - ../../docs/design/ARSENAL_EQUIPMENT_PROGRESSION.md
  - ../../docs/design/PLAYER_FACING_FLOW.md
  - ../../docs/architecture/FIRST_SLICE_ARCHITECTURE.md
  - ../../docs/design/reports/arsenal-equipment-system.html
  - 2026-07-12-actual-game-production-roadmap.md
---

# Single-Hero Arsenal Migration Plan

> **Superseded 2026-07-14.** Do not execute this plan's two-weapon swap,
> six-discipline, per-weapon enchantment, or enhancement-rank phases. The active
> gameplay target is `docs/design/COMBAT_EQUIPMENT_CRAFTING.md`; the active UI work
> sequence is `docs/design/PLAYER_UIUX_REFINEMENT_PLAN.md`. A replacement cross-code
> ExecPlan must be created from those documents before implementation begins.

## Purpose

Replace the released three-character selection model with one persistent hero whose
two equipped weapon disciplines, complete support equipment, enchantments, mastery,
and deterministic upgrades define play. Add a skippable/replayable Arsenal Trial,
an armory before and between stages, three local profile slots, and checkpoint-based
Save & Quit / Continue.

This is a nine-batch migration. Each implementation item identifies current and
target ownership and keeps a user-testable path available. Existing combat kits,
stage content, enemies, rewards, transaction safety, profile backup logic, and
movement validation are reused before new content is authored.

## Why / Context

The current game is structurally complete but partitions combat, equipment, cards,
and mastery by Warrior, Archer, and Assassin. That makes a reward irrelevant when
it targets another selected character and weakens the fantasy of one hero building
an arsenal from enemy materials and discoveries.

The code already has useful boundaries: typed kits, deterministic build resolution,
transaction-safe rewards, persistent equipment/materials/mastery, and atomic
profile writes with backup recovery. The migration should reclassify those systems
rather than start again.

Profile persistence exists today, but the player cannot select save slots, inspect
save metadata, or continue an interrupted run. `ProfileSaveService` writes
`user://profile.json`; `RunState` has a readable snapshot but no restore contract;
`RunDirector.show_main_menu()` settles an active run as abandoned. The target keeps
automatic profile persistence and adds a separate checkpoint-level run suspend.

## Decisions Locked With The Owner (2026-07-14)

| Topic | Decision | Source / note |
| --- | --- | --- |
| Player identity | Production uses one persistent hero, not selectable combat classes. | Owner requested one character whose weapons create playstyle. |
| Build scope | Loadout includes two weapons, armor, charm, relic, consumable, and one enchantment per weapon. | Owner clarified that the redesign is not weapon-only. |
| First disciplines | Reclassify Warrior, Archer, Assassin as Sword & Shield, Bow, Twin Blades. | Preserve working content before new authoring. |
| Complete discipline target | Add Spear, Great Axe, and Matchlock only after the first three pass fun/balance gates. | Six is diverse without an unrestricted weapon library. |
| Tutorial | Use a separate deterministic Arsenal Trial prologue; allow permanent skip and later replay. | Owner requested skippable Stage 1/tutorial behavior. |
| Skip parity | Skip grants every mechanical tutorial reward and a valid default preset. | Skipping must not create a weaker profile. |
| Preparation | Equipment changes occur in the Armory before/between stages, not during combat. | Preserves meaningful loadout decisions. |
| Elements | Four shared enchantments: Fire, Frost, Poison, Shock. | Broad expression with bounded rule count. |
| Upgrade model | Deterministic authored ranks/branches; no random stats, failure, destruction, or downgrade. | Reuses current deterministic forge principles. |
| Materials | Keep Rusted Scrap, Sky Thread, Slime Residue, Boss Core; blueprints carry element/item identity. | Prevent currency proliferation. |
| Save model | Three local profiles plus one checkpoint-level run suspend per profile. | Matches common local single-player expectations without free save states. |
| Mid-run continuity | `Save & Return to Menu` and crash recovery resume from an authored checkpoint, not exact actor state. | Avoid serializing scene trees and reward duplication. |
| Existing maps | Required traversal remains loadout-independent and fixed Stage Plans remain active. | Preserve owner-accepted map direction and safety work. |

## Assumptions And Open Decisions

| Topic | Current assumption | Why it matters | Default handling |
| --- | --- | --- | --- |
| Hero name/story | Systems need one stable hero ID, but final name and narrative are not selected. | IDs must not churn with copy decisions. | Use internal `hero` and player-facing `Adventurer` until narrative work. |
| Weapon swap input | A new remappable action is required. | Existing action map has no production weapon switch. | Add one keyboard/gamepad binding and keep it out of traversal metrics. |
| Final unlock order | First three are fixed; later three need encounter/content support. | Unlock timing affects tutorial and rewards. | Twin Blades: Stage 1 milestone; Spear: Stage 2; Great Axe: Stage 3; Matchlock: boss/next-cycle until playtests revise. |
| Save localization | Current production copy is English. | Save/profile UI adds substantial new copy. | Implement concise English strings and layouts that fit Korean; localization remains separate. |
| Cosmetics | Equipment should visually affect the one hero, but final sprites do not exist. | Player needs loadout recognition. | Use current procedural overlay and weapon silhouettes first. |

## Progress

### Landed / already true

- [x] Shared movement supports double jump, dash, crouch/drop, climb, and checkpoint return.
- [x] Warrior, Archer, and Assassin each have a complete typed combat kit and six mastery nodes.
- [x] Persistent equipment slots already include weapon, armor, charm, relic, and consumable.
- [x] Rewards are transaction-safe; duplicate equipment already salvages to materials.
- [x] `ProfileSaveService` verifies staged JSON, rotates backup, migrates legacy data, and recovers a corrupt primary.
- [x] Fixed normal-stage plans, enemies, field pickups, rest/forge, boss, settlement, and production shell exist.
- [x] Combat footprints, pickup receipts, fall recovery, and the compact action HUD have focused validators.

### Still open

- [ ] Reclassify character-owned content and remove selectable classes from production.
- [ ] Add the complete loadout, enchantment, enhancement, and armory contracts.
- [ ] Migrate profile v1 to v2 without losing ownership or transactions.
- [ ] Add profile slots, run suspend, Continue, and Save & Return to Menu.
- [ ] Build and validate the Arsenal Trial complete/skip/replay paths.
- [ ] Update HUD, hero presentation, reward filtering, balance matrices, docs, and telemetry.
- [ ] Carry forward broad committed-return replay, reduced-motion polish, fresh-player recognition, and full manual runs from the superseded refinement plan.

## Guiding Implementation Principle

**Reclassify before expanding.** The first visible slice must play the existing three
kits on one hero through weapon switching and the Armory. Do not author Spear, Great
Axe, Matchlock, additional gear, or new currencies while class IDs still own combat,
cards, mastery, profile loadouts, or UI.

Shared owners to create, reuse, or retire:

| Concern | Desired owner | Existing owner(s) to reuse or retire |
| --- | --- | --- |
| Hero baseline | `HeroDefinition` / one base profile | Retire three movement `CharacterProfile` resources after migration. |
| Combat grammar | `WeaponDisciplineDefinition` + discipline runtime | Reuse `CharacterKit` data/behavior, then retire character terminology. |
| Concrete weapon | `WeaponFormDefinition` or generalized `EquipmentDefinition` | Reuse six weapon equipment resources and effects. |
| Full loadout | `ArmoryLoadout` in `ProfileData`/`ProfileState` | Replace per-character loadout dictionaries. |
| Build resolution | `PlayerBuild` snapshot pipeline | Reuse; replace character compatibility with discipline/loadout tags. |
| Enchantment | One shared status/enchantment catalog | Do not put element rules in six combat runtimes. |
| Enhancement | Profile command + authored rank definition | Replace ad hoc permanent upgrades; keep temporary forge separate. |
| Profile persistence | `ProfileSaveService` + v2 migration | Reuse atomic/backup write path; add slot paths. |
| Run continuity | `RunSuspendData` + `RunSuspendSaveService` | No current owner; `RunSnapshot` is read-only evidence, not restorable state. |
| Top-level flow | `RunDirector` | Replace character select phases/routes and add Continue/Tutorial/Armory. |
| Player-facing setup | `Armory` scene and snapshot | Retire production `CharacterSelect` after parity. |

## Current-State Evidence Map

| Concern | Current owner(s) | Observed behavior / problem | Plan handling |
| --- | --- | --- | --- |
| Character identity | `CharacterCatalog`, three profiles/kits, `RunState.selected_profile` | Combat, movement tuning, cards, mastery, equipment, HUD color, and tests branch around three IDs. | Reclassify kit ownership; normalize movement to one hero. |
| Combat runtime | `PlayerCombatController`, three `*CombatRuntime` scripts | Boundary is already extracted, but names and selection use profile IDs. | Preserve behavior and swap the configured discipline at runtime. |
| Equipment | `EquipmentDefinition`, `ProfileData.DEFAULT_LOADOUTS`, `ProfileState` | Full support slots exist, but weapon compatibility and loadouts are per character; only one weapon can be active. | Add two weapon slots, enchant assignments, ranks, branches, and one hero preset. |
| Mastery | `MasteryNodeDefinition.character_id`, 18 resources | Six-node graphs already match target shape but are character-owned and always active. | Migrate to discipline IDs and equip bounded modifier presets. |
| Cards | `CardDefinition.compatibility`, `CardOfferService` | Character-compatible offers work but cannot reason over two equipped disciplines. | Filter shared + either equipped discipline; preview affected weapon. |
| Materials | Four IDs in `ProfileData` and equipment/mastery validators | Correct bounded wallet already exists. | Preserve IDs; add blueprint and enhancement sinks. |
| Temporary forge | `ForgeAffixDefinition`, `RunState` | Run-local deterministic affix is useful but visually resembles permanent gear progression. | Keep separate and label duration; do not merge with permanent enhancement. |
| Profile save | `ProfileSaveService`, `ProfileState`, profile validators | Automatic single-file save, backup, migration, and retry exist. | Generalize paths to three slots and migrate v1 -> v2. |
| Run save | `RunSnapshot`, `RunState`, `RunDirector.show_main_menu` | Snapshot cannot restore; leaving settles the run as abandoned. | Add explicit suspend export/restore and legal checkpoint boundaries. |
| Main flow | `MainMenu`, `CharacterSelect`, `RunDirector`, `RunPhase` | New Run -> character/loadout; no Continue, Profiles, Training, or Armory. | Replace with profile-aware menu and one-hero armory. |
| Tutorial | None; Stage 1 immediately starts the run | No progressive introduction or skip/replay state. | Add a separate deterministic Arsenal Trial and parity skip transaction. |
| Presentation | `PlayerVisualOverlay`, HUD action slots | Overlay and accent imply three characters; HUD has one active kit only. | Show equipped weapon/armor identity and swap state. |

## As-Is / To-Be Delta Map

| Concern | As-is | To-be | Acceptance check | Guard / leftover check |
| --- | --- | --- | --- | --- |
| Entry flow | Main Menu -> Character Select -> run. | Profile -> optional Trial/skip -> Armory -> run; Continue restores suspend. | Keyboard/gamepad flow validator covers every path. | No production `CHARACTER_SELECT` phase or selectable class card. |
| Hero | Three profiles alter HP/mobility and kit. | One baseline hero; equipment and weapons create combat variation. | All required routes pass one shared movement fixture. | No class ID branch in movement/camera/damage. |
| Weapons | One character-compatible weapon slot. | Two weapon forms, one active, each with discipline and enchantment. | Swap changes all five action slots and passive state truthfully. | No duplicate active kit or stale cooldown leakage. |
| Support gear | Armor/charm/relic/consumable exist per character loadout. | One shared saved loadout with clear slot responsibilities. | Armory comparison and runtime build match. | No hidden grid inventory or combat-time equip. |
| Mastery | Six nodes per character, purchased nodes all active. | Six per discipline; permanent unlocks, bounded equipped preset. | Purchase/respec/preset/save round trips. | No character compatibility in target catalogs. |
| Enchantments | No elemental weapon system; temporary forge has broad affixes. | Four shared deterministic status rules, one socket per weapon. | 4 x 3 first-slice discipline matrix passes. | No per-runtime duplicate element implementations. |
| Enhancement | Equipment ownership is persistent; forging is run-local only. | Weapon Rank 0-3, armor Rank 0-2; authored branch/capstone. | Preview, purchase, save, migration, and cap tests. | No failure, downgrade, random roll, or charm/relic levels. |
| Tutorial | None. | Separate Trial, equal skip rewards, replay from Training. | Complete and skip snapshots compare equal. | Skip cannot lose or duplicate baseline unlocks. |
| Profile save | One `profile.json`; no player slot UI. | Three atomic v2 slots with metadata and v1 import. | Slot isolation, migration, corruption fallback. | v1 remains backup until v2 validation succeeds. |
| Run save | No restore; menu exit settles death/abandon. | One checkpoint-level suspend per profile and Continue. | Resume matrix for stage/checkpoint/reward phases. | No exact node serialization or reward replay. |
| UI | Character cards and class state. | Hero armory, two weapon states, next-stage pressure, save status. | 960x540, 1280x720, 1920x1080 captures and focus tests. | No raw IDs, debug contracts, overlap, or fake save buttons. |

## Scope / Non-Scope

In scope:

- The source-of-truth document migration and code/data migration it requires.
- One hero, six bounded weapon disciplines, full equipment slots, four elements,
  deterministic enhancement, material/blueprint economy, and temporary cards/forge.
- Skippable/replayable tutorial, Armory, HUD weapon switching, profile slots, and
  checkpoint resume.
- Save v1 -> v2 compatibility and focused/full regression coverage.
- Carried-forward traversal safety and player-facing quality gates.

Non-scope:

- Random map generation re-entry, additional regions/bosses, final narrative,
  commissioned art/audio, localization, multiplayer, cloud saves, or online accounts.
- Grid inventory, five-piece armor, durability, random affixes/rarities, manual
  mid-combat saves, or exact scene-tree serialization.

Destructive actions:

- Do not delete v1 fixtures, class resources, scenes, or validators until migration
  parity is green and grep guards identify all remaining consumers.
- Do not overwrite the user's real `user://profile.json` during tests. All tests use
  isolated `user://test_*` paths and remove only their own fixtures.

## Source Map

- Product authority: `docs/product/2d_platform_action_card_game_prd.md`.
- Target system: `docs/design/ARSENAL_EQUIPMENT_PROGRESSION.md`.
- Target UI behavior: `docs/design/PLAYER_FACING_FLOW.md`.
- Current architecture: `docs/architecture/FIRST_SLICE_ARCHITECTURE.md`.
- Current profile owners: `scripts/profile/ProfileData.gd`,
  `ProfileSaveService.gd`, `ProfileCommandService.gd`, `scripts/autoload/ProfileState.gd`.
- Current run owners: `scripts/autoload/RunState.gd`, `RunDirector.gd`,
  `scripts/run/RunSnapshot.gd`, `RunPhase.gd`.
- Current combat owners: `scripts/player/PlayerCombatController.gd`,
  `CharacterKit.gd`, `scripts/player/combat/*CombatRuntime.gd`.
- Current UI owners: `MainMenu`, `CharacterSelect`, `ProductionHUD`, `PauseMenu`,
  `RestForge`, shared production components/styles.
- Existing save evidence: `validate_profile_persistence.gd`,
  `validate_profile_state.gd`, `validate_profile_run_integration.gd`.

## Evidence Rules

- Current code and focused validators are implementation truth until replaced.
- The active arsenal specification is target product truth; superseded class specs
  remain migration evidence only.
- Every migration batch needs code/test/commit evidence. Separate evidence documents
  are required only for save compatibility tables or rendered UI comparisons that
  future work must reuse.
- A passing catalog test does not prove combat feel. Every discipline batch includes
  one production encounter and one boss punish play pass.
- Never report save/load complete from serialization alone; menu, failure, backup,
  resume, and duplicate-reward paths must all pass.

## Phase A - Freeze Baseline And Introduce Target Vocabulary

**Goal:** Preserve current behavior while creating typed target contracts and
migration fixtures.

**Source owners:** product/design docs, character/equipment/mastery catalogs,
profile v1 fixtures, release matrix.

- [ ] **A1 Record v1 compatibility fixtures.**
  - As-is: tests construct transient profiles but no committed representative v1
    fixtures cover all three loadouts, mastery branches, materials, settings, and
    transaction IDs together.
  - To-be: add clean, progressed, and recoverable/corrupt v1 fixtures under test
    ownership with expected v2 snapshots.
  - Accept: current build loads each valid v1 fixture and fixtures contain no user path.
  - Guard: fixture data cannot become a production default.
- [ ] **A2 Add target Resources without switching production.**
  - Add or generalize `HeroDefinition`, `WeaponDisciplineDefinition`,
    `WeaponFormDefinition`, `EnchantDefinition`, enhancement branch/rank definitions,
    and catalogs.
  - Reuse `AttackDefinition`, `SkillDefinition`, behavior effects, and build effects.
  - Accept: target catalogs validate Sword & Shield, Bow, Twin Blades by referencing
    existing attacks/skills with no copied timing/damage definitions.
- [ ] **A3 Add adapters and terminology guards.**
  - As-is: compatibility is `character_id/profile_id` throughout catalogs.
  - To-be: one temporary adapter maps historical IDs to discipline IDs at a single
    migration boundary; new APIs use `hero`, `discipline`, `weapon_form`, `loadout`.
  - Accept: grep shows no new target file introducing class-owned terminology.
- [ ] **A4 Update architecture target sections and runtime catalog index.**

*Batch gate:* all current 33 core release checks remain green before production
selection changes.

## Phase B - One Hero And Three Reclassified Disciplines

**Goal:** Make the current three complete kits playable by one hero through a
runtime weapon switch before adding new progression.

**Source owners:** `RunState`, `PlayerController`, `PlayerCombatController`, combat
runtimes, character/kit data, player visual overlay, input bindings.

- [ ] **B1 Normalize the hero baseline.**
  - As-is: profile selection changes health, movement, accent, and combat kit.
  - To-be: one hero definition owns shared stats; loadout selects combat only.
  - Accept: movement metrics and all fixed-route fixtures use the one hero envelope.
  - Guard: no discipline changes collision shape, double jump, dash count, or climb.
- [ ] **B2 Reclassify the current kits.**
  - `warrior` -> `sword_shield`, `archer` -> `bow`, `assassin` -> `twin_blades`.
  - Preserve exact attack/skill/mastery behavior while moving compatibility ownership.
  - Retain historical IDs only inside migration aliases and v1 fixtures.
- [ ] **B3 Add two weapon slots and active-slot state.**
  - Add equip validation, swap cooldown/commit rules, per-discipline cooldown/passive
    state, and an immutable combat-loadout snapshot.
  - Accept: swap fixture proves complete kit/HUD change and no cooldown/passive leak.
- [ ] **B4 Add remappable Weapon Swap input.**
  - Keyboard and gamepad defaults, conflict checks, prompt glyph, persistence, and
    accessibility name must be covered.
- [ ] **B5 Update procedural hero presentation.**
  - One body identity; active weapon and armor silhouette/accent communicate loadout.
  - Remove class-colored body identity after screenshot parity passes.

*Visible result:* a developer/production route starts one hero with Sword & Shield
and Bow, switches complete kits in the existing Ruin Approach, and can clear it.

*Batch gate:* three discipline combat suites, combat spacing, boss base-clear, input,
fixed route, production boot, and stage validation pass.

## Phase C - Full Armory Loadout And Build Resolution

**Goal:** Replace per-character loadouts with one complete, previewable armory preset.

**Source owners:** new typed `ArmoryLoadout` value, `EquipmentDefinition`, equipment
catalog, `PlayerBuild`, a migration adapter, and the Armory prototype. Persistent
`ProfileData`/`ProfileState` activation remains Phase D work.

- [ ] **C1 Define the standalone target `ArmoryLoadout` value.**
  - Weapon A/B form IDs, active slot, enchantment A/B, armor, charm, relic,
    consumable, and discipline mastery presets.
  - Accept: validation reports the exact invalid slot, ownership, compatibility, or
    duplicate-form error.
  - Guard: do not serialize this value into the v1 profile schema.
- [ ] **C2 Generalize compatibility and build sources.**
  - Replace character compatibility with slot, discipline, and shared tags.
  - Keep support equipment shared across both active disciplines.
- [ ] **C3 Build one armory snapshot/preview facade.**
  - UI receives owned/locked options, base/result stats, behavior changes, costs,
    ranks, branches, enchantments, and validation errors. The prototype emits
    transient preview/equip intents; persistent commands are enabled in Phase D.
- [ ] **C4 Convert current support gear.**
  - Retain Traveler Jacket, Patched Mail, Runner Cloak, Copper/Spring charms,
    Slime Relic, and three consumables with truthful target compatibility.
- [ ] **C5 Record the exact v1 loadout -> target value field mapping.**
  - Keep per-character profile writes active until Phase D migration and round-trip
    tests pass; do not create a second temporary persistence format.

*Visible result:* an in-memory Armory prototype can equip two existing weapon forms
plus all support slots, preview the final build, start a development stage, and
reproduce the preview. Persistent production writes remain unchanged.

## Phase D - Profile Save V2 And Three Local Slots

**Goal:** Preserve every v1 player fact while exposing normal profile selection and
recovery behavior.

**Source owners:** `ProfileData`, `ProfileSaveService`, `ProfileState`, new profile
registry/metadata, profile UI, existing persistence validators.

- [ ] **D1 Define v2 schema and migration.**
  - As-is: v1 owns per-character loadouts/mastery and one file.
  - To-be: v2 owns hero arsenal, tutorial state, blueprints, enchantments, ranks,
    branches, presets, materials, settings, playtime, and persistent ledger.
  - Accept: three representative v1 fixtures migrate to exact v2 expectations.
  - Guard: v1 primary rotates only after staged v2 round-trip validation.
- [ ] **D2 Generalize save paths to slots.**
  - `user://profiles/slot_1..3/profile.json`, independent backups, metadata summary,
    selected-slot registry, and current `profile.json` import into slot 1.
- [ ] **D3 Add profile commands.**
  - Create, select, rename, delete with confirmation, retry failed save, and expose
    last played/build/stage metadata without loading another slot into active state.
- [ ] **D4 Add profile-slot UI and error states.**
  - Empty, active, saving, failed, corrupt-recovered, incompatible-newer-version,
    and delete confirmation states.
- [ ] **D5 Expand persistence tests.**
  - Slot isolation, backup rotation, failed staging, corruption recovery, schema
    rejection, v1 import idempotence, Unicode profile name, and settings isolation.
- [ ] **D6 Activate v2 Armory writes and retire v1 loadout writes.**
  - Route the Phase C facade through profile commands only after migration fixtures
    pass; keep historical readers solely at the v1 import boundary.
  - Accept: a saved Armory preset round-trips through all three slots and no target
    runtime writes a per-character loadout dictionary.

*Batch gate:* no test reads/writes the user's default profile path; profile v1 backup
survives migration; release matrix passes with v2 defaults.

## Phase E - Enchantments, Enhancement, And Reward Economy

**Goal:** Add four bounded elemental rules and deterministic permanent investment
on the v2 profile contract without duplicating cards, temporary forging, or
materials.

**Source owners:** new enchant/enhancement catalogs, damage/status resolution,
`ProfileCommandService`, `RunState`, reward catalogs, forge UI/services.

- [ ] **E1 Implement one shared enchantment status owner.**
  - Fire, Frost, Poison, Shock follow the canonical rules and secondary-hit guards.
  - Attack definitions declare `none/once/finisher` application; runtimes do not
    implement private element copies.
- [ ] **E2 Add weapon/armor enhancement state and commands.**
  - Weapon Rank 0-3, armor Rank 0-2, authored Rank 2 branch, material costs,
    Boss Core gate, preview, atomic purchase, and branch selection.
- [ ] **E3 Preserve progression responsibilities.**
  - Technique cards remain run-local behavior changes.
  - Temporary forge remains run-local and visibly time-bounded.
  - Charms/relics remain fixed and do not gain rank trees.
- [ ] **E4 Add blueprint ownership and authored reward sources.**
  - Blueprints are unique unlock IDs, never a fifth wallet.
  - Update chest/stage/boss rewards and duplicate salvage with source-attributable
    transaction IDs.
- [ ] **E5 Run the first-slice 3 x 4 discipline/enchantment matrix.**

*Visible result:* the same two-weapon loadout can be prepared with different
elements and produces visibly different, deterministic combat interactions.

## Phase F - Checkpoint Run Suspend And Continue

**Goal:** Let players stop and resume a run safely without arbitrary save states or
reward duplication.

**Source owners:** new `RunSuspendData/SaveService`, `RunState`, `RunDirector`,
`RunPhase`, stage checkpoint/objective owners, main/pause menu.

- [ ] **F1 Define restorable run facts.**
  - Seed, phase, approved plan/content version, checkpoint, health, XP/level, coins,
    unsettled materials, loadout snapshot, cards, upgrades, consumable, objectives,
    pending mandatory choice, elapsed time, and transaction ledgers.
  - Explicitly exclude node trees, enemy transforms, projectiles, animations, and
    mid-attack state.
- [ ] **F2 Add export/restore commands to run owners.**
  - `RunState` validates payload and reconstructs domain state.
  - `RunDirector` reconstructs the stage/phase and hands the player to the authored
    checkpoint only after setup validation succeeds.
- [ ] **F3 Define legal write boundaries.**
  - Authored checkpoint activation, inter-stage Armory, pending mandatory choice,
    explicit Save & Return, and application shutdown after a safe snapshot.
  - Keep the latest valid checkpoint snapshot available during the run for crash
    recovery; overwrite atomically at the next legal boundary.
- [ ] **F4 Add Continue/abandon lifecycle.**
  - Continue loads the selected profile's valid suspend.
  - New Run with a suspend requires Continue or Abandon.
  - Death, victory, and explicit abandon delete suspend only after settlement.
- [ ] **F5 Validate duplicate safety and failures.**
  - Resume before/after chest claim, stage reward, pending level/card choice,
    temporary forge, checkpoint, boss entry, and failed stage reconstruction.

*Visible result:* Save & Return from Stage 2, restart the app, Continue, and resume
at the same checkpoint with identical build/currency/reward ownership.

## Phase G - Arsenal Trial Complete, Skip, And Replay

**Goal:** Teach baseline melee/guard/ranged/swap verbs once without making onboarding
a permanent tax.

**Source owners:** new tutorial stage/rooms and metadata, `RunDirector`, profile
tutorial command, objective/prompt UI, fixed enemies and reward transactions.

- [ ] **G1 Author four deterministic trial rooms.**
  - Blade, Guard, Bow, and Swap Trial; 30-60 seconds each; no long text overlays.
  - Reuse Walker/Charger/Shooter or smaller teaching variants with safe recovery.
- [ ] **G2 Add a first-profile choice.**
  - Play Trial and Skip Trial are both explicit; skip confirmation states equal
    mechanical rewards and Training replay availability.
- [ ] **G3 Make completion and skip one idempotent unlock command.**
  - Both paths grant Sword & Shield, Bow, default forms/preset, and tutorial state.
  - Accept: snapshots are equal except completion telemetry.
- [ ] **G4 Add Training replay.**
  - Replay grants no duplicate unlocks/materials and never replaces an active run.
- [ ] **G5 Fresh-player recognition test.**
  - Players demonstrate Basic, Heavy, Guard/Rush, Bow charge, and Weapon Swap without
    debug narration before starting Ruin Approach.

## Phase H - Replace Character Selection With The Armory Experience

**Goal:** Ship coherent player-facing preparation, gameplay, and save surfaces.

**Source owners:** MainMenu, CharacterSelect replacement, ProductionHUD, PauseMenu,
RestForge, result screens, reusable production components/styles.

- [ ] **H1 Replace Main Menu commands.**
  - Continue, New Run, Profiles, Training, Settings, Quit with truthful visibility,
    focus order, confirmation, and loading/error states.
- [ ] **H2 Replace `CharacterSelect` with authored `Armory`.**
  - Hero/loadout overview, next-stage pressures, two weapons, enchantments, support
    slots, mastery preset, stats/behavior comparison, costs, save status, Start.
  - Reuse decision panels; do not construct another large script-generated screen.
- [ ] **H3 Update HUD for active/secondary weapons.**
  - Persistent weapon pair, swap input/state, active passive meter, enchantment,
    Basic/Heavy/three skills, consumable, objective, and receipts.
- [ ] **H4 Separate inspect from equip.**
  - Pause Loadout Overview is read-only during stages; only Armory safe states equip.
- [ ] **H5 Add save/profile feedback.**
  - Saving/Saved/failure, suspend metadata, Continue summary, recovered backup, and
    incompatible-content options.
- [ ] **H6 Update result and telemetry.**
  - Record hero, both disciplines/forms/elements, support gear, mastery presets,
    cards, upgrade ranks, save/resume count, and tutorial path.
- [ ] **H7 Retire class selection UI, copy, colors, and obsolete capture fixtures.**

*UI acceptance:* keyboard and gamepad operate every surface; focus is visible and
returns correctly; 960x540, 1280x720, and 1920x1080 show no clipping/overlap; state
does not rely on color; reduced motion is respected.

## Phase I - Expansion, Cleanup, And Release Gates

**Goal:** Finish content breadth only after migration parity, then remove old owners
and prove the complete run.

- [ ] **I1 Fun gate the first three disciplines.**
  - Movement-only, representative encounters, mixed pressure, optional reward,
    attrition, boss punish, and full run with at least three distinct loadouts.
- [ ] **I2 Author Spear, Great Axe, Matchlock one vertical slice at a time.**
  - Each slice includes discipline/form/mastery data, presentation, reward unlock,
    representative encounter, boss fixture, and full target catalog validation.
- [ ] **I3 Complete target support gear counts without random filler.**
- [ ] **I4 Remove compatibility adapters and retired class resources.**
  - Only v1 migration code/fixtures may retain historical IDs.
- [ ] **I5 Carry forward traversal and presentation gates.**
  - Full branch-entry-to-return replay, invalid geometry fixtures, pickup audio,
    reduced motion, responsive/focus verification, and production-style runs.
- [ ] **I6 Update architecture, data index, release record, and `.agent/Documentation.md`.**

## Validation Cadence

Inner-loop checks:

- Targeted catalog validator for the touched discipline/equipment/enchantment.
- Focused combat or profile command validator.
- `git diff --check` and targeted `rg` terminology/owner guards.
- One 960x540 capture for a touched UI state when layout changes.

Batch gates:

- After B/E: combat spacing, three-discipline roster, boss base-clear, build preview.
- After C/D: profile state, persistence, migration, equipment decision UI.
- After F/G: production boot/flow, resume matrix, trial complete/skip parity.
- After H: shell/HUD/reward UI at all supported viewports and input modes.

Final gates:

- Headless import and short boot through `tools/godot.ps1`.
- Core and full release candidate matrices with updated target checks.
- Profile v1 -> v2, corrupt primary/backup, slot isolation, and suspend round trips.
- Six-discipline x stage/boss eligibility and four-enchantment interaction matrices.
- Full fixed-stage committed-return validation.
- At least one fresh-profile tutorial run, one skip run, one Save & Quit / Continue
  run, one death, and one boss clear on a production build.
- Rendered 960x540, 1280x720, and 1920x1080 UI review plus keyboard/gamepad focus.

Rerun policy:

- Run the smallest failed check after a concrete change or new hypothesis.
- Run a full matrix only at named batch gates and final handoff.
- Record known warnings; do not rerun a passing slow suite as progress.

Tool fallback:

- If in-app browser/UI automation fails twice for tool reasons, switch to Godot
  capture scripts, Playwright/browser DOM inspection, or documented manual evidence.

## Error Handling

- Missing target path: verify current owner with `rg`; do not create a parallel
  similarly named module without checking architecture.
- Invalid profile migration: preserve v1 primary/backup, show actionable failure,
  and stop activation of partial v2 data.
- Invalid run suspend: try backup; if both fail, offer Restart Stage or Abandon and
  do not settle/duplicate pending rewards automatically.
- Content-version mismatch: reject silent reconstruction and explain available safe
  actions.
- Trial scene failure: keep baseline unlock transaction unapplied and return to a
  stable profile/Armory surface.
- UI load failure: retain last valid snapshot and provide Retry/Main Menu.
- Existing unrelated changes: do not stage, revert, move, or reformat them.

## Guard Checks

- [ ] No production class selection, `CHARACTER_SELECT` phase, or class-specific
  movement remains.
- [ ] Historical `warrior/archer/assassin` IDs remain only in migration aliases,
  v1 fixtures, and archived/superseded documents.
- [ ] No element rule is implemented independently in a discipline runtime.
- [ ] No required route, boss opening, or objective requires one discipline/element.
- [ ] No UI writes profile, run, reward, enhancement, or save state directly.
- [ ] No random affix, rarity roll, upgrade failure, downgrade, destruction, or
  hidden stat range enters the target catalogs.
- [ ] No arbitrary node-tree or exact mid-frame state enters a run suspend.
- [ ] No Continue/reload path can replay a consumed transaction.
- [ ] Trial complete and skip grant identical mechanical state exactly once.
- [ ] No save test touches the user's real profile or suspend path.
- [ ] No retired testbed/debug UI/random production planner returns.
- [ ] No unrelated user-authored change is staged or reverted.

## Suggested Execution Order

1. A: target contracts and v1 fixtures.
2. B: one hero and three weapon disciplines.
3. C: complete armory loadout.
4. D: profile v2 and slots before persistent new progression writes ship.
5. E: enchantments, enhancement, and reward economy on v2.
6. F: run suspend/continue.
7. G: Arsenal Trial and skip parity.
8. H: production UI replacement.
9. I: later disciplines, cleanup, and release gates.

## Risks

- A broad rename can break working runtime behavior without improving the player
  experience. Keep aliases until parity tests pass, then remove once.
- Two full kits can overwhelm players. Preserve identical input roles and teach
  weapon swap only after each baseline kit is understood.
- Six disciplines times four elements can become 24 bespoke systems. Enforce four
  shared status owners and data-declared delivery.
- Permanent mastery, enhancement, equipment, and run cards can duplicate power.
  Keep their documented questions distinct and cap persistent direct power.
- Save v2 and run suspend can duplicate rewards if ledgers or pending choices are
  incomplete. Treat resume fixtures as release blockers.
- Profile slot deletion and v1 conversion are destructive. Require explicit
  confirmation and preserve backups until validated.

## Open Questions To Resolve During Implementation

- Final hero name, portrait, and narrative framing.
- Final animation/art treatment for weapon/armor presentation.
- Exact costs and unlock cadence after first-slice economy simulations.
- Whether same-discipline dual forms create useful play or should be disallowed
  after playtesting.

These questions do not block the first three-discipline migration contracts.

## Decision Notes

- `2026-07-14`: Selected a separate Arsenal Trial rather than renaming Ruin
  Approach. This keeps the normal run short, makes skip/replay clean, and prevents
  tutorial state from changing fixed Stage 1 rewards.
- `2026-07-14`: Selected three profile slots plus one autosaved checkpoint suspend,
  not unrestricted manual saves. This supports normal local-game continuity while
  preserving deterministic run/reward contracts.
- `2026-07-14`: Selected full support equipment but one slot per category. More body
  slots would add comparison work without adding a distinct gameplay decision.

## Handoff Summary

Read first:

1. `docs/design/ARSENAL_EQUIPMENT_PROGRESSION.md`.
2. This plan's Decisions, Current-State Map, and Guard Checks.
3. Current profile/combat/flow owners listed in Source Map.
4. The interactive report for feature-level relationships and UI intent.

Produce last:

- Updated runtime catalogs and architecture/data index.
- Profile v2 migration and run-suspend compatibility evidence.
- Rendered UI evidence and full release gate result.
- A completed plan marked `done` and concise durable updates in
  `.agent/Documentation.md`.

Stop only when the one-hero flow, first three migrated disciplines, complete
loadout, tutorial/skip, profile slots, Save & Quit / Continue, and all named final
gates are working. Later disciplines may remain a separately approved expansion
only if the owner explicitly narrows the complete-target scope.

## Next Steps

- [ ] Begin Phase A with committed v1 fixtures and target Resource contracts.
- [ ] Do not modify production character selection until the A batch gate passes.
- [ ] Deliver the Phase B one-hero/two-weapon playable slice before new content.
