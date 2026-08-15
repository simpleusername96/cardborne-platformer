---
type: plan
status: active
owner: BK
created: 2026-08-15
last_reviewed: 2026-08-15
scope: Eight continuous boss cycles, eight distinct bosses, boss-death cleanup, four ordinary enemies, three combat upgrades, five symmetric neutral facilities, newest-ten diagnostics, stacked run reports, localization, approved visual assets, and release validation
related:
  - ../../docs/reports/2026-08-15-eight-boss-combat-design-analysis.md
  - ../../docs/reports/2026-08-15-eight-boss-combat-approval-ko.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/product/vehicle_upgrade_catalog.md
  - ../../docs/product/vehicle_weapon_balance_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../design/DESIGN.md
  - ../cardborne-performance-engineering-policy.md
---

# Eight-Boss Combat Depth and Run Report - Execution Contract

The shipped run becomes eight continuous quota-gated boss cycles. It removes Shock
without replacement, adds three bosses, four ordinary enemy roles, three primary-fire
upgrades, five symmetric neutral facilities, a safe two-second boss-death cleanup, newest-
ten diagnostics retention, and one stacked report shared by terminal and Settings
surfaces. The implementation preserves the existing Godot 4.7/GDScript architecture,
exact enemy workload, manual aim, held primary fire, dash, acquired weapons, and one fixed
Hard difficulty.

## Purpose

- Objective: deliver the approved combat and run-depth revision as one production-ready,
  bilingual Cardborne update.
- Deliverable: gameplay, data, UI, localization, approved production imagery, focused
  validators, rendered evidence, and a production Web export.
- Completion state: every checkbox and named gate passes; exact visual candidates are
  approved by hash before promotion; this document is then marked `done`.

## Scope and Boundaries

In scope:

- Eight `boss_cycle` units, each with ordinary quota, warning, boss combat, boss-death
  cleanup, and continuation.
- Common boss charge and broad three-row projectile barrage plus eight profile-owned
  identities and monotonically stronger base statistics.
- Four ordinary enemy roles, the 4/8/3-second engagement-gap contract, and newest-ten
  diagnostic retention.
- Miss Compensation, Hit Chain, Braced Fire, and missing active/secondary offer
  reservation.
- Repair, Barrier, Gravity, Cryo, and Weakpoint facilities; repair-pickup replacement and
  five visible XP shards per cycle.
- One shared left-aligned vertically stacked report body for victory, defeat, and Settings.
- Removal of Shock from resources, runtime state, offers, copy, telemetry/reporting,
  imagery, and validators. Cryo is the only utility primary attribute.
- Three boss, four enemy, two facility, three upgrade-card, and one boss-explosion raster
  additions; removal of one Shock raster; final production manifest count `90`.

Out of scope:

- A replacement utility attribute, true instant-kill attacks, defense-only bosses, Shield
  Breaker, corpse objects, separate bossless stages, absolute completion-time targets,
  new maps, difficulty selection, production dependencies, engine changes, threads,
  GDExtension, custom Web templates, sprite sheets, particles, or per-boss death art.

Constraints and invariants:

- Use Godot 4.7.1 through `./tools/godot.ps1`; preserve exact cap 48 and all existing
  projectile/effect capacities unless a locked task explicitly adds a bounded kind.
- Keep gameplay rules outside UI and visual geometry outside collision truth. Do not add
  card-specific state machines to `scripts/vehicle/vehicle_run.gd`; use responsibility-
  shaped owners and leave `VehicleRun` as orchestration only.
- Korean remains default and Korean/English coverage must remain complete.
- Every high-threat attack warns for at least 1.30 seconds, commits collision-matching
  geometry, leaves one escape corridor at least player diameter + 80 units, applies damage
  once per execution, and never retargets after final commit.
- No empty or off-screen-only combat gap may exceed 3.0 seconds; first visible hostile is
  due within 4.0 seconds and first meaningful attack preparation within 8.0 seconds.
  Do not teleport hostiles or lower counts/cadence to satisfy this.
- Total run time is telemetry only, never a pass/fail threshold.
- Visual authoring and approval follow the canonical authority pair and workbench. Runtime
  promotion is hash-addressed and never inferred from style alignment.

Destructive or irreversible actions:

- Delete `data/cards/vehicle/shock_disruption.tres` and the production Shock PNG only
  after every reference is removed in the same commit. Git history is the recovery path.

Exact actions requiring user approval:

- Promote only the exact visual files and SHA-256 hashes presented in the approval report.
  Existing direction-clear candidates and newly generated upgrade-card candidates remain
  outside production until that approval is explicit.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Progression | `vehicle_combat_stages.gd`, `vehicle_stage_catalog.gd`, `vehicle_stage_transition_runtime.gd`, and `vehicle_run.gd` expose ten odd/even stages and only five bosses | Current source and product spec | Replace player-facing stages with eight quota-gated boss cycles; every cycle has a boss | 1.1, 2.1 |
| Boss combat | `scripts/bosses/` owns patterns, phases, shields, and runtime; `VehicleRun` orchestrates enemy state and receipts | Current boss owners and validators | All bosses keep common charge and broad barrage; identity patterns own at least three of five selections; only bosses 3 and 5 use defense | 2.2-2.4 |
| Boss death | Current transition advances after boss defeat without the approved cleanup | Transition/runtime source and report evidence | Add `VehicleBossDeathRuntime` with the exact 2.00-second state/timing contract | 2.5 |
| Ordinary enemies | Archetypes and specialist runtime own existing active roles; no four proposed identities exist | `vehicle_enemy_archetypes.gd`, `vehicle_enemy_specialist_runtime.gd` | Add Rail Sniper, Orbit Gunner, Bombing Runner, and Wreck Scavenger; no Shield Breaker or corpse system | 3.1 |
| Primary attributes | Build has damage IDs Thermal/Toxin and utility IDs Cryo/Shock; payload/status/validators still reach Shock | Build, payload, status, card resource, manifest, and grep evidence | Delete Shock with no replacement; utility slot contains Cryo only | 1.2 |
| New upgrades | Shot groups and movement are orchestrated in combat/run code, while definitions and offers are card-owned | Card/runtime owners | Implement the three exact bounded card contracts and reserve missing weapon categories | 3.2, 3.3 |
| Neutral facilities | `VehicleMysteryDeviceRuntime` owns three destroy-to-trigger outcomes; repair remains a pickup | Runtime, visual spec, and product spec | Five persistent, attackable, pass-through facilities affect player and enemies symmetrically | 3.4 |
| Diagnostics | Store retains 20 sessions and already sorts by saved time/session ID with 25 MiB/14-day caps and quarantine | Store and validator | Change maximum to newest 10 on both load and persist; keep other caps and quarantine | 4.1 |
| Report | `VehicleCombatReportBody` is shared but terminal surfaces still use columns/tabs/build rail and nested content regions | UI owners and validators | One left-aligned vertical stack, one outer scroll, fixed primary action, no tabs/sub-scroll/side rail | 4.2 |
| Visuals | Manifest has 77 approved production images after Shock removal; 13 grounded candidates remain outside production pending exact-file approval | Manifest and workbench evidence | Promote the 13 approved rasters for exactly 90 production images | 1.3, 5.1, 5.2 |
| Performance | Current Web exact-cap-48 physics evidence is red; historical render evidence does not attribute sustained cost to raster size | Performance policy/audit and prior active plan | Preserve workload/capacities; label functional, visual, native, and Web performance verdicts separately | 5.3 |

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership, safety, and
  validation decision is closed.
- Godot 4.7.1, repository wrappers, validators, ImageGen, and the Web export path are
  available. No dependency bootstrap is authorized or required.
- Remaining visual approval is an explicit hash gate, not an executor design decision.
- Remaining unknowns are implementation-local and cannot change this contract.

## Locked Behavior Tables

### Common boss kit and scaling

- Committed charge: exact corridor warning `1.00-1.25 s`, locked direction, active travel
  `0.55-0.75 s`, wall stop, normal damage.
- Broad barrage: three rows at `0.38 s` intervals; each row simultaneously emits `4/5/6`
  projectiles for cycles `1-3/4-6/7-8`, center spacing `96`, warning `0.65 s`, pressure
  damage, and one `0.80 s` per-target hit lock for the whole activation. `SPREAD` uses a
  42-degree fan; `ROTATE` turns the emission axis 22.5 degrees between rows.
- Base health is `5200`. Health scales: `1.00, 1.12, 1.25, 1.39, 1.54, 1.70, 1.87,
  2.05`; damage: `1.00, 1.06, 1.12, 1.18, 1.24, 1.31, 1.38, 1.46`; move speed:
  `145, 150, 155, 160, 166, 172, 178, 184`; cadence: `1.00, .97, .94, .91, .88,
  .85, .82, .79`; coverage: `1.00, 1.04, 1.08, 1.12, 1.16, 1.20, 1.24, 1.28`.
- Damage bands: pressure `10-18`, normal `22-38`, high threat `60-85`.

### Boss identities

| # | Boss | Barrage | Identity contract |
| ---: | --- | --- | --- |
| 1 | Foundry Colossus | SPREAD | Furnace Gates closes two warned lanes; wall collision after charge gives 1.4 s vulnerability; no shield |
| 2 | Archive Leviathan | ROTATE | Fixed X-cross laser alternates orientation by 45 degrees; no shield |
| 3 | Drydock Titan | SPREAD | Permanent 110-degree frontal 90% interception; facing locks during attacks; blocked damage charges a visible frontal counterburst |
| 4 | Switchyard Behemoth | ROTATE | One moving beam sweep; below 45% health a sweep follows from the opposite side; no shield |
| 5 | Crown Engine | SPREAD | Three attached destructible relay hardpoints each own one shield sector and bolt lane; losing one removes both and accelerates remaining relays |
| 6 | Siege Battery | SPREAD | Alternating banks fire 8-10 long-lived projectiles into different lanes; no shield |
| 7 | Vector Loom | ROTATE | Translating parallel laser walls followed by an orthogonal pass; each wall has one explicit moving gap; no shield |
| 8 | Pulse Core | ROTATE | Expanding/contracting rings with a missing wedge followed by sparse spiral shots; no shield |

### Boss-death cleanup

- `0.00`: disable AI, collision, intake, spawn, and damage output; retire boss-owned
  damaging projectiles/zones; freeze facing.
- `0.00-0.15`: keep body intact; spawn exactly one centered explosion at scale `0.20`;
  play priority-destruction audio once.
- `0.15-1.30`: ease-out explosion scale to `1.20`; body remains fully visible.
- `0.20-1.10`: stagger owned summons/facilities by `0.12 s`; scale/fade to zero; grant no
  XP, loot, or quota; report source `boss_cleanup`.
- `1.30-1.70`: hold explosion scale `1.20`; fade explosion and unchanged body together.
- `1.70-2.00`: clear remaining owned objects, freeze report snapshot, permit transition.
- Reduced motion starts the explosion at scale `1.20`, removes hit-stop/impulse/growth,
  and preserves the synchronized fade and 2.00-second duration.

### Upgrades and facilities

- Miss Compensation: missed retired primary shot groups stack to 5; next hostile hit adds
  `8/11/14%` damage per stack and consumes all.
- Hit Chain: consecutive hit shot groups stack to 8; primary damage gains `3/4/5%` per
  stack; a missed retired group clears it.
- Braced Fire: each `220` units moved charges a segment to 5; speed below `20` for `0.60 s`
  consumes charge and grants `6/8/10%` primary damage per segment for `4.0 s`; speed above
  `60` ends the window. Split children share one shot-group outcome for all three cards.
- Missing active and secondary categories reserve one offer slot each; reservation ends
  per category immediately after acquisition.
- Facilities have `360` health, last until destroyed or cycle cleanup, accept player and
  hostile damage, do not block projectiles, and affect every eligible actor whose center
  is inside the radius. Repair/Barrier use radius `420` and restore one third of maximum
  hull per second; Barrier caps at shield equal to maximum hull. Gravity uses radius `480`
  and multiplies acceleration and maximum speed by `0.55` without positional pull. Cryo
  uses radius `360` and multiplies movement and attack cadence by `0.70`. Weakpoint uses
  radius `420` and multiplies received damage by `1.25`. Effects stop immediately outside
  the radius or when the facility is destroyed.
- Spawn three distinct facilities per cycle from a run-seeded deterministic rotation;
  across eight cycles every type appears at least once. Remove repair pickups, replace
  their authored sockets with XP shards, and add exactly five visible XP shards per cycle.

## Tasks

### Phase 1: Contracts and Shock removal

Goal: make current product, terminology, data, validation, and visual counts agree before
new runtime behavior lands.

Source owners: `docs/product/`, `docs/design/VISUAL_SYSTEM.md`, `.agents/design/DESIGN.md`,
`scripts/cards/`, `scripts/combat/vehicle_primary_payload_profile.gd`,
`scripts/combat/vehicle_status_runtime.gd`, localization catalogs, production manifest,
and focused validators.

- [x] **1.1** Replace ten-stage/paired player-facing contracts with eight boss cycles.
  - Change: update product specs, design context, localization inventory, guidebook/report
    terminology, and validation expectations. Preserve internal compatibility names only
    within the same migration commit and remove them before acceptance.
  - Accept: repository search finds no reachable `Stage N/10`, odd/even boss-stage rule,
    or five-boss acceptance claim outside archived evidence.
- [x] **1.2** Delete Shock end to end with no replacement.
  - Change: remove the card resource, build/catalog ID, payload/status fields, offer paths,
    copy, telemetry/report fields, semantic asset registration, production PNG, and Shock-
    specific validator cases. Keep Cryo as the sole utility ID.
  - Accept: card catalog reports 27 live card IDs and 91 nominal levels; Shock has no
    reachable resource, offer, runtime state, localized label, report row, provider ID, or
    production file. Damage attributes still choose Thermal or Toxin independently of Cryo.
  - Guard: names `Shockwave`/`kinetic_shockwave` remain because they are unrelated active-
    weapon identities.
- [x] **1.3** Update the visual contract for the approved scope and final count.
  - Change: authorize eight boss bodies, profile-owned shields, attached Crown hardpoints,
    four enemy silhouettes, five facility roles, three new card images, and exactly one
    shared boss explosion raster exception; set final manifest target to 90.
  - Accept: `validate_cardborne_visual_authority.ps1` passes and all numeric/category
    claims in active design docs agree.

Phase gate:

- Run `git diff --check`, the focused card/status/semantic-provider validators, and
  `./tools/validation/validate_cardborne_visual_authority.ps1` once after 1.1-1.3 pass.

### Phase 2: Eight-cycle boss run

Goal: deliver the complete run progression, common kit, eight identities, and safe death
cleanup without adding unrelated behavior to `VehicleRun`.

Preconditions: Phase 1 passes.

Source owners: `scripts/vehicle/stages/vehicle_combat_stages.gd`,
`scripts/vehicle/vehicle_stage_catalog.gd`, `scripts/vehicle/vehicle_stage_transition_runtime.gd`,
`scripts/enemies/vehicle_stage_difficulty.gd`, `scripts/bosses/`,
`scripts/combat/vehicle_effect_store.gd`, and `scripts/vehicle/vehicle_run.gd` orchestration.

- [x] **2.1** Implement the eight-cycle state flow and cycle-owned quotas/snapshots.
  - Accept: a deterministic fixture completes exactly eight cycles in order and every
    boss begins only after its ordinary quota; no transition occurs before cleanup.
- [x] **2.2** Implement common charge, broad barrage, selection cap, scaling, and damage bands.
  - Accept: validators assert simultaneous row counts/spacing/timing/motion, monotonic
    profiles, at most two common selections per five, and exact hit locks.
- [x] **2.3** Implement bosses 1-5 with their revised identity and defense contracts.
  - Accept: each identity geometry and state validator passes; only Drydock and Crown have
    shields and their defenses directly emit the locked offense.
- [x] **2.4** Implement Siege Battery, Vector Loom, and Pulse Core.
  - Accept: each can charge, barrage, and complete its unique pattern; warning geometry
    equals collision and high-threat escape checks pass.
- [x] **2.5** Add `scripts/bosses/vehicle_boss_death_runtime.gd` and bounded explosion state.
  - Accept: frame-step validator proves the exact timeline, safety, ownership retirement,
    no cleanup rewards/quota, one cosmetic receipt maximum, reduced-motion behavior, and
    transition only at 2.00 seconds.

Phase gate:

- Run focused campaign, stage transition, boss phase/shield/pattern, attack readability,
  effect-store, cleanup, localization, and deterministic continuity validators.

### Phase 3: Ordinary combat, upgrades, facilities, and pacing

Goal: add the approved target-priority roles and player build depth while preserving
bounded hot paths and continuous engagement.

Preconditions: Phase 2 passes.

Source owners: `scripts/enemies/`, `scripts/cards/`, responsibility-shaped combat runtime
owners, `scripts/vehicle/vehicle_mystery_device_runtime.gd`, progression/pickup owners,
and `VehicleRun` orchestration hooks.

- [ ] **3.1** Add the four ordinary enemy roles and engagement-gap correction.
  - Accept: role-specific fixtures prove attack cadence/geometry and Wreck Scavenger's
    radius-360 death-event stacks, exclusions, maximum five, exact multipliers, and active
    attack at zero stacks; 4/8/3 pacing capture passes without teleport or count reduction.
- [x] **3.2** Add the three primary-fire upgrade runtimes and definitions.
  - Accept: shot-group and movement fixtures prove all thresholds, caps, consumption,
    split-child deduplication, and level values with bounded state and no per-tick pair scan.
- [x] **3.3** Enforce missing active/secondary offer reservation.
  - Accept: seeded offer fixtures reserve both categories when both are absent, one when
    one is absent, and none after both are acquired while preserving three legal offers.
- [x] **3.4** Replace Mystery outcomes and repair pickups with five symmetric facilities.
  - Accept: player/enemy enter/exit tests prove exact radii/effects, both factions can
    destroy facilities, projectiles continue through, deterministic cycle distribution
    covers all types, repair pickups are unreachable, and five added XP shards remain visible.

Phase gate:

- Run focused enemy, engagement, upgrade, offer, facility, progression, spatial/collision,
  and workload/capacity validators.

### Phase 4: Diagnostics and shared stacked report

Goal: retain actionable recent evidence and make the same readable report available from
terminal and Settings surfaces.

Preconditions: Phase 1 contracts pass; this phase may execute in parallel with Phases 2-3
when it does not edit shared orchestration files.

Source owners: `scripts/diagnostics/vehicle_session_diagnostic_store.gd`,
`scripts/combat/vehicle_run_result_builder.gd`, `scripts/combat/vehicle_stage_report_builder.gd`,
`scripts/ui/vehicle_combat_report_body.gd`, `vehicle_result_panel.gd`,
`vehicle_stage_report_panel.gd`, `vehicle_settings_panel.gd`, and shared UI primitives.

- [x] **4.1** Retain the newest ten valid diagnostics on load and persist.
  - Accept: validator creates more than ten valid/tied/old/oversize/corrupt bundles and
    proves descending `(saved_unix, session_id)`, ten maximum, quarantine, 25 MiB, 14-day
    caps, and protected cycle/boss/cleanup/report summaries.
- [x] **4.2** Recompose the shared report as one stacked outer-scroll body.
  - Change: section order is outcome, cycle progress, build, damage, defense, enemies,
    bosses, pacing, diagnostics limitations; remove report tabs, metric sub-scrolls, and
    the side build rail. Keep exactly one fixed Deployment action on terminal surfaces.
  - Accept: the same view model/component instance contract is used by victory, defeat,
    and Settings; focus order follows section order and debug contracts report one scroll,
    zero tabs, zero nested scrolls, zero build rails.
- [x] **4.3** Complete Level 3 rendered UI evidence.
  - Accept: Korean/English captures at 960x540, 1280x720, and 1920x1080 at 100%/200% text
    show zero overflow, clipping, overlap, horizontal scroll, or hidden action; keyboard
    and controller focus traverse every reachable report state.

Phase gate:

- Run diagnostic, report builder, report panel, result, Settings, UI component,
  localization, layout, and accessibility validators once after rendered fixes settle.

### Phase 5: Visual promotion and production qualification

Goal: promote only approved exact imagery, integrate it without workload drift, and close
the production build/evidence boundary.

Preconditions: the relevant gameplay identity exists; exact candidate approval is recorded
before task 5.2.

Source owners: visual workbench units, `art/visuals/production/gameplay/asset-manifest.json`,
`scripts/presentation/components/vehicle_semantic_asset_provider.gd`, actor/effect catalogs,
renderer batches, and production Web tooling.

- [x] **5.1** Generate and present the three card-art candidates and exact approval sheet.
  - Change: use ImageGen with the canonical style PNG as an actual reference; combine the
    three card candidates with the existing nine actor/facility and one explosion candidate
    in the Korean approval report with exact paths and hashes.
  - Accept: workbench evidence records prompts, actual-reference use, canvas/alpha/hash,
    actual-size/grayscale checks, and each candidate remains outside production pending the
    exact approval gate.
- [ ] **5.2** Promote the approved set and remove Shock art.
  - Accept: manifest indexes exactly 90 files; every new semantic ID resolves; Shock does
    not; canvases/pivots/imports match contracts; one explosion receipt and no sprite sheet,
    new dependency, extra effect raster, node-per-effect, or collision change exists.
- [ ] **5.3** Complete source, render, export, interaction, and performance gates.
  - Change: run focused validators, import/parse, production Web export, built-Web
    interaction, and only then the declared clean native/Web same-workload performance
    scenarios. Announce the broad/expensive gate before starting and stop contaminated
    samples without drawing a verdict.
  - Accept: functional and rendered gates are green; native/Web verdicts name exact commit,
    dirty state, workload, viewport, renderer, warmup, duration, focus, isolation, and pass
    label. A pre-existing Web physics failure is reported truthfully and does not become an
    asset failure without attribution.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | Relevant `./tools/godot.ps1 --headless --path . --script res://tools/validation/<focused>.gd` and `git diff --check` | The owning task changes | Relevant implementation input changes |
| Visual phase | `./tools/validation/validate_cardborne_visual_authority.ps1` plus manifest/provider/import checks | Visual contract or promoted bytes change | Visual input changes |
| UI phase | Report/layout validators plus the locked locale/viewport/text-scale capture matrix | Report composition/localization stabilizes | UI or copy input changes |
| Final source | All task-owned focused validators and Godot import/parse | All phases pass | Source/resource input changes |
| Final Web | `./tools/export_web.ps1`, static release validation, built-Web interaction | Final source gate passes | Web/runtime/resource input changes |
| Performance | Active policy's clean same-workload native then Web scenarios | Functional/rendered/Web gates pass and machine is quiescent | Measured input or hypothesis changes |

Validation rules:

- Run the narrowest check that proves the current task and each phase gate once.
- Do not repeat a passing check unless a relevant input changed.
- Rerun a failed check only after a relevant implementation change or a new hypothesis.
- Keep functional, rendered, native performance, and Web performance verdicts separate.
- Record known non-blocking warnings once. Do not reduce workload, quality, or thresholds
  to manufacture a pass.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A verified material fact contradicts this contract | Stop the affected branch and revise this contract before resuming | Executor cannot choose a new product, architecture, dependency, UX, safety, or validation contract |
| Exact visual approval is missing | Continue independent code/data work; keep bytes outside production and stop task 5.2 | Never infer approval from direction-clear status or plan execution |
| New visual candidate fails authority/canvas/alpha/readability | Regenerate only that candidate with the canonical image reference and update its hash/evidence | Do not repair geometry with SVG/ImageMagick |
| Shared `VehicleRun` edit conflicts across workstreams | Root integrator owns the orchestration edit; workers return focused owner modules and required hooks | Do not let parallel workers edit the same orchestrator |
| Facility or boss state exceeds a fixed store | Add one bounded typed receipt only in the owning store and update capacity validators | Do not add unbounded nodes/arrays or evict functional effects |
| Performance sample is contaminated or lacks comparable metadata | Reject it as diagnostic-only and wait for a quiet rerun | Do not kill unrelated processes or claim pass/failure |
| Threads, native code, dependency, engine, template, workload, or threshold change becomes necessary | Stop and request a new approved contract | Not authorized here |

Implementation-local discoveries may be handled inside the locked contract when they
cannot change scope, visible behavior, ownership, architecture, safety, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 3 pacing qualification and Phase 5 visual approval gate.
- Next task: commit the independently complete implementation, run the clean 4/8/3 pacing
  capture, then request exact hash approval for task 5.2.
- Last completed gate: focused source/runtime/UI validation. The 8-cycle campaign, boss
  patterns and cleanup, four specialist enemies, 27-card/91-level catalog, five symmetric
  facilities, newest-ten diagnostics, stacked reports, guidebook, localization, and the
  960/1280/1920 Korean/English 100%/200% report capture matrix are green.
- Update rule: after a task passes, record concise evidence, check it, and advance this
  pointer in the same edit. On start/resume, inspect only the current checkpoint inputs.
- Checked tasks and recorded passing evidence stay complete unless a relevant input changed.

Execution evidence recorded on 2026-08-15:

- Focused validators passed for upgrade system/facilities, eight-boss campaign, boss
  patterns/runtime, specialist enemies, attack/status contracts, diagnostics, stage/final
  reports, eight-cycle catalog, engagement steering, localization, guidebook, experience,
  field layout, renderer, semantic assets, weapon balance, persistent facilities, map
  integration, destructible terrain, and the full VehicleRun fixture.
- The shared report capture matrix rendered Korean and English at 960x540, 1280x720, and
  1920x1080 with 100% and 200% text scale. Inspection found no clipping, overflow, nested
  scroll, side rail, or hidden terminal action.
- Three meaningful local sessions were retained after seven exact automated sub-second
  diagnostics were removed. Their engagement-gap evidence drove bounded off-screen steering;
  clean 4/8/3 capture remains the acceptance gate for task 3.1.
- Thirteen exact visual candidates and their SHA-256 hashes are recorded in the Korean
  approval report and remain outside production. Task 5.2 is intentionally blocked on the
  user's explicit exact-file approval.

## Completion and Stop Conditions

Complete when:

- Every task acceptance, guard, phase gate, final gate, and exact visual approval gate passes.
- No Shock identity, player-facing ten-stage pairing, global boss shield rule, report
  overflow, nested report scroll, or unapproved production candidate remains.
- The final manifest count is exactly 90 and the production Web artifact is built and
  interaction-checked.
- Durable behavior is incorporated into its owning specs and this plan is marked `done`.

Replan when a material discovery invalidates a locked behavior, owner, safety boundary,
or acceptance check. Do not replan for implementation-local mechanics or a passing check
whose inputs have not changed.
