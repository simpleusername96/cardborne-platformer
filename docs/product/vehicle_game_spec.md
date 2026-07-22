---
type: spec
status: active
owner: BK
created: 2026-07-21
topic: Cardborne vehicle game
scope: Current five-stage vehicle campaign, combat, encounters, rewards, settings, and compatible future additions
last_reviewed: 2026-07-22
canonical_for: Cardborne gameplay and product behavior
related:
  - ../design/UI_VISUAL_SYSTEM.md
---

# Cardborne Vehicle Game Specification

## Purpose

Cardborne is a top-down vehicle action shooter built around manual target
priority, held Pulse Cannon fire, a stronger opening shot after one idle second,
dash positioning, passive seekers, one explicit EMP skill, field items, and
card-defined run builds. Exploration and combat share one authored field;
ordinary-enemy extermination is never a stage-exit requirement.

This specification describes the shipped five-stage campaign. It is the sole
product contract for the current executable.

## Scope

This contract covers the connected vehicle campaign, controls, encounter pacing,
stage progression, enemies, bosses, items, cards, HUD and modal flows, audio,
localization, settings, persistence, and the validation required to ship them.
Future ideas are outside scope until accepted here.

## Requirements

- Preserve independent movement and aim, held primary fire, the one-second
  opening shot, dash, passive support, and one explicit active skill.
- Keep navigation and combat in the same authored field while allowing ordinary
  enemies to be bypassed.
- Give every stage a readable spatial rule, target-priority problem, optional
  reward, and boss exam without forking the common control or UI contracts.
- Keep stage data, encounter pacing, enemy behavior, boss patterns, cards, UI,
  and persistence under their named responsibility owners.

## Controls and settings

Fresh defaults are:

| Intent | Default |
| --- | --- |
| Move | Arrow keys or WASD |
| Aim | Mouse position, independent of movement |
| Primary fire | Hold Mouse 1 |
| Dash | Space |
| EMP | Left Shift |
| Pause | Escape |

Normal primary fire repeats while held and is never charge-gated. Releasing it
for one second primes the next shot as an opening attack with stronger health and
structure damage plus temporary pierce. Dash is a short defensive repositioning
tool; passive seekers fire without another command; EMP is the only explicit
cooldown skill.

Deployment and pause open one shared settings surface. Primary fire, dash, and
EMP can be rebound, reset, persisted, and reflected immediately in HUD copy.
Conflicting bindings are rejected rather than silently swapping or unbinding an
action. Korean is the default language; English, audio levels, and the Standard
or Onslaught combat preset persist in the same settings contract.

## Campaign rhythm

Every stage uses the same deterministic onboarding and encounter language:

1. Arrival is safe from active damaging enemies for six seconds.
2. A visible entry cue begins at 5.1 seconds and one scout enters at 6.0 seconds.
3. Later packets activate from authored route events. Units enter sequentially,
   then cohere into squads of three, four, and five as the stage advances. After
   arrival, Standard uses 0.34x authored unit and squad gaps; Onslaught uses
   0.28x, so authored groups arrive roughly three times as quickly without
   changing the safe opening or spawning the whole map at once.
4. Calibration, two route installations, a relay cache, an optional field-boss
   branch, and a stage boss provide the macro decisions.
5. Ordinary enemies may remain alive when an authored exit opens. Installations,
   interactions, and bosses—not total kills—own progression gates.

Calibration and relay caches release 18/30 collectible experience instead of
opening fixed card choices. The shared level curve produces four to six mandatory
level-up choices on a full-clear stage, and the stage boss adds one mandatory
choice. The optional field-boss route can add one more. The current run build is
preserved between stages.

## Authored stages

Stages run in this fixed order:

| # | Stage | Spatial rule and target-priority problem | Boss exam |
| --- | --- | --- | --- |
| 1 | Flooded Works | Central safe plaza, two generator routes, solid cover, and an optional foundry pocket teach map semantics and installation priority. | Foundry Colossus recombines committed attacks, cover, and barrier pylons. |
| 2 | Tidal Archive | Marked current lanes push vehicles and projectiles while interceptor towers and artillery change route order. | Archive Leviathan tests current-lane positioning, relay seals, and cover. |
| 3 | Storm Drydock | Alternating electrical sweeps make grounded lanes and safe islands the movement read; shield escorts and beam sentinels change target order. | Drydock Titan tests safe-zone timing, escorts, and a committed ram. |
| 4 | Coral Switchyard | Three drive-over pads toggle one paired gate state. The open flank is always traversable; a timed salvage convoy is optional. | Switchyard Behemoth charges only through the learned open lane and becomes vulnerable after a cover crash. |
| 5 | Abyssal Observatory | Two drive-over consoles rotate two reflectors. Their orientations open the optional vault and redirect both friendly and hostile rounds. | Crown Engine starts behind two reflection-only shield relays and separates beam and carrier windows. |

Every stage definition owns its world bounds, safe start, walkable regions, solid
cover, water/void, hazards, landmarks, objective triggers, static threats,
encounter packets, field items, crates, and four reward anchors. The same data is
consumed by movement, projectile collision, line of sight, minimap rendering,
spawn validation, and backdrop drawing. Visual-only corridors and collision-only
blockers are invalid.

Flooded Works starts at the exact map center with a 360-pixel clear radius. Later
stages use authored entry plazas with the same clearance. Critical routes,
optional branches, boss entrances, and return paths must remain reachable for
the player collision radius.

## Encounter and difficulty contract

The campaign contains 19 data-defined archetypes spanning compact drones,
chasers, shooters, denial units, support vehicles, installations, field bosses,
and stage bosses. Enemy behavior must answer what space it claims, why it should
be targeted, what announces damage, and what response defeats it.

Important target-priority roles include:

- Shield Escort: protects one nearby ordinary ally with a visible relation.
- Artillery Spotter: paints a large impact area before denial becomes active.
- Interceptor Tower: visibly spends three charges to stop player projectiles.
- Rammer: paints one committed lane, crashes into cover, and exposes recovery.
- Repair Tender: restores one damaged ally through an unobstructed link.
- Drone Carrier: releases children sequentially under a six-child cap.
- Beam Sentinel: warns, activates for 0.6 seconds, stops at cover, then recovers.

Player and enemy projectiles collide with ordinary solid cover. An exception is
allowed only when a named boss or stage mechanic communicates it, such as an
Observatory reflector.

Authored population bands are:

| Stage | Total authored enemies before dynamic carrier children |
| --- | ---: |
| Flooded Works | 112–128 |
| Tidal Archive | 128–148 |
| Storm Drydock | 144–164 |
| Coral Switchyard | 152–176 |
| Abyssal Observatory | 160–184 |

Population does not equal simultaneous pressure. Standard active caps progress
through 1/15/22/28/32 units; Onslaught uses 1/22/33/44/52. The faster packet
timing fills those bounded caps while total authored population remains
unchanged. Standard threat budgets progress through 1.0/3.0/4.5/5.25/6.25;
Onslaught uses a 7.5 budget behind its beat-aware active caps. At most three
ranged commits and two
denial commits may overlap. Committed attackers are retained when caps are
enforced. Distant and optional packets remain dormant rather than being deleted
or globally activated.

Ordinary swarm and standard enemies use 1.12x health, 1.20x movement speed,
1.18x hostile projectile speed, 1.35x contact and projectile damage, and 1.28x
recovery rate. Priority enemies, field bosses, and stage bosses do not receive
the ordinary health multiplier. These multipliers increase active pressure while
preserving authored telegraphs and boss time-to-kill.

Authored non-boss enemies receive a small additional stage curve after their
archetype values: health progresses through 1.00/1.04/1.08/1.12/1.16, damage
through 1.00/1.03/1.06/1.09/1.12, and movement through
1.00/1.01/1.02/1.03/1.04. Projectile speed, startup, recovery, denial duration,
and ranged/denial commit ceilings do not scale by stage. Field and stage bosses
use explicit stage profiles rather than this curve.

## Rewards, items, and upgrades

The catalog contains 43 typed card definitions. Offers contain three compatible,
non-duplicate choices; selection and application are separate actions behind a
short input guard, and no card is applied before explicit confirmation. Card
data lives under `data/cards/vehicle/`; gameplay owners apply behavior while UI
only presents the offer.

Upgrade families cover:

- primary cadence and geometry: cadence, projectile count, ricochet, pierce,
  range, projectile scale, and an always-on reduced-damage Forked Muzzle side
  round per level;
- opening attacks: faster readiness, structure breach, and Shock Breach;
- mutually exclusive burn, poison, or slow cores and their bounded follow-ups;
- passive targeting: Marked Salvo plus seeker count, cadence, pierce, target
  priority, and warhead changes;
- dash and movement: Ion Wake, Ram Pulse, Phase Shear, direct mobility, and a
  visible two-second Coolant Surge fire-rate buff;
- EMP and barrier: aftershock, Relay Overload, Static Aegis, and Aegis Cycle;
- recurring cycle effects: Aegis every 14 seconds, Overclock every 12 seconds,
  and Thruster every 10 seconds, each with an exact active window shown around
  the player;
- sustain: Siphon Matrix heals 2%/3.5% of actual player-owned health damage,
  capped at six hull per second and excluding overkill or non-health structure
  damage such as crates.

Enemy defeats grant no experience directly. One collectible experience shard is
left at the defeat position for every authored enemy: swarm enemies are worth 1,
standard enemies 2, priority enemies and installations 4, field bosses 18, and
stage bosses 24. Summons grant zero experience. At most 192 shard entries remain
live; merging preserves their total value. Experience is added only when a shard
is collected by proximity or by an experience-recall pickup.

Run level starts at one. The next level requires
`min(72, 26 + 3 * (run_level - 1))` experience and carries excess experience.
Each reached level queues one mandatory three-card select-then-confirm offer.
Calibration and relay caches release collectible 18/30 experience clusters
instead of fixed card modals. A full-clear stage yields four to six level-up
offers, one mandatory stage-boss offer, and at most one optional field-boss offer.

Exactly two field pickup behaviors exist. `repair` heals its authored amount;
`experience_recall` pulls every active experience shard to the player over 0.65
seconds without collecting repairs, crates, caches, or objectives. Each stage
authors two repairs and one experience recall, while five breakable crates hold
four repairs and one experience recall. Temporary attack, cadence, movement,
barrier, seeker, capacitor, and magnet field items are retired into the card
build. Individual experience shards do not appear on the minimap.

## UI, audio, and persistence

The live HUD prioritizes compact hull and experience, objective, primary opening
state, passive seeker, dash, EMP, minimap, and exceptional buffs. The minimap distinguishes discovered
walkable space, blockers, objectives, rewards, bosses, and the player; unvisited
space stays concealed. A separate 12-direction off-screen threat arc aggregates
nearby off-screen enemies at 10 Hz rather than duplicating visible enemies.
Semantic HUD snapshots refresh at 20 Hz; world motion, aiming, projectiles, and
telegraphs continue to render every frame.

At 960x540 opaque combat HUD panels occupy at most 12% of the viewport and stay
outside the central 60% by 60% combat rectangle. The hull/XP cluster is at most
184x54, the objective chip 360x44, minimap 168x112, action cluster 276x60,
target panel 184x64, and boss strip 520x40, with smaller 960-pixel variants.
Recurring cycle effects use three shape-distinct 24-pixel radial badges around
the projected vehicle; reduced motion preserves arc state without pulsing.

Deployment, settings, upgrade, pause, result, and garage are explicit modal focus
layers. Gameplay HUD is hidden behind them, each exposes a clear primary action,
and keyboard focus remains deterministic. Boss state replaces competing top-HUD
clusters while active.

Thirteen stored WAV effects cover firing, impacts, rewards, destruction, and boss
warnings. Audio is enabled by default and controlled from the shared settings
surface. Persistent data keeps locale, audio, bindings, difficulty preset,
selected equipment, and earned persistent modules; replay resets the active run
build and stage pickups without corrupting settings.

## Ownership

- Stage data: `scripts/vehicle/stages/` behind `vehicle_stage_catalog.gd`.
- Movement and action intent: `scripts/player/` and the vehicle runtime.
- Encounter pacing and pressure: `scripts/encounters/`.
- Enemy definitions and specialist behavior: `scripts/enemies/`.
- Boss patterns: `scripts/bosses/`.
- Card definitions/effects: `data/cards/vehicle/` and `scripts/cards/`.
- UI and settings surfaces: `scripts/ui/`.
- Persistent settings: `scripts/autoload/settings_store.gd`.

The shared vehicle runtime orchestrates these owners. It must not become a second
stage catalog, settings store, card catalog, or presentation system.

## Acceptance criteria

- All five stages pass schema, reachability, clearance, packet-population, boss,
  transition, reward, and mechanic validators.
- First cue is 5.1 seconds, first scout is 6.0 seconds, and the 3/4/5 squad
  sequence remains deterministic in both presets.
- Fresh controls, remapping, conflict rejection, reset, persistence, Korean/
  English copy, audio, and difficulty settings pass focused validation.
- A full-clear route resolves four to six collectible-experience levels per
  stage plus five mandatory stage-boss reward transactions and preserves the
  build through the fifth boss.
- Standard and Onslaught fixed-step pressure profiles cover 32 and 52 moving
  actors respectively, a saturated scheduler, and the live HUD, and stay at or
  below 8ms.
- 960x540, 1280x720, and 1920x1080 rendered reviews show no clipped modal, HUD
  overlap, hidden route, ambiguous blocker, or unreadable objective.
- Native boot, Web export, and a browser boot of the built artifact all succeed.

## Non-goals

- endless global wave spawning or mandatory full-map extermination;
- procedural maps before the authored campaign is replayable and enjoyable;
- ammo limits or charge gates on ordinary primary fire;
- screen-filling passive proc chains or permanent control locks;
- realistic materials, dense micro-texture, or an unrelated asset-pack style;
- a black-floor/white-blocker or matching actor redesign before a separate
  monochrome readability decision is accepted;
- a walkable base filled with chores.
