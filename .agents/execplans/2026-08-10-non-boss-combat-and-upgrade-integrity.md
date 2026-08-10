---
type: plan
status: active
owner: BK
created: 2026-08-10
last_reviewed: 2026-08-10
topic: Non-boss upgrade truth, contact damage, reinforcement recurrence, balance evidence, and final qualification
scope: Upgrade-card progression copy and values, ordinary melee contact reliability, reinforcement-facility recurrence proof, locked enemy balance verification, carried non-boss visual evidence, and release qualification
supersedes: ./2026-08-10-combat-correction-and-boss-pattern-expansion.md
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/product/vehicle_upgrade_catalog.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/design/cardborne-universal-art-style-reference.png
  - ../design/DESIGN.md
  - ../cardborne-performance-engineering-policy.md
  - ../cardborne-runtime-architecture-audit.md
  - ../../docs/design/visual-replacement-workbench/candidates/emp-magnetic-flux-v2/candidate-metadata.json
---

# Non-Boss Combat and Upgrade Integrity - Execution Contract

The completed non-boss work remains in production. This contract finishes the newly
verified progression and contact defects, proves the already-authored reinforcement and
balance behavior, carries the still-required non-boss capture/export gates, and qualifies
the resulting workload. Boss attack-pattern work and every decision about the final EMP
image are explicitly excluded. The current production EMP remains unchanged, and the
`emp-magnetic-flux-v2` candidate remains unapproved, non-production evidence.

## Purpose

- Objective: make every upgrade offer state truthful, make intended melee contact damage
  reliable during normal movement, prove reinforcement recurrence, and verify rather than
  silently retune the accepted enemy health and damage curves.
- Deliverable: gameplay-owned upgrade preview data, level-aware Korean/English card copy,
  a bounded swept-contact runtime, focused deterministic validators, rendered UI/combat
  evidence, a production Web artifact, and precise performance qualification.
- Completion state: all task and phase gates pass; no EMP or boss-pattern byte changes;
  the plan is then marked `done` and removed only after its durable decisions have been
  incorporated into their owning product/design sources.

## Why and Current Context

- The 13-card catalog has 36 offer states. Six behavior cards have empty `modifiers`, so
  `VehicleUpgradeOfferPresenter.snapshot()` publishes zero effect rows even though their
  gameplay values change: Split Muzzle, Piercing Rounds, Homing Missiles, Electric Field,
  Orbiting Blades, and Drop Mines.
- The UI validator currently counts the always-visible level row as a value row. It
  therefore passes cards with zero actual effect rows.
- The first Homing Missiles offer is currently classified as an unlock even though Seeker
  is already equipped at one missile and 25 damage. Optional secondaries genuinely unlock
  at level one. Element cards need different enhancement summaries after acquisition.
- The accepted ordinary health curve, final ordinary/boss health multipliers, and ordinary
  outgoing-damage multiplier are already implemented and validated. Increasing them again
  would hide the separate contact-detection defect and compound balance without evidence.
- The reinforcement facility already advances on elapsed time and can spawn repeatedly,
  but its validator proves only the first spawn and capacity blocking. It does not prove a
  second interval, a freed child/global slot, or the run integration's `carrier_id` count.
- Player movement is updated before enemies. Chaser and Rammer contact checks compare only
  the final positions of an active step; Bulkhead Guard and Splitter Barge check contact
  only on their scheduled decision path. Relative movement can cross between those checks,
  so visible overlap often causes no damage.
- Current HEAD `3eea8434` passes the upgrade-system, upgrade-UI, reinforcement-facility,
  and run-difficulty validators. `validate_vehicle_damage_feedback.gd` has one pre-existing,
  unrelated world-layout-dependent crate-warning assertion failure. No current-HEAD native
  or Web release-performance result is qualified.

## Scope and Boundaries

In scope:

- The six missing behavior-card value previews and level-aware element summaries.
- Correct unlock/enhance semantics for built-in and optional weapon upgrades.
- Product-spec reconciliation with the binding card order: category, title, artwork,
  level, one or two effect rows, then a maximum two-line summary.
- Exact relative swept-circle contact for intended ordinary melee roles.
- Repeated reinforcement-facility lifecycle and run-integration validation.
- Verification of the accepted ordinary health curve
  `[0.85, 1.00, 1.15, 1.30, 1.45]`, final ordinary and boss health multipliers `2.60`,
  ordinary damage multiplier `1.755`, and damage stage curve
  `[1.00, 1.03, 1.06, 1.09, 1.12]`.
- The previously outstanding non-boss rendered capture, Web export, manual hitch trace,
  and controlled native/Web performance qualification after feature code stops changing.

Out of scope:

- Selecting, revising, rejecting, approving, promoting, or switching the final EMP image.
  Do not edit the EMP candidate metadata, raster, comparison, production manifest, effect
  catalog, renderer, or runtime as part of this contract.
- Boss attack patterns, boss contact rules, boss damage, boss health, boss shielding, or
  boss visual work.
- New enemy roles, new reinforcement roles, changed spawn intervals/caps, more actor or
  projectile capacity, changed XP values, new cards, or a save-data migration.
- Further enemy-stat increases before the contact correction and final evidence are
  complete. Any later balance change requires a separate user decision.
- New authored raster/SVG assets, new UI chrome, horizontal separators, status icons,
  floating damage numbers, or additional HUD instrumentation.
- A generic performance rewrite, threads, GDExtension, engine changes, dependencies, or
  hidden reductions to workload, cadence, collision accuracy, or quality.

Constraints and invariants:

- Godot `4.7.1-stable`, GDScript, current stores/caps, fixed Hard run, manual aim, dash,
  current one-second hull invulnerability, barriers, and all accepted combat values remain.
- UI consumes a frozen gameplay-owned snapshot. It does not calculate upgrade mechanics.
- `VehicleStatModifier` remains reserved for stats that `VehicleRunBuild.stat()` actually
  applies. Behavior-only preview rows must not be modeled as fake modifiers.
- Cards show one or two real effect rows in every legal offer state, use no horizontal
  separator, and fit Korean/English at 960x540, 1280x720, 1920x1080, and 200% text scale.
- Contact correctness is fairness-critical and remains on the 60 Hz physics boundary.
  The implementation may scan the already-built bounded active-enemy worklist once, but it
  may not allocate, query the spatial grid once per enemy, or add per-contact nodes/events.
- Gameplay damage resolution remains independent from visual feedback.

Destructive or irreversible actions:

- None. Generated build, capture, and performance outputs remain under ignored `build/`
  paths. Every source change lands in a coherent task-owned commit.

Exact actions requiring owner or user approval:

- Before the two 60-second native performance scenarios or the user-driven manual trace,
  state their duration, foreground/window impact, stopping condition, and required quiet
  machine state, then obtain user alignment. Do not infer that this plan-writing request
  authorizes those expensive runs.
- No visual approval is requested by this contract. EMP approval remains outside it.

## Assumptions

- The current production EMP and all already-approved production imagery remain byte-identical.
- The six missing card rows are a presentation-boundary defect, not authorization to change
  their gameplay values.
- Reinforcement recurrence code is expected to be correct; tests determine whether any
  production correction is necessary. Do not rewrite a passing lifecycle.
- Ordinary health and damage values are accepted constants. Perceived weakness is
  re-evaluated only after contact hit opportunities are fixed.
- The pre-existing crate-warning validator failure is a fixture-isolation defect unless a
  focused investigation proves a gameplay mismatch; the plan repairs the oracle without
  changing crate collision or warning geometry.

## Domain Alignment

The upgrade domain uses these context-local terms:

- `unlock`: the first acquisition creates a previously absent behavior. This applies to
  Split Muzzle, Piercing Rounds, the three optional secondaries, and the three elements.
- `enhance`: the offer improves a behavior the player already owns. Homing Missiles is
  `enhance` from its first offer because Seeker is built in; every behavior card is
  `enhance` after its first level.
- `stats`: a card whose `VehicleStatModifier` values are directly composed by
  `VehicleRunBuild.stat()`.
- `effect preview`: one or two localized, gameplay-owned current/next value rows. It is
  presentation data and never a second gameplay calculation.

`VehicleUpgradeDefinition` owns the first-offer meaning through existing category,
modifier, and `secondary_slot_kind` facts. The presenter selects a frozen summary and
preview; the card only renders it. No separate glossary or new domain artifact is needed;
the durable behavior belongs in `vehicle_game_spec.md` and `vehicle_upgrade_catalog.md`.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Active plan lifecycle | The prior active plan mixes completed non-boss work with deferred boss work and open qualification gates. | `.agents/execplans/2026-08-10-combat-correction-and-boss-pattern-expansion.md` | Supersede it, preserve it as history, and make this the only active contract. | 0.1, 4.4 |
| EMP uncertainty | Candidate metadata says `awaiting_exact_user_approval` and `production_applied: false`; the user does not find it clearly better. | `docs/design/visual-replacement-workbench/candidates/emp-magnetic-flux-v2/candidate-metadata.json` | Leave candidate and production EMP untouched; no EMP task or approval gate exists here. | All |
| Missing card values | Presenter builds rows only from `definition.modifiers`; six behavior cards have none. | `scripts/cards/vehicle_upgrade_offer_presenter.gd:15`, `data/cards/vehicle/*.tres` | Add a gameplay-owned behavior-preview boundary; never add fake runtime modifiers. | 1.1-1.3 |
| Upgrade source truth | Split/Pierce values live in `VehicleRun`; Seeker upgrades are hardcoded in secondary runtime; optional secondary values live in `.tres` definitions. | `scripts/vehicle/vehicle_run.gd:1575`, `scripts/player/vehicle_secondary_runtime.gd:205`, `data/weapons/vehicle/secondary/*.tres` | Centralize primary rules and secondary definition loading, then make both runtime and previews consume them. | 1.1 |
| Card semantics and layout | Built-in Seeker is misclassified; element copy is static. Runtime already renders level, effect rows, then summary with zero dividers, while product prose lists summary before values. | `scripts/cards/vehicle_upgrade_offer_presenter.gd:30`, `scripts/ui/vehicle_upgrade_choice_card.gd:243`, `docs/product/vehicle_game_spec.md:550`, `docs/design/VISUAL_SYSTEM.md` | Correct change-kind semantics, add enhancement summaries, and reconcile product prose to the binding visual order. | 0.1, 1.2-1.4 |
| Enemy health and damage | Accepted curves and multipliers are already in source and focused tests. | `scripts/enemies/vehicle_stage_difficulty.gd`, `scripts/encounters/vehicle_encounter_director.gd`, `tools/validation/validate_vehicle_run_difficulty.gd` | Preserve all values; rerun exact effective-value checks after contact changes and report them plainly. | 3.2 |
| Reinforcement recurrence | Runtime resets its interval after each accepted spawn and retains zero while capacity-blocked; current test stops after first spawn/cap checks. | `scripts/vehicle/vehicle_reinforcement_facility_runtime.gd:45`, `tools/validation/validate_vehicle_reinforcement_facility.gd:20` | Extend lifecycle and run-integration tests; change production only if those exact tests expose a defect. | 3.1 |
| Missing player contact damage | Player and enemy endpoints are checked at different cadences; there is no relative swept contact owner. | `scripts/vehicle/vehicle_run.gd:1423`, `:2628`, `:2967`, `:3021`; `scripts/enemies/vehicle_enemy_update_schedule.gd` | Add one fixed-cap 60 Hz contact runtime using relative swept circles and explicit role semantics; remove legacy endpoint/decision-only checks. | 2.1-2.4 |
| Hit protection semantics | `_damage_player()` returns no receipt; one-shot attacks commit before an invulnerability rejection. | `scripts/vehicle/vehicle_run.gd:4169`, `tools/validation/validate_vehicle_damage_feedback.gd` | Return accepted/not-accepted while preserving every caller; barrier absorption is accepted, invulnerability rejection is not. One-shot attacks remain consumed; persistent hull contact retries while overlap remains. | 2.1-2.4 |
| Hot-path risk | Current runtime already has a bounded active worklist and reusable state; current HEAD lacks qualified release evidence. | `.agents/cardborne-performance-engineering-policy.md`, `.agents/cardborne-runtime-architecture-audit.md`, `scripts/vehicle/vehicle_run.gd:2016` | Reuse the active worklist, add no per-frame allocations, measure the named contact section, and compare clean before/after scenarios without changing workload. | 0.3, 2.2-2.4, 4.3 |
| Validation baseline | Four focused validators pass; damage feedback has one unrelated crate-warning failure on clean `3eea8434`. | Commands and output recorded during 2026-08-10 discovery | Isolate the crate fixture before using that validator as a gate; never report the current failing script as passed. | 0.2 |
| Visual authority | Current visual spec was read completely; canonical sheet inspected at 1448x1086 with SHA-256 `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`. | `docs/design/VISUAL_SYSTEM.md`, canonical PNG | This plan adds no asset. UI changes reuse current Theme/components and require rendered evidence plus the authority validator. | 1.4, 4.1-4.2 |

Readiness statement:

- Every material product, architecture, data, UX, ownership, safety, and validation
  decision is closed for this scope.
- Required tools are present: PowerShell, `tools/godot.ps1`, Godot 4.7.1, focused
  validators, capture driver, Web exporter, and performance recorder.
- Remaining unknowns are implementation-local. Any evidence that requires a new balance
  value, role rule, asset, dependency, or performance owner triggers the change-control
  rules below instead of an executor guess.

## Proposed Design

### Upgrade preview ownership and exact rows

Create `scripts/player/vehicle_primary_upgrade_rules.gd` as the source for Split Muzzle
shot composition and Piercing Rounds count. `VehicleRun._fire_primary()` and the preview
boundary consume the same functions. Create `scripts/player/vehicle_secondary_catalog.gd`
as the sole loader/query boundary for secondary definitions. Expand `seeker.tres` to the
already-shipped three runtime states (base, L1, L2), and remove the duplicate Seeker arrays
from `VehicleSecondaryRuntime`.

Create `scripts/cards/vehicle_upgrade_effect_preview.gd` to compose at most two rows from
those gameplay owners or existing real modifiers. It owns label/unit selection but not
mechanics. The locked row matrix is:

| Card | Row 1 | Row 2 | Current/next sequence |
| --- | --- | --- | --- |
| Split Muzzle | Projectiles per volley | Total volley damage | `1->2->3`; `100%->140%->165%` |
| Piercing Rounds | Additional penetrations | none | `0->1->2->3` |
| Homing Missiles | Missiles per volley | Damage per missile | `1->2->3`; `25->28->32` |
| Electric Field | DPS | Radius | first acquisition shows `8`, `120`; then `8->12->16`, `120->140->160` |
| Orbiting Blades | Blade count | Damage per blade | first acquisition shows `2`, `14`; then `2->3->4`, `14->18->22` |
| Drop Mines | Damage | Deployment interval | first acquisition shows `48`, `3.2s`; then `48->60->72`, `3.2->2.8->2.4s` |

Optional-secondary first acquisition and first element acquisition hide an inapplicable
current value rather than showing a false zero. Split/Pierce compare against the true base
primary state, and built-in Seeker compares against its true base state.

Add optional `enhance_description_key` to `VehicleUpgradeDefinition`; the presenter picks
it after acquisition while the UI renders only the snapshot. Keep the current first-level
element summaries and add these enhancement summaries:

| Element | Korean | English |
| --- | --- | --- |
| Thermal Burst | `폭발 피해·범위 증가` | `Stronger, wider burst` |
| Bio Toxin | `중독 피해·지속 증가` | `Stronger, longer toxin` |
| Cryo Slow | `감속·지속 증가` | `Stronger, longer chill` |

All new row labels and summaries are complete in Korean and English. The card keeps exactly
one artwork, zero horizontal/body dividers, and the existing shared component hierarchy.

### Ordinary melee contact semantics

Add `scripts/enemies/vehicle_enemy_contact_runtime.gd`. At the start of the existing enemy
status/activation scan, save each active enemy's physics-start position in a fixed field.
After all scheduled and Mystery forced motion, advance the contact runtime once over the
already-built active list. For each eligible role, solve the relative segment
`(player_from - enemy_from) -> (player_to - enemy_to)` against a circle centered at zero
with the exact combined contact radius and authored padding.

| Enemy/state | Contact rule | Repeat rule |
| --- | --- | --- |
| Chaser, including Scrap Drone, during warned `active` lunge | Swept contact only during the committed active step | Set `hit_committed` before damage; at most once per lunge, even if dash/hit protection rejects damage |
| Rammer during warned `active` charge | Same relative sweep using Rammer padding | At most once per charge, same rejection semantics |
| Collective `execute` charge/fuse movement | Same relative sweep while the collective attack is committed | At most once per collective execution |
| Bulkhead Guard and Splitter Barge hull overlap | Persistent swept body contact in move/recovery/holding states | Start per-enemy `0.8s` cooldown only when barrier or hull accepts the contact; invulnerability rejection keeps it armed so continued overlap can hit after protection expires |
| Ranged, support, fixed structure, ordinary mine | No hull-contact damage | Existing projectiles, beams, mine fuse, and explosion remain the only damage paths |
| Boss | Unchanged | Excluded from this contract |

Add `contact_previous_position` and `contact_cooldown` to `VehicleEnemyState`, reset them on
pool reuse, and decrement the cooldown at 60 Hz. Change `_damage_player()` to return `true`
when a positive hit is accepted by barrier or hull and `false` when simulation state,
invulnerability, stage completion, or zero effective damage rejects it. Existing callers
may ignore the return value. Remove the three ordinary legacy endpoint/decision-only
contact checks so no role has two damage owners.

This pass creates no event dictionaries, nodes, per-enemy spatial query, or dynamic
container growth. Add a named `contact_resolution` timing only to existing diagnostic
instrumentation. If measured contact cost is material, the only in-contract optimization
is a fixed retained melee-contact worklist maintained by the existing update schedule; do
not weaken the collision rule or lower cadence.

### Reinforcement and balance evidence

The facility validator must prove two sequential intervals below cap, blocking at child
and global caps, immediate spawn when a zeroed timer gains a slot, and permanent stop after
destroy/retire/stage completion. A run integration check must count only living children
with `summoned == true` and `carrier_id == "reinforcement_facility"` and prove the spawned
spec preserves that identity.

The difficulty validator remains the executable balance oracle. It must continue to prove:

- standard/swarm health multiplier by stage:
  `1.12 * 2.60 * [0.85,1.00,1.15,1.30,1.45]`;
- priority health multiplier by stage:
  `2.60 * [0.85,1.00,1.15,1.30,1.45]`;
- boss health `[3250,3510,3770,4030,4290]`;
- ordinary outgoing damage multiplier
  `[1.755,1.80765,1.8603,1.91295,1.9656]`;
- boss final-effective and friendly/environmental bypasses unchanged.

No balance constant changes unless a separate user-approved plan follows post-contact
gameplay evidence.

## Tasks

### Phase 0: Bind contracts and establish usable baselines

Goal: make the durable contract and validation baseline truthful before implementation.

Preconditions:

- Worktree contains no unrelated edits in the files to be changed.
- The executor re-reads this active plan, root/nearest instructions, current product/visual
  specs, and the Cardborne performance guard.

Source owners: `docs/product/vehicle_game_spec.md`,
`docs/product/vehicle_upgrade_catalog.md`,
`tools/validation/validate_vehicle_damage_feedback.gd`, performance recorder

- [ ] **0.1 Reconcile durable product contracts.**
  - Change: add the effect-row matrix, unlock/enhance rules, element summary transition,
    relative melee-contact matrix, and reinforcement recurrence acceptance. Correct the
    product card order so effect rows precede the final summary. Do not duplicate visual
    measurements already owned by `VISUAL_SYSTEM.md`.
  - Accept: product/catalog prose matches the locked design above, Korean/English content
    requirements are explicit, and EMP/boss work remains absent.
- [ ] **0.2 Repair the pre-existing damage-feedback oracle without gameplay changes.**
  - Change: isolate the live-crate warning fixture from generated cover so its expected
    boundary comes only from `CRATE_COLLISION_RADIUS + padding`; keep runtime geometry and
    warning behavior byte-for-byte unchanged.
  - Accept: `validate_vehicle_damage_feedback.gd` passes on the pre-contact runtime, and
    the formerly failing assertion still proves projectile warning and projectile collision
    stop at the same live-crate boundary.
  - Guard: if isolation reveals a real runtime mismatch instead of a fixture defect, stop
    and amend this contract before changing combat geometry.
- [ ] **0.3 Record the clean native before baseline.**
  - Change: after user alignment and a quiescent-process preflight, commit the doc/oracle
    baseline and run `peak_horde` and `capacity_pressure` once for 10s warmup + 60s sample
    at 1280x720, GL Compatibility, VSync off. Record exact commit, dirty state, renderer,
    workload/count validity, focus, hardware, and raw JSON under ignored `build/performance/`.
  - Accept: both samples are valid and comparable, whether green or red. A red result is
    labeled pre-existing and does not justify a speculative optimization.
  - Guard: do not start if unrelated Godot/capture/build/heavy processes overlap; do not
    stop processes whose ownership is unknown.

Batch gate:

- `git diff --check`, focused product/search checks, passing damage-feedback validator,
  and two eligible native baseline records.

### Phase 1: Make every upgrade offer truthful

Goal: every one of the 36 legal offer states shows its real level transition, one or two
real gameplay values, and the correct level-aware summary without changing gameplay.

Preconditions:

- Phase 0 contract and oracle tasks pass. Phase 0.3 may run immediately before Phase 2 if
  the executor completes the UI-only tasks first, but it must precede any runtime hot-path
  edit.

Source owners: `scripts/player/vehicle_primary_upgrade_rules.gd`,
`scripts/player/vehicle_secondary_catalog.gd`,
`scripts/player/vehicle_secondary_runtime.gd`,
`scripts/cards/vehicle_upgrade_definition.gd`,
`scripts/cards/vehicle_upgrade_effect_preview.gd`,
`scripts/cards/vehicle_upgrade_offer_presenter.gd`,
`scripts/ui/vehicle_upgrade_choice_card.gd`, card/secondary `.tres`, localization

- [ ] **1.1 Centralize behavior values without changing them.**
  - Change: extract primary upgrade rules, centralize secondary definition loading, expand
    Seeker's definition to base/L1/L2, and make primary/secondary runtime consume those
    owners. Preserve every damage, count, angle, interval, radius, cap, cadence, and slot rule.
  - Accept: focused primary/secondary tests prove exact equivalence for all levels; repository
    search finds no duplicate Seeker arrays or Split/Pierce rule tables in runtime/presenter.
- [ ] **1.2 Publish exact behavior effect previews.**
  - Change: implement the locked six-card row matrix and correct first-acquisition current
    visibility. Existing modifier-backed cards continue through real modifiers.
  - Accept: every legal card/current-level pair publishes one or two effect rows, never
    more than two; exact numeric sequences match gameplay owners.
- [ ] **1.3 Publish correct level-aware semantics and copy.**
  - Change: add optional enhancement description ownership, three localized element
    enhancement summaries, and correct built-in Seeker's first-offer kind to `enhance`.
  - Accept: first element/optional-secondary acquisition remains an unlock, Seeker is an
    enhancement from its first offer, and every later behavior level is an enhancement in
    accessibility text and frozen snapshot data.
- [ ] **1.4 Close the upgrade UI gate.**
  - Change: keep the existing vertical hierarchy and zero-divider structure; strengthen
    validators to assert actual `effect_rows >= 1` rather than combined `value_rows`.
  - Accept: Korean/English at 960x540, 1280x720, 1920x1080, and 200% text scale show no
    overflow, overlap, clipping, horizontal separator, or stale first-level summary. Rendered
    captures show first and enhanced Thermal plus representative Split, Seeker, Electric,
    and Mine cards.

Batch gate:

- Upgrade catalog/system/UI, secondary runtime, localization, capture-driver, visual
  authority, Godot import, and `git diff --check` pass once after all Phase 1 tasks.

### Phase 2: Restore reliable ordinary melee contact

Goal: intended melee attacks damage on exact relative contact during normal movement while
all non-melee overlap, warning, invulnerability, barrier, dash, and one-hit semantics remain.

Preconditions:

- Eligible Phase 0.3 native baseline exists.
- Phase 1 acceptance checks pass and the runtime workload is frozen except for Phase 2.

Source owners: `scripts/enemies/vehicle_enemy_contact_runtime.gd`,
`scripts/enemies/vehicle_enemy_state.gd`, `scripts/enemies/vehicle_enemy_store.gd`,
`scripts/vehicle/vehicle_run.gd`, `scripts/combat/vehicle_attack_contract.gd`

- [ ] **2.1 Make player damage acceptance explicit.**
  - Change: return a boolean receipt from `_damage_player()` with the accepted/rejected
    semantics above; preserve all existing damage, telemetry, barrier, hit feedback, defeat,
    and one-second invulnerability behavior.
  - Accept: direct focused tests cover inactive/stage-complete/invulnerable rejection,
    full and partial barrier acceptance, hull acceptance, and callers that ignore the return.
- [ ] **2.2 Implement the bounded relative-sweep contact owner.**
  - Change: add fixed enemy start-position/cooldown state, one no-allocation pass over the
    existing active list, exact relative swept-circle math, and the locked role matrix.
  - Accept: endpoint crossing at large delta cannot tunnel; no per-frame allocation or
    per-enemy grid query is introduced; fixed state resets cleanly on pool reuse.
- [ ] **2.3 Remove competing legacy contact owners and integrate at 60 Hz.**
  - Change: remove Chaser, Rammer, collective-charge endpoint checks and Bulkhead/Splitter
    decision-only overlap checks; invoke the new owner after every ordinary/forced movement
    and before projectile damage; instrument the named section only in diagnostic mode.
  - Accept: every role has exactly one contact owner; presentation/collision radii remain
    separate; boss, mine, ranged, support, and fixed-structure paths are unchanged.
- [ ] **2.4 Close the contact correctness and cost gate.**
  - Change: add `validate_vehicle_enemy_contact.gd` with deterministic relative-motion,
    phase, cooldown, barrier, invulnerability, dash protection, collective, role-exclusion,
    pool-reuse, and large-delta cases.
  - Accept: Chaser/Rammer hit once only in active; persistent hull roles hit once, do not
    repeat inside protection/cooldown, and can hit after protection expires if overlap
    continues; ranged/support/mine overlap never causes hull damage. A short controlled
    diagnostic proves fixed capacity and no allocation growth.

Batch gate:

- New contact validator, damage feedback, attack contract, update schedule, enemy store,
  run, dash/protection, difficulty, performance-scenario structural validator, Godot import,
  and `git diff --check` pass.

### Phase 3: Prove reinforcement and accepted balance

Goal: convert “it seems” into deterministic evidence without changing already-accepted
spawn or balance values.

Preconditions:

- Phase 2 contact gate passes so post-contact damage opportunities are representative.

Source owners: `scripts/vehicle/vehicle_reinforcement_facility_runtime.gd`,
`scripts/vehicle/vehicle_run.gd`, `scripts/enemies/vehicle_stage_difficulty.gd`,
`scripts/encounters/vehicle_encounter_director.gd`, focused validators

- [ ] **3.1 Prove the complete reinforcement lifecycle.**
  - Change: extend the focused runtime validator and add run-integration coverage for two
    intervals, both caps, released slots, destroy/retire/stage-complete, and carrier identity.
  - Accept: stages 1-5 preserve `8/7/6/5/4s`, `2/3/4/5/6` children, stage roles, and
    time-driven recurrence. If current production code already passes, leave it unchanged.
- [ ] **3.2 Re-verify and report enemy balance without retuning.**
  - Change: retain the existing difficulty oracle, add only missing exact effective examples
    if needed, and run it after contact integration.
  - Accept: every multiplier and bypass in the Proposed Design passes. The handoff reports
    both authored factors and effective stage multipliers so a tester can verify the claim.
- [ ] **3.3 Perform a bounded normal-play contact sanity pass.**
  - Change: use a deterministic or capture fixture with one Chaser, one Rammer, one
    persistent hull role, and one ranged control while the player crosses their bodies.
  - Accept: visible hit feedback and hull/barrier changes match the contact validator; no
    extra debug HUD or production marker is added.

Batch gate:

- Reinforcement facility, run difficulty, enemy contact, damage feedback, stage report,
  localization, capture driver, and main run validators pass.

### Phase 4: Render, build, and qualify the final non-boss workload

Goal: inspect the actual product, carry forward the outstanding Drop Mine evidence, and
make only precise qualification claims against the final code.

Preconditions:

- Phases 1-3 pass and feature sources stop changing.

Source owners: capture driver/gateway, visual authority validator, Web exporter,
performance scenario/recorder, active evidence record

- [ ] **4.1 Inspect rendered UI and carried non-boss combat evidence.**
  - Change: capture Korean/English supported viewports and 200% text for upgrade cards;
    capture all three approved Drop Mine radii plus reduced motion; inspect at 1x and
    grayscale. No EMP capture or candidate decision is part of this task.
  - Accept: card values/copy/layout, mine radius mapping, player/enemy priority, and existing
    visual contracts are correct with zero overflow or horizontal dividers.
- [ ] **4.2 Build and smoke the production Web artifact.**
  - Change: run visual/document authority checks, Godot import, focused final validators,
    `tools/export_web.ps1`, and a production-style built start through the `npjt-port-guard`
    codex lane.
  - Accept: `WEB_EXPORT_OK`, required Web files, Korean/English navigation, upgrade selection,
    ordinary contact, reinforcement recurrence, and stage progression work in the build.
- [ ] **4.3 Compare final runtime and diagnose the user's stutter report.**
  - Change: after user alignment, collect one normal-play manual trace through the reported
    slow period, then run the same clean native `peak_horde` and `capacity_pressure` pair and
    built-Web peak-horde against the final commit. Compare exact workload, frame/physics,
    contact section, scheduled enemies/grid, combat/effects, HUD/presentation, render CPU/GPU,
    focus, and process-isolation metadata.
  - Accept: samples are valid and the contact change causes no regression. Use only the
    precise labels `scenario valid`, `native release performance passed`, or `Web release
    performance passed` when their complete gates pass.
  - Guard: if only contact resolution is red, apply the predetermined retained melee-worklist
    optimization and repeat the affected scenario once. If another owner is red, stop and
    create a measured-owner plan; do not fold a generic optimization into this contract.
- [ ] **4.4 Close durable records and plan lifecycle.**
  - Change: update the owning product/catalog and performance evidence with accepted facts,
    remove task-owned temporary helpers, mark all checkboxes truthfully, and set this plan
    to `done` only when no required work remains. The superseded plan stays non-current.
  - Accept: there is exactly one relevant active ExecPlan, no completed decision depends on
    chat history, and EMP/boss state is unchanged.

Batch gate:

- Final focused batch, visual authority, import, Web export, built-product smoke, eligible
  native/Web performance evidence, `git diff --check`, and task-owned commit review pass.

## Test Plan

Focused commands use the repository wrapper and run sequentially:

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_upgrade_system.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_upgrade_ui.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_secondary_weapons.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_enemy_contact.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_damage_feedback.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_reinforcement_facility.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_run_difficulty.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_run.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_performance_scenarios.gd
.\tools\validation\validate_cardborne_visual_authority.ps1
.\tools\godot.ps1 --path . --headless --import
.\tools\export_web.ps1
git diff --check
```

Capture command shape, repeated for required locale/viewport/text-scale combinations:

```powershell
$captureDir = Join-Path (Resolve-Path .).Path 'build\captures\non-boss-integrity'
$godotArgs = @(
  '--rendering-method', 'gl_compatibility', '--',
  "--capture-all=$captureDir", '--capture-locale=ko', '--capture-size=1280x720',
  '--layout-seed=12886704'
)
.\tools\godot.ps1 @godotArgs
```

Native performance command shape, run from a clean committed tree only after the required
user alignment and quiescence check:

```powershell
$perfCommit = (git rev-parse HEAD).Trim()
$env:PERFORMANCE_COMMIT = $perfCommit
$env:PERFORMANCE_DIRTY = '0'
try {
  foreach ($scenario in @('peak_horde', 'capacity_pressure')) {
    $output = "res://build/performance/non-boss-integrity/$($perfCommit.Substring(0,8))-$scenario-60s.json"
    .\tools\godot.ps1 --path . --rendering-method gl_compatibility `
      --resolution 1280x720 --position '40,40' --disable-vsync -- `
      "--performance-scenario=$scenario" "--performance-output=$output" `
      '--performance-warmup=10' '--performance-duration=60'
    if ($LASTEXITCODE -ne 0) { throw "performance scenario invalid: $scenario" }
  }
} finally {
  Remove-Item Env:PERFORMANCE_COMMIT -ErrorAction SilentlyContinue
  Remove-Item Env:PERFORMANCE_DIRTY -ErrorAction SilentlyContinue
}
```

For built Web, first load `npjt-port-guard`, resolve the `codex` lane, serve only
`build/web` from a hidden task-owned process, open the exact peak-horde query, save
`window.__cardbornePerformanceResultJson`, and stop only the verified task-owned PID.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | Changed owner's one focused validator plus `git diff --check` | After the task compiles and direct examples exist | Relevant implementation input changes |
| Upgrade phase gate | Upgrade system/UI, secondary weapons, localization, capture-driver, visual authority, import | Tasks 1.1-1.4 pass | Card data, preview, UI, localization, or layout changes |
| Contact phase gate | Enemy contact, damage feedback, attack contract, schedule/store, difficulty, Run, performance-scenario structure | Tasks 2.1-2.4 pass | Contact/damage/state/schedule inputs change |
| Gameplay evidence gate | Reinforcement, difficulty, contact, damage, report, capture, Run | Tasks 3.1-3.3 pass | Facility, balance, contact, or fixture inputs change |
| Export gate | Visual authority, import, `tools/export_web.ps1`, built smoke | All feature phases and rendered inspection pass | Imported/export/runtime input changes |
| Native release gate | Exact clean native pair with workload and isolation metadata | Before hot-path edit and once on final code, after user alignment | Runtime/workload/instrumentation changes or sample invalidation |
| Web release gate | Built-Web peak-horde on codex lane with exact JSON | Final native gate is valid and built artifact matches | Build/runtime/workload changes or sample invalidation |

Validation rules:

- Run the narrowest check that proves the current task.
- Run each phase gate once after task acceptance passes.
- Do not call the current baseline damage-feedback validator passed until Task 0.2 closes
  its exact failure.
- A Web export is not an interactive smoke or performance pass. A valid scenario is not a
  release-performance pass unless all threshold and workload fields pass.
- Rerun a failed check only after a relevant implementation change or a new causal
  hypothesis can produce new evidence.
- Record non-blocking warnings once instead of rediscovering them.

## Rollback and Safety

- Keep each phase in coherent, scoped commits. Revert only the affected task commit if its
  focused gate fails; never reset or clean unrelated user work.
- If centralized gameplay rules change a runtime number, revert that extraction and fix
  the shared owner before proceeding; do not update expected tests to the accidental value.
- If contact resolution double-hits, restore the previous committed state and correct the
  single owner; do not increase invulnerability or lower damage as compensation.
- If an optional visual receipt/capture is absent, gameplay remains authoritative. Do not
  create a geometric stand-in or touch EMP.
- Performance samples require a clean commit and quiet environment. Preserve invalid/red
  evidence with its reason; do not cherry-pick a favorable run.

## Risks

- Fake modifiers would apply behavior values a second time. The dedicated preview boundary
  and runtime-equivalence tests prevent this.
- Centralizing Seeker data can introduce a level-index off-by-one. The definition explicitly
  includes base/L1/L2, and tests cover all three states.
- A second contact owner can double damage. Repository search and role-by-role tests must
  prove legacy endpoint/decision checks are gone.
- Starting persistent-contact cooldown on an invulnerability rejection would recreate the
  user's missed-hit complaint. Only accepted barrier/hull contact starts that cooldown.
- A new 60 Hz scan can regress physics tails. The active list is bounded and reused, the
  baseline precedes edits, and the only in-contract optimization is a fixed contact-role
  worklist.
- Card copy can overflow Korean or English even when logic tests pass. Rendered supported-
  viewport and 200% evidence is mandatory.
- Repeated facility tests may pass while the run counts the wrong children. The integration
  test separately locks `summoned` plus `carrier_id` identity.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A verified gameplay value differs from the locked matrix | Stop that branch, correct the owning product/gameplay source or amend this contract with user approval | Do not let UI or tests invent a replacement value |
| Crate baseline failure is a real runtime geometry defect | Preserve evidence and amend scope before editing combat geometry | Task 0.2 authorizes fixture isolation only |
| Reinforcement recurrence test fails | Fix only timer/cap/child-identity lifecycle to the already-authored values | Do not change cadence, roles, caps, quota, or rewards |
| Post-contact play still feels weak while exact hit tests pass | Report the evidence and request a separate balance decision | Do not increase health/damage inside this contract |
| Contact section alone causes a qualified performance regression | Maintain a fixed retained melee-contact worklist in the existing update schedule, preserving exact sweep semantics | No cadence/collision/workload reduction |
| Another performance owner is red | Stop optimization, record the measured owner, and create a new owner-specific contract | No generic cache/pool/thread/render rewrite |
| EMP or boss-pattern work is requested during execution | Finish or checkpoint the current phase and create a separate approval/implementation contract | Do not reactivate the superseded mixed plan |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain required approval | Executors may resolve implementation-local details only |

Implementation-local discoveries may be handled inside the locked contract when they
cannot change scope, visible behavior, ownership, architecture, safety, or acceptance.

## Open Questions

- None for the authorized non-EMP, non-boss scope.

## Decision Notes

- 2026-08-10: The user said the `emp-magnetic-flux-v2` candidate is not clearly better and
  excluded the final EMP image decision. This contract neither approves nor rejects it.
- 2026-08-10: The existing mixed boss/non-boss plan is superseded, not deleted. Its
  completed history remains available, while deferred boss tasks no longer occupy active
  execution context.
- 2026-08-10: Existing health/damage constants are preserved. Reliable contact is fixed
  before any new balance proposal.
- 2026-08-10: Homing Missiles is an enhancement from its first card because Seeker is a
  built-in weapon. Optional secondary first cards remain unlocks.
- 2026-08-10: Behavior previews use gameplay owners rather than fake stat modifiers.
- 2026-08-10: Relative swept contact uses a bounded reused active list instead of adding
  one spatial query per enemy or a second collision truth.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 0.
- Next task: 0.1, reconcile durable product and upgrade catalog contracts.
- Last completed gate: Discovery Closure Gate.
- Verified baseline: clean runtime commit `3eea8434`; four named focused validators pass;
  the exact pre-existing crate-warning validation failure is recorded above.
- Implementation completed under this contract: none.
- Update rule: after a checkpoint passes, record concise evidence, check the task, and
  advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check and phase/final gate passes.
- Every legal card state has truthful values/copy, every contact case has one owner,
  facility recurrence and accepted balance are proven, and the built artifact is inspected.
- Performance claims use exact eligible labels and evidence; any measured red external
  owner has an explicit successor contract rather than a hidden workaround.
- EMP production and candidate bytes/metadata, boss behavior, and all excluded values are
  unchanged.
- Durable decisions are in their owning specs/evidence, and this plan's frontmatter is
  changed to `done` only after no required work remains.

Replan when:

- A material discovery invalidates a locked product, architecture, data, UX, safety, or
  validation decision.

Do not replan or stop for:

- Implementation-local mechanics already contained by this contract.
- A passing check whose relevant inputs have not changed.
