---
type: plan
status: active
created: 2026-08-22
source: "User decisions from the 2026-08-22 planning session and origin/codex/boss-shared-pattern-defense-rules at db007c6c"
scope: Selective boss-pattern integration, enemy upgrade-device competition, recall availability, universal hostile contact damage, canonical documentation, and release validation
related:
  - ../PLANS.md
  - ./2026-08-21-onboarding-progression-and-combat-pressure.md
  - ./2026-08-22-enemy-upgrade-devices.md
  - ../cardborne-performance-engineering-policy.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
---

# Boss, Device, Recall, and Contact Integration - Execution Contract

Starting from local `master` at `198c6653`, integrate only the required boss behavior from remote commit `db007c6c`, replace its rejected two-lane projectile family with the existing three-row broad barrage, make four enemy upgrade devices create real enemy objectives in every non-tutorial boss cycle, double recall replenishment availability, and make ordinary hostile contact reliably damage an unprotected player. The remote branch is reference material, not a merge source; current local behavior remains authoritative outside the locked changes in this contract.

## Purpose

- Objective: produce a faster and more coherent twelve-boss run in which bosses share a reusable attack language, signature mechanics remain distinct, enemies visibly contest upgrade devices, recall pickups remain available under pressure, and hostile bodies and attacks do not pass harmlessly through the player.
- Deliverable: scoped GDScript, documentation, localization, validator, presentation, and integration changes on local `master`, with coherent task-owned commits and final native/Web evidence.
- Completion state: every task and named gate passes, accepted product and visual documents match runtime truth, the final built-Web boot is verified through the existing repository workflow or an approved equivalent, and this plan is marked `done` with final commit and evidence identifiers.

## Scope and Boundaries

In scope:

- Selectively port the common/signature boss model, rapid commitment, periodic squads, Stage 6 proximity ordnance, Stage 10 segmented reflection, and Stage 7/9 wall tuning from remote commit `db007c6c`.
- Keep `common_broad_barrage` as three timed rows of six projectiles. Preserve both its spread variant and its fast row-angle-changing `rotate` variant.
- Delete `common_lane_volley` from the integrated common-family contract rather than replacing it with a second new family.
- Publish four enemy upgrade devices simultaneously at the start of each boss cycle from cycle 2 through cycle 12. Cycle 1 remains the tutorial cycle and publishes no device.
- Let ordinary mobile enemies claim device participation slots after entering an invisible influence radius, travel to the claimed device, remain for the five-second channel, and receive an immediate personal augmentation when activation succeeds.
- Keep a bounded run upgrade tier for later ordinary admissions and keep boss actors and boss summons outside the upgrade system.
- Make experience-recall replenishment begin and retry twice as often while maintaining four active recalls.
- Add generic hostile hull-scrape damage and standard swept collision checks without enlarging gameplay shapes beyond their existing visible presentation.
- Preserve and update Korean and English player-facing text.

Out of scope:

- Merging or cherry-picking the remote branch wholesale.
- Porting remote `.github/workflows/`, `.agents/tmp/`, one-shot migration scripts, patch-recovery material, or old neutral-facility content.
- Creating a new raster, SVG, projectile asset, boss asset, device asset, HUD panel, live upgrade rail, or top-right objective surface.
- Adding a persistent HUD device counter. Counted activation/destruction announcements and existing world/minimap markers are the feedback contract for this slice.
- Changing the current ordinary-enemy startup table, `ENEMY_RECOVERY_RATE`, ordinary movement multiplier, boss health, ordinary health, encounter quota, player dash protection, or the one-second post-hit protection window.
- Changing dependencies, engine version, renderer, physics tick rate, save schema, or release thresholds.
- Publishing, deploying, force-pushing, or opening a pull request without explicit user approval at the execution checkpoint.

Constraints and invariants:

- Local `master` is authoritative for every non-boss behavior not explicitly changed below. Remote commit `db007c6c` is pinned reference evidence even if the remote branch later moves.
- Current ordinary attacks already use the accepted faster cadence: ordinary startup values remain at or above `0.40 s`, and `VehicleEncounterDirector.ENEMY_RECOVERY_RATE` remains `1.28`.
- A common boss attack teaches a reusable interaction. A signature attack or state remains owned by one boss because it changes movement, space, defense, summons, or another stage-specific rule.
- The common direct pool is exactly `common_charge`, `common_broad_barrage`, `common_radial_bombardment`, `common_parallel_beam`, and `common_x_beam`. `common_squad_call` is the shared periodic family.
- Stage 1 teaches charge, broad barrage, radial bombardment, and squad call. Stage 2 adds parallel and X beams. Stage 3 retains that set and adds segmented guard. Stages 4–12 retain the complete common pool and layer their signatures on top.
- Boss lane, fan, and cross projectiles commit in at most `0.18 s`; the broad barrage commits in at most `0.22 s`; charge commits in at most `0.28 s`; Stage 6 distance-growth ordnance commits in at most `0.30 s`. Radial bombardment, emitted beams, and moving walls retain their authored longer warnings.
- Rapid committed attacks capture target or direction once and do not track through startup or active execution.
- Every broad-barrage execution schedules rows at `0.00`, `0.38`, and `0.76 s`, with six projectiles per row. Spread rows retain the current approximately `+/-21` degree within-row fan. Rotate rows change the row axis by `22.5` degrees per row and remain enabled for Stages 2, 4, 7, and 8.
- Four devices are cycle-scoped opportunities selected from the existing six run-level sockets. Unresolved devices remain until the next cycle transition, then retire before the next four are published.
- Each device accepts at most three participants. One enemy can hold at most one device claim at a time. The capture radius stays `180`; the uninterrupted channel stays `5.0 s`; the invisible influence radius is `720` world units; assignment refresh remains `0.25 s`.
- A successful device activation immediately grants each living participant one personal augmentation of `+30` maximum/current health, `+12%` pack-owned attack damage, and `+3` movement speed. A living enemy can receive this personal augmentation at most once.
- Each successful activation also increments the run upgrade tier up to six. Future ordinary admissions receive the tier total. Activation after tier six still augments its current participants and remains a real player-facing event, but does not raise the future-admission tier beyond the existing six-activation maximum.
- Bosses, boss-owned summons, fixed hostile structures, and immobile mines cannot claim a device or receive device bonuses. Ordinary encounter enemies remain eligible even when they have a non-empty `leash_rect`.
- Player-primary projectiles damage and stop at the earliest intersected active device. Hostile projectiles pass through devices. Device bodies continue to block actor movement. Multiple active devices never depend on array order for collision selection.
- Every unprotected contact with a living hostile body produces a damage attempt. Authored charge, lunge, shield-bash, collective, and boss-contact attacks take precedence so one physical crossing cannot apply both authored and generic contact damage.
- Generic mobile/support/fixed/mine hull scrape uses `6` base damage and a `1.0 s` per-enemy accepted-hit cooldown. Defender/coordinator persistent contact retains `12` damage and `0.8 s`. Boss generic hull scrape uses `12` damage and `1.0 s`; authored boss charge damage takes precedence.
- A dash-protected or post-hit-protected player can reject damage. A rejected persistent overlap remains armed and retries after protection expires; protection does not consume the contact cooldown.
- Player, enemy, projectile, beam, and area collision use gameplay-owned circles, segments, or corridors. No task may enlarge a collision radius, beam width, area radius, or contact padding to compensate for presentation.
- Korean and English must remain complete for every changed announcement, Guidebook row, and accepted product description.
- Preserve unrelated tracked and untracked worktree content. Stage and commit only paths owned by the current task.

Destructive or irreversible actions:

- None. Do not delete the remote branch, retired neutral-facility implementation, existing evidence, or unrelated worktree content.

Exact actions requiring owner or user approval:

- Obtain user alignment immediately before the final broad all-validator, rendered-capture, and Web gate, with its expected runtime and machine impact.
- Obtain explicit approval before pushing, opening a pull request, triggering deployment-capable workflow behavior, publishing, force-pushing, adding a dependency, changing a release threshold, or weakening a supply-chain or validation safeguard.

## Domain and Lifecycle Contract

Canonical terms:

| Term | Meaning and owner | Hidden implementation detail |
| --- | --- | --- |
| Boss cycle | One of the twelve connected quota-to-boss progress periods on the persistent field | Internal stage IDs remain `stage_1` through `stage_12` |
| Common boss attack | A reusable attack family selected from the shared common pool | Ordering cursors and per-stage damage scaling stay inside `VehicleBossPatterns` and `VehicleBossRuntime` |
| Signature boss attack | A stage-owned direct or autonomous mechanic with a distinct interaction | Scheduling remains separate from the common cursor |
| Broad barrage | Three timed rows of six projectiles, using spread or rotate row axes | Projectile allocation remains in `VehicleRun` under the fixed hostile capacity |
| Enemy upgrade device | A hostile, destructible cycle objective that enemies attempt to activate | Socket selection, claims, capture progress, and outcomes stay inside the device runtime |
| Device participant | One eligible ordinary mobile enemy holding one stable claim on one device | Influence queries and route-field storage are not exposed to UI or encounter code |
| Personal augmentation | One immediate, non-stacking bonus applied to a participant after activation | Per-enemy application receipts remain runtime-only |
| Run upgrade tier | The bounded zero-through-six bonus applied to later ordinary admissions | UI receives event counts, not mutation access |
| Generic hull scrape | Low damage for ordinary physical overlap outside an authored contact attack | Relative swept collision and cooldown bookkeeping stay in the contact runtime |
| Hit protection | Dash protection or the existing one-second post-hit rejection window | Damage sources call the same receipt path and do not bypass protection unless already authored to do so |

Device lifecycle:

1. Cycle 1 keeps all sockets unpublished.
2. At the start of cycles 2–12, retire prior-cycle device state and select four valid sockets deterministically. Choose the socket farthest from the player's cycle-start position first; then repeatedly choose the socket whose minimum squared distance to the player and every already selected socket is greatest. Resolve equal scores by stable socket ID. Publish all four as unresolved active devices.
3. An eligible enemy entering a device's `720`-unit influence circle may claim one of its three vacant participant slots. Equal-distance ties resolve by stable device ID, then enemy ID.
4. A claim persists until the enemy dies, becomes invalid, the device resolves, or the cycle changes. Temporary movement outside the influence circle does not cause assignment thrash.
5. Assigned enemies route to their device and stop inside `115.2` units, preserving the current `0.64 * CAPTURE_RADIUS` stop rule.
6. Three living assigned enemies inside radius `180` advance the uninterrupted five-second channel. Losing a required in-radius participant resets channel time but preserves valid claims.
7. Activation applies personal augmentation, increments the bounded run tier, publishes an event, and resolves that device. Player destruction publishes the corresponding destruction event and resolves it without quota, XP, or upgrade credit.
8. Resolved or unresolved devices do not republish during the same cycle. The next cycle starts a new four-device set.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Safe branch integration | Remote branch diverged at `8d762af1`; direct merge conflicts with current device docs, `VehicleRun`, Guidebook, and shared validators and carries unrelated automation | `git merge-tree`; `git diff master...db007c6c`; remote execution contract and evidence | Selectively implement from pinned commit; never merge or bulk cherry-pick | 1.1–2.4, 5.1 |
| Common versus signature attacks | Current local boss uses one stage sequence; remote separates common/signature and uses two common attacks before a signature | `scripts/bosses/vehicle_boss_patterns.gd`; `scripts/bosses/vehicle_boss_runtime.gd`; remote commit `db007c6c` | Adopt the separation and periodic squad owner, but remove `common_lane_volley` | 1.1–1.4 |
| Three-row and rotating barrage | Current barrage owns three timed rows and `barrage_mode()` uses rotate in Stages 2, 4, 7, and 8; current early rows can contain fewer than six shots | `VehicleBossPatterns.broad_barrage_rows()` and `barrage_mode()` | Every common barrage is three rows of six; preserve spread and 22.5-degree rotate variants | 1.2 |
| Faster combat | Local ordinary attack cadence is already faster; remote adds exact rapid boss startup caps | `VehicleAttackContract.ORDINARY_ATTACKS`; `VehicleEncounterDirector.ENEMY_RECOVERY_RATE`; remote `startup_seconds()` | Preserve ordinary values and adopt remote boss rapid caps | 1.3 |
| Stage-specific boss fixes | Local Stage 6 lacks proximity detonation; Stage 10 uses facing-based reflection; Stage 7/9 walls retain full speed and damage | Current boss, projectile, and late-mechanic owners compared with `db007c6c` | Port the remote fixes while preserving current local non-boss code | 2.1–2.4 |
| Recall availability | Four authored recalls already exist; replenishment starts at 90 seconds, retries at 30 seconds, and stops at the low-water mark of two | `scripts/rewards/vehicle_recall_replenishment_runtime.gd`; field-layout validators | Use `45/15`, low-water mark four, active cap four; do not add more layout objects | 4.1 |
| Device count and pursuit | Current runtime exposes one of six sockets per run, globally reselects three nearest enemies, and has one objective route field | Device runtime, run subtype, and completed device plan | Four simultaneous devices per cycles 2–12 with stable influence claims and a bounded four-target route owner | 3.1–3.4 |
| Enemies ignore devices | Real encounter enemies receive `leash_rect`; `_eligible_enemy()` rejects every such enemy; validator fakes empty leash data | Encounter materialization, `_eligible_enemy()`, device validator | Leash is not an eligibility exclusion; validate with a real encounter-spawned enemy | 3.2, 3.7 |
| Device upgrades and feedback | Current activation strengthens only later spawns; bilingual activation/destruction messages exist; one snapshot/marker is published | Run subtype, localization CSV, device renderer | Immediately augment participants, keep bounded future tier, publish counted messages, show four world/minimap markers, add no HUD counter | 3.4–3.6 |
| Harmless body overlap | Current contract deliberately leaves pursuit, charger outside attack, support, fixed, and mine overlap inert | Contact runtime and validator | Add generic hull scrape for every hostile body while keeping authored attack priority and player protection | 4.2–4.3 |
| Projectile and zone crossing | Hostile projectile collision sweeps the projectile against the player's endpoint; beams and areas sample the player endpoint | `VehicleRun._update_projectile_buffer()` and `_update_denied_zones()` | Use relative swept tests for projectile and active-zone crossings without changing radii or widths | 4.4 |
| Visual authority | Authority pair is unchanged and covers barrage, defense, device, minimap, messages, and collision separation | Receipt below | Reuse existing assets and retained geometry; update documents and inspect one batched rendered result | 2.4, 3.5, 5.1–5.3 |
| Runtime capacity | Four route targets and twelve participants add bounded recurring work; current performance evidence is not a comparable baseline for this new workload | Performance policy and runtime architecture audit | Share walkability, cap combined route expansion at 512 cells/tick, reuse query buffers, and report only focused scenario validity unless a clean release gate is run | 3.3, 3.7, 5.3 |

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership, safety, and validation decision is closed.
- Godot 4.7.1 is available through `./tools/godot.ps1`; repository-owned focused validators, document checks, visual-authority checks, Web export, and Web static verification are present.
- The existing `.github/workflows/vehicle-run-validation.yml` is the verified all-validator, rendered-capture, Web-export, and built-Web boot owner. External push or workflow execution remains approval-gated.
- Remaining unknowns are implementation-local and cannot change this contract.

## Visual Authority Receipt

- Canonical text: `docs/design/VISUAL_SYSTEM.md`, completely read for this root task; observed SHA-256 `9b660b372a724cc526a83b3f4bfdf63c2d185b8fc1b1ec6d612e1e92931b4c0e`.
- Canonical sheet: `docs/design/cardborne-universal-art-style-reference.png`; expected and observed SHA-256 `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`; inspected at original `1448 x 1086` detail.
- Original artifact provenance: `C:/Users/BK/.codex/generated_images/019fbfe9-857e-7453-b72d-20908d848577/exec-0b8aa606-cf55-45c1-abb3-fb3df762b080.png`, timestamp `2026-08-02 12:13:44 KST`.
- User sketch inspected at original detail: `D:/Program Files/ImageMagick-7.1.1-Q16-HDRI/captures/2026-08-22 11 24 36.png`. It is a gameplay-arrangement reference for the existing broad barrage, not an asset source.
- `actual_image_reference_used=false`; `reference_input_method=not_applicable`. No raster or SVG deliverable is authorized.
- Task constraints: preserve collision/presentation separation; render shield gaps from the exact angular collision snapshot; keep Stage 6 projectiles disconnected from false beam trails; keep the device's approved authored PNG and semantic marker; show up to four devices through retained batches; use counted bilingual announcements; add no HUD panel or live upgrade rail; do not increase any collision footprint to match effects.

## Tasks

### Phase 1: Shared Boss Language and Rapid Commitment

Goal: every boss uses a queryable common pool plus stage-owned signatures, with the user-approved rapid commitment and no two-lane projectile family.

Preconditions:

- Confirm local `master` still contains the device feature layer and the remote source commit `db007c6c` is reachable.
- Inspect the current worktree only enough to preserve unrelated changes; do not clean or stage them.

Source owners: `scripts/bosses/vehicle_boss_patterns.gd`, `scripts/bosses/vehicle_boss_runtime.gd`, `scripts/bosses/vehicle_boss_phase_catalog.gd`, `scripts/combat/vehicle_attack_telegraph_builder.gd`, `scripts/vehicle/vehicle_run.gd`, `tools/validation/validate_vehicle_boss_patterns.gd`, `tools/validation/validate_vehicle_boss_runtime.gd`

- [x] **1.1** Publish exact common and signature catalogs.
  - Change: port the remote common/signature queries and per-stage signature sequences; define the five direct common IDs and periodic squad family listed in this contract; set Stage 1 and Stage 2 unlocks to three and five direct families; remove every runtime definition, query, validator expectation, and canonical product or visual-document mention of `common_lane_volley`. This plan may retain the name only to record the rejected remote behavior.
  - Accept: Stages 1, 2, and 3 resolve the locked cumulative sets; Stages 4–12 resolve all five direct common families; common and signature queries are disjoint; no tracked runtime or validator reference to `common_lane_volley` remains.
  - Guard: do not copy remote neutral-facility, CI, migration, or patch-recovery changes while moving the catalog.
- [x] **1.2** Make the broad barrage exactly three rows by six shots.
  - Change: keep one fixed-cap broad-barrage scheduler, publish rows at `0.00/0.38/0.76 s`, force six projectiles per row in every cycle, preserve spread mode, and preserve the `22.5`-degree row-axis rotation in Stages 2, 4, 7, and 8.
  - Accept: a deterministic fixture observes exactly eighteen projectiles per execution, three six-shot row receipts, correct row times, unchanged spread angles, and rotated row axes in every named rotate stage.
  - Guard: one barrage execution may schedule the eighteen projectiles once only; direct and autonomous owners cannot duplicate it.
- [x] **1.3** Apply rapid committed startup without retargeting.
  - Change: port the remote `0.18/0.22/0.28/0.30 s` startup caps by boss pattern kind; capture target/direction once; preserve longer radial, beam, crossing-wall, and compression warnings; leave the current ordinary attack table and recovery-rate constant unchanged.
  - Accept: focused fixtures prove each rapid cap, non-tracking startup/active behavior, unchanged radial/beam/wall warning values, and byte- or value-equivalent ordinary attack startup/recovery data.
- [x] **1.4** Separate common/signature cursors and publish periodic squads.
  - Change: select two common direct attacks before an available signature, prevent immediate repeat where an alternative exists, reset cursors per boss, use the remote ten-second phase-aware squad timer, and prevent a squad call from beginning during a major signature execution.
  - Accept: all twelve bosses produce valid bounded common actions; bosses with signatures produce the exact two-common/one-signature rhythm; squad packets remain within the existing live-add cap and phase composition; health thresholds no longer create duplicate immediate squads.

Batch gate:

```powershell
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_boss_patterns.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_boss_runtime.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_boss_exams.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_twelve_boss_campaign.gd
```

Checkpoint and commit:

- Record the focused receipts in this plan, check Tasks 1.1–1.4, and commit only Phase 1 files with a short explanatory body.
- 2026-08-22 receipt: Godot `4.7.1.stable`; boss-pattern, boss-runtime, boss-exam, and twelve-boss-campaign validators passed. The runtime fixture observed eighteen projectiles, six receipts at each `0.00/0.38/0.76 s` row, spread edges at `+/-21` degrees, and rotate axes at `0/22.5/45` degrees. Runtime and validator sources contain no `common_lane_volley`; ordinary attack-contract and encounter-cadence owners were unchanged.

### Phase 2: Stage 6, Segmented Defenses, and Wall Corrections

Goal: port the coherent stage-specific boss fixes without importing remote non-boss state.

Preconditions:

- Phase 1 acceptance checks and batch gate pass.

Source owners: `scripts/bosses/vehicle_boss_shield_runtime.gd`, `scripts/bosses/vehicle_late_boss_mechanics.gd`, `scripts/combat/vehicle_projectile_state.gd`, `scripts/presentation/vehicle_combat_renderer.gd`, `scripts/vehicle/vehicle_run.gd`, `scripts/progression/vehicle_guidebook_stat_adapter.gd`

- [x] **2.1** Complete Stage 6 distance-growth ordnance.
  - Change: start speed/radius/damage at `1.00x`, preserve monotonic caps `1.35x/1.50x/1.60x`, arm at `720` travelled units, trigger within `96` plus player radius, apply one `150`-radius radial detonation, and share one direct-contact/proximity retirement path.
  - Accept: pre-arm contact cannot detonate; growth samples are monotonic; proximity without body contact detonates once; direct contact cannot add a second hit; one Stage 6 scheduler emits one authored bank.
- [x] **2.2** Generalize Stage 3 guard and Stage 10 reflection under one segmented defense owner.
  - Change: preserve Stage 3's three `80`-degree segments, three `40`-degree gaps, `8 s` active, `2 s` down, `15%` through-segment damage, rotation, and counterburst. Replace Stage 10's facing plate with three `70`-degree reflection segments and three `50`-degree gaps, `15 s` fully down, a non-blocking cue during the last exposed second, and `5 s` active.
  - Accept: Stage 3 values are unchanged; Stage 10 segment hits reflect, gap hits damage normally, full-down hits damage normally, and boss facing cannot alter angular coverage.
- [x] **2.3** Apply exact Stage 7 and Stage 9 wall scales.
  - Change: multiply boss-owned Stage 7 crossing-wall speed and damage and boss-owned Stage 9 compression-wall speed and damage by `0.70`; preserve geometry, openings, warnings, delays, and non-boss uses.
  - Accept: deterministic equal-duration samples measure exactly seventy percent of prior travel and damage for every wall variant while geometry and unrelated boss stats remain unchanged.
- [x] **2.4** Synchronize presentation and Guidebook truth.
  - Change: remove the false beam-like Stage 6 trail; render only the growing projectile and bounded armed cue; render Stage 3/10 defense segments from the exact collision snapshot; update only the corresponding boss Guidebook rows.
  - Accept: renderer fixtures expose no Stage 6 connecting line, armed cues appear only when collision is armed, and visible defense arcs/gaps/cue/down states equal runtime values.

Batch gate:

```powershell
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_distance_growth_projectile.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_late_boss_mechanics_correction.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_late_boss_identities.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_combat_renderer.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_boss_identity_cues.gd
```

Checkpoint and commit:

- Record the focused receipts in this plan, check Tasks 2.1–2.4, and commit only Phase 2 files with a short explanatory body.
- 2026-08-22 receipt: distance-growth projectile, late-boss mechanics, late-boss identities, combat renderer, boss identity cues, boss exams, twelve-boss campaign, and boss-difficulty validators passed under Godot `4.7.1.stable`. Stage 6 proximity and single-retirement paths, Stage 3/10 collision-owned segments, Stage 7/9 exact `0.70` boss-wall scales, retained Guidebook device rows, and the no-false-trail renderer contract were exercised. Two remote validator defects were corrected locally: explicit `Dictionary` typing for a dynamic runtime snapshot and five-family common-pool expectations after rejecting the lane volley.

### Phase 3: Four Contested Enemy Upgrade Devices per Non-Tutorial Cycle

Goal: make device competition observable and reliable with real encounter enemies and bounded four-target routing.

Preconditions:

- Phase 2 acceptance checks and batch gate pass.
- Load `$cardborne-performance-guard` before changing the multi-device query or route hot path.

Source owners: `scripts/vehicle/vehicle_enemy_upgrade_device_runtime.gd`, `scripts/vehicle/vehicle_run_enemy_upgrade_devices.gd`, `scripts/enemies/vehicle_enemy_state.gd`, `scripts/enemies/vehicle_pursuit_field.gd`, new `scripts/enemies/vehicle_objective_pursuit_field_set.gd`, `scripts/combat/vehicle_spatial_grid.gd`, `scripts/presentation/vehicle_enemy_upgrade_combat_renderer.gd`, `scripts/ui/vehicle_minimap_mesh_builder.gd`, `localization/vehicle_stage.csv`, `tools/validation/validate_vehicle_enemy_upgrade_devices.gd`

- [x] **3.1** Replace the one-per-run sequence with four cycle-scoped devices.
  - Change: retain six generated sockets as layout capacity; publish none in cycle 1; select and publish four deterministic valid sockets at the start of cycles 2–12 using the locked farthest-first, greedy maximum-separation rule; retire the prior cycle's device set before republishing; scale health from the current cycle index; never respawn a resolved device inside the same cycle.
  - Accept: a twelve-cycle fixture observes `0` devices in cycle 1 and exactly `4` unresolved published devices at the start of every later cycle, with the exact expected socket IDs for a fixed player position, no fifth device, no stale collision body, and no same-cycle republish.
- [x] **3.2** Recruit real ordinary enemies through stable influence claims.
  - Change: add `INFLUENCE_RADIUS = 720.0`; query nearby enemies at `0.25 s` cadence through caller-owned spatial-grid buffers; remove `leash_rect` as an exclusion; accept only living active mobile ordinary non-summons; reserve at most three participants per device and one device per enemy; preserve claims through temporary range departure and reset channel time when fewer than three participants remain inside radius `180`.
  - Accept: a fixture materialized through the real encounter spawn path retains a non-empty leash, enters the influence circle, claims a slot, changes movement reason, reaches the device, and contributes to a five-second activation. Fixed actors, mines, bosses, summons, dead actors, and a fourth claimant are rejected.
  - Guard: equal-distance arbitration is deterministic by device ID and enemy ID; assignment refresh does not clear and rebuild valid claims every tick.
- [x] **3.3** Add one bounded four-target objective route owner.
  - Change: implement `VehicleObjectivePursuitFieldSet` with shared static walkability, at most four device-ID target fields, one combined `512`-cell expansion budget per physics tick, stable round-robin progress, and direct-target fallback until a field is ready. Assigned enemies use their claimed device's field, stop at `115.2`, and remain exempt from player-pursuit bias and ordinary attack selection.
  - Accept: all four targets become reachable around authored walls; per-tick processed cells never exceed `512`; removing a device releases only its participants and field; container capacities do not grow across a bounded repeated-cycle fixture.
- [x] **3.4** Apply immediate personal and bounded future-enemy upgrades.
  - Change: on activation, apply one personal augmentation to each living participant, mark that enemy so it cannot receive a second personal augmentation, increment the run upgrade tier up to six, and apply the tier to later ordinary admissions through the existing health/speed/pack-damage owners. Preserve boss and summon exclusions.
  - Accept: participants gain current and maximum health, speed, and attack multiplier immediately; an already-personally-augmented participant does not stack again; later admissions receive the exact bounded tier total; a seventh activation cannot raise the future tier above six but still augments eligible current participants.
- [x] **3.5** Make four devices collision- and presentation-complete.
  - Change: publish all unresolved devices in snapshots, retained world rendering, and minimap markers; test actor clearance against all active bodies; return the earliest segment hit among all active devices; preserve player-primary blocking/damage and hostile-projectile pass-through.
  - Accept: four world bodies and four minimap markers are visible without new nodes or textures; projectile ordering selects the nearest geometric hit regardless of device-array order; resolved devices disappear from collision and presentation in the same simulation state.
- [x] **3.6** Publish counted bilingual outcomes without a new HUD counter.
  - Change: retain activation and destruction announcements, include current-cycle outcome counts so simultaneous events do not collapse into indistinguishable text, coalesce same-tick events to the final truthful count, and update Korean and English strings together.
  - Accept: player destruction and enemy activation each produce a localized verified announcement; a four-event same-tick fixture retains the final activated/destroyed counts without queue overflow or stale prior-cycle values.
- [x] **3.7** Replace the synthetic device validator gap with end-to-end fixtures.
  - Change: extend focused device validation through real encounter materialization, four simultaneous devices, route progress, channel interruption/retry, immediate participant augmentation, bounded future tier, collision ordering, event counting, and cycle retirement.
  - Accept: the validator fails on the current leash exclusion and passes only through the production owners after correction; its debug snapshot proves fixed capacities and the combined route budget.

Batch gate:

```powershell
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_enemy_upgrade_devices.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_map_mechanics_integration.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_combat_renderer.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_ui_localization.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/profile_vehicle_pressure.gd
```

The pressure script is a focused trend sample and may be reported only as `scenario valid` with its exact counts and bounded-work receipts. It is not a native or Web release-performance pass.

Checkpoint and commit:

- Record device counts, route-budget evidence, focused validator receipts, and the pressure label in this plan; check Tasks 3.1–3.7; commit only Phase 3 files with a short explanatory body.
- 2026-08-22 receipt: enemy-upgrade-device, map-mechanics integration, combat-renderer, and UI-localization validators passed under Godot `4.7.1.stable`. The twelve-cycle fixture observed `0` tutorial devices and exact IDs `test_device_1/2/3/5` for all `4` later-cycle publications; real materialization retained a non-empty leash and produced `12` bounded claims across four devices. Four shared route fields converged with a fixed `3375`-cell capacity each and never exceeded the combined `512`-cell tick budget. The hard pressure microbenchmark is labeled only `scenario valid`: `72/72` active-capped enemies, `192` shards, `1` queued window, `4` devices, `12` seeded participants, `12` peak claims, `4` peak route targets, `512` peak route cells, and `6.767 ms` combined subsystem sample. This is not native or Web release-performance evidence.

### Phase 4: Recall Availability and Standard Player Hit Detection

Goal: keep recall resources present and make ordinary genre-standard hostile contact reliable without changing presentation footprints or protection rules.

Preconditions:

- Phase 3 acceptance checks and batch gate pass.

Source owners: `scripts/rewards/vehicle_recall_replenishment_runtime.gd`, `scripts/enemies/vehicle_enemy_contact_runtime.gd`, `scripts/combat/vehicle_attack_contract.gd`, `scripts/vehicle/vehicle_run.gd`, `tools/validation/validate_vehicle_recall_replenishment.gd`, `tools/validation/validate_vehicle_enemy_contact.gd`, `tools/validation/validate_vehicle_damage_feedback.gd`

- [ ] **4.1** Double recall replenishment frequency and maintained quantity.
  - Change: set `START_SECONDS = 45.0`, `INTERVAL_SECONDS = 15.0`, `LOW_WATERMARK = 4`, and retain `ACTIVE_CAP = 4`; reactivate one authored inactive recall per eligible interval and reset its publication state through the current owner.
  - Accept: replenishment cannot occur before 45 seconds, occurs after each 15-second eligible interval, restores the four-recall low-water mark, never exceeds four active recalls, and does not create new layout objects.
- [ ] **4.2** Add generic contact damage to every hostile body.
  - Change: extend the single contact runtime to all active hostile `EnemyState` roles, including ordinary pursuit/charger outside attacks, support, fixed actors, mines, and boss; use the locked damage/cooldowns; retain relative swept motion; and give authored contact attacks first and exclusive precedence.
  - Accept: each role family damages an unprotected player on endpoint overlap and between-endpoint crossing; a warned lunge/charge/bash applies only its authored damage; one crossing never double-hits; a protected rejection remains armed; a retired/dead/inactive actor cannot damage.
- [ ] **4.3** Preserve protection and visible-footprint limits.
  - Change: route generic contact through `_damage_player()` without bypassing dash or post-hit protection; retain existing player/enemy radii and attack padding; add assertions against the documented presentation envelope rather than enlarging gameplay shapes.
  - Accept: dash and one-second hit protection reject contact, the same continuing overlap retries when protection ends, and every contact danger radius remains no larger than the corresponding visible body envelope.
- [ ] **4.4** Use relative swept collision for hostile projectiles and active zones.
  - Change: compare player previous-to-current motion against projectile previous-to-current motion; test the player's swept segment against active beam corridors and radial areas; account for translated corridor motion through its previous and current geometry; preserve damage falloff, widths, radii, tick cadence, and one-hit locks.
  - Accept: deterministic crossings that start and end separated still damage once; paths outside the exact combined circle/corridor remain safe; direct endpoint contacts remain unchanged; no projectile, beam, or area radius/width increases.

Batch gate:

```powershell
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_recall_replenishment.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_enemy_contact.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_attack_contract.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_damage_feedback.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_attack_route_readability.gd
```

Checkpoint and commit:

- Record the focused receipts in this plan, check Tasks 4.1–4.4, and commit only Phase 4 files with a short explanatory body.

### Phase 5: Canonical Documentation, Quality Audit, and Final Evidence

Goal: make accepted documentation match the integrated runtime, remove responsibility drift, and run one coherent final gate.

Preconditions:

- Phases 1–4 and their batch gates pass.
- All task-owned implementation is committed; unrelated worktree content remains unstaged.

Source owners: `docs/product/vehicle_game_spec.md`, `docs/design/VISUAL_SYSTEM.md`, this plan, affected validators, `.github/workflows/vehicle-run-validation.yml`

- [ ] **5.1** Update canonical product and visual contracts from current local documents.
  - Change: edit current local documents in place for the five-family common pool, three-by-six spread/rotate barrage, rapid boss timing, common/signature rhythm, Stage 6/7/9/10 rules, four-device cycle lifecycle, personal and bounded run upgrades, counted messages, recall `45/15/4/4`, universal contact attempts, preserved hit protection, and unchanged collision footprints. Do not copy remote documents wholesale or restore neutral-facility text.
  - Accept: canonical product and visual-document searches find no active contract for `common_lane_volley`, one-device-per-run publication, a six-device-resolution lifecycle, `90/30` recall, harmless hostile overlap, a facing-based Stage 10 plate, or a contradictory minimum-`1.30 s` rule for rapid boss projectile/charge kinds. Historical rejection text in this execution plan is allowed.
  - Guard: the older active onboarding plan's “do not shorten startup” decision is historical for this scope and must not override the newer explicit user decision recorded here.
- [ ] **5.2** Run the task-scoped quality audit and correct only safe owned findings.
  - Change: load `$codebase-quality-auditor`; review responsibility creep, competing schedulers, catch-all expansion, mutable snapshot leakage, device collision ordering, contact double-hit paths, public contract drift, localization completeness, and missing integration fixtures. Apply only small task-scoped corrections.
  - Accept: no reachable task-owned failure path, competing common/signature/device/contact owner, stale fallback publication, or missing validator remains; material redesign findings stop this phase and trigger contract revision.
- [ ] **5.3** Run the single final broad gate after user alignment.
  - Change: explain the exact all-validator, import, rendered-capture, Web-export, and built-Web boot workload and obtain alignment; then run the repository workflow on the coherent commit or an approved exact local equivalent. Inspect the boss barrage/defense/device/contact-relevant native captures and the built-Web boot image; run one focused human play pass for attack pace, device pursuit, announcements, recall availability, and ordinary contact feel.
  - Accept: document authority, visual authority, Godot import, every production validator except the workflow's three explicit manual/performance exclusions, native `1280x720` capture, Web release export, itch static verification, and built-Web boot pass; human observations confirm no harmless unprotected overlap, four-device competition after cycle 1, readable rapid source cues, and no collision larger than the visible threat.
  - Guard: do not deploy. A workflow dispatch must use `publish=false`; a push to `master` is approval-gated because the workflow can publish on push.
- [ ] **5.4** Close the execution contract.
  - Change: record final commit IDs, commands/workflow run, exact partial-pass labels, capture/evidence locations, known non-blocking warnings, and any unqualified performance boundary; change frontmatter to `status: done` only after every completion condition passes.
  - Accept: the task checkboxes are the only progress source, this plan names the final evidence, and no required behavior remains only documented or only implemented.

Final local checks before any approval-gated external workflow:

```powershell
./tools/validation/validate_document_authority.ps1
./tools/validation/validate_cardborne_visual_authority.ps1
./tools/godot.ps1 --headless --path . --import
./tools/export_web.ps1 -SkipImport
./tools/validation/validate_itch_web_release.ps1 -ReleaseDirectory build/web
git diff --check
```

The authoritative all-validator, rendered-capture, Web-export, and built-Web boot command sequence is the checked-in `.github/workflows/vehicle-run-validation.yml`. Do not reproduce its deployment step. Use workflow dispatch with `publish=false` only after approval, or run an approved local equivalent that preserves its validator exclusions, `1280x720` capture, four required Web files, and built-artifact boot.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | The task-local Godot validator named in the current task, plus `git diff --check` for edited text | After a coherent owner edit | A relevant implementation input changes |
| Phase gate | The exact focused command block under that phase | All phase tasks pass their acceptance checks | A phase-owned input changes |
| Device capacity trend | `./tools/godot.ps1 --headless --path . --script res://tools/validation/profile_vehicle_pressure.gd` | Once after Phase 3 behavior is coherent | Device query, routing, actor counts, or pressure-fixture inputs change |
| Final gate | The existing `vehicle-run-validation.yml` sequence or approved exact equivalent | Once after Phases 1–5.2 pass and the user aligns on cost/impact | A final-gate input changes |

Validation rules:

- Run the narrowest check that proves the current task.
- Run each phase gate once after its owned tasks pass.
- Do not rerun a passing check merely to regain confidence.
- Rerun a failed check only after a relevant implementation change or a new hypothesis can produce different evidence.
- Preserve exact actor, projectile, device, participant, and effect counts in performance or capture fixtures. Reduced workload cannot manufacture a pass.
- Report `focused validator passed`, `scenario valid`, `native rendered capture passed`, `Web export passed`, and `built-Web boot passed` separately. Do not claim release performance without an eligible clean native/Web performance scenario.
- A static or headless check cannot close attack feel, visual/collision alignment, or built-Web behavior. Use the one final rendered and interaction gate for those claims.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A verified material fact contradicts this contract | Stop the affected branch, update this contract, and obtain required approval before resuming | Do not let the executor choose a new product, architecture, dependency, UX, safety, or validation contract |
| Remote code conflicts with current device or encounter code | Reimplement the named boss behavior through current local owners and validators | Never resolve by accepting the remote file wholesale |
| A tracked remote hunk changes neutral facilities, current devices, ordinary enemies, CI, migration, or unrelated docs | Reject that hunk and keep local `master` | Only the locked boss behavior may cross the branch boundary |
| Six shots per row exceed the fixed hostile projectile store in a valid scenario | Preserve eighteen-shot behavior and boss reserve; correct scheduling/retirement or capacity ownership inside existing fixed limits | Do not reduce row count or weaken collision without revising this contract |
| Four device route fields exceed the `512`-cell combined budget or fail to converge | Preserve four targets and claims; fix incremental scheduling, shared masks, or target invalidation | Do not lower device/participant counts or bypass walls as an optimization |
| A device has fewer than three eligible ordinary enemies | Keep it unresolved until eligible enemies enter; do not assign bosses, summons, fixed actors, or mines | This is valid gameplay state, not a reason to relax eligibility |
| Four simultaneous device events overflow announcements | Coalesce same-tick events into truthful counted bilingual messages | Do not add a HUD panel or silently drop the final count |
| Generic contact double-hits with an authored attack | Give authored contact exclusive precedence for that crossing and fix the resolver | Do not lower authored damage or remove generic contact from other overlaps |
| Collision can damage outside the visible body/effect | Correct collision use to the existing smaller gameplay footprint or correct presentation if it is stale simulation output | Never enlarge presentation solely to hide an oversized collision and never enlarge collision for feel |
| A focused check fails for unrelated pre-existing worktree content | Preserve the failure evidence, isolate the path, and continue only if task-owned acceptance is independently provable | Do not stage, revert, delete, or repair unrelated user work |
| Final CI/workflow execution requires a push or could deploy | Stop and request explicit approval; use workflow dispatch with `publish=false` when approved | No external mutation is implied by this plan |

Implementation-local discoveries may be handled inside the locked contract when they cannot change scope, visible behavior, ownership, architecture, safety, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 4.
- Next task: Task 4.1, double recall replenishment availability while retaining four authored recalls.
- Last completed gate: Phase 3 focused device/map/renderer/localization gate plus the bounded hard-pressure scenario sample.
- Update rule: on start or resume, read this contract and inspect the worktree only enough to confirm checkpoint inputs, then continue from the first unchecked task whose prerequisites pass. After each checkpoint, record concise evidence, check the task, advance this pointer, and commit the coherent phase. Do not mirror progress into another plan.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check passes.
- Every guard, phase gate, and final gate named by this contract passes.
- The five-family common pool, three-by-six spread/rotate barrage, rapid timings, signatures, squads, Stage 6/7/9/10 mechanics, four-device cycle, personal and bounded upgrades, recall policy, and universal contact behavior are runtime truth.
- Korean and English changed surfaces are complete.
- Product and visual documents match implementation and retain local device authority.
- The final task-owned commits contain no unrelated user changes.
- Final evidence records exact validation labels and any performance limit that remains unqualified.
- Frontmatter status changes to `done` only after implementation and final evidence are complete.

Replan when:

- A material discovery invalidates a locked count, timing, lifecycle, ownership boundary, collision invariant, dependency boundary, or validation path.
- Four simultaneous devices cannot be supported inside the fixed route budget without changing gameplay counts or architecture beyond the bounded field-set owner.
- The only path to reliable contact requires removing dash or post-hit protection, increasing collision beyond presentation, changing physics tick rate, or adding a dependency.

Do not replan or stop for:

- Implementation-local mechanics already contained by this contract.
- A passing check whose relevant inputs have not changed.
- A device remaining unresolved because fewer than three eligible ordinary enemies are currently available.
- A rejected remote hunk whose behavior is outside the locked boss scope.

## Anti-Rework Execution Rules

- On start or resume, read this active contract and inspect the current worktree only enough to confirm checkpoint inputs, then continue from the first unchecked task whose prerequisites are satisfied.
- Treat checked tasks and recorded passing evidence as complete unless a relevant input changed, the evidence is missing, or this contract schedules the broader final gate.
- Run each check at its declared cadence. Do not repeat a passing check merely to regain confidence.
- Rerun a failed check only after a relevant implementation change or a new hypothesis can produce different evidence.
- Mark a task complete only after its acceptance check passes; run and record a guard only when that task names one.
- Update task checkboxes and the single progress pointer together after a checkpoint. Do not mirror task state into another document.
- If reality contradicts a material decision, stop that branch and revise this contract before continuing. Handle implementation-local mechanics within the locked contract without reopening planning.
