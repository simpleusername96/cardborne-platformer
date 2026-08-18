---
type: plan
status: done
owner: BK
created: 2026-08-11
last_reviewed: 2026-08-12
topic: Dash-coherent threat radar, monotonic stage and boss pressure, guidebook stat ownership, and Garage removal
scope: Five-stage Cardborne run; threat-radar presentation, ordinary and boss difficulty profiles, boss autonomous pattern execution, guidebook information architecture, modal routing, focused validation, Web export, rendered QA, and bounded performance evidence
related:
  - ../../AGENTS.md
  - ../../.agents/AGENTS.md
  - ../../.agents/PLANS.md
  - ../../.agents/design/DESIGN.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/design/cardborne-universal-art-style-reference.png
  - ./2026-08-11-combat-clarity-smoothness-difficulty.md
  - ../../.agents/cardborne-performance-engineering-policy.md
  - ../../.agents/research/performance/cardborne-runtime-architecture-audit.md
  - ../../.agents/evidence/performance/semantic-v2-runtime-acceptance-evidence.md
---

# Dash Radar, Boss Scaling, Guidebook, and Flow - Execution Contract

This plan fixes four connected product problems without adding new content or visual
themes. The threat radar will keep the player as its live origin during a dash. Stage 2
through Stage 5 ordinary enemies will receive a moderate, explicit health and damage
increase. Bosses will gain one stage-owned profile for health, damage, shield mitigation,
cadence, and footprint, and their autonomous attacks will execute their authored shapes.
The Guidebook will read combat statistics from canonical gameplay owners instead of
showing generic prose. The non-interactive Garage detour will be removed and its callers
will route directly to the next useful surface.

The implementation is complete only after contracts, runtime behavior, Korean and English
UI, deterministic validators, rendered evidence, Web export, and production-style runtime
checks agree. Subjective balance and feel remain a short user playtest after automated
qualification; they are not a reason to leave known contract failures unresolved.

## Purpose

- Keep the threat radar centered on the current player presentation and keep its sampled
  contacts temporally coherent during the complete `0.20 s` dash.
- Raise ordinary enemy health and damage from Stage 2 onward while preserving Stage 1,
  encounter counts, movement speeds, telegraphs, projectile speeds, quotas, and caps.
- Make later bosses reliably stronger across health, attack damage, shield mitigation,
  autonomous cadence, and coverage, while retaining readable startup and recovery windows.
- Execute autonomous `area`, `lanes`, `beam`, and `summon` boss patterns as their authored
  shapes before tuning their size.
- Replace Guidebook filler with derived, stage-aware enemy and boss statistics.
- Put all hostile actors and elite modifiers under Enemies, and keep Field Objects limited
  to non-hostile world interactions, traversal, and rewards.
- Remove repeated `???` rows, distinguish the actual Mystery Device from locked content,
  and replace the Guidebook's textual Back command with an accessible icon command.
- Remove the Garage screen and its redundant routing without deleting persistent module
  effects, unlocks, discovery state, or save compatibility.

## Why and Current Context

### Threat radar

- `VehicleRun._update_threat_contacts()` samples at `THREAT_SAMPLE_INTERVAL = 0.20` and
  stores offsets relative to the player position at that sample.
- `VehicleHudPresenter` publishes world-marker data on a separate `0.20 s` timer with an
  initial phase offset. The simulation sample and UI publication are therefore not one
  atomic event.
- The cached contact dictionaries are cleared and reused after publication. The radar can
  observe borrowed mutable data from a different sample generation.
- A dash lasts `0.20 s` at `1220 px/s`, so the player travels about `244 px` during one
  complete contact interval. Camera smoothing continues independently. The radar can draw
  a current screen center with old player-relative offsets, or an old projected center
  beside the live player. This is the confirmed temporal ownership defect behind the
  visible squeeze and brief loss of the craft origin.
- The current validator protects the borrowed-cache identity and the `5 Hz` actor scan,
  but it does not test dash-time origin coherence.

### Ordinary enemies and bosses

- Current ordinary health pressure is `[1.35, 1.40, 1.45, 1.50, 1.50]` and damage pressure
  is `[1.15, 1.20, 1.25, 1.30, 1.30]`. Health rises substantially after Stage 1, but the
  damage curve is comparatively shallow and both curves flatten at Stage 5.
- Current boss health is `[1250, 1350, 1450, 1550, 1650] * 3.90`, or
  `[4875, 5265, 5655, 6045, 6435]` before any external difficulty multiplier.
- Boss damage uses one global `1.30` multiplier. Shield-up received damage is `0.12` in
  every stage, and the exposed state remains `1.00` for `4.0 s` in every stage.
- `PHASE_GAPS = [0.55, 0.42, 0.32]` and autonomous intervals
  `[6.0, 4.9, 3.9]` depend on boss phase, not stage. Later-stage bosses do not inherently
  attack more often.
- Boss footprints are authored per pattern and are not monotonic by stage. Stage 2 has an
  area radius of `185`, while Stage 1 has `230`; later bosses use different mixtures of
  areas, lanes, beams, charges, fans, crosses, and summons.
- `VehicleRun._execute_boss_autonomous()` special-cases the sentinel summon and converts
  every other autonomous event into a circular denied zone. Consequently autonomous
  `opposing_lanes`, `switch_sweeps`, and `radial_lattice` lose their authored lane or beam
  geometry. Size-only tuning would amplify the wrong shape.
- The precise answer to "are later bosses stronger?" is therefore: boss HP is reliably
  higher and encounter composition differs, but damage, shield mitigation, cadence, and
  coverage do not currently form a reliable Stage 1-to-5 escalation.

### Guidebook and Garage

- `VehicleGuidebookCatalog` owns a second static description system. It publishes
  `movement_key`, `attack_key`, and `counter_key`, but no health, damage, defense, speed,
  interval, or footprint data.
- `VehicleGuidebookPanel` always draws the same Movement, Attack, and Counter rows for
  discovered enemies and bosses. Those rows are generic prose rather than gameplay truth.
- Base health and speed belong to `VehicleEnemyArchetypes`; attack values and telegraphs
  belong to `VehicleAttackContract` and specialist runtimes; stage scaling belongs to
  `VehicleStageDifficulty`; boss damage/shape and shield rules belong to boss owners.
  Copying these values into the catalog would create a second balance authority.
- The visible `mobile` category excludes stationary hostiles, while `object_elite_*`
  modifiers are declared under `objects`. The UI can therefore show enemy modifiers as
  Field Objects while omitting turrets, mines, generators, sentinels, and other stationary
  enemies.
- Locked entries are emitted as separate `???` rows. `object_mystery_device` is a real
  neutral field object and is localized as `미확인 장치`; the two unrelated meanings of
  "unknown" become visually adjacent and confusing.
- Guidebook Back reuses the Settings text key `SETTINGS_CLOSE` (`돌아가기` / `Back`) rather
  than an icon-only navigation component with an accessible name and input hint.
- Garage presents a read-only build summary and only two commands: Deployment Setup and
  Settings. It offers no build selection or editing. Pause, failure, and final-result
  paths enter Garage, then Garage Launch enters Deployment, so it is a redundant modal
  hop. Persistent progression is saved by `VehicleRun`, not by the Garage panel.

## Scope and Boundaries

In scope:

- Threat sampling/publication ownership and radar-only presentation behavior.
- A fixed-capacity threat-sector frame, live player anchor, sample-generation contract,
  and dash-time regression fixture.
- Stage 2-to-5 ordinary health and damage pressure.
- Stage-specific boss health, damage, shield-up mitigation, cadence, and coverage profiles.
- Correct autonomous boss dispatch for all authored kinds already present.
- Guidebook category structure, read-only stat adapter, active-stage/range context, locked
  summary behavior, Mystery Device display name, and the Guidebook Back command.
- Removal of Garage UI, mode/routes/signals/localization/capture fixtures, and direct
  routing to Deployment.
- Product/design documentation, focused validators, deterministic captures, Web export,
  built runtime QA, and one final bounded performance comparison.

Out of scope:

- New stages, enemies, bosses, cards, boss attacks, encounter counts, quotas, or active
  caps.
- Ordinary-enemy speed, attack cadence, projectile speed, or spawn-density changes.
- Shorter attack startup, active telegraphs, or player escape windows.
- Player health, movement, dash, weapon damage, upgrade, or economy retuning.
- A new armor stat that does not exist in gameplay. Guidebook defense rows must describe
  real shield, plate, guard, or modifier behavior.
- Removal of the Mystery Device mechanic. Only its display label and Guidebook clarity
  change; the stable `mystery_device` runtime identifier remains.
- Removal or migration of persistent module/unlock/save data.
- New raster art, generated imagery, SVG geometry, named themes, or changes to the approved
  visual language.
- A `60 Hz` all-enemy radar scan or any relaxation of performance gates.

## Facts, Constraints, and Assumptions

- Korean remains the default UI language. Every changed user-facing key must have complete
  Korean and English values.
- Gameplay positions and pattern geometry remain authoritative. UI may derive display
  data but must not decide collision, damage, or target eligibility.
- The existing `5 Hz` hostile eligibility scan remains the performance boundary. Only a
  maximum of 12 sector summaries may be rebased during a render frame.
- Radar topology, colors, sector count, priority grammar, and visual scale remain unchanged.
  The task corrects temporal behavior, not art direction.
- Stage 1 ordinary values remain unchanged because the request begins at Stage 2.
- Boss startup and recovery durations remain unchanged except where a larger footprint
  would violate the existing base-walk escape margin; in that case startup may increase,
  never decrease.
- Boss projectile reservation `24`, total hostile projectile cap `120`, live boss-add cap
  `12`, effect cap `96`, and enemy capacity `320` remain hard limits.
- Guidebook entry IDs already persisted in `vehicle-guidebook.cfg` remain stable. Category
  IDs are not persisted and may change from `mobile` to `enemies`.
- The active-run Guidebook shows exact effective values for the current stage. Outside an
  active run, it shows a localized Stage 1-to-5 range. It never silently mixes base and
  effective values.
- Existing performance evidence is red under stress, including a recent clean
  `capacity_pressure` median near `7.5 FPS`. This work must report scenario validity and
  comparable regression evidence honestly; it must not describe the existing baseline as
  passed.
- No production dependency, engine change, save-schema migration, force operation, or
  external write is authorized by this plan.

## Domain Alignment

| Term | Meaning in this plan | Owner | Invariant |
| --- | --- | --- | --- |
| Threat sample | One fixed-generation summary of eligible hostile contacts | threat-feed owner | Sample origin and sector records publish together |
| Live anchor | Current player world position and current projected HUD position | Run to HUD presentation path | Updated without rescanning hostile actors |
| Enemy | Any non-boss hostile actor, mobile or stationary | enemy archetypes/runtime | Never appears as a Field Object |
| Elite modifier | A trait applied to an existing enemy | elite trait catalog | Describes deltas; it is not a standalone field object |
| Boss stage profile | Stage-owned health, damage, shield, cadence, and coverage scalars | stage difficulty | Later stages satisfy declared monotonic rules |
| Field Object | A non-hostile world interaction, traversal object, or reward | field/object owners | Contains no enemy actors or elite traits |
| Locked discovery | A count of undiscovered entries, not a fake selectable object | Guidebook catalog/store | Does not reveal name, preview, or stats |
| Garage | Current read-only intermediate modal | removed | Persistent progression remains independently owned |

Stable storage IDs such as `mobile_edge_enemy`, `object_elite_armored`, and
`object_mystery_device` may remain for save compatibility even when their visible category
or label changes. Legacy storage names must not dictate user-facing domain language.

## Visual Authority Evidence

- Canonical visual document read completely:
  `docs/design/VISUAL_SYSTEM.md`.
- Canonical style sheet inspected at original detail:
  `docs/design/cardborne-universal-art-style-reference.png`.
- Expected and observed SHA-256:
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- Original reference provenance: repository path above, `1,670,764` bytes, filesystem
  timestamp `2026-08-02 12:13:44 +09:00`.
- The sheet is a mandatory style reference only and grants no asset approval.
- Actual image reference used for generation/editing: not applicable. This plan creates no
  raster asset and performs no ImageGen or raster edit.
- Allowed output is existing code-native UI geometry and a text glyph in a shared command
  component. The deterministic SurfaceDetail SVG exception is not used.
- The Guidebook remains a wide three-column desktop surface and compact tab/list-detail
  surface. Existing panel, spacing, type, preview, focus, and reduced-motion contracts
  remain authoritative.

## Alternatives Considered

### Threat radar

1. Scan and rebuild the complete radar every frame.
   - Rejected. It would move an up-to-320-actor query and geometry build into a hot path,
     contradict the performance policy and the existing `5 Hz` contract.
2. Force one new sample only at dash start/end.
   - Rejected as the complete solution. It narrows the stale interval but leaves the live
     center, unsynchronized publisher, borrowed mutable buffer, and mid-dash origin error.
3. Move only the radar center with the player and keep sampled offsets unchanged.
   - Rejected as incomplete. The craft stays centered, but contact directions still use a
     stale origin during the largest movement burst.
4. Publish a bounded coherent sector frame and rebase it against a live anchor.
   - Selected. The actor scan remains `5 Hz`; sample origin and records swap atomically;
     only 12 sector representatives are rebased/regrouped with reusable storage per frame.

### Difficulty and boss behavior

1. Raise role base values in many enemy/specialist files.
   - Rejected for this request. It fragments the Stage 2-to-5 rule and makes Guidebook
     parity harder to prove.
2. Increase enemy count or projectile count.
   - Rejected. It does not directly satisfy requested health/damage changes and increases
     clutter and runtime load.
3. Change only global boss damage and radius numbers.
   - Rejected. It cannot make defense/cadence stage-aware and would enlarge incorrectly
     flattened autonomous patterns.
4. Keep ordinary tuning in `VehicleStageDifficulty`, add one boss stage profile there,
   and make boss runtime dispatch authored shapes.
   - Selected. It gives one auditable stage curve, preserves pattern identity, and lets
     Guidebook stats read the same source as combat.

### Guidebook and Garage

1. Replace prose with hard-coded numbers in the Guidebook catalog.
   - Rejected. Every balance change would require a manual second edit and could lie to
     the player.
2. Keep the current categories and only rename Field Objects.
   - Rejected. Elite traits and omitted stationary hostiles would remain semantically
     misplaced.
3. Add a read-only stat adapter over canonical combat owners and restructure categories.
   - Selected. Catalog owns identity/discovery; combat owners own values; UI only renders
     ordered `stat_rows`.
4. Improve or merge Garage into Deployment.
   - Rejected for the current product. Garage has no unique edit action, and merging its
     read-only summary would burden the already functional Deployment surface.
5. Remove Garage and route callers directly.
   - Selected. It deletes a redundant modal while preserving persistent state and the
     existing Deployment owner.

## Proposed Design

### 1. Coherent threat-radar feed

Add a small presentation data owner under `scripts/presentation/` rather than expanding
the already large `VehicleRun` with another cache protocol. It owns two fixed-capacity
frames and a generation counter. Each frame contains:

- sampled player world origin;
- sample generation and timestamp;
- exactly 12 reusable sector records;
- per sector: active flag, count, nearest representative world position, nearest distance,
  and strongest threat class/priority required by the current visual grammar.

At the existing `0.20 s` scan, `VehicleRun` fills the inactive frame from eligible enemies,
then swaps the active index once. It never clears or mutates the active frame. The HUD
presenter reads one generation rather than a borrowed dictionary graph. Independent HUD
publication timing may remain, because a generation is internally coherent.

`VehicleRun` also publishes a narrow live-anchor value each presentation frame: current
player world position and the matching projected player screen position after the camera
transform for that frame is current. This path performs no enemy iteration and allocates
no dictionaries or arrays.

`VehicleThreatRadar` keeps geometry local to origin and positions the CanvasItem at the
live screen anchor. For each frame it rebases at most 12 representative world positions
against the current player world position, regroups them into 12 reusable display bins,
and updates a retained compact vertex buffer. Anchor-only movement changes the CanvasItem
transform and does not dirty topology. The implementation must prove:

- no new `ArrayMesh` per frame;
- no per-frame `Dictionary`, `Array`, or packed-array growth;
- no enemy scan outside the existing sample cadence;
- no visible center displacement greater than `1 px` from the projected player during a
  full dash at supported capture sizes;
- sample generation, origin, and records can never be observed from different writes.

The scanner may take an immediate sample on dash begin/end only if rendered evidence still
shows a direction discontinuity. That is a fallback after the live-rebase design, not a
replacement for it.

### 2. Ordinary stage pressure

Keep the current global, class, stage, and difficulty formula order. Change only the two
ordinary pressure arrays in `VehicleStageDifficulty`:

| Stage | Health pressure current -> target | Effective priority HP/base | Damage pressure current -> target | Effective damage/authored point |
| --- | ---: | ---: | ---: | ---: |
| 1 | `1.35 -> 1.35` | `2.9835` | `1.15 -> 1.15` | `2.018250` |
| 2 | `1.40 -> 1.45` | `3.7700` | `1.20 -> 1.24` | `2.241486` |
| 3 | `1.45 -> 1.55` | `4.6345` | `1.25 -> 1.33` | `2.474199` |
| 4 | `1.50 -> 1.65` | `5.5770` | `1.30 -> 1.42` | `2.716389` |
| 5 | `1.50 -> 1.75` | `6.5975` | `1.30 -> 1.50` | `2.948400` |

Swarm/standard roles retain their existing additional `1.12` health class multiplier;
priority roles do not gain it. Compared with current Stage 2-to-5 values, the target
priority HP increase is approximately `3.6%`, `6.9%`, `10.0%`, and `16.7%`; damage per
authored point increases approximately `3.3%`, `6.4%`, `9.2%`, and `15.4%`. This is a
moderate second increase after commit `6af25e29`, not a new difficulty system.

### 3. Boss stage profile and pattern execution

`VehicleStageDifficulty` owns five aligned boss curves. Pattern owners continue to own
authored base values and geometry. Runtime asks the stage profile for the scalar once and
does not duplicate arrays.

| Stage | HP multiplier | Target HP | Damage multiplier | Shield-up received damage | Cadence scale | Coverage scale |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | `4.20` | `5250` | `1.35` | `0.110` | `0.95` | `1.05` |
| 2 | `4.30` | `5805` | `1.42` | `0.105` | `0.90` | `1.10` |
| 3 | `4.40` | `6380` | `1.50` | `0.100` | `0.85` | `1.15` |
| 4 | `4.50` | `6975` | `1.58` | `0.095` | `0.80` | `1.20` |
| 5 | `4.60` | `7590` | `1.70` | `0.090` | `0.75` | `1.25` |

The monotonic contract is:

- authored boss HP and final target HP increase by stage;
- damage multiplier never decreases;
- shield-up received-damage multiplier never increases;
- phase read gap, initial autonomous delay, and autonomous interval never increase after
  the stage cadence scale is applied;
- every radius, beam width, lane spacing, fan spread, and cross spread uses the stage
  coverage scale where that dimension exists;
- projectile/volley count, active cap, projectile speed, startup, active duration, and
  recovery remain unchanged.

Apply cadence scale to `VehicleBossRuntime.read_gap()`, the initial autonomous delay, and
`AUTONOMOUS_INTERVALS`. Do not scale startup, active time, recovery, or the `4.0 s` exposed
window. The independent autonomous layer supplies the material frequency increase without
destroying the direct attack's readable sequence or damage window.

Replace `_execute_boss_autonomous()`'s catch-all circle with kind-specific dispatch:

- `area`: exact circular denied zone using scaled radius;
- `lanes`: existing lane projectile/corridor executor using scaled lane spacing;
- `beam`: existing exact beam startup/active corridor using scaled width;
- `summon`: bounded authored summon path, including the existing sentinel cap checks;
- any unknown kind: a validator failure and explicit diagnostic, never a silent circle.

Coverage scales resolve to these representative values before rounding: Stage 1
`thermal_ring 241.5`, Stage 2 `archive_depth 203.5`, Stage 3 `pulse_burst 270.25`, Stage 4
`gate_shockwave 288`, Stage 4 `switch_sweep width 93.6`, Stage 5 `radial_beam width 102.5`,
and Stage 5 `relay_pulse_rings 281.25`. Because attack shapes differ, raw radius is not a
valid cross-stage strength score. The stage profile, effective shape, frequency, and
damage together define escalation.

Before accepting each enlarged area, verify the existing escape rule
`startup * 280 >= radius + 40`. `gate_shockwave` at radius `288` requires startup at least
`1.172 s`; set it to `1.20 s`. Any other failing footprint receives the smallest rounded
startup increase that restores the margin. No startup may be shortened.

### 4. Guidebook stat adapter and information architecture

Create `VehicleGuidebookStatAdapter` under `scripts/progression/`. It is read-only and
combines canonical data from:

- `VehicleEnemyArchetypes` for base health, speed, radius, and role;
- `VehicleAttackContract` and specialist runtimes for positive direct damage and attack
  geometry;
- `VehicleStageDifficulty` for exact current-stage or Stage 1-to-5 effective values;
- `VehicleEliteTraitCatalog` for modifier deltas;
- `VehicleBossPatterns`, `VehicleBossRuntime`, and `VehicleBossShieldRuntime` for boss
  damage range, shield behavior, cadence, and coverage.

The adapter returns ordered semantic rows such as
`{label_key, value_key/value_args, semantic}`. The panel formats no formulas. Numeric
rounding rules live in the adapter and are tested:

- HP: nearest whole point;
- damage: nearest whole point, or a localized min-max range for multiple positive attacks;
- movement speed and footprint: nearest whole `px/s` or `px`;
- intervals: one decimal second;
- received-damage multiplier displayed as damage reduction percentage, for example
  `0.09` becomes `피해 감소 91%` / `91% damage reduction`;
- a non-damaging support attack displays `지원` / `Support`, never fake zero damage.

Visible rows:

- ordinary enemy: effective HP, direct damage/range, movement speed, and a defense or
  protection row only when a real shield/plate/guard/modifier exists;
- boss: effective HP, positive attack damage range, shield damage reduction, exposed
  duration, autonomous interval range, and largest representative footprint;
- elite modifier: only its actual health/damage/speed/cooldown/plate deltas;
- field object: concise effect/value rows from its owning object catalog, with no Movement
  or Attack filler;
- current ship: retain its existing useful build summary and do not force enemy stat rows.

`VehicleGuidebookCatalog` continues to own stable identity, visible name, preview reference,
category, and discovery. It stops owning enemy/boss descriptions and counterplay filler.
The panel renders `stat_rows` and no longer knows `movement_key`, `attack_key`, or
`counter_key`.

Change visible categories to:

1. Current Ship / 현재 기체
2. Enemies / 적
3. Bosses / 보스
4. Field Objects / 필드 오브젝트

The `enemies` category contains all non-boss hostiles, both mobile and stationary, and the
three elite modifiers. Existing persisted entry IDs remain stable. Add stable catalog
entries and discovery mapping for currently omitted stationary roles: turret, mine,
Fixed Ranged Ordinary Enemy Lv.2, Fixed Beam Ordinary Enemy Lv.1, and generator, plus any other active non-boss role found
by the final catalog parity validator. Field Objects contain only experience, repair,
recall, reward crates, the renamed Mystery Device, and transit/traversal objects.

Do not emit one selectable row per locked entry. Each category lists discovered entries
and one non-selectable localized summary such as `미발견 4` / `4 undiscovered`. It reveals
no name, preview, stats, or ID. The category tab still shows discovered/total progress.

Keep the runtime ID and save entry ID `mystery_device` / `object_mystery_device`, but change
the visible Korean/English label to `변칙 장치` / `Anomaly Device`. Its concise object rows
state that activation resolves one of the existing authored outcomes; they do not expose
an encounter's hidden result before activation. This separates a real object from locked
discovery placeholders without deleting the mechanic.

### 5. Accessible icon-only Back command

Add or extend a shared navigation-command helper, not the combat action-glyph renderer.
For Guidebook Back:

- render a familiar code-native left-arrow glyph `←` in a `48 x 48` secondary command;
- keep the existing close signal, Escape behavior, focus ring, controller navigation, and
  reduced-motion behavior;
- set localized `accessibility_name` and tooltip to `COMMON_BACK`;
- show the localized input hint required by `VISUAL_SYSTEM.md` for keyboard/controller
  navigation;
- verify the focus target is at least `44 x 44`, is not clipped at compact widths, and
  remains the final predictable focus stop.

This task changes only the Guidebook's visible Back command. The helper is reusable, but
unrelated Settings controls are not migrated without a separate reason.
Dangerous commands such as abandoning a run remain visible text.

### 6. Garage removal and direct routing

Remove `VehicleGaragePanel`, its `.uid`, Stage UI host, runtime mode/branch, signals,
localization, debug contract, capture fixture, and Garage-specific validators. Do not leave
dead wrappers or a hidden empty panel.

Introduce or reuse one explicit return-to-deployment route that owns projectile cleanup,
run teardown/reset, player health/reset semantics, mode transition, focus, and Settings
return context. Replace callers as follows:

| Current source | Current route | Target route |
| --- | --- | --- |
| Pause `Abandon run` | Garage -> Deployment | Deployment directly |
| Failure report primary | Garage -> Deployment | Deployment directly |
| Final result Garage/Replay | two commands that converge | one `New Run` / `새 런` primary -> Deployment |
| Garage Settings return | Garage | removed |

The Deployment screen remains the sole owner of launch setup and general Settings access.
Result/report surfaces may keep their existing run summary; no summary is copied into
Deployment. Persistent relay/field module effects, unlock flags, Guidebook discovery, and
save keys remain intact and receive parity tests.

## Discovery Closure Map

| Requirement/question | Evidence | Locked decision | Owning tasks | Proof |
| --- | --- | --- | --- | --- |
| Why does radar squeeze during dash? | separate 5Hz timers, stale relative origin, mutable borrowed cache, 244px dash | atomic sector generation plus live rebase | 1.1-1.5 | dash fixture and capture |
| Can radar update every frame? | current capacity reaches 320 and stress baseline is red | only 12 summaries update; actor scan stays 5Hz | 1.2-1.5, 6.6 | allocation/cadence/perf evidence |
| Raise enemies from Stage 2 | stage pressure owner already exists | exact target arrays above; Stage 1 unchanged | 2.1-2.3 | numeric oracle |
| Are later bosses fully stronger now? | only HP is monotonic; other axes are not | one monotonic boss stage profile | 3.1-3.4 | Stage 1-5 profile oracle |
| Why tune shape before size? | autonomous lanes/beams become circles | dispatch authored kinds first | 3.2 | all ten autonomous patterns execute |
| What belongs under Enemies? | mobile-only catalog excludes stationary roles; elite traits sit in Objects | all non-boss hostiles and elite modifiers | 4.2-4.4 | catalog/runtime parity |
| Where do Guidebook stats come from? | combat values have multiple canonical owners | one read-only adapter, no copied constants | 4.1-4.5 | source parity validator |
| What are `???` and Mystery Device? | locked placeholder and real object are separate | locked count summary; Anomaly Device display label | 4.3-4.5 | ko/en rendered capture |
| Does Garage own progression? | it only presents summary and routes; Run saves state | remove UI, preserve save owners | 5.1-5.5 | route/save parity validators |
| Should Back be an icon everywhere? | request is Guidebook-specific | shared helper, Guidebook migration only | 4.6 | accessibility/focus/layout tests |

## Milestones and Tasks

### 0. Contract and specification

- [x] 0.1 Reconcile `docs/product/vehicle_game_spec.md` with threat radar origin/sample
  ownership, new ordinary/boss curves, corrected autonomous pattern kinds, Guidebook
  categories/stats/locked behavior, Anomaly Device label, direct post-run routes, and the
  removal of Garage.
- [x] 0.2 Reconcile `docs/design/VISUAL_SYSTEM.md` and `.agents/design/DESIGN.md` with the
  retained radar visual grammar, stat-first Guidebook detail, icon-only Back accessibility,
  modal stack without Garage, and updated screen-flow map.
- [x] 0.3 Update relevant validators before implementation so old borrowed-cache,
  three-prose-row, `???`, text-Back, and Garage assumptions fail for the intended reasons.
- [x] 0.4 Run `tools/validation/validate_cardborne_visual_authority.ps1` after authority
  surfaces change and record that no visual asset was created or approved.

### 1. Dash-coherent threat radar

- [x] 1.1 Add a responsibility-shaped fixed-capacity threat-feed owner with two sample
  frames, 12 sector records, and an atomic generation swap.
- [x] 1.2 Change `VehicleRun._update_threat_contacts()` to fill the inactive sector frame
  at the existing cadence; remove the borrowed mutable contact-cache contract.
- [x] 1.3 Publish the current player world/screen anchor after the current camera transform
  through `VehicleStageUI` and `VehicleGameplayHud` without allocating or scanning enemies.
- [x] 1.4 Change `VehicleThreatRadar` to draw at local origin, rebase/regroup at most 12
  summaries with retained storage, and update compact geometry without recreating meshes.
- [x] 1.5 Add a deterministic dash fixture covering dash begin/mid/end, a HUD-timer phase
  mismatch, buffer reuse, sector crossings, camera smoothing, no-enemy state, and
  viewport-edge clamping.
- [x] 1.6 Inspect rendered normal/reduced-motion radar evidence at 960, 1280, and 1920
  widths and both locales; require center error <= `1 px` for the complete dash.

### 2. Ordinary Stage 2-to-5 difficulty

- [x] 2.1 Replace only `ORDINARY_HEALTH_PRESSURE` and
  `ORDINARY_DAMAGE_PRESSURE` with the locked arrays.
- [x] 2.2 Extend `validate_vehicle_run_difficulty.gd` with exact formulas for priority and
  swarm/standard examples at all five stages, including damage values and Stage 1 parity.
- [x] 2.3 Confirm encounter counts, role speeds, attack recovery, projectile speed,
  quotas, caps, player stats, and reward economy are byte-for-byte or value-for-value
  unchanged by this phase.

### 3. Boss shape and stage profile

- [x] 3.1 Add the aligned boss curves and public accessors to
  `VehicleStageDifficulty`; validate size, bounds, and monotonicity.
- [x] 3.2 Replace autonomous catch-all circle execution with explicit `area`, `lanes`,
  `beam`, and `summon` dispatch. Exercise every pattern in `AUTONOMOUS_SEQUENCES` and fail
  unknown kinds.
- [x] 3.3 Apply stage damage and coverage scalars through `VehicleBossPatterns`; remove the
  single global boss damage constant as an independent authority.
- [x] 3.4 Apply stage cadence scale through `VehicleBossRuntime` and shield-up multiplier
  through `VehicleBossShieldRuntime`; keep exposure at `1.00` for `4.0 s`.
- [x] 3.5 Increase only the startup values required by the `radius + 40` escape margin,
  including `gate_shockwave` to `1.20 s`; do not shorten any warning or recovery.
- [x] 3.6 Extend boss pattern/runtime/exam validators for effective shape, telegraph-hit
  parity, Stage 1-to-5 profile monotonicity, add/projectile/effect caps, and arena-safe
  target placement.
- [x] 3.7 Inspect all five bosses in deterministic runtime fixtures at phase 1 and later phase for startup,
  active, recovery, shield-up/exposed, autonomous/direct overlap, safe space, and actual
  map coverage.

### 4. Guidebook structure and stats

- [x] 4.1 Add `VehicleGuidebookStatAdapter` and parity tests against canonical enemy,
  attack, specialist, elite, stage, boss-pattern, boss-runtime, and shield owners.
- [x] 4.2 Change the category ID/label from `mobile` to `enemies`, preserve existing entry
  IDs, add stationary hostile entries, and move elite entries out of Field Objects.
- [x] 4.3 Replace per-entry locked rows with one non-selectable discovered/undiscovered
  summary per category, without name/preview/stat leakage.
- [x] 4.4 Rename only the visible Mystery Device name to Anomaly Device/변칙 장치 and add
  concise field-object outcome rows while preserving runtime/save IDs and behavior.
- [x] 4.5 Replace generic description and Movement/Attack/Counter rows with ordered
  stage-aware `stat_rows`; active run shows current stage and non-run shows Stage 1-to-5.
- [x] 4.6 Add the shared navigation command and replace the Guidebook text Back button with
  the accessible left-arrow command.
- [x] 4.7 Update discovery/store snapshots, Stage UI/HUD propagation, localization,
  compact/wide layout contracts, capture fixtures, and Guidebook validators.
- [x] 4.8 Inspect Korean and English at text scales `1.0`, `1.3`, and `2.0`; verify long
  stat ranges, empty/partial/full discovery, all categories, keyboard/controller focus,
  no clipping, and no horizontal overflow.

### 5. Remove Garage and close flow gaps

- [x] 5.1 Add one explicit return-to-Deployment lifecycle route and use it from Pause,
  failure report, and final result.
- [x] 5.2 Prove normal-run defeat teardown returns directly to Deployment.
- [x] 5.3 Remove Garage panel/UID, runtime mode/branch, Stage UI host, signals, Settings
  return context, localization, debug/capture surface, and manifest entry `94-garage.png`.
- [x] 5.4 Replace result/report command labels and focus contracts with one useful next
  action per the route table; preserve visible text for abandon/destructive actions.
- [x] 5.5 Prove persistent modules, unlock flags, discovery state, and save load/store are
  unchanged, then remove obsolete code rather than retaining compatibility wrappers.

### 6. Integration, quality audit, and final qualification

- [x] 6.1 Run focused owner validators after each phase and `git diff --check` after each
  coherent edit group.
- [x] 6.2 Use `codebase-quality-auditor` after the multi-file implementation; correct only
  small task-owned responsibility leaks, duplicated constants, stale public routes, or
  reachable failure paths.
- [x] 6.3 Run the consolidated gameplay/UI/localization/capture/import validators once the
  feature set is substantially complete.
- [x] 6.4 Generate deterministic Korean/English rendered evidence, compare it with the
  canonical visual authority, and inspect it at original detail. Update capture manifests
  and counts after removing Garage and replacing locked/counterplay fixtures.
- [x] 6.5 Run `tools/export_web.ps1`, then load `npjt-port-guard`, resolve the current
  fastrun `codex` lane, serve only `build/web` from a hidden task-owned process, and perform
  production-style navigation and workflow QA in the built app. Stop only that verified
  task-owned process.
- [x] 6.6 After advance notice and user alignment for the expensive final checkpoint, run
  one clean native `peak_horde` and `capacity_pressure` pair. Compare scenario validity,
  frame/physics/scheduled-enemy/grid/combat/render metrics, and allocations against the
  current clean baseline. Do not rerun without a material hot-path change.
- [x] 6.7 Commit coherent task-owned changes only. Integrate durable decisions into the
  product/design specifications, add final evidence, close lifecycle status, and remove
  the completed plan when project policy requires plan deletion.

## Test Plan

### Inner-loop validators

Run only the changed owner's focused validator while implementing:

```powershell
./tools/godot.ps1 --path . --headless --script tools/validation/validate_vehicle_run.gd
./tools/godot.ps1 --path . --headless --script tools/validation/validate_vehicle_hud_presenter.gd
./tools/godot.ps1 --path . --headless --script tools/validation/validate_vehicle_stage_ui_layout.gd
./tools/godot.ps1 --path . --headless --script tools/validation/validate_vehicle_run_difficulty.gd
./tools/godot.ps1 --path . --headless --script tools/validation/validate_vehicle_boss_patterns.gd
./tools/godot.ps1 --path . --headless --script tools/validation/validate_vehicle_boss_runtime.gd
./tools/godot.ps1 --path . --headless --script tools/validation/validate_vehicle_boss_exams.gd
./tools/godot.ps1 --path . --headless --script tools/validation/validate_vehicle_guidebook.gd
./tools/godot.ps1 --path . --headless --script tools/validation/validate_vehicle_pause.gd
./tools/godot.ps1 --path . --headless --script tools/validation/validate_vehicle_stage_report.gd
./tools/godot.ps1 --path . --headless --script tools/validation/validate_vehicle_ui_components.gd
./tools/godot.ps1 --path . --headless --script tools/validation/validate_vehicle_ui_localization.gd
./tools/godot.ps1 --path . --headless --script tools/validation/validate_vehicle_run_capture_driver.gd
git diff --check
```

If a listed validator name changes during implementation, update this plan and use the
responsibility-equivalent validator; do not silently skip the contract.

### Consolidated checkpoint

After all phases are integrated, run the relevant validator set once, not after every
small edit. Include the commands above plus:

```powershell
./tools/godot.ps1 --path . --headless --script tools/validation/validate_vehicle_attack_route_readability.gd
./tools/godot.ps1 --path . --headless --script tools/validation/validate_vehicle_enemy_contact.gd
./tools/godot.ps1 --path . --headless --script tools/validation/validate_vehicle_performance_scenarios.gd
./tools/validation/validate_cardborne_visual_authority.ps1
./tools/godot.ps1 --path . --editor --headless --quit-after 1
./tools/export_web.ps1
git diff --check
git status --short
```

Before this broader checkpoint, state its purpose, expected several-minute cost, and stop
condition to the user. Stop at the first structural failure, repair that owner, and restart
only the invalidated phase rather than rerunning every gate.

### Deterministic rendered evidence

Use the existing capture driver. Generate separate directories for locale/size/text-scale
combinations. The baseline Korean 1280 command is:

```powershell
$captureDir = Join-Path (Resolve-Path .).Path "build\captures\dash-radar-guidebook"
$godotArgs = @(
  "--rendering-method", "gl_compatibility", "--",
  "--capture-all=$captureDir", "--capture-locale=ko", "--capture-size=1280x720",
  "--layout-seed=12886704"
)
./tools/godot.ps1 @godotArgs
```

Add deterministic fixtures for dash begin/mid/end and the revised Guidebook rather than
relying on a single still image to prove motion. Required evidence includes:

- radar at rest and at three points in a dash with identical projected-player center;
- current-stage enemy stats, Stage 1-to-5 range stats, boss stats, elite modifier stats,
  field objects, partial discovery, and no `???` rows;
- Korean and English Guidebook at 960x720, 1280x720, and 1920x1080;
- text scales `1.0`, `1.3`, and `2.0` for the most constrained compact/wide surfaces;
- all five boss startup/active/recovery and representative autonomous shapes;
- final/failure/pause routes with no Garage surface or stale focus target.

Inspect captures at original detail. Exact pixel comparison may verify center stability and
clipping, but it does not approve style or playability.

### Native performance checkpoint

Run only from a clean committed tree, after the required user alignment and a check that no
unrelated task-owned runner is active:

```powershell
$perfCommit = (git rev-parse HEAD).Trim()
$env:PERFORMANCE_COMMIT = $perfCommit
$env:PERFORMANCE_DIRTY = '0'
try {
  foreach ($scenario in @('peak_horde', 'capacity_pressure')) {
    $output = "res://build/performance/dash-radar-guidebook/$($perfCommit.Substring(0,8))-$scenario-60s.json"
    ./tools/godot.ps1 --path . --rendering-method gl_compatibility `
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

Acceptance is not "60 FPS" by assertion. It requires valid fixed workloads, no new radar
actor scan, no unbounded allocation, and no material regression attributable to this task
against comparable clean evidence. Record red inherited thresholds as red.

## Validation and Rework Controls

| Cadence | Check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | changed owner's focused validator + `git diff --check` | direct behavior exists | that owner's input changes |
| Radar phase | Run, HUD presenter, Stage UI layout, dash fixture, allocation/cadence assertions | 1.1-1.5 complete | threat feed/anchor/mesh changes |
| Difficulty phase | run difficulty + exact ordinary oracle | 2.1-2.3 complete | pressure formula changes |
| Boss phase | patterns, runtime, exams, attack readability | 3.1-3.6 complete | profile/shape/timing changes |
| Guidebook phase | guidebook, components, localization, layout, capture driver | 4.1-4.8 complete | catalog/stat/UI/copy changes |
| Flow phase | pause, report/result, Stage UI, persistence, capture driver | 5.1-5.5 complete | route/lifecycle changes |
| Export gate | visual authority, import, Web export, built smoke | all feature phases and capture inspection pass | runtime/export input changes |
| Performance gate | clean native pair | final code committed and user aligned | material hot-path change |

Anti-rework rules:

- Do not tune subjective values while a structural failure remains, especially autonomous
  shape dispatch or stale radar origin.
- Do not copy combat constants into localization, panel scripts, or catalog entries.
- Do not add compatibility wrappers for Garage when no persisted/public contract needs
  them.
- Do not regenerate the full capture suite for copy-only changes; recapture only invalidated
  surfaces until the final manifest pass.
- Do not run broad validators or performance scenarios repeatedly. Use the phase gate and
  stopping condition above.
- Do not change caps, counts, cadence classes, or telegraphs to make a validator pass.

## Acceptance Criteria

- During a complete dash, the radar origin remains within `1 px` of the projected player,
  contact directions rebase from the live origin, and no mutable-generation tear occurs.
- Hostile eligibility is still scanned at `5 Hz`; render-time work is bounded to 12 sector
  summaries with retained storage and no per-frame mesh recreation.
- Stage 1 ordinary effective health and damage are unchanged. Stage 2-to-5 exact pressure
  arrays and derived values match the locked table.
- Every boss target HP, damage scalar, shield-up mitigation, cadence scalar, and coverage
  scalar matches the stage table and declared monotonic rules.
- All ten autonomous patterns retain their authored kind; lanes and beams are not circular
  denied zones, summons remain capped, and unknown kinds fail validation.
- Enlarged boss footprints retain the base-walk escape margin, visible warning/hit parity,
  projectile/effect/add caps, and meaningful safe space.
- Guidebook enemy and boss details show derived combat stats, not generic
  Movement/Attack/Counter filler. Active-run and outside-run context is explicit.
- Enemies contains all non-boss hostiles and elite modifiers. Field Objects contains no
  hostile actor or elite modifier.
- Locked content is summarized as a count and never appears as selectable `???` rows.
  Anomaly Device/변칙 장치 remains the existing Mystery Device mechanic under a clear
  display label.
- Guidebook Back is a focusable `48 x 48` left-arrow command with Korean/English accessible
  name, tooltip, input hint, Escape behavior, and no clipping at supported layouts.
- No Garage mode, panel, route, signal, localization, capture, validator expectation, or
  dead wrapper remains. Pause/failure/result/practice flows reach their intended target in
  one step.
- Persistent progression and discovery load/save remain compatible.
- Focused validators, visual-authority validation, import, Web export, built runtime QA,
  and honest final evidence complete with no task-owned helper left running.

## Rollback and Safety

- Keep commits phase-shaped: contracts, radar, ordinary/boss balance, Guidebook, Garage
  routes, and final evidence. Never stage unrelated user changes.
- Radar rollback restores the last coherent radar-feed commit, not only the panel drawing,
  so producer/consumer generation contracts cannot diverge.
- Balance rollback restores the complete aligned arrays and their oracle together. Never
  revert one boss curve without the shared stage-profile contract.
- Guidebook rollback restores catalog, adapter, localization, panel, discovery snapshot,
  and validator as one unit to avoid displaying wrong values.
- Garage removal is destructive to source files but explicitly authorized by the selected
  product decision. Preserve recovery through scoped git commits; do not delete save keys
  or user data.
- Never use hard reset, force push, broad cleanup, or process-name termination. Stop only
  verified task-owned test/browser/server PIDs.
- If the worktree becomes dirty with unrelated user changes, preserve them and commit only
  task-owned paths. Stop for direction only if ownership overlaps cannot be separated.

## Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| Live radar correction creates a new hot path | fixed 12-sector rebase, retained arrays/mesh, cadence/allocation tests, final comparable performance pair |
| Sector summaries lose exact individual regrouping after a very large dash | preserve nearest representative world positions, reaggregate the bounded summaries, add begin/mid/end and sector-crossing fixtures |
| HP plus stronger shield produces excessive boss TTK | keep exposed multiplier/time unchanged, use moderate target curves, validate deterministic boss phase timing, hand subjective TTK to user QA |
| Larger/faster attacks remove fair escape space | never shorten startup/recovery, enforce `radius + 40`, inspect warning-hit parity and overlapping direct/autonomous layers |
| Stage-wide ordinary scalar over-buffs support/priority roles | exact role examples and run-level playtest; no role-base edits in the same pass |
| Guidebook stats drift from combat | read-only adapter plus parity validators; no copied numbers in UI/catalog/localization |
| Category rename loses discovery | preserve entry IDs and test an existing schema-v1 save before/after |
| Garage removal skips teardown or focus reset | one lifecycle route, route matrix tests, normal/practice separation, no wrappers |
| Icon-only Back becomes inaccessible | 48px target, accessible name, tooltip, input hint, focus/keyboard/controller and high-text-scale tests |
| Existing red stress baseline is misreported | record workload validity and comparable deltas separately; never relabel inherited failures |

## Open Questions

No implementation-blocking product decision remains. The plan selects:

- exact current-stage stats during a run and Stage 1-to-5 ranges outside a run;
- direct Deployment routing after normal run termination;
- display-only rename to Anomaly Device/변칙 장치;
- Guidebook-only migration to the shared icon Back command.

The only post-implementation question is subjective balance: whether the locked moderate
ordinary curve and boss profile produce the desired time-to-kill, pressure, and map
coverage in the user's real play style. Automated gates establish correctness and safety;
the user playtest determines whether a later tuning-only pass is desired.

## Decision Notes

- 2026-08-11: Selected atomic sampled sector frame plus live rebase over 60Hz actor scans,
  dash-only refresh, or center-only correction.
- 2026-08-11: Kept Stage 1 ordinary balance unchanged and selected moderate Stage 2-to-5
  health/damage pressure increases.
- 2026-08-11: Selected one stage-owned boss profile and kind-correct autonomous execution;
  shape correctness precedes size tuning.
- 2026-08-11: Defined later-boss strength across multiple monotonic axes rather than
  claiming current pattern base values are already monotonic.
- 2026-08-11: Selected canonical-data Guidebook stats, an Enemies category covering mobile
  and stationary hostiles, and locked-count summaries.
- 2026-08-11: Preserved Mystery Device behavior and IDs but selected a clearer visible name.
- 2026-08-11: Selected full Garage UI/route removal while preserving progression owners.
- 2026-08-11: Limited the visible icon-Back migration to Guidebook while creating a reusable
  accessible component boundary.
- 2026-08-11: Corrected compact modal classification to use the actual viewport, because a
  wide child's minimum size can expand its host before the responsive decision runs.
- 2026-08-11: Published the Guidebook snapshot on every Deployment presentation after built-
  Web QA exposed an empty first-open catalog before the first gameplay HUD update.
- 2026-08-11: Recorded the single clean native pair at `d0822273`. Both scenarios were
  structurally valid. `capacity_pressure` was focused and authoritative but remained red at
  7.5 median FPS, matching the inherited `6af25e29` median; draw-call p95 rose from 82 to 99
  while remaining below 200. `peak_horde` lost focus during 142 samples and is therefore not
  authority evidence. All CPU subsystem medians moved together by roughly 28-39%, so the
  pair does not support attributing that timing delta to one task-owned subsystem. Per the
  performance guard, the pair was not rerun without a material hot-path change.

## Progress

- [x] Read project/product/design/performance authority and relevant runtime architecture.
- [x] Inspect the canonical style sheet at original detail and verify its expected hash.
- [x] Trace threat sampling, HUD publication, dash timing, camera timing, and radar geometry.
- [x] Trace ordinary/boss formulas, boss cadence/coverage, and autonomous kind dispatch.
- [x] Trace Guidebook catalog/UI/discovery/stat owners, locked entries, Field Objects, and
  Garage callers/persistence owners.
- [x] Compare alternatives and lock a decision-complete implementation contract.
- [x] Implement Milestones 0-5 and complete deterministic rendered inspection.
- [x] Complete import, focused/consolidated validators, Web export, and built-app smoke QA.
- [x] Complete Milestone 6 qualification and close the plan lifecycle.

## Next Steps

No implementation work remains. A user playtest can decide whether the accepted monotonic
balance curve needs a later tuning-only pass. Project policy calls for deletion of completed
plans after integration, but document deletion requires explicit user approval under the
active lifecycle steward; this plan therefore remains retained with `status: done`.
