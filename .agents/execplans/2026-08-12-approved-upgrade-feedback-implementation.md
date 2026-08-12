---
type: plan
status: active
owner: BK
created: 2026-08-12
last_reviewed: 2026-08-12
topic: Implementation of the approved upgrade review and its gameplay, UI, visual, and documentation consequences
scope: Run-scoped upgrade catalog, damage and utility attributes, passive secondaries, Shift active weapons, conditional damage, HUD and upgrade UI, localization, validation, and durable product specifications
source: ../../docs/reports/2026-08-12-cardborne-upgrade-feedback.json
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../design/DESIGN.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/product/vehicle_upgrade_catalog.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/reports/2026-08-12-vehicle-upgrade-categories-and-skill-tree-ko.html
  - ./2026-08-12-faster-early-level-progression.md
  - ./2026-08-12-player-facing-language-simplification.md
  - ./2026-08-11-dense-combat-progression-and-run-completion.md
---

# Approved Upgrade Feedback Implementation Plan

## Purpose

Turn BK's saved review of the 47 report entries into one implementation-complete
upgrade contract. The result removes the one rejected live card, retains the approved
live behaviors unless a note explicitly changes them, adds the seven approved proposed
cards, adds the second utility attribute requested in the Cryo note, and updates every
affected gameplay, UI, visual, localization, validation, and product owner.

This is an execution plan, not another idea list. All material gameplay choices and
initial balance values are fixed below. After implementation moves the accepted behavior
into the active product and visual specifications, delete this plan as required by the
repository plan lifecycle.

## Why and Current Context

- The saved feedback contains 47 reviews: 27 approved, 20 rejected, and 13 with notes.
- Twenty of the approved entries already exist in the runtime. Seven approved entries
  are proposed cards that do not yet exist.
- `range_polarization` is the only existing runtime card that BK rejected and explicitly
  asked to delete.
- The Cryo note changes the model from one exclusive element slot to one damage-attribute
  slot plus one utility-attribute slot and asks for a second utility choice.
- The active report is evidence and a review tool, not runtime authority. The accepted
  decisions below become product truth only when implementation updates
  `vehicle_game_spec.md`, `vehicle_upgrade_catalog.md`, and `VISUAL_SYSTEM.md`.
- The feedback is now preserved losslessly in the repository. All 47 IDs, approval values,
  and notes are equal to the source export. The source download SHA-256 is
  `9a42bc79c3a5023eea27c380a8331f335c225ffa701e48f915f10a8a86603de9`; the normalized
  repository JSON SHA-256 is
  `4bdb64fb65444b10221bd170b3e1d5c0b5bfa3079820eef10fb687fccc36fa2c`.

This plan takes precedence over the overlapping upgrade rules in
`2026-08-11-dense-combat-progression-and-run-completion.md`: its range card, rear-facing
laser, one-element exclusivity, EMP-with-no-card-expansion, 21-card/68-state count, and
related acceptance claims are historical after this implementation. That older plan
remains active only for its unfinished dense-combat performance qualification and closeout.

## Discovery Closure

| Decision area | Current evidence | Closed implementation decision |
| --- | --- | --- |
| Feedback integrity | Exported JSON schema v1, 47 stable IDs, repository copy with matching SHA-256 | Treat the repository JSON as immutable evidence; do not depend on browser local storage during implementation. |
| Catalog ownership | `VehicleUpgradeCatalog`, `.tres` card definitions, `VehicleRunBuild` | Add explicit damage/utility and active-kind ownership fields; never infer exclusivity from display names. |
| Save compatibility | Run build levels are not persisted; only unrelated run-clear modules and settings are saved | Delete and rename run-scoped card IDs without save migration. Keep input binding action `active_skill` internally to preserve settings compatibility. |
| Conditional damage | `VehicleOutgoingDamagePolicy` owns critical, range, dash, and low-Hull rules | Remove all range-only flags, parameters, preview rows, tests, data, and copy. Keep deterministic critical sampling internally but expose only ordinary critical-hit language. |
| Passive secondaries | One bounded `VehicleSecondaryRuntime`; Seeker is built in and two of five optional weapons may be equipped | Keep the 2-of-5 optional limit. Add two shared enhancement cards that consume no weapon slot. Rename and retarget Rear Laser as Auto Laser. |
| Mine note | The runtime immediately places one mine, then places behind movement or the stopped hull every `3.2/2.8/2.4/2.4 s`; proximity 54 or eight-second expiry detonates it | Keep behavior unchanged. Preserve direct, plain copy and validator coverage; add no extra control or tutorial. |
| Orbiting Blade note | Gameplay center radius 78, hit radius 22, visual half-size 38; renderer hard-codes only three level counts | Use center radius 88, hit radius 52, visual half-size 52, and publish the gameplay-owned blade count to the renderer so level 4 is valid. |
| Attribute split | Thermal, Toxin, and Cryo are currently one mutually exclusive group in `VehicleElementProfile` | Thermal/Toxin become the exclusive damage pair. Cryo/new Shock become the exclusive utility pair. One choice from each pair may coexist. |
| Active weapons | Shift directly owns EMP state in the oversized `VehicleRun` | Extract one bounded active-weapon runtime and data catalog. EMP is the default kind; one acquired kind card replaces it for the rest of the run. |
| HUD status | HUD has a fixed Dash/Seeker/EMP cluster plus an unrelated centered `buff_text` label | Make the fifth action glyph represent the equipped active weapon. Remove `buff_text`; show Dash Boost with a craft-attached state rail. |
| Upgrade modal | Runtime currently shows three cards only; the active visual specification requires a build-summary rail | Implement the specified two-column modal and add separate damage and utility slots without creating new equipment limits. |
| Visual media | Ten approved shared upgrade artworks and code-native dynamic areas already exist; the production manifest has 63 images | Reuse approved semantic artwork. Add no raster/SVG assets and keep the manifest at 63 images. New live areas and beams are exact code-native geometry. |
| Runtime cost | Dense-combat release performance is still red and current HEAD is not qualified | Capture a comparable clean baseline before hot-path edits, keep every new scan/state bounded, and report functional, visual-budget, native, and Web results separately. |

No material discovery question remains open. Balance observations after the fixed initial
implementation are follow-up evidence, not permission for an executor to invent new cards
or silently change enemy health, counts, or performance thresholds.

## Scope and Non-Scope

### In scope

- Preserve the 20 approved live cards, with the note-driven changes below.
- Delete `range_polarization` from data, runtime, UI, localization, documentation, and
  validation.
- Add `secondary_coolant`, `secondary_amplifier`, `gravity_collapse`,
  `kinetic_shockwave`, `piercing_lance`, `active_coolant`, and `active_amplifier`.
- Add `shock_disruption` as the requested second utility attribute; it is not the rejected
  chain-damage `arc_conduction` proposal.
- Split primary payload selection into one damage attribute and one utility attribute.
- Replace the rear-facing beam with deterministic high-density Auto Laser targeting.
- Increase Orbiting Blade presentation and contact size and fix level-4 rendering.
- Replace meta-like critical copy with ordinary critical-hit language.
- Reduce the first-level Low-Hull Damage bonus and show Dash Boost on the craft.
- Generalize Shift from EMP-only presentation to one equipped active weapon.
- Add the build-summary rail and dynamic active-weapon HUD/Ship Status presentation.
- Update Korean and English together and update active product/visual specifications.

### Non-scope

- Do not implement any rejected proposal:
  `primary_amplifier`, `primary_cycle_tuner`, `projectile_fusion`,
  `secondary_targeting`, `synchronized_targeting`, `thunder_core`, `mine_layer`,
  `arc_conduction`, `elemental_resonance`, `active_radius`, `active_duration`,
  `dash_coolant`, `barrier_efficiency`, `barrier_reactor`, `survival_reactor`,
  `combo_calibration`, `shield_breaker`, `execution_protocol`, or `cooled_shot`.
- Do not add a third optional secondary slot, multiple simultaneous active-weapon kinds,
  rerolls, skip actions, meta progression, or new player controls.
- Do not change mine behavior, enemy XP values, stage quotas, enemy health, enemy attack
  cadence, actor/projectile/effect capacities, collision accuracy, or difficulty.
- Do not merge this work with the separate XP-threshold implementation. The XP plan keeps
  its own formula, tasks, validation, and commit.
- Do not create new raster, SVG, audio dependency, production package, thread, native
  extension, or engine change.
- Do not rewrite the interactive HTML report as a product specification or mutate the
  preserved feedback JSON.

## Assumptions and Invariants

- Korean remains the default locale and every new or changed string has complete Korean
  and English text.
- One primary shot may carry one damage attribute and one utility attribute. Damage
  affinity owns projectile tint and telemetry; utility state is shown on the affected
  target, so a projectile never needs a misleading mixed tint.
- Direct attacks may critically hit. The implementation uses a deterministic per-receipt
  sample so unrelated attacks do not consume shared RNG, but players see only chance and
  critical damage.
- Existing committed enemy startup/active attacks are never cancelled by the new Shock
  utility. EMP remains the only active weapon that fully stuns.
- Shared multipliers modify the weapon's base damage/cadence before dash, low-Hull, and
  critical rules. Critical multiplication remains last.
- Dynamic attack geometry is presentation of gameplay truth, not a second collision or
  damage owner.
- New runtime state is run-scoped. No card build or active-weapon choice is added to
  persistent save data.

## Proposed Design

### 1. Canonical player-facing language

Use function-first names for the changed or new concepts. Internal IDs stay stable except
where the old ID directly contradicts new behavior.

| Internal ID | Korean | English | Meaning |
| --- | --- | --- | --- |
| `critical_targeting` | 치명타 | Critical Hit | Direct attacks have the displayed chance to deal `2x` damage. |
| `auto_laser` | 자동 레이저 | Auto Laser | Fires toward the direction that intersects the most enemies. Replaces `rear_laser`. |
| `secondary_coolant` | 보조무기 재사용 | Secondary Cooldown | Reduces every passive secondary cadence. |
| `secondary_amplifier` | 보조무기 피해 | Secondary Damage | Multiplies all passive secondary damage. |
| `shock_disruption` | 감전 | Shock | Temporarily prevents a new enemy attack commitment. |
| `gravity_collapse` | 블랙홀 | Black Hole | Pulls enemies into a distant aimed area, then damages them. |
| `kinetic_shockwave` | 충격파 | Shockwave | Damages and pushes enemies away from the craft. |
| `piercing_lance` | 십자 광선 | Cross Beam | Fires two map-spanning, aim-aligned piercing beams through the craft. |
| `active_coolant` | 발동무기 재사용 | Active Cooldown | Reduces the equipped active weapon's cooldown. |
| `active_amplifier` | 발동무기 피해 | Active Damage | Multiplies the equipped active weapon's damage. |

Do not expose phrases such as "reproducible chance roll," "active-weapon framework," or
other implementation language in cards, HUD, Ship Status, tooltips, or notifications.

### 2. Card schema, ownership, and catalog size

Add two explicit fields to `VehicleUpgradeDefinition`:

- `attribute_slot_kind`: `""`, `damage`, or `utility`.
- `active_slot_kind`: `""`, `kind`, or `enhancement`.

`secondary_slot_kind` continues to describe only built-in/optional weapon ownership.
Shared secondary enhancements leave it empty; the catalog validator stops requiring every
card in the secondary display category to consume a weapon slot.

`VehicleRunBuild` exposes:

- `active_damage_attribute_id()` for Thermal or Toxin;
- `active_utility_attribute_id()` for Cryo or Shock;
- `active_weapon_id()`, returning `emp` when no active-kind card has been acquired.

Compatibility is slot based:

- at most one damage attribute;
- at most one utility attribute;
- at most one active-weapon kind card;
- at most two optional secondaries;
- shared secondary/active enhancements consume no kind or weapon slot.

The final catalog is exactly 28 cards and 92 nominal level states. A legal run can acquire
65-67 levels after excluding one damage branch, one utility branch, two of three active
kinds, and three of five optional secondaries. The separate faster-XP plan ends its minimum
quota path at level 30, so it cannot exhaust this catalog.

### 3. Existing approved card corrections

#### Range Polarization

Delete the card resource and localization. Remove `RANGE_ELIGIBLE`, near/far constants,
range bonus functions, preview rows, range parameters, range-only attack origins, and all
range assertions. Do not retain a hidden level-zero implementation or retired offer alias;
run builds are not persisted.

#### Critical Hit

Keep chances `8/12/16%` and multiplier `2x`. Card and detail copy states only the ordinary
critical rule. Keep the internal integer-mixing function and shared-RNG isolation comment
inside the damage owner.

#### Low-Hull Damage

Keep the existing linear window: no bonus at 60% Hull or above, full bonus at 25% or
below. Change the maximum bonuses from `15/25/35%` to `5/10/20%`, so the first card is a
small baseline benefit as requested.

#### Dash Boost indicator

Keep the two-second duration and `15/25/35%` damage values. Delete the centered
`buff_text` HUD label and snapshot field. While active, publish one boolean and remaining
time to presentation and draw one static `26 x 6` world-unit amber rail over the authored
front weapon housing, aligned with the hull. It uses an existing retained primitive batch,
adds no node/ring/orbit/text/HUD slot, and remains static under reduced motion.

#### Drop Mines

Make no behavior change. Keep the immediate first mine, placement behind movement or the
stopped hull, level cadence, proximity trigger, eight-second expiry, live cap, radius, and
damage. Retain plain localized copy and lock the behavior in the secondary validator.

### 4. Damage and utility attributes

Damage slot:

- Thermal Burst, levels 1-4, unchanged.
- Bio Toxin, levels 1-4, unchanged.

Utility slot:

- Cryo Slow, levels 1-3, unchanged values and boss half-effect rule.
- Shock, levels 1-3. An eligible direct primary hit may apply attack lock for
  `0.6/0.8/1.0 s`. The same target cannot receive another Shock lock for `3.0 s`. Boss
  lock duration is halved. Movement, recovery timers, and already committed startup/active
  attacks continue; only a new attack commitment is blocked while the lock is live.

Replace `VehicleElementProfile` with the responsibility-shaped
`VehiclePrimaryPayloadProfile`. It freezes the selected damage affinity and utility
payload from one build revision. `VehicleStatusRuntime` may then hold Toxin plus Cryo or
Shock at the same time while keeping stacks/timers bounded.

Extend the existing enemy status compositor rather than adding an icon, node, outline,
ring, or material per enemy. It blends Toxin green, Cryo blue, and Shock purple inside the
authored actor alpha using the current batch custom data. Add fixed Shock presentation
scalars to `VehicleEnemyState`; presentation never walks the status dictionary.

### 5. Passive secondary changes

#### Orbiting Blades

- Orbit center radius: `88`.
- Contact radius: `52` instead of `22`.
- Presentation half-size: `52` instead of `38`.
- The inner visual/contact edge is therefore 36 units from the player center, immediately
  outside the 35-unit craft presentation radius.
- Damage, repeat cooldown, blade counts, and max level remain unchanged.
- Publish `orbit_radius`, `blade_radius`, and `blade_count` in the borrowed secondary
  snapshot. Remove the renderer's hard-coded `[2,3,4]` lookup so level 4 remains valid.

#### Auto Laser

Rename `rear_laser` resources, secondary ID, card ID, damage source, snapshot fields,
localization, tests, and docs to `auto_laser`. Keep damage `48/66/86`, base cooldown
`0.9 s`, length `760`, half-width `18`, cover clipping, and `0.14 s` exact corridor.

On a successful primary shot with the laser ready:

1. Query eligible enemies within 760 units once.
2. Keep at most 24 deterministic direction candidates, ordered by distance then stable ID.
3. Score each candidate direction against that same bounded set after cover clipping.
4. Prefer the direction with the largest corridor hit count, then the largest fixed-role
   priority sum, then the nearest first target, then stable ID.
5. Run the existing exact corridor query for final targets. If no candidate exists, do not
   fire and keep cooldown ready.

This is bounded `24 x 24` scoring at most once per laser cadence, not an unbounded enemy
pair scan.

#### Shared secondary cards

| Card | Levels | Exact values | Applies to |
| --- | ---: | --- | --- |
| Secondary Cooldown | 3 | cooldown/tick multiplier `0.90/0.82/0.75` | Seeker fire, Electric Field tick, Blade repeat, Mine placement, Auto Laser, Storm Barrage |
| Secondary Damage | 3 | damage multiplier `1.12/1.25/1.40` | Seeker direct and burst/structure damage, Field ticks, Blades, Mines, Auto Laser, Storm Barrage |

Compute each multiplier once per secondary update. For Electric Field, keep the existing
damage per tick while shortening the tick interval, so the cooldown card has a real effect.
Apply shared damage before dash/low-Hull/critical resolution. Do not increase projectile,
mine, blade, target, warning, or effect capacities.

### 6. Active-weapon system

Create `VehicleActiveWeaponDefinition`, `VehicleActiveWeaponCatalog`, and
`VehicleActiveWeaponRuntime` under `scripts/player/`, with matching definitions under
`data/weapons/vehicle/active/`. This runtime owns exactly one equipped kind, cooldown,
startup, one live action state, and borrowed gameplay/presentation intents. `VehicleRun`
owns input orchestration and consumes damage, displacement, projectile-clear, stun, and
visual descriptors; it does not absorb the new weapon algorithms.

Shift continues to use the saved internal input action `active_skill`. The public control
name becomes Active Weapon / 발동무기. Every run starts with EMP. Acquiring Black Hole,
Shockwave, or Cross Beam replaces EMP for that run and makes the other two kind cards
incompatible; later copies level the selected kind to level 4.

| Kind | Startup / cooldown | Level damage | Level size | Exact behavior |
| --- | --- | --- | --- | --- |
| EMP (default) | `0.42 / 13.0 s` | `62` | radius `285`; projectile clear `325` | Preserve current immediate damage, `2.1 s` stun, projectile clear, and protection. Shared active cards apply; EMP has no kind levels. |
| Black Hole | `0.35 / 12.0 s` | `60/85/115/150` | radius `150/175/200/225` | Center is 480 units along aim, clamped to the world bounds. For `1.2 s`, a 10 Hz bounded query pulls mobile non-boss enemies toward the center at 360 units/s through the existing cover-aware movement path; then one direct damage receipt resolves. Bosses/structures take damage but are not displaced. |
| Shockwave | `0.20 / 9.0 s` | `45/65/90/120` | radius `180/210/240/270` | One centered radius query damages targets and moves mobile non-boss enemies up to 180 units outward through the existing cover-aware movement path. It does not stun or clear projectiles. |
| Cross Beam | `0.35 / 12.0 s` | `70/95/125/160` | half-width `14/18/22/26` | At release, one beam follows aim through both sides of the map and one perpendicular beam crosses it through the craft. They ignore cover, hit every enemy/eligible structure intersecting the union once, and use one bounded full enemy-store pass at release. |

Shared active cards:

- Active Cooldown: multiplier `0.90/0.82/0.75`, applied after the existing EMP relay
  reduction and to every active kind.
- Active Damage: multiplier `1.15/1.30/1.50`, applied to every active kind before the
  shared outgoing-damage policy.
- There is no Active Radius or Active Duration card. Black Hole, Shockwave, and Cross Beam
  increase damage and effective area as their kind card levels, exactly as requested.

### 7. Active and status presentation

Keep all live effects code-native and gameplay-sized:

- Black Hole: one near-black full disk to the exact radius, one purple boundary, and at
  most four broad inward planes. No concentric rings, particle spray, raster, or expanding
  damage front.
- Shockwave: one full amber/system disk at final radius on its first release frame, one
  boundary, and a `0.18 s` fade. No outward-moving ring.
- Cross Beam: two exact filled corridors in startup and release states. Startup uses low
  alpha; release uses body plus hot core for `0.18 s`. No endpoint caps or cover clipping.
- Auto Laser remains one exact filled corridor.
- Shock status reuses the one enemy compositor with purple custom data.

The production gameplay manifest remains exactly 63 images and the shared upgrade-art
identity count remains 10. Reuse approved art as follows:

- shared cooldown/damage cards: `upgrade/system_relay`;
- Shock utility and Black Hole: `upgrade/ion_field`;
- Shockwave: `upgrade/defense_matrix`;
- Cross Beam and Auto Laser: `projectile/energy_teardrop`.

No raster generation or per-asset switch approval is needed because no asset bytes or
manifest identities change.

### 8. UI and read-only build state

- Add `activated` to the upgrade display categories and localize it as 발동무기 / Active
  Weapons.
- Extend `VehicleBuildSnapshotBuilder` with the equipped active weapon and effective
  active stats. Ship Status replaces its EMP-only group with a dynamic Active Weapon group.
- Change the HUD's fifth action item from fixed EMP to the equipped active kind. It keeps
  the same slot and shows `READY` or remaining cooldown; only its semantic glyph and
  accessible name change.
- Add simple code-native action glyphs for Black Hole, Shockwave, and Cross Beam through
  `VehicleUiGlyphCatalog`; do not add image icons.
- Implement `VehicleUpgradeBuildRail` as a focused UI owner. The upgrade modal becomes the
  specified summary-left/offers-right composition. The primary lane has damage attribute
  1, utility attribute 1, and primary-mod slots 2; Secondary has 3; Active has kind 1 plus
  shared enhancements 2; Chassis/Combat keeps the specified compact summary slots. These
  are summaries, not new equipment limits.
- Pass one frozen build snapshot into the modal when the reward opens. UI never computes
  compatibility, damage, cooldown, or status values.
- Preserve three selectable offers, explicit selection, Equip confirmation, mandatory
  choice, no Skip/Reroll/Leave, and deterministic focus.
- At 200% text, stack summary before offers inside one outer scroll while keeping Equip
  fixed. Verify Korean and English at 960x540, 1280x720, and 1920x1080.

## Responsibility and File Map

| Responsibility | Primary owners | Required adjacent updates |
| --- | --- | --- |
| Feedback evidence | `docs/reports/2026-08-12-cardborne-upgrade-feedback.json` | Never mutate during implementation |
| Card schema and compatibility | `scripts/cards/vehicle_upgrade_definition.gd`, `vehicle_upgrade_catalog.gd`, `vehicle_run_build.gd`, `data/cards/vehicle/*.tres` | offer presenter, preview rows, catalog validators |
| Primary payload | new `scripts/combat/vehicle_primary_payload_profile.gd`, `vehicle_status_runtime.gd`, `vehicle_attack_contract.gd` | projectile state, enemy state, telemetry, status validator |
| Conditional damage | `scripts/player/vehicle_outgoing_damage_policy.gd`, `vehicle_dash_upgrade_runtime.gd` | run damage call sites, conditional validator |
| Passive secondaries | `scripts/player/vehicle_secondary_runtime.gd`, secondary catalog/definitions and `.tres` | renderer snapshot, damage source catalog, secondary validator |
| Active weapons | new player runtime/catalog/definition plus active `.tres` | thin `VehicleRun` integration, build snapshot, active validator |
| Combat presentation | `scripts/presentation/vehicle_combat_renderer.gd`, visual event/glyph catalogs, visual profile | retained capacity/debug contracts, visual validators |
| HUD and modal | HUD presenter/gameplay HUD, new upgrade build rail, upgrade choice/stage UI, build summary | accessibility, responsive geometry, UI validators |
| Localization | `localization/vehicle_stage.csv` | localization validator, accessible names, input hints |
| Durable product truth | `vehicle_game_spec.md`, `vehicle_upgrade_catalog.md`, `VISUAL_SYSTEM.md`, `.agents/design/DESIGN.md` | retire stale overlapping plan clauses after verified implementation |

## Tasks and Milestones

### M0. Preserve evidence and establish the performance baseline

- [x] Preserve all exported feedback values in the repository, verify semantic equality,
  and record both source and normalized-copy SHA-256 values.
- [x] Read the active product/design/runtime owners and close the design decisions above.
- [x] Complete the visual-authority preflight: read `VISUAL_SYSTEM.md`, inspect the
  1448x1086 sheet at original detail, and observe the required SHA-256
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- [ ] Before runtime hot-path edits, tell BK that the exact native baseline is two
  70-second scenarios plus startup and validation overhead. From a clean committed tree
  and quiet machine, collect one valid `peak_horde` and `capacity_pressure` pair with the
  existing 10-second warmup/60-second duration protocol.
- [ ] Record exact commit, dirty state, viewport, renderer, VSync, workload counts, focus,
  and process isolation. If unrelated Godot/heavy work prevents a comparable baseline,
  stop the performance-sensitive branch instead of inventing a performance claim.

Gate: feedback and visual evidence are durable, and a comparable baseline exists before
the new scans/effects are introduced.

### M1. Migrate the catalog contract and delete Range Polarization

- [ ] Add explicit attribute and active ownership fields and their validators.
- [ ] Add the `activated` category and change secondary-category validation so shared
  enhancements do not consume optional slots.
- [ ] Delete Range Polarization data/copy/runtime/test/doc reachability and remove every
  range-only flag, parameter, and receipt field whose search proves it has no other owner.
- [ ] Rename Rear Laser to Auto Laser across run-scoped IDs and damage telemetry.
- [ ] Add resource definitions for the eight new cards, with the exact max levels and
  approved existing artwork IDs.
- [ ] Update the catalog expectations to 28 cards, 92 nominal states, and legal exhaustion
  65-67 without duplicate or fabricated offers.

Gate: the catalog loads with exact IDs and groups; rejected cards have zero runtime
definitions; build compatibility follows explicit slots.

### M2. Correct existing approved behaviors

- [ ] Update Low-Hull Damage to `5/10/20%` and its preview rows.
- [ ] Keep the critical algorithm but replace every player-facing deterministic-roll phrase
  with ordinary critical chance and `2x` damage language.
- [ ] Increase Orbiting Blade radii/size and publish the level-owned count to presentation.
- [ ] Implement bounded Auto Laser density selection and preserve cover/damage/cadence.
- [ ] Keep Drop Mines unchanged and strengthen the immediate/moving/stopped/expiry oracle.
- [ ] Replace the centered Dash Boost text with the craft-attached rail and remove the old
  HUD label, snapshot field, and localization if no remaining consumer exists.

Gate: each feedback note has a direct focused assertion, and no rejected or stale behavior
remains reachable.

### M3. Split damage and utility attributes

- [ ] Replace the single-element build/profile API with damage and utility slot APIs.
- [ ] Migrate Thermal/Toxin to damage and Cryo to utility without changing their values.
- [ ] Implement Shock status, reapplication lockout, boss scaling, committed-attack
  preservation, telemetry, and target-state compositor data.
- [ ] Extend projectile condition masks without letting the condition mask overwrite the
  damage-affinity tint.
- [ ] Validate all four legal pairings: Thermal+Cryo, Thermal+Shock, Toxin+Cryo, and
  Toxin+Shock, plus each slot by itself.

Gate: one damage plus one utility choice coexists; two choices in the same slot are never
offered; visuals and telemetry expose the actual payload without extra actor nodes/batches.

### M4. Add shared secondary upgrades

- [ ] Add the exact cooldown and damage modifier resources and preview rows.
- [ ] Apply each multiplier once through the secondary runtime to every listed cadence and
  damage source, including Seeker burst/structure damage.
- [ ] Verify final-level rates under existing projectile/mine/blade/pending/effect caps.
- [ ] Add build-summary and Ship Status values from gameplay-owned effective state.

Gate: all six passive secondary families receive the common modifiers and no count,
capacity, or targeting limit increases.

### M5. Implement the active-weapon owner and four kinds

- [ ] Add definition, catalog, runtime, and `.tres` data with the exact table values.
- [ ] Move EMP startup/cooldown/release state out of `VehicleRun` behind the new narrow
  runtime API while preserving its current behavior.
- [ ] Implement kind exclusivity and immediate run-scoped replacement of EMP.
- [ ] Implement Black Hole, Shockwave, and Cross Beam gameplay using bounded queries and
  existing movement/damage/structure owners.
- [ ] Apply Active Cooldown and Active Damage to EMP and all three selectable kinds.
- [ ] Add `validate_vehicle_active_weapons.gd` for exact values, state transitions,
  geometry, cover rules, union deduplication, boss/structure handling, and capacities.

Gate: Shift triggers exactly one equipped kind; every state/value is gameplay-owned and
deterministic; `VehicleRun` remains orchestration rather than a second active-weapon owner.

### M6. Integrate presentation, HUD, modal, and localization

- [ ] Render the three new active effects and Shock overlay through existing retained
  primitives/batches, with exact first-frame geometry and one-live-state bounds.
- [ ] Make the fifth HUD action slot and Ship Status group dynamic by active kind.
- [ ] Add localized code-native active glyphs and accessible names/input hints.
- [ ] Implement the build-summary rail and frozen snapshot path in the upgrade modal.
- [ ] Update every changed/new Korean and English card, effect row, status, report source,
  control label, and accessible string.
- [ ] Update debug geometry contracts and capture fixtures for 960/1280/1920, 200% text,
  Korean/English, keyboard/controller focus, reduced motion, overflow, and clipping.

Gate: no UI computes gameplay; no new raster/SVG exists; all supported layouts and locales
are readable and operable.

### M7. Update durable specifications and qualify the result

- [ ] Update `vehicle_game_spec.md`, `vehicle_upgrade_catalog.md`, `VISUAL_SYSTEM.md`, and
  `.agents/design/DESIGN.md` with the verified catalog, active weapon, attribute split,
  HUD/modal, effect, and asset-count contracts.
- [ ] Update the older dense-combat plan so its remaining active scope no longer presents
  superseded upgrade rules as executable current work.
- [ ] Run the focused validators listed below, Godot import, and Web export.
- [ ] Load `$npjt-port-guard`, use the fastrun manager's `codex` lane, and inspect the built
  Web artifact through normal Deployment and upgrade flows. Do not use an ad hoc server.
- [ ] Run the exact final native performance pair once from the clean committed checkpoint
  only after the full feature set is stable. Compare against M0 with identical workload;
  preserve red inherited thresholds as red and identify the changed owner if cost regresses.
- [ ] Run the codebase quality audit over task-owned public/resource/UI/runtime changes and
  correct only small safe task-scoped findings.
- [ ] Incorporate all durable decisions, delete this completed plan, and commit only the
  task-owned implementation.

Gate: functional, localization, layout, visual-budget, export, built-Web smoke, and precise
performance verdicts are recorded without weakening workload or thresholds.

## Progress

- [x] Imported and counted all 47 saved review decisions.
- [x] Preserved the feedback outside browser storage with a matching SHA-256.
- [x] Distinguished approved existing behavior, rejected runtime behavior, approved new
  cards, and note-created work.
- [x] Traced current card, build, status, secondary, conditional damage, active input,
  renderer, HUD, localization, product, and validation owners.
- [x] Closed terminology, exclusivity, initial balance, targeting, geometry, capacity, UI,
  visual-media, and save-safety decisions.
- [x] Completed the mandatory visual-authority inspection and performance-policy review.
- [ ] Runtime implementation has not started.

Current pointer: `M0`, clean performance baseline before runtime edits. The feedback JSON
and this decision-complete plan are already durable; browser-local notes are no longer the
only copy.

## Next Steps

1. Create a clean scoped planning commit containing the feedback evidence and plan updates.
2. Obtain the M0 clean native baseline after the explicit cost notice.
3. Execute M1 and M2 first so deletion/renaming and current-note corrections are stable
   before adding new payload/runtime branches.
4. Execute M3-M6 behind focused validators, then update durable specs and run M7 once.

## Test Plan

### Focused validation during implementation

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_upgrade_system.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_upgrade_ui.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_build_snapshot.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_conditional_upgrades.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_status_stacking.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_secondary_weapons.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_active_weapons.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_hud_presenter.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_combat_renderer.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_ui_layout.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_ui_localization.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_run.gd
.\tools\validation\validate_cardborne_visual_authority.ps1
```

The new active validator command becomes valid in M5. Until then, do not replace it with a
generic passing check.

### Build and production-style UI validation

```powershell
.\tools\godot.ps1 --path . --headless --editor --quit
.\tools\export_web.ps1
```

Then use the built Web artifact on the guarded `codex` lane and verify:

- default Shift EMP and each selectable active kind;
- one damage plus one utility attribute and illegal same-slot combinations absent;
- Auto Laser density direction, larger close Orbiting Blades, unchanged mines;
- Dash Boost craft rail with no centered buff text;
- dynamic active HUD glyph/cooldown and Ship Status values;
- three-card selection, build rail popovers, Equip focus, and no skip/exit action;
- Korean/English, 960x540/1280x720/1920x1080, 200% text, reduced motion, and no clipping.

### Native performance baseline/final protocol

Run only after user cost notice, from a clean committed tree and quiescent machine:

```powershell
$upgradePerfCommit = (git rev-parse HEAD).Trim()
$env:PERFORMANCE_COMMIT = $upgradePerfCommit
$env:PERFORMANCE_DIRTY = '0'
try {
  foreach ($upgradeScenario in @('peak_horde', 'capacity_pressure')) {
    $upgradeOutput = "res://build/performance/approved-upgrade-expansion/$($upgradePerfCommit.Substring(0,8))-$upgradeScenario-60s.json"
    .\tools\godot.ps1 --path . --rendering-method gl_compatibility `
      --resolution 1280x720 --position '40,40' --disable-vsync -- `
      "--performance-scenario=$upgradeScenario" "--performance-output=$upgradeOutput" `
      '--performance-warmup=10' '--performance-duration=60'
    if ($LASTEXITCODE -ne 0) { throw "performance scenario invalid: $upgradeScenario" }
  }
} finally {
  Remove-Item Env:PERFORMANCE_COMMIT -ErrorAction SilentlyContinue
  Remove-Item Env:PERFORMANCE_DIRTY -ErrorAction SilentlyContinue
}
```

Run this pair once at M0 and once after M7 only. A task-owned runtime input change or invalid
sample is the only reason to rerun it.

## Acceptance Criteria

- The runtime has exactly 28 cards and 92 nominal states; every legal exhaustion path ends
  at 65-67 acquisitions without duplicate, rejected, incompatible, or fabricated offers.
- `range_polarization` and `rear_laser` have zero runtime/data/localization/test reachability;
  `auto_laser` has the fixed high-density behavior.
- All 20 approved live cards remain, subject only to the exact note-driven changes in this
  plan; all 20 rejected report entries remain absent.
- Thermal/Toxin and Cryo/Shock occupy separate exclusive slots and all legal pairs work.
- Shock never cancels a committed attack, respects target lockout and boss half duration,
  and is visually distinct from Toxin without a new node/batch/material.
- Orbiting Blades use radius/size `88/52/52`, including a valid level-4 count. Drop Mines
  retain their exact existing behavior.
- Secondary Cooldown and Damage affect all six families at exact values without raising
  any object/query/pending/effect capacity.
- Shift controls exactly one active kind. EMP remains the default; Black Hole, Shockwave,
  and Cross Beam match the exact values, geometry, displacement, cover, and exclusivity
  rules above. Active shared cards affect all four kinds.
- Low-Hull Damage is `5/10/20%`; critical copy is ordinary; Dash Boost has a visible
  craft-attached rail and no centered text label.
- HUD, Ship Status, and upgrade build rail consume frozen gameplay state and are complete
  in Korean/English at all required viewport/text modes with visible focus and no clipping.
- Production remains at 63 images and 10 shared upgrade artwork identities, with no new
  raster/SVG, unbounded state, or second gameplay-geometry owner.
- Focused validators, import, Web export, built-Web normal-flow smoke, and visual authority
  validation pass.
- Performance evidence uses exact labels. A functional/visual-budget pass is not reported
  as a native or Web release-performance pass, and inherited red gates stay visible.

## Rollback and Safety

- The repository feedback JSON is immutable input. Runtime implementation cannot erase it,
  and the plan retains every actionable note even if browser storage is cleared.
- All card choices are run-scoped, so Range deletion and Auto Laser ID replacement require
  no save migration. Keep the persisted input action name `active_skill` to avoid binding
  migration.
- Make schema/catalog deletion, payload split, secondary changes, active runtime, and UI
  integration separate coherent commits. Do not mix the separate XP plan into them.
- If a milestone fails, revert only that milestone's task-owned commit; do not restore
  rejected cards or weaken validation.
- New geometry remains derived from gameplay values. Never fix a mismatch by changing only
  the renderer or only collision truth.
- If the performance baseline/final sample is contaminated, record it as invalid and wait
  for a clean environment. Do not kill unrelated processes, lower counts, reduce cadence,
  or change thresholds.

## Risks and Contingencies

| Risk | Detection | Fixed response |
| --- | --- | --- |
| Shock plus Cryo/Toxin increases status hot-path work | Named status timing and capacity fixture | Keep fixed scalar fields/custom data and one compositor; do not add per-enemy nodes/materials. |
| Black Hole pull causes wall penetration or grid drift | Cover oracle and grid reconciliation | Use existing cover-aware actor motion and update the spatial grid after accepted movement. |
| Cross Beam double-hits the intersection | Union-dedup validator with enemies on both corridors | Use one generation-marked receipt per target in the one release pass. |
| Auto Laser targeting becomes quadratic at full density | Candidate-count and timing assertion | Cap scoring at 24 candidates and keep the exact final corridor query separate. |
| Faster secondary cadence exceeds capacities | Maximum-build focused scenario | Preserve all existing caps; reject a proposed value change rather than raising workload silently. |
| New active glyph/effects become decorative clutter | Original-detail captures, grayscale, reduced motion | Use one full-area body/boundary or exact corridors and the existing HUD slot; no rings, particles, new icon rail, or raster. |
| Upgrade modal clips after adding the summary rail | Required viewport/locale/200% geometry checks | Use the specified responsive stack and single outer scroll; never shrink body text below 14. |
| Separate XP plan increases choice frequency | Combined minimum-path catalog simulation | Keep the plans separate; its level-30 endpoint remains below the 65-67 legal card ceiling. |
| Active dense-combat plan still states old upgrade rules | Plan audit before closeout | Add a precedence note now and remove or rewrite obsolete clauses when durable specs are updated. |

## Open Questions

None block implementation. Later balance changes require observed full-run evidence and a
separate owner decision; the executor must not treat manual preference as permission to
change the fixed initial values in this plan.

## Completion and Stop Conditions

Complete only when every acceptance criterion has evidence, the active product and visual
specifications contain the verified behavior, the older performance plan no longer exposes
superseded upgrade rules as current work, and this plan has been deleted after its durable
decisions are incorporated.

Stop the affected branch and report the exact blocker when the clean performance baseline
cannot be collected, the visual-authority reference hash changes, an implementation would
require a new unapproved raster or production dependency, a proposed fix changes enemy or
effect workload to manufacture a pass, or current runtime evidence contradicts one of the
fixed gameplay assumptions above. Functional milestones that do not cross the blocked
boundary must not be misreported as full completion.

## Decision Notes

- 2026-08-12: BK approved 27 report entries, rejected 20, and supplied 13 notes through the
  exported feedback JSON.
- 2026-08-12: Existing cards remain approved by default except the explicitly rejected
  Range Polarization card.
- 2026-08-12: Cryo becomes utility, not damage; Thermal/Toxin remain the damage pair and
  new Shock supplies the second utility choice without chain damage.
- 2026-08-12: Rear-facing behavior is replaced, not merely relabeled; the run-scoped ID
  becomes `auto_laser` to avoid permanent semantic debt.
- 2026-08-12: EMP remains the default Shift weapon, while one selected active-kind card
  replaces it for the run. Active Radius/Duration remain rejected.
- 2026-08-12: Dynamic effects and glyphs are code-native; existing approved semantic card
  art is reused, so no new raster approval gate is created.
- 2026-08-12: The current report and feedback remain evidence. Verified behavior must be
  incorporated into the active product and visual specifications before plan deletion.

## Sources

- Saved owner feedback: `docs/reports/2026-08-12-cardborne-upgrade-feedback.json`, normalized
  SHA-256 `4bdb64fb65444b10221bd170b3e1d5c0b5bfa3079820eef10fb687fccc36fa2c`;
  source export SHA-256
  `9a42bc79c3a5023eea27c380a8331f335c225ffa701e48f915f10a8a86603de9`.
- Interactive review context: `docs/reports/2026-08-12-vehicle-upgrade-categories-and-skill-tree-ko.html`.
- Active product truth: `docs/product/vehicle_game_spec.md` and
  `docs/product/vehicle_upgrade_catalog.md`.
- Active visual authority: complete `docs/design/VISUAL_SYSTEM.md` and original-detail
  `docs/design/cardborne-universal-art-style-reference.png`.
- Current gameplay owners named in the Responsibility and File Map.
- Runtime performance policy and current evidence boundary:
  `.agents/cardborne-performance-engineering-policy.md` and
  `.agents/cardborne-runtime-architecture-audit.md`.
