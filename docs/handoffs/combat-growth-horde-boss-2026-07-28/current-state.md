---
type: handoff
status: active
owner: BK
created: 2026-07-28
last_reviewed: 2026-07-28
expires: 2026-08-28
topic: Current Cardborne combat-growth issue state
scope: Evidence-backed orientation for a read-only external reviewer
source: ../../../.agents/survivor-shooter-combat-growth-reference-study.md
related:
  - ./README.md
  - ./source-map.md
  - ../../product/vehicle_game_spec.md
  - ../../product/combat-growth-improvement-direction.md
---

# Current State

## Current State

### User intent

The user wants the game to deliver the defining payoff of this genre:

- early weakness that grows into the ability to erase large enemy groups;
- meaningful herding and spatial setup rather than scattered cleanup;
- terrain that can be intentionally used to kill or compress enemies;
- bosses that feel like distinct encounters, not enlarged ordinary attack
  schedulers;
- constrained random upgrades whose rules and power destinations are clear.

The user explicitly does **not** require a separate mounted-weapon art asset for
every ship upgrade. The immediate request is independent review, not
implementation.

### Product identity that already exists

Cardborne is a Godot 4.7 top-down vehicle action shooter with:

- manual aim and held primary fire;
- a one-second Breach Shot;
- dash and EMP;
- passive Seeker support and up to two additional optional secondary families;
- a connected five-stage authored run;
- run-selected persistent fields, map pickups, crates, card upgrades, ordinary
  defeat quotas, and stage bosses;
- complete Korean and English user-facing surfaces;
- bounded hostile pressure, deterministic scheduling, exact telegraphs, and
  performance gates.

These are constraints to preserve, not symptoms to remove.

### Verified current behavior

#### Growth and offers

- `VehicleUpgradeCatalog` loads 46 cards.
- Offers are deterministic from run seed, stage, source, and offer serial.
- Offers contain at most three unique eligible cards.
- The first empty-build offer guarantees primary, element, and
  passive-or-mobility categories.
- Early mobility safety and underdeveloped elemental-branch bias already exist.
- Most cards are valid for both level-up and boss sources.
- Boss rewards therefore resemble another regular three-card offer instead of
  converting a prepared build into a distinct evolution tier.
- Behavior-changing cards exist, but no guaranteed named qualitative breakpoint
  is reached at a predictable stage.
- The minimum quota path currently distributes regular level-up choices roughly
  `7 / 4 / 3 / 3 / 4` across the five stages.

#### Encounter pressure

- Hard active caps are encounter-beat values, not stage values:
  `1 / 62 / 78 / 88 / 92`.
- Stage quotas are `125 / 166 / 208 / 250 / 291`.
- Authored ordinary populations are `260 / 300 / 340 / 380 / 420`.
- After the opening scout, a packet schedules eight squads of three to five
  enemies.
- Each squad receives its own deterministic off-screen anchor across a large
  `7200x4320` field.
- The allocator and director prioritize safe arrival, pursuit coverage, and
  distributed ranged/denial pressure.
- Small squad cohesion exists, but the system does not author one large
  killable front with a shared tactical weakness.
- A `group_clear` presentation event exists, but it is not a growth or reward
  loop.

#### Terrain

- Arc Surge strips damage both teams.
- Breakable Bulkheads alter paths and can be destroyed by a full Breach Shot.
- Transit Gates move only the player.
- Repair and overdrive fields support the player.
- Player-triggered mobile and stationary mines can damage enemies and chain.
- These pieces exist, but they do not consistently form a readable
  `herd → compress → trigger → mass kill → collect XP` loop.

#### Bosses

- Five named bosses use a shared stage-boss runtime and common actor dimensions.
- Boss phases change at 65% and 30% health.
- Phase progression reorders the same direct-pattern set, reduces read gaps,
  increases some volley pressure, and accelerates autonomous systems.
- Generic pattern kinds include lanes, charge, fan, area, cross, beam, pylons,
  and summon.
- Each boss exposes one approved signature startup to Breach interruption.
- Ordinary spawning stops when the quota is reached, so most boss fights lose
  the horde-processing part of the build.
- Boss defeat recalls XP and opens a mandatory three-card reward drawn mostly
  from the ordinary card catalog.

#### Optional field boss

Repository guidance says optional field bosses should be preserved, and
`VehicleRewardRuntime` can represent an optional `field_boss` reward. No live
field-boss spawn or encounter flow was found. Treat it as an unimplemented
product intention, not current gameplay.

### Mismatch

The current game pays both genre costs:

- manual shooter input load: aim, move, charge Breach, dash, EMP, prioritize;
- survivor-like endurance load: many enemies, repeated level-ups, large quotas.

The payoff is weaker than either reference family:

- no guaranteed manual-weapon rule transformation comparable to a weapon
  evolution or prerequisite super-mod;
- no reliably dense engagement in which a new build can demonstrate large
  clear acceleration;
- no environment-processing loop that turns movement and timing into mass
  kills;
- no boss phase that changes the player's objective sentence or arena rule;
- no boss-exclusive reward class that closes the growth milestone.

This is a design inference, not a measured fun result. It must be challenged
against live play and better telemetry.

### Relevant flow

```text
ordinary defeat
  -> VehicleExperienceRuntime shard
  -> level threshold
  -> VehicleUpgradeCatalog.offer(...)
  -> UI choice
  -> VehicleRunBuild.apply(...)
  -> primary / secondary / mobility behavior

VehicleCombatStages packet
  -> VehicleEncounterRuntime scheduler
  -> VehicleSpawnAllocator anchors
  -> pursuit and encounter director
  -> ordinary defeat quota
  -> VehicleBossRuntime
  -> VehicleRewardRuntime
  -> another catalog offer

player movement + Breach / EMP / mine
  -> VehicleTerrainRuntime and VehicleRun integration
  -> Arc / bulkhead / mine outcome
  -> damage attribution and XP
```

### Completed work

- `624f807` added the deep current-code and nine-game reference study.
- `docs/product/combat-growth-improvement-direction.md` records an unaccepted
  draft direction with requirements and Stage 1 acceptance targets.
- The draft proposes:
  - Foundation → Specialization → Evolution card roles;
  - Stage 1–4 boss-only Evolution offers;
  - two or three pressure fronts instead of eight dispersed arrival directions;
  - authored formations built from current enemy roles;
  - one player-triggerable enemy-processing interaction per field;
  - semantic boss phases, finite boss-wave adds, and boss-specific objectives;
  - engaged-density, kill-burst, environment, growth, and boss telemetry.
- No gameplay code has been changed for this direction.

### Open questions for the reviewer

1. Is the root cause actually missing system coupling, or is another problem
   more fundamental?
2. Is a three-tier growth model the smallest useful intervention?
3. Which current cards can be recombined into qualitative evolutions without
   multiplying content and UI complexity?
4. Can arrival fronts be clustered without producing unfair projectile
   overlap, path congestion, spawn delay, or performance regressions?
5. Should terrain be a universal shared verb, a field-specific verb, or a
   smaller mine/Breach extension?
6. How much ordinary pressure should remain during bosses?
7. Which boss distinctions can live in shared primitives, and which require
   stage-specific state owners?
8. Are the draft targets—`5/4/4/4/4` level-ups, 24 enemies in one sector,
   P90 engaged ratio 0.55, and 12 kills in two seconds—useful gates or arbitrary
   numbers?
9. Should quota pacing change only after instrumentation, or is the current
   structure itself already the wrong progression gate?

## Next Steps

- Review the exact sources in `source-map.md`.
- Correct any baseline claim that is not supported by current code.
- Evaluate the draft in `accept / modify / reject / needs-local-verification`
  terms.
- Return a bounded first vertical slice and the evidence required to expand it.
- Return one Markdown response without editing the repository. The local
  coordinator will save it unchanged in `external-review-raw.md`.

## Risks

- Static code can show scheduling and rules but not the felt density on screen.
- The draft may overfit reference games and underweight Cardborne's manual
  aiming and first-clear readability.
- Reauthoring encounter fronts could invalidate pacing validators without
  improving actual engagement.
- Adding stateful boss mechanics in `vehicle_run.gd` would worsen responsibility
  concentration; ownership recommendations need concrete module boundaries.
- Exact tuning without telemetry would turn design hypotheses into brittle
  constants.
