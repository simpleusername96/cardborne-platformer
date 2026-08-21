---
type: plan
status: active
created: 2026-08-21
scope: Boss pattern semantics, independent boss statistics, attack execution correctness, circular warning readability, hostile beam timing, Stage 10 reflection availability, focused boss-depth improvements, and the Korean implementation report
related:
  - ../../docs/reports/2026-08-21-boss-implementation-analysis.html
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../design/DESIGN.md
  - 2026-08-18-twelve-boss-combat-progression.md
---

# Boss Pattern and Independent Stat Correction - Execution Contract

Cardborne will replace stage-multiplied boss readouts with independently authored boss and pattern values, classify shared attacks by actual runtime behavior rather than display name, repair selectable patterns that do not execute, strengthen two under-specified boss signatures, improve radial warning progression and hostile-beam response time, reduce Stage 10 reflection uptime, and record the plan and verified result in the existing Korean HTML report.

## Purpose

- Objective: make every boss pattern name, runtime behavior, timing, statistic, visual cue, and report classification describe the same implemented attack.
- Deliverable: corrected boss profile and pattern owners, focused validators, synchronized product/visual specifications, updated Korean HTML report, and rendered gameplay evidence for the changed radial, beam, and reflection states.
- Completion state: every task and named gate passes, the report contains planned and completed changes, and this plan is marked `done`.

## Scope and Boundaries

In scope:

- Canonical behavior-family metadata for every selectable direct and autonomous boss pattern.
- A shared-pattern rule based on use by two or more distinct boss stages, regardless of pattern ID or display name.
- Independently authored boss health, movement, active movement, read gaps, autonomous intervals, and independently authored per-stage pattern damage, timing, radius, and width.
- Removal of runtime stage multiplication for boss damage, coverage, startup/active duration, recovery, and attack movement.
- Preservation of the current effective numeric results as the migration baseline unless this contract explicitly changes the value.
- Dispatch coverage for every selectable pattern, including the currently inert Stage 6 direct `long_bank_barrage`.
- Stage 4 `switch_sweep` as a real three-heading sequential emitted-beam sweep instead of a name-only alias of the generic beam topology.
- A full-footprint radial warning whose danger fill darkens monotonically with readiness while gameplay-owned damage-band boundaries remain visible.
- Shared hostile emitted-beam timing: `0.45 s` source charge before damage begins and `0.20 s` collision-owned growth to full length.
- Stage 10 reflection schedule: initial exposed state, one-second activation cue, five seconds active, and fifteen seconds exposed in each twenty-second cycle.
- The existing Korean HTML report, product spec, visual spec, Guidebook adapter, and focused validators.

Out of scope:

- New raster assets, ImageGen work, boss body replacement, ordinary-enemy balance, campaign length, stage quotas, player weapon balance, save migration, or release publication.
- A new difficulty mode or any stage-wide multiplier applied to bosses.
- Removing required radial damage-band boundaries, showing a hostile beam path during startup, or changing collision truth from presentation code.
- Adding a new signature mechanic to every boss. Stage 1 remains the intentionally simplest entry encounter; existing working signatures remain unchanged unless a defect is proven.

Constraints and invariants:

- Use Godot 4.7.1 through `./tools/godot.ps1` and keep gameplay geometry/collision outside presentation code.
- A `pattern ID` identifies an authored selection. A `behavior family` identifies the runtime execution algorithm. A `shared pattern` is any behavior family selected by at least two distinct boss stages. A `signature pattern` is selected by exactly one stage.
- A different name, affinity, damage, radius, direction offset, or cadence does not create a distinct behavior family by itself.
- Boss statistics are absolute authored values. Temporary mechanics such as shield countercharge and Stage 12 overload may still apply explicit state modifiers because they are encounter rules, not stage scaling.
- Preserve fixed-cap stores and existing cleanup semantics. New Stage 4 beam steps reuse existing retained beam/zone capacity and do not add nodes, materials, textures, or production dependencies.
- Circular warnings keep one continuous full-area body from center to exact gameplay radius. Readiness is communicated by monotonic fill intensity, not expanding radius or decorative repeated rings.
- Hostile emitted beams show only source-attached charge geometry during the `0.45 s` startup. Damage and the borderless beam begin together, then grow along collision truth for `0.20 s`.
- Korean remains the default user-facing language and the HTML report must remain readable at desktop and narrow widths.

Destructive or irreversible actions:

- None. No file deletion, dependency change, asset promotion, push, or deployment is authorized by this plan.

Exact actions requiring owner or user approval:

- None within the locked scope. Any change to boss count, boss artwork, player damage, ordinary-enemy scaling, or release state requires a revised contract and user direction.

## Domain Alignment

- Canonical terms: `pattern ID`, `behavior family`, `shared pattern`, `signature pattern`, `boss profile`, and `pattern stats`.
- Current conflict: the report treats only `common_charge` and `common_broad_barrage` as shared, while many differently named IDs execute the same `charge`, `fan`, `lanes`, `cross`, `area`, or emitted-beam code.
- Intended owners: `VehicleBossPatterns` owns pattern IDs, behavior-family metadata, sequences, and absolute pattern stats; a focused boss-profile catalog owns absolute per-boss movement and cadence values; `VehicleBossRuntime` owns sequencing and dispatch; `VehicleRun` owns collision-backed world execution; the renderer consumes readiness and collision truth only.
- Invariant: callers may ask for a stage's profile or a pattern's resolved absolute definition but cannot reconstruct it by multiplying generic base values by a stage factor.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Shared-pattern meaning | `vehicle_boss_patterns.gd` exposes `is_common()` for only two IDs, but runtime dispatch is keyed by `kind`; many different IDs use the same execution branches | `PATTERNS`, `EXTRA_PATTERNS`, `VehicleBossRuntime.update_active()` | Add canonical behavior-family metadata and derive shared/signature status from distinct stage use | 1.1, 1.2 |
| Boss stat ownership | Health is direct, but damage, coverage, attack time, recovery, cadence, and attack movement are composed with stage arrays in `vehicle_stage_difficulty.gd` | Pattern helpers and boss validators assert the multiplier model | Move boss-only absolute values to a focused profile owner and bake current effective pattern values into resolved stage definitions; remove boss multiplier arrays from runtime use | 1.3, 2.1 |
| Inert selectable attack | Stage 6 selects `long_bank_barrage` directly, but `update_active()` has no `long_banks` branch; only autonomous execution calls `_spawn_boss_long_banks()` | Stage 6 direct sequence, runtime dispatch, `VehicleRun._execute_boss_autonomous()` | Add a direct execution receipt and a validator that every selectable kind produces a measurable execution outcome | 2.2 |
| Radial walk-out timing | The effective Stage 3 `radial_pulse` and Stage 5 `relay_pulse_rings` startup values are shorter than their exact radius plus the maintained walk-out margin | Absolute-value migration validator using runtime startup/radius values | Raise only these warnings to `1.28 s` and `1.31 s`; retain their damage, radius, and active duration | 1.3 |
| Name-only beam variation | `switch_sweep`, `focused_beam`, `reflect_lance`, and `resonance_break` all route through the same topology-cycling emitted-beam builder | Telegraph builder and runtime beam collision | Classify generic beams as shared; give Stage 4 `switch_sweep` a three-heading sequential sweep owned by one explicit behavior family | 2.3 |
| Radial warning clarity | Renderer already fills the footprint at alpha `0.10→0.20`, then overlays nested filled disks and dark rings; the result can read as static concentric bands | `_sync_area_telegraph()` and the user's observation | Use one full-footprint fill with a stronger monotonic readiness ramp; retain only the thin gameplay damage-band boundaries and outer perimeter | 3.1 |
| Beam response time | Boss beam startup is pattern-scaled with a `0.65 s` floor, then collision grows for `0.30 s` | attack contract, pattern definitions, runtime and renderer | Use a shared absolute `0.45 s` charge and `0.20 s` collision/presentation growth for hostile boss-emitted beams | 3.2 |
| Stage 10 availability | Reflection starts active and repeats `6 s` active / `2 s` exposed, so it blocks the frontal arc 75% of combat time | `vehicle_late_boss_mechanics.gd`, collision path, renderer | Start exposed; use `15 s` exposed, `1 s` cue, `5 s` active, total `20 s` | 3.3 |
| Documentation drift | Product spec and report describe stage multipliers and the old reflection schedule | `vehicle_game_spec.md`, current HTML report | Synchronize both with independent profiles, behavior-based sharing, exact intentional timing changes, and verified implementation status | 1.4, 4.1 |
| Visual authority | Radial fills, emitted beams, and reflection plate are code-native visual truth governed by the canonical authority pair | Full `VISUAL_SYSTEM.md` read and original-detail reference inspection | Preserve code-native ownership, semantic colors, full-area truth, no startup path, no new asset, and collision-matched active geometry | 3.1-3.3 |

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership, safety, and validation decision is closed.
- Godot 4.7.1 and the repository wrappers/validators are available. No dependency bootstrap is required.
- Remaining unknowns are implementation-local and cannot change this contract.

### Visual authority receipt

- Binding document read completely: `docs/design/VISUAL_SYSTEM.md`.
- Canonical sheet inspected at original `1448×1086` detail: `docs/design/cardborne-universal-art-style-reference.png`.
- Expected and observed sheet SHA-256: `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- Observed `VISUAL_SYSTEM.md` SHA-256: `86e9ab2549793c70c55edf1b1c9856a9811a2a433c445a4f78b221238d30caa2`.
- Original artifact provenance: `C:/Users/BK/.codex/generated_images/019fbfe9-857e-7453-b72d-20908d848577/exec-0b8aa606-cf55-45c1-abb3-fb3df762b080.png`, timestamp `2026-08-02 12:13:44 KST`.
- Task constraints: code-native full-area radial warning, danger semantic color, monotonic readiness, damage-band boundaries only, source-only hostile beam startup, collision-matched active beam, body-attached reflection state, no new raster/SVG/ImageGen asset.
- Raster/ImageGen actual reference use: not applicable; no raster creation or edit is in scope.

## Tasks

### Phase 1: Canonical semantics and independent data contract

Goal: make code and the report name the same actual behavior and establish absolute boss-owned values before changing runtime behavior.

Preconditions:

- Discovery Closure Gate and visual-authority receipt above remain current.

Source owners: `scripts/bosses/vehicle_boss_patterns.gd`, `scripts/bosses/vehicle_boss_profile_catalog.gd`, `scripts/enemies/vehicle_stage_difficulty.gd`, `scripts/progression/vehicle_guidebook_stat_adapter.gd`, `docs/reports/2026-08-21-boss-implementation-analysis.html`

- [x] **1.1** Publish canonical behavior-family metadata for every selectable pattern.
  - Change: add behavior family and variant parameters to definitions; expose stage-use and shared/signature classification without relying on ID prefixes.
  - Accept: every direct/autonomous selection resolves one family, and shared status is true exactly when at least two distinct stages select the family.
- [x] **1.2** Remove name-based common-pattern reporting.
  - Change: update the HTML report to group by shared behavior family and stage signature behavior; show aliases only as implementation IDs.
  - Accept: charge/fan/lanes/cross/area/generic emitted-beam aliases are not presented as unique attacks merely because their IDs differ.
- [x] **1.3** Replace boss stage multipliers with independently authored profiles and resolved absolute pattern stats.
  - Change: add the focused profile catalog; migrate current effective values without rebalancing; remove boss multiplier use from runtime, Guidebook, and validators.
  - Accept: no boss damage, coverage, timing, recovery, cadence, or attack movement value is computed from a stage multiplier; the migrated baseline values match the pre-change effective values within `0.01` except the explicit timing changes in Phase 3.
- [x] **1.4** Record the active correction plan and verified baseline defects in the existing Korean report.
  - Change: add a concise “수정 계획과 진행 상태” section with independent-stat semantics, behavior-family sharing, the Stage 6 dispatch defect, radial/beam work, and Stage 10 schedule target.
  - Accept: the report distinguishes planned, implemented, and verified states and does not call scaled damage “최종 피해.”

Batch gate:

- `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_boss_patterns.gd`
- `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_boss_difficulty_correction.gd`
- `git diff --check`

### Phase 2: Runtime dispatch and boss-pattern depth

Goal: ensure every selectable attack works and give Stage 4 and Stage 6 behavior matching their identity.

Preconditions:

- Phase 1 acceptance checks and batch gate pass.

Source owners: `scripts/bosses/vehicle_boss_runtime.gd`, `scripts/vehicle/vehicle_run.gd`, `scripts/combat/vehicle_attack_telegraph_builder.gd`, `tools/validation/validate_vehicle_boss_runtime.gd`

- [x] **2.1** Add exhaustive selectable-pattern dispatch validation.
  - Change: exercise each selectable direct and autonomous pattern through its real dispatcher and assert projectile, zone, beam, summon, movement/contact, or state output.
  - Accept: no selectable pattern completes without a measurable owned effect, and unsupported kinds fail the validator.
- [x] **2.2** Repair Stage 6 direct long-bank execution.
  - Change: dispatch one direct long-bank volley at active start using the same distance-growth projectile contract as the autonomous version.
  - Accept: direct selection emits exactly ten growth projectiles once; autonomous execution remains unchanged and fixed-cap safe.
- [x] **2.3** Implement the Stage 4 sequential switch sweep.
  - Change: replace the generic topology alias with three collision-backed emitted-beam headings released in sequence under one fixed-cap behavior receipt.
  - Accept: the three headings execute once each, use the shared beam timing from Phase 3, retire cleanly, and never publish a startup path.

Batch gate:

- `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_boss_runtime.gd`
- `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_late_boss_mechanics_correction.gd`

### Phase 3: Warning progression, beam timing, and Stage 10 availability

Goal: make the changed attacks readable in time and keep Stage 10 damageable for most of its cycle.

Preconditions:

- Phase 2 runtime behavior is stable.

Source owners: `scripts/combat/vehicle_attack_contract.gd`, `scripts/presentation/vehicle_combat_renderer.gd`, `scripts/bosses/vehicle_late_boss_mechanics.gd`, `scripts/vehicle/vehicle_run.gd`, `docs/design/VISUAL_SYSTEM.md`

- [x] **3.1** Make radial readiness visually monotonic across the full footprint.
  - Change: use one danger fill ramp from alpha `0.06` to `0.30`; keep the thin outer perimeter and gameplay damage-band rings without nested filled-disk emphasis.
  - Accept: renderer fixtures prove the same radius at start/mid/end, strictly increasing full-footprint alpha, and unchanged boundary radii.
- [x] **3.2** Apply hostile boss-emitted beams sooner.
  - Change: set absolute `0.45 s` charge and `0.20 s` collision/presentation growth for every boss-emitted beam family, including the Stage 4 sweep.
  - Accept: no beam damage occurs before `0.45 s`; collision and pixels begin together at active start; full length is reached at `0.65 s` from initial charge.
- [x] **3.3** Reduce and signal Stage 10 reflection uptime.
  - Change: begin exposed, cue for the final one second of the exposed interval, activate for five seconds, then return to fifteen seconds exposed.
  - Accept: schedule fixtures prove exposed at `0–14 s`, cue at `14–15 s`, active at `15–20 s`, exposed again at `20 s`, and 25% long-run active uptime.

Batch gate:

- `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_combat_renderer.gd`
- `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_boss_identity_cues.gd`
- `./tools/validation/validate_cardborne_visual_authority.ps1`

### Phase 4: Synchronized report and final evidence

Goal: make the Korean report the accurate readable handoff for the corrected implementation.

Preconditions:

- Phases 1–3 pass their acceptance checks.

Source owners: `docs/product/vehicle_game_spec.md`, `docs/design/VISUAL_SYSTEM.md`, `docs/reports/2026-08-21-boss-implementation-analysis.html`, existing capture gateway and production wrapper

- [ ] **4.1** Synchronize canonical specs and the report.
  - Change: replace multiplier language, old beam timing, old Stage 10 schedule, name-based sharing, and known defect notes with implemented truth; retain current production boss images.
  - Accept: code/spec/report values and terminology agree, and report rows show each boss's absolute stats and resolved attack values.
- [ ] **4.2** Capture and inspect one bounded rendered gameplay batch.
  - Change: use the existing project capture path for radial readiness start/mid/end, hostile beam charge/early/full states, and Stage 10 exposed/cue/active states.
  - Accept: actual pixels show monotonic radial darkening, no hostile startup path, collision-matched beam growth, and distinguishable reflection states without clipping or new visual owners.
- [ ] **4.3** Run the final focused and production-style gates.
  - Accept: full import, focused boss/renderer/Guidebook validators, Web export, built-Web smoke, report script validation, and `git diff --check` pass once after the implementation set is complete.

Final gate:

- `./tools/godot.ps1 --headless --path . --editor --quit`
- `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_boss_patterns.gd`
- `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_boss_runtime.gd`
- `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_late_boss_mechanics_correction.gd`
- `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_combat_renderer.gd`
- `./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_guidebook.gd`
- `./tools/export_web.ps1`
- built-Web smoke through the repository fastrun `codex` lane after loading `$npjt-port-guard`
- execute the HTML report script with a stub DOM and assert 12 bosses, 12 images, no unresolved values, and behavior-based shared/signature sections
- `git diff --check`

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | The single focused validator named by the current task | After that task's owner changes | A relevant implementation input changes |
| Phase gate | The commands listed under the phase | All phase tasks pass | A phase-owned input changes |
| Render gate | One capture batch for radial, beam, and reflection states | Phase 3 static/headless checks pass | A visual or timing input changes |
| Final gate | Full import, focused validators, Web export/smoke, report execution, and diff check | All phases pass | A final-gate input changes |

Validation rules:

- Run the narrowest check that proves the current task.
- Run each named phase gate once after its owned tasks pass.
- Rerun a failed check only after a relevant implementation change or a new hypothesis can produce different evidence.
- Do not repeat a passing check merely to regain confidence.
- Use rendered evidence for timing/readability claims; headless success alone cannot prove them.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A verified material fact contradicts this contract | Stop the affected branch, update this contract, and obtain any required approval before resuming | Do not let the executor choose a new product, architecture, data, UX, safety, or validation contract |
| Baking current effective values reveals a pre-existing non-finite or missing value | Fail the migration validator and repair the owning source before removing the old calculation | Do not silently substitute a default stat |
| Stage 4's three beam steps exceed an existing fixed-cap store | Reduce concurrent step retention by retiring completed steps before the next release | Do not increase global capacities without revising the performance contract |
| The stronger radial fill obscures actors/projectiles at runtime | Lower only the locked alpha endpoints while keeping strict monotonicity and the full-footprint contract, then update this plan before rerendering | Do not revert to expanding radius or nested decorative rings |
| The `0.45 s + 0.20 s` beam contract is unreadable in rendered motion | Stop after evidence, record the exact failure, and revise both timing values together | Do not let presentation and collision use different timings |

Implementation-local discoveries may be handled inside the locked contract when they cannot change scope, visible behavior, ownership, architecture, safety, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 4.
- Next task: 4.1, finish report/spec synchronization and remove remaining obsolete terminology.
- Last completed gate: Phase 3 batch gate (`validate_vehicle_combat_renderer`, `validate_vehicle_boss_identity_cues`, and visual-authority validation).
- Phase 1 evidence: all 12 profiles and every selected pattern resolve absolute values; the two walk-out failures found during migration were corrected to 1.28 s and 1.31 s; the report renders 12 boss cards and 12 production images with no unresolved values or boss multiplier readouts.
- Phase 2 evidence: every selection kind resolves an explicit direct/autonomous route; Stage 6 direct long banks emit one ten-projectile receipt; Stage 4 builds three forward collision beams at release delays `0.00/0.18/0.36 s` and uses a distinct signature family.
- Phase 3 evidence: one exact-radius disk remains constant while alpha rises `0.06/0.18/0.30`; beam collision and pixels use a shared `0.20 s` growth after `0.45 s` source charge; reflection fixtures prove exposed/cue/active boundaries at `0/14/15/20 s`.
- Update rule: after a checkpoint passes, record concise evidence, check the task, and advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check passes.
- Every guard, phase gate, and final gate named by this contract passes.
- No placeholder or unresolved material decision remains.
- Code, product/visual specs, Guidebook, and the Korean report agree.
- Frontmatter status changes to `done` only after implementation and final evidence complete.

Replan when:

- A material discovery invalidates the locked independent-stat, pattern-family, timing, reflection, capacity, or validation contract.

Do not replan or stop for:

- Implementation-local mechanics already contained by this contract.
- A passing check whose relevant inputs have not changed.

## Execution Discipline

- On start or resume, read this contract and inspect the current worktree only enough to confirm checkpoint inputs, then continue from the first unchecked task whose prerequisites pass.
- Treat checked tasks and recorded passing evidence as complete unless a relevant input changed, the evidence is missing, or this contract schedules a broader final gate.
- Run each check at its declared cadence and rerun failures only after a relevant change or new hypothesis.
- Mark a task complete only after its acceptance check passes; update the checkbox and progress pointer together.
- If reality contradicts a material decision, stop the affected branch and revise this contract before continuing.
