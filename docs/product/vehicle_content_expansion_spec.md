---
type: spec
status: active
owner: BK
created: 2026-07-21
topic: Vehicle-led Cardborne stage, enemy, and upgrade expansion
scope: Implemented three-stage vehicle run, enemy-role, upgrade, and future content boundaries
last_reviewed: 2026-07-22
related:
  - ./vehicle_stage_one_experimental_spec.md
  - ./progression_upgrade_system_spec.md
  - ../design/vehicle_stage_one_future_directions.md
---

# Vehicle Content Expansion Spec

## Purpose

This specification governs the implemented three-stage vehicle run and future additions without turning Cardborne into an undirected survival arena. Manual target priority, held Pulse Cannon fire, a one-second idle-powered opening shot, dash positioning, installation pressure, and map-acquired build choices are the shared combat language.

Flooded Works, Tidal Archive, and Storm Drydock are implemented authored stages. Their first playable versions intentionally reuse the shared macro objective cadence and boss behavior while proving distinct layouts, environment rules, and enemy mixes. Further production polish remains subject to playtesting.

## Scope

This specification applies to the current vehicle run, its stage definitions,
enemy-role composition, run-card behavior, presentation needs, and compatible
future additions. It does not supersede the retained humanoid-proof product brief
or protected repository policy, and it does not authorize the broader persistent
economy described by the progression specification.

## Requirements

The detailed contracts below are normative within this scope. In summary:

- retain manual target priority, held primary fire, the one-second opening shot,
  dash, passive support, and one explicit active skill;
- keep navigation and combat in one authored field while making ordinary-enemy
  extermination unnecessary for progression;
- give each stage one new spatial verb, one new threat relationship, and one new
  reward interaction;
- coordinate simultaneous pressure and preserve readable startup, active, and
  recovery windows;
- keep card definitions, run state, enemy behavior, stage data, UI, and
  persistence under their existing responsibility owners.

## Core run rhythm

Every authored stage combines navigation and combat in one continuous field. A stage should take roughly 8–12 minutes on a successful first clear and contain five beats:

1. **Safe read:** a short arrival space reveals the stage's dominant landmark and one new hazard without damage pressure.
2. **Open pressure:** mobile enemies teach the local movement problem while the player can choose a target and route.
3. **Installation decision:** two or more fixed threats create a priority problem. Destroying every ordinary enemy is never required to advance.
4. **Reward decision:** an authored cache, elite, or field boss offers a meaningful card or module after a visible achievement.
5. **Boss exam:** the final arena recombines the stage's movement problem, one installation rule, and known enemy pressure with readable startup, active, and recovery windows.

A stage is not a recolored arena. It must add one new spatial verb, one new threat relationship, and one new reward interaction while reusing enough existing language to remain immediately readable.

## Stage construction contract

Each stage definition owns:

- a stable ID, display-name key, theme ID, world bounds, player entry, and boss arena;
- one critical route plus at least one optional risk/reward branch;
- landmark positions visible from adjacent combat spaces;
- solid-cover geometry shared by movement, hostile projectiles, player projectiles, aim assist, and passive target selection;
- encounter groups with activation bounds rather than global timed spawning;
- required installations, optional field-boss trigger, reward cache, and exit condition;
- minimap marker roles and discovery bounds;
- a stage-specific palette subset that preserves global player/reward/threat semantics.

Route widths must accommodate the player collision radius, a full dash, and at least two ordinary enemies without creating accidental door blocks. Every entrance and exit gets an automated reachability check and a rendered spawn-safety capture.

### Stage 2: Tidal Archive

- **Spatial verb:** redirect slow water currents that push vehicles and projectiles along marked lanes.
- **Installation problem:** two current regulators share the field with artillery spotters and limited-charge interceptor towers; route choice changes the order in which those threats gain line of sight.
- **Optional branch:** travel against the current to reach a field boss guarding a passive-module blueprint.
- **Boss exam:** rotate current lanes, destroy exposed relay seals, and use cover while the boss fires committed archive beams.
- **Reuse:** chasers and turrets return with changed placement; mines drift only inside clearly painted current lanes.

### Stage 3: Storm Drydock

- **Spatial verb:** move between grounded safe zones before broad electrical sweeps activate.
- **Installation problem:** mobile shield escorts protect nearby ordinary enemies while artillery and interception roles contest the divided drydock lanes.
- **Optional branch:** a timed salvage crane exposes a reward while temporarily removing cover.
- **Boss exam:** alternating safe zones, destructible shield escorts, and a slow committed ram pattern; no unrelated bullet-wall phase.
- **Reuse:** shooters and controllers return in smaller numbers so the stage-specific electrical timing remains dominant.

## Enemy role contract

Every enemy must answer four questions in data and presentation:

1. What space does it claim?
2. Why might the player target it before the nearest enemy?
3. What visible cue announces damage?
4. What movement, aim, dash, or timing response defeats it?

The standard roster is role-based:

| Role | Purpose | Required counter/read | Coordination limit |
|---|---|---|---|
| Pursuer | Dislodge stationary firing | sidestep or dash a committed approach | at most two attacking simultaneously |
| Skirmisher | Contest open lanes | use cover, close distance, or pre-aim | burst windows do not overlap continuously |
| Controller | Deny a marked area | leave the shape before activation | one major denial zone near the player at a time |
| Installation | Create target priority | break line of sight or destroy its support relation | placement must leave one safe approach |
| Support | Shield, repair, spot, or redirect | identify and sever a visible link | never make an off-screen target invulnerable |
| Elite/field boss | Guard optional value | learn two combined role rules; retreat remains possible | isolated from the required stage boss gate |
| Stage boss | Test taught rules | read startup/active/recovery and exploit a vulnerability window | phases recombine known verbs instead of replacing them |

New enemies add one primary behavior, not several hidden exceptions. Silhouette, threat color, health bar, telegraph shape, projectile ownership, and death result must be readable at gameplay zoom. Ordinary enemy bullets collide with solid cover unless a clearly named elite/boss rule communicates otherwise.

### Implemented additions

- **Shield Escort:** circles the player-facing formation and grants a visible shield to nearby ordinary allies. Destroying or separating it exposes them.
- **Artillery Spotter:** paints one large impact point, then resolves a denial zone after a long startup.
- **Interceptor Tower:** consumes a limited number of player projectiles before overheating; its remaining intercept charges are shown as large pips.

Salvage Thief remains an unimplemented future candidate and must not delete critical progression.

## Encounter composition

Use coordinated pressure, not raw enemy count alone. Flooded Works, Tidal Archive, and Storm Drydock contain exactly 204, 228, and 252 pre-boss enemies, while hard local mobile activation caps are 48, 54, and 60. The scheduler retains committed attackers and then the nearest enemies, making distant groups dormant without deleting them. Compact swarm units create visible density; a 6.5-point attack budget, three ranged commits, and two denial commits bound simultaneous danger. Enemy movement is 15% faster, hostile projectiles are 12% faster, enemy damage is 25% higher, and ordinary recovery is 20% faster than the original dense-combat baseline; startup warnings remain unchanged. Inactive groups do not move, attack, draw, or create individual minimap noise. Fixed installations participate in the same coordination rules where applicable.

Activation uses authored zones and proximity. Enemies may pursue across connected local spaces but return or reposition when navigation fails. Progress gates depend on installations, interaction, survival, or boss defeat—not total ordinary-enemy extermination.

## Upgrade contract

Run upgrades are cards that visibly change a behavior within the next encounter. A card must belong to one family and state its trigger, effect, and meaningful tradeoff:

| Family | Examples | Avoid |
|---|---|---|
| Primary cadence/geometry | faster held fire, extra projectiles, ricochet, pierce, range | ammo limits or charge-gating ordinary fire |
| Opening shot | faster one-second recharge, stronger breach/stagger, elemental payoff | forcing the player to stop firing for ordinary damage |
| Element | mutually exclusive burn, poison, or slow cores and their follow-ups | unreadable multi-element stacking |
| Passive command | two weaker seekers; marked-target priority; pickup-triggered drone | passive screen clearing with no target relation |
| Dash collision | ion wake, ram pulse, projectile erase with longer cooldown | unconditional invulnerability uptime |
| EMP/control | aftershock, linked-installation disruption, pickup conversion | permanent stunlock or unreadable proc chains |

The current catalog contains 34 typed, bounded definitions. An offer contains three compatible, non-duplicate cards. Every stage presents mandatory calibration, relay, and post-boss offers plus an optional field-boss offer, for nine mandatory and up to three optional choices per run. Selection and application are separate actions behind a 0.35-second input guard. Cards never implement effects in UI code; definitions live in data, run state owns levels and elemental exclusion, and gameplay owners read derived values and behavior IDs.

Persistent progression unlocks sidegrades, new card families, route choices, or equipment options. It must not add mandatory permanent damage grinding that invalidates authored encounter tuning. Important cards, blueprints, and equipment use deliberate reward presentation, never tiny floor drops.

## Asset and UI needs

Before a content milestone starts, list only assets that cannot be communicated by current geometry and theme controls:

- one large stage landmark/background motif and a restrained ground-surface set;
- one readable silhouette per new vehicle/enemy/installation role;
- startup, active, recovery, hit, disabled, and destroyed states where behavior requires them;
- large pickup/reward symbols with the existing semantic colors;
- minimap marker and codex icon only when the role cannot reuse an existing symbol.

Cooldowns, charge counts, links, health, card copy, selection, and settings remain live Godot UI. They are not baked into images. During play, a 208 px off-screen threat indicator follows the projected player position and aggregates threats outside the safe viewport into 12 short directional arcs within 1,200 px. Arc weight communicates density/proximity; priority and current target use distinct semantic treatments. On-screen enemies are not duplicated in this overlay, and contact sampling runs at 10 Hz while the player-centered projection remains current.

## Data and ownership

- Stage layout and encounter definitions belong under stage/encounter data owners, not the UI.
- Enemy movement and attacks remain under enemy behavior owners; stage scripts activate groups but do not implement role logic.
- Card definitions and effects remain separate from presentation and player input.
- Global run state owns current cards and route; persistent state owns unlocks and equipment.
- Localization keys are stored with display data; stable IDs remain language-independent.

Stage identity, layout, population, rewards, and environment data live in `vehicle_stage_catalog.gd`; continuous cadence and opening charge live in `vehicle_primary_weapon.gd`; formation/pressure limits live in `vehicle_encounter_director.gd`; card/status/audio/UI responsibilities use their dedicated owners. The shared runtime orchestrates those owners and should not absorb another catalog or presentation system.

## Acceptance Criteria

A proposed stage can enter implementation only when:

- its new spatial verb and target-priority problem are stated in one sentence each;
- a route diagram identifies entry, critical path, optional branch, reward, field boss, boss, cover, and exit;
- all critical points pass reachability and spawn-safety checks;
- the enemy composition respects coordination limits and cover collision rules;
- at least one new reward changes a visible combat behavior;
- Korean and English names/copy exist before rendered UI review;
- 960x540 and 1280x720 captures show readable terrain, threats, rewards, telegraphs, and HUD;
- direct playtesting records time-to-first-decision, avoidable damage causes, target-priority clarity, and whether the boss tests taught rules.

## Non-goals

- endless global wave spawning;
- procedural maps before two authored stages are replayable and enjoyable;
- mandatory full-map extermination;
- screen-filling passive proc chains;
- a walkable base filled with errands;
- large asset-pack adoption without a separate license and visual-fit review.
