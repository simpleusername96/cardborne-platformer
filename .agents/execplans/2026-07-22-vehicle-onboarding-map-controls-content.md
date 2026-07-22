---
type: plan
status: active
owner: BK
created: 2026-07-22
scope: Vehicle-run onboarding cadence, authored map readability, input rebinding, enemy and upgrade expansion, and two additional stages
source: Owner feedback in the current Codex thread and verified current repository state
related:
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
---

# Vehicle Onboarding, Map, Controls, and Content Expansion - Execution Plan

This plan turns the current three-stage vehicle game into a five-stage authored
run with a readable central Stage 1 start, delayed and sequential enemy entry,
cohesive 3–5-unit squads, remappable combat controls, four additional enemy
roles, and twelve additional upgrades. Work is divided into seven executable
phases, each ending in a user-visible or independently verifiable result.

## Purpose

- **Objective:** preserve manual aiming, held primary fire, dash positioning,
  passive seekers, EMP, map rewards, and card builds while making the first
  minutes readable and expanding the game through authored content.
- **Final artifact:** a five-stage Godot vehicle run whose default first-clear
  pacing starts safely, escalates by encounter beat, and exposes keyboard/mouse
  combat rebinding from every pre-combat or pause settings surface.
- **Completion state:** all five stages are traversable and distinct; Stage 1
  starts at the map center; enemy packets enter one unit at a time after a
  six-second arrival grace; the catalog contains 19 enemy archetypes and 46
  upgrades; current validators, new pacing/layout/input validators, rendered
  captures, performance profiling, and Web export pass.

## Why and Context

The current combat core is worth preserving, but the first encounter does not
provide a safe read. The current player start lies inside the activation area of
a 27-unit swarm, and moving slightly can activate enough neighboring enemies to
approach the 48-unit Stage 1 cap. This asks the player to learn movement, aim,
held fire, dash, target priority, and EMP while a dense mixed-role fight is
already active.

The map has a second structural problem: floor regions define presentation, but
movement collision is primarily constrained by cover rectangles and world
bounds. A cobalt area can therefore look non-walkable without being the shared
navigation truth. The long left-to-right Stage 1 layout also starts the player
near the western edge instead of in a legible central safe plaza.

Controls compound the onboarding cost. `Shift` currently duplicates primary
fire, `Z` triggers EMP, action-rail labels are hard-coded, and the settings store
persists only audio and language. The owner has now selected Left Shift as the
default EMP input and requested rebinding.

The earlier difficulty benchmark reached the same relevant conclusions: keep
the direct combat identity, remove deployment-zone activation, replace broad
activation rectangles with authored gateways, escalate a few enemy languages at
a time, and coordinate density as squads rather than many independent threats.
Those conclusions were rechecked against the current post-cleanup source before
this plan was written; the historical report is not restored as active project
documentation.

## Pre-plan Evidence Already Verified

| Source or path | Verified fact | Decision affected | Freshness or recheck boundary |
| --- | --- | --- | --- |
| `docs/product/vehicle_game_spec.md` | Manual target priority, held fire, one-second opening shot, dash, passive support, one active skill, authored fields, and non-extermination progression are current product contracts. | Preserve the combat identity and use authored encounter packets instead of endless global waves. | Recheck if the active product specification changes. |
| `docs/design/UI_VISUAL_SYSTEM.md` | Walkable ivory, blocked ceramic green, and cobalt void/water are mandatory semantic roles; rendering and collision must agree. | Build walkability and blockers from the same stage definition and preserve the flat-color language. | Recheck if the visual specification changes. |
| `scripts/vehicle/vehicle_stage_catalog.gd` | All stages share a `5200x2200` world, `PLAYER_START = (330,1100)`, global landmarks, broad floor rectangles, and 27–31-unit swarm groups. | Replace global geometry constants with per-stage definitions; put Stage 1 start at the exact center; retire static mass swarms. | Recheck immediately before editing because this is the main data owner. |
| `scripts/encounters/vehicle_encounter_director.gd` | Current target counts are 204/228/252 and active caps are 48/54/60; group activation rectangles are `1240x860`. | Add beat-aware packet pacing and squad coordination; retain threat tokens but stop using broad rectangles as the activation source. | Recheck immediately before editing. |
| `scripts/vehicle/vehicle_run.gd` | Reset instantiates the complete enemy blueprint; the first group is activated by area overlap; fixed roles begin active; progression uses world-X thresholds. | Extract encounter timing, spawn queues, and beat state from the shared runtime; replace coordinate thresholds with authored events. | Recheck immediately before editing. |
| `scripts/main/game_root.gd` | Primary fire is Mouse 1 plus Shift; dash is Space; EMP is Z; every boot overwrites `InputMap`. | Mouse 1 becomes the sole keyboard/mouse primary default, Space remains dash, and Left Shift becomes EMP. Persisted overrides must be applied after defaults. | Recheck immediately before editing. |
| `scripts/autoload/settings_store.gd` and `tools/validation/validate_settings_store.gd` | Only audio and locale values are persisted and malformed values fall back safely. | Extend the existing store with validated control descriptors and a combat-pressure preset without moving persistence into UI code. | Recheck immediately before editing. |
| `scripts/ui/vehicle_stage_ui.gd` | Pause and garage duplicate audio/language controls; HUD binding labels are literal `SHIFT / LMB`, `SPACE`, and `Z`. | Add one reusable settings panel and derive action labels from the live input profile. | Recheck immediately before editing. |
| `scripts/enemies/vehicle_enemy_archetypes.gd` | The current catalog contains 15 archetypes, including three swarm roles, six standard/support roles, installations, and bosses. | Add exactly four roles with one readable behavior each. | Recheck when Phase 5 starts. |
| `scripts/cards/vehicle_upgrade_catalog.gd` and `data/cards/vehicle/` | The current catalog contains 34 validated upgrades across existing families. | Add twelve upgrades inside existing families; do not add another family or UI category. | Recheck when Phase 5 starts. |
| Git evidence at commit `f7a8127` | The prior benchmark identified deployment overlap, compound difficulty, map/director drift, independent crowd noise, and a first-clear active-cap ramp of 12–24 as the high-confidence problems. | Set a safe arrival, authored gateways, squad-level escalation, Standard pressure, and explicit acceptance telemetry. | Evidence is advisory; current source and owner feedback override it. |

## Locked Decisions

| Topic | Final decision | Rationale / source |
| --- | --- | --- |
| First enemy timing | Gameplay begins with exactly 6.0 seconds of arrival grace. A large 0.9-second gate pulse begins at 5.1 seconds and the first single scout becomes active at 6.0 seconds. No enemy may damage the player during grace. | Falls inside the owner's 5–10-second preference while remaining short enough to preserve momentum. |
| Spawn presentation | Mobile enemies are not instantiated as a full dormant population. An authored packet queues them and emits at most one enemy per spawn tick from a marked anchor. | Prevents simultaneous popping and avoids processing/drawing unused enemies. |
| Squad escalation | Beat 0 uses one scout. Beat 1 uses 3-unit squads at 0.80-second unit spacing. Beat 2 uses 4-unit squads at 0.65 seconds. Beats 3–4 use 5-unit squads at 0.50 seconds. Minimum gaps between squad starts are 8.0, 6.0, and 4.5 seconds respectively. | Directly implements one-at-a-time emergence and increasingly frequent/larger groups. |
| Squad behavior | A squad shares an ID, leader, formation slots, leash, and target sector. Non-committed movement blends 70% role movement with 30% cohesion steering and stays within 220 pixels of the squad centroid. Startup and active attacks are never bent by formation steering. | Makes 3–5 enemies read as one pressure unit without overriding individual attack tells. |
| Standard pressure | Standard is the default. Beat active-mobile caps are `1 → 12 → 16 → 20 → 24`; threat budgets are `1.0 → 2.5 → 3.5 → 4.0 → 5.0`; ranged and denial commits remain at most 2 and 1 until Beat 4. | Preserves challenge while teaching one relationship at a time. |
| Onslaught pressure | Onslaught is an optional settings value. It keeps the same six-second grace and one-at-a-time presentation, raises active-mobile caps to `1 → 16 → 24 → 32 → 40`, and uses the existing 6.5 threat budget from Beat 2 onward. | Preserves the high-pressure identity for repeat play without making it the onboarding default. |
| Population bands | Standard pre-boss authored populations are Stage 1 `112–128`, Stage 2 `128–148`, Stage 3 `144–164`, Stage 4 `152–176`, and Stage 5 `160–184`. Validators enforce the bands; active pressure, not raw total count, controls difficulty. | Retains large encounters while removing 27–31-unit simultaneous group activation. |
| Stage 1 map | Stage 1 uses a `4400x2800` world and starts exactly at `(2200,1400)` in a `720x720` central safe plaza with no blocker or hazard within 360 pixels. The critical rhythm is west learning loop → central calibration reward → visible north/south generator fork → east relay and boss. The optional field-boss branch is northwest and has an independent leash. | Creates a legible central respawn and turns the map into a readable route choice instead of a long strip. |
| Later-stage starts | Stages 2–5 each own an authored safe entry plaza. Only Stage 1 is required to use the mathematical center; every stage must provide 360 pixels of clear space and a visible critical landmark. | Preserves stage-specific composition while keeping every transition safe. |
| Walkability truth | Each stage defines `walkable_regions`, `cover_rects`, and `hazard_regions`. Player/enemy movement must remain inside walkable regions and outside cover; the backdrop draws those exact shapes. Projectiles and line of sight continue to use cover, with stage-specific reflector rules only in Stage 5. | Eliminates disagreement between visual floor and movement collision. |
| Visual separation | Walkable surfaces remain uninterrupted ivory. Blockers use ceramic-green tops, a deep-cobalt bottom-right elevation side, and a minimum 18-pixel contact shadow. Cobalt water/void never receives walkable motifs. No outlines or fine textures are added. | Strengthens value/elevation cues without violating the accepted flat-color style. |
| Default controls | Primary fire: Mouse 1. Dash: Space. EMP: Left Shift. Z has no default binding. Existing gamepad defaults remain unchanged. | Implements the owner's selected EMP default and removes Shift's conflicting primary-fire role. |
| Remappable controls | The settings UI remaps keyboard/mouse bindings for `primary_fire`, `dash`, and `active_skill`. Movement keeps both WASD and arrows; pause remains Escape; gamepad rebinding is outside this plan. | Satisfies the requested remap with a bounded, testable first control surface. |
| Binding conflicts | A duplicate keyboard/mouse binding is rejected with localized conflict copy; the prior binding remains. Escape cancels capture. Reset restores all three defaults. | Avoids hidden swaps and prevents unreachable actions. |
| Settings access | One reusable settings panel is reachable from deployment, pause, and garage. It contains Audio, Controls, Gameplay, and Language pages and fits inside a `ScrollContainer` at 960x540. | Lets a player change EMP before the first combat and removes duplicated settings construction. |
| Stage-data ownership | `vehicle_stage_catalog.gd` becomes a facade over one definition file per stage. Each definition owns world geometry, start, landmarks, packets, objectives, pickups, and environment data. | Five stages and distinct maps should not expand one catch-all catalog. |
| Encounter ownership | A new deterministic `vehicle_encounter_runtime.gd` owns grace, packet queues, spawn timing, beat caps, and debug metrics. `vehicle_encounter_director.gd` owns squad formation and attack-token rules. `vehicle_run.gd` only consumes spawn requests and runs combat instances. | Keeps orchestration out of the already large shared runtime. |
| New enemy roles | Add Rammer, Repair Tender, Drone Carrier, and Beam Sentinel. Each has one primary counter and no hidden immunity. | Adds target-priority and movement decisions without redundant variants. |
| New upgrades | Add exactly twelve cards within current families: Burst Capacitor, Relay Rounds, Shock Breach, Reserve Charge, Marked Salvo, Guardian Seeker, Phase Shear, Coolant Wake, Static Aegis, Relay Overload, Emergency Vector, and Salvage Booster. | Expands builds without creating another family or menu taxonomy. |
| Added stages | Add Stage 4 **Coral Switchyard** and Stage 5 **Abyssal Observatory** with the contracts below. | Two stages make “more stages” concrete and keep the milestone bounded. |
| Assets | Use the current procedural flat-color rendering and font/audio set. No external dependency or asset pack is added. | Current readability work is a geometry/presentation problem, not an asset acquisition problem. |

## Added Content Contracts

### New enemy roles

| ID | Visible behavior | Counter | Limits |
| --- | --- | --- | --- |
| `rammer` | Shows a 0.9-second coral lane, commits to a straight charge, and enters 1.2 seconds of vulnerability after hitting solid cover or ending the lane. | Sidestep/dash, then punish the recovery. | At most one committed rammer per squad and two in the active field. |
| `repair_tender` | Maintains one thick mint link and repairs one damaged ordinary ally or installation for 4 hull/second within 360 pixels. | Break line of sight, separate it, or prioritize it. | Never repairs itself, field bosses, stage bosses, or more than one target. |
| `drone_carrier` | Telegraphs a bay opening, then releases one 3-unit drone squad at 0.65-second spacing before an 8-second recovery. | Destroy or interrupt it before the squad finishes. | Maximum six living children per carrier; death cancels queued children. |
| `beam_sentinel` | Fixed installation paints one wide lane for 1.2 seconds, fires a 0.6-second cover-blocked beam, then recovers for 2.4 seconds. | Read the lane and use cover or a flank. | One active beam per local packet; never fires through cover. |

### New upgrade cards

| ID | Family | Locked effect |
| --- | --- | --- |
| `burst_capacitor` | primary | Every eighth held-fire round becomes a tight three-round burst at 70% damage per projectile. |
| `relay_rounds` | primary | A projectile that ricochets or passes through an Observatory reflector gains 35% damage and 20 structure damage for that flight. |
| `shock_breach` | opening | A fully charged opening hit emits a 90-pixel shock burst for 45% of opening damage; maximum two levels. |
| `reserve_charge` | opening | Completing a dash advances opening-shot recharge by 0.35 seconds; maximum two levels. |
| `marked_salvo` | passive | Primary hits mark one target for 2.5 seconds; seekers prioritize it and deal 25% more damage. |
| `guardian_seeker` | passive | Every third seeker intercepts one hostile projectile before seeking a target. |
| `phase_shear` | dash | Passing through an enemy marks it for 20% increased incoming damage for 3 seconds; one mark at a time. |
| `coolant_wake` | dash | Dash leaves a 2-second mint wake; firing while inside it is 15% faster. |
| `static_aegis` | skill | Each hostile projectile cleared by EMP grants 1 barrier, capped at 18 barrier per cast; maximum two levels raise the cap to 24. |
| `relay_overload` | skill | EMP disables ordinary supports and installations for 2.5 additional seconds; maximum two levels. |
| `emergency_vector` | mobility | Once per encounter, dropping below 30% hull resets dash cooldown and grants 0.4 seconds of invulnerability. |
| `salvage_booster` | mobility | Collecting a map pickup grants 15% movement speed for 4 seconds; maximum two levels raise it to 22%. |

### Stage 4: Coral Switchyard / 산호 분기장

- **Spatial verb:** three large switch pads rotate ceramic gate blocks between two
  painted positions. A switch opens one flank and closes the other, but every
  state leaves one 480-pixel route and can never trap the player.
- **Start:** central maintenance court with 360 pixels of clear space and the
  first switch visible.
- **Threat relationship:** Rammer lanes are dangerous in the open route while a
  Repair Tender sustains the installation controlling the safer flank.
- **Optional branch:** intercept a repair convoy before it reaches a side dock;
  failure closes only the bonus cache, never critical progress.
- **Field boss:** Salvage Convoy, a repair tender escorted by two alternating
  rammers; the player may retreat through the entry gate.
- **Stage boss:** Switchyard Behemoth. Its charge follows the currently open gate
  lane, crashes into cover, and exposes a recovery core. No unrelated projectile
  phase is introduced.

### Stage 5: Abyssal Observatory / 심연 관측소

- **Spatial verb:** two large reflector plates rotate between cardinal angles at
  player-operated consoles. Reflected player and hostile projectiles follow a
  large visible 90-degree path; all other cover behavior remains unchanged.
- **Start:** sheltered observation court with both reflector states visible on a
  large floor diagram.
- **Threat relationship:** Drone Carriers build pressure behind cover while Beam
  Sentinels force the player to rotate reflectors or take a flank.
- **Optional branch:** align both reflectors to open the Mirror Warden vault; the
  branch has a dedicated return route and leash.
- **Field boss:** Mirror Warden, a mobile carrier protected by one beam sentinel.
- **Stage boss:** Crown Engine. The player uses the learned reflectors to break
  two shield relays, then attacks during explicit recovery. Carrier reinforcements
  are capped at one 3-unit squad and stop during beam patterns.

## Rejected Alternatives

| Alternative | Why it was viable | Why it was rejected |
| --- | --- | --- |
| Global timed waves | Simple to implement and easy to scale numerically. | Breaks the authored continuous-map identity and can trigger combat unrelated to player location or route choice. |
| Instantiate every mobile enemy at reset and reveal them later | Reuses the current runtime with fewer source changes. | Retains mass dormant state, complicates sequential presentation, and keeps activation bugs tied to oversized rectangles. |
| Keep 27–31-unit swarm groups and only lower damage | Preserves current population data. | Does not solve simultaneous visual decisions, first-contact overload, or map/director drift. |
| Keep Shift on primary fire and add Shift to EMP | Preserves an old fallback. | One input would trigger two combat actions and violate the owner's selected default. |
| Add full movement, pause, and gamepad rebinding now | Produces a comprehensive controls menu. | Expands focus navigation, axis capture, and conflict policy beyond the requested EMP/attack/dash problem. |
| Add more upgrade families | Makes the catalog look broader. | Creates more comprehension and UI taxonomy before current families are fully exploited. |
| Add external map or enemy assets | Could change appearance quickly. | Does not solve collision truth, route composition, activation timing, or control usability. |

## Current State

Already true or landed:

- The game is a Godot 4.7 top-down vehicle shooter with three connected stages.
- Manual aim, held primary fire, one-second opening shot, dash, passive seekers,
  EMP, map pickups, card choices, optional field bosses, and stage bosses exist.
- Enemy attack tokens, projectile/cover collision, health bars, minimap fog,
  off-screen threat arcs, Korean/English UI, audio settings, and Web export have
  automated coverage.
- The active art specification already defines strong semantic colors and large
  flat shapes suitable for the map readability correction.

Remaining implementation:

- Current Stage 1 start overlaps first-contact activation and sits near the map edge.
- Mobile populations are authored as oversized static swarms rather than queued squads.
- Floor presentation is not the full movement boundary contract.
- Stage geometry and landmarks are global rather than stage-owned.
- Progression depends on world-X thresholds.
- EMP uses Z, Shift duplicates primary fire, and binding labels/settings are static.
- Existing Stage 2/3 layouts reuse too much macro structure.
- The run has three stages, 15 enemy archetypes, and 34 upgrade cards.

## Scope

In scope:

- the Stage 1 central map rewrite and per-stage geometry schema;
- sequential encounter packets, squad cohesion, Standard and Onslaught pressure;
- Shift-default EMP and keyboard/mouse remapping for primary, dash, and EMP;
- one shared settings panel and live HUD binding labels;
- migration and readability correction of Stages 2 and 3;
- four enemy roles, twelve upgrades, Coral Switchyard, and Abyssal Observatory;
- Korean/English copy, deterministic validation, rendered evidence, profiling,
  native boot, and Web export;
- incorporation of accepted behavior into the current product/visual specs and
  deletion of this plan after all work is complete.

Out of scope:

- procedural maps or endless survival spawning;
- another player vehicle or primary weapon;
- a walkable base, equipment repair economy, or persistent grind redesign;
- full movement/gamepad input rebinding;
- external asset packs, engine changes, or production dependencies;
- hidden dynamic difficulty or mandatory enemy extermination;
- exploration puzzles beyond the locked switch and reflector stage verbs.

Destructive or irreversible actions:

- Remove `_swarm_groups()` and the old global geometry constants only after all
  three current stages load from their new definition files and parity tests pass.
- Replace coordinate-threshold progression only after event-based progression
  reaches every existing reward and boss transition in validation.
- Delete this ExecPlan only after its durable decisions are incorporated into
  the active specifications and every completion gate passes.

Exact actions requiring owner/user approval:

- None for local implementation, tests, captures, build, and a scoped commit.
- Remote push, release publication, new dependencies, or expansion beyond the
  five locked stages requires a separate explicit request.

## Assumptions

No material assumptions remain. The owner's `5–10 seconds` preference is locked
to 6.0 seconds; `3–5 enemies` is locked to the beat progression above; “center”
means the exact center of the Stage 1 world. A change to those values is product
change control, not an implementation-local choice.

## Proposed Design and Ownership

| Concern | Final owner | Interface or invariant | Existing owner to reuse or retire |
| --- | --- | --- | --- |
| Default and saved input descriptors | New `scripts/input/vehicle_input_profile.gd` | Allowlisted descriptors for three actions; keyboard/mouse events only; gamepad defaults appended separately. | Reuse `game_root.gd` for `InputMap`; retire literal binding arrays from it. |
| Settings persistence | `scripts/autoload/settings_store.gd` | Persist `[controls]` descriptors and `[gameplay] combat_preset`; malformed per-action values restore only that action's default. | Reuse current ConfigFile and save path. |
| Settings UI | New `scripts/ui/vehicle_settings_panel.gd` | One component embedded by deployment, pause, and garage; event capture blocks carried gameplay input. | Retire duplicated settings construction in `vehicle_stage_ui.gd`. |
| Stage definitions | New `scripts/vehicle/stages/*.gd` | One `definition()` dictionary per stage with world, walkability, cover, hazards, landmarks, packets, objectives, and environment. | `vehicle_stage_catalog.gd` remains the validated facade; retire global geometry constants. |
| Walkability and collision | `scripts/vehicle/vehicle_stage_rules.gd` | `move_circle`, reachability, spawn validation, and rendering consume the same stage definition. | Extend current collision helpers; do not duplicate shapes in UI. |
| Static presentation | `scripts/vehicle/vehicle_stage_backdrop.gd` and `vehicle_stage_visual_profile.gd` | Draw exact walkability/cover/hazard data with the locked semantic roles and elevation treatment. | Reuse cached drawing and current palette. |
| Packet lifecycle | New `scripts/encounters/vehicle_encounter_runtime.gd` | Deterministic grace, gateway activation, spawn queue, beat cap, squad timing, and debug snapshot; returns spawn requests only. | Retire direct blueprint mass instantiation from `_reset_run()`. |
| Formation and commits | `scripts/encounters/vehicle_encounter_director.gd` | Squad slots/cohesion plus existing attack-cost, ranged, and denial limits. | Replace broad activation-rectangle expansion. |
| Enemy instances | `scripts/enemies/vehicle_enemy_archetypes.gd` and focused behavior helpers under `scripts/enemies/` | One role behavior per new archetype; every damage action has startup, active, and recovery. | `vehicle_run.gd` orchestrates instances but does not define content tables. |
| Boss patterns | New `scripts/bosses/vehicle_boss_patterns.gd` | Stage-selected pattern data and timers; every damaging pattern has startup, active, recovery, and a debug contract. | Extract stage-specific branches from the shared run before adding two bosses. |
| Upgrade data/effects | `data/cards/vehicle/`, `vehicle_upgrade_catalog.gd`, `vehicle_run_build.gd`, and relevant combat owners | 46 validated definitions; three-choice offers; existing compatibility/exclusion rules. | No card behavior in UI. |
| Localization and HUD | `localization/vehicle_stage.csv` and `scripts/ui/vehicle_stage_ui.gd` | Korean/English parity; binding labels derive from the live profile. | Retire hard-coded `SHIFT / LMB`, `SPACE`, `Z`, and static control sentence. |

## As-Is / To-Be Delta Map

| Concern | As-is | To-be | Acceptance check | Guard / leftover check |
| --- | --- | --- | --- | --- |
| Deployment | First swarm area overlaps start. | Six seconds safe, then one scout with a 0.9-second gate cue. | Simulated first 6 seconds contain zero active damaging enemies and one spawn at 6.0 seconds. | Search finds no start-overlapping activation rectangle. |
| Group entry | 27–31 members can activate together. | One unit per tick; squads progress 1/3/4/5 by authored beat. | Spawn timeline matches locked intervals and never emits two units on one tick. | `_swarm_groups` and mass-expansion calls are absent. |
| Group motion | Individuals independently steer and clump. | Squad identity, slots, centroid cohesion, shared leash and sector. | A debug simulation keeps 95% of non-committed squad members within 220 pixels of centroid. | Committed attacks remain unchanged by cohesion. |
| Stage 1 start | `(330,1100)` near west boundary. | `(2200,1400)` at exact center of `4400x2800`, with 360-pixel clearance. | Geometry validator asserts center equality, clearance, and route reachability. | No runtime fallback to a global start. |
| Map semantics | Floor rendering and movement truth can differ. | Walkable regions, cover, and hazards share one stage definition. | Every route point is walkable; every cover sample blocks; outside-floor movement is rejected. | No second visual-only floor list. |
| Progression | X-coordinate thresholds open rewards. | Authored packet/objective completion events open rewards. | Debug full-run reaches each reward and boss regardless of route order. | Search finds no progression check based only on player X. |
| EMP input | Z; Shift also fires primary. | Shift; primary is Mouse 1; Z unbound. | Input validator and in-game HUD agree. | No literal old control copy remains. |
| Settings | Audio/language only, duplicated UI. | Shared Audio/Controls/Gameplay/Language component with persistence. | Change, reload, reset, conflict, locale, focus, and 960x540 layout tests pass. | Pause/garage contain no duplicate slider construction. |
| Content | 3 stages, 15 archetypes, 34 cards. | 5 stages, 19 archetypes, 46 cards. | Catalog validators assert exact IDs/counts and all localization keys. | No orphan content file or unregistered ID. |

## Tasks

### Phase 1: Remappable combat controls and shared settings

Goal: make Left Shift EMP work immediately and let the player change combat
bindings before entering combat.

Source owners touched: `scripts/input/vehicle_input_profile.gd`,
`scripts/main/game_root.gd`, `scripts/autoload/settings_store.gd`,
`scripts/ui/vehicle_settings_panel.gd`, `scripts/ui/vehicle_stage_ui.gd`,
`localization/vehicle_stage.csv`, `tools/validation/validate_settings_store.gd`,
`tools/validation/validate_vehicle_input_bindings.gd`

- [x] **1.1 Define the input profile and apply order.**
  - As-is: `game_root.gd` replaces every action with literal defaults.
  - To-be: create allowlisted event descriptors, register defaults, load saved
    overrides, and append unchanged gamepad defaults.
  - Accept: Mouse 1 fires, Space dashes, Left Shift triggers EMP, and Z triggers
    nothing in a fresh profile.
  - Guard: movement, Escape, and gamepad controls retain their current events.
- [x] **1.2 Persist validated control and gameplay settings.**
  - As-is: SettingsStore persists audio and locale only.
  - To-be: add `[controls]` descriptors, `combat_preset`, change signals, per-key
    malformed fallback, reset defaults, and atomic save through the current file.
  - Accept: all three bindings and Standard/Onslaught survive reload; one corrupt
    descriptor restores only its action.
  - Guard: existing audio/locale persistence and Korean default remain intact.
- [x] **1.3 Build the reusable settings panel.**
  - As-is: pause and garage build duplicate sliders and language rows.
  - To-be: one scroll-safe panel with Audio, Controls, Gameplay, and Language
    pages; deployment opens it before launch; key capture shows cancel/conflict/reset.
  - Accept: keyboard, mouse, and focus navigation reach every control at 960x540;
    gameplay input is blocked while capture is active.
  - Guard: modal dismissal cannot carry a fire, dash, or EMP event into gameplay.
- [x] **1.4 Derive all input copy from live bindings.**
  - As-is: action rail and deployment copy contain literal old keys.
  - To-be: format labels from `VehicleInputProfile` and use localized control
    templates rather than localized key names.
  - Accept: rebinding EMP updates deployment help and the HUD without restarting.
  - Guard: Korean and English expose identical actions and reset behavior.

Batch acceptance: a fresh run uses Shift EMP, a remapped EMP survives restart,
and every settings surface displays the live binding.

Batch guard: primary held fire, opening-shot charge, dash, gamepad actions,
audio, locale, modal focus, and supported viewport layouts still pass.

### Phase 2: Per-stage geometry and central Stage 1 map

Goal: make walkable space unambiguous and place Stage 1 respawn at the center of
an authored route rather than the edge of a shared strip.

Source owners touched: `scripts/vehicle/stages/flooded_works.gd`,
`scripts/vehicle/stages/tidal_archive.gd`,
`scripts/vehicle/stages/storm_drydock.gd`,
`scripts/vehicle/vehicle_stage_catalog.gd`,
`scripts/vehicle/vehicle_stage_rules.gd`,
`scripts/vehicle/vehicle_stage_backdrop.gd`,
`scripts/vehicle/vehicle_stage_visual_profile.gd`,
`scripts/vehicle/vehicle_run.gd`,
`tools/validation/validate_vehicle_stage_layouts.gd`

- [ ] **2.1 Split current stage definitions behind the catalog facade.**
  - As-is: world/start/landmark geometry is global and layout data is centralized.
  - To-be: create one current-stage definition per file and a schema validator;
    keep public catalog lookups stage-aware.
  - Accept: all three existing IDs load and expose every required field.
  - Guard: no caller receives a default stage silently for a registered bad ID.
- [ ] **2.2 Author the locked central Flooded Works layout.**
  - As-is: long `5200x2200` west-to-east strip and west-edge start.
  - To-be: `4400x2800`, center start and plaza, west learning loop, central
    reward return, north/south generator fork, northwest optional branch, east boss.
  - Accept: start, critical path, both generators, reward, field boss, boss gate,
    boss center, retreat loop, and return shortcuts pass reachability.
  - Guard: no blocker/hazard/spawn lies inside the 360-pixel start clearance.
- [ ] **2.3 Make walkability shared simulation truth.**
  - As-is: visual floor regions do not fully constrain actors.
  - To-be: update movement and grid reachability to require a circle to remain
    in walkable regions and outside cover; draw those exact regions.
  - Accept: test probes cannot move into cobalt void/water or ceramic cover and
    can traverse every critical lane with the player radius plus dash clearance.
  - Guard: cover still blocks both teams' ordinary projectiles and line of sight.
- [ ] **2.4 Strengthen floor/blocker presentation.**
  - As-is: semantic colors exist, but map composition and collision boundaries
    do not consistently expose elevation and traversability.
  - To-be: uninterrupted ivory floor, ceramic-green top, cobalt side/shadow,
    minimum 18-pixel contact shadow, and motifs clipped to walkable regions.
  - Accept: 960x540 and 1280x720 captures allow a reviewer to trace the critical
    path and identify every blocker without collision-debug overlays.
  - Guard: no outline, microtexture, speckling, or new semantic color is added.
- [ ] **2.5 Replace coordinate-threshold progression with authored events.**
  - As-is: calibration and discovery use player X thresholds.
  - To-be: encounter/interaction completion IDs drive reward, landmark discovery,
    generator completion, relay access, and boss gate state.
  - Accept: upper-first and lower-first route simulations both finish the stage.
  - Guard: ordinary enemy survivors never block a completed critical objective.

Batch acceptance: Stage 1 restarts at the exact center, displays a visually
obvious safe plaza and route fork, and completes through either generator order.

Batch guard: Stage 2/3 continue to load through migrated definitions while their
full map correction waits for Phase 4.

### Phase 3: Sequential encounter packets and cohesive squads

Goal: replace immediate mass activation with the locked six-second grace and
one-at-a-time 1/3/4/5-unit squad escalation.

Source owners touched: `scripts/encounters/vehicle_encounter_runtime.gd`,
`scripts/encounters/vehicle_encounter_director.gd`,
`scripts/vehicle/stages/flooded_works.gd`,
`scripts/vehicle/vehicle_run.gd`,
`scripts/enemies/vehicle_enemy_archetypes.gd`,
`scripts/ui/vehicle_stage_ui.gd`,
`tools/validation/validate_vehicle_encounter_pacing.gd`,
`tools/validation/profile_vehicle_pressure.gd`

- [ ] **3.1 Implement deterministic packet state outside VehicleRun.**
  - As-is: reset builds every enemy and activation happens per enemy.
  - To-be: encounter runtime owns arrival grace, gateway unlocks, packet queues,
    unit/squad intervals, active caps, and debug snapshots; it returns spawn specs.
  - Accept: fixed-step simulation reproduces an identical timeline for a seed and
    never emits more than one unit on a spawn tick.
  - Guard: encounter runtime owns no drawing, damage, UI, or enemy attack logic.
- [ ] **3.2 Author the Stage 1 six-beat packet curriculum.**
  - As-is: six threat languages can appear before the first upgrade.
  - To-be: one scout after grace; 3-unit single-language squads; 4-unit mixed
    squads and early calibration reward; 5-unit fork/compound squads; isolated boss.
  - Accept: no more than two attack families overlap in the first three minutes;
    first behavior card arrives 45–75 seconds along the critical route.
  - Guard: field boss packets cannot activate from the critical route and stop at
    their leash when the player retreats.
- [ ] **3.3 Add squad identity and cohesion steering.**
  - As-is: active enemies independently converge and become an unreadable clump.
  - To-be: assign leader/slot/centroid/sector/leash metadata and blend cohesion
    only during non-committed movement.
  - Accept: squad debug simulation meets the 220-pixel cohesion contract and
    preserves each role's startup lane/target after commitment.
  - Guard: cover avoidance and stuck recovery still use shared movement rules.
- [ ] **3.4 Add large spawn cues and first-clear metrics.**
  - As-is: activation has no shared gateway presentation or pacing evidence.
  - To-be: pulse a marked anchor for 0.9 seconds; record time to first spawn,
    first damage, active count percentile, attack-family overlap, first reward,
    and damage-source family in a local debug snapshot.
  - Accept: capture sequence shows safe arrival, gate cue, first scout, 3-unit
    squad, and later 5-unit squad as distinct readable states.
  - Guard: metrics remain local/debug data and never block or alter gameplay.
- [ ] **3.5 Add Standard and Onslaught through the same packet data.**
  - As-is: one high-pressure tuning is always active.
  - To-be: preset changes caps, budgets, and gaps only; map, enemy behaviors,
    rewards, and safe arrival are shared.
  - Accept: Standard and Onslaught simulations use locked values and both remain
    under the projectile/effect/performance caps.
  - Guard: preset choice is visible, persisted, and never changes mid-stage.

Batch acceptance: natural Stage 1 play has six safe seconds, readable sequential
entry, coherent squads, an early card, and increasing pressure without a mass pop.

Batch guard: no endless timer spawning, no extermination gate, no hidden preset
switch, and no performance regression above the 8ms fixed-step budget.

### Phase 4: Correct Stage 2 and Stage 3 composition

Goal: migrate the current later stages to the same safe-start, map-truth, packet,
and squad contracts while preserving their distinct spatial verbs.

Source owners touched: `scripts/vehicle/stages/tidal_archive.gd`,
`scripts/vehicle/stages/storm_drydock.gd`,
`scripts/vehicle/vehicle_stage_catalog.gd`,
`scripts/vehicle/vehicle_stage_rules.gd`,
`scripts/vehicle/vehicle_stage_backdrop.gd`,
`scripts/encounters/vehicle_encounter_runtime.gd`,
`tools/validation/validate_vehicle_stage_layouts.gd`,
`tools/validation/validate_vehicle_encounter_pacing.gd`

- [ ] **4.1 Re-author Tidal Archive around current lanes.**
  - As-is: it reuses the shared macro layout and population-first pressure.
  - To-be: safe intake plaza, two visible current lanes, one counter-current
    optional branch, sequential 3/4/5-unit packets, and isolated boss vault.
  - Accept: current direction is readable before entry; every packet anchor and
    retreat path is reachable; population remains inside the Stage 2 band.
  - Guard: currents never push the player into non-walkable space or through cover.
- [ ] **4.2 Re-author Storm Drydock around grounded safe zones.**
  - As-is: it reuses the shared macro layout and dense swarm expansion.
  - To-be: safe service plaza, large grounded islands, visible sweep timing,
    shield-support packet sequencing, and isolated boss cradle.
  - Accept: every electrical sweep leaves one reachable safe region and Stage 3
    population remains inside its band.
  - Guard: electrical timing cannot overlap an unavoidable spawn entrance.
- [ ] **4.3 Validate cross-stage escalation.**
  - As-is: later difficulty is mainly a higher count and cap.
  - To-be: Stage 2 adds current/installation relationships; Stage 3 adds
    safe-zone/shield relationships; squad timing escalates within each stage.
  - Accept: a debug full run records distinct environment, role mix, packet table,
    and reward IDs for all three stages.
  - Guard: Stage 2/3 still begin with six safe seconds and one first scout.

Batch acceptance: all three current stages have distinct maps, safe entries,
shared geometry truth, and staged squad pressure.

Batch guard: accumulated upgrades, persistent modules, localization, stage
transitions, result screens, and garage flow remain unchanged.

### Phase 5: Four enemy roles and twelve upgrades

Goal: expand target-priority decisions and build variety only after the first
three stages meet onboarding and map gates.

Source owners touched: `scripts/enemies/vehicle_enemy_archetypes.gd`, focused
helpers under `scripts/enemies/`, `scripts/cards/vehicle_upgrade_catalog.gd`,
`scripts/cards/vehicle_run_build.gd`, `scripts/combat/vehicle_status_runtime.gd`,
`scripts/vehicle/vehicle_run.gd`, `data/cards/vehicle/*.tres`,
`localization/vehicle_stage.csv`,
`tools/validation/validate_vehicle_upgrade_system.gd`,
`tools/validation/validate_vehicle_run.gd`

- [ ] **5.1 Implement and validate the four locked enemy roles.**
  - As-is: no ram recovery target, explicit repair link, bounded carrier, or beam
    installation exists.
  - To-be: implement exactly the contracts in “New enemy roles,” with large
    telegraphs, health presentation, cover rules, and coordination costs.
  - Accept: deterministic tests exercise startup, active, counter, recovery,
    death cleanup, LOS, child caps, and concurrency limits for every role.
  - Guard: ordinary projectiles/beams do not pass through cover and no role gains
    hidden immunity.
- [ ] **5.2 Add the twelve locked card definitions and behavior hooks.**
  - As-is: 34 cards.
  - To-be: 46 cards using existing families, resource validation, exclusion,
    requirement, preview, and application flow.
  - Accept: every card produces its stated effect, respects max level, has Korean
    and English copy, and appears only in compatible offers.
  - Guard: no effect is implemented in UI and no offer contains duplicates or
    incompatible element cores.
- [ ] **5.3 Protect early reward comprehension.**
  - As-is: the full catalog is broadly available.
  - To-be: Stage 1's first calibration offer remains curated to one primary,
    one element/opening, and one passive/mobility behavior; advanced new cards
    enter later-stage/relay/field-boss source tags.
  - Accept: first offer has three visibly distinct choices and later offers can
    surface all twelve new cards over deterministic seed coverage.
  - Guard: adding cards does not add mandatory modal interruptions.

Batch acceptance: catalogs report 19 enemy archetypes and 46 valid cards, and
all new behaviors are readable in isolated debug contracts.

Batch guard: Stage 1 first-contact role count and curated reward pool do not grow.

### Phase 6: Coral Switchyard and Abyssal Observatory

Goal: extend the run from three to five authored stages with the locked spatial
verbs, enemy relationships, optional branches, and bosses.

Source owners touched: `scripts/vehicle/stages/coral_switchyard.gd`,
`scripts/vehicle/stages/abyssal_observatory.gd`,
`scripts/vehicle/vehicle_stage_catalog.gd`,
`scripts/vehicle/vehicle_stage_rules.gd`,
`scripts/vehicle/vehicle_stage_backdrop.gd`,
`scripts/bosses/vehicle_boss_patterns.gd`,
`scripts/vehicle/vehicle_run.gd`,
`localization/vehicle_stage.csv`,
`tools/validation/validate_vehicle_stage_layouts.gd`,
`tools/validation/validate_vehicle_run.gd`

- [ ] **6.1 Author Coral Switchyard.**
  - As-is: no Stage 4.
  - To-be: implement the locked switches, safe routes, packet tables, Rammer/
    Repair Tender relationship, optional convoy, field boss, and Behemoth boss.
  - Accept: both switch states and both critical-route orders reach every required
    objective; no state traps the player; population remains in the Stage 4 band.
  - Guard: switch state uses large live geometry and minimap feedback, not text-only
    instructions or invisible collision changes.
- [ ] **6.2 Author Abyssal Observatory.**
  - As-is: no Stage 5.
  - To-be: implement the locked reflectors, safe routes, Carrier/Beam relationship,
    optional vault, field boss, and Crown Engine boss.
  - Accept: all reflector orientations resolve deterministically; reflected
    projectile paths match their visible angle; population remains in Stage 5 band.
  - Guard: non-reflector cover keeps current collision behavior and the boss never
    combines carrier reinforcements with its active beam pattern.
- [ ] **6.3 Extend run progression and rewards to five stages.**
  - As-is: Stage 3 is final.
  - To-be: Stage 3 result advances to Stage 4, Stage 4 to Stage 5, and Stage 5 to
    final garage/result; run upgrades persist and new reward source tags resolve.
  - Accept: automated full-run summary contains all five IDs in order and reaches
    final completion with the accumulated build intact.
  - Guard: replay/restart resets only the intended stage/run state and never skips
    an unclaimed mandatory reward.

Batch acceptance: a complete run traverses five visually and mechanically
distinct stages and both new bosses test their stage's taught spatial verb.

Batch guard: Stage 4/5 reuse the same input, packet, geometry, UI, save, and card
contracts rather than creating parallel systems.

### Phase 7: Production validation, specification update, and plan retirement

Goal: prove the integrated game, make current specifications truthful, and leave
no transient implementation authority behind.

Source owners touched: `docs/product/vehicle_game_spec.md`,
`docs/design/UI_VISUAL_SYSTEM.md`, `README.md`, `.github/workflows/vehicle-run-validation.yml`,
all validators named below, and this ExecPlan

- [ ] **7.1 Run complete automated and performance gates.**
  - As-is: current validators assume three stages, old counts, and old bindings.
  - To-be: update exact contracts and run clean import, focused validators,
    five-stage full-run validation, pressure profiles for both presets, native
    boot, rendered capture, and Web export.
  - Accept: every command in “Validation Cadence” exits zero and both presets
    remain at or below 8ms per fixed simulation step.
  - Guard: warnings are classified; no test is weakened to accommodate a failure.
- [ ] **7.2 Conduct the locked rendered and natural-play review.**
  - As-is: no evidence exists for the new start, packet entry, binding panel, or
    added stages.
  - To-be: capture the required states and perform at least one fresh-profile
    Standard run through Stage 1 plus direct route checks for Stages 2–5.
  - Accept: the reviewer can identify walkable space, blockers, first spawn,
    squad size, critical objective, optional route, and live bindings without a
    debug overlay; Stage 1 first spawn occurs at 6.0 seconds.
  - Guard: do not accept screenshots that hide clipping, crowd overlap, or failed
    collision with a convenient camera position.
- [ ] **7.3 Update durable current documentation and remove the plan.**
  - As-is: the active spec describes three stages, current counts, and current
    input behavior.
  - To-be: record the landed five-stage, pacing, geometry, input, enemy, and card
    contracts in the active specs; update README commands/counts; run lifecycle audit.
  - Accept: docs describe only landed behavior, lifecycle audit has zero findings,
    and no stale three-stage/old-binding/mass-swarm contract remains.
  - Guard: delete this plan only after all completion criteria pass and durable
    decisions are present in the canonical specs.

Batch acceptance: production artifacts, current specs, and source all describe
the same five-stage game; the repository is clean after one scoped commit.

Batch guard: no completed plan, capture dump, or historical report remains as
active project authority.

## Test Plan and Validation Cadence

Inner-loop commands:

```powershell
.\tools\godot.ps1 --headless --import
.\tools\godot.ps1 --headless --script res://tools/validation/validate_vehicle_input_bindings.gd
.\tools\godot.ps1 --headless --script res://tools/validation/validate_settings_store.gd
.\tools\godot.ps1 --headless --script res://tools/validation/validate_vehicle_stage_layouts.gd
.\tools\godot.ps1 --headless --script res://tools/validation/validate_vehicle_encounter_pacing.gd
.\tools\godot.ps1 --headless --script res://tools/validation/validate_vehicle_upgrade_system.gd
```

Batch gates:

```powershell
.\tools\godot.ps1 --headless --script res://tools/validation/validate_vehicle_primary_weapon.gd
.\tools\godot.ps1 --headless --script res://tools/validation/validate_vehicle_run.gd
.\tools\godot.ps1 --headless --script res://tools/validation/validate_vehicle_rewards_ui_audio.gd
.\tools\godot.ps1 --headless --script res://tools/validation/profile_vehicle_pressure.gd
git diff --check
```

Final gates:

- **Clean import:** `.\tools\godot.ps1 --headless --import`
- **Native boot:** `.\tools\godot.ps1 --headless --quit-after 2`
- **Rendered evidence:** run the current `--capture-all=<absolute directory>`
  contract and retain captures for deployment/settings, safe arrival, spawn cue,
  first scout, 3-unit squad, 5-unit squad, Stage 1 fork, and Stages 2–5.
- **Full tests:** run every script under `tools/validation/` except capture-only
  helpers; all must exit zero.
- **Production build:** `.\tools\export_web.ps1`; verify non-empty `index.html`,
  `index.js`, `index.pck`, and `index.wasm`.
- **CI production boot:** run `.github/workflows/vehicle-run-validation.yml`,
  including native captures and built-Web browser boot.
- **Viewport review:** 960x540, 1280x720, and 1920x1080; Korean and English;
  deployment, shared settings, combat, upgrade, pause, result, and garage.
- **Persistence:** fresh defaults, custom bindings, reset bindings, conflict
  rejection, malformed descriptor, Standard/Onslaught, audio, and locale.
- **Document lifecycle:**
  - `python C:\Users\BK\.codex\skills\doc-lifecycle-steward\scripts\audit_docs.py --root docs --markdown`
  - `python C:\Users\BK\.codex\skills\doc-lifecycle-steward\scripts\audit_docs.py --root .agents --markdown`
- **Stale-contract scan:** search for `SHIFT / LMB`, `EMP Z`, `KEY_Z`,
  `_swarm_groups`, old exact populations, global `PLAYER_START`, three-stage
  final-result assumptions, and coordinate-only progression gates.

Rerun policy:

- Rerun a failed narrow check only after a concrete change or new hypothesis.
- Rerun full gates only after the suspected cause changed.
- Record known non-blocking warnings instead of rediscovering them.

## Rollback and Safety

- Land each phase as a separate scoped commit after its batch gates pass.
- Preserve the current catalog facade while migrating consumers; remove old
  constants/functions only after the last caller and validator move.
- Keep current three stages playable while Phases 1–5 proceed. Stage 4/5 do not
  enter `STAGE_IDS` until their definition, localization, reachability, packet,
  boss, and transition checks all pass.
- Save-data additions use defaults for missing `[controls]` and `[gameplay]`
  sections. Do not change the existing save path or invalidate audio/locale data.
- Do not lower collision, input, or catalog validation to pass incomplete data.
- Do not install dependencies, import asset packs, rewrite Git history, or push
  remotely as part of this plan.

## Predetermined Error Handling and Contingencies

| Trigger | Required response | Limit / escalation point |
| --- | --- | --- |
| A spawn anchor overlaps cover, hazard, start clearance, or another spawn. | Fail stage validation and move the authored anchor inside the same locked pocket; never relocate randomly at runtime. | Escalate only if the locked route has no valid anchor without changing map geometry. |
| A packet would spawn while its prior squad exceeds the active cap. | Keep it queued and resume its squad gap after capacity becomes available. | Never delete required enemies or exceed the cap. |
| The player retreats from an optional pocket. | Stop new optional spawns, leash living members, and preserve already earned damage/state until the packet resets at its authored boundary. | Optional enemies must never follow into the critical route. |
| A saved binding is malformed. | Restore the default for that action, preserve every valid action/audio/locale value, warn once, and save the repaired profile. | Never discard the complete settings file for one bad descriptor. |
| A requested binding conflicts. | Reject the new descriptor, keep both prior bindings, and show localized conflict text. | No implicit swap or unbound action. |
| Walkable rendering and movement validation disagree. | Treat stage data as authoritative, fail the build, and correct the backdrop or rule consumer. | Do not add a visual-only or collision-only patch list. |
| A Standard pressure profile exceeds 8ms. | First remove dormant work, cache stage queries, and bound projectile/effect creation; rerun the narrow profile. | Do not lower population or acceptance caps until the implementation waste is removed and the owner approves a design change. |
| A new stage fails any route order or reflector/switch state. | Keep the stage out of `STAGE_IDS` and fix its definition/tests. | Do not ship a fallback teleport or invisible corridor. |
| A new card cannot be expressed through a focused combat owner. | Do not implement it in UI or the shared catalog; place the behavior in the owning player/combat/runtime module. | Escalate only if the locked effect requires a new cross-system contract. |

## Risks

- Per-stage geometry touches movement, projectile collision, spawn validation,
  minimap interpretation, progression, and rendering; facade-first migration and
  shared validators are mandatory.
- The 3,800-line shared run is prone to absorbing new responsibilities; encounter
  timing and boss pattern extraction must happen before content expansion.
- Sequential spawning can feel slow if enemies emerge far from combat; authored
  gates, visible cues, and locked squad gaps prevent dead air without removing grace.
- Cohesion steering can fight cover avoidance or attack commitment; it is limited
  to non-committed movement and only 30% of desired velocity.
- More cards can dilute early offers; source tags and the curated first offer are
  hard guards.
- Reflectors can create ambiguous projectile ownership; hostile and player color,
  trail, and damage ownership remain unchanged after reflection.

## Open Questions

No material questions remain. Implementation-local coordinate adjustments are
allowed only inside the locked route, clearance, lane-width, population, timing,
and validation boundaries above. Any change to stage count, stage verbs, default
controls, grace duration, squad sizes, pressure presets, enemy roles, or upgrade
list requires owner change control.

## Decision Notes

- “Enemies appear after 5–10 seconds” is implemented as a deterministic six-second
  arrival grace, not a random delay.
- “One at a time” applies to presentation and spawn ticks; “3–5 together” applies
  to squad identity and movement after sequential entry.
- “More frequent/larger later” is tied to authored encounter beats, not elapsed
  global time, so exploration does not trigger unrelated waves.
- “Respawn in the center” applies exactly to Flooded Works and to every Stage 1
  restart/replay; later stages use authored safe entry plazas.
- Shift replacing Z is an accepted input change. Z is removed from default copy
  and remains available only if the player rebinds it.
- Content expansion starts only after the current three-stage game satisfies the
  new onboarding, map, and pacing gates.

## Progress

- [x] Phase 1: Remappable combat controls and shared settings
- [ ] Phase 2: Per-stage geometry and central Stage 1 map
- [ ] Phase 3: Sequential encounter packets and cohesive squads
- [ ] Phase 4: Correct Stage 2 and Stage 3 composition
- [ ] Phase 5: Four enemy roles and twelve upgrades
- [ ] Phase 6: Coral Switchyard and Abyssal Observatory
- [ ] Phase 7: Production validation, specification update, and plan retirement
- [ ] Final gates

## Next Steps

1. Implement Phase 1 and run its focused input/settings/layout gates.
2. Complete Phases 2–3 as the first full user-playable Stage 1 vertical slice.
3. Play and validate Stage 1 Standard and Onslaught before touching Stage 2/3.
4. Complete Phases 4–6 in order, running each batch gate before adding the next
   content layer.
5. Finish Phase 7, incorporate landed contracts into active specs, and delete
   this plan only when the repository is clean and every completion check passes.

## Completion Criteria

- [ ] Fresh Stage 1 deployment has six seconds without an active damaging enemy.
- [ ] First enemy is one scout; subsequent squads enter one unit at a time and
  progress through locked 3/4/5 sizes and gaps.
- [ ] Standard and Onslaught use visible, persisted, deterministic contracts.
- [ ] Stage 1 starts at exact map center with 360-pixel clearance and both
  generator routes, optional branch, reward, boss, and return paths reachable.
- [ ] Walkable, blocked, hazard, and void presentation matches collision truth.
- [ ] Mouse 1 primary, Space dash, and Left Shift EMP are the fresh defaults; all
  three remap, reset, persist, reject conflicts, and update live UI copy.
- [ ] Stages 1–3 meet safe-start, map, packet, squad, and isolated-boss contracts.
- [ ] Rammer, Repair Tender, Drone Carrier, and Beam Sentinel pass all behavior,
  telegraph, cover, cap, and cleanup checks.
- [ ] All twelve new cards behave as specified; catalog count is 46.
- [ ] Coral Switchyard and Abyssal Observatory are complete, distinct, localized,
  reachable, and connected as Stages 4 and 5.
- [ ] Five-stage full-run, reward, save, UI, performance, native capture, Web
  export, and built-Web boot gates pass.
- [ ] Active product/visual specifications describe only landed behavior.
- [ ] No retired owner, duplicate path, placeholder, unresolved material decision,
  old binding copy, mass-swarm contract, or completed ExecPlan remains.

## Stop Conditions

Complete when all completion criteria and final gates pass, durable contracts are
in the active specifications, this plan is removed, and the scoped commit leaves
a clean worktree.

Escalate only when a locked route cannot satisfy geometry/spawn safety, a locked
behavior requires a new dependency or save migration, performance remains above
8ms after removing implementation waste, or the owner requests a material
product change.

Do not stop because one stage, card, enemy, capture, localization surface, or
validator remains incomplete; finish the current phase and its batch gates before
handoff.

## Handoff

```text
Goal: Implement the active vehicle onboarding, map, controls, and five-stage content plan without changing its locked product decisions.

Read first:
- AGENTS.md
- .agents/AGENTS.md
- .agents/PLANS.md
- .agents/execplans/2026-07-22-vehicle-onboarding-map-controls-content.md
- docs/product/vehicle_game_spec.md
- docs/design/UI_VISUAL_SYSTEM.md

Execute exactly:
- Start at Phase 1 and complete phases in order.
- Keep each new responsibility in the owner named by Architecture and Ownership.
- Commit each phase only after its batch gates pass.

Validate with:
- The focused commands and final gates in Test Plan and Validation Cadence.
- Standard and Onslaught rendered/natural-play reviews.

Stop when:
- Every completion criterion passes, current specs are updated, the plan is deleted, and the worktree is clean.
```
