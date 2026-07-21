---
type: spec
status: draft
owner: BK
created: 2026-07-21
topic: Vehicle-led Cardborne stage, enemy, and upgrade expansion
scope: Implementation-ready content boundaries after the accepted Stage 1 combat loop is playtested
related:
  - ./vehicle_stage_one_experimental_spec.md
  - ./progression_upgrade_system_spec.md
  - ../design/vehicle_stage_one_future_directions.md
---

# Vehicle Content Expansion Spec

## Purpose and authority

This draft turns the broad future-direction notes into a concrete way to add stages, enemies, and upgrades without turning Cardborne into an undirected survival arena. It does not authorize Stage 2 production by itself. Stage 1 playtesting must first confirm that manual target priority, finite primary bursts, dash positioning, installation pressure, and one mid-stage card choice are enjoyable.

The requirements below are the proposed reusable content contract. Named Stage 2 and Stage 3 concepts are examples to evaluate, not accepted production commitments.

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

### Proposed Stage 2 example: Tidal Archive

- **Spatial verb:** redirect slow water currents that push vehicles and projectiles along marked lanes.
- **Installation problem:** two current regulators protect an artillery archivist; disabling either opens a safer line of sight but strengthens the other lane.
- **Optional branch:** travel against the current to reach a field boss guarding a passive-module blueprint.
- **Boss exam:** rotate current lanes, destroy exposed relay seals, and use cover while the boss fires committed archive beams.
- **Reuse:** chasers and turrets return with changed placement; mines drift only inside clearly painted current lanes.

### Proposed Stage 3 example: Storm Drydock

- **Spatial verb:** move between grounded safe zones before broad electrical sweeps activate.
- **Installation problem:** mobile shield escorts link to fixed lightning towers, forcing the player to break the link or reposition for a direct shot.
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

### Candidate additions

- **Shield Escort:** orbits a linked enemy and blocks shots only across the visible link arc. Destroying or separating it exposes the target.
- **Artillery Spotter:** paints one large impact point, then fires after a long startup. Breaking line of sight cancels the accurate shot but produces a weaker fallback shell.
- **Interceptor Tower:** consumes a limited number of player projectiles before overheating; its remaining intercept charges are shown as large pips.
- **Salvage Thief:** steals an exposed temporary pickup and retreats toward a marked nest, creating a chase without permanently deleting critical progression.

## Encounter composition

Use a threat budget, not raw enemy count. A standard combat group contains one space-maker, one priority target, and up to two supporting bodies. Only two ordinary enemies may be in committed damaging attack phases at once; the others reposition, communicate support, or recover. Fixed installations count against the same pressure budget.

Activation uses authored zones and proximity. Enemies may pursue across connected local spaces but return or reposition when navigation fails. Progress gates depend on installations, interaction, survival, or boss defeat—not total ordinary-enemy extermination.

## Upgrade contract

Run upgrades are cards that visibly change a behavior within the next encounter. A card must belong to one family and state its trigger, effect, and meaningful tradeoff:

| Family | Examples | Avoid |
|---|---|---|
| Primary geometry | ricochet, forked final round, tighter scatter at low rounds | invisible universal damage-only bonuses |
| Charge cycle | larger burst with slower full charge; quick refill after a dash; final round overload | removing the finite-burst decision entirely |
| Passive command | two weaker seekers; marked-target priority; pickup-triggered drone | passive screen clearing with no target relation |
| Dash collision | ion wake, ram pulse, projectile erase with longer cooldown | unconditional invulnerability uptime |
| EMP/control | aftershock, linked-installation disruption, pickup conversion | permanent stunlock or unreadable proc chains |

An offer contains three compatible, non-duplicate cards. At least two different families appear unless the player deliberately chose a focused reward source. Cards never implement their effects in UI code; definitions live in data, run state owns selections, and gameplay owners read effect IDs. The UI translates display keys and emits only the selected stable ID.

Persistent progression unlocks sidegrades, new card families, route choices, or equipment options. It must not add mandatory permanent damage grinding that invalidates authored encounter tuning. Important cards, blueprints, and equipment use deliberate reward presentation, never tiny floor drops.

## Asset and UI needs

Before a content milestone starts, list only assets that cannot be communicated by current geometry and theme controls:

- one large stage landmark/background motif and a restrained ground-surface set;
- one readable silhouette per new vehicle/enemy/installation role;
- startup, active, recovery, hit, disabled, and destroyed states where behavior requires them;
- large pickup/reward symbols with the existing semantic colors;
- minimap marker and codex icon only when the role cannot reuse an existing symbol.

Cooldowns, charge counts, links, health, card copy, selection, and settings remain live Godot UI. They are not baked into images.

## Data and ownership

- Stage layout and encounter definitions belong under stage/encounter data owners, not the UI.
- Enemy movement and attacks remain under enemy behavior owners; stage scripts activate groups but do not implement role logic.
- Card definitions and effects remain separate from presentation and player input.
- Global run state owns current cards and route; persistent state owns unlocks and equipment.
- Localization keys are stored with display data; stable IDs remain language-independent.

The current monolithic Stage 1 script is acceptable for the proof but must be split along these boundaries before a second production stage duplicates it.

## Acceptance gates for adding a stage

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
