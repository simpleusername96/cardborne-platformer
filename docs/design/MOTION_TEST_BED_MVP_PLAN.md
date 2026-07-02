---
type: plan
status: active
created: 2026-07-02
source: User request on 2026-07-02; split from the first long MVP-ish testbed plan
scope: Router/index for the motion test bed miniature game implementation
related:
  - ./MOTION_TEST_BED_SPEC.md
  - ./testbed-plan/FEATURE_PRIORITY.md
  - ./testbed-plan/00_foundation_contracts.md
  - ./testbed-plan/01_authored_lanes.md
  - ./testbed-plan/02_combat_damage.md
  - ./testbed-plan/03_interaction_input_ui.md
  - ./testbed-plan/04_generated_landscape.md
  - ./testbed-plan/05_qa_and_handoff.md
  - ../product/2d_platform_action_card_game_prd.md
  - ../architecture/FIRST_SLICE_ARCHITECTURE.md
---

# Motion Test Bed MVP Plan Index

This is the router for the MVP-ish motion test bed work. Use it to choose the next small plan document, then work from that focused checklist. The detailed behavioral source of truth remains `MOTION_TEST_BED_SPEC.md`; the immediate-vs-later implementation boundary is `testbed-plan/FEATURE_PRIORITY.md`.

## Purpose

- Future goal: build a user-testable Godot 4.x testbed that behaves like a miniature game.
- Why it matters: normal stages, shops, upgrades, and boss maps should not be built on unproven movement, damage, interaction, input, or generated-route contracts.
- Final artifact: a playable `MotionTestStage` with authored validation lanes and a seed-driven generated landscape lane.
- Intended execution style: sequential. Finish foundation contracts before content-like lanes, and finish authored validation before generated landscape work.

## Progress

Already true:

- [x] Godot project boots through `scenes/main/Main.tscn`.
- [x] `Game`, `RunState`, and `SignalBus` autoloads exist.
- [x] One `PlayerController` uses three profile resources.
- [x] `DamageInfo`, `Hitbox`, `Hurtbox`, `StageBase`, `Interactable`, and `ExitPortal` exist.
- [x] HUD and settings popup shells exist.
- [x] The testbed requirements are documented in `MOTION_TEST_BED_SPEC.md`.

Still open at the index level:

- [ ] Movement metrics and ability flags are not a shared contract yet.
- [ ] Authored lanes are not character-aware and do not yet prove camera-followed multi-screen traversal.
- [ ] Rope climb, wall climb, wall slide, wall jump, and similar climb traversal are not planned deeply enough in implementation tasks.
- [ ] Combat lacks a real enemy baseline, readable attack timing, and attack-destructible obstacles.
- [ ] NPC/object interaction and input binding UI are incomplete.
- [ ] Runtime seeded landscape generation is missing.
- [ ] Miniature run replay, clear/fail summary, and final QA matrix are missing.

## Tasks

Execute these documents in order:

| Order | Plan doc | Main output | Stop after |
| --- | --- | --- | --- |
| - | `testbed-plan/FEATURE_PRIORITY.md` | Feature-by-feature Now/Later boundary. | Current implementation pass has a controlled scope. |
| 0 | `testbed-plan/00_foundation_contracts.md` | Baseline launch path, movement metrics, ability flags, shared state/UI signals. | Metrics and ability flags are visible in-game. |
| 1 | `testbed-plan/01_authored_lanes.md` | Character-aware authored movement/test lanes, camera-followed route scale, climb traversal, safe recovery, and route gating. | Least-mobile profile can clear the required authored route without seeing the whole map at once. |
| 2 | `testbed-plan/02_combat_damage.md` | Readable attack timing, real enemy, destructible obstacles, hazard damage, recovery behavior. | Player can fight, break an obstacle, take damage, recover, and retest. |
| 3 | `testbed-plan/03_interaction_input_ui.md` | Non-exit interaction, actual binding guide, settings/input surface. | Tester can discover controls and interact with a non-exit object. |
| 4 | `testbed-plan/04_generated_landscape.md` | Segment-template generator, route validation, generated lane, seed replay. | Same seed/profile/mode reproduces a playable route. |
| 5 | `testbed-plan/05_qa_and_handoff.md` | Final clear gate, manual QA matrix, handoff criteria. | Testbed can be launched, understood, cleared, and replayed by seed. |

## Source Map

| Source or path | Role | Handling |
| --- | --- | --- |
| `AGENTS.md` | Repo policy | Obey Godot, folder ownership, placeholder asset, and PRD-priority rules. |
| `.agent/PLANS.md` | Plan policy | Treat this as ExecPlan-sized future work, but use split docs for execution. |
| `docs/design/MOTION_TEST_BED_SPEC.md` | Active testbed spec | Preserve as the behavior source of truth. |
| `docs/design/testbed-plan/FEATURE_PRIORITY.md` | Priority boundary | Decide what belongs in the immediate implementation pass before opening phase docs. |
| `docs/product/2d_platform_action_card_game_prd.md` | Active product spec | Preserve unless the user explicitly supersedes it. |
| `docs/architecture/FIRST_SLICE_ARCHITECTURE.md` | Ownership guide | Keep player, combat, enemy, stage, UI, and autoload responsibilities separated. |
| `docs/design/testbed-plan/*.md` | Working checklists | Load only the current phase doc plus this index and the spec. |

## Operating Rules

- Keep `MOTION_TEST_BED_SPEC.md` as the durable behavior contract.
- Use `testbed-plan/FEATURE_PRIORITY.md` to avoid pulling later-scope polish into the current implementation pass.
- Keep this file as an index, not a giant implementation checklist.
- Put phase-specific tasks, acceptance checks, and risks in `docs/design/testbed-plan/`.
- Do not add production stages to compensate for unfinished testbed contracts.
- Do not make the default gameplay camera show the entire playable map at once; overview is debug-only.
- Do not promote the generated landscape work into full procedural region generation in this pass.
- Use commit/test evidence for implementation slices; create new evidence docs only when a reusable boundary or decision is discovered.

## Validation Cadence

- Inner loop: use targeted Godot smoke checks and manual route checks while working inside one phase doc.
- Batch gates: run the acceptance checks at the end of each phase doc before moving to the next.
- Final gate: follow `testbed-plan/05_qa_and_handoff.md`.
- Rerun policy: rerun failed checks only after a concrete change or new hypothesis.

## Goal Stop Conditions

Complete the full goal when:

- [ ] The testbed can be launched and understood from in-game UI.
- [ ] Authored lanes validate movement, combat, damage, interaction, and controls.
- [ ] The default camera follows the player through a route larger than one viewport.
- [ ] Generated landscape mode can generate, validate, play, replay, and regenerate seeded routes.
- [ ] The final QA matrix in `05_qa_and_handoff.md` is complete or explicitly deferred with reasons.

Ask the user when:

- [ ] The decision would change product direction, such as making double jump default, changing canonical controls, adding external assets, or expanding into full procedural region generation.
- [ ] A destructive cleanup would remove existing user-authored work.

Do not stop merely because:

- [ ] The work is large.
- [ ] A validation failure points to a concrete fix.
- [ ] A later phase needs polish but the current phase has a clear next task.

## Next Steps

- [ ] Read `testbed-plan/FEATURE_PRIORITY.md` first.
- [ ] Start implementation with `testbed-plan/00_foundation_contracts.md`.
- [ ] Keep each implementation session scoped to one phase doc unless a dependency forces a small cross-file adjustment.
- [ ] After each phase, update that phase doc's progress before moving to the next one.
