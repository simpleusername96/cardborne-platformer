# Claude Code Review Prompt

You are the independent read-only reviewer for the current Cardborne repository.
Do not modify files, create patches, install dependencies, or change git state.

Repository:

- Local path: `D:\npjt\cardborne-platformer`
- Remote: `https://github.com/simpleusername96/cardborne-platformer`
- Branch: `master`
- Code baseline: `faf8dfc4e85f129913ea38423a143d681a795f7c`
- Engine: Godot 4.7 stable, GDScript

Goal:

Perform a repository-wide, evidence-based audit of the game as currently
implemented. Assess product/spec alignment, gameplay state flow, architectural
ownership, correctness failure paths, UI/localization integrity, performance
design, test quality, and documentation trustworthiness. This is not a request
for implementation or generic best practices.

Read first:

1. `docs/handoffs/repository-audit-2026-07-26/README.md`
2. `docs/handoffs/repository-audit-2026-07-26/current-state.md`
3. `docs/handoffs/repository-audit-2026-07-26/constraints-and-decisions.md`
4. `docs/handoffs/repository-audit-2026-07-26/source-map.md`
5. `AGENTS.md`
6. `docs/product/vehicle_game_spec.md`
7. `docs/design/UI_VISUAL_SYSTEM.md`
8. The current source, resources, and validators needed to verify claims

Audit questions:

1. What does the executable actually implement, and where do the canonical
   specifications overstate, understate, or contradict it?
2. Which P0/P1 correctness or release risks exist in run flow, encounters,
   enemies, bosses, projectiles, rewards, upgrades, persistence, UI, or
   localization?
3. Which modules have responsibility creep or implicit coupling? Name the
   concrete responsibilities and consumers; do not recommend splitting by line
   count alone.
4. Can the present performance architecture plausibly sustain authored hard
   pressure in the full rendered game? Identify unmeasured costs and invalid
   benchmark assumptions.
5. Which validators exercise behavior, and which merely restate constants,
   inspect debug contracts, or risk false confidence?
6. Which failure, empty, malformed, transition, retry, locale, input, or
   low-resolution states remain reachable but weakly verified?
7. Are active documents and comments trustworthy, or are there stale claims and
   competing owners?
8. What is the smallest prioritized next work that materially improves release
   confidence without redesigning the product?

Required output:

1. Executive verdict: release confidence and the three most important risks.
2. Verified current architecture and gameplay flow.
3. Findings table with:
   - severity (`P0`, `P1`, `P2`, `P3`);
   - exact file and symbol evidence;
   - observed fact;
   - consequence;
   - recommendation;
   - confidence (`high`, `medium`, `low`).
4. Spec/code drift.
5. Performance and scalability review.
6. Validator/test-quality review, including false-confidence risks.
7. UI, localization, accessibility, and responsive-state review.
8. Documentation and maintainability review.
9. Prioritized next actions split into:
   - must fix before release;
   - next stabilization batch;
   - optional later improvements.
10. Assumptions, uncertainties, and items requiring real runtime or human play
    verification.

Rules:

- Cite exact current paths and symbols for every material finding.
- Distinguish verified evidence from inference.
- Do not invent missing behavior or claim runtime proof from static inspection.
- Do not recommend destructive actions, dependency additions, engine changes,
  product pivots, or broad rewrites.
- Do not repeat the handoff summary as the answer.
- If a claim cannot be verified, label it explicitly rather than filling gaps.

