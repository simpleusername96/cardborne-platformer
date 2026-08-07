---
type: plan
status: active
created: 2026-08-07
scope: Reduce and rename the live vehicle-upgrade catalog, remove obsolete upgrade runtime branches, enlarge retained Seeker and mine presentation, and update canonical bilingual product documentation.
related:
  - ../../AGENTS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/product/vehicle_upgrade_catalog.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../cardborne-performance-engineering-policy.md
---

# Streamline Upgrade Language - Execution Contract

Cardborne will ship a twelve-card, four-category, thirty-four-state upgrade catalog. The removed cards and their exclusive runtime branches will be deleted; retained mechanics will use AGY-derived Korean-first terminology, and existing Seeker/mine assets will render larger without changing collision or simulation footprints.

## Why and Context

The current nineteen-card catalog still contains generic stat increases, a targeting mark, Dash cards, EMP cards, and elemental `Core` terminology that the user rejected. The current Kinetic Rounds card is a damage multiplier, not a wall ricochet, so it must be removed. Reducing to twelve definitions leaves too little reward depth unless retained mechanics gain natural extra levels: three-level Piercing Rounds plus three-level fire, toxin, and cold packages preserve three legal cards throughout the shipped twenty-five mandatory rewards.

AGY job `20260807T095238667Z-21afb314-e225-42a1-9a38-4407d69d59dc` used `Gemini 3.6 Flash (High)` with no model runtime limit. Its terminology is accepted except for corrupted output characters and the physically incorrect Korean phrase `전류 자기장`, which becomes `전기장`.

## Purpose

- Objective: Deliver the user-approved minimal upgrade structure and complete Korean/English copy.
- Deliverable: Updated card resources, runtime behavior, localization, focused validators, product spec, and canonical upgrade catalog Markdown.
- Completion state: Exactly twelve live definitions and thirty-four total level states validate; every simulated twenty-five-choice route still returns three legal cards; removed upgrade IDs have no live references; visuals are larger only in presentation; Web export succeeds.

## Scope and Non-scope

In scope:

- Delete Kinetic Rounds, Rapid Cycle, Marked Salvo, all Dash upgrades, and all EMP upgrades.
- Rename all twelve retained card/system concepts to the accepted AGY vocabulary and align live internal IDs where the old ID would contradict the new public term.
- Change the built-in homing upgrade to two missiles at 28 damage, then three missiles at 32 damage; remove mark priority and mark bonus.
- Expand Piercing Rounds to three levels and fire, toxin, and cold statuses to three levels.
- Increase Seeker presentation scale from 4.025 to 5.0 collision radii and mine presentation half-size from 16 to 22 world units; collision, trigger, blast, cadence, and actor/projectile counts stay unchanged.
- Update localization, report-source labels, capture/performance fixtures, focused validators, and canonical product Markdown.

Out of scope:

- Base Dash and base EMP behavior, controls, cooldowns, and HUD slots.
- New cards, new assets, raster edits, balance changes outside the retained upgrade progression, optional-secondary slot count, reward count, or offer algorithm.
- Release-performance qualification or threshold changes. This work can claim focused validation and successful Web export only.

Constraints and invariants:

- Preserve manual aim, uniform held primary fire, the built-in homing secondary, three optional secondary families with a choose-two cap, independent element coexistence, and Pickup Magnet's collection behavior.
- Four categories are `primary`, `secondary`, `element`, and `chassis`.
- Total level states are 34; a legal run can access 31 after excluding one unselected optional secondary. With at most three levels per definition, seven remaining states after 24 choices imply at least three compatible definitions for choice 25.
- Existing semantic rasters and asset IDs remain unchanged. No SVG, ImageMagick authoring, raster generation, or asset approval occurs.
- The visual reference was inspected at original detail; its observed SHA-256 is `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`, matching the required value.

Destructive or irreversible actions:

- Delete seven obsolete card concepts, replace twelve retained `.tres` resources under clear IDs, and remove exclusive code and localization branches. Git history preserves recovery.

Exact actions requiring owner or user approval:

- None beyond the deletions and structural discretion already authorized in the current request. Dependencies, save schemas, performance thresholds, and raster assets are untouched.

## Assumptions and Proposed Design

- Upgrade levels are run-scoped and have no persisted save migration contract.
- The accepted live IDs are `split_muzzle`, `piercing_rounds`, `homing_missiles`, `electric_field`, `orbiting_blades`, `drop_mines`, `thermal_burn`, `bio_toxin`, `cryo_slow`, `chassis_speed`, `pickup_radius`, and `hull_integrity`.
- Fire levels use DPS/duration `2/3`, `3/4`, `4/5`; toxin uses `2/5`, `3/6`, `4/7`; cold uses slow/duration `6%/2`, `8%/2.5`, `10%/3`. Each remains capped at three stacks, and boss cold magnitude/duration stay halved.
- Public Korean elemental names use native Korean consistently: `화염 부여`, `독 부여`, `냉기 부여`. No `코어` or mixed Korean transliteration family remains.
- AGY's public vocabulary is otherwise used as drafted: `확산 총구`, `관통 탄환`, `추적 미사일`, `전기장`, `회전 날개`, `후방 기뢰`, `주행 속도`, `수거 범위`, `장갑 내구도`, with complete English counterparts.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Catalog and offer depth | `scripts/cards/vehicle_upgrade_catalog.gd` owns exact IDs/counts and deterministic three-card offers | Current constants are 19/39; validator simulates 25 choices | Replace with 12/34 and retain the 25-choice oracle | 1.1, 3.1 |
| Card data and categories | `data/cards/vehicle/*.tres` owns IDs, copy keys, category, levels, modifiers | Nineteen resources inspected directly | Keep twelve concepts in four categories and remove primary damage/fire-rate modifiers | 1.1 |
| Exclusive removed behavior | `scripts/vehicle/vehicle_run.gd`, enemy state, renderer, and damage-source catalog own mark, shear, surge, and EMP aftershock/barrier branches | Exact call sites and state fields traced with `rg` | Delete upgrade-only branches while preserving base Dash/EMP | 1.2 |
| Secondary mechanics | `scripts/player/vehicle_secondary_runtime.gd` and secondary resources own IDs, homing count/damage, optional behavior | Current homing damage decreases with count and mark adds 25% | Use 1x25 base, 2x28 L1, 3x32 L2; rename optional systems without changing their simulation values | 2.1 |
| Status payload | `scripts/combat/vehicle_status_profile.gd` owns fired-build immutable status values | Current three roots are one level with fixed values | Derive the locked three-level values from build levels | 2.2 |
| Visual sizes | visual profile and combat renderer own projectile multiplier and mine texture size | Seeker is 4.025x; mine is 16 units; gameplay radii are separate | Set 5.0x and 22 units; update focused renderer/readability checks | 2.3 |
| Language and UI | `localization/vehicle_stage.csv`, resource copy keys, offer UI, and report keys own player-facing text | AGY answer and current key usage inspected | Apply accepted bilingual copy, remove dead card/category keys, keep layout unchanged | 3.1 |
| Durable product truth | `docs/product/vehicle_game_spec.md` and `docs/product/vehicle_upgrade_catalog.md` are active specs | Both still define 19 cards, 39 states, and six categories | Update them to the implemented 12/34 four-category contract | 3.2 |
| Validation | Godot 4.7.1 wrapper and focused validators exist; Web export is required for broad runtime work | `.\tools\godot.ps1 --version` returned `4.7.1.stable.official.a13da4feb` | Run targeted checks during implementation, then import, focused integration validators, and one Web export | 4.1 |

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership, safety, and validation decision is closed.
- Required tools and dependencies are available and each named command uses the repository's PowerShell wrapper.
- Remaining unknowns are implementation-local and cannot change this contract.

## Milestones and Tasks

### Phase 1: Minimal catalog and obsolete-runtime deletion

Goal: Only the twelve approved definitions and their required runtime branches remain.

Preconditions:

- The AGY answer is immutable at its recorded external job path.
- Current worktree is clean at commit `78bfb757`.

Source owners: `data/cards/vehicle/`, `scripts/cards/vehicle_upgrade_catalog.gd`, `scripts/vehicle/vehicle_run.gd`, `scripts/enemies/vehicle_enemy_state.gd`, `scripts/combat/vehicle_damage_source_catalog.gd`

- [x] **1.1** Reduce and rename the resource catalog.
  - Change: Delete seven rejected card resources, rename the twelve retained resources/IDs, set Piercing/element levels, and restrict categories/stat IDs.
  - Accept: `validate_vehicle_upgrade_system.gd` loads exactly 12 definitions and 34 states and simulates all 25 rewards with exact three-card offers.
  - Guard: Removed IDs are absent from the live catalog and resource directory.
- [x] **1.2** Remove upgrade-only Dash, EMP, and mark behavior.
  - Change: Delete surge, shear, aftershock, static barrier, and marked-salvo state, scheduling, damage, visuals, and report-source branches; simplify base primary/EMP paths.
  - Accept: `validate_vehicle_run.gd` passes with base Dash and EMP tests but no removed-upgrade fixture.
  - Guard: Targeted `rg` finds no live removed ID or exclusive state symbol outside historical reports.

### Phase 2: Retained behavior and presentation

Goal: Retained cards have the locked behavior and requested visual readability.

Preconditions:

- Phase 1 acceptance passes.

Source owners: `scripts/player/vehicle_secondary_runtime.gd`, `data/weapons/vehicle/secondary/`, `scripts/combat/vehicle_status_profile.gd`, `scripts/vehicle/vehicle_stage_visual_profile.gd`, `scripts/presentation/vehicle_combat_renderer.gd`

- [x] **2.1** Implement the renamed secondary systems and stronger homing progression.
  - Change: Align optional system IDs and sources; use 25/28/32 damage for one/two/three homing missiles with distinct targets and no mark multiplier.
  - Accept: `validate_vehicle_secondary_weapons.gd` verifies counts, damage, distinct-target request count, choose-two slots, and unchanged mine placement behavior.
- [x] **2.2** Implement three-level status packages.
  - Change: Populate immutable fire, toxin, and cold values from the acquired levels.
  - Accept: `validate_vehicle_status_stacking.gd` verifies every level, coexistence, three-stack cap, fired-projectile immutability, and reduced boss cold.
- [x] **2.3** Increase presentation-only Seeker and mine size.
  - Change: Set Seeker scale to 5.0 and mine texture half-size to 22.
  - Accept: projectile-readability and combat-renderer validators assert the new visible envelopes.
  - Guard: Seeker collision radius remains 8; mine trigger radius remains 54 and explosion radii remain 96/108/120.

### Phase 3: Bilingual copy and canonical documentation

Goal: Every live upgrade surface and durable specification uses the final terminology and exact mechanics.

Preconditions:

- Phase 2 behavior is final.

Source owners: `localization/vehicle_stage.csv`, capture/build fixtures, `docs/product/vehicle_game_spec.md`, `docs/product/vehicle_upgrade_catalog.md`

- [x] **3.1** Apply the accepted AGY copy and update fixtures.
  - Change: Replace category/card/interface/secondary/report labels, remove dead upgrade strings, and update capture, performance, UI, HUD, and build fixtures to live IDs.
  - Accept: localization and upgrade-UI validators pass for Korean and English at supported sizes.
- [x] **3.2** Rewrite the canonical upgrade Markdown and product references.
  - Change: Record four categories, all twelve cards, all thirty-four level states, exact values, selection invariants, and removed-card rationale.
  - Accept: Docs agree with resource/runtime constants and contain no `Core`, Kinetic/Rapid/Marked, Dash-upgrade, or EMP-upgrade entry in the live catalog.

### Phase 4: Integration and handoff

Goal: The complete change is validated, reviewed, committed, and the task plan is retired after durable truth is captured.

Preconditions:

- Phases 1–3 pass their task checks.

Source owners: focused validators under `tools/validation/`, `tools/export_web.ps1`, task-owned git commits

- [x] **4.1** Run the final gates and quality audit.
  - Change: Run import, affected focused validators, native headless boot, one Web export, `git diff --check`, and `$codebase-quality-auditor`; correct only task-scoped findings.
  - Accept: Every named gate passes and no unrelated worktree change is staged.
- [ ] **4.2** Commit and retire task state.
  - Change: Create coherent task-owned commits, incorporate final truth into product specs, then remove this completed plan per `.agents/PLANS.md`.
  - Accept: Worktree is clean and recent commits contain only task-owned changes.

## Test Plan and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | `.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_upgrade_system.gd`; secondary/status/renderer validators beside their owner changes | The owned phase changes are present | Relevant owner input changes |
| Phase gate | `.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_upgrade_ui.gd`; `.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_ui_localization.gd`; `.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_run.gd` | Phase 3 is complete | UI, localization, or run input changes |
| Final gate | `.\tools\godot.ps1 --path . --headless --import`; affected focused validator set; `.\tools\godot.ps1 --path . --headless --quit-after 1`; `.\tools\export_web.ps1`; `git diff --check` | All phases pass | A final-gate input changes |

Validation rules:

- Run the narrowest check that proves the current task.
- Do not run release-performance scenarios; no performance qualification is claimed.
- Rerun a failed check only after a relevant implementation change or a new causal hypothesis.
- Record known non-blocking warnings once instead of rediscovering them.

## Rollback, Safety, Risks, and Predetermined Contingencies

Rollback and safety:

- All deletions and renames are version-controlled. Do not reset, clean, or alter unrelated files.
- Do not modify raster bytes, asset pivots, collision radii, mine gameplay radii, workload caps, dependencies, or performance thresholds.

Risks:

- Renamed IDs can leave capture or validator fixtures stale; the targeted removed/stale-ID scan and all affected validators close this risk.
- Longer Korean/English copy can overflow the fixed card layout; the existing Korean/English multi-viewport validator is the acceptance owner.
- Fewer cards can exhaust exact-three offers; the 25-choice multi-seed route and 31-accessible-state proof close this risk.

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A renamed ID is persisted outside the inspected run-scoped build | Stop, restore the stable ID or add an explicit migration contract before continuing | Do not invent save migration behavior |
| Three-card offers fail before choice 25 | Correct level-state depth inside the locked retained concepts | Do not add a new card or reduce reward count without user approval |
| Larger visuals require collision, cadence, count, raster, or threshold changes | Stop that branch and report the conflict | Visual readability does not authorize gameplay or performance-contract changes |
| A verified material fact contradicts this contract | Stop the affected branch and revise the contract before resuming | Do not choose a new product or architecture contract during implementation |

## Open Questions

None. The user delegated remaining structure, required the listed deletions and retained Pickup Magnet behavior, and requested broad acceptance of the AGY language pass.

## Decision Notes

- Kinetic Rounds is deleted because its current mechanic is damage multiplication, not a one-wall bounce.
- The one-wall ricochet card removed in the prior reduction is not restored because the user's condition applies to Kinetic Rounds' current behavior.
- Public status names use clear native Korean instead of English phonetic Korean, so a global Venom/Ice/Inferno transliteration migration is unnecessary.
- `전류 자기장` is rejected as an AGY drafting error; `전기장` is the accurate minimal correction.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 4.
- Next task: 4.2 commit and retire task state.
- Last completed gate: focused integration, native boot, visual-authority hash, and Web export passed.
- Update rule: Check tasks and advance this pointer only after their named acceptance passes.

## Completion and Stop Conditions

Complete when:

- Every task acceptance, guard, phase gate, and final gate passes.
- Durable product truth is in the two active product specs.
- This completed task plan is removed per repository policy and the worktree is clean after scoped commits.

Replan when:

- A persisted-ID contract, offer-depth contradiction, or visual/gameplay ownership conflict invalidates a locked decision.

Do not replan or stop for:

- Implementation-local mechanics already contained by this contract.
- A passing check whose relevant inputs have not changed.
