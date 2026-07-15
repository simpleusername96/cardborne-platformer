---
type: plan
status: active
owner: BK
created: 2026-07-15
last_reviewed: 2026-07-15
topic: Master-targeted production UI overhaul and measured presentation-asset adoption
scope: Functional-baseline integration, current UI asset adoption, full production-screen and HUD visual migration, and measurement-backed world-presentation dependencies
source: Owner direction through 2026-07-15, clean master audit, current functional/UI branches, active UI specifications, runtime catalogs, validators, and rendered Godot captures
related:
  - ../../docs/README.md
  - ../../docs/product/2d_platform_action_card_game_prd.md
  - ../../docs/design/PRODUCTION_UI_CONTRACT.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../docs/design/GAME_COMPONENT_ART_SYSTEM.md
  - ../../docs/design/WORLD_COMPONENT_IMAGE_PRODUCTION_PLAN.md
  - ../handoffs/2026-07-14-world-component-imagegen-session.md
  - ./2026-07-15-gameplay-validity-repair.md
  - ./2026-07-15-svg-ui-asset-catalog.md
---

# Master Production UI Overhaul ExecPlan

## Purpose

Replace the prototype-looking production UI on the `master` line with the accepted
flat, outline-free Cardborne visual language while preserving the working Traveler
flow, snapshots, commands, focus rules, localization, and responsive contracts.

The implementation order is deliberate:

1. make the latest functional branch the `master` baseline;
2. selectively adopt every already-usable production UI asset;
3. establish one shared Theme and one runtime asset owner;
4. migrate every current screen and the gameplay HUD in player-testable batches;
5. measure rather than guess the number of world-background panels and terrain
   component types;
6. leave a concrete asset-production backlog for art that does not yet exist.

This plan is active because the owner explicitly requested a complete `master` UI
replacement. It does not authorize changing gameplay rules or treating unaccepted
world-art experiments as production assets.

## Why / Context

The current game is functionally much further along than its presentation. A clean
audit of `master` at `d278184` and the current functional line found:

- three fixed stages, Safe Intermission, Arsenal Trial, Slime Court, rewards,
  Forge, merchant, retry/settlement, and the production HUD are implemented;
- `master` tracks 6 structural SVG masks and 22 semantic SVG glyphs, but runtime
  scenes and scripts contain no `res://art/` references;
- `codex/ui-readability-localization` contains the later gameplay-validity,
  localization, responsive-text, modal, merchant, intermission, and validation
  work and is a direct descendant of `master`;
- `codex/ui-visual-pass-1` diverged earlier and contains useful visual assets, but
  also older screen behavior, obsolete documentation changes, and a browser-
  inappropriate Quit action, so it must not be merged wholesale;
- that UI branch contains five `1672x941` static screen backgrounds and nineteen
  independent `512x512` RGBA illustrations covering the active Traveler, eight
  equipment models, two Spirit Stones, potion, five cards, Slime King, and Boss
  Core;
- the nineteen raster illustrations are cataloged but not wired into any runtime
  screen;
- the normal stages and boss still render prototype polygons and procedural
  backdrops; no generated world component or panorama has been accepted as
  production art.

The owner rejected the earlier assumption that every state or every object should
be generated independently. World presentation must remain terrain-first, use one
canonical component base plus overlays/effects, and prove a complete room before
catalog expansion.

## Decisions Locked With The Owner

| Topic | Decision | Source / consequence |
| --- | --- | --- |
| Integration target | `master` remains the product center; functional work wins over an older visual branch. | Do not let UI merges revert gameplay, localization, or browser contracts. |
| Existing assets | Apply all assets that fit a real runtime role before generating replacements. | Every production asset must be referenced or have an explicit defer/reject reason. |
| Background count | Do not lock an arbitrary count such as three panels. | Derive the count from stage bounds, supported viewport, scroll scale, overscan, panel size, and seam overlap. |
| UI construction | Panels, buttons, labels, values, focus, disabled state, and live feedback remain Godot Controls/Theme/SVG. | Do not bake complete screens or state into bitmap images. |
| Art construction | Detailed portraits, items, cards, static backdrops, terrain, actors, and world components are raster assets. | UI raster art does not become a gameplay sprite merely because the subject matches. |
| Stateful components | Use one canonical base body and separate overlays, movable parts, particles, transforms, or shaders. | Do not regenerate full vent/platform/chest bodies per state. |
| Visual direction | Flat-color, outline-free, low-noise ancient industrial ruins; no micro-speckle, stains, decorative borders, or nested ornamental panels. | Reuse `UI_VISUAL_SYSTEM.md`; do not introduce a competing style document. |
| Review medium | Real Godot screens and gameplay-scale galleries are authoritative. | Figma is not a prerequisite or delivery target for this work. |

## Assumptions And Open Decisions

| Topic | Current assumption / suggested default | Why it matters | Resolution gate |
| --- | --- | --- | --- |
| Functional baseline | Fast-forward or merge the current functional branch into `master` before visual implementation. | UI work on `d278184` would reintroduce already-fixed behavior and copy. | Baseline release checks and branch diff review in Milestone 0. |
| Implementation branch | Create `codex/master-ui-overhaul` from the updated `master`; do not work directly in a dirty main worktree. | Isolates visual migration while keeping `master` authoritative. | Confirm clean updated `master`, then branch. |
| UI visual spec | Keep `UI_VISUAL_SYSTEM.md` draft during the first cross-screen spike; promote it only after rendered evidence passes. | Prevents an unproven visual proposal from becoming canonical. | Milestone 2 evidence review. |
| Static backgrounds | Main Menu, Hero Preparation, and Run Result use full-screen art. Shell Settings may use its background; in-run Settings keeps the live scene. Forge uses the live Safe Intermission behind its centered modal, with `forge.png` used only as a restrained modal/content crop if it helps. | Blind one-to-one wiring would violate the active overlay contract. | Contextual captures for shell/in-run Settings and Forge. |
| Font | Keep the current Godot font path for the first migration. Add a font only if Korean/English rendered evidence proves a real identity or legibility gap. | A new font is an external asset, license, import, and fallback decision. | Type-system spike at three viewports. |
| Motion | Use immediate or short state feedback only; no large spatial panel transitions. | Preserves input responsiveness and the current reduced-motion boundary. | Focus/pressed/receipt captures and timing review. |
| Panorama final panel | Start with a cleaned `2048x1536` 4:3 production panel, `192 px` horizontal overlap, one background layer, `scroll_scale = 0.18`, horizontal overscan `192 px`, and vertical overscan `128 px`. Generator output is source material and may be smaller; the final runtime file is normalized separately. | These values convert measured stage bounds into a reproducible initial count and fit the current maximum camera envelope. | One Flooded Works room proof; the reporting tool recalculates if any value changes. |
| Panorama loading | Load only the current location's panels; never preload the entire run's panorama set. | Avoids turning eleven large panels into an all-run memory cost. | Runtime memory/profile check in Milestone 6. |
| Terrain chunk count | No count is accepted yet. Extract the actual solid span, ledge, wall, corner, underside, one-way, support, liquid-edge, and socket usage from the authored rooms first. | A visually attractive but incomplete arbitrary kit will not cover the current rooms. | Terrain inventory report before any new terrain generation. |
| Additional UI raster art | No new UI raster is required for the first migration unless a real screen slot remains unresolved after the 19-asset pack is applied. | Prevents more generation before the existing pack is evaluated in context. | Asset-resolution validator and all-screen review. |

## Progress

### Landed / Already True

- The active product and UI behavior contracts are documented.
- The functional branch implements Korean/English copy, 48 px targets, centered
  merchant/Forge shells, responsive layouts, and three-viewport validators.
- The original project-owned SVG starter set contains 28 production assets.
- The visual branch contains five reviewed static backgrounds and nineteen
  reviewed independent raster illustrations with manifest metadata.
- `ProductionBackdrop`, `CenteredModalShell`, `RewardChoiceCard`,
  `HeroPreparationDetail`, `HUDActionSlot`, and `HUDCombatDock` provide usable
  ownership boundaries, even though their visuals still need migration.
- Deterministic capture scripts exist for shell, progression, HUD, fixed-stage,
  and boss states.
- The current post-functional normal-stage bounds have been measured rather than
  inferred from the old HTML gallery.

### Still Open

- Move the functional baseline to `master` and create the implementation branch.
- Selectively import the visual branch's production assets without importing its
  stale behavior or documentation deletions.
- Create one runtime asset owner and eliminate scattered asset paths.
- Apply the current 52 production UI assets to appropriate runtime slots or record
  explicit disposition.
- Replace bordered, rounded, code-local style construction with the approved flat
  Theme system.
- Migrate every current screen and HUD state without breaking commands, focus,
  snapshots, localization, or viewport fit.
- Produce the measured world-asset manifest and complete one Flooded Works visual
  proof before broader world art.
- Pass the production export and served-browser UI flow.

### Out Of Scope For This Plan

- New gameplay rules, rewards, equipment, cards, enemy behaviors, or map topology.
- Touch/mobile UI or a gamepad path.
- Runtime-random stage selection, map preview, seed selection, or multiple saves.
- Full player/enemy/boss animation production.
- Broad terrain and actor rollout before the representative world proof passes.
- Downloading an external UI pack or silently adding third-party runtime assets.

## Scope / Non-scope

### In Scope

- Branch integration strategy and `master` baseline preservation.
- UI Theme, semantic tokens, asset resolution, shared controls, and fallback rules.
- Main Menu, Hero Preparation, Arsenal Trial prompts, gameplay HUD, Card Reward,
  Level Reward, Merchant, Forge, Safe Intermission prompts, Pause, Settings,
  remapping, Retry Decision, Run Result, reward receipts, and boss HUD.
- All current normal/focus/hover/pressed/selected/disabled/error/success/loading
  states that the active flow can reach.
- Existing UI background, SVG, portrait, equipment, Spirit Stone, potion, card,
  boss, and reward assets.
- Measurement-backed world-panorama coverage and a first real-room presentation
  proof as a dependency of HUD/world readability.
- English and Korean rendering at `960x540`, `1280x720`, and `1920x1080`.
- Production web export and served-build verification after local gates pass.

### Destructive Or Irreversible Actions

- None are required. The migration keeps procedural/flat fallbacks until each
  replacement passes and uses scoped commits per surface batch.

### Requires Owner Approval Before

- Replacing the proposed panorama panel/overlap/scroll contract after the first
  room proof rather than because of implementation convenience.
- Introducing a third-party font, icon pack, UI kit, or other external asset.
- Promoting `UI_VISUAL_SYSTEM.md` from draft to active.
- Expanding from the accepted representative world room to all stage art.

## Current-State Map (Evidence)

| Concern | Owner(s) today | Evidence inspected | Observed behavior / problem | Plan handling |
| --- | --- | --- | --- | --- |
| Functional UI contract | `docs/design/PRODUCTION_UI_CONTRACT.md`, `RunDirector`, `ProfileState`, `RunState` | Active spec, current branch diff, validators | Behavior is real and must not be replaced by the visual branch. | Preserve public signals, commands, snapshots, and focus semantics. |
| Visual direction | `docs/design/UI_VISUAL_SYSTEM.md` | Draft spec and owner corrections | Direction is clear but not yet proven across the complete runtime. | Implement through a staged Theme migration; promote only after evidence. |
| Shared styling | `scripts/ui/production/ProductionUIStyles.gd` | Current source and captures | Bordered/rounded `StyleBoxFlat` construction is repeated and screen-local. | Narrow it to tokens/helpers and move recurring properties to one Theme. |
| UI assets | `art/ui/production/asset-manifest.json` | `master` SVG set and UI-branch v2 manifest | 28 SVG assets exist on `master`; 24 raster assets exist only on the visual branch; none of the detailed illustrations are runtime-wired. | Selectively import, resolve through one runtime owner, validate every ID. |
| Static background rendering | `scripts/ui/production/ProductionBackdrop.gd` | Current procedural renderer and visual-branch cover renderer | Procedural fallback works; optional raster cover implementation already has a bounded proof. | Reapply cover behavior onto the functional baseline and keep fallback. |
| Screen composition | `.tscn` scenes plus screen scripts | Scene trees and capture scripts | Some screens are authored; Card/Level Reward and HUD still build substantial composition in code. | Move stable composition to scenes/components while presenters retain binding. |
| Modal context | `CenteredModalShell.gd`, Settings/Pause, Merchant/Forge | Current localized branch and active contract | In-run overlays must preserve the live map and restore focus/input. | Reuse one modal owner; do not apply full-screen backgrounds in gameplay context. |
| HUD | `ProductionHUD.gd/.tscn`, `HUDCombatDock.gd`, `HUDActionSlot.tscn` | Layout snapshots, guard captures, boss captures | Functionally dense and readable, but visually dominated by bordered boxes and text. | Scene-author the stable layout, use SVG at small scale, preserve center playfield. |
| World backdrop | `ProductionStageBackdrop.gd` | Current source, fixed-stage captures, measured assembly bounds | One procedural draw covers the whole stage; no accepted panorama renderer or assets. | Add a measured single-layer sequential panorama path with procedural fallback. |
| World components | Room scenes, hazard catalog, world-art handoff | Current runtime data and rejected generation evidence | Visual families and exact chunk coverage are unresolved. | Inventory current geometry first; prove terrain plus two stateful components in one room. |

## Proposed Design

### Shared Owners

| Concern | Desired owner | Existing owner(s) to reuse or retire |
| --- | --- | --- |
| Semantic visual tokens and Theme variations | `art/ui/production/production_ui_theme.tres` plus a narrowed `ProductionUIStyles.gd` | Reuse constants; retire repeated scene/script style overrides. |
| Runtime asset lookup and fallbacks | New `scripts/ui/production/ProductionUIAssets.gd` | `asset-manifest.json` remains provenance/review metadata, not a runtime loader. |
| Static screen image cover/fallback | `ProductionBackdrop.gd` | Reapply the proven optional-texture behavior from the visual branch. |
| Modal layout, dimming, close/back, focus restoration | `CenteredModalShell.gd` and a scene-owned shell if the node tree stabilizes | Retire per-screen modal geometry and duplicated input handling. |
| Repeated reward/choice presentation | `RewardChoiceCard.tscn/.gd` and its view model | Retire procedural glyphs when a manifest raster exists; retain semantic fallback. |
| Equipment/detail art slot | `HeroPreparationDetail.tscn/.gd` plus a reusable illustrated-detail primitive only if a second consumer proves it | Do not add image handling independently to every screen. |
| HUD composition | `ProductionHUD.tscn` plus HUD components | Move stable node creation out of `ProductionHUD.gd`; keep snapshot binding and responsive mode there. |
| World panorama definition | New typed stage-visual definition/catalog under `scripts/presentation/` and `data/presentation/` | `ProductionStageBackdrop.gd` remains the renderer/fallback owner. |
| World coverage report | New `tools/report_stage_visual_coverage.gd` | Replace manual panel counts and the stale hardcoded gallery bounds. |

### Existing Asset Disposition

| Asset family | Count | Immediate runtime use | Guard |
| --- | ---: | --- | --- |
| Structural SVG masks | 6 | Main/shell planes, buttons, slots, objective surfaces where the silhouette survives resizing | Do not create nested ornamental frames or stretch a non-nine-slice shape blindly. |
| Semantic SVG glyphs | 22 | Navigation, equipment role, material, supply, reward, and interaction slots at small sizes | Use tint plus text/state; never rely on hue alone. |
| Static UI backgrounds | 5 | Main Menu, Hero Preparation, Run Result; contextual Settings and Forge use as described above | Full-screen art must never hide a live gameplay overlay context. |
| Content illustrations | 19 | Preparation/Forge details, Card Reward, Merchant potion, boss/result, and larger receipts | Do not use 512 px UI poses as animated world actors; do not force detailed art into unreadable 24-32 px HUD slots. |

After import, the production manifest contains 52 distinct UI assets. Milestone 1
must assign each one one of `runtime`, `fallback`, `contextual`, or `deferred` with a
reason. An unreferenced file with no disposition fails the batch.

### Screen Migration Map

| Surface | Existing assets applied first | Structural change | Acceptance |
| --- | --- | --- | --- |
| Main Menu | `main_menu.png`, panel/button SVGs | Preserve only Begin Expedition and Settings; use a restrained left decision plane and responsive safe zone. | Primary action is immediate, no Quit action returns, KO/EN and three viewports fit. |
| Hero Preparation | `hero_preparation.png`, Traveler, eight equipment, two Spirit Stones, potion, role/material SVGs | Add stable art slots without reducing exact costs/current-result information; simplify three-column containment. | Every model resolves the correct art/fallback and no bottom command clips. |
| Arsenal Trial | Existing navigation/interaction SVGs only | Restyle prompts and Skip Trial; keep the world visible and completion/skip mechanically equal. | Prompts, skip, bindings, and focus fit all viewports/languages. |
| Gameplay HUD | Semantic SVGs; Slime King portrait only if a reviewed 64+ px boss slot remains clear | Replace bordered boxes with flat lanes/markers; scene-author stable composition; keep the center safe gap. | All guard, pickup, interaction, boss, low-health, and reward states remain readable without covering play. |
| Card Reward | Five card vignettes, `panel_card.svg`, semantic fallbacks | Replace generic glyphs; keep three comparable cards and exact effects/costs. | Every active catalog card resolves; selection/focus/disabled/reroll remain explicit. |
| Level Reward | Speed/health/force SVGs unless a later real content slot needs raster art | Share choice primitives without pretending level upgrades are cards. | Upgrade identity and result remain readable without new raster generation. |
| Merchant | Potion raster, material/supply SVGs | Use the centered modal and clear buy/sell rows; no NPC portrait is required for the first pass. | Price, holdings, disabled reason, receipt, close, and focus return pass. |
| Forge | Eight equipment/two Spirit Stone rasters and role/material SVGs | Keep centered overlay over Safe Intermission; use `forge.png` only as a restrained internal texture if it improves hierarchy. | Craft/recraft/repair/equip and exact disabled reason remain the sole truthful primary command. |
| Pause / Settings / Remap | Navigation/settings SVGs and contextual `settings.png` | Preserve live world while paused; shell Settings may use the static background; keep focus/capture/conflict paths. | Pause and Settings never overlap or trap focus; bindings remain operable in KO/EN. |
| Retry Decision / Run Result | `run_result.png`, Traveler, Slime King, Boss Core, material SVGs | Distinguish retry from terminal settlement and visually separate retained/lost state. | Victory, retry, and ended-expedition paths have correct commands and summaries. |

### World Background Coverage Contract

The earlier value of three images is not used as a requirement. The panel count is
derived from the post-functional-baseline stage geometry.

Measured current bounds:

| Location | World bounds | Initial role |
| --- | ---: | --- |
| Ruin Approach | `8960 x 1630` | Sequential panorama |
| Flooded Works | `8960 x 1600` | Sequential panorama and first proof |
| Broken Sanctum | `11520 x 2160` | Sequential panorama |
| Arsenal Trial | `3440 x 720` | Short sequential panorama |
| Safe Intermission | `1280 x 720` | One fixed composition |
| Slime Court | `1280 x 720` | One fixed boss composition |

For a single scrolling background layer, calculate required coverage as:

```text
required_width = max_viewport_width
               + max(world_width - max_viewport_width, 0) * scroll_scale
               + 2 * horizontal_overscan

required_height = max_viewport_height
                + max(world_height - max_viewport_height, 0) * scroll_scale
                + 2 * vertical_overscan

coverage(n) = panel_width + (n - 1) * (panel_width - overlap)
```

Safe Intermission and Slime Court are fixed compositions, not scrolling
panoramas. Their renderer is centered and pinned to the viewport with
keep-aspect-covered scaling, so each needs one panel whose minimum coverage is
the maximum viewport (`1920x1080`); scrolling overscan is intentionally not
charged to those two locations.

Using the suggested first-proof contract (`1920x1080` maximum viewport,
`2048x1536` final 4:3 panels, `192 px` overlap, `scroll_scale 0.18`, horizontal
overscan `192 px`, vertical overscan `128 px`) produces:

| Location | Required width | Required height | Initial panel count |
| --- | ---: | ---: | ---: |
| Ruin Approach | about `3572 px` | about `1435 px` | 2 |
| Flooded Works | about `3572 px` | about `1430 px` | 2 |
| Broken Sanctum | about `4032 px` | about `1531 px` | 3 |
| Arsenal Trial | about `2578 px` | at most `1336 px` | 2 |
| Safe Intermission | fixed `1920 px` | fixed `1080 px` | 1 |
| Slime Court | fixed `1920 px` | fixed `1080 px` | 1 |
| **Current run total** |  |  | **11** |

This is an initial measured result, not a hand-entered permanent asset count. The
coverage tool must recompute it after changes to stage bounds, viewport support,
panel normalization, overlap, overscan, or scroll scale. The first Flooded Works
proof may change the proposed contract; if so, update the manifest and all counts
together.

Sequential generation and cleanup rules:

- panel `n+1` uses the accepted right overlap of panel `n` as a reference;
- the overlap zone uses large, simple silhouettes and low-frequency lighting;
- no important landmark, readable text, interactable, or unique gameplay cue sits
  inside a seam zone;
- generator output is source material, not the final runtime panel;
- final panels are normalized to the accepted dimensions, color density, overlap,
  and import settings before Godot integration;
- only the current location's panel array is loaded.

### Remaining Asset Inventory After Existing UI Adoption

New UI raster generation is not a first-pass requirement. The remaining work is:

- small SVG gap check, with `coin`, `warning`, and `lock/unavailable` as the three
  currently evidenced candidate glyphs;
- the measured panorama set above;
- a scan-derived terrain chunk/pattern kit rather than a guessed tile count;
- the first canonical stateful components: timed poison vent base plus warning/
  active/cooldown overlays, and crumbling platform base plus crack/debris/respawn
  overlays;
- the current twelve field-pickup identities, grouped under a shared pickup
  grammar only after terrain/component scale is proven;
- later Traveler, six enemy-archetype, regional variant-layer, Small Slime,
  Summon Node, Slime King, projectile, impact, and telegraph assets;
- unique Safe Intermission, Arsenal Trial, and Slime Court props only after the
  background/terrain language is accepted.

Legacy class, active-skill, mastery, and old equipment-item records are compatibility
data and receive no new production art unless the product contract changes.

## As-Is / To-Be Delta Map

| Concern | As-is | To-be | Acceptance check | Guard / leftover check |
| --- | --- | --- | --- | --- |
| Branch ownership | Functional and visual work live on divergent branches. | Updated `master` contains functional truth; one new branch applies selected visuals. | Diff shows no gameplay/data regression and no stale branch-wide deletions. | No wholesale merge of `codex/ui-visual-pass-1`. |
| Asset paths | SVGs are cataloged but unused; raster art is on another branch. | One asset owner resolves every runtime ID with stable fallback. | Asset validator resolves 52 identities or explicit dispositions. | `rg` finds no scattered hard-coded production image paths outside owners/scenes. |
| Theme | Bordered/rounded script-local styles. | One flat zero-border Theme with semantic variations and reserved focus markers. | Theme/state capture review at three viewports. | No per-screen color/style vocabulary without a documented exception. |
| Static screens | Procedural backdrop and text-heavy panels. | Accepted raster backdrop plus live, responsive, accessible Controls. | Main/Prep/Result captures fill without distortion or clipping. | No baked text, state, buttons, or values. |
| Overlays | Context handling differs by screen and older visual code can replace the live scene. | Settings, Merchant, and Forge preserve the live screen/map where required. | Shell and in-run context tests both pass. | No full-screen Forge or gameplay Settings regression. |
| Choice content | Generic procedural glyphs. | Correct content raster with semantic fallback and live selection state. | Five cards and all active equipment models resolve correctly. | No legacy/class content enters active screens. |
| HUD | Script-built bordered clusters with many small text blocks. | Scene-owned flat lanes, SVG recognition, precise live values, stable center gap. | Existing layout snapshots plus rendered guard/boss/pickup states pass. | Detailed raster art is not shrunk into noise. |
| Background count | Historical gallery and conversation values are manual. | Runtime geometry report produces required coverage and panel count. | Tool output matches manifest and renderer configuration. | No fixed `3` or stale `8960` literal outside fixtures. |
| World state art | Full-body state generation drifts. | Canonical base plus overlays/effects with fixed pivot/envelope. | Gallery and one-room proof show state changes without body drift. | Collision, damage, timing, support top, and interaction range remain unchanged. |

## Tasks

### Milestone 0 - Master Baseline And Branch Gate

**Goal:** Put visual work on the latest functional truth without contaminating
`master` with obsolete UI-branch behavior.

**Source owners:** Git branches/worktrees, release matrix, active specs, `.agent`
records.

- [ ] Confirm the current `master` head and re-run the core release gate; record
  failures before any UI merge.
- [ ] Review `master..codex/ui-readability-localization` and integrate the complete
  functional/localization series into `master` through a clean fast-forward or
  reviewed merge.
- [ ] Confirm the new `master` includes Safe Intermission, merchant, centered
  modal behavior, KO/EN localization, current controls, stage composition, retry,
  and their validators.
- [ ] Create `codex/master-ui-overhaul` from that clean `master`.
- [ ] Capture all current shell/progression/HUD/fixed-stage/boss baselines at the
  supported viewports before visual changes.
- [ ] Record exact visual-branch paths/commits to import; explicitly reject its
  Quit action, documentation deletions, and stale screen behavior.

**As-is:** `master` is behind the functional branch and the visual branch diverged
before those contracts landed.

**To-be:** one clean implementation branch has functional parity with the intended
`master` target and a rendered baseline.

**Accept:** focused validators and baseline captures pass or every pre-existing
failure is recorded with a current owner.

**Guard:** never resolve a functional/visual conflict by accepting the visual branch
wholesale.

### Milestone 1 - Asset Import, Runtime Owner, And Easy Adoption

**Goal:** Bring every already-usable asset onto the functional baseline and make it
visible in the lowest-risk real screens.

**Source owners:** `art/ui/production/**`, `asset-manifest.json`,
`ProductionUIAssets.gd`, `ProductionBackdrop.gd`, Main Menu, Hero Preparation,
Card Reward, and Run Result.

- [ ] Selectively import the five production backgrounds, nineteen production
  illustrations, their reviewed import settings, and v2 manifest entries from
  `codex/ui-visual-pass-1`.
- [ ] Preserve the 28 existing SVG assets and merge manifest metadata without
  losing provenance, fallback, tint, display-size, or ownership fields.
- [ ] Add `ProductionUIAssets.gd` as the only runtime lookup/fallback owner.
- [ ] Add a focused validator that checks manifest IDs, paths, dimensions,
  fallbacks, and runtime/deferred disposition.
- [ ] Reapply optional aspect-preserving cover rendering to
  `ProductionBackdrop.gd` with the procedural fallback intact.
- [ ] Apply `main_menu.png`, `hero_preparation.png`, and `run_result.png` to their
  full-screen contexts.
- [ ] Apply Traveler/equipment/Spirit/potion illustrations to Hero Preparation
  and the five card vignettes to Card Reward.
- [ ] Apply Slime King/Boss Core/Traveler art to result/boss-summary contexts where
  it improves identity without replacing live values.
- [ ] Assign every one of the 52 UI assets a runtime, fallback, contextual, or
  deferred disposition.

**As-is:** assets exist but do not affect the main runtime.

**To-be:** the first visible path uses real assets through one owner and still works
with a missing-asset fallback.

**Accept:** Main Menu -> Hero Preparation -> Card Reward -> Run Result captures show
the intended assets at `960x540`, `1280x720`, and `1920x1080`; all focused validators
pass.

**Guard:** do not use UI portraits as world sprites, do not rasterize live controls,
and do not hide missing IDs through layout changes.

### Milestone 2 - Theme And Shared Component Foundation

**Goal:** Make the visual system genuinely flat and reusable before migrating every
screen independently.

**Source owners:** `ProductionUIStyles.gd`, new
`art/ui/production/production_ui_theme.tres`, `CenteredModalShell`,
`RewardChoiceCard`, `HeroPreparationDetail`, `HUDActionSlot`, and
`HUDCombatDock`.

- [ ] Create one project Theme with the semantic variations defined in
  `UI_VISUAL_SYSTEM.md`.
- [ ] Move recurring color, spacing, type, control-height, meter, focus, selected,
  disabled, error, and success styling into Theme/tokens.
- [ ] Narrow `ProductionUIStyles.gd` to semantic constants and unavoidable
  construction helpers; remove duplicated per-screen style ownership.
- [ ] Replace default borders/radii with flat planes, spacing, type hierarchy,
  marker lanes, icons, and fill changes.
- [ ] Preserve at least 48 px primary/confirm targets and stable bounds across all
  states.
- [ ] Ensure focus is unmistakable through more than color and does not shift
  layout.
- [ ] Stabilize the shared modal, choice, detail, action-slot, and combat-dock
  component contracts before screen-wide migration.
- [ ] Render one shell screen, one dense progression screen, one modal, and one HUD
  state in KO/EN at all viewports.
- [ ] If the spike passes, request owner approval to promote
  `UI_VISUAL_SYSTEM.md` from draft to active; otherwise keep it draft and record
  the failed rule.

**As-is:** shared helpers exist, but borders, rounding, local overrides, and script-
built composition still define the look.

**To-be:** a small semantic Theme/component vocabulary defines the system.

**Accept:** the cross-surface spike reads as one outline-free system and passes
focus, fit, contrast, and state checks.

**Guard:** do not replace every old border with another decorative container or
make focus depend on a thin outline alone.

### Milestone 3 - Shell, Pause, Settings, And Result Migration

**Goal:** Complete every global/shell surface and prove context-sensitive
background behavior.

**Source owners:** `MainMenu.tscn/.gd`, `PauseMenu.tscn/.gd`,
`SettingsPopup.tscn/.gd`, `RunResult.tscn/.gd`, `ProductionBackdrop.gd`, shell
capture/validation scripts.

- [ ] Finish Main Menu composition without reintroducing unsupported actions.
- [ ] Migrate Pause and End Expedition confirmation to the shared Theme and
  explicit destructive hierarchy.
- [ ] Apply `settings.png` only in shell context; preserve the live stage plus dim
  layer in pause/in-run context.
- [ ] Keep capture, conflict, cancel, reset-one, restore-all, language, audio,
  screen-shake, and damage-flash paths visible and operable.
- [ ] Migrate victory, retry decision, and ended-expedition summaries with
  Traveler/Slime King/Boss Core art in appropriate slots.
- [ ] Verify initial focus, focus neighbors, Escape/back, close, and return focus.

**Accept:** all shell states pass `ValidateShellUI.gd` and rendered KO/EN evidence
at three viewports with no clipping, overlap, unsupported action, or lost context.

**Guard:** no background image may make a modal look like navigation to another
screen.

### Milestone 4 - Preparation, Rewards, Merchant, And Forge Migration

**Goal:** Complete all dense decision/economy surfaces using the current raster
content pack and shared components.

**Source owners:** Hero Preparation, Card Reward, Level Reward, Merchant, Forge,
their components/view models, and focused validators.

- [ ] Add stable image slots to loadout/model/detail rows without reducing exact
  costs, current-result comparison, condition, save, or disabled-reason content.
- [ ] Ensure all eight equipment models, two Spirit Stones, and potion resolve
  their correct art and semantic role.
- [ ] Apply the five card vignettes without baking rarity, stack, selection,
  reroll, or disabled state into images.
- [ ] Keep Level Reward on semantic SVG/state art unless a real unresolved raster
  slot is demonstrated.
- [ ] Migrate Merchant buy/sell presentation with potion/material/supply assets,
  exact price/holdings, receipt, and stable failure states.
- [ ] Migrate Forge as a centered live-world overlay. Test `forge.png` only as a
  restrained internal crop; defer it with a reason if it competes with content.
- [ ] Confirm Card Reward remains global while Merchant/Forge remain bounded
  overlays.

**Accept:** all commands still use the existing services/snapshots, all focused
validators pass, and the complete preparation/reward/intermission path is usable by
keyboard alone at every supported viewport and locale.

**Guard:** no screen writes gameplay dictionaries, no legacy item/class content
returns, and illustrations never hide mechanical comparison data.

### Milestone 5 - HUD, Feedback, Trial, And World-Visibility Migration

**Goal:** Replace the prototype cockpit look while preserving exact combat state and
the visible play area.

**Source owners:** `ProductionHUD.tscn/.gd`, HUD components, receipt presenter,
feedback director/cues, Arsenal Trial prompts, HUD validators/captures.

- [ ] Move stable HUD node composition from `ProductionHUD.gd` into scenes and
  reusable components; keep snapshot/event binding in scripts.
- [ ] Replace small procedural role glyphs with the SVG set where legible.
- [ ] Keep precise values for health, XP, condition, stability, ammunition,
  charges, cost, cooldown, and boss state as text/meters.
- [ ] Use detailed raster only at reviewed `64 px+` identity slots; otherwise use
  SVG or text.
- [ ] Preserve the center player-safe gap, objective/boss lane, context lane, and
  stable bottom combat dock.
- [ ] Migrate guard start/block/precise/break/recovery, low health, pickup,
  interaction, reward, boss startup/active/recovery, and failure states.
- [ ] Restyle Arsenal Trial instructions and Skip Trial without obscuring traversal.
- [ ] Add the evidenced missing simple SVGs only if the all-state review still
  requires them.

**Accept:** gameplay HUD and Trial validators pass in KO/EN at all viewports, and
rendered gameplay states preserve landing edges, player, enemies, hazards, and
telegraphs.

**Guard:** visual simplification cannot remove exact state, and decorative UI cannot
occupy the playfield simply because space is available.

### Milestone 6 - Measured World Background And Component Proof

**Goal:** Turn the remaining presentation gap into measured production work without
making world art a guessed UI batch.

**Source owners:** new visual-coverage report/catalog, `ProductionStageBackdrop.gd`,
fixed-stage capture scripts, Flooded Works representative room, world-art docs and
gallery.

- [ ] Add `tools/report_stage_visual_coverage.gd` to emit current stage bounds,
  viewport envelope, proposed scroll/overscan, required composite size, and panel
  count from runtime data.
- [ ] Add a typed stage-visual definition/catalog and one panorama renderer path
  with procedural fallback and per-location lazy loading.
- [ ] Validate the proposed 4:3 panel, overlap, overscan, and `0.18` scroll default
  in one representative Flooded Works room.
- [ ] If accepted, produce the two sequential Flooded Works source panels using
  the accepted overlap as the next-panel reference, then clean/normalize them.
- [ ] Extract current authored terrain/component usage before deciding the chunk
  type count.
- [ ] Build only the minimum Flooded Works terrain chunk/pattern family needed by
  the representative room.
- [ ] Build the canonical poison-vent and crumbling-platform bases and their
  separate state overlays.
- [ ] Compose background, terrain, components, player, HUD, and collision/debug
  overlays in the real room; compare behavior snapshots before/after.
- [ ] Recalculate the run-wide panel manifest. Do not generate the remaining nine
  initial panels or broader components until the room proof is accepted.

**Accept:** the representative room reads as one world, panels connect without a
visible seam, repeated terrain does not expose a lighting pattern, state overlays
retain one body/pivot, current-stage memory is measured, and gameplay geometry/
timing is unchanged.

**Guard:** the initial count of eleven does not authorize eleven immediate
generation calls; expansion follows the accepted proof and recalculated manifest.

### Milestone 7 - Integration, Production Export, And Handoff

**Goal:** Land the completed UI overhaul on `master` with full behavioral and
rendered evidence.

- [ ] Run all focused UI, input, reward, intermission, progression, retry, HUD,
  boss, and result validators after each related merge batch.
- [ ] Run the full release candidate gate after the final source batch.
- [ ] Build the production Web export. Before serving a `D:\npjt` build, use the
  repo-required `npjt-port-guard`/fastrun `codex` lane rather than an ad hoc port.
- [ ] Complete the full keyboard/mouse path in the built app: Main Menu -> Prep ->
  Trial/skip -> three stages -> rewards -> intermissions -> boss -> result, plus
  retry/end, Settings/remap, pause, Forge, and merchant.
- [ ] Capture KO/EN states at `960x540`, `1280x720`, and `1920x1080`, including
  longest text and all reachable focus/disabled/error/success states.
- [ ] Compare baseline and final captures for hierarchy, clipping, world
  visibility, crop, image softness, and context preservation.
- [ ] Verify no active production asset lacks a disposition and no obsolete
  procedural placeholder remains outside documented fallbacks.
- [ ] Update active specs/records only after the corresponding evidence passes;
  mark this plan done when no implementation task remains.

**Accept:** the built production run is visually coherent and fully operable without
a soft lock, focus trap, clipped required text, unsupported action, stale asset,
hidden gameplay state, or behavior regression.

## Test Plan

### Inner Loop

- `./tools/godot.ps1 --path . --headless --import`
- the focused validator for the touched screen/component;
- the asset-manifest/fallback validator after any asset or registry change;
- one rendered state at the reference viewport after each visible change;
- `git diff --check` and a targeted stale-path/style grep.

### Batch Gates

- after Milestone 1: asset resolution plus Main/Prep/Card/Result captures;
- after Milestone 2: Theme/component state matrix at all three viewports;
- after Milestone 3: `ValidateShellUI.gd`, Pause, Settings/remap, and result tests;
- after Milestone 4: preparation, card, merchant, Forge, safe-intermission, reward,
  and transaction tests;
- after Milestone 5: `ValidateGameplayHUD.gd`, boss HUD, feedback, interaction,
  pickup, guard, and Trial tests;
- after Milestone 6: stage geometry/presentation/hazard tests, visual coverage
  report, memory profile, real-room screenshots, and before/after gameplay facts.

### Final Gates

- `./tools/validate_release_candidate.ps1 -Full`
- production Web export and production-style served start;
- full keyboard/mouse run in English and Korean;
- UIUX Gate Level 4 evidence report with surfaces, states, viewports, focus/
  accessibility checks, screenshots, exceptions, remaining warnings, and result;
- asset manifest/path/fallback/disposition validation;
- `git diff --check`, lifecycle audit for task-owned docs, and scoped commit review.

### Accessibility And Fit Checks

- Initial focus and visible focus on every screen and modal.
- Arrow navigation matches visual/task order.
- Enter/Space confirms and Escape closes/returns consistently.
- Focus returns to the initiating control after modal close.
- Mouse operates pointer-appropriate controls.
- State never depends on color alone.
- Required text survives Korean/English, `960x540`, and realistic text wrapping.
- No child clips, overlaps, escapes, or creates accidental horizontal scroll.
- Primary/confirm targets remain at least 48 px high.
- Modal/gameplay input blocking and restoration remain correct.

### Rerun Policy

- Rerun a failed focused check only after its suspected owner changes or a new
  hypothesis exists.
- Rerun full release/export gates only after the failing batch changes.
- Record known external/tool warnings rather than repeatedly rediscovering them.
- If GUI/browser control fails twice for runtime reasons, use deterministic Godot
  captures, focused tests, and a documented manual built-app path.

## Verification

The plan itself is valid when:

- every referenced path exists now or is explicitly marked as a new planned owner;
- branch and asset source claims match Git history;
- measured stage bounds and the initial panel-count calculation are reproducible;
- the plan contains no arbitrary fixed background count;
- active specs remain authoritative for behavior and the draft visual spec remains
  non-canonical until its acceptance gate;
- a future executor can start Milestone 0 without relying on conversation history;
- Markdown/frontmatter and `git diff --check` pass.

## Rollback / Safety

- Keep the procedural backdrop and semantic glyph fallbacks until each replacement
  passes its batch gate.
- Commit by milestone or coherent screen family; do not mix world-art expansion,
  gameplay logic, and unrelated docs in one commit.
- If a visual batch fails, revert that batch without reverting functional baseline
  work.
- Never reset or overwrite user-authored changes in another worktree.
- Preserve snapshot/intent/service boundaries; visual nodes may emit existing
  intents but do not mutate domain dictionaries.
- Do not preload all panorama panels or all stage skins.
- Do not delete old plan/evidence documents as part of implementation; lifecycle
  cleanup requires separate owner approval.

## Risks

| Risk | Failure mode | Mitigation |
| --- | --- | --- |
| Whole visual branch merge | Reverts localization, modal behavior, active docs, or browser actions. | Selective asset/path adoption onto the updated functional baseline. |
| Asset enthusiasm outruns layout | Large art crowds precise progression data. | Measure slots, enforce documented display sizes, and prefer art in details rather than every row. |
| Flat borderless UI loses focus | Keyboard navigation becomes ambiguous. | Reserved marker lane, fill/icon/text state, and focus captures in both languages. |
| Background art breaks context | Settings or Forge looks like a new screen and hides the live map. | Context-aware renderer and explicit shell/in-run tests. |
| HD softness | `1672x941` backgrounds visibly soften at `1920x1080`. | Accept for the MVP only if capture review passes; otherwise regenerate/clean the specific failed background, not the whole family. |
| Panorama seams | Sequential panels reveal lighting/geometry discontinuity. | Large simple overlap zones, reference the accepted preceding edge, normalize after generation, real-camera sweep test. |
| Panorama memory | Large panels are all loaded at once. | Per-location lazy loading, current-stage-only arrays, import/profile gate. |
| Terrain kit is arbitrary | Attractive pieces fail real room coverage. | Scan authored geometry first and prove one complete room. |
| State drift | Warning/active/cooldown bodies do not match. | Canonical base plus separate overlays/parts/effects. |
| Theme migration changes behavior | Focus, commands, or snapshots regress during restyle. | Preserve public APIs and migrate/test one surface family at a time. |
| Documentation authority conflicts | Draft art plans are mistaken for approved execution. | This active plan cites drafts as evidence and carries explicit approval gates. |

## Open Questions

These are not blockers for Milestones 0-1 unless noted:

- Does the first Flooded Works camera sweep accept `scroll_scale 0.18`, or should
  the single layer move more/less? Changing it must trigger a count recalculation.
- Does `forge.png` improve the centered Forge modal as a cropped internal texture,
  or should it be kept as a shell/reference asset because the live world is clearer?
- Does the current Godot font provide enough Cardborne identity after hierarchy and
  spacing improve, or is a licensed bilingual font worth the dependency?
- Which simple SVG gaps remain after real screen adoption? `coin`, `warning`, and
  `lock/unavailable` are candidates, not automatic production work.
- What terrain chunk/pattern count does the authored-room inventory actually
  require? No number is accepted before the report.
- After the representative room passes, should world art continue in this branch
  or move to a separate presentation branch while UI integration proceeds?

## Decision Notes

- 2026-07-15: The owner made `master` the target line and required existing easy
  assets to be applied before commissioning more.
- 2026-07-15: The owner rejected a conversation-chosen three-panel count; world
  background quantity must come from measured coverage.
- 2026-07-15: Post-functional-baseline stage bounds measured as Ruin
  `8960x1630`, Flooded `8960x1600`, and Sanctum `11520x2160`.
- 2026-07-15: The initial 4:3 single-layer coverage proposal yields 11 panels for
  the complete current run, but only the two-panel Flooded Works proof is eligible
  before the contract is accepted.
- 2026-07-15: Existing UI raster art covers the active first-slice content catalog;
  additional UI raster generation is deferred until a real unresolved slot exists.
- 2026-07-15: The old visual branch is an asset/evidence source, not an integration
  authority.

## Next Steps

1. Execute Milestone 0: integrate the functional branch into `master`, create
   `codex/master-ui-overhaul`, and record a clean rendered baseline.
2. Execute Milestone 1 without new image generation: selectively import the five
   backgrounds and nineteen illustrations, add the asset owner/validator, and
   apply the first visible screen path.
3. Stop for rendered review after the easy-adoption batch before beginning the
   Theme-wide migration.

## Handoff Summary

Read first:

- `AGENTS.md`
- `.agent/PLANS.md`
- `docs/README.md`
- `docs/design/PRODUCTION_UI_CONTRACT.md`
- `docs/design/UI_VISUAL_SYSTEM.md`
- this plan
- `.agent/handoffs/2026-07-14-world-component-imagegen-session.md` before any
  world-art generation

Produce last:

- scoped commits and updated plan progress;
- focused and full validation output;
- three-viewport KO/EN captures and final UIUX evidence;
- an asset manifest with runtime/fallback/contextual/deferred disposition;
- the measured stage-visual coverage report and accepted/rejected proof decision;
- updated active specs/records only for behavior and decisions that actually land.

Stop when:

- every current production UI surface is migrated and verified;
- every existing production UI asset is used or explicitly dispositioned;
- the production build completes the full run in KO/EN at supported viewports;
- the world-presentation dependency has an accepted representative proof and a
  measured backlog rather than arbitrary counts;
- no required task, validation gate, or documentation handoff remains.
