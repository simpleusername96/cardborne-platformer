---
type: plan
status: active
owner: BK
created: 2026-08-13
last_reviewed: 2026-08-13
topic: Commit-linked performance evidence, category-owned upgrade slots, and a scalable exact-enemy runtime
scope: Cardborne performance provenance, upgrade build summaries, ordinary-enemy scheduling and spatial work, native/Web qualification, and capacity exploration
related:
  - ../../AGENTS.md
  - ../PLANS.md
  - ../design/DESIGN.md
  - ../cardborne-performance-engineering-policy.md
  - ../cardborne-runtime-architecture-audit.md
  - ./2026-08-11-dense-combat-progression-and-run-completion.md
  - ./2026-08-13-dense-combat-and-engagement-flow.md
  - ./2026-08-13-run-pacing-result-and-upgrade-slots.md
  - ./2026-08-11-half-scale-continuous-stage-flow.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/product/vehicle_upgrade_catalog.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/performance/2026-08-13-dense-enemy-stutter-evidence.md
  - ../../docs/performance/2026-08-13-dense-enemy-architecture-options.md
  - ../../docs/performance/2026-08-13-enemy-arrival-and-engagement-research.md
---

# Evidence, Category Slots, and Scalable Swarm - Execution Contract

Make performance evidence reproducible from an exact source commit, replace the acquisition-order
upgrade grid with six category-owned slot groups, and remove the remaining production-replay p99
spikes before exploring higher exact-enemy capacities. Keep the approved virtual reserve and current
48 exact-ordinary shipping cap during optimization. Do not simulate fake visible enemies, weaken
combat truth, or raise shipping difficulty merely to claim a larger crowd.

For this request, this plan owns the unresolved performance follow-up shared by the three related
predecessor plans and corrects their flat progressive-grid decision. Their completed gameplay,
engagement, result, and run-clock changes remain current; this plan does not undo them. The
predecessor documents remain in the active tree because removing project records requires explicit
approval, and each now points executors to this plan for the overlapping follow-up scope.

## Purpose

- Objective: make each important performance claim traceable, make the build panel express the
  actual upgrade categories, and give the exact enemy simulation enough headroom for stable play and
  later density growth.
- Deliverable: a tracked evidence ledger and selected raw evidence, grouped category slots reused by
  Upgrade and Result, tail-correlated profiling, measured hot-owner corrections, native/Web
  qualification, and a non-shipping 48/64/96/128 capacity envelope.
- Completion state: the same clean commit passes the existing native `production_replay` physics
  gates (p95 at most `6 ms`, p99 at most `8 ms`), passes built-Web checks, renders all six upgrade
  categories correctly in Korean and English, and records every final artifact under one evidence
  ID. A higher shipping cap remains a separate balance approval even if a larger diagnostic tier
  passes.

## Plain-language Starting Point

The game does not become slow because 43 images are hard to draw. The latest valid run drew the
scene comfortably, but some physics updates performed several expensive enemy jobs together. Those
rare updates reached `11.593 ms`, above the current `8 ms` p99 limit.

Other crowd games can show many enemies because a visible sprite does not necessarily receive the
same amount of work as a Cardborne vehicle. Cardborne currently combines manual-aim projectile
truth, swept motion, cover and line-of-sight, local overlap, statuses, contact, role coordination,
authored arrival rules, rewards, and boss quota accounting. The engineering target is therefore not
"draw more sprites". It is "do less repeated bookkeeping, spread non-urgent work, and keep one
compact exact truth for actors that can affect combat."

The latest clean native evidence is
`build/performance/run-pacing-result-slots-production-replay-final.json`, produced from commit
`4f7f7acd1fdfc8b0265469520d29a0fdd13fea23`. It is scenario-valid and authority-eligible, with 43
median/minimum exact active actors and 269 virtual-reserve units. Its key values are:

| Metric | Value | Current gate | Result |
| --- | ---: | ---: | --- |
| Physics median | `2.828 ms` | diagnostic | green |
| Physics p95 | `5.211 ms` | `6 ms` | green |
| Physics p99 | `11.593 ms` | `8 ms` | red |
| Frame p95 / p99 | `2.381 / 4.718 ms` | `18 / 25 ms` | green |
| Enemy/grid p99 | `3.432 ms` | attribution | largest named owner |
| Encounter/pursuit p99 | `2.867 ms` | attribution | second named owner |
| Scheduled ordinary p99 | `2.860 ms` | attribution | overlapping enemy work |
| Draw calls p95 | `95` | `200` | green |

## Assumptions

- Current `HEAD` includes the completed quota seal, active-run clock, final Result, virtual reserve,
  engagement flow, larger ordinary presentation, and the first image-based flat build rail.
- The user's category-slot correction changes build presentation, not card eligibility or a hidden
  equipment system.
- The current source tree and Git history are authoritative for behavior; ignored local logs are
  evidence only when their embedded provenance and workload are valid.
- There is no persistent mid-run build save that requires a category-slot migration.
- The current native and single-threaded Web release targets remain required.

## Scope and Boundaries

In scope:

- Provenance for synthetic performance JSON, manual traces, visual captures, Web builds, and the
  concise conclusions that future agents use.
- A tracked append-only evidence ledger plus selected decision-changing raw JSON.
- Six localized category groups in the build rail: Primary, Secondary, Element, Activated,
  Chassis, and Combat.
- Tail-correlated profiling of the existing shipping workload.
- Removal or staggering of measured repeated scans, pursuit rebuild work, schedule construction,
  and overlap snapshot work.
- A diagnostic exact-cap staircase after the 48-cap release gate is green.
- Native, locally built Web, GitHub Pages, and itch.io verification from one final commit.

Out of scope:

- New upgrade artwork; reuse the 28 approved `upgrade/<id>` raster assets.
- A new equipment, unequip, replacement, inventory, or save-data system.
- Changing card compatibility, maximum card level, upgrade offer rules, boss quotas, XP, enemy HP,
  enemy speed, contact damage, attacks, stage geometry, or authored packet order.
- Presentation-only enemies that appear attackable but have no hit, damage, status, reward, or
  collision truth.
- Raising the shipping exact cap during this plan. Higher tiers are capability evidence only.
- Changing the engine, adding a production dependency, enabling Web threads, or adding a
  GDExtension without a separate explicit user approval.
- Retaining CI artifacts longer than one day. Durable evidence belongs in Git, not paid Actions
  artifact storage.

Constraints and invariants:

- Godot `4.7.1` through `./tools/godot.ps1`; no project-local runtime.
- Manual aim, held primary fire, dash, seekers, EMP, exact earliest-hit behavior, fair contact,
  authored encounters, pickups, cards, five connected stages, and quota-gated bosses remain intact.
- Current materialized caps remain `1/40/48/48/48`; authored pressure remains
  `1/124/172/224/276` while implementation work is evaluated.
- Renderer, batching, and pooling are not selected as primary work unless new evidence contradicts
  the current green measurements.
- Existing semantic art is reorganized, not visually regenerated or modified.
- Korean and English remain complete at `960x540`, `1280x720`, `1920x1080`, and 200% text scale.
- Performance comparisons use the same scenario, seed, viewport, renderer, warmup, sample duration,
  process-isolation rules, and authority checks.

Destructive or irreversible actions:

- None. Old raw local evidence remains ignored and is not deleted by this plan.

Exact actions requiring owner or user approval:

- A Web-capable GDExtension, custom Web export templates, Web threads/COOP/COEP deployment, engine
  change, or a higher shipping enemy cap.

## Domain and Ownership Contract

| Term | Exact meaning | Canonical owner |
| --- | --- | --- |
| Evidence ID | Immutable ID linking one run or related artifact set to provenance, metrics, hashes, and a plan checkpoint. | New evidence recorder/ledger tooling |
| Authority-eligible | A run with the required environment, source cleanliness, workload, focus, viewport, warmup, and duration. It may still fail thresholds. | Performance recorder policy |
| Authoritative pass/fail | An authority-eligible run whose threshold result is explicitly pass or fail. | Performance recorder plus ledger |
| Diagnostic | A useful measurement that cannot pass or fail a release gate. | Ledger status, never inferred from filename |
| Category build slot | A presentation position inside one upgrade category. It mirrors simultaneous unique-card capacity but does not add an equipment action or limit. | Catalog contract and frozen build snapshot |
| Category occupancy | Unique acquired cards mapped into catalog-owned semantic positions inside that category; a level-up updates its existing position. | Catalog, `VehicleRunBuild`, and snapshot builder |
| Exact actor | One materialized enemy with authoritative health, position, collision, attacks, status, damage, reward, and quota behavior. | Enemy store and combat runtime |
| Virtual reserve | Authored ordinary identity and schedule data that has not materialized and cannot affect combat. | Encounter runtime |
| Capacity envelope | Diagnostic highest exact tier that meets unchanged correctness and timing gates. It is not a shipping balance decision. | Performance evidence |

Do not use `slot` alone when it is unclear whether it means a category build slot, an optional
secondary gameplay slot, an attribute slot, an active-weapon slot, or a pooled runtime slot.

## Locked Upgrade Slot Design

The build rail contains six sections in existing catalog order. Each section owns a fixed maximum
simultaneous unique-card capacity derived from current compatibility rules:

| Category | Localized key | Slot count | Why this is the maximum simultaneous occupancy |
| --- | --- | ---: | --- |
| Primary | `UPGRADE_CATEGORY_PRIMARY` | 2 | Both primary modification cards can coexist. |
| Secondary | `UPGRADE_CATEGORY_SECONDARY` | 5 | Built-in Homing Missiles, two optional secondary weapons, and two global secondary enhancements. |
| Element | `UPGRADE_CATEGORY_ELEMENT` | 2 | One damage attribute and one utility attribute. |
| Activated | `UPGRADE_CATEGORY_ACTIVATED` | 3 | One active weapon kind and two active enhancements. |
| Chassis | `UPGRADE_CATEGORY_CHASSIS` | 5 | All five chassis/support cards can coexist. |
| Combat | `UPGRADE_CATEGORY_COMBAT` | 4 | All four combat-system cards can coexist. |

There are 21 simultaneous presentation positions, not 28 catalog identity positions and not one
global progressive capacity. Positions are semantic rather than a loose per-category queue:

- Primary owns fixed `split_muzzle` and `piercing_rounds` positions.
- Secondary owns fixed `homing_missiles`, `secondary_coolant`, and `secondary_amplifier` positions
  plus generic `optional_0` and `optional_1` positions for the two legal optional weapon roots.
- Element owns `damage` and `utility`, using the existing `attribute_slot_kind` contract.
- Activated owns `kind`, `active_coolant`, and `active_amplifier`, using the existing
  `active_slot_kind` contract.
- Chassis and Combat own fixed catalog-order card positions.

Leveling a card updates the same position. A new acquisition in another category never shifts an
existing image. Empty positions are outlined and not focusable. Filled positions use the existing
semantic image, level marker, keyboard/controller focus, hover/pin behavior, and one shared popover.

The rail uses category heading plus a maximum four-column slot grid. Five-slot categories wrap the
fifth position to a second row. The build rail remains vertically scrollable; it never makes the
three offer rows or mandatory action area scroll. Compact mode uses the existing compact cell size,
and the Result reuses the same rail component and frozen snapshot.

`VehicleRunBuild.acquisition_order` remains only to keep the two generic optional-secondary
positions stable when the second optional weapon is acquired. It does not decide category order,
fixed semantic positions, the flat summary order, or gameplay eligibility, and it is not an
equipment limit. A later save-data contract may replace it with explicit optional-slot assignment;
this run has no persistent mid-run save that requires migration.

The existing localization keys remain, but their values align with the canonical catalog wording:
`UPGRADE_CATEGORY_ELEMENT` becomes Korean `공격 속성` / English `Attack Attributes`, and
`UPGRADE_CATEGORY_COMBAT` becomes Korean `전투 조건` / English `Combat Conditions`.

## Why Survivor-like Games Are Not a Contradiction

The comparison supports the following mechanisms, not claims about undisclosed internals of a
specific game:

1. **Rendering and simulation are separate costs.** Godot documents MultiMesh as a way to draw huge
   instance counts efficiently, but Cardborne rendering is already green. More batching does not
   remove enemy decisions, collision, LOS, or encounter work.
2. **Crowd systems change fidelity by relevance.** Epic's Mass system separates representation LOD
   and simulation LOD, with configurable distance and count limits. Network engines similarly use
   relevancy and lower update frequency for less important actors.
3. **Large systems choose a coarser model away from the important boundary.** SUMO's mesoscopic
   traffic mode uses queues and reports substantially faster execution than microscopic per-vehicle
   dynamics. Cardborne's virtual reserve is the analogous safe boundary: authored pressure remains,
   but only combat-relevant arrivals become exact.
4. **Data layout matters after the product boundary is correct.** Unity and Unreal document
   data-oriented, chunk/archetype processing. Cardborne's earlier broad typed-GDScript migration
   regressed because it retained compatibility mirroring and maintenance work. A future hot-core
   migration must replace one truth owner, not create a second copy of the same world.
5. **Successful survivor games also hit this problem.** poncle reported that Vampire Survivors'
   earlier physics was limited by one CPU core and later moved to a new engine; the official post
   reported a large benchmark improvement. Deep Rock Galactic: Survivor publicly described an ECS
   rebuild for longer runs and Steam Deck performance, then set it aside because the engineering
   cost threatened its schedule. There is no honest basis for assuming that any engine makes rich
   exact actors free.

Primary references:

- [Godot general optimization](https://docs.godotengine.org/en/stable/tutorials/performance/general_optimization.html)
- [Godot MultiMesh optimization](https://docs.godotengine.org/en/latest/tutorials/performance/using_multimesh.html)
- [Godot low-level Servers](https://docs.godotengine.org/en/stable/tutorials/performance/using_servers.html)
- [Epic Mass Gameplay and simulation LOD](https://dev.epicgames.com/documentation/unreal-engine/overview-of-mass-gameplay-in-unreal-engine?lang=en-US)
- [Unity chunk iteration](https://docs.unity.cn/Packages/com.unity.entities%401.0/manual/iterating-data-ijobchunk.html)
- [Unreal actor relevancy](https://dev.epicgames.com/documentation/en-us/unreal-engine/actor-relevancy-in-unreal-engine)
- [SUMO microscopic and mesoscopic models](https://sumo.dlr.de/docs/Theory/Traffic_Simulations.html)
- [SUMO mesoscopic runtime model](https://sumo.dlr.de/docs/Simulation/Meso.html)
- [Reynolds, local flocking behavior](https://www.red3d.com/cwr/papers/1987/boids.html)
- [poncle development roadmap](https://store.steampowered.com/news/posts/?enddate=1648165599&feed=steam_community_announcements)
- [Deep Rock Galactic: Survivor, Endless Mode Postponed](https://store.steampowered.com/news/posts/?enddate=1742819828&feed=steam_community_announcements)
- [Godot Web export constraints](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_web.html)

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Are all logs commit/version linked and durable? | No. Raw `build/**` is ignored; 163 local performance JSON files include 105 full commits, one short commit, and 57 missing commits. Capture manifests omit commit data. CI evidence expires after one day. | `.gitignore`, recorder/manual wrapper, capture driver, CI workflow, local census | Auto-create common provenance, track a ledger and selected decision-changing raw JSON, keep noisy/local artifacts ignored. | 1.1-1.4 |
| Can a future agent compare evidence? | Selected metrics are manually pinned in plans, but there is no central machine-readable index or artifact hash. | Current plans and evidence docs | Plans reference evidence IDs; comparison tooling rejects incomplete provenance. | 1.2-1.4 |
| What does category slot mean? | The catalog owns six categories and real compatibility subslots; current UI flattens acquisition order into a global grid. | Catalog, RunBuild, snapshot builder, build rail | Six grouped capacities `2/5/2/3/5/4` with semantic positions; no equipment action or rule change. | 2.1-2.4 |
| Is rendering the current crowd bottleneck? | No. Latest draw/frame/render values pass while physics p99 fails. | `4f7f7acd` production replay and dense-enemy evidence | Do not prioritize MultiMesh, art reduction, or renderer replacement. | 3.1, 4.1-4.3 |
| Why does p99 fail at only 43 actors? | Several rich exact-simulation jobs coincide; current detailed timing samples every seventh physics tick and is not inherently correlated with the slowest ticks. | `VehicleRun`, recorder JSON | Add low-overhead every-tick coarse attribution and a bounded top-32 slow-tick receipt before choosing more code. | 3.1-3.3 |
| Which current owners deserve first inspection? | Enemy/grid, encounter/pursuit, and scheduled ordinary are the three largest named p99 owners. Schedule, pressure, and overlap code still include repeated or capacity-wide work. | Current source and JSON | Correct one measured owner at a time; keep exact narrow phase and deterministic behavior. | 4.1-4.4 |
| Should all 320 authored units become exact again? | The previous dual-state typed-GDScript migration was slower; current virtual reserve fixed catastrophic density but p99 remains red. | Dense architecture option study and implementation history | First make 48 exact stable. Then measure 64/96/128 without shipping them. Native code is an approval-only escalation. | 5.1-5.3 |
| Do native fixes automatically fix GitHub Pages and itch.io? | Source fixes export to both, but Web is single-threaded WebAssembly/Compatibility and must be measured separately. | Export preset, workflow, Godot Web docs | Same-commit local built-Web and deployed verification are mandatory. | 6.1-6.4 |

Readiness statement:

- Product behavior, category capacity, evidence retention, hot-owner selection, escalation, and
  validation decisions are closed.
- The existing Godot runtime, PowerShell, Git, capture/export tooling, and current assets are enough
  for Phases 1-6. No new dependency is authorized.
- The only conditional implementation branch is evidence-driven owner selection in Phase 4; its
  allowed responses and rejection rules are fixed below.

## Tasks

### Phase 1: Durable commit-linked evidence

Goal: ensure every decision-changing result can be found, verified, and compared without relying on
a filename or one agent's memory.

Preconditions:

- Current raw artifacts remain untouched under ignored `build/`.
- Existing Actions artifact retention remains one day.

Source owners: `scripts/performance/vehicle_performance_recorder.gd`,
`scripts/performance/vehicle_manual_performance_trace.gd`,
`scripts/vehicle/vehicle_run_capture_driver.gd`, `tools/run_manual_performance_trace.ps1`, new
`tools/performance/`, new `docs/performance/evidence/`, new
`docs/performance/vehicle-performance-evidence.jsonl`

- [ ] **1.1 Define and validate one provenance envelope.**
  - Change: add an evidence ID and common fields for full commit, source cleanliness including
    untracked source files, branch/ref, UTC start/end, command, artifact kind, schema/tool version,
    scenario, seed/fingerprint, warmup/sample duration, OS/Godot/GPU/renderer, logical/window
    viewport, focus/visibility/headless state, Web user agent/build hash when applicable, and
    process-isolation preflight. Record `scenario_valid`, `authority_eligible`,
    `thresholds_passed`, and final status separately.
  - Accept: a validator rejects a missing/short commit, unknown cleanliness, absent workload,
    unsupported viewport, missing authority data, or a status inferred only from a filename.
  - Guard: generated output under ignored `build/` does not itself make source cleanliness dirty.
- [ ] **1.2 Add the tracked append-only ledger.**
  - Change: add one JSON Lines entry per retained evidence set. Store metrics, raw artifact paths,
    SHA-256, byte size, plan checkpoint, and supersedes relation. Plans cite evidence IDs.
  - Accept: tooling can select comparable records by scenario and reject different seeds,
    workloads, viewports, renderer modes, or authority classes.
- [ ] **1.3 Promote only evidence that changes a decision.**
  - Change: copy authoritative pass/fail JSON and any diagnostic explicitly cited by a durable plan
    into `docs/performance/evidence/<evidence-id>.json`; keep routine logs, screenshots, invalid
    experiments, and repeated raw output ignored. The ledger hashes both tracked and local raw data.
  - Accept: the latest `4f7f7acd` red result is imported with its original hash and an explicit
    `authoritative_fail` status; its retained file remains readable without Actions artifacts.
  - Guard: no bulk import of all 163 historical files and no CI retention increase.
- [ ] **1.4 Make all producers use the envelope.**
  - Change: synthetic recorder, manual wrapper, capture manifest, Web build info, and evidence
    promotion command share one evidence ID. Remove optional environment-only commit provenance;
    the wrapper resolves it and the recorder refuses release authority when it is missing.
  - Accept: a synthetic run, manual diagnostic, capture, and Web build each pass focused provenance
    validators and emit linked metadata.

Batch gate:

- Ledger parser, provenance validators, `git diff --check`, and a round-trip test from a temporary
  raw artifact to a ledger entry pass. No authoritative timing run occurs in this phase.

### Phase 2: Six category-owned upgrade slot groups

Goal: make Upgrade and Result show what kind of build the player owns, not merely when cards were
picked.

Preconditions:

- Phase 1 source changes are committed or otherwise isolated from UI timing work.
- The visual authority pair remains unchanged and the 28 current raster assets are reused.

Source owners: `scripts/cards/vehicle_upgrade_catalog.gd`, `scripts/cards/vehicle_run_build.gd`,
`scripts/cards/vehicle_build_snapshot_builder.gd`, `scripts/ui/vehicle_upgrade_build_rail.gd`,
`scripts/ui/vehicle_upgrade_build_cell.gd`, Upgrade/Result consumers, localization, product/visual
specs, and focused upgrade/capture validators

- [ ] **2.1 Put capacity truth beside compatibility truth.**
  - Change: publish catalog-order category descriptors and simultaneous capacities
    `2/5/2/3/5/4`, including the exact semantic position keys defined above. Validate them against
    the 28-card roster and optional-secondary, attribute, and active-kind compatibility rules.
  - Accept: no UI file counts cards or infers compatibility from localized category text.
- [ ] **2.2 Freeze grouped build records.**
  - Change: snapshot builder emits ordered category records with category ID/key, capacity, and
    fixed slot entries `{slot_key, record}`. Optional-secondary acquisition order assigns only
    `optional_0/1`; every other record maps by catalog ID or existing slot-kind metadata. Preserve a
    deterministic flat `upgrades` projection in category/slot order for the current Ship Status
    summary; it is not a rail-layout source.
  - Accept: every unique card appears once, fixed positions never move, optional positions remain
    stable, a level-up updates in place, and occupancy never exceeds capacity.
- [ ] **2.3 Render grouped sections in the shared rail.**
  - Change: replace the global progressive capacity with six labeled grids. Use at most four
    columns per group; five-slot groups wrap. Keep filled-only focus, one popover, scroll containment,
    and existing compact/large sizing.
  - Accept: zero upgrades shows all 21 empty categorized positions; a mixed fixture fills the exact
    category positions with existing artwork; no image or popover is clipped at supported sizes.
- [ ] **2.4 Reuse and localize the corrected rail everywhere.**
  - Change: Upgrade and Result use the same grouped snapshot/rail. Update Korean/English strings only
    if shorter category headings are required; update `DESIGN.md`, `VISUAL_SYSTEM.md`, product and
    upgrade specs to retire the global progressive-grid contract.
  - Accept: keyboard/controller traversal never lands on an empty slot, locale switching refreshes
    headings and popover content, and choice selection remains the only mandatory action owner.

Batch gate:

- Focused upgrade-system, build-snapshot, upgrade-UI, result-builder, result-UI, localization,
  accessibility, capture, headless import, and visual-authority checks pass.
- Rendered Korean/English evidence covers empty, mixed, full-capacity-category, Result, compact, and
  200% text states. Inspect alignment, padding, scroll containment, focus, clipping, and popover
  placement.

### Phase 3: Tail-correlated performance evidence

Goal: identify what actually happens on the slowest physics ticks instead of optimizing the largest
average bucket.

Preconditions:

- Phase 1 provenance is available.
- Phase 2 is complete and broad UI/capture work is quiet.

Source owners: `scripts/vehicle/vehicle_run.gd`, performance recorder/manual trace, scenario,
engagement telemetry, and their validators

- [ ] **3.1 Add bounded slow-tick receipts.**
  - Change: while a recorder/manual trace is active, measure the five coarse physics sections on
    every tick. Retain only the top 32 ticks in fixed preallocated columns. Each receipt includes
    physics serial, total and coarse section times, exact/visible counts, due/critical counts,
    decision/motion phase, pursuit rebuild state and processed cells, overlap owners/candidates,
    spawn/cue counts, and projectile/effect counts.
  - Accept: no per-tick Dictionary/Array allocation is added to shipping play; output Dictionaries
    are created only when the report is finalized.
- [ ] **3.2 Keep deep attribution opt-in and reproducible.**
  - Change: retain current low-rate detailed timers for the first run. Add a named deep mode that
    times only the selected coarse owner on every tick in a same-seed rerun.
  - Accept: a receipt identifies whether current p99 aligns with pursuit rebuild, pressure scan,
    schedule/due phase, overlap snapshot/query, spawn materialization, or a non-enemy section.
  - Guard: no profiler mode may change actor cadence, spawn order, collision, or decisions.
- [ ] **3.3 Record a clean baseline under the new schema.**
  - Change: one 10-second warmup plus 30-second diagnostic `production_replay` at `1280x720`, native
    Compatibility, current cap 48. Promote it through Phase 1 tooling.
  - Accept: workload and authority fields are valid, top-tick receipts are present, and the selected
    Phase 4 owner is written into this plan before code changes.

Batch gate:

- Performance-recorder and manual-trace validators pass; instrumentation-off normal play has zero
  receipt work; instrumentation-on fixture counts remain identical.

### Phase 4: Remove measured repeated work

Goal: bring the current exact-48 production replay below the existing p99 limit without changing
gameplay.

Preconditions:

- Phase 3 identifies the selected owner and alignment trigger.
- Only one candidate owner changes between comparable measurements.

Source owners: the selected subset of encounter runtime, pursuit field, enemy update schedule,
spatial grid, enemy store, and `VehicleRun` orchestration

- [ ] **4.1 Remove non-gameplay pressure scans from the 60 Hz path.**
  - Change: when Phase 3 selects pressure work, update pressure sectors/near/visible telemetry only
    while consumed and at the declared telemetry cadence. Reuse existing buffers and schedule it
    away from pursuit rebuild start. Admission counts and threat commitment remain authoritative
    through their gameplay owners. Otherwise record `not selected` and skip the source change.
  - Accept: normal play performs no diagnostic pressure scan; recorded pressure retains its schema
    and sample cadence; encounter order and production qualification counts are identical.
- [ ] **4.2 Make pursuit rebuild cost explicit and phase-bounded.**
  - Change: when Phase 3 selects pursuit work, preserve exact walkability and the 0.20-second refresh
    contract, but give each rebuild a hard per-tick time/work budget and a stable phase that does not
    coincide with telemetry or the largest ordinary-decision group. Never discard a pending player
    target. Otherwise record `not selected` and skip the source change.
  - Accept: reachability/direction oracles pass and the top-32 receipts contain no pursuit burst
    above its selected budget.
- [ ] **4.3 Snapshot only live local-overlap members.**
  - Change: when Phase 3 selects overlap snapshot work, spatial grid maintains a compact active-slot
    list on membership changes and snapshots only those slots. Rebuild only marked owner rows. Keep
    exact distance/body predicates, stable tie order, maximum eight neighbors, and stale-generation
    rejection. Otherwise record `not selected` and skip the source change.
  - Accept: the 320-slot capacity buffers remain fixed, but snapshot work scales with live members;
    grid and steering parity fixtures pass.
- [ ] **4.4 Change schedule construction only if receipts still select it.**
  - Change: if scheduled ordinary or schedule rebuild remains the largest selected p99 owner after
    4.1-4.3, replace 60 Hz full-list reconstruction with persistent membership plus due stamps for
    the existing 60/30/20/10 Hz lanes. One owner must be canonical; do not mirror a second complete
    mutable enemy state. If it is no longer selected, record the evidence and skip this task.
  - Accept: membership changes update lanes once, due order and accumulated delta match the oracle,
    attack commitments and deterministic replay match, and no per-tick sort/Dictionary rebuild is
    introduced.

Candidate measurement gate:

- Use one same-environment 30-second diagnostic before and after each selected owner change.
- Retain a candidate only when its named-owner p99 improves at least 15%, overall physics p99 does
  not worsen by more than `0.25 ms`, fixture counts match, and no other coarse owner absorbs the
  removed cost. Otherwise revert only that task-owned candidate before the next hypothesis.
- After all retained corrections, run one clean 10-second warmup plus 60-second authoritative native
  `production_replay`. Phase 4 passes only at physics p95 at most `6 ms` and p99 at most `8 ms`.

### Phase 5: Measure scalable exact-enemy headroom

Goal: answer how many rich Cardborne enemies the corrected portable runtime can truly support,
without changing the shipping balance.

Preconditions:

- The cap-48 authoritative gate passes.
- No design, capture, export, browser, or unrelated Godot process contaminates timing.

Source owners: performance scenario overrides and evidence ledger only; production stage caps remain
unchanged

- [ ] **5.1 Add non-shipping exact-cap overrides.**
  - Change: performance scenario can request 48, 64, 96, or 128 exact ordinary actors while keeping
    the same role mix, deterministic seed, combat truth, viewport, and timing gates. The override is
    unreachable from normal play and excluded from saved product data.
  - Accept: each result labels exact count, authored reserve, workload fingerprint, and
    `diagnostic_only` status; scenario validation rejects a missed target count.
- [ ] **5.2 Run the capacity staircase with an early stop.**
  - Change: run 30-second diagnostics in ascending order. Stop at the first tier whose p95 exceeds
    `6 ms`, p99 exceeds `8 ms`, or correctness/count validation fails. Do not run higher tiers.
  - Accept: ledger records the last passing and first failing tier with comparable provenance.
- [ ] **5.3 Make the next architecture decision from the envelope.**
  - Change: if 96 or 128 passes, document the technical headroom and leave shipping cap 48 pending a
    separate gameplay/balance decision. If 64 fails, prepare a narrow approval request for a
    single-truth packed native kernel; do not implement it in this plan.
  - Accept: the conclusion distinguishes technical capacity, visible pressure, authored reserve,
    and shipping difficulty.

Batch gate:

- The staircase cannot modify product resources or export presets. `git diff` after the run contains
  only ledger/evidence additions.

### Phase 6: Same-commit native and Web release proof

Goal: prove the corrected source behaves in the local editor/runtime and in both deployed Web copies.

Preconditions:

- Phases 1-5 pass or Phase 5 stops normally after recording the capacity boundary.
- All source, UI, documentation, and evidence changes are committed; worktree source is clean.

Source owners: focused validators, capture driver, `tools/export_web.ps1`, export preset, GitHub
workflow, evidence ledger, deployment build info

- [ ] **6.1 Run the final focused and integration batches.**
  - Change: run affected performance, encounter, pursuit, schedule, spatial, combat, upgrade, result,
    localization, accessibility, capture, and document-authority validators; then headless import and
    diff checks.
  - Accept: all pass with no parser error or new warning attributable to this work.
- [ ] **6.2 Run final native authority once.**
  - Change: on the final clean commit, run the 10-second warmup plus 60-second cap-48
    `production_replay`; promote raw JSON and ledger entry.
  - Accept: scenario/authority/count checks pass; physics p95/p99 pass `6/8 ms`; frame, render,
    memory, draw-call, and batch gates pass.
- [ ] **6.3 Export and test the built Web game.**
  - Change: run the Web export, production-style local host, and one focused/visible 10-second
    warmup plus 60-second `production_replay` at `1280x720`. Read the published Web result, and
    record browser user agent, headless state, Web build/PCK hash, focus, scheduler throttling, and
    exact commit.
  - Accept: the built-Web result is authority-eligible, scenario/count-valid, and
    `thresholds.passed == true`; controls and UI smoke pass with no console/runtime error. A headless,
    hidden, throttled, or incomplete run is diagnostic only and cannot satisfy this task.
- [ ] **6.4 Verify GitHub Pages and itch.io from the same build.**
  - Change: deploy only after 6.1-6.3 pass. Verify both public surfaces report the same commit/build
    hash and complete a short manual combat smoke including Upgrade category slots and Result.
  - Accept: neither deployment uses stale assets/code; observed behavior matches the local built
    Web artifact; evidence IDs and URLs are recorded without increasing artifact retention.

Final gate:

- Run the diff-scoped codebase-quality audit. Correct only small task-owned ownership, unreachable
  failure, competing-owner, or contract gaps.
- Update durable product/visual/performance specs and the evidence ledger. Mark this plan `done` only
  when final source commit, evidence IDs, native result, built-Web result, and both deployment hashes
  are recorded.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | One changed-owner validator plus `git diff --check` | After a coherent local change | Its relevant source changes |
| UI phase | Upgrade/build/result/localization/accessibility validators and selected rendered states | Phase 2 tasks pass | UI/snapshot/theme/localization input changes |
| Performance diagnostic | One 30-second same-scenario comparison | A measured candidate is ready | The selected owner or hypothesis changes |
| Native authority | 10-second warmup + 60-second cap-48 production replay | Final source is clean and quiet | A runtime/resource/export input changes |
| Capacity staircase | Ascending 48/64/96/128 diagnostics with early stop | Native cap-48 authority passes | Runtime or scenario input changes |
| Web final | Export, local built-Web trace, then deployed smoke | Native and source gates pass | Web/runtime/resource input changes |

Validation rules:

- Track implementation correctness and timing qualification separately.
- A valid workload can still be an authoritative failure; `authority_eligible` is not `passed`.
- Do not compare records with different workload, seed, viewport, renderer, duration, focus, or
  environment status.
- Do not rerun an expensive check after a failure until code or a named hypothesis changes.
- Do not claim Web success from native evidence, or native success from a headless Web smoke.
- Stop a timing run if unrelated heavy work, focus loss, scheduler throttling, or source dirtiness
  invalidates authority.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A retained raw artifact lacks a full commit or required workload fields | Import it as `diagnostic` or `invalid`, never authoritative | Do not repair provenance by trusting the filename |
| Category occupancy exceeds the proposed capacity | Stop Phase 2 and correct the catalog-derived capacity | Do not silently hide an acquired card or add scrolling inside one category |
| Five-slot category cannot fit at a supported width | Wrap after four positions and use the existing rail scroll | Do not shrink artwork below current compact size or move offer actions into scroll |
| Renderer becomes a measured failing owner | Record the contradiction and replan that owner | Do not preemptively replace the renderer or assets |
| 4.1-4.3 make schedule no longer material | Skip 4.4 and record why | Do not implement a persistent scheduler without selection evidence |
| A candidate improves its bucket but worsens total p99 | Reject/revert the candidate and inspect transferred work | Do not keep local-looking wins |
| Cap 48 remains above p99 8 ms after Phase 4 | Stop before Web release and request approval for a narrow Web-capable native-kernel spike | Do not add threads, GDExtension, or custom templates automatically |
| 64 fails in Phase 5 | Record 48 as the portable envelope and stop the staircase | Do not lower correctness or timing gates |
| 96/128 passes | Record technical headroom only | Shipping cap/difficulty requires a separate product decision |
| Built Web is materially slower or invalid while native passes | Keep release blocked and isolate Web-only environment/runtime cost | Do not publish a native-only performance claim |
| A verified material fact contradicts this contract | Stop the affected branch, update the plan, and obtain required approval | Executor cannot choose a new product/architecture/dependency contract |

## Risks

- The current seventh-tick detail sampling may have misranked the actual p99 trigger. Phase 3 is
  deliberately before structural work.
- Profiling itself can add cost. Coarse timing is bounded and enabled only for evidence runs; its
  overhead must be reported.
- Persistent structures can cost more than rebuilding at only 48 actors. Phase 4 retains them only
  if the measured candidate gate passes.
- A category capacity expresses maximum simultaneous unique cards, not the number of catalog cards.
  Documentation and accessibility names must make this distinction clear.
- Web single-thread performance can differ from native even when the same GDScript is exported.
  Both public deployments therefore need same-build verification.
- Selected raw JSON in Git grows repository history. Promotion is limited to authority results and
  decision-changing diagnostics; routine output remains local.

## Rollback and Safety

- Implement each phase in a coherent scoped commit. Never stage, revert, clean, or overwrite
  unrelated work.
- Provenance and category-snapshot additions land before their consumers. Until migration is
  complete, the current flat snapshot remains a derived compatibility view.
- Preserve all ignored historical raw evidence. Evidence promotion copies selected files and never
  moves or deletes the originals.
- Reject and revert only a task-owned performance candidate that fails its comparison gate; never
  reset the whole worktree or weaken the benchmark.
- Keep production caps and export settings unchanged throughout candidate work. Diagnostic capacity
  overrides remain unreachable from normal play.
- Do not deploy until the final native and local built-Web gates pass. A failed public smoke rolls
  forward with a corrected build or uses the repository's existing recoverable deployment path; it
  never force-pushes or rewrites release history.

## Decision Notes

- 2026-08-13: raw performance/capture output is not currently a durable versioned record. The
  latest important results are manually summarized in plans, which is useful but insufficient.
- 2026-08-13: keep one-day Actions artifact retention. Durable small evidence moves into Git; CI
  storage is not used as a long-term archive.
- 2026-08-13: replace the flat 4-column progressive grid with six category sections and 21 maximum
  simultaneous positions. This corrects presentation only.
- 2026-08-13: semantic category positions replace general acquisition ordering. Retain acquisition
  order only for stable assignment of the two generic optional-secondary positions.
- 2026-08-13: keep the current virtual reserve and cap 48 while fixing p99. It solved the catastrophic
  exact-320 overload but did not meet the final tail gate.
- 2026-08-13: rendering, generic pooling, and a generic "add a spatial grid" answer are rejected as
  first work because those facilities already exist and the measured render path passes.
- 2026-08-13: do not repeat the broad dual-state typed-GDScript migration. Any future packed/native
  core must replace one canonical owner and requires approval if it changes deployment shape.
- 2026-08-13: higher exact capacity is measured only after cap 48 passes, and does not automatically
  ship.

## Open Questions

No material implementation question remains open. A future user decision is required only if Phase
4 proves that a native kernel is necessary or if Phase 5 proves enough headroom to consider raising
the shipping exact cap.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 1, durable commit-linked evidence.
- Next task: 1.1, define and validate the provenance envelope.
- Last completed gate: Discovery Closure Gate.
- Update rule: after a checkpoint passes, record its concise evidence, check the task, and advance
  this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every required task acceptance check and final gate passes.
- Category slots are correct on Upgrade and Result in both locales and supported layouts.
- The final cap-48 native p95/p99 are at most `6/8 ms` and built Web is valid.
- The evidence ledger can reconstruct the final claim from full commit and artifact hashes.
- The capacity envelope is recorded without silently changing shipping balance.
- Durable product, visual, and performance decisions are incorporated into their owning specs.

Replan when:

- New tail receipts contradict the selected owner set.
- Category compatibility changes the maximum simultaneous capacities.
- A native extension, Web threading, custom template, or higher shipping cap becomes necessary.

Do not replan or stop for:

- Local implementation mechanics inside the locked category/evidence/runtime boundaries.
- A rejected measured candidate; revert it and continue with the next selected hypothesis.
- A normal Phase 5 early stop after the first failing capacity tier.
