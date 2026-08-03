---
type: plan
status: active
owner: BK
created: 2026-08-03
last_reviewed: 2026-08-03
topic: Shared-component reconstruction of every player-facing UI surface
scope: UI product contracts, shared Theme primitives, modal and HUD composition, fixed-Hard deployment, mandatory upgrade choice, legacy chrome retirement, localization, and rendered release evidence
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/design/visual-replacement-workbench/README.md
  - ../../docs/design/visual-replacement-workbench/previews/ui-screen-direction/index.html
  - ../../art/visuals/production/ui/vehicle_stage_theme.tres
  - ../semantic-v2-runtime-acceptance-evidence.md
  - ./2026-08-02-visual-replacement-workbench-and-runtime-switch.md
---

# Shared UI System Reconstruction - Execution Contract

At the clean discovery baseline `2935d08`, Cardborne has a functional but
visually fragmented image-backed UI: one Theme imports 54 chrome-state PNGs,
screen scripts still construct many one-off layouts, and the recently approved
screen previews are not yet reflected in runtime composition. This contract
rebuilds the complete UI around one code-native Theme asset and six reusable
primitives, preserves all gameplay information, makes Hard the only run
difficulty, makes every upgrade choice mandatory, and retires the obsolete
raster chrome only after every consumer and validator has migrated.

This contract supersedes only the Phase 5 UI-chrome target and the UI-count
assumptions in
`.agents/execplans/2026-08-02-visual-replacement-workbench-and-runtime-switch.md`.
That broader plan remains authoritative for gameplay visual packages in its
Phases 6 through 11, but Phase 6 must not start until this contract completes.

## Purpose

- Objective: reconstruct every player-facing runtime UI surface so the
  approved simple general-SF direction is visible in the game, not merely in
  review PNGs.
- Deliverable: one shared code-native component system, all modal and HUD
  consumers migrated to it, fixed-Hard deployment, mandatory upgrade choice,
  complete Korean and English layouts, no production raster UI chrome, and
  native plus built-Web evidence at every supported viewport.
- Completion state: `shared_ui_reconstruction_complete`.

## Why / Context

The previous visual-replacement Phase 5 replaced the bytes of thirteen raster
families without changing the screen hierarchy that made the UI feel busy.
The current production pack therefore contains 54 state PNGs across modal,
content, HUD, card, button, tab, toggle, slider, meter, preview, and small-state
families. The Theme exposes more than thirty visual variations, while several
screens still create direct Buttons, nested panels, separator lanes, badges,
and screen-specific surfaces.

The review gallery now establishes the accepted composition direction:

- preserve information and behavior;
- remove ornamental lines, dots, corners, nested frames, badges, and panels;
- use one component skeleton for one semantic role;
- keep only one primary action per screen;
- keep meaningful gameplay imagery while eliminating decorative UI imagery.

BK added four binding corrections to that direction:

1. An upgrade card has no small top/category image. It has exactly one larger
   related family artwork in the card body.
2. The upgrade screen has no Leave, Exit, Skip, or decline action.
3. Pause actions form one vertical stack.
4. Easy and Normal are removed from the product; every run uses the current
   Hard balance.

The current product and visual specifications still require Easy/Normal/Hard,
optional upgrade decline, and image-backed chrome while forbidding
`StyleBoxFlat`. Those contracts must change before runtime code or media is
retired. This plan makes that amendment its first implementation gate.

## Authority and Interpretation

Use this order when two sources appear to disagree:

1. Root and nearest `AGENTS.md` files govern execution and safety.
2. BK's decisions recorded in this contract govern the requested UI outcome.
3. The product and visual specifications, after Phase 1 amendments, govern
   durable behavior and presentation.
4. This contract governs execution order and acceptance.
5. The UI screen-direction gallery governs composition and density only.
6. Current code and validators describe the starting implementation, not the
   desired design.

The gallery PNGs are review evidence, not pixel-perfect runtime assets. Current
runtime data and actions override invented preview copy or numbers. The four BK
corrections above override the visible top icons, Leave button, and horizontal
Pause row in the existing upgrade and Pause PNGs.

"Preserve information" means that current gameplay values, control hints,
metrics, locked-state secrecy, settings, and conditional states remain
available. It does not preserve the explicitly removed difficulty selector,
difficulty preference copy, optional reward copy, duplicate artwork, or
ornamental chrome.

## Scope and Boundaries

In scope:

- `docs/product/vehicle_game_spec.md` and `docs/design/VISUAL_SYSTEM.md` UI,
  difficulty, reward-choice, HUD, responsive, and accessibility contracts.
- The shared UI Theme, factory, modal host, modal surface, and all Theme
  variation consumers.
- Deployment, gameplay HUD, upgrade choice, Pause, Settings, Guidebook, stage
  and failure report, final result, Garage, transition banner, notifications,
  and debug Boss Practice.
- Hard-only deployment and removal of saved difficulty preference.
- Mandatory upgrade transactions and removal of the unused decline path.
- Korean and English localization changes required by the new product flow.
- Focus, keyboard, controller, mouse, compact/wide, 200% text, reduced-motion,
  and overflow contracts.
- Workbench ledger changes and retirement of obsolete raster UI chrome after
  the exact deletion gate.
- Native captures, Web export, built-Web interaction smoke, and durable
  acceptance evidence.

Out of scope:

- Any change to the current Hard quotas, caps, health, damage, speed, stage
  curve, encounter authored content, or performance capacity.
- Gameplay controls, card effects, upgrade eligibility, combat state,
  collision, navigation, map topology, pickups, bosses, or save data other than
  removing the obsolete next-run difficulty preference.
- The authored optional reward enclosures and their drops. Opening an enclosure
  remains optional; only the reward transaction after opening becomes
  non-dismissible.
- New gameplay artwork, a new art style, a named cultural/material theme, or
  generated production UI imagery.
- A new UI framework, engine, font family, production dependency, or scene-file
  conversion. UI remains Godot 4.7 GDScript and programmatic Control hierarchy.
- Phone portrait layouts or a new supported viewport below `960x540`.
- Rewriting retained minimap geometry, threat radar semantics, status rules, or
  gameplay semantic asset catalogs.
- Continuing the broader visual-replacement plan's Phase 6+ gameplay asset
  production.

Constraints and invariants:

- Noto Sans KR remains the only UI font family.
- The existing flat-color, role-readable general-SF palette remains fixed.
- No body text may auto-shrink below 14 px and every focus target remains at
  least 44 px high or wide on its operated axis.
- Korean and English must expose the same actions and information.
- Color is never the only selected, focused, disabled, warning, or locked cue.
- A modal has one host-owned root Surface. A screen may add a PreviewWell or a
  scroll viewport for content semantics, but may not add nested decorative
  panel shells.
- A screen owns hierarchy, copy, signals, and state. The Theme and component
  factory own reusable visual construction only.
- Meaningful craft, upgrade-family, enemy, boss, object, minimap, and action
  imagery continues to come from the gameplay semantic asset provider. UI
  chrome never duplicates those images.
- No localized text, key hint, dynamic value, or runtime icon is baked into a
  background image.
- The current `1100` compact breakpoint and `1180` three-column breakpoint
  remain unless a named screen task below supplies a narrower rule.
- No unrelated user-authored change may be staged, reverted, or committed.

Destructive or irreversible actions:

- Phase 8 intends to remove the exact 54 current UI chrome PNGs and their 54
  tracked `.png.import` sidecars, plus
  `art/visuals/production/ui/ui-asset-manifest.json`,
  `scripts/ui/vehicle_ui_asset_provider.gd`, and its `.uid` after zero runtime
  references are proven.
- Phase 8 also retires the obsolete raster-only validator
  `tools/validation/validate_visual_replacement_ui_surface_targets.gd` and its
  `.uid` after its replacement validator is green.
- All removals remain recoverable from the immediately preceding scoped Git
  commit. Never use `git reset --hard`, broad cleanup, or directory-wide delete.

Exact actions requiring owner or user approval:

- Before deleting any Phase 8 path, print one deterministic sorted retirement
  list, its current baseline commit, and SHA-256 for every PNG. Obtain explicit
  approval for that exact set. Approval of this plan is not deletion approval.
- No other task in this contract needs a new product or visual choice. Any
  proposed new dependency, new viewport contract, or new gameplay behavior is
  outside this plan and requires separate direction.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Simple art direction | The visual spec already prohibits rivets, functionless seams, repeated lamps, concentric forms, nested frames, scratches, and unexplained greeble | `docs/design/VISUAL_SYSTEM.md`, Design Direction and Approved Art Style Grammar | Preserve and strengthen that rule for UI chrome; no decorative exception | 1.2, 2.1, 2.2 |
| Raster fragmentation | One manifest owns 13 families and 54 PNG states; the Theme imports them through 48 `StyleBoxTexture` subresources | `art/visuals/production/ui/ui-asset-manifest.json`; `vehicle_stage_theme.tres` | Replace chrome with one code-native Theme asset; retain only meaningful gameplay images and the font | 1.2, 2.1, 8.1-8.5 |
| Shared construction owner | The 59-line factory already owns modal surfaces, labels, commands, and section headings | `scripts/ui/vehicle_ui_component_factory.gd` | Expand this existing boundary; do not create a catch-all screen builder | 2.2 |
| Modal ownership | `VehicleStageUI` routes nine modal surfaces and `VehicleModalHost` owns viewport clamping, focus/overflow inspection, and compact mode | `scripts/ui/vehicle_stage_ui.gd::_install_components`; `scripts/ui/vehicle_modal_host.gd` | Preserve routing and host ownership; migrate only presentation and changed signal contracts | 2.2, 3.1, 4.1 |
| Upgrade image hierarchy | The card currently renders a 38x32 family glyph inside a framed family badge and no separate main-art region | `scripts/ui/vehicle_upgrade_choice_card.gd::_build` | Remove the top glyph/badge and render the same approved family asset once at 64x64 compact / 88x88 wide inside the card body | 4.2 |
| Upgrade exit | The panel and stage UI expose an optional decline signal, but every current runtime call opens rewards with `optional=false` | `vehicle_upgrade_choice_panel.gd`; `vehicle_stage_ui.gd`; `vehicle_run.gd::_advance_reward_queue` | Delete the dead optional/decline path; every reward requires selection and Equip | 1.1, 4.1, 4.3 |
| Pause composition | Current Pause isolates Resume, places Restart and Settings in one horizontal row, then places Garage separately | `scripts/ui/vehicle_pause_panel.gd::_build` | Header utility remains; Resume, Restart, Settings, Garage form one equal-width vertical stack in that order | 2.3 |
| Fixed Hard | Specs, deployment, settings persistence, runtime, and validators currently support three profiles; Hard factors are all 1.0 | `vehicle_run_difficulty.gd`; `settings_store.gd`; product spec Fixed Run Difficulty | Remove Easy/Normal UI and persistence; keep a Hard-only compatibility profile so combat math and telemetry retain the exact baseline | 1.1, 3.1-3.4 |
| Full surface inventory | Runtime mounts Deployment, Upgrade, Pause, Result, Report, Garage, Settings, Guidebook, and debug Practice; HUD also owns notifications and transition banner | `vehicle_stage_ui.gd`; all `scripts/ui/vehicle_*_panel.gd`; `vehicle_gameplay_hud.gd` | Every listed surface is included; result/debug/transient UI may not remain on legacy chrome | 3.2-7.4 |
| Meaningful imagery | Craft, upgrade-family, guidebook, enemy, boss, object, minimap, and action assets already come from the gameplay semantic provider | `vehicle_semantic_asset_provider.gd`; `vehicle_upgrade_glyph_renderer.gd`; `vehicle_guidebook_preview.gd` | Reuse those assets at their content locations; do not generate new screen-specific images | 3.2, 4.2, 5.2, 6.1, 7.1 |
| Information retention | Current owners expose controls, stats, metrics, locked states, conditional HUD data, and report partitions | Screen scripts and product spec UI section | Simplify containers only; preserve data and conditional states except explicitly removed difficulty/decline content | 3.2-7.4 |
| Localization | One CSV owns complete Korean and English copy, including now-obsolete difficulty and decline keys | `localization/vehicle_stage.csv` | Remove obsolete rows, update Garage labels, and preserve exact KO/EN key parity | 3.1, 3.3, 4.1, 9.1 |
| Responsive contract | Modal host and validators cover 960x540, 1280x720, and 1920x1080; 200% text is supported by the capture driver | `vehicle_modal_host.gd::_apply_viewport`; `validate_vehicle_stage_ui_layout.gd`; capture driver CLI | Keep these three viewports, both locales, and 200% 1280 captures as acceptance; do not claim phone support | 2.4, 3.4, 4.3, 5.4, 6.3, 7.4, 9.2 |
| Workbench lifecycle | The workbench deterministically projects production media and supports retire-only units | workbench README, model, builder, and validator | Consolidate the 13 current UI families into one retired history unit and retain it through this plan; the broader visual plan may remove completed history only at its Phase 10 lifecycle cleanup | 8.2-8.5 |
| Release path | Repository policy requires focused validators, import, Web export, built-Web smoke, and production-style evidence | root `AGENTS.md`; `.github/workflows/vehicle-run-validation.yml`; `tools/export_web.ps1` | Run focused gates per phase and the full native/Web gate once after all inputs stabilize | 9.1-9.5 |

Readiness statement:

- Every material product, architecture, data, UX, ownership, safety, and
  validation decision is closed.
- Godot 4.7, the existing PowerShell wrappers, capture driver, workbench
  builder, Web exporter, and the registered fastrun-manager Codex lane are
  available; no dependency bootstrap is required.
- Remaining unknowns are implementation-local and cannot change this contract.

## Proposed Design

### Locked Shared Component System

The production UI has exactly six reusable conceptual primitives. Theme
variations may encode semantic roles, but they may not introduce a new shape,
texture family, or per-screen ornament.

| Primitive | Owner | Required variants | Runtime responsibility | Forbidden use |
| --- | --- | --- | --- | --- |
| Surface | `vehicle_stage_theme.tres`, `VehicleUiComponentFactory.surface()` | modal, modal compact, content, HUD, toast | One flat fill, at most one 1 px boundary, optional single semantic rail | Nested decoration, screen-specific corners, multiple perimeter lines |
| TextRow | `VehicleUiComponentFactory.text_row()` | label/value, label/detail, metric | Alignment, wrapping, shared gap, localized children | A panel per row, truncating required information |
| Command | `VehicleUiComponentFactory.command_button()` | primary, secondary, danger | One button geometry with semantic fill/outline and shared states | A different silhouette per screen or action |
| Selectable | factory plus the stateful `VehicleUpgradeChoiceCard` | normal, hover, pressed, focus, selected, disabled | Repeated choice skeleton and non-color selection cue | Badge-inside-card or a second selected frame |
| Meter | Theme plus existing live ratio owners | health, resource, boss, cooldown, support | One track geometry; role changes only fill color and necessary state cue | Decorative segmentation unrelated to the value |
| PreviewWell | factory plus existing semantic content renderers | normal, locked, focused | One quiet content region for craft, upgrade family, guide entry, or enemy/object art | Decorative thumbnails, duplicate art, baked labels |

Target factory API in `scripts/ui/vehicle_ui_component_factory.gd`:

```gdscript
static func surface(role: StringName, minimum_size := Vector2.ZERO) -> PanelContainer
static func modal_surface(minimum_size: Vector2) -> PanelContainer
static func command_button(text: String, role: StringName) -> Button
static func selectable_button(text: String, selected := false) -> Button
static func text_row(label_text: String, value_text: String, options := {}) -> HBoxContainer
static func section_heading(text: String) -> Label
static func preview_well(minimum_size: Vector2) -> PanelContainer
static func meter(role: StringName) -> ProgressBar
```

The factory defines role constants and maps them to Theme variations. Screen
scripts do not assign raw style names or construct local `StyleBox` resources.
`modal_surface()` remains as the compatibility entry used by
`VehicleModalHost`. `flat_panel()` is removed after its consumers migrate.

The Theme keeps these public semantic variations and no screen-specific plate
variations:

- `ModalSurface`, `ModalSurfaceCompact`, `ContentSurface`, `HudSurface`,
  `ToastSurface`;
- `PrimaryButton`, `SecondaryButton`, `DangerButton`;
- `SelectableButton`, `SelectedSelectableButton`;
- `HealthMeter`, `ResourceMeter`, `BossMeter`, `CooldownMeter`,
  `SupportMeter`;
- `PreviewFrame`, `PreviewLocked`, `PreviewFocused`;
- `DisplayLabel`, `TitleLabel`, `SectionLabel`, and `MetricLabel`.

`CheckButton`, `HSlider`, `OptionButton`, `TabBar`, and `TabContainer` use the
same code-native line, focus, selected, and disabled resources. Obsolete
variations including
`FamilyBadge`, `SummaryBand`, `ContentInset`, `ContentSummary`,
`HudHealthResource`, `HudObjectiveBoss`, `HudMinimapTarget`, `HudActionRail`,
`HudToast`, `ChoiceButton`, `SelectedChoiceButton`,
`SelectedRailButton`, `UpgradeChoiceCard`,
`SelectedUpgradeChoiceCard`, and `TertiaryDangerButton` do not survive the
migration.

Phase 2 may retain those obsolete names only as compatibility aliases that
resolve to the exact shared resources above. An alias may not carry a unique
StyleBox, color, margin, geometry, or state. The factory may likewise accept
legacy Theme-variation arguments only through one explicit semantic-role map.
Each screen phase removes its aliases at the call sites it owns. Phase 8 proves
zero remaining alias references, then deletes both the Theme aliases and the
factory compatibility map before the raster pack is retired.

Visual states are deliberately simple:

- normal: dark flat surface and one quiet boundary;
- hover: boundary changes to system cyan;
- focus: visible 2 px system outline, independent of hover;
- pressed: one darker fill shift, no new ornament;
- selected: one 3 px amber rail plus selected text/accessibility state;
- disabled: lower contrast plus a structural cue such as a broken boundary or
  disabled text, never alpha/color alone;
- danger: red text and boundary, never a competing filled primary button.

### Locked Screen Contracts

| Surface and owner | Information and actions that remain | Target composition |
| --- | --- | --- |
| Deployment — `vehicle_deployment_panel.gd` | Field, title, Pulse Cannon and its full summary, craft identity, movement, aim, held fire, dash, EMP, Deploy, Settings, debug-only Boss Practice | Wide: two unboxed columns. Left has field/title, weapon line, one `attachment/player_craft_body` PreviewWell, and weapon summary. Rotate only the TextureRect presentation so the existing +X craft appears nose-up; do not alter the source image or gameplay orientation. Right has four TextRows: movement; mouse aim plus held fire; dash; EMP. Deploy is the only primary, Settings is quiet secondary, debug Practice appears only in debug. Compact retains two columns: a 40% identity/weapon column with a 104x104 preview and a 60% controls column. The body alone may scroll at 200% text; the header and Deploy/Settings footer remain fixed. No difficulty label, choice, description, or saved preference. |
| Gameplay HUD — `vehicle_gameplay_hud.gd` | Hull, XP, level, objective and detail, boss name/health/state/objective, minimap, target name/health/state, dash, passive/secondary, EMP, buff, notifications, transition, radar, status orbit | Four restrained zones: top-left hull/XP; top-center objective and conditional boss; top-right minimap and conditional target; bottom-center one compact three-slot action strip. A zone has at most one subtle Surface. Toast/transition is text-first under the objective. No full-width dock or ornamental edge frame. |
| Upgrade — `vehicle_upgrade_choice_panel.gd`, `vehicle_upgrade_choice_card.gd` | Kicker, title, instruction, three frozen offers, family text, title, summary, up to two effect rows, behavior change, selected/pending/apply-failed state, Equip | Header, three equal Selectables, message, one centered primary Equip. Each card order is family text, title, summary, exactly one lower 64x64 compact / 88x88 wide family artwork, effect rows, behavior. No image, icon, or badge appears above the title; no stage pips, nested card, Leave, Exit, Skip, or decline exists. Escape only shows the mandatory-choice notice. |
| Pause — `vehicle_pause_panel.gd` | Title, Guidebook utility, Resume, Restart, Settings, Garage/Abort | One compact modal. Header contains title and the accessible Guidebook utility. Below it, equal-width Commands form one vertical stack: Resume primary, Restart secondary, Settings secondary, Garage danger. No horizontal row, action lanes, or inner panels. |
| Settings — `vehicle_settings_panel.gd` | Guide, Back, Ship Status, Audio, Controls, Gameplay, Language, live/empty ship snapshot, sliders, bindings, reduced motion, locale | Header, one borderless category rail in the current order, one scrollable aligned content region. Active category uses one amber rail. Rows are TextRows with shared Slider, Toggle, or Command controls. Gameplay retains reduced motion but contains no difficulty explanation. |
| Guidebook — `vehicle_guidebook_panel.gd`, `vehicle_build_summary_panel.gd`, `vehicle_guidebook_preview.gd` | Five categories, entries, discovered/locked states, one semantic preview, description, movement/attack/counter rows, complete ship build summary | Wide keeps category/list/detail columns separated by simple spacing or one divider. Compact replaces the category rail with one accessible `OptionButton` in the same five-category order. Non-Ship categories keep a 34% entry list and 66% detail split; each side owns vertical scrolling. Ship hides the empty entry pane and gives detail the full body width. Rows are borderless. Locked entries remain `???` with one neutral silhouette and leak no name, color, description, or counterplay. |
| Stage/failure report — `vehicle_stage_report_panel.gd` | Header/summary, defeats, outgoing damage sources, attributes, percentages, failure last hit and top incoming sources, context-specific bottom action | Wide uses three TextRow columns; compact uses the existing three keyboard-operable tabs. Failure-only incoming data follows the same row primitive. One fixed bottom action remains. No framed metric row. Stages 1-4 still do not open a success report during the connected run. |
| Final result — `vehicle_result_panel.gd` | Stage/title, time, hull, selected upgrade, three performance values, reward, Garage, Replay | Kicker/title, one aligned three-value summary, two unboxed text sections for performance and reward, then Garage primary and Replay secondary. Remove summary-band and boxed-column treatment without removing data. |
| Garage — `vehicle_garage_panel.gd` | Kicker/title, clear/hull summary, primary/passive/active loadout, unlocked modules, current run build, Deployment Setup, Settings | Header, one-line summary, two unboxed columns for Loadout and Modules/current build, then Deployment Setup primary and Settings secondary. Empty module/build states remain readable without placeholder panels. |
| Transition and notifications — `vehicle_stage_transition_banner.gd`, HUD notification owner | Stage title/status and queued localized notifications | One narrow ToastSurface below the objective. No modal frame, corner ornament, or duplicate backing. Timing and queue behavior remain unchanged. |
| Debug Boss Practice — `vehicle_boss_practice_panel.gd` | Boss, field, phase, pattern, invulnerability, Start, Back | Reuse Settings form TextRows, Selectables, Toggle, and Commands. It remains debug-only and outside the production gallery. |

### Responsive and Accessibility Contract

- Supported acceptance viewports remain `960x540`, `1280x720`, and
  `1920x1080`.
- `VehicleModalHost._apply_viewport()` keeps compact mode below 1100 px width
  or 650 px height. Guidebook and report retain their 1180 px three-column
  decision.
- Modal outer margins remain 16, 24, and 32 px for compact, 1280 wide, and
  1920 centered review respectively.
- Upgrade cards remain `224-244x286` with 12 px gap in compact and `304x330`
  with 18 px gap in wide mode. The single artwork is 64 px compact and 88 px
  wide; text is reduced by spacing before any font is reduced.
- Pause uses a `520x430` preferred modal, a command width no greater than 360
  px, 48 px command height, and 8/12 px compact/wide stack gaps.
- Scroll is limited to Settings content, Guidebook list/detail, report content,
  debug Practice form, and the Deployment body at compact 200% text. Upgrade,
  Pause, Deployment header and command footer, Result actions, and Garage
  actions do not scroll.
- `clip_contents` remains a safety guard, never an overflow solution.
- Visual focus order and input focus order are identical. Dialog entry moves
  focus to the primary task or first selectable; close/return restores the
  correct parent surface.
- Mouse, keyboard, and controller can operate every action. Numeric `1-3`
  upgrade selection remains supported.
- KO/EN at 200% text scale must preserve actions and information. If content
  cannot fit, reduce redundant spacing or use an already-authorized scroll
  region; never hide content, shrink below 14 px, or create a new viewport
  contract.

## Milestones and Checklist

### Phase 1: Amend durable contracts and freeze the old UI lane

Goal: make the requested product and component architecture authoritative
before runtime code starts depending on it.

Preconditions:

- Read root `AGENTS.md`, `.agents/AGENTS.md`, `.agents/PLANS.md`, this complete
  contract, the complete product spec, the complete visual spec, and the
  related active visual-replacement plan.
- Run `git status --short`; stop only if unrelated changes overlap a named task
  path and cannot be preserved.
- Record branch, full HEAD, timestamp, Godot version, and clean/dirty state in
  this contract's Decision Notes.

Source owners: `docs/product/vehicle_game_spec.md`,
`docs/design/VISUAL_SYSTEM.md`, the related active ExecPlan, and the UI gallery.

- [x] **1.1 Lock fixed-Hard and mandatory reward behavior in the product spec**
  - Change: replace the three-profile player choice with one fixed Hard run;
    remove next-run difficulty persistence and selector acceptance; state that
    every level and boss reward requires one selected card and Equip; remove
    decline language while preserving frozen offers and two-step confirmation.
    Keep authored optional reward enclosures optional to open; once opened,
    their reward transaction follows the same mandatory choice contract.
  - Accept: the spec contains no active Easy/Normal selector, preference, or
    decline contract; all current Hard numbers and the connected five-stage
    flow remain unchanged.
- [x] **1.2 Replace the image-backed UI-chrome contract in the visual spec**
  - Change: authorize the six code-native primitives, `StyleBoxFlat`/line-based
    Theme chrome, semantic gameplay imagery, the screen table above, the
    upgrade and Pause corrections, fixed-Hard deployment, and the rule against
    useless lines/dots/detail. Remove the 54-state/image-manifest acceptance
    language and the prohibition on code-native chrome.
  - Accept: the visual spec has one unambiguous UI foundation, no second style
    document, no screen-specific raster requirement, and no loss of typography,
    spacing, focus, grayscale, or responsive requirements.
- [x] **1.3 Make this contract the UI execution pointer**
  - Change: add this file to the related active visual-replacement plan; record
    that its Phase 5 is historical baseline only; block that plan's Phase 6
    until this contract completes; replace its UI count assumptions with the
    post-retirement code-native contract.
  - Accept: a fresh agent reading either plan reaches this contract before
    producing more assets or continuing gameplay visual work.
- [x] **1.4 Correct the review-gallery interpretation without generating new art**
  - Change: add a visible bilingual note to the UI gallery that the upgrade
    top image and Leave button are removed, Pause is a vertical stack, and
    runtime captures—not the PNGs—will be final evidence.
  - Accept: the gallery remains review-only, all eight images still resolve,
    and its text cannot be mistaken for approval of the two obsolete details.

Batch gate:

```powershell
.\tools\validation\validate_document_authority.ps1
.\tools\design\build_visual_replacement_workbench.ps1 -Check
.\tools\validation\validate_visual_replacement_workbench.ps1
git diff --check
```

Commit boundary: one contract-migration commit containing only plan/spec/gallery
coordination changes.

### Phase 2: Build the shared Theme foundation and prove it through Pause

Goal: replace raster styling with the complete reusable primitive foundation
and one immediately visible, low-coupling screen slice.

Preconditions:

- Phase 1 batch gate passes.
- Keep all 54 raster files, their manifest, and provider in place during this
  phase; they remain a rollback source until Phase 8.

Source owners: `art/visuals/production/ui/vehicle_stage_theme.tres`,
`scripts/ui/vehicle_ui_component_factory.gd`,
`scripts/ui/vehicle_modal_surface.gd`,
`scripts/ui/vehicle_modal_host.gd`, `scripts/ui/vehicle_stage_ui.gd`,
`scripts/ui/vehicle_pause_panel.gd`, and the raster-sensitive UI validators.

- [x] **2.1 Rebuild the Theme as one code-native component asset**
  - Change: replace the Theme's raster external resources and
    `StyleBoxTexture` resources with shared `StyleBoxFlat`, `StyleBoxLine`,
    `StyleBoxEmpty`, font, color, spacing, and focus resources implementing the
    exact public variations listed above. Keep the temporary compatibility
    aliases defined above, with each alias pointing to the exact matching shared
    resource. Keep Noto Sans KR and the canonical palette. Do not create a
    second Theme file.
  - Accept: the Theme loads without missing resources; contains zero
    `StyleBoxTexture`; has no screen-specific HUD plate, family badge, summary
    band, or tertiary danger shape; every temporary alias is resource-identical
    to a public semantic role; and every required state has non-color
    focus/selected/disabled distinction.
- [x] **2.2 Expand the factory and preserve modal ownership**
  - Change: implement the locked factory API and role constants; update
    `VehicleModalSurface.debug_contract()` to describe a flat shared surface;
    keep `VehicleModalHost.configure()`, `_apply_viewport()`, focus counting,
    primary-action counting, and overflow inspection intact while mapping it
    to the new modal variations. Route any legacy variation argument through one
    documented compatibility dictionary; never silently create a style or use
    the argument as a raw Theme key.
  - Accept: screens can construct all six primitives without local StyleBoxes;
    modal compact switching still occurs at the existing breakpoint; no
    behavior or routing moves into the factory or host; unknown legacy aliases
    fail loudly in debug validation.
- [x] **2.3 Make Pause the reference implementation**
  - Change: rebuild `VehiclePausePanel._build()` around one header and one
    centered VBox command stack in the exact order Resume, Restart, Settings,
    Garage. Use the common Command primitive for all four and retain the
    accessible Guidebook header utility. Update
    `VehicleStageUI.MODAL_MINIMUMS["pause"]` to `Vector2(520, 430)` so the host
    and the new composition share one size contract.
  - Accept: no horizontal action row, action lane, nested panel, or unique
    button variation remains; Resume receives initial focus; all signals and
    paused-tree return behavior remain unchanged.
- [x] **2.4 Add the shared-component validator and migrate foundation checks**
  - Change: add `tools/validation/validate_vehicle_ui_components.gd` and `.uid`
    to assert the six factory APIs, public Theme roles, compatibility-alias
    identity, zero raster Theme resources, one root Surface per modal, Pause
    vertical order, minimum targets, and visible focus contracts. In the same
    task, update `VehicleStageUI.debug_ui_contract()`,
    `validate_vehicle_stage_ui_layout.gd`, `validate_vehicle_upgrade_ui.gd`,
    and `validate_vehicle_visual_replacement_coverage.gd` so their foundation
    assertions recognize the code-native Theme while their not-yet-migrated
    screens continue through exact aliases. Keep
    `validate_visual_replacement_ui_surface_targets.gd` checking the physical
    54-file rollback pack until Phase 8.
  - Accept: the validator fails on a reintroduced `StyleBoxTexture`, direct
    screen-local StyleBox, alias with unique styling, or horizontal Pause
    layout. Every existing `validate_*.gd` script remains green; no validator is
    intentionally left red between phases.

Batch gate:

```powershell
.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_ui_components.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_pause.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_ui_layout.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_upgrade_ui.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_visual_replacement_coverage.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_visual_replacement_ui_surface_targets.gd
```

Commit boundary: one shared-foundation and Pause vertical-slice commit.

### Phase 3: Make Deployment and Garage the fixed-Hard entry flow

Goal: remove the difficulty-choice product path and deliver the approved
Deployment/Garage composition without changing Hard combat balance.

Preconditions:

- Phase 2 batch gate passes.
- Factory and Theme APIs are frozen. Later phases may consume them but may not
  add another primitive or screen-local variation.

Source owners: `scripts/vehicle/vehicle_run_difficulty.gd`,
`scripts/autoload/settings_store.gd`, `scripts/ui/vehicle_stage_ui.gd`,
`scripts/ui/vehicle_deployment_panel.gd`, `scripts/ui/vehicle_garage_panel.gd`,
`scripts/ui/vehicle_settings_panel.gd`, `scripts/vehicle/vehicle_run.gd`,
`scripts/encounters/vehicle_encounter_runtime.gd`, localization and difficulty
validators.

- [x] **3.1 Collapse the selectable difficulty contract to Hard-only**
  - Change: keep `VehicleRunDifficulty` only as a compatibility owner with
    `HARD`, `DEFAULT`, `IDS=[HARD]`, and one all-1.0 profile; remove Easy and
    Normal constants/profiles. Remove `SettingsStore.run_difficulty`, its
    signal, setter, validation, loading, and saving. Ignore any legacy
    `gameplay/run_difficulty` value for behavior, then erase only that obsolete
    key on the next normal settings save while preserving every other setting.
    Change deployment signals and handlers to carry only `primary_id`;
    initialize every run and encounter with Hard internally.
  - Accept: no user-facing or saved difficulty can change a run; current Hard
    quotas, caps, health, boss health, damage, and speed are bit-for-bit the
    previous Hard values; restart and stage transition preserve that baseline.
  - Guard: retain the internal Hard profile and telemetry field during this
    plan so UI reconstruction does not broaden into combat-math rewrites.
- [x] **3.2 Recompose Deployment from the accepted direction**
  - Change: remove `_difficulty_box`, buttons, detail, selection helpers, and
    difficulty parameters. Build the locked wide and compact two-column layout;
    show one existing `attachment/player_craft_body` semantic asset in a
    PreviewWell, rotating only its TextureRect presentation nose-up; retain the
    complete Pulse Cannon summary; merge mouse aim and held primary fire into
    one row without deleting either instruction; keep Deploy, Settings, and
    debug-only Practice. In compact 200% text, place only the body in a vertical
    ScrollContainer and keep the header and command footer outside it.
  - Accept: one primary Deploy action emits `pulse_cannon`; no difficulty word
    or selector appears; every control and weapon fact remains; KO/EN fit all
    supported viewports; debug Practice remains absent in release builds.
- [x] **3.3 Recompose Garage and remove obsolete difficulty copy**
  - Change: rebuild Garage as the locked two-column TextRow layout; retain all
    loadout, module, empty, and current-run-build states; change
    `GARAGE_LAUNCH` to Deployment Setup and `GARAGE_SETTINGS` to Settings in
    both locales. Remove `SETTINGS_DIFFICULTY_LOCKED`, all deployment difficulty
    keys, and the settings difficulty label.
  - Accept: Garage exposes exactly Deployment Setup primary and Settings
    secondary; it never promises a difficulty choice; every current data field
    remains visible.
- [x] **3.4 Rewrite difficulty and settings validation around fixed Hard**
  - Change: update `validate_vehicle_run_difficulty.gd`,
    `validate_settings_store.gd`, deployment assertions in
    `validate_vehicle_stage_ui_layout.gd`, capture fixtures, encounter pacing,
    damage feedback, reward/UI audio, and performance fixture expectations.
  - Accept: validators prove one Hard ID, all-1.0 factors, no persisted
    preference, no selector, unchanged Hard quotas/caps/damage, and the new
    signal signatures.

Batch gate:

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_settings_store.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_run_difficulty.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_encounter_pacing.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_damage_feedback.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_ui_layout.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_ui_localization.gd
```

Rendered phase evidence: KO and EN `01-deployment.png` and `94-garage.png` at
960x540 and 1280x720.

Commit boundary: one fixed-Hard Deployment/Garage flow commit.

### Phase 4: Rebuild Upgrade as mandatory Selectable cards

Goal: provide one clear select-then-Equip flow with one meaningful image per
card and no exit path.

Preconditions:

- Phase 3 batch gate passes.
- Existing eight `hud/upgrade_<family>` semantic images remain production
  content assets and are not copied into the UI folder.

Source owners: `scripts/rewards/vehicle_reward_runtime.gd`,
`scripts/vehicle/vehicle_run.gd`, `scripts/ui/vehicle_stage_ui.gd`,
`scripts/ui/vehicle_upgrade_choice_panel.gd`,
`scripts/ui/vehicle_upgrade_choice_card.gd`,
`scripts/presentation/components/vehicle_upgrade_glyph_renderer.gd`,
localization and upgrade/reward validators.

- [ ] **4.1 Remove the unused optional reward/decline path end to end**
  - Change: remove `_current_optional`, `decline()`, and
    `is_current_optional()` from `VehicleRewardRuntime`; remove the `optional`
    argument from `begin()`, `_open_upgrade_reward()`, `show_upgrade()`, and
    panel `open()`; remove `upgrade_declined`, `_on_upgrade_declined()`, the
    declined outcome branch, optional cached state, and decline notifications.
    Delete `UPGRADE_LEAVE_REWARD`, `UPGRADE_CONFIRM_LEAVE`,
    `UPGRADE_OPTIONAL_NOTICE`, and `NOTIFY_REWARD_DECLINED` from both locales.
  - Accept: every current reward source remains claimable exactly once; offers
    remain frozen; Escape cannot leave or reroll; no declined terminal outcome
    or UI signal remains.
- [ ] **4.2 Rebuild each card around one body artwork**
  - Change: remove `_header`, the small `_glyph` placement,
    `_family_badge`, and the `FamilyBadge` contract. Keep the family label as
    unboxed text, followed by title and summary; place one lower
    `VehicleUpgradeGlyphRenderer` at 64x64 compact or 88x88 wide after the
    summary and before effects/behavior. Use
    `SelectableButton`/`SelectedSelectableButton`; update debug contracts to
    expose `header_art_count=0` and `body_art_count=1`.
  - Accept: all eight families render through their existing semantic asset;
    every visible card has exactly one artwork; selected, focus, disabled, and
    pending states remain distinguishable without color; no card-inside-card or
    family badge remains.
- [ ] **4.3 Rebuild the panel around one Equip command**
  - Change: delete `_decline`, `_decline_armed`, `_request_decline()`, and the
    two-button command row; center one shared primary Equip command. Keep input
    guard, numeric shortcuts, first-card focus, selection preview, failure
    message, and two-step selection/confirmation.
  - Accept: three unique frozen cards appear; Equip is disabled until one is
    selected; one confirmation applies exactly one card; Escape shows only the
    mandatory notice; there is no Leave/Exit/Skip control or focus stop.
- [ ] **4.4 Replace raster/card assertions with behavioral and layout assertions**
  - Change: rewrite `validate_vehicle_upgrade_ui.gd` to test one artwork,
    absence of top artwork/badge/decline, three Selectables, selection and
    focus cues, card geometry, both locales, all supported viewports, pending
    and apply-failed states. Update `validate_vehicle_rewards_ui_audio.gd` to
    remove decline expectations and prove mandatory reward completion.
  - Accept: upgrade, reward runtime, upgrade system, UI layout, localization,
    and capture-driver validators all pass.

Batch gate:

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_upgrade_system.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_upgrade_ui.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_rewards_ui_audio.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_ui_layout.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_ui_localization.gd
```

Rendered phase evidence: KO/EN `06-level-up-choice.png`,
`06b-level-up-selected.png`, `06c-level-up-confirmed.png`, and
`06d-localization-third-slot.png` at 960x540 and 1280x720.

Commit boundary: one mandatory Upgrade interaction and card-layout commit.

### Phase 5: Migrate Settings, Guidebook, build summary, and debug Practice

Goal: replace repeated boxes and direct controls with shared category, row,
preview, and command primitives while preserving every setting and discovery
state.

Preconditions:

- Phase 4 batch gate passes.
- Theme and factory remain frozen.

Source owners: `vehicle_settings_panel.gd`, `vehicle_guidebook_panel.gd`,
`vehicle_build_summary_panel.gd`, `vehicle_guidebook_preview.gd`,
`vehicle_boss_practice_panel.gd`, Settings and Guidebook stores, localization,
and their focused validators.

- [ ] **5.1 Recompose Settings**
  - Change: retain the five categories in their current order; style the
    category control as one borderless Selectable rail; use TextRows for status,
    audio, bindings, reduced motion, and language; replace private `_button()`
    and bespoke row construction with factory primitives. Keep one scrollable
    content region and remove the difficulty lock row.
  - Accept: active/empty Ship Status, sliders, binding capture/conflict/reset,
    reduced motion, KO/EN switch, Guide, Back, and return-surface behavior all
    work; no setting row has its own decorative panel.
- [ ] **5.2 Recompose Guidebook and shared build summary**
  - Change: keep the current category/list/detail state model, semantic preview
    provider, and locked-entry rules; replace framed rows and summary bands with
    TextRows and simple section spacing; map the preview shell to PreviewWell;
    make `VehicleBuildSummaryPanel` use the same row API as Settings and Garage.
    The current-ship PreviewWell uses `attachment/player_craft_body` with the
    same presentation-only nose-up rotation as Deployment. At compact width,
    replace the category rail with one five-option `OptionButton`; use the locked
    34/66 entry/detail split for non-Ship categories, independent vertical
    scrolling, and full-width detail for Ship.
  - Accept: Ship, mobile, stationary, boss, and object categories remain; ship
    intentionally skips an empty entry pane; discovered and locked entries are
    correct; the category selector and entry/detail focus order work by keyboard
    and controller; long KO/EN descriptions scroll only in the detail region.
- [ ] **5.3 Migrate debug Boss Practice without adding production UI**
  - Change: rebuild its form from TextRows, Selectables, Toggle, and Commands;
    retain debug-only mounting, options, validation, Start, and Back.
  - Accept: release builds still omit the surface; debug capture remains
    operable and uses no legacy Theme variation.
- [ ] **5.4 Update focused contracts and capture fixtures**
  - Change: update Settings/Guidebook/UI layout/localization/capture validators
    for shared primitives, screen state, focus order, and no nested row chrome.
  - Accept: active-run and no-run Settings, current ship, discovered boss,
    locked entry, enemy counterplay, compact layout, and debug Practice fixtures
    all pass.

Batch gate:

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_settings_store.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_guidebook.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_boss_practice.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_ui_layout.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_ui_localization.gd
```

Rendered phase evidence: KO/EN `01b-shared-settings.png`,
`01c-guidebook.png`, `01d-gameplay-settings.png`,
`01e-guidebook-boss-preview.png`, `01f-guidebook-locked.png`,
`01g-guidebook-enemy-counterplay.png`, and debug `01h-boss-practice.png` at
960x540 and 1280x720.

Commit boundary: one Settings/Guidebook/shared-form commit.

### Phase 6: Migrate reports and final result

Goal: make dense end-state data readable through shared rows and spacing, not
framed metrics, without changing run flow or telemetry.

Preconditions:

- Phase 4 passes. This phase may run in parallel with Phase 5 only after the
  Theme and factory are frozen and each worker owns disjoint files.

Source owners: `vehicle_stage_report_panel.gd`, `vehicle_result_panel.gd`,
`vehicle_combat_mesh_icon.gd`, damage-source catalog, localization, stage-report
and UI-layout validators.

- [ ] **6.1 Recompose stage and failure reports**
  - Change: replace `_metric_row()` and `_damage_row()` panel treatment with
    shared TextRows; preserve semantic enemy/attribute icons only where they
    identify the source; keep wide three-column and compact tab behavior,
    failure-only incoming section, percentages, totals, and one fixed action.
  - Accept: outgoing source and affinity partitions still agree within 0.01;
    failure last-hit/top-three data remains; no metric row has a decorative
    shell; no Stage 1-4 success modal is introduced.
- [ ] **6.2 Recompose final result**
  - Change: replace summary band and boxed columns with one three-value TextRow
    summary plus Performance and Reward sections; use shared Commands for
    Garage primary and Replay secondary.
  - Accept: every current summary, performance, reward, and action value remains
    visible; the correct initial focus and signals remain.
- [ ] **6.3 Update report/result contracts and capture fixtures**
  - Change: update `validate_vehicle_stage_report.gd`, layout/localization
    assertions, and final/failure capture fixtures for the shared row system.
  - Accept: KO/EN at 960/1280/1920 show no overlap, clipping, raw keys, incorrect
    percentages, or action loss.

Batch gate:

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_report.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_ui_layout.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_ui_localization.gd
```

Rendered phase evidence: KO/EN `91-stage-report.png`,
`92-failure-report.png`, and `93-final-result.png` at 960x540 and 1280x720.

Commit boundary: one report/result composition commit.

### Phase 7: Migrate the live HUD and transient UI

Goal: complete the shared system on the only always-visible surface while
preserving combat readability and all conditional state.

Preconditions:

- Phases 5 and 6 pass.
- Do not alter minimap geometry, radar semantics, gameplay snapshots, or combat
  performance ownership.

Source owners: `vehicle_gameplay_hud.gd`, `vehicle_hud_presenter.gd`,
`vehicle_stage_transition_banner.gd`, `vehicle_status_orbit.gd`,
`vehicle_threat_radar.gd`, retained minimap components, UI glyph catalog, and
HUD/layout/reward validators.

- [ ] **7.1 Collapse HUD backing into four shared zones**
  - Change: replace health, objective/boss, minimap/target, action, and toast
    screen-specific plate variations with `HudSurface`/`ToastSurface`; keep a
    surface only when contrast against the world requires containment; move or
    retain the compact three-slot action strip at bottom center as the accepted
    direction; preserve every conditional cluster and snapshot field.
  - Accept: top-left, top-center, top-right, and bottom-center zones match the
    locked screen contract; no zone gains nested backing; the world, player,
    crosshair, target, and threat cues remain unobscured.
- [ ] **7.2 Remove raster meter and small-state consumers**
  - Change: remove `UiAssets` use from `HealthPips` and `ActionRailSlot`; render
    live ratios and cooldown/availability through the shared Meter/state
    geometry and existing semantic icons. Replace status-orbit
    `pip_available`/`pip_filled` textures with one code-native structural state
    cue. Preserve health animation, cooldown, accessibility text, and status
    semantics.
  - Accept: `rg -n "VehicleUiAssetProvider|UiAssets\.texture" scripts` returns
    no production consumer; health/resource/boss/cooldown/support states remain
    readable in color and grayscale; ready versus disabled is not color-only.
- [ ] **7.3 Simplify transition and notification surfaces**
  - Change: make the transition banner and notification queue consume
    `ToastSurface` and shared label spacing; preserve timing, queue cap, message
    color role, localization, and objective/crosshair avoidance.
  - Accept: banners never create modal dimming, duplicate borders, or blocked
    input; all queued messages still appear in order.
- [ ] **7.4 Validate live, boss, pressure, and reduced-motion states**
  - Change: update HUD presenter, layout, rewards/audio, capture driver, and
    structural component assertions. Capture ordinary live play, cooldowns,
    boss objective/target, peak horde, collective states, Pause overlay, and
    reduced motion.
  - Accept: no current HUD value/state disappears; combat batch and draw-call
    contracts do not regress; all focusable overlays and action hints remain
    correct in KO/EN.

Batch gate:

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_hud_presenter.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_rewards_ui_audio.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_ui_layout.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_combat_renderer.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_performance_scenarios.gd
```

Rendered phase evidence: `02-safe-arrival.png`,
`02b-first-contact-cue.png`, `02c-ship-status-active.png`,
`02d-action-cooldowns.png`, `03-peak-horde.png`, collective-state captures,
`07-stage-boss-startup.png`, and `90-pause.png` in KO and EN at 1280x720,
plus KO compact at 960x540.

Commit boundary: one live HUD/transient UI commit.

### Phase 8: Retire the fragmented raster chrome and reconcile the workbench

Goal: remove only proven-obsolete UI chrome and make all inventory, coverage,
and active-plan counts describe the new code-native truth.

Preconditions:

- Phases 2 through 7 and every focused gate pass.
- A clean scoped commit exists immediately before retirement.
- No new UI chrome PNG has been introduced.

Source owners: UI manifest/provider/media folders, Theme and factory,
`tools/design/visual_replacement_workbench_model.psm1`,
`tools/design/build_visual_replacement_workbench.ps1`,
`tools/validation/validate_visual_replacement_workbench.ps1`,
`docs/design/visual-replacement-workbench/replacement-workbench.json`, generated
`inventory.json` and `index.html`, visual-replacement coverage validators, and
the active visual-replacement plan.

- [ ] **8.1 Prove zero production dependency on the legacy pack**
  - Change: scan project files, Theme, project settings, workbench consumers,
    validators, and runtime code for `ui-asset-manifest`,
    `VehicleUiAssetProvider`, `StyleBoxTexture`, every old Theme variation, and
    all 54 manifest paths. Remove the temporary Theme compatibility aliases and
    the factory legacy-role map only after every screen call site is at a public
    semantic role, then repeat the scan.
  - Accept: production code and Theme have zero references; only the temporary
    retirement ledger, active plan history, and explicit retirement validation
    may name the old files. The Theme exposes no compatibility alias and the
    factory contains no legacy-role map.
- [ ] **8.2 Consolidate the exact retirement unit**
  - Change: replace the thirteen current `ui_manifest` workbench units with one
    `ui_chrome_retirement` retire-only unit whose `current_paths` are exactly
    the 54 current PNGs and whose `retire_paths` are those PNGs, their 54
    sidecars, the manifest, provider, provider `.uid`, raster-only validator,
    and validator `.uid`: 113 sorted paths total. Set it to `switch_ready` only
    after the workbench and zero-reference checks pass. Update the workbench
    model to enforce retire-unit approval/application state generically; update
    the builder so the UI manifest is required only before this retirement is
    approved; and replace the validator's Phase-3-specific global assumptions
    with explicit old-retirement and `ui_chrome_retirement` lifecycle checks.
  - Accept: every current production image still has one ledger owner; the
    retirement unit has no deliverable, no runtime consumer, no wildcard, and
    a deterministic sorted path list. Before deletion, the projection is
    exactly 36 units, four retire-only units, 215 gameplay PNGs, 54 UI PNGs, one
    font, and statuses `keep_current=2`, `target_required=30`,
    `switch_ready=1`, `retired=3`.
- [ ] **8.3 Display and obtain the exact destructive approval**
  - Change: print baseline commit, sorted retirement paths, PNG sizes and
    SHA-256 values, plus the empty runtime-reference result. Ask BK to approve
    that exact displayed set.
  - Accept: approval text binds the exact baseline and paths. Stop only this
    retirement branch if approval is absent or differs; the migrated runtime
    remains usable with unreferenced files still present.
- [ ] **8.4 Delete only the approved paths and update coverage**
  - Change: after exact approval, remove only the approved files using literal
    repository-contained paths. Retain `vehicle_stage_theme.tres`, the font and
    license, and every gameplay semantic image. Remove raster count/provider
    assertions from `validate_vehicle_visual_replacement_coverage.gd`; rely on
    `validate_vehicle_ui_components.gd` for the code-native contract.
  - Accept: Godot import reports no missing resource; zero files remain under
    UI `controls`, `surfaces`, or `glyphs`; the UI production root contains the
    Theme and font family only; all focused validators pass.
- [ ] **8.5 Record application and reconcile generated workbench output**
  - Change: set `ui_chrome_retirement` to `retired`, record its exact
    approval/application evidence, rebuild `inventory.json` and `index.html`,
    and amend the broader visual plan's expected UI PNG/manifest count from 54
    to zero code-native chrome files. Retain `ui_chrome_retirement` as retired
    history until the broader visual plan's Phase 10 lifecycle cleanup; do not
    remove it opportunistically in this plan.
  - Accept: workbench build and `-Check` are byte-identical; every remaining
    production media file has one owner; the final projection is exactly 36
    units, four retire-only units, 215 gameplay PNGs, zero UI PNGs, one font,
    and statuses `keep_current=2`, `target_required=30`, `retired=4`; the gallery
    remains review-only; no completed UI target asks for replacement artwork.

Batch gate:

```powershell
.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_ui_components.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_visual_replacement_coverage.gd
.\tools\design\build_visual_replacement_workbench.ps1
.\tools\design\build_visual_replacement_workbench.ps1 -Check
.\tools\validation\validate_visual_replacement_workbench.ps1
git diff --check
```

Commit boundaries: one ledger/approval-preparation commit, one exact approved
retirement commit, and one application-ledger/generated-output commit. Do not
combine deletion with unrelated screen work.

### Phase 9: Run cross-surface release evidence and retire this contract

Goal: prove the reconstructed UI in production-style native and built-Web
flows, record durable truth, and return the broader visual plan to Phase 6.

Preconditions:

- Phase 8 passes and the worktree contains only task-owned changes.
- Load `codebase-quality-auditor` before the final architecture audit.
- Load `npjt-port-guard` before starting or reusing any built-Web server.

Source owners: all changed UI/runtime/validator/docs paths, capture driver,
`tools/export_web.ps1`, evidence record, and both active plans.

- [ ] **9.1 Run the complete deterministic validator and import gate**
  - Change: run document authority, every sorted `validate_*.gd`, workbench
    build/check/validation, Godot import, and `git diff --check` from the repo
    root. Save long logs under `build/ui-reconstruction-final/logs`.
  - Accept: every command exits zero; no missing resource, raw key, orphan
    chrome reference, layout overflow, gameplay behavior, or fixed-Hard failure
    remains.
- [ ] **9.2 Capture the complete KO/EN viewport matrix**
  - Change: capture all fixtures at 960x540, 1280x720, and 1920x1080 in Korean
    and English, plus KO and EN at 1280x720 with text scale 2.0.
  - Accept: each directory contains the complete capture manifest; every modal,
    HUD state, selected/focused/disabled state, locked state, empty state,
    failure state, and primary action is judgeable.
- [ ] **9.3 Perform the Level 4 visual/accessibility review**
  - Change: compare the actual runtime captures to the accepted gallery
    direction and the four authoritative corrections. Inspect alignment,
    typography, spacing, surface count, focus order, focus visibility,
    grayscale state, 200% text, clipping, overflow, scroll boundaries,
    reduced motion, and primary/destructive hierarchy.
  - Accept: no information is missing; upgrade has one image/card and no exit;
    Pause is one vertical stack; no difficulty UI appears; no decorative
    greeble or screen-specific chrome returns; all warnings are fixed or
    explicitly recorded with owner acceptance.
- [ ] **9.4 Export and smoke the built Web artifact**
  - Change: run `.\tools\export_web.ps1`, serve the resulting `build\web`
    directory with the exact port/readiness/PID block below, and use Chrome to
    test Deployment -> live HUD -> Pause -> Settings -> Guidebook -> resume, an
    Upgrade choice, failure/report, result/Garage, KO/EN switching, keyboard
    focus, mouse, and compact resize. Reuse only a verified same-project server;
    stop only the exact task-owned server PID afterward.
  - Accept: required Web files exist; all requests succeed; console has no UI
    error/warning; every tested action returns to the correct surface; no
    unowned process remains.
- [ ] **9.5 Audit boundaries and fix only task-scoped findings**
  - Change: run the codebase-quality audit over the Theme, factory, shared
    primitives, screen owners, signal changes, validators, and removed pack.
    Correct responsibility creep, duplicate construction, stale contracts, or
    competing ownership only when the fix stays inside this plan.
  - Accept: no catch-all screen builder, direct local StyleBox, duplicate
    semantic image, stale optional/difficulty path, or competing UI owner
    remains.
- [ ] **9.6 Record durable evidence and retire the plan**
  - Change: update `docs/product/vehicle_game_spec.md` and
    `docs/design/VISUAL_SYSTEM.md` with any implementation-exact wording; append
    commit, Godot version, commands, capture paths, viewport/locale matrix,
    built-Web result, and accepted warnings to
    `.agents/semantic-v2-runtime-acceptance-evidence.md`; unblock the broader
    visual plan at Phase 6; delete this completed ExecPlan after all durable
    decisions and evidence have landed.
  - Accept: future agents need only the active product/visual specs and the
    broader visual plan; this temporary execution contract no longer remains
    in `.agents/execplans`.

Final gate commands:

```powershell
.\tools\validation\validate_document_authority.ps1
$validators = Get-ChildItem -LiteralPath tools\validation -Filter validate_*.gd | Sort-Object FullName
foreach ($validator in $validators) {
  $resourcePath = "res://tools/validation/$($validator.Name)"
  .\tools\godot.ps1 --path . --headless --script $resourcePath
  if ($LASTEXITCODE -ne 0) { throw "Validator failed: $resourcePath" }
}
.\tools\godot.ps1 --path . --headless --import
.\tools\design\build_visual_replacement_workbench.ps1 -Check
.\tools\validation\validate_visual_replacement_workbench.ps1
.\tools\export_web.ps1
git diff --check
```

Capture commands:

```powershell
.\tools\godot.ps1 --path . -- --capture-all=build\ui-reconstruction-final\ko-960x540 --capture-locale=ko --capture-size=960x540
.\tools\godot.ps1 --path . -- --capture-all=build\ui-reconstruction-final\en-960x540 --capture-locale=en --capture-size=960x540
.\tools\godot.ps1 --path . -- --capture-all=build\ui-reconstruction-final\ko-1280x720 --capture-locale=ko --capture-size=1280x720
.\tools\godot.ps1 --path . -- --capture-all=build\ui-reconstruction-final\en-1280x720 --capture-locale=en --capture-size=1280x720
.\tools\godot.ps1 --path . -- --capture-all=build\ui-reconstruction-final\ko-1920x1080 --capture-locale=ko --capture-size=1920x1080
.\tools\godot.ps1 --path . -- --capture-all=build\ui-reconstruction-final\en-1920x1080 --capture-locale=en --capture-size=1920x1080
.\tools\godot.ps1 --path . -- --capture-all=build\ui-reconstruction-final\ko-1280x720-text2 --capture-locale=ko --capture-size=1280x720 --capture-text-scale=2
.\tools\godot.ps1 --path . -- --capture-all=build\ui-reconstruction-final\en-1280x720-text2 --capture-locale=en --capture-size=1280x720 --capture-text-scale=2
```

Codex-lane port resolution before built-Web smoke:

```powershell
$uiSmokePort = (py -3.11 "C:\Users\BK\.codex\skills\npjt-port-guard\scripts\npjt_port_guard.py" --project "D:\npjt\cardborne-platformer" --service web --print-port | Select-Object -Last 1) -as [int]
$uiSmokeWebRoot = (Resolve-Path -LiteralPath "build\web").Path
$uiSmokeLogRoot = Join-Path (Resolve-Path -LiteralPath "build\ui-reconstruction-final").Path "web-smoke"
New-Item -ItemType Directory -Path $uiSmokeLogRoot -Force | Out-Null
$uiSmokeStdout = Join-Path $uiSmokeLogRoot "server.stdout.log"
$uiSmokeStderr = Join-Path $uiSmokeLogRoot "server.stderr.log"
$uiSmokeProcess = $null
$uiSmokeOwnsProcess = $false

$uiSmokeListener = Get-NetTCPConnection -State Listen -LocalPort $uiSmokePort -ErrorAction SilentlyContinue
if ($null -ne $uiSmokeListener) {
  $uiSmokePid = @($uiSmokeListener | Select-Object -ExpandProperty OwningProcess -Unique)
  if ($uiSmokePid.Count -ne 1) { throw "Codex-lane port has ambiguous listeners." }
  $uiSmokeProcessRecord = Get-CimInstance Win32_Process -Filter "ProcessId = $($uiSmokePid[0])"
  if ($null -eq $uiSmokeProcessRecord -or $uiSmokeProcessRecord.CommandLine -notlike "*http.server*$uiSmokePort*$uiSmokeWebRoot*") {
    throw "Codex-lane port is owned by an unverified process."
  }
} else {
  $uiSmokePython = (py -3.11 -c "import sys; print(sys.executable)" | Select-Object -Last 1).Trim()
  $uiSmokeProcess = Start-Process -FilePath $uiSmokePython -ArgumentList @(
    "-m", "http.server", [string]$uiSmokePort,
    "--bind", "127.0.0.1", "--directory", $uiSmokeWebRoot
  ) -RedirectStandardOutput $uiSmokeStdout -RedirectStandardError $uiSmokeStderr -WindowStyle Hidden -PassThru
  $uiSmokeOwnsProcess = $true
}

try {
  $uiSmokeReady = $false
  for ($uiSmokeAttempt = 0; $uiSmokeAttempt -lt 40; $uiSmokeAttempt++) {
    try {
      $uiSmokeResponse = Invoke-WebRequest -UseBasicParsing "http://127.0.0.1:$uiSmokePort/index.html"
      if ($uiSmokeResponse.StatusCode -eq 200) { $uiSmokeReady = $true; break }
    } catch {}
    Start-Sleep -Milliseconds 250
  }
  if (-not $uiSmokeReady) { throw "Built-Web server did not become ready within 10 seconds." }
  # Perform the Chrome interaction matrix in Task 9.4 while this block is active.
} finally {
  if ($uiSmokeOwnsProcess -and $null -ne $uiSmokeProcess) {
    $uiSmokeOwnedRecord = Get-CimInstance Win32_Process -Filter "ProcessId = $($uiSmokeProcess.Id)"
    if ($null -ne $uiSmokeOwnedRecord -and $uiSmokeOwnedRecord.CommandLine -like "*http.server*$uiSmokePort*$uiSmokeWebRoot*") {
      Stop-Process -Id $uiSmokeProcess.Id
    } elseif ($null -ne $uiSmokeOwnedRecord) {
      throw "Refusing to stop a process whose command line no longer matches the task-owned server."
    }
  }
}
```

Expected current registry result is `13029`; always use the helper result and
never invent a fallback. If occupied, inspect the PID, command line, and
project/service ownership before reuse; never kill an unknown listener.

Commit boundary: one final integration/evidence commit followed by the durable
handoff/plan-retirement commit required by `.agents/PLANS.md`.

## Parallel Execution Map

Parallel work is allowed only after Phase 2 freezes the shared API.

| Lane | Earliest start | Owned files | Forbidden overlap | Merge gate |
| --- | --- | --- | --- | --- |
| Entry/reward lane | Phase 2 complete | Phase 3 then Phase 4 runtime, Deployment, Garage, Upgrade, related validators/localization | Theme/factory changes after Phase 2 | Phase 4 gate |
| Settings/Guide lane | Phase 4 contracts complete | Phase 5 screen owners and focused validators | Stage UI routing, reward runtime, report files | Phase 5 gate |
| Report lane | Phase 4 contracts complete | Phase 6 screen owners and focused validators | Theme/factory, Settings/Guide files, HUD | Phase 6 gate |
| HUD/integration lane | Phases 5 and 6 complete | Phase 7, then parent-owned retirement and release | No parallel deletion or workbench application | Phase 7 gate |

Every subagent receives a goal, exact owned paths, forbidden paths, stop
condition, and required command evidence. The parent integrates and validates;
no child may delete media, change the Theme contract, or commit another lane's
files.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | Parser/import plus the one focused validator named by the task | A task-owned code or resource input changes | That input changes again or a failed assertion is fixed |
| Contract gate | Document authority, localization, workbench `-Check` | Phase 1 or durable contract text changes | A governing doc, locale row, or workbench source changes |
| Component gate | `validate_vehicle_ui_components.gd`, Pause, stage UI layout | Theme, factory, host, primitive, or Pause changes | One of those owners changes |
| Entry gate | settings, run difficulty, encounter pacing, damage feedback, layout, localization | Phase 3 tasks pass | Entry/difficulty/settings input changes |
| Upgrade gate | upgrade system, upgrade UI, rewards/UI audio, layout, localization | Phase 4 tasks pass | Upgrade/reward input changes |
| Content modal gate | Settings, Guidebook, Boss Practice, stage report, layout, localization | Phase 5 or 6 tasks pass | Those screen owners change |
| HUD gate | HUD presenter, rewards/UI audio, layout, renderer, performance scenarios | Phase 7 tasks pass | HUD/presenter/transient input changes |
| Retirement gate | import, component validator, replacement coverage, workbench build/check/validate | Exact deletion or ledger changes | Retirement-owned input changes |
| Final gate | all validators, full capture matrix, Web export, built-Web interaction smoke, quality audit | All phases are green and inputs are frozen | A final-gate input changes |

Validation rules:

- Run the narrowest check that proves the current task.
- Run each phase gate once after its owned tasks pass.
- Do not run full captures or export after every screen; run phase captures at
  the named checkpoints and the complete matrix once in Phase 9.
- Rerun a failed check only after a relevant implementation change or a new
  hypothesis can produce different evidence.
- Record a known non-blocking warning once; do not repeatedly rediscover it.
- A passing headless check cannot replace rendered visual evidence.
- A successful Web export cannot replace built-Web interaction smoke.

## Test Plan

Structural invariants:

- [ ] One Theme asset owns all code-native UI chrome.
- [ ] Six conceptual primitives cover every screen.
- [ ] Zero production screen creates a local StyleBox or screen-specific chrome
  variation.
- [ ] Zero `StyleBoxTexture`, UI manifest, or UI provider reference remains
  after Phase 8.
- [ ] Zero production PNG remains under UI `controls`, `surfaces`, or `glyphs`.
- [ ] The UI folder retains only the Theme, Noto Sans KR font, and license.
- [ ] Gameplay semantic imagery retains its gameplay manifest/provider owner.
- [ ] Every modal has one host-owned root Surface and at most one primary
  action.

Behavior invariants:

- [ ] Every run uses the previous Hard factors and no preference can alter it.
- [ ] Deployment has no difficulty UI and preserves every control/loadout fact.
- [ ] Upgrade offers remain frozen, require one selection and Equip, and expose
  no decline path.
- [ ] Every upgrade card has zero header images and exactly one body artwork.
- [ ] Pause actions form Resume -> Restart -> Settings -> Garage vertically.
- [ ] Settings, Guidebook, report, result, Garage, debug Practice, HUD,
  transition, and notification behavior remains complete.
- [ ] Stages 1-4 still transition without a success report; Stage 5 and failure
  flows remain correct.
- [ ] Manual aim, held primary fire, dash, EMP, passive secondaries, collision,
  encounter content, and map behavior remain unchanged.

Visual/accessibility invariants:

- [ ] No unnecessary dot, seam, corner, nested frame, lamp, badge, or greeble
  remains in UI chrome.
- [ ] Information is removed only for the explicitly retired difficulty and
  decline concepts.
- [ ] Focus, selected, disabled, danger, warning, and locked states do not rely
  on color alone.
- [ ] KO and EN have identical reachable actions and complete copy.
- [ ] 960x540, 1280x720, 1920x1080, and KO/EN 200% text have no overlap,
  clipping, container escape, or unreachable fixed action.
- [ ] Every operated target is at least 44 px and focus order matches task
  order.
- [ ] Reduced motion removes only repeated motion, never information.

## Rollback and Safety

- Create one coherent task-owned commit at every named commit boundary.
- Record the last green commit in Progress before starting the next phase.
- If a phase fails, use a normal `git revert` of only its scoped commit or apply
  a narrow correction. Never reset, clean, or restore unrelated work.
- Keep the 54 raster files until every runtime consumer and focused validator
  is green; unreferenced files are safer than premature deletion.
- Phase 8 deletion uses an explicit sorted literal path set. Do not use glob or
  recursive delete against the UI root.
- Verify each retirement target resolves inside
  `D:\npjt\cardborne-platformer\art\visuals\production\ui` or is one of the
  explicitly named provider/validator files before deletion.
- If import fails after retirement, revert only the retirement commit, locate
  the remaining reference, and repeat the zero-reference gate. Do not recreate
  replacement PNGs as a shortcut.
- If built Web fails after a native pass, keep native evidence as diagnostic,
  fix the built artifact path, and do not declare completion.
- Stop only exact task-owned server/browser helpers. Never terminate by process
  name alone.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A current spec sentence conflicts with this contract | Apply Phase 1's locked amendment before code changes | Do not preserve the obsolete raster/difficulty/decline sentence as a second authority |
| A gallery image conflicts with a locked screen contract | Follow the text contract and actual runtime data | Do not regenerate another concept image to decide the issue |
| Compact content overflows | Remove decorative spacing, use the authorized screen scroll region, then retest KO/EN | Do not remove information or shrink body text below 14 px |
| A meaningful preview asset is unavailable | Use the existing approved family glyph or neutral locked silhouette owned by the gameplay semantic provider | Do not generate a screen-specific replacement without new approval |
| A screen appears to need a seventh primitive | Express it as a semantic variant/composition of the six primitives | Replan only if behavior cannot be represented without a new responsibility owner |
| A legacy raster reference remains | Keep all retirement files, fix the owner, and rerun the focused gate | Do not request deletion approval while a consumer remains |
| The exact retirement set changes after approval | Invalidate approval, print the new baseline/path/hash set, and request approval again | Never infer approval for an altered set |
| Old user settings contain `gameplay/run_difficulty` | Ignore its value, erase only that key on the next normal save, and preserve all other settings | Do not mutate the active run or wipe/rewrite unrelated settings |
| A validator enforces an obsolete visual implementation | Replace it with behavior, structure, layout, and state assertions in the same phase | Do not weaken coverage merely to make the suite pass |
| Built-Web port is occupied | Inspect PID, command line, and project/service; reuse only a matching Cardborne server | Stop and report unknown ownership; never choose another port or kill it |
| A verified material fact invalidates this contract | Stop the affected branch, update this contract, and obtain required approval | Do not let an executor choose a new product, architecture, UX, safety, or validation contract |

Implementation-local discoveries may be handled inside the locked contract when
they cannot change scope, visible behavior, ownership, architecture, safety, or
acceptance.

## Risks

- The Theme is a central dependency, so a syntax or variation-name error can
  break every surface. Mitigation: Phase 2 keeps legacy media, imports first,
  and proves one Pause vertical slice before parallel migration.
- Programmatic UI can hide duplication inside screen scripts. Mitigation: the
  new component validator and final quality audit check factory use and
  forbidden local styles, not only screenshots.
- Fixed-Hard changes cross UI, settings, run, encounter, and tests. Mitigation:
  retain the existing Hard compatibility profile and verify exact 1.0 factors
  and authored quotas before visual work proceeds.
- Removing optional decline crosses reward runtime and UI. Mitigation: current
  call-site evidence shows all opens are mandatory; focused reward and upgrade
  validators prove transaction completion and frozen offers.
- English or 200% text can expose failures not visible in Korean 1280 captures.
  Mitigation: explicit eight-directory final capture matrix and no font
  reduction below 14 px.
- The 54-state workbench history can conflict with a zero-raster final state.
  Mitigation: one temporary retire-only ledger, generated-output checks, and an
  explicit amendment to the broader visual plan.

## Assumptions

- Discovery baseline `2935d08` is clean; execution records a fresh baseline if
  HEAD advances before Phase 1.
- The accepted gallery establishes composition and density, not exact text,
  numeric values, or production pixels.
- BK's request to consolidate fragmented shared component assets authorizes
  replacing raster chrome with one code-native Theme asset after the canonical
  spec is amended.
- The current eight upgrade-family semantic images are the intended related
  card artwork; this plan does not create 41 per-card illustrations.
- The current Hard profile is the desired sole balance and remains numerically
  unchanged.
- `960x540` is the smallest contractual viewport. A smaller smoke may be
  diagnostic but cannot become release acceptance in this plan.

## Open Questions

None at planning handoff. All material product, architecture, layout,
retirement, and validation decisions are locked above.

## Progress

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 4 — rebuild Upgrade as mandatory Selectable cards.
- Last completed gate: Phase 3 entry-flow gate; settings migration, fixed-Hard,
  encounter pacing, damage feedback, stage-layout, and KO/EN localization
  validators passed after a clean Godot import.
- Last green implementation commit:
  `06f8e2b23f85630d8494aa6aeca3ff4409b87f2d`.
- Update rule: after a checkpoint passes, record concise evidence, check the
  task, update the last green commit, and advance this pointer in the same edit.

## Next Steps

1. Remove the optional reward/decline path from runtime and UI.
2. Recompose Upgrade cards around one lower semantic artwork and one Equip
   command.
3. Pass the Phase 4 reward and Upgrade gate before parallel Phase 5/6 work.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check and batch/final gate passes.
- The actual runtime, not only the gallery, visibly uses the shared simple UI.
- Fixed Hard, mandatory Upgrade, one-art cards, vertical Pause, every other
  screen contract, and all preserved information are verified.
- The approved legacy raster set is retired with zero reference and durable
  evidence, or remains present only because exact deletion approval was not
  granted; in the latter case this plan is not complete.
- Durable product/design truth and acceptance evidence are current.
- This completed plan is deleted according to `.agents/PLANS.md` after its
  decisions are incorporated.

Replan when:

- A verified fact invalidates a locked product, architecture, ownership,
  safety, or acceptance decision.

Do not replan or stop for:

- Implementation-local mechanics already contained by this contract.
- A passing check whose relevant inputs have not changed.
- The absence of new generated UI images; this contract intentionally replaces
  chrome with shared code-native components.

## Decision Notes

- 2026-08-03T18:55:34+09:00: Execution started on branch `master` at clean
  baseline `d7ac985d614532049e04be16edb26854f735cf66` with Godot
  `4.7.1.stable.official.a13da4feb`.
- 2026-08-03: Phase 1 completed in
  `01dd966ab3ac63bcce11fa768834a4cd87b56c99`; product and visual specs now own
  fixed Hard, mandatory upgrade confirmation, shared code-native UI chrome, and
  the corrected gallery interpretation.
- 2026-08-03: Phase 2 completed in
  `52cdce9c38566793802a7faa8b0045667b653da6`; the Theme now contains zero raster
  StyleBoxes, the factory owns the six shared primitives and compatibility map,
  and Pause is the first vertical-stack reference screen.
- 2026-08-03: Phase 3 completed in
  `06f8e2b23f85630d8494aa6aeca3ff4409b87f2d`; every run now uses the unchanged
  Hard profile, obsolete saved difficulty is retired on normal save, and
  Deployment/Garage use the shared two-column composition without a selector.
- 2026-08-03: BK accepted the simplified UI direction while explicitly
  preserving information rather than reducing it.
- 2026-08-03: BK required deletion of the small top image on upgrade cards,
  because one related image will appear in the card body; BK also stated that
  the Upgrade screen should not have a Leave button.
- 2026-08-03: BK required Pause to be a simple vertical stack and considered
  the remaining screen directions acceptable.
- 2026-08-03: The component, layout, and validation audits found that the
  requested direction conflicts with the active raster-only, three-difficulty,
  and optional-decline specifications. This contract resolves those conflicts
  through a spec-first migration.
- 2026-08-03: The code-native Theme route is locked because another raster
  state family would preserve the exact fragmentation BK asked to remove. The
  Theme resource is the shared design asset; semantic gameplay imagery remains
  image-backed content.
- 2026-08-03: No new concept or production images are required for this plan.
  Actual native and built-Web runtime captures become final visual evidence.

## Execution Handoff

A fresh executor starts at Task 1.1 after reading this complete contract and
the authority files named in Phase 1. Execute phases in order, except the
explicitly disjoint Phase 5/6 parallel lane. Do not add another visual
direction, generate new UI chrome, preserve the obsolete difficulty/decline
paths, or delete any legacy media before the exact Phase 8 approval gate.
