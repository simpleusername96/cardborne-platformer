---
type: plan
status: active
owner: BK
created: 2026-07-24
last_reviewed: 2026-07-24
scope: Implement three enlarged persistent run-level fields, unified wall truth, six functional field-feature families, startup-selective Breach Shot interrupts, avoidable mines, additional and elite enemy roles, distinct bosses, a debug-only boss-practice harness, visual guidebook entries, Ship Status, and per-stage combat reports
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../vehicle-world-combat-expansion-evidence.md
  - ../vehicle-difficulty-meta-progression-decision-study.md
  - ./2026-07-23-vehicle-performance-architecture-stabilization.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
---

# Vehicle World and Combat Expansion ExecPlan

## Purpose

The current build is a playable five-stage vehicle shooter, but its physical
field and boss encounters do not yet communicate enough meaningful decisions.
All functional terrain from the earlier multi-map campaign was deleted during
the shared-field rebuild. The surviving field draws several nonfunctional floor
motifs, while impassable boundaries and internal cover use inconsistent visual
language. The one-second opening shot has numeric bonuses but no exclusive job.
Mines punish only the player, the guidebook is text-only, and the five bosses
mostly reuse the same runtime attack grammar.

This plan expands the game without reversing the persistent-field decision or
raising the active-enemy capacity. After completion, a new run selects one of
three `7200x4320` authored field layouts and keeps it for all five stages and
retries. Every solid boundary has one visual and collision truth. Environmental
terrain affects both sides, while three explicitly player-owned field
facilities provide traversal, bounded recovery, and exposed-position damage
advantages. The opening shot becomes a precision Breach Shot whose job is to
open protected or priority targets after the player naturally stops firing to
move or evade. Its first direct hit can cancel an explicitly interruptible
attack startup, but it never creates idle stun-lock and cannot erase an attack
that has already committed. Each boss exposes only one interruptible signature
attack while committed and autonomous systems preserve pressure. Mines, new
roles, deterministic elite traits, and five distinct bosses create learnable
combat interactions. A debug-only practice surface reuses those exact bosses
for QA without touching progression. The guidebook shows what discovered
threats actually look like, paused Settings shows the current build, and every
stage ends with a combat report.

## Scope

### In scope

- Three total, same-theme `7200x4320` field layouts selected once per new run.
- A unified static-wall and boundary-rail contract.
- Complete removal of decorative map motifs.
- Flow Channel, Arc Surge Strip, Breakable Bulkhead, Transit Gate, Repair
  Basin, and Overdrive Field features.
- Breach Shot behavior, presentation, localization, and counterplay.
- One-shot friendly-fire stationary mines and active mobile minelets.
- Two additional non-projectile enemy roles plus the existing unused Minelet.
- Three deterministic, shape-distinct elite traits with fixed per-stage counts.
- Three-phase, stage-specific boss behaviors and silhouettes.
- A debug/editor-only Boss Practice setup and session that reuse the production
  field, boss runtime, telegraphs, attacks, and presentation.
- Visual guidebook previews and concise counterplay hints.
- A read-only Ship Status page in Settings with effective stats and acquired
  upgrades.
- A Stage Report after every cleared stage with per-archetype defeats and
  outgoing damage contribution.
- A localized incoming-damage recap and partial combat report on failure.
- Canonical product/design documentation, Korean/English localization, focused
  validation, production Web export, and rendered evidence.
- Performance evidence inside the current declared capacity envelope.

### Non-goals

- A different physical map per stage.
- A fourth field or runtime procedural topology.
- A new game engine, dependency, renderer, raster asset pack, or shader.
- Raising the `72` ordinary-enemy active cap or projectile capacities.
- New currencies, base stage, exploration puzzles, meta progression, equipment
  repair, or an expanded pickup taxonomy.
- Redesigning card-offer progression, prerequisites, or difficulty selection;
  only the three existing opening-family card effects are revised with Breach.
- A player-facing boss-rematch progression mode or rewards from Boss Practice.
- A run-risk contract, optional reward-triggered encounter, or repeated version
  of the same stage. The unresolved difficulty/meta-progression study owns that
  separate decision.
- Enemies that steal, carry, delete, or deny experience.
- Generic Breach stun, stagger accumulation, or idle/move-state hit reactions.
- More than one interruptible signature attack per stage boss, adjacent
  interruptible boss patterns, or cancellation of committed/autonomous attacks.
- Rebalancing all existing enemy health and damage.

## Success Criteria

- A seeded new run selects one of three fields, and its field ID, collision,
  terrain, cover selection, and explored minimap remain coherent through all
  five stages.
- No decorative floor motif remains, and a player can identify every
  impassable static boundary solely from the shared wall fill, rail, and shadow.
- Flow Channels and Arc Surge Strips visibly match their exact simulation and
  create intentional interactions with both the player and enemies. Transit
  Gates, the Repair Basin, and the Overdrive Field remain unmistakably
  player-owned facilities with exact visible footprints, bounded benefits, and
  no hidden collision.
- Breach Shot turns natural firing downtime into one precision opportunity to
  break protection, cancel one readable startup, or expose a priority target.
  It has reliable bulkhead, mine, armor, ordinary-startup, priority-enemy,
  boss-signature, and boss-recovery interactions without replacing held fire as
  the best sustained damage or creating a repeatable stun-lock.
- Mines are readable one-shot state machines, can damage enemies, cannot damage
  through walls, trigger before the player enters their blast radius, are
  escapable without dash, and never lose quota or XP attribution.
- Spark Minelets and the two new roles add stage-by-stage decisions without
  raising the active enemy or projectile envelope.
- Stages contain exactly `1/2/3/4/5` elite replacements, never more than two
  live at once; each trait reads from silhouette as well as color and adds no
  projectile count.
- Each of the five bosses has a distinguishable silhouette, three behavioral
  phases, exactly one interruptible signature, committed direct pressure,
  autonomous system pressure, one unique spatial mechanic, and one
  base-speed-avoidable final exam.
- Every discovered enemy, boss, mine, and terrain entry has a matching visual
  preview and concise Korean/English counterplay; locked entries leak nothing.
- Paused Settings shows the current effective ship stats and every acquired
  upgrade from gameplay-owned values rather than UI-side calculations.
- Every stage report shows actual enemy defeats and applied-health-damage share
  by attack unit; failure shows the same partial data plus incoming causes.
- Debug/editor Boss Practice can launch every boss, phase, and individual
  pattern on every registered field, can restart without a run, and can never
  grant rewards, discovery, completion, or persistent state.
- Focused validators, production Web export, rendered UI/UX evidence, and all
  active performance gates pass.

## Locked Assumptions and Constraints

- Godot `4.7` stable and GDScript remain the implementation platform.
- Korean remains the default language and every new user-facing string has
  complete Korean and English entries.
- Manual aim, held primary fire, one-second idle priming, dash, passive
  secondaries, EMP, five-stage flow, card upgrades, field bosses, and stage
  bosses remain intact.
- One run uses one immutable field topology through all stages and retries.
- `7200x4320`, center `(3600,2160)`, camera zoom `1`, `560 px` center
  clearance, and a `20x12` exploration grid are common field contracts.
- The Sunken Ceramic Fresco palette and flat-color, large-shape style remain.
- A passable floor overlay may use semantic colors, but every solid static
  obstacle uses the same ceramic-green wall base and common shadow.
- Visual geometry does not become collision authority. One compiled field
  snapshot feeds collision, navigation, projectile clipping, minimap, and
  presentation.
- Environmental motion and damage affect the player and eligible enemies.
  Transit, Repair, and Overdrive are explicitly player-owned facilities and
  never masquerade as neutral environmental terrain.
- No attack added by this plan requires dash. From the first damaging warning
  frame, base movement speed has a valid escape route with at least `40 px`
  margin.
- The active performance ExecPlan remains authoritative for frame, draw-call,
  lifecycle, and soak thresholds. This plan may not bypass or relax it.

## Current State and Evidence

The full audit is in
`../vehicle-world-combat-expansion-evidence.md`. Implementation must preserve
these facts:

- Historical current and storm hazards existed in commit `278be30` and were
  removed by `cb40059`; they are not present in the current runtime.
- `drowned_ruin_field.gd` owns four decorative motifs with no gameplay.
- collision is currently composed from the walkable union, water, selected
  covers, and live crates, but those blockers do not share one rendered wall
  language;
- the current opening shot cannot cross the `35` boss stagger threshold;
- ordinary attacks expose readable `startup` phases but carry no
  interruptibility metadata, while the generic `stun` field stops ordinary
  enemies regardless of whether they were attacking;
- every current boss pattern enters `boss_startup`, so a phase-only interrupt
  rule would incorrectly make every boss attack cancellable;
- attack telegraphs carry exact geometry and continuous `readiness` but no
  color-independent interruptible/committed/autonomous classification;
- Forked Muzzle level 1 currently places two projectiles on opposite sides of
  the aim axis, and every projectile inherits the current `opening` flag, so no
  unique center interaction owner exists;
- the stationary mine is repeatable and damages only the player;
- `spark_minelet` exists in data and visuals but is unused by stage role sets;
- current populations already reach `420` authored enemies and `72` active
  ordinary enemies;
- the current `5600x3400` pursuit grid contains `59x36 = 2124` cells per
  actor-radius contract, while the accepted `7200x4320` field contains
  `75x45 = 3375`; enlarging the map therefore requires retained packed buffers
  and bounded multi-tick rebuilds rather than a larger per-frame dictionary
  traversal;
- the existing capture harness can already prepare every stage boss, but no
  interactive practice session, phase/pattern selection, or reward isolation
  owner exists;
- the guidebook snapshot contains no preview metadata;
- Settings has four configuration-only tabs and no run-build data;
- stages 1–4 advance without a report, and no current runtime records
  per-archetype defeats or outgoing damage by source; and
- boss pattern names vary, but several kinds share generic execution.

## Accepted Product Design

### 1. Run-level field selection

Add exactly three registered field definitions:

| Field ID | Spatial identity | Environmental emphasis | Persistent rule |
| --- | --- | --- | --- |
| `drowned_ruin_field` | Open central plaza, four broad outer courts, north/south loops | One Flow Channel, one Arc Surge Strip, two Breakable Bulkheads | Selected once and kept for stages 1–5 and retries |
| `tidal_archive_field` | Two broad lateral halls joined by three crossings and one central court | Two Flow Channels, one Arc Surge Strip, two Breakable Bulkheads | Same |
| `storm_drydock_field` | Large center basin with two wide perimeter loops and four diagonal approaches | One Flow Channel, two Arc Surge Strips, two Breakable Bulkheads | Same |

Each definition must provide:

- the common `7200x4320` world rectangle and `(3600,2160)` center;
- at least twenty broad walkable regions;
- exactly thirty-two ordinary spawn candidates;
- exactly twelve boss arrival anchors;
- twenty-four cover candidates split into six sectors, selecting exactly eight
  per run;
- at least thirty-two item sockets;
- six stationary-enemy candidate groups, selecting exactly four per stage;
- one environment/facility blueprint containing the field's locked feature
  counts;
- a `560 px` empty center;
- no corridor narrower than `320 px`;
- no dead-end pocket shorter than `480 px`;
- two vertex-disjoint routes from center to every outer court after selected
  cover and intact bulkheads are applied; and
- terrain/facility zones that do not overlap the center clearance, spawn
  anchors, boss anchors, pickup sockets, or stationary sockets.

Every field contains exactly two Transit Gate pairs, one Repair Basin, and one
Overdrive Field in addition to the environmental emphasis listed above. The
four gates occupy four different outer sectors. Each pair crosses at least
`2800 px` of straight-line distance, and no single pair is the only route to a
court.

Ordinary encounter arrivals are selected from valid anchors between `1000` and
`1800 px` from the player and outside the camera rectangle expanded by `220 px`.
If fewer than two anchors satisfy the preferred ring, select the nearest valid
off-camera anchors in deterministic distance/ID order. Boss arrivals use valid
anchors between `900` and `1500 px`, remain at least `240 px` outside the
viewer, and preserve one base-speed route toward the player. This keeps the
larger world from turning combat into off-screen travel without changing
population, quota, or the `72` active cap.

`field_id` is derived deterministically from the layout seed with a stable
`field:v1` sub-seed. Add a `--field-id=<id>` debug override. Deployment shows
the selected localized field name as read-only context. The selected ID and
compiled layout remain in `VehicleFieldLayout` through all stage transitions
and stage restarts; only a new run may choose again.

The `96 px` pursuit grid is exactly `75x45`. Replace Dictionary-owned reverse
costs with one preallocated `PackedByteArray` walkability buffer and one
preallocated `PackedInt32Array` cost/queue set for each `36 px` and `76 px`
radius contract. A rebuild processes at most `1024` cells per physics tick,
keeps the prior complete field active until the new field is ready, and swaps
the completed buffer atomically. Player-cell changes coalesce into the newest
pending target; the boss-radius field updates only while a boss is live.
Bulkhead destruction invalidates both radius buffers once. No enemy performs an
individual path search, and player-only Transit Gates are not navigation edges
for enemies.

### 2. One wall truth and zero motifs

Delete the motif contract completely:

- remove `motifs` from field definitions and required catalog fields;
- delete `_motifs()` and the four motif draw functions;
- delete motif colors/constants from the visual profile;
- remove motif assertions from validators and canonical specifications; and
- do not leave disabled motif data or presentation branches.

Introduce a compiled `VehicleFieldGeometrySnapshot` owned by the field-layout
pipeline. It exposes immutable:

- walkable polygons;
- selected static-cover rectangles;
- live breakable-bulkhead rectangles;
- wall boundary segments/loops;
- water/background polygons;
- terrain zones;
- navigation occupancy;
- spawn, boss, item, and stationary sockets.

The shared wall presentation contract is:

| Token | Locked value |
| --- | --- |
| `WALL_FILL` | Existing ceramic green |
| `WALL_SHADOW` | Existing deep cobalt shadow |
| `WALL_RAIL_WIDTH` | `48 px` |
| `WALL_SHADOW_OFFSET` | `(0, 12)` |
| static cover/bulkhead base | Same fill, rail, and shadow |
| collision-only color variants | None |

Derive wall boundary loops from the merged walkable union. Draw the `48 px`
rail centered on the physical boundary, so its floor-side edge lies `24 px`
inside the floor and matches the base ship-center clearance. Fill internal
solid islands with `WALL_FILL` and the same shadow. A cobalt outside/water mass
may remain behind the field but may never be the only visual sign of collision.
Any nonwalkable internal hole is either filled as a wall island or enclosed by
the identical rail. No decorative line, motif, floor-tone change, or water
color may imply collision when none exists.

The snapshot is the only source consumed by:

- player and enemy movement;
- pursuit/navigation;
- player and enemy projectile clipping;
- line of sight;
- backdrop drawing;
- minimap static geometry; and
- layout validators.

### 3. Functional terrain and facility contract

Add exactly six initial field-feature families. Field features are authored in
field data and executed by one low-count `VehicleTerrainRuntime`; they do not
create one node per zone or actor. Flow, Arc Surge, and Breakable Bulkhead are
environmental terrain. Transit, Repair, and Overdrive are visually distinct
player-owned facilities. That category boundary is part of the guidebook and
visual language: neutral terrain can affect both teams, while a mint/mustard
facility benefits only the player and never pretends to be a neutral hazard.

#### Flow Channel

| Rule | Locked behavior |
| --- | --- |
| footprint | Passable rectangle or polygon at least `320 px` wide |
| player | Adds a `72 px/s` world-space vector after input acceleration and before collision resolution |
| ordinary mobile enemy | Receives the full `72 px/s` vector |
| boss | Receives `36 px/s` |
| stationary enemy | Unaffected |
| projectiles | Unaffected |
| visual | One muted mint/cobalt strip and three large ivory chevrons; no repeating micro-pattern |
| discovery | First camera visibility unlocks the guidebook object entry |

The same vector applies continuously while an actor center is inside the exact
visible footprint. Collision still resolves against the same compiled wall
snapshot, so a current cannot push an actor through a wall.

#### Arc Surge Strip

| Rule | Locked behavior |
| --- | --- |
| cycle | `5.2 s` |
| warning | `1.4 s` |
| active | `0.8 s` |
| player damage | `10` once per active window |
| ordinary-enemy damage | `18` once per active window |
| boss damage | `6` once per active window |
| stationary enemy | Takes the ordinary-enemy value |
| visual | Exact violet boundary, continuous warning fill from `0%` to `100%`, then one active flash |
| discovery | First camera visibility unlocks the guidebook object entry |

One actor cannot be hit twice by the same strip in one active window. Damage is
environmental, participates in the normal accepted-hit feedback, and records
the strip as a damage source. A player-triggered mine explosion may overlap a
surge, but each source resolves independently.

#### Breakable Bulkhead

| Rule | Locked behavior |
| --- | --- |
| count | Exactly `2` per field |
| health | `72` structure |
| blocking | Movement, navigation, line of sight, and both projectile teams |
| visual base | Identical `WALL_FILL`, rail, and shadow |
| state hint | One large mustard fracture glyph; no alternate wall fill |
| normal fire | Deals normal structure damage |
| Breach Shot | Deals exactly `72` structure and breaks an undamaged bulkhead in one hit |
| persistence | Broken through later successful stage transitions in the same run; reset on a stage restart/replay or new run |
| placement | Never required for center-to-court connectivity |

The bulkhead has `intact`, `breaking`, and `broken` states. `breaking` lasts
`0.18 s`, disables collision on the same simulation tick as health reaches
zero, and emits only bounded fragments/effects from the existing effect batch.
It drops no item and grants no experience.

#### Transit Gate

| Rule | Locked behavior |
| --- | --- |
| count | Exactly two bidirectional pairs (`A` and `B`) per field |
| footprint | `96 px` circular activation footprint |
| activation | Player center remains inside for `0.35 s`; leaving cancels progress |
| destination | The paired center, with velocity cleared and hull/aim direction preserved |
| cooldown | `10.0 s` shared by both ends of the used pair |
| arrival protection | `0.45 s` normal damage invulnerability; no attack, dash, or movement lock |
| enemies/projectiles | Never transported or redirected |
| visual | One large paired ivory bracket and cobalt/mint fill; activation and cooldown use the same exact outer circle |
| minimap | Discovering either end reveals both ends and their common `A` or `B` shape |

Every destination requires a `260 px` static safe circle and `360 px` clearance
from ordinary, boss, and stationary spawn sockets. A roaming enemy may still
enter the area; the short arrival protection prevents an unreadable immediate
hit without turning the gate into permanent safety. The cooldown prevents
invulnerability cycling. Gates never create connectivity required by layout
validation, so disabling them cannot strand the player.

#### Repair Basin

| Rule | Locked behavior |
| --- | --- |
| count | Exactly one per field |
| footprint | `150 px` circular support footprint |
| start | Player remains inside for `0.50 s` |
| healing | `4` hull per second, player only |
| budget | `24` hull per stage; full health consumes nothing |
| interruption | Taking accepted hull damage pauses healing for `1.0 s` |
| reset | Budget resets on stage start/restart, not when leaving the zone |
| visual | Six large mint reservoir segments disappear as budget is spent |

The Basin grants no invulnerability and does not heal barriers or enemies. It
has `280 px` clearance from static cover and `360 px` from spawn/stationary
sockets, leaving it exposed rather than creating a safe bunker. Depletion turns
off the mint fill but leaves the known ceramic base and minimap marker.

#### Overdrive Field

| Rule | Locked behavior |
| --- | --- |
| count | Exactly one per field |
| footprint | `180 px` circular support footprint |
| player effect | `1.20x` player-owned enemy-health damage while the player center is inside |
| excluded damage | Structures, neutral environmental damage, and damage already owned by an enemy |
| stacking | Multiplies independently with target-side effects such as Breach Exposed |
| enemies | Receive no buff |
| visual | One mustard sun mass and a continuous exact boundary; no repeated floor pattern |

The damage check reads the player's zone membership when each damage event is
applied, including secondary and status ticks. The field has `320 px` cover
clearance and two validated base-speed approaches. It is deliberately exposed:
the player may hold the advantage only while accepting converging pressure.

Transit progress/cooldown, Repair budget/pause, and active Overdrive membership
use large shape changes on the ground and one compact status-orbit icon. They
add no persistent HUD text. Their first camera visibility unlocks matching
guidebook entries.

At most three functional feature footprints may intersect a normal gameplay
viewer at once. This is a readability constraint, not a simulation shortcut.

### 4. Breach Shot

Rename the user-facing “opening shot” to `Breach Shot` / `돌파탄`. Its baseline
still primes automatically after exactly `1.0 s` without primary fire and
consumes the primed state on the next primary shot. Existing card modifiers may
shorten that baseline only through the established
`opening_seconds_multiplier`; this plan adds no second charge timer.

Its combat identity is **priority opening and conditional interrupt**, not
generic burst damage or generic crowd control. Held fire remains the correct
answer to an already exposed target. The player earns a Breach Shot while
naturally ceasing fire to dash, cross the field, evade a committed attack, or
reacquire aim; the next precise shot converts that downtime into an opportunity
to remove protection, cancel one readable attack preparation, or focus a
high-value target. Waiting only to repeat Breach against an unprotected target
must always lose sustained damage to uninterrupted held fire.

Use these final modifiers:

| Property | Breach value |
| --- | --- |
| health damage | `1.85x` base primary damage |
| structure damage | `4.0x`, equal to `72` at the current base |
| radius | `1.75x`, equal to `12.25 px` at the current base |
| pierce | `+1` |
| successful interrupt stop | `0.45 s` `interrupted_recovery` |

Its exclusive jobs are:

- break a full-health Breakable Bulkhead in one hit;
- force an Arc Mine into its `0.75 s` short fuse;
- remove a full-health Bulkhead Guard front plate or Armored elite shell in one
  hit;
- cancel one explicitly interruptible ordinary or boss attack before it
  commits;
- apply `Breach Exposed` to one unprotected priority enemy when no interrupt
  occurs; and
- apply the same exposure during a boss's natural recovery window.

The center projectile owns one Breach interaction token. Its first direct enemy,
mine, plate, shell, bulkhead, or structure contact consumes that token. The
projectile may continue through its remaining pierce with the same health
damage, radius, and normal elemental-stack application, but consumption clears
its token, Breach visual, Shock Breach/opening-capstone ownership, and resets
remaining structure damage to the unprimed center-shot value. It therefore
cannot interrupt, expose, short-fuse, or one-shot a second structure. Forked
Muzzle side projectiles, Shock Breach splash, Flashover splash, passive
secondaries, reflected damage, and status ticks never receive an interrupt
token. The center projectile's first-contact structure damage is never reduced
below `72` by Forked Muzzle's per-projectile falloff. This keeps Breach one
precision decision even after multishot, pierce, or area upgrades.

Forked Muzzle must always preserve one projectile on the exact aim axis. Keep
its current total shot counts and total neutral direct-damage scales:

| Forked Muzzle level | Projectile layout and neutral scales |
| --- | --- |
| `0` | center `0° @ 1.0` |
| `1` | center `0° @ 1.0`, one side `±7° @ 0.40`; side alternates left/right by shot serial |
| `2` | center `0° @ 1.0`, sides `-7°/+7° @ 0.325` each |

These totals remain `1.0/1.4/1.65`, matching the current
`1x1.0/2x0.70/3x0.55` neutral output. On a primed trigger, only the center
projectile receives Breach health/radius/structure/pierce, the first-contact
token, Shock Breach ownership, and Flashover/Shatter opening resolution. Side
projectiles remain ordinary scaled primary shots and may apply their normal new
elemental stacks. Replace `VehicleProjectileState.opening` with explicit
`breach_token_available` and `breach_visual` fields; projectile-store eviction
protects only the live token owner.

Resolve the first-contact interaction in this fixed order:

1. Apply the direct hit and any structure/plate/shell damage.
2. If the target is an Arc Mine, force its short fuse and stop; a live fuse is
   not an attack startup and cannot be cancelled.
3. If the still-living target is in an explicitly interruptible startup,
   cancel only that not-yet-committed attack, clear its startup telegraphs, and
   enter `interrupted_recovery` for exactly `0.45 s`. The same hit does not
   apply `Breach Exposed`.
4. Otherwise, apply `Breach Exposed` only when the target satisfies the
   priority-enemy or natural boss-recovery rule below.
5. In every other state, deal normal Breach damage without changing phase,
   movement, timers, projectiles, zones, summons, or cooldowns.

An ordinary successful interrupt sets velocity to zero, clears only the
cancelled startup's temporary descriptors, and does not spawn its projectile,
zone, burst, charge, beam, or summon. After `0.45 s`, the target returns to
`move` with its full normal post-attack cooldown. Breach never writes the
existing generic `stun` field. The following direct attack startups are
interruptible:

| Interruptible startup | Cancelled before commit |
| --- | --- |
| `chaser`, `rammer` | charge movement and contact window |
| `shooter`, `turret`, `interceptor_tower` | the complete pending shot or pre-burst |
| `controller`, `artillery_spotter` | the pending fixed damage zone |
| `drone_carrier` | the pending child-release sequence |
| `beam_sentinel` | the pending beam |

`mine` fuse startup is short-fused rather than interrupted. Contact-only
movement, repair ticks, generator behavior, boss-pylon behavior, already active
bursts, existing projectiles, active beams, placed zones, and released summons
are never interrupted. Planned Bulkhead Guard and Splitter Barge movement
remains contact pressure without an invented Breach window.

At the commit boundary, damage resolution reads the target's current phase. If
the target is still in `startup`, the interrupt wins; once its active transition
has executed, the attack is committed and cannot be rolled back. Validators
must cover `commit - epsilon`, exact commit, and `commit + epsilon` without
depending on wall-clock timing.

`Breach Exposed` is a `1.25 s`, nonstacking `+20%` effective health-damage
window from player-owned sources. The eligible non-boss archetypes are
`repair_tender`, `drone_carrier`, `turret`, `interceptor_tower`,
`beam_sentinel`, and `generator`; one full center Breach applies exposure if no
plate/shell absorbed that shot and no interrupt occurred. Mines, neutral
structures, and reflection-locked boss pylons never receive exposure. It cannot
stack or refresh while active. For a boss, exposure can be applied only once
during each natural `boss_recovery`; it cannot be applied by an interrupting
hit and cannot refresh until the boss commits its next attack. Exposure never
changes phase, phase time, velocity, pursuit, pattern, startup, active time,
recovery time, or attack sequence. The hit may play a `0.12 s` material
crack/flash while the simulation continues.

Retire the current accumulated boss `STAGGER_THRESHOLD`, `STAGGER_WINDOW`,
`STAGGER_RECOVERY_READ`, `staggered` phase, and all damage-threshold hard-stop
transitions. The new `interrupted_recovery` state is entered only by one direct
Breach hit during metadata-approved startup; it is not a meter and cannot
accumulate. Preserve generic `stun` only for EMP and other systems that already
own explicit crowd-control behavior.

The baseline Breach has no area damage. Area clearing remains a secondary/EMP
job and is added to Breach only by the existing `shock_breach` card. Preserve
and make the current opening-family interactions explicit:

| Existing card/system | Locked Breach interaction |
| --- | --- |
| `fast_capacitor` | Prime time becomes `0.85 s` and `0.75 s` at levels 1 and 2 |
| `breach_round` | Keep the resource ID; replace `opening_breach_multiplier` with additive `breach_health_scale_bonus=[0.20,0.40]` and `breach_exposure_bonus=[0.05,0.10]`, producing center health `2.05x/2.25x` and exposure `+25%/+30%`; the `72` structure minimum remains |
| `shock_breach` | Center-token contact only; the struck target remains excluded and `90 px` impact damage is `45%` of center Breach health damage per level; splash cannot interrupt or expose |
| Flashover/Shatter | Center-token contact only; resolve against stacks already on the target before the center Breach applies its new elemental stack |

These interactions provide three build paths—faster access, stronger
single-target opening, and optional area conversion—without giving every
Breach all three jobs by default. Save-compatible IDs remain unchanged.

Presentation uses:

- every startup/world-warning descriptor receives a gameplay-owned
  `commit_mode` from `VehicleAttackContract` or `VehicleBossPatterns`;
  `VehicleAttackTelegraphBuilder` forwards it and the renderer never infers
  interruptibility from phase, role, color, or pattern name;
- a collision head exactly matching the `12.25 px` damaging radius;
- a mustard/ivory double-diamond head;
- a `48 px` tapered trail distinct from normal fire;
- a stronger muzzle flash and the existing opening-shot audio channel;
- a complete primed ring near the ship/reticle plus the existing HUD readiness
  channel;
- one large fracture bracket on a currently aimed breachable/priority target
  and one continuous crack ring during `Breach Exposed`;
- one broken-diamond bracket and telegraph-edge notch for an interruptible
  startup, a closed diamond for a committed/noninterruptible startup, and no
  boss-body bracket for an autonomous system warning;
- affinity color continues to describe attack type; interruptibility is always
  communicated by shape and never by color alone;
- a successful interrupt collapses the cancelled warning inward and plays one
  short crack/recoil cue, while a late hit leaves the committed warning intact;
  and
- a short localized guidebook counterplay line.

Held fire resumes at the existing repeat cadence after the Breach Shot. No new
input, manual charge, or firing lockout is added.

### 5. Mines affect both teams

#### Stationary Arc Mine

Replace the reusable cycle with:

`Dormant -> Armed -> Exploding -> Retired`.

| Transition or effect | Locked behavior |
| --- | --- |
| player enters `230 px` | Arms with a `1.25 s` fuse while still outside the damaging ring |
| player damage reduces health to zero | Arms or shortens the fuse to `0.75 s`; never disappears silently |
| enemy proximity alone | Does not arm the mine |
| explosion radius | `160 px`, shown exactly and separately from activation |
| center damage | `26`, linearly tapering to `45%` at the edge |
| targets | Player and every enemy except the source mine |
| boss multiplier | `0.25x` |
| ownership | Player proximity or player damage marks the mine as player-triggered; enemy casualties credit quota/XP while player damage received still names `arc_mine` |
| lifecycle | Retires after one explosion |

Render a thin `230 px` activation ring and a stronger `160 px` damage ring.
The damage ring fills continuously over the fuse and plays one spatial audio
cue on arm plus a faster cue at `75%` fuse. At the first proximity-trigger
frame, the player has a `70 px` non-damaging buffer.

Every authored stationary-mine center requires `260 px` clearance from static
walls, live bulkheads, crates, and terrain footprints, plus `360 px` from
another stationary mine. This leaves the complete trigger ring on walkable
floor and proves a base-speed reverse route without dash. A mine hit by another
mine does not explode in the same frame. It is armed with at least `0.80 s`
remaining fuse, inherits the originating player trigger, and one explosion may
arm at most six other mines in deterministic distance order.

#### Mobile Spark Minelet

Activate the existing archetype from stage 2 onward:

- trigger radius `160 px`;
- fuse `1.0 s`;
- explosion radius `100 px`;
- center damage `14`;
- same all-team damage and ownership rules;
- no ranged projectile;
- no more than twelve live minelets; and
- no more than six may be in `Armed` state simultaneously.

An armed Minelet stops and locks its explosion position, leaving a `60 px`
buffer at first trigger. Mine explosions stop at neither ordinary enemies nor
the player, but they do not pass through static walls: exposure is checked
against the same line-of-sight/wall snapshot before damage.

### 6. Enemy variety inside the existing capacity

Do not change current authored stage populations, quotas, or the `72` active
ordinary-enemy cap in this plan. Activate the existing Spark Minelet and add
two roles:

| Role | Base contract | Tactical decision | Capacity rule |
| --- | --- | --- | --- |
| Bulkhead Guard | `90` health, `140 px/s`, `24 px` radius, melee; frontal plate has `72` structure and blocks frontal health damage | Reposition around it or use one primed Breach Shot to remove the plate | Maximum `8` live |
| Splitter Barge | `96` health, `120 px/s`, `26 px` radius, melee | Control space before it dies and splits | Maximum `6` live; spawns exactly two summon-only Scrap Drones when capacity permits |

Splitter children do not add quota or experience and use the existing summon
capacity. No more than twelve splitter children may be live. If capacity is
full, missing children are skipped rather than queued.

Roll out the mechanics as:

| Stage | New lesson | Combination |
| --- | --- | --- |
| 1 | Flow, Repair Basin, and one Armored elite | Mine friendly fire appears in an authored low-pressure packet; Breach removes the first elite shell |
| 2 | Spark Minelet and Transit Gates | Flow changes minelet approach vectors; gates teach long-distance repositioning |
| 3 | Bulkhead Guard and Overdrive Field | Arc Surge and guard positioning compete with the exposed damage zone |
| 4 | Prior roles in denser authored combinations | Guard, Minelet, support, ranged pressure, and two live elites may combine |
| 5 | Splitter Barge and all prior roles | Terrain, facilities, support, melee, ranged, and elite roles combine under the existing cap |

Projectile-firing ordinary roles remain no more than `50%` of active ordinary
enemies. Minelet, Guard, and Splitter are non-projectile roles. No role may
target, move, consume, store, destroy, or suppress experience shards.

#### Elite replacements

Elites are a bounded modifier on an eligible existing unit, not a new spawn
family and not an extra enemy. Add `elite_trait` to enemy state and one
`VehicleEliteTraitCatalog`; the encounter coordinator replaces the next
eligible unit when a fixed quota-progress threshold is crossed.

| Stage | Exact elite count | Quota-progress thresholds |
| --- | --- | --- |
| 1 | `1` | `55%` |
| 2 | `2` | `42%`, `72%` |
| 3 | `3` | `35%`, `60%`, `82%` |
| 4 | `4` | `30%`, `48%`, `66%`, `84%` |
| 5 | `5` | `24%`, `39%`, `54%`, `69%`, `84%` |

Eligible base archetypes are `chaser`, `shooter`, `controller`,
`shield_escort`, `artillery_spotter`, and `rammer`. Swarms, priority/support
units, stationary units, summoned children, field bosses, and stage bosses are
never modified. An elite reservation waits for the next eligible authored unit
and never creates an extra spawn. Exactly two elites may be live at once; a
pending reservation waits until a slot opens. Each elite counts as one defeat,
uses the base role's threat family, and grants `1.5x` its base experience
rounded up.

Add exactly three one-trait-only variants:

| Trait | Simulation | Shape language and counterplay |
| --- | --- | --- |
| `armored` | Adds a fixed `72`-structure shell before health; difficulty does not scale the shell | Two large ivory split plates; normal fire can break them, one full center Breach removes them |
| `overclocked` | `1.15x` movement speed and `0.85x` attack cooldown; never adds a projectile or removes a tell | Two mustard rear fins and one pulsing outer bracket; preserve distance and clear it before pressure compounds |
| `heavy` | `1.35x` health, `1.15x` collision/visual radius, `0.90x` speed, and `1.15x` contact/committed-melee damage; only melee base roles are eligible | One enlarged ceramic-green body mass and broad ivory core; kite the slow footprint |

Stage 1 always reserves `armored` as the first tutorial elite. Later traits use
the layout/encounter seed, rotate without an immediate repeat, and apply at most
one trait. Difficulty and stage curves apply to base stats before the elite
multiplier; the Armored shell remains fixed so Breach behavior is identical on
Easy, Normal, and Hard. Elite modifiers never add an elemental affinity,
projectile penetration, projectile-wall bypass, or hidden attack.

The renderer composes the trait geometry with the existing base mesh so
silhouette, not recolor alone, communicates the variant. The minimap uses one
hollow diamond around the normal enemy marker. First contact unlocks one
guidebook entry per trait using a neutral chassis plus the exact trait geometry,
without leaking an unseen base archetype. Stage Report keeps one row per base
archetype and adds a localized secondary count such as `정예 1 / 1 Elite`
instead of multiplying rows.

### 7. Five distinct boss exams

Extract boss state and execution from `VehicleRun` into a dedicated
`VehicleBossRuntime`. Keep data-owned pattern definitions under `scripts/bosses`
and keep presentation dependent only on a boss snapshot.

#### Shared boss rules

- Three phases: phase 1 above `65%` health, phase 2 from `65%` through `30%`,
  phase 3 below `30%`.
- Between committed attacks, the boss pursues or repositions toward its
  stage-specific preferred range. Normal hits never stop movement or attack
  timers.
- Phase sequence gaps are `0.55 s`, `0.42 s`, and `0.32 s`.
- Every direct attack retains its authored startup tell; every autonomous
  system owns an independent world warning. Phase escalation comes from
  combinations and reduced dead time, not removed warning.
- No immediate attack repeat.
- Phase 2 may layer one low-reaction space-control pattern with one direct
  response pattern.
- Phase 3 has one fixed authored combo per boss.
- Light hits remain `20–22`, standard hits `26–30`, and heavy hits `32–36`.
- Every exact damaging footprint is visible from startup through impact.
- Target position/direction locks when the warning first appears and does not
  chase the player afterward.
- Base movement has a valid escape route with at least `40 px` margin.
- Boss projectile reserve remains at most `24`.
- Every pattern declares exactly one `commit_mode`:
  `interruptible_signature`, `committed`, or `autonomous`.
- Each boss owns exactly one `interruptible_signature`; it appears at most once
  in a four-pattern direct cycle and never follows another signature.
- A center Breach during that signature's `boss_startup` cancels only the
  not-yet-committed signature, clears its startup telegraphs, and enters
  `boss_interrupted_recovery` for `0.45 s`. The boss then enters the normal
  phase-specific `boss_read` gap, and its next direct pattern must come from the
  `committed` pool.
- The interrupting Breach does not apply `Breach Exposed`. A Breach during
  movement, read, committed startup, active time, autonomous warning, or
  interrupted recovery deals damage without changing boss state.
- Projectiles, zones, mines, pylons, summons, and system layers that already
  exist continue after an interrupt. No cleanup path may infer ownership from
  the boss's changed phase.
- Autonomous systems are scheduled and telegraphed independently of the boss
  body. They continue while the boss pursues, uses a direct attack, recovers,
  or has its signature interrupted.
- One Breach Shot during recovery may apply `Breach Exposed` once per committed
  attack, but never pauses or retimes the boss.
- A health-threshold phase transition preserves excess damage and outranks an
  interrupt caused by the same hit: the boss enters its normal phase-transition
  read without an additional `0.45 s` stop.

#### Stage-specific identities

| Boss | Interruptible signature | Committed direct pressure | Autonomous system pressure | Phase-3 exam |
| --- | --- | --- | --- | --- |
| Foundry Colossus | `foundry_ram`: locked charge | `furnace_gates`: two slow projectile walls with one `180 px` gap | `slag_ring` and two `overload_pylons` | Furnace Gates establish the gap; Foundry Ram crosses it, but interrupting the ram does not erase the moving gates |
| Archive Leviathan | `archive_lunge`: locked pursuit burst | `current_fan`: slow gapped fan | `undertow_lanes` and three fixed `depth_charges` | Undertow moves the player while three fixed Depth Charges demand route choice; neither depends on a body cast |
| Drydock Titan | `titan_pulse`: radial ring plus one aimed pair | `grounding_grid`: two warned Arc strips with one safe lane | `thunder_chain` and a bounded `beam_sentinel_call` | Grounding Grid activates before Titan Pulse; interrupting the pulse leaves the grid active |
| Switchyard Behemoth | `ricochet_volley`: one fully warned bounce path | `breaker_charge`: locked forward line | four one-shot `switchyard_mines` and two fixed `switch_sweeps` | Mines arm first, then autonomous sweeps leave one base-speed route through them |
| Crown Engine | `carrier_wave`: one carrier and two escorts released on commit | `mirror_cross`: direct cross pressure | `crown_lattice` and timed `relay_pulse` rings | `royal_overload` combines lattice lanes with concentric timing; interrupting a later Carrier Wave cannot clear either layer |

The interruptible signature always reads as a deliberate boss-body wind-up. A
committed direct attack may also animate the body but uses the closed-diamond
contract and must be dodged. An autonomous system warning originates from its
world emitter or exact footprint rather than a cancellable boss-body motion.
All three modes remain fully telegraphed; “autonomous” never means invisible,
instant, or detached from exact damage geometry.

Give every boss a distinct `boss_variant` mesh in
`VehicleCombatVisualLibrary`, using large flat-color masses and no micro-detail:

- Colossus: broad furnace shoulders;
- Leviathan: long split prow;
- Titan: square grounded core;
- Behemoth: forward breaker wedge; and
- Crown Engine: radial crown frame.

The same variants appear in combat, minimap boss markers, guidebook previews,
and boss HUD labels. Pattern affinity still controls effect color; silhouette
does not recolor to communicate collision.

#### Debug-only Boss Practice

Boss Practice is a QA harness, not a player progression mode. It is available
only when `OS.is_debug_build()` is true and is absent—not merely disabled—from
release deployment and production Web UI. A secondary
`보스 연습 / Boss Practice` action on debug deployment opens one modal with:

- one of the five stage bosses;
- one of the three registered fields;
- start phase `1`, `2`, or `3`;
- `전체 전투 / Full Fight` or `패턴 반복 / Pattern Loop`;
- one exact pattern from that boss with its signature/committed/autonomous
  shape label when Pattern Loop is selected; and
- `피해 무시 / Invulnerable` off by default.

The full-fight session uses normal boss health, phase transitions, pursuit,
attacks, wall collision, terrain, telegraphs, and failure. Pattern Loop fixes
boss health at `80%`, `50%`, or `20%` for phases 1–3. Signature and committed
patterns run their selected startup, active, and recovery unchanged.
Autonomous patterns run their independent warning, active, and lifetime while
the boss remains in production pursuit/read behavior. A successful signature
interrupt follows the production `boss_interrupted_recovery` path. After the
selected lifecycle completes or is interrupted, the session removes only
payload IDs registered to that practice iteration, waits `1.5 s`, and starts it
again. It does not reset player position between loops. The invulnerable option
still resolves accepted-hit visuals and incoming telemetry but clamps hull to a
minimum of `1`; it never suppresses attack collision.

Practice starts the player at field center and the boss at the nearest valid
boss anchor between `1000` and `1400 px` from center. It creates no ordinary
encounter packets except summons/pylons owned by the selected boss pattern.
Pause contains `연습 재시작 / Restart Practice`,
`설정으로 / Practice Setup`, and `배치 화면으로 / Deployment`. Defeat offers
the same three actions. A small shape-plus-text `연습 / PRACTICE` label is the
only persistent QA indicator; boss HUD and pattern state remain the production
presenters.

Practice owns a temporary `VehicleBossPracticeSession`. It reuses the exact
`VehicleBossRuntime`, field snapshot, combat stores, attack telegraphs, renderer,
audio, and HUD snapshot. It cannot:

- grant experience, cards, clear count, module unlocks, guidebook discovery, or
  Stage Reports;
- read or write `user://vehicle-run.cfg`;
- change the preferred run difficulty;
- append production run telemetry; or
- enter the normal five-stage progression state machine.

Support the same harness without UI through debug-only arguments:

```text
--boss-practice=stage_1
--practice-field=drowned_ruin_field
--practice-phase=1
--practice-pattern=full
--practice-invulnerable
```

`--practice-pattern=<pattern_id>` selects Pattern Loop. Unknown boss, field,
phase, or pattern values print one error and exit nonzero in headless mode;
interactive debug runs return to the practice modal with a localized error.
This command path is the deterministic owner for per-pattern screenshots and
performance evidence.

### 8. Visual guidebook and learning aids

Add a reusable `VehicleGuidebookPreview` `Control`. It receives preview metadata
and draws the exact mesh from `VehicleCombatVisualLibrary`; it does not create
or load portrait images.

Unlocked enemy and boss entries contain:

- `preview_archetype` and optional `boss_variant`;
- one `176x176` desktop preview with a `128x128` minimum;
- localized Movement, Attack, and Counter rows;
- the same broken-diamond, closed-diamond, or autonomous-emitter shape beside
  any described attack mode; and
- no raw health, speed, damage, quota, or hidden spawn data.

Locked entries show:

- the existing `???` name;
- one neutral generic silhouette not derived from the hidden archetype;
- no description, category count leak, color leak, or counterplay text.

Add object entries for:

- Flow Channel;
- Arc Surge Strip;
- Breakable Bulkhead;
- Transit Gate;
- Repair Basin;
- Overdrive Field;
- Arc Mine; and
- Armored, Overclocked, and Heavy elite traits.

Each object preview is one large semantic diagram: flow chevrons, surge timing
fill, fracture glyph, paired gate, six-segment reservoir, sun field, trait
shell/fins/body, or armed mine ring. Discovery occurs when the object first
enters the camera-expanded viewer or the player interacts with it. The existing
guidebook persistence store records the ID. Facility diagrams use their exact
combat shapes. Elite diagrams use one neutral chassis so a discovered trait
never reveals an unseen base archetype.

The guidebook remains a modal focus layer. Verify Korean and English text,
keyboard/gamepad focus order, locked/unlocked states, reduced motion, and no
clipping at every supported size. The first discovered interruptible attack
adds one concise legend entry:
`깨진 마름모: 돌파탄으로 준비 취소 / Broken diamond: Breach cancels startup`.
The legend also shows a closed diamond as “committed—evade” and an
emitter-centered mark as “system attack—disable or evade”; it never relies on
affinity color to communicate interruptibility.

### 9. Ship Status in Settings

Add a first Settings tab named `기체 현황 / Ship Status`. Keep the existing
Audio, Controls, Gameplay, and Language tabs after it. The tab is read-only and
contains no controls that can mutate the run.

Create one gameplay-owned `VehicleBuildSnapshotBuilder` and one reusable
`VehicleBuildSummaryPanel`. The builder reads `VehicleRunBuild`, primary,
secondary, cycle, experience, player, dash, and EMP runtime values and emits a
deep immutable snapshot only when:

- a run starts or restarts;
- an upgrade is applied;
- Settings or the guidebook is about to open; or
- a stage report is finalized.

Do not build the snapshot every HUD frame. The same summary panel and snapshot
feed the Settings Ship Status tab and the guidebook Ship entry, preventing two
different stat calculations.

Ship Status shows:

| Group | Visible values |
| --- | --- |
| Run | difficulty, stage, level, experience/current requirement, hull/current maximum |
| Movement and defense | effective move speed, dash distance and cooldown, hit invulnerability, active barrier, lifesteal, pickup radius |
| Primary | applied base damage per center projectile, shots per second, projectile count, speed, radius, pierce, bounce |
| Breach Shot | current prime time, health damage, first-contact structure damage, radius, pierce, `0.45 s` interrupt recovery, eligible startup rule, boss exposure duration and bonus |
| EMP | effective cooldown, startup, radius, and damage |
| Secondaries | every installed family, level, effective damage, interval/tick, radius/range, and family-specific count |
| Acquired upgrades | localized title, current/max level, family, and current localized effect description |

Sort acquired upgrades by the fixed family order `primary`, `element`,
`secondary`, `mobility`, `defense`, `skill`, then stable catalog ID. Do not show
unacquired upgrades on this page. Values are formatted from gameplay units:
damage as an integer when exact, time in seconds, speed in `px/s`, rates in
shots/ticks per second, and percentages with at most one decimal.

The Settings surface is used from deployment, pause, and garage. During an
active paused run it shows the live snapshot. Outside a run it keeps the tab
visible and shows one localized empty state—`진행 중인 런이 없습니다 / No run
in progress`—without stale values. Opening Settings from pause keeps the tree
paused, makes the cursor visible, and returns focus to the Settings button on
close.

### 10. Stage Report and outgoing damage attribution

Add `VehicleStageTelemetry`, a compact attempt-scoped data owner. It contains
bounded dictionaries keyed by stable `StringName` IDs and records:

- actual player/environment-caused defeats by enemy archetype;
- elite defeats by trait, nested under the defeated base archetype;
- actual applied enemy-health damage by attack source; and
- incoming applied hull damage by source for failure learning.

It does not allocate one event object per hit, update UI during combat, retain
enemy references, or scan the live enemy array. Reset stage counters at stage
start/restart and freeze one immutable snapshot at stage completion. Append only
confirmed cleared-stage snapshots to `completed_stage_reports`; a manual stage
restart discards its current counters. Final-run totals are derived from the
completed snapshots, plus the current partial snapshot only on failure, so a
restarted attempt is never counted twice.

Use these outgoing attack-source families:

| Source ID | Includes |
| --- | --- |
| `primary` | normal center/side shots, pierce, and ricochet direct damage |
| `breach` | Breach direct damage and Shock Breach |
| `passive_seeker` | passive seeker direct and burst damage |
| `ion_field` | Ion Field ticks |
| `orbit_blades` | Orbit Blade contacts |
| `wake_mines` | player secondary Wake Mine damage |
| `escort_drone` | Escort Drone fire |
| `emp` | EMP and EMP Aftershock |
| `dash` | Dash impact and its upgrade effects |
| `burn` | burn damage over time |
| `poison` | poison damage over time and Contagion |
| `elemental_burst` | Flashover and Shatter burst damage |
| `reflected_shot` | reflected hostile projectiles |
| `arc_mine` | player-triggered world Arc Mine damage to enemies |
| `arc_surge` | Arc Surge environmental damage to enemies |
| `other` | validated fallback; never an internal function or node name |

Migrate outgoing damage calls and projectile/secondary state to carry one stable
source ID. Do not infer reporting groups by parsing display strings. Record the
actual value returned by `_damage_enemy` after modifiers and overkill capping.
The damage denominator is effective enemy-health damage only; it excludes
crates, Breakable Bulkheads, Guard plate structure, invulnerable hits, and
overkill. Status damage remains its own visible source so elemental upgrades
are measurable.

Record a defeat only when `_defeat_enemy` resolves an actual combat death.
Include ordinary, stationary, summoned, field-boss, and stage-boss archetypes;
mark summoned rows with a localized secondary label. Do not count enemies
silently retired during stage cleanup. Sort defeat rows by count descending,
then stable archetype ID.

After the boss reward is confirmed, change the flow to:

`boss reward -> freeze Stage Report -> player confirms Continue -> next stage`.

Stage 5 uses:

`boss reward -> Stage Report -> Continue -> final run result`.

The new `RunMode.STAGE_REPORT` stops simulation, hides the live HUD, clears
carried combat input, shows the cursor, and owns focus. It cannot be closed with
Escape into gameplay. The single primary action is
`다음 스테이지 / Continue` for stages 1–4 and
`최종 결과 / Final Result` for stage 5. It becomes enabled after `0.35 s` to
reject the carried reward-confirm input.

The report displays:

- stage number, localized title, clear time, and remaining hull;
- `40x40` shared combat silhouettes, localized enemy names, and actual defeat
  counts, with a secondary `정예 N / N Elite` count when nonzero;
- attack-source icon/name, actual applied damage, and percentage of total; and
- a total-damage row.

On `1280x720` and wider, defeats and damage use two aligned columns. At
`960x540`, the same modal uses two keyboard-accessible tabs, `처치 / Defeats`
and `피해 / Damage`, inside one vertical scroll region. Show at most eight
damage rows; fold the remainder into localized `기타 / Other`. Calculate
tenths-of-a-percent with largest-remainder allocation so visible percentages
sum to exactly `100.0%`. When total damage is zero, show `—` instead of a
percentage.

### 11. Failure report and incoming damage recap

Before the existing Garage transition, `RunMode.FAILURE_REPORT` uses the same
panel in failure mode and shows the current partial Stage Report plus a compact
localized learning block:

- `마지막 피해 / Last hit`: source display name and amount;
- `가장 큰 피해원 / Top damage sources`: at most three source names with
  percentages for the completed attempt.

Sources are stable semantic IDs such as `arc_surge`, `arc_mine`,
`boss_foundry_ram`, `enemy_contact`, and `enemy_projectile`; they do not expose
internal node names. Reset the accumulator at the start of every attempt.
Environmental friendly-fire kills remain attributed correctly for quota and XP,
but the player's recap records only damage received by the player.

The failure report stops simulation, cannot close back into gameplay, and has
one primary `격납고로 / Continue to Garage` action with the same `0.35 s`
carried-input guard. Neither report adds live-HUD text.

## Ownership and File Boundaries

| Responsibility | Existing owner or new owner | Must not absorb |
| --- | --- | --- |
| Immutable field definitions and authored sockets | `scripts/vehicle/stages/*_field.gd` | Runtime timers, actor mutation, UI |
| Field registry and compiled collision snapshot | `vehicle_stage_catalog.gd`, `vehicle_field_layout_generator.gd`, `vehicle_field_layout.gd`, new `vehicle_field_geometry_snapshot.gd` | Boss rules, guidebook copy |
| Terrain/facility definitions and low-count execution | new `scripts/vehicle/vehicle_terrain_catalog.gd`, `vehicle_terrain_runtime.gd` | Backdrop drawing, enemy rendering, per-zone nodes |
| Static field presentation | `vehicle_stage_backdrop.gd`, `vehicle_stage_visual_profile.gd` | Collision decisions |
| Primary and Breach Shot state | `scripts/player/vehicle_primary_weapon.gd` and run-build modifiers | UI layout, bulkhead lifecycle |
| Attack metadata and interrupt classification | `scripts/combat/vehicle_attack_contract.gd`, `scripts/bosses/vehicle_boss_patterns.gd` | Runtime mutation, telegraph styling |
| Ordinary attack phases and cancellation | performance-plan owner `VehicleEnemyRuntime` in new `scripts/enemies/vehicle_enemy_runtime.gd`, using `vehicle_enemy_specialist_runtime.gd` constants | Boss state, structures, card logic |
| Enemy definitions and specialist behavior | `vehicle_enemy_archetypes.gd`, `vehicle_enemy_specialist_runtime.gd` | Boss state, stage flow |
| Elite trait values and deterministic assignment | new `scripts/enemies/vehicle_elite_trait_catalog.gd`, encounter coordinator | Base-role behavior, renderer geometry, quota inflation |
| Mine and enemy lifecycle | enemy runtime/store plus bounded query services | Guidebook discovery |
| Boss direct/system data and state | `vehicle_boss_patterns.gd`, new `vehicle_boss_runtime.gd` | General enemy store, HUD controls, duplicated system cleanup |
| Debug practice lifecycle and argument validation | new `scripts/bosses/vehicle_boss_practice_session.gd`, new `scripts/ui/vehicle_boss_practice_panel.gd` | Duplicate boss attacks, persistence, rewards |
| Shared telegraphs/meshes/batched presentation | `vehicle_attack_telegraph_builder.gd`, `vehicle_combat_visual_library.gd`, `vehicle_combat_renderer.gd` | Gameplay damage, collision, or inferred interrupt rules |
| Guidebook metadata/persistence/UI | `vehicle_guidebook_catalog.gd`, `vehicle_guidebook_store.gd`, `vehicle_guidebook_panel.gd`, new preview control | Enemy behavior |
| Effective build snapshot | new `scripts/presentation/vehicle_build_snapshot_builder.gd` | Gameplay mutation, card application, settings persistence |
| Reusable Ship Status UI | new `scripts/ui/vehicle_build_summary_panel.gd`, `vehicle_settings_panel.gd`, guidebook composition | Stat calculation or card behavior |
| Combat telemetry | new `scripts/combat/vehicle_stage_telemetry.gd`, stable source IDs carried by damage/projectile state | Encounter scheduling, live UI updates |
| Stage/failure report UI | new `scripts/ui/vehicle_stage_report_panel.gd`, `vehicle_stage_ui.gd` | Damage calculation, enemy lifecycle |
| Orchestration only | `vehicle_run.gd` | New catalogs, per-role algorithms, or presentation geometry |

Move the existing ordinary attack functions
`_update_ordinary_enemy`, `_start_enemy_attack`, `_begin_enemy_active`,
`_update_enemy_active`, and `_enemy_recovery_cooldown` into
`VehicleEnemyRuntime`. Move `_update_stage_boss`, `_boss_select_pattern`,
`_boss_begin_active`, `_boss_update_active`, `_boss_reposition`, and
`_boss_combat_move` into `VehicleBossRuntime`. `VehicleRun` retains only
service callbacks and ordered orchestration; implementation must not add the
new interrupt or autonomous-system branches back to that orchestrator.

## Tasks

### Milestone 0 — Baseline, authority, and extension budgets

- [ ] Run the current focused vehicle validators and Web export before edits;
      save results under ignored `build/evidence/world-combat-expansion/baseline/`.
- [ ] Capture deterministic standalone and Web `1280x720` performance scenarios
      using the active performance plan's recorder.
- [ ] Record current guidebook, all five bosses, current motifs/walls, and one
      complete Stage 1 run at `1280x720`.
- [ ] Add the accepted contracts in this plan to
      `docs/product/vehicle_game_spec.md` and `docs/design/UI_VISUAL_SYSTEM.md`
      before gameplay code.
- [ ] Add a short implementation progress entry to this plan after every
      milestone without changing locked product decisions.

**Exit condition:** baseline evidence exists, canonical docs agree with this
plan, and no performance threshold was relaxed.

### Milestone 1 — Field registry and unified wall geometry

- [ ] Introduce the three-field registry and deterministic `field:v1`
      selection with `--field-id`.
- [ ] Expand all registered definitions to the locked `7200x4320` rectangle,
      `(3600,2160)` center, and exact anchor/socket/candidate counts.
- [ ] Make `VehicleFieldLayout` retain `field_id`, field definition, compiled
      geometry, terrain blueprint, and persistent bulkhead state.
- [ ] Replace global single-field caches in `VehicleStageCatalog` and layout
      generation with field-keyed immutable caches.
- [ ] Author and validate `tidal_archive_field` and `storm_drydock_field`.
- [ ] Compile merged walkable boundaries and one wall snapshot consumed by
      movement, projectiles, LOS, navigation, minimap, and backdrop.
- [ ] Replace full-grid Dictionary pursuit costs with the locked `75x45`
      preallocated buffers, `1024`-cell multi-tick rebuild, atomic swap, and
      boss-live radius policy.
- [ ] Change explored minimap sampling from `16x10` to `20x12`, preserving
      square `360x360 px` world cells and field-keyed static geometry.
- [ ] Enforce the locked player-relative ordinary and boss arrival rings so the
      larger field does not lower on-screen encounter pressure.
- [ ] Remove all motif data, rendering, profile constants, localization copy,
      validators, and canonical references.
- [ ] Render every boundary and solid island with the locked shared wall
      material, rail, and shadow.
- [ ] Preserve the chosen field across stages/restarts and preserve broken
      bulkheads across successful stage transitions; a stage restart/replay
      restores its bulkheads.

**Acceptance:**

- every field passes player-radius, ordinary-radius, and boss-radius
  connectivity;
- every field is exactly `7200x4320`, has thirty-two ordinary anchors, twelve
  boss anchors, thirty-two item sockets, and the locked cover/stationary pools;
- all required sockets are reachable and clear;
- every blocked pixel boundary has the shared wall rail;
- no visually open slit rejects a `24 px` player;
- no rendered motif remains;
- stage transitions never change `field_id`; and
- field selection is deterministic for a fixed seed;
- minimap exploration uses `20x12` square world cells; and
- pursuit rebuild work never exceeds `1024` visited cells in one physics tick
  and never clears the last complete field before replacement.

### Milestone 2 — Functional terrain, facilities, and Breach Shot

- [ ] Add typed terrain definitions and one centralized runtime.
- [ ] Implement Flow Channel for player, ordinary mobile enemies, and bosses
      with wall-safe movement.
- [ ] Implement Arc Surge warning, one-hit-per-window damage, all-team
      interaction, and source attribution.
- [ ] Implement persistent Breakable Bulkheads using the same wall snapshot.
- [ ] Implement the two Transit Gate pairs, exact dwell/cooldown/arrival
      contract, paired discovery, and debug snapshots.
- [ ] Implement the stage-budgeted Repair Basin and accepted-hit pause.
- [ ] Implement Overdrive membership and damage-source ownership exclusions.
- [ ] Complete the active performance plan's selected
      `VehicleEnemyRuntime` extraction before adding Breach behavior: it owns
      ordinary `move/startup/active/recovery/interrupted_recovery` transitions
      at the already accepted decision and simulation cadences.
- [ ] Rename and rebalance the opening shot as Breach Shot.
- [ ] Add exact Breach visuals, readiness feedback, audio use, KR/EN copy, and
      guidebook metadata.
- [ ] Add one first-contact Breach token to the center projectile and consume it
      deterministically across structure, mine, interrupt, and exposure
      resolution; side/pierced/splash/status hits never duplicate the token.
- [ ] Recenter Forked Muzzle with the locked alternating/symmetric layouts and
      `1.0/1.4/1.65` neutral totals; retire projectile `opening` in favor of
      explicit token/visual fields and keep opening capstones center-only.
- [ ] Add ordinary attack interruptibility metadata, exact `0.45 s`
      cancellation recovery, full post-attack cooldown, and the locked
      noninterruptible exclusions without writing generic `stun`.
- [ ] Add the bulkhead/armor one-shot, priority `Breach Exposed`, conditional
      boss-signature interrupt, and natural boss-recovery exposure contracts;
      retire accumulated boss hard-stagger state and constants.
- [ ] Preserve the existing `fast_capacitor`, `breach_round`, `shock_breach`,
      Flashover, and Shatter IDs while applying the locked, nonredundant Breach
      interactions.
- [ ] Remove the retired `opening_breach_multiplier` stat ID and update card,
      snapshot, localization, and validation ownership to the two locked
      additive Breach Round modifiers.
- [ ] Preserve the Breach contract under every existing primary-projectile,
      charge-time, pierce, and status upgrade combination.
- [ ] Add terrain discovery events without per-frame deep guidebook snapshots.

**Acceptance:**

- terrain footprints match simulation exactly;
- currents never alter projectiles or push actors through walls;
- each surge hits an actor no more than once per active window;
- surge damage can kill enemies with deterministic ownership;
- every gate pair crosses at least `2800 px`, preserves aim, clears velocity,
  shares one `10.0 s` cooldown, and cannot transport enemies/projectiles;
- Repair heals no more than `24` hull per stage, pauses after an accepted hit,
  and consumes no budget at full hull;
- Overdrive applies exactly `1.20x` only while the player center is inside and
  never changes structure or neutral-environment damage;
- one full Breach Shot breaks a full-health bulkhead;
- Forked Muzzle and other existing upgrades cannot remove the center
  projectile's Breach interaction;
- Forked Muzzle levels emit the exact locked angles/scales, preserve current
  neutral total damage, and produce exactly one center Breach token;
- normal primary fire can eventually break a bulkhead;
- one full Breach removes an Armored elite shell or Guard plate;
- one Breach against an unprotected priority target applies one nonstacking
  exposure window only when that hit did not interrupt an attack;
- one direct center Breach during each listed ordinary startup cancels the
  attack before payload creation, stops the target for `0.45 s`, then applies
  its full post-attack cooldown;
- the same hit during move, idle, active, ordinary recovery, an existing mine
  fuse, or an unlisted behavior causes no phase or velocity change;
- the first direct contact consumes the only special interaction even when the
  projectile continues through its extra pierce;
- one Breach in boss recovery applies one `1.25 s` exposure window without
  changing boss movement, timers, phase, or attack;
- uninterrupted held fire remains higher sustained damage than intentionally
  waiting to re-prime against an unprotected, status-free target;
- baseline Breach has no area damage, while `shock_breach` owns its bounded
  `90 px` conversion;
- broken bulkheads remain broken through later successful stages and reset on a
  stage restart/replay; and
- no terrain/facility creates a required path narrower than `320 px`; and
- at most three field-feature footprints intersect a normal viewer.

### Milestone 3 — Mines and additional enemy roles

- [ ] Convert stationary mines to one-shot fuse state machines.
- [ ] Apply mine damage to player and enemies with wall occlusion.
- [ ] Implement player-caused short fuse, deterministic bounded chain arming,
      quota, XP, and damage-source attribution.
- [ ] Enforce the `230/160 px` stationary and `160/100 px` Minelet
      activation/damage-ring contracts plus authored clearance.
- [ ] Activate Spark Minelets from stage 2 within their locked caps.
- [ ] Implement Bulkhead Guard plate ownership and Breach counterplay.
- [ ] Implement Splitter Barge children inside summon capacity.
- [ ] Add the three elite trait definitions, exact `1/2/3/4/5` reservation
      schedule, eligible-role filter, two-live limit, fixed shell, and rounded
      experience multiplier.
- [ ] Compose elite silhouette geometry and hollow-diamond minimap treatment in
      the existing retained presentation path; do not create role-by-trait
      duplicate meshes.
- [ ] Update authored encounter packets to the locked teach-combine-test rollout
      without changing active/population envelopes.
- [ ] Preserve the `<=50%` ordinary projectile-role share.

**Acceptance:**

- mines retire after one explosion;
- approaching or destroying a mine produces the correct fuse;
- a proximity-triggered mine leaves the player outside the damage ring and a
  base-speed reverse route clears it without dash;
- stationary mine placement has the locked wall/terrain/mine clearance;
- an armed Minelet stops, locks its position, and leaves the player outside its
  damage ring on the first trigger frame;
- enemy proximity alone does not arm a mine;
- explosions cannot hit through a wall;
- at most six chain mines arm per source explosion;
- quota/XP attribution is correct for approach-triggered and shot-triggered
  explosions;
- no enemy behavior reads or mutates experience shards;
- splitter children never increase quota/XP and never exceed cap;
- elites replace authored eligible units, count once, never change quota or the
  `72` active cap, and meet every stage's exact count;
- no more than two elites are live, every elite has exactly one trait, and
  Stage 1's first elite is Armored;
- every trait remains distinguishable in monochrome silhouette and adds no
  projectile or hidden affinity;
- one full Breach always removes a full Armored shell on every difficulty;
- every new role uses local/bounded queries; and
- the active cap remains `72`.

### Milestone 4 — Boss runtime, five distinct exams, and practice QA

- [ ] Extract the boss state machine and attack execution from
      `vehicle_run.gd` into `VehicleBossRuntime`.
- [ ] Replace the two-phase reorder with the locked three-phase sequence model.
- [ ] Add mandatory `commit_mode` metadata and implement each named signature,
      committed direct pattern, autonomous system, and exact telegraph
      footprint in the boss table above.
- [ ] Schedule autonomous systems independently from boss-body
      `boss_startup/active/recovery`; retain their own low-count warning,
      lifetime, cleanup owner, and damage attribution.
- [ ] Ensure pursuit/repositioning continues after normal hits and outside
      committed attacks.
- [ ] Implement the one-signature-per-boss Breach cancellation,
      `boss_interrupted_recovery`, committed next-pattern guard, and natural
      recovery-only `Breach Exposed`; remove the old accumulated boss
      hard-stagger transitions.
- [ ] Add five unique boss meshes/variants and reuse them in combat, minimap,
      HUD, and guidebook.
- [ ] Keep projectile reserve at or below `24` and add bounded summon handling.
- [ ] Add deterministic pattern fixtures for each phase and combo.
- [ ] Add `VehicleBossPracticeSession` and the debug-only deployment/setup,
      full-fight, pattern-loop, pause, failure, and exit flows.
- [ ] Parse and validate the locked debug practice arguments without mixing
      them into capture/performance request ownership.
- [ ] Route practice through the exact production boss runtime, field snapshot,
      combat stores, telegraphs, renderer, audio, and HUD while hard-isolating
      persistence, rewards, discovery, reports, and production telemetry.

**Acceptance:**

- every boss reaches and executes every phase deterministically;
- normal hits never freeze boss movement or attack timers;
- a Breach hit stops a boss only during its one metadata-approved signature
  startup and only for the locked `0.45 s` recovery;
- the interrupting shot grants no `Breach Exposed`, the next direct pattern is
  committed, and a phase-threshold hit does not add interrupt downtime;
- Breach during read, movement, committed startup, active, autonomous warning,
  interrupted recovery, or an already spawned payload never freezes, deletes,
  pauses, or retimes that behavior;
- every boss cycle contains exactly one nonadjacent signature attack;
- no immediate pattern repeats;
- all warnings stop tracking after lock;
- warning and damage geometry are identical;
- autonomous layers remain fully warned and continue through a signature
  interrupt without depending on a boss-body animation;
- every pattern and phase-three combo is escapable at base speed with `40 px`
  margin;
- damage remains inside the locked light/standard/heavy bands;
- each boss creates a different spatial decision, not only a different color;
- all five variants are visually distinguishable in monochrome silhouette; and
- boss capacity does not exceed the current projectile/summon envelope;
- every boss/field/phase/pattern combination starts from the debug UI and
  command path with the selected exact production behavior;
- Pattern Loop runs the selected direct or autonomous production lifecycle,
  cleans only its iteration-owned temporary objects, waits `1.5 s`, and repeats
  without moving the player;
- practice accepted hits remain visually testable with invulnerability enabled;
- practice cannot alter save bytes, difficulty preference, guidebook discovery,
  clear count, rewards, or normal run telemetry; and
- release deployment and production Web contain no Boss Practice control or
  argument activation path.

### Milestone 5 — Combat telemetry and Ship Status

- [ ] Add stable outgoing and incoming damage-source IDs to gameplay state;
      remove report grouping by display-string parsing.
- [ ] Add `VehicleStageTelemetry` with stage/reset/run-total lifecycle and
      bounded source/archetype dictionaries.
- [ ] Record only actual applied enemy-health damage after modifiers and
      overkill capping.
- [ ] Record actual combat defeats by archetype without counting stage cleanup.
- [ ] Record elite trait counts under the base-archetype defeat row without
      creating one telemetry key for every role/trait combination.
- [ ] Add `VehicleBuildSnapshotBuilder` using gameplay-owned effective values.
- [ ] Add reusable `VehicleBuildSummaryPanel`.
- [ ] Add the first Settings `Ship Status` tab, its paused-run snapshot, and its
      no-run empty state.
- [ ] Reuse the same summary panel/snapshot in the guidebook Ship entry.
- [ ] Add complete Korean/English stat labels, units, upgrade names, levels, and
      current effect descriptions.

**Acceptance:**

- every direct, secondary, elemental, reflected, mine, and surge damage path
  records one stable source ID and its exact applied damage;
- percentages exclude overkill, neutral structures, and invulnerable hits;
- stage restart resets stage counters while a successful transition freezes the
  prior snapshot and preserves run totals;
- no telemetry owner stores enemy references or allocates one object per hit;
- Settings shows gameplay-equal effective values after every upgrade;
- all acquired upgrades appear once with current/max level and effect;
- outside a run, Ship Status shows only the localized empty state;
- Settings remains paused, scroll-safe, keyboard-operable, and returns focus;
  and
- the guidebook and Settings cannot disagree because they consume the same
  immutable build snapshot.

### Milestone 6 — Guidebook previews and stage/failure reports

- [ ] Extend guidebook snapshots with nonleaking preview and counterplay
      metadata.
- [ ] Add `VehicleGuidebookPreview` using shared mesh geometry.
- [ ] Add unique boss, enemy, mine, and terrain object previews.
- [ ] Add exact facility and neutral-chassis elite-trait previews.
- [ ] Add Movement, Attack, and Counter rows in Korean and English.
- [ ] Preserve neutral locked silhouettes and `???` without hidden metadata.
- [ ] Add discovery triggers for terrain and new roles.
- [ ] Add `RunMode.STAGE_REPORT`, report snapshot freezing, and the
      reward-report-next-stage/final-result transitions.
- [ ] Add `VehicleStageReportPanel` with defeat and outgoing-damage views,
      responsive two-column/tab layouts, and the `0.35 s` carried-input guard.
- [ ] Add `RunMode.FAILURE_REPORT`, the partial report, incoming
      last-hit/top-three summary, and explicit Garage continuation.
- [ ] Add deterministic `100.0%` largest-remainder formatting and zero-damage
      empty state.
- [ ] Verify modal pause/input blocking and deterministic focus.

**Acceptance:**

- every discovered enemy/boss entry visually matches its combat silhouette;
- every discovered facility and elite trait visually matches its world shape
  without revealing an unseen base enemy;
- locked entries leak no identity;
- every text key exists and fits in Korean and English;
- preview controls clip neither mesh nor focus indicator;
- reduced motion produces a static but complete preview;
- every cleared stage stops on its own report after the boss reward;
- defeat rows match actual combat deaths by archetype and never include cleanup;
- outgoing damage rows match telemetry values and visible percentages sum to
  exactly `100.0%`;
- Stage 1–4 Continue advances once, while Stage 5 Continue opens final result;
- the failure recap shows the correct last hit and no more than three aggregate
  sources; and
- no new persistent live-HUD text is introduced.

### Milestone 7 — Integration, performance, rendered QA, and cleanup

- [ ] Run every focused validator listed below.
- [ ] Run the complete current vehicle validation suite.
- [ ] Export the production Web build.
- [ ] Run deterministic capacity scenarios for all three fields, all five
      bosses, each terrain/facility family, mine chains, the activated Minelet,
      both new roles, every elite trait, and Boss Practice isolation.
- [ ] Complete three foreground standalone/Web repetitions at the required
      resolutions and the active performance plan's ten-minute lifecycle soak.
- [ ] Capture UI/UX evidence at `960x540`, `1280x720`, and `1920x1080` in Korean
      and English.
- [ ] Review field walls, all terrain states, every boss phase, Breach readiness,
      mine fuses, every facility state, every elite trait, Boss Practice setup
      and loop, Ship Status, per-stage reports, guidebook locked/unlocked
      entries, focus, and failure recap.
- [ ] Remove superseded branches, dead motif code, unused generic boss
      execution, stale localization, and temporary instrumentation.
- [ ] Run `$codebase-quality-auditor` and apply only safe task-scoped findings.
- [ ] Update evidence, canonical docs, and this plan's progress truthfully.

**Exit condition:** all functional, visual, localization, lifecycle, and
performance gates pass. If any declared gate fails, this plan remains active.

## Validation and Test Plan

### Focused validators

Run with the repository Godot wrapper:

```powershell
./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_stage_layouts.gd
./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_field_layout_generation.gd
./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_navigation_clearance.gd
./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_primary_weapon.gd
./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_attack_contract.gd
./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_boss_patterns.gd
./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_encounter_pacing.gd
./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_spawn_allocation.gd
./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_guidebook.gd
./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_combat_renderer.gd
./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_performance_scenarios.gd
./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_run.gd
```

Add responsibility-shaped validators rather than expanding one catch-all:

- `validate_vehicle_terrain_runtime.gd`
- `validate_vehicle_wall_contract.gd`
- `validate_vehicle_breach_interrupts.gd`
- `validate_vehicle_mines.gd`
- `validate_vehicle_enemy_expansion.gd`
- `validate_vehicle_elite_traits.gd`
- `validate_vehicle_boss_runtime.gd`
- `validate_vehicle_boss_practice.gd`
- `validate_vehicle_build_snapshot.gd`
- `validate_vehicle_stage_telemetry.gd`
- `validate_vehicle_stage_report.gd`

### Deterministic fixtures

Every test has a fixed seed and no wall-clock dependency:

- each field with fallback and six representative cover masks;
- the exact `7200x4320`, `20x12` minimap, anchor/socket counts, arrival rings,
  and bounded `75x45` pursuit rebuild;
- every terrain state boundary at `warning - epsilon`, `warning`, `active -
  epsilon`, `active`, and cycle reset;
- Flow entry/exit for player, ordinary enemy, boss, stationary enemy, and
  projectile;
- Transit dwell cancel/complete/cooldown/arrival, Repair full/empty/hit-pause,
  and Overdrive enter/leave/source-exclusion cases;
- bulkhead normal-fire and Breach destruction;
- mine proximity while outside the blast, health-zero, chain, placement
  clearance, wall occlusion, and attribution;
- Minelet, Guard, and Splitter at capacity and stage transition;
- every elite stage threshold, eligibility skip, two-live wait, trait rotation,
  fixed shell on all difficulties, one-trait limit, XP rounding, and report
  aggregation;
- every boss pattern in every phase and the five phase-three combos;
- every listed ordinary interrupt at `commit - epsilon`, exact commit, and
  `commit + epsilon`, proving pre-commit cancellation, zero payload creation,
  exact `0.45 s` stop, and full post-attack cooldown;
- Breach during ordinary move, active, recovery, mine fuse, contact-only
  movement, repair, generator, and pylon behavior, proving no generic stun or
  phase change;
- every boss pattern declares one valid commit mode; every boss has exactly one
  signature per nonadjacent four-pattern cycle;
- Breach during every boss signature startup, committed startup, autonomous
  warning, active, natural recovery, interrupted recovery, and phase threshold,
  proving the exact cancel/expose/no-op matrix;
- interrupting a signature while its phase combo has live projectiles, zones,
  mines, pylons, summons, or system layers leaves those payloads and their
  cleanup/attribution unchanged;
- Breach against plain, priority, plated, elite-shell, mined, Flashover,
  Shatter, Shock Breach, both Forked Muzzle layouts and alternating serial,
  pierce-first/pierce-second, and
  continuous-fire comparison fixtures;
- debug practice full-fight and pattern-loop launch for every boss/field/phase,
  malformed arguments, loop cleanup, invulnerable accepted-hit feedback, and
  byte-identical persistence before/after;
- build snapshots before a run and after representative primary, elemental,
  secondary, mobility, defense, and skill upgrades;
- guidebook locked/unlocked snapshot equivalence;
- stage telemetry with direct, overkill, invulnerable, status, reflected,
  structure, cleanup, summoned, and environmental cases;
- Stage 1–4 Continue, Stage 5 Continue, failure-to-Garage, carried input, zero
  damage, more-than-eight sources, and percentage rounding; and
- last-hit/top-three aggregation ties resolved by damage descending, then stable
  source ID.

### Production build

```powershell
./tools/export_web.ps1
```

Use the built Web export for final navigation and rendered QA. A dev/editor run
is iterative evidence only.

### Performance gates

Use the exact active performance-plan thresholds:

| Gate | Required result |
| --- | --- |
| capacity subsystem simulation | `p95 <= 6.0 ms`, `p99 <= 8.0 ms` |
| standalone `1280x720` | median `>=59 FPS`, 1% low `>=55 FPS`, frame `p95 <=18 ms`, `p99 <=25 ms`, no two consecutive frames over `33.3 ms` |
| standalone `2560x1600` | median `>=58 FPS`, 1% low `>=50 FPS`, frame `p95 <=20 ms`, `p99 <=33.3 ms` |
| Web `1280x720` | median `>=58 FPS`, 1% low `>=50 FPS`, frame `p95 <=20 ms`, `p99 <=33.3 ms`, no three consecutive frames over `33.3 ms` |
| total draw calls | `p95 <=200` at capacity |
| lifecycle | no retired live enemies, stale IDs, or cap overflow |
| ten-minute soak | static-memory growth `<8 MiB` after warmup |

Adding content may not lower an accepted simulation cadence, disable visual
feedback, reduce the existing envelope, or reinterpret the threshold.

## UI/UX Gate and Rendered Evidence

This is a Level 4 interface/system revision because wall semantics, terrain,
combat telegraphs, guidebook structure, and result feedback change together.
Final rendered evidence must include:

| Surface | Required states |
| --- | --- |
| deployment | separate seeded captures for each of the three read-only selected field names; debug build with Boss Practice action and release build without it; KR/EN; keyboard focus |
| gameplay field | all three enlarged layouts; shared walls; zero motifs; `20x12` minimap exploration; every terrain/facility warning, active, cooldown, depleted, and discovered state |
| Breach Shot | unprimed, charging, ready, fired, first-contact token consumed, bulkhead/plate/shell hit, ordinary interrupt, priority exposure, mine hit, boss-signature interrupt, committed late hit, natural-recovery exposure, Shock Breach |
| mine | separate activation/damage rings; dormant, normal fuse, short fuse, chained fuse, explosion with enemy inside |
| elites | all three traits on representative base meshes; monochrome silhouette; minimap diamond; Stage Report secondary count |
| bosses | each silhouette; every phase; broken-diamond signature, closed-diamond committed attack, emitter-owned autonomous warning, successful interrupt with surviving system layer, phase-three combo, boss HUD/minimap identity |
| Boss Practice | debug setup full/pattern modes, field/boss/phase/pattern selection, invalid state, invulnerability, pause/failure actions, pattern loop; release absence |
| guidebook | locked/unlocked enemy, boss, mine, terrain, facility, and elite trait; interrupt/committed/autonomous legend; KR/EN; focus; reduced motion |
| Settings Ship Status | active-run filled state, no-run empty state, long upgrade list, KR/EN, keyboard focus, 200% text scaling |
| Stage Report | two-column desktop, tabbed `960x540`, zero/one/eight-plus damage sources, long enemy/attack labels, focus and carried-input guard |
| failure | partial stage report plus last hit and one/two/three-source recap in KR/EN |

Capture at `960x540`, `1280x720`, and `1920x1080`. Check alignment,
typography, spacing, focus, overflow, clipping, central combat occlusion,
color-independent shape differentiation, and static reduced-motion states.
No screenshot with debug-only labels may be used as final evidence.

## Predetermined Contingencies

- If a field cannot meet two-route connectivity after thirty-two generated
  cover attempts, use that field's authored fallback cover IDs. If the fallback
  fails, reject the field at load; never silently narrow actor radius.
- If merged boundary loops self-intersect, fail validation and fix the authored
  regions. Do not draw an approximate wall unrelated to collision.
- If a Breakable Bulkhead would disconnect a required route, reject its authored
  socket. Do not auto-open it at runtime.
- If the player moves to another pursuit target cell before a bounded rebuild
  completes, finish or discard the in-progress work at the next `1024`-cell
  boundary, retain the last complete field, and begin the newest target. Never
  run a second full rebuild in the same physics tick.
- If a Transit destination fails its static `260/360 px` clearance or a pair is
  shorter than `2800 px`, reject the authored field. Never shrink the safe
  arrival circle or make the gate a required connectivity edge.
- If mine-chain demand exceeds six targets, arm the six nearest by distance then
  stable ID; leave the rest dormant.
- If generated stationary-mine placement cannot satisfy the full `260 px`
  solid/terrain clearance and `360 px` mine separation, use that field's
  authored fallback mine sockets. If fallback fails, omit the mine and fail the
  layout validator; never shrink the activation buffer or require dash.
- If a splitter cannot allocate both children, spawn only the available count;
  do not queue delayed hidden spawns.
- If an elite reservation reaches an ineligible authored unit, preserve the
  reservation for the next eligible unit. If the stage fixture cannot place
  every reserved elite before the boss quota, fail the authored encounter
  validator; never add post-quota enemies or hold the boss gate at runtime.
- If an attack lacks `commit_mode`, fail its catalog validator and make it
  non-runnable; never infer interruptibility from `startup`, role, name, or
  telegraph color.
- If a Breach collision resolves after the active transition on the same
  physics tick, treat the attack as committed. Never destroy an active payload
  or rewind to startup.
- If a signature interrupt occurs while autonomous or already committed child
  payloads are live, clear only startup-owned descriptors registered to that
  signature. Never clear by boss ID, phase name, or broad effect type.
- If a boss combo cannot prove base-speed escape, increase warning or gap
  geometry before reducing damage. Dash never becomes mandatory.
- If a practice request contains an unknown stage, field, phase, or pattern,
  headless mode exits nonzero and interactive debug mode returns to setup with
  one localized error. It never substitutes a different boss or pattern.
- If a guidebook mesh is too large for its preview, scale the shared mesh
  uniformly inside a `16 px` inset; do not crop or author a separate portrait.
- If an attack source lacks a catalog ID, record it as visible localized
  `other`, fail the focused source-coverage validator, and fix the source before
  release. Never expose an internal display string.
- If more than eight outgoing sources have nonzero damage, show the seven
  largest and combine the remainder into `Other`; telemetry retains exact
  individual values for validation.
- If Ship Status opens without an active-run snapshot, show the defined no-run
  empty state. Never reuse the previous run's snapshot.
- If a new repeated visual cannot use MultiMesh ordering correctly, use a fixed
  retained `MeshInstance2D` pool. Do not return to per-frame procedural
  high-count drawing.
- If any performance gate fails, first profile and reduce query cadence or
  presentation invalidation within the locked behavior. Do not raise caps,
  remove effects, lower physics FPS, or claim success from a headless
  microbenchmark.

## Safety and Rollback

- Work in coherent commits by milestone; do not mix unrelated user changes.
- Field registry changes precede content so every later commit has one field
  selection contract.
- Keep the current field definition usable until all three layouts pass. A
  failed new field can be removed from the registry without reverting wall,
  terrain, or combat fixes.
- Add the new boss runtime behind the same public snapshot contract, then delete
  the old generic branches only after parity validators pass.
- Persisted guidebook IDs are append-only. Never rename an existing discovered
  entry without a migration.
- Layout-seed behavior changes version from existing cover sub-seeds only through
  the new `field:v1` selection. Existing explicit `--layout-seed` remains
  deterministic.

## Risks

| Risk | Control |
| --- | --- |
| Three larger fields multiply cache and validation bugs | Key every immutable cache by `field_id`; use exact common dimensions/counts; run every fixture across all fields |
| `7200x4320` makes pursuit rebuilds spike | Preallocated `75x45` buffers, `1024`-cell work ceiling, prior-field atomic retention, boss-radius work only while live |
| A larger field feels empty | Player-relative `1000–1800 px` ordinary arrival ring, off-camera fallback, unchanged active cap, and two long-distance gate pairs |
| A common wall rail visually shrinks corridors | Lock `320 px` minimum corridor and align the `24 px` floor-side edge with player-center collision |
| Friendly-fire mines solve encounters automatically | Enemy proximity cannot arm them; player approach or damage creates the event |
| Breach Shot becomes mandatory DPS | Baseline has no area damage; unprotected sustained-fire fixture must beat intentional re-priming; an interrupting hit cannot also expose |
| Breach Shot stun-locks ordinary enemies | Only metadata-approved startup is cancellable; one first-contact token, `0.45 s` recovery, full post-attack cooldown, and no generic `stun` write |
| Breach Shot trivializes bosses | Exactly one signature per boss cycle, no adjacent signature, forced committed next pattern, autonomous layers survive, and natural-recovery exposure is mutually exclusive with interrupt |
| Repair or Overdrive becomes a camping bunker | Both have large cover/spawn clearance; Repair pauses on hit and exhausts at `24` hull; Overdrive is exposed to converging enemies |
| Transit Gate trivializes pressure | `0.35 s` dwell, `10.0 s` pair cooldown, no enemy transport, no required connectivity, and only `0.45 s` arrival protection |
| A mine detonates before the player can understand it | Activation is `70/60 px` outside damage, fuse is continuous, and placement proves a base-speed escape route |
| Boss layering becomes unreadable | One low-reaction autonomous layer plus one direct response; exact warnings, commit-mode shapes, and base-speed escape proof |
| New roles reintroduce lag | Bounded live caps, local queries, existing active cap, MultiMesh presentation |
| Elite variants multiply content or projectiles | One trait field on an existing unit, three shared geometry overlays, fixed stage replacements, two-live cap, no added projectile |
| Practice diverges from production bosses | It owns session/reset only and imports the exact production runtime, stores, telegraphs, renderer, and HUD; no duplicate pattern executor |
| Practice mutates progression | Debug-only reachability plus byte-identical persistence and no-reward/discovery validators |
| Guidebook leaks unseen content | Neutral locked preview and snapshots that omit hidden metadata |
| Combat reporting slows gameplay | Bounded numeric dictionaries update in the existing damage/defeat path; UI snapshot freezes only at report/open events |
| Settings and guidebook show different stats | Both render the same immutable gameplay-owned build snapshot and shared summary component |
| Run-level field variation is mistaken for stage map switching | Field name shown on deployment and field ID immutable through stage flow |

## Progress

- [x] Recovered the previous current and storm terrain behavior from git history.
- [x] Audited the current field, motif, wall, opening-shot, mine, enemy,
      boss-pattern, guidebook, and performance contracts.
- [x] Audited map-size effects on pursuit/minimap, current boss capture reuse,
      elite insertion boundaries, and the separate difficulty/meta decision.
- [x] Audited ordinary and boss startup/active/recovery transitions, generic
      stun behavior, damage resolution order, and telegraph metadata; locked
      the conditional interrupt matrix before revising this plan.
- [x] Reviewed current primary external design and engine references.
- [x] Locked one implementation direction with no deferred design choice.
- [ ] Milestone 0 implementation baseline and canonical-spec update.
- [ ] Milestone 1 field registry and wall truth.
- [ ] Milestone 2 terrain and Breach Shot.
- [ ] Milestone 3 mines and enemy expansion.
- [ ] Milestone 4 boss runtime and exams.
- [ ] Milestone 5 combat telemetry and Ship Status.
- [ ] Milestone 6 guidebook and stage/failure reports.
- [ ] Milestone 7 integration and release evidence.

## Open Questions

None. The map count, `7200x4320` dimensions, persistence, wall contract, six
field-feature families, first-contact Breach token, ordinary interrupt table,
one-signature boss rule, committed/autonomous boss pressure, mine safety
geometry, enemy/elite roster, debug practice isolation, Ship Status, telemetry
attribution, report flow, localization, performance envelope, and validation
gates are locked. A run-risk contract remains outside this execution plan in
the separate difficulty/meta evidence study. A change to any in-plan contract
is change control from the owner, not an implementation-time choice.

## Decision Notes

- 2026-07-24: Preserve one field through a run, but select that field from three
  authored layouts at new-run creation.
- 2026-07-24: Delete all motifs rather than recolor or hide them.
- 2026-07-24: Treat every impassable static edge as one wall material and derive
  it from compiled collision geometry.
- 2026-07-24: Rebuild, rather than restore, the old current and storm mechanics
  so terrain affects both sides and never changes projectile flight.
- 2026-07-24: Give the one-second shot structure, mine, protected-enemy,
  startup-interrupt, and natural boss-recovery exposure jobs; keep held fire.
- 2026-07-24: Define Breach as a precision priority-opening tool earned during
  natural firing downtime. Baseline Breach does not clear groups; existing
  cards own faster, stronger, or area-conversion branches.
- 2026-07-24: Increase enemy and boss decision variety without increasing the
  existing active-cap envelope.
- 2026-07-24: Reuse combat meshes for guidebook visuals instead of creating
  separate image assets.
- 2026-07-24: Replace generic and accumulated Breach stagger with one direct,
  metadata-approved pre-commit cancellation. Ordinary and boss interrupts last
  `0.45 s`, grant no exposure, and cannot affect committed or autonomous
  payloads.
- 2026-07-24: Give each boss exactly one interruptible signature per
  nonadjacent four-pattern cycle. Force a committed next pattern after success
  and run space-control systems independently from boss-body attack phases.
- 2026-07-24: Remove Relay Scavenger and every experience-stealing/denial
  behavior without replacement.
- 2026-07-24: Make mine activation visibly larger than its damaging radius and
  validate a base-speed, no-dash escape.
- 2026-07-24: Add shared Ship Status to paused Settings and the guidebook.
- 2026-07-24: Add a Stage Report after every boss reward with per-archetype
  defeats and applied-health-damage contribution by stable attack source.
- 2026-07-24: Enlarge every field to `7200x4320`, pair it with a `20x12`
  minimap and bounded packed pursuit rebuild, and preserve current actor caps.
- 2026-07-24: Add player-owned Transit, Repair, and Overdrive facilities as a
  visually explicit exception to neutral terrain's both-team interaction rule.
- 2026-07-24: Add fixed `1/2/3/4/5` elite replacements with three
  shape-distinct one-trait variants; never add them on top of quota/cap.
- 2026-07-24: Add debug-only rewardless Boss Practice for QA by reusing the
  production boss runtime and stores; keep all progression and persistence
  unreachable.
- 2026-07-24: Keep optional danger/risk contracts out of this plan. If retained
  later, they are deployment-time whole-run modifiers owned by the unresolved
  difficulty/meta-progression decision, never same-stage repetition.

## Completion Criteria

- [ ] Every Success Criterion and milestone acceptance statement passes.
- [ ] The canonical product and visual specifications contain the implemented
      durable behavior.
- [ ] Korean and English UI evidence passes the Level 4 UIUX gate at all
      declared viewports and states.
- [ ] Focused, full-suite, production Web, performance, and lifecycle gates
      pass without relaxing the existing envelope.
- [ ] No motif path, accumulated boss hard-stagger transition, generic
      Breach-to-`stun` write, experience-denial role,
      duplicate build calculation, display-string damage grouping, stale
      localization, or temporary instrumentation remains.
- [ ] No `5600x3400`/`16x10` field assumption, full-grid Dictionary pursuit
      rebuild, duplicated boss-practice attack path, reward-capable practice
      path, role-by-trait elite mesh duplication, phase/name/color-inferred
      interruptibility, multi-contact Breach token, projectile `opening` field,
      or retired `opening_breach_multiplier` stat remains.
- [ ] This active ExecPlan is deleted after its durable decisions and final
      evidence are incorporated into the canonical specs, as required by
      `.agents/PLANS.md`.

## Stop Conditions

Complete only when every Completion Criterion passes. Escalate only if the owner
changes a locked product rule, a required existing owner cannot support the
specified interface without architectural expansion, or a measured performance
gate fails after the predetermined bounded remedies. A narrow test failure,
layout rejection, or report overflow is not a stop condition; apply the
predetermined contingency and continue.

## Next Steps

Begin Milestone 0 only when implementation is explicitly requested. Do not
alter game code from this planning document alone.
