---
type: plan
status: active
owner: BK
created: 2026-08-06
scope: Replace overlapping map blockers and stationary hazards with run-fixed inner walls, broad traversable hazard zones, and stage-scoped mystery devices
related:
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../cardborne-performance-engineering-policy.md
  - ../cardborne-runtime-architecture-audit.md
---

# Map Structure, Hazard Zone, and Mystery Device Implementation

## Purpose

Implement the user's simplified map language in the current Godot 4.7 codebase. One
run keeps a deterministic set of varied inner-wall groups and broad traversable hazard
zones. Each stage scatters reward crates, loose pickups, and three mystery devices.
The change removes map systems whose jobs overlap: independent cover, stationary enemy
installations, Arc Surge, Wear Collapse tiles, repair/overdrive pads, and breakable
reward rooms.

This plan is executable. No product choice blocks code work. New raster candidates are
an approval gate for production visual switching, not a blocker for layout, simulation,
localization, documentation, or focused headless validation.

## Why and Context

The current map has too many stationary elements that damage actors or interrupt
movement while using different names and rules. Eight independent covers, stationary
enemy roles, Arc Surge strips, Wear Collapse tiles, support pads, and breakable reward
rooms compete for the same tactical space. The user wants fewer categories, simpler
placement, and larger permanent ground hazards that read like swamp or lava rather than
thin pass-through walls.

The current owners are already suitable for an incremental replacement:

- `VehicleFieldLayoutGenerator` owns deterministic run/stage placement.
- `VehicleStageTacticalLayout` owns immutable collision and object blueprints.
- `VehicleTerrainRuntime` owns low-count field mechanics and transit state.
- focused runtime classes should own mystery-device health/outcomes instead of adding
  another rule set directly to `VehicleRun`.
- `VehicleRun` remains the orchestrator and damage-attribution boundary.
- the product and visual specs own durable behavior and presentation contracts.

The field remains `7200x4320`, starts at `(3600, 2160)`, uses the existing 96-unit
layout grid, and preserves the 560-unit start-safe radius.

## Domain Alignment

Use these canonical terms in new code and durable documentation:

| Term | Meaning | Owner | Not this |
| --- | --- | --- | --- |
| `inner_wall` | Run-fixed solid structure made from one or more rectangles; blocks movement, projectiles, and line of sight | run field layout, terrain runtime, and geometry snapshot | independent `cover`, destructible object, damage source |
| `hazard_zone` | Run-fixed broad traversable ground footprint; refreshes neutral lingering field exposure | terrain runtime | wall, node, mine, Arc Surge window, player status payload |
| `mystery_device` | Stage-scoped neutral destructible object with one hidden beneficial battlefield effect | mystery-device runtime | enemy, crate, hazard source, quota target |
| `transit_gate` | Run-fixed paired player movement utility | terrain runtime | damage facility or mystery outcome |
| `crate` | Stage-scoped destructible reward container | existing crate runtime | mystery device or wall |
| `pickup` | Stage-scoped immediate repair/experience-recall item | existing pickup runtime | support pad |

`field_exposure` is an internal environmental timer. It is not the player's burn,
poison, or chill build status. Callers only ask the terrain runtime for due neutral
damage; timer storage, overlap refresh, and expiration remain hidden there.

## Scope

### Included

- Replace the eight independent covers with five run-fixed inner-wall groups selected
  from six templates without replacement.
- Generate four broad run-fixed hazard zones and select one run-wide visual/affinity
  variant: toxic bog or lava pool. Both variants use the same gameplay rule.
- Remove Arc Surge, Wear Collapse, repair/overdrive pads, reward bulkheads/enclosures,
  and map-spawned stationary enemies from the active run.
- Keep two paired Transit Gate routes as movement-only utilities.
- Add three stage-scoped mystery devices with hidden, deterministic, non-duplicated
  outcomes.
- Keep six loose pickups and eight crates per stage, but scatter them with explicit
  spacing and remove guarded reward positions.
- Preserve ordinary enemy quota, XP shard, and damage-attribution behavior.
- Update Korean and English names/descriptions, guidebook entries, product rules,
  visual rules, deterministic fingerprints, snapshots, and focused validators.
- Prepare ImageGen raster candidates using the canonical Cardborne style sheet as an
  actual reference. Do not promote candidates until the user approves the exact files.

### Non-Scope

- No maze generator, navmesh rewrite, global hazard avoidance, or per-frame path search.
- No new engine, dependency, thread, generic object pool, atlas, or renderer rewrite.
- No mid-stage respawn or relocation of walls, hazards, devices, crates, or pickups.
- No damage, dud, trap, healing, XP, or random-loot mystery outcome in the first pool.
- No separate bog and lava balance rules; only affinity and presentation differ.
- No production visual switch without exact asset approval.
- No release-performance claim from focused validators or export alone.

## Locked Geometry and Counts

All dimensions and placement origins snap to the 96-unit grid. Inner-wall thickness is
192 units. Each group is one tactical object but may compile to two collision rectangles.

### Inner-wall template bag

| Template | Rectangle composition | Bounding size | Purpose |
| --- | --- | ---: | --- |
| `i_short` | `768x192` | `768x192` | brief straight sight break |
| `i_long` | `1152x192` | `1152x192` | long lane split |
| `l_small` | `768x192` plus `192x576` sharing one end | `768x576` | two-angle retreat |
| `l_large` | `960x192` plus `192x768` sharing one end | `960x768` | large route bend |
| `t_small` | `960x192` plus centered `192x576` | `960x576` | three-way lane split |
| `step` | two `576x192` bars offset by `384x384` | `960x576` | staggered sight break |

Select exactly five templates without replacement. Rotate by 0/90/180/270 degrees.
Do not generate U, C, O, closed rooms, reward pockets, or touching wall chains. A group
must remain at least 384 units from another group by rectangle-edge distance.

### Hazard footprints

| Template | Size | Typical crossing |
| --- | ---: | --- |
| `pool_wide` | `768x576` | broad local pool |
| `pool_large` | `960x576` | medium route pressure |
| `pool_long` | `1152x480` | long ground band, still at least 480 units wide |
| `pool_deep` | `864x672` | deep open-area pool |

Use all four once per run, with 90-degree rotation allowed. Their combined area is about
6.8% of the full field, large enough to change a route without becoming a wall. Every
zone stays at least 576 units from another hazard by edge distance, 192 units from an
inner wall, 384 units from gates and stage rewards, and outside the 560-unit start-safe
radius. Hazard zones have no collision.

### Stage content

| Element | Count | Lifetime | Minimum spacing |
| --- | ---: | --- | --- |
| mystery device | 3 | until broken; no stage respawn | 960 center-to-center; 576 from gates/hazards; 480 from rewards |
| reward crate | 8 | until broken; no stage respawn | 672 center-to-center; 384 from hazards; 576 from devices |
| loose pickup | 6 | until collected; no stage respawn | 384 center-to-center; 384 from crates/hazards; 480 from devices |
| transit gate | 4 endpoints / 2 pairs | fixed for run | existing authored endpoints, reserved radius 96 |

Stage transition creates a new deterministic device/crate/pickup layout. Walls, hazards,
gates, exploration, player position, build, and aim persist across all five stages.

## Placement Algorithm

Keep the algorithm bounded and easy to inspect:

1. Divide the field conceptually into a `6x4` macro-cell grid. Candidate centers are
   snapped to 96 units before validation.
2. Shuffle the 24 cells from the run seed.
3. Place five different wall templates in spread cells. Reject only overlap, reserved
   footprints, start clearance, floor/void escape, wall clearance, and failed ordinary/
   boss flood-fill reachability.
4. Place the four hazard templates in remaining spread cells. Hazards do not participate
   in reachability because they are traversable.
5. Use at most 24 deterministic attempts. If they fail, compile one field-specific,
   code-owned fallback arrangement and mark `used_fallback` in the snapshot.
6. At each stage, shuffle reachable 96-grid content candidates. Round-robin through
   macro cells so devices, crates, and pickups do not clump. Apply the spacing table and
   run one final reachability check for every stage target.
7. Use a deterministic stage fallback when content placement fails. Never relax spacing
   silently and never retry during play.

The generator performs this work once before play or stage compilation. Runtime does not
score layouts, rebuild flood fill, or move static content.

## Hazard-Zone Rules

- Select `toxic_bog` or `lava_pool` once from the run seed. All four zones in that run
  share the selected presentation and damage-source label.
- Entering or remaining inside any zone refreshes `field_exposure` to 2.5 seconds.
- First contact produces one immediate tick. Further ticks occur every 0.75 seconds.
- Leaving the zone does not end exposure; ticks continue until the 2.5-second timer
  expires. Re-entry refreshes the timer but never stacks another exposure.
- Tick damage starts at 5 player hull, 8 ordinary/elite enemy health, and 3 boss health.
  These are explicit first-QA tuning values, not hidden affinity scaling.
- The player, ordinary enemies, elites, and stage boss are valid targets. Projectiles,
  crates, mystery devices, and boss objective nodes are not.
- Enemy AI does not intentionally attack, globally avoid, or re-route around a hazard.
  Existing local collision recovery remains unchanged because the zone is not solid.
- Damage is neutral (`player_owned=false`). If it kills an ordinary enemy, the normal
  quota advances and an XP shard drops. It does not trigger player-owned kill effects.
- Track at most the player plus current hostile capacity. Use existing enemy stable IDs,
  reuse caller-owned buffers, and remove exposure state on actor retirement/stage reset.

## Mystery-Device Rules

- Use the user-facing name `미확인 장치` / `Mystery Device`.
- Physical footprint: 192-unit authored body, 84-unit collision/target radius, 90 health
  (five unmodified 18-damage primary hits).
- It blocks actor movement and player projectiles while intact. Hostile projectiles pass
  through and enemy AI never targets it, so it cannot become an accidental shield.
- Primary fire and player-owned area damage may damage it. Autonomous target selection
  does not choose it. Damage to a device never advances the enemy quota and breaking it
  drops no XP or item.
- Each stage assigns three different outcomes by shuffling the outcome bag from the
  layout seed and stage ID. Outcome identity is hidden from player-facing snapshots until
  break time.
- Breaking reveals a short localized outcome name and applies exactly one effect:

| Outcome | Initial behavior | Important invariant |
| --- | --- | --- |
| `gravity_pull` | pull non-boss enemies within 480 units toward the wreck for 1.2 seconds | no collision damage; boss immune |
| `cryo_lock` | stop non-boss movement and new attack starts within 360 units for 0.8 seconds | committed warned attacks continue; shorter/local than EMP |
| `projectile_purge` | immediately retire hostile projectiles within 420 units | does not affect enemies or player shots |
| `decoy_signal` | enemies within 900 units steer/aim toward the wreck for 6 seconds | they do not attack the device; no global path rebuild |

- The first pool has four outcomes so a three-device stage always omits one. The stage
  contains no duplicate outcome. Later QA may add push, aim deflection, or temporary
  hazard insulation through the same outcome contract.
- The device may retain a resolved wreck only while an outcome needs an anchor, then it
  retires. Maximum live state is three devices and three short outcome states.

## Damage and Quota Relationships

- Devices are neutral objects, not enemies. They are never part of stage population or
  quota totals.
- Hazard damage, not the device, owns a later hazard kill even when pull/decoy moved the
  enemy into the zone.
- Neutral hazard kills call the existing enemy-defeat path with `player_owned=false`;
  quota and XP remain normal.
- Device effects deal zero direct damage in the first implementation.
- Transit, walls, crates, and pickups never become damage sources.

## Runtime and Performance Contract

| Mechanic | Maximum live instances | Update cadence | Spatial path | Presentation | Retirement |
| --- | ---: | --- | --- | --- | --- |
| inner-wall groups | 5 groups / at most 10 rects | static | existing tactical broadphase and exact collision | retained world batch | run end |
| hazard zones | 4 rects | player 60 Hz; enemies on existing terrain update pass | four bounded rectangle tests, exposure dictionary keyed by stable actor ID | one retained world semantic batch | run end; exposure reset at stage boundary |
| mystery devices | 3 | existing object/combat cadence; outcome timers at 60 Hz only while active | direct radius checks against existing stores/grids | one intact/resolved retained semantic family | break/effect end/stage boundary |
| stage rewards | 8 crates + 6 pickups | existing cadence | existing collision/query paths | existing retained batches | break/collect/stage boundary |

Do not raise the 320 hostile, 240 player-projectile, 120 hostile-projectile, 192 XP,
96 effect, 50 combat-batch, 12 world-batch, or 200 draw-call contracts. Focused tests
may prove behavior and batch accounting, but only the active release scenarios can make
a release-performance claim.

## Visual Contract and Approval Gate

The visual authority pair is:

- `docs/design/VISUAL_SYSTEM.md`
- `docs/design/cardborne-universal-art-style-reference.png`

The observed canonical sheet SHA-256 is
`96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
The sheet was inspected at original detail and is style reference only.

Required new raster candidates are:

- toxic-bog ground footprint;
- lava-pool ground footprint;
- mystery-device intact body;
- mystery-device resolved wreck if retained anchoring is required.

The exact transparent approval candidates prepared on 2026-08-06 are:

| Candidate | Size | SHA-256 |
| --- | ---: | --- |
| `tmp/imagegen/hazard_toxic_bog_candidate.png` | `1024x768` | `06e91b352d1fceb7466c30795c4969a3816f21d761a4cb3ac86dfd7592e6e4aa` |
| `tmp/imagegen/hazard_lava_pool_candidate.png` | `1024x768` | `dd551c884139b1836f4c87d8f52309e1eaa7be8e6cfbab456adbc129ebd6a8f5` |
| `tmp/imagegen/mystery_device_intact_candidate.png` | `384x384` | `cfbbc2b42a747c2e0859137c5a7230a7d812203f719e4e9ffeea033b98d5950c` |
| `tmp/imagegen/mystery_device_resolved_candidate.png` | `384x384` | `551cc82e34d5caf244c02981906bd84234a8bd8762ce59ef0bca0dff7bf9825e` |

ImageGen must receive the canonical sheet as an actual referenced image and the prompt
must state that the sheet supplies style grammar only. Candidate generation does not
approve an asset. Keep candidates outside the production manifest until the user approves
the exact file. Logic may use test-only descriptors or remain headless before approval;
do not ship procedural world stand-ins.

## Proposed File Ownership

- `scripts/vehicle/vehicle_field_layout_generator.gd`: bounded wall/hazard/content scatter,
  fallback, spacing, and reachability.
- `scripts/vehicle/vehicle_field_layout.gd`: immutable aggregate of run-fixed features and
  stage tactical layouts.
- `scripts/vehicle/vehicle_stage_tactical_layout.gd`: stage-scoped mystery-device,
  crate, pickup, arrival-anchor, and canonical snapshot data.
- `scripts/vehicle/vehicle_field_geometry_snapshot.gd`: consume structural-wall terrain
  features as blocker truth; retain empty cover compatibility until the shared movement
  and presentation APIs are renamed in a separate refactor.
- `scripts/vehicle/vehicle_terrain_definition.gd` and
  `scripts/vehicle/vehicle_terrain_runtime.gd`: hazard exposure and Transit Gate state;
  delete obsolete Arc/Wear/support/bulkhead state.
- new focused mystery-device runtime owner under `scripts/vehicle/`: device health,
  deterministic hidden outcomes, active effect timers, snapshot privacy, and retirement.
- `scripts/vehicle/vehicle_run.gd`: narrow orchestration, accepted damage calls, device
  projectile contact, outcome application, and renderer snapshots.
- stage field definitions: remove stationary/cover candidate and obsolete terrain feature
  tables; retain floor, void, arrival anchors, item candidate sources, and gates.
- presentation catalogs/renderer: semantic IDs and retained instances only after exact
  asset approval.
- guidebook/locales/damage-source catalog: complete Korean/English terminology and report
  source labels.
- focused validators: layout determinism/spacing/reachability, hazard timing/attribution,
  device outcome privacy/effects, world batch/collision ownership, product-spec sync.

## Tasks

- [x] Inspect current product, visual, layout, terrain, runtime, validation, and
  performance owners.
- [x] Lock terminology, counts, dimensions, lifetime, spacing, damage attribution, and
  performance limits.
- [x] Record the implementation and approval contract in this active ExecPlan.
- [x] Implement run-fixed inner-wall and hazard-zone generation.
- [x] Implement stage-scoped crate/pickup/device scattering and remove guarded rewards.
- [x] Implement hazard exposure runtime and neutral damage integration.
- [x] Implement mystery-device state and four initial outcomes.
- [x] Remove obsolete active systems and stale runtime/guidebook/localization branches.
- [x] Update product and visual specs.
- [x] Generate grounded raster candidates and request exact user approval.
- [ ] Integrate only approved visual files and update the production manifest/catalogs.
- [x] Run focused headless validators and the editor parse/import check; report each pass
  with its precise label.
- [ ] After visual approval, run intended-size/rendered QA, Web export, and
  production-style smoke.
- [x] Run the task-scoped code-quality audit and correct small safe findings.
- [ ] Commit only task-owned files in coherent commits.

## Milestones

### Milestone 1 — Layout model and deterministic scatter

Replace cover IDs/rectangles with inner-wall groups and rectangles, add run-fixed hazard
blueprints, generate stage content with spacing, and update layout fingerprints. Complete
when all three fields compile for multiple seeds, retries are identical, adjacent stages
vary content, every target is reachable, and no forbidden overlap exists.

### Milestone 2 — Hazard and device simulation

Replace Arc/Wear/support/bulkhead runtime branches with hazard exposure and a focused
mystery-device runtime. Integrate neutral damage and zero-damage outcomes through narrow
`VehicleRun` calls. Complete when timing, attribution, privacy, quota, XP, projectile,
and committed-attack rules pass focused tests.

### Milestone 3 — Product, localization, guidebook, and presentation contracts

Update the canonical specs and user-facing copy. Remove obsolete active entries. Wire new
semantic visual roles but keep unapproved candidates out of production. Complete when
Korean/English coverage and static authority validators pass.

### Milestone 4 — Exact visual approval and runtime switch

Generate grounded candidates, show the exact files, obtain explicit user approval, then
copy approved files into the production tree and update manifest/catalog consumers.
Complete when intended-size, grayscale, silhouette, spacing, overflow, world-batch, and
visual-authority validation pass.

### Milestone 5 — Integrated verification and handoff

Run the relevant focused validators first. After implementation stabilizes, run one full
Godot import, Web export, and built production-style smoke if the project path supports
it. Do not run expensive authoritative performance scenarios without the separate
alignment required by project guidance. Complete after the code-quality audit, scoped
commits, durable spec updates, and a truthful handoff.

## Verification

### Layout

- Generate all three field IDs for the default seed plus at least five fixed additional
  seeds.
- Assert five wall groups, unique templates, four unique hazard footprints, 96-grid snap,
  all spacing rules, 560 start clearance, floor containment, and no void overlap.
- Assert ordinary radius 36 and boss radius 76 can reach every authored arrival and every
  stage device/crate/pickup/gate.
- Assert identical seed/field fingerprints reproduce exactly and adjacent stage content
  fingerprints differ.

### Hazard

- Entry causes one immediate tick; repeated calls before 0.75 seconds do not.
- Exit continues damage for exactly the remaining 2.5-second exposure; expiry stops it.
- Re-entry refreshes without stacking.
- Player/ordinary/boss values are 5/8/3 and device/crate/projectile are excluded.
- Neutral lethal enemy damage advances quota and creates XP but does not invoke
  player-owned kill effects.
- Actor retirement and stage transition remove all exposure records.

### Mystery device

- Exactly three devices spawn per stage with unique hidden outcomes.
- Public snapshot before break contains no outcome identity; reveal snapshot after break
  contains the localized outcome ID.
- Five base primary hits break a device; hostile shots and enemy AI ignore it.
- Device break never changes quota and creates no XP/drop.
- Pull, cryo lock, projectile purge, and decoy obey their radii/durations and committed-
  attack invariants.
- All device and outcome state retires at stage transition.

### Presentation and docs

- New user-facing text exists in Korean and English and does not expose hidden outcomes.
- No active guide/spec claims Arc Surge, Wear Collapse, support pads, guarded rewards, or
  four stage stationary threats.
- Surface, outer wall, and inner wall retain the approved solid role colors.
- No unapproved raster enters the production manifest.

## Rollback and Safety

- Keep layout, simulation, documentation, and visual promotion in separate coherent
  commits so an unapproved visual switch can be omitted without reverting gameplay.
- Preserve the unrelated untracked root file `0.0001`; never stage, edit, or remove it.
- Do not rewrite or delete current performance evidence. This product change invalidates
  only future comparisons that do not use matching workload labels.
- If a field cannot compile within the bounded attempts, use the explicit deterministic
  fallback and expose that fact. Do not relax collision or spacing at runtime.

## Risks

- Larger walls can invalidate existing arrival anchors. Mitigation: validate both actor
  radii before accepting a run layout and keep fallback arrangements per field.
- A 2.5-second lingering hazard can punish a slow crossing too heavily. Mitigation: the
  first values are explicit QA knobs; do not change area, duration, and damage together.
- `cryo_lock` can reduce EMP's value. Mitigation: keep it local, 0.8 seconds, non-boss,
  and unable to cancel committed attacks; if QA still shows overlap, replace it with a
  strong slow through the same outcome ID contract.
- `VehicleRun` is already oversized. Mitigation: new state lives in focused runtimes and
  the run only coordinates existing stores and damage calls.
- New ground transparency can increase overdraw. Mitigation: four bounded retained
  instances, no animated full-screen overlays, and retained world-batch validation.
- Exact visual approval may arrive after gameplay code. Mitigation: do not use procedural
  stand-ins or promote candidates early; keep headless/focused behavior tests valid.

## Open Questions

No blocking product question remains. Exact generated raster selection is intentionally
deferred until concrete candidates exist; it is an approval step, not an unspecified
mechanic.

## Decision Notes

- Dedicated cover is removed because inner walls already supply movement restriction and
  temporary attack avoidance.
- A hazard zone is broad ground, not a narrow pass-through wall or small node.
- Bog and lava are one mechanic with two run-wide presentations; this prevents another
  taxonomy split.
- Stationary damage is consolidated into the permanent hazard-zone system. Mystery
  devices are non-damaging interactions, so their role does not overlap.
- Reward crates stay separated and unguarded. Risk/reward pockets can be reconsidered
  only after direct play QA.
- No mid-stage respawn keeps the map readable and the runtime bounded.

## Progress

The deterministic layout, neutral hazard exposure, three-device outcome runtime,
VehicleRun integration, obsolete stationary-map contract removal, bilingual copy, and
canonical spec updates are implemented. The generator passes all three default fields
and the adjacent 48-seed fixture, including deterministic seed-aware fallback behavior.
Focused hazard, mystery-device, live integration, terrain, stage, run, guidebook, and
bilingual localization checks pass. Retired bulkhead/wear/support validators now act as
compatibility sentinels for the replacement contract. The quality audit's minimap-oracle
and fallback-seed findings are corrected.

Four transparent, hashed raster candidates are prepared outside production and have
been shown to the user. The runtime intentionally does not draw the new hazard/device
rasters until the exact four files are approved. The production visual switch, rendered
QA, Web export, production-style smoke, and scoped commits therefore remain open.

## Next Steps

1. Obtain explicit approval or rejection of the four exact hashed candidate files.
2. If approved, copy them byte-for-byte into the production tree and register the four
   semantic asset states without changing collision truth.
3. Run intended-size and gameplay-frame visual QA, remaining focused validators, visual
   authority validation, Web export, and production-style smoke.
4. Update this plan with final rendered evidence and commit only task-owned files while
   preserving the unrelated `0.0001` file.
