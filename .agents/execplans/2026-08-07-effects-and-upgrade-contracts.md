---
type: plan
status: active
owner: BK
created: 2026-08-07
last_reviewed: 2026-08-07
topic: Combat effect semantics and upgrade decision quality
scope: Effect event routing, state feedback, upgrade presentation, offer and application contracts, focused QA, and final Web verification
related:
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/design/cardborne-universal-art-style-reference.png
  - ../../docs/reports/game-system-review/index.html
  - ../semantic-v2-runtime-acceptance-evidence.md
  - ./2026-08-02-pre-asset-code-stabilization.md
---

# Effects and Upgrade Contracts

This is the decision-complete execution contract for the next Cardborne product
pass. It converts the user's prior effect and upgrade feedback into bounded code,
content, validation, and runtime-QA work. An executor should not need to invent a
new visual direction, progression system, card count, or asset family.

## Outcome

Complete the pass when all of the following are true:

1. every emitted visual event has one explicit presentation owner and only
   renderer-owned transient events enter the 96-state effect store;
2. barrier-only hits, Marked Salvo, and Phase Shear are distinguishable at live
   gameplay scale without new raster media or unrelated warning rings;
3. all 28 behavior-only upgrade definitions show a localized `New behavior` /
   `새 행동` comparison row without duplicating their description;
4. every reachable reward transaction produces exactly three unique legal cards,
   and the runtime rejects an upgrade outside the frozen current offer;
5. the 41-card, 83-level-state, built-in Seeker, two-optional-slot, five-secondary,
   mandatory-choice contract remains intact;
6. focused validators, representative native play QA, Web export, and built-Web
   smoke pass without text clipping or a new visual-asset dependency.

This plan does not declare the project performance-qualified. The native
peak/capacity pair and built-Web peak measurements remain owned by
`2026-08-02-pre-asset-code-stabilization.md`.

## Progress

- [x] 2026-08-07: recovered user feedback from prior sessions and reconciled it
  with current source, specifications, reports, and validators.
- [x] 2026-08-07: inspected the complete visual authority document and the
  canonical reference sheet at original detail.
- [x] 2026-08-07: audited the 39-event visual catalog, effect store, renderer,
  41 upgrade definitions, offer flow, card UI, localization, and validators.
- [x] 2026-08-07: removed stale decision pages and temporary visual artifacts
  from the active repository surface; updated the consolidated report.
- [ ] Phase 1: encode event, behavior-card, offer, and application invariants in
  focused validators.
- [ ] Phase 2: repair effect routing and the three missing state-feedback paths.
- [ ] Phase 3: repair upgrade presentation, catalog schema, offer, and apply
  boundaries.
- [ ] Phase 4: perform representative native and built-Web acceptance, update
  durable evidence, and close this plan.

## Authority and Evidence

The implementation must preserve this authority order:

1. `docs/product/vehicle_game_spec.md` owns the five-stage run and upgrade model.
2. `docs/design/VISUAL_SYSTEM.md` owns visual grammar and the media boundary.
3. `docs/design/cardborne-universal-art-style-reference.png` is the mandatory
   style reference, never an approved runtime asset.
4. gameplay state and collision code own live truth; presentation consumes it.

Visual-authority preflight recorded for this plan:

- document: `docs/design/VISUAL_SYSTEM.md`, read completely on 2026-08-07;
- sheet: `docs/design/cardborne-universal-art-style-reference.png`, inspected at
  original detail on 2026-08-07;
- observed and expected SHA-256:
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`;
- recorded generation provenance:
  `C:/Users/BK/.codex/generated_images/019fbfe9-857e-7453-b72d-20908d848577/exec-0b8aa606-cf55-45c1-abb3-fb3df762b080.png`,
  2026-08-02 12:13:44 KST;
- raster or ImageGen output in this plan: none;
- actual image-reference input for generated media: `not_applicable`.

Run `tools/validation/validate_cardborne_visual_authority.ps1` after any
player-facing presentation change and at final acceptance.

## User Feedback Converted to Decisions

| Feedback or observed problem | Locked decision | Work item |
| --- | --- | --- |
| The same result needs the same visual family; different results and player/enemy ownership must stay distinct. | Every visual-event entry names its consuming owner. Shared cues are reused only for the same semantic result; ownership remains in state color, placement, projectile identity, or attached target cue. | EFX-01, EFX-02, EFX-05 |
| Minor effect frames should be retired; EMP is the exceptional large effect. | Keep `effect/emp_release` as the only authored effect raster. Use current code-native batches, state tint, and existing semantic assets for all work in this plan. | EFX-02 through EFX-05 |
| Generic rings should not represent unrelated jobs; live areas must match gameplay truth. | Keep rings for true live radii such as barrier and Ion Field. Marked uses amber four-corner target brackets. Sheared uses mint split side-bars. Neither is a warning area. | EFX-03, EFX-04 |
| Upgrade cards should show meaningful behavior and current-to-next progression. | Numeric cards keep up to two current-to-next rows. Behavior-only cards show one localized `New behavior` comparison row and their existing behavior sentence once. | UPG-01, UPG-02 |
| Upgrade selection is mandatory. | Preserve three unique cards, no reroll, no decline, and the existing 0.35-second input guard. Never open a one- or two-card modal. | UPG-04, UPG-05 |
| Card art must not replace in-world effect feedback. | No upgrade artwork changes are part of this plan. Runtime behavior and live feedback remain separate owners. | All |
| Historical A/B/C effect sheets were not approvals. | Do not recreate or promote those sheets. Git history is sufficient recovery for the deleted reports. | Non-goal |
| Elaborate invented concepts such as an undefined overload/discharge taxonomy were unclear. | Add no new lore term or effect taxonomy. Catalog metadata describes implementation ownership only. | EFX-01 |

## Discovery Closure Gate

Discovery is closed for this plan. The following evidence resolves the material
questions that could otherwise force an executor to improvise:

| Question | Evidence | Closed decision |
| --- | --- | --- |
| Is new effect art required? | The current manifest has 71 authored gameplay PNGs, one authored effect, and no raster animation; the visual specification prohibits restoring small effect frames. | No new raster, atlas, animation, dependency, or ImageGen work. |
| Which event modes consume the transient store? | `VehicleCombatRenderer._sync_effects()` renders `hull_afterimage`, `live_emp_radius`, `authored_emp`, `floating_damage`, and `directed_transfer`; it skips `direct_feedback`, `suppressed`, and `hud_only`. | Add one catalog helper that is the sole buffer-eligibility authority and gate `VehicleRun._add_effect()` with it. |
| Does every direct-feedback event already have a visible owner? | Catalog validators count modes but do not prove a consumer. Barrier-only damage lacks a distinct pulse. Marked and sheared cues are trapped inside the repair-tender overlay branch. | Add explicit consumer metadata and fix the three demonstrated gaps before peak-pressure QA. |
| Are Marked and Sheared multi-target effects? | Applying either clears the previous target before setting the new one. | At most one marker of each kind is live. Reuse the renderer's small overlay batches; do not add a per-enemy node tree. |
| Is behavior-card artwork missing? | All 41 definitions have explicit `artwork_asset_id`; the gap is text routing. | Do not change art. Route existing behavior text into a labeled comparison row. |
| Why is the behavior row empty? | All 28 behavior definitions have no numeric modifiers and use the same summary and description key. The presenter emits a behavior key only when those keys differ. | For behavior-only cards, label and show `summary_key` in the comparison lane once; do not duplicate it in the footer. |
| Can the catalog return fewer than three cards? | `VehicleUpgradeCatalog.offer()` returns as many legal definitions as it finds and has no final size contract. The panel hides missing buttons. | Validate reachable states and guard the reward transaction before opening the modal. Duplicates and fabricated fallbacks are prohibited. |
| Is `exclusion_group` active design? | No current definition sets it and no catalog path reads it. | Remove the exported field and assert that no resource contains it before deletion. |
| Is the artwork fallback active? | Every current definition validates a non-empty artwork ID before presentation. | Delete `ARTWORK_BY_UPGRADE` and family fallbacks; a missing ID is a validation error, not a UI substitution. |
| Is full performance qualification part of this pass? | The active stabilization plan still requires final quiet native and built-Web measurements. | Run only task-relevant smoke and regression scenarios here. Preserve the separate final performance gate. |

No open design choice remains. If source evidence contradicts one of these facts
before implementation begins, stop this plan and update the authority document or
product specification before changing code.

## Scope Boundaries

### In scope

- visual-event ownership metadata, producer coverage, and buffer eligibility;
- the effect-store call boundary, without changing its 96-state capacity;
- barrier-only hit feedback and existing audio routing;
- Marked and Sheared target-attached code-native cues;
- removal of the orphan `bulkhead_destroy` event if the active product catalog
  still has no producer at implementation time;
- behavior-only card text routing and Korean/English label completeness;
- exact three-card offer and frozen-offer application invariants;
- removal of dead upgrade schema/presentation fallbacks;
- deterministic tests, native rendered QA, Web export, and built-Web smoke.

### Out of scope

- changing the five-stage campaign, encounter counts, bosses, controls, manual
  aim, primary fire, dash, passive Seeker, EMP, pickups, or quota gates;
- changing the 41-card catalog size, 83 level states, five secondary families,
  built-in Seeker, or two optional slots;
- adding rerolls, declines, shops, meta-progression, a new growth system, or
  additional reward sources;
- creating or editing PNG, SVG, atlas, sprite sheet, shader art, or font files;
- restoring retired minor effect frames or old A/B/C candidate directions;
- broad tuning of enemies, stages, bosses, hazards, or player movement;
- changing effect-store capacity or making a performance claim without the
  separate measurement plan.

## Implementation Map

The primary owners are:

- event definition and routing contract:
  `scripts/presentation/components/vehicle_visual_event_catalog.gd`;
- transient presentation storage: `scripts/combat/vehicle_effect_store.gd`;
- gameplay producers and player presentation snapshot:
  `scripts/vehicle/vehicle_run.gd`;
- batched world presentation:
  `scripts/presentation/vehicle_combat_renderer.gd`;
- capture groups:
  `scripts/presentation/components/vehicle_visual_event_capture_fixture.gd`;
- upgrade schema: `scripts/cards/vehicle_upgrade_definition.gd` and
  `scripts/cards/vehicle_stat_modifier.gd`;
- offer policy: `scripts/cards/vehicle_upgrade_catalog.gd`;
- build and behavior state: `scripts/cards/vehicle_run_build.gd`;
- immutable UI snapshot: `scripts/cards/vehicle_upgrade_offer_presenter.gd`;
- card and modal presentation: `scripts/ui/vehicle_upgrade_choice_card.gd` and
  `scripts/ui/vehicle_upgrade_choice_panel.gd`;
- bilingual strings: `localization/vehicle_stage.csv`.

Do not move upgrade behavior into UI code or draw gameplay geometry in collision
owners. `vehicle_run.gd` may expose state in a snapshot, but the combat renderer
owns the new visual geometry.

## Phase 1 — Encode the Contracts First

### EFX-01 — Make visual-event ownership executable

Change `VehicleVisualEventCatalog.EVENTS` so every entry has:

- `mode`: current rendering strategy;
- `consumer`: one of `renderer`, `player_state`, `enemy_state`, `world_state`,
  `hud`, or `audio_state`;
- `buffered`: `true` only for the five renderer-consumed mode families listed in
  the Discovery Closure Gate.

Add `descriptor(kind)`, `is_known(kind)`, and `is_buffered(kind)` helpers. Keep
the catalog as data; do not add drawing behavior to it.

Update `validate_vehicle_visual_replacement_coverage.gd` and
`vehicle_visual_event_capture_fixture.gd` to validate required keys rather than
brittle total counts. Scan `_add_effect(&"...")` producers and fail when an
emitted ID is absent. Fail when a non-HUD catalog entry has neither a producer
nor an explicit state-owner exemption.

Remove `bulkhead_destroy` from the catalog, fixture, and expected IDs if the
active world catalog still has no breakable-bulkhead producer. Do not retain it
as historical inventory.

Acceptance:

- an unknown event fails validation with its ID;
- every catalog event has exactly one allowed consumer;
- `direct_feedback`, `suppressed`, and `hud_only` cannot be buffered;
- the only authored-effect asset ID remains `effect/emp_release`.

### UPG-01 — Add failing behavior-card and offer tests

Extend `validate_vehicle_upgrade_system.gd` to discover, rather than hard-code,
all definitions with `behavior_ids` and no modifiers. Assert the current set is
28 until a product-spec revision changes it. For each level and locale, require
the snapshot to expose `change_kind=behavior`, a non-empty label key, and a
non-empty behavior text key.

Build near-exhaustion fixtures for each reward `source_tag`, each optional-slot
count, every element branch prerequisite, and each first-stage family rule.
Enumerate all build states reachable through the fixture transitions until the
offer set repeats or all upgrades are capped. Every non-terminal reward state
must return exactly three unique compatible definitions.

Extend `validate_vehicle_upgrade_ui.gd` so all 28 behavior-only definitions run
through compact, standard, and large card profiles at the existing 960, 1280,
and 1920 viewport matrix.

### UPG-02 — Add catalog-schema tests

Before changing production code, add assertions that:

- duplicate resource IDs are reported before dictionary insertion can hide one;
- families and source tags belong to explicit allowed sets;
- `secondary_slot_kind` is empty, `built_in`, or `optional`, and matches family;
- modifier operation is `add` or `multiply` and every stat ID belongs to the
  `VehicleRunBuild` stat contract;
- requirements resolve, do not self-reference, and do not form a cycle;
- no `.tres` file sets `exclusion_group`;
- every definition has a semantic artwork ID resolved by the asset provider.

Stop Phase 1 when these new checks fail only for the known implementation gaps.
Do not weaken assertions to make the baseline green.

## Phase 2 — Repair Effect Routing and Feedback

### EFX-02 — Gate the effect store at one boundary

Preload `VehicleVisualEventCatalog` in `vehicle_run.gd`. In `_add_effect()`, reject
unknown IDs with an error visible to tests, return immediately for known
non-buffered IDs, and call `effect_store.add()` only when `is_buffered(kind)` is
true. Keep producers intact during this step so state feedback and event audit
remain independently testable.

Extend `validate_vehicle_effect_store.gd` with a mixed burst containing more than
96 non-buffered events around one authored EMP and one dash afterimage. Assert
that non-buffered events cause zero acquisitions or evictions and cannot retire
the renderer-owned entries. Keep `MAX_LIVE_EFFECTS=96` and the pool allocation
strategy unchanged.

### EFX-03 — Add barrier-only hit feedback

Add `player_barrier_hit_flash` next to `player_hit_flash` in `vehicle_run.gd`.
Set it whenever `absorbed > 0`, decay it in the existing presentation-timer
block, reset it with run state, and publish its remaining duration in
`_runtime_combat_presentation_snapshot()`.

In `VehicleCombatRenderer._sync_world_overlays()`, render the pulse by briefly
increasing brightness and thickness/scale of the existing 61-unit barrier
outline. Use the same mint barrier language; do not create a second radius or a
warning ring. If full absorption depletes barrier strength to zero, the flash
snapshot keeps the outline visible only for the short hit duration.

Route a barrier-hit sound through the existing audio director using an existing
short system-hit timbre. Do not reuse the hull-hit cue and do not add an audio
file. Hull flash, hull shake, hull invulnerability, and camera behavior remain
unchanged for fully absorbed damage.

Extend `validate_vehicle_damage_feedback.gd` and
`validate_vehicle_combat_renderer.gd` for partial absorption, full absorption,
full depletion, and spill-through damage.

### EFX-04 — Give Marked and Sheared distinct target cues

Remove `_draw_enemy_marks()` from the `VehicleRun` overlay path after equivalent
renderer ownership is in place. In `VehicleCombatRenderer`, consume
`enemy.marked_time` and `enemy.shear_time` while syncing the enemy overlay:

- Marked Salvo: four amber corner brackets attached just outside the target's
  visual radius. Reuse `_sync_target_brackets()` or factor a color-parameterized
  helper; do not use the vulnerable crosshair or a ring.
- Phase Shear: two mint split side-bars, one on each lateral side of the target,
  made with the existing batched beam primitive; do not use a ring or diamond.

Both cues follow the target, remain inside the enemy overlay budget, and use no
new nodes per frame. Their maximum simultaneous count is one each under the
current gameplay state contract.

Extend `validate_vehicle_status_stacking.gd` and renderer snapshots to prove
visibility, distinct batch output, expiry, target transfer, and coexistence.

### EFX-05 — Verify the remaining direct-feedback owners

Create one validator table covering all catalog entries whose consumer is not
`renderer`. For each event, point to an observable state field, HUD transaction,
audio state, projectile removal, actor tint, health change, or world-state
transition. A comment is not sufficient evidence.

Use the existing capture groups to inspect representative player, secondary,
enemy, boss, pickup, and transit events at actual gameplay scale. If an event's
result is already unambiguous through its owning state, keep it suppressed. If
it is not, add the smallest code-native owner-specific cue and update the table;
do not create a new asset or a generic burst.

Commit Phase 2 only after all effect-focused validators pass. This is the first
rollback point.

## Phase 3 — Repair Upgrade Decisions and Boundaries

### UPG-03 — Render behavior-only cards as behavior choices

Add one localization key to `localization/vehicle_stage.csv`:

- Korean: `새 행동`;
- English: `New behavior`.

In `VehicleUpgradeOfferPresenter.snapshot()`, emit a normalized change payload:

- numeric definitions: `change_kind=stats`, current `effect_rows`, summary in
  the footer;
- behavior-only definitions: `change_kind=behavior`, localized label key, and
  the next-level `summary_key` as the behavior text;
- hybrid definitions, if introduced by a later approved spec: stats in the
  comparison lane and a separate non-duplicate behavior key in the footer.

In `VehicleUpgradeChoiceCard`, render behavior-only payloads in the existing
comparison lane. Show the label and sentence once, hide the duplicate footer,
preserve one body artwork, and add no scroll container. Update accessible text
to read family, title, level transition, `New behavior`, and the sentence.

Run localization completeness and the full upgrade geometry matrix. Any clip,
ellipsis that removes the behavior outcome, or child outside its card bounds is
a failure.

### UPG-04 — Guarantee the three-card reward transaction

Keep `VehicleUpgradeCatalog.offer()` deterministic. After normal branch and
family ordering, require exactly three unique compatible definitions. It may not
duplicate a card, ignore a requirement, exceed optional slots, or fabricate a
fallback from another source tag.

At the `VehicleRun` reward-opening boundary, validate the result before freezing
`current_card_offer` and before opening `VehicleUpgradeChoicePanel`. If the
result is not exactly three, keep simulation paused in the existing reward
transaction, log the source tag, seed, serial, build levels, and eligible count,
and surface the failure to the validator/debug snapshot. Do not consume the
reward, silently resume play, or open an incomplete modal.

The exhaustive Phase 1 fixture must show that this failure path is unreachable
for the shipped five-stage run. Its purpose is to prevent silent corruption if
future content changes violate the invariant.

### UPG-05 — Enforce the frozen offer at application

In `VehicleRun.apply_upgrade()`, accept an ID only when a reward transaction is
active and the ID exists in the exact frozen `current_card_offer`. Reject empty,
unknown, compatible-but-unoffered, already-maxed, and stale IDs without mutating
the build, reward serial, cycle state, or modal state.

After a valid application, keep the existing mandatory close and cycle sync.
Extend `validate_vehicle_upgrade_system.gd` with valid selection, unoffered
selection, double-submit, and stale-submit cases.

### UPG-06 — Remove dead schema and artwork fallback

After UPG-02 is green:

- remove `exclusion_group` from `VehicleUpgradeDefinition`;
- delete `ARTWORK_BY_UPGRADE` and family fallback branches from
  `VehicleUpgradeOfferPresenter.artwork_asset_id()`;
- return the definition's explicit `artwork_asset_id` only;
- retain validation as the failure owner for a missing or unresolved asset.

Do not rename card IDs, behavior IDs, families, stats, or localization keys as
part of this cleanup.

### UPG-07 — Verify decision quality without broad retuning

Add deterministic micro-scenarios for these shipped build packages:

1. primary damage/cycle/projectile-speed;
2. built-in Seeker damage/cycle;
3. each optional secondary family: Ion Field, Orbit Blades, Wake Mines, Escort
   Drone;
4. Thermal, Toxin, and Cryo branches;
5. dash behaviors including Coolant Wake, Ion Wake, Phase Shear, and Ram Pulse;
6. barrier/defense and EMP packages;
7. movement, hull, and pickup utility.

For each card level, assert that the advertised stat value or named behavior is
observed and differs from the previous level. Numeric-only levels must change
their owned effective measure by at least 8 percent, except additive utility
stats whose exact displayed delta is the acceptance value. Do not alter numbers
merely to meet a global DPS target. Record any card that passes mechanics but
still feels weak in play as a separate tuning proposal with scenario evidence;
do not expand this contract into speculative balance work.

Commit Phase 3 only after upgrade, UI, localization, secondary, status, and
asset-provider validators pass. This is the second rollback point.

## Phase 4 — Acceptance and Handoff

### Targeted automated checks

Run while implementing:

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_effect_store.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_visual_replacement_coverage.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_combat_renderer.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_damage_feedback.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_status_stacking.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_secondary_weapons.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_upgrade_system.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_upgrade_ui.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_ui_localization.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_semantic_asset_provider.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_visual_asset_coverage.gd
```

After the implementation stabilizes, run the broader task boundary once:

```powershell
.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_attack_contract.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_attack_route_readability.gd
.\tools\validation\validate_cardborne_visual_authority.ps1
.\tools\design\build_visual_replacement_workbench.ps1 -Check
.\tools\validation\validate_visual_replacement_workbench.ps1
.\tools\export_web.ps1
git diff --check
```

Do not repeatedly run the broad set after cosmetic edits. Rerun only the
affected focused validator until the next material boundary.

### Native rendered QA

Use the fastrun manager's `codex` lane before starting any server or interactive
runtime. Inspect Korean and English at 960x540, 1280x720, and 1920x1080.

Required scenarios:

- barrier partially absorbs a hit;
- barrier fully absorbs and remains active;
- barrier depletes on the hit;
- damage spills through to hull;
- Marked and Sheared appear separately, transfer targets, coexist, and expire;
- EMP charge and release remain aligned to their actual radii;
- a peak-pressure player/secondary/enemy group remains ownership-readable;
- one numeric card and every behavior-only card fit all three layout profiles;
- a reward always opens with three unique cards and rejects keyboard/controller
  double-submit during the input guard.

Reject the pass for clipped text, a cue that reads as an attack warning when it
is only a status, player/enemy ownership ambiguity, a new generic effect family,
or any visual geometry that disagrees with gameplay state.

### Built-Web smoke

After `tools/export_web.ps1`, use the built output, not the editor-only runtime.
Verify boot, one combat encounter, barrier feedback, Marked/Sheared, one numeric
upgrade, one behavior upgrade, Korean/English switching, keyboard/controller
selection, and return to play. Record the exact build commit and evidence path
in `.agents/semantic-v2-runtime-acceptance-evidence.md`.

This smoke validates functional parity only. It does not replace the quiet
built-Web peak measurement in the active performance plan.

## Commit and Validation Cadence

Use coherent task-owned commits:

1. `test: lock effect and upgrade contracts` — Phase 1 validators only;
2. `fix: align combat feedback ownership` — Phase 2 runtime plus tests;
3. `fix: enforce upgrade decision contracts` — Phase 3 runtime, UI,
   localization, and tests;
4. `docs: record effects and upgrade acceptance` — evidence, report status, and
   plan closure.

Do not stage unrelated user changes. Inspect `git status --short` before and
after every commit. If an implementation step needs more than the named owners,
record why in this plan before expanding scope.

## Stop Conditions

Stop and request a product decision instead of improvising when any of these
conditions occurs:

- a fix requires a new raster, shader, font, audio file, or external dependency;
- exactly three legal cards cannot be reached without changing card count,
  source rules, optional slots, or the mandatory-choice model;
- a behavior-card sentence cannot fit without removing required information or
  changing the approved responsive card contract;
- state cues require a new warning category, lore term, or gameplay-area change;
- a deterministic micro-scenario proves that an existing product specification
  and runtime behavior disagree;
- performance validation needs a threshold, capacity, workload, or policy change.

Ordinary implementation bugs, failing tests, or small owner-local refactors are
not stop conditions.

## Completion and Durable Handoff

Before setting `status: done`:

- check every Progress item;
- record exact commits and validation results below;
- update `docs/reports/game-system-review/index.html` from planned to applied;
- append durable runtime evidence to
  `.agents/semantic-v2-runtime-acceptance-evidence.md`;
- move any product-level decisions into `vehicle_game_spec.md` or
  `VISUAL_SYSTEM.md` if they are not already present;
- then delete this completed plan in a separate documentation-lifecycle commit,
  because Git history and the authority documents become the recovery record.

### Implementation record

Not started. Record phase commits, validation dates, rendered-evidence paths,
and any plan amendments here during execution.
