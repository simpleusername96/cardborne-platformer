---
type: plan
status: done
created: 2026-08-18
scope: Twelve continuous boss cycles, generic stage/enemy/boss naming, rolling boss-introduction enemy rosters, field resource supply, segmented stage-3 boss defense, late-run durability, raised and smoothed upgrade ceilings, route-safe boss cues, fixed visual production, localization, validation, and release
related:
  - ../../docs/reports/2026-08-18-combat-progression-and-upgrades-ko.html
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/product/vehicle_upgrade_catalog.md
  - ../../docs/product/vehicle_weapon_balance_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../design/DESIGN.md
  - 2026-08-15-eight-boss-combat-depth-and-run-report.md
---

# Generic Twelve-Boss Learning Progression - Execution Contract

Cardborne expands the current single-field eight-cycle run to twelve boss cycles while
keeping boss death limited to future ordinary-enemy composition. Every tracked game-owned
stage, ordinary-enemy, and boss proper noun becomes a generic stage/role identifier and
bilingual ordinal label. A three-role rolling roster makes the current cycle's teaching
enemy introduce one essential response used by that cycle's boss without copying the full
boss pattern. The change also restores field-resource availability, gives the stage-3 boss
a timed segmented shield, raises and smooths all 27 upgrade curves across three additional
levels, removes full-path previews from bosses 7 and 8, and ships through the existing
Godot 4.7.1, GitHub, and itch.io paths.

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
- Repository-wide removal of game-owned proper nouns for stages, ordinary enemies, and bosses,
  including code IDs, localization keys, tests, docs, reports, asset filenames, manifests, and
  retained candidate metadata. Git history, third-party/provenance names, and upgrade-card names
  remain unchanged.
- A generic identity contract: public/catalog IDs use `ordinary_<role>_<level>` or
  `boss_stage_<number>`; bilingual labels use `근거리 일반 적 Lv.1` / `Melee Enemy Lv.1` and
  `스테이지 3 보스` / `Stage 3 Boss`. Mechanic identifiers such as `ram`, `frontal_shield`,
  and `crossing_wall` remain descriptive and are not actor names.
- A rolling three-role mobile roster with two initial basics and one teaching role per boss cycle.
  Only future admissions use the new roster; already-live ordinary enemies survive boss death.
- The stage-3 boss's three rotating shield segments, three permanent gaps, and exact 8/2-second
  protected/exposed cycle.
- A twelve-cycle ordinary durability curve with an additional late-pressure multiplier that
  starts at cycle 4 and reaches `1.50` at cycle 12.
- A global 30% boss-health increase and authored cycles 9-12 boss profiles.
- Exactly three additional levels for every one of the 27 current upgrade cards, with raised
  scalar ceilings and unchanged projectile/count/penetration ceilings.
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
| Generic naming | Proper nouns are spread through runtime IDs, localization keys, tests, docs, reports, actor filenames, manifests, capture fixtures, and workbench metadata | Tracked-tree search plus `vehicle_combat_stages.gd`, archetype/Guidebook catalogs, localization CSV, semantic manifest, validation fixtures | Remove every game-owned stage/enemy/boss proper noun from the tracked working tree. Use ordinal boss IDs/labels and role-plus-level ordinary IDs/labels. Preserve upgrade names, Git history, external provenance, and descriptive mechanic IDs | 3.1-3.2, 6.2-6.3 |
| Teaching roster | Current cycles expose 4-13 mobile roles and family weighting; boss association is incidental and boss death already affects only future spawns | `vehicle_combat_stages.gd::MOBILE_ROLES`, `_role_sequence_for_arc`, phase add tables, continuity contract | Use one three-slot queue: cycle 1 is two basics plus teaching role 1; every next cycle evicts the oldest slot and appends that cycle's teaching role. The current teaching role owns 25% of future ordinary admissions (12% for the cycle-12 support role), is encountered at least four times before the quota, and shares exactly one response rule with its boss | 3.3-3.5 |
| Stage-3 defense | Stage 3 uses `frontal_intercept`; blocked hits deal 50%, the shield follows boss facing, and no reachable branch sets `shield_up = false` | `vehicle_boss_phase_catalog.gd`, `vehicle_boss_shield_runtime.gd` | Use three 80-degree protected arcs separated by three 40-degree gaps, rotating independently at 18 degrees/second. Cycle is 8 seconds up and 2 seconds down. Arc hits deal 15%; gaps/down state deal 100% | 2.1-2.3 |
| Ordinary durability | Current health curve is `1.00..2.00` across eight cycles and stacks global `2.60 * 1.20`; no separate late pressure exists | `vehicle_stage_difficulty.gd`, `vehicle_run.gd::_make_enemy()` | Extend base curve to 12 with `2.00` capped from cycle 8. Multiply by late pressure `[1,1,1,1,1.06,1.13,1.19,1.25,1.31,1.38,1.44,1.50]` | 3.1 |
| Boss health | Current health is 26,000 through 53,300 before the requested increase | `vehicle_stage_difficulty.gd`; Korean report snapshot | Multiply every cycle 1-12 boss profile by `1.30`; use pre-increase multipliers `2.20/2.35/2.50/2.70` for cycles 9-12 | 3.2 |
| Upgrade jumps and ceilings | Several secondaries improve damage, count, and cadence together; effective step increases exceed 70% and reach roughly 140%. The previous plan incorrectly froze current maximum output | Current weapon resources, card resources, preview rules, report analysis, and user correction | Add exactly 3 levels per card. Preserve L1, raise direct offense/defense scalar ceilings to 130% of current maximum, utility ceilings to 120%, and CC scalar benefit to approximately 120% using the locked active curves. Keep projectile/count/penetration maxima unchanged and distribute their existing unlocks across paired level bands; every level still raises a scalar | 4.1-4.4 |
| Numeric authoring | Current resources include values such as `79.2`, `1.968`, and `5.75`; simulation relies on floats | Card/weapon resources and runtime owners | Author damage/health/radius/count/percent as integers and time as 0.1-second values. Keep float simulation and round only presentation; do not add repeated runtime truncation | 4.2 |
| Boss 7/8 route leaks | `crossing_weave` and `alternating_pulse` publish warning geometry matching the complete future route | Boss identity runtime and renderer | Remove startup route geometry. Keep source/body charge and local edge-entry cues; show hazard geometry only when active | 5.1 |
| Twelve-cycle expansion | Stage arrays, difficulty arrays, visual catalogs, Guidebook entries, localization, and validators are eight-wide | Current source search and eight-boss validators | Add cycles 9-12 across every owner; no compatibility fallback may silently clamp them to cycle 8 | 5.2-6.3 |
| Combat roles | Existing ordinary roles cover enough mechanics for cycles 1-8; four generated candidate roles cover cycles 9-12 | Archetypes, attack contract, specialist runtime, candidate batch | Normalize to two basics plus twelve teaching roles. Reuse or adapt existing mechanics for teaching roles 1-8 and implement the four already-planned mechanics for 9-12. Retire mobile roles outside the three-slot progression unless a fixed installation or boss-add contract still owns them | 3.3-3.5, 5.3 |
| Visual production | Existing and generated actor images are not visually preferred but the user explicitly fixed them for this implementation | Production asset tree, candidate batch, user decision | Do not redesign or regenerate visuals. Rename files/semantic IDs generically and promote the existing cycle 9-12 candidates as the fixed inputs while preserving their exact pixels | 6.1-6.2 |

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
- Itay Keren's GDC boss-design material describes bosses as skill tests and recommends testing
  recently taught skills. It supports the teaching-role link, but the plan deliberately shares
  only one response rule so an ordinary enemy cannot disclose or duplicate the full boss exam.
  <https://media.gdcvault.com/gdc2018/presentations/Keren_Itay_BossUp.pdf>
- Sébastien Lambottin's combat-design guidance treats enemies as incremental teaching challenges.
  It supports repeated bounded exposure before each boss and the conservative 25% teaching-role
  share instead of replacing every encounter with a boss-pattern miniature.
  <https://www.gamedeveloper.com/design/make-your-enemies-stupider-if-it-helps-your-player-learn>
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
- The user-directed Task 6.1 candidate batch now exists at
  `docs/design/visual-replacement-workbench/candidates/twelve-boss-actor-assets-v1/`.
  All eight ImageGen calls used the canonical sheet as the actual referenced image, so
  `actual_image_reference_used=true` and `reference_input_method=built_in_image_gen`.
- `candidate-manifest.json` records the shared prompt contract, per-actor subject prompt, generated
  source hash, normalized candidate hash, expected/observed authority hash, alpha-removal command,
  and `pending_user_approval` / `not_integrated` state. The Korean report owns color, actual-canvas,
  and grayscale review presentation. No SVG or ImageMagick geometry authoring occurred; local
  processing was limited to chroma alpha removal, proportional resize, and centered canvas extent.

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

### Stage-3 boss segmented shield

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

### Twelve-cycle scaling (superseded historical decision)

The following 30% boss-health table is retained only as completed-history evidence. Phase 9
supersedes every boss-health value in its two boss-health columns; ordinary curves remain active.

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

The active authored boss maximum-health sequence is
`16900/21300/28300/36800/46700/57500/69200/81600/94600/108200/122300/136890`.

Boss-entry ordinary defeat quotas are exactly
`90/99/108/117/126/135/144/153/162/171/180/189`. These are the previous six-defeat
progression extended through cycle 12 and multiplied by `1.50`; no hidden time gate is added.

### Upgrade expansion

- New maxima are current maxima plus exactly three: `3 -> 6`, `4 -> 7`, and `2 -> 5`.
- Preserve each current L1. Set the new final scalar endpoint to exactly `1.30` times the current
  maximum for direct offense and defense, and `1.20` times the current maximum for mobility,
  pickup, sustain, radius-only utility, and non-damaging control benefit. Round authored
  damage/health/radius/whole-percent values to integers and times to 0.1 seconds. Interpolate
  monotonically across all levels in effective-output space; no level may be a dead level.
- A card with two or more multiplicative axes changes only one major axis on a discrete-unlock
  level. Count/cap unlocks do not also receive a major cadence step.
- Secondary weapon balancing uses total volley damage or effective DPS as the primary budget,
  not per-projectile damage in isolation.
- Projectile, blade, mine-cap, and penetration maxima remain at their current maximum values.
  Existing discrete unlocks are spread into paired level bands: a six-level curve uses
  `low/low/mid/mid/high/high`; a seven-level curve uses `low/low/mid/mid/high/high/high`.
  Within each band, per-projectile damage, interval, duration, radius, or another scalar increases.
  `split_muzzle` therefore uses total projectile counts `2/2/3/3/3/3`; four-to-seven-level
  projectile/count cards use their existing low/mid/high count values as
  `low/low/mid/mid/high/high/high`; `piercing_rounds` ends at its current penetration maximum.
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

### Rolling boss-introduction roster

The roster is a three-slot FIFO queue. Cycle 1 starts with `ordinary_melee_01`,
`ordinary_ranged_01`, and `ordinary_area_01`. Each later cycle removes the oldest slot and appends
that cycle's teaching role. The current teaching role receives 25% of future admissions and at
least four pre-boss encounters; `ordinary_support_01` is capped at 12% because its aura multiplies
other pressure. Existing live actors never change identity or disappear at transition.

| Cycle | Three future-spawn roles | Teaching role -> one boss response |
| ---: | --- | --- |
| 1 | melee 01, ranged 01, area 01 | `ordinary_area_01`: leave a charged circular danger area |
| 2 | ranged 01, area 01, lane 01 | `ordinary_lane_01`: move through an offset lane gap |
| 3 | area 01, lane 01, shield 01 | `ordinary_shield_01`: attack through a rotating gap or down window |
| 4 | lane 01, shield 01, sweep 01 | `ordinary_sweep_01`: cross behind a committed lateral sweep |
| 5 | shield 01, sweep 01, beam 01 | `ordinary_beam_01`: read source charge and leave its firing axis |
| 6 | sweep 01, beam 01, growth 01 | `ordinary_growth_01`: avoid a projectile that becomes stronger with travel |
| 7 | beam 01, growth 01, gap 01 | `ordinary_gap_01`: follow a moving opening in a placed hazard |
| 8 | growth 01, gap 01, pulse 01 | `ordinary_pulse_01`: alternate near/far safe positioning |
| 9 | gap 01, pulse 01, compression 01 | `ordinary_compression_01`: react to the entry edge and cross the current gap |
| 10 | pulse 01, compression 01, reflect 01 | `ordinary_reflect_01`: avoid the frontal plate and attack from the side |
| 11 | compression 01, reflect 01, resonance 01 | `ordinary_resonance_01`: remain in the effective damage band |
| 12 | reflect 01, resonance 01, overload 01 | `ordinary_overload_01`: focus the stronger but vulnerable overload window |

The boss keeps its full multi-pattern exam. A teaching role shares only the stated response,
uses lower coverage and damage, and cannot combine the boss's other phases or autonomous pattern.

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

- [x] **1.1** Generate four recall pickups, six facilities, and bounded reserve anchors.
  - Accept: deterministic layouts for every field contain exactly 4 recalls and 6 facilities,
    all reachable, separated, and outside reserved geometry; reserve anchors are deterministic.
- [x] **1.2** Add the 90-second recall replenishment rule.
  - Accept: a frame-step fixture proves active count, timer, pause/modal exclusion, four-active
    cap, anchor reuse safety, and no allocation or scan in the hot path.
- [x] **1.3** Preserve boss-death continuity.
  - Accept: defeating a boss changes only the future role pool; existing enemies, pickups,
    facilities, structural geometry, and field fingerprint remain unchanged.

Checkpoint: update these checkboxes with fixture evidence, report the exact supply behavior, and
continue to Phase 2 only after the phase gate passes.

Batch gate:

- Run the field-layout, experience, rewards, pickup-contact, mystery-device, continuous-field,
  and single-field validators once.

### Phase 2: Stage-3 segmented defense

Goal: replace passive damage padding with visible openings and a reliable focus-fire window.

Preconditions:

- Phase 1 passes.

Source owners: `scripts/bosses/vehicle_boss_phase_catalog.gd`,
`scripts/bosses/vehicle_boss_shield_runtime.gd`, boss damage intake, retained renderer shield
batch, Guidebook stat adapter, localization, and boss-exam validators.

- [x] **2.1** Implement the exact angular and 8/2-second state machine.
  - Accept: deterministic angle tests prove every arc edge, every gap, independent 18-degree
    rotation, 15% protected damage, 100% gap damage, and exactly 2.0 exposed seconds per cycle.
- [x] **2.2** Publish collision-owned scalar presentation state to the retained renderer.
  - Accept: one code-native shield batch draws three segments that match gameplay intervals at
    representative rotations; no raster, node-per-segment, or full-screen route overlay exists.
- [x] **2.3** Update state messages and Guidebook truth.
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

- [x] **3.1** Replace stage and boss identities with generic ordinal contracts.
  - Change: migrate stage/boss catalog IDs, localization keys, runtime variants, pattern prefixes,
    tests, docs, reports, filenames, semantic manifests, capture fixtures, and workbench metadata.
  - Accept: tracked-tree forbidden-name validation reports zero game-owned stage/boss proper nouns;
    all twelve bosses resolve as `boss_stage_01..12` and bilingual ordinal labels.
- [x] **3.2** Replace ordinary-enemy identities with generic role-and-level contracts.
  - Accept: every ordinary catalog/Guidebook/result/localization/asset identity uses
    `ordinary_<role>_<level>` and a matching bilingual role label; descriptive mechanic IDs remain
    stable and upgrade-card names are unchanged.
- [x] **3.3** Implement the rolling three-role teaching roster.
  - Accept: all twelve pools equal the locked table, each transition changes only future
    admissions, current teaching roles meet their bounded share/minimum exposure, and live actors
    survive unchanged.
- [x] **3.4** Implement and verify the twelve one-mechanic teaching links.
  - Accept: each role fixture proves its one stated response, lower coverage/damage than the boss,
    no copied multi-phase pattern, and no extra route preview.
- [x] **3.5** Extend every stage-owned array and apply the locked ordinary curves.
  - Accept: cycles 1-3 are byte-for-byte equivalent in computed ordinary health/speed/damage;
    cycle 4 has no extra late multiplier; cycle 12 applies exactly `2.00 * 1.50` before global
    ordinary durability factors; speed never exceeds the 1.30 stage curve.
- [x] **3.6** Apply 30% boss health and add cycles 9-12 boss profiles.
  - Accept: computed health matches the locked table for all twelve cycles and no owner clamps
    stage IDs 9-12 to stage 8.
- [x] **3.7** Extend quotas, authored counts, reports, and run completion.
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

- [x] **4.1** Generate and review one canonical expanded-curve table from the locked rules.
  - Accept: all 27 cards have current maximum +3, monotonic values, no missing level,
    preserved L1, exact 130% offense/defense and 120% utility endpoints, exact active-weapon
    curves, unchanged discrete maxima, and one visible scalar change at every new level.
- [x] **4.2** Replace authored values with integer and one-decimal-time values.
  - Accept: card and weapon resources contain no fractional damage/health/radius/count/whole
    percent and no time precision beyond one decimal; runtime remains float-based.
- [x] **4.3** Separate multiplicative axes on secondary weapon levels.
  - Accept: a calculated effective-output table has no simultaneous major count/cap and cadence
    jump; paired count bands and unchanged final count/penetration caps are proved independently.
- [x] **4.4** Update offers, previews, localization, product truth, and level-state expectations.
  - Accept: catalog size remains 27, total level states become 172, all legal levels can be
    offered/applied, and Korean/English previews equal gameplay snapshots.

Checkpoint: record the final 27-card curve table and focused validator evidence before Phase 5.

Batch gate:

- Run upgrade system, conditional upgrade, active/secondary runtime, upgrade UI, offer, and
  localization validators once.

### Phase 5: Route-safe boss patterns and new combat identities

Goal: refine bosses 7/8 and implement cycles 9-12 with source-readable, route-hidden attacks while
the generic teaching-role roster owns pre-boss introductions.

Preconditions:

- Phase 4 passes.

Source owners: `scripts/bosses/`, `scripts/enemies/`, combat renderer and effect store,
`vehicle_combat_stages.gd`, Guidebook catalog/stat adapter, and relevant fixed-cap stores.

- [x] **5.1** Remove complete startup paths from stage-7 and stage-8 bosses.
  - Accept: startup snapshots contain source/body and local entry cues but zero future corridor,
    wedge, or ring geometry; active collision and presentation remain coincident.
- [x] **5.2** Implement the four locked boss identities and profiles.
  - Accept: each boss completes its direct and autonomous sequences, has a distinct counterplay
    fixture, honors fixed capacities, and exposes no full-path startup overlay.
- [x] **5.3** Implement the final four generic teaching-role mechanics.
  - Accept: role fixtures prove exact base stats, startup, attack/support rules, target priority,
    boss/support exclusions, stage scaling, bounded storage, and the links in the rolling table.
- [x] **5.4** Extend boss/add cleanup and report ownership through cycle 12.
  - Accept: no boss-owned damaging object survives cleanup, ordinary non-owned actors do survive,
    and the final report contains twelve ordered boss records.

Checkpoint: record pattern/collision fixtures and capacity counts before visual production.

Batch gate:

- Run boss pattern/runtime/identity, enemy expansion/specialist/movement, effect-store, fixed-cap,
  Guidebook, and twelve-cycle campaign validators once.

### Phase 6: Grounded visuals and bilingual surfaces

Goal: integrate the fixed existing actor images under generic semantic IDs without changing pixels,
gameplay truth, or the visual authority pair.

Preconditions:

- Phase 5 gameplay identities and actual-size requirements are stable.

Source owners: `docs/design/VISUAL_SYSTEM.md`, canonical style sheet, visual workbench,
`art/visuals/production/`, semantic manifest/provider, actor visual catalog, Guidebook previews,
and localization catalogs.

- [x] **6.1** Generate one ImageGen candidate batch for the eight new actors.
  - Change: pass the canonical sheet as an actual reference and state that it is style grammar
    only; require one dominant silhouette, 3-5 planes for ordinary enemies, 4-6 planes for
    bosses, dark perimeter, restrained accents, and actual-size readability.
  - Accept: provenance, prompt, canonical paths, expected/observed sheet hash, actual reference
    input, and actual-size/grayscale sheets are recorded; no SVG/ImageMagick authoring occurs.
- [x] **6.2** Promote the user-fixed candidate hashes and generically rename all actor assets.
  - Accept: provider, manifest, actor catalog, Guidebook, and runtime resolve the fixed exact-pixel
    files through generic IDs; no old proper-noun filename or semantic ID remains.
- [x] **6.3** Complete generic Korean/English names, descriptions, stat rows, reports, and UI.
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

- [x] **7.1** Run the broad native and deterministic final gate.
  - Accept: all focused validators named above, full Godot import, `git diff --check`, and native
    production smoke pass with no new blocker.
- [x] **7.2** Run the one deferred heavy performance and Web gate.
  - Accept: fixed-cap/capacity checks, production Web export, built-Web smoke, and the existing
    Cardborne performance evidence contract pass or record a truthful blocked verdict.
- [x] **7.3 (superseded)** Hold the previous release while combat-feedback correction is active.
  - Evidence: the 2026-08-18 feedback audit invalidated the prior health, late-boss, route-warning,
    progression-exhaustion, and health-bar decisions. Publication is deferred to Task 15.3.

Checkpoint: record final SHAs, release run, itch.io payload, and close this contract only after
all acceptance checks pass.

### Phase 8: Combat-feedback authority correction

Goal: replace the conflicting decisions without duplicating this active contract.

- [x] **8.1** Supersede the uniform 30% boss-health increase, reused cycle-9-12 mechanics,
  fixed-distance supply publication, card-exhaustion completion, and fixed/boss-only health bars.
  - Accept: this contract and the four canonical specs contain the locked correction values and
    no active section still presents a superseded rule as current truth.
- [x] **8.2** Record visual-authority evidence for the correction.
  - Accept: the canonical document was read completely, the reference was inspected at original
    detail, and its observed SHA-256 is
    `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.

### Phase 9: Boss and ordinary durability truth

- [x] **9.1** Author boss maximum health as
  `16900/21300/28300/36800/46700/57500/69200/81600/94600/108200/122300/136890`.
  - Accept: stages 1 and 12 equal the endpoints and all twelve values increase monotonically.
- [x] **9.2** Add startup/active scale
  `1.00/.98/.96/.94/.92/.90/.88/.86/.85/.84/.83/.82`, attack-movement scale
  `.62/.64/.66/.68/.70/.72/.74/.76/.78/.80/.81/.82`, and `0.65s/0.45s` minima.
  - Accept: boss runtime applies the authored scales without producing an instant attack.
- [x] **9.3** Publish final effective ordinary HP in Guidebook and validation snapshots.
  - Accept: output includes role base health plus all active cycle pressure and durability factors.

### Phase 10: Distinct cycle-9-12 mechanics and teaching roles

- [x] **10.1** Implement moving compression slabs with `compression_single`,
  `compression_shift`, and `compression_pair`.
- [x] **10.2** Implement the 100-degree, `6s` on/`2s` off direct-projectile reflection plate.
- [x] **10.3** Implement the alternating `420-760` and `520-880` resonance damage bands.
- [x] **10.4** Implement the delayed, periodic six-second overload exchange and its three attacks.
- [x] **10.5** Replace the final four teaching roles with
  `ordinary_compression_01`, `ordinary_reflect_01`, `ordinary_resonance_01`, and
  `ordinary_overload_01` and verify at least four pre-quota admissions each.
  - Accept: each fixture proves the corresponding response through real damage, reflection,
    distance, or overload state rather than names or roster counts alone.

### Phase 11: Combat presentation correction

- [x] **11.1** Hide every complete future route during startup and keep active geometry equal to
  collision truth.
- [x] **11.2** Cycle hostile beam topology `parallel -> X -> plus`, with source orbs in startup and
  `0.30s` collision-owned growth in active.
- [x] **11.3** Render the stage-3 shield as three independent thick body-attached segments.
- [x] **11.4** Render compression, reflection, resonance, and overload states with the locked
  code-native visual grammar.
- [x] **11.5** Publish always-visible health bars for every visible living hostile through one
  `Overlay_health` MultiMesh of at most `EnemyStore.MAX_LIVE_HOSTILES * 2 = 640` instances.
  - Accept: a 320-hostile structural fixture emits at most 640 backing/fill instances with no
    missing bar or overflow and correct ordinary/fixed/boss diagnostics.

### Phase 12: Viewport-aware field supply

- [x] **12.1** Keep all four recall pickups, ten placed shards, and six facilities in run state,
  while publishing at most one direct item and one dormant facility in the actual viewport.
- [x] **12.2** Use `visible_world.grow(240)` as the activation safety region and preserve already
  visible objects before admitting the nearest waiting anchor.
- [x] **12.3** Retire an uncollected direct item only after 60 published seconds and only while it
  is outside the expanded viewport; relocate it to a validated off-screen anchor without
  teleporting on screen. Facilities never relocate.
  - Accept: supported viewport fixtures preserve state, counts, collision, and the two one-visible
    caps while recall reserve remains separate from viewport publication.

### Phase 13: Progression and conditional-state correction

- [x] **13.1** Add catalog-independent `fallback_firepower`, `fallback_chassis`, and
  `fallback_operations` ranks, previews, application, stats, and snapshots with 20 ranks each.
- [x] **13.2** Offer fallback choices only when compatible cards are exhausted; consume XP pending
  levels only for XP rewards, and show `EXP MAX` only when cards and all fallback ranks are maxed.
- [x] **13.3** Add Piercing Rounds primary-damage multipliers
  `105/111/118/126/135/145/156%` while preserving additional penetration
  `1/1/2/2/3/3/4`.
- [x] **13.4** Replace formatted gameplay-owned conditional strings with structured status and
  keep owned inactive states visible; show all statuses in paused Ship Status.
  - Accept: Korean/English HUD and Pause output agrees with live stacks, bonus, next-hit bonus,
    and remaining time; activation uses only a 0.18-second edge accent and respects reduced motion.

### Phase 14: Sustained boss combat and synchronized truth

- [x] **14.1** Continue bounded maintenance packets from the active three-role roster after
  authored reserve exhaustion; refresh nearest pursuit instead when capacity is full.
- [x] **14.2** Stop maintenance on boss death/cleanup and preserve the existing low/high watermarks,
  packet size, normal interval, and `0.75s` emergency interval.
- [x] **14.3** Synchronize Guidebook, product specs, localization, diagnostics, and validation.
  - Accept: a headless 180-second stage-1 boss fixture records no visible ordinary-threat gap over
    three seconds without using a synthetic maximum-load benchmark.

### Phase 15: Final verification and corrected release

- [x] **15.1** Run the task-focused validators, full Godot import, and `git diff --check`.
- [x] **15.2** Run production Web export and built-Web functional smoke. Do not run synthetic
  maximum-load, profiler, frame-time, or long performance benchmarks and do not claim performance
  qualification.
- [x] **15.3** Commit only task-owned changes in coherent stages, push `master`, and publish the
  corrected itch.io Web build under the previously approved release scope.
  - Accept: local and remote SHAs agree, release succeeds, and the published payload matches the
    validated build.

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
- Current phase: Complete.
- Next task: None; reopen only for a new user request or a verified release regression.
- Phase 15.3 checkpoint: GitHub Actions run `32130238115` succeeded for commit
  `3f48df33aa57190915f78f17084d8de26dfd9d40`. The remote gate passed all non-performance
  functional validators, a 160-file native capture manifest, Web export, itch.io static
  validation, built-Web boot, itch.io publication, and GitHub Pages deployment. itch.io received
  `alpha.47+3f48df3` on `html5`; the extracted Web payload was 54,541,379 bytes and `index.pck`
  SHA-256 was `6d8965f282e1d406b3f76f668466a6ba980fcfc7cd6c67618faef1993f84170c`.
- Phase 15.1-15.2 checkpoint: final focused boss, route, renderer-capacity, viewport-supply,
  progression, maintenance, localization, Guidebook, UI, and visual validators passed with a full
  Godot 4.7.1 import and `git diff --check`. The production Web export passed the itch.io static
  contract at 9 files and 22,917,785 gzip bytes. The guarded `13029` smoke returned HTTP 200 for
  `index.html` and `index.pck`, Chrome exited zero, and a 1280x720 Godot loading frame rendered.
  The authored XP shards were separated from enemy-drop shards during this gate so the former now
  share the single direct-item viewport slot with recalls. No performance benchmark was run.
- Phase 14 checkpoint: `validate_vehicle_boss_maintenance_180s.gd` passed a simulated 180-second
  living-boss fixture with no visible ordinary-threat gap over three seconds; the existing arrival
  scheduler also passed. Maintenance now cycles a bounded three-role roster after reserve exhaustion.
- Phase 13 checkpoint: `validate_vehicle_progression_correction.gd`, upgrade-system/UI,
  conditional-upgrade, experience, localization, and Guidebook validators passed. They prove three
  20-rank fallback paths, the seven piercing damage/penetration steps, and structured inactive/live
  conditional state in Korean and English.
- Phase 12 checkpoint: `validate_vehicle_viewport_supply_policy.gd` passed one-item and one-dormant-
  facility publication, visible-item retention, off-screen-only 60-second relocation, and fixed
  facility anchors.
- Phase 11 checkpoint: `validate_vehicle_health_bar_capacity.gd` passed 320 visible enemies as
  exactly 640 retained instances with no overflow and correct ordinary/fixed/boss diagnostics.
  Attack-route, boss-runtime, boss-pattern, visual-authority, and monolithic combat-renderer
  validators passed locally and in the successful remote release gate.
- Phase 10 checkpoint: `validate_vehicle_late_boss_mechanics_correction.gd` passed under Godot
  4.7.1. It proves dedicated common-free sequences, exact compression slab/gap/pair timing,
  frontal reflection transfer with preserved speed/life and capped damage, live resonance damage,
  live overload received damage, and at least four admissions for each new teaching role.
- Phase 9 checkpoint: `validate_vehicle_boss_difficulty_correction.gd` and
  `validate_vehicle_guidebook.gd` passed under Godot 4.7.1. The difficulty owner now publishes
  direct boss health, attack-time/movement curves, fairness floors, and final effective ordinary
  HP through the existing Guidebook adapter.
- Phase 8 checkpoint: the active ExecPlan and four canonical specs now contain the correction;
  `validate_cardborne_visual_authority.ps1` passed with the required PNG hash and
  `git diff --check` passed. No raster asset was created or edited.
- Last completed gate: successful corrected release run `32130238115`, including itch.io and
  GitHub Pages publication from validated commit `3f48df33`.
- Release note: GitHub Actions run `32108482311` belonged to the superseded release attempt. The
  corrected itch.io build is `alpha.47+3f48df3`. Synthetic maximum-load, profiler, frame-time,
  and long-duration performance benchmarks were not run and remain outside this correction.
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
