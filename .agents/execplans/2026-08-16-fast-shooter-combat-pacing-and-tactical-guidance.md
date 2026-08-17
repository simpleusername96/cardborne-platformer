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
- Deliverable: four sequential phases covering HUD and guidance, upgrade cadence, a
  quota increase plus one spawn-pressure adjustment, and a duration/difficulty
  observation report.
- Completion state: each slice passes its own acceptance checks before the next slice is
  implemented; the final native and built-Web checks pass.

## Scope and Boundaries

In scope:

- Improve the existing top HUD so boss/quota, Dash, and Active information remains legible.
- Present boss and facility guidance through the existing announcement pipeline with a
  fixed auxiliary-AI identity and concise Korean/English text.
- Reduce early upgrade interruptions by tuning the existing XP requirement curve.
- Increase every cycle's ordinary-defeat requirement before boss entry to exactly `1.5x`
  its current value.
- Make one small change to existing spawn weighting.
- Re-measure run duration and difficulty after the earlier slices without automatically
  changing any other fixed-Hard balance values.

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
- UI work uses existing shared components. The current visual contract still requires a
  panel-free HUD row and a text-only, event-limited announcement surface, so Phase 1 must
  amend only those exact clauses before the proposed backing or facility guidance is
  implemented. This plan does not override the active visual specification by itself.

Destructive or irreversible actions:

- None.

Exact actions requiring user approval:

- Any change outside the boundaries above, including campaign restructuring, new content,
  cap increases, dependencies, or player-control changes.
- Phase 1's narrow HUD/announcement contract amendment is grounded in the user's prior
  request for backed fit-square status cells and an auxiliary-AI guidance presence, and in
  the current instruction to apply that feedback incrementally. Any broader visual-contract
  amendment requires a new explicit decision.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked incremental decision | Task IDs |
| --- | --- | --- | --- | --- |
| Run ends near ten minutes | `VehicleStageFlow` gates each boss on the quota owned by `VehicleCombatStages.QUOTAS`; the current product and runtime sequence is `40/44/48/52/56/60/64/68`, and no timer ends the run. | `scripts/encounters/vehicle_stage_flow.gd`, `scripts/vehicle/stages/vehicle_combat_stages.gd`, `docs/product/vehicle_game_spec.md`, prior session diagnostics | Preserve the gate and multiply each current value by exactly `1.5`, producing `60/66/72/78/84/90/96/102`. Keep authored populations and simultaneous-pressure caps unchanged. | 3.1, 4.1 |
| Fast movement can leave enemies trailing | The allocator already distributes arrivals by sector and considers player velocity. | `scripts/encounters/vehicle_spawn_allocator.gd` | Keep the allocator. Adjust only its existing sector/role scoring so the first pass reduces rear pursuit modestly; do not add a new encounter scheduler. | 3.2 |
| Difficulty became too easy | Ordinary pressure is owned by shared projectile-speed, recovery, threat-budget, stage commit limits, and spawn placement. | `scripts/encounters/vehicle_encounter_director.gd`, `scripts/encounters/vehicle_spawn_allocator.gd` | Keep fixed-Hard numeric values unchanged in this contract. Test whether the one spawn-direction adjustment improves relevant pressure, then report any remaining balance gap. | 3.2, 4.1 |
| Upgrades interrupt play too often | XP requirements are computed in `VehicleExperienceRuntime`; pending levels and the existing modal already have stable owners. | `scripts/progression/vehicle_experience_runtime.gd`, `scripts/vehicle/vehicle_run.gd` | Keep the modal and reward flow. Change only `EARLY_REQUIREMENT_SURCHARGE` from `4` to `8` for the existing first ten requirement calculations. | 2.1 |
| Boss progress is clipped and status items lack backing | The gameplay HUD formats boss/quota text and owns the existing status items. The active visual contract currently forbids backing on this row. | `scripts/ui/vehicle_gameplay_hud.gd`, `scripts/ui/vehicle_hud_presenter.gd`, `docs/design/VISUAL_SYSTEM.md` | Preserve the current information and order. First amend the exact HUD clause, then give boss progress a width-aware backed cell and keep Dash/Active in equal backed square cells; do not build a new cockpit layout. | 1.0, 1.1 |
| Existing messages do not teach mechanics | The gameplay HUD already owns a localized, prioritized announcement queue and emits diagnostics. The active visual contract currently allows only four event families and text-only presentation. | `scripts/ui/vehicle_gameplay_hud.gd`, `scripts/ui/vehicle_stage_ui.gd`, `scripts/vehicle/vehicle_run.gd`, `docs/design/VISUAL_SYSTEM.md` | First amend the exact announcement clause, then add a fixed `CONTROL` label/glyph and verified boss/facility state messages to the existing queue. Preserve queue capacity and priority behavior. | 1.0, 1.2 |

Readiness statement:

- Product scope is locked to incremental changes in existing owners.
- The only numeric progression changes are the locked XP curve change and the exact quota
  sequence `60/66/72/78/84/90/96/102`. No implementation task selects a new campaign,
  encounter, progression, balance, or UI architecture.
- Required tooling and validators already exist in the repository.

## Tasks

### Phase 1: Make current information readable

Goal: fix the visible HUD problem and add the requested assistant-style guidance without
changing gameplay state or screen structure.

Preconditions:

- Load `$uiux-gate`, `.agents/design/DESIGN.md`, and `$cardborne-visual-authority` before
  implementation because this phase changes player-facing UI.

Source owners: `scripts/ui/vehicle_gameplay_hud.gd`,
`scripts/ui/vehicle_hud_presenter.gd`, `scripts/ui/vehicle_stage_ui.gd`,
`scripts/vehicle/vehicle_run.gd`, `docs/design/VISUAL_SYSTEM.md`, existing localization
catalogs, focused HUD validators.

- [ ] **1.0 Reconcile the two narrow visual-contract clauses**
  - Change: update only the HUD-row and normal-announcement clauses in
    `docs/design/VISUAL_SYSTEM.md`. Permit one restrained shared-Theme backing for
    `stage_progress`, `dash`, and `active`, and permit the existing announcement surface
    to show a fixed `CONTROL` sender label plus verified boss and neutral-facility state
    events. Preserve the one-row order, minimap ownership, queue behavior, semantic colors,
    code-native glyph ownership, and ban on screen-specific chrome.
  - Accept: the revised clauses are compatible with the product spec, design map, runtime
    owners, Korean/English requirement, and visual-authority validator.
  - Guard: do not revise modal layouts, world visuals, gameplay rules, or unrelated visual
    contracts.

- [ ] **1.1 Back the existing HUD status items**
  - Change: retain boss/quota, total defeats, Dash, and Active in their current order.
    Replace the clipped boss text slot with a width-aware backed cell and render Dash and
    Active in equal fit-square backed cells through shared UI primitives.
  - Accept: Korean and English boss progress is fully visible at 960×540, 1280×720, and
    1920×1080 at 100% and 200% text scale; no child clips or overflows.
  - Guard: minimap, threat radar, aiming area, focus behavior, and gameplay snapshot keys
    remain unchanged.
- [ ] **1.2 Add `CONTROL` to the current announcement surface**
  - Change: add one restrained code-native sender mark and label to the existing panel.
    Add concise observation/action copy for boss arrival or phase truth and neutral-facility
    activation, expiry warning, and shutdown. Publish messages only from verified runtime
    events; do not infer state from display text.
  - Accept: the current queue still prioritizes and coalesces messages; all new reachable
    keys exist in Korean and English; the panel does not cover the reticle at the locked
    viewport/text-scale matrix.
  - Guard: immediate danger remains in world telegraphs and the threat radar.

Phase gate:

- Run the focused HUD, stage-UI layout, localization, and visual-authority validators.
- Capture one Korean and one English gameplay frame showing boss progress and one
  `CONTROL` message at 960×540.

### Phase 2: Reduce upgrade fatigue within the current progression

Goal: increase the time between early upgrade modals without inventing a new currency or
choice schedule.

Preconditions:

- Phase 1 checks pass.

Source owners: `scripts/progression/vehicle_experience_runtime.gd`,
`scripts/vehicle/vehicle_run.gd`, `tools/validation/validate_vehicle_upgrade_system.gd`.

- [ ] **2.1 Tune the existing early XP curve**
  - Change: set `EARLY_REQUIREMENT_SURCHARGE` from `4` to `8`; preserve the first-ten-level
    boundary, pending-level behavior, modal contents, card rules, shard values, and late
    requirement curve.
  - Accept: the focused progression fixture reports the new first-ten requirements and
    unchanged level 11+ requirements; a deterministic run still grants every earned level.
  - Guard: no upgrade charge, service break, deployment card, or replacement modal exists.

Phase gate:

- Run `./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_upgrade_system.gd`.

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

- [ ] **3.1 Increase every boss-entry quota to `1.5x`**
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
- [ ] **3.2 Reweight existing spawn sectors**
  - Change: keep current candidate generation and deterministic sector allocation. In the
    existing scoring pass, prefer ahead/lateral sectors for one additional request before
    reusing a rear sector. Keep every safety, geometry, separation, and fallback check.
  - Accept: deterministic fixtures retain valid allocations and show a lower rear-sector
    share than the current baseline without removing rear pressure or creating a sealed ring.
  - Guard: no new scheduler, beat state, spawn source, or actor is added.
Phase gate:

- Run the focused stage continuity, single-field campaign, run difficulty, spawn allocator,
  encounter pacing, and performance contract validators once after Tasks 3.1 and 3.2 pass.

### Phase 4: Observe duration and report the next bounded decision

Goal: determine whether the four incremental slices improved interruption rate, route
pressure, difficulty, and duration without silently changing the campaign.

Preconditions:

- Phases 1–3 pass and five complete deterministic runs are captured with the same build and
  workload settings.

Source owners: campaign and pacing validators, session diagnostics.

- [ ] **4.1 Record matched-run evidence without tuning another system**
  - Change: calculate the median active run time, per-cycle ordinary-combat duration,
    upgrade-session count and gap, rear-sector share, accepted damage, and completion result
    from the five completed runs. Compare them with the prior diagnostic capture and state
    its provenance and limitations.
  - Accept: the evidence states whether the four slices improved each concern, records the
    exact enlarged quota sequence and unchanged remaining fixed-Hard values, and separates
    observation from recommendation.
  - Guard: do not further change quotas, fixed-Hard values, HP, damage, projectile speed,
    recovery, threat budgets, commit caps, actor caps, or campaign flow in this contract. If
    another numeric balance change is still justified, propose one isolated variable for
    separate user and product-spec approval.

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
| Duration or difficulty remains unsatisfactory after Phase 3 | Record the gap and propose one isolated numeric variable for a separate product-spec decision | Do not make a second quota or balance change in this contract |
| A requested improvement requires a new campaign, scheduler, progression currency, modal, or content family | Stop and revise the contract with explicit user approval | Executor cannot expand scope |

Implementation-local discoveries may be handled inside the locked existing owner when they
do not change visible behavior, architecture, scope, safety, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 1.
- Next task: 1.0 Reconcile the two narrow visual-contract clauses.
- Last completed gate: Discovery Closure Gate.
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
