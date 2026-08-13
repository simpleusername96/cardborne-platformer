---
type: evidence
status: active
owner: BK
created: 2026-08-13
last_reviewed: 2026-08-13
topic: Enemy arrival and engagement-distribution research
scope: Cardborne ordinary-enemy birth, approach, engagement, fairness, tactical variety, and performance interaction
source: Current product contract and runtime code, direct genre precedents, and cross-domain scheduling, traffic, robotics, crowd, ecology, and sampling research
related:
  - ./2026-08-13-enemy-arrival-conclusion-ko.md
  - ./2026-08-13-dense-enemy-stutter-evidence.md
  - ./2026-08-13-dense-enemy-architecture-options.md
  - ../product/vehicle_game_spec.md
  - ../../.agents/cardborne-performance-engineering-policy.md
---

# Enemy arrival and engagement-distribution research

## Purpose

Explain why Cardborne enemies often become one trailing mass even though births are distributed
around the player, then compare a broad set of alternatives. The desired outcome is more varied,
readable pressure around a moving player without assuming that spatial dispersion alone reduces
CPU cost.

This is an evidence and option study. It does not authorize a gameplay-contract change or a
runtime implementation.

## Executive finding

The observed tail is not primarily a random-spawn failure. Cardborne already gives each ordinary
unit an independent off-screen birth position and balances each canonical arrival window across
all eight sectors. The tail forms after birth:

1. Birth distance is selected from a deterministic hash rather than role speed or predicted
   time-to-engagement.
2. A moving player can be faster than every ordinary continuously moving enemy.
3. The normal movement focus is the current player plus a short bounded lead.
4. Pursuit actors move radially toward that focus; squads do not own approach lanes or angular
   positions.
5. Separation begins only after bodies overlap.

Therefore, a balanced **birth distribution** can collapse into an unbalanced **engagement
distribution**. A useful redesign must schedule where and when enemies become tactically relevant,
not merely where and when their objects are created.

The strongest candidate is a small deterministic **engagement director** layered between the
existing encounter scheduler and role movement:

- assign role-aware time-to-engagement targets;
- reserve a small set of target-relative approach sectors and time slots;
- keep one readable escape corridor instead of seeking a perfect surround;
- give an incoming actor a stable approach gate, then release it to the existing role behavior;
- interleave authored arrival patterns for deliberate variety; and
- keep attack-commit limits separate from visible population and arrival distribution.

This can be implemented as low-frequency scheduling work. It must not become per-enemy flocking,
pairwise formation solving, or a continuously invalidated positioning solver.

## Domain boundary

The word `spawn` hides four different operations. Keeping them separate prevents a local fix from
targeting the wrong layer.

| Term | Meaning in this study | Current owner |
|---|---|---|
| Birth | Create an enemy object at a valid off-screen world position. | `VehicleSpawnAllocator` and `VehicleEncounterRuntime` |
| Arrival window | A telegraphed, scheduled group of births. | `VehicleCombatStages` and `VehicleEncounterRuntime` |
| Transit / approach | Travel from the birth position toward a useful combat position. | targeting and movement policies in `VehicleRun` |
| Engagement distribution | The direction and time at which enemies become tactically relevant around the player. | No explicit current owner |
| Attack commitment | Permission to execute an attack that can harm or constrain the player. | existing role and global commit limits |

The missing responsibility is engagement distribution. Adding more rules to birth placement alone
cannot reliably own it because the player and enemies continue moving after allocation.

## Current-system evidence

### Birth is already broadly distributed

The product contract requires:

- three arrival windows of four logical squads;
- independent positions 900–2400 pixels from the cue-time player, with an emergency extension to
  2800 pixels;
- at least 220 pixels outside the view;
- at least 320 pixels of separation from the current window and recent births;
- all eight sectors in canonical windows, with counts differing by at most one;
- the first moving-player sector nearest the travel heading, with the remaining sectors still
  completing the all-sector distribution; and
- at most four due enemies per atomic round, with 0.16-second unit spacing.

The allocator implements eight sectors and target distances of 1200, 1650, and 2100 pixels. It
uses a maximally spaced sector order. The existing validator explicitly requires all eight sectors
and balanced counts.

This evidence rules out “the allocator only creates enemies behind the player” as the main cause.

### Birth distance ignores engagement time

`VehicleSpawnAllocator` hashes each request identity into one of the three target-distance lanes.
That choice is independent of:

- the role's movement speed;
- its desired standoff band;
- the player's current speed and likely displacement;
- the route length around obstacles; and
- other actors' predicted arrival times.

A slow support actor born at 2100 pixels and a fast pursuit actor born at 1200 pixels therefore
receive very different arrival times by chance. The scheduler spaces births, but it does not space
meaningful combat arrivals.

### Movement collapses angular diversity

After birth, pursuit movement is radial toward the current movement focus. Standoff roles add a
tangent only near their range band. Shared route guidance is used when blocked, not as a persistent
approach lane. The contract explicitly says logical squad anchors and centroid cohesion do not
steer ordinary movement.

Movement prediction is bounded to 1.20 seconds / 280 pixels for pursuit, 0.85 seconds / 200 pixels
for standoff, and 0.60 seconds / 140 pixels for escort/support. All ordinary continuous movement
speeds remain below the player's 280 pixels per second. A player who keeps moving can therefore
convert initially broad births into a rear-biased chase.

### Separation acts after congestion already exists

Local separation checks only actual body overlap, considers at most eight neighbors within 120
pixels, and preserves the role's original speed. It can soften a pile after it forms, but it does
not reserve distinct approach directions or arrival times.

### Causal chain

```text
balanced off-screen births
        |
        v
random raw-distance lane, not role-aware ETA
        |
        v
slower enemies aim at player or short lead
        |
        v
player continues to move faster than ordinary actors
        |
        v
many trajectories collapse into the player's wake
        |
        v
late overlap separation cannot restore tactical fronts
```

This diagnosis is high confidence at the code and contract level. The exact player-visible rear
share has not yet been measured in a replay, so the size of each contributing effect is not yet
quantified.

## Performance interaction

The prior performance study established sustained simulation overload at high enemy count. Arrival
redesign and simulation redesign are related, but they are not substitutes.

### What may improve

- Temporal arrival spacing can reduce same-frame contact, route, attack, and effect bursts.
- Multiple approach lanes can reduce body overlap and dense local-neighbor candidate sets.
- Role-aware placement can reduce long, useless transit and cleanup chases.
- Low-frequency reservations can replace some repeated reactive corrections.

### What may get worse

- Keeping more enemies near or visible around the player can move more actors into higher-frequency
  simulation and presentation bands.
- More valid firing lanes can increase projectile and line-of-sight work.
- A continuously updated formation solver would add CPU work to every actor.
- Full-sector feedback built by rescanning all enemies would repeat the current full-population-pass
  problem.

Therefore, “the enemies are less clumped, so performance will improve” is only a hypothesis. The
safe architecture is event-driven or low-frequency: maintain incremental sector/ETA counters and
make decisions at arrival allocation or a coarse director cadence. Do not add pairwise flocking.

## External precedent: adjacent games

### Directly matching failure

The clearest precedent is the developer account for *Geometry Wars 2*. The earlier behavior made
all enemies follow the player, which produced a large clump behind players who traveled in loops.
Later enemies did not simply replay the player's path, and pickups encouraged reversals. This is
strong qualitative support for changing approach intent, not merely adding more random birth
angles.

Source: [Bizarre Creations developer Q&A](https://www.gamespot.com/articles/qanda-bizarre-surveys-geometry-wars-2-aftermath/1100-6196237/).

### Combat directors and pressure budgets

- Valve's *Left 4 Dead* director separates population placement from Build, Peak, and Relax pacing,
  uses route flow and visibility, and manages an active area set. This supports explicit pacing and
  logical population ownership, but its corridor navigation does not transfer directly to an open
  vehicle field. Source: [Valve, “The AI Systems of Left 4 Dead”](https://steamcdn-a.akamaihd.net/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf).
- The GDC Adventure Director retrospective reports that random spawn sockets plus a desired
  intensity curve produced waiting for skilled players and snowballing floods for struggling
  players. The improved system compared intended pressure with observed player/world state and
  gave spawned units targets that helped them enter combat. Source:
  [GDC 2025 slides](https://media.gdcvault.com/gdc2025/Slides/Mejerwall_Marie_Growing_an_AI.pdf).
- *The Anacrusis* used path direction, player performance signals, and explicit backspawns. Its
  developers also reported that random deployments and excessive back pressure were punishing.
  Source: [AI Director 2.0 developer post](https://store.steampowered.com/news/posts/?enddate=1637079052&feed=steam_community_announcements).

These systems support feedback and planned arrival fronts. They do not support an invisible,
permanent 360-degree surround.

### Positioning, readability, and attack permission

- *God of War* used a fixed aggression-token pool and data-driven separation/position zones. The
  team also reported that a weight-heavy positioning solver became difficult to debug and was
  repeatedly invalidated. Source:
  [Santa Monica Studio GDC slides](https://ubm-twvideo01.s3.amazonaws.com/o1/vault/gdc2019/presentations/Sheth_Mihir_EvolvingCombat.pdf).
- A GDC combat-design talk recommends multiple off-screen avenues but warns that unseen rear
  spawns should be sparse because they can feel unfair. Source:
  [“Creating Conflict/Combat”](https://media.gdcvault.com/gdceurope2016/presentations/Ellis_Peter_CreatingConflictCombat.pdf).
- *Doom Eternal* deliberately uses rear spawns for 360-degree pressure, but its developer ties that
  choice to unusually strong player movement and traversal. Source:
  [developer interview](https://game.info.intel.com/gaming-access/doom-eternal-aggression-solves-every-problem).

The transferable rule is to distribute presence more broadly while separately capping actual
attack commitments and preserving an escape route.

### Horde scale and population cost

- Riot's *Swarm* uses data-driven wave location and shape while treating pathfinding, clumping,
  readability, batching, and per-object frame cost as explicit scale problems. Source:
  [Riot engineering article](https://www.riotgames.com/en/news/the-tech-behind-swarm).
- *State of Decay 2* uses active simulation areas, probabilistic off-screen populations, local
  population budgets, cooldowns, and capped per-tick queries. Source:
  [population-manager postmortem](https://www.gamedeveloper.com/design/procedurally-generating-enemies-places-and-loot-in-i-state-of-decay-2-i-).

Logical populations and object reuse can help a later performance architecture, but silently
teleporting existing enemies would damage Cardborne's spatial trust and is not recommended as the
first arrival fix.

## External precedent: unrelated domains

The cross-domain search intentionally looked for mechanisms rather than thematic similarity.

### Air traffic and road metering: schedule arrival, not release alone

FAA time-based flow management assigns crossing times at constrained points and applies spacing
where congestion exists. Ramp metering research likewise treats arrival profiles and platoon
breaking as important, while warning that a local fix can move the bottleneck downstream.

Transfer: give enemies target-relative engagement times and meter crowded approach sectors. Use
off-screen transit to absorb spacing. Do not optimize maximum throughput; combat needs readable
pressure and recovery.

Sources: [FAA TBFM guidance](https://www.faa.gov/air_traffic/publications/atpubs/foa_html/chap18_section_25.html),
[ALINEA record](https://trid.trb.org/View/365587), and
[ramp-metering evaluation](https://doi.org/10.1155/2019/8740158).

### Network scheduling: serve neglected lanes cheaply

Deficit Round Robin carries forward service owed to a queue and achieves approximate fairness with
constant work per packet. MaxWeight/backpressure selects work based on queue state. The “power of
two choices” result shows that comparing two sampled destinations can greatly improve load balance
over one random choice.

Transfer: sectors can accumulate bounded “arrival debt.” For a new arrival, compare a small number
of valid sector/ETA candidates and choose the one with lower predicted pressure or higher debt.
This avoids a global optimizer. Stale feedback and unconstrained debt can still cause oscillation
or mechanically perfect alternation.

Sources: [Shreedhar and Varghese, Deficit Round Robin](https://openscholarship.wustl.edu/cse_research/339/),
[Tassiulas and Ephremides, MaxWeight](https://drum.lib.umd.edu/items/571fda52-aefb-4497-9a2d-69d8c7c907b9), and
[Princeton notes on the power of two choices](https://www.cs.princeton.edu/courses/archive/spring13/cos521/notes/COS_521_Feb_6.pdf).

### Robotics: reserve bearings around a moving target

Target-enclosure research shows that local bearing rules, target-velocity estimates, and angular
phase spacing can distribute agents around a moving target. Moving-region coverage research adds
feed-forward motion so reservations move with the target rather than lagging behind it.

Transfer: reserve coarse angular approach gates around a predicted player position. Breakpoint:
perfect encirclement is a robotics success condition but often a game-fairness failure. Cardborne
should use incomplete, expiring reservations and leave a gap.

Sources: [local-bearing encirclement](https://doi.org/10.1016/j.automatica.2015.01.014),
[temporal spacing around moving targets](https://scholarsarchive.byu.edu/facpub/5384/), and
[feed-forward moving-region coverage](https://webdiis.unizar.es/~glopez/papers/TeruelRAS2019.pdf).

### Ecology: dispersion without an elaborate command hierarchy

Observed African wild-dog hunts did not require fixed high-level chase roles: moderate dispersion
increased encounter area and many chase attempts were short. A decentralized wolf model produced
tracking and enclosure from attraction to prey plus repulsion after a safe distance.

Transfer: independent, limited-duration approach assignments can create variety without simulating
a tactical commander for every enemy. Biological results are habitat-specific and cannot calibrate
game difficulty or fairness.

Sources: [wild-dog field study](https://doi.org/10.1038/ncomms11033) and
[decentralized wolf model](https://doi.org/10.1016/j.beproc.2011.09.006).

### Crowd flow: more pressure can produce less useful flow

Crowd experiments observe self-organized lanes, oscillatory bottlenecks, and faster-is-slower
effects under competitive pressure. This is negative evidence against sending every enemy through
the same direct lane or simply raising speed to break the tail.

Transfer: preserve several approach bands, use congestion as an admission warning, and avoid
high-gain corrections. Human crowd safety results do not directly predict game performance.

Sources: [counterflow experiment](https://doi.org/10.1016/j.trpro.2014.09.006) and
[competitive evacuation experiment](https://www.nature.com/articles/s41598-017-11197-x).

### Blue-noise sampling: separate events in space and time

Poisson-disk sampling enforces minimum spatial separation without producing a rigid grid. Cardborne
already applies a related idea to birth positions, but only in world-space position and recent
birth time.

Transfer: apply the rejection rule in target-relative angle and predicted engagement time. This
would stop several well-separated births from turning into the same contact-time platoon. Boundary
bias and candidate starvation still require deterministic relaxation tiers.

Source: [Bridson, fast Poisson-disk sampling](https://www.cs.ubc.ca/~rbridson/docs/bridson-siggraph07-poissondisk.pdf).

## Common-answer baseline

These obvious answers were recorded before divergent exploration so they would not be mistaken for
novel options.

| Common answer | Useful part | Why it is insufficient alone |
|---|---|---|
| Random off-screen ring | Cheap variety | Already constrained more carefully than this; random births still converge after movement. |
| Equal eight-sector births | Broad initial coverage | This is the current canonical rule and does not preserve engagement angles. |
| More forward spawns | Counters a fast moving player | Repeating only the forward sector creates a new front clump and can punish forward travel. |
| Faster enemies | Shortens transit | Changes difficulty, increases collision pressure, and can worsen congestion. |
| Stronger player lead | Improves interception | All enemies can converge on the same future point and form another clump. |
| Fixed ring formation | Maintains surround | Looks artificial, can remove escape space, and invites continuous solver cost. |
| Despawn and respawn rear enemies | Removes cleanup tails | Breaks spatial trust and changes population semantics. |

## Frozen candidate portfolio

The following candidates were generated in three rounds before ranking. They remain in the ledger
even when they are not part of the first recommendation.

### Round 1: direct changes to the current pipeline

| ID | Candidate | Mechanism | Main risk |
|---|---|---|---|
| D1 | Role-aware engagement ETA | Select birth distance and time from role speed, band, route estimate, and player motion instead of a hashed raw-distance lane. | Prediction error when the player reverses sharply. |
| D2 | Angular debt scheduler | Coarse sectors gain debt while underrepresented in predicted engagement; new reservations repay debt with bounded randomness. | Oscillation or visibly mechanical alternation. |
| D3 | One-shot approach gate | Give each incoming enemy a stable waypoint near a reserved engagement sector; release it to existing role movement after crossing the gate or timeout. | Bad gates around obstacles; extra transit state. |
| D4 | Spatiotemporal blue noise | Reject candidates too close in angle and predicted engagement time, not only world position and birth time. | Candidate starvation at high load. |

### Round 2: direct game-design precedents

| ID | Candidate | Mechanism | Main risk |
|---|---|---|---|
| G1 | Authored pattern vocabulary | Rotate readable crescents, split fronts, crossing streams, shallow pincers, and rotating gaps within existing windows. | Too many patterns can obscure cause and effect. |
| G2 | Terrain-flow avenues | Select two or three valid approach corridors from field geometry, visibility, and route flow instead of forcing all eight sectors every window. | Field-specific authoring and coverage gaps. |
| G3 | Arrival permission plus attack tokens | Separate presence, engagement entry, and attack permission so a broad crowd does not create simultaneous damage. | Actors may look passive if cues are weak. |
| G4 | Stable off-screen quadrant memory | Keep an existing unseen actor in a stable world-space approach assignment; do not silently move it to repair balance. | Slow recovery from a poor assignment. |

### Round 3: distant-domain transfers

| ID | Candidate | Mechanism | Main risk |
|---|---|---|---|
| X1 | Sector ramp metering | Release queued arrivals more slowly only for predicted congested sectors, with a bounded wait override. | Moves pressure later and can extend a stage. |
| X2 | Power-of-two candidate choice | Sample two valid sector/ETA options and choose the less loaded one using incremental counters. | Local choice may miss a globally better pattern. |
| X3 | Expiring partial phase slots | Give only a small subset of incoming actors coarse angular slots around a moving target; leave at least one gap and expire slots. | Can still look like a ring if overused. |
| X4 | Logical population shell | Keep far-off cohorts as cheap logical records and materialize them at a reserved approach boundary. | Large architecture and product-semantics change; not a first fix. |

## Comparison after portfolio freeze

Scores are qualitative implementation hypotheses, not measured results.

| Candidate | Tail reduction | Tactical variety | Fairness/readability | Runtime cost | Contract change |
|---|---:|---:|---:|---:|---:|
| D1 Role-aware engagement ETA | High | Medium | High | Low | Medium |
| D2 Angular debt scheduler | High | Medium | Medium–High | Low | High |
| D3 One-shot approach gate | High | High | High when telegraphed | Low–Medium | High |
| D4 Spatiotemporal blue noise | Medium–High | Medium | High | Low | Medium |
| G1 Authored pattern vocabulary | Medium | High | High | Low | High |
| G2 Terrain-flow avenues | High on supported fields | High | High | Medium | High |
| G3 Arrival permission plus attack tokens | Low alone | Medium | High | Low | Medium |
| G4 Stable quadrant memory | Medium | Medium | High | Low | Medium |
| X1 Sector ramp metering | Medium | Medium | Medium | Low | High |
| X2 Power-of-two candidate choice | Medium–High | Medium | Medium–High | Very low | Medium |
| X3 Expiring partial phase slots | High | High | Medium | Low–Medium | High |
| X4 Logical population shell | Medium | Medium | Medium | Potentially high benefit | Very high |

## Recommended design direction

### 1. Change the unit of scheduling

Replace “pick a birth sector and distance” with “reserve an engagement sector and ETA, then derive a
safe birth.” Keep birth geometry validation, cues, deterministic seeds, and existing role counts.

An engagement reservation should contain only compact values:

- target-relative sector;
- intended engagement-time bucket;
- role/family;
- approach gate or corridor identifier;
- expiry/fallback time; and
- cue identity.

It should not own the enemy's whole movement behavior.

### 2. Use role-aware arrival math

Use each role's continuous speed and desired range band to estimate transit. Favor nearer or more
forward gates for slow support/standoff actors. Fast pursuit actors can absorb longer or lateral
routes. The goal is not simultaneous arrival: deliberately distribute ETAs inside and across
windows.

Player prediction must be bounded and confidence-aware. When player speed is low or the path turns
sharply, fall back toward the current position and wider time buckets rather than continuously
retargeting every gate.

### 3. Maintain sector debt incrementally

Track reserved and engaged counts per coarse target-relative sector and ETA bucket. Update counters
on reservation, gate completion, expiry, death, and removal. Do not rebuild the table by scanning
every active enemy each physics tick.

Use bounded debt or a power-of-two comparison to select among valid candidates. Exact equality is
not the objective. Preserve noise and allow authored asymmetry.

### 4. Preserve a readable escape corridor

The director should seek varied pressure, not total enclosure. At least one meaningful movement
corridor should stay less committed during ordinary play. Rear pressure should be conditional,
telegraphed, and less frequent than side/front pressure unless a deliberate authored beat says
otherwise.

Attack-commit caps remain the final safety boundary. Presence in a sector must not imply immediate
permission to fire, charge, or body-block.

### 5. Add a small authored pattern vocabulary

Use constrained patterns as a layer over the allocator, not a replacement for geometry checks.
Candidate families include:

- broad crescent with one open side;
- two offset side streams;
- shallow pincer with delayed second arm;
- forward screen plus sparse rear interrupter;
- rotating gap across successive windows; and
- terrain-gate pair with a late cross-stream.

Each pattern must specify cueing, escape intent, eligible roles, fallback behavior, and maximum
simultaneous attack commitments. Avoid an opaque bag of unrestricted random shapes.

### 6. Keep the director cheap

The first implementation should run when allocating an arrival window or at a coarse cadence only
when reservations become invalid. Candidate counts must be fixed and small. Avoid:

- all-pairs separation or flocking;
- continuous optimal-position scoring for every enemy;
- per-frame route recomputation for all reservations;
- teleporting active unseen enemies; and
- a new full-enemy scan for every sector decision.

## Suggested first experiment

The smallest coherent prototype is **D1 + D3 + X2**, with a minimal G1 pattern set:

1. Calculate role-aware ETA for the existing allocator candidates.
2. For each unit, compare two valid sector/ETA candidates using incremental reservation counts.
3. Assign a one-shot approach gate around a bounded predicted player position.
4. Release to the existing pursuit/standoff/escort/support behavior at the gate or timeout.
5. Test two readable patterns: broad crescent and two offset streams.
6. Preserve current counts, cues, spawn safety, attack caps, and deterministic replay.

This prototype directly addresses the diagnosed transition from birth to engagement without first
introducing a global optimizer, entity teleportation, or a new population model.

## Measurement and falsification plan

Before changing behavior, add observation-only telemetry to a deterministic run. Sample at a coarse
cadence and retain aggregates rather than writing per-enemy logs every physics tick.

### Player-experience measures

- share of engaged enemies in the rear hemisphere relative to player velocity;
- target-relative sector histogram and largest empty angular gap;
- time from cue and birth to first meaningful engagement;
- arrivals entering the engagement shell per fixed time bucket;
- number of distinct active approach directions;
- duration of uninterrupted one-direction tail states;
- attacks, charges, and denial effects committed simultaneously; and
- time spent cleaning up distant stragglers.

### Performance measures

- physics p50/p95/p99 and displayed-frame pacing;
- active, visible, near-600, and near-900 populations;
- spawn-decision and approach-gate CPU time;
- overlap-neighbor candidates and route-guidance requests;
- line-of-sight and hostile-projectile work;
- rejected allocation candidates and delayed reservation backlog; and
- peak births and meaningful engagements per time bucket.

### Fairness guardrails

- no untelegraphed birth or attack in immediate danger range;
- no perfect-surround objective during ordinary play;
- a measurable escape corridor during normal windows;
- stable off-screen assignments rather than silent repositioning;
- unchanged attack-commit limits unless separately approved; and
- deterministic fallback when geometry cannot satisfy a pattern.

The hypothesis fails if rear-tail duration does not materially improve, if the new system merely
moves the clump to a future intercept point, if escape space collapses, or if higher near-player
activity worsens frame pacing beyond the benefit from lower burst/overlap work.

## Contract and validator impact

An implementation would intentionally conflict with parts of the current canonical contract:

- canonical windows currently must use all eight sectors;
- the moving-player rule may change only the first sector's order;
- 600/900 occupancy is telemetry only and cannot control admission, holding, detours, or despawn;
- logical squad anchors and cohesion cannot steer movement; and
- high density near the player is an allowed convergence result.

The existing multi-sector validator locks the all-eight-sector rule. Any implementation therefore
needs an explicit product-spec decision and revised validators. It must not be hidden as an
allocator optimization.

Likely affected responsibilities in a future implementation are:

- `VehicleSpawnAllocator`: derive safe births from engagement reservations;
- `VehicleEncounterRuntime`: own reservation lifecycle and incremental counts;
- enemy targeting/movement policy: consume a bounded approach gate before normal role behavior;
- presentation: show directional intent only if existing cues are insufficient;
- validators: assert ETA spacing, escape corridors, deterministic fallback, and role behavior; and
- profilers: correlate engagement distribution with the established frame-time metrics.

## Decision summary

The cause is clear enough to justify a targeted prototype: Cardborne balances object births but
does not own the moving player's later engagement distribution. The solution direction is also
clear: schedule role-aware approach sectors and engagement times, keep an escape gap, and then hand
actors back to their current combat roles.

What remains uncertain is calibration, not mechanism. A deterministic replay and observation-only
baseline must quantify the current rear bias and confirm whether spatial/temporal spreading reduces
bursts without increasing near-player simulation cost. The dense-simulation architecture work from
the companion performance report is still required for the high-count frame-time failure.
