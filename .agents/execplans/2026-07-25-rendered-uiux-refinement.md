---
type: plan
status: active
owner: BK
created: 2026-07-25
last_reviewed: 2026-07-25
scope: Rendered UI hierarchy, modal composition, upgrade-choice usability, guide and report readability, and combat silhouette identity
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ./2026-07-23-vehicle-performance-architecture-stabilization.md
  - ./2026-07-25-stage-tactical-variation-and-ui-readability.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../docs/design/uiux-refinement-direction/README.md
---

# Rendered UIUX Readability and Visual Identity — Execution Plan

This six-phase plan refines the current Godot 4.7 connected vehicle run
without changing its controls, combat rules, progression, palette, or art
direction. It starts from the rendered Korean/English capture matrix and the
current production owners, then replaces weak information hierarchy and
duplicated combat silhouettes with one decision-complete implementation. The
six generated target images are explanatory evidence, not raster assets to ship
in the game.

## Purpose

- **Objective:** Make the current game immediately readable at first encounter:
  choices should scan in order, modal actions should have obvious priority,
  current-build information should be easy to inspect, and tactically different
  actors/projectiles should remain distinguishable at gameplay scale.
- **Final artifact:** Production Godot UI and procedural mesh changes, complete
  Korean/English copy, focused validators, deterministic rendered captures, a
  production Web export, and an updated active visual specification.
- **Completion state:** Every in-scope screen matches the locked hierarchy below
  at `960×540`, `1280×720`, and `1920×1080`; combat presentation keeps the
  existing batch/capacity contract; no HOLD item or new gameplay enters the
  implementation.

## Pre-plan Evidence Already Verified

| Source or path | Verified fact | Decision affected | Freshness or recheck boundary |
| --- | --- | --- | --- |
| `AGENTS.md`, `.agents/AGENTS.md`, `.agents/PLANS.md` | Broad multi-owner UI work requires an ExecPlan, Korean/English parity, Godot 4.7, current owners, focused validators, and Web export. | Plan location, lifecycle, ownership, and gates. | Re-read before execution if any instruction file changes. |
| `docs/product/vehicle_game_spec.md` | The executable is a connected run with fixed controls, held primary fire, one-second Breach Shot, three difficulties, five secondary families, five guide categories, and current report data. | No controls, progression, or gameplay may be invented by the UI pass. | Re-read if product behavior changes. |
| `docs/design/UI_VISUAL_SYSTEM.md` | Flat color, large geometric masses, no decorative outline/texture, the existing semantic palette, compact HUD, 44-pixel commands, Korean default, and exact collision/visual truth are canonical. | Palette, typography, shape, density, and accessibility constraints. | Re-read before changing theme or combat geometry. |
| `art/ui/production/vehicle_stage_theme.tres` | Noto Sans KR is wired at weight 650/800; common button states are shared, but choice cards and tertiary destructive actions have no dedicated state contract. | Extend the existing theme; do not create per-screen ad hoc styles. | Reinspect after another theme change. |
| `scripts/ui/vehicle_upgrade_choice_panel.gd` | Three `272×244` buttons receive one concatenated text string; selection/confirmation guard logic is already correct. | Replace presentation structure while preserving the two-step transaction and `0.35 s` guard. | Reinspect if reward flow changes. |
| `scripts/ui/vehicle_stage_ui.gd` | Deployment is one tall stack; pause uses a dominant filled danger action; garage prints a trailing empty passive label; HUD anchors and boss replacement behavior are already compact and functional. | Recompose only the weak modal surfaces; keep live HUD structure. | Reinspect if screen ownership moves. |
| `scripts/ui/vehicle_build_summary_panel.gd`, `vehicle_settings_panel.gd` | Active build data is sufficient but presented as one long list; no-run behavior intentionally has one empty state. | Group existing data only; do not invent baseline stats outside a run. | Reinspect if the build snapshot schema changes. |
| `scripts/ui/vehicle_guidebook_panel.gd` | The Current Ship category wastes an entry-list column; discovered entries already contain preview, description, movement, attack, and counterplay data. | Collapse only the redundant ship column and structure existing detail data. | Reinspect if guide categories or discovery rules change. |
| `scripts/ui/vehicle_stage_report_panel.gd` | Wide three-column and compact tab layouts already express the correct datasets and input guard. | Keep the information architecture; polish alignment and CTA width only. | Reinspect if telemetry schema changes. |
| `scripts/presentation/vehicle_combat_visual_library.gd` | Several different tactical roles share identical square, hexagon, or stepped-square silhouettes; all hostile heads use one round mesh. | Redesign only duplicated families and hostile head geometry inside current static meshes. | Reinspect if archetypes or projectile affinities change. |
| `scripts/ui/vehicle_threat_radar.gd` | Priority and targeted sectors already use distinct mustard/ivory shape cues in one batched mesh. | Reject the audit suggestion to add another radar priority system. | Recheck only if radar snapshot fields change. |
| `build/audits/ui-visual-snapshot-2026-07-25/` | 384 local PNGs cover production assets and runtime states; current weaknesses are visible at real scale across locale/viewport matrices. | Rendered evidence, not source inspection alone, is the visual authority. | Regenerate after implementation. |
| `build/audits/ui-visual-snapshot-2026-07-25/agy-reports/FINAL-rendered-ui-visual-asis-tobe-audit.md` | The corrected external audit identifies real hierarchy and silhouette issues but also contains proposals that conflict with current specs. | Treat as advisory evidence; accept only locally verified findings. | Never use as policy or spec. |

## Locked Decisions

| Topic | Final decision | Rationale / source |
| --- | --- | --- |
| Product scope | Preserve the complete current connected run, controls, data, input guards, focus flow, and gameplay rules. | Product spec and user request are for UIUX refinement, not another pivot. |
| Art direction | Keep the exact Sunken Ceramic Fresco semantic palette, flat fills, large shapes, and restrained detail. Add no glow, gradient, texture, ornamental border, or new affinity hue. | Active visual spec. |
| Generated images | Use the six PNGs under `docs/design/uiux-refinement-direction/` as composition and hierarchy references only. All runtime values, localization, and controls remain code-generated. | Active visual spec forbids baked UI text/assets; image-model text is not authoritative. |
| Live HUD | Keep the current top-left hull/XP, `154×34` icon rail, transient top-center objective, top-right minimap, off-screen threat radar, boss replacement, and target panel. | Rendered and code inspection show the structure is already compact and bounded. |
| Upgrade choice | Replace each monolithic text button with a reusable structured `Button` component: family strip, bold title, short effect, numeric delta rows, three-step level pips, and a selected marker. Keep exactly three choices and explicit confirm. | Highest-frequency visible hierarchy failure; all required data already exists. |
| Upgrade selection state | Selected uses a four-pixel mustard frame plus a solid diamond marker; keyboard focus uses the existing left focus rail. Disabled confirm remains readable but visibly inactive. No state relies on color alone. | Accessibility and current visual system. |
| Upgrade prerequisites | Do not add a “Requires” badge in this pass. The offer already filters out unmet prerequisites, and the selection snapshot does not expose a stable prerequisite-title contract. | Avoid irrelevant or invented information and cross-module schema expansion. |
| Deployment | Recompose existing content into a spanning header and two-column body. Left owns controls and Pulse Cannon summary; right owns difficulty and its locked-run explanation. Use a centered `300×48` Deploy action, compact Settings action, and debug-only Boss Practice. Add no map preview. | Reduces vertical stacking using only existing data and behavior. |
| Pause | Keep all actions, but make Resume the only filled primary action; Settings and Restart remain secondary; Abort becomes a restrained tertiary danger action. Keep `?` in the header. | Prevent destructive action dominance without changing flow. |
| Garage | Preserve current functionality and data. Render `없음` / `None` when the passive list is empty and use the same compact loadout/command hierarchy as other modals. | Verified formatting bug and hierarchy inconsistency. |
| Active Ship Status | Use existing `run_state`, stat IDs, secondary rows, and upgrades. Show one summary strip, three stat groups, then secondary and upgrade lists inside the existing single page scroll. | Improves scan order without changing gameplay ownership. |
| No-run Ship Status | Show only the existing localized empty state and hide all group headings/values. Do not fabricate baseline stats or placeholder slots. | Explicit product and visual spec requirement. |
| Guidebook | Keep five categories and discovery rules. Hide the entry column and adjacent separator only for Current Ship; otherwise keep category → entry → detail. Add explicit selected states and lay detail as preview, description, then Movement/Attack/Counter rows. Locked entries remain unchanged. | Uses existing data and fixes the verified redundant column. |
| Stage/failure report | Preserve the wide three-column and compact-tab information architecture. Align names, amounts, percentages, and counts; use light dividers; constrain the primary action to `300×48`. Add no chart. | Existing report is functionally strong; only density and scan alignment need refinement. |
| Enemy identity | Keep effective role colors and radii. Redesign only the duplicated silhouette families with one large body cut or directional mass per role; keep already distinct actors unchanged. | Fixes tactical ambiguity without recoloring ownership or changing simulation. |
| Hostile projectile identity | Keep current affinity colors, damage-sized collision radii, and trails. Give each affinity a distinct head silhouette whose farthest vertex equals, and never exceeds, the collision radius. Player mustard-ring projectiles remain unchanged. | Improves reaction readability while preserving collision truth and ownership. |
| Vehicle upgrade shades | Leave current hull/primary/secondary shade tiers and engine-count presentation unchanged. | Exact replacement values remain unapproved; the corrected audit classifies this as HOLD. |
| Threat radar and field pickups | Make no structural radar or pickup-animation change in this plan. | Radar priority already exists; floating pickup depth is not required by current product/visual specs. |
| Final result and locked guide entries | Leave unchanged except for shared typography/theme fixes that cause no content or structure change. | Their product flows remain intentionally HOLD. |
| Performance | UI modals create no combat work. Combat visual changes reuse the same archetype/affinity meshes, MultiMesh instances, capacities, and update cadence. No extra per-actor nodes, surfaces, or draw paths. | Active performance architecture and visual implementation boundaries. |

## Rejected Alternatives

| Alternative | Why it was viable | Why it was rejected |
| --- | --- | --- |
| Full UI or art-direction rewrite | The current visuals are visibly underdeveloped. | It would discard working architecture and contradict the accepted Sunken Ceramic Fresco system. |
| Add a deployment map preview | It could fill space and establish place. | Deployment currently receives a field name, not a stable pre-run tactical snapshot; it would add a new data flow for decoration rather than solve hierarchy. |
| Show default ship stats outside a run | It would make the empty settings tab look busier. | It contradicts the explicit one-empty-state contract and could imply stats that are not an active build snapshot. |
| Add prerequisite badges to offered cards | It could expose tech-tree context. | Unmet cards are never offered, and the current snapshot does not own prerequisite titles; the badge would add clutter and schema work without helping the immediate decision. |
| Recolor hostile support units or affinities with cyan/acid green | It could increase contrast. | It invents a palette outside the canonical semantic system and creates new ownership conflicts. |
| Use glow, shadow, texture, or fine internal line art | It could make primitives look more detailed. | It violates the flat, large-shape, performance-bounded art contract and repeats earlier visual failures. |
| Add a TAB build screen or other hotkeys | It could improve access. | No approved input contract exists and the user did not request new controls. |
| Replace the stage report with charts | Charts could look richer. | Three precise lists already answer the task; charts would consume space and duplicate data. |
| Add more live HUD panels | More data could be visible without pausing. | The user has repeatedly asked to uncover the map; current build detail belongs in Settings/Guidebook. |
| Rework threat radar priority coloring | The external audit recommended it. | Local code already implements priority and targeted color/shape cues; the finding is stale. |
| Add pickup bobbing and drop shadows | It could suggest elevation. | The game uses flat ground semantics and the change is not necessary to identify the two pickup types. |

## Current State

Already true or landed:

- The current Godot scene boots the complete connected run with Korean default
  and English parity.
- The production theme uses Noto Sans KR at medium/heavy weights and shared
  button states.
- Every major modal blocks gameplay, hides the live HUD, and provides keyboard
  focus and a 44-pixel command minimum.
- Upgrade selection already has unique choices, a `0.35 s` carried-input guard,
  explicit selection, and explicit confirmation.
- Settings and Guidebook already share one gameplay-owned build snapshot.
- The report already supports three columns at `>=1180` and keyboard tabs below
  that width.
- Combat actors/projectiles already render through bounded prebuilt meshes and
  retained MultiMesh batches.
- The live HUD, minimap, threat radar, boss bar, hit feedback, and player
  projectile ownership are already acceptable and remain in place.

Remaining implementation:

- Create responsibility-shaped structured upgrade cards and shared theme states.
- Recompose Deployment, Pause, and Garage without changing their actions.
- Reformat current-build information and remove redundant Guidebook space.
- Tighten report alignment and CTA width.
- Separate duplicated enemy roles and hostile affinities by large shape.
- Extend focused validators and regenerate the full rendered evidence matrix.

## Scope

In scope:

- `art/ui/production/vehicle_stage_theme.tres`
- A new `scripts/ui/vehicle_upgrade_choice_card.gd` presentation component.
- `scripts/ui/vehicle_upgrade_choice_panel.gd`
- Modal/HUD composition owned by `scripts/ui/vehicle_stage_ui.gd`
- `scripts/ui/vehicle_build_summary_panel.gd`
- `scripts/ui/vehicle_settings_panel.gd`
- `scripts/ui/vehicle_guidebook_panel.gd`
- `scripts/ui/vehicle_stage_report_panel.gd`
- `scripts/presentation/vehicle_combat_visual_library.gd`
- Korean/English UI copy in `localization/vehicle_stage.csv`
- Relevant validators and deterministic capture evidence.
- Durable accepted requirements in `docs/design/UI_VISUAL_SYSTEM.md`.

Out of scope:

- Combat balance, enemy AI, boss behavior, encounter pacing, stage topology,
  collision, damage, progression, card math, save schemas, input actions, or
  audio.
- Vehicle upgrade shade values, locked Guidebook entries, final-result flow,
  metagame, new field previews, new radar behavior, or pickup animation.
- Rasterizing runtime UI or replacing procedural production assets with the
  generated mockups.
- Raising entity, projectile, effect, batch, surface, or draw-call caps.

Destructive or irreversible actions:

- None. Existing IDs, data resources, input actions, save data, and runtime
  behavior remain intact.

Exact actions requiring owner/user approval:

- Any change to the locked palette, HOLD list, controls, gameplay data, save
  schema, production dependency set, or performance thresholds.

## Architecture and Ownership

| Concern | Final owner | Interface or invariant | Existing owner to reuse or retire |
| --- | --- | --- | --- |
| Shared typography/control states | `vehicle_stage_theme.tres` | One Noto Sans KR type system; 44-pixel commands; visible focus; flat fills. | Reuse all current theme variations; add only choice-card and tertiary-danger variations. |
| One upgrade card | `vehicle_upgrade_choice_card.gd` | Pure presentation of one offer dictionary; emits pressed intent through `Button`; no card behavior. | Retire monolithic `Button.text` formatting only. |
| Upgrade transaction | `vehicle_upgrade_choice_panel.gd` | Three unique offers, selection, guard, optional decline, explicit confirm. | Preserve every signal and timing contract. |
| Deployment/Pause/Garage composition | `vehicle_stage_ui.gd` | Existing actions and data only; modal input/focus remains blocked and deterministic. | Reuse current surface builders and responsive owner. |
| Frozen build rendering | `vehicle_build_summary_panel.gd` | Read-only snapshot; groups by existing stable stat IDs; no gameplay queries. | Reuse in Settings and Guidebook. |
| Settings flow | `vehicle_settings_panel.gd` | Five tabs, persistence owners, binding capture, no-run empty state. | Reuse current SettingsStore/InputProfile contracts. |
| Guide discovery and detail | `vehicle_guidebook_panel.gd` | Five categories; only encountered entries reveal content; locked remains `???`. | Reuse current snapshot and preview owners. |
| Stage/failure report | `vehicle_stage_report_panel.gd` | Existing defeat/source/attribute/incoming data and `0.35 s` guard. | Reuse current wide/compact split. |
| Actor/projectile mesh identity | `vehicle_combat_visual_library.gd` | Static vertex-colored meshes; maximum visible head radius equals collision radius; colors remain semantic. | Replace duplicated polygon recipes only. |
| Runtime transforms/batching | `vehicle_combat_renderer.gd` | No new batch, node, cadence, or capacity. | No structural change expected; touch only if a static mesh hookup requires it. |
| Localization | `localization/vehicle_stage.csv` | Korean/English rows remain complete and layout-equivalent. | Reuse current labels where possible; change only inaccurate or newly required section labels. |

## As-Is / To-Be Delta Map

| Concern | As-is | To-be | Acceptance check | Guard / leftover check |
| --- | --- | --- | --- | --- |
| Upgrade cards | One concatenated block per dark-green button. | Structured family/title/effect/delta/pips with stable equal heights. | Three cards scan in the same order in KO/EN at all viewports. | No `Button.text` body formatting remains. |
| Selected/disabled state | Thin left rail; confirm text becomes low-contrast. | Frame + diamond selected cue; clear focus; readable muted disabled CTA. | State is identifiable in grayscale and by keyboard focus. | Guard and confirm behavior are unchanged. |
| Deployment | Long single stack and full-width commands. | Two-column content and one compact primary action lane. | All existing content/actions remain reachable without clipping. | No field preview or new option exists. |
| Pause | Destructive fill competes with Resume. | Resume dominates; Abort is restrained tertiary danger. | First focus and strongest visual weight are both Resume. | Restart/Settings/Guide remain. |
| Garage empty passive | Trailing `보조 무기 · ` / `Passive · `. | Localized `없음` / `None`. | Empty and populated captures both read naturally. | No loadout/save behavior changes. |
| Active ship status | One long undifferentiated stat list. | Summary strip, three stat groups, secondaries, then upgrades. | Existing nine stats and current run values all appear once. | No gameplay calculation in UI. |
| No-run ship status | One message inside a large empty page. | One compact message; all headings/lists hidden. | No stale value or empty heading appears. | No fabricated baseline values. |
| Guide Current Ship | Redundant one-item middle column. | Middle column/separator hidden for Ship and restored elsewhere. | Full detail width for Ship; other categories unchanged. | Locked entries reveal nothing new. |
| Guide actor detail | Preview plus prose block. | Preview, concise description, and aligned Movement/Attack/Counter rows. | Existing localized fields appear exactly once. | No new stats or hidden content. |
| Stage report | Correct data, loose row alignment, full-width CTA. | Aligned columns/dividers and `300×48` primary action. | Source/attribute totals and responsive tabs remain correct. | No chart or duplicated data. |
| Enemy identity | Four square roles, three hex roles, and tower/boss reuse collide. | Ten duplicated roles receive distinct large silhouettes; already distinct roles stay untouched. | Grayscale catalog and live pressure capture allow role-family separation. | Colors, radii, AI, and collision unchanged. |
| Hostile heads | Every affinity is a colored round head. | Kinetic circle, thermal ember, toxin droplet, cryo shard, arc bolt-diamond, hybrid split diamond, support ring. | Head extent never exceeds physics radius; affinities differ without color. | Player projectile mesh unchanged. |
| HUD | Compact structure with acceptable ownership. | Same structure; benefits only from clearer combat shapes and shared typography. | Opaque area ratio and central-safe checks do not regress. | No new panel or bottom dock. |
| Vehicle shade | Subtle but implemented. | Unchanged. | Existing upgrade-sheet capture remains identical. | No new body decoration. |

## Tasks

### Phase 1: Shared component and state foundation

Goal: Add only the reusable visual primitives required by later phases.

Source owners touched: `art/ui/production/vehicle_stage_theme.tres`,
`scripts/ui/vehicle_upgrade_choice_card.gd`,
`tools/validation/validate_vehicle_stage_ui_layout.gd`

- [ ] **1.1** Extend the production theme with flat choice-card states.
  - **As-is:** Generic `ChoiceButton` states carry both command and card roles.
  - **To-be:** Add normal, hover, pressed, focus, selected, and disabled card
    variations with the existing green/mustard/ivory tokens. Selected has a
    four-pixel mustard frame; focus retains a distinct left rail.
  - **Accept:** Text remains medium/heavy, selected/focus/disabled are distinct
    without color alone, and no decorative radius/shadow/gradient is added.
  - **Guard:** Existing command, tab, progress, and HUD theme values do not
    change unintentionally.
- [ ] **1.2** Add `VehicleUpgradeChoiceCard`.
  - **As-is:** The panel owns body string formatting and button behavior.
  - **To-be:** A `Button` subclass owns family, title, effect, value rows, level
    pips, and selected marker; it receives an immutable offer dictionary.
  - **Accept:** The component has no catalog/run dependency and no apply logic.
  - **Guard:** Do not create one node per stat outside the three paused modal
    cards; no combat processing is added.
- [ ] **1.3** Add theme/layout contract assertions.
  - **As-is:** Validators check broad command height and modal visibility.
  - **To-be:** Assert card state variations, `>=44` commands, Noto Sans KR
    weights, and the absence of bottom-center HUD content.
  - **Accept:** Focused validator fails on a missing state or undersized action.
  - **Guard:** Do not encode screenshot colors as unrelated gameplay rules.

Batch acceptance:

- A standalone three-card fixture renders normal, focused, selected, and
  disabled states in Korean and English.

Batch guard:

- Existing scene import and `validate_vehicle_stage_ui_layout.gd` pass before
  screen recomposition begins.

### Phase 2: Upgrade-choice vertical slice

Goal: Ship the highest-frequency decision surface with complete hierarchy and
unchanged transaction behavior.

Source owners touched: `scripts/ui/vehicle_upgrade_choice_panel.gd`,
`scripts/ui/vehicle_upgrade_choice_card.gd`,
`tools/validation/validate_vehicle_rewards_ui_audio.gd`,
`localization/vehicle_stage.csv`

- [ ] **2.1** Replace monolithic card text with three structured components.
  - **As-is:** Family, title, description, values, and level are one text blob.
  - **To-be:** Family strip → title → one effect block → numeric delta rows →
    three fixed progress pips. Cards expand evenly with a 10-pixel gap.
  - **Accept:** Each card exposes the same information once; KO/EN body copy
    wraps without clipping at `960×540`.
  - **Guard:** Card IDs, offer order, duplicate prevention, shortcut keys, and
    optional decline remain unchanged.
- [ ] **2.2** Make selection and confirmation unmistakable.
  - **As-is:** Selection is a narrow rail and disabled confirm is low contrast.
  - **To-be:** Selected card uses frame + diamond; detail line reflects the
    selected effect; the centered `300×48` Equip action becomes enabled only
    after selection.
  - **Accept:** Mouse, keyboard focus, keys `1–3`, Enter/Space, Escape notice,
    guard, apply failure, and optional decline all pass.
  - **Guard:** No carried input or hover applies a card; no timer is introduced.
- [ ] **2.3** Capture all upgrade states.
  - **As-is:** Current matrix exposes weak choice/selected/confirmed hierarchy.
  - **To-be:** Deterministic captures cover choice, focus, selected, disabled
    confirm, confirmed teardown, optional decline armed, and apply failure.
  - **Accept:** The visual guide's hierarchy is recognizable without relying on
    generated text fidelity.
  - **Guard:** Confirmed teardown remains immediate.

Batch acceptance:

- `02-upgrade-choice.png` is matched in structure, and every behavioral
  assertion in the reward/UI validator still passes.

Batch guard:

- No `.tres` card definition, modifier, requirement, or offer algorithm changes.

### Phase 3: Deployment, Pause, and Garage hierarchy

Goal: Remove oversized command slabs and make primary/destructive intent clear.

Source owners touched: `scripts/ui/vehicle_stage_ui.gd`,
`art/ui/production/vehicle_stage_theme.tres`,
`localization/vehicle_stage.csv`,
`tools/validation/validate_vehicle_stage_ui_layout.gd`,
`tools/validation/validate_vehicle_pause.gd`

- [ ] **3.1** Recompose Deployment from existing content.
  - **As-is:** An `840×620` single column stretches controls and actions.
  - **To-be:** A responsive surface up to `920×560` uses a spanning header and
    two body columns with a 20-pixel gap. Existing controls/Pulse Cannon occupy
    the left; difficulty and detail occupy the right; Deploy is `300×48`.
  - **Accept:** All three difficulties, selected state, locked-run explanation,
    Settings, debug Boss Practice, footer, and first focus remain reachable in
    both locales at all supported sizes.
  - **Guard:** No field preview, loadout selector, or difficulty behavior change.
- [ ] **3.2** Correct deployment guidance copy.
  - **As-is:** The footer refers to an obsolete “boss gate” interpretation.
  - **To-be:** Korean/English copy states that a full living-enemy clear is not
    required and that reaching the defeat quota then defeating the boss advances
    the run.
  - **Accept:** Copy matches the active stage-flow specification exactly.
  - **Guard:** This is documentation in UI, not a stage-flow change.
- [ ] **3.3** Rebalance Pause action hierarchy.
  - **As-is:** Filled coral Abort competes with mustard Resume.
  - **To-be:** Resume is the sole filled primary; Restart/Settings are secondary;
    Abort uses a flat tertiary danger style; Guide stays a named `?` control.
  - **Accept:** First keyboard focus, largest visual weight, and Escape return all
    point to Resume; destructive action remains reachable and labeled.
  - **Guard:** Pause still freezes simulation and shows the system cursor.
- [ ] **3.4** Fix and compact Garage.
  - **As-is:** Empty secondary data leaves a dangling label; content and actions
    are visually loose.
  - **To-be:** Empty lists show `SHIP_STATUS_NONE`; primary, automatic systems,
    active EMP, unlocks, and build summary form one scan path; Launch remains the
    primary action.
  - **Accept:** Empty and populated Korean/English captures contain no dangling
    separators, stale values, or invented equipment.
  - **Guard:** Garage and replay signals/data remain unchanged.

Batch acceptance:

- Deployment, Pause, and Garage have one obvious primary action and no clipped
  child at `960×540`, `1280×720`, or `1920×1080`.

Batch guard:

- Modal input blocking, HUD hiding, cursor visibility, focus restoration, and
  difficulty snapshot semantics pass unchanged.

### Phase 4: Settings, Guidebook, and Report information architecture

Goal: Make dense reference surfaces scan quickly while preserving their data and
discovery boundaries.

Source owners touched: `scripts/ui/vehicle_build_summary_panel.gd`,
`scripts/ui/vehicle_settings_panel.gd`,
`scripts/ui/vehicle_guidebook_panel.gd`,
`scripts/ui/vehicle_stage_report_panel.gd`,
`localization/vehicle_stage.csv`,
`tools/validation/validate_vehicle_build_snapshot.gd`,
`tools/validation/validate_vehicle_guidebook.gd`,
`tools/validation/validate_vehicle_stage_report.gd`

- [ ] **4.1** Group the active build snapshot by stable IDs.
  - **As-is:** Nine stats are one two-column sequence followed by long lists.
  - **To-be:** Existing `run_state` forms a Level/Hull/XP summary strip.
    `hull/speed/dash_cooldown`, primary/Breach stats, and EMP stats form three
    heading/divider groups. Secondary and upgrade lists follow.
  - **Accept:** Every current snapshot value appears once with its unit and no
    recalculation; long upgrade descriptions wrap safely.
  - **Guard:** UI groups by existing IDs only and does not query gameplay.
- [ ] **4.2** Preserve the truthful no-run state.
  - **As-is:** The empty message is correct but occupies a nested empty pane.
  - **To-be:** Show one compact localized message and hide summary/stat/list
    groups completely.
  - **Accept:** Deployment/Garage Settings shows no empty headings or stale run
    values.
  - **Guard:** Do not add fake baseline stats or slot placeholders.
- [ ] **4.3** Improve Settings density without changing the five tabs.
  - **As-is:** Some single controls stretch across the content width.
  - **To-be:** Constrain toggles, sliders, and binding command lanes while
    preserving 44-pixel targets and one vertical scroll per page.
  - **Accept:** Audio, controls, gameplay, and language behavior and persistence
    are unchanged in KO/EN.
  - **Guard:** No nested scroll trap and no difficulty control during a run.
- [ ] **4.4** Collapse the redundant Guidebook ship-entry column.
  - **As-is:** Current Ship consumes category, one-item entry, and detail columns.
  - **To-be:** Ship uses category + expanded detail; all other categories restore
    category + entry + detail. Active category and entry receive explicit
    selected states.
  - **Accept:** Switching categories repeatedly restores exact widths and focus
    order; Ship stats reuse the same build summary.
  - **Guard:** Locked entries remain only `???` with the neutral silhouette.
- [ ] **4.5** Structure discovered Guidebook details.
  - **As-is:** Preview is followed by prose and one concatenated counterplay
    label.
  - **To-be:** Large existing preview, concise description, then aligned Movement,
    Attack, and Counter rows using current keys.
  - **Accept:** No future name, description, color, role, or counterplay leaks.
  - **Guard:** Do not add stats, tabs, or search.
- [ ] **4.6** Polish the existing report rather than redesign it.
  - **As-is:** Correct three-column data with loose text alignment and a
    full-width action.
  - **To-be:** Stable label/value/percentage columns, restrained dividers, and a
    centered `300×48` action; compact tabs remain below `1180`.
  - **Accept:** Defeat, outgoing, attribute, incoming, empty, failure, and final
    states retain exact totals and focus order.
  - **Guard:** No charts, new telemetry, or duplicated totals.

Batch acceptance:

- The generated Settings, Guidebook, and Report references are matched in
  hierarchy; runtime data and discovery contracts remain identical.

Batch guard:

- KO/EN strings, keyboard navigation, 200% text-scale simulation, and compact
  scroll behavior show no clipping or focus trap.

### Phase 5: Combat silhouette and projectile identity

Goal: Make tactical roles readable without adding combat cost or changing the
semantic palette.

Source owners touched: `scripts/presentation/vehicle_combat_visual_library.gd`,
`tools/validation/validate_vehicle_combat_renderer.gd`

- [ ] **5.1** Introduce one static multi-polygon shape recipe per archetype.
  - **As-is:** `_enemy_polygon()` returns one body polygon and several roles share
    identical helpers.
  - **To-be:** A static recipe may contain one body plus at most one large inset
    mass/cut. `enemy_mesh()` still produces one vertex-colored mesh surface per
    archetype and the renderer still uses one existing MultiMesh batch.
  - **Accept:** Surface/batch/instance counts are unchanged.
  - **Guard:** No per-enemy nodes, runtime vertex generation, animation player,
    shader, outline, or texture.
- [ ] **5.2** Separate the ten duplicated role silhouettes.
  - **As-is:** Shooter/artillery/beam/pylon share a square; controller/repair/
    shield share a hexagon; turret/interceptor and Titan share a stepped square.
  - **To-be:** Shooter = forward-notched gun block; Artillery = broad target
    diamond; Beam Sentinel = long lens lozenge; Boss Pylon = four-arm anchor;
    Controller = six-lobed cog; Repair Tender = blocky plus; Shield Escort =
    forward shield/kite; Turret = stepped base with one barrel mass; Interceptor
    Tower = broad dish/wing mass; Titan = four-bastion fortress.
  - **Accept:** Each pair has a different grayscale outer contour at catalog and
    live scale; facing is legible where the role is directional.
  - **Guard:** Keep current role colors, radii, shadows, health bars, target
    brackets, collision, AI, and stats.
- [ ] **5.3** Preserve already successful actors.
  - **As-is:** Chaser, mine, rammer, bulkhead guard, splitter barge, Leviathan,
    Behemoth, and the player already have useful contours.
  - **To-be:** No geometry change except mechanical migration required by the
    recipe helper.
  - **Accept:** Pixel/mesh comparison confirms no visible redesign.
  - **Guard:** Do not expand this phase into all 20 enemies or five bosses.
- [ ] **5.4** Give hostile affinities distinct collision-bounded heads.
  - **As-is:** Seven hostile heads are circles; only trails and color differ.
  - **To-be:** Kinetic circle, thermal ember, toxin droplet, cryo shard, arc
    bolt-diamond, hybrid split diamond, and support ring. The largest vertex
    radius equals the simulation radius within `0.25 px`; no vertex exceeds it.
  - **Accept:** Affinities remain distinguishable in grayscale at light,
    standard, and heavy sizes, and player mustard-ring ownership remains unique.
  - **Guard:** Preserve affinity colors, trail families, damage, speed,
    collision, wall behavior, projectile pools, and batch count.
- [ ] **5.5** Validate maximum-pressure readability.
  - **As-is:** Repeated primitives merge under dense pressure.
  - **To-be:** Priority support, stationary threats, direct shooters, mines, and
    bosses remain separable while telegraphs retain top visual priority.
  - **Accept:** Rendered `03-maximum-pressure-xp`, boss startup, and projectile
    catalog captures pass human review at actual size.
  - **Guard:** HUD opaque-area ratio, warning geometry, and frame cost do not
    regress.

Batch acceptance:

- The combat reference image's hierarchy is reproduced using production meshes,
  not sprites or screenshot assets.

Batch guard:

- Collision truth, palette constants, mesh surfaces, draw batches, projectile
  capacities, and live update cadence are bit-for-bit or count-for-count stable
  where behavior is not intentionally visual.

### Phase 6: Localization, rendered QA, performance guard, and lifecycle close

Goal: Prove the complete UIUX pass in the real build and retire this plan safely.

Source owners touched: relevant validators, `docs/design/UI_VISUAL_SYSTEM.md`,
deterministic capture outputs under `build/`

- [ ] **6.1** Complete Korean/English copy and accessibility validation.
  - **As-is:** Current copy is complete, but new grouping labels and corrected
    footer copy are not yet defined.
  - **To-be:** Every added/revised key has natural Korean and English; focus,
    accessible names, state cues, and 44-pixel targets remain explicit.
  - **Accept:** No untranslated key appears in captures or validators.
  - **Guard:** Do not reduce body text below 15 pixels to solve overflow.
- [ ] **6.2** Run focused and full validators.
  - **As-is:** Existing suite passes the current implementation.
  - **To-be:** New state/shape/layout assertions join the focused suite, then all
    repository validators pass.
  - **Accept:** Every command in Validation Cadence exits zero.
  - **Guard:** Never weaken a threshold or delete a failing assertion to pass.
- [ ] **6.3** Regenerate the deterministic rendered matrix.
  - **As-is:** `build/audits/ui-visual-snapshot-2026-07-25/` is the baseline.
  - **To-be:** Fresh KO/EN captures cover all supported sizes, card states,
    active/empty build, guide categories, reports, garage states, live pressure,
    and boss startup.
  - **Accept:** No clipping, text collision, wrong state, blank frame, or
    generated-mockup raster appears in production.
  - **Guard:** Review screenshots at native size, not contact-sheet size alone.
- [ ] **6.4** Run the production Web path and combat performance guard.
  - **As-is:** A separate active performance plan owns release frame-tail
    thresholds.
  - **To-be:** Web export and built-app navigation pass. Visual changes preserve
    the existing `50` batch ceiling, current capacities, and do not add a
    task-owned draw-call regression.
  - **Accept:** Scenario validation is valid; batch/surface/instance counts do not
    rise; the latest frame metrics are recorded for the performance plan.
  - **Guard:** This plan neither weakens nor claims closure of the separate
    performance architecture gate.
- [ ] **6.5** Promote only implemented decisions to the visual spec.
  - **As-is:** This active plan owns pending work; generated images are evidence.
  - **To-be:** `UI_VISUAL_SYSTEM.md` records only the landed component,
    hierarchy, and silhouette contracts. Historical rationale remains in git.
  - **Accept:** No task list or generated-image text becomes canonical spec copy.
  - **Guard:** Product behavior stays in the product spec.
- [ ] **6.6** Close lifecycle.
  - **As-is:** This plan is active.
  - **To-be:** After every completion criterion passes and durable rules are in
    the spec, mark the plan done and delete it per `.agents/PLANS.md`.
  - **Accept:** No duplicate active UI plan claims the same scope.
  - **Guard:** Do not delete the plan while any task remains.

Batch acceptance:

- A human can follow Deployment → Gameplay → Upgrade → Pause/Settings/Guide →
  Report → Garage in the built Web export, in Korean by default, with the
  hierarchy shown by the six references and no gameplay regression.

Batch guard:

- The separate performance plan remains authoritative for final release frame
  pacing and is not silently superseded.

## Validation Cadence

Inner-loop commands:

```powershell
.\tools\godot.ps1 --path . --headless --import

$focused = @(
  "validate_vehicle_stage_ui_layout.gd",
  "validate_vehicle_rewards_ui_audio.gd",
  "validate_vehicle_pause.gd",
  "validate_vehicle_build_snapshot.gd",
  "validate_vehicle_guidebook.gd",
  "validate_vehicle_stage_report.gd",
  "validate_vehicle_combat_renderer.gd"
)
foreach ($validator in $focused) {
  .\tools\godot.ps1 --path . --headless --script ("res://tools/validation/" + $validator)
  if ($LASTEXITCODE -ne 0) { throw "Validation failed: $validator" }
}
```

Batch gates:

- After Phase 2: upgrade choice/reward validators plus KO/EN card captures.
- After Phase 3: stage UI/pause validators plus Deployment/Pause/Garage captures.
- After Phase 4: build/guide/report validators plus active/empty/locked/compact
  captures.
- After Phase 5: combat renderer validator, actor/projectile catalogs, maximum
  pressure, and boss-startup capture.

Final gates:

- **Full lint/type checks:** Godot import and all `.gd` focused validators.
- **Full tests:**

```powershell
Get-ChildItem tools/validation -Filter *.gd | Sort-Object Name | ForEach-Object {
  .\tools\godot.ps1 --path . --headless --script ("res://tools/validation/" + $_.Name)
  if ($LASTEXITCODE -ne 0) { throw "Validation failed: $($_.Name)" }
}
```

- **Production build and start:** `.\tools\export_web.ps1`, then load
  `$npjt-port-guard` and use the registered fastrun-manager `codex` lane for the
  built `build/web` artifact.
- **Manual UI routes and viewport sizes:** KO/EN at `960×540`, `1280×720`, and
  `1920×1080`; Deployment, gameplay pressure, upgrade default/focus/selected,
  Pause, Settings active/empty, Guide Ship/discovered/locked, Report
  wide/compact/failure, Result, and Garage empty/populated.
- **Accessibility checks:** keyboard-only primary flow, visible focus, initial
  focus, Escape behavior, accessible names for `?`, non-color state cues,
  reduced-motion preservation, 200% text-scale/reflow simulation, and no nested
  scroll trap.
- **Persistence/data validation:** locale, audio, reduced motion, keybindings,
  difficulty preference, guide discovery, and build snapshot remain unchanged.
- **Documentation and lifecycle validation:** plan frontmatter remains valid;
  implemented durable rules move to the visual spec; plan is retired only after
  completion.

Deterministic capture command:

```powershell
$captureRoot = Join-Path (Resolve-Path .).Path "build\captures\uiux-refinement"
$seed = 12886704
foreach ($locale in @("ko", "en")) {
  foreach ($size in @("960x540", "1280x720", "1920x1080")) {
    $dir = Join-Path $captureRoot "drowned_ruin_field-$locale-$size"
    $args = @(
      "--path", ".", "--rendering-method", "gl_compatibility", "--",
      "--capture-all=$dir", "--capture-locale=$locale",
      "--capture-size=$size", "--layout-seed=$seed",
      "--field-id=drowned_ruin_field"
    )
    .\tools\godot.ps1 @args
    if ($LASTEXITCODE -ne 0) { throw "Capture failed: $locale $size" }
  }
}
```

Rerun policy:

- Rerun a failed narrow check only after a concrete change or new hypothesis.
- Rerun full gates only after the suspected cause changed.
- Record known non-blocking warnings instead of rediscovering them.
- Do not repeatedly rerun the separate 60-second performance gate while tuning
  paused modal spacing; run it once after combat mesh work is stable.

## Predetermined Error Handling and Contingencies

| Trigger | Required response | Limit / escalation point |
| --- | --- | --- |
| Korean or English text clips at `960×540` | Shorten only newly added copy, rebalance spacing, or allow the existing page scroll. Keep body text `>=15 px` and commands `>=44 px`. | Escalate only if preserving required copy cannot fit without a new responsive mode. |
| Structured card height differs across offers | Use equal expanding cards and reserve fixed regions for description/value/pips; do not hide data. | Block Phase 2 if three cards cannot remain aligned in both locales. |
| Selection is ambiguous in grayscale | Keep frame plus diamond marker and visible focus; do not add glow or new color. | Block Phase 2 until non-color recognition passes. |
| Current Ship column fails to restore after category change | Centralize layout mode in `_select_category()` and assert repeated Ship → Boss → Ship transitions. | Block Phase 4; do not duplicate Guidebook screens. |
| Empty build shows stale data | Clear children before visibility changes and validate deployment/garage entry paths. | Block Phase 4; never mask stale values with opacity. |
| Actor mesh adds a surface/batch | Merge body/accent polygons into the same vertex-colored surface or simplify the accent. | Reject the redesign if the current batch contract cannot be kept. |
| Projectile shape exceeds collision radius | Normalize recipe vertices to the runtime radius and add exact extent assertions. | Block Phase 5; never enlarge physics for visual convenience. |
| Affinity or role needs a new color to read | Strengthen the one large shape/trail cue inside the existing palette. | Escalate to the user before any palette change. |
| Web export differs from native captures | Diagnose theme import, font, and viewport ownership in the built artifact. | Do not hand off on editor-only evidence. |
| Task-owned frame/draw regression appears | Remove extra live surfaces/nodes and preserve static mesh batching. | Hand performance root cause to the active performance plan only after isolating it. |

## Progress

- [x] Read root and `.agents` instructions plus the ExecPlan standard.
- [x] Read active product/visual specs and the relevant current UI/presentation
  owners.
- [x] Inspect the Korean `1280×720` runtime screens and production actor/
  projectile catalogs at native size.
- [x] Reconcile the external visual audit against current code and reject stale
  or spec-conflicting recommendations.
- [x] Lock scope, non-scope, exact component hierarchy, target surfaces,
  ownership, validation, and stop conditions.
- [x] Generate six explanatory target images and record their non-authoritative
  boundary in `docs/design/uiux-refinement-direction/README.md`.
- [ ] Phase 1: Shared component and state foundation.
- [ ] Phase 2: Upgrade-choice vertical slice.
- [ ] Phase 3: Deployment, Pause, and Garage hierarchy.
- [ ] Phase 4: Settings, Guidebook, and Report information architecture.
- [ ] Phase 5: Combat silhouette and projectile identity.
- [ ] Phase 6: Localization, rendered QA, performance guard, and lifecycle close.
- [ ] Final gates.

## Next Steps

1. Start with Phase 1 and commit the shared card/theme contract separately.
2. Complete and validate each user-testable phase before proceeding to the next.
3. Finish with the full capture matrix, built Web review, non-regression
   performance evidence, visual-spec update, and lifecycle close.

## Completion Criteria

- [ ] Every user-visible requirement passes its acceptance check.
- [ ] Every regression guard and final validation gate passes.
- [ ] No retired monolithic card formatter, dangling garage label, redundant Ship
  entry column, duplicated in-scope silhouette, placeholder, or unresolved
  material decision remains.
- [ ] KO/EN expose the same controls, content, focus order, and readable states.
- [ ] `960×540`, `1280×720`, and `1920×1080` captures show no clipping,
  overlap, undersized command, or obscured central combat rectangle.
- [ ] Actor/projectile visual changes preserve collision, palette, batch,
  capacity, and cadence contracts.
- [ ] The six generated PNGs remain evidence only and are not loaded by runtime.
- [ ] Durable implemented rules and run/verify commands are recorded in their
  canonical project documents.

## Stop Conditions

Complete when:

- All six phases, final gates, spec promotion, and task-scoped commits are
  complete; then retire and delete this plan according to `.agents/PLANS.md`.

Escalate only when:

- A requested result requires changing the semantic palette, product flow,
  control scheme, gameplay data, collision, save schema, production dependency,
  or performance threshold; or an exact required screen cannot fit at the
  supported minimum without removing required information.

Do not stop when:

- A layout wraps, a localized label needs adjustment, focus order fails, a mesh
  recipe triangulates incorrectly, a capture fixture drifts, or a validator
  reveals a task-owned regression. Those are implementation work.

## Rollback / Safety

- Commit each phase separately and never mix balance/content changes into this
  plan.
- Preserve stable screen, card, upgrade, guide, enemy, boss, projectile,
  localization, and save IDs.
- Keep the old monolithic card construction only until the structured component
  passes identical signal/input tests, then remove it in the same phase.
- Keep all generated references outside runtime import paths and never replace
  procedural production UI/meshes with screenshots.
- If a new actor shape fails gameplay-scale review, revert that one recipe while
  keeping the rest of the phase; do not recolor the whole family.
- If Web or performance evidence regresses, restore the last passing task-owned
  visual commit without resetting unrelated user work.

## Risks

- Dense English card and settings copy can overflow even when Korean fits;
  fixed content regions and minimum font sizes must be verified in both locales.
- A custom `Button` with child labels can accidentally consume mouse input;
  child controls must ignore mouse and the parent must own focus/press state.
- Reusing the build summary in two different scroll owners can create a nested
  scroll trap; the summary itself must remain scroll-free.
- Hiding the Guidebook entry column can break focus restoration or separator
  width; repeated category transition tests are required.
- Concave procedural silhouettes can fail triangulation; recipes must be simple,
  bounded, and validated before catalog capture.
- Extra mesh surfaces or live UI nodes could reintroduce draw-call/frame-tail
  pressure; static single-surface recipes and existing modal-only nodes are
  mandatory.
- Generated target images may contain imperfect text, soft shading, or gradients.
  Those are image-model artifacts and must not be copied. Exact runtime copy,
  flat-fill rules, and measurements in this plan/spec take precedence over
  pixels in those images.

## Open Questions

None. Every material product, visual, layout, ownership, data, validation, and
HOLD decision required for implementation is locked above.

## Decision Notes

- The external audit is retained as evidence, not authority. Its verified
  hierarchy/silhouette findings were accepted; new palette, fake baseline
  stats, radar rework, field-drop animation, unsupported hotkeys, vehicle-shade
  changes, and final-result redesign were rejected.
- The six explanatory images cover the minimum set needed to understand the
  result: live combat, upgrade choice, deployment, active ship settings,
  discovered Guidebook detail, and stage report. Pause and Garage use the same
  modal/action grammar and therefore do not need separate generated images.
- This plan deliberately keeps the already-correct HUD, report data model,
  reduced-motion feedback, player projectile ownership, and unique actor
  silhouettes instead of rewarding visible churn.

## Handoff

```text
Goal:
Implement the locked rendered UIUX readability and combat identity refinement
without changing gameplay, palette, collision, input, save data, or performance
budgets.

Read first:
AGENTS.md
.agents/AGENTS.md
.agents/PLANS.md
docs/product/vehicle_game_spec.md
docs/design/UI_VISUAL_SYSTEM.md
.agents/execplans/2026-07-25-rendered-uiux-refinement.md
docs/design/uiux-refinement-direction/README.md

Execute exactly:
Phases 1 through 6 in order, one coherent task-scoped commit per phase.

Validate with:
The focused validator list, complete validator suite, deterministic KO/EN
capture matrix, production Web export, built-app keyboard/visual review, and the
non-regression combat performance guard in this plan.

Stop when:
Every completion criterion passes and durable implemented rules have moved to
the active visual specification; then retire and delete this plan.
```
