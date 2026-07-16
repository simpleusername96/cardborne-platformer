---
type: plan
status: proposed
owner: BK
created: 2026-07-16
last_reviewed: 2026-07-16
topic: Convert the structurally complete Cardborne vertical slice into a tested Core Play Proof centered on movement, combat agency, build expression, authored exploration, and boss culmination
scope: Development instrumentation, movement and input, combat ownership and experiments, enemy interaction states, first-run cards and equipment identities, one proof stage, Giant Slime King, gameplay communication, one final-enough presentation slice, and gated procedural re-entry
source: Repository gameplay audit, current production code and specifications, release evidence, owner goals, and cross-genre developer research
related:
  - ../../docs/audits/cardborne_gameplay_experience_audit_2026-07-16.md
  - ../../docs/design/CORE_PLAY_FOUNDATIONS.md
  - ../../docs/product/2d_platform_action_card_game_prd.md
  - ../../docs/design/COMBAT_EQUIPMENT_CRAFTING.md
  - ../../docs/design/ENEMIES_TRAPS_GIMMICKS.md
  - ../../docs/design/2D_PLATFORMER_MAP_DESIGN_GUIDELINE.md
  - ../../docs/design/PROCEDURAL_REGION_GENERATION.md
  - ../../docs/architecture/FIRST_SLICE_ARCHITECTURE.md
---

# Core Play Experience Roadmap

## Purpose

Cardborne already has a structurally complete fixed run and unusually strong correctness contracts. This plan redirects the next development cycle from breadth to **Core Play Proof**: an eight-to-ten minute authored stage, three recognizable build approaches, and one boss that are enjoyable enough to make players voluntarily restart.

The plan uses the existing systems as a safety net. It does not replace run/profile/reward ownership, deterministic Stage Plans, authored rooms, or exactly-once persistence. It adds the experience evidence those systems currently lack.

Every implementation pull request must answer five questions:

1. What player experience is expected to change?
2. What is the smallest implementation that can test the hypothesis?
3. What fixture or automated check protects correctness?
4. What human observation decides whether the change is successful?
5. How can the change be disabled or reverted without invalidating saves and the existing fixed run?

## Completion definition

This plan is complete only when:

- keyboard and gamepad players can complete the proof path;
- movement-only play reaches the acceptance gates in `CORE_PLAY_FOUNDATIONS.md`;
- the selected attack-intent scheme is predictable and does not spend ammunition accidentally;
- Exposed, Breach, and Interruptible are readable in ordinary combat;
- Pursuit, Counter, and Control are recognizable from behavior;
- Ruin Approach is remembered as a route and place after one blind run;
- Giant Slime King tests learned verbs and gives every build a meaningful conversion;
- one final-enough world/audio/animation slice proves the target readability and production cost;
- the majority of target testers voluntarily restart or choose a different build/route for a gameplay reason;
- the project records a go/no-go decision for broader content and procedural variation.

A passing automated release matrix is necessary but not sufficient.

## Decisions already locked

| Topic | Decision |
| --- | --- |
| Product scope | One Traveler, no class selection or active-skill bar. |
| Content strategy | Improve interaction depth before adding enemies, stages, equipment families, currencies, or bosses. |
| Map strategy | Preserve authored room templates and fixed benchmark topology during Core Play Proof. |
| Generation | Keep runtime random topology dormant until the human Core Play Proof gates pass. |
| Build philosophy | Cards and model identities change behavior; run-level upgrades remain small maintenance choices. |
| Difficulty | Increase pressure through learned combinations, space, timing, and priority—not hidden information or health inflation. |
| Architecture | Use incremental extraction around stable interfaces; do not rewrite run/profile/reward ownership. |
| Evidence | Every behavioral PR includes deterministic fixtures and recorded continuous play evidence. |
| Delivery | Changes land as small draft PRs in the order below; later PRs do not absorb a failed earlier hypothesis. |

## Decisions deliberately left experimental

| Question | Experiment |
| --- | --- |
| Should one attack button remain contextual? | Compare forecasted contextual attack against tap-melee/hold-ranged in identical fixtures. |
| Does equipment condition improve the expedition? | Disable it during initial proof tests; re-enable only after a measured route/purchase/tool decision appears. |
| Which buffer and corner-correction values feel best? | Start with conservative values in the foundation spec and tune from failure traces. |
| How much combat text should remain? | Keep training labels in the Trial; compare ordinary combat with semantic visual/audio feedback only. |
| Does Safe Intermission belong in the short proof path? | Include only when one choice materially changes the boss plan. |

## Branch and pull-request policy

- Start every implementation PR from the latest accepted `master`.
- Use `agent/core-play-<scope>` branches.
- Default every PR to draft until automated checks and the PR-specific human gate are recorded.
- One PR owns one primary player-facing hypothesis. Mechanical prerequisite refactors may be separate PRs with no behavior delta.
- Feature flags or development settings isolate experiments from the production default until selected.
- Profile schema changes require explicit approval and migration fixtures. None are expected before the build pass proves a need.
- Do not mix final art for later stages into mechanics PRs.
- Each PR description records: hypothesis, changed owners, player path, test fixture, rendered/recorded evidence, result, retained limitations, and rollback switch.

## Evidence package shared by all PRs

Create a development-only evidence root outside committed player saves. Each test session produces:

```text
session metadata
input-device and build configuration
room/event timeline
forecasted and committed attack intents
damage and enemy-state events
route/reward decisions
retry and boss-pattern history
short observer notes
player answers to the required questions
```

Committed repository artifacts contain schemas, fixtures, summary tables, and representative captures only. Raw personal playtest data and large recordings stay outside source control.

## Pull-request sequence

## PR 0 — Audit, foundations, and roadmap

**Branch:** `agent/cardborne-gameplay-experience-audit`

**Purpose:** Establish the diagnosis, target experience, acceptance gates, and safe implementation order before runtime changes begin.

**Files:**

- `docs/audits/cardborne_gameplay_experience_audit_2026-07-16.md`
- `docs/design/CORE_PLAY_FOUNDATIONS.md`
- this ExecPlan
- `docs/README.md` index links

**Expected result:** Reviewers can agree or disagree with explicit product hypotheses instead of debating disconnected feature requests.

**Validation:**

- all referenced active repository paths resolve;
- links and terminology align with current one-Traveler/fixed-stage architecture;
- no runtime, resource, save, or release behavior changes.

**Gate:** Owner accepts the Core Play Proof scope and the fact that content expansion and procedural topology remain blocked by human experience evidence.

## PR 1 — Playtest recorder and baseline fixtures

**Branch:** `agent/core-play-observability`

**Primary hypothesis:** The project can diagnose dullness and control failures more reliably when a complete exchange and route timeline is reviewable.

**Small implementation:**

- add a development-only `PlaytestRecorder` and stable event schema;
- add one movement dojo and one combat dojo scene using current production actors;
- record room entry/exit, commands, buffers, intents, hits, damage, enemy states, route commitments, rewards, deaths, and boss patterns;
- add a local summary tool that reports action mix, unexplained damage candidates, decision gaps, and encounter duration;
- capture the current baseline before changing mechanics.

**Likely owners:**

- new `scripts/playtest/` responsibility;
- narrow signals from `PlayerController`, `PlayerCombatController`, enemy actors, `ProductionStageHost`, `RunState`, and boss actor;
- `tools/` summary/validation entry point;
- new test-only scenes under `scenes/testbeds/core_play/`.

**Do not:**

- upload analytics;
- change combat values;
- make recorder failures affect gameplay;
- store raw recordings in profile saves.

**Automated acceptance:**

- recorder disabled by default in production/export configuration;
- identical deterministic fixture inputs yield stable event ordering;
- recorder failure cannot block run state, rewards, save, or scene transition;
- current Full release matrix remains green.

**Human gate:** A reviewer can reconstruct one damage event, one attack-intent decision, one route choice, and one retry from the timeline without reading gameplay code.

## PR 2 — Combat seam extraction with zero intended behavior delta

**Branch:** `agent/core-play-combat-seams`

**Primary hypothesis:** Combat experiments can be implemented safely only after the 2,348-line production controller exposes narrow owners.

**Small implementation:** Extract interfaces and delegate in place:

- `PlayerCombatInput`: command collection and one-command buffers;
- `AttackIntentService`: target snapshot, line of sight, forecast, and retention;
- `AttackExecutor`: startup/active/recovery, cancellation, hitbox, and projectile dispatch;
- `PlayerDefenseController`: guard phases, stability, and defense results;
- `CombatLoadoutRuntime`: stage-local condition, supply, shield, and Spirit state;
- `PlayerCombatFeedbackBridge`: immutable UI/presentation snapshots and semantic cues;
- `LegacyCombatAdapter`: historical class/skill fixture path outside production flow.

The existing `PlayerCombatController` may remain as an orchestrator during the transition.

**Do not:**

- change timing, damage, target choice, guard results, card effects, or resource costs;
- delete migration fixtures before an explicit compatibility decision;
- introduce a generic event bus for all gameplay.

**Automated acceptance:**

- golden snapshots and current combat validators are byte/field equivalent where ordering is stable;
- baseline dojo timeline matches PR 1 within declared non-semantic differences;
- production never resolves retired active-skill actions;
- no new gameplay behavior is added to the monolith after extraction begins.

**Human gate:** Side-by-side baseline play shows no perceived behavior change; any difference is either fixed or documented before merge.

## PR 3 — Input parity and movement comfort

**Branch:** `agent/core-play-controls-movement`

**Primary hypothesis:** Players enjoy and learn the game faster when correct movement intentions survive small timing/position errors and input-device choice.

**Small implementation:**

- add gamepad actions and automatic keyboard/gamepad glyph switching;
- ship Arrow and WASD movement aliases together;
- preserve existing remapping and migrate saved bindings safely;
- add dash and attack buffers through the extracted input owner;
- prototype conservative jump/dash corner correction;
- make rope attach, descent, dismount, and aerial-resource refresh rules explicit;
- revise the movement dojo into flow, correction, and speed routes;
- update `MovementMetrics` only after the accepted runtime behavior is selected.

**Automated acceptance:**

- keyboard and gamepad fixtures produce equivalent semantic commands;
- focus loss releases both devices;
- no duplicate command occurs when glyph mode changes;
- geometry validators consume the selected movement envelope;
- current fixed required routes remain legal.

**Human gate:**

- movement-only enjoyment reaches at least 4/5 median;
- at least 80% of failures are explained as visible route/timing errors, not ignored input;
- accidental crouch/drop and rope attachment remain below the foundation threshold;
- second-attempt improvement is visible without extra instruction text.

**Rollback:** Device parity remains; individual forgiveness rules are feature-toggled and may be tuned or removed independently.

## PR 4 — Attack-intent control experiment

**Branch:** `agent/core-play-attack-intent-experiment`

**Primary hypothesis:** A single attack surface can remain simple without hiding agency if the pending tool and target are predictable.

**Small implementation:**

- implement development-selectable Variant A and Variant B from `CORE_PLAY_FOUNDATIONS.md`;
- add one shared world-space target/tool forecast component;
- ensure forecast and committed attack use the same `AttackIntent` instance/snapshot;
- delay ranged-supply commitment until the selected ranged intent is committed;
- create close/far/elevated/occluded/multi-target/resource-empty fixtures;
- log prediction, cancellation, fallback, and supply-spend results.

**Automated acceptance:**

- preview/execution equivalence in every fixture;
- no supply loss on rejected/cancelled attacks;
- deterministic threshold and retention behavior;
- keyboard/gamepad parity;
- no compatibility branch affects production intent.

**Human gate:** Select one scheme using the foundation criteria: at least 95% prediction, under 2% accidental spend, no material response-time penalty, lower loss-of-control reports, and clear multi-height behavior.

**Decision artifact:** Add a short dated decision record to the active combat spec. Remove the losing experiment path after the chosen scheme survives one later integrated PR.

## PR 5 — Readable combat states and impact

**Branch:** `agent/core-play-combat-states-feedback`

**Primary hypothesis:** Existing enemies become more engaging when the player can create and convert shared openings, and when impact/results are communicated without repeated combat text.

**Small implementation:**

- add typed Exposed, Breach, and Interruptible state tags/snapshots;
- apply them first to Walker, Charger, Shooter, and Shield Guard;
- update the combat dojo with isolated lessons and one mixed encounter;
- add minimum hitstop, recoil/reaction, hit flash, semantic sounds, defeat timing, and bounded camera impulse;
- retain optional training labels in the Arsenal Trial, but remove repeated ordinary-combat timing sentences after first-use teaching;
- expose damage source and response category to the recorder and death recap owner.

**Automated acceptance:**

- each state has exact entry, exit, cap, and cleanup tests;
- enemy defeat immediately disables damage;
- Breach and Exposed cannot duplicate reward or card triggers;
- accessibility toggles clear active camera/flash transients;
- mixed encounter remains legal under encounter and geometry contracts.

**Human gate:**

- at least 80% identify Exposed and Breach without debug labels;
- unexplained damage falls below 10%;
- no single response safely resolves every fixture;
- players deliberately convert at least one opening rather than only trading damage.

## PR 6 — Three behavior-changing build directions

**Branch:** `agent/core-play-build-expression`

**Primary hypothesis:** A compact set of equipment/card interactions creates more replay value than additional item count or rarity.

**Small implementation:**

- preserve Pursuit, Counter, and Control as build tags for authoring/testing, not classes shown to players;
- revise the five current cards and add at most one Control card according to the foundation spec;
- add tool-specific Counterclaim conversions through typed data rather than controller conditionals;
- ensure Aerial Relay, Dash Wake, and Controlled Shot interact with the shared enemy states;
- keep micro-upgrades in their current maintenance tier;
- feature-flag equipment condition wear off for the first build test;
- create three equal-power prebuilt fixture loadouts and a build-comparison report.

**Do not:**

- add random affixes, rarity ladders, active skills, equipment slots, or new currencies;
- make build tags permanent class restrictions;
- balance only by aggregate DPS.

**Automated acceptance:**

- card triggers deduplicate by action/event identity;
- no infinite dash, ammunition, guard, or stagger loop;
- every effect has a bounded stack/cooldown/resource contract;
- card UI and runtime resolve the same typed effect;
- current save migration tolerates card/catalog version changes.

**Human gate:**

- observers identify the three approaches in at least 80% of clips;
- players name a behavioral consequence of their card and test it in the first eligible room;
- each build changes route, target priority, or timing;
- median clear-time differences stay within the accepted band unless safety/resource cost explains them.

**Decision artifact:** Record whether condition remains disabled, returns unchanged, or returns with a redesigned expedition decision. Do not re-enable it by inertia.

## PR 7 — Ruin Approach Core Play Proof stage

**Branch:** `agent/core-play-ruin-proof`

**Primary hypothesis:** One memorable authored stage creates more curiosity and replay value than broader but weak procedural variation.

**Small implementation:** Re-author only the proof path using existing room infrastructure:

- one landmark visible from at least three positions;
- exposed fast upper route versus sheltered slower lower route;
- divergence lasting more than one room and a forward rejoin;
- one controlled descent and one persistent world-state change/shortcut;
- Walker, Charger, Shooter, and Shield Guard used only where their terrain relation supports the room intention;
- one quiet overlook/recovery beat;
- one pre-boss card reward or intermission decision;
- final encounter combines only taught elements;
- continuous camera and route evidence from start to finish.

The current fixed plan remains available as a fallback during development.

**Automated acceptance:**

- all stage, room, geometry, fall-recovery, completion, minimap, reward, and retry validators pass;
- branch/rejoin, landmark, decision-gap, and repeated-primary-lesson diagnostics are reported separately;
- no required route needs build effects;
- every combat room has a machine-readable intention ID and human sentence in its authoring sheet.

**Human gate:**

- at least 70% reconstruct the macro route and landmark after one blind run;
- route selection is no worse than 70/30 without an approved expert-route rationale;
- players state a non-numeric reason for the route;
- room traces show teach, transform, test, and release;
- blind first clear targets eight to ten minutes without empty transit.

## PR 8 — Slime King as learned-verb and build exam

**Branch:** `agent/core-play-slime-king-proof`

**Primary hypothesis:** The boss becomes memorable when each pattern recalls a learned stage question and every build sees a distinct conversion window.

**Small implementation:**

- map Body Bump, Jump Slam, Poison Bands, and Summon to the provenance table in the foundation spec;
- add shared state outcomes: endpoint/landing Exposed, supported precise-guard Breach, ranged weak-point/supply opportunity;
- make phase 1 present families separately;
- make phase 2 combine only learned legal pairs;
- change arena use or vulnerability during transition rather than only speed/color;
- tune health and recovery only after pattern comprehension is proven;
- add death-response questions and boss timeline summary.

**Automated acceptance:**

- scheduler simulations preserve warning floors, safe lanes, add caps, no repeats, and no illegal overlaps;
- every build can finish with baseline persistent progression;
- no post-defeat damage/reward duplicate;
- pattern-state and shared-state transitions are deterministic.

**Human gate:**

- at least 80% identify each response after one exposure;
- at least 70% explain deaths correctly;
- genre-familiar baseline players win within roughly two to five attempts;
- every build has a useful conversion and still faces an execution check;
- successful fight duration comes from resolving patterns, not idle health depletion.

## PR 9 — Gameplay UI, economy focus, and final-enough presentation slice

**Branch:** `agent/core-play-presentation`

**Primary hypothesis:** A focused presentation pass can prove combat readability, place, and emotional escalation without finishing art for the whole game.

**Small implementation:**

- finalize input glyph switching and world-space attack forecast;
- add concise death recap with source and response category;
- add card behavior demonstration/before-after panel;
- audit and remove HUD elements that do not support an imminent decision;
- expose only the run resources used by the proof path;
- add final-enough Traveler and proof-enemy motion states, Ruin terrain kit, landmark, set-piece change, combat sounds, ambience, and a small music-layer pass;
- keep later-stage art, broad economy screens, and new content out of scope.

The existing UI visual system remains authoritative for shell composition. This PR closes the mismatch between that shell and the action scene only for the proof path.

**Automated acceptance:**

- responsive HUD/UI checks pass at all supported viewports;
- keyboard/gamepad focus and glyph paths pass;
- no hidden resource affects proof combat without a visible state;
- audio/visual toggles are independent and clear active transients;
- assets resolve through the production manifest/fallback owners.

**Human gate:**

- roles and startup states are recognized from silhouette/motion;
- audio communicates startup, precise guard, hurt, defeat, and boss transition;
- players identify the landmark and infer at least one world event;
- UI comprehension improves without increasing combat-screen fixation.

## PR 10 — Integrated Core Play Proof and go/no-go decision

**Branch:** `agent/core-play-integrated-proof`

**Primary hypothesis:** The combined loop is strong enough to justify further production.

**Small implementation:**

- integrate the selected control scheme and accepted values;
- remove the losing experiment path after one regression cycle;
- connect preparation, proof Ruin, reward/intermission decision, Slime King, and result;
- run the target playtest cohort and produce an anonymized aggregate report;
- compare baseline and proof on action mix, unexplained damage, route memory, build recognition, boss learning, enjoyment, and voluntary replay;
- update active specs and release limitations with the accepted product decisions.

**Automated acceptance:**

- Full release matrix passes;
- fresh profile, migrated profile, retry, end expedition, victory, and refresh/persistence paths pass;
- all feature flags have explicit production defaults;
- no development recorder or experiment UI leaks into release builds.

**Human acceptance:** All Core Play Proof gates in `CORE_PLAY_FOUNDATIONS.md` pass or have an explicit owner-approved exception backed by evidence.

**Go outcome:** Begin staged content expansion and procedural re-entry.

**No-go outcome:** Keep the fixed benchmark and iterate on the failed category. Do not compensate by adding content, currencies, or random topology.

## PR 11 — Procedural re-entry phase 1, only after Go

**Branch:** `agent/core-play-procedural-encounters`

**Primary hypothesis:** Reviewed encounter-package and reward variation can change decisions while preserving the proof stage's identity and pacing.

**Small implementation:**

- keep macro topology, landmark, set-piece, and boss authored;
- vary only reviewed encounter packages and reward offers at compatible anchors;
- use named RNG streams and deterministic reports;
- compare generated variants against the fixed proof seed;
- report repetition, decision gaps, threat overlap, reward clustering, damage concentration, and fallback reason separately.

**Automated acceptance:** Existing generation invariants plus deterministic package selection, safe fallback, and no un-taught mixed lesson.

**Human gate:** Generated variants match the fixed benchmark for clarity, pacing, route memory, and enjoyment within an owner-approved tolerance, while players report a changed decision rather than only a changed enemy order.

Later procedural phases—optional-route offers, rhythm-slot room substitution, then constrained graph variation—require separate plans and PRs.

## Cross-PR ownership map

| Responsibility | Expected owner |
| --- | --- |
| Development evidence | new `scripts/playtest/` and `tools/` summaries |
| Input and buffers | `InputBindings.gd`, new `PlayerCombatInput`, focused player input owner |
| Movement physics | `PlayerController.gd`, `MovementMetrics.gd`, movement validators |
| Attack forecast/choice | new `AttackIntentService`, existing `AttackIntentResolver`, forecast UI component |
| Attack phases/execution | new `AttackExecutor` orchestrated by `PlayerCombatController` |
| Defense | existing `ShieldCombatRuntime` plus new `PlayerDefenseController` facade |
| Stage-local equipment runtime | new `CombatLoadoutRuntime`; profile mutations only at declared transaction boundaries |
| Shared enemy states | typed combat-state definitions consumed by existing enemy actors |
| Cards/build effects | `data/cards/`, card definitions/runtime, typed effect handlers |
| Proof stage | current Stage Plan/room pipeline and Ruin authored scenes/resources |
| Boss | `SlimeKingActor`, scheduler/pattern runtime/data, Slime Court scene |
| Gameplay UI | production HUD components and immutable combat/stage snapshots |
| Presentation | `FeedbackDirector`, player/enemy presenters, production asset resolver |
| Procedural re-entry | existing generation planner/allocator/report owners after proof acceptance |
| Legacy compatibility | isolated adapter and migration fixtures; never a production extension point |

## Regression matrix

Every behavior PR reruns the smallest focused checks plus the Full release gate before merge. The integrated proof additionally covers:

| Path | Required evidence |
| --- | --- |
| Fresh profile | Trial/skip baseline, preparation, proof run, reward, boss, result |
| Migrated profile | v1→v2 preservation and no retired production UI/action |
| Keyboard | movement, combat, UI focus, remap, pause, retry, result |
| Gamepad | semantic command parity, glyph switching, focus, combat, retry |
| Attack intent | close/far/elevated/occluded/empty-resource/multi-target |
| Defense | normal, precise, recovery, outside angle, unblockable, break |
| Shared states | entry/exit/dedup/cleanup for Exposed, Breach, Interruptible |
| Builds | Pursuit, Counter, Control plus baseline/no-card |
| Stage | route split/rejoin, shortcut, minimap, fall recovery, retry knowledge |
| Boss | all patterns, phase transition, each build, death/retry, victory cleanup |
| Accessibility | shake, flash, training labels, device switch, readable state without color alone |
| Persistence | save failure rollback, backup recovery, no duplicate permanent reward |

## Risk register

### Risk: The contextual attack is fundamentally frustrating

Mitigation: select by A/B evidence. The roadmap permits an explicit tap/hold intent scheme without adding a weapon wheel or second attack button.

### Risk: More forgiving movement lowers challenge

Mitigation: forgiveness protects intention at boundaries. Challenge is retuned through route and timing after accepted movement physics, never by relying on dropped inputs.

### Risk: Shared states homogenize enemies

Mitigation: states describe openings, not behavior. Each archetype retains a distinct tell, lane, response, and conversion rule.

### Risk: Build effects create loops or invalidate authored routes

Mitigation: cap resources and event identities; required routes remain baseline; automated loop tests and equal-power fixtures precede stage adoption.

### Risk: One proof stage delays the complete run

Mitigation: the complete fixed run remains available. The proof prevents expensive replication of weak interactions across three stages and future generated content.

### Risk: Presentation work begins too early

Mitigation: final-enough assets are limited to states needed to judge readability and production cost. Later-stage content remains placeholder.

### Risk: Human gates are noisy

Mitigation: pair telemetry with the same short questions, retain anonymized aggregate results, and make decisions from repeated patterns rather than one opinion.

### Risk: Refactor scope expands

Mitigation: extract delegates with golden behavior before redesign. No broad engine/framework change and no rewrite of stable run/profile/reward systems.

## Work explicitly blocked until Core Play Proof passes

- production random stage topology;
- additional normal stages or bosses;
- new normal enemy archetypes;
- additional equipment families/slots;
- active skills, class selection, mastery trees, or resonance systems;
- random item affixes or rarity ladders;
- broader permanent-stat progression;
- final art for Flooded Works and Broken Sanctum;
- seed UI, daily runs, leaderboards, multiple save slots, or mid-run Continue.

## Review checklist for this plan

- Does the owner accept one excellent stage as the immediate benchmark?
- Are Pursuit, Counter, and Control useful authoring targets without becoming classes?
- Is the tap/hold attack variant acceptable as an experiment, not a locked direction?
- Are the human acceptance thresholds strict enough to prevent “finishable” from being called “fun”?
- Is any blocked feature genuinely required to test the core loop? If so, identify the exact decision it enables before unblocking it.
