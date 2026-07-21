---
type: plan
status: active
owner: BK
created: 2026-07-21
topic: High-density vehicle combat, one-second opening shot, and map-driven run upgrades
scope: Continuous primary fire, compact enemy populations, upgrade data/runtime/UI, map reward cadence, field items, stored SFX assets, validation, and specification alignment
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_stage_one_experimental_spec.md
  - ../../docs/product/vehicle_content_expansion_spec.md
  - ../../docs/product/progression_upgrade_system_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ./2026-07-21-deliberate-primary-multistage-run.md
  - ./2026-07-21-primary-charge-hud-content-expansion.md
---

# High-Density Combat and Map-Driven Upgrade Loop ExecPlan

This plan replaces the current press-once attack-energy rhythm with uninterrupted held fire plus a one-second opening-shot reward, rebuilds all three stages around substantially smaller and denser enemy groups, and makes the player's build emerge from 34 map-acquired upgrades instead of a deployment weapon choice. Seven implementation phases produce an early playable combat slice, then complete run upgrades, reward placement, deliberate selection UX, real stored SFX, and production validation.

## Why / Context

The current three-stage vehicle run is playable, localized, and visually coherent, but its combat density and progression do not match the latest owner direction. Primary fire accepts only `just_pressed`, consumes a three-second energy resource, and makes frequent combat input feel constrained. Ordinary enemies use 24–30 px collision radii and a shared 36 px visual radius, while each stage contains only 11–15 pre-boss entries. The result is a sparse field populated by relatively large threats.

Progression is similarly narrow. Deployment still asks the player to choose Repeater or Scatter before entering the map. The run upgrade pool has ten one-time Boolean effects, each stage has one required cache, and the upgrade window commits immediately on a card click or number key. The runtime therefore cannot express stackable projectile speed, count, damage, movement speed, elemental status, previewed level changes, or a map-driven build identity.

The target loop is direct and action-heavy: hold to fire continuously into many small enemies, deliberately stop for one second when a high-value target or breakable structure justifies a strong opening shot, and shape the vehicle through clear upgrade anchors encountered during the stage. This remains a manually aimed authored shooter, not an automatic survival arena and not a class-selection game.

## Purpose

- Objective: make the three-stage vehicle run immediately busier, more readable, and more replayable through continuous manual fire, compact enemy groups, and a fully specified map-driven upgrade system.
- Final artifact: one production-buildable Godot 4.7 run with one neutral starting vehicle, 68/76/84 authored enemies across Stages 1/2/3, 34 data-driven upgrades, nine field-item families, safe deliberate reward UI, and stored project-owned SFX files.
- Completion state: every checklist item, regression guard, deterministic validator, Korean/English rendered flow, Web release export, and production-style boot gate passes; this plan is then marked `done`.

## Assumptions

- Current master at `4d19a07`, the existing 5,200×2,200 stage geometry, current bosses, Korean-first localization, and the Sunken Ceramic Fresco visual direction are the implementation baseline.
- Run upgrades remain transient through all three stages; persistent materials, equipment, Forge, and mastery retain their separate active product boundary.
- Godot drawing and the current player/boss assets can represent the compact enemy and status states; this plan does not require a new art pack.
- The task can be completed locally with Godot 4.7, GDScript, typed Resources, Python's standard library for deterministic WAV generation, and the repository's existing build/validation tools.

## Pre-plan Evidence Already Verified

| Source or path | Verified fact | Decision affected | Recheck boundary |
| --- | --- | --- | --- |
| `AGENTS.md`, `.agent/AGENTS.md`, `.agent/PLANS.md` | Godot 4.7/GDScript, authored combat proof, flat-color direction, responsibility-shaped gameplay files, no unrequested dependency, and an ExecPlan for cross-system work are required. | Keep the existing engine and art direction, add no package, split new owners by responsibility, use this checklist plan. | Recheck before implementation if repository instructions change. |
| `scripts/vehicle/vehicle_primary_charge.gd` | One accepted press consumes stored energy; full recovery takes 3.0 seconds and minimum fire energy is 0.34. | Retire this owner and replace it with a continuous-fire/idle-opening-shot owner. | Recheck immediately before editing if the file changed after this plan commit. |
| `scripts/vehicle/vehicle_stage_one.gd:598-766` | Primary input uses `is_action_just_pressed`; both primaries consume charge and set a 0.12 second cooldown. | Use `is_action_pressed`, retain a 0.12 base cadence, and make idle charge independent of firing availability. | Same-branch changes to player input or projectile spawn require plan revalidation. |
| `scripts/vehicle/vehicle_stage_catalog.gd` | Stages currently contain 15, 11, and 11 pre-boss entries; activation is mostly distance-based. | Replace flat sparse lists with authored encounter-group data and deterministic formations totaling 68/76/84 enemies. | Recheck if stage geometry or cover changes. |
| `scripts/vehicle/vehicle_stage_one.gd:381-493` and `vehicle_stage_visual_profile.gd` | Ordinary collisions are 24–30 px and ordinary visuals use a 36 px radius. | Add 10–13 px minions and reduce ordinary standards to 16–22 px collision / 24–32 px visual radii. | Recheck if player/camera scale changes. |
| `scripts/vehicle/vehicle_stage_rules.gd:67-147` | Upgrade definitions are ten dictionaries, offers are fixed slices, and definitions do not contain levels, modifiers, prerequisites, or exclusion groups. | Move upgrade definitions to typed Resources and add level/compatibility/offer owners. | Recheck if another card runtime lands first. |
| `scripts/vehicle/vehicle_stage_one.gd:1776-1799` | `applied_upgrades` is a Boolean dictionary and `apply_upgrade` rejects every duplicate. | Replace with level counts, derived stats, behaviors, element-core exclusivity, preview, and an immutable receipt. | Recheck if run persistence begins storing card state. |
| `scripts/ui/vehicle_stage_ui.gd:498-526,741-769,897-902` | A card button immediately disables all cards and emits the selection; the first card receives focus automatically. | Separate highlight from confirmation, add an input guard and value preview, and move the panel to its own component. | Recheck if the modal is refactored before implementation. |
| `scripts/vehicle/vehicle_stage_catalog.gd:185-207` and `vehicle_stage_one.gd:913-939` | Each stage has five placed pickups, three crates, and only repair/attack/overdrive/barrier effects. | Expand to nine item families with authored placement and bounded encounter rewards. | Recheck if pickup blueprints change. |
| Repository asset inventory | No `.wav`, `.ogg`, `.mp3`, `.flac`, `.aac`, or `.m4a` file exists; `_build_audio()` synthesizes short tones in memory. | Add stored project-owned SFX assets and keep voice acting and music outside this milestone. | Recheck if audio assets land independently. |
| `docs/product/vehicle_content_expansion_spec.md` and `progression_upgrade_system_spec.md` | Active specs still require deliberate attack energy and discourage raw numeric run upgrades. | Align both specs with bounded stackable fundamentals plus behavior mutations before closing the implementation. | Recheck on any accepted product-spec revision. |
| Git `4d19a07` | Master contains the deliberate-primary and three-stage implementation; working tree also contains unrelated Godot `.import` churn. | Build from current master and never stage unrelated generated import changes. | Audit before every commit. |

## Locked Product Decisions

| Topic | Final decision | Rationale |
| --- | --- | --- |
| Starting identity | Every run starts with one neutral `pulse_cannon`; Repeater/Scatter deployment choice and garage toggle leave the active flow. Existing saved primary IDs are read but normalized to the neutral cannon and are no longer written. | Build identity must emerge in the map rather than before play. |
| Primary cadence | Holding left mouse/Left Shift/right trigger fires every 0.12 seconds while firing is permitted. No ammo, heat, charge cost, release latch, or minimum-energy gate exists. | Continuous manual fire is the baseline fun action. |
| Opening-shot charge | Time since the last successful primary shot fills from 0 to 1 over exactly 1.0 second. Below 0.25 seconds there is no bonus; from 0.25–1.0 seconds the next projectile scales linearly; the first successful shot consumes the charge. | One second rewards a deliberate pause without dominating the rhythm. |
| Full opening shot | Full charge grants 1.75× health damage, 3.0× stagger and structure damage, 1.5× projectile radius, and one temporary pierce. It is strongest against installations, breakable structures, elites, and bosses but remains useful against ordinary enemies. | The pause has a clear target-priority purpose without making stop-start fire mandatory for every minion. |
| Primary baseline | Pulse Cannon uses 18 damage, 1120 px/s projectile speed, 1100 px range, 5.5 px radius, one projectile, zero pierce, zero bounce, and a 0.12 second interval. | Current speed/range are readable; lower per-shot damage supports dense low-health targets. |
| Enemy scale | Swarm collisions use 10–13 px and visuals 16–20 px. Standard mobile roles use 16–22 px collision and 24–32 px visuals. Installations use 28–36 px collision and 42–52 px visuals. Field/stage bosses retain strong 80/112 px visual hierarchy. | Many enemies can coexist while role silhouettes remain legible. |
| Stage population | Excluding the stage boss, Flooded Works contains 68 enemies, Tidal Archive 76, and Storm Drydock 84. No more than 28 ordinary enemies are active locally and typical visible pressure is 12–22. | This is substantially denser than 11–15 entries without turning the whole map into one global wave. |
| Threat coordination | Attack permission uses a 4.0-point budget: swarm contact 0.25, swarm projectile 0.5, standard direct attack 1.0, installation/support 1.25, and major denial 1.5. At most two ranged volleys and one major denial may be active simultaneously. | Population and danger are controlled separately. |
| Health presentation | Priority installations and bosses always show health. Standard enemies show health while targeted or for 1.5 seconds after damage; swarm enemies show it while targeted or for 1.0 second after damage. Minimap shows groups and priority targets, never every minion. | Dense combat stays readable. |
| Upgrade lifetime | All 34 upgrades are run-local. Stackable upgrades store integer levels; unique mutations store level 1; all reset on a new run and persist between the three stages of one run. | No premature permanent economy or save migration is introduced. |
| Element rule | Incendiary, toxin, and cryo cores are mutually exclusive for one run. After one core is chosen, the other core and its dependents are filtered from offers. | One readable elemental identity avoids proc clutter. |
| Reward cadence | Each stage has a mandatory early calibration cache, a mandatory relay cache, an optional field-boss cache, and a post-boss offer. Stage 3 ends after its post-boss selection/result. A run grants nine mandatory and up to three optional upgrades. | Builds form early and continue changing without constant modal interruption. |
| Offer contract | Every offer has three compatible, non-maxed cards from at least two families. The first Stage 1 offer always contains one primary fundamental, one elemental core, and one passive/mobility card. Relay offers guarantee one behavior change; field-boss and post-boss offers guarantee one unique or element mutation. | Offers remain understandable and cannot become three invisible stat copies. |
| Upgrade confirmation | Opening a choice applies a 0.35 second input guard. Click/Space/keys 1–3 select only. A separate enabled `장착 / Equip` button confirms once. Mandatory offers cannot be skipped; optional field-boss offers include a separate `보상 포기 / Leave reward` action. | Carry-over input and single-click mistakes cannot consume a reward. |
| Field items | Field items are immediate/temporary and separate from run upgrades. Ordinary kills do not spray loot; authored placements, crates, group completion, and elites create bounded rewards. | More items add combat variation without floor clutter. |
| Audio scope | Store project-owned SFX as actual WAV files. This milestone adds no spoken voice, BGM, Music bus, licensed pack, or external dependency. | The current generated tones are inadequate as final feedback, while voice/music production is a separate scope. |

## Complete Upgrade Catalog

All percentage modifiers apply to the base/derived value multiplicatively unless the row explicitly says percentage points or a fixed amount. A selected stack immediately produces a previewable old/new value and an immutable apply receipt.

### Primary fundamentals

| ID | Max | Exact effect |
| --- | ---: | --- |
| `kinetic_rounds` | 3 | Primary health damage +15% per level. |
| `accelerator_coil` | 3 | Primary projectile speed +20% per level. |
| `rapid_cycle` | 3 | Primary interval -10% per level; hard floor 0.085 seconds. |
| `forked_muzzle` | 2 | +1 projectile per level. Two shots deal 70% base damage each; three deal 55% each. Projectiles spread in 7-degree steps around aim. |
| `phase_lance` | 2 | +1 permanent primary pierce per level. |
| `mass_driver` | 3 | Projectile radius +18% and structure damage +25% per level. |
| `ricochet_matrix` | 1 | One cover bounce; the bounced projectile retains 70% damage and cannot bounce again. |
| `stabilizer` | 2 | Range +15% and multi-projectile spread -30% per level. |

### Element cores and mutations

| ID | Max | Requirement | Exact effect |
| --- | ---: | --- | --- |
| `incendiary_core` | 1 | No element core | Primary hit applies Burn: 4 damage/second for 3 seconds; reapplication refreshes duration. |
| `thermal_compound` | 2 | `incendiary_core` | Burn gains +2 damage/second and +1 second duration per level. |
| `flashover` | 1 | `incendiary_core` | A full opening shot consumes Burn, immediately deals 125% of its remaining damage, and splashes that damage within 70 px. |
| `toxin_core` | 1 | No element core | Primary hit applies Poison: 2 damage/second for 5 seconds, up to three stacks with independent duration. |
| `concentrated_toxin` | 2 | `toxin_core` | Poison gains +1 damage/second and +1 maximum stack per level. |
| `contagion` | 1 | `toxin_core` | A poisoned enemy's death transfers one stack with its base duration to enemies within 100 px. |
| `cryo_core` | 1 | No element core | Primary hit slows movement and attack timers by 18% for 2 seconds. Boss magnitude and duration are halved. |
| `deep_freeze` | 2 | `cryo_core` | Slow gains 8 percentage points and 0.5 seconds per level; ordinary-enemy slow is capped at 40%. |
| `shatter` | 1 | `cryo_core` | A full opening shot against a target slowed by at least 30% deals +40% health damage and clears the slow. |

### Passive seeker

| ID | Max | Exact effect |
| --- | ---: | --- |
| `seeker_warhead` | 3 | Passive missile damage +20% per level. |
| `seeker_cycle` | 3 | Passive cooldown -12% per level; hard floor is 60% of the 1.35 second base. |
| `twin_seekers` | 2 | +1 simultaneous missile per level. Two missiles deal 85% base each; three deal 70% each. |
| `phase_seeker` | 2 | +1 passive missile pierce per level. |
| `hunter_firmware` | 1 | Target order becomes support/installation, elite, current aim target, then nearest. Missile kills create a 65 px burst for 35% missile damage. |

### Mobility, sustain, opening shot, dash, and EMP

| ID | Max | Exact effect |
| --- | ---: | --- |
| `tuned_thrusters` | 3 | Base movement speed +8% per level. |
| `dash_capacitor` | 2 | Dash cooldown -12% per level; hard floor is 75% of the 1.25 second base. |
| `reinforced_hull` | 3 | Maximum health +15 and immediate repair +15 per level. |
| `pickup_magnet` | 3 | Pickup collection radius +70 px per level. |
| `field_converter` | 2 | Timed field-item duration +20% and barrier strength +10 per level. |
| `fast_capacitor` | 2 | Full opening charge time changes from 1.0 to 0.85 seconds at level 1 and 0.75 seconds at level 2. |
| `breach_round` | 2 | Opening-shot stagger and structure multipliers gain +50% per level. |
| `ion_wake` | 1 | Dash leaves a 0.75 second damaging trail with the current truthful visual radius. |
| `ram_pulse` | 1 | Dash completion creates the current 145 px damage/clear pulse. |
| `emp_capacitor` | 2 | EMP cooldown -15% per level; hard floor is 70% of the 13 second base. |
| `emp_focus` | 2 | EMP damage +20% and radius +15% per level. |
| `emp_aftershock` | 1 | EMP repeats once at 68% radius and reduced damage after the existing delay. |

## Enemy and Encounter Contract

### New compact roles

| Role | Collision / visual | Health / speed | Behavior and budget |
| --- | --- | --- | --- |
| `scrap_drone` | 12 / 18 px | 18 / 225 | Swarms toward the player, commits a short contact dash, costs 0.25. |
| `needle_drone` | 11 / 17 px | 14 / 170 | Holds 300–460 px, fires one cover-blocked needle, costs 0.5. |
| `spark_minelet` | 10 / 16 px | 12 / 90 | Drifts to a nearby lane, warns before a small proximity burst, costs 0.5. |

Existing chaser, shooter, controller, shield escort, and artillery roles become standard enemies with 16–22 px collision, 24–32 px visuals, and 40–68 health. Turrets, interceptor towers, generators, field bosses, and stage bosses remain priority silhouettes and do not become swarm units.

`VehicleStageCatalog` will define encounter groups rather than dozens of unrelated top-level entries. Each group owns a stable ID, activation rectangle, leash rectangle, anchor, deterministic formation, role counts, formation seed, priority targets, and completion reward policy. Formation expansion is deterministic and must reject cover overlap, entrance overlap, reward-anchor overlap, and player-start overlap during validation; it never relocates runtime enemies randomly.

| Stage | Groups | Total before stage boss | Local active cap | Composition emphasis |
| --- | ---: | ---: | ---: | --- |
| Flooded Works | 7 | 68 | 24 | Scrap swarms around existing chasers, turrets, mines, and generators. |
| Tidal Archive | 8 | 76 | 26 | Needle drones travel through current lanes around spotters and interceptors. |
| Storm Drydock | 8 | 84 | 28 | Mixed drone groups cross safe-zone timing around escorts and artillery. |

Player projectiles are capped at 240, hostile projectiles at 120, and cosmetic effects at 96. The oldest non-opening player projectile is retired when the player cap is exceeded; ordinary hostile emission waits when its cap is reached; already telegraphed priority attacks are never deleted; the oldest cosmetic effect is retired first. Inactive groups do not move, attack, draw health, or appear as individual minimap contacts.

## Map Upgrade and Item Contract

Every stage uses these exact reward beats:

1. `calibration_cache` at the shared safe lane near `Vector2(1760, 1100)`, unlocked by reaching the installation threshold rather than exterminating enemies; mandatory before the relay district.
2. `field_boss_cache` spawned at the defeated field boss anchor; optional and explicitly skippable.
3. Existing `relay_cache` at `Vector2(3470, 1120)`, unlocked by the two required installations; mandatory before the boss arena.
4. `boss_reward` presented after boss victory and before stage advance/result; mandatory.

Ordinary enemies never gate these rewards or the next stage. Only the two named installations gate the relay cache, and only the active stage-boss arena seals movement.

The field-item catalog is fixed to nine families:

| ID | Exact field effect |
| --- | --- |
| `repair` | Restore 35 health immediately. |
| `major_repair` | Restore 70 health immediately; authored/elite reward only. |
| `attack_boost` | Primary and passive damage +30% for 8 seconds. |
| `coolant` | Primary interval -25% for 8 seconds, respecting the 0.085 second floor. |
| `overdrive` | Movement +35%, current collision mitigation, and ramming damage for 8 seconds. |
| `barrier` | Grant 50 barrier for 10 seconds, clear nearby hostile projectiles, and repel nearby ordinary enemies. |
| `seeker_battery` | Immediately launch up to three seekers at valid targets and reset passive cooldown. |
| `capacitor_cell` | The next three primary firing starts within 8 seconds count as full opening shots without idle wait. |
| `magnet_field` | Add 250 px collection radius for 10 seconds. |

Each stage contains eight authored loose pickups and five crates. Completing a non-boss encounter group has a deterministic 35% chance, seeded by run/stage/group ID, to create one pickup from its allowed table; a field boss always creates `major_repair` plus its upgrade cache. Individual swarm deaths create no loose loot. No ammunition item or ammunition HUD is introduced.

## Upgrade Choice UX Contract

This is a Level 3 UI flow change under the UI/UX gate because it changes a mandatory decision path, keyboard behavior, responsive composition, and multiple reachable states.

- The live field remains visible under the existing dim layer and simulation remains paused.
- A 0.35 second guard ignores mouse, keyboard, and gamepad confirmation input carried into the modal.
- No card is selected on open. Focus may start on the first card, but focus and selection remain visually distinct.
- Mouse click, Space on a focused card, or keys 1–3 select/highlight only; they never apply an upgrade.
- The detail region shows family, current level, next level, exact current-to-next values, trigger, and incompatibility explanation where relevant.
- `장착 / Equip` is disabled until a valid card is selected. Activating it emits one stable upgrade ID and disables the complete modal until the runtime returns a receipt.
- A failed apply leaves the modal open, restores controls, and shows a localized deterministic reason; it never silently consumes the cache.
- Mandatory calibration/relay/boss rewards have no close or skip command. Escape shows `업그레이드를 하나 선택해야 합니다 / Choose one upgrade` without leaving the state.
- Optional field-boss rewards include `보상 포기 / Leave reward`; this action asks for one explicit confirmation and records the cache as declined.
- The modal fits 960×540, 1280×720, and 1920×1080 in Korean and English with 44 px minimum primary targets, stable focus order, no horizontal scroll, and no clipped dynamic values.

## Stored SFX Contract

The implementation creates deterministic project-owned PCM WAV files under `art/audio/vehicle/sfx/` using `tools/audio/generate_vehicle_sfx.py` and Python's standard `wave` module. The generator has no third-party dependency and records its parameters in source. Required files are:

- `primary_start.wav`, `primary_loop.wav`, `primary_end.wav`;
- `opening_ready.wav`, `opening_fire.wav`;
- `impact_enemy.wav`, `impact_cover.wav`;
- `enemy_destroy_small.wav`, `enemy_destroy_priority.wav`;
- `pickup.wav`, `upgrade_select.wav`, `upgrade_confirm.wav`, `boss_warning.wav`.

`scripts/presentation/vehicle_audio_director.gd` owns start/loop/end primary playback, one-shot routing, SFX bus volume, and a two-voice impact limiter. Runtime tone synthesis in `_build_audio()` and `_make_tone()` is retired after every named sound resolves. There is no `Music` bus, speech/voice asset, streamed soundtrack, or external license entry in this plan.

## Scope / Non-scope

In scope:

- continuous held primary and one-second opening shot;
- neutral starting weapon and retirement of deployment weapon-type choice;
- compact enemy archetypes, authored encounter groups, higher population, attack budget, projectile/effect caps, and dense health/minimap presentation;
- typed run-upgrade definitions, levels, derived stats, elemental statuses, compatibility, offers, preview, receipt, and reset behavior;
- exact map reward cadence and nine field-item families;
- deliberate upgrade selection UI and Korean/English copy;
- stored project-owned SFX and removal of runtime tone synthesis;
- current-spec alignment, focused validators, rendered evidence, Web export/boot, code-quality pass, lifecycle completion, and scoped commits.

Out of scope:

- permanent materials, equipment, Forge, mastery tree, shop, repair cost, or save-schema progression;
- additional stages, procedural maps, endless waves, new bosses, player classes, multiple selectable vehicles, ammunition, guard, or auto-aimed primary fire;
- spoken dialogue, voice acting, BGM, external sound/art packs, package installation, or dependency upgrades;
- changing the accepted Sunken Ceramic Fresco palette, current world bounds, cover geometry, boss route, language default, or ordinary-projectile cover collision.

Destructive or irreversible actions: none. The old saved primary field is ignored but not deleted from user files.

Exact actions requiring owner approval: adopting any external audio/art pack, adding BGM or voice production, changing save data persistently, altering cover/world geometry, deleting historical documents, force-pushing, or pushing remotely. None is required to complete this plan locally.

## Architecture and Ownership

| Concern | Final owner | Interface / invariant | Existing owner to reuse or retire |
| --- | --- | --- | --- |
| Primary cadence/opening state | `scripts/player/vehicle_primary_weapon.gd` (`VehiclePrimaryWeapon`) | `tick(delta, firing_allowed, input_held)`, `consume_shot()`, `snapshot()`; availability is never tied to charge. | Retire `scripts/vehicle/vehicle_primary_charge.gd`. |
| Upgrade definition | `scripts/cards/vehicle_upgrade_definition.gd`, `scripts/cards/vehicle_stat_modifier.gd`, `data/cards/vehicle/*.tres` | Stable ID, family, max level, prerequisites, exclusions, source tags, level modifiers, behavior IDs, localization keys. | Remove definitions from `VehicleStageRules.get_upgrade_pool()`. |
| Catalog and offers | `scripts/cards/vehicle_upgrade_catalog.gd` | Loads all definitions, validates unique IDs, filters compatible cards, and creates deterministic three-card offers by run/stage/source seed. | Retire `get_card_offer()` fixed slicing. |
| Run build | `scripts/cards/vehicle_run_build.gd` | Owns levels, element core, derived stats/behaviors, preview, apply receipt, stage preservation, and run reset. | Replace `applied_upgrades: Dictionary = {id:true}`. |
| Status effects | `scripts/combat/vehicle_status_runtime.gd` | Owns burn, poison, slow tick/stack/refresh/resistance rules and returns explicit damage/speed results. | Remove status logic from projectiles/UI; stage only delegates. |
| Enemy archetypes | `scripts/enemies/vehicle_enemy_archetypes.gd` | Stable role data for health, speed, collision, visual radius, attack cost, health-display class, and status resistance. | Move role constants out of `_make_enemy()`. |
| Encounter activation | `scripts/encounters/vehicle_encounter_director.gd` | Expands deterministic formations, owns activation/leash, attack budget, projectile/effect caps, and group-completion reward intent. | Replace distance-only activation and raw committed count in `vehicle_stage_one.gd`. |
| Stage content | `scripts/vehicle/vehicle_stage_catalog.gd` | Owns encounter groups, reward anchors, item/crate placement, environment, cover, and boss identity. | Reuse and replace sparse enemy lists. |
| Shared runtime | `scripts/vehicle/vehicle_stage_one.gd` | Orchestrates owners, projectile truth, player/enemy interaction, stage flow, snapshots, and drawing; it does not define cards or archetype values. | Reduce monolithic responsibilities without rewriting boss patterns. |
| Upgrade UI | `scripts/ui/vehicle_upgrade_choice_panel.gd` | Owns guard, focus, selection, preview display, confirm/decline, responsive layout, and emits intents only. | `vehicle_stage_ui.gd` hosts the component and HUD snapshots. |
| Audio presentation | `scripts/presentation/vehicle_audio_director.gd`, `art/audio/vehicle/sfx/*.wav` | Stored asset playback, loop lifecycle, SFX bus, voice limiting. | Retire `_build_audio()`/`_make_tone()` synthesis. |
| Validation | focused scripts under `tools/validation/` plus `validate_vehicle_stage_one.gd` | Pure contract checks, deterministic stress run, responsive UI debug surface, full route. | Preserve existing 125 checks and extend rather than weaken them. |

## Proposed Design

`VehicleStageOne` remains the shared run orchestrator but delegates four growing responsibilities. `VehiclePrimaryWeapon` owns continuous cadence and idle-opening state; `VehicleEncounterDirector` expands catalog formations and controls activation/pressure; `VehicleRunBuild` derives combat values from typed card Resources and delegates elemental state to `VehicleStatusRuntime`; `VehicleUpgradeChoicePanel` renders snapshots and emits deliberate reward intents. The stage catalog remains the authored map/content boundary, and the new audio director owns stored SFX playback.

The vertical data flow is fixed:

```text
input -> VehiclePrimaryWeapon snapshot/shot intent -> VehicleRunBuild derived stats
      -> projectile/status payload -> enemy archetype/status runtime -> damage/result feedback

stage reward anchor -> deterministic catalog offer -> UI selection/preview
                    -> explicit confirm -> run-build receipt -> resumed combat
```

No UI owner applies an upgrade, no card Resource calls gameplay code, no enemy decides global pressure, and no audio owner changes simulation state.

## As-Is / To-Be Delta Map

| Concern | As-is | To-be | Acceptance | Guard |
| --- | --- | --- | --- | --- |
| Basic firing | One shot per press, energy-gated. | Held fire every 0.12 seconds. | One second of held input produces 8–9 successful baseline shots. | Dash/paused/modal states still suppress fire. |
| Strong attack | Three-second full charge blocks ordinary fire. | Idle-only first-shot bonus reaches full at 1.0 second. | Continuous fire never pauses for charge; a 1.0 second idle produces exactly one full opener. | Brief release below 0.25 seconds gives no bonus. |
| Starting build | Repeater/Scatter chosen before play. | Neutral Pulse Cannon, first map cache begins build identity. | Deployment has one launch action and no weapon toggle. | Old persisted IDs do not change combat. |
| Enemy field | 11–15 relatively large entries. | 68/76/84 compact enemies in authored groups. | Stage contract counts and rendered local density match targets. | Active/attack/projectile caps hold. |
| Upgrades | Ten non-stacking Booleans. | 34 typed definitions with levels, elements, behaviors, preview, and receipts. | Every catalog row loads and applies exact values. | UI/player code contains no hard-coded card copy. |
| Reward cadence | One required cache per stage. | Early, relay, optional field-boss, and post-boss choices. | Nine mandatory and up to three optional upgrades are possible per run. | Ordinary extermination never gates progress. |
| Choice safety | One click/key applies immediately. | Guard, select, compare, explicit confirm. | No single click or number press can mutate build state. | Mandatory offers cannot disappear. |
| Items | Four effects, five pickups, three crates. | Nine effects, eight pickups, five crates plus bounded group rewards. | Every effect is visible and resets correctly. | Swarm deaths do not create loot spray. |
| Audio | In-memory beeps only. | Thirteen stored project-owned WAVs and a playback owner. | All assets import/load and continuous fire loop starts/stops cleanly. | No unlicensed/external file enters the repo. |

## Milestones

1. Prove continuous fire, one-second opening shots, compact enemies, and pressure caps in one playable Stage 1 slice.
2. Expand the compact authored population and presentation across all three stages.
3. Land the complete typed 34-upgrade build/status system.
4. Move build formation into map reward anchors and expand field items.
5. Make reward selection deliberate, previewable, localized, and responsive.
6. Replace synthesized tones with stored project-owned SFX.
7. Align specs, validate the production build, complete quality/lifecycle gates, and commit scoped work.

## Tasks

### Phase 1: Playable dense-combat vertical slice

Goal: make the Flooded Works approach immediately demonstrate held fire, a one-second opening shot, and many small targets before building the wider progression system.

Source owners: `vehicle_primary_weapon.gd`, `vehicle_enemy_archetypes.gd`, `vehicle_encounter_director.gd`, `vehicle_stage_catalog.gd`, `vehicle_stage_one.gd`, `vehicle_stage_visual_profile.gd`, focused validators.

- [ ] **1.1 Replace attack energy with continuous fire and idle opening state.**
  - As-is: `VehiclePrimaryCharge` gates every shot and input uses `just_pressed`.
  - To-be: `VehiclePrimaryWeapon` exposes the exact baseline and one-second opening contract; runtime uses held input.
  - Accept: cadence, partial/full opener, one-shot consumption, dash suppression, reset, and snapshot tests pass.
  - Guard: no ammo/heat/release latch appears and passive/EMP/dash input remains unchanged.
- [ ] **1.2 Add compact archetype data and one Flooded Works swarm group.**
  - As-is: role values are a match block and ordinary visual radius is globally 36 px.
  - To-be: new archetype owner supplies exact swarm/standard/installation sizes and one deterministic 18-enemy approach group.
  - Accept: rendered 1280×720 approach shows at least 12 small enemies, a distinguishable player, and truthful hit radii.
  - Guard: no enemy spawns in cover, the entry lane, or a reward anchor.
- [ ] **1.3 Add attack-budget and cap enforcement.**
  - As-is: two ordinary startup/active states are allowed regardless of role weight.
  - To-be: the 4.0-point budget and projectile/effect caps govern the slice.
  - Accept: stress validation never exceeds budget/caps and telegraphed priority attacks are not deleted.
  - Guard: more bodies do not create unavoidable overlapping ranged volleys or denial zones.

Batch acceptance: the first combat space is playable with held fire, 1.0 second full opener, 12–18 visible compact enemies, correct cover collision, and no runtime errors.

Batch guard: existing boss, stage transition, localization, settings, and map reachability tests still pass.

### Phase 2: Complete all-stage enemy density and presentation

Goal: convert all three sparse blueprints into authored groups at the locked populations while preserving each stage's spatial identity.

Source owners: `vehicle_stage_catalog.gd`, `vehicle_enemy_archetypes.gd`, `vehicle_encounter_director.gd`, `vehicle_stage_one.gd`, `vehicle_stage_visual_profile.gd`, minimap/HUD snapshot code.

- [ ] **2.1 Define and validate every encounter group.**
  - To-be: 7/8/8 groups expand to exactly 68/76/84 pre-boss enemies with stable IDs and deterministic positions.
  - Accept: every expanded spawn passes cover, entrance, reward-anchor, boss-gate, and reachability validation.
  - Guard: required installations and optional/stage bosses retain stable IDs and progression semantics.
- [ ] **2.2 Apply role-specific activation, leash, and coordination.**
  - To-be: groups activate by authored rectangles, leash locally, and enforce 24/26/28 active caps plus the shared threat budget.
  - Accept: skipped enemies cannot follow across the entire stage or block any later reward/exit.
  - Guard: moving enemies continue repositioning instead of remaining stuck.
- [ ] **2.3 Recompose dense enemy feedback.**
  - To-be: compact silhouette families, targeted/damaged health timing, group/priority minimap markers, and small/priority destruction effects replace always-large feedback.
  - Accept: role and danger remain readable at 960×540 and 1280×720 without displaying every health bar/minimap dot.
  - Guard: color is not the sole role cue and visual bodies do not imply larger damage areas.

Batch acceptance: each stage reaches its exact count, retains a readable safe entry, and shows 12–22 typical local enemies without exceeding the pressure contract.

Batch guard: Stage 2 current and Stage 3 storm behavior remain functional and ordinary enemies never become progression gates.

### Phase 3: Data-driven build, statuses, and exact 34-upgrade catalog

Goal: replace Boolean effects with a typed, stackable, previewable run build and implement every locked upgrade effect.

Source owners: new `scripts/cards/*`, `data/cards/vehicle/*.tres`, `vehicle_status_runtime.gd`, `vehicle_stage_one.gd`, localization CSV/translations, validators.

- [ ] **3.1 Add typed definitions, modifier resources, catalog validation, and all 34 `.tres` entries.**
  - Accept: IDs, families, localization keys, max levels, prerequisites, exclusions, source tags, modifier lengths, and behavior IDs validate uniquely.
  - Guard: definitions contain no UI nodes, runtime references, or localized stable IDs.
- [ ] **3.2 Add `VehicleRunBuild`, preview, apply receipt, and reset/stage-preserve behavior.**
  - Accept: each stack changes exact derived values, max levels reject safely, preview has no mutation, apply is idempotent per reward transaction, stage changes preserve, and new run clears.
  - Guard: UI and projectile code cannot mutate the level dictionary directly.
- [ ] **3.3 Add deterministic compatible offers.**
  - Accept: family quota, first-offer composition, source guarantees, max filtering, prerequisites, element exclusivity, and stable run/stage/source seeds pass repeated tests.
  - Guard: no offer has duplicates, three maxed choices, incompatible cores, or a dependent card without its core.
- [ ] **3.4 Implement primary/passive/mobility/dash/EMP modifiers.**
  - Accept: all 25 non-element upgrade rows produce their documented numeric or behavior change in the next encounter.
  - Guard: fire-rate/dash/passive/EMP floors and projectile caps cannot be bypassed by stacks or items.
- [ ] **3.5 Implement Burn, Poison, Slow, and their six mutations.**
  - Accept: tick rate, duration, stack/refresh, propagation, detonation, shatter, boss resistance, death cleanup, and structure interaction are deterministic.
  - Guard: status effects cannot recursively trigger themselves, spread without a source cap, permanently slow a boss, or continue after death.

Batch acceptance: a debug route can assemble and visibly demonstrate one fire, one poison, one cryo, one projectile-count, one passive, and one mobility build, while the live run enforces one element core.

Batch guard: base Pulse Cannon with zero upgrades can still defeat every required target and boss.

### Phase 4: Map reward cadence and expanded field items

Goal: make build decisions and temporary combat tools part of the authored map rather than deployment or random loot spray.

Source owners: `vehicle_stage_catalog.gd`, `vehicle_stage_one.gd`, `vehicle_upgrade_catalog.gd`, `vehicle_run_build.gd`, UI intent boundary, localization, validators.

- [ ] **4.1 Add calibration, field-boss, relay, and boss reward sources to every stage.**
  - Accept: source IDs/positions/unlock rules produce nine mandatory and up to three optional transactions across a full run.
  - Guard: only installations and the active boss gate movement; living ordinary enemies never gate a reward or transition.
- [ ] **4.2 Replace the deployment weapon choice and garage toggle.**
  - To-be: deployment is a one-action briefing; garage shows the current/latest build summary without changing a weapon type.
  - Accept: a fresh or old save always launches the neutral Pulse Cannon and the first map choice begins build identity.
  - Guard: locale/settings/persistent module fields remain compatible and old primary keys cause no error.
- [ ] **4.3 Implement all nine item families and authored placement.**
  - Accept: each stage has eight loose items, five crates, deterministic group reward rolls, and a guaranteed field-boss repair.
  - Guard: effects reset on stage/run boundaries as specified, never become permanent upgrades, and do not add ammo UI.

Batch acceptance: a complete three-stage route grants the exact reward cadence, optional cache behavior, and all item types without loot clutter or extermination locks.

Batch guard: minimap fog reveals reward anchors only by existing discovery rules and does not expose unexplored optional rewards.

### Phase 5: Deliberate upgrade selection UI and combat HUD

Goal: make every upgrade choice hard to trigger accidentally and easy to understand in Korean and English.

Source owners: new `vehicle_upgrade_choice_panel.gd`, `vehicle_stage_ui.gd`, vehicle Theme, localization, UI debug contract, validators.

- [ ] **5.1 Extract and implement the upgrade-choice component.**
  - Accept: 0.35 second guard, focus/selection separation, 1–3 selection, explicit confirmation, disabled pending state, receipt/error return, and optional decline work by mouse, keyboard, and gamepad.
  - Guard: one interaction cannot both select and apply; duplicate confirmation emits once.
- [ ] **5.2 Add current-to-next preview and compatibility copy.**
  - Accept: exact levels/values/triggers and selected element consequences fit all target viewports/locales.
  - Guard: UI reads catalog/build snapshots and contains no effect implementation or offer filtering.
- [ ] **5.3 Replace attack-energy HUD with opening-shot readiness.**
  - To-be: primary rail communicates `연사 중 / Firing`, partial capacitor, and `강공격 준비 / Opening ready`; it does not imply ammo or disabled normal fire.
  - Accept: a player can tell when the next first shot is full without reading instructional prose.
  - Guard: passive/dash/EMP/buff/target states remain visible and non-overlapping.

Batch acceptance: every reward source completes through a deliberate two-step choice, compact Korean/English layouts pass, and combat resumes exactly once with the applied receipt.

Batch guard: all interactive targets are at least 44 px, mandatory choices cannot close, and no unsupported inventory/economy control appears.

### Phase 6: Stored audio feedback

Goal: replace temporary synthesized beeps with stored, layered feedback for continuous fire, opening shots, dense impacts, rewards, and bosses.

Source owners: `tools/audio/generate_vehicle_sfx.py`, `art/audio/vehicle/sfx/*.wav`, `vehicle_audio_director.gd`, `vehicle_stage_one.gd`, settings/audio validation.

- [ ] **6.1 Generate and commit the thirteen locked WAV assets.**
  - Accept: files are deterministic, non-empty, mono PCM, normalized below clipping, and import in Godot without warnings.
  - Guard: no downloaded sample, external license, package, or generated cache is staged as source.
- [ ] **6.2 Add playback routing and retire runtime synthesis.**
  - Accept: held fire has clean start/loop/end, full readiness/fire are distinct, impacts use a two-voice limiter, and upgrade select/confirm are different cues.
  - Guard: Master/SFX settings still control all sounds; no Music bus or voice line is added.

Batch acceptance: a dense combat capture has no stuck loop, impact cacophony, missing stream, or audible clipping, and silence follows pause/result as intended.

Batch guard: deleting `_make_tone()` leaves no unresolved sound ID or null stream.

### Phase 7: Specifications, quality, production validation, and lifecycle completion

Goal: prove the complete loop and leave one truthful implementation contract.

Source owners: active product specs, validators, capture tooling, all task-owned code/assets, this plan.

- [ ] **7.1 Align active product and design contracts.**
  - Update `vehicle_content_expansion_spec.md` for continuous fire, compact groups, reward cadence, and the catalog contract.
  - Update `progression_upgrade_system_spec.md` so bounded stackable vehicle-run fundamentals and behavior mutations coexist without changing persistent Forge/mastery scope.
  - Accept: no active spec still requires three-second attack energy, Repeater/Scatter deployment, one cache per stage, or Boolean-only cards.
  - Guard: do not promote this run-local system into permanent progression or rewrite protected `AGENTS.md`.
- [ ] **7.2 Extend deterministic and full-route validation.**
  - Accept: primary, populations, formations, reachability, threat budget, caps, all upgrades, statuses, offers, items, UI, audio, stage preservation, run reset, settings, localization, and ordinary-enemy bypass pass.
  - Guard: never weaken an existing assertion to make the new behavior pass; replace only assertions whose accepted contract changed.
- [ ] **7.3 Run rendered UI/gameplay evidence.**
  - Capture deployment, dense Stage 1 approach, each elemental state, upgrade unselected/selected/confirmed states, optional decline, Stage 2 density, Stage 3 density, boss reward, result, and garage/build summary at 1280×720; capture Korean and English upgrade/combat at 960×540.
  - Accept: no clipping, unreadable tiny threat, hidden route, misleading collision, health-bar flood, accidental modal exit, or HUD overlap remains.
  - Guard: rendered evidence must come from the built/current implementation, not mockups or DOM-only inspection.
- [ ] **7.4 Run production and task-scoped quality gates.**
  - Use `$codebase-quality-auditor` after multi-file implementation; correct only safe task-scoped findings.
  - Run headless import, focused validators, Web export, canonical fastrun Codex-lane boot, staged-file audit, and `git diff --check`.
  - Accept: all gates pass and only task-owned source/assets/docs are committed.
  - Guard: pre-existing `.import` churn remains unstaged; no remote push occurs without a new request.
- [ ] **7.5 Complete lifecycle.**
  - Record final evidence and deviations that stay within locked tuning floors/caps, check every completed phase, set this plan to `done`, and commit the final scoped batch.
  - Guard: do not mark done if any catalog effect, required reward source, UI flow, audio ID, build, or regression gate remains incomplete.

Batch acceptance: the complete run is locally buildable and playable with the locked combat/progression loop, the active specs agree, and the plan contains truthful completion evidence.

Batch guard: no unrelated architecture rewrite, historical document deletion, save-data migration, dependency adoption, or remote operation is included.

## Test Plan

### Validation cadence

Inner-loop commands:

- `./tools/godot.ps1 --path . --headless --quit-after 2`
- `./tools/godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_primary_weapon.gd`
- `./tools/godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_upgrade_system.gd`
- `./tools/godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_one.gd`
- `./tools/godot.ps1 --path . --headless --script res://tools/validation/validate_pivot_settings.gd`
- `git diff --check`

Batch gates:

- Phase 1: focused primary test, 18-enemy formation contract, threat budget/cap stress, one rendered approach.
- Phase 2: exact stage counts, every formation/spawn/reachability check, all-stage scripted bypass route, three dense captures.
- Phase 3: 34-resource catalog check, every max/exclusion/offer/preview/apply/status test, six representative live builds.
- Phase 4: full three-stage reward transaction count, all items, old-save normalization, optional decline and mandatory progression.
- Phase 5: interaction/focus/fit/localization checks at 960×540, 1280×720, and 1920×1080 plus selected/unselected/pending/error captures.
- Phase 6: asset format/import/load checks and continuous-fire/impact-limiter playback route.
- Phase 7: all validators, complete captures, Web release export, built-app boot, quality audit, documentation lifecycle, staged-file audit.

Final gates:

- Full script/import checks: `./tools/godot.ps1 --path . --headless --quit-after 2` exits zero without parser/resource errors.
- Full tests: the primary, upgrade, stage, and settings validators exit zero and the stage validator prints its success token.
- Production build: `./tools/godot.ps1 --headless --path . --export-release Web build/web/index.html` exits zero with expected `.html`, `.js`, `.wasm`, and `.pck` artifacts.
- Production-style start: load `$npjt-port-guard`, use the registered `D:\npjt\cardborne-platformer` Codex lane, boot the built Web export, verify HTTP 200 and first playable screen, then stop only the task-owned preview process.
- Manual/rendered routes: the capture list in Phase 7.3 at locked viewports/locales.
- Data validation: all 34 definitions, nine item IDs, encounter group IDs, transaction IDs, and localization keys are unique and resolvable.
- Documentation/lifecycle: active specs match behavior, this plan's lifecycle is truthful, `git diff --check` passes, and no unrelated `.import` file is staged.

Rerun policy:

- Rerun a failed narrow check only after a concrete change or new hypothesis.
- Rerun full gates only after the suspected cause changed.
- Record known non-blocking Godot exit warnings rather than repeatedly rerunning unchanged commands.

## Predetermined Error Handling and Contingencies

| Trigger | Required response | Limit / escalation |
| --- | --- | --- |
| Formation position overlaps cover/reward/entry | Move the authored group anchor or deterministic formation offsets in catalog data and rerun all stage formation checks. Never random-relocate at runtime. | Escalate only if current cover geometry cannot hold the locked local cap without geometry changes. |
| Dense group exceeds readable pressure | Keep total population and small scale; reduce active rectangle overlap or attack-cost permission, not enemy count. | Escalate only if 12 visible small enemies remain unreadable after health/minimap cleanup. |
| Player/hostile projectile cap is reached | Apply the locked retirement/wait policy and record a counter in the debug snapshot. | Escalate if a telegraphed priority attack would need deletion. |
| Upgrade resource invalid/missing | Catalog load fails closed with exact ID/path; do not omit the card or substitute a different effect. | Stop the batch until all 34 definitions validate. |
| Apply becomes invalid after selection | Keep modal open, show localized reason, regenerate from the same deterministic source excluding invalid choices, and preserve the reward transaction. | Stop after one regeneration failure and fix source state. |
| Status propagation approaches cap | Contagion spreads once per death to targets within 100 px and never triggers from propagated DOT death a second time in the same chain. | Escalate only if capped propagation still causes simulation instability. |
| 960×540 upgrade modal clips | Reduce secondary prose and spacing through compact mode while preserving 44 px controls and the exact comparison. Do not add horizontal scroll. | Escalate if required controls cannot fit without removing an accepted field. |
| SFX generator output clips or loops click | Adjust generator envelope/loop zero crossing and regenerate all dependent files; do not normalize with a new external tool. | Stop after two evidence-backed parameter revisions and report the exact audio limitation. |
| Existing gameplay validator fails | Replace only assertions tied to intentionally retired attack-energy/weapon-choice contracts; fix every unrelated regression. | Escalate if the failure predates task-owned changes and blocks verification. |
| Godot creates unrelated `.import` churn | Leave it unstaged; stage only source imports required by newly added WAV/Resource files. | Never clean or revert user-owned churn. |
| Built preview requires a server | Use `$npjt-port-guard` and the canonical fastrun Codex lane; do not invent a port. | Stop if the manager cannot allocate/reuse the project lane and report the exact blocker. |

## Progress

- [ ] Phase 1: playable dense-combat vertical slice.
- [ ] Phase 2: complete all-stage enemy density and presentation.
- [ ] Phase 3: data-driven build, statuses, and 34-upgrade catalog.
- [ ] Phase 4: map reward cadence and expanded field items.
- [ ] Phase 5: deliberate upgrade selection UI and combat HUD.
- [ ] Phase 6: stored audio feedback.
- [ ] Phase 7: specifications, quality, production validation, and lifecycle completion.
- [ ] Final gates.

## Next Steps

1. Start with Phase 1 only and hand back a playable Flooded Works approach showing held fire, a one-second opening shot, and the compact swarm before broadening the data migration.
2. Complete enemy density, then the typed upgrade runtime/statuses, then reward placement and UI in the listed order so each batch remains playable.
3. Finish with stored audio, spec alignment, complete rendered evidence, production build/boot, quality audit, lifecycle update, and scoped commits.

## Completion Criteria

- [ ] Held primary continuously fires at the documented cadence and normal fire is never charge-gated.
- [ ] Exactly one full opening shot becomes ready after the documented 1.0 second idle and applies the documented health/stagger/structure/radius/pierce effects.
- [ ] Stages contain exactly 68/76/84 pre-boss enemies with compact scale, local caps, attack budget, and readable presentation.
- [ ] All 34 upgrades load from data, obey exact levels/prerequisites/exclusions/floors, preview accurately, apply once per transaction, persist across stages, and reset with the run.
- [ ] Burn, Poison, Slow, elemental exclusivity, passive upgrades, mobility, opening, dash, and EMP upgrades behave exactly as cataloged.
- [ ] Nine mandatory and up to three optional upgrade choices occur at the locked map/run beats without ordinary-enemy extermination gates.
- [ ] All nine field items, authored placements, crates, group reward policy, and no-loot-spray guard pass.
- [ ] No single click, number key, or carried input can accidentally apply or skip an upgrade; Korean and English layouts pass all viewports.
- [ ] Thirteen stored WAV files replace runtime synthesis with clean continuous-fire and limited impact playback.
- [ ] Active product specs describe the implemented behavior and do not retain conflicting attack-energy/class-choice/card constraints.
- [ ] All automated, rendered, build, production-style boot, quality, lifecycle, and staged-file gates pass.
- [ ] No retired owner, duplicate runtime path, unresolved material decision, placeholder, or unrelated staged change remains.

## Rollback / Safety

- Implement and commit by phase so each coherent batch can be reverted independently.
- No phase deletes or migrates persistent user data. Old primary-selection keys are tolerated and ignored.
- Reverting Phases 1–6 restores the prior deliberate-energy run; product specs are aligned only after the implementation they describe passes.
- Do not reset, clean, revert, stage, or commit the pre-existing `.import` changes.
- Do not add packages, change lockfiles, adopt external assets, push, force-push, or delete historical documents under this plan.

## Risks

- More bodies can improve firing feel while weakening target priority. The local cap, weighted attack budget, priority roles, health timing, and minimap grouping are mandatory mitigations rather than optional polish.
- Thirty-four upgrades are enough to create dead or incompatible offers if filtering is weak. Catalog validation and source-specific offer guarantees block implementation completion.
- Numeric upgrades can become invisible. Exact preview, capped stacks, and guaranteed behavior changes at relay/elite/boss sources prevent a run from becoming only percentage accumulation.
- One-second opening charge can reward repetitive tapping. The 0.25 second no-bonus window and the larger structure/stagger specialization make full pauses purposeful rather than constant.
- The current 3,470-line stage runtime is already broad. New definitions, status, encounter, UI, and audio responsibilities must leave that file rather than expanding new catch-all sections.
- Generated SFX can remain stylized rather than realistic. This milestone requires clear, non-fatiguing functional feedback, not final music or voice production.

## Open Questions

No material product or technical question remains for this implementation. Changes to the locked enemy counts, one-second charge, 34-card catalog, elemental exclusivity, reward cadence, permanent progression, external assets, BGM/voice, map geometry, or additional stages require owner change control and an updated plan before implementation.

## Decision Notes

- 2026-07-21: owner explicitly restored held continuous primary fire and reduced the strong-opening interval from three seconds to about one second; this plan locks it to exactly 1.0 second.
- 2026-07-21: owner requested enemies be substantially smaller and more numerous; this plan separates total population, local activation, and attack pressure instead of treating raw count as difficulty.
- 2026-07-21: owner rejected a preselected character/weapon type in favor of map upgrades; this plan retires the active Repeater/Scatter choice and starts from one neutral cannon.
- 2026-07-21: bounded numeric upgrades are accepted as foundation cards, while source guarantees preserve visible behavior changes and one elemental identity.
- 2026-07-21: stored project-owned SFX are included because the repository contains no audio files; speech and music remain separate production decisions.

## Stop Conditions

Complete when:

- all seven phases, completion criteria, and final gates are checked; exact evidence is recorded; active specs agree; this plan is `done`; and task-owned work is committed locally.

Escalate only when:

- completion requires changing locked product values, cover/world geometry, persistent save data, external dependencies/assets, voice/music scope, destructive Git, remote push, or protected instructions.

Do not stop when:

- a task-scoped refactor, formation correction, balance implementation within locked floors/caps, localization fit fix, SFX regeneration, capture workaround, validation correction, or safe quality finding remains.

## Handoff

```text
Goal: Replace sparse deliberate-energy combat with a high-density manually aimed vehicle run driven by held fire, a one-second opening shot, and map-acquired upgrades.

Read first: AGENTS.md, .agent/AGENTS.md, .agent/PLANS.md, this plan, docs/product/vehicle_content_expansion_spec.md, docs/product/progression_upgrade_system_spec.md.

Execute exactly: phases 1 through 7 in order, preserving current map geometry, bosses, Korean default, cover collision, run transition, and settings while retiring attack energy and pre-run weapon choice.

Validate with: focused primary/upgrade validators, the extended vehicle-stage/settings validators, locked rendered captures, Web release export, canonical fastrun built boot, quality audit, lifecycle review, git diff check, and staged-file audit.

Stop when: every completion criterion passes, the active specs match, this plan is done, and only task-owned changes are committed locally.
```
