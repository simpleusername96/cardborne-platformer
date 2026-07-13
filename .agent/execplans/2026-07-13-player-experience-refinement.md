---
type: plan
status: active
owner: BK
created: 2026-07-13
last_reviewed: 2026-07-13
topic: Fixed-stage player experience refinement after the first complete run
scope: Fixed stage plans, traversal safety, field items, combat spacing, gameplay HUD, and production UI replacement
source: Owner playtest feedback through 2026-07-13 and current production runtime evidence
related:
  - ../../docs/product/2d_platform_action_card_game_prd.md
  - ../../docs/design/PLAYER_CHARACTER_SYSTEMS.md
  - ../../docs/design/PROCEDURAL_REGION_GENERATION.md
  - ../../docs/design/MAP_AUTHORING_PIPELINE_CONTRACT.md
  - ../../docs/design/PROGRESSION_EQUIPMENT_ECONOMY.md
  - ../../docs/design/PLAYER_FACING_FLOW.md
  - ../../docs/architecture/FIRST_SLICE_ARCHITECTURE.md
  - 2026-07-12-actual-game-production-roadmap.md
  - 2026-07-13-combat-feedback-reward-clarity.md
---

# Cardborne Player Experience Refinement Plan

## Purpose

Refine the first complete run into a game that is reliably traversable, comfortable
to fight in, rewarding to explore, and presented through a coherent game UI rather
than testbed-style text panels. The work is organized into seven executable batches.
Every implementation item states the current behavior, target behavior, acceptance
evidence, and the regression it must avoid.

The final player-facing result must provide:

- three approved fixed stages that cannot strand any playable character after a
  committed drop;
- visible field items that create recovery, route-choice, and reward moments;
- class-specific attacks that can engage normal enemies without forced contact damage;
- a compact bottom action bar with skills, cooldowns, class state, and consumables;
- game-like menus, choices, forge, and result screens built from reusable visual
  components instead of large text-heavy debug panels;
- exact equipment and forge comparisons before the player commits a choice.

## Why / Context

The integrated testbed is retired and the production run is structurally complete,
but owner playtests exposed a gap between system completeness and player experience.
Owner playtests exposed optional-room returns whose practical route did not match the
declared socket contract. The fixed-layout V3 repair now connects every approved basin,
cross-room rope, and upper-cache drop to a usable landing, with all-character input
replay covering the six committed-return fixtures. Broader clearance categories and
human full-run evidence remain open.

Combat definitions and visible attack footprints now agree, and direct chest/material
claims now publish exact receipts. Those fixes exposed a separate balance problem:
the Assassin basic attack is especially short, normal enemy contact damage is always
active, and close-range engagement can feel like mandatory damage trading. The map
also has large stretches with enemies, hazards, chests, and material nodes but few
small visible pickups that reward movement or soften attrition.

The UI is connected to the production flow, but most surfaces are still assembled as
large labels and generic panels. `ProductionHUD` renders attacks and skills as a text
list with `READY` strings, while consumable charges are absent from the live HUD.
The documented gameplay HUD contract already requires skill identity, cooldowns,
charges, and disabled states. This plan treats the current UI as a functional shell,
not as an acceptable final presentation baseline.

## Decisions Locked With The Owner (2026-07-13)

| Topic | Decision | Source / note |
| --- | --- | --- |
| Product state | The integrated testbed remains retired; improvements land in the actual run. | Owner explicitly questioned testbed-like output and requested natural game UI/UX. |
| Terrain form | Terrain uses filled rock masses at varied heights, not isolated thin debug platforms. | Owner visual reference and repeated map feedback. |
| Production map mode | Use one approved curated Stage Plan per normal region while gameplay is refined. Keep the random planner dormant for later re-entry; do not delete it. | Owner explicitly deferred random generation until the overall game loop is settled. |
| Traversal | Every approved fixed stage must preserve usable character space and be traversable with the supported base movement kit. | Owner feedback on jump, dash, crouch, rope, and unreachable terrain. |
| Baseline movement | All characters retain double jump, dash, crouch/drop, and climb; character identity must not gate required routes. | Existing product contract plus owner correction. |
| Drop recovery | A player who commits to an optional lower route must still have a guaranteed practical return or forward exit. | Owner screenshot and explicit soft-lock concern. |
| Field items | Items should be visibly placed in the map to improve convenience, exploration, and fun, not only to repair healing scarcity. | Owner clarification. |
| Combat scale | Prefer increasing and reshaping effective attack reach over enlarging the character body. | Owner preference; body scaling would invalidate map clearances. |
| Class identity | Warrior, Assassin, and Archer attacks remain behaviorally distinct. | Existing character-system contract and owner feedback. |
| HUD placement | Add a lower-screen inventory/skill-oriented game HUD. | Owner feedback. |
| Presentation | Replace testbed-style text UI with natural game-like visual hierarchy, icons, meters, and feedback. | Owner feedback. |
| Existing fixes | Preserve exact attack-footprint presentation and exact interactive reward receipts. | Landed in `a1515d2`; do not reopen as unresolved work. |

## Assumptions And Open Decisions

| Topic | Current assumption | Why it matters | Default handling |
| --- | --- | --- | --- |
| In-run inventory | Use one quick-consumable slot plus automatic/immediate field pickups, not a grid inventory. | The active PRD excludes grid inventory and equipment is not freely swapped during combat. | Build the action bar first; add a separate inventory screen only if later gameplay creates meaningful mid-run item management. |
| Initial field items | Start with a healing pickup, consumable-charge refill, cooldown-recovery pickup, and small currency/material pickups. | Covers sustain, combat tempo, and exploration without adding a second item economy. | Names and exact values remain tuning data, not locked product terminology. |
| UI language | Preserve the current English game copy during this pass. | Localization is not yet an active product scope. | Keep strings short and structure layouts so Korean can fit later. |
| Visual assets | Use project-original icons, frames, and procedural/bitmap assets with no new external runtime dependency. | The owner requested polished presentation, while adoption rules still apply. | External packs require a separate license/adoption decision. |
| Attack tuning | Increase practical melee reach per class rather than applying one global percentage. | Uniform scaling would erase class identity and unnecessarily extend Archer range. | Use measured contact-safety envelopes and tune through fixtures plus playtests. |
| Dynamic assistance | Field items are authored at fixed reviewed positions and are not secretly added from current health. | The fixed-stage phase should be easy to inspect and balance. | Use typed pickup actors in approved rooms; do not inspect current HP when composing a stage. |

## Scope / Non-Scope

In scope:

- Conservative traversal and guaranteed return for every approved production
  room/plan/profile.
- Authored field pickups, class-specific combat reach, live HUD replacement, shared UI
  components, full production-screen parity, and exact equipment/forge comparison.
- Focused automated validation, rendered evidence, and complete human run checks.

Non-scope:

- New characters, regions, boss roster, grid inventory, final cinematics, or a renewed
  integrated testbed.
- Unapproved external packages/assets or unrelated progression/economy replacement.

Destructive actions require owner approval. Normal implementation must preserve save,
catalog, transaction, and stage IDs unless a separately reviewed migration is necessary.

## Domain Alignment

Use these terms consistently during implementation:

| Term | Meaning | Owner |
| --- | --- | --- |
| **Committed drop** | A traversal transition after which the entry support cannot be recovered without another authored route. | Room metadata and geometry validation. |
| **Guaranteed return** | A conservative traversable path from every stable post-drop landing/recovery position to the branch return or forward required route. | `StageGeometryValidator` and runtime traversal fixtures. |
| **Recovery anchor** | A safe standing/reset point. It does not by itself prove escape or route connectivity. | Room authoring data. |
| **Attack footprint** | Collision region that can confirm a hit at one instant. | `AttackDefinition` and combat controller. |
| **Effective reach** | Furthest practical enemy overlap reachable from neutral spacing, including footprint, offset, bounded movement, and projectile spawn. | Combat tuning and fixtures. |
| **Contact-safety margin** | Distance/time buffer between the earliest player hit and the enemy's contact-damage envelope. | Combat balance validation. |
| **Field pickup** | Visible world item collected immediately or automatically; it does not occupy a general inventory grid. | Field-item catalog, authored placement manifest, and pickup actor. |
| **Interactive reward** | Chest, material node, or other deliberate interaction that settles a transaction and publishes a receipt. | Existing reward services and interactables. |
| **Consumable** | One equipped run-local item with explicit charges and manual activation. | `RunState` and the action bar. |
| **Action bar** | Persistent bottom HUD showing basic, heavy, three skills, and equipped consumable. | Production HUD components. |
| **Context lane** | One temporary region above the action bar used for interaction prompts and reward/pickup receipts without overlap. | Production HUD layout. |
| **Approved Stage Plan** | The reviewed fixed room order, connections, encounters, hazards, rewards, and pickup positions used by production for one region. | `CuratedStagePlanBuilder`, fixed room scenes, and production-stage validation. |

## Progress

### Landed / already true

- [x] The old integrated motion testbed and debug HUD are retired.
- [x] Production flow includes menu, character/loadout, three assembled stages,
  rewards, rest/forge, boss, settlement, and result.
- [x] All three characters share the required baseline movement kit.
- [x] Required room seams and stage entries have focused generation validation.
- [x] Attack visuals are bounded by the same footprint used for hit confirmation.
- [x] Assassin swept attacks use Hurtbox bounds rather than hidden point padding.
- [x] Chests/material nodes publish exact, non-modal reward receipts exactly once.
- [x] Run state already owns one selected consumable and its charge count.
- [x] Equipment data already contains base mechanical descriptions, tradeoffs, and
  build/behavior effects.

### Completed in the current implementation

- [x] Production requests one versioned approved Stage Plan per normal region; random
  planning remains dormant and is excluded from the default release gate.
- [x] Fixed-layout V3 guarantees the six approved committed-return scenarios through
  authored ropes, one-way hatches, recovery support, static contracts, and runtime
  input replay for Warrior, Archer, and Assassin.
- [x] Visible typed field pickups occupy fixed reviewed room positions and settle once
  through authoritative run state with a concise HUD receipt.
- [x] Warrior, Assassin, and Archer use class-specific practical reach with collision-
  truthful attack presentation and hit-before-contact fixtures.
- [x] The live HUD uses compact health/resource regions, a six-slot bottom action bar,
  class state, consumable charges, objective/boss state, and one context lane.
- [x] Loadout, reward, Treasure, Rest & Forge, pause/settings, and result decisions show
  authoritative availability and current-versus-result information.

### Still open

- [ ] Add invalid fixtures for every remaining clearance category, not only support,
  rope, one-way hatch, recovery, and fixed pickup contracts.
- [ ] Finish the authored-scene/component migration where large screen scripts still
  own procedural composition, and decide whether a single icon manifest adds value.
- [ ] Complete pickup audio and reduced-motion/transition polish without adding an
  external runtime dependency.
- [ ] Complete three full production runs, combat attrition sessions, fresh-player UI
  recognition, and final fun/balance acceptance.

### Implementation evidence (2026-07-13)

- Fixed layout V3 is locked by complete plan signatures for Ruin Approach, Flooded
  Works, and Broken Sanctum across multiple run seeds.
- `validate_fixed_drop_runtime.gd` passes three character profiles against six committed
  return fixtures: two local basin ropes, three cross-room ropes, and one upper drop.
- `validate_fixed_field_pickup_manifest.gd` and `validate_field_pickups.gd` cover fixed
  placement, supported landing, authoritative effects, duplicate callbacks, receipts,
  and actor removal.
- Combat spacing, gameplay HUD, reward choice, equipment decision, shell UI, gamepad,
  and settings validators are part of the default release matrix.
- Layout, combat, field-item, HUD, equipment/reward, and shell changes are split into
  scoped commits so remaining polish can be reviewed or reverted independently.

### Out of scope for this plan

- Final commercial character animation, narrative cinematics, or recorded voice.
- New playable characters, stages, boss roster, or a second full run.
- Grid inventory, durability, item destruction, random forge failure, or loot rarity
  inflation.
- Character body scaling as the primary combat-range solution.
- Reintroducing debug route annotations or a parallel testbed into production flow.
- External UI frameworks or asset packages without explicit approval and adoption
  evidence.
- Random room topology/content selection, broad seed matrices, or procedural map
  balancing. These return only after fixed-stage gameplay and UI are accepted.

## Proposed Design / Guiding Implementation Principles

1. **Playable safety precedes reward and polish.** An approved room that can strand a
   player is invalid even if it is visually attractive or technically escapable at a
   theoretical movement limit.
2. **The least-mobile profile owns required traversal.** Optional entry may be harder,
   but escape after commitment is treated as required traversal.
3. **Fixed composition precedes procedural variety.** Production uses reviewed curated
   plans and authored content positions. The dormant planner remains isolated until a
   later plan defines its re-entry criteria.
4. **Combat comfort is measured against enemy threat, not sprite width alone.** Reach,
   startup, movement, target Hurtbox, and contact damage form one practical envelope.
5. **UI scenes own composition; scripts own state and intent.** Replace large procedural
   `_build_ui()` methods with authored `.tscn` layouts and responsibility-shaped
   presenters/components.
6. **Icons and meters carry repeated combat state.** Text remains for exact descriptions,
   choices, and exceptional status, not for continuously repeated `READY` lists.
7. **No duplicate state owner.** UI consumes snapshots and emits intents; generation,
   combat, rewards, profile, and run services retain authority.

## Shared Owners To Create, Reuse, Or Retire

| Concern | Desired owner | Reuse / retire |
| --- | --- | --- |
| Guaranteed-return graph | `StageGeometryValidator` over authored support/climb/drop metadata | Reuse `MovementMetrics`; retire the assumption that a recovery anchor proves escape. |
| Field-pickup policy | One typed field-item catalog plus authored pickup actors in approved rooms | Keep effect rules in catalog/runtime; room scenes own reviewed positions, never effect semantics. |
| Field-pickup settlement | Run/reward service transaction with one pickup actor | Reuse exactly-once reward semantics; do not create a second wallet owner. |
| Attack contact safety | Character attack resources plus shared combat fixtures | Reuse `AttackDefinition`; do not scale player collision bodies. |
| UI visual language | `ProductionUIStyles`, authored UI scenes, shared component scenes | Retire repeated raw `PanelContainer`/`Label` construction where a shared component exists. |
| Gameplay action display | One action-bar presenter consuming combat/run snapshots | Retire the left-side multiline `CombatState` label. |
| Temporary messages | One context lane coordinating prompt and receipt priority | Reuse reward receipts; retire overlapping independent bottom anchors. |
| Stat comparison | One reusable stat-delta view model/component | Reuse equipment/build snapshots; do not calculate stats inside UI scripts. |

## Baseline Evidence Map (Pre-Implementation)

The observations in this table preserve the starting point. The Progress section and
checked task evidence are authoritative for the current implementation state.

| Concern | Owner(s) today | Observed behavior / problem | Plan handling |
| --- | --- | --- | --- |
| Optional drop return | `scripts/generation/StageGeometryValidator.gd`, `scripts/stages/RoomTemplateHost.gd`, `scenes/rooms/broken_sanctum/BsMaterialCrypt.tscn` | The crypt basin is 120 px below its shelves. The rope reaches the shelf level, not the basin. Validation checks the declared return socket/rope but not every basin landing. | Extend geometry graph and repair/audit authored rooms. |
| Optional movement margin | `tools/validate_broken_sanctum_rooms.gd`, `scripts/player/MovementMetrics.gd` | Optional rises may use full theoretical double-jump height instead of the conservative required-route envelope. | Treat committed return segments as required traversal. |
| Production stage topology | `CuratedStagePlanBuilder`, `StageGenerationService`, `ProductionStageHost` | Curated plans already exist only as random-generation fallback; production currently tries random plans first. | Make curated plans the explicit production path and validate only the approved composition during this plan. |
| Terrain readability | Room scenes and procedural terrain visuals | Some background decoration reads like collision, and route affordances such as ropes do not visually connect to the reachable floor. | Separate collision silhouette, backdrop, climbable, and hazard treatment. |
| Field items | Existing reward tables, chests, material nodes, enemy rewards | No small visible map-pickup loop; traversal space can feel empty between large interactions. | Add typed field pickups and reviewed fixed placement manifests without replacing major rewards. |
| Consumable visibility | `RunState`, `PlayerController`, `InputBindings` | Consumable and charges exist and `H` uses them, but the live HUD does not expose the slot or count. | Add action-bar consumable slot and failure states. |
| Melee spacing | `AttackDefinition` resources, `PlayerCombatController`, `EnemyBase` | Warrior basic forward footprint reaches farther than Assassin; enemy contact hitboxes are continuously active. Closing distance can feel like forced damage trading. | Measure and tune class-specific contact-safety margins. |
| Attack truthfulness | `PlayerAttackPresenter`, Assassin runtime | Visuals now stay inside actual footprints and swept checks use Hurtboxes. | Preserve with regression tests while tuning reach. |
| Gameplay HUD | `scripts/ui/production/ProductionHUD.gd` | Health/build are text blocks; all five attacks are a multiline list with `READY`; class state is appended as text; no action icons or consumable. | Replace with authored HUD scene and shared components. |
| Reward feedback | `RewardReceiptPresenter`, `StageRewardInteractable` | Exact receipts work but occupy a bottom-center lane that future action UI also needs. | Preserve content; coordinate it through one context lane. |
| Equipment/loadout | `CharacterSelect.gd`, `ProfileState` snapshots | Effective stats exist, but item descriptions are weakly surfaced and candidate deltas are not clearly visible. | Add item detail and current-versus-selected delta view. |
| Forge | `RestForge.gd`, `RunState.get_rest_forge_snapshot()` | Item rows and offers omit complete base effects, current affix detail, projected deltas, and clear run-only labeling. | Expand snapshots and reuse stat-delta component. |
| Other production screens | `MainMenu`, `LevelReward`, `CardReward`, `TreasureChoice`, `RunResult`, pause/settings | Large generic panels and labels provide function but little game identity or visual hierarchy. | Broad parity replacement after shared primitives exist. |

## As-Is / To-Be Delta Map

| Concern | As-is | To-be | Acceptance check | Guard / leftover check |
| --- | --- | --- | --- | --- |
| Drop recovery | Declared anchors and rope/socket endpoints can pass while a basin remains practically inescapable. | Every committed drop included in an approved plan has a conservative authored return or forward exit. | Runtime fixtures escape every fixed-plan drop with every character. | No room is accepted solely because a recovery anchor exists. |
| Production map selection | Production currently attempts random topology before curated fallback. | Production calls an explicit curated-plan path with one fixed layout seed; the random planner remains dormant and separately testable. | Different run seeds assemble the same room/content signature for each stage. | Do not delete planner/catalog code or silently fall back to random topology. |
| Terrain visuals | Backdrop, solid terrain, climbables, and hazards can share similar block-like treatment. | Filled rock masses remain dominant while collision tops, pass-through decoration, ropes, and hazards are visually distinct. | Screenshot review identifies valid route and collision at a glance without debug text. | Visuals never imply walkable support outside collision bounds. |
| Field items | Only large rewards/interactions meaningfully punctuate the map. | Fixed pickups create sustain, tempo, economy, and optional-risk lures at reviewed room positions. | Every approved stage has the documented pickup set and every pickup is reachable. | Stage clear never depends on loose pickup collection. |
| Melee reach | Especially short Assassin engagement can enter continuous contact-damage range. | Every basic attack has a documented class-specific contact-safety margin; Warrior controls space, Assassin steps/sweeps safely, Archer handles near-release overlap without extra max range. | Neutral-spacing fixtures prove hit-before-contact for normal melee targets; class timing and identity remain distinct. | No hidden hit padding or visual reach beyond collision. |
| Gameplay HUD | Top/left text panels dominate and require reading repeated labels. | Health/XP/resources use compact meters; bottom action bar shows six actions, cooldowns, inputs, charges, disabled state, and class state. | A first-time player identifies health, usable skills, consumable count, objective, and resources within one glance. | No required HUD covers player, landing edge, enemy, or telegraph at supported viewports. |
| Context messages | Prompt and reward receipt own separate bottom anchors. | One priority/queue lane above the action bar switches cleanly between prompt, pickup, and reward receipt. | Rapid pickup + chest + prompt scenarios remain readable and non-blocking. | No duplicate receipt, overlapping panels, or stale prompt. |
| Loadout/forge | Item IDs/names and affix text are shown without a complete before/after decision. | Base effect, tradeoff, current affix, proposed affix, affected stats, final currency, and run-only status are visible before confirmation. | Applied build equals preview; cancel leaves all state unchanged. | UI never recomputes authoritative stats or implies a permanent forge upgrade. |
| Production UI | Screens are procedural collections of generic panels, labels, and buttons. | Authored scenes share frames, iconography, focus treatment, typography, spacing, transitions, and responsive rules while preserving each screen's task. | Complete keyboard/gamepad flow works at 960x540, 1280x720, and 1920x1080 with no clipping. | No debug labels, fake actions, or orphaned old layout builders remain. |

## Visual Direction

Companion reference: [production gameplay HUD concept](../../docs/design/visuals/player_experience_ui_concept.png)
with [editable SVG source](../../docs/design/visuals/player_experience_ui_concept.svg).
The image communicates hierarchy and visual character; the layout and state contracts
below remain authoritative during implementation.

### Design read

- **Surface:** controller/keyboard-first 2D platform action game, not a dashboard.
- **Player task:** read threats and landing space first, then health/actions/resources.
- **Composition:** unobtrusive live HUD; focused choice screens; no floating wall of cards.
- **Density:** compact combat cockpit, moderate choice-screen detail.
- **Mood:** weathered expedition gear and card-game craft, grounded in moss, iron,
  parchment, mineral cyan, hazard crimson, and reward amber.
- **Motion:** short state transitions, radial cooldowns, pickup arcs, damage/ready pulses;
  no ornamental continuous motion.

### Gameplay HUD composition contract

```text
+--------------------------------------------------------------------------+
| [portrait] HP bar / guard          objective              Lv / XP / coin |
|                                                                          |
|                         unobstructed game world                          |
|                                                                          |
|                 [context prompt OR reward/pickup receipt]                |
|            [F Basic][G Heavy][Q S1][R S2][V S3][H Consumable xN]        |
|                        [class state / short status]                       |
+--------------------------------------------------------------------------+
```

- Health remains top-left but becomes a meter with exact value as secondary text.
- Objective remains top-center and fades to a compact label after transitions.
- Level/XP/coin/material summary remains top-right as icons plus concise values.
- The action bar uses stable slot dimensions and cannot shift when labels/cooldowns
  change.
- Basic/heavy slots show identity and temporary lock/charge state; skill slots show
  cooldown masks and numeric seconds; consumable shows icon, input, and count.
- Interaction prompts and receipts share the context lane because interacting with a
  source normally replaces its prompt with its receipt.
- Boss UI occupies a restrained top-center band and does not displace the action bar.

### Screen-specific hierarchy

| Screen | Primary visual | Secondary information | Actions |
| --- | --- | --- | --- |
| Main menu | Character/world key art and game title | Selected profile / persistent progress summary | Start Run, Settings, Quit |
| Character/loadout | Selected character silhouette and combat promise | Equipment slots, effective stats, candidate delta | Equip/select, mastery, start |
| Level reward | Three compact upgrade choices | Current -> resulting value | Choose one |
| Card reward / Treasure | Three physical card/reward objects | Exact behavior, tags, ownership/replacement | Choose, reroll where legal |
| Rest & Forge | Camp/forge focal scene | Health, coins, consumable, item comparison | Heal, buy, forge, leave |
| Pause/settings | Dimmed live game with compact command column | Controls/audio/display | Resume, settings, abandon |
| Result | Run outcome and character/build summary | Rewards kept, notable cards/equipment | Continue |

## Tasks

The seven milestones are executed in order. An unchecked phase can contain completed
items; its remaining item or human gate is stated inside the phase.

- [ ] **Phase A:** Baseline, safety contract, and visual foundation.
- [ ] **Phase B:** Approved fixed Stage Plans and guaranteed traversal.
- [ ] **Phase C:** Combat spacing and class-specific reach.
- [ ] **Phase D:** Field items and map reward rhythm.
- [x] **Phase E:** Gameplay HUD and context feedback.
- [ ] **Phase F:** Production screen replacement and decision clarity.
- [ ] **Phase G:** Integrated fun, balance, accessibility, and release gate.

---

# Phase A - Baseline, Safety Contract, And Visual Foundation

**Goal:** Freeze current evidence, define conservative traversal/combat/UI metrics,
and establish reusable presentation primitives before broad replacement.

**Source owners:** `MovementMetrics.gd`, `StageGeometryValidator.gd`,
`ProductionUIStyles.gd`, production UI scenes/scripts, focused validators.

- [ ] **A1 Capture reproducible playtest baselines.**
  - **As-is:** Owner screenshots identify failures, but room/plan/profile and HUD state
    are not always captured together.
  - **To-be:** Add development-only evidence capture that records stage ID, approved-plan
    version, room ID, character, position, health, and current build beside a
    screenshot/runtime log.
  - **Accept:** The crypt failure and one representative combat/HUD scene can be
    reproduced from recorded facts without reintroducing a player-facing debug HUD.
  - **Guard:** Evidence tooling is absent from release presentation and never mutates
    the run.

- [x] **A2 Lock conservative traversal margins.**
  - **As-is:** Required routes use conservative factors, but optional committed returns
    can use full theoretical movement height.
  - **To-be:** Document and expose one least-mobile envelope for required paths and
    committed returns, including landing width, body/ceiling clearance, jump rise,
    horizontal reach, dash chain, rope entry, and crouch clearance.
  - **Accept:** Movement validators report the same envelope for every approved stage.
  - **Guard:** Optional pre-commit challenges may exceed the required envelope only when
    a safe refusal/return remains available.

- [ ] **A3 Establish UI tokens and authored component scenes.**
  - **As-is:** `ProductionUIStyles` provides colors and panel helpers, while screens
    repeatedly construct controls in code.
  - **To-be:** Define typography tiers, spacing, slot sizes, focus/disabled states,
    semantic colors, and authored `.tscn` primitives for icon label, meter, action slot,
    choice card, context toast, and stat delta.
  - **Accept:** A component gallery fixture renders all states at three supported sizes.
  - **Guard:** No new runtime package; Korean-length stress strings do not clip;
    compact/standard/HD token buckets increase readable scale instead of leaving tiny
    fixed text inside large empty layouts.

- [ ] **A4 Create an icon/content manifest.**
  - **As-is:** Actions, currencies, items, classes, and states are mostly text-only.
  - **To-be:** Map every visible gameplay noun to a project-original icon or explicit
    temporary fallback with consistent silhouette, stroke, and color rules.
  - **Accept:** Every action-bar slot, currency, field pickup, equipment slot, and class
    state resolves an icon without file-path logic in UI scripts.
  - **Guard:** Color is never the only state signal and icons never imply unavailable
    actions.

*Phase A gate:* focused component render, movement-metric validator, and baseline
evidence exist before shared runtime rules change.

---

# Phase B - Approved Fixed Stage Plans And Guaranteed Traversal

**Goal:** Assemble one reviewed Stage Plan per normal region and make every included room
and branch practically traversable for every base character, including recovery after a
committed drop.

**Source owners:** `CuratedStagePlanBuilder.gd`, `StageGenerationService.gd`,
`ProductionStageHost.gd`, `StageGeometryValidator.gd`, `StagePlanValidator.gd`,
`RoomTemplateHost.gd`, `RoomTemplateData.gd`, approved room scenes/data, validators.

- [x] **B1 Make curated Stage Plans the explicit production path.**
  - **As-is:** `StageGenerationService` tries random plans first and reaches the existing
    curated builder only after retries are exhausted.
  - **To-be:** Add an explicit curated-plan service entry, use one versioned fixed layout
    seed, and have `ProductionStageHost` request it directly for all three normal stages.
  - **Accept:** Different run seeds produce the same room, encounter, hazard, reward, and
    pickup signature for a given stage profile.
  - **Guard:** Keep the random planner and its focused tests intact but dormant; production
    never silently falls back to random topology.

- [x] **B2 Validate the approved composition as a product contract.**
  - **As-is:** A curated fallback can be valid without a durable identity proving which
    exact composition shipped.
  - **To-be:** Record a stable plan mode/layout version in the generation report and add
    deterministic signatures for each approved stage.
  - **Accept:** Runtime and headless fixtures identify the curated mode and expected room
    sequence for Ruin Approach, Flooded Works, and Broken Sanctum.
  - **Guard:** Run seed may still drive cards and rewards outside map assembly; it cannot
    alter stage geometry or authored pickup placement.

- [x] **B3 Promote committed-drop returns to required traversal.**
  - **As-is:** Entering an optional branch is optional, so its internal return can be
    validated too leniently.
  - **To-be:** Once a drop removes access to the entry support, every stable landing must
    reach the declared branch return or a forward required route at required-route
    margins.
  - **Accept:** A fixture matching the current crypt basin fails before room repair and
    passes only after a real route reaches the basin.
  - **Guard:** A checkpoint/recovery anchor alone cannot satisfy the rule.

- [x] **B4 Repair and audit approved drop rooms.**
  - **As-is:** `BsMaterialCrypt` has a near-limit 120 px shelf rise and a rope terminating
    at shelf height; other lower-route rooms may share the same metadata pattern.
  - **To-be:** Extend ropes to the basin or add comfortable rock steps/one-way ledges;
    audit all rooms with drops, lower routes, fall resets, recovery anchors, and ropes.
  - **Accept:** All three characters can return from every audited landing without
    items, upgrades, enemy boosts, or damage tricks.
  - **Guard:** Filled rock-mass composition and varied terrain heights remain; fixes do
    not collapse rooms into flat corridors.

- [ ] **B5 Enforce movement-space clearances in approved rooms.**
  - **As-is:** Local supports may be individually reachable while ceilings, walls,
    hazards, or narrow gaps make the movement unusable.
  - **To-be:** Validate standing width, jump arc clearance, dash corridor, crouch tunnel,
    rope mount/dismount volume, landing recovery space, and hazard-free reset position.
  - **Accept:** Purpose-built invalid fixtures fail for each clearance category with a
    specific message.
  - **Guard:** Character body dimensions remain unchanged during this batch.
  - **Progress:** Fixed support widths, rope endpoints, local recovery graphs, drop
    hatches, collision layers, and target recovery landings are enforced. Dedicated
    invalid ceiling, dash-corridor, crouch-tunnel, and moving-sweep fixtures remain.

- [x] **B6 Add all-character runtime traversal fixtures.**
  - **As-is:** Geometry math and boot checks can pass without exercising representative
    movement from the exact recovery positions.
  - **To-be:** Spawn every character at each committed-drop recovery anchor and execute
    bounded authored traversal inputs toward return/exit.
  - **Accept:** Every approved room sequence completes without timeout, respawn loop, or
    manual intervention for Warrior, Assassin, and Archer.
  - **Guard:** Runtime fixtures supplement rather than replace deterministic geometry
    validation.

- [ ] **B7 Clarify collision visually.**
  - **As-is:** Decorative pillars/mineral forms can read as solid, and a rope may look
    useful while failing to meet the floor.
  - **To-be:** Solid top edges, pass-through backdrop, climbables, one-way platforms,
    hazards, and exits receive distinct silhouettes/contrast without debug labels.
  - **Accept:** Screenshot review can trace the intended return route at normal zoom.
  - **Guard:** No invisible collision wall or visible unsupported floor remains.
  - **Progress:** Fixed rooms use filled masses, visible one-way hatch caps, shaft
    recesses, and ropes that extend above their landing. Final full-stage screenshot
    review remains part of the Phase G gate.

*Phase B gate:* fixed-plan identity tests, focused room validators, all three curated
region validators, roster-stage matrix, and rendered route screenshots pass before field
items are added. The dormant random planner's existing property tests remain useful, but
the broad seed matrix is not a completion blocker for this plan.

---

# Phase C - Combat Spacing And Class-Specific Reach

**Goal:** Let every character initiate normal combat from readable spacing without
making all attacks feel identical or expanding the player body.

**Source owners:** character kit/attack resources, `PlayerCombatController.gd`,
character runtimes, `EnemyBase.gd`, attack presentation and combat validators.

- [x] **C1 Measure contact-safety envelopes.**
  - **As-is:** Attack data is validated in isolation; no matrix compares earliest player
    hit to enemy body/contact overlap after startup and relative motion.
  - **To-be:** Record effective reach, startup travel, enemy approach travel, Hurtbox
    overlap, contact envelope, and resulting safety margin for each basic/heavy attack
    against representative melee enemies.
  - **Accept:** A validator reports margins and fails unsafe neutral engagements.
  - **Guard:** It uses actual shapes/offsets and runtime movement, not guessed sprite size.

- [x] **C2 Tune Warrior space control.**
  - **As-is:** Cleave is broader than Assassin attacks but can still feel visually small
    against the game scale.
  - **To-be:** Widen/extend the frontal arc modestly and preserve slower commitment,
    stagger, and knockback identity; consider a bounded step only if static reach harms
    animation readability.
  - **Accept:** Cleave hits a normal melee target before contact at neutral spacing and
    remains clearly shorter than Archer projectile play.
  - **Guard:** Breaker and skills do not inherit unintended global range inflation.

- [x] **C3 Tune Assassin entry and sweep.**
  - **As-is:** Twin Cut's forward edge is the shortest melee basic and may require unsafe
    proximity despite fast timing.
  - **To-be:** Add a small committed step-in and/or wider swept footprint so both pulses
    can engage without body contact; retain lower static control than Warrior and high
    mobility identity.
  - **Accept:** Twin Cut passes hit-before-contact fixtures in both directions and its two
    pulses remain visually and mechanically distinct.
  - **Guard:** No invulnerability, hidden vertical padding, or off-footprint hit is added
    merely to hide spacing problems.

- [x] **C4 Improve Archer near-release reliability.**
  - **As-is:** Long projectile range is already ample, but close targets can expose spawn
    or collision-size edge cases.
  - **To-be:** Validate projectile spawn overlap, collision width, and immediate near
    target acquisition while keeping authored max ranges unchanged.
  - **Accept:** Close, mid, and maximum-range fixtures hit exactly within the declared
    projectile contract.
  - **Guard:** No full-screen aim line or universal range increase.

- [ ] **C5 Review continuous enemy contact damage.**
  - **As-is:** Normal enemy contact hitboxes are always active and repeat hits.
  - **To-be:** Keep contact as a readable threat, but ensure hit cooldown, knockback,
    enemy reactions, and player recovery do not create unavoidable repeated trades.
  - **Accept:** Controlled fixtures prove one spacing mistake does not become an
    uninterruptible multi-hit loss; deliberate enemy attacks retain telegraphs.
  - **Guard:** Do not solve all melee difficulty by disabling contact damage.
  - **Progress:** Hit-before-contact and knockback fixtures pass. Repeated-engagement
    attrition judgment remains a human Phase G session.

- [x] **C6 Preserve truthful attack presentation.**
  - **As-is:** The landed presenter now derives visuals from the exact footprint.
  - **To-be:** Update motion silhouettes after tuning while preserving footprint bounds,
    facing symmetry, startup/active/recovery timing, and distinct class signatures.
  - **Accept:** Existing attack-motion tests plus new tuned-resource snapshots pass.
  - **Guard:** No visual arc implies reach beyond collision.

*Phase C gate:* Warrior, Assassin, Archer, enemy contact, and roster combat matrices
pass; human playtest confirms normal basic attacks no longer require routine damage
trading.

---

# Phase D - Field Items And Map Reward Rhythm

**Goal:** Add visible, constrained pickups that reward movement and route choice while
preserving authoritative reward/economy ownership.

**Source owners:** new typed field-item catalog/actor, authored room pickup nodes,
fixed-stage placement manifests, reward/run services, and room validators.

- [x] **D1 Define the minimum field-pickup catalog.**
  - **As-is:** Consumables and currencies exist, but no typed small world-pickup catalog
    owns immediate effects, visuals, eligibility, or value.
  - **To-be:** Define data-driven healing, consumable-refill, cooldown-recovery, coin,
    and material pickups with stable IDs, effect contracts, visuals, sound, and duplicate
    transaction policy.
  - **Accept:** Catalog validator rejects unknown effects, negative values, missing
    presentation, and unsupported inventory behavior.
  - **Guard:** Field pickups do not become equipment, cards, or a second consumable bag.

- [x] **D2 Add purpose-tagged authored pickup positions.**
  - **As-is:** Rooms expose enemy, hazard, moving-platform, reward, and recovery anchors,
    but not small pickup placement intent.
  - **To-be:** Place safe-route, post-combat, recovery, optional-risk, secret, and economy
    pickup nodes in the rooms used by the approved Stage Plans.
  - **Accept:** Every position sits on reachable safe support, declares one purpose, and
    is included in a reviewed per-stage manifest.
  - **Guard:** Pickups never float unintentionally, overlap hazards, block sockets, or
    occupy required landing space.

- [x] **D3 Define fixed per-stage pickup manifests and budgets.**
  - **As-is:** Major reward budgets exist; small pickup rhythm does not.
  - **To-be:** Give each approved stage an exact reviewed sustain, tempo, and economy set
    with stable IDs and positions; keep budget ranges as future procedural constraints.
  - **Accept:** Different run seeds assemble the same expected pickup manifest and every
    placement meets support, hazard-clearance, and spacing rules.
  - **Guard:** Assembly does not inspect current HP and required progression never depends
    on collecting all loose pickups.

- [x] **D4 Implement safe collection and settlement.**
  - **As-is:** Interactive reward sources already have exactly-once transactions, but
    loose field collection does not exist.
  - **To-be:** Collect immediate effects once, auto-store currencies/materials through
    existing services, cap healing/charges correctly, and publish one concise pickup
    receipt.
  - **Accept:** Reload/duplicate/overlap fixtures cannot apply a pickup twice; full-health
    and full-charge behavior is explicit.
  - **Guard:** UI never writes health, charges, currencies, or materials directly.

- [x] **D5 Make pickups worth route decisions.**
  - **As-is:** Traversal often leads only to mandatory combat or large interactables.
  - **To-be:** Place modest recovery on readable safe paths, stronger economy/material
    value on optional risk, and tempo pickups where they can change an upcoming combat
    decision.
  - **Accept:** Each normal stage contains at least one visible low-risk and one optional
    risk-reward pickup moment without cluttering every platform.
  - **Guard:** No pickup lures the player into a non-returnable drop.

- [ ] **D6 Add pickup presentation.**
  - **As-is:** No shared small-item silhouette, idle cue, collection arc, or quantity
    feedback exists.
  - **To-be:** Give categories distinct silhouettes/colors, restrained idle motion,
    collection sound/flash, and an icon-based receipt in the context lane.
  - **Accept:** Pickup type and collectability are readable against all three regions.
  - **Guard:** Effects never resemble hazards, enemy projectiles, or required exits.
  - **Progress:** Category silhouettes/colors, idle bob, collection lift/fade, and HUD
    receipt are implemented. Pickup audio and final three-region visual review remain.

*Phase D gate:* catalog, authored-position, fixed-manifest, transaction, and production
stage checks pass; rendered captures demonstrate intentional item rhythm without visual
noise.

---

# Phase E - Gameplay HUD And Context Feedback

**Goal:** Replace the debug-like combat text panel with a compact game HUD that makes
actions and resources immediately readable without covering play space.

**Source owners:** `ProductionHUD.gd`, combat/run snapshots, new action-bar/context
components, `RewardReceiptPresenter`, interaction prompt, boss HUD.

- [x] **E1 Expand player-facing snapshots without moving authority.**
  - **As-is:** Combat actions expose ID, label, input, and cooldown; run snapshot owns
    consumable data separately; disabled reasons/icons are absent.
  - **To-be:** Provide presentation-ready action identity, icon ID, cooldown fraction,
    charge state, active/locked reason, class-state payload, and consumable slot through
    composed read-only snapshots.
  - **Accept:** HUD can render every state without querying catalogs ad hoc or calculating
    gameplay legality.
  - **Guard:** No UI-specific mutable gameplay state enters `RunState` or combat runtime.

- [x] **E2 Build the six-slot bottom action bar.**
  - **As-is:** Five attacks/skills render as multiline text in a top-left panel and the
    consumable is invisible.
  - **To-be:** Stable slots show Basic, Heavy, Skill 1-3, and Consumable with icon, input
    badge, cooldown/charge mask, exact short value, active state, and unavailable state.
  - **Accept:** Keyboard remap and gamepad prompts update live; longest supported binding
    and Korean stress labels fit without moving slots.
  - **Guard:** Routine readiness is visual; do not restore repeated `READY` strings.

- [x] **E3 Replace health/build text panels.**
  - **As-is:** Health and build summary occupy large bordered rectangles with dominant
    text.
  - **To-be:** Use a compact portrait/class emblem, health meter, optional guard layer,
    thin XP progress, and icon-based level/coin/material strip.
  - **Accept:** Exact values remain available while meter change, low-health, heal, XP,
    and currency gain are readable peripherally.
  - **Guard:** No oversized persistent panel obscures upper landing or enemy space.

- [x] **E4 Give class states dedicated visual language.**
  - **As-is:** Guard, charge, Hunter's Mark, Flow, and Death Mark are appended to a text
    list.
  - **To-be:** Render only relevant class state as compact pips/rings/stacks adjacent to
    the owning action or class emblem, with short exact details on focus/pause.
  - **Accept:** Warrior, Assassin, and Archer screenshots each communicate their active
    mechanic without reading a sentence.
  - **Guard:** State meaning is not conveyed by color alone.

- [x] **E5 Unify prompts and receipts in the context lane.**
  - **As-is:** Interaction prompt and reward receipt use independent bottom anchors and
    would collide with an action bar.
  - **To-be:** One lane prioritizes active interaction, then committed receipt/pickup
    feedback, queues rapid receipts, and clears stale prompts. Error feedback takes
    priority over a committed receipt, which takes priority over an active prompt.
  - **Accept:** Chest open, material claim, loose pickup, and nearby second interactable
    scenarios remain readable without modal interruption.
  - **Guard:** Existing exactly-once receipt semantics and input continuity remain.

- [x] **E6 Integrate objective and boss states.**
  - **As-is:** Objective and boss panels work but share the same generic text/panel
    language.
  - **To-be:** Objective appears briefly on room/phase change then collapses; boss name,
    health, phase, and stagger use one readable top band while player HUD remains stable.
  - **Accept:** Boss telegraphs and landing space remain unobstructed at all viewports.
  - **Guard:** Boss mode does not resize or relocate action slots.

*Phase E gate:* HUD state fixtures and rendered 960x540, 1280x720, 1920x1080
captures cover normal combat, cooldowns, no consumable, class states, interaction,
rapid receipts, low health, and boss combat.

---

# Phase F - Production Screen Replacement And Decision Clarity

**Goal:** Bring every player-facing screen to the same game-like visual language and
make build/equipment decisions exact before confirmation.

**Source owners:** production menu/choice/rest/result scripts and scenes,
`CharacterSelect`, `RestForge`, profile/run snapshots, shared choice/stat components.

- [ ] **F1 Migrate procedural screen composition to authored scenes.**
  - **As-is:** Major screens create many panels, labels, selectors, and buttons directly
    in GDScript.
  - **To-be:** `.tscn` scenes own hierarchy, anchors, responsive containers, focus order,
    and component instances; scripts bind snapshots and emit intents.
  - **Accept:** Screen scripts shrink toward presentation logic and no duplicate layout
    builder owns the same visual pattern.
  - **Guard:** Existing routes, signals, idempotent commands, and save/error states remain.
  - **Progress:** Production scenes and reusable action, reward, equipment, and forge
    components exist. Remaining large composition code must be split only where it
    still owns layout rather than binding/presentation.

- [x] **F2 Redesign main menu and character/loadout.**
  - **As-is:** Selection is information-complete but dominated by generic cards and text.
  - **To-be:** Character silhouette/portrait and combat promise lead; loadout slots use
    item icons; effective stats and candidate deltas sit in a restrained comparison
    region; mastery remains a focused subview. Raw implementation values such as
    negative jump velocity are replaced by player-readable movement summaries.
  - **Accept:** A player can identify class role, equipped items, locked cost, selected
    consumable, and Start Run readiness without tooltips.
  - **Guard:** Locked choices never appear actionable and start remains single-submit.

- [x] **F3 Redesign level-up, card, and Treasure choices.**
  - **As-is:** Choices are mainly text inside similar panels.
  - **To-be:** Use distinct upgrade/card/reward objects with icon/art, concise primary
    effect, exact current -> result values, compatibility, selected/focus states, and
    one clear confirmation lane.
  - **Accept:** Keyboard/gamepad user compares and commits exactly one valid choice; all
    long descriptions fit or intentionally scroll.
  - **Guard:** Visual rarity or animation never hides actual mechanics.

- [x] **F4 Add reusable equipment detail and stat-delta view.**
  - **As-is:** Equipment resources own mechanics/tradeoffs, but UIs expose incomplete
    portions and may hide descriptions in tooltips.
  - **To-be:** Show item name/slot, permanent base effect, tradeoff, current affix,
    candidate effect, only affected numeric deltas, and exact behavior changes.
  - **Accept:** Preview equals the authoritative resulting build snapshot for all twelve
    items and compatible characters.
  - **Guard:** Behavioral effects are described honestly rather than converted into fake
    scalar scores.

- [x] **F5 Redesign Rest & Forge.**
  - **As-is:** Rows show item names and affix descriptions without complete base context,
    projected stats, final coin balance, or prominent temporary duration.
  - **To-be:** Camp/forge scene leads; heal, consumable, reroll, and forge are distinct
    working stations; forge comparison shows current -> proposed effect, affected stats,
    final coins, and `THIS RUN` duration before commit.
  - **Accept:** Purchase/forge preview and applied snapshot match exactly; failure states
    explain cost/eligibility without changing state.
  - **Guard:** Temporary forge never reads as permanent equipment leveling.

- [x] **F6 Redesign pause/settings and result.**
  - **As-is:** Functional modal panels do not share strong game identity or outcome
    hierarchy.
  - **To-be:** Pause keeps the dimmed live scene visible with compact commands; settings
    preserves remap/conflict states; result leads with clear/defeat and kept rewards,
    then build details.
  - **Accept:** Focus, back, retry/error, abandon confirmation, and long-value states all
    work without mouse.
  - **Guard:** Pause never leaks input to gameplay and result never double-settles.

- [ ] **F7 Add restrained screen transitions and feedback.**
  - **As-is:** State changes often appear instantly or rely on text replacement.
  - **To-be:** Use short focus, selection, card reveal, forge commit, reward gain, and
    screen transition motion with reduced-motion alternatives.
  - **Accept:** Motion clarifies state and completes quickly enough for repeated runs.
  - **Guard:** No looping decoration, camera-obscuring flash, or input delay masquerades
    as polish.
  - **Progress:** Reward and pickup feedback are present. A coherent transition pass and
    explicit reduced-motion alternative remain.

- [x] **F8 Retire debug-like copy and obsolete builders.**
  - **As-is:** `READY`, raw IDs, implementation terms, and generic helper paragraphs can
    leak into player-facing text.
  - **To-be:** Use concise action language, catalog display names, and icon/state
    treatment; remove old procedural controls after replacements are proven.
  - **Accept:** Static grep plus full-flow review finds no debug route labels, raw IDs,
    stale `READY` list, or unreachable duplicate control.
  - **Guard:** Exact mechanics remain accessible in focused decision/detail screens.

*Phase F gate:* full keyboard/gamepad production flow at all three viewports, plus
snapshot parity for loadout, level/card choice, Treasure, rest/forge, settings, and
result.

---

# Phase G - Integrated Fun, Balance, Accessibility, And Release Gate

**Goal:** Validate the revised systems together as a coherent run rather than accepting
isolated technical success.

- [x] **G1 Validate every approved plan and pickup manifest together.**
  - **As-is:** Existing checks do not include fixed pickup positions or all post-drop
    escape scenarios in the exact production compositions.
  - **To-be:** Validate all three approved plans with all characters for route
    reachability, item support, hazard clearance, exact pickup manifests, and exit
    completion.
  - **Accept:** No invalid stage reaches gameplay and no item is required to escape.
  - **Guard:** Layout signature remains stable unless a documented stage-content version
    bump intentionally changes it.

- [ ] **G2 Run combat spacing and attrition sessions.**
  - **As-is:** Deterministic combat tests prove mechanics but not repeated engagement
    comfort or item pacing.
  - **To-be:** Play each character through all regions with base loadout and representative
    builds; record contact damage, healing used, unused pickups, fight duration, and
    deaths caused by unreadable spacing.
  - **Accept:** Basic combat no longer assumes trades, while hazards/enemy attacks still
    create meaningful attrition and field items do not trivialize the run.
  - **Guard:** Do not tune only from one character or one stage.

- [ ] **G3 Run UI recognition tests.**
  - **As-is:** Functional labels can technically expose state while remaining slow to
    parse.
  - **To-be:** Ask a fresh viewer/player to identify health, available skills, cooldown,
    consumable count, class state, objective, and latest pickup from short captures.
  - **Accept:** Required state is identified accurately without explanatory paragraphs.
  - **Guard:** Add labels where necessary; do not make essential state icon-only if the
    icon has not been taught.

- [ ] **G4 Verify responsive, focus, and accessibility states.**
  - **As-is:** Existing captures cover some viewports but not the redesigned component
    state matrix.
  - **To-be:** Check clipping, safe margins, contrast, non-color state, keyboard/gamepad
    focus, reduced motion, disabled/empty/error states, and longest supported strings.
  - **Accept:** 960x540, 1280x720, and 1920x1080 pass every required screen/state.
  - **Guard:** No required indicator covers player, enemy, landing edge, or telegraph.
  - **Progress:** Automated shell and HUD checks cover 960x540, 1280x720, and
    1920x1080, including focus restoration and compact states. Fresh-player
    recognition and the complete screen/state matrix remain.

- [ ] **G5 Run code/document quality gates.**
  - **As-is:** Broad UI changes risk large catch-all scripts and stale comments/docs.
  - **To-be:** Audit responsibility boundaries, comments, dead builders, resource schema,
    duplicated state, validation quality, and canonical design-doc deltas.
  - **Accept:** Codebase quality audit has no unresolved high-severity finding; comments
    are short, truthful, and explain only non-obvious intent/invariants.
  - **Guard:** No unrelated refactor or asset/dependency churn.
  - **Progress:** Independent audit findings for fixed-map signatures, card fail-closed
    behavior, loadout focus, dormant random gates, and pickup lifecycle were addressed.
    Final release-matrix and documentation reruns remain.

- [ ] **G6 Complete release-style manual runs.**
  - **As-is:** Prior RC proves complete flow before these experience changes.
  - **To-be:** Complete one full run per character through menu -> stages -> choices ->
    rest/forge -> boss -> result using production startup and no debug input.
  - **Accept:** No soft lock, UI overlap, duplicate settlement, misleading attack, missed
    required state, or presentation-blocking issue remains.
  - **Guard:** A passing headless suite alone cannot close the plan.

*Phase G gate:* all final automated gates pass and three production-style human runs
are complete with recorded approved-plan IDs/builds and no required work left.

---

## Validation Cadence

### Inner-loop checks

- Run only the focused validator for the touched responsibility.
- For UI, render one target state at 960x540 and 1280x720 before broad capture.
- For room work, validate the edited room plus one invalid fixture before all-region checks.
- For combat tuning, run the affected character and contact-safety fixture before roster
  matrix.
- Use `git diff --check` and targeted `rg` guards after each focused batch.

### Batch gates

- **After B:** fixed-plan identity, room, curated-region runtime, and roster-stage checks.
- **After C:** all character combat validators, attack presentation, enemy/contact fixtures.
- **After D:** field catalog/authored-position/manifest/transaction checks in all regions.
- **After E:** HUD state suite and three-viewport screenshot inspection.
- **After F:** complete UI flow, focus, snapshot parity, and three-viewport screen matrix.

### Final gates

```powershell
git diff --check
.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --quit-after 2
.\tools\godot.ps1 --path . --headless --script res://tools/validate_production_boot.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_production_stage.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_roster_stage_matrix.gd
.\tools\validate_release_candidate.ps1 -Full
```

- Render normal HUD, low-health, cooldown, class-state, interaction, pickup/receipt,
  boss, menu, loadout, level/card choice, Treasure, rest/forge, pause/settings, and
  result at 960x540, 1280x720, and 1920x1080.
- Complete one full production-style run per character.
- Run `$codebase-quality-auditor` after implementation and make only scoped safe fixes.
- Update active design docs and `.agent/Documentation.md` before marking this plan done.

### Rerun policy

- Rerun a failed narrow check only after a concrete change or new hypothesis.
- Run full region/roster/release matrices at named gates, not after every resource edit.
- If GUI/browser automation fails twice for tool/runtime reasons, use Godot screenshot
  fixtures, targeted runtime snapshots, or documented manual capture rather than
  turning tool repair into the task.

## Test Plan

### Traversal scenarios

- Every character starts at every recovery anchor in every room with a committed drop.
- Rope begins at a reachable lower mount zone and ends at a safe upper dismount zone.
- One-way drop has a separate conservative return or forward exit.
- Crouch tunnel admits body dimensions and exits onto standing space.
- Jump/dash paths clear ceilings, walls, hazards, and moving-platform sweep bounds.
- Deliberately invalid basin, rope, ceiling, landing, and hazard fixtures are rejected.

### Field-item scenarios

- Different run seeds assemble the same approved item categories and positions.
- Full health, partial health, zero/full consumable charges, and active cooldown states.
- Rapid overlapping pickup callbacks settle exactly once.
- Pickup immediately before death, checkpoint/reset, stage clear, and reload.
- Optional pickup is reachable and returnable; no item occupies a required landing.
- Stage clear succeeds even when every loose pickup is ignored.

### Combat scenarios

- Each basic/heavy attacks stationary, approaching, and retreating normal targets.
- Target touches footprint edge, stands one pixel outside, and approaches during startup.
- Attack in both facing directions and near wall/ledge constraints.
- Enemy contact overlap, repeat cooldown, knockback, and player recovery.
- Assassin two-pulse/swept movement, Warrior broad control, Archer near/mid/max range.
- Visible motion stays inside collision footprint after every tuning change.

### UI scenarios

- All six action slots: ready, cooldown, active, disabled, remapped input, gamepad input.
- Consumable: selected, count 1+, empty, unavailable, use rejected at full health.
- Class-specific state: Warrior guard, Assassin Flow/Death Mark, Archer Hunter's Mark.
- Prompt -> chest receipt, prompt -> material receipt, loose pickup receipt queue.
- Low health, healing, XP gain/level-up, coin/material gain, boss phase/stagger.
- Long item/card/affix descriptions, current -> projected deltas, insufficient currency.
- Keyboard/gamepad focus, back/cancel, duplicate confirm prevention, error recovery.

## Guard Checks

- [ ] No `MotionTestStage`, debug HUD, seed/map selector, or route annotation returns to production.
- [ ] No stable post-drop support in an approved room lacks a validated return/exit path.
- [ ] No field pickup exists outside an authored, validated pickup node.
- [ ] No map item, movement upgrade, enemy boost, or damage trick is required to escape.
- [ ] No character body/collision scale changes as a substitute for attack tuning.
- [ ] No attack visual exceeds its real collision footprint.
- [ ] No UI script mutates health, cooldowns, rewards, equipment, currency, or save state.
- [ ] No raw catalog ID or repeated `READY` list remains in player-facing production UI.
- [ ] No raw coordinate-sign movement value or internal multiplier is exposed as player
  copy when a readable summary or exact named effect is available.
- [ ] No prompt/receipt/action-bar overlap at supported viewports.
- [ ] No forge preview implies permanent equipment enhancement.
- [ ] No external dependency or asset pack is added without explicit approval.
- [ ] No unrelated user-authored change is staged, reverted, or reformatted.

## Rollback / Safety

- Implement one responsibility per scoped commit so geometry, combat tuning, field items,
  HUD foundation, and screen migration can be reverted independently.
- Preserve existing resource IDs, transaction IDs, save schema, and signal contracts
  unless a migration is explicitly planned and tested.
- Add new UI scenes alongside old builders, switch one screen at a time, then delete the
  old builder only after parity and responsive checks pass.
- Version approved stage and pickup manifests when an intentional layout/content change
  alters their deterministic signatures.
- Do not repair invalid stages at runtime. Reject and report them before gameplay so
  rollback remains deterministic.

## Risks And Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Conservative traversal flattens room variety | Stages become safe but dull. | Keep optional pre-commit challenges and varied rock masses; constrain only mandatory/committed returns. |
| Melee reach inflation removes positioning | Combat becomes trivial and classes converge. | Tune contact-safety margins per attack and preserve timing, stagger, movement, and target caps. |
| Field pickups trivialize attrition | Healing/economy decisions lose meaning. | Budget by stage, cap values, space pickups, and validate no hidden HP-based rubber-banding. |
| New action bar obscures play space | Landing/telegraphs become harder to read. | Stable compact dimensions, safe-area review, shared context lane, three viewport gates. |
| Broad UI rewrite breaks state ownership | Preview and applied results diverge. | Snapshot-only presenters, shared stat-delta view model, parity tests, one screen per migration commit. |
| Generated art becomes inconsistent | UI looks polished in parts but incoherent overall. | Icon/content manifest, fixed palette/material rules, component gallery, asset review before broad use. |
| Plan becomes another foundation-only effort | Player sees little progress for too long. | Each batch ends in a user-testable route; Phase B fixes the reported room, Phase C changes combat feel, Phase D adds visible pickups, Phase E replaces the live HUD. |

## Next Steps

1. Finish final automated import, boot, focused UI/map checks, and the default release
   matrix against fixed layout V3.
2. Render and inspect the current hatch/rope, HUD, shell, reward, and equipment states at
   supported viewports; repair only visible blockers.
3. Close scoped quality/documentation findings and decide whether remaining procedural
   screen composition or a global icon manifest materially improves the player build.
4. Complete one production-style run per character plus combat attrition and UI
   recognition sessions; record balance/fun findings before marking the plan done.
5. Define random-generation re-entry in a separate future plan only after fixed-stage
   gameplay is accepted.

## Open Questions To Confirm As Work Proceeds

- Exact names, values, and per-stage budgets for the first field-pickup catalog after one
  playable vertical slice.
- Whether a separate paused run-summary screen is useful after the action bar and
  loadout/forge comparisons are complete; do not build it without a meaningful task.
- Whether final game copy remains English-only or begins Korean localization in a later
  dedicated pass.
- Whether project-original generated icons are sufficient or an external licensed art
  pack should be evaluated under the adoption contract.

## Decision Notes / Resolved Decisions

- The production run, not a renewed integrated testbed, is the manual QA surface.
- Attack truthfulness and reward receipts are completed foundations, not substitutes for
  reach tuning and full UI replacement.
- A recovery anchor means safe standing/reset, not guaranteed escape.
- Character body enlargement is rejected as the main attack-range fix.
- The first in-run inventory presentation is an action bar/quick consumable, not a grid.
- Hidden health-sensitive item spawning is rejected; field items stay fixed and authored.
- Random stage generation remains implemented but dormant until the core game loop and
  fixed-stage content are proven fun enough to define meaningful procedural constraints.
- Fixed layout V3 is the current approved map contract. A layout-version bump and new
  deterministic signatures are required for future room/content changes.

## Handoff Summary

Read first:

1. Root `AGENTS.md` and `.agent/PLANS.md`.
2. `docs/README.md` and the canonical product/design documents linked in frontmatter.
3. This plan's locked decisions, domain alignment, current-state map, and the current
   phase only.
4. Completed combat/reward plan before touching attack presentation or receipts.

Produce last:

- updated active design contracts for traversal, field items, combat tuning, and UI;
- responsibility-shaped implementation and focused tests;
- rendered evidence at all supported viewports;
- one complete production run per character;
- a concise `.agent/Documentation.md` status update and this plan marked `done` only
  when no required work remains.

Stop when:

- every phase gate and final gate passes;
- no approved stage can strand a base character after a committed drop;
- normal combat does not require routine contact trades;
- field pickups are constrained, useful, and non-essential to completion;
- all production screens use the shared game UI language without debug-style leftovers;
- previews match applied equipment/forge state;
- three full production-style character runs complete without a soft lock, misleading
  UI, duplicate settlement, or presentation blocker.

Ask the owner only when a choice would materially change product scope, such as adding
a grid inventory, adopting an external asset dependency, changing save compatibility,
or replacing the locked progression/economy model.
