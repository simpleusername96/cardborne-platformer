---
type: plan
status: active
owner: BK
created: 2026-08-07
last_reviewed: 2026-08-07
topic: Minimal vehicle upgrade catalog and reward contract
scope: Upgrade taxonomy, live catalog, runtime cleanup, card presentation, offer and application contracts, product documentation, and focused QA
related:
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/product/vehicle_upgrade_catalog.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/design/cardborne-universal-art-style-reference.png
  - ../../docs/reports/game-system-review/effects-upgrades-as-is.md
  - ./2026-08-02-pre-asset-code-stabilization.md
---

# Minimal Vehicle Upgrade Catalog

## Why and Context

The live catalog grew to 41 cards and 83 level states. Its `family` field mixes
mechanic ownership, trigger, result, and reward grouping. Several cards only
repeat small numeric changes, duplicate an existing role, or add narrow runtime
branches that are harder to read than the choice is worth.

On 2026-08-07 the user explicitly required `Pickup Magnet` to remain and
authorized redesigning the remaining structure and deleting cards down to a
minimal set. This decision supersedes the earlier 41-card preservation clause
in this plan and in the current product specification.

The already completed combat-effect work remains recorded in Git commits
`f3dbcc5b` and `b9e66b86`. This plan now owns only the unfinished upgrade pass.

## Outcome

Complete the pass when all of the following are true:

1. the live catalog contains exactly 19 cards and 39 level states;
2. every card belongs to one of six user-facing build categories whose meaning
   is stable: `primary`, `secondary`, `element`, `dash`, `emp`, or `chassis`;
3. `change_kind` and `secondary_slot_kind` describe how a card changes the build
   without overloading the category;
4. deleted cards have no gameplay producer, resource, localization entry, or
   focused validator dependency;
5. every reachable reward transaction freezes exactly three unique legal cards
   and rejects any application outside that frozen offer;
6. behavior cards distinguish a first unlock from a later enhancement in Korean
   and English without duplicating their description;
7. `docs/product/vehicle_upgrade_catalog.md` lists every category, card, level,
   value, slot rule, and offer rule as the canonical catalog specification;
8. focused validators, Godot import, production Web export, and representative
   rendered upgrade-card QA pass without new visual assets or clipping.

This plan does not declare Cardborne performance-qualified. Removing obsolete
Ion Wake gameplay code may change a synthetic performance fixture. If that
fixture must change, record it as a workload-contract change that requires a
later re-baseline; do not change release thresholds or make a performance claim.

## Authority and Preflight

Authority order:

1. the user's 2026-08-07 catalog-reduction decision;
2. `docs/product/vehicle_game_spec.md` for the five-stage run and reward model;
3. the new `docs/product/vehicle_upgrade_catalog.md` for the exact live catalog;
4. `docs/design/VISUAL_SYSTEM.md` for card presentation and media rules;
5. gameplay state and collision code for live behavior truth.

Visual-authority preflight for this pass:

- `docs/design/VISUAL_SYSTEM.md` was read completely on 2026-08-07;
- the canonical reference sheet was inspected at original detail;
- observed and expected SHA-256:
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`;
- no raster, ImageGen, SVG, font, shader-art, or audio output is planned;
- existing semantic upgrade artwork remains available even if a current card no
  longer consumes every identity.

UI work is Level 2 under the UI/UX gate: retain the existing three-card modal,
theme, artwork placement, focus behavior, and responsive layout. Change only
the semantic labels and card data necessary to expose the new contract.

## Proposed Design

### Classification axes

`category` is a player-facing build lane, not the runtime owner of every effect:

| Category | Meaning |
| --- | --- |
| `primary` | Held-fire weapon damage, cadence, or projectile form |
| `secondary` | Built-in Seeker behavior or an optional autonomous weapon |
| `element` | One elemental status package applied by player attacks |
| `dash` | A new result caused by completing or crossing with Dash |
| `emp` | A new result caused by the EMP skill |
| `chassis` | Persistent vehicle movement, collection, or survivability stats |

Orthogonal fields:

- `change_kind`: derived as `stats`, `unlock`, or `enhance` for the next level;
- `secondary_slot_kind`: empty, `built_in`, or `optional`;
- optional secondaries consume one of two slots only on first acquisition.

### Locked live catalog

| Category | Cards and max levels |
| --- | --- |
| Primary | `kinetic_rounds` 3, `rapid_cycle` 3, `forked_muzzle` 2, `phase_lance` 2 |
| Secondary | `twin_seekers` 2, `marked_salvo` 1, `ion_field` 3, `orbit_blades` 3, `wake_mines` 3 |
| Element | `incendiary_core` 1, `toxin_core` 1, `cryo_core` 1 |
| Dash | `coolant_wake` 1, `phase_shear` 1 |
| EMP | `emp_aftershock` 1, `static_aegis` 2 |
| Chassis | `tuned_thrusters` 3, `pickup_magnet` 3, `reinforced_hull` 3 |

The three optional secondaries are Ion Field, Orbit Blades, and Wake Mines.
Keeping three choices for two slots preserves one meaningful exclusion decision
without retaining the fourth autonomous weapon. Built-in Seeker does not
consume a slot.

### Locked deletions

Delete these 22 card definitions and their card-owned behavior paths:

- Primary: `accelerator_coil`, `mass_driver`, `overclock_cycle`,
  `ricochet_matrix`, `stabilizer`;
- Secondary: `escort_drone`, `hunter_firmware`, `phase_seeker`, `seeker_cycle`,
  `seeker_warhead`;
- Element follow-ups: `thermal_compound`, `concentrated_toxin`, `contagion`,
  `deep_freeze`;
- Dash: `dash_capacitor`, `ion_wake`, `ram_pulse`;
- EMP/defense: `aegis_cycle`, `emp_capacitor`, `emp_focus`, `relay_overload`,
  `siphon_matrix`.

Deletion rationale is role-based: remove hidden handling stats, duplicated cycle
systems, incremental status branches, narrow target exceptions, redundant
autonomous ranged fire, and mechanics whose runtime cost exceeds their decision
value. Keep cards that change a weapon form, positioning rule, target priority,
skill result, or a plainly legible chassis baseline.

### Resource schema

Keep only these definition fields:

- `id`, `title_key`, `description_key`, `category`, `artwork_asset_id`;
- `secondary_slot_kind`, `max_level`, and `modifiers`.

Remove `summary_keys`, `family`, `requirement`, `exclusion_group`, `source_tags`,
and `behavior_ids`. All live rewards share the same level-up/boss eligibility,
all prerequisites disappear with the element branches, all artwork is explicit,
and behavior cards are exactly the definitions with no numeric modifiers.

The presenter returns `category`, `category_key`, `change_kind`, localized change
label, comparison rows, and the one non-duplicated description. Missing explicit
artwork remains a validation failure; there is no presenter fallback.

### Offer and application contract

The catalog deterministically shuffles compatible definitions from seed, stage,
source, and serial. It first takes at most one card per category, then fills from
the remaining shuffled definitions. It has no first-run forced category, forced
Tuned Thrusters, element branch priority, or behavior-card priority.

The catalog has 30 non-optional level states. A run can add six states from any
two optional secondary families, for at least 36 reachable states. The authored
quota path has 20 level-up choices plus five boss rewards. Before the 25th pick,
at least 12 states remain; with a three-level maximum, at least four definitions
remain legal. Therefore the shipped route can supply three unique cards without
duplicates or fabricated fallbacks.

`VehicleRun` verifies the exact size before opening the modal. A failure keeps
the reward transaction paused and exposes diagnostic context. Application is
legal only while the upgrade modal transaction is active and only for an ID in
the exact frozen `current_card_offer`.

## Scope

In scope:

- card resources, schema, category localization, presenter, build state, offer,
  frozen application boundary, and card UI semantics;
- deletion or simplification of runtime branches owned only by deleted cards;
- focused validators and fixtures that encode 19 cards, 39 states, three
  optional secondaries, two optional slots, exact offers, and all level effects;
- product specification, canonical catalog Markdown, authority links, and
  archival labeling of the prior 41-card evidence;
- existing visual-authority validation and rendered Korean/English card QA.

Out of scope:

- changing the five stages, quotas, bosses, controls, manual aim, held primary
  fire, Dash, built-in passive Seeker, base EMP, pickups, or reward frequency;
- new cards, rerolls, declines, shops, meta-progression, reward sources, assets,
  dependencies, or broad enemy and boss tuning;
- deleting existing shared visual assets or changing the visual manifest;
- changing performance thresholds or claiming release performance.

## Assumptions

- Saved upgrade builds are run-scoped and not persisted across releases.
- Level-up and boss rewards use the same live card pool.
- Three optional weapons are enough to make the two-slot rule meaningful.
- Element roots retain their current base burn, poison, and chill constants;
  only their follow-up branches disappear.
- Existing shared art may remain unreferenced by the minimal catalog because
  visual-asset retirement is an independent governed task.

## Milestones

### M1 — Lock schema and catalog tests

- Assert the exact ID set, six categories, 19 resources, and 39 states.
- Validate unique resource IDs before dictionary insertion, allowed categories,
  slot kinds, modifier operations/stat IDs, explicit artwork, and bilingual keys.
- Enumerate reachable reward states and require three unique legal definitions.
- Add frozen-offer apply tests for valid, unoffered, stale, and double submit.

Stop when failures identify only the intended production changes.

### M2 — Reduce the catalog and runtime

- Delete the 22 `.tres` definitions and obsolete localization rows.
- Rename `family` to `category` across resources, snapshots, UI, and validators.
- Remove dead definition fields and presenter fallbacks.
- Simplify element, Seeker, primary, Dash, EMP, lifesteal, cycle, and trail paths
  that exist only for deleted cards; delete the cycle runtime if no caller remains.
- Preserve base weapon, Seeker, element, Dash, EMP, pickup, health, and optional
  weapon behavior owned by retained cards.
- Keep existing visual assets and manifest contracts unchanged.

Commit after focused gameplay and upgrade validators pass.

### M3 — Finish presentation and documentation

- Show `New behavior` / `새 행동` for first acquisition and `Behavior upgrade` /
  `행동 강화` for later levels; numeric cards keep current-to-next rows.
- Preserve one description, one art region, three cards, the 0.35-second input
  guard, and responsive focus/selection behavior.
- Add `docs/product/vehicle_upgrade_catalog.md` with exact Korean/English titles,
  categories, slot ownership, every level effect, base constants needed to
  interpret those effects, and offer/application rules.
- Update product/authority indexes and archive the 41-card AS-IS evidence as the
  pre-reduction baseline.

### M4 — Validate and close

- Run focused gameplay, UI, localization, document, and visual-authority checks.
- Import with Godot 4.7.1 and export the production Web build.
- Inspect representative numeric, unlock, and enhancement cards in Korean and
  English at 960x540, 1280x720, and 1920x1080.
- Run the codebase quality audit and make only small task-scoped corrections.
- Commit task-owned changes, move durable decisions into specs, then delete this
  completed plan in a separate lifecycle commit.

## Test Plan

Targeted while implementing:

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_upgrade_system.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_upgrade_ui.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_ui_localization.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_secondary_weapons.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_status_stacking.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_primary_weapon.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_experience.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_build_snapshot.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_run.gd
```

Final boundary, run once after stabilization:

```powershell
.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_ui_layout.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_semantic_asset_provider.gd
.\tools\validation\validate_document_authority.ps1
.\tools\validation\validate_cardborne_visual_authority.ps1
.\tools\export_web.ps1
git diff --check
```

Do not run the expensive performance qualification pair. If its synthetic trail
fixture changes, update only the fixture contract validator and record that a
future baseline is required.

## Rollback and Safety

- Card and script deletions remain recoverable through Git history.
- Do not stage, revert, or clean unrelated user changes.
- Do not change dependencies, visual assets, manifests, or performance limits.
- Commit schema/catalog/runtime changes before documentation closure so the
  coherent gameplay rollback point is obvious.
- If the 25-choice route cannot prove three legal cards with the locked set,
  stop before inventing duplicates or weakening the mandatory-choice contract.

## Risks

- Deleted IDs may survive in capture fixtures, report strings, damage source
  names, or synthetic performance setup even after resources disappear.
- Removing Ion Wake can change the shape of a performance workload even if its
  aggregate object count stays constant; treat this as unqualified until a later
  controlled re-baseline.
- Category-key renaming can leave Korean or English blank at runtime.
- A behavior enhancement label may add height pressure at 960x540.
- Direct dictionary insertion can hide duplicate card IDs unless validation
  checks file resources before constructing the ID map.

## Open Questions

None. The latest user decision, current route counts, and locked set above close
the product choices required for implementation.

## Decision Notes

- 2026-08-07: Keep `Pickup Magnet`.
- 2026-08-07: Replace the 41-card preservation contract with the 19-card set.
- 2026-08-07: Keep three optional secondaries for a real choose-two decision;
  remove Escort Drone because passive Seeker already owns autonomous ranged fire.
- 2026-08-07: Replace `family` with six player-facing categories and keep slot
  ownership/change kind as separate axes.
- 2026-08-07: Keep all existing shared artwork; asset retirement is out of scope.
- 2026-08-07: No performance claim or threshold change belongs to this pass.
- 2026-08-07: Focused gameplay/UI/document validators, three-size bilingual
  captures, Godot import, Web export, and built-Web browser smoke passed. The
  performance workload change remains explicitly unqualified pending re-baseline.

## Progress

- [x] Read current product, design, report, runtime, resource, and validation
  authority surfaces.
- [x] Complete UI/UX, visual-authority, domain-language, document-lifecycle, and
  performance-guard preflight.
- [x] Lock the 19-card catalog, 39 states, six categories, and 22 deletions.
- [x] M1: encode schema, catalog, offer, and application contracts.
- [x] M2: implement catalog and runtime reduction.
- [x] M3: finish card presentation and canonical catalog documentation.
- [x] M4: validate, audit, commit, and close this plan.

## Prior Implementation Record

- `f3dbcc5b`: reduced the production visual-event catalog to four transients and
  moved barrier, Marked, and Sheared feedback to direct state ownership.
- `b9e66b86`: centralized the minimal combat-cue policy and removed duplicate
  projectile routes and general-enemy radar contacts.

Those commits passed their focused runtime, capture, visual-authority, import,
and Web-export checks. They are historical context, not work to repeat here.
