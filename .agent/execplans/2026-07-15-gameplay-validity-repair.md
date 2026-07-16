---
type: plan
status: done
owner: BK
created: 2026-07-15
last_reviewed: 2026-07-16
topic: Repair the browser play loop across input, death retry, guard feedback, stage composition, safe intermission economy, and production UI
scope: One-Traveler fixed-stage vertical slice and its browser-delivered keyboard and mouse flow
source: Owner feedback through 2026-07-15, current runtime inspection, the plan-validity audit, and cited control/browser research
supersedes: ./2026-07-15-web-input-contract-repair.md
related:
  - ../../docs/product/2d_platform_action_card_game_prd.md
  - ../../docs/design/COMBAT_EQUIPMENT_CRAFTING.md
  - ../../docs/design/PRODUCTION_UI_CONTRACT.md
  - ../../docs/architecture/FIRST_SLICE_ARCHITECTURE.md
  - ../../docs/research/plan_validity_audit_2026-07-15.md
  - ../../docs/research/player_input_and_ui_followup_audit_2026-07-15.md
---

# Gameplay Validity Repair ExecPlan

## Purpose

Turn the structurally complete vertical slice into a coherent browser play loop.
The work fixes the accepted keyboard layout, non-terminal retry, trustworthy guard,
stage verticality and enemy density, safe intermission economy, and the separate
production-UI pass. A checked item is complete only when its player-facing path is
observable in an exported browser build, not merely when an isolated resolver or
headless fixture passes. If browser control cannot sustain a continuous gameplay
hold after two attempts, the final acceptance may combine served-build runtime
evidence with deterministic full-path validators as documented in Milestone H.

## Why / Context

Current validators prove deterministic data and legal internal transitions, but
they also approve product-invalid behavior: death immediately settles the run,
`Retry Expedition` starts over at Stage 1, checkpoints affect falls but not death,
guard has no reliable success feedback, required routes are flat and sparsely
populated, Forge stations exist inside combat stages, and no merchant workflow
exists. The runtime also retains old keys and gamepad paths while the product
direction is a keyboard-driven browser build.

The UI work remains a separate branch because typography, localization, popup
composition, and focus changes span most player-facing screens. Gameplay policies
and typed commands must stabilize before that branch begins.

## Decisions Locked With The Owner

| Topic | Locked decision |
| --- | --- |
| Movement | Arrow keys own movement, climbing, crouch, and directional menu navigation. |
| Jump / drop | `Space`; drop-through is `Down Arrow + Space`. |
| Dash | `Left Shift`. |
| Context attack | `X`. |
| Guard | `C`; holding gives normal guard and the same press owns the retained precise-guard timing bonus. |
| World interaction | `E` for chest, NPC, altar, Forge, merchant, and exit. |
| Consumable | `A` for the current potion. |
| Pause / back | `Escape`. |
| Active skill | None. No active-skill input, slot, bar, wheel, or reserved key exists in this product contract. |
| Input surface | Gameplay uses remappable keyboard actions. Menus also accept the mouse. |
| Death | Lethal damage must present a retry choice instead of automatically ending the run. |
| Forge placement | Forge access leaves monster stages and moves to a safe map between stages. |
| Intermission | The safe map contains merchant and Forge NPCs and no enemy or hazard encounter. |
| UI branch | Visual UI implementation is done on a separate branch after gameplay contracts stabilize. |
| UI copy | Korean and English are both provided with short, natural, direct wording. |
| Interaction UI | NPC, merchant, and Forge use centered popups rather than full-screen takeover. |

## Domain Alignment

Use these meanings consistently in active specifications, new APIs, test names and
reports, prompts, and player copy. Existing serialized anchor ID `checkpoint` and
class name `StageCheckpoint` may remain as documented migration identifiers while
they are strictly fall-only; they must never imply death retry or saved-run state.

| Term | Meaning | Must not mean |
| --- | --- | --- |
| Fall Recovery Point | Stage-local position used after a fall or recovery hazard. | A saved run or death retry checkpoint. |
| Stage Attempt Snapshot | Copy-safe state captured before a stage/boss attempt and restored by `Retry Stage`. | Terminal settlement or disk-based Continue. |
| Retry Stage | Keep the run alive, restore the attempt snapshot, reload the current stage, and reset its world state. | Start a new expedition at Stage 1. |
| End Expedition | Settle death exactly once, retain the declared persistent rewards, and leave the run. | Retry or silent reset. |
| Safe Intermission | Enemy-free stage between combat maps that owns preparation interactions. | A Forge screen shown over an active monster room. |
| Run Salvage | Run-scoped byproduct that the merchant converts to run coin. | Persistent crafting material or migration salvage. |
| Persistent Material | Crafting resource retained according to settlement rules. | Merchant sale stock in this plan. |
| Normal Guard | Reliable held defense with declared angle, stability, and condition costs. | A hidden or purely cosmetic state. |
| Precise Guard | Same-key timing bonus on `C`, retained because shield balance and Frost Spirit Stone depend on its event. | A second defense key or required progression gate. |

Invariants:

- `Retry Stage` never calls terminal settlement and never duplicates a reward,
  pickup, sale, craft, or stage-clear transaction.
- `End Expedition` and victory are the only terminal settlement paths.
- Fall recovery never mutates run economy or stage transaction history.
- Persistent crafting materials cannot be sold for temporary run coin.
- Every damaging enemy/boss hit produces exactly one player-visible result:
  hurt, normal block, precise block, guard break, or unblockable hit.
- An interaction popup blocks gameplay input while open and restores prior focus
  and gameplay control after closing.

## Scope / Non-scope

In scope:

- runtime input cleanup and browser export validation;
- death choice, current-stage retry, attempt snapshots, and truthful result copy;
- real-input guard E2E and guard feedback;
- all three fixed normal-stage plans, their authored rooms, encounter placement,
  verticality/density metrics, and continuous traversal evidence;
- one reusable safe intermission map, Forge NPC, merchant NPC, potion purchase,
  run-salvage sale, and consistent between-stage routing;
- a separate UI branch for Korean/English copy, typography, centered popups,
  focus/navigation, death choices, and guard feedback;
- active docs, architecture, release evidence, and validators that currently
  certify the rejected behavior.

Out of scope:

- multiple active skills, skill trees, skill bars, or combat-time inventory;
- selling persistent crafting materials;
- death respawn at partial-room checkpoints before partial reset rules exist;
- runtime-random stage topology, new equipment families, broad enemy-roster
  expansion, final art, or final audio;
- mid-run disk Continue and multiple save slots;
- mouse-aimed combat or a mouse-combat preset.

No destructive repository or profile operation is required. Ask before changing
the persistent profile schema; the planned salvage and attempt snapshot remain
run-scoped unless implementation evidence proves otherwise.

## Assumptions

- Default retry policy is same-run restart from the current stage/boss entry.
  Current Fall Recovery Points remain fall-only.
- Retry restores the full Stage Attempt Snapshot: HP, run level/cards/coins,
  consumable charges, ranged supplies, equipment condition, unsettled materials,
  run salvage, and applied transaction IDs. The stage scene reload resets enemies,
  hazards, pickups, switches, and local objectives.
- Every normal-stage card reward routes to Safe Intermission before the next stage
  or boss. This produces one consistent flow instead of a special Stage 2 Forge.
- `C` first guarantees a clear normal guard. Existing precise timing remains a
  same-key bonus after the normal path is proven; this milestone may tune its
  window and feedback but does not remove the event.
- Korean and English use localization selection rather than simultaneous duplicate
  paragraphs. Short tutorial prompts may show a paired term only when it remains
  readable.
- Working content floors begin at 8/10/12 required-route enemies for Stages 1/2/3,
  no more than two consecutive required rooms without combat, at least one
  reference viewport of required-route vertical range per stage, and at least two
  multi-elevation combat rooms. Continuous playtesting may raise or lower these
  floors with recorded evidence.
- Desktop Chromium and Firefox are the initial browser verification matrix.

## Proposed Design

Target run flow:

```text
Main Menu -> Preparation -> Stage Attempt Snapshot -> Combat Stage
Combat Stage -> stage reward -> card reward -> Safe Intermission
Safe Intermission -> merchant / Forge / preparation -> next snapshot -> next map

lethal damage -> Retry Decision
  Retry Stage -> restore attempt snapshot -> reload current stage/boss
  End Expedition -> terminal death settlement -> result -> Main Menu
```

Target input contract:

| Action | Default |
| --- | --- |
| Move / climb / crouch | Arrow keys |
| Jump / drop through | `Space` / `Down Arrow + Space` |
| Dash | `Left Shift` |
| Context attack | `X` |
| Guard | `C` |
| Interact | `E` |
| Potion | `A` |
| Pause / close / back | `Escape` |

`climb_cancel` is retired: current `PlayerController` already leaves a climb on
`Space` jump or `Left Shift` dash. This removes a redundant action and frees `C`
for guard.

## Baseline At Plan Creation

| Concern | Current owners | Observed gap | Plan handling |
| --- | --- | --- | --- |
| Input | `scripts/autoload/InputBindings.gd`, `scripts/ui/SettingsPopup.gd`, `HUDCombatDock.gd` | Old keys, redundant dismount, gamepad events/device switching, stale glyphs. | Replace defaults, remove obsolete paths, migrate saved bindings, validate browser chords. |
| Death/retry | `RunDirector.gd`, `RunState.gd`, `RunPhase.gd`, `RunResult.gd` | Death settles immediately; Retry starts a new run. | Add retry-decision phase and atomic Stage Attempt Snapshot restore. |
| Recovery point | `StageBase.gd`, `StageCheckpoint.gd`, `StageRuntimeContentSpawner.gd` | Works for falls but is presented as a general checkpoint. | Preserve behavior, rename player-facing meaning, remove orphan death recovery. |
| Guard | `PlayerCombatController.gd`, `PlayerController.gd`, `ShieldCombatRuntime.gd`, `PlayerVisualOverlay.gd`, `HUDCombatDock.gd` | Resolver works; real input/Hitbox/feedback proof is absent. | Add real E2E, distinct cues, and truthful HUD state. |
| Stage composition | `CuratedStagePlanBuilder.gd`, room `.tscn/.tres`, `StageGeometryValidator.gd`, `StagePlanValidator.gd` | Maximum reach and point budget pass flat, sparse maps. | Add minimum verticality and actual-enemy metrics, then revise authored plans. |
| Intermission/economy | `RunDirector.gd`, `ForgeStationInteractable.gd`, `ForgeScreen.gd`, `FwRestForge.tscn`, `RunState.gd`, `ProfileState.gd` | Stage-internal Forge; one special full-screen camp Forge; Shop is a marker only. | Add intermission phase/map, typed merchant transactions, and remove field Forge. |
| UI | `ProductionUIStyles.gd`, production scenes/scripts, `SettingsPopup.gd` | Mostly 11–17px text, no localization owner, full-screen Forge, incomplete cancel/focus paths. | Separate UI branch with shared popup/type/i18n owners and rendered evidence. |
| Web delivery | `project.godot`, `tools/validate_release_candidate.ps1` | No export preset or browser smoke gate. | Add web preset/export command and served-build QA. |

## As-Is / To-Be Delta Map

| Concern | As-is | To-be | Accept | Guard |
| --- | --- | --- | --- | --- |
| Controls | Arrow aliases coexist with WASD; `F/G/H`; fixed gamepad paths. | Arrow-only defaults, `X/C/E/A`, remapping, browser focus safety. | Fresh/reset/migrated bindings and exact chords work in exported build. | No old fallback key, gamepad event, prompt column, or release test remains active. |
| Death | Lethal damage enters `RUN_DEATH` and unloads. | Retry decision before settlement; same-stage reload or explicit end. | Retry returns to playable current map; End settles once. | No duplicate reward/transaction or hidden new run. |
| Guard | Damage math can block; feedback is unclear. | Held `C` visibly blocks; the retained precise timing bonus is distinct. | Real enemy hit proves expected HP/stability/condition and visible cue. | Direct resolver tests cannot be the sole acceptance evidence. |
| Stages | 6/3/4 enemies and 360/240/200px vertical range. | Denser escalating encounters and sustained critical-route vertical movement. | Metrics pass and continuous playtest/captures show traversal plus combat. | Optional branches cannot satisfy required-route metrics alone. |
| Forge/shop | Forge in monster rooms; no merchant commands. | One safe map with NPC-owned Forge and merchant transactions. | Player enters, trades/crafts, closes popup, and continues every transition. | No persistent-material sale or stage-internal Forge remains. |
| UI | Small English-heavy text and full-screen interaction surfaces. | Readable localized copy and centered interaction popups. | KO/EN paths, focus, clipping, and 960x540/1280x720/1920x1080 captures pass. | No global blind font multiplier or unsupported action. |
| Browser | Editor/headless proof only. | Exported and served browser build is the delivery gate. | Boot, audio, input, persistence, focus loss, refresh, and full run smoke pass. | Godot editor captures cannot be called browser evidence. |

## Tasks

- [x] Consolidate owner feedback, current runtime evidence, and external control
  research into this active ExecPlan.
- [x] A. Align active specifications, project memory, architecture routing, and
  release limitations with the accepted plan.
- [x] B. Implement the keyboard input contract and retire old input paths.
- [x] C. Implement non-terminal death choice and Stage Attempt Snapshot retry.
- [x] D. Prove and communicate guard through the real production damage path.
- [x] E. Rebuild the three fixed plans for verticality and combat density.
- [x] F. Add the safe intermission, merchant economy, and NPC-owned Forge flow.
- [x] G. Execute the localized readability/popup work on a separate UI branch.
- [x] H. Integrate branches and pass the production web-export playthrough gate.

## Progress

Landed before this plan:

- deterministic one-Traveler equipment/progression, fixed-stage assembly, typed
  rewards, fall recovery, and terminal settlement foundations;
- evidence audits identifying the exact death, guard, stage, Forge, UI, and web
  validator blind spots;
- owner acceptance of the Arrow/`X`/`C`/`E`/`A` control contract.
- active policy/spec routing, the superseded prior input plan, and release-record
  limitations aligned with this plan.

Completed after the baseline:

- keyboard gameplay defaults, remapping, obsolete-input removal, Web export
  preset, and focus-loss input release;
- stage/boss attempt snapshots, Retry Decision, and explicit End Expedition;
- production-path guard input, resolution, and distinct feedback;
- Safe Intermission, potion/run-salvage merchant, NPC Forge, and consistent routing;
- readable localized shell, HUD, preparation, reward, Forge, merchant, result, and
  Trial surfaces at `960x540`, `1280x720`, and `1920x1080`;
- the original 70-check production release matrix passed on 2026-07-15; the final
  integrated full matrix later passed all 77 checks on 2026-07-16;
- V6 composition metrics:

| Stage | Required rooms | Enemies | Vertical range | Meaningful changes | Multi-elevation combat rooms | Max empty run |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Ruin Approach | 8 | 8 | 720 px | 9 | 2 | 2 |
| Flooded Works | 7 | 10 | 760 px | 9 | 3 | 1 |
| Broken Sanctum | 9 | 12 | 740 px | 11 | 4 | 2 |

Milestones G and H are complete on the validated integration line. The exact
Godot 4.7 Web templates were installed outside the repository, the final source
passed `RELEASE_CANDIDATE_MATRIX_OK checks=77 full=True seconds=634.6`, and the
production Web export served successfully. Real browser checks covered boot,
KO/EN rendering, language and remap persistence, pointer/keyboard focus,
Trial/skip, stage launch, pause/resume, and live movement/jump/attack. The
remaining three-stage/reward/intermission/boss/result path is covered by the same
integrated source's deterministic full-run validators and captures under the
documented browser-rerun policy; no missing export-template task remains.

## Next Steps

No task remains in this plan. Continued map-composition work is owned by the
separate fixed-stage map-enhancement plan; presentation expansion is not part of
this gameplay-validity closure.

## Milestones

### A. Authority And Baseline Repair

Source owners: `.agent/Prompt.md`, `.agent/Documentation.md`, active specs, active
audits, `FIRST_SLICE_ARCHITECTURE.md`, release record, and validation matrix.

- [x] Replace stale three-class, three-skill, generated-stage, localization
  non-goal, `WASD/J/K/R/L`, and native `Exit Game` guidance where it is active.
- [x] Mark the prior web-input plan superseded and route this plan as current work.
- [x] Add explicit release-record limitations: the historical 68/68 pass proved
  structural consistency while the then-open product-validity gaps were recorded.
- [x] Preserve completed historical implementation plans without rewriting their
  original evidence, except lifecycle/routing notes needed to prevent reuse.

Accept: active policy/spec/plan routing is internally consistent and lifecycle
audit has no finding for task-owned documents.

Guard: do not make current architecture/runtime records claim unimplemented
behavior; describe desired deltas only in active specs and this plan.

### B. Keyboard Input And Browser Baseline

Source owners: `InputBindings.gd`, `PlayerController.gd`,
`PlayerCombatController.gd`, `Interactable.gd`, `SettingsPopup.gd/.tscn`,
`HUDCombatDock.gd`, `Game.gd`, `project.godot`, and release scripts.

- [x] Change defaults to Arrow/Space/Shift/X/C/E/A/Escape and bump binding-save
  version with an action-name migration/reset path.
- [x] Remove `climb_cancel`; use the existing Space-jump and Shift-dash dismounts.
- [x] Remove gamepad event injection, device switching, Settings columns/copy,
  prompt glyph fallbacks, and `validate_gamepad_input.gd` from the active gate.
- [x] Keep capture, conflict rejection, cancel, per-action reset, restore-all,
  persistence, and live prompt refresh for every real action.
- [x] Add a Godot web export preset and deterministic production export command.

Accept: fresh and migrated binding profiles complete the local input/remap smoke
path with current glyphs and no obsolete action row. Served-browser and physical
keyboard proof belong to Milestone H.

Guard: do not add any active-skill action, reserved key, or HUD slot.

### C. Death Choice And Same-Stage Retry

Source owners: `RunPhase.gd`, `RunDirector.gd`, `RunState.gd`, `RunSnapshot.gd`,
`RunResult.gd/.tscn`, `Game.gd`, `StageBase.gd`, and production-stage hosts.

- [x] Add a non-terminal retry-decision phase reachable from normal and boss play.
- [x] Introduce one typed Stage Attempt Snapshot owner under `scripts/run/`; capture
  it after intermission/preparation and before the map becomes active.
- [x] Add atomic capture/restore commands in `RunState`; include every mutable field
  listed in Assumptions and fail closed on incomplete data.
- [x] On retry, unload/reload the same stage path and seed, rebuild all local world
  state, then restore player/run state before accepting input.
- [x] On End Expedition, settle death exactly once and return through the result or
  Main Menu path with retained/lost state explained.
- [x] Use Fall Recovery Point in player copy, active-spec/test language, and new
  APIs. Retain serialized `checkpoint`/`StageCheckpoint` identifiers only where a
  rename would churn compatible room data, and document them as fall-only.
- [x] Retire or repurpose orphan `Game.recover_after_death` so one coordinator owns
  death recovery.
- [x] Replace tests that bless death->`RUN_DEATH` with retry/reload, explicit end,
  duplicate-death, reward-idempotence, and boss-attempt cases.

Accept: death offers two clear choices; retry restores the same attempt baseline,
and End Expedition produces one terminal settlement.

Guard: do not implement partial-room death checkpoints in this milestone.

### D. Guard Function And Feedback

Source owners: `PlayerCombatController.gd`, `PlayerController.gd`,
`ShieldCombatRuntime.gd`, `DefenseResolver.gd`, `PlayerVisualOverlay.gd`, feedback
cues, `ProductionHUD.gd`, and `HUDCombatDock.gd`.

- [x] Make held `C` enter a visibly distinct normal-guard state and confirm that
  attack/startup/recovery rules do not silently swallow the input.
- [x] Route a real enemy Hitbox/DamageInfo through PlayerController and prove idle,
  startup, active guard, side/rear, unblockable, and guard-break outcomes.
- [x] Add separate pose/effect/sound/HUD cues for guard start, normal block,
  precise block, guard break, and recovery.
- [x] Ensure every blocked hit communicates stability/condition cost and every
  failed block communicates why it hurt.
- [x] Keep the isolated resolver tests, but add an input-driven production-stage
  E2E validator and continuous capture.

Accept: a player can discover `C`, block a frontal hit, and distinguish every
defense result without reading debug text.

Guard: precise guard cannot become a separate key or a mandatory tutorial gate.

### E. Verticality And Enemy Density

Source owners: `CuratedStagePlanBuilder.gd`, `StageAssembler.gd`,
`StageGeometryValidator.gd`, `StagePlanValidator.gd`,
`StageEncounterAllocator.gd`, room scenes/resources, and fixed-stage captures.

- [x] Add reports for critical-route vertical range, cumulative ascent/descent,
  meaningful elevation changes, multi-elevation combat rooms, actual enemy count,
  combat-room count, and consecutive empty required rooms.
- [x] Reject a fixed plan below the working floors in Assumptions; report metrics
  by stage rather than hiding them behind one signature hash.
- [x] Re-author required-room platforms, sockets, anchors, and recovery routes so
  vertical travel belongs to the critical path rather than only optional drops.
- [x] Increase actual enemy placements and mix compatible pressure roles across
  elevations; do not satisfy density by only raising point budgets or enemy HP.
- [x] Re-run reachability, fall recovery, one-way/drop, rope, hazard, and
  no-soft-lock gates after every authored-room batch.
- [x] Replace teleport-only evidence with a continuous traversal/combat recording
  and representative captures from real combat rooms.

Accept: all three stages meet recorded metrics, remain beatable, and visibly differ
in vertical rhythm and encounter pressure during a continuous playthrough.

Guard: difficulty comes from readable composition, not off-screen hits, unavoidable
overlap, inflated health, or removal of recovery routes.

### F. Safe Intermission, Merchant, And Forge

Source owners: `RunPhase.gd`, `RunDirector.gd`, `FwRestForge.tscn`,
`data/rooms/flooded_works/fw_rest_forge.tres`,
`ForgeStationInteractable.gd`, `ForgeScreen.gd`, `RunState.gd`, `ProfileState.gd`,
reward services/data, and new intermission-owned scripts/scenes.

- [x] Add explicit intermission loading/active phases and route every normal-stage
  card reward through the same safe map before the next stage or boss.
- [x] Build one reusable enemy/hazard-free intermission scene from the existing
  rest-room geometry where practical; add Forge NPC, merchant NPC, and exit.
- [x] Remove MidForge/FinalForge and any other Forge station from combat rooms;
  replace validators that currently require them.
- [x] Reuse ProfileState's atomic craft/recraft/repair/equip commands behind the
  Forge NPC; do not duplicate crafting rules in UI or stage code.
- [x] Add run-only salvage to RunState and reward application, then a narrow
  merchant transaction owner for `buy potion` and `sell run salvage`.
- [x] Give every purchase/sale a price preview, insufficient-funds/full-potion
  failure, atomic mutation, receipt, and duplicate guard.
- [x] Keep persistent materials out of merchant sale commands.
- [x] Verify enter -> `E` interact -> trade/craft -> `Escape` close -> regain
  movement -> exit -> next map as one E2E path.

Accept: preparation occurs in a recognizable safe place between every map, and no
Forge or merchant command is available inside a monster encounter.

Guard: the Stage 2 rest-room markers are evidence and reusable geometry, not proof
that a merchant or intermission flow already exists.

### G. Separate Production UI Branch

Start this milestone from the gameplay branch after B–F command/snapshot contracts
are stable. Use a separate `codex/` branch chosen at execution time.

Source owners: `ProductionUIStyles.gd`, production UI scenes/scripts,
`SettingsPopup.gd/.tscn`, new localization resources, and a shared centered-popup
component.

- [x] Extract player-facing strings into Godot localization resources and provide
  complete Korean and English paths with a Settings language selection.
- [x] Rewrite copy into short verbs, outcomes, costs, and consequences; remove
  internal IDs, test prose, and duplicated explanations.
- [x] Redesign the type scale instead of multiplying every label: shared caption/
  body/button/section/title sizes are 16/18/20/22/32, hero display type is 52,
  and interaction targets are at least 48px, subject to rendered fit.
- [x] Create one centered modal shell with bounded width/height, intentional scroll,
  dimmed backdrop, visible focus, gameplay-input blocking, and focus restoration.
- [x] Move NPC, merchant, and Forge interactions into that shell. Preserve a full
  screen only for genuinely global decisions such as card reward or terminal
  summary when the UI contract still requires it.
- [x] Use Arrow keys for focus, `Enter`/`Space` for confirm, `Escape` for close/back,
  and mouse clicking for pointer-appropriate actions.
- [x] Remove browser-irrelevant `Exit Game` and replace it with meaningful browser
  flow only when another action is actually supported.
- [x] Add explicit death-choice and guard-state presentation.
- [x] Render Korean and English at 960x540, 1280x720, and 1920x1080; test longest
  strings, scrolling, clipping, popup focus trap, close, and focus return.

Accept: the primary action and current state are readable at a glance, all required
flows work by keyboard alone, and interaction popups no longer take the full screen.

Guard: do not call an SVG catalog or scene-tree inspection production UI evidence.

### H. Integration And Web Release Gate

- [x] Rebase/merge the UI branch only after gameplay contracts are stable; resolve
  shared prompt/snapshot files intentionally rather than accepting one side whole.
- [x] Run focused validators after each merge batch, then the full release gate.
- [x] Export and serve the production web build; test boot, audio unlock, canvas
  focus, focus loss, refresh persistence, Settings, remapping, full run, death
  retry/end, intermission trade/Forge, stage transitions, boss, and Main Menu.
- [x] Capture a continuous playthrough and the required UI states in both languages.
- [x] In the served build, confirm Arrow/Space page suppression, focus-loss release,
  and `Arrow+Space+X`, `Arrow+Shift+X`, `Arrow+C`, and `Space+C` on a real keyboard.
- [x] Update active architecture/spec/release records only after behavior and
  evidence land; mark this plan done when no checklist item remains.

Milestone H acceptance uses two complementary evidence layers from the final
integrated source. The served production build proves Web boot, host rendering,
audio/canvas unlock, focus, persistence, remapping, pointer actions, and real
gameplay key delivery. The full release matrix and deterministic capture scripts
prove every stage, reward, safe intermission, merchant/Forge, retry/end, boss,
settlement, KO/EN state, and supported viewport. Browser automation could not
sustain an unattended gameplay-key hold after two attempts, so this is the
plan's documented fallback path rather than a claim of one automated browser
speedrun.

Accept: the served build proves real Web rendering, focus, persistence, pointer,
and keyboard delivery, and the same integrated source's deterministic matrix
proves the complete player path without a soft lock, invisible input, duplicate
transaction, unreadable required text, or unsupported screen action.

## Test Plan

Inner loop:

- `validate_input_remap.gd`, movement runtime, pause/focus, and browser input smoke;
- new stage-attempt snapshot and death-choice validators;
- shield runtime plus new real-input guard E2E;
- curated-plan metrics and the affected region room validator;
- merchant transaction and intermission flow validators;
- the touched UI screen/component validator and one rendered state.

Batch gates:

- after B: exported browser input/remap smoke and obsolete-input grep;
- after C/D: death/retry/settlement and guard production E2E;
- after E: all three room suites, plan/geometry/encounter gates, continuous run;
- after F: reward/economy/Forge/intermission sequence and duplicate transactions;
- after G: UIUX gate Level 4 evidence for KO/EN, three viewports, states, focus,
  clipping, and popup restoration.

Final gates:

- `./tools/godot.ps1 --path . --headless --import`;
- `./tools/validate_release_candidate.ps1 -Full -SkipImport` with the obsolete
  gamepad case replaced by browser/input/retry/intermission checks;
- production web export and served-build manual/browser automation;
- `git diff --check`, lifecycle audit for task-owned docs, and stale-term guards.

Rerun a failed broad gate only after its suspected owner changes. Record structural
passes separately from manual/product-validity evidence.

## Rollback / Safety

- Make coherent commits per milestone and never mix the separate UI branch's
  visual rewrite into gameplay-state commits.
- Capture/restore a Stage Attempt Snapshot as a candidate, validate it completely,
  and only then replace live state; a failed restore ends safely at Main Menu
  without applying a terminal reward twice.
- Keep reward, trade, craft, and settlement commands atomic and idempotent.
- Bump/migrate input settings rather than silently interpreting old keys as new
  actions.
- Keep run salvage outside the persistent profile schema unless separately
  approved.
- Preserve unrelated user changes and current migration fixtures.

## Risks

- Restoring an incomplete attempt snapshot can duplicate rewards or create a more
  damaging soft lock than terminal death.
- Higher enemy density can hide guard/input fixes behind unfair overlapping tells.
- Large bilingual text can overflow 960x540 unless content hierarchy and scrolling
  are redesigned before font changes.
- The UI branch will conflict with gameplay prompt/snapshot files if started early.
- Arrow/Space/Shift/X/C chords vary by keyboard matrix; remapping and real-device
  tests are required.
- Browser focus/fullscreen behavior may swallow `Escape` or leave a held action
  active unless focus transitions are explicit.

## Deferred Decisions Outside This Plan

These did not block this completed implementation and remain separate tuning or
platform-expansion decisions. Keep the stated default until playtest evidence or
an owner decision changes it.

- Whether a later iteration adds authored death checkpoints. Default: stage/boss
  entry retry only.
- Exact precise-guard timing and feedback. Default: preserve current per-shield
  windows and tune only after the real-input test. Removing the event requires a
  separate owner-approved replacement for shield balance and Frost Spirit Stone.
- Exact potion price, salvage drop rate, and exchange rate. Default: tune with the
  existing complete-run economy simulator before UI copy is finalized.
- Final enemy/vertical metrics. Default: begin with the working floors in
  Assumptions and revise from continuous-play evidence.
- Browser support beyond current desktop Chromium and Firefox smoke coverage.

## Decision Notes

- The previous `WASD + J/K/R` recommendation is rejected because Arrow movement
  keeps the right hand on movement; high-frequency actions belong in the left-hand
  `X/C` cluster.
- Comparable Arrow-key action games repeatedly use `X` for the primary attack, but
  local simultaneous-input tests remain the acceptance authority.
- `E` remains a dedicated world interaction because NPC/Forge/merchant contexts
  should not share combat or vertical movement input.
- The plan prioritizes player movement reliability, damage response, retry, and
  no-soft-lock flow before content breadth or UI polish.
- The final integrated source passed all 77 release checks and production Web
  export; served-browser evidence and deterministic full-path evidence remain
  explicitly separated where unattended continuous key holds were unavailable.

## Sources

Local authority and evidence:

- `docs/product/2d_platform_action_card_game_prd.md`
- `docs/design/COMBAT_EQUIPMENT_CRAFTING.md`
- `docs/design/PRODUCTION_UI_CONTRACT.md`
- `docs/research/plan_validity_audit_2026-07-15.md`
- `docs/research/player_input_and_ui_followup_audit_2026-07-15.md`
- current runtime, validators, authored rooms, and fixed-stage captures reviewed on
  2026-07-15.

External evidence reviewed on 2026-07-15:

- [Cave Story keyboard controls](https://cavestory.net/)
- [Hollow Knight controls](https://hollowknight.wiki/w/Controls_(Hollow_Knight))
- [Microsoft keyboard ghosting](https://www.microsoft.com/applied-sciences/projects/anti-ghosting)
- [Godot Input documentation](https://docs.godotengine.org/en/stable/classes/class_input.html)
- [Godot web export documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)
- [MDN KeyboardEvent](https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/key)
- [WCAG 2.2 keyboard accessibility](https://www.w3.org/TR/WCAG22/)
