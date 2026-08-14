---
type: plan
status: active
owner: BK
created: 2026-08-14
scope: Run-start weapon removal, weapon-owned upgrade progression, upgrade/HUD truth, and early XP pacing
related:
  - ../../AGENTS.md
  - ../PLANS.md
  - ../design/DESIGN.md
  - ./2026-08-14-active-weapon-ten-stage-density-and-run-ownership.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/product/vehicle_upgrade_catalog.md
  - ../../docs/product/vehicle_weapon_balance_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
---

# Weapon Unlocks and Early Level Pacing - Execution Contract

Cardborne will start each run with no automatic or active weapon, offer EMP and Homing Missiles as ordinary weapon cards, remove all four shared weapon-policy cards, keep one exclusive active weapon and up to three equal automatic weapons, move damage/range/cadence growth into each weapon definition, and slow only the first ten level thresholds without reducing the authored minimum-path final level.

## Purpose

- Objective: make every weapon choice and upgrade legible as that weapon's own progression, remove misleading default/shared state, and prevent the first ten level-ups from arriving after too few kills.
- Deliverable: aligned product/design specs, a 25-card/85-state catalog, empty run-start weapon state, weapon-owned active/automatic curves, truthful Upgrade/Result/HUD/Deployment surfaces, complete Korean/English copy, and the revised early XP curve.
- Completion state: the five-stage game starts with primary fire and Dash only; one of four active weapons and up to three of six automatic weapons can be acquired; no shared weapon card/stat remains; the first ten requirements are exactly `10/12/14/17/21/26/31/36/42/49`; the minimum quota path still reaches Level 30; focused, rendered, import, and production Web gates pass.

## Scope and Boundaries

In scope:

- Remove `active_coolant`, `active_amplifier`, `secondary_coolant`, and `secondary_amplifier` from data, offers, stats, localization, production artwork, manifests, snapshots, and tests.
- Add EMP as a four-level ordinary Active card; convert Homing Missiles from built-in-plus-three-upgrades to an ordinary four-level Auto Weapon card.
- Treat all six automatic weapons equally under one three-weapon acquisition limit; keep all four active weapons mutually exclusive under one active slot.
- Move weapon damage, range/count, and cooldown/cadence truth into active/secondary weapon definitions and their effect previews.
- Update Upgrade, Result, Ship Status, gameplay HUD, Deployment controls, input-aware first-acquisition descriptions, localization, visual asset coverage, captures, and specs.
- Add `+4 XP` to each of the first ten level requirements only.

Out of scope:

- Ten-stage implementation, encounter density, difficulty-stat changes, performance optimization, `VehicleRun` extraction, new enemies/bosses/maps, permanent progression, card deletion, weapon respec, reroll, skip, or decline.
- Raising runtime capacities, changing physics cadence, adding dependencies, threads, GDExtension, or custom Web templates.
- Rebalancing primary, element, chassis, or combat cards except where catalog counts and offer fixtures must acknowledge removed weapon-policy cards.

Constraints and invariants:

- Manual aim, held primary fire, Dash, fixed Hard, deterministic frozen offers, exact collision/damage ownership, and mandatory reward confirmation remain unchanged.
- Run start owns no active weapon and no automatic weapon. Pressing the active input before acquisition is a safe no-op.
- An acquired active weapon is run-locked: exactly zero or one of EMP, Black Hole, Shockwave, and Cross Beam can exist. No ordinary replacement or deletion flow is added.
- Up to three distinct automatic weapons can exist. Homing Missiles consumes one of those three positions exactly like every other automatic weapon.
- A weapon's first card is Level 1 and `NEW`; later copies increase that same card in place.
- All changed player-facing text is complete in Korean and English. A manual-weapon hint displays the current active-skill binding, not hard-coded `Shift`; an automatic-weapon hint says that it fires automatically.
- UI consumes gameplay-owned snapshots and does not calculate combat values.
- No run build is persisted across application launches, so no save migration is required. Settings and discovery persistence remain untouched.
- This implementation may make narrow call-site edits in `scripts/vehicle/vehicle_run.gd`, but it must not mix in the separate `VehicleRun` ownership refactor.

Destructive or irreversible actions:

- The four obsolete card resources and their four production upgrade images are removed in a task-scoped Git commit after all references are migrated. Git retains recovery history.

Exact actions requiring owner or user approval:

- The new EMP upgrade-card PNG must be generated under the canonical visual-authority pair and receive exact asset approval before production manifest integration. Data/runtime work can proceed first, but the final visual and Web gates stop if no EMP candidate is approved.

## Domain Alignment and Locked Product Design

| Canonical term | Meaning | Owner |
| --- | --- | --- |
| Active weapon | One manually triggered weapon bound to `active_skill`; absent at run start and exclusive after first acquisition | `VehicleRunBuild`, `VehicleActiveWeaponRuntime` |
| Automatic weapon | One acquired autonomous weapon family; Homing Missiles has no built-in privilege | `VehicleRunBuild`, `VehicleSecondaryRuntime` |
| Weapon slot | A gameplay acquisition limit: one Active and three Auto Weapons | Upgrade catalog/build compatibility |
| Build cell | A read-only summary position; it mirrors acquired state and never creates another limit | `VehicleBuildSnapshotBuilder`, shared build rail |
| Weapon-owned progression | Damage, footprint/count, and cadence values selected by that weapon's level; no cross-weapon policy multiplier | Active/secondary definition resources |

State transitions:

- Active: `empty -> one Active Lv.1 -> same Active Lv.2..4`; every other active card becomes incompatible at the first transition.
- Automatic: `0 -> 1 -> 2 -> 3 distinct families`; owned families can keep leveling, while a fourth first acquisition is incompatible.
- Removed shared card IDs are invalid input and never appear in offers, build snapshots, reports, localization coverage, or semantic asset coverage.

## Alternatives and Decision

| Candidate | Benefit | Cost or failure | Decision |
| --- | --- | --- | --- |
| Keep shared cards but hide their cells | Smallest code change | Contradicts the user's policy; weapon strength remains detached from the chosen weapon | Rejected |
| Apply the former final shared multiplier to every level | Source-backed endpoints | Makes first acquisition immediately `1.4x/1.5x` stronger and worsens the already-easy opening | Rejected |
| Interpolate from the current Level-1 value to the former fully-stacked endpoint inside each existing weapon curve | Keeps Level 1 stable, preserves known maximum power, removes global synergy, and needs no branch UI | Fewer total selectable states | Selected |
| Add levels solely to preserve 92 nominal states | Preserves a catalog count | Requires unsupported new balance points and still does not preserve legal path length | Rejected |
| Add damage/range/cooldown branch cards per weapon | More build specialization | Expands the catalog toward 45+ cards, dilutes offers, and recreates policy-card clutter | Rejected |

The selected curve uses these exact per-level factors against each weapon's current authored raw value:

- Four-level active damage: `[1.00, 1.15, 1.30, 1.50]`; active cooldown: `[1.00, 0.90, 0.82, 0.75]`.
- Four-level automatic damage: `[1.00, 1.12, 1.25, 1.40]`; automatic cadence: `[1.00, 0.90, 0.82, 0.75]`.
- Three-level automatic damage: `[1.00, 1.20, 1.40]`; automatic cadence: `[1.00, 0.86, 0.75]`.
- Existing range, count, cap, and base cadence arrays remain the raw weapon identity. Each level's stored effective damage and cadence is `raw[level] * factor[level]`. Display rounding does not alter stored values.
- EMP expands to four states with raw damage `[62,62,62,62]`, radius `[285,285,285,285]`, projectile-clear radius `[325,325,325,325]`, fixed stun `2.1`, base cooldown `[13,13,13,13]`, and the active factors above. Its effective damage is `[62,71.3,80.6,93]`; cooldown is `[13,11.7,10.66,9.75]`.
- Homing Missiles exposes its existing four runtime states directly as card Levels 1-4: raw damage `[25,28,32,38]`, missile count `[2,3,4,4]`, and base interval `[1.35,1.35,1.35,1.35]`, then applies the four-level automatic factors. Structure damage becomes an explicit weapon-owned array `[25,28,32,35]`; it no longer reads a shared multiplier.
- Electric Field retains raw DPS `[8,11.5,16,22]` and radius `[240,280,320,320]`; its per-level tick interval derives from `0.25 * cadence_factor`, and the effect preview publishes actual effective DPS rather than a hidden shared multiplier.
- Orbiting Blades applies the same factors to existing per-hit damage and the `0.55` target re-hit interval. Drop Mines applies them to existing damage and placement interval arrays. Auto Laser and Storm Barrage apply the three-level factors to their existing damage and cadence arrays. Counts, target caps, warning time, footprints, and collision stay unchanged.

Catalog contract after migration:

- Category card counts: Primary `2`, Auto Weapons `6`, Attack Effects `4`, Active Skill `4`, Chassis `5`, Combat `4`.
- Total: `25` cards and `85` nominal level states (`92 - 12 + 4 EMP + 1 Homing`).
- Legal maximum path: `54-56` selections, safely above the current 29-upgrade minimum-quota path.
- Build rail capacities: `2/3/2/1/5/4`, totaling 17 cells. Empty build has 17 empty cells. Auto and Active cells fill only after acquisition.

Offer contract:

- Delete the Stage-1 default-EMP enhancement guarantee.
- The first Level-up offer deterministically contains exactly one compatible unowned Active card, exactly one compatible unowned Auto Weapon card, and one compatible card from another category when available. The player still chooses only one.
- From the second transaction onward, preserve the current deterministic distinct-category pass and Stage-3 attack-card guarantee against the new legal pool.

HUD and copy contract:

- The top-left cluster always shows stage, total defeats, Dash, and one generic Active position. Before acquisition that position uses the shared active-action glyph with localized `LOCKED`; after acquisition it changes to the weapon glyph and `READY`/remaining cooldown. It never shows Homing Missiles or another automatic weapon as a privileged action slot.
- Automatic cooldowns remain in Ship Status/build detail; adding three live automatic cooldown items to the HUD is rejected as clutter and would privilege arbitrary acquisition order.
- Deployment retains four control rows and labels the active binding as usable after card acquisition.
- First-acquisition Active descriptions append localized `Press %s to use`, formatted with `VehicleInputProfile.action_display_name(active_skill, bindings)`. First-acquisition Auto Weapon descriptions append localized `Fires automatically`. Enhancement descriptions omit the tutorial suffix.

Early XP contract:

```text
base(n) = min(96, 6 + round(1.5n + 0.32n^2))
required(n) = base(n) + 4  when 0 <= n < 10
required(n) = base(n)      when n >= 10
```

- First twelve requirements become `10/12/14/17/21/26/31/36/42/49/53/61`.
- Stage 1's first 48 quota enemies are 24 swarm and 24 standard, averaging 4 XP per defeat, so the surcharge is approximately one additional ordinary kill per early level.
- The first ten requirements cost 40 more XP in total. The authored `1968 XP` minimum path still reaches Level 30 with 29 upgrades; stage distribution changes from `9/5/4/5/6` to `9/4/4/6/6`.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Defaults | `VehicleRunBuild` falls back to EMP; Secondary runtime always publishes/fires Seeker | build and weapon runtimes; passing baseline validators | Empty state; both become ordinary cards | 1.1-1.4 |
| Shared policies | Four resources provide 12 global modifier levels | catalog/resources/runtime stat calls | Delete IDs/stats and embed curves in each weapon definition | 1.2-2.3 |
| Slot meaning | Current UI has 5 Secondary and 3 Active cells although gameplay limits differ | catalog descriptors, snapshot builder, current Upgrade capture | Three equal Auto cells and one Active cell, all empty initially | 3.1-3.3 |
| First-use teaching | Current copy assumes default EMP/Seeker and can be rebound | localization, input profile, Deployment | Input-aware manual hint and automatic-use hint only on `NEW` | 3.2-3.4 |
| XP speed | First requirement is 6; Stage-1 average is 4 XP/kill | experience runtime, field-drop rules, authored opening | First ten requirements only receive `+4` | 4.1-4.2 |
| Progression capacity | Current catalog is 28/92 and minimum path grants 29 upgrades | catalog and experience validator | New 25/85 catalog retains 54-56 legal selections and Level 30 | 1.2, 4.2 |
| Persistence | Build state is run-scoped and reset; no saved-run serializer exists | build/run source search | No migration or legacy card remapping | 1.4 |
| Visual assets | Each live card needs one authored PNG; four removed cards have production images; EMP has no upgrade art | manifest, semantic provider, visual spec | Remove four entries/assets, add one approved EMP card image; manifest total 78 | 3.4 |
| Architecture overlap | `VehicleRun` is oversized but separate plan owns extraction | active long-term contract and architecture audit | Only adapt narrow calls/snapshots here | 2.3, 3.3 |

Readiness statement:

- Every material product, data, UX, ownership, balance, and validation decision is closed.
- Godot `4.7.1.stable.official.a13da4feb` and the repository wrapper are available. The six focused baseline validators named below pass at the starting commit.
- The EMP image has a predetermined art contract and explicit approval gate; its absence blocks only production integration, not a redesign by the executor.
- Remaining unknowns are implementation-local and cannot change this contract.

## Tasks

### Phase 1: Establish empty weapon state and the new catalog

Goal: make the build model truthful before changing combat behavior or UI.

Source owners: `data/cards/vehicle/`, `scripts/cards/vehicle_upgrade_definition.gd`, `scripts/cards/vehicle_upgrade_catalog.gd`, `scripts/cards/vehicle_run_build.gd`, product specs, upgrade validators.

- [ ] **1.1 Align product and design contracts.**
  - Change: update `docs/product/vehicle_game_spec.md`, `docs/product/vehicle_upgrade_catalog.md`, `docs/product/vehicle_weapon_balance_spec.md`, `.agents/design/DESIGN.md`, and `docs/design/VISUAL_SYSTEM.md` for no defaults, 25/85, one Active, three equal Auto Weapons, 17 build cells, the stable locked-to-equipped Active HUD position, and 78 production images.
  - Accept: targeted searches find no active claim that Seeker/EMP starts equipped, shared weapon cards exist, category capacity is `2/5/2/3/5/4`, the HUD always has five items, or the manifest must contain 81 images.
- [x] **1.2 Replace the card/schema contract.**
  - Change: delete the four shared resources; add `emp.tres`; make Homing max 4; remove shared modifier stat IDs and built-in/optional/enhancement semantics that no longer represent the categories; set counts to 25/85 and limits to one Active/three Auto Weapons.
  - Accept: catalog validation enumerates exactly the locked IDs, counts, states, category counts, compatibility, and 54-56 legal path.
- [x] **1.3 Make offers teach the new start.**
  - Change: delete the EMP-enhancement special case and implement the locked first Level-up composition without changing frozen transaction safety.
  - Accept: same seed/source/serial repeats the same three IDs; the first offer has one Active, one Auto, one other; stale/unoffered/double submissions remain rejected.
- [x] **1.4 Make build transitions explicit.**
  - Change: `VehicleRunBuild` returns empty active state until acquisition, maps all four active card IDs, counts all six Auto Weapon IDs equally, and rejects a second active or fourth automatic first acquisition.
  - Accept: reset build owns zero weapons; valid transition traces reach one Active/three Auto; same-card levels remain legal; no legacy removed ID is accepted.

Phase gate:

- Run upgrade-system and catalog-focused assertions once; do not proceed if the data model can still create a default or shared weapon state.

### Phase 2: Move combat strength into each weapon

Goal: preserve known Level-1 and fully-stacked endpoints without any cross-weapon modifier.

Preconditions:

- Phase 1 passes.

Source owners: `data/weapons/vehicle/active/`, `data/weapons/vehicle/secondary/`, active/secondary definition/catalog/runtime scripts, active recharge, `scripts/cards/vehicle_upgrade_effect_preview.gd`, narrow `VehicleRun` consumers.

- [x] **2.1 Extend definition resources with level-owned cadence.**
  - Change: Active definitions own cooldown-by-level and auxiliary-size-by-level where applicable; Secondary definitions own behavior-appropriate interval/re-hit arrays and explicit Homing structure damage. Store the locked effective arrays, not runtime reads of build-wide stats.
  - Accept: definition validators prove every array length equals card max level and every displayed value comes from the same definition used by combat.
- [x] **2.2 Remove shared multiplier execution.**
  - Change: delete active/secondary shared-stat reads and parameters, make empty state a no-op, make EMP/Homing require Level 1, and consume only weapon-owned values.
  - Accept: no source reference to the four shared IDs/stat IDs remains; empty state emits no active/Seeker attack; all ten weapon families hit the exact locked Level-1 and max endpoints.
  - Guard: active recharge credits remain ignored while no active weapon exists and apply normally after acquisition.
- [x] **2.3 Preserve mutation and capacity ownership.**
  - Change: adapt only the existing weapon event/intent boundary in `VehicleRun`; keep enemy, structure, projectile, effect, collision, and capacity mutation in their current owners.
  - Accept: active/secondary/effect/weapon-balance validators pass with unchanged projectile/effect caps, exact footprints, target caps, and hit rules.

Phase gate:

- Run `validate_vehicle_active_weapons.gd`, `validate_vehicle_active_recharge.gd`, `validate_vehicle_secondary_weapons.gd`, and `validate_vehicle_weapon_balance_contract.gd` once after Phase 2 acceptance.

### Phase 3: Make every player-facing surface truthful

Goal: remove default/shared affordances and teach new weapons at first acquisition without adding UI clutter.

Preconditions:

- Phase 2 passes.

Source owners: build/offer snapshot presenters, shared Upgrade rail/cells/rows, gameplay HUD/presenter, Deployment, Ship Status, Result, input profile, localization, semantic asset provider/manifest, product visual owners.

- [x] **3.1 Publish the 17-cell build snapshot.**
  - Change: Auto Weapons uses three acquisition-order cells; Active uses one cell; both are empty before acquisition. Remove synthetic EMP and nested shared records. Upgrade and Result consume the same snapshot.
  - Accept: empty snapshot has 17 empty cells; three Auto families and one Active occupy their exact cells; levels update in place; a maximal legal build fits without truncation.
- [x] **3.2 Add input-aware acquisition descriptions.**
  - Change: mark weapon activation mode in gameplay-owned offer data; compose the localized current-binding/manual or automatic suffix only for first acquisition and accessibility text.
  - Accept: default Shift and one remapped key render correctly; every Auto Weapon says it fires automatically; later levels do not repeat tutorial copy; Korean/English text fits.
- [x] **3.3 Simplify HUD and Deployment.**
  - Change: remove the fixed Seeker HUD item, keep one stable generic Active position as `LOCKED` until owned, preserve stage/defeats/Dash and minimap placement, and change Deployment from EMP-specific wording to the acquired-active contract.
  - Accept: run start has no false READY/default weapon; acquiring any active replaces the one placeholder with its glyph/cooldown without reflow; automatic acquisitions do not add arbitrary action items; controls remain complete and remappable.
- [ ] **3.4 Replace semantic artwork coverage.**
  - Change: under the canonical authority pair, create one flat-stencil EMP card-art candidate, obtain exact approval, add `upgrade/emp`, remove the four obsolete card entries/images, and update provider/coverage counts. Do not create UI chrome or effect raster.
  - Accept: approved EMP art resolves at card size; every one of 25 card IDs has one artwork identity; no removed ID/file/manifest entry remains; total production image count is exactly 78.

Rendered gate:

- Capture and inspect Korean and English at 960x540 and 1280x720 for empty build, first Active offer, first Auto offer, mixed acquired build, popover, gameplay before/after active acquisition, Deployment, Ship Status, and Result. Add the existing 200% text state because dynamic binding/description wrapping changed.

### Phase 4: Slow early levels without changing the run endpoint

Goal: require roughly one extra ordinary kill for each of the first ten upgrades and keep the minimum route at Level 30.

Source owners: `scripts/progression/vehicle_experience_runtime.gd`, `tools/validation/validate_vehicle_experience.gd`, XP copy in product specs and HUD fixtures.

- [x] **4.1 Implement the bounded surcharge.**
  - Change: add `EARLY_REQUIREMENT_SURCHARGE := 4` and `EARLY_SURCHARGE_LEVEL_COUNT := 10`; apply it after the current capped base formula only for progression indices 0-9.
  - Accept: first twelve requirements are exactly `10/12/14/17/21/26/31/36/42/49/53/61`; Level 11 onward equals the prior formula.
- [x] **4.2 Re-lock the authored route cadence.**
  - Change: update deterministic route expectations to `9/4/4/6/6`, retain total `1968 XP`, Level 30, 29 upgrades, carry behavior, MAX behavior, shard capacity, and recall behavior.
  - Accept: the full experience validator passes and proves all named totals; no XP award or enemy drop value changes.

### Phase 5: Integrate, audit, and hand off

Goal: close cross-module, visual, localization, and production-path regressions without mixing in later campaign work.

- [ ] **5.1 Run focused source gates.**
  - Change: run the validation matrix below after all phases cohere.
  - Accept: every focused validator, Godot import, visual-authority validator, asset coverage check, and `git diff --check` passes.
- [ ] **5.2 Run the production Web path and focused interaction.**
  - Change: export with `./tools/export_web.ps1`; if browser interaction is needed, first use `$npjt-port-guard` and the fastrun Codex lane. Exercise no-weapon start, first two level-ups, Active input before/after acquisition, three-Auto limit, Active exclusivity, Upgrade focus/confirm, pause/Result return flow, and remapped binding text.
  - Accept: built Web has zero console/runtime errors, no stale default/shared copy, no clipping or focus loss, and matches the locked transitions.
- [ ] **5.3 Run the scoped quality audit and commit.**
  - Change: use `$codebase-quality-auditor` on changed APIs/shared UI/data owners, correct only small task-owned findings, commit coherent checkpoints, and update this plan's checkboxes/progress evidence.
  - Accept: no removed policy remains as dead code/data/art; no duplicate owner or new `VehicleRun` responsibility appears; task-owned commits are clean.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | One changed-owner validator plus `git diff --check` | After a coherent owner change | Relevant input changes |
| Catalog gate | `./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_upgrade_system.gd` | Phase 1 passes | Catalog/build/offer input changes |
| Weapon gate | Active, recharge, secondary, and weapon-balance validators named in Phase 2 | Phase 2 passes | Weapon definition/runtime input changes |
| UI gate | Upgrade UI, HUD presenter, rewards/UI/audio, input binding, localization validators plus named captures | Phase 3 passes | Snapshot/UI/localization/input changes |
| XP gate | `validate_vehicle_experience.gd` | Phase 4 passes | XP/drop/stage input changes |
| Visual gate | semantic provider/asset coverage validators and `./tools/validation/validate_cardborne_visual_authority.ps1` | EMP art or manifest changes | Visual input changes |
| Final gate | Godot import, `./tools/export_web.ps1`, built-Web interaction | All phases pass | Runtime/resource/UI input changes |

Baseline evidence at plan creation:

- `./tools/godot.ps1 --version` returned `4.7.1.stable.official.a13da4feb`.
- `validate_vehicle_upgrade_system.gd`, `validate_vehicle_upgrade_ui.gd`, `validate_vehicle_secondary_weapons.gd`, `validate_vehicle_active_weapons.gd`, `validate_vehicle_experience.gd`, and `validate_vehicle_rewards_ui_audio.gd` all passed before implementation.
- `docs/design/VISUAL_SYSTEM.md` was read completely; the canonical 1448x1086 sheet was inspected at original detail; observed SHA-256 `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889` matched the required value. No raster was created or edited during planning, so actual image-reference input was not applicable and no asset approval is claimed.

Validation rules:

- Run the narrowest check that proves the current task; run each phase/final gate once at its declared checkpoint.
- Do not call a source, visual, export, or interaction result a performance pass. This plan has no performance claim.
- Do not repeat a passing broad gate unless a relevant input changed.
- A screenshot proves layout/state only; interaction verifies input and transitions.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| EMP card art is not exactly approved | Stop manifest integration and final visual/Web gates; preserve data/runtime progress | Do not reuse an action glyph, effect frame, or removed policy art as a substitute |
| First acquisition is stronger than the locked Level-1 baseline | Correct the weapon curve/data mapping | Do not weaken enemies or XP to compensate |
| Fully leveled endpoint differs from the locked former shared maximum | Correct definition arrays and preview/runtime consumers together | Do not reintroduce a global multiplier |
| Three equal Auto Weapons cannot be represented without old built-in/optional flags | Replace the obsolete schema with category-count compatibility | Do not retain a hidden Homing privilege |
| The four-item HUD cluster overlaps minimap/announcement at a supported state | Adjust shared cluster spacing within the visual contract while keeping one stable Active position | Do not add an Auto cooldown dock, hide state by reflow, or add local chrome |
| Minimum route no longer reaches Level 30 | Stop and correct only the early surcharge application/test | Do not change enemy XP or late cap silently |
| A change requires broad `VehicleRun` extraction | Stop that branch and defer it to the related long-term contract | Do not combine structural refactor with weapon migration |
| A verified material fact contradicts this contract | Stop the affected branch and revise the contract | Do not let the executor choose a new product/UX/balance contract |

Implementation-local discoveries may be handled inside the locked contract when they cannot change visible behavior, ownership, architecture, balance endpoints, safety, or acceptance.

## Risks

- Removing two globally efficient damage/cooldown paths reduces broad multi-weapon scaling even though each selected weapon can reach the old fully-stacked endpoint. This is intentional and supports the harder-run direction; first-acquisition strength must not rise.
- A first offer with both weapon categories may create a strong opening choice. It is intentional because the run otherwise begins with only primary fire and Dash, and it avoids an unlucky no-weapon opening.
- The Active placeholder changes glyph/value state without changing cluster width. Rendered overlap, `LOCKED` legibility, and 200% text checks are mandatory.
- Card and production-image counts are duplicated in several validators/specs; stale numeric contracts must be removed in the same phase.
- Existing captures are fixture evidence, not proof of actual play difficulty. This plan changes only the exact early threshold requested; broader difficulty remains in the long-term contract.

## Rollback and Safety

- Keep phases in separate coherent commits so weapon data/runtime, UI/assets, and XP can be diagnosed independently.
- Remove the old card resources/assets only in the same commit that removes every consumer and updates coverage.
- Do not keep compatibility aliases for removed run-only card IDs; no saved run requires them.
- If a phase fails, revert only that task-owned phase commit rather than resetting unrelated work.

## Decision Notes

- 2026-08-14: remove both defaults and all four shared weapon-policy cards.
- 2026-08-14: treat Homing Missiles exactly like the other five automatic weapons and use three equal automatic slots.
- 2026-08-14: retain exclusive run-long active commitment; do not add deletion, respec, or repeated alternative Lv.0 offers.
- 2026-08-14: select endpoint-preserving interpolation because it keeps Level 1 stable while removing global synergy.
- 2026-08-14: use `+4 XP` for the first ten requirements because Stage-1 ordinary enemies average 4 XP and the minimum route still reaches Level 30.
- 2026-08-14: keep ten-stage, density/performance, and `VehicleRun` extraction in the related long-term plan; they are not implemented in this batch.
- 2026-08-14: generated and technically inspected the exact 192×192 EMP candidate at
  `docs/design/visual-replacement-workbench/previews/emp-upgrade-card-v1/emp-upgrade-card-candidate-v2-192.png`;
  production integration remains blocked on BK's exact asset approval.

## Open Questions

No material implementation decision remains open. Exact EMP artwork approval is a required production gate, not permission for the executor to redesign the card or visual system.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 3 approval gate.
- Next task: obtain exact approval for the EMP candidate, then finish 1.1 and 3.4,
  run the rendered/visual/final Web gates, audit, commit, and mark the plan done.
- Last completed gate: catalog, active weapon, active recharge, automatic weapon,
  weapon-balance, build snapshot, HUD presenter, localization, input binding,
  rewards/UI/audio, Result builder, and XP focused validators passed. Upgrade UI
  and stage-layout validation now fail only because `upgrade/emp` is intentionally
  absent from production until approval.
- Update rule: after a checkpoint passes, record concise evidence, check the task, and advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check and named phase/final gate passes.
- The product starts with no automatic/active weapon, supports one of four Active and three of six equal Auto Weapons, and contains no shared weapon-policy card or stat.
- Catalog, build rail, art coverage, first-use copy, HUD, Ship Status, Result, and Korean/English surfaces agree on the same state.
- First ten requirements and the minimum-path Level-30 result match the locked values.
- Durable behavior is incorporated into its owning specs and this plan becomes `done` only after implementation.

Replan when:

- A material discovery invalidates a locked product, balance, ownership, visual, or validation decision.

Do not replan or stop for:

- Implementation-local mechanics already contained by the named owners.
- A passing check whose relevant inputs have not changed.

Anti-rework rules:

- On start or resume, read this contract and inspect the worktree only enough to confirm the next unchecked task's inputs.
- Treat checked tasks and recorded passing evidence as complete unless a relevant input changed or evidence is missing.
- Rerun a failed check only after a relevant implementation change or new causal hypothesis.
- Update the checkbox and single progress pointer together; do not mirror progress elsewhere.
- If reality contradicts a material decision, revise the contract instead of redesigning during implementation.
