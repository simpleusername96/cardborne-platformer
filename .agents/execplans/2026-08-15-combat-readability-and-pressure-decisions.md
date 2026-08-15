---
type: plan
status: active
owner: BK
created: 2026-08-15
last_reviewed: 2026-08-15
scope: Decide the coordinated report, combat-readability, neutral-facility, conditional-status, enemy-engagement, boss-defense, boss-pressure, and encounter-density revision; no implementation readiness is implied
related:
  - ../../docs/reports/2026-08-15-combat-readability-pressure-review.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../design/DESIGN.md
  - ../cardborne-performance-engineering-policy.md
  - ./2026-08-15-eight-boss-combat-depth-and-run-report.md
---

# Combat Readability and Pressure Revision - Research Checklist

## Purpose

- Decision or research question: which reported problems are defects, which are current
  contracts, and which coherent revision should become a later implementation contract?
- Why it matters: isolated value edits would deepen current owner/affinity ambiguity,
  invalidate fairness and visual contracts, and increase an unqualified Web workload.
- Decision owner: BK.
- Final output: the evidence report linked above plus one approved decision package that
  can be converted into a separate Mode 3 execution contract.

## Scope and Evidence Contract

- In scope: failure build reporting; neutral-facility radius, identity, overlap, and hit
  receipt; player/hostile/neutral projectile and AOE grammar; conditional status HUD;
  engagement relevance; directional boss shields; boss death; boss pressure; one
  distance-growth enemy mechanic; continuous encounter refill and capacity boundary.
- Out of scope: implementation, new assets, spec edits, production value changes, engine or
  dependency changes, higher-than-48 runtime capacity, and release qualification.
- Destructive or irreversible actions: none.
- Approval required before: changing product/design specs; deleting the boss explosion;
  changing facility or boss balance; changing admission caps; creating or promoting visual
  assets; or beginning implementation.
- Search budget or reassessment point: local authority, owning code, recent history,
  existing captures, eight focused validators, and at most ten primary or authoritative
  external sources. This budget is complete.
- Conflict-resolution rule: user direction outranks an older product choice, but the
  affected product, visual, test, manifest, and performance contracts must be revised
  together. Accessibility and exact-footprint rules remain invariants unless explicitly
  rejected.
- Stop rule for unproductive exploration: stop after each concern has an owning code path,
  a classification, and either decisive evidence or one named approval need.

| Evidence category | Primary source | Freshness requirement | What it must establish | Sufficient evidence |
| --- | --- | --- | --- | --- |
| Product behavior | `vehicle_game_spec.md` and current runtime | Current HEAD | Intended facility, report, encounter, and boss behavior | Contract and consumer traced |
| Visual/UI behavior | `VISUAL_SYSTEM.md`, canonical sheet, DESIGN, captures | Current HEAD and canonical sheet hash | Semantic palette, owner grammar, HUD and rendered baseline | Full docs read and key captures inspected |
| Runtime ownership | Owning GDScript and validators | Current HEAD | Where state, decisions, and presentation data belong | Producer-to-consumer path identified |
| Performance | Performance policy, architecture audit, current evidence | Recheck after any workload change | What may change without qualification | Exact cap and missing Web evidence recorded |
| External guidance | Microsoft, W3C, Riot, Ubisoft, Godot, Bungie, GDC | Current pages accessed 2026-08-15 | Readability, multi-channel cues, pacing, and profiling principles | At least one authoritative source per principle; no invented balance claim |

## Viable Options

| Option | Why materially viable | Decision criteria | Disqualifier |
| --- | --- | --- | --- |
| A. Minimal defect repair | Lowest implementation and balance risk | Fixes report, hit receipt, stale validation, and data loss | Does not satisfy requested strategic range, boss pressure, HUD, or spawn outcome |
| B. Coordinated bounded revision | Addresses all user outcomes while retaining caps, fairness, and semantic ownership | Readability, strategic effect, role identity, testability, Web qualification path | Rejected if it requires color-only cues, blanket unsafe multipliers, or unbounded work |
| C. Blanket multiplier/content pass | Fastest apparent response: 3x facilities, 1.5x all boss axes, more spawns, all bullets recolored | Immediate magnitude | Disqualified: squared AOE growth, palette overload, unclear ownership, and unqualified capacity |

Recommended option: B.

## Proposed Decision Package

The following is the recommended bounded revision for owner approval:

1. Treat defeat build omission, boss reward leakage, premature boss-clear reporting,
   missing broad-barrage/wedge-ring cues, facility hit-receipt loss, hostile-area owner
   loss, directional shield collapse, and the engagement/document-authority validation
   failures as defects.
2. Increase facility radii to approximately 3x, retain symmetric effects, reduce continuous
   magnitude as a first tuning hypothesis, use strongest-only same-kind overlap, and cap
   distinct simultaneous facility modifiers per actor at two.
3. Encode owner through silhouette/boundary pattern and affinity/effect through color.
   Gravity uses a black interior plus a high-contrast rim; no critical cue uses color alone.
4. Add a maximum-five conditional-status strip below the current top-left row, backed by a
   gameplay-owned snapshot and stable priority.
5. Preserve intentional role standoff, but release stale engagement gates early when they
   increase distance from the current player without relevant tactical value.
6. Preserve projectile pass-through on facilities initially and add localized impact
   receipt. Revisit projectile blocking only if playtest evidence requires a combat change.
7. Remove the boss explosion while retaining the safe cleanup and body-only fade.
8. Implement true Drydock frontal interception and Crown three-sector body-attached
   defense before adding more boss patterns.
9. Use axis-specific boss multipliers: locomotion 1.25x, projectile speed 1.40x, reach
   1.45x, charge speed 1.30x, and AOE radius 1.25x, with no warning-time reduction.
10. Continuously refill an engaged-visible floor within cap 48, starting with the cap
    hypothesis `28,36,44,48,48,48,48,48`; require current built-Web qualification before
    any cap above 48.
11. Prototype distance-growing ammunition only on one Siege Battery boss or elite, with an
    arming distance and hard caps; do not make it a global projectile rule.
12. Resolve the eight-cycle HUD/quota and difficulty-curve authority drift before tuning
    encounter pressure, and add explicit first-attack-preparation evidence.
13. Resolve the product spec's contradictory facility projectile paragraphs in favor of
    the newer pass-through runtime plus clear hit receipt, unless BK explicitly selects
    player-shot blocking as a new combat rule.
14. Restore the approved boss identity gaps, including Archive Cross's X-laser and the
    defense-to-offense coupling for Titan/Drydock and Crown, before adding pattern breadth.

## Milestones for a Later Execution Contract

This sequencing is planning input, not authorization to implement:

1. Revise product, visual, report, boss-defense, HUD, and performance acceptance contracts.
2. Repair reward/report parity, missing boss cue paths, and the stale replay validator; add
   missing producer-boundary tests.
3. Add gameplay-owned owner/affinity/phase and conditional-status presentation snapshots.
4. Implement attack/facility cue grammar, facility hit receipt, and HUD layout with rendered
   Korean/English evidence.
5. Implement engagement relevance release and real directional shields with deterministic
   validators.
6. Apply facility and boss values, continuous refill, and the bounded distance-growth
   prototype behind exact workload budgets.
7. Run focused gates, full relevant regression, Web export, built-product visual QA, and
   current native/Web performance qualification.

## Test Plan for a Later Execution Contract

- Defeat after acquiring representative level-one and level-three cards shows the same
  frozen build facts as Settings/final result in Korean and English.
- Boss cleanup grants no boss-owned XP/group reward, and a boss is reported cleared only
  after safe cleanup completes.
- Broad barrage and Pulse wedge ring both publish visible, offscreen-aware startup cues that
  match their exact gameplay geometry.
- Every facility accepts a projectile hit, gives a localized receipt, and follows the
  approved pass-through rule.
- Player, hostile, and neutral circles remain distinguishable in grayscale, at reduced
  effect intensity, and during overlapping affinity colors.
- Conditional status slots cover activation, charging, stacking, consumption, reset,
  expiration, maximum count, 200-percent text, and both locales without clipping.
- Enemy movement tests distinguish engagement gate, pursuit, standoff, recovery, and wall
  reposition; relevance release never teleports or retargets.
- Drydock front/rear and Crown sector tests prove collision truth matches the rendered
  boundary and defense-to-attack link.
- Each boss attack preserves exact footprint, one-hit semantics, minimum warning, and an
  escape corridor after tuning.
- Continuous refill respects boss transition, attack budgets, effect/projectile caps, and
  deterministic replay.
- Worst-case two-facility overlap, cap-48 ordinary combat, conditional HUD, and boss combat
  pass current native and built-Web frame-time gates.

## Rollback and Safety for a Later Execution Contract

- Keep value changes data-driven and commit contract, defect repair, cue/HUD, boss defense,
  and balance/capacity work separately.
- Revert an individual tuning commit if fairness or performance fails; do not revert the
  report or validator repair with it.
- Do not delete the boss explosion file until all runtime, manifest, workbench, capture,
  validator, and spec references are removed in the same scoped commit. Git history is the
  recovery path.
- Do not increase capacities, lower physics rate, or weaken supply-chain protections as a
  performance shortcut.

## Risks

- Approximate 3x facility radius can dominate the viewport and multiply effect overlap.
- More materialized enemies can improve pressure while worsening navigation, projectile,
  AOE, and HUD contention.
- Color-per-bullet can destroy affinity meaning unless owner silhouette remains primary.
- Body-attached Crown sectors require one explicit visual-contract reconciliation.
- Axis-specific boss tuning still needs per-pattern playtest; the numbers are hypotheses.
- Existing native performance evidence is not a current built-Web qualification.
- Eight-cycle progress/quota and ordinary difficulty sources currently disagree; tuning
  before resolving authority would make the drift harder to recover.
- The product spec contradicts itself on whether facilities block player projectiles; the
  current runtime and newer facility contract use pass-through.

## Open Questions and Owner Decisions

- [ ] BK approves Option B and the proposed package as the basis for a separate execution
  contract.
- [ ] BK approves Crown's three body-attached sectors instead of separate relay actors.
- [ ] BK approves the distance-growth mechanic as Siege Battery boss identity first,
  rather than a global or ordinary-enemy rule.
- [ ] BK approves continuous refill within cap 48 before any higher-cap experiment.
- [ ] BK approves axis-specific boss tuning instead of a blanket 1.5x multiplier.

The boss explosion removal and approximate 3x facility intent are already explicit user
directions; implementation still waits for a coordinated contract revision.

## Tasks

### Phase 1: Establish current truth

- [x] Read and verify the bounded source set.
- [x] Record current constraints, versions, ownership, and approval boundaries.
- [x] Remove options that fail a stated disqualifier.

Phase gate:

- Passed. Every surviving option is materially viable and every current-state claim has
  inspected evidence.

### Phase 2: Gather decisive evidence

- [x] Inspect owning code, current captures, targeted validators, and recent history.
- [x] Record primary/authoritative external sources, access date, supported claim, and
  limitation in the evidence report.
- [x] Stop at the bounded source budget after the decision criteria were satisfied.

Phase gate:

- Passed. The remaining input is owner approval, not missing research.

### Phase 3: Decide and record

- [x] Compare viable options against common criteria.
- [x] Separate fact, inference, recommendation, and owner decision.
- [ ] Record BK's approval or requested changes to the proposed package.
- [ ] Mark this research checklist `done` when the decision is recorded.

Phase gate:

- Pending one specific blocker: BK's decisions in the Open Questions section.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this checklist.
- Current phase: Phase 3.
- Next task: record BK's approval or requested changes.
- Last completed gate: decisive local and external evidence gathered and synthesized.
- Update rule: do not repeat completed research unless current files change or a decision
  introduces a new material option.

## Completion and Stop Conditions

Complete when:

- BK approves Option B with any amendments or selects another viable option;
- the selected decisions are recorded here without implying implementation readiness; and
- frontmatter status is changed to `done`.

Escalate when:

- the selected direction requires color-only critical cues, removal of fairness
  invariants, or an unqualified capacity increase;
- product and visual authorities cannot be reconciled for Crown defense; or
- a later implementation requires a destructive asset deletion without explicit approval.

If implementation follows, invoke the planning workflow again in execution-contract mode.
Do not extend this research checklist into implementation while the owner decisions above
remain open.
