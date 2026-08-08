---
type: plan
status: active
created: 2026-08-08
scope: Selected B gameplay HUD, essential-only notifications, actor-attached health, upgrade-card readability, and doubled enemy durability and field repair
related:
  - ../../AGENTS.md
  - ../PLANS.md
  - ../design/DESIGN.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/product/vehicle_upgrade_catalog.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/design/visual-replacement-workbench/previews/hud-overlay-options/left-top-overlay-three-directions.png
  - ./2026-08-02-pre-asset-code-stabilization.md
  - ./2026-08-07-combat-feedback-and-reinforcement-facility.md
---

# Combat Readability and Signal Cleanup - Execution Contract

Implement the user-selected B HUD as a high, panel-free top overlay; reduce combat
messages to six essential signals beneath the center health strip; move boss and
damageable-world-object health into the world; remove the upgrade-card plus icon and
double its description type; and double current enemy health and player field-repair
amounts. The current source owners, responsive states, localization surface, renderer
batch, balance composition, and validation commands have been verified. This contract
is ready to execute without further product or design choices.

## Purpose

- Objective: expose only information that changes an immediate combat decision while
  giving more of the map back to the player.
- Deliverable: the selected B HUD and notification policy, actor-attached health bars,
  readable upgrade descriptions without the unlock plus, the requested health and
  repair tuning, synchronized Korean/English copy, and focused plus production-style
  evidence.
- Completion state: all task checkboxes and named gates pass, authoritative specs match
  runtime behavior, the Web release exports, the result is visually reviewed at all
  supported viewport classes, and this plan is marked `done`.

## Scope and Boundaries

In scope:

- Replace the top-left mission panel with B: `STAGE`/`스테이지`, large current-stage
  fraction, `DEFEATED`/`처치`, and large defeated/quota fraction.
- Remove the edge-HUD objective prose, objective detail, experience rail, target panel,
  boss panel, and their now-unused snapshots, timers, and localization.
- Keep only the six notifications locked below and place them directly below the
  top-center health and acquired-upgrade stack.
- Remove the redundant stage-transition banner while preserving stage progression,
  full heal, 1.2-second protection, audio, and timing.
- Show boss health and damageable-world-object health above the owning world actor.
- Remove the upgrade-card unlock plus/diamond and make description copy primary white,
  twice the current normal-profile size, and capable of two lines.
- Double the current final ordinary and boss health multipliers and double player field
  repair pickup and crate amounts.
- Update Korean/English localization, product/design contracts, debug contracts,
  focused validators, and rendered evidence.

Out of scope:

- New raster art, production-asset promotion, minimap redesign, player health-strip
  redesign, acquired-upgrade rail redesign, or EMP action-rail redesign.
- Enemy count, quota, active cap, speed, damage, attack cadence, AI, boss pattern,
  projectile, experience, drop count, or reward-quality changes.
- Stage-transition full heal, Hull Integrity's immediate `+15` heal, barrier recovery,
  enemy Repair Tender/Generator healing, or Mystery Device outcome changes.
- A generic notification framework rewrite, new dependencies, engine changes, or
  unrelated UI cleanup.
- Reopening the completed combat-feedback plan. Its old edge-HUD contract is superseded
  only where this plan explicitly names a replacement.

Constraints and invariants:

- Preserve the connected five-stage run, manual aim, held primary fire, dash, passive
  secondaries, EMP, authored encounters, map pickups, mandatory card choice, and
  quota-gated boss flow.
- Korean and English remain complete. Runtime labels use localization keys; numeric
  fractions remain locale-neutral.
- HUD B uses no enclosing panel, progress bar, rail, border, or icon. Its data is
  `stage_number / 5` and `defeated / quota`; it does not show the stage title.
- HUD and toast placement use the 8-pixel top datum. The toast must not move down when
  the taller B stack changes height.
- World health uses the existing `Overlay_health` retained batch. Do not add one node or
  draw-call owner per actor, and retain the ordinary-enemy cap of 12 bars.
- UI visuals remain aligned with `docs/design/VISUAL_SYSTEM.md` and the canonical sheet;
  the selected mockup is direction evidence, not a shippable asset.
- Work in coherent task-scoped commits without staging or reverting unrelated changes.
- Coordinate presentation-snapshot edits with the active frame-pacing plan: reuse
  buffers after warm-up and do not reintroduce per-frame nested snapshot allocation.

Destructive or irreversible actions:

- Delete only the obsolete stage-transition-banner script and UID after all runtime,
  UI API, spec, and validator references are removed. Git preserves recovery.
- Delete only localization rows proven to have no remaining consumer after the new HUD
  and notification policy land.
- No irreversible external action, asset promotion, dependency mutation, or saved-data
  migration is authorized.

Exact actions requiring owner or user approval:

- Before the broad final Korean/English viewport and Web evidence pass, report its
  scope, expected run time, and stop condition and obtain user alignment as required by
  repository policy. No product choice remains at that pause.
- Any change to the locked six-message whitelist, balance interpretation, responsive
  sizes, world-health visibility policy, or named out-of-scope behavior requires a plan
  update and user approval before implementation continues.

## Locked Product Decisions

### B HUD and top-edge geometry

| Profile | Viewport rule | Left margin | Label type | Fraction type | Top | Approximate footprint |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Compact | width `< 1100` | 16 px | 15 px | 30 px | 8 px | 100-112 px high |
| Standard | width `1100-1599` | 24 px | 16 px | 32 px | 8 px | 108-116 px high |
| Large | width `>= 1600` | 32 px | 18 px | 40 px | 8 px | 116-124 px high |

- Stack order is label, value, 8-pixel group gap, label, value. Label-to-value gap is
  4 pixels. Text is left aligned and uses existing primary/system roles with sufficient
  contrast over the world.
- The top-center health/acquired-upgrade stack and top-right minimap also move to an
  8-pixel top datum. Their internal design and sizes do not change.
- The normal toast is 320 x 36 in compact and 360 x 40 in standard/large. Its vertical
  position is `8 + center_status_height + 4`; it is never derived from the left HUD
  height. The existing 720 x 80 accessibility toast remains available.

### Essential notification whitelist

Only these gameplay producers may call the transient top-center message surface:

1. `NOTIFY_REINFORCEMENT_FACILITY`: an extra hostile spawn source became active.
2. `NOTIFY_REINFORCEMENT_FACILITY_DESTROYED`: that spawn source stopped.
3. `NOTIFY_BOSS_INBOUND`: the encounter changed to boss arrival.
4. `NOTIFY_BARRIER_DEPLETED`: a survival layer was lost.
5. `NOTIFY_MYSTERY_DEVICE_RESULT`: a deliberately hidden device result was revealed.
6. `BOSS_SHIELD_DOWN_HINT`: the four-second focus-fire window opened.

Remove transient calls and dead rows for contact inbound, deployed, module online,
stage reset/arrival, calibration complete, repair amount, experience recall, level up,
hull disabled, boss shield up, boss shard collection, and boss-practice start. The
level-up modal, failure flow, world/radar cues, health changes, acquired-upgrade rail,
and effects remain the owning feedback. The notification queue remains generic and
bounded, but only the whitelist may enqueue during gameplay.

### World-attached health policy

- Stage boss: always show one larger backed bar above the visible boss body. Use the
  boss-command fill role and do not duplicate it at any screen edge.
- Reinforcement Facility: keep its always-visible bar above the facility while active.
- Mystery Device and reward crate: show a bar above the object for 1.5 seconds after
  accepted damage. Do not show an idle permanent bar, because that would replace one
  map-occlusion problem with many smaller ones.
- Ordinary enemies: preserve current priority/aim/recent-hit/startup visibility and the
  deterministic maximum of 12 simultaneous ordinary bars.
- Count boss, facility, device, and crate bars separately in the renderer debug
  contract. The batch has two instances per visible bar: backing and fill.

### Upgrade-card description and icon policy

- Delete `UnlockIndicator`, its center container, visual debug contract, and plus/
  diamond geometry. Preserve first-acquisition semantics in the card's accessible name
  through the existing localized change label; numeric plus signs in stat values stay.
- Description color is `Art.TEXT_PRIMARY`, never `Art.TEXT_MUTED`.
- Description sizes are exactly 32 px compact, 34 px standard, and 36 px large. The
  200% accessibility profile resolves to at least 40 px through its existing scaling
  path. Every profile permits two lines with smart word wrap.
- Card sizes become 280 x 410 compact, 360 x 488 standard, and 420 x 512 large. The
  panel row heights match. The 520 x 920 accessibility card and vertical-scroll
  behavior remain. Never shrink the locked description type to fix overflow.

### Balance interpretation

- `ORDINARY_HEALTH_MULTIPLIER` changes from `1.30` to `2.60`, and
  `BOSS_HEALTH_MULTIPLIER` changes from `1.30` to `2.60`. This doubles current final
  health after the authored base, stage curve, encounter multiplier, and fixed Hard
  profile; it is not a replacement with `2.00`.
- Loose and crate field repairs change from 25 to 50 HP; the one 20 HP crate changes to
  40 HP; the defensive fallback changes from 35 to 70 HP. The exact stage field-repair
  budget changes from 245 to 490 HP.
- Pickup and crate counts, placement, drop identity, full-heal transitions, Hull
  Integrity `+15`, and enemy support healing remain unchanged.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Selected top-left direction | `VehicleGameplayHud` owns a 260 x 76 mission panel with objective detail, boss cluster, and XP rail | `scripts/ui/vehicle_gameplay_hud.gd`; selected B column in the related mockup | Replace it with the panel-free B geometry and numeric stage/quota snapshot above | 1.1, 1.2, 1.5 |
| Message amount and position | `VehicleRun` has 17 notification producers; toast Y currently uses `max(mission_size, center_size)` | `scripts/vehicle/vehicle_run.gd`; `scripts/ui/vehicle_gameplay_hud.gd` | Keep the exact six-message whitelist and anchor the toast only to center status | 1.2, 1.3, 1.5 |
| Redundant stage message | `VehicleStageTransitionBanner` shows a non-modal 1.6-second stage banner during automatic progression | `scripts/ui/vehicle_stage_transition_banner.gd`; `vehicle_game_spec.md` | Remove the banner and UI API, preserving gameplay timing/protection/audio | 1.4 |
| Boss and structure health | Renderer omits boss from its ordinary-bar candidates, shows the facility in world, and has device health without max health; crates own health/max/flash in `VehicleRun` | `scripts/presentation/vehicle_combat_renderer.gd`; device/facility runtimes; crate dictionaries | Add boss/device/crate bars to the existing retained overlay batch with the locked visibility rules | 2.1-2.3 |
| Upgrade plus and description | Card draws a 22-pixel diamond plus; summary is muted and 16/17/18 px with one line | `scripts/ui/vehicle_upgrade_choice_card.gd`; `vehicle_upgrade_catalog.md` | Remove the visual indicator, use primary 32/34/36 px two-line summary, and update card/row sizes | 3.1-3.3 |
| Enemy durability | Ordinary and boss final multipliers are each `1.30` | `scripts/enemies/vehicle_stage_difficulty.gd`; `vehicle_game_spec.md` | Change each to `2.60` so current final health doubles | 4.1, 4.3 |
| Player field recovery | Four loose 25 HP repairs and crate repairs of five 25 plus one 20 total 245; fallback is 35 | `scripts/vehicle/vehicle_field_layout_generator.gd`; `_collect_pickup` | Change to 50/40, total 490, fallback 70; no other healing changes | 4.2, 4.3 |
| Responsive and bilingual proof | Existing validators cover ko/en, 960 x 540, 1280 x 720, 1920 x 1080, all 34 card states, and 200% text | `validate_vehicle_stage_ui_layout.gd`; `validate_vehicle_upgrade_ui.gd` | Extend those contracts and add rendered review before one final import/Web export | 5.1-5.4 |
| Performance ownership | Active stabilization plan owns reusable HUD/presentation staging and bounded batches | `2026-08-02-pre-asset-code-stabilization.md`; current runtime buffers | Extend existing reusable frames and overlay batch; no per-frame node/dictionary growth | 1.1, 2.1-2.3, 5.2 |

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership, safety, and
  validation decision is closed.
- Godot 4.7.1 is available through `./tools/godot.ps1`; all named validators are
  SceneTree scripts using the verified `--path . --headless --script res://...` form;
  `./tools/export_web.ps1` is the repository release export path.
- No repository-owned production start script exists. The strongest safe substitute is
  the native rendered capture/review plus the release Web export and output-file check.
- Remaining unknowns are implementation-local and cannot change this contract.

## Proposed Design and Ownership

The HUD presenter publishes only stable numeric combat state. `VehicleGameplayHud`
owns layout and transient messages; it does not reconstruct gameplay policy. The
combat renderer owns all world-attached bars and consumes reused snapshots supplied by
the run and structure runtimes. Upgrade-card presentation changes remain inside the
card and its parent row; card behavior and offer rules do not move into UI. Balance
constants remain in the existing difficulty and field-layout owners. Product and
visual specs are updated in the same implementation so no stale competing contract
survives.

## Tasks

### Phase 1: Selected B HUD and essential signal surface

Goal: ship one small, high top HUD whose only persistent left-edge content is stage and
defeat progress, with six essential messages below the center status stack.

Preconditions:

- Preserve the selected B direction; do not generate another mockup.
- Preserve center player health, acquired upgrades, minimap, threat radar, and EMP rail.

Source owners: `scripts/ui/vehicle_gameplay_hud.gd`,
`scripts/ui/vehicle_hud_presenter.gd`, `scripts/vehicle/vehicle_run.gd`,
`scripts/ui/vehicle_stage_ui.gd`, `localization/vehicle_stage.csv`

- [ ] **1.1** Publish the B HUD's minimal numeric snapshot.
  - Change: replace objective/title/target/boss fast clusters with `stage_number`,
    `stage_total`, `defeated`, and `quota`; remove obsolete reusable target/boss frames
    and state-text helpers after proving no remaining consumer.
  - Accept: presenter and run validators prove `2 / 5` and `86 / 168`-style values,
    update only when source values change, and expose no edge target/boss snapshot.
  - Guard: keep the active performance plan's staged snapshot cadence and reuse.
- [ ] **1.2** Implement B at the locked top-edge geometry.
  - Change: replace the mission panel with four localized labels in the locked compact,
    standard, and large sizes; remove objective detail timer, mission XP rail, target
    panel, and boss cluster; align all three top zones to Y=8.
  - Accept: debug geometry shows no enclosing surface/bar/icon, correct type sizes and
    margins at 960/1280/1920 widths, and no overlap with center or minimap zones.
- [ ] **1.3** Enforce the notification whitelist and independent center anchor.
  - Change: retain only the six producers, delete retired calls/rows, resize the normal
    toast, and calculate its Y from the center stack only.
  - Accept: a source-level validator asserts the exact whitelist and absence of every
    retired producer; runtime geometry keeps the toast within 4 pixels below center
    status regardless of B height; both locales fit without clipping.
- [ ] **1.4** Retire the redundant stage-transition banner.
  - Change: remove show/hide calls and UI API, then delete
    `vehicle_stage_transition_banner.gd` and its UID; keep automatic progression, full
    heal, audio, next-encounter start, and 1.2-second protection unchanged.
  - Accept: stage-transition and run validators pass with no banner symbol/path/key,
    and stages 1-4 still advance automatically while stage 5 reaches results.
- [ ] **1.5** Synchronize authoritative HUD and message contracts.
  - Change: update `vehicle_game_spec.md`, `VISUAL_SYSTEM.md`, localization, and any
    focused debug/validation contracts; remove obsolete objective and boss-status rows
    only when `rg` proves zero consumers.
  - Accept: product and visual docs name B, the six-message whitelist, the center toast
    anchor, and no stage banner or edge boss/target health; localization validator
    reports complete Korean and English surfaces.

Batch gate:

- `validate_vehicle_hud_presenter.gd`, `validate_vehicle_stage_ui_layout.gd`,
  `validate_vehicle_stage_transition.gd`, `validate_vehicle_ui_localization.gd`, and
  `validate_vehicle_run.gd` pass together after all Phase 1 tasks.

### Phase 2: Actor-attached boss and damageable-object health

Goal: health ownership is spatially obvious without filling the map with permanent
labels or returning boss/target bars to screen edges.

Preconditions:

- Phase 1 batch gate passes.
- Use only the existing health overlay batch and reusable runtime presentation frames.

Source owners: `scripts/presentation/vehicle_combat_renderer.gd`,
`scripts/vehicle/vehicle_run.gd`, `scripts/vehicle/vehicle_mystery_device_runtime.gd`,
`scripts/vehicle/vehicle_reinforcement_facility_runtime.gd`

- [ ] **2.1** Add the always-visible boss world bar.
  - Change: route active visible `stage_boss` directly to a boss-sized variant of the
    existing backed bar and track it separately from ordinary candidates.
  - Accept: boss bar is above the boss, uses boss-command fill, reflects current/max
    health and phase damage, consumes two retained instances, and never consumes one of
    the 12 ordinary slots.
- [ ] **2.2** Add recent-damage Mystery Device and reward-crate bars.
  - Change: expose device `max_health` plus a 1.5-second accepted-hit visibility timer;
    add the same timer to crate state; fill a reusable crate overlay buffer in the
    existing presentation snapshot; draw backed bars above intact, visible objects only
    while their timers are positive.
  - Accept: accepted player direct/area damage opens or refreshes the bar for exactly
    1.5 seconds, rejected hostile/environment damage does not, health ratios are exact,
    and destroyed/retired objects stop drawing immediately.
- [ ] **2.3** Bound and verify the combined overlay batch.
  - Change: preserve facility behavior and ordinary selection, expose separate debug
    counts, and set a fixed batch capacity for 12 ordinary + 1 boss + 1 facility + 3
    devices + 8 crates, two instances each, with no runtime growth after warm-up.
  - Accept: renderer and performance-scenario validators observe the exact cap and no
    allocation/batch regression; the visual spec names the same ownership policy.

Batch gate:

- `validate_vehicle_combat_renderer.gd`,
  `validate_vehicle_mystery_device_runtime.gd`,
  `validate_vehicle_reinforcement_facility.gd`,
  `validate_vehicle_map_mechanics_integration.gd`, and
  `validate_vehicle_performance_scenarios.gd` pass together.

### Phase 3: Readable upgrade-card descriptions

Goal: every upgrade card explains itself in large primary text with no unexplained plus
icon and without losing keyboard, gamepad, localization, or scroll behavior.

Preconditions:

- Phase 2 batch gate passes.
- Do not change card definitions, actual effect values, category membership, offer
  legality, selection guard, or confirmation flow.

Source owners: `scripts/ui/vehicle_upgrade_choice_card.gd`,
`scripts/ui/vehicle_upgrade_choice_panel.gd`, `docs/product/vehicle_upgrade_catalog.md`,
`docs/design/VISUAL_SYSTEM.md`

- [ ] **3.1** Remove the visual unlock indicator completely.
  - Change: delete its class, container, field, visibility logic, body-order/debug
    claims, and drawn geometry; retain the localized change label in accessibility text.
  - Accept: no `UnlockIndicator`/unlock-icon node or plus/diamond draw command remains;
    first-acquisition cards stay distinguishable to assistive output.
- [ ] **3.2** Apply the locked summary typography and geometry.
  - Change: use primary color, 32/34/36 px type, two-line smart wrap, locked card sizes,
    matching panel-row heights, and preserved 520 x 920 accessibility scrolling.
  - Accept: debug contracts report exact sizes/color/line limits and no card, line,
    control, selection cue, or confirm control clips or overflows.
- [ ] **3.3** Update the full bilingual card matrix and authoritative contracts.
  - Change: replace the catalog and visual-system one-line/muted/unlock-icon language;
    update validators for all 34 card/level states, selected/unselected states, ko/en,
    960 x 540, 1280 x 720, 1920 x 1080, and 200% text.
  - Accept: both upgrade validators and layout validator pass the complete matrix; no
    executor may shorten copy or reduce the locked font sizes to make a case pass.

Batch gate:

- `validate_vehicle_upgrade_ui.gd`, `validate_vehicle_upgrade_system.gd`,
  `validate_vehicle_rewards_ui_audio.gd`, and
  `validate_vehicle_stage_ui_layout.gd` pass together.

### Phase 4: Doubled enemy durability and field repair

Goal: apply the requested twofold durability and recovery change once, at the existing
final composition points, without collateral combat or reward changes.

Preconditions:

- Phase 3 batch gate passes.
- Preserve the fixed Hard profile and all stage curves; change only the named final
  multipliers and repair amounts.

Source owners: `scripts/enemies/vehicle_stage_difficulty.gd`,
`scripts/vehicle/vehicle_field_layout_generator.gd`,
`scripts/vehicle/vehicle_run.gd`, relevant capture fixtures,
`docs/product/vehicle_game_spec.md`

- [ ] **4.1** Double current ordinary and boss health.
  - Change: set both final multipliers to `2.60` and update expected composed values in
    run, boss, difficulty, capture, and encounter validators.
  - Accept: every ordinary and boss case is exactly twice current final health at the
    same stage/profile; damage, speed, quota, count, cap, and pattern expectations do
    not change.
- [ ] **4.2** Double player field-repair amounts.
  - Change: set field layout repair amounts to 50/40, fallback to 70, capture fixtures
    to the same values, and expected stage budget to 490.
  - Accept: generation produces four loose 50 HP repairs plus crate repairs totaling
    290 HP for an exact 490 HP stage budget; pickup clamping still stops at max hull;
    counts, placement, drop types, full heal, Hull Integrity, and enemy healing stay
    unchanged.
- [ ] **4.3** Synchronize product balance and regression contracts.
  - Change: update the game spec and focused assertions; explicitly retain the out-of-
    scope healing and difficulty behavior.
  - Accept: `rg` finds no stale 1.30 final multiplier, 245 budget, 25/20 field repair,
    or 35 fallback contract in active product/runtime/validator owners.

Batch gate:

- `validate_vehicle_run.gd`, `validate_vehicle_run_difficulty.gd`,
  `validate_vehicle_field_layout_generation.gd`,
  `validate_vehicle_boss_patterns.gd`, `validate_vehicle_boss_runtime.gd`,
  `validate_vehicle_pickup_contact.gd`, and
  `validate_vehicle_run_capture_driver.gd` pass together.

### Phase 5: Integrated visual, localization, performance, and release proof

Goal: prove the complete change in native rendering and the production export without
repeated broad runs or stale evidence.

Preconditions:

- Phases 1-4 and their batch gates pass.
- Before this broad pass, report purpose, scope, expected cost, and stop condition to
  the user and obtain alignment.

Source owners: focused validators, capture driver, `tools/export_web.ps1`, this plan

- [ ] **5.1** Run the complete named focused-validator set once.
  - Change: execute the exact final validator batch below and save concise pass/fail
    evidence in this plan's progress notes.
  - Accept: every script exits 0; a failure is rerun only after a relevant change or a
    new testable hypothesis.
- [ ] **5.2** Review native rendered evidence.
  - Change: capture representative gameplay HUD, boss/facility/device/crate health, and
    upgrade-card states in ko/en at 960 x 540, 1280 x 720, and 1920 x 1080; include one
    200% text case. Inspect actual pixels, not debug contracts alone.
  - Accept: top HUD and toast do not cover one another or the minimap; toast remains
    high; no retired message or edge health panel appears; bars track their actors;
    white card descriptions are legible and unclipped; focus/selection remains clear.
- [ ] **5.3** Run import and one clean release Web export.
  - Change: run the exact commands below once after rendered QA passes.
  - Accept: import exits 0; export reports `WEB_EXPORT_OK`; `index.html`, `index.js`,
    `index.pck`, and `index.wasm` exist under `build/web`.
- [ ] **5.4** Close documentation, evidence, and commits.
  - Change: run visual-authority validation and `git diff --check`; record authority
    evidence, final commands, known non-blocking warnings, and task-scoped commit IDs;
    mark all tasks complete and frontmatter `done` only after every gate passes.
  - Accept: no stale active contract or unexplained worktree change remains, the
    selected B mockup remains direction-only, and the implementation commit contains
    only task-owned files.

## Test Plan and Exact Commands

Run one validator with:

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_hud_presenter.gd
if ($LASTEXITCODE -ne 0) { throw 'validator failed: validate_vehicle_hud_presenter.gd' }
```

Final named batch:

```powershell
$validators = @(
  'validate_vehicle_hud_presenter.gd',
  'validate_vehicle_stage_ui_layout.gd',
  'validate_vehicle_stage_transition.gd',
  'validate_vehicle_ui_localization.gd',
  'validate_vehicle_run.gd',
  'validate_vehicle_combat_renderer.gd',
  'validate_vehicle_mystery_device_runtime.gd',
  'validate_vehicle_reinforcement_facility.gd',
  'validate_vehicle_map_mechanics_integration.gd',
  'validate_vehicle_performance_scenarios.gd',
  'validate_vehicle_upgrade_ui.gd',
  'validate_vehicle_upgrade_system.gd',
  'validate_vehicle_rewards_ui_audio.gd',
  'validate_vehicle_run_difficulty.gd',
  'validate_vehicle_field_layout_generation.gd',
  'validate_vehicle_boss_patterns.gd',
  'validate_vehicle_boss_runtime.gd',
  'validate_vehicle_pickup_contact.gd',
  'validate_vehicle_run_capture_driver.gd'
)
foreach ($validator in $validators) {
  .\tools\godot.ps1 --path . --headless --script "res://tools/validation/$validator"
  if ($LASTEXITCODE -ne 0) { throw "validator failed: $validator" }
}
```

Representative native capture form; use a task-owned absolute output directory and
repeat only for the locked locale/viewport cases selected in Task 5.2:

```powershell
.\tools\godot.ps1 --path . --rendering-method gl_compatibility --resolution 1280x720 -- `
  --capture-all=D:/npjt/cardborne-platformer/build/qa/combat-readability/ko-1280x720 `
  --capture-locale=ko --capture-size=1280x720
if ($LASTEXITCODE -ne 0) { throw 'native rendered capture failed' }
```

Release gate:

```powershell
.\tools\godot.ps1 --path . --headless --import
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed' }
.\tools\export_web.ps1 -SkipImport
if ($LASTEXITCODE -ne 0) { throw 'Web export failed' }
.\tools\validation\validate_cardborne_visual_authority.ps1
if ($LASTEXITCODE -ne 0) { throw 'visual authority validation failed' }
git diff --check
if ($LASTEXITCODE -ne 0) { throw 'git diff check failed' }
```

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | One owning SceneTree validator using the verified command form | A task's code and direct assertions are ready | That task's relevant input changes |
| Phase gate | The exact named batch under the phase | All task-level acceptance checks in that phase pass | A phase-owned code, spec, localization, or test input changes |
| Render gate | Locked ko/en representative capture and pixel review | All implementation phase gates pass and user aligns on broad validation | A visible HUD/card/world-health input changes |
| Final gate | Final 19-validator batch, import, Web export, visual-authority validator, `git diff --check` | Render gate passes | A final-gate input changes |

Validation rules:

- Run the narrowest check that proves the current task.
- Run each phase gate once after its owned tasks pass.
- Do not run the full card/locale/viewport matrix during individual layout edits; use
  one representative compact case until Phase 3 is stable.
- Do not run native capture, Web export, or the final batch again for documentation-only
  progress edits after their implementation inputs are unchanged.
- Record a known non-blocking warning once. A new error, parse failure, timeout, clipping
  case, or changed pixel is blocking until explained or corrected.
- Stop a failing broad batch at the first failure, repair the owner with its narrow test,
  then resume the batch from that validator once.

## Visual Authority Evidence

- Text authority: `docs/design/VISUAL_SYSTEM.md`, read completely on 2026-08-08.
- Canonical visual reference:
  `docs/design/cardborne-universal-art-style-reference.png`, inspected at original
  detail on 2026-08-08.
- Expected and observed SHA-256:
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- Original generation provenance:
  `C:/Users/BK/.codex/generated_images/019fbfe9-857e-7453-b72d-20908d848577/exec-0b8aa606-cf55-45c1-abb3-fb3df762b080.png`,
  timestamp `2026-08-02 12:13:44 KST`.
- Direction evidence: the related three-direction mockup was generated with the
  canonical PNG supplied as an actual referenced image. The user selected B. The image
  controls direction only; it is not production asset approval and will not be copied
  into runtime.
- This plan creates no new raster output. Final promotion state is `code-native visual
  implementation pending`; Task 5.4 records validator and rendered-review results.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A verified material fact contradicts this contract | Stop the affected branch, update this contract, and obtain required approval before resuming | Do not let the executor choose a new product, design, balance, ownership, dependency, or validation contract |
| Locked description type clips at a supported size | Reallocate the card's internal vertical lane and use the already-locked card/row heights and accessibility scroll | Do not reduce 32/34/36 px type, return to one line, shorten localized copy, or expand beyond supported viewport bounds |
| World bars exceed batch capacity | Correct count accounting or fixed preallocation inside the exact 50-instance ceiling | Do not add nodes, unbounded arrays, runtime growth, or remove ordinary-bar guarantees |
| B or toast overlaps at a supported viewport | Correct anchors/margins inside the locked responsive table | Do not add a background panel, move messages below the left stack, or redesign center/minimap content |
| A retired localization key has another live consumer | Keep that row and remove only the obsolete producer/UI path | Do not break another user-facing surface to satisfy source cleanup |
| Current-HEAD validator fails for an unrelated pre-existing reason | Record the exact failure and confirm it against the pre-task commit; repair only if it blocks this task and the correction is small and safe | Otherwise stop the affected gate and request scope expansion instead of absorbing unrelated work |
| A task-owned server or capture process remains after evidence collection | Close only the positively identified task-owned process and verify its port/process is gone | Never kill by process name alone |

Implementation-local discoveries may be handled inside the locked contract when they
cannot change scope, visible behavior, ownership, architecture, safety, or acceptance.

## Assumptions, Risks, and Open Questions

Assumptions:

- “Enemy health x2” means twice the current final value, therefore `1.30 -> 2.60`.
- “Recovery x2” means player field repair pickups and repair-crate contents, not full
  heals, upgrade grants, barriers, or enemy healing.
- “Destructible terrain” maps to current damageable non-enemy world objects: the
  Reinforcement Facility, Mystery Device, and reward crate. The terrain runtime itself
  has no damageable-health object.

Risks and fixed mitigations:

- Double health can lengthen stages. Keep quota/count/pacing unchanged for this request;
  measure the result but do not silently retune damage or spawns.
- Large card copy can overflow compact layouts. The locked increased card/row heights,
  removal of the 22-pixel indicator lane, two-line limit, and existing accessibility
  scroll are the only allowed layout response.
- Extra world bars can increase overlay work. Fixed retained capacity and separate
  counts prevent runtime growth.
- Removing messages can hide state. The six-message whitelist is chosen only for
  otherwise-hidden or immediately actionable transitions; all removed cases retain an
  owning modal, effect, radar cue, health change, or failure/result surface.

Open questions: none.

## Rollback and Safety

- Each phase is a coherent scoped commit. Revert by phase commit if a later user test
  rejects one slice; do not hard-reset or revert unrelated work.
- The deleted banner script and localization rows remain recoverable from Git.
- No save format, dependency, external service, asset promotion, database, or user data
  changes are involved.
- Build output under `build/` is generated evidence and is not a production source
  owner unless existing repository policy explicitly tracks it.

## Decision Notes

- 2026-08-08: The user selected HUD direction B.
- 2026-08-08: Messages remain top-center, directly below player health/acquired
  upgrades, and are independent of the left HUD's height.
- 2026-08-08: The user required removal of most messages and tighter top attachment;
  the whitelist and 8-pixel datum above close those decisions.
- 2026-08-08: The current source audit found no health-bearing destructible terrain in
  `VehicleTerrainRuntime`; the current damageable non-enemy objects are facility,
  Mystery Device, and reward crate.
- 2026-08-08: The selected mockup remains direction evidence only. No new raster asset
  is required for implementation.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 1 - Selected B HUD and essential signal surface.
- Next task: 1.1 - Publish the B HUD's minimal numeric snapshot.
- Last completed gate: Discovery Closure Gate.
- Update rule: after a checkpoint passes, record concise evidence, check the task, and
  advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check passes.
- Every guard, phase gate, render gate, and final gate named by this contract passes.
- No placeholder, stale competing contract, retired notification producer, edge boss/
  target health panel, unlock plus icon, or unresolved material decision remains.
- Durable product, visual, localization, run, and verify knowledge is recorded in its
  owning file.
- Frontmatter status is changed to `done` only after implementation is complete.

Replan when:

- A material discovery invalidates a locked product, UX, balance, ownership,
  performance, safety, or validation decision.

Do not replan or stop for:

- Implementation-local mechanics already contained by this contract.
- A passing check whose relevant inputs have not changed.
