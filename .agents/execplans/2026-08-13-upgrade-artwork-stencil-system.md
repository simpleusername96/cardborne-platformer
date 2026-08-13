---
type: plan
status: done
owner: BK
created: 2026-08-13
scope: Replace and integrate all 28 vehicle upgrade-card artwork assets with the user-selected flat stencil system.
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/product/vehicle_upgrade_catalog.md
---

# Upgrade Artwork Stencil System - Execution Contract

Replace the shared and world-asset-derived artwork currently used by Cardborne's 28 upgrade cards with one distinct authored PNG per card, all using the user-selected Direction C stencil language. Generate in three parallel ownership groups, integrate through the existing semantic asset provider, and keep gameplay and UI layout unchanged.

## Purpose

- Objective: make every live upgrade card visually distinct without allowing the artwork system to accumulate extra rendering styles.
- Deliverable: 28 transparent `192×192` PNGs, 28 `upgrade/<card_id>` manifest entries, 28 matching card resource references, an upgrade-specific visual rule, and focused validation updates.
- Completion state: every catalog definition resolves its own image through the semantic provider; old shared upgrade art is no longer referenced; import and focused validators pass.

## Scope and Boundaries

In scope:

- The 28 resources under `data/cards/vehicle/`.
- Upgrade PNGs under `art/visuals/production/gameplay/upgrades/`.
- Upgrade entries and counts in `art/visuals/production/gameplay/asset-manifest.json`.
- Upgrade-art rules in `docs/design/VISUAL_SYSTEM.md` and focused semantic/UI validators.

Out of scope:

- Gameplay rules, values, card offer logic, localization, UI layout, card shell, world weapon imagery, HUD glyphs, and runtime performance qualification.
- A second style exploration, per-level images, animation, procedural icon drawing, or new dependencies.

Constraints and invariants:

- The selected Direction C sheet is the user-approved task style reference; the canonical visual authority pair remains mandatory and higher authority.
- Every icon uses exactly one dominant warm-off-white stencil silhouette, one semantic accent, and one short near-black offset shadow. Maximum three visible colors; no gradients, bevels, texture, glow, material rendering, card frame, text, number, enclosing badge, or decorative background.
- Each card gets one unique image at all levels. Exact values and conditions remain text-owned.
- ImageGen authors the content. Mechanical crop, alpha removal, resize, and sheet slicing are permitted; no scripted geometry may create or repair icons.
- Preserve `192×192` canvas, centered pivot, straight RGBA, linear filtering, no mipmaps, and current semantic provider ownership.
- Concurrent dense-combat files are user-owned and excluded from this plan and commit.

Destructive or irreversible actions:

- Remove the 12 superseded shared upgrade PNGs only after all 28 card references and manifest entries have switched and repository search proves zero consumers. Git preserves recovery.

Exact actions requiring owner or user approval:

- None. The user explicitly selected Direction C and requested every upgrade asset be modified and applied.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Complete scope | `docs/product/vehicle_upgrade_catalog.md` and `data/cards/vehicle/` define exactly 28 cards | Catalog count and resource inventory | One semantic PNG per card ID | 1.1-1.3, 2.1 |
| Current reuse | Card resources point to 12 upgrade images plus several projectile/secondary world images | `artwork_asset_id` fields and asset manifest | Replace every field with `upgrade/<card_id>` | 2.1 |
| Style containment | Direction C was selected by the user | `upgrade-artwork-flat-style-parallel-v2/direction-c.png` | Lock the three-layer stencil rule; no variants | 1.1-1.3, 2.2 |
| Runtime owner | Semantic provider resolves manifest IDs and checks canvas sizes | `vehicle_semantic_asset_provider.gd` | Keep provider API unchanged; change data only | 2.1, 3.1 |
| Performance boundary | Upgrade artwork is modal/card content, not a combat hot-path owner | Performance policy and UI consumer | No gameplay/performance code or threshold change | all |

Readiness statement:

- Product scope, style, media ownership, schema, cleanup, and validation decisions are closed.
- ImageGen, the canonical references, ImageMagick mechanical tools, Godot 4.7.1 wrapper, and focused validators are available.
- Remaining unknowns are limited to generation quality within the locked style and can be rejected without changing the contract.

## Tasks

### Phase 1: Generate and normalize 28 unique icons

Goal: produce complete authored source coverage in one visual language.

Preconditions:

- Canonical visual authority preflight is complete and Direction C is visually inspected.

Source owners: `docs/design/cardborne-universal-art-style-reference.png`, `docs/design/visual-replacement-workbench/previews/upgrade-artwork-flat-style-parallel-v2/direction-c.png`, `docs/product/vehicle_upgrade_catalog.md`

- [x] **1.1** Generate and normalize the primary, activated, and element group.
  - Change: create unique stencil images for 11 assigned IDs through ImageGen sheets, then mechanically split, key, and resize.
  - Accept: every assigned file is `192×192` sRGBA with transparent corners and a distinct readable silhouette.
- [x] **1.2** Generate and normalize the secondary group.
  - Change: create unique stencil images for the 8 secondary IDs.
  - Accept: the eight files meet the same image contract and visibly distinguish weapon identities from shared damage/cooldown modifiers.
- [x] **1.3** Generate and normalize the chassis and combat group.
  - Change: create unique stencil images for the 9 chassis/combat IDs.
  - Accept: the nine files meet the image contract and avoid generic target/radar-only readings.

Batch gate:

- Exactly 28 card-ID PNGs exist, with no duplicate filenames, dimensions, or missing alpha.

### Phase 2: Integrate the per-card semantic identities

Goal: make the generated images the only live card artwork owners.

Preconditions:

- Phase 1 batch gate passes.

Source owners: `data/cards/vehicle/`, `art/visuals/production/gameplay/asset-manifest.json`, `docs/design/VISUAL_SYSTEM.md`

- [x] **2.1** Switch all card resources and the manifest.
  - Change: assign `artwork_asset_id = &"upgrade/<card_id>"`, replace shared upgrade manifest rows with 28 rows, and update total/family counts.
  - Accept: the 28 resource IDs are unique, exactly equal to the 28 manifest upgrade IDs, and every path exists at `192×192`.
- [x] **2.2** Record the compact upgrade stencil rule.
  - Change: add the selected three-layer rule to the upgrade artwork section of `VISUAL_SYSTEM.md` without changing other asset families.
  - Accept: one upgrade-art rule owns palette layers, forbidden complexity, level reuse, and text/image responsibility.
- [x] **2.3** Retire superseded shared artwork.
  - Change: remove the 12 old upgrade PNG sources after zero-consumer proof; leave unrelated generated `.import` ownership to Godot import.
  - Accept: repository search finds no old semantic IDs or paths outside historical workbench evidence.

Batch gate:

- Manifest JSON parses; all 28 resources point to existing provider entries; no gameplay or UI layout owner changed.

### Phase 3: Validate the applied system

Goal: prove asset import and card presentation contracts without real-time play QA.

Preconditions:

- Phase 2 batch gate passes.

Source owners: `tools/validation/validate_vehicle_semantic_asset_provider.gd`, `tools/validation/validate_vehicle_visual_asset_coverage.gd`, `tools/validation/validate_vehicle_upgrade_ui.gd`, `tools/validation/validate_vehicle_upgrade_system.gd`

- [x] **3.1** Update focused validator expectations.
  - Change: replace the former shared upgrade-ID sets/counts with the exact 28-card identity contract.
  - Accept: validators assert uniqueness, asset existence, canvas size, and category coverage.
- [x] **3.2** Run one focused import/validation batch.
  - Change: run the visual authority validator, headless import, semantic provider, visual coverage, upgrade system, and upgrade UI validators, plus `git diff --check`.
  - Accept: every command exits successfully with no new parser/import/runtime error.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Image batch | file count, dimensions, alpha corners, non-empty coverage | Each generation owner finishes | Its source sheet or normalization input changes |
| Integration gate | JSON/resource ID parity and zero old-ID references | Phase 2 completes | Manifest/resource inputs change |
| Final gate | authority validator, headless import, four focused Godot validators, `git diff --check` | All implementation is complete | A final-gate input changes |

Validation rules:

- Run the narrowest check that proves the current task.
- Run each named phase gate once after its tasks pass.
- Do not run live game, browser, performance, or Web QA for this asset-only task.
- Rerun a failed check only after a relevant implementation change.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A sheet violates the locked style or cell boundaries | Reject only the affected sheet and regenerate once with the same meanings and stricter prompt | Do not invent another style or manually redraw content |
| Chroma removal damages semantic colors | Choose a non-conflicting key and regenerate the affected sheet | Do not repair silhouettes with drawing tools |
| Concurrent work overlaps a task-owned file | Stop that file, preserve both sides, and coordinate before staging | Never revert or stage the concurrent dense-combat changes |
| Import creates generated `.import` files | Include only those corresponding to the 28 task-owned PNGs when required by repository convention | Do not modify unrelated import files |

Implementation-local discoveries may be handled inside the locked contract when they do not change scope, visible behavior, ownership, architecture, safety, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Complete.
- Next task: None.
- Last completed gate: Phase 3 focused validation gate.
- Completion evidence: 28 unique `192×192` transparent PNGs and exact
  card/manifest ID parity; visual authority and workbench checks; headless
  import; semantic provider, visual coverage, upgrade system, upgrade UI,
  visual replacement coverage, and rewards UI/audio validators; `git diff
  --check`.
- Update rule: after a checkpoint passes, record concise evidence, check the task, and advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check and named gate passes.
- All 28 cards resolve unique selected-style PNGs and no superseded shared identity remains live.
- The durable style decision is recorded in `VISUAL_SYSTEM.md`.
- The plan status becomes `done`; it may be retired after the durable owners and commit preserve the outcome.

Replan when:

- A material discovery invalidates the 28-card, per-card semantic identity, or selected-style contract.

Do not replan or stop for:

- Implementation-local generation, slicing, alpha, import, or validator mechanics already contained by this contract.
