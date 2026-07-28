---
type: evidence
status: active
owner: BK
created: 2026-07-28
last_reviewed: 2026-07-28
topic: Constraints and decision boundaries for Cardborne combat-growth review
scope: Product, architecture, evidence, privacy, and rejected-direction boundaries
source: ../../../AGENTS.md
related:
  - ./README.md
  - ./current-state.md
  - ./source-map.md
  - ../../product/vehicle_game_spec.md
  - ../../product/combat-growth-improvement-direction.md
---

# Constraints and Decisions

## Purpose

This document tells the external reviewer which boundaries are already
authoritative, which statements are only current observations, and which
proposals remain open to challenge.

## Sources

- `../../../AGENTS.md`
- `../../product/vehicle_game_spec.md`
- `../../design/UI_VISUAL_SYSTEM.md`
- Current code and validators in `source-map.md`
- User feedback summarized in `current-state.md`

## Findings

### Must preserve

- Godot 4.7 stable and GDScript
- manual aim and held primary fire
- the one-second opening Breach Shot
- dash, passive Seeker support, optional secondary families, and EMP
- the connected five-stage authored run
- run-selected fields, map pickups, card choices, stage bosses, and the
  repository's optional-field-boss product intention
- complete Korean and English user-facing text
- fair startup telegraphs and first-clear readability
- bounded actor, projectile, and presentation budgets
- deterministic scheduling and focused validators
- the flat-color Sunken Ceramic Fresco visual system
- card behavior outside UI code
- visual geometry independent from collision truth

### User-stated preferences

- The fun target is progression toward large-group clearing, not merely
  surviving longer.
- Herding should matter, either through build geometry, enemy formations, or
  intentional terrain use.
- Bosses must feel like distinct bosses.
- Upgrade randomness should be constrained and understandable.
- Ship-mounted upgrade weapons do not each need a separate art asset.
- Analysis should precede implementation.

### Current observations, not accepted design

- The current deterministic offer rules are real, but their constraint goals
  emphasize build safety more than guaranteed transformation.
- Active enemy count is not the same as engaged density.
- Existing terrain pieces are functional but do not consistently close a
  mass-kill loop.
- Current boss phases are mainly pattern-order and cadence phases.
- Optional field-boss reward plumbing is not a live optional encounter.

### Draft proposals that remain reviewable

The external reviewer may accept, modify, or reject all of the following:

- Foundation → Specialization → Evolution as the growth taxonomy
- Stage 1–4 boss-only Evolution offers
- regular level-up redistribution from `7/4/3/3/4` to `5/4/4/4/4`
- three evolution archetypes: line breaker, priority converter, wake controller
- grouping eight squads into two or three pressure fronts
- authored formation names and compositions
- Breakthrough chain feedback at eight kills in two seconds
- one field-specific player-triggered enemy-processing interaction per field
- 12–18 finite ordinary adds during boss phases
- the proposed five boss-specific arena/objective directions
- the Stage 1 acceptance targets for density, kill burst, and environment kills

### Must avoid

- switching engines or adding production dependencies
- replacing manual target priority with full auto-aim
- solving the issue by raising active caps before measuring engagement
- solving boss identity with HP, speed, or projectile volume alone
- adding six or more simultaneous weapon slots or a large shop economy
- multiplying content into hundreds of cards, weapons, or characters
- full procedural destruction or mining
- placing new card policy or behavior in UI code
- adding all new encounter, terrain, reward, and boss state to
  `vehicle_run.gd` without respecting existing owners
- treating passing tests as proof of fun
- treating the external model as source of truth
- implementation, patches, dependency installation, destructive commands, or
  git-state changes during the external review

### Previously rejected reference imports

- Vampire Survivors-style automatic combat and 6+6 slot breadth
- Brotato-style six-weapon shop economy
- Soulstone Survivors-scale content and meta systems
- Deep Rock Galactic: Survivor's full procedural mining loop
- Nova Drift's 200+ upgrade breadth and harsh self-damage assumptions
- arbitrary active-cap increases
- boss HP inflation without semantic state

### Authority and implementation-evidence hierarchy

For product and agent constraints:

1. Current user intent and the active instruction chain
2. Root and nearest `AGENTS.md`
3. Active `docs/product/vehicle_game_spec.md`
4. Active `docs/design/UI_VISUAL_SYSTEM.md`
5. Current code, resources, and executable tests as implementation evidence
6. Active evidence documents
7. This handoff package
8. Draft improvement direction
9. External reviewer feedback

When deciding what **currently executes**, current code and executable tests
override narrative summaries that describe implementation. They do not override
higher-authority product, architecture, safety, or operating constraints.

An external recommendation becomes actionable only after Codex validates it
against the relevant current code, tests, and active constraints, and the user
accepts any material product change.

### Privacy and publication boundary

Do not inspect, include, or publish:

- credentials, tokens, `.env` files, private keys, unrelated private account
  data, or personal exports;
- `.godot/`, `.codex-runtime/`, temporary build outputs, ignored caches, or raw
  chat/browser transcripts;
- unrelated generated art evidence merely because it is present in history.

The workspace path and project remote URL are intentionally included as
authorized access locations required for this handoff. They are not permission
to expose the repository, credentials, or unrelated local data. The remote may
be access-controlled; the reviewer must use authorized access or the local
workspace and must not request that the repository be made public.

## Recommendations

- Challenge the draft before proposing implementation.
- Name exact files and symbols for every material conclusion.
- Separate a minimal vertical slice from later content expansion.
- Mark every unverified gameplay claim as needing runtime or human playtest.
- Prefer reusing current roles, cards, terrain primitives, and state owners.

## Limitations

- The user has not yet accepted the draft improvement direction as the product
  contract.
- Exact damage, cadence, quota, and duration tuning remains open.
- No current telemetry measures engaged density, kill bursts, evolution
  timing, or semantic boss-phase comprehension.
