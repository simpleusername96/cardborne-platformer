---
type: plan
status: active
owner: BK
created: 2026-07-24
last_reviewed: 2026-07-24
scope: Player damage readability, fairer hostile projectiles, distributed encounters, one seeded field layout per run, faster early run levels, and stackable elemental card branches
related:
  - ../PLANS.md
  - ../vehicle-performance-stabilization-evidence.md
  - ./2026-07-23-vehicle-performance-architecture-stabilization.md
  - ./2026-07-23-single-field-campaign-secondaries-guidebook.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
---

# Combat Readability, Seeded Field Variation, and Progression — Execution Plan

This plan makes accepted damage obvious at the ship, keeps projectile-heavy
combat while making hostile shots fairer to read, distributes each surge across
more valid arrival points, varies walls, stationary enemies, and field items
within a validated run-scoped field layout, accelerates early run levels, and
lets the three elemental card branches coexist without adding hot-path
allocations. It deliberately does not change difficulty profiles or add
death-persistent progression.

## Purpose

- **Objective:** improve moment-to-moment clarity, spatial variety, build
  expression, and runtime safety without reducing the authored enemy
  population, changing enemy damage, or replacing the current game loop.
- **Final artifact:** one implementation in which damage feedback is visible
  without reading the top-left HUD, ranged pressure remains the game's identity
  but uses smaller/slower fair shots, squads arrive from several telegraphed
  locations, every new run receives one validated field variant that remains
  stable through all five stages and retries, early level-ups arrive sooner,
  and fire, poison, and chill branches can all be owned and applied together.
- **Completion state:** all focused validators, the complete validator suite,
  native boot, Web export, fixed-seed captures, reduced-motion checks, and the
  bounded development performance checks in this plan pass from one clean
  implementation commit lineage.

## Why / Context

Accepted hull damage currently sets `player_hit_flash` for `0.22 s`,
`player_invulnerable` for `0.28 s`, and an `8 px` camera shake. Presentation
receives only a boolean and changes the ship to an overbright white. The result
is easy to miss during dense combat, especially when the player is not looking
at the top-left health bar. Barrier absorption already has a separate effect
and must remain distinct from hull damage.

Every hostile projectile currently receives a global `1.18` speed multiplier,
a `7 px` collision radius, a rendered head of at least `7 px`, and a `47 px`
trail. Ordinary shooters, towers, and bosses therefore create similar visual
pressure even though their jobs differ. Boss predictive aim also receives the
unscaled base speed while projectile motion receives the multiplier later, so
prediction and actual travel speed do not share one owner.

The field has sixteen usable ordinary anchors, but every authored packet chooses
one anchor and schedules as many as eight squads there. This produces a large
clump at one place rather than several readable arrivals. The field's thirteen
internal covers, four stationary positions, three pickups, and five crates are
also immutable. Existing runtime seams already accept extra cover for movement,
line of sight, projectiles, and the minimap, but those seams return empty arrays;
the pursuit field and backdrop still assume only catalog-static cover.

The XP threshold is `26 + 3 × (level - 1)`, capped at `72`. It increases, but
the first level arrives late and the cap flattens later progression. Elemental
cards have the opposite problem: their prerequisites exist, but
`element_core` makes fire, poison, and chill mutually exclusive. Projectiles
also duplicate a status dictionary on every shot. Removing the exclusion
without replacing that representation would create avoidable allocation and
status-rendering pressure.

## Pre-plan Evidence Already Verified

| Source or path | Verified fact | Locked consequence | Freshness boundary |
| --- | --- | --- | --- |
| `AGENTS.md`, `.agents/AGENTS.md`, `.agents/PLANS.md` | This is cross-system gameplay, UI, data, and validation work and therefore requires an active ExecPlan. | Store the plan here, keep implementation checklists decision-complete, reconcile durable behavior into the specs, and delete this plan after completion. | Re-read if repository guidance changes. |
| `docs/product/vehicle_game_spec.md` | The current contract is a five-stage run on one `5600×3400` field, with held primary fire, a one-second opening shot, dash, passive weapons, EMP, XP shards, and card choices. It currently describes immutable field geometry and no procedural generation. | Preserve the run loop and controls; replace only the immutable-internal-cover clause with bounded, seeded, validated run variation during implementation. | Re-read before specification reconciliation. |
| `docs/design/UI_VISUAL_SYSTEM.md` | Sunken Ceramic Fresco uses large flat-color shapes, coral for danger, mustard for player/reward emphasis, Korean by default, and reduced-motion support. Collision truth must match visible geometry. | Use coral hull feedback, large simple wall modules, no texture noise, no extra opaque HUD panel, and one collision/render layout source. | Re-read before rendered QA. |
| `scripts/vehicle/vehicle_run.gd::_damage_player()` | Accepted hull damage currently produces a short white flash, `0.28 s` invulnerability, an `8 px` camera shake, and the generic `hurt` sound. Fully absorbed barrier damage returns before hull feedback. | Keep barrier and hull events distinct; replace hull presentation and set an exact one-second post-hit invulnerability. | Recheck before Phase 1 edits. |
| `scripts/presentation/vehicle_combat_renderer.gd` | The retained player overlay accepts a boolean hit state; projectile heads use `max(7, radius × 1.35)` and trails are `47 px`. | Extend retained snapshots and batches; do not create transient nodes or procedural per-hit assets. | Recheck before Phase 1. |
| `scripts/presentation/vehicle_audio_director.gd`, `tools/audio/generate_vehicle_sfx.py` | `hurt` currently resolves to `impact_cover`; project-owned deterministic PCM generation already exists. | Add one dedicated generated hull-hit sound through the existing generator and director. | Recheck if audio ownership changes. |
| `scripts/encounters/vehicle_encounter_director.gd` | All hostile shots receive `HOSTILE_PROJECTILE_SPEED_MULTIPLIER = 1.18`. | Set one effective-speed owner to `1.0` and use it for both motion and predictive aim. | Recheck before Phase 1. |
| `scripts/vehicle/stages/vehicle_combat_stages.gd` | Each non-scout packet contains up to eight squads of three to five units, but all squads share one packet anchor. Authored mobile counts are `260/300/340/380/420`. | Keep counts and squad sizes; assign each squad its own deterministic valid anchor and stagger concurrent sectors. | Recheck before Phase 4. |
| `scripts/encounters/vehicle_encounter_runtime.gd` | The scheduler owns trigger, cue, queue, beat cap, and metrics. It currently resolves one packet anchor when scheduling. | Keep scheduling ownership here and delegate spatial selection to one new bounded allocator. | Recheck before Phase 4. |
| `scripts/vehicle/stages/drowned_ruin_field.gd` | The field owns sixteen ordinary anchors, eight boss anchors, four stationary anchors, thirteen covers, three pickups, and five crates. | Keep the world/floor/water/motifs and boss anchors; replace internal cover and object positions with authored candidate sockets selected by a run layout. | Recheck before Phase 2. |
| `scripts/vehicle/vehicle_stage_rules.gd`, `scripts/vehicle/vehicle_run.gd` | `*_with_extra` movement, hit, LOS, and reachability APIs exist, but `_runtime_cover_rects()`, `_runtime_projectile_cover_rects()`, and runtime LOS still return empty data. Projectile broadphase first checks only static catalog cover. | Fill and reuse the runtime layout array, add a runtime broadphase gate, and route every geometric consumer through the same data. | Recheck after each layout integration task. |
| `scripts/enemies/vehicle_pursuit_field.gd` | Reverse-cost navigation caches only catalog-static walkability for radii `36` and `76`. | Include the run layout at reset and rebuild neither layout nor walkability every frame. | Recheck before Phase 3. |
| `scripts/vehicle/vehicle_stage_backdrop.gd` | The backdrop draws only static catalog cover and redraws on stage configuration. | Draw the run layout once per layout fingerprint and preserve the same view through stage transitions. | Recheck before Phase 3. |
| `scripts/progression/vehicle_experience_runtime.gd` | Current requirement is `min(72, 26 + 3 × (level - 1))`; XP shards are preallocated and multiple pending levels are already queued safely. | Change only the requirement curve; keep XP values, shard cap, collection, and queued reward semantics. | Recheck before Phase 5. |
| `scripts/cards/vehicle_upgrade_catalog.gd`, `scripts/cards/vehicle_run_build.gd` | `element_core` and the `element_core` exclusion group block simultaneous elemental roots. Capstones currently require the root rather than the intermediate card. | Remove the exclusion owner and make each branch an explicit three-step chain. | Recheck before Phase 5. |
| `scripts/combat/vehicle_status_runtime.gd`, `scripts/combat/vehicle_projectile_state.gd` | Status payload selects only one core and every projectile constructs a dictionary; poison stacks, but burn refreshes and chill replaces. | Use one shared typed status profile per build revision and bounded independent stacks for all three elements. | Recheck before Phase 5. |
| `.agents/vehicle-performance-stabilization-evidence.md` | Runtime capacity is 128 enemies, 240 player projectiles, 120 hostile projectiles with 24 boss-reserved slots, 192 XP shards, retained MultiMesh presentation, and cached spatial queries. The short focused pressure smoke passes, while the full release matrix remains intentionally deferred. | Preserve all caps and retained ownership, prohibit per-frame generation/RNG/new nodes, and run regression smoke rather than reopening the full release matrix. | Recheck before final performance validation. |

## Research and Discovery Checklist — Complete

- [x] Traced accepted/rejected hull-damage state, barrier absorption, dash
  invulnerability, camera shake, player rendering, HP rendering, and audio
  routing.
- [x] Traced ordinary and boss projectile speed, prediction, collision radius,
  visual head/trail, cover collision, and bounded store ownership.
- [x] Traced packet construction, cue/spawn scheduling, active caps, role
  definitions, pursuit, and the packet-wide anchor bottleneck.
- [x] Traced fixed field geometry, every runtime-cover seam, static broadphase,
  backdrop, pursuit cache, minimap, and debug collision consumers.
- [x] Checked all proposed cover rectangles against the current walkable union
  and mechanically confirmed radius-36 and radius-76 reachability for all
  `1296` cover masks before locking the coordinates in this plan.
- [x] Traced XP values, requirement math, shard pooling, level queueing, and
  quota-path cadence.
- [x] Traced elemental resource prerequisites, exclusion behavior, per-shot
  status copying, stack semantics, opening-shot consumers, and world/HUD status
  presentation.
- [x] Checked active performance ownership, capacities, thresholds, and the
  explicit decision to defer release-matrix repetition while gameplay changes.

## Execution Readiness

- Discovery, inspection, and design selection are complete. Implementation
  phases contain no search, comparison, option selection, or TODO.
- This plan authorizes exactly the values, lifecycle, ownership, and fallback
  behavior below. A freshness check confirms that a named owner still exists;
  it does not reopen design.
- If current code materially contradicts a locked contract, stop and amend this
  plan before coding around the conflict.
- Implement phases in order. The one exception is that deterministic data-only
  fixtures for a phase may be added in the same commit as their validator.

## Scope

### In scope

- Ship-local hull-hit feedback, a compact HP-loss trail, dedicated hull-hit
  audio, and one-second post-hit invulnerability.
- Smaller and slower hostile projectile profiles with one effective-speed
  calculation shared by motion and prediction.
- Per-squad distributed arrival anchors, directional fairness rules, and
  deterministic role-order composition without changing total enemy counts.
- One deterministic, validated, seeded field layout per full run, reused across
  stages and retries.
- Randomized-within-rules internal cover, stationary positions, ordinary spawn
  anchors, pickups, and crates.
- Faster early XP requirements with a rising late curve.
- Coexisting fire, poison, and chill card branches with explicit prerequisite
  chains and bounded stack behavior.
- Korean/English status text affected by elemental stacking.
- Focused gameplay, geometry, localization, audio, performance, native, Web,
  and rendered validation.

### Non-scope

- Difficulty multiplier, enemy-stat, enemy-damage, enemy-total, quota, boss
  damage, or difficulty-selection changes.
- Any card, stat, currency, unlock, or loadout persisted because the player
  died or completed a prior run.
- Dynamic difficulty adjustment, hidden aim assistance changes, new enemy
  archetypes, new bosses, new pickups, new passive weapon families, or new
  stages.
- Fully procedural floor topology, runtime room carving, destructible walls,
  per-stage wall rearrangement, or random geometry generated during play.
- A new visual theme, detailed textures, shader-heavy hit effects, a full-screen
  damage vignette, or a new map-blocking HUD panel.
- The deferred three-run release performance matrix and ten-minute soak owned
  by the active performance stabilization plan.

## Assumptions

- Godot 4.7 stable, GDScript, and the existing project-owned assets remain the
  production stack.
- Hard remains the current default, but this plan treats that only as untouched
  existing state.
- The `5600×3400` field boundary, floor-region union, water, central start,
  four motifs, and eight boss-arrival anchors remain authored and fixed.
- A “new run” is a deployment with a new `run_index`; a stage retry and a stage
  advance remain part of the same run.
- Existing enemy role multisets, authored counts, active caps, threat budgets,
  projectile caps, XP values, pickup types, and item counts remain unchanged.
- The field layout is not save-persistent. It only needs to survive the active
  five-stage run and exact stage retries.

## Proposed Design — Locked Product and Technical Contracts

### 1. Accepted hull damage

1. `_damage_player()` continues to reject damage while dashing, invulnerable,
   outside play, or after completion. Rejected damage does not restart any
   feedback timer.
2. A barrier that absorbs all incoming damage keeps the existing barrier effect
   and does not trigger hull feedback or hull invulnerability.
3. Accepted hull damage sets:
   - `player_hit_flash = 0.20 s`;
   - `player_invulnerable = max(current, 1.00 s)`;
   - hit-camera shake to at most `3 px`;
   - one dedicated `player_hull_hit` audio event.
4. The first `0.18 s` renders a coral ship tint and a deterministic ship-only
   recoil/jitter with a maximum `5 px` offset. It changes presentation only;
   player position, collision, aim origin, and camera target remain unchanged.
5. From `0.18 s` until invulnerability ends, the ship alternates between its
   normal color and a pale coral tint at `8 Hz`. Alpha never falls below `0.70`,
   so flicker cannot make the ship disappear.
6. Reduced motion disables ship jitter, camera shake, and alternating flicker.
   It uses one steady pale-coral tint plus a thin coral invulnerability ring
   until the same gameplay timer expires.
7. `HealthPips` shows the current coral HP fill immediately and retains the
   previous HP as a pale delayed segment for `0.18 s`, then closes it over
   `0.45 s`. Its `_process()` runs only while that segment is active. Reduced
   motion snaps the segment and uses a `0.20 s` outline pulse instead.
8. The combat snapshot exposes remaining hit and invulnerability time, not only
   a boolean. No hit creates a node, material, timer node, or heap collection.

### 2. Hostile projectile readability

1. Replace direct multiplier use with
   `EncounterDirector.effective_hostile_projectile_speed(base_speed)`.
   Its multiplier is exactly `1.00`, a `15.25%` reduction from the current
   effective speed. Every hostile spawn and boss predictive-aim calculation
   calls the helper.
2. Ordinary hostile projectiles use a `5 px` collision radius, a minimum `6 px`
   rendered head, a `36 px` trail, and trail width `head × 1.25`.
3. Boss-reserved/final hostile projectiles use a `6 px` collision radius, a
   minimum `7 px` rendered head, the same `36 px` trail, and the existing
   boss-magenta identity.
4. Beam, denial-zone, contact, charge, telegraph duration, attack cooldown,
   damage, projectile lifetime, and projectile-count contracts do not change.
5. Visual size is never smaller than collision size. Coral/magenta contrast and
   the readable trail remain even at the smaller profile.
6. Existing ordinary capacity `96` plus boss reserve `24` remains unchanged.

### 3. Run layout lifecycle and seed domains

1. `VehicleFieldLayout` is created once for a new `run_index`, before stage
   actors/items are configured. It is reused for stages 1–5 and exact stage
   retries. Only a new run creates a new layout.
2. Normal play creates one dedicated `RandomNumberGenerator` in `_ready()`,
   calls `randomize()` exactly once, stores that generator's seed as the session
   seed, and derives
   `layout_seed = hash("field:v1:<session_seed>:<run_index>")`.
3. Capture, validation, and performance paths accept `--layout-seed=<integer>`.
   Their default fixed seed is `0xC4A2B0`.
4. Independent sub-seeds prevent an item implementation change from moving
   walls:
   - `hash("<layout_seed>:cover:v1")`;
   - `hash("<layout_seed>:<stage_id>:stationary:v1")`;
   - `hash("<layout_seed>:<stage_id>:items:v1")`;
   - `hash("<layout_seed>:<stage_id>:encounter:v1")`.
5. The layout stores the seed, selected cover rectangles, valid ordinary and
   boss anchors, per-stage stationary and item blueprints, and one fingerprint.
   Hot paths reuse its arrays by reference after configuration; they never
   duplicate or mutate them during play.
6. The seed and fingerprint appear in debug and performance snapshots so a bad
   layout is reproducible.

### 4. Authored modular cover set

`DrownedRuinField` stops returning the thirteen current internal covers as
catalog-static collision. It retains fixed floor/water/boundary/motif data and
defines the following sixteen large candidate rectangles. The generator selects
exactly two candidates from each quadrant, for exactly eight internal covers.

| ID | `Rect2(x, y, width, height)` |
| --- | --- |
| `nw_a` | `(600, 650, 260, 150)` |
| `nw_b` | `(1200, 1020, 300, 150)` |
| `nw_c` | `(1760, 780, 240, 160)` |
| `nw_d` | `(1870, 1160, 220, 160)` |
| `ne_a` | `(4740, 650, 260, 150)` |
| `ne_b` | `(4100, 1020, 300, 150)` |
| `ne_c` | `(3600, 780, 240, 160)` |
| `ne_d` | `(3510, 1160, 220, 160)` |
| `sw_a` | `(600, 2600, 260, 150)` |
| `sw_b` | `(1200, 2230, 300, 150)` |
| `sw_c` | `(1760, 2460, 240, 160)` |
| `sw_d` | `(1870, 2080, 220, 160)` |
| `se_a` | `(4740, 2600, 260, 150)` |
| `se_b` | `(4100, 2230, 300, 150)` |
| `se_c` | `(3600, 2460, 240, 160)` |
| `se_d` | `(3510, 2080, 220, 160)` |

The deterministic fallback selection is:
`nw_a, nw_c, ne_b, ne_d, sw_b, sw_d, se_a, se_c`.

Every cover uses the existing unified ceramic/ivory wall color and flat stepped
shadow. There are no small decorative blockers. The rendered rectangle and the
collision rectangle come from the same selected array.

### 5. Candidate object and arrival sockets

#### Ordinary arrivals

The valid pool starts with these 24 authored candidates. The layout validator
removes a candidate only when cover/floor clearance fails and requires at least
16 survivors:

```text
(480,520)   (880,480)   (1280,560)  (4320,520)
(4800,480)  (5200,640)  (480,2860)  (880,2920)
(1280,2820) (4320,2860) (4800,2920) (5200,2760)
(1900,700)  (3600,700)  (1900,2700) (3600,2700)
(1540,620)  (2380,620)  (3220,620)  (4060,620)
(1540,2780) (2380,2780) (3220,2780) (4060,2780)
```

The eight existing boss anchors remain fixed candidates but must pass large
actor reachability for the selected cover layout.

#### Stationary enemies

Each stage chooses one valid point per quadrant, for exactly four stationary
enemies. Roles remain the current stage-specific four-role list and are
deterministically shuffled before assignment.

| Quadrant | Three candidate points |
| --- | --- |
| northwest | `(1120,1340)`, `(1640,1180)`, `(1940,1400)` |
| northeast | `(4480,1340)`, `(3960,1180)`, `(4060,1500)` |
| southwest | `(1120,2060)`, `(1640,2220)`, `(1940,2000)` |
| southeast | `(4480,2060)`, `(3960,2220)`, `(4060,1900)` |

#### Pickups and crates

Each stage selects eight valid points from this fixed 24-point pool:

```text
(1080,920)  (1420,1420) (1420,1980) (1080,2480)
(1900,920)  (2180,1460) (2180,1940) (1900,2480)
(2300,1540) (2300,1860) (2680,920)  (2920,920)
(2680,2480) (2920,2480) (3300,920)  (3300,2480)
(3740,920)  (3740,2480) (4020,1500) (4020,1900)
(4520,1100) (4520,2300) (5000,850)  (5000,2550)
```

The first three selected sockets receive two repairs and one experience recall;
the remaining five receive four repair crates and one recall crate. Type order
is shuffled from the stage item sub-seed. The two recall sources must be at
least `1200 px` apart.

### 6. Layout validation invariants

Generation tries at most 32 deterministic candidate selections, then uses the
locked fallback. The fallback is subject to the same validator and a failed
fallback is a hard implementation failure.

- Keep a `480 px` radius around `(2800,1700)` free of cover, stationary enemies,
  and arrival anchors.
- Keep at least `176 px` Euclidean rectangle-to-rectangle clearance between any
  two selected covers and between selected cover and water.
- Every selected rectangle is wholly inside the walkable floor union and does
  not intersect water.
- With `96 px` grid cells, radius `36` reaches every valid ordinary anchor,
  stationary socket, pickup, crate, and each of the four outer combat courts
  from the center.
- Radius `76` reaches every boss anchor and each outer combat court.
- An ordinary arrival is at least `960 px` from the player when selected.
- A stationary enemy is at least `96 px` from cover and `480 px` from center.
- Items are at least `96 px` from cover, `180 px` from hostile/stationary
  sockets, and `200 px` from one another.
- No item lies inside an arrival cue footprint.
- Movement, player and enemy projectiles, enemy LOS, pursuit navigation,
  minimap, debug collision overlay, and backdrop use the exact same runtime
  cover array.
- The validator exhausts all `6⁴ = 1296` cover masks and checks 256 complete
  run/stage seed fixtures for object placement and deterministic replay.

### 7. Distributed encounter scheduling

1. `VehicleCombatStages` continues to author time, beat, squad sizes, roles,
   and totals but no longer assigns a packet-wide position.
2. The first scout remains one unit after the existing grace period.
3. Every later squad is one arrival cue at one distinct anchor and contains the
   existing three-to-five units. No arrival cue produces more than five units.
4. A packet's eight squads use eight distinct valid anchors whenever at least
   eight candidates satisfy the current player-distance rule. Otherwise the
   allocator may reuse the farthest anchor only after every valid anchor has
   been used once.
5. At activation, prefer anchors at least `160 px` beyond the visible world
   rectangle. If none qualify, choose the farthest reachable anchor satisfying
   the `960 px` player distance; if none satisfy both, choose the farthest valid
   reachable anchor and keep the full `0.9 s` cue.
6. Beats 0–1 schedule at most two arrival sectors in one group and keep those
   sectors within one contiguous `135°` player-relative arc. Beats 2–4 schedule
   at most three sectors within `180°`. This prevents an unreadable immediate
   360-degree surround while still varying attack direction.
7. Arrival groups are separated by `0.90 s` in beats 0–1 and `0.65 s` in
   beats 2–4. Unit spacing remains `0.16 s`; cue lead remains `0.9 s`.
8. The allocator avoids the four most recently used anchors before reuse and
   uses the encounter sub-seed for stable tie-breaking. It runs at packet
   activation only, never every physics frame.
9. Every squad of three to five contains at least one pursuit role
   (`scrap_drone`, `chaser`, `rammer`, or `spark_minelet`) and at most two
   direct projectile roles (`needle_drone` or `shooter`). The current
   stage/packet role multiset is reordered, not replaced, so authored counts,
   XP, and role totals do not change.
10. Stationary enemies, denial roles, supports, boss arrivals, active caps,
    threat budgets, and boss quotas keep their current contracts.

### 8. XP requirement curve

For `n = run_level - 1`, use:

```gdscript
min(160, 12 + roundi(3.0 * n + 0.55 * n * n))
```

The first fifteen requirements are locked to:

```text
12, 16, 20, 26, 33, 41, 50, 60, 71, 84, 97, 112, 127, 144, 160
```

Enemy XP values, boss XP, shard geometry/cap, attraction, recall, uncollected
XP, and queued multi-level behavior remain unchanged. With the current quota
path and unchanged role multiset, the deterministic five-stage validation gains
`6, 4, 2, 4, 3` levels respectively and ends at run level `20`.

### 9. Stackable elemental branches

The three branches become independent and may all be owned:

```text
Incendiary Core -> Thermal Compound -> Flashover
Toxin Core      -> Concentrated Toxin -> Contagion
Cryo Core       -> Deep Freeze -> Shatter
```

- Remove `VehicleRunBuild.element_core`, `_core_for()`, and the
  `element_core` exclusion checks/data values.
- Change each capstone requirement from its root to its intermediate card.
- A locked child never appears. When an owned branch has an eligible child,
  one of the three later level-up choices is reserved for an eligible child
  from the least-progressed owned branch; seeded ordering breaks ties. Other
  elemental roots remain eligible.
- Fire, poison, and chill apply together from one shared typed
  `VehicleStatusProfile` built only on run reset or card application. Each
  projectile stores a reference to the profile active when it was fired.
  Projectile acquire/release does not duplicate a dictionary.

Bounded status rules:

| Status | Root behavior | Intermediate behavior | Capstone trigger |
| --- | --- | --- | --- |
| Burn | `2.0 DPS` per stack, `3.0 s`, maximum 3 stacks; a hit adds one and refreshes duration | Each Thermal level adds `0.75 DPS` per stack and `0.5 s` | A charged opening shot consumes all burn stacks; bonus is `DPS per stack × stacks × remaining seconds × 1.25` in the existing `70 px` splash |
| Poison | `2.0 DPS` per stack, `5.0 s`, maximum 3 stacks | Each Concentrated Toxin level adds `1.0 DPS` and one maximum stack | Contagion gives one stack to at most eight nearest live enemies within `100 px` |
| Chill | `6%` slow per stack, `2.0 s`, maximum 3 stacks; a hit adds one and refreshes duration | Each Deep Freeze level adds `2%` slow per stack and `0.5 s` | A charged opening shot at 3 stacks consumes chill and adds the existing `40%` base-damage Shatter bonus |

Boss chill magnitude and duration remain at `50%` of ordinary values. Burn,
poison, and chill may coexist; the stack cap is enforced before writing enemy
state. Contagion gives exactly one poison stack to at most the eight nearest
live enemies within `100 px`, ordered by distance and stable runtime ID.

World presentation uses one retained status-arc MultiMesh with capacity
`128 × 3`. Each active status receives one large `110°` segment around the
enemy: coral for burn, mint for poison, cobalt for chill. Remove the per-frame
procedural status arcs from `VehicleRun`. The existing target/boss state line
adds localized status names and stack counts so exact stacking is visible
without adding world text.

## Rejected Alternatives

- **Full procedural floor or room generation:** rejected because the current
  floor union, collision caches, boss navigation, minimap, and five-stage
  learning loop benefit from a stable authored topology.
- **Rerolling walls every stage:** rejected because players could not learn
  cover or routes within one run and a stage transition could invalidate the
  player's spatial plan.
- **Random continuous wall coordinates:** rejected because visible/collision
  truth and route clearance could not be exhaustively guaranteed.
- **Keeping thirteen fixed covers and adding random covers on top:** rejected
  because it increases clutter and does not create meaningful layout variation.
- **Reducing enemy totals or damage in the same pass:** rejected because those
  are difficulty decisions explicitly outside this plan and would obscure
  whether projectile/readability changes work.
- **A full-screen red damage vignette:** rejected because it competes with dense
  projectile reading; ship-local tint, recoil, audio, and HP trail provide the
  needed channels without hiding the field.
- **Hiding the ship completely during invulnerability:** rejected because the
  player must remain trackable in projectile-heavy combat.
- **Assigning one anchor per packet:** rejected because it recreates the current
  clump. **Choosing anchors every frame:** rejected because it is unstable,
  non-reproducible, and unnecessary.
- **One mutable status dictionary duplicated per projectile:** rejected because
  simultaneous elemental roots would multiply avoidable hot-path allocation.
- **Keeping mutually exclusive elemental roots:** rejected because it conflicts
  with the accepted expectation that run upgrades stack and makes branch
  descendants opaque.
- **Another linear XP curve with a low cap:** rejected because it cannot make
  early choices frequent while still increasing later requirements.

## Ownership and Data Flow

```text
DrownedRuinField candidate data
        |
        v
VehicleFieldLayoutGenerator -- seed + validation --> VehicleFieldLayout
        |                                                |
        |                     +--------------------------+-------------------+
        |                     |                          |                   |
        v                     v                          v                   v
StageBackdrop          VehicleStageRules          PursuitField      Minimap/debug
visible cover          movement/LOS/shots         cached costs       same rectangles

VehicleCombatStages roles/times
        |
        v
VehicleEncounterRuntime --> VehicleSpawnAllocator(player, visible rect, layout anchors)
        |
        v
existing bounded enemy store
```

- `VehicleFieldLayoutGenerator` owns generation and validation only. It does not
  draw, move actors, or schedule encounters.
- `VehicleFieldLayout` owns one run's selected immutable data. It does not know
  active actors or UI.
- `VehicleSpawnAllocator` owns anchor choice and directional grouping only.
  `VehicleEncounterRuntime` remains the schedule/cue/queue owner.
- `VehicleRun` remains orchestration glue and must not absorb generation rules,
  coordinate tables, status formulas, or UI drawing.
- Card compatibility remains in `VehicleUpgradeCatalog`; build levels remain in
  `VehicleRunBuild`; status math remains in `VehicleStatusRuntime`.

## Expected File Ownership

### New files

- `scripts/vehicle/vehicle_field_layout.gd`
- `scripts/vehicle/vehicle_field_layout_generator.gd`
- `scripts/encounters/vehicle_spawn_allocator.gd`
- `scripts/combat/vehicle_status_profile.gd`
- `tools/validation/validate_vehicle_damage_feedback.gd`
- `tools/validation/validate_vehicle_field_layout_generation.gd`
- `tools/validation/validate_vehicle_status_stacking.gd`
- `art/audio/vehicle/sfx/player_hull_hit.wav`

### Existing owners expected to change

- `scripts/vehicle/vehicle_run.gd`
- `scripts/vehicle/stages/drowned_ruin_field.gd`
- `scripts/vehicle/stages/vehicle_combat_stages.gd`
- `scripts/vehicle/vehicle_stage_catalog.gd`
- `scripts/vehicle/vehicle_stage_rules.gd`
- `scripts/vehicle/vehicle_stage_backdrop.gd`
- `scripts/enemies/vehicle_pursuit_field.gd`
- `scripts/encounters/vehicle_encounter_director.gd`
- `scripts/encounters/vehicle_encounter_runtime.gd`
- `scripts/presentation/vehicle_combat_renderer.gd`
- `scripts/presentation/vehicle_audio_director.gd`
- `scripts/ui/vehicle_stage_ui.gd`
- `scripts/combat/vehicle_projectile_state.gd`
- `scripts/combat/vehicle_status_runtime.gd`
- `scripts/cards/vehicle_run_build.gd`
- `scripts/cards/vehicle_upgrade_catalog.gd`
- the nine elemental `.tres` resources under `data/cards/vehicle/`
- `tools/audio/generate_vehicle_sfx.py`
- focused validators under `tools/validation/`
- `localization/vehicle_stage.csv`
- `docs/product/vehicle_game_spec.md`
- `docs/design/UI_VISUAL_SYSTEM.md`
- `README.md`

Do not add generation logic to `vehicle_run.gd`, card behavior to UI, or
collision-specific alternate coordinates to the backdrop.

## Milestones and Checklist

### Phase 0 — Baseline and fixture lock

- [ ] Re-read root/local agent guidance, both active related ExecPlans, the
  product spec, visual system, and performance evidence.
- [ ] Run the current focused validators for run, encounter, layout, navigation,
  experience, upgrades, renderer, HUD, audio/rewards, bosses, and performance
  scenarios; save only concise failure evidence.
- [ ] Capture one fixed-seed `1280×720` Korean frame containing ordinary
  projectiles, the player, cover, a pickup, and the HUD.
- [ ] Record current counts, seed behavior, and performance scenario output;
  do not reinterpret a pre-existing failure as caused by this plan.
- [ ] Confirm the worktree and identify unrelated user changes before editing.

**Acceptance:** the implementation has a reproducible baseline or a specifically
recorded pre-existing failure. No production file changes in this phase.

### Phase 1 — Damage feedback and hostile projectile fairness

- [ ] Add exact hit/invulnerability timers and snapshot fields in
  `vehicle_run.gd`; preserve barrier and dash rejection semantics.
- [ ] Add deterministic ship-only recoil, coral hit/invulnerability rendering,
  reduced-motion behavior, and the reduced `3 px` hit-camera response in the
  retained renderer path.
- [ ] Add the delayed HP-loss segment with active-only processing to
  `HealthPips`.
- [ ] Generate and register `player_hull_hit.wav`; route `hurt` to it and update
  audio completeness checks.
- [ ] Centralize effective hostile speed, set multiplier to `1.00`, and use the
  result in spawn motion and boss prediction.
- [ ] Apply exact ordinary/boss hit and render radii plus the `36 px` trail.
- [ ] Add/update focused damage, boss-pattern, projectile-store, renderer, HUD,
  rewards/audio, and integrated-run assertions.

**Acceptance:**

- One accepted hit visibly and audibly reads at the ship without looking at HP.
- Further contact/projectile damage inside `1.00 s` removes no additional HP
  and does not restart feedback.
- Fully absorbed barrier damage does not produce hull feedback.
- Reduced motion preserves clarity without jitter or flicker.
- Prediction uses the same final speed as projectile velocity.
- Damage, attack cadence, hostile capacity, and enemy totals are unchanged.

**Stop condition:** any visual effect changes collision/aim position, creates
nodes per hit, or makes a projectile visual smaller than its collision radius.

### Phase 2 — Seeded layout model and exhaustive generation validator

- [ ] Add the exact cover, arrival, stationary, and item candidate constants to
  `DrownedRuinField`; remove the thirteen old internal covers from static
  catalog collision.
- [ ] Implement `VehicleFieldLayout` as the run-owned data contract with seed,
  fingerprint, selected rectangles, valid anchors, and per-stage object
  blueprints.
- [ ] Implement `VehicleFieldLayoutGenerator` with isolated sub-seeds, 32
  attempts, exact selection counts, validation invariants, and locked fallback.
- [ ] Add a lightweight runtime-cover broadphase cache owned by the layout so
  projectile motion does not scan unrelated geometry or allocate.
- [ ] Add `--layout-seed` parsing and seed/fingerprint debug fields without
  changing normal deployment UI.
- [ ] Build the exhaustive `1296` cover-mask validator and 256 complete seeded
  layout fixtures, including same-seed equality and different-seed variation.

**Acceptance:**

- Every mask passes radius-36 and radius-76 reachability and visible/collision
  clearance.
- Every generated/fallback layout has exactly eight covers, at least sixteen
  valid ordinary anchors, four valid stationary positions per stage, three
  pickups, and five crates.
- Same run seed/stage produces the same canonically ID-sorted layout blueprint
  and fingerprint; at least 90% of adjacent tested seeds differ in cover mask
  or object placement.
- Generation completes before play and performs no work in `_physics_process`.

**Stop condition:** fallback fails, any seed produces an unreachable required
socket, or generation silently deletes required content.

### Phase 3 — One geometry truth through presentation, physics, and navigation

- [ ] Create a new layout only on new-run deployment; reuse it on
  `_advance_stage()` and `_restart_stage()`.
- [ ] Replace empty runtime-cover seams with the layout's cached rectangles.
- [ ] Route movement, LOS, beam endpoints, repair targeting, all player/enemy
  projectile cover hits, minimap, and collision debug through the layout.
- [ ] Make projectile broadphase check static floor/boundary plus runtime cover
  instead of gating runtime cover behind static catalog cover.
- [ ] Configure `VehiclePursuitField` with the layout once, include it in cached
  radius-36/radius-76 walkability, and preserve staggered rebuild cadence.
- [ ] Configure `VehicleStageBackdrop` with layout and redraw only when its
  fingerprint changes.
- [ ] Populate stationary enemies, pickups, and crates from layout stage
  blueprints; exact retries reproduce positions and collected state resets.
- [ ] Mark the minimap static channel dirty only when layout fingerprint changes.
- [ ] Retire catalog methods whose only purpose was to return fixed positioned
  stationary/items; keep role/count analysis separate from positioned runtime
  blueprints.
- [ ] Update layout, navigation, single-field campaign, renderer, minimap/HUD,
  run, and projectile collision validators.

**Acceptance:**

- Every visible wall blocks player, enemies, ordinary/boss projectiles, LOS,
  and pursuit; no invisible wall blocks any of them.
- A fixed seed looks and collides identically across all five stages and a stage
  retry.
- A new run seed changes the allowed modular selection without changing field
  size, floor topology, central start, water, or motifs.
- The minimap and debug overlay match the backdrop at every selected wall.
- Runtime cover produces no per-frame array duplication or navigation rebuild.

**Stop condition:** a system needs a second geometry list, a stage transition
changes wall positions, or runtime cover is omitted from projectile broadphase.

### Phase 4 — Distributed arrivals and role composition

- [ ] Remove packet-wide anchor selection from `VehicleCombatStages` while
  preserving triggers, beats, squads, role multiset, and counts.
- [ ] Implement `VehicleSpawnAllocator` with exact distance, off-screen
  preference, recent-anchor exclusion, angular-sector, grouping, and seed
  contracts.
- [ ] Pass player position, visible-world rectangle, layout anchors, and the
  encounter sub-seed at packet activation without moving selection into the
  physics hot loop.
- [ ] Schedule each squad at its own cue/anchor with exact beat concurrency,
  group gap, cue lead, and unit spacing.
- [ ] Deterministically reorder the existing role bag to satisfy pursuit and
  direct-projectile composition; never alter role totals to satisfy it.
- [ ] Extend debug snapshots with chosen squad anchor, player distance, visible
  status, angular sector, cue time, and role composition.
- [ ] Update encounter pacing, stage layout, navigation, performance scenario,
  single-field campaign, and run validators.

**Acceptance:**

- No cue contains more than five units.
- Eight-squad packets use eight distinct anchors when eight valid anchors exist.
- Early/later simultaneous sectors and angular arcs never exceed the locked
  limits.
- Every non-scout squad satisfies pursuit/direct-projectile composition.
- Five-stage authored counts, quotas, role totals, caps, and XP totals are
  unchanged.
- Same seed/player fixture produces the same anchor schedule; invalid,
  unreachable, covered, or too-close candidates are never selected.

**Stop condition:** distribution raises active/enemy totals, removes cue time,
spawns on screen when an off-screen valid candidate exists, or uses RNG each
frame.

### Phase 5 — XP curve and independent elemental trees

- [ ] Replace the XP requirement formula and assert the exact first fifteen
  values and five-stage `6/4/2/4/3` quota-path cadence.
- [ ] Remove `element_core` state/exclusion and change the three capstone
  requirements to their intermediate cards.
- [ ] Add `VehicleStatusProfile`; rebuild it only on reset/card application and
  store direct references on projectile state.
- [ ] Implement exact bounded burn, poison, and chill stack rules and
  independent coexistence.
- [ ] Make Flashover/Shatter consume only their own status; keep Contagion
  bounded and preserve attribution/lifesteal rules.
- [ ] Implement one guaranteed eligible child offer for owned branches without
  exposing locked descendants or removing other roots.
- [ ] Move world status presentation into the retained `128 × 3` arc batch and
  remove procedural per-enemy status drawing.
- [ ] Add Korean/English status-and-stack text to target/boss state snapshots
  and update localization parity.
- [ ] Update experience, upgrade, status, primary-opening, projectile-pool,
  renderer, localization, HUD, and integrated-run validators.

**Acceptance:**

- The exact curve and cadence pass with unchanged XP drops.
- A run can own all three roots and eligible descendants.
- A hit applies every owned root; each status obeys its own cap and duration.
- Projectiles already in flight retain the profile active when fired.
- No per-shot status dictionary duplication or per-enemy procedural status
  geometry remains.
- Korean and English show truthful localized stacks without clipping.

**Stop condition:** one element erases another, a child can appear before its
prerequisite, a card offer has fewer than three valid choices when three exist,
or status presentation breaches retained capacities.

### Phase 6 — Integrated reconciliation and handoff

- [ ] Run every focused validator after its owner changes, then the complete
  suite once after integration.
- [ ] Run native import/boot and Web export from the Godot 4.7 wrapper.
- [ ] Capture fixed-seed gameplay at `960×540`, `1280×720`, and `1920×1080`,
  Korean and English, reduced motion off/on.
- [ ] Inspect accepted hit, invulnerability, barrier-only absorption, ordinary
  and boss shots, two distributed arrival groups, two different run seeds,
  same-seed stage transition/retry, pickup/crate placement, minimap, three
  simultaneous elements, and early level-up modal.
- [ ] Run one current-pressure and one boss-pressure development regression
  sample with the fixed layout seed and compare counts/tails to the active
  performance thresholds; do not run the deferred release matrix.
- [ ] Update `vehicle_game_spec.md`, `UI_VISUAL_SYSTEM.md`, and `README.md` with
  accepted behavior and remove stale immutable-cover/element-exclusion text.
- [ ] Run `git diff --check`, stale-reference searches, a task-scoped
  code-quality audit, and an agent-document lifecycle audit.
- [ ] Commit coherent phase-owned changes only.
- [ ] After all accepted behavior is durable in the specs and all gates pass,
  mark this plan complete for the handoff commit, then delete it according to
  `.agents/PLANS.md`.

**Acceptance:** all listed functional, visual, localization, capacity, native,
Web, and development performance gates pass from the same clean code state.

## Test Plan and Validation Cadence

### Focused commands

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_damage_feedback.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_boss_patterns.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_combat_renderer.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_field_layout_generation.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_layouts.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_navigation_clearance.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_encounter_pacing.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_experience.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_upgrade_system.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_status_stacking.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_rewards_ui_audio.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_run.gd
```

### Full validation, boot, and export

```powershell
Get-ChildItem tools/validation -Filter *.gd | Sort-Object Name | ForEach-Object {
  .\tools\godot.ps1 --headless --script ("res://tools/validation/" + $_.Name)
  if ($LASTEXITCODE -ne 0) { throw "Validation failed: $($_.Name)" }
}

.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --quit-after 2
.\tools\export_web.ps1
git diff --check
git status --short
```

### Rendered evidence

- Use fixed layout seed `0xC4A2B0` for before/after comparisons and one second
  non-default seed to prove allowed variation.
- Verify ship feedback remains visible over light and dark floor tones and does
  not resemble an enemy.
- Verify reduced motion removes displacement/flicker while retaining a clear
  invulnerability state.
- Verify ordinary shot heads remain visibly larger than their collision radius,
  boss shots remain distinct, and trails do not obscure small enemies.
- Verify cues identify every distributed arrival before units appear and no
  group creates a simultaneous 360-degree surround.
- Verify every wall edge is visually unambiguous and exactly matches collision,
  LOS, projectile impact, minimap, and pursuit behavior.
- Verify Korean and English target status text, early XP, upgrade choices, and
  HP trail at all three supported resolutions.

### Development performance gate

- Preserve current scenario populations and fixed capacities.
- Run `current_pressure` and `boss_pressure` using the existing scenario
  harness, a fixed layout seed, the standard warmup, and at least a 30-second
  foreground sample.
- Apply the active stabilization thresholds:
  - capacity simulation p95 `≤ 6.0 ms`, p99 `≤ 8.0 ms`;
  - native `1280×720` frame p95 `≤ 18 ms`, p99 `≤ 25 ms`, with no two
    consecutive post-warmup frames over `33.3 ms`;
  - total engine draw-call p95 `≤ 200`.
- Treat the run as a regression gate, not release certification. The full
  platform/resolution repetition and lifecycle soak remain deferred.

### Rerun policy

- Rerun a failed focused validator only after a relevant code/data change or a
  new falsifiable hypothesis.
- Rerun the full suite only after all focused failures are repaired.
- Do not lower entity counts, capacities, visual resolution, or test duration to
  manufacture a pass.

## Predetermined Error Handling and Contingencies

- **No preferred off-screen spawn anchor:** use the farthest valid reachable
  anchor after enforcing the `0.9 s` cue; never spawn in cover or silently skip
  the squad.
- **Fewer than eight unique eligible anchors at activation:** use every eligible
  anchor once, then reuse the farthest one in recent-use order. Record the
  fallback in the debug timeline.
- **A generated candidate set fails:** advance the deterministic attempt counter
  up to 32; then use the locked fallback. Never repair a layout during play.
- **The locked fallback fails validation:** fail the implementation gate and
  amend this plan; do not weaken reachability or clearance.
- **Status profile missing/null:** treat it as no elemental status, record a
  debug assertion in validation, and never allocate a replacement per shot.
- **Retained status batch reaches capacity:** this is an invariant failure
  because `128 enemies × 3 statuses` is the exact cap; do not grow dynamically.
- **Performance threshold fails:** inspect the measured dominant subsystem and
  correct it within retained layout/status/spawn ownership. Do not lower enemy
  count, projectile count, or feedback requirements.
- **Rendered/collision disagreement:** the runtime layout array wins as truth;
  repair the consumer and fail the visual gate until both agree.

## Rollback and Safety

- Implement each phase as a coherent scoped commit. Do not stage unrelated user
  changes.
- Phase 1 can be reverted independently because it changes no save schema.
- Phases 2–4 form one layout/encounter migration boundary: keep old fixed owners
  only until the new path passes its focused gate, then remove them in the same
  phase lineage. Do not leave two permanent geometry systems or a feature flag.
- Phase 5 changes only run-scoped build/status state. It must not write a save
  migration or persistent progression data.
- Existing settings and guidebook persistence IDs remain unchanged.
- Generated capture, Web, and performance artifacts stay ignored. Commit only
  production assets, source, validators, specs, and bounded durable evidence.
- No dependency, engine, force-push, hard reset, or destructive cleanup is
  authorized by this plan.

## Risks and Mitigations

- **Risk: longer invulnerability makes rapid contact too forgiving.**
  - Mitigation: this plan changes no enemy count or damage; validate accepted
    hit cadence separately and reassess difficulty only after this isolated
    behavior is playable.
- **Risk: more spawn locations create unfair crossfire despite fewer units per
  point.**
  - Mitigation: exact angular arc, concurrent-sector, distance, off-screen
    preference, and cue contracts bound simultaneous pressure.
- **Risk: randomized cover creates unreachable pockets or hidden blockers.**
  - Mitigation: small authored candidate set, exhaustive mask validation,
    two actor radii, one geometry source, 32 attempts, and one validated
    fallback.
- **Risk: layout RNG becomes non-reproducible after unrelated code changes.**
  - Mitigation: versioned independent sub-seeds and seed/fingerprint telemetry.
- **Risk: multiple elemental effects cause allocation or draw-call regression.**
  - Mitigation: one typed shared profile per build revision, bounded enemy
    dictionaries, one retained status batch, and no per-shot deep copy.
- **Risk: faster early XP pauses combat too frequently.**
  - Mitigation: the exact quota-path cadence is validated; queued levels already
    serialize one mandatory choice at a time, and no threshold decision is left
    to implementation.
- **Risk: removing catalog-static cover invalidates fast spatial caches.**
  - Mitigation: retain static floor/water caches, add one eight-rectangle
    runtime broadphase, and test projectile/movement/navigation consumers
    independently before deleting fixed-cover assumptions.
- **Risk: fixed coordinate candidates do not satisfy the intended exhaustive
  gate.**
  - Mitigation: Phase 2 validates all combinations before production wiring;
    failure triggers plan amendment, not an ad hoc coordinate choice.

## Open Questions

None. Difficulty tuning and death-persistent progression are intentionally
outside this plan and require a separate accepted product decision after these
combat-readability changes are playable. Any new ambiguity that changes the
locked contracts must amend the plan before implementation.

## Decision Notes

- 2026-07-24: chose one run-scoped seeded layout instead of per-stage
  randomization so players can learn and exploit the field during a run.
- 2026-07-24: chose an authored socket/mask generator instead of unconstrained
  procedural topology so every visual route can be exhaustively validated.
- 2026-07-24: retained all authored enemy totals and stats; projectile and
  invulnerability changes are isolated from difficulty tuning.
- 2026-07-24: distributed squads across distinct anchors with bounded angular
  concurrency instead of simply adding more simultaneous spawn directions.
- 2026-07-24: selected a one-second post-hit invulnerability and ship-local
  feedback instead of a full-screen damage overlay.
- 2026-07-24: selected a rising quadratic XP curve with an exact early sequence
  instead of another low linear cap.
- 2026-07-24: removed elemental exclusivity and made explicit prerequisite
  chains; no cross-element combo-card expansion is included.
- 2026-07-24: preserved the active performance architecture and deferred its
  release matrix rather than repeating it during unsettled gameplay design.
