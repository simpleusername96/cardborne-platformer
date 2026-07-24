---
type: evidence
status: active
owner: BK
created: 2026-07-24
last_reviewed: 2026-07-24
topic: Vehicle field, terrain, enemy, boss, opening-shot, and guidebook expansion
scope: Current repository evidence, recovered history, external design findings, and the accepted direction for the next execution plan
source: ./execplans/2026-07-24-vehicle-world-combat-expansion.md
related:
  - ./execplans/2026-07-24-vehicle-world-combat-expansion.md
  - ./execplans/2026-07-23-vehicle-performance-architecture-stabilization.md
  - ../docs/product/vehicle_game_spec.md
  - ../docs/design/UI_VISUAL_SYSTEM.md
---

# Vehicle World and Combat Expansion Evidence

## Purpose

Record the facts behind the next field and combat revision before implementation.
This document is evidence and design rationale, not product authority. The
execution-ready decisions live in the related ExecPlan and, when implemented,
must be reflected in the canonical product and visual specifications.

The investigation answers six user concerns:

1. whether directional and periodic-damage terrain previously existed;
2. why the current map has no functional terrain;
3. why walls and floor motifs contradict collision readability;
4. why the one-second opening shot and stationary mine lack a clear tactical
   role;
5. why five bosses still feel similar and weak despite having separate pattern
   lists; and
6. how more maps, enemy types, guidebook visuals, and genre-standard learning
   aids can be added without returning to the previous performance problem.

## Sources

### Repository and history

- Current branch implementation, especially:
  - `scripts/vehicle/stages/drowned_ruin_field.gd`
  - `scripts/vehicle/vehicle_field_layout_generator.gd`
  - `scripts/vehicle/vehicle_stage_catalog.gd`
  - `scripts/vehicle/vehicle_stage_backdrop.gd`
  - `scripts/player/vehicle_primary_weapon.gd`
  - `scripts/enemies/vehicle_enemy_archetypes.gd`
  - `scripts/bosses/vehicle_boss_patterns.gd`
  - `scripts/progression/vehicle_guidebook_catalog.gd`
  - `scripts/ui/vehicle_guidebook_panel.gd`
  - `scripts/presentation/vehicle_combat_visual_library.gd`
  - `scripts/vehicle/vehicle_run.gd`
- `git show 278be30`, which introduced distinct current and storm terrain.
- `git show cb40059`, which replaced five physical stage maps with one shared
  field and removed their functional terrain.
- The current product, visual, and performance contracts linked in the
  frontmatter.
- Current rendered evidence under
  `build/captures/attack-readability-2026-07-24/`.

### Current primary external references

- Housemarque,
  [Creating Returnal's otherworldly enemies](https://blog.playstation.com/2021/04/14/creating-returnals-otherworldly-enemies-vfx-driven-tentacle-tech-and-deep-sea-inspirations/):
  enemy roles are prototyped from gameplay needs, attacks read from the enemy
  body, and melee/ranged combinations are treated as deliberate encounter
  composition.
- Housemarque,
  [The making of Returnal's Hyperion fight](https://blog.playstation.com/2021/05/28/returnal-the-making-of-that-unforgettable-hyperion-fight/):
  phases layer authored sequences, reaction requirements receive distinct
  visual language, and apparent chaos still has to remain avoidable.
- Housemarque,
  [Unpacking Returnal's UX design](https://blog.playstation.com/2021/05/11/unpacking-returnals-ux-design-gameplay-first-ui-retro-futuristic-tech-and-accessibility/):
  immediate combat information belongs near the player or reticle while
  peripheral UI carries secondary state.
- Bad Robot Games,
  [Designing 4:Loop's Scanner boss](https://blog.playstation.com/2026/04/28/4loop-designing-the-ominous-cube-shaped-scanner-boss/):
  a boss should alter required strategy and use of space, not only present a
  different model.
- Supergiant Games,
  [Hades: Welcome to Hell update](https://www.supergiantgames.com/blog/hades-welcome-to-hell-update-patch-notes/)
  and [Hades updates](https://www.supergiantgames.com/blog/hades-updates/):
  trap hitboxes are tuned as combat rules, traps can damage enemies, attack
  effects must remain distinct, and the codex combines encounter knowledge with
  visual identification.
- Santa Monica Studio,
  [God of War gameplay tips and bestiary](https://blog.playstation.com/2022/01/13/god-of-war-on-pc-gameplay-tips-for-tomorrows-launch/):
  encountered-enemy records are useful when they communicate behavior and
  counterplay rather than exposing raw internal statistics.
- Funday Games,
  [Deep Rock Galactic: Survivor news](https://store.steampowered.com/app/2321470/news/):
  run-level field variation can make repeated missions different while each
  individual mission retains one coherent physical space.
- Godot,
  [Resources](https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html)
  and [MultiMesh](https://docs.godotengine.org/en/stable/classes/class_multimesh.html):
  authored data should be separated from runtime presentation, and high-count
  repeated visuals should stay in the existing batched rendering path.

## Findings

### 1. Functional terrain did exist, but it was intentionally removed

Commit `278be30` contained two relevant systems:

| Former field | Mechanic | Exact former behavior |
| --- | --- | --- |
| `tidal_archive.gd` | directional current | Two large horizontal zones pushed the player and player projectiles at `72` or `86 px/s`; a counter-current used `92 px/s`. Enemies were not affected. |
| `storm_drydock.gd` | periodic surge | Two strips used a `5.2 s` cycle. The active window lasted `0.8 s`, and the player took `10` damage every `0.55 s` while inside. Enemies were not affected. |

Commit `cb40059` deleted `tidal_archive.gd`, `storm_drydock.gd`, and the other
three physical stage-map files when the campaign moved to one persistent
`drowned_ruin_field`. The current product specification consequently has no
functional terrain contract. Restoring the old scripts verbatim would also
restore their problems: currents changed player ballistics without affecting
enemies, storm strips repeatedly ticked only the player, and every stage used a
different physical map.

The correct direction is therefore a new shared terrain contract, not a revert.

### 2. The current field has visual collision contradictions

The current field is `5600x3400`, centered at `(2800, 1700)`, and has:

- sixteen overlapping walkable rectangles;
- four peripheral water rectangles;
- sixteen cover candidates, of which eight are selected per run;
- twenty-four ordinary spawn candidates;
- eight boss arrival anchors; and
- four large decorative motifs.

`VehicleStageBackdrop` renders the outside and water as cobalt, walkable floor
as ivory variants, internal cover as ceramic green, and the four motifs as
additional floor graphics. As a result:

- an internal green rectangle and a cobalt gap can both block the ship but do
  not look like the same class of object;
- some narrow negative spaces look open even though the player-radius collision
  test rejects them;
- the four motifs look semantically important despite having no behavior; and
- collision truth is distributed across walkable union, water, selected cover,
  crates, and presentation-specific drawing.

The existing visual specification already says static solid cover should use
one blocker fill. The user's stricter rule is coherent and more testable:
every impassable map edge and internal solid must expose the same wall material,
edge, and shadow.

### 3. “More maps” must not undo the persistent-field campaign

The canonical game flow deliberately keeps one field through all five stages and
retries. Changing physical maps after every boss would contradict that flow and
reintroduce the earlier transition and continuity problems.

A compatible interpretation is run-level field variation:

- a new run selects one authored field from a small set;
- that field remains fixed for all five stages and retries;
- encounter, cover, item, and hazard seeds vary inside the selected field; and
- a subsequent run may select another field.

This supplies map variety without turning stages back into separate rooms.

### 4. The one-second opening shot has numbers but no exclusive job

After one second without primary fire, the current first shot receives roughly:

- `1.75x` health damage;
- `3x` structure damage;
- `3x` stagger;
- `1.5x` radius; and
- one extra pierce.

Those bonuses are real but weakly expressed. Normal held fire resumes after the
shot, no current world object requires it, and the current boss stagger
threshold is `35` while one opening shot supplies only `15` stagger. The player
therefore sees a slightly larger projectile but does not learn a unique reason
to wait.

The opening shot needs named, exclusive interactions:

- breach a designed structure;
- intentionally detonate a mine;
- break a protected enemy plate; and
- stagger a boss during a readable recovery window.

This makes waiting one second a tactical choice without replacing held fire.

### 5. The current mine is a reusable stationary player hazard

The existing stationary mine:

- has `65` health;
- arms when the player enters `190 px`;
- waits `0.62 s`;
- deals up to `16` damage within `205 px`;
- damages only the player;
- recovers for `1.8 s`; and
- can repeat indefinitely.

If player damage removes its health, it is defeated immediately and does not
explode. It cannot become a tactical tool against enemies. The mobile
`spark_minelet` is defined and rendered but is not in the current stage role
sets, so it is effectively dormant content.

A one-shot mine with a readable fuse, player-caused short-fuse detonation, and
enemy friendly fire is both more intuitive and more interactive. Enemy
proximity alone should not arm it: that would resolve encounters without player
intent. The player creates the opportunity by approaching or shooting it.

### 6. Enemy quantity is already high; decision variety is the missing dimension

Current authored stage populations rise from `260` to `420`, quotas from `96`
to `224`, and the ordinary active cap is `72`. The catalog contains many roles,
but several share similar pursuit-and-projectile decisions and one defined
minelet is unused. Increasing the cap would directly conflict with the still
active performance-stabilization acceptance work.

The next content pass should:

- keep the `72` active ordinary-enemy cap;
- activate the existing minelet;
- add a small number of visibly distinct, non-projectile roles;
- roll them out through a teach-combine-test stage curve; and
- use terrain and enemy combinations to create variety inside the same capacity.

“More enemies” therefore means more meaningful archetypes and combinations
first, not five times more simultaneous instances.

### 7. Five boss lists currently collapse into the same runtime grammar

The catalog contains four names per stage, but most definitions resolve to the
same generic kinds: lanes, fan, cross, charge, beam, area, pylons, or summon.
The runtime makes area, pylon, and summon attacks share a similar aimed-burst
execution. The second phase mainly reorders the same four entries and adds one
volley.

Current boss hits already range from `20` to `36`, or about `17–30%` of the
base `120` hull. Raising damage alone would make deaths faster without making
the fights richer. The higher-value changes are:

- three behavioral phases;
- shorter but still readable downtime;
- stage-specific space-control mechanics;
- one authored phase-three combination per boss;
- persistent pursuit/repositioning outside committed attacks;
- unique boss silhouettes; and
- no generic hit reaction that stops movement and attacks.

Threat should come from sustained, legible pressure and changing decisions, not
unavoidable hits or inflated health.

### 8. The guidebook has no visual identification layer

`VehicleGuidebookCatalog` exposes only name and description keys.
`VehicleGuidebookPanel` renders text detail. The combat visual library already
owns a deterministic mesh for every current enemy archetype, including mines
and the stage boss.

The cheapest stable solution is a guidebook preview `Control` that draws those
same meshes. It avoids duplicate raster assets, keeps the guidebook synchronized
with actual combat silhouettes, and can show a neutral placeholder without
leaking locked entries.

### 9. Performance constraints are a design input

The active performance plan still requires final rendered repetitions and a
ten-minute lifecycle soak. Its capacity gates include:

- `p95 <= 18 ms` and `p99 <= 25 ms` at standalone `1280x720`;
- `p95 <= 20 ms` and `p99 <= 33.3 ms` for Web `1280x720`;
- no more than `200` total draw calls at capacity;
- no retired live entities or stale IDs; and
- less than `8 MiB` static-memory growth over the ten-minute soak.

New terrain must use a low-count centralized runtime, new enemy decisions must
use bounded spatial queries, and all repeated visuals must use the existing mesh
and MultiMesh architecture. No design in this pass justifies raising the active
enemy or projectile envelopes.

## Accepted Direction

The related ExecPlan fixes one implementation direction:

1. Three total run-level field layouts in the same Sunken Ceramic Fresco theme:
   `drowned_ruin_field`, `tidal_archive_field`, and
   `storm_drydock_field`. One is selected at run creation and retained for all
   five stages and retries.
2. Zero decorative floor motifs. The motif data, rendering, profile constants,
   validators, and canonical references are removed rather than hidden.
3. One wall material for every impassable map boundary and internal solid:
   ceramic-green fill, one common shadow, and a `48 px` boundary rail whose
   floor-side edge matches the `24 px` base ship clearance.
4. Three initial functional-terrain families:
   - Flow Channel;
   - Arc Surge Strip; and
   - Breakable Bulkhead.
5. The current opening shot becomes `Breach Shot` / `돌파탄`, with exclusive
   structure, mine, protected-enemy, and boss-recovery interactions.
6. Stationary and mobile mines become one-shot, fuse-driven threats whose
   player-triggered explosions can damage enemies and credit their defeats.
7. The existing minelet is activated and three non-projectile enemy roles are
   added: Bulkhead Guard, Relay Scavenger, and Splitter Barge.
8. Each boss receives a unique silhouette, three-phase behavior, and an authored
   stage-specific spatial exam while remaining avoidable at base movement speed.
9. The guidebook renders actual discovered silhouettes and concise
   movement/attack/counterplay hints.
10. Failure results add a localized last-hit and top-three damage-source recap,
    making hazards and boss patterns learnable without adding permanent HUD
    clutter.

## Additional Ideas and Disposition

### Included now because they reinforce the requested changes

| Idea | Why it belongs now |
| --- | --- |
| Teach-combine-test encounter rollout | A new enemy or terrain appears alone, then with one familiar pressure source, then in a boss exam. Variety becomes learnable instead of noisy. |
| Environment damages both sides | Hazards become positioning tools rather than arbitrary player taxes. |
| Damage-source recap | It exposes whether a mine, terrain pulse, contact hit, or boss pattern caused failure and improves tuning evidence. |
| Discovered counterplay in the guidebook | The visual preview answers “what was that?” and the three short hints answer “how do I respond?” |
| Run-level field identity on deployment | The player knows which persistent field was selected without implying that stages change maps. |

### Worth a later plan, but deliberately excluded from this implementation

| Candidate | Potential value | Why deferred |
| --- | --- | --- |
| Boss practice terminal after first encounter | Lets players learn patterns without replaying a complete run. | Requires a separate mode, save-state rules, and reward exclusions. |
| Optional danger beacon | Lets the player voluntarily trigger a dense elite encounter for an extra card choice. | Reward economy and encounter-placement work should follow the core field revision. |
| One-modifier elite enemies | Adds recognizable variants such as armored, fast, or spawning. | Needs strict visual vocabulary and budget rules after the three new base roles prove readable. |
| End-of-run tactical timeline | Could show upgrades, bosses, damage, and cause of death. | The compact damage recap supplies the immediate learning need first. |
| Accessibility presets for telegraph shape and screen shake | Broadens readability and comfort. | Existing reduced-motion and settings behavior should be audited as a separate accessibility pass. |

### Rejected for this pass

- A different physical map for every stage.
- Unbounded procedural topology.
- More than `72` simultaneous ordinary enemies.
- Restoring projectile drift inside currents.
- Enemy-only or player-only environmental damage.
- Per-enemy guidebook scenes or duplicated raster portraits.
- New loot currencies, a base stage, exploration puzzles, meta progression, or
  a new item taxonomy.
- Raw boss damage or health inflation as the primary difficulty solution.

## Conclusion

The user's remembered terrain was real, but it belonged to the discarded
multi-map implementation and should not be copied back. The coherent revision
is a persistent run-level field selected from three authored layouts, with one
wall truth, zero decorative motifs, three mutually interactive terrain
families, and combat roles that teach the player how to exploit those systems.
This also gives the Breach Shot, mines, bosses, and guidebook purposes that the
current implementation does not express.
