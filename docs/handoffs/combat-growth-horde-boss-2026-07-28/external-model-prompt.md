---
type: handoff
status: active
owner: BK
created: 2026-07-28
last_reviewed: 2026-07-28
expires: 2026-08-28
topic: Copyable prompt for external Cardborne combat-growth review
scope: Read-only evidence-based review request
source: ./README.md
related:
  - ./current-state.md
  - ./source-map.md
  - ./constraints-and-decisions.md
  - ./external-review-raw.md
---

# External Model Review Prompt

## Current State

The block below is the copyable review request. If the reviewer already has
direct repository access, point it to this file and ask it to follow the prompt
without modifying the repository.

## Copyable Prompt

You are the independent, read-only design and code reviewer for the current
Cardborne repository. Your job is to challenge an evidence-backed gameplay
diagnosis and improvement draft. Do not implement, edit files, generate patches,
install dependencies, or change git state.

Repository:

- Local path: `D:\npjt\cardborne-platformer`
- Remote: `https://github.com/simpleusername96/cardborne-platformer`
- Branch: `master`
- Gameplay/research baseline before the handoff:
  `57346d9f6c645aaa80d6b5ca3f0a909bb7898fc2`
- Handoff folder:
  `docs/handoffs/combat-growth-horde-boss-2026-07-28/`
- Engine: Godot 4.7 stable, GDScript

Product goal:

Strengthen the core survivor-shooter payoff without erasing Cardborne's manual
vehicle-shooter identity. The desired loop is:

`herd enemies → compress a readable group → deliberately trigger a mass kill →
collect the growth payoff → qualitatively evolve the build → face a boss that
tests the new rule`.

Current diagnosis to verify, not assume:

1. Upgrade offers are constrained and deterministic, but no predictable
   qualitative transformation is guaranteed.
2. The game has high active-enemy caps, yet separate squad anchors and the large
   field can produce low practical engagement density.
3. Arc, bulkheads, gates, support fields, and mine chains exist, but do not
   consistently close a deliberate environment-kill loop.
4. Bosses have three phases and stage-specific patterns, but phase changes
   mostly alter pattern order and cadence rather than the player's objective or
   arena state.
5. Boss rewards mostly reuse the ordinary card pool, so bosses are weak growth
   milestones.
6. Existing validators prove current rules and boundedness, not fun, clear
   acceleration, or boss identity.

Read in this order:

1. `docs/handoffs/combat-growth-horde-boss-2026-07-28/README.md`
2. `docs/handoffs/combat-growth-horde-boss-2026-07-28/current-state.md`
3. `docs/handoffs/combat-growth-horde-boss-2026-07-28/constraints-and-decisions.md`
4. `docs/handoffs/combat-growth-horde-boss-2026-07-28/source-map.md`
5. `AGENTS.md`
6. `docs/product/vehicle_game_spec.md`
7. `.agents/survivor-shooter-combat-growth-reference-study.md`
8. `docs/product/combat-growth-improvement-direction.md`
9. The current code, card resources, and validators needed to verify material
   claims

Review questions:

1. Which current-state claims are verified, overstated, understated, or wrong?
   Cite exact current paths and symbols.
2. Is “weak coupling between growth, engagement density, terrain, and bosses”
   the correct root cause? If not, what is more fundamental?
3. Evaluate the proposed Foundation → Specialization → Evolution model. Can the
   current 46-card catalog support a smaller qualitative-growth intervention?
4. Evaluate the proposed boss-only Evolution offer. Should boss rewards instead
   unlock, transform, specialize, or conditionally complete builds another way?
5. Evaluate encounter-front clustering. What is the smallest change that
   creates real herd-and-wipe moments while preserving spawn fairness, pathing,
   ranged/denial caps, and performance?
6. Which proposed formation concepts can be built from current enemy roles, and
   which would require behavior the game does not have?
7. Evaluate field-specific player-triggered terrain interactions. Are they the
   right layer, or would a smaller universal Breach/EMP/mine interaction be
   clearer and cheaper?
8. What makes each current boss insufficiently distinct in code? Recommend
   semantic boss states without creating five unrelated boss engines or
   concentrating all state in `vehicle_run.gd`.
9. How much ordinary-enemy pressure, if any, should remain during boss fights?
10. Critique these draft targets rather than accepting them:
    - regular level-ups `5/4/4/4/4`;
    - 24 swarm bodies in one 135-degree arrival sector;
    - P90 engaged-within-900px ratio of 0.55;
    - 12 kills within two seconds for an evolved build;
    - 8-kill Breakthrough feedback;
    - 12–18 finite boss-wave adds.
11. What telemetry, deterministic simulation, rendered QA, and human playtest
    evidence are required before changing quotas, caps, XP, or boss HP?
12. What is the smallest Stage 1 vertical slice that can falsify or validate
    the overall direction?

Required output:

1. **Executive verdict**
   - Is the diagnosis substantially correct?
   - The three highest-leverage changes.
   - The three largest risks or false assumptions.

2. **Verified baseline and corrections**
   - A table with claim, exact local evidence, verdict, and confidence.
   - Separate implemented facts from specification claims and draft proposals.

3. **Recommendation verdicts**
   - For every major draft axis—growth, formation, terrain, boss, reward,
     telemetry—label it `accept`, `modify`, `reject`, or
     `needs-local-verification`.
   - Explain why and cite paths/symbols.

4. **Revised target loop**
   - Describe the player experience in concrete combat events.
   - Show how manual aim, Breach, dash, EMP, automatic secondaries, enemies,
     terrain, and boss rewards connect.

5. **Smallest Stage 1 vertical slice**
   - Ordered scope and non-scope.
   - Existing systems to reuse.
   - New state or data that is genuinely required.
   - Concrete file/module owners.
   - Stop conditions if the direction fails.

6. **Boss review**
   - Current shared behavior that should remain.
   - The minimum semantic state needed for each boss to be distinctive.
   - How to avoid five bespoke unmaintainable runtimes.

7. **Validation plan**
   - Static/deterministic validators.
   - Runtime telemetry.
   - Rendered QA.
   - Human playtest questions.
   - Which current validators must change rather than merely keep passing.

8. **Assumptions and uncertainty**
   - Anything requiring local runtime, profiling, or human judgment.
   - Any source that appears stale or contradictory.

Rules:

- Do not repeat the handoff or draft as your answer.
- Cite exact current files and symbols for every material code claim.
- Distinguish fact, inference, recommendation, and uncertainty.
- Do not infer fun from constants or validator success.
- Do not assume high active count means high engagement density.
- Do not recommend raising caps, adding content breadth, or increasing boss HP
  without measured evidence.
- Do not propose full auto-aim, an engine change, a new production dependency,
  a broad rewrite, or full procedural destruction.
- Preserve Korean/English completeness, readable telegraphs, deterministic
  behavior, performance budgets, card/UI separation, and collision truth.
- If an omitted file is required, name it and explain why.
- If the draft is wrong, say so directly and give a smaller alternative.

## Next Steps

1. Run the review against the current workspace or authenticated branch.
2. Return one Markdown response matching the required output without editing
   repository files.
3. The local coordinator will save that response unchanged in
   `external-review-raw.md`.
4. Have Codex validate the saved response before planning or implementing
   anything.

## Risks

- A model without repository access can only critique the summaries and must
  label all code conclusions unverified.
- The remote may be access-controlled; do not request public publication.
- The improvement direction is draft evidence, not permission to implement.
- Model confidence does not replace runtime profiling or human playtesting.
