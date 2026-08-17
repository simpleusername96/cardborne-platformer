---
type: plan
status: active
owner: BK
created: 2026-08-16
last_reviewed: 2026-08-17
scope: Incremental combat pacing, upgrade cadence, HUD readability, and tactical guidance improvements within the current Cardborne run
related:
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../design/DESIGN.md
  - ../../docs/reports/2026-08-16-fast-shooter-combat-and-guidance-en.html
---

# Incremental Fast-Shooter Improvements — Execution Contract

Cardborne keeps its current run structure and combat identity. This contract applies the
user's feedback through small, separately testable changes to existing systems. It keeps
quota progression while increasing every boss-entry ordinary-defeat quota to `1.5x`; it
does not rebuild encounters as authored beats, move upgrades to a new service loop, or
redesign the campaign.

## Purpose

- Objective: make the current run longer, more demanding, less interruption-heavy, and
  easier for a first-time player to read without changing its overall structure.
- Deliverable: three sequential phases covering auxiliary-AI guidance, upgrade cadence,
  and a quota increase plus one spawn-pressure adjustment.
- Completion state: each slice passes its own acceptance checks before the next slice is
  implemented; the final native and built-Web checks pass.

## Scope and Boundaries

In scope:

- Keep the existing top HUD unchanged and present boss and facility guidance immediately
  below the minimap through the existing announcement pipeline with a fixed auxiliary-AI
  identity and concise Korean/English text.
- Reduce early upgrade interruptions by tuning the existing XP requirement curve.
- Increase every cycle's ordinary-defeat requirement before boss entry to exactly `1.5x`
  its current value.
- Make one small change to existing spawn weighting.

Out of scope:

- New combat beats, a new campaign or stage model, replacement of quota-gated bosses,
  service breaks, upgrade charges, a new two-choice modal, new maps, new enemies, new
  bosses, new facilities, a new failure-analysis system, or a new guidebook architecture.
- Changes to player speed, dash, manual aim, held primary fire, weapons, cards, boss order,
  one-field continuity, active-actor caps, or production dependencies.
- Fixed-Hard multipliers, projectile speed, enemy recovery, HP, damage, and a promised
  duration target. Any later numeric balance change beyond the exact quota and XP changes
  in this contract requires a separate, evidence-backed product-spec decision.
- A promised final run length. Duration remains measured telemetry, not a timer.

Constraints and invariants:

- Preserve the current eight-cycle quota flow and every existing reachable surface. Scale
  the current quota sequence `40/44/48/52/56/60/64/68` to the exact integer sequence
  `60/66/72/78/84/90/96/102`; do not apply runtime difficulty scaling or rounding.
- Preserve the current spawn allocator, encounter director, upgrade modal, announcement
  queue, localization pipeline, Theme, component factory, and performance caps.
- Tune one concern at a time. Implement and record the quota increase separately from the
  spawn-sector change so duration and difficulty evidence can identify each input.
- Korean remains the default and Korean/English coverage must remain complete.
- UI work uses existing shared components. The current visual contract still limits the
  top-right zone to the minimap and requires a text-only top-center announcement, so
  Phase 1 must amend only those exact clauses before the auxiliary-AI surface is moved
  below the minimap. This plan does not override the active visual specification by itself.

Destructive or irreversible actions:

- None.

Exact actions requiring user approval:

- Any change outside the boundaries above, including campaign restructuring, new content,
  cap increases, dependencies, or player-control changes.
- Phase 1's narrow announcement contract amendment is grounded in the user's current
  instruction to leave the top HUD alone and place auxiliary-AI messages below the minimap.
  Any broader visual-contract amendment requires a new explicit decision.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked incremental decision | Task IDs |
| --- | --- | --- | --- | --- |
| Run ends near ten minutes | `VehicleStageFlow` gates each boss on the quota owned by `VehicleCombatStages.QUOTAS`; the current product and runtime sequence is `40/44/48/52/56/60/64/68`, and no timer ends the run. | `scripts/encounters/vehicle_stage_flow.gd`, `scripts/vehicle/stages/vehicle_combat_stages.gd`, `docs/product/vehicle_game_spec.md`, prior session diagnostics | Preserve the gate and multiply each current value by exactly `1.5`, producing `60/66/72/78/84/90/96/102`. Keep authored populations and simultaneous-pressure caps unchanged. | 3.1, 4.1 |
| Fast movement can leave enemies trailing | The allocator already distributes arrivals by sector and considers player velocity. | `scripts/encounters/vehicle_spawn_allocator.gd` | Keep the allocator. Adjust only its existing sector/role scoring so the first pass reduces rear pursuit modestly; do not add a new encounter scheduler. | 3.2 |
| Difficulty became too easy | Ordinary pressure is owned by shared projectile-speed, recovery, threat-budget, stage commit limits, and spawn placement. | `scripts/encounters/vehicle_encounter_director.gd`, `scripts/encounters/vehicle_spawn_allocator.gd` | Keep fixed-Hard numeric values unchanged in this contract. Test whether the one spawn-direction adjustment improves relevant pressure, then report any remaining balance gap. | 3.2, 4.1 |
| Upgrades interrupt play too often | XP requirements are computed in `VehicleExperienceRuntime`; pending levels and the existing modal already have stable owners. | `scripts/progression/vehicle_experience_runtime.gd`, `scripts/vehicle/vehicle_run.gd` | Keep the modal and reward flow. Change only `EARLY_REQUIREMENT_SURCHARGE` from `4` to `8` for the existing first ten requirement calculations. | 2.1 |
| Existing messages do not teach mechanics | The gameplay HUD already owns a localized, prioritized announcement queue and emits diagnostics. The active visual contract currently allows only four event families and a text-only top-center presentation. | `scripts/ui/vehicle_gameplay_hud.gd`, `scripts/ui/vehicle_stage_ui.gd`, `scripts/vehicle/vehicle_run.gd`, `docs/design/VISUAL_SYSTEM.md` | Keep the top HUD row unchanged. Amend only the top-right and announcement clauses, dock the existing queue below the minimap, and add a fixed `CONTROL` label with verified boss/facility state messages. Preserve queue capacity and priority behavior. | 1.0, 1.1, 1.2 |

Readiness statement:

- Product scope is locked to incremental changes in existing owners.
- The only numeric progression changes are the locked XP curve change and the exact quota
  sequence `60/66/72/78/84/90/96/102`. No implementation task selects a new campaign,
  encounter, progression, balance, or UI architecture.
- Required tooling and validators already exist in the repository.

## Tasks

### Phase 1: Make current information readable

Goal: add the requested assistant-style guidance below the minimap without changing the
existing top HUD row or gameplay state.

Preconditions:

- Load `$uiux-gate`, `.agents/design/DESIGN.md`, and `$cardborne-visual-authority` before
  implementation because this phase changes player-facing UI.

Source owners: `scripts/ui/vehicle_gameplay_hud.gd`, `scripts/ui/vehicle_stage_ui.gd`,
`scripts/vehicle/vehicle_run.gd`, `docs/design/VISUAL_SYSTEM.md`, existing localization
catalogs, focused HUD validators.

- [x] **1.0 Reconcile the two narrow visual-contract clauses**
  - Change: update only the top-right and normal-announcement clauses in
    `docs/design/VISUAL_SYSTEM.md`. Keep the panel-free top HUD row unchanged; permit one
    restrained shared-Theme auxiliary-AI Surface immediately below the minimap with a
    fixed `CONTROL` sender label and verified boss and neutral-facility state events.
    Preserve minimap ownership, queue behavior, semantic colors, and the ban on
    screen-specific chrome.
  - Accept: the revised clauses are compatible with the product spec, design map, runtime
    owners, Korean/English requirement, and visual-authority validator.
  - Guard: do not revise modal layouts, world visuals, gameplay rules, or unrelated visual
    contracts.
  - Evidence: `docs/design/VISUAL_SYSTEM.md` now preserves the top HUD row and permits one
    shared-Theme auxiliary-AI Surface below the minimap; the visual-authority validator
    passed with the canonical `1448×1086` sheet and required SHA-256.

- [x] **1.1 Dock the existing announcement queue below the minimap**
  - Change: replace the top-center text-only presentation with one compact right-aligned
    shared Surface directly below the minimap. Keep the existing queue, priority,
    coalescing, capacity, timing, and public notification API unchanged.
  - Accept: Korean and English messages fit without clipping or overlap at 960×540,
    1280×720, and 1920×1080 at 100% and 200% text scale; the existing top HUD row is
    unchanged and the panel never covers the reticle.
  - Guard: minimap, threat radar, aiming area, focus behavior, and gameplay snapshot keys
    remain unchanged.
  - Evidence: `VehicleGameplayHud` now renders the unchanged bounded queue in a
    right-aligned shared `HudSurface` below the minimap. The stage-UI layout validator
    passed at the supported viewport and 200% text-scale matrix.
- [x] **1.2 Add `CONTROL` to the current announcement surface**
  - Change: add a fixed `CONTROL` sender label to the existing panel.
    Add concise observation/action copy for boss arrival or phase truth and neutral-facility
    activation, expiry warning, and shutdown. Publish messages only from verified runtime
    events; do not infer state from display text.
  - Accept: the current queue still prioritizes and coalesces messages; all new reachable
    keys exist in Korean and English; the panel does not cover the reticle at the locked
    viewport/text-scale matrix.
  - Guard: immediate danger remains in world telegraphs and the threat radar.
  - Evidence: the facility runtime emits bounded activation, three-second warning, and
    shutdown events into a caller-owned buffer; GameRoot integration and Korean/English
    localization validators passed. Real 960×540 captures at
    `build/validation/hud-control-20260817-v2/{ko,en}/04c-progression-max.png` show the
    `CONTROL` message below the minimap without clipping or reticle overlap.

Phase gate:

- Run the focused HUD, stage-UI layout, localization, and visual-authority validators.
- Capture one Korean and one English gameplay frame showing one `CONTROL` message below
  the minimap at 960×540.

### Phase 2: Reduce upgrade fatigue within the current progression

Goal: increase the time between early upgrade modals without inventing a new currency or
choice schedule.

Preconditions:

- Phase 1 checks pass.

Source owners: `scripts/progression/vehicle_experience_runtime.gd`,
`scripts/vehicle/vehicle_run.gd`, `tools/validation/validate_vehicle_experience.gd`.

- [x] **2.1 Tune the existing early XP curve**
  - Change: set `EARLY_REQUIREMENT_SURCHARGE` from `4` to `8`; preserve the first-ten-level
    boundary, pending-level behavior, modal contents, card rules, shard values, and late
    requirement curve.
  - Accept: the focused progression fixture reports the new first-ten requirements and
    unchanged level 11+ requirements; a deterministic run still grants every earned level.
  - Guard: no upgrade charge, service break, deployment card, or replacement modal exists.
  - Evidence: `EARLY_REQUIREMENT_SURCHARGE` is `8`; the focused experience validator
    passed the exact first-ten requirements, unchanged level-11+ values, borrowed receipt
    reuse, pending-level behavior, and complete authored route cadence.

Phase gate:

- Run `./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_experience.gd`.

### Phase 3: Extend ordinary combat and increase relevant pressure

Goal: require `1.5x` as many ordinary defeats before every boss and make the fast vehicle
choose routes more often through one existing allocator change, while retaining the current
enemies, fixed-Hard values, encounter flow, authored populations, and capacity.

Preconditions:

- Phase 2 checks pass and its telemetry is recorded once.

Source owners: `docs/product/vehicle_game_spec.md`,
`scripts/vehicle/stages/vehicle_combat_stages.gd`,
`scripts/vehicle/vehicle_stage_catalog.gd`, `scripts/encounters/vehicle_stage_flow.gd`,
`scripts/encounters/vehicle_spawn_allocator.gd`, and existing campaign, spawn, and pacing
validators.

- [x] **3.1 Increase every boss-entry quota to `1.5x`**
  - Change: update the product contract and `VehicleCombatStages.QUOTAS` from
    `40/44/48/52/56/60/64/68` to `60/66/72/78/84/90/96/102`. Preserve exact-defeat boss
    gating, quota counting rules, authored populations `260/300/340/390/440/500/560/630`,
    HUD remaining-quota publication, boss warning timing, and fixed-Hard factor `1.0`.
  - Accept: catalog and flow fixtures report the exact new sequence; every boss remains
    blocked through quota minus one and begins its warning on the exact final countable
    defeat; every authored population remains at least quota plus the required 32-unit
    margin.
  - Guard: do not increase simultaneous active caps, authored populations, spawn capacity,
    boss counts, XP per enemy, enemy stats, or boss warning duration as part of this task.
  - Evidence: product/runtime quotas are exactly `60/66/72/78/84/90/96/102`; catalog,
    stage-continuity, single-field campaign, encounter-pacing, difficulty, and experience
    validators passed. The larger minimum route yields 3445 XP and 44 earned upgrades
    solely from the additional countable enemies; XP values and card rules are unchanged.
- [x] **3.2 Reweight existing spawn sectors**
  - Change: keep current candidate generation and deterministic sector allocation. In the
    existing scoring pass, prefer ahead/lateral sectors for one additional request before
    reusing a rear sector. Keep every safety, geometry, separation, and fallback check.
  - Accept: deterministic fixtures retain valid allocations and show a lower rear-sector
    share than the current baseline without removing rear pressure or creating a sealed ring.
  - Guard: no new scheduler, beat state, spawn source, or actor is added.
  - Evidence: moving allocation keeps the first request forward, places one additional
    request in a forward/lateral sector, then resumes the existing maximal-spacing pass.
    Spawn-allocation and the 16-seed × three-field × eight-cycle multi-sector validator
    passed while retaining later rear pressure and all geometry/safety checks.
Phase gate:

- Run the focused stage continuity, single-field campaign, run difficulty, spawn allocator,
  encounter pacing, and performance contract validators once after Tasks 3.1 and 3.2 pass.

Final gate:

- Run the focused validators for every touched owner, Godot import/parse, production Web
  export, and one built-Web Korean/English smoke path. This proves the changed slices only;
  it does not replace the product spec's complete release qualification. Record native and
  Web performance separately and do not claim a duration or difficulty target from headless
  simulation alone.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | Focused validator for the current owner | After the owner changes | A relevant implementation input changes |
| Phase gate | Checks named under that phase | All phase tasks pass | A phase-owned input changes |
| Final gate | Godot parse/import, production Web export, built-Web bilingual smoke | All phases pass | A final-gate input changes |

Validation rules:

- Run the narrowest check that proves the current task.
- Do not repeat a passing broad check to regain confidence.
- Rerun a failed check only after a relevant implementation change or a new hypothesis.
- Keep implementation evidence and play-duration evidence separate.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A phase makes readability, difficulty, interruption rate, or performance materially worse | Stop before the next phase and correct or revert only that phase | Do not compensate by redesigning another system |
| Duration or difficulty remains unsatisfactory after Phase 3 | Leave evaluation and any follow-up tuning to the user | Do not make a second quota or balance change in this contract |
| A requested improvement requires a new campaign, scheduler, progression currency, modal, or content family | Stop and revise the contract with explicit user approval | Executor cannot expand scope |

Implementation-local discoveries may be handled inside the locked existing owner when they
do not change visible behavior, architecture, scope, safety, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Final gate.
- Next task: Godot import/parse, production Web export, and built-Web bilingual smoke.
- Last completed gate: Phase 3 campaign, pacing, spawn-allocation, difficulty, experience,
  and performance-scenario contract gate.
- Update rule: after a checkpoint passes, record concise evidence, check the task, and
  advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check and named gate passes.
- The current run structure and out-of-scope systems remain unchanged.
- Korean/English rendered checks pass and the production Web build completes.
- Frontmatter status changes to `done` only after implementation is complete.

Replan when:

- A material fact invalidates a locked incremental decision or the user authorizes broader
  structural change.

Do not replan or stop for:

- Implementation-local mechanics inside an existing owner.
- A passing check whose relevant inputs have not changed.

## Visual Authority Evidence

- Canonical text contract read completely:
  `docs/design/VISUAL_SYSTEM.md`.
- Canonical style reference inspected at original `1448×1086` detail:
  `docs/design/cardborne-universal-art-style-reference.png`.
- Expected and observed SHA-256:
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- Provenance: original Codex artifact
  `C:/Users/BK/.codex/generated_images/019fbfe9-857e-7453-b72d-20908d848577/exec-0b8aa606-cf55-45c1-abb3-fb3df762b080.png`,
  timestamp `2026-08-02 12:13:44 KST`; the repository copy is canonical.
- Reference-input method: `not_applicable`. This planning correction creates no raster or
  SVG deliverable and grants no production asset or UI approval.
- Applicable constraints: use the shared Theme and component factory; retain one compact
  top-left row; prevent Korean/English clipping; avoid nested frames, decorative detail,
  raster UI, and screen-specific chrome; keep UI separate from gameplay truth.
