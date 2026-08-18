---
type: plan
status: active
created: 2026-08-18
scope: Twelve continuous boss cycles, field resource supply, segmented Drydock defense, late-run durability, upgrade-curve expansion, route-safe boss cues, four new bosses, four new ordinary enemy roles, grounded visual production, localization, validation, and release
related:
  - ../../docs/reports/2026-08-18-combat-progression-and-upgrades-ko.html
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/product/vehicle_upgrade_catalog.md
  - ../../docs/product/vehicle_weapon_balance_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../design/DESIGN.md
  - 2026-08-15-eight-boss-combat-depth-and-run-report.md
---

# Twelve-Boss Combat Progression - Execution Contract

Cardborne expands the current single-field eight-cycle run to twelve boss cycles while
keeping boss death limited to future ordinary-enemy composition. The change restores
field-resource availability, replaces Drydock Titan's ineffective frontal defense with a
timed segmented shield, smooths all 27 upgrade curves across three additional levels,
removes full-path previews from bosses 7 and 8, adds four new bosses and four new ordinary
roles, and ships the result through the existing Godot 4.7.1, GitHub, and itch.io paths.

## Purpose

- Objective: make the continuous run sustain resources and meaningful build growth through
  twelve distinct, readable boss encounters without resetting the field at boss death.
- Deliverable: updated gameplay data and runtimes, bilingual product and Guidebook truth,
  approved ImageGen-authored actor rasters, focused validators, production Web export, and
  GitHub/itch.io publication.
- Completion state: every task and named gate passes, exact visual files are approved before
  production promotion, the release workflow succeeds, and this plan is marked `done`.

## Scope and Boundaries

In scope:

- Four initial experience-recall pickups, six initial neutral facilities, and a bounded
  time-based recall replenishment independent of boss death.
- Drydock Titan's three rotating shield segments, three permanent gaps, and exact 8/2-second
  protected/exposed cycle.
- A twelve-cycle ordinary durability curve with an additional late-pressure multiplier that
  starts at cycle 4 and reaches `1.50` at cycle 12.
- A global 30% boss-health increase and authored cycles 9-12 boss profiles.
- Exactly three additional levels for every one of the 27 current upgrade cards.
- Integer-authored damage, health, radius, count, and whole-percent values where the gameplay
  meaning permits; durations and cooldowns use one-decimal-second authoring.
- Source-local rather than full-route anticipation for bosses 7 and 8.
- Four new boss identities and four new ordinary enemy roles for cycles 9-12.
- Korean and English localization, Guidebook/report integration, visual assets, deterministic
  fixtures, Web export, GitHub push, and itch.io deployment.

Out of scope:

- Field geometry replacement, map reset, removal of surviving ordinary enemies, or pickup and
  facility refresh triggered by boss death.
- New engine, production dependency, difficulty selector, save migration, or result-based
  metric evaluation performed by the executor.
- Damage-dealing active weapons. EMP, Black Hole, Shockwave, and Cross Beam remain CC-only.
- SVG or ImageMagick geometric authoring for actors, attacks, cues, UI, report diagrams, or
  review artifacts.
- Replacing any production visual without exact-file approval.

Constraints and invariants:

- Use Godot 4.7.1 through `./tools/godot.ps1`; keep gameplay rules outside UI and visual
  geometry outside collision truth.
- Boss death changes only the composition used for future ordinary spawns. It does not remove
  active ordinary enemies, replace the map, respawn facilities, or repopulate pickups.
- Existing cycles 1-3 ordinary statistics remain unchanged. The extra late-health pressure
  begins at cycle 4 and never compounds by 50% per cycle.
- Ordinary movement retains the `1.30x` stage-speed ceiling. Boss movement has separately
  authored profiles and must continue closing distance to the player.
- Full future attack corridors, wedge footprints, rings, or travel paths are not drawn during
  startup for bosses 7-12. Fairness comes from source charge, body/module state, audio, and a
  brief local entry cue; active hazards remain visible after release.
- Every raster creation or edit supplies
  `docs/design/cardborne-universal-art-style-reference.png` as an actual ImageGen reference.
  The sheet supplies style grammar only. `docs/design/VISUAL_SYSTEM.md` supplies binding
  constraints. Candidate approval remains separate from style conformance.
- Heavy runtime, native, Web, and performance checks run only after the implementation set is
  substantially complete. Targeted deterministic validators remain allowed in the inner loop.

Destructive or irreversible actions:

- None. Replaced assets remain recoverable through Git history. No dependency or engine change
  is authorized.

Exact actions requiring owner or user approval:

- Promote only the exact ImageGen candidate files and SHA-256 hashes shown in the visual review
  batch. Candidate generation and the Korean report do not themselves authorize production use.
- Push and itch.io deployment are already authorized by the user's request, but occur only after
  the final gates pass.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Resource scarcity | `vehicle_field_layout_generator.gd` creates two recalls and three facilities per stage layout, but `vehicle_run.gd::_populate_stage_items()` is called only when the persistent field is initialized | Current source and validators still assert `2` recalls and `3` devices | Start with 4 recalls and 6 facilities. When active recalls fall below 2, replenish one after 90 active-play seconds at a precompiled free pickup anchor, with at most 4 active. Facilities do not respawn | 1.1-1.2 |
| Boss-death continuity | The run now keeps one field and advances future spawn composition | `vehicle_combat_stages.gd`, transition runtime, completed single-field work | Preserve all existing actors and world objects at boss death; only the future ordinary role pool advances | 1.3 |
| Drydock defense | Stage 3 uses `frontal_intercept`; blocked hits deal 50%, the shield follows boss facing, and no reachable branch sets `shield_up = false` | `vehicle_boss_phase_catalog.gd`, `vehicle_boss_shield_runtime.gd` | Use three 80-degree protected arcs separated by three 40-degree gaps, rotating independently at 18 degrees/second. Cycle is 8 seconds up and 2 seconds down. Arc hits deal 15%; gaps/down state deal 100% | 2.1-2.3 |
| Ordinary durability | Current health curve is `1.00..2.00` across eight cycles and stacks global `2.60 * 1.20`; no separate late pressure exists | `vehicle_stage_difficulty.gd`, `vehicle_run.gd::_make_enemy()` | Extend base curve to 12 with `2.00` capped from cycle 8. Multiply by late pressure `[1,1,1,1,1.06,1.13,1.19,1.25,1.31,1.38,1.44,1.50]` | 3.1 |
| Boss health | Current health is 26,000 through 53,300 before the requested increase | `vehicle_stage_difficulty.gd`; Korean report snapshot | Multiply every cycle 1-12 boss profile by `1.30`; use pre-increase multipliers `2.20/2.35/2.50/2.70` for cycles 9-12 | 3.2 |
| Upgrade jumps | Several secondaries improve damage, count, and cadence together; effective step increases exceed 70% and reach roughly 140% | Current weapon resources, card resources, preview rules, and report analysis | Add exactly 3 levels per card. Preserve current L1 and current maximum output as curve anchors, distribute scalar growth monotonically across the expanded level count, and do not raise damage ceilings merely because more levels exist. Discrete behavior unlocks are isolated from simultaneous major damage/cadence jumps | 4.1-4.4 |
| Numeric authoring | Current resources include values such as `79.2`, `1.968`, and `5.75`; simulation relies on floats | Card/weapon resources and runtime owners | Author damage/health/radius/count/percent as integers and time as 0.1-second values. Keep float simulation and round only presentation; do not add repeated runtime truncation | 4.2 |
| Boss 7/8 route leaks | `crossing_weave` and `alternating_pulse` publish warning geometry matching the complete future route | Boss identity runtime and renderer | Remove startup route geometry. Keep source/body charge and local edge-entry cues; show hazard geometry only when active | 5.1 |
| Twelve-cycle expansion | Stage arrays, difficulty arrays, visual catalogs, Guidebook entries, localization, and validators are eight-wide | Current source search and eight-boss validators | Add cycles 9-12 across every owner; no compatibility fallback may silently clamp them to cycle 8 | 5.2-6.3 |
| New combat roles | Existing ordinary roles already cover chase, ranged, denial, repair, shield, carrier, and scavenger pressure | Archetypes, attack contract, specialist runtime | Add Phase Skirmisher, Anchor Drone, Pulse Guard, and Command Relay with the locked contracts below; do not add cosmetic-only reskins | 5.3 |
| Visual production | Eight approved boss bodies and current ordinary actors exist; four new bosses/enemies do not | Production asset tree, semantic provider, visual authority pair | Generate candidates with ImageGen using the canonical sheet as actual reference; approve by exact hash before provider/manifest integration | 6.1-6.2 |

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership, safety, and
  validation decision is closed.
- Godot 4.7.1, repository wrappers, focused validators, ImageGen, Web export, GitHub, and itch.io
  release paths are available. No dependency bootstrap is required.
- The only deliberate approval gate is exact visual candidate promotion; it does not require
  an executor to redesign the gameplay contract.
- Remaining unknowns are implementation-local and cannot change scope, visible behavior,
  ownership, architecture, safety, or acceptance.

### Research application and rejected alternatives

- Local evidence took precedence: current stage, boss, enemy, card, field-layout, Guidebook,
  renderer, localization, and validator owners were inspected directly. The Korean report records
  the current computed values rather than copying an older design proposal.
- The official Returnal UI/UX post supports keeping critical anticipation close to the player or
  attack source and reducing unrelated screen distraction. It applies to source/module charge and
  edge-entry cues; it does not justify removing all anticipation.
  <https://blog.playstation.com/2021/05/11/unpacking-returnals-ux-design-gameplay-first-ui-retro-futuristic-tech-and-accessibility/>
- The Talakat paper supports constructing readable bullet patterns from bounded composable
  spawners and evaluating strategy/dexterity demands. It applies to the fixed-cap boss pattern
  owners; its automated content-generation method is not adopted.
  <https://arxiv.org/abs/1806.04718>
- Furi's official material supports boss-specific exams built from learnable rules and responsive
  control. It applies as a comparison point only; no Furi attack, art, or content is copied.
  <https://www.thegamebakers.com/furi/>
- Rejected: repopulating the field at boss death, because it violates continuous-world ownership;
  compounding ordinary HP by 50% every cycle, because it grows exponentially; forcing all runtime
  arithmetic to integers, because movement/timers would accumulate rounding error; keeping 50%
  shield leakage, because it leaves no strong reason to seek a gap; and removing all warning,
  because source anticipation is still required for fairness.

### Visual authority evidence for this planning/report batch

- Binding document read completely: `docs/design/VISUAL_SYSTEM.md`.
- Canonical sheet inspected at original detail:
  `docs/design/cardborne-universal-art-style-reference.png`.
- Expected and observed SHA-256:
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- Original artifact provenance remains
  `C:/Users/BK/.codex/generated_images/019fbfe9-857e-7453-b72d-20908d848577/exec-0b8aa606-cf55-45c1-abb3-fb3df762b080.png`, timestamp
  `2026-08-02 12:13:44 KST`.
- No raster was created or edited in this batch. The HTML report reuses already approved current
  production actor images, so `actual_image_reference_used=false` and
  `reference_input_method=not_applicable`. Future Task 6.1 requires the actual canonical sheet in
  every ImageGen call.

## Locked Behavior Tables

### Resource supply

| Resource | Current | Required |
| --- | ---: | ---: |
| Initial experience recalls | 2 | 4 |
| Recall replenishment | none | if active count is below 2, one after 90 seconds; maximum 4 active |
| Initial neutral facilities | 3 | 6 |
| Facility replenishment | none | none |

The generator compiles all replenishment anchors at run creation. Replenishment time advances
only during active play and is not reset by boss death, upgrade modal, or pause.

### Drydock Titan segmented shield

| Axis | Required value |
| --- | --- |
| Protected geometry | 3 body-attached arcs, each 80 degrees |
| Open geometry | 3 gaps, each 40 degrees |
| Angular motion | 18 degrees/second, independent of boss facing |
| Cycle | 8.0 seconds shielded, 2.0 seconds fully exposed |
| Damage through protected arc | 15% |
| Damage through gap/down state | 100% |
| Counterburst | retain current charge behavior; prevented damage supplies charge |
| Presentation | one retained code-native segmented shield; no new shield raster |

### Twelve-cycle scaling

| Cycle | Base ordinary HP curve | Extra late HP | Ordinary speed curve | Boss pre-30% HP | Boss final HP | Boss move speed |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 1.00 | 1.00 | 1.00 | 26,000 | 33,800 | 380 |
| 2 | 1.10 | 1.00 | 1.04 | 29,120 | 37,856 | 395 |
| 3 | 1.20 | 1.00 | 1.08 | 32,500 | 42,250 | 410 |
| 4 | 1.35 | 1.00 | 1.12 | 36,140 | 46,982 | 425 |
| 5 | 1.50 | 1.06 | 1.17 | 40,040 | 52,052 | 440 |
| 6 | 1.65 | 1.13 | 1.21 | 44,200 | 57,460 | 455 |
| 7 | 1.82 | 1.19 | 1.26 | 48,620 | 63,206 | 470 |
| 8 | 2.00 | 1.25 | 1.30 | 53,300 | 69,290 | 485 |
| 9 | 2.00 | 1.31 | 1.30 | 57,200 | 74,360 | 495 |
| 10 | 2.00 | 1.38 | 1.30 | 61,100 | 79,430 | 505 |
| 11 | 2.00 | 1.44 | 1.30 | 65,000 | 84,500 | 515 |
| 12 | 2.00 | 1.50 | 1.30 | 70,200 | 91,260 | 525 |

Boss damage multipliers for cycles 9-12 are `1.54/1.62/1.70/1.78`, cadence scales are
`0.52/0.51/0.50/0.49`, and coverage scales are `1.30/1.32/1.34/1.36`. Existing cycles 1-8
retain their damage, cadence, and coverage values.

Boss-entry ordinary defeat quotas are exactly
`90/99/108/117/126/135/144/153/162/171/180/189`. These are the previous six-defeat
progression extended through cycle 12 and multiplied by `1.50`; no hidden time gate is added.

### Upgrade expansion

- New maxima are current maxima plus exactly three: `3 -> 6`, `4 -> 7`, and `2 -> 5`.
- Damage-producing and defensive scalar curves preserve the current L1 and current maximum as
  endpoints. For new level `n` of maximum `N`, use linear interpolation at
  `(n - 1) / (N - 1)`, then round damage/health/radius/whole-percent values to integers and time
  values to 0.1 seconds. If rounding repeats a level, raise it to the smallest valid next grid
  value without changing the final endpoint. CC-only active weapons are the explicit exception
  and use the exact extended curves below.
- A card with two or more multiplicative axes changes only one major axis on a discrete-unlock
  level. Count/cap unlocks do not also receive a major cadence step.
- Secondary weapon balancing uses total volley damage or effective DPS as the primary budget,
  not per-projectile damage in isolation.
- Discrete profiles are fixed as follows: Homing Missiles and Orbiting Blades use counts
  `2/2/3/3/4/4/4`; Drop Mines uses active caps `3/3/4/4/5/5/5`; Split Muzzle uses projectile
  counts `2/2/2/3/3/3`; Piercing Rounds alone extends linearly to 1-7 additional penetrations.
- Active weapons use these exact seven-level curves:
  - EMP: stun radius `285/315/345/375/405/435/465`, clear radius `325/355/385/415/445/475/505`,
    stun `1.4/1.6/1.8/2.0/2.2/2.4/2.6 s`, cooldown `13.0/12.3/11.6/10.9/10.2/9.5/8.8 s`.
  - Black Hole: radius `180/200/220/240/260/280/300`, duration
    `1.6/1.8/2.0/2.2/2.4/2.6/2.8 s`, slow `25/28/31/34/36/38/40%`, cooldown
    `12.0/11.4/10.8/10.2/9.6/9.0/8.4 s`.
  - Shockwave: radius `200/220/240/260/280/300/320`, stagger
    `0.4/0.5/0.6/0.7/0.8/0.9/1.0 s`, push `180/200/220/240/260/280/300`, cooldown
    `9.0/8.6/8.1/7.7/7.2/6.8/6.3 s`.
  - Cross Beam: half-width `28/34/40/46/52/58/64`, slow duration
    `1.5/1.8/2.0/2.3/2.5/2.8/3.0 s`, slow `25/28/30/33/35/38/40%`, cooldown
    `10.5/9.9/9.4/8.8/8.3/7.7/7.2 s`.
- The Korean report is the locked current-state inventory for every card. Implementation updates
  `docs/product/vehicle_upgrade_catalog.md` with the generated expanded curves before changing
  resources, so data, preview, and runtime use one reviewed table.

### New cycles 9-12

| Cycle | Boss | Identity and counterplay | New ordinary role |
| ---: | --- | --- | --- |
| 9 | 위상 절단기 / Phase Cutter | Two source-paired cutter bars enter from flashed field edges. No route line is shown; the active bars reveal their own bodies. Alternating entry timing creates a readable moving gap | 위상 척후기 / Phase Skirmisher: HP 76, speed 188, radius 20; three-shot lateral burst, 11 damage each, 0.75 s startup, 1.0 s recovery |
| 10 | 중력 닻 / Gravity Anchor | Three body modules light in order and emit bounded pull pulses; destroying nothing is required. The lit module identifies pulse origin, and the active field is visible only after release | 닻 드론 / Anchor Drone: HP 92, speed 154, radius 23; 180-radius pull zone followed by 18 damage, 0.9 s startup, 1.2 s active |
| 11 | 공명 반응로 / Resonance Reactor | Core state alternates near and far pulses. Color plus core aperture state communicates which pulse comes next without drawing its final ring footprint | 펄스 수호기 / Pulse Guard: HP 108, speed 168, radius 25; alternating near/far burst, 18 damage, 1.0 s startup |
| 12 | 지휘 코어 / Command Core | Three body modules run a fixed three-beat sequence that remixes edge entry, pulse, and focused barrage. The active module communicates attack family; no complete path is previewed | 지휘 중계기 / Command Relay: HP 98, speed 150, radius 24; within radius 320 grants ordinary allies +10% damage and 15% shorter recovery; never affects bosses or another relay |

Every new role uses the existing ordinary stage health, speed, and damage multipliers. Their base
values above are authored values before those multipliers.

## Tasks

### Phase 1: Persistent-field supply and continuity

Goal: make recalls and facilities findable throughout the longer run without making boss death a
world-reset event.

Preconditions:

- The current worktree and this contract are read; current generator counts still match the
  report snapshot or the contract is revised first.

Source owners: `scripts/vehicle/vehicle_field_layout_generator.gd`,
`scripts/vehicle/vehicle_run.gd`, pickup/device runtimes, minimap snapshot owners, and focused
field/reward validators.

- [ ] **1.1** Generate four recall pickups, six facilities, and bounded reserve anchors.
  - Accept: deterministic layouts for every field contain exactly 4 recalls and 6 facilities,
    all reachable, separated, and outside reserved geometry; reserve anchors are deterministic.
- [ ] **1.2** Add the 90-second recall replenishment rule.
  - Accept: a frame-step fixture proves active count, timer, pause/modal exclusion, four-active
    cap, anchor reuse safety, and no allocation or scan in the hot path.
- [ ] **1.3** Preserve boss-death continuity.
  - Accept: defeating a boss changes only the future role pool; existing enemies, pickups,
    facilities, structural geometry, and field fingerprint remain unchanged.

Checkpoint: update these checkboxes with fixture evidence, report the exact supply behavior, and
continue to Phase 2 only after the phase gate passes.

Batch gate:

- Run the field-layout, experience, rewards, pickup-contact, mystery-device, continuous-field,
  and single-field validators once.

### Phase 2: Drydock segmented defense

Goal: replace passive damage padding with visible openings and a reliable focus-fire window.

Preconditions:

- Phase 1 passes.

Source owners: `scripts/bosses/vehicle_boss_phase_catalog.gd`,
`scripts/bosses/vehicle_boss_shield_runtime.gd`, boss damage intake, retained renderer shield
batch, Guidebook stat adapter, localization, and boss-exam validators.

- [ ] **2.1** Implement the exact angular and 8/2-second state machine.
  - Accept: deterministic angle tests prove every arc edge, every gap, independent 18-degree
    rotation, 15% protected damage, 100% gap damage, and exactly 2.0 exposed seconds per cycle.
- [ ] **2.2** Publish collision-owned scalar presentation state to the retained renderer.
  - Accept: one code-native shield batch draws three segments that match gameplay intervals at
    representative rotations; no raster, node-per-segment, or full-screen route overlay exists.
- [ ] **2.3** Update state messages and Guidebook truth.
  - Accept: Korean/English shield-up and shield-down messages and 85% reduction/2-second exposure
    rows match runtime snapshots without duplicate HUD ownership.

Checkpoint: record shield timing and angular fixture evidence before Phase 3.

Batch gate:

- Run boss exam, shield, renderer, Guidebook, localization, and visual-authority validators once.

### Phase 3: Twelve-cycle stat and spawn ownership

Goal: extend progression without resetting the map or changing early-run difficulty.

Preconditions:

- Phase 2 passes.

Source owners: `scripts/vehicle/stages/vehicle_combat_stages.gd`,
`scripts/enemies/vehicle_stage_difficulty.gd`, encounter director stage arrays, stage transition,
stage/result/Guidebook snapshots, and campaign validators.

- [ ] **3.1** Extend every stage-owned array and apply the locked ordinary curves.
  - Accept: cycles 1-3 are byte-for-byte equivalent in computed ordinary health/speed/damage;
    cycle 4 has no extra late multiplier; cycle 12 applies exactly `2.00 * 1.50` before global
    ordinary durability factors; speed never exceeds the 1.30 stage curve.
- [ ] **3.2** Apply 30% boss health and add cycles 9-12 boss profiles.
  - Accept: computed health matches the locked table for all twelve cycles and no owner clamps
    stage IDs 9-12 to stage 8.
- [ ] **3.3** Extend quotas, authored counts, spawn composition, reports, and run completion.
  - Change: raise the boss quota gate to 1.5 times the previous per-position eight-cycle curve,
    rounded to integers, and author cycles 9-12 consistently; boss death changes only future
    composition.
  - Accept: a deterministic fixture completes exactly twelve bosses, every boss appears only
    after its quota, and active ordinary enemies survive transitions.

Checkpoint: record the twelve computed profiles and deterministic completion fixture before
Phase 4.

Batch gate:

- Run campaign ownership, stage transition, continuity, telemetry, report, Guidebook, and
  encounter-cap validators once.

### Phase 4: Expanded and smoothed upgrade curves

Goal: make every card progress through three more readable steps without damage-dealing active
weapons or hidden float-heavy authored values.

Preconditions:

- Phase 3 passes and the longer run supplies enough upgrade offers to reach the expanded curves.

Source owners: `data/cards/vehicle/`, `data/weapons/vehicle/`, card catalog/build/offer owners,
primary/secondary/active runtimes, effect preview, product catalog, UI snapshots, and validators.

- [ ] **4.1** Generate and review one canonical expanded-curve table from the locked rules.
  - Accept: all 27 cards have current maximum +3, monotonic values, no missing level,
    damage-producing/defensive L1 and current-maximum endpoint preservation, exact active-weapon
    curves, and one visible change at every new level.
- [ ] **4.2** Replace authored values with integer and one-decimal-time values.
  - Accept: card and weapon resources contain no fractional damage/health/radius/count/whole
    percent and no time precision beyond one decimal; runtime remains float-based.
- [ ] **4.3** Separate multiplicative axes on secondary weapon levels.
  - Accept: a calculated effective-output table has no simultaneous major count/cap and cadence
    jump; each discrete unlock is labeled and bounded independently.
- [ ] **4.4** Update offers, previews, localization, product truth, and level-state expectations.
  - Accept: catalog size remains 27, total level states become 172, all legal levels can be
    offered/applied, and Korean/English previews equal gameplay snapshots.

Checkpoint: record the final 27-card curve table and focused validator evidence before Phase 5.

Batch gate:

- Run upgrade system, conditional upgrade, active/secondary runtime, upgrade UI, offer, and
  localization validators once.

### Phase 5: Route-safe boss patterns and new combat identities

Goal: refine bosses 7/8 and implement cycles 9-12 with source-readable, route-hidden attacks and
four distinct ordinary roles.

Preconditions:

- Phase 4 passes.

Source owners: `scripts/bosses/`, `scripts/enemies/`, combat renderer and effect store,
`vehicle_combat_stages.gd`, Guidebook catalog/stat adapter, and relevant fixed-cap stores.

- [ ] **5.1** Remove complete startup paths from Vector Loom and Pulse Core.
  - Accept: startup snapshots contain source/body and local entry cues but zero future corridor,
    wedge, or ring geometry; active collision and presentation remain coincident.
- [ ] **5.2** Implement the four locked boss identities and profiles.
  - Accept: each boss completes its direct and autonomous sequences, has a distinct counterplay
    fixture, honors fixed capacities, and exposes no full-path startup overlay.
- [ ] **5.3** Implement the four locked ordinary roles and cycle compositions.
  - Accept: role fixtures prove exact base stats, startup, attack/support rules, target priority,
    boss/relay exclusions, stage scaling, and bounded storage.
- [ ] **5.4** Extend boss/add cleanup and report ownership through cycle 12.
  - Accept: no boss-owned damaging object survives cleanup, ordinary non-owned actors do survive,
    and the final report contains twelve ordered boss records.

Checkpoint: record pattern/collision fixtures and capacity counts before visual production.

Batch gate:

- Run boss pattern/runtime/identity, enemy expansion/specialist/movement, effect-store, fixed-cap,
  Guidebook, and twelve-cycle campaign validators once.

### Phase 6: Grounded visuals and bilingual surfaces

Goal: give the four bosses and four enemies production-ready identities without changing gameplay
truth or violating the visual authority pair.

Preconditions:

- Phase 5 gameplay identities and actual-size requirements are stable.

Source owners: `docs/design/VISUAL_SYSTEM.md`, canonical style sheet, visual workbench,
`art/visuals/production/`, semantic manifest/provider, actor visual catalog, Guidebook previews,
and localization catalogs.

- [ ] **6.1** Generate one ImageGen candidate batch for the eight new actors.
  - Change: pass the canonical sheet as an actual reference and state that it is style grammar
    only; require one dominant silhouette, 3-5 planes for ordinary enemies, 4-6 planes for
    bosses, dark perimeter, restrained accents, and actual-size readability.
  - Accept: provenance, prompt, canonical paths, expected/observed sheet hash, actual reference
    input, and actual-size/grayscale sheets are recorded; no SVG/ImageMagick authoring occurs.
- [ ] **6.2** Present exact candidates for approval and promote only approved hashes.
  - Accept: provider, manifest, actor catalog, Guidebook, and runtime resolve the approved files;
    rejected/unapproved files remain outside production.
- [ ] **6.3** Complete Korean/English names, descriptions, stat rows, reports, and twelve-cycle UI.
  - Accept: localization coverage, text bounds, 200% text, and supported viewport checks pass.

Checkpoint: report approved hashes, runtime semantic IDs, and rendered evidence before Phase 7.

Batch gate:

- Run visual authority, semantic provider/coverage/separation, actor visual, Guidebook, UI
  localization, and rendered text-fit validators once.

### Phase 7: Final validation and release

Goal: validate the complete implementation once at production scope and publish it.

Preconditions:

- Phases 1-6 and their gates pass; exact visual promotion is approved.

Source owners: repository validators, Web export preset, release workflow, GitHub `master`, and
itch.io HTML5 channel.

- [ ] **7.1** Run the broad native and deterministic final gate.
  - Accept: all focused validators named above, full Godot import, `git diff --check`, and native
    production smoke pass with no new blocker.
- [ ] **7.2** Run the one deferred heavy performance and Web gate.
  - Accept: fixed-cap/capacity checks, production Web export, built-Web smoke, and the existing
    Cardborne performance evidence contract pass or record a truthful blocked verdict.
- [ ] **7.3** Commit task-owned changes, push `master`, and publish itch.io.
  - Accept: local and `origin/master` SHAs match, release workflow succeeds, and the itch.io
    HTML5 build reports the same payload SHA.

Checkpoint: record final SHAs, release run, itch.io payload, and close this contract only after
all acceptance checks pass.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | The single phase-owned command in **Exact gate commands** that covers the changed owner | After the task-owned behavior is implemented | Relevant task input changes |
| Phase gate | The validator batch listed under that phase | All phase tasks pass | A phase-owned input changes |
| Visual gate | `./tools/validation/validate_cardborne_visual_authority.ps1` plus visual provider/coverage validators | Visual contract, workbench, candidate state, or production visual inputs change | A visual-authority input changes |
| Final native gate | Full import, all named focused validators, native production smoke, and `git diff --check` | Phases 1-6 pass | A final-gate input changes |
| Final Web/performance gate | Existing Cardborne performance evidence path, production Web export, built-Web smoke, and release validator | Native final gate passes | A performance/Web/release input changes |

Validation rules:

- Run the narrowest check that proves the current task.
- Run each named phase gate once after its owned tasks pass.
- Do not open the game or repeat broad performance checks between small edits.
- Rerun a failed check only after a relevant implementation change or a new hypothesis can
  produce new evidence.
- Record known non-blocking warnings once instead of rediscovering them.

### Exact gate commands

Run from the repository root. Each `./tools/godot.ps1` call is a separate command and its exit
code must be zero.

- Phase 1:
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_field_layout_generation.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_experience.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_rewards_ui_audio.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_pickup_contact.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_mystery_device_runtime.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_continuous_field_transition.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_single_field_campaign.gd`
- Phase 2:
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_boss_exams.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_boss_identity_cues.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_combat_renderer.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_guidebook.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_ui_localization.gd`
  - `./tools/validation/validate_cardborne_visual_authority.ps1`
- Phase 3:
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_campaign_ownership.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_stage_transition_runtime.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_stage_continuity.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_stage_telemetry.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_stage_report.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_run_result_builder.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_twelve_boss_campaign.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_twelve_cycle_catalog.gd`
- Phase 4:
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_upgrade_system.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_conditional_upgrades.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_active_weapons.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_secondary_weapons.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_upgrade_ui.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_weapon_balance_contract.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_build_snapshot.gd`
- Phase 5:
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_boss_patterns.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_boss_runtime.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_boss_identity_cues.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_attack_route_readability.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_late_boss_identities.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_enemy_expansion.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_enemy_specialist_runtime.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_effect_store.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_enemy_store.gd`
- Phase 6:
  - `./tools/validation/validate_cardborne_visual_authority.ps1`
  - `./tools/validation/validate_visual_replacement_workbench.ps1`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_semantic_asset_provider.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_visual_asset_coverage.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_semantic_visual_separation.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_actor_visuals.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_guidebook.gd`
  - `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_ui_localization.gd`
- Final native gate:
  - `./tools/godot.ps1 --headless --path . --editor --quit`
  - `Get-ChildItem tools/validation/validate_vehicle_*.gd | Sort-Object FullName | ForEach-Object { ./tools/godot.ps1 --headless --path . --script $_.FullName; if ($LASTEXITCODE -ne 0) { throw "Validator failed: $($_.Name)" } }`
  - `git diff --check`
- Final Web/release gate:
  - `./tools/export_web.ps1`
  - `./tools/validation/validate_itch_web_release.ps1 -ReleaseDirectory build/web`

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain required approval before resuming | Do not let the executor choose a new product, architecture, data, UX, safety, or validation contract |
| Six facilities or recall reserve anchors cannot satisfy deterministic separation | Expand only the precompiled anchor candidate set; do not reduce counts or weaken reachability/clearance | Revise the contract if field geometry itself must change |
| Expanded card endpoint interpolation creates a non-monotonic or invisible level | Raise the intermediate rounded value to the smallest next valid integer/0.1-second step and keep the endpoint fixed | Revise the contract if endpoint power must change |
| A new boss/role exceeds a fixed-cap store | Reduce that identity's simultaneous emissions/summons while preserving its counterplay and cadence | Do not increase global capacities without revising the performance contract |
| ImageGen candidates fail actual-size silhouette or authority evidence | Regenerate with the same locked gameplay identity and authority pair | Do not repair with SVG/ImageMagick or promote an unapproved file |

Implementation-local discoveries may be handled inside the locked contract when they cannot
change scope, visible behavior, ownership, architecture, safety, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 1.
- Next task: 1.1, generate the increased initial field supply and reserve anchors.
- Last completed gate: Discovery Closure Gate. The Korean current-state report was created at
  `docs/reports/2026-08-18-combat-progression-and-upgrades-ko.html`.
- Update rule: after a checkpoint passes, record concise evidence, check the task, and advance
  this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check passes.
- Every guard, phase gate, and final gate named by this contract passes.
- No placeholder or unresolved material decision remains.
- Product, upgrade, visual, Guidebook, localization, and release truth agree on twelve cycles.
- Frontmatter status is changed to `done` only after implementation and publication complete.

Replan when:

- A material discovery invalidates a locked product, architecture, visual, data, safety, capacity,
  or release decision.

Do not replan or stop for:

- Implementation-local mechanics already contained by this contract.
- A passing check whose relevant inputs have not changed.

## Execution Discipline

- On start or resume, read this contract and inspect the current worktree only enough to confirm
  checkpoint inputs, then continue from the first unchecked task whose prerequisites pass.
- Treat checked tasks and recorded passing evidence as complete unless a relevant input changed,
  the evidence is missing, or this contract schedules a broader final gate.
- Run each check at its declared cadence. Do not repeat a passing check merely to regain confidence.
- Mark a task complete only after its acceptance check passes; update the checkbox and progress
  pointer together.
- If reality contradicts a material decision, stop that branch and revise this contract before
  continuing.
