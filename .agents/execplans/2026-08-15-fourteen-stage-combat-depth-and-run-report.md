---
type: plan
status: active
owner: BK
created: 2026-08-15
last_reviewed: 2026-08-15
scope: Product specification, upgrades, facilities, enemies, bosses, stage pacing, diagnostics, report UI, localization, visual assets, validation, and release evidence
related:
  - ../../docs/reports/2026-08-15-fourteen-stage-feedback-summary-ko.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../design/DESIGN.md
  - ../cardborne-performance-engineering-policy.md
  - ./2026-08-13-run-pacing-result-and-upgrade-slots.md
---

# Fourteen-Stage Combat Depth and Run Report

## Purpose

Turn the 2026-08-15 play feedback into one decision-complete implementation contract.
The finished run must provide more real play, not merely more health: fourteen paired
stages, three new ordinary enemies, two new bosses, clearer combat pressure, neutral
facilities that affect both sides, three feedback-driven upgrades, reliable weapon-slot
offers, and one readable stacked report shared by terminal results and Settings.

This plan supersedes the ten-stage/content assumptions in the active product spec only
for the topics explicitly decided below. Earlier plans remain evidence of completed or
pending work; they do not own this expansion.

## Why / Context

The local diagnostic store is active at Godot `user://diagnostics`, which resolves on
this machine to
`C:\Users\BK\AppData\Roaming\Godot\app_userdata\Cardborne\diagnostics`. It contains 14
valid schema-1 session bundles from 2026-08-14 through 2026-08-15. The latest completed
ten-stage run (`session-1786726906-6020137-0.json`) lasted 576.37 active seconds, or
9 minutes 36 seconds. Earlier valid five-stage completions were in roughly the same
8 minute 34 second to 10 minute 14 second band. The ten-stage campaign therefore has not
yet produced a materially longer normal run.

That latest run retained 13 exact visible-gap closures totaling 37.15 seconds, including
a 12.18-second stage-2 opening gap. Full-run one-Hz samples also show an approximately
11-second no-visible interval in stage 7 and a 6-second interval in stage 10 while about
42 enemies remained alive. The detailed event buffer dropped 247 events after reaching
its 256-event cap, so late-run exact attribution is incomplete. This is sufficient to
confirm the reported search problem, but not sufficient to blame one AI role without
better stage summaries.

Current reports also fail the intended information-first UI contract. The terminal
result uses an outer scroll, three internal metric scrolls or tabs, and a narrow compact
build rail. At 960×540 with 200% text scaling, the first view shows navigation chrome but
almost no report content. Settings does not show the same accumulated report; it shows a
separate build-only summary.

## Discovery Closure Map

| Concern | Current owner/evidence | Decision in this plan |
| --- | --- | --- |
| Upgrade catalog and offers | `vehicle_upgrade_catalog.gd`, card resources, `vehicle_run_build.gd` | Add three combat cards and persistent missing-weapon offer reservations |
| Primary shot outcomes | `vehicle_primary_upgrade_rules.gd`, `vehicle_outgoing_damage_policy.gd`, projectile retirement in `vehicle_run.gd` | Add one narrow shot-group outcome owner; do not put the state machine in UI or expand `VehicleRun` with card rules |
| Neutral objects | `vehicle_mystery_device_runtime.gd`, stage pickup/layout owners | Replace anomaly-on-destruction behavior with always-active neutral facilities affecting both sides |
| Enemy behavior | enemy catalogs, specialist runtime, encounter scheduler | Add three active-pressure roles and a no-recipient fallback for support enemies |
| Campaign | `vehicle_combat_stages.gd`, difficulty arrays, guidebook, localization | Expand from 10 to 14 stages and from five to seven paired-run bosses |
| Bosses | boss profiles, patterns, shield/runtime owners | Add a frontal-shield boss and a sustained multi-direction siege boss; make beam/volley dimensions data-owned |
| Search gaps | scheduler, approach lanes, live/visible state in `vehicle_run.gd` | Expedite reserves and redirect nearby mobile hostiles without teleporting or lowering authored counts |
| Diagnostics | session recorder/store and run lifecycle signals | Split protected core summaries from bounded detail events |
| Reports | report/result builders and UI panels | Reuse one left-aligned vertical report body with exactly one content scroll |
| Visual authority | `VISUAL_SYSTEM.md`, canonical reference sheet, production manifest | Add only ten approved raster assets; keep shields, beams, fields, and meters code-native |
| Performance | performance policy and runtime audit | Preserve workload and exact collision; qualify only comparable clean native/Web checkpoints |
| Saved runs | repository search | No saved-run serializer exists; no run migration or compatibility alias is required |

## Scope

- Revise the product and visual specifications for a fourteen-stage paired campaign.
- Add three upgrade cards and their level/state, damage, HUD, offer, localization, and
  report contracts.
- Replace repair pickups and anomaly devices with five neutral facility types.
- Add three ordinary enemy roles, two boss profiles, four stages, and revised late-boss
  patterns.
- Correct visible-pressure gaps without reducing authored pressure or teleporting actors.
- Preserve complete lifecycle and per-stage pacing summaries in diagnostics.
- Redesign terminal/failure/Settings reporting around one shared stacked body.
- Author and approve ten new production rasters under the existing visual workflow.
- Validate Korean and English, supported viewports, import, Web export, functional
  behavior, and clean release performance.

## Non-Scope

- Engine, renderer, physics-tick, collision-accuracy, or production-dependency changes.
- A generic AI rewrite, generic pooling/cache work, or a big-bang `VehicleRun` split.
- New cultural, marine, ritual, or named-material themes.
- Raster UI chrome, raster beam/field effects, or SVG/ImageMagick-authored player-facing
  geometry outside the existing `SurfaceDetail` exception.
- Endless mode, procedural stages, online services, cloud telemetry, or saved mid-run
  continuation.
- Reducing encounter counts, attack cadence, visual quality, or acceptance thresholds to
  manufacture a pacing or performance pass.

## Assumptions

- Godot 4.7.1 and the existing GL Compatibility/Web targets remain authoritative.
- Korean remains the default language and every new user-facing string ships in Korean
  and English together.
- The campaign remains a connected paired run. Bosses occur on even stages.
- Existing ten-stage progress is run-scoped; starting a deployment always constructs the
  current fourteen-stage catalog.
- Existing collision truth, manual aim, held primary fire, dash, seekers, EMP, authored
  encounters, card upgrades, and quota-gated bosses remain intact.

## Proposed Design

### 1. Fourteen-stage campaign and duration contract

Add stages 11–14 as two complete teaching/remix pairs. Use quotas
`[64, 64, 72, 72]` and authored ordinary counts `[756, 756, 900, 900]`. Stages 11/12
introduce the three new ordinary roles and the frontal-shield boss. Stages 13/14 remix
the whole role set and end with the siege-array boss. Extend every stage-indexed table,
guide entry, localization key, capture fixture, report label, and validator to 14 entries.

Continue the current shallow difficulty progression with these exact stage 11–14 values:

| Curve | 11 | 12 | 13 | 14 |
| --- | ---: | ---: | ---: | ---: |
| Health | 1.517 | 1.583 | 1.650 | 1.717 |
| Damage | 1.133 | 1.147 | 1.160 | 1.173 |
| Speed | 1.044 | 1.049 | 1.053 | 1.058 |
| Ordinary health pressure | 2.094 | 2.189 | 2.283 | 2.378 |
| Ordinary damage pressure | 1.736 | 1.811 | 1.887 | 1.962 |
| Boss base health | 1694.444 | 1738.889 | 1783.333 | 1827.778 |
| Boss health multiplier | 4.644 | 4.689 | 4.733 | 4.778 |
| Boss damage | 1.944 | 1.989 | 2.033 | 2.078 |
| Boss cadence | 0.728 | 0.706 | 0.683 | 0.661 |
| Boss coverage | 1.272 | 1.294 | 1.317 | 1.339 |

The release target is 14–18 active minutes for a normal completed run in a comparable
built-Web natural-play cohort. If the median remains below 14 minutes, adjust quotas,
wave windows, and encounter composition first. Do not pad the run with more health.

### 2. Upgrade cards and offer policy

Add three cards, increasing the catalog from 25 cards/85 level states to 28 cards/94
level states. Increase combat slots from 4 to 7 and the total build rail from 17 to 20;
category capacities become `2/3/2/1/5/7` in their current category order.

1. **Miss Compensation**: treat every trigger pull and all Split Muzzle children as one
   `shot_group_id`. A group that retires without any hostile hit adds one stack. The next
   hostile-hit group gains +6/+8/+10% direct primary damage per stack, maximum four
   stacks (+24/+32/+40%), then consumes all stacks. Wall, range, and structure-only
   retirement count as a miss. Splash, status, facility, and structure damage do not
   receive the bonus.
2. **Hit Chain**: a shot group with any hostile hit adds one chain stack; a miss resets
   it. The next group gains +3/+4/+5% direct primary damage per stack, maximum eight
   stacks (+24/+32/+40%). Use the same group and damage exclusions as Miss Compensation.
3. **Braced Fire**: actual player displacement charges 1200/1000/800 world units. At full
   charge, remaining at speed ≤30 for 0.6 seconds starts a 4-second +15/+20/+25% bonus to
   direct player weapon damage. Speed >30 ends the buff. Charging pauses during the buff.
   Show a code-native 36×3 linear meter below the crosshair only while the card is owned.

Create `vehicle_primary_shot_outcome_runtime.gd` for group hit/miss retirement and stack
state, and `vehicle_braced_fire_runtime.gd` for displacement/settling/buff state. Keep
damage application in the outgoing-damage policy and expose only narrow run-orchestrator
calls. One group can satisfy both cards, but each card keeps independent stacks.

Offer construction uses this priority before ordinary diversity rules:

- If the build owns neither Active nor Secondary, every offer reserves one legal card
  from each category.
- If exactly one category is missing, every offer reserves one legal card from that
  category.
- After both have been acquired at least once, the reservation ends permanently for the
  run; stage-3+ attack-category guarantee and current diversity then apply.
- A full/ineligible category cannot consume a reserved slot; validation must prove the
  fallback still returns a complete legal offer.

### 3. Neutral facilities and pickups

Replace the current Anomaly Device concept with **Neutral Facility**. A facility is
non-hostile, gives no quota progress or XP, emits its field while intact, and ends its
field when destroyed. It has no destruction burst. Player and hostile direct, projectile,
beam, and area attacks can damage it; projectiles pass through without being consumed.
AI does not explicitly target facilities, but incidental hostile fire can destroy them.

Place exactly three facilities per stage: one Repair, one Barrier, and one rotating
hazard selected from Gravity, Cryo, and Weakpoint. Facility health is
`360 × stage health curve`, excluding the ordinary-enemy 2.6 multiplier. Fields do not
affect facilities. Same-kind fields do not stack; different kinds compose.

| Facility | Radius | Effect on player and hostiles while inside |
| --- | ---: | --- |
| Repair | 520 | Restore one-third maximum health per second; zero-to-full takes 3 seconds |
| Barrier | 520 | Restore barrier at one-third maximum health per second, capped at 100% maximum health |
| Gravity | 480 | Movement-only pull, acceleration 520 px/s² and added-speed cap 180; steering remains available |
| Cryo | 360 | Move speed ×0.35 and attack-start/cadence ×0.5; never cancel a committed or warned attack |
| Weakpoint | 420 | Incoming actor damage ×1.25 |

Fixed installations ignore movement-only Gravity/Cryo effects but can receive Repair,
Barrier, and Weakpoint. Bosses use the same semantic formulas. Delete all five repair
pickups from each stage. Keep the two experience-recall pickups and place one existing
value-3 XP shard at each former repair location, adding 15 authored XP and five visible
XP items per stage without a new pickup asset. Recalculate XP/shard-cap fixtures rather
than raising caps without evidence.

### 4. Ordinary enemies and pressure continuity

Add three general science-fiction roles:

- **Shield Vanguard**: frontal armor and a committed short charge; teaches flanking before
  the frontal-shield boss.
- **Volley Gunship**: fires a visible six-shot sustained burst while repositioning.
- **Pursuit Harrier**: rapidly closes distance and uses a short side burst to maintain
  visible pressure.

Every mobile support enemy must support a valid recipient or, after 0.75–1.0 seconds
without one, reposition and use a weak direct fallback attack. A fixed support
installation must actively support or attack. No spawned hostile may remain in a
behaviorally idle state merely because it has no current support recipient.

Pacing rules:

- If reserves remain and no live threat exists, admit the next due reserve within 0.25 s.
- If live enemies exist but no hostile is visible or in a meaningful committed attack for
  1.5 s, redirect up to the four closest mobile hostiles through existing approach lanes
  toward the live player anchor.
- Never teleport an enemy, bypass spawn/layout validity, or change authored counts.
- Acceptance per stage: first visible threat ≤4 s, first meaningful attack commitment
  ≤8 s, ordinary no-visible gap ≤3 s, and offscreen-live gap ≤3 s.

### 5. Boss shields, beams, and volleys

Add boss 6 **Bastion** for stage 12. It has a permanent 110° frontal shield that reduces
front-arc damage by 90% and accepts full side/rear damage. Its rotation is capped at
55°/s and its facing is frozen during committed attacks so flanking is readable and fair.
It does not use the current global shield node or four-second direct-attack shield drop.
Render only a body-attached, code-native frontal boundary.

Add boss 7 **Siege Array** for stage 14. It uses the existing timed global-shield family
and focuses on sustained multi-direction beams and long volleys. Move beam length, width,
count/directions, active duration, volley interval, and volley limit into boss-pattern
data. Preserve early bosses. Expand only stage 10 and the new late bosses:

- Beam startup ≥1.2 s and active duration 1.2–1.6 s.
- Beam length reaches the tactical wall, capped at 1400–1500; late widths are 104–112.
- Multi-direction beams must preserve at least one escape gap wider than the player
  diameter plus 80 px and must never close every exit.
- Sustained volleys use 8–10 shots at 0.18–0.20 s intervals.
- Telegraph geometry and damage geometry use the same data and transform.

### 6. Diagnostics and pacing evidence

Split the session recorder into a protected core buffer (capacity 128) and a detail
buffer (capacity 256). Core records are never dropped and include run/stage start/end plus
one per-stage summary containing duration, first-visible time, first-commit time, and
count/total/longest values for both empty-world and offscreen-live gaps. Detail drops keep
their explicit counter. Merge records by monotonic sequence during export. Keep the
current 20-session, 25 MB, 14-day store limits.

The recorder must remain diagnostic-only and bounded. It must not change AI decisions,
spawn timing, pause semantics, or run-clock semantics. The implementation checkpoint may
use the latest local run as discovery evidence, but final pacing acceptance requires new
built-Web sessions from the changed campaign.

### 7. Shared stacked report

Replace the terminal report's grid/tabs/nested-scroll structure with one left-aligned
vertical stack inside exactly one content `ScrollContainer`. Keep the terminal action
button outside that scroll. Use this order:

1. Run summary
2. Stage timeline
3. Enemy and elite defeats
4. Damage sources
5. Damage attributes
6. Action counters
7. Loadout/build
8. Reward
9. Diagnostic export/status

Reuse the same report-body component in terminal Result, Failure, and Settings → Ship
Status. Settings receives the current accumulated run snapshot and build; final-only
reward and terminal action remain owned by Result. Deployment may show an empty-state
version. Gameplay data stays in `vehicle_stage_report_builder.gd` and
`vehicle_run_result_builder.gd`; UI only formats and lays it out.

Acceptance covers Korean and English at 960×540, 1280×720, and 1920×1080 with 100% and
200% text scaling: one content scroll, no metric tabs, no independently scrolling
sections, no clipping/overflow, readable left alignment, and a reachable fixed action.
Update the UI validator so controls inside a `ScrollContainer` are not excluded from
overflow checks.

### 8. Visual asset contract

Add exactly ten production PNGs: three upgrade cards, three ordinary enemies, two bosses,
and two facilities (Repair and Barrier). Reuse the existing approved anomaly/device
visual identities for the three hazard facilities only after the workbench proves the
semantic mapping remains clear. The production manifest moves from 78 to 88 approved
assets.

Before any production integration, generate or author candidates with the canonical
style sheet as an actual reference input, record provenance, show AS-IS/TO-BE workbench
evidence, and obtain exact user approval for each promoted raster. The sheet is style
authority, not asset approval. Frontal shields, beams, facility fields, shot meters,
report chrome, and other dynamic cues remain code-native geometry and must be specified
in `VISUAL_SYSTEM.md` before implementation.

## Tasks and Milestones

The executor must update this plan's Progress section and send a compact user checkpoint
after each milestone because this plan has more than four top-level steps. Do not begin a
later milestone while its predecessor's explicit authority or validation gate is red.

### Milestone 0 — Lock product, data, and evidence contracts

- Update `vehicle_game_spec.md` and `VISUAL_SYSTEM.md` with the decisions above.
- Record exact new IDs, localization keys, catalog capacities, stage arrays, report schema,
  and diagnostic core/detail schema before runtime edits.
- Replace obsolete “ten-stage” and “mystery device” validator names/contracts with
  fourteen-stage and neutral-facility equivalents; do not retain misleading aliases.
- Baseline the exact clean commit, worktree state, viewport, renderer, VSync, warmup,
  duration, focus, machine state, actor/projectile/effect counts, and current native/Web
  qualification status before making performance claims.

**Exit:** specs and validators agree on 14 stages, 28 cards, five facility types, seven
bosses, the report schema, and protected diagnostic summaries.

### Milestone 1 — Visual workbench and approval gate

- Produce referenced candidates for ten new rasters and update the workbench provenance.
- Inspect at actual gameplay size in static and representative combat contexts.
- Run `validate_cardborne_visual_authority.ps1` and request exact user approval.
- Stop before production promotion if any asset lacks approval.

**Exit:** all ten semantic IDs have an approved raster and recorded provenance; no
unapproved candidate exists in production.

### Milestone 2 — Upgrades and offer integrity

- Implement shot-group receipts, both accuracy cards, Braced Fire, damage exclusions,
  meter state, resources, localization, guidebook, snapshots, and reports.
- Implement missing-Active/Secondary reservations and legal full-offer fallback.
- Add `validate_vehicle_primary_shot_outcomes.gd` and
  `validate_vehicle_braced_fire.gd`; extend upgrade, weapon, projectile, damage, offer,
  snapshot, and localization validators.

**Exit:** deterministic fixtures prove group semantics, stack caps/reset/consumption,
direct-damage-only bonuses, motion thresholds, and offer guarantees across eligible/full
category cases.

### Milestone 3 — Neutral facilities and XP flow

- Replace anomaly lifecycle/owners with the five facility policies.
- Apply effects symmetrically to the player and hostiles, including boss/fixed-actor
  exceptions; add barrier state and report signals where required.
- Allow all intended hostile attacks to damage facilities without projectile consumption.
- Remove repair pickups, place existing XP shards, and update progression/layout/capacity
  fixtures.
- Replace `validate_vehicle_mystery_device_runtime.gd` with
  `validate_vehicle_neutral_facilities.gd` and extend field, damage, boss, pickup, XP, and
  localization validation.

**Exit:** every facility formula, stacking rule, destruction rule, faction symmetry, and
pickup count passes deterministic tests.

### Milestone 4 — Enemies, four stages, pacing, and protected diagnostics

- Add the three ordinary roles, active support fallbacks, stages 11–14, exact difficulty
  arrays, pair compositions, guidebook content, and diagnostics summaries.
- Implement reserve expedite and approach-lane redirection in the existing scheduler
  boundary. Keep player input, collision, committed attacks, and fairness state on their
  current physics boundary.
- Replace `validate_vehicle_ten_stage_catalog.gd` with
  `validate_vehicle_fourteen_stage_catalog.gd`; extend enemy, stage continuity,
  difficulty, pacing, diagnostics, capacity, capture, and localization validators.

**Exit:** deterministic fixtures prove catalog counts and no-idle fallbacks; built-Web
natural-play evidence meets the per-stage visibility/commit/gap limits or records the
specific failing stage/owner for one bounded rework pass.

### Milestone 5 — Boss profiles and late-pattern expansion

- Implement Bastion's frontal-arc damage policy and facing constraints.
- Implement Siege Array and data-owned late beam/volley dimensions; upgrade stage-10 late
  patterns without altering early bosses.
- Validate telegraph/damage geometry identity, escape corridors, durations, projectile
  counts, shield ownership, boss exams, and facility interactions.

**Exit:** focused boss validators and built-Web manual checks prove readable flanking,
unavoidable-corridor prevention, sustained attacks, and complete Korean/English cues.

### Milestone 6 — One stacked report across terminal and Settings

- Build the shared report body and replace tabs, metric scrolls, and narrow build rail.
- Feed current accumulated snapshots to Settings → Ship Status.
- Keep final reward/action ownership in Result and support an empty Deployment state.
- Update report, result-builder, pause/settings, capture, accessibility, overflow, and
  localization validators.

**Exit:** all 12 locale/viewport/text-scale combinations pass automated bounds checks and
rendered review with exactly one report content scroll.

### Milestone 7 — Integration and release qualification

- Run focused owners first, then import, all relevant validators, Web export, and
  production-style built-Web interaction through the registered `codex` lane.
- Run the codebase quality audit for cross-module ownership, public snapshot/report
  contracts, obsolete owners, failure paths, and validator fidelity; make only small
  task-scoped corrections.
- From the exact clean checkpoint, run comparable native and built-Web performance gates.
  Preserve exact workload/counts and use precise labels: import, focused validator,
  visual budget, scenario validity, native release performance, and Web release
  performance.
- Complete a normal built-Web run cohort and report median active time plus stage gap
  summaries. If duration is short, adjust encounter composition/quota windows, not health.

**Exit:** the clean committed checkpoint passes functional, visual, localization,
duration, pacing, native, and Web gates, with retained evidence and no unapproved assets.

## Test Plan

### Focused validation

- Upgrade catalog/offers, primary shot groups, outgoing damage, primary projectile store,
  Braced Fire, build snapshots, and guidebook.
- Neutral facilities, field composition, hostile/player/facility damage, barrier/repair,
  pickup layout, XP math, shard capacity, bosses, and fixed actors.
- Fourteen-stage catalog, difficulty arrays, stage continuity, encounter pacing, enemy
  expansion/specialists, quota/boss transitions, diagnostics retention, and captures.
- Boss patterns/runtime/exams, frontal arc, beam escape gaps, volley counts, and warning
  geometry.
- Report/result builders, shared UI, pause/settings, localization completeness,
  accessibility scaling, overflow/clipping, and single-scroll ownership.

### Rendered and interaction validation

- Import through `./tools/godot.ps1 --path . --headless --import`.
- Export with `./tools/export_web.ps1`.
- Serve only through the port-guard registered `codex` lane; current discovery resolves
  the Web lane to port 13029, but resolve again at execution time.
- Check built Web in Korean and English at 960×540, 1280×720, and 1920×1080, at 100% and
  200% text scale. Cover combat cards/meters, all facilities, new enemies, both bosses,
  terminal Result, Failure, Settings Ship Status, and diagnostic export.
- Inspect new rasters at original detail and actual gameplay size. Run the visual-authority
  validator after spec, workbench, manifest, or production-asset changes.

### Performance and duration validation

- Do not run an authoritative scenario until the feature set is substantially complete,
  the worktree is clean, and unrelated Godot/browser/capture/build work is absent.
- Compare the same workload, viewport, renderer, VSync, warmup, sample duration, focus,
  instrumentation mode, and machine state. Reject contaminated or count-invalid samples.
- Preserve current actor/projectile/effect ceilings and committed attack activity.
- Use a three-run built-Web natural-play cohort for the 14–18 minute duration decision;
  report individual times, median, and per-stage gap summaries. Three runs are the minimum
  evidence, not a claim about population-wide balance.

## Rollback / Safety

- Commit each milestone separately and keep task-owned changes isolated from unrelated
  worktree edits. Never reset, clean, or stage unrelated changes.
- Visual candidate generation and production promotion are separate commits. Removing an
  unapproved candidate must not touch approved production assets.
- If a new subsystem fails, disable its catalog/stage reference in the same milestone
  branch rather than leaving partial runtime calls. Do not leave compatibility aliases
  for deleted anomaly/ten-stage concepts once replacement validation is green.
- Preserve diagnostic bundles and failed performance evidence with their eligibility
  reason. Never choose a shorter or luckier run as the release result.
- Stop and request a decision if the remaining solution requires weaker thresholds,
  reduced workload, native code, threads, a new dependency, engine changes, or a material
  visual/product theme change.

## Risks and Contingencies

| Risk | Detection | Bounded response |
| --- | --- | --- |
| Four extra stages still feel short | Built-Web cohort median <14 min | Increase encounter windows/quotas and role composition once; do not inflate health |
| More actors/facility queries regress physics | Comparable named subsystem timings fail | Profile the selected owner; reuse bounded queries/state only there; preserve counts and exact collision |
| Neutral facilities create unavoidable deaths | Gravity/Cryo and boss corridor fixtures fail | Reduce field overlap/layout adjacency or movement pull while retaining symmetric semantics |
| Accuracy cards double-count split shots | Shot-group deterministic fixtures fail | Fix group receipt/retirement owner; do not patch per-projectile damage ad hoc |
| Offer reservation starves diversity | Legal-offer matrix fails | Apply reservation first, then existing diversity; use explicit full/ineligible fallback |
| Frontal shield rotates too perfectly | Flank timing/manual boss exam fails | Lower turn cap or extend committed facing lock; do not weaken side/rear identity |
| Report remains unreadable at 200% | Bounds/capture review fails | Reflow sections and row wrapping inside the single scroll; do not restore tabs/nested scrolls |
| Detail diagnostics still crowd out pacing facts | Core-summary retention fixture fails | Protect core buffer and export merge order; keep store limits unchanged |
| Asset approval is incomplete | Workbench/provenance validator fails | Stop production integration at Milestone 1 |

## Anti-Rework Rules

- Decide IDs, formulas, capacities, report schema, and diagnostic schema in Milestone 0;
  later milestones may not silently rename or reinterpret them.
- Do not mix raster promotion with behavior/performance correction in one causal commit.
- Do not expand `VehicleRun` with card, facility, report-formatting, or diagnostic-storage
  policy; create or use the responsibility owner named above.
- A failed rendered or performance gate gets one bounded correction based on a named
  cause. Re-run only after a relevant change.
- If implementation evidence contradicts a formula or capacity here, update this plan's
  Decision Notes before changing code.

## Open Questions

None. Exact raster promotion remains a scheduled user-approval gate, not an unresolved
product decision.

## Decision Notes

- 2026-08-15: chose 14 stages rather than indefinite content growth because two new
  teaching/remix pairs add meaningful breadth while keeping the paired-run structure.
- 2026-08-15: defined three cards; the Active/Secondary bullet is an offer policy, not a
  fourth card.
- 2026-08-15: replaced anomaly destruction effects with persistent neutral fields so
  positioning, destruction, and faction symmetry become legible tactical choices.
- 2026-08-15: kept facility projectiles non-blocking to avoid accidental safe cover and
  retained incidental hostile destruction.
- 2026-08-15: selected one shared stacked report because the current grid, tabs, and
  nested scrolls fail small-screen and 200%-text readability.
- 2026-08-15: no saved-run migration is needed because repository evidence shows no
  mid-run serializer.
- 2026-08-15: duration is qualified by active built-Web play time; health inflation is
  explicitly excluded as the first correction.

## Progress

- [x] Discovery: inspected current specs, visual authority, stage/enemy/boss/card owners,
  report captures/owners, local diagnostics, validators, recent history, and performance
  policy.
- [x] Planning: converted feedback into exact product, data, UI, visual, validation, and
  stop contracts.
- [ ] Milestone 0 — Lock product, data, and evidence contracts.
- [ ] Milestone 1 — Visual workbench and approval gate.
- [ ] Milestone 2 — Upgrades and offer integrity.
- [ ] Milestone 3 — Neutral facilities and XP flow.
- [ ] Milestone 4 — Enemies, four stages, pacing, and protected diagnostics.
- [ ] Milestone 5 — Boss profiles and late-pattern expansion.
- [ ] Milestone 6 — One stacked report across terminal and Settings.
- [ ] Milestone 7 — Integration and release qualification.

## Next Steps

Start Milestone 0 in a clean task branch/checkpoint. Update the product and visual specs,
declare stable IDs and schemas, and add the failing contract validators before runtime or
asset promotion work. Then publish the first compact checkpoint and update this plan.

## Completion and Stop Conditions

Mark this plan complete only when all milestones and exit criteria are checked, the
fourteen-stage built-Web cohort meets duration and gap contracts, every new raster has
exact approval, and clean native/Web qualifications are recorded with precise labels.

Mark the work blocked only under the repository's blocked threshold and only when the
same external authority or environment condition has prevented meaningful progress for
three consecutive goal turns. Otherwise leave the plan active and record the next bounded
action.
