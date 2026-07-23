---
type: evidence
status: active
owner: BK
created: 2026-07-24
last_reviewed: 2026-07-24
topic: Run difficulty and death-persistent progression
scope: Evidence and decision checklist for whether Cardborne should rely on fixed run difficulty, bounded persistent growth, or both
source: User feedback and the current local implementation
related:
  - ../docs/product/vehicle_game_spec.md
  - ./vehicle-performance-stabilization-evidence.md
---

# Difficulty and Death-Persistent Progression — Decision Study

## Purpose

Determine how Cardborne should combine its Easy/Normal/Hard run settings with
progress that survives death. This document is advisory evidence and a bounded
decision checklist, not an implementation plan or an accepted product
specification.

The combat-readability, projectile, encounter, field-layout, XP, and
elemental-stack baseline is now implemented in commit `1c7a2b0`. The decision
must still wait for structured play evidence from that baseline: those changes
alter effective survivability and upgrade cadence, so selecting persistent
growth from code inspection alone would substitute an assumption for observed
play.

## Scope

### In scope

- Whether fixed run difficulty is sufficient.
- Whether persistent progression should add power, options, recovery, or an
  opt-in assist.
- Whether cards should persist directly, become unlockable starter modules, or
  reset completely.
- Caps and safeguards needed to preserve run identity and meaningful difficulty.
- Evidence required before selecting one model.

### Out of scope

- Changing current difficulty values now.
- Adding a save schema, currency, card archive, loadout screen, adaptive
  difficulty, or retained cards before a later accepted execution plan.
- Tuning enemy stats as part of this unresolved decision study.
- Treating this evidence document as authority over
  `docs/product/vehicle_game_spec.md`.

## Sources

| Source | Inspected fact | Use in this study |
| --- | --- | --- |
| `scripts/vehicle/vehicle_run_difficulty.gd` | Hard is `1.0`; Normal is approximately `0.85` combined simultaneous pressure; Easy is approximately `0.72`. Difficulty scales quota, active cap, health, boss health, damage, and movement speed. | Establishes the existing explicit challenge axis. |
| `scripts/enemies/vehicle_stage_difficulty.gd` | Across stages 1–5, health rises to `1.16`, damage to `1.12`, and speed to `1.04`; telegraph and projectile timing are excluded. | Separates stage escalation from selected run difficulty. |
| `scripts/vehicle/vehicle_run.gd` | Deployment locks difficulty for a complete run. Defeat goes directly to the garage and a new run resets `VehicleRunBuild` and XP. | Establishes that no cards currently survive death. |
| `scripts/vehicle/vehicle_run.gd::_load_persistence()` and `_save_persistence()` | Current run persistence stores clear count, relay-module flag, field-module flag, and primary selection. | Establishes the existing save owner and current persistent surface. |
| `scripts/vehicle/vehicle_run.gd::_finalize_stage_completion()` | A full clear increments clear count and unlocks the relay module. No current runtime path sets the field-module flag to true. | Shows that a small persistent-power precedent exists, but it is incomplete and not death progression. |
| `scripts/cards/vehicle_upgrade_catalog.gd` and `data/cards/vehicle/` | The run currently has 46 cards, three-card offers, maximum levels, prerequisites, and bounded secondary slots. | Defines the build-diversity system persistent growth must not erase. |
| `docs/product/vehicle_game_spec.md` | Hard is the default; difficulty is fixed at deployment; the run is currently specified around run-scoped cards and five stages. | Defines current authority until a later decision changes it. |
| Commit `1c7a2b0` and `docs/product/vehicle_game_spec.md` | Damage feedback, hostile projectiles, distributed spawns, run-seeded layout variation, early XP, and independent element stacking are implemented and documented. | Establishes the candidate mechanics whose balance must now be observed in play. |
| 2026-07-24 validation pass | The complete focused validator suite, native boot, Web export, fixed-seed captures, and bounded current/boss pressure regressions passed on the implemented baseline. | Establishes a clean technical baseline, not a balance conclusion. |

## Findings

### Facts

- Difficulty and persistent progression solve different problems. Difficulty
  selects immediate pressure; persistent progression can create long-term
  motivation, recovery from failure, or broader build options.
- They are not mutually exclusive, but changing both at once would make it
  difficult to identify why completion rates or enjoyment changed.
- Retaining every acquired card would continuously raise starting power and
  shrink the importance of in-run three-card choices.
- Retaining a random subset would preserve less power but remove player agency
  at the moment of failure.
- A bounded pre-run loadout can preserve player choice and accumulated options
  while capping starting power.
- A permanent stat tree is easy to understand but risks making first clear
  depend on accumulated numerical power rather than learning.
- An opt-in adaptive assist can help a player continue without affecting the
  named difficulty baselines, but it may feel like a hidden difficulty system
  unless explicitly presented.
- The current code already persists two module flags, but it does not have a
  generic card archive, progression currency, migration version, or loadout
  capacity owner.

### Inferences

- The implemented baseline will probably feel easier in short damage bursts
  because accepted hits gain a one-second invulnerability and hostile shots
  are slower/smaller. Faster early XP may also produce stronger builds sooner.
  The net result cannot be inferred reliably without play.
- If fresh Hard remains the default, any persistent power system should not be
  required to make Normal or a first Hard attempt technically viable.
- Option unlocks are less likely than uncapped stats to invalidate encounter
  tuning, but an equipped starter loadout still needs a strict power budget.

## Decision Question

Using the implemented combat baseline, which progression contract gives the
desired balance of mastery, accessibility, long-term motivation, and run
variety without making Hard a grind gate or making in-run card choices trivial?

The owner decision must explicitly answer:

1. Should a fresh save be expected to clear Hard through mastery alone?
2. Is death intended to grant power, broader options, an opt-in assist, or no
   gameplay advantage?
3. How much starting-build control is desirable before it weakens run discovery?
4. Should persistent progress reward reaching milestones, time spent, repeated
   deaths, or some bounded combination?

## Evidence Contract

| Evidence category | Primary source | Freshness requirement | What it must establish | Enough evidence |
| --- | --- | --- | --- | --- |
| Post-change difficulty | Fixed-seed native play on the completed related ExecPlan | Same clean commit as the tested build | Stage reached, defeat cause, run duration, upgrades gained, damage source, and subjective pressure | At least five complete attempts on Normal and five on Hard, including failures |
| Build pacing | Run telemetry and card-offer logs | Same card catalog and XP curve | How many meaningful choices occur before each stage/boss and whether early offers already create sufficient recovery | Five-stage simulated route plus the ten play attempts |
| Persistent-power bounds | Deterministic loadout simulation | Same upgrade formulas as tested build | Starting damage, survivability, mobility, and secondary increase for each proposed cap | Fresh build and maximum proposed starter build compared on the same scenarios |
| Save and migration risk | Current persistence owner and validator prototype | Current Godot/save code | New fields, versioning, malformed-save fallback, reset behavior, and capture isolation | One written schema candidate per still-viable persistence model |
| Comparable design evidence | Current official developer documentation, talks, or postmortems for recent action roguelites | Rechecked when this study resumes | How comparable games separate named difficulty, assist, unlock breadth, and permanent power | Maximum six primary sources; stop earlier when no option ranking changes |
| Player preference | BK's explicit response to the four owner questions | Current after post-change play | Desired role of mastery versus accumulation | One explicit answer per question |

- Label measured runtime results as **fact**, cross-game transfer as
  **inference**, a proposed model as **recommendation**, and the final choice as
  **owner decision**.
- When sources conflict, Cardborne's observed play and stated product goal take
  precedence over another game's convention.
- Stop external research after six primary sources or after two consecutive
  sources fail to change the option comparison.

## Viable Options

| Option | What persists | Why materially viable | Main risk | Disqualifier |
| --- | --- | --- | --- | --- |
| Fixed difficulty only | Guidebook, clear count, cosmetic/option unlocks; no combat power | Preserves mastery and makes each difficulty stable | Failure may feel unrewarding | Post-change Normal remains discouraging despite understandable failure and visible improvement |
| Bounded memory loadout | Permanently discovered cards; a small point-limited subset starts at level 1 | Accumulates options and player agency while capping starting power | Can pre-solve early build decisions | Maximum legal loadout trivializes Stage 1 or bypasses prerequisites |
| Shallow permanent stat grid | Small capped hull, speed, damage, or recovery increments | Extremely clear and always useful | Risks making balance grind-dependent | Fresh Normal/Hard is not viable without accumulated stats, or cap meaningfully invalidates boss pressure |
| Opt-in adaptive assist | Explicit damage resistance or recovery that grows after failures and can be disabled | Supports continued play without changing named baseline profiles | May feel like hidden pity or undermine achievement | Cannot be explained transparently or changes without player consent |
| Direct retained run cards | Some or all cards from the failed run remain equipped | Strong continuity and immediate sense of growth | Power snowball, invalid prerequisites, weak run reset | Unbounded retention, random involuntary loss, or no fixed starting-power cap |
| Hybrid breadth plus assist | Unlockable options plus a separately enabled assist, no permanent raw stats | Separates long-term collection from accessibility | More UI/state and harder messaging | Either subsystem is not independently understandable or testable |

No option is selected by this document.

## Decision Criteria

Score every still-viable option against the same criteria:

1. **Fresh-save viability:** Normal and Hard remain learnable without prior
   grinding.
2. **Run identity:** most power still comes from decisions made during the
   current run.
3. **Failure motivation:** a failed run produces understandable progress or
   learning rather than pure repetition.
4. **Player agency:** persistent rewards are selected or clearly earned, not
   randomly retained.
5. **Build diversity:** persistence expands viable builds without collapsing
   offers into one solved opening.
6. **Difficulty integrity:** Easy/Normal/Hard retain stable, explainable meaning.
7. **Bounded power:** maximum persistent advantage has a calculable cap.
8. **Clarity:** Korean and English can explain the system in one deployment or
   garage surface without excessive rules.
9. **Persistence safety:** save versioning, malformed data, reset, and backward
   compatibility are testable.
10. **Implementation cost:** added UI and code ownership are proportionate to
    the demonstrated player problem.

## Research and Decision Checklist

### Phase 1 — Establish the post-change game

- [x] Complete and validate the combat-readability baseline.
- [ ] Freeze one candidate build for balance observation; do not change
  difficulty or persistence during the sample.
- [ ] Record five Normal and five Hard attempts using the evidence fields above.
- [ ] Separate unavoidable/unreadable deaths from understood execution errors.

**Success check:** the dominant failure and motivation problem is observable
rather than assumed.

**Failure handling:** if performance or correctness disrupts the sample, repair
that issue before interpreting balance.

### Phase 2 — Gather only decision-changing evidence

- [ ] Inspect at most six current primary external sources.
- [ ] Model the maximum starting power of every still-viable option.
- [ ] Draft one save-schema candidate only for options that survive power and
  clarity checks.
- [ ] Obtain BK's explicit answer to the four owner questions.

**Success check:** every option has measured or primary-source evidence for its
main benefit and risk.

**Failure handling:** record the missing source or owner answer; do not convert
uncertainty into a default implementation.

### Phase 3 — Compare and decide

- [ ] Score all surviving options against the ten criteria.
- [ ] Select one contract, or explicitly select no combat-power persistence.
- [ ] Lock starting-power cap, prerequisite behavior, reward timing, UI owner,
  save owner, migration, reset, and difficulty interaction.
- [ ] Record rejected alternatives and consequences.

**Success check:** the selected contract can be implemented without choosing a
progression model during coding.

**Failure handling:** if two options remain materially tied, the blocker is BK's
product preference; present the measured tradeoff and request that decision.

### Phase 4 — Promote only an accepted decision

- [ ] Update `docs/product/vehicle_game_spec.md` only after BK accepts the
  contract.
- [ ] Create a separate decision-complete ExecPlan for implementation.
- [ ] Archive this evidence after its accepted findings are incorporated.

**Success check:** advisory evidence never silently becomes product authority.

## Interim Recommendations

- Do not tune current difficulty profiles or add death persistence in the
  combat-readability implementation.
- Do not retain all cards or a random subset without a hard starting-power cap.
- Test bounded memory loadout, fixed-difficulty-only, and explicit opt-in assist
  as the first three options after the required play evidence is collected.
- Treat a permanent stat grid as viable only if fresh-save play remains fully
  supported and the cap is demonstrably shallow.

These are investigation priorities, not accepted features.

## Limitations

- No structured post-change play-attempt data exists yet.
- No external comparison source has been added in this pass; the future source
  budget is deliberately bounded.
- The current persistence implementation contains a field-module flag with no
  observed unlock path, so it should not be treated as a complete prior model.
- A solo player's desired balance between mastery and accumulation is a product
  preference that code inspection cannot decide.

## Decision Status

No model is selected. No difficulty or death-persistent progression code is
authorized by this document.
