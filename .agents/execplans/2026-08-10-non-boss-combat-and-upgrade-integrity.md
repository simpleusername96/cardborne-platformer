---
type: plan
status: active
owner: BK
created: 2026-08-10
last_reviewed: 2026-08-10
topic: Upgrade truth, contact damage, exact area-effect presentation, reinforcement recurrence, balance evidence, and final qualification
scope: Upgrade-card progression copy and values, ordinary melee contact reliability, exact gameplay-footprint presentation for every displayed area effect, reinforcement-facility recurrence proof, locked enemy balance verification, and release qualification
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
  - ./2026-08-10-emp-wavefront-integration.md
---

# Combat, Upgrade, and Area-Effect Integrity - Execution Contract

The completed non-boss work remains in production. This contract finishes the newly
verified progression and contact defects, proves the already-authored reinforcement and
balance behavior, corrects every displayed area effect so its visible body covers its exact
gameplay footprint, carries the still-required capture/export gates, and qualifies the
resulting workload. Boss attack patterns and values remain excluded, but their shared
circular area presentation follows the same footprint rule. The user rejected raster
layers whose only job is shape and color, so dynamic disks, boundaries, corridors, bars,
and simple markers are code-native retained geometry. The previously integrated
outward-only EMP wavefront and its decorative raster are removed from runtime.

## Purpose

- Objective: make every upgrade offer state truthful, make intended melee contact damage
  reliable during normal movement, make every displayed area effect match its complete
  gameplay footprint, prove reinforcement recurrence, and verify rather than silently
  retune the accepted enemy health and damage curves.
- Deliverable: gameplay-owned upgrade preview data, level-aware Korean/English card copy,
  a bounded swept-contact runtime, gameplay-owned area-effect footprint data, full-area
  retained presentation, focused deterministic validators, rendered UI/combat evidence,
  a production Web artifact, and precise performance qualification.
- Completion state: all task and phase gates pass; no gameplay-value or boss-pattern
  changes; obsolete shape-only effect/cue rasters are absent from the runtime pack;
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
- Electric Field already draws a radius-scaled mesh, but its `0.10` interior alpha is too
  weak on the light world surface and the captured result reads primarily as a broken edge.
- EMP damage and stun apply immediately to the complete `285` radius and hostile-projectile
  clear applies immediately to `325`, while the current release image expands from
  `0.15 -> 1.00` radius over `0.20s` and has an open center. That presentation falsely
  implies delayed edge-only propagation.
- Thermal Burst, Drop Mine, and Mystery Projectile Purge resolve their complete areas
  immediately, but their current presentation relies on a shaped impact or ring and scales
  toward final radius after gameplay has already resolved. Boss circular damaging windows
  likewise render only an outer ring. Beam startup/active already fills the exact gameplay
  corridor and is the retained compliant reference.
- Current clean HEAD `6494563f` contains the completed EMP wavefront integration. Its
  closeout records passing renderer, effect-store, capture, asset, workbench, visual-
  authority, import, export, and built-product visual checks. The earlier upgrade-system,
  upgrade-UI, reinforcement-facility, and run-difficulty baseline remains recorded; the
  pre-existing world-layout-dependent crate-warning assertion still requires Task 0.2
  isolation. No current-HEAD native or Web release-performance result is qualified.

## Scope and Boundaries

In scope:

- The six missing behavior-card value previews and level-aware element summaries.
- Correct unlock/enhance semantics for built-in and optional weapon upgrades.
- Product-spec reconciliation with the binding card order: category, title, artwork,
  level, one or two effect rows, then a maximum two-line summary.
- Exact relative swept-circle contact for intended ordinary melee roles.
- Exact full-area presentation for Electric Field, EMP charge/release, Thermal Burst,
  Drop Mine, Mystery Projectile Purge, and every boss circular damage footprint.
- Explicit EMP damage/stun radius `285` and projectile-clear radius `325` presentation
  without delayed radius growth or an authored-raster accent.
- Regression proof that beam startup/active continues to fill its exact damage corridor.
- Repeated reinforcement-facility lifecycle and run-integration validation.
- Verification of the accepted ordinary health curve
  `[0.85, 1.00, 1.15, 1.30, 1.45]`, final ordinary and boss health multipliers `2.60`,
  ordinary damage multiplier `1.755`, and damage stage curve
  `[1.00, 1.03, 1.06, 1.09, 1.12]`.
- The previously outstanding rendered capture, Web export, manual hitch trace,
  and controlled native/Web performance qualification after feature code stops changing.

Out of scope:

- Creating or replacing authored raster/SVG content. This contract retires only the nine
  existing shape/color-only runtime images for EMP, Thermal Burst, Drop Mine, health frame,
  ring, beam strip, diamond marker, disk mask, and unused crosshair; their historical
  workbench evidence remains history and no replacement image is created.
- Boss attack patterns, boss contact rules, boss damage, boss health, boss shielding, or
  boss body work. Only the shared presentation of an existing circular gameplay footprint
  may change.
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
- Every displayed area effect has a continuous low-alpha body from center to exact gameplay
  boundary. A perimeter or internal plane may reinforce identity but may never be the sole
  range representation. Instant gameplay areas appear at full extent on their resolution
  frame; presentation must not imply outward damage propagation.
- Presentation consumes gameplay-owned centers, shapes, radii, timing, and phase. It owns
  no collision/damage query and creates no second gameplay truth.
- Existing retained batches consume reusable code-native unit meshes for dynamic disks,
  rings, beam corridors, health rectangles, and diamond markers. No replacement texture,
  material, batch, effect-store capacity, or unbounded per-frame allocation is added; the
  dedicated Thermal and Drop Mine raster batches are removed.
- Contact correctness is fairness-critical and remains on the 60 Hz physics boundary.
  The implementation may scan the already-built bounded active-enemy worklist once, but it
  may not allocate, query the spatial grid once per enemy, or add per-contact nodes/events.
- Gameplay damage resolution remains independent from visual feedback.

Destructive or irreversible actions:

- Remove the nine exact obsolete production PNGs and their `.import` sidecars after all
  runtime references and manifest entries are removed. This is explicitly within the
  user's shape/color-only retirement direction; git history and workbench evidence remain
  recoverable. Generated build, capture, and performance outputs remain under ignored
  `build/` paths. Every source change lands in a coherent task-owned commit.

Exact actions requiring owner or user approval:

- The user directed that all feature fixes be completed before the two 60-second native
  performance scenarios or the user-driven manual trace. Immediately before that final
  qualification, state their duration, foreground/window impact, stopping condition, and
  required quiet machine state. This direction authorizes the final runs, not an interim
  or pre-change baseline.
- Before Phase 4 closes, present the exact-radius color/grayscale captures for user review.
  This approves the runtime composition only; it does not reopen or replace any raster.

## Assumptions

- Authored actors, projectiles, rewards, facilities, upgrade art, and other images with a
  real semantic silhouette remain unchanged. Only shape/color-only effect and cue images
  are retired.
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

The area-effect presentation domain uses these context-local terms:

- `gameplay footprint`: the center plus radius or corridor published by the gameplay owner;
  it determines recipients and remains authoritative.
- `full-area body`: a restrained continuous filled plane covering the footprint from center
  to boundary. It is required for any visual that claims an area of effect.
- `perimeter accent`: an optional edge cue or authored silhouette. It may reinforce the
  boundary but never substitute for the full-area body.
- `instant area event`: gameplay resolves the complete footprint in one simulation step;
  its visual starts at full extent and may fade, but may not grow outward.
- `persistent area`: gameplay remains active over time; its full-area body follows the live
  gameplay center and radius for the complete active interval.
- `multi-envelope event`: one action owns different recipient ranges. EMP has a stronger
  inner damage/stun disk at `285` and a restrained outer projectile-clear disk at `325`.

Gameplay owners publish these facts. `VehicleEffectState` freezes transient presentation
data, `VehicleVisualEventCatalog` assigns presentation mode, and
`VehicleCombatRenderer` renders it without inferring damage. The durable footprint rule
belongs in `vehicle_game_spec.md` and `VISUAL_SYSTEM.md`; no new glossary file is needed.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Active plan lifecycle | The prior active plan mixes completed non-boss work with deferred boss work and open qualification gates. | `.agents/execplans/2026-08-10-combat-correction-and-boss-pattern-expansion.md` | Supersede it, preserve it as history, and make this the only active contract. | 0.1, 5.4 |
| Area-effect invariant | The user requires every displayed area effect to cover its complete gameplay footprint and rejected images whose only role is shape/color. | User decisions on 2026-08-10; Electric Field and boss-area captures; current cue/effect rasters | Render dynamic footprints from reusable code-native geometry; keep no EMP, Thermal, or Drop Mine raster accent. | 0.1, 4.1-4.4 |
| EMP multi-envelope mismatch | EMP damage/stun resolves instantly at radius `285`; projectile clear resolves instantly at `325`; the release previously expanded an open-center octagon and then retained that octagon as a decorative accent. | `VehicleRun._release_emp()`, `VehicleEffectState`, `VehicleCombatRenderer._sync_effects()`, user correction on 2026-08-10 | Publish both radii and show both complete code-native disks immediately; remove the octagon asset and all release-radius interpolation. | 0.1, 4.1-4.4 |
| Other geometric cue ownership | Dynamic disks, rings, beam strips, health frames, and diamond markers currently request authored PNGs even though runtime supplies their dimensions and colors. | `VehicleCombatRenderer._build_batches()`, `_write_beam()`, `_write_disk()`, `_sync_health_bar()`, `VehicleRun._draw_terrain()`, `_draw_enemy_overlay()` | Reuse retained code-native unit meshes and code-native lines/arcs, preserve exact gameplay dimensions and capacities, and retire the nine obsolete runtime images. | 4.2-4.4 |
| Missing card values | Presenter builds rows only from `definition.modifiers`; six behavior cards have none. | `scripts/cards/vehicle_upgrade_offer_presenter.gd:15`, `data/cards/vehicle/*.tres` | Add a gameplay-owned behavior-preview boundary; never add fake runtime modifiers. | 1.1-1.3 |
| Upgrade source truth | Split/Pierce values live in `VehicleRun`; Seeker upgrades are hardcoded in secondary runtime; optional secondary values live in `.tres` definitions. | `scripts/vehicle/vehicle_run.gd:1575`, `scripts/player/vehicle_secondary_runtime.gd:205`, `data/weapons/vehicle/secondary/*.tres` | Centralize primary rules and secondary definition loading, then make both runtime and previews consume them. | 1.1 |
| Card semantics and layout | Built-in Seeker is misclassified; element copy is static. Runtime already renders level, effect rows, then summary with zero dividers, while product prose lists summary before values. | `scripts/cards/vehicle_upgrade_offer_presenter.gd:30`, `scripts/ui/vehicle_upgrade_choice_card.gd:243`, `docs/product/vehicle_game_spec.md:550`, `docs/design/VISUAL_SYSTEM.md` | Correct change-kind semantics, add enhancement summaries, and reconcile product prose to the binding visual order. | 0.1, 1.2-1.4 |
| Enemy health and damage | Accepted curves and multipliers are already in source and focused tests. | `scripts/enemies/vehicle_stage_difficulty.gd`, `scripts/encounters/vehicle_encounter_director.gd`, `tools/validation/validate_vehicle_run_difficulty.gd` | Preserve all values; rerun exact effective-value checks after contact changes and report them plainly. | 3.2 |
| Reinforcement recurrence | Runtime resets its interval after each accepted spawn and retains zero while capacity-blocked; current test stops after first spawn/cap checks. | `scripts/vehicle/vehicle_reinforcement_facility_runtime.gd:45`, `tools/validation/validate_vehicle_reinforcement_facility.gd:20` | Extend lifecycle and run-integration tests; change production only if those exact tests expose a defect. | 3.1 |
| Missing player contact damage | Player and enemy endpoints are checked at different cadences; there is no relative swept contact owner. | `scripts/vehicle/vehicle_run.gd:1423`, `:2628`, `:2967`, `:3021`; `scripts/enemies/vehicle_enemy_update_schedule.gd` | Add one fixed-cap 60 Hz contact runtime using relative swept circles and explicit role semantics; remove legacy endpoint/decision-only checks. | 2.1-2.4 |
| Hit protection semantics | `_damage_player()` returns no receipt; one-shot attacks commit before an invulnerability rejection. | `scripts/vehicle/vehicle_run.gd:4169`, `tools/validation/validate_vehicle_damage_feedback.gd` | Return accepted/not-accepted while preserving every caller; barrier absorption is accepted, invulnerability rejection is not. One-shot attacks remain consumed; persistent hull contact retries while overlap remains. | 2.1-2.4 |
| Hot-path risk | Current runtime already has a bounded active worklist, reusable effect state, retained overlay batches, and reusable render buffers; current HEAD lacks a comparable pre-change release baseline. | `.agents/cardborne-performance-engineering-policy.md`, `.agents/cardborne-runtime-architecture-audit.md`, `scripts/vehicle/vehicle_run.gd`, `scripts/presentation/vehicle_combat_renderer.gd` | Preserve batch capacities, replace textures with startup-built meshes, remove two obsolete effect batches, add no per-frame allocation, and qualify only after all fixes. Without a comparable pre-change baseline, make no causal regression claim. | 0.3, 2.2-2.4, 4.1-4.4, 5.3 |
| Validation baseline | Four focused validators pass; damage feedback has one unrelated crate-warning failure on clean `3eea8434`. | Commands and output recorded during 2026-08-10 discovery | Isolate the crate fixture before using that validator as a gate; never report the current failing script as passed. | 0.2 |
| Visual authority | Current visual spec was read completely; canonical sheet inspected at 1448x1086 with SHA-256 `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`. The sheet is style reference, not asset approval. | `docs/design/VISUAL_SYSTEM.md`, canonical PNG | Add no asset. Dynamic truth uses restrained hard-edged code-native geometry and semantic tokens; exact-radius rendered evidence plus the authority validator remain required. | 1.4, 4.1-4.4, 5.1-5.2 |

Readiness statement:

- Every material product, architecture, data, UX, ownership, safety, and validation
  decision is closed for this scope.
- Required tools are present: PowerShell, `tools/godot.ps1`, Godot 4.7.1, focused
  validators, capture driver, Web exporter, and performance recorder.
- Remaining unknowns are implementation-local. Any evidence that requires a new balance
  value, role rule, asset, dependency, or performance owner triggers the change-control
  rules below instead of an executor guess.
- Visual-authority evidence: `docs/design/VISUAL_SYSTEM.md` was read completely; the
  canonical `docs/design/cardborne-universal-art-style-reference.png` was inspected at
  original `1448x1086` detail; expected and observed SHA-256 are
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
  Recorded provenance is the original Codex artifact
  `C:/Users/BK/.codex/generated_images/019fbfe9-857e-7453-b72d-20908d848577/exec-0b8aa606-cf55-45c1-abb3-fb3df762b080.png`
  from `2026-08-02 12:13:44 KST`. `actual_image_reference_used=false` and
  `reference_input_method=not_applicable` because this plan creates no raster/SVG and only
  changes retained code-native composition. Historical raster approvals are not reused as
  runtime authority; the new composition is pending the Phase 4.4 exact-radius review.

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

### Exact area-effect footprint presentation

The renderer composes every displayed area from an exact gameplay-owned footprint. The
continuous area body, boundary, and beam corridor use reusable code-native unit meshes in
the existing retained batches; Electric Field keeps its dedicated retained mesh. Runtime
health rectangles and simple diamond markers use the same code-native ownership rule. No
visual geometry calculates damage or collision.

| Effect | Gameplay footprint and timing | Locked presentation |
| --- | --- | --- |
| Electric Field | Player-centered persistent radius `120/140/160`, active continuously with `0.25s` damage ticks | Dedicated full disk fill alpha `0.18`, up to four internal planes alpha `0.06`, broken perimeter alpha `0.30`; all geometry remains inside the exact live radius |
| EMP charge preview | Live player center; previews damage/stun `285` and projectile clear `325`; no gameplay result before release | Full outer `325` system disk alpha `0.08`, full inner `285` system disk alpha `0.12`, one outer boundary accent; both follow the current player and do not expand |
| EMP release | Release position; damage/stun resolves instantly through `285`, projectile clear instantly through `325`; `0.55s` visual life | Full outer `325` disk alpha `0.10` and full inner `285` disk alpha `0.20`; both start at final size and only fade, with no raster accent |
| Thermal Burst | Direct-hit center; instant splash radius `72/84/96`; `0.18s` visual life | One full thermal disk alpha `0.16` at final radius from the first frame; it only fades |
| Drop Mine | Mine origin; instant area hit radius `96/108/120`; `0.18s` visual life | One full player-reward disk alpha `0.16` at final radius from the first frame; it only fades |
| Mystery Projectile Purge | Device position; instant hostile-projectile clear radius `420`; `0.18s` visual life | Full system disk alpha `0.14` at final radius from the first frame; one existing perimeter accent may remain and only fades |
| Mystery Gravity Pull | Device position; affects non-boss enemies through radius `480` for `1.2s` | Full system disk alpha `0.10` at the exact live radius for the complete duration; the existing boundary remains an accent |
| Mystery Cryo Lock | Device position; affects non-boss enemies through radius `360` for `0.8s` | Full cryo disk alpha `0.12` at the exact live radius for the complete duration; the existing boundary remains an accent |
| Mystery Decoy Signal | Device position; redirects enemies through radius `900` for `6s` | Full system disk alpha `0.08` at the exact live radius for the complete duration; the existing boundary remains an accent |
| Boss circular area | Committed center and pattern/zone radius during startup and damaging window | Full thermal disk alpha `0.10 -> 0.20` from readiness `0 -> 1`, plus the existing single outer boundary; active damage keeps the full disk at exact radius |
| Beam startup/active | Exact clipped damage rectangle | Preserve the existing two-plane startup and three-plane active filled corridor dimensions and colors on a code-native unit quad; validate as the non-radial compliant case |

Projectiles, melee/contact, orbiting blades, dash afterimages, barriers/shields, Toxin/Cryo
body overlays, and actor bodies do not claim radial areas and do not receive a disk. The
ordinary hostile mine remains an actor-owned proximity attack with no persistent or
edge-only range effect; this contract does not add an always-on range ring. If a future
task adds a detonation effect for it, that effect must use the same full-area rule.

Add an explicit secondary-radius field to the fixed `VehicleEffectState` and a named EMP
effect-store acquisition method so `VehicleRun` publishes `285` and `325` without making
the renderer derive `+40`. Reset the field on pool reuse and validate both radii. Remove
EMP, Thermal, Drop Mine, and Mystery Purge radius interpolation because their gameplay resolves
at full extent immediately. Standard and reduced motion retain the same complete footprint;
they may differ only in non-spatial fade behavior already allowed by the visual system.

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
`docs/design/VISUAL_SYSTEM.md`,
`tools/validation/validate_vehicle_damage_feedback.gd`,
`scripts/performance/vehicle_performance_recorder.gd`

- [x] **0.1 Reconcile durable product contracts.**
  - Change: add the effect-row matrix, unlock/enhance rules, element summary transition,
    relative melee-contact matrix, reinforcement recurrence acceptance, and exact area-
    footprint matrix. Correct the product card order so effect rows precede the final
    summary. Replace the obsolete EMP outward-wavefront and hollow-area rules in
    `VISUAL_SYSTEM.md`; record EMP `285` damage/stun and `325` projectile-clear envelopes in
    the product contract without moving gameplay ownership into design prose.
  - Accept: product/catalog prose matches the locked design above, Korean/English content
    requirements are explicit, every displayed area requires a center-to-boundary body,
    and no product value or boss pattern changes.
- [x] **0.2 Repair the pre-existing damage-feedback oracle without gameplay changes.**
  - Change: isolate the live-crate warning fixture from generated cover so its expected
    boundary comes only from `CRATE_COLLISION_RADIUS + padding`; keep runtime geometry and
    warning behavior byte-for-byte unchanged.
  - Accept: `validate_vehicle_damage_feedback.gd` passes on the pre-contact runtime, and
    the formerly failing assertion still proves projectile warning and projectile collision
    stop at the same live-crate boundary.
  - Guard: if isolation reveals a real runtime mismatch instead of a fixture defect, stop
    and amend this contract before changing combat geometry.
- [x] **0.3 Lock final-only performance cadence.**
  - Change: per the user's direction, do not run an interim or pre-change performance
    baseline. Complete Phases 2-4 first; Phase 5.3 owns the manual trace and clean native/Web
    qualification against the final committed workload.
  - Accept: no authoritative performance scenario runs before feature work is complete, and
    the final report makes no causal regression claim because this contract has no comparable
    pre-change sample.
  - Guard: focused structural and diagnostic validators remain allowed during implementation;
    do not present them as release-performance evidence.

Batch gate:

- `git diff --check`, focused product/search checks, passing damage-feedback validator, and
  the final-only performance cadence recorded in this contract.

### Phase 1: Make every upgrade offer truthful

Goal: every one of the 36 legal offer states shows its real level transition, one or two
real gameplay values, and the correct level-aware summary without changing gameplay.

Preconditions:

- Phase 0 contract, oracle, and validation-cadence tasks pass.

Source owners: `scripts/player/vehicle_primary_upgrade_rules.gd`,
`scripts/player/vehicle_secondary_catalog.gd`,
`scripts/player/vehicle_secondary_runtime.gd`,
`scripts/cards/vehicle_upgrade_definition.gd`,
`scripts/cards/vehicle_upgrade_effect_preview.gd`,
`scripts/cards/vehicle_upgrade_offer_presenter.gd`,
`scripts/ui/vehicle_upgrade_choice_card.gd`, card/secondary `.tres`, localization

- [x] **1.1 Centralize behavior values without changing them.**
  - Change: extract primary upgrade rules, centralize secondary definition loading, expand
    Seeker's definition to base/L1/L2, and make primary/secondary runtime consume those
    owners. Preserve every damage, count, angle, interval, radius, cap, cadence, and slot rule.
  - Accept: focused primary/secondary tests prove exact equivalence for all levels; repository
    search finds no duplicate Seeker arrays or Split/Pierce rule tables in runtime/presenter.
- [x] **1.2 Publish exact behavior effect previews.**
  - Change: implement the locked six-card row matrix and correct first-acquisition current
    visibility. Existing modifier-backed cards continue through real modifiers.
  - Accept: every legal card/current-level pair publishes one or two effect rows, never
    more than two; exact numeric sequences match gameplay owners.
- [x] **1.3 Publish correct level-aware semantics and copy.**
  - Change: add optional enhancement description ownership, three localized element
    enhancement summaries, and correct built-in Seeker's first-offer kind to `enhance`.
  - Accept: first element/optional-secondary acquisition remains an unlock, Seeker is an
    enhancement from its first offer, and every later behavior level is an enhancement in
    accessibility text and frozen snapshot data.
- [x] **1.4 Close the upgrade UI gate.**
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

- Phase 1 acceptance checks pass and the runtime workload is frozen except for Phase 2.

Source owners: `scripts/enemies/vehicle_enemy_contact_runtime.gd`,
`scripts/enemies/vehicle_enemy_state.gd`, `scripts/enemies/vehicle_enemy_store.gd`,
`scripts/vehicle/vehicle_run.gd`, `scripts/combat/vehicle_attack_contract.gd`

- [x] **2.1 Make player damage acceptance explicit.**
  - Change: return a boolean receipt from `_damage_player()` with the accepted/rejected
    semantics above; preserve all existing damage, telemetry, barrier, hit feedback, defeat,
    and one-second invulnerability behavior.
  - Accept: direct focused tests cover inactive/stage-complete/invulnerable rejection,
    full and partial barrier acceptance, hull acceptance, and callers that ignore the return.
- [x] **2.2 Implement the bounded relative-sweep contact owner.**
  - Change: add fixed enemy start-position/cooldown state, one no-allocation pass over the
    existing active list, exact relative swept-circle math, and the locked role matrix.
  - Accept: endpoint crossing at large delta cannot tunnel; no per-frame allocation or
    per-enemy grid query is introduced; fixed state resets cleanly on pool reuse.
- [x] **2.3 Remove competing legacy contact owners and integrate at 60 Hz.**
  - Change: remove Chaser, Rammer, collective-charge endpoint checks and Bulkhead/Splitter
    decision-only overlap checks; invoke the new owner after every ordinary/forced movement
    and before projectile damage; instrument the named section only in diagnostic mode.
  - Accept: every role has exactly one contact owner; presentation/collision radii remain
    separate; boss, mine, ranged, support, and fixed-structure paths are unchanged.
- [x] **2.4 Close the contact correctness and cost gate.**
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

- [x] **3.1 Prove the complete reinforcement lifecycle.**
  - Change: extend the focused runtime validator and add run-integration coverage for two
    intervals, both caps, released slots, destroy/retire/stage-complete, and carrier identity.
  - Accept: stages 1-5 preserve `8/7/6/5/4s`, `2/3/4/5/6` children, stage roles, and
    time-driven recurrence. If current production code already passes, leave it unchanged.
- [x] **3.2 Re-verify and report enemy balance without retuning.**
  - Change: retain the existing difficulty oracle, add only missing exact effective examples
    if needed, and run it after contact integration.
  - Accept: every multiplier and bypass in the Proposed Design passes. The handoff reports
    both authored factors and effective stage multipliers so a tester can verify the claim.
- [x] **3.3 Perform a bounded normal-play contact sanity pass.**
  - Change: use a deterministic or capture fixture with one Chaser, one Rammer, one
    persistent hull role, and one ranged control while the player crosses their bodies.
  - Accept: visible hit feedback and hull/barrier changes match the contact validator; no
    extra debug HUD or production marker is added.

Batch gate:

- Reinforcement facility, run difficulty, enemy contact, damage feedback, stage report,
  localization, capture driver, and main run validators pass.

### Phase 4: Make every displayed area footprint truthful

Goal: every area visual covers its complete gameplay footprint at the same center, shape,
radius, and resolution timing without shape/color-only raster layers.

Preconditions:

- Phases 1-3 pass, and effect/gameplay constants are frozen to the matrix above.

Source owners: `scripts/combat/vehicle_effect_state.gd`,
`scripts/combat/vehicle_effect_store.gd`,
`scripts/presentation/components/vehicle_visual_event_catalog.gd`,
`scripts/presentation/components/vehicle_combat_cue_policy.gd`,
`scripts/presentation/vehicle_combat_renderer.gd`,
`scripts/vehicle/vehicle_run.gd`,
`scripts/vehicle/vehicle_run_capture_gateway.gd`,
`scripts/vehicle/vehicle_run_capture_driver.gd`, focused validators

- [x] **4.1 Publish exact transient area footprints.**
  - Change: add and reset explicit secondary-radius state, add a named EMP effect-store
    acquisition path, and publish charge/release damage/stun `285` plus projectile-clear
    `325` from gameplay-owned constants. Keep all single-radius events unchanged except for
    explicit first-frame/final-radius validation data.
  - Accept: the effect store reuses its fixed 96 states, EMP snapshots expose both exact
    radii without renderer arithmetic, pool reuse clears both, and gameplay damage, stun,
    clear order, values, center, cooldown, and effect capacity are unchanged.
- [x] **4.2 Render full-area bodies without false propagation or raster primitives.**
  - Change: replace shape/color-only disk, ring, beam, health-frame, and diamond textures
    with reusable code-native meshes in the existing retained batches; use code-native
    line/arc drawing for the two matching `VehicleRun` overlays; remove EMP, Thermal, and
    Drop Mine raster accents and their two dedicated batches; retain the locked final-radius
    timing, mystery footprints, boss fill, and beam plane dimensions.
  - Accept: renderer debug data proves exact center/radius and first-frame final extent for
    every matrix row; no area is hollow or edge-only, no primitive depends on an authored
    texture, no geometry extends beyond its gameplay footprint, two effect batches are
    removed, and no new node, material, batch, or recurring allocation is added.
- [x] **4.3 Strengthen deterministic footprint and asset-retirement validation.**
  - Change: update effect-store, combat-renderer, attack-route, secondary-weapon, and damage-
    feedback validators for the matrix, including EMP `285/325`, Electric `120/140/160`,
    Thermal `72/84/96`, Drop Mine `96/108/120`, Mystery Purge `420`, Gravity Pull `480`,
    Cryo Lock `360`, Decoy Signal `900`, boss runtime radii, first-frame full extent,
    persistent full-duration extent, standard/reduced parity, unchanged beam corridors,
    texture-free primitive batches, and absence of retired runtime IDs/files.
  - Accept: tests fail for an edge-only disk, renderer-derived radius, delayed scale-up,
    wrong center, alpha/geometry outside the footprint, stale pooled radius, or changed
    gameplay recipient result.
- [x] **4.4 Capture and approve exact-radius runtime evidence.**
  - Change: capture Electric levels 1-3; EMP charge and release in standard/reduced motion;
    Thermal and Drop Mine levels 1-3; all four Mystery outcomes; boss circular
    startup/active; and beam startup/active at 1280x720 in color and grayscale. Place
    reference actors/projectiles at the inner, boundary, and just-outside cases and present
    the consolidated sheet for user review before closing the phase.
  - Accept: center, middle, and edge all read as one affected area; just-outside space is
    clearly unaffected; EMP's `285` inner and `325` outer envelopes are distinguishable;
    actors/projectiles remain readable; the user approves the runtime composition.

Batch gate:

- Effect store, combat renderer, attack route, secondary weapons, damage feedback, capture
  driver, visual authority, Godot import, `git diff --check`, and exact-radius rendered
  review pass. The retained disk/effect counts stay within their existing capacities.

### Phase 5: Render, build, and qualify the final workload

Goal: inspect the actual product and make only precise qualification claims against the
final code and visual workload.

Preconditions:

- Phases 1-4 pass and feature sources stop changing.

Source owners: `scripts/vehicle/vehicle_run_capture_driver.gd`,
`scripts/vehicle/vehicle_run_capture_gateway.gd`,
`tools/validation/validate_cardborne_visual_authority.ps1`, `tools/export_web.ps1`,
`scripts/performance/vehicle_performance_scenario.gd`,
`scripts/performance/vehicle_performance_recorder.gd`,
`.agents/semantic-v2-runtime-acceptance-evidence.md`

- [x] **5.1 Inspect rendered UI and consolidated combat evidence.**
  - Change: capture Korean/English supported viewports and 200% text for upgrade cards;
    reuse the passing Phase 4 effect evidence unless an owned input changed; inspect upgrade,
    contact, reinforcement, effect, and player/enemy priority at 1x and grayscale.
  - Accept: card values/copy/layout, every area-footprint mapping, player/enemy priority,
    and existing visual contracts are correct with zero overflow or horizontal dividers.
- [x] **5.2 Build and smoke the production Web artifact.**
  - Change: run visual/document authority checks, Godot import, focused final validators,
    `tools/export_web.ps1`, and a production-style built start through the `npjt-port-guard`
    codex lane.
  - Accept: `WEB_EXPORT_OK`, required Web files, Korean/English navigation, upgrade selection,
    ordinary contact, complete area effects, reinforcement recurrence, and stage progression
    work in the build.
- [ ] **5.3 Qualify final runtime and diagnose the user's stutter report.**
  - Change: after all fixes and the production Web build are complete, state the approved
    run impact, collect one normal-play manual trace through the reported slow period, then
    run the clean native `peak_horde` and `capacity_pressure` pair and built-Web peak-horde
    against the final commit. Inspect exact workload, frame/physics,
    contact section, scheduled enemies/grid, combat/effects, disk/effect counts, draw calls,
    transparent coverage, HUD/presentation, render CPU/GPU, focus, and process-isolation
    metadata.
  - Accept: samples are valid and receive only the precise labels `scenario valid`, `native
    release performance passed`, or `Web release performance passed` when their complete
    gates pass. Report measured final owners, but do not claim that this contract caused or
    avoided a regression because no comparable pre-change baseline was collected.
  - Guard: if contact resolution or area-effect fill is red, preserve the final evidence and
    stop the affected optimization branch for a separately approved measured-owner change.
    Do not apply the prior before/after contingencies, remove the full-area body, change
    resolution or footprint, or fold a generic optimization into this contract.
- [ ] **5.4 Close durable records and plan lifecycle.**
  - Change: update the owning product/catalog/design and performance evidence with accepted
    facts, remove task-owned temporary helpers, mark all checkboxes truthfully, and set this
    plan to `done` only when no required work remains. The superseded plan stays non-current.
  - Accept: there is exactly one relevant active ExecPlan, no completed decision depends on
    chat history, EMP/boss gameplay is unchanged, and only the explicitly retired
    shape/color-only production rasters are removed.

Batch gate:

- Final focused batch, visual authority, import, Web export, built-product smoke, eligible
  native/Web performance evidence, `git diff --check`, and task-owned commit review pass.

## Test Plan

Focused commands use the repository wrapper and run sequentially:

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_upgrade_system.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_upgrade_ui.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_secondary_weapons.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_effect_store.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_combat_renderer.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_attack_route_readability.gd
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
$captureDir = Join-Path (Resolve-Path .).Path 'build\captures\combat-upgrade-effect-integrity'
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
    $output = "res://build/performance/combat-upgrade-effect-integrity/$($perfCommit.Substring(0,8))-$scenario-60s.json"
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
| Area-effect phase gate | Effect store, renderer, attack route, secondary weapons, damage feedback, capture, visual authority, import, exact-radius review | Tasks 4.1-4.4 pass | Effect state/catalog/renderer/cue/capture/spec input changes |
| Export gate | Visual authority, import, `tools/export_web.ps1`, built smoke | All feature phases and rendered inspection pass | Imported/export/runtime input changes |
| Native release gate | Exact clean native pair with workload and isolation metadata | Once on final code after all feature, render, export, and built-smoke work | Runtime/workload/instrumentation changes or sample invalidation |
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
- If a visual receipt/capture is absent, gameplay remains authoritative. Correct only the
  existing event/capture path; do not invent a radius or change damage to fit the visual.
- If a full-area composition fails readability, revert only its renderer task and retain
  the prior gameplay. Do not edit approved raster bytes or remove the required area body.
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
- A new 60 Hz scan can increase physics tails. The active list is bounded and reused, the
  named section is instrumented, and final qualification reports its measured cost without
  a causal regression claim.
- Card copy can overflow Korean or English even when logic tests pass. Rendered supported-
  viewport and 200% evidence is mandatory.
- Repeated facility tests may pass while the run counts the wrong children. The integration
  test separately locks `summoned` plus `carrier_id` identity.
- A visible perimeter can still dominate a technically nonzero fill. Exact-radius color and
  grayscale review must prove center, middle, and edge read as one area.
- EMP has two gameplay envelopes. Collapsing them into one radius would misstate either
  damage/stun or projectile clear; explicit pooled state and boundary tests prevent that.
- Additional large translucent disks can increase overdraw. The plan reuses one retained
  batch, validates draw/batch ceilings, and reports final fill cost without silently reducing
  complete footprint visibility.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A verified gameplay value differs from the locked matrix | Stop that branch, correct the owning product/gameplay source or amend this contract with user approval | Do not let UI or tests invent a replacement value |
| Crate baseline failure is a real runtime geometry defect | Preserve evidence and amend scope before editing combat geometry | Task 0.2 authorizes fixture isolation only |
| Reinforcement recurrence test fails | Fix only timer/cap/child-identity lifecycle to the already-authored values | Do not change cadence, roles, caps, quota, or rewards |
| Post-contact play still feels weak while exact hit tests pass | Report the evidence and request a separate balance decision | Do not increase health/damage inside this contract |
| Final contact section exceeds its qualified budget | Preserve evidence and create a measured-owner contact optimization contract | No causal regression claim and no cadence/collision/workload reduction inside this plan |
| Final full-area presentation exceeds its qualified fill budget | Preserve evidence and present a measured-owner follow-up for explicit user approval | Do not remove the body, reduce resolution, shrink radius, or change gameplay inside this plan |
| Another performance owner is red | Stop optimization, record the measured owner, and create a new owner-specific contract | No generic cache/pool/thread/render rewrite |
| A new or revised authored effect raster is requested | Stop and obtain an explicit user decision that supersedes the shape/color-only no-raster rule before opening a separate authority-pair AS-IS/TO-BE contract | This plan retires authored transient effect rasters |
| Boss-pattern or boss-value work is requested during execution | Finish or checkpoint the current phase and create a separate implementation contract | Shared circular footprint presentation does not authorize boss gameplay changes |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain required approval | Executors may resolve implementation-local details only |

Implementation-local discoveries may be handled inside the locked contract when they
cannot change scope, visible behavior, ownership, architecture, safety, or acceptance.

## Open Questions

- None for the authorized gameplay-preserving upgrade, contact, and area-effect scope.

## Decision Notes

- 2026-08-10: The completed EMP wavefront plan remains historical evidence, but both its
  outward-propagation presentation and later raster-accent fallback are superseded. EMP now
  uses two immediate code-native disks and no authored effect image.
- 2026-08-10: Every displayed area effect must show a continuous body through its complete
  gameplay footprint. A ring, burst, or perimeter may never be the sole area representation.
- 2026-08-10: The user rejected images whose only role is geometry and color. Dynamic disk,
  ring, beam, health-frame, and simple diamond geometry therefore belongs to reusable
  code-native primitives; EMP, Thermal, and Drop Mine raster accents are retired instead
  of composited over those footprints. This supersedes the cue-disk normalization repair.
- 2026-08-10: Runtime tracing found that Gravity Pull, Cryo Lock, and Decoy Signal also used
  ring-only Mystery presentation. They are governed by the same full-area rule at exact
  radii `480`, `360`, and `900` for their complete active durations.
- 2026-08-10: EMP preserves separate `285` damage/stun and `325` projectile-clear envelopes;
  both appear at full extent on release because both gameplay results resolve immediately.
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
- 2026-08-10: The user directed that all planned fixes precede the long performance scenarios
  and manual trace. This contract therefore collects final-only qualification and makes no
  before/after causal regression claim.
- 2026-08-10: After rejecting image assets used only for geometry and color, the user
  delegated the remaining implementation and review judgment. The authority-pair review,
  exact-radius color/grayscale sheets, and built-Web EMP check therefore close the revised
  runtime-composition gate without another raster candidate or review pause.
- 2026-08-10: The clean final native pair is workload-valid and authority-eligible but fails
  release frame thresholds for the prior raster-composited renderer. It remains historical
  evidence after the primitive-retirement input change. Native render GPU, draw calls,
  batches, contact, and combat/effect timings did not identify the full-area presentation
  or contact owner as the dominant cost;
  `enemies_and_grid`, physics catch-up, and unattributed wait remain the measured investigation
  surfaces. No optimization or product tradeoff is authorized inside this contract.
- 2026-08-10: The built-Web workload completed, but the automation browser identified itself
  as headless and scheduler-throttled. Preserve it as an ineligible diagnostic and do not issue
  a Web release-performance label.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 5 final qualification and durable closeout.
- Next task: commit the accepted code-native renderer/build evidence, then rerun the clean
  final native pair and built-Web diagnostic once because the renderer input changed.
- Last completed gate: the revised focused final batch passed all 12 contract validators,
  visual authority, Godot import, and `git diff --check`. The 115-capture runtime matrix and
  24-case color/grayscale sheet show continuous exact-area bodies. Web export reports
  `WEB_EXPORT_OK`; the newly built product starts on the guarded `codex` lane, switches Korean
  to English, shows the immediate complete EMP footprint, and records ordinary collision/melee
  contact in its failure report with no browser console warnings or errors.
- Final qualification evidence: native `peak_horde` and `capacity_pressure` are scenario-valid,
  authority-eligible 10+60 second samples but fail release thresholds. Median FPS is `19.09`
  and `7.50`; enemies/grid p95 is `11.84/14.17 ms`, contact p95 is `0.584/0.680 ms`, and native
  GPU time is `1.61/1.70 ms`. The Web peak workload is correct but release-ineligible because
  the automation browser is headless and scheduler-throttled. Exact payloads and the narrow
  non-causal diagnosis are recorded in `../semantic-v2-runtime-acceptance-evidence.md`.
- Verified source baseline: clean commit `04839774` preceded the Task 0.1/0.2 work. The
  former crate-warning failure was fixture contamination from generated cover; the isolated
  one-crate clear-path fixture passes without a runtime geometry change. Per user direction,
  this contract intentionally has no pre-change native performance baseline.
- Implementation completed under this contract: Tasks 0.1-5.2. Primary Split/Pierce
  and secondary definitions own runtime/preview values; all 36 offer states expose one or two
  rows; built-in Seeker begins as `enhance`; ordinary melee contact has one bounded relative-
  sweep owner; reinforcement recurrence and locked balance values are proven; every area
  state publishes gameplay-owned exact footprints, shape/color-only runtime rasters are
  retired, and the revised code-native renderer has current native capture and built-Web
  evidence. The prior final qualification remains historical and does not qualify the revised
  renderer input.
- Manual-trace status: the final trace launcher was started only after all fixes and synthetic
  qualification. No user gameplay or normal close occurred during the bounded wait, so it was
  stopped without a JSON and without substituting synthetic input. Task 5.3 remains open for
  that user-driven trace; the red synthetic evidence has already been preserved.
- Update rule: after a checkpoint passes, record concise evidence, check the task, and
  advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check and phase/final gate passes.
- Every legal card state has truthful values/copy, every contact case has one owner,
  every displayed area has a truthful center-to-boundary footprint, facility recurrence and
  accepted balance are proven, and the built artifact is inspected.
- Performance claims use exact eligible labels and evidence; any measured red external
  owner has an explicit successor contract rather than a hidden workaround.
- The nine shape/color-only runtime raster IDs and files are retired; all remaining authored
  visual bytes, pivots, and semantic IDs, boss behavior/values, and excluded gameplay values
  are unchanged.
- Durable decisions are in their owning specs/evidence, and this plan's frontmatter is
  changed to `done` only after no required work remains.

Replan when:

- A material discovery invalidates a locked product, architecture, data, UX, safety, or
  validation decision.

Do not replan or stop for:

- Implementation-local mechanics already contained by this contract.
- A passing check whose relevant inputs have not changed.
