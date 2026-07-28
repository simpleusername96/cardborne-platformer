---
type: handoff
status: active
owner: BK
created: 2026-07-28
last_reviewed: 2026-07-28
expires: 2026-08-28
topic: External review of Cardborne combat growth, horde, terrain, and boss design
scope: Read-only review of the current five-stage vehicle campaign and the unaccepted improvement draft
source: ../../../.agents/survivor-shooter-combat-growth-reference-study.md
related:
  - ../../../AGENTS.md
  - ../../product/vehicle_game_spec.md
  - ../../product/combat-growth-improvement-direction.md
  - ./external-model-prompt.md
---

# Cardborne Combat Growth, Horde, Terrain, and Boss Review Handoff

## Current State

Objective: obtain an independent, code-aware critique of why Cardborne's current
five-stage vehicle run does not yet deliver a strong
`herd enemies → wipe a dense group → feel a qualitative power jump → face a
distinctive boss` loop, and determine the smallest coherent improvement slice.

- Intended reviewer: an external code-aware model such as Claude Code,
  ChatGPT Pro, Gemini, or an equivalent reviewer
- Review mode: read-only analysis; no implementation or patch generation
- Workspace: `D:\npjt\cardborne-platformer`
- Branch: `master`
- Gameplay/research baseline before this handoff:
  `57346d9f6c645aaa80d6b5ca3f0a909bb7898fc2`
- Dirty state before package creation: clean
- Remote: `https://github.com/simpleusername96/cardborne-platformer`
- Remote access note: authenticated Git access is available; unauthenticated
  HTTP returned 404, so a reviewer must use this local workspace or authorized
  repository access
- Engine: Godot 4.7 stable, GDScript

The baseline contains the evidence study at commit `624f807` and a later
docs-only visual-direction commit. This handoff does not change gameplay.

### Reading order

1. `external-model-prompt.md`
2. `current-state.md`
3. `constraints-and-decisions.md`
4. `source-map.md`
5. `../../../AGENTS.md`
6. `../../product/vehicle_game_spec.md`
7. `../../../.agents/survivor-shooter-combat-growth-reference-study.md`
8. `../../product/combat-growth-improvement-direction.md`
9. Current code and validators named in `source-map.md`

### Requested result

The reviewer should:

- verify or correct the current-state diagnosis with exact code evidence;
- evaluate the proposed growth, formation, terrain, and boss direction rather
  than merely summarize it;
- label each proposal `accept`, `modify`, `reject`, or
  `needs-local-verification`;
- produce a smaller, ordered Stage 1 vertical slice if the current draft is too
  broad;
- identify metrics and playtest evidence required before tuning quotas, active
  caps, damage, or progression;
- distinguish current fact, inference, recommendation, and unresolved
  uncertainty.

## Next Steps

1. Give the external reviewer access to this local workspace or the authenticated
   `master` branch.
2. Copy the prompt body from `external-model-prompt.md` if the model is not
   operating directly in the repository.
3. Have the external reviewer return one Markdown response without editing the
   repository.
4. The local coordinator saves that returned response unchanged in
   `external-review-raw.md`.
5. Ask Codex to validate every material recommendation against current code,
   docs, and tests before any implementation plan is created.
6. Mark this handoff `done` or archive it after the external response has been
   reconciled.

## Risks

- `combat-growth-improvement-direction.md` is a draft, not the active product
  contract. The reviewer must be willing to reject its assumptions.
- Static inspection can establish rules and ownership but cannot prove fun,
  actual engaged density, time-to-clear, or boss comprehension.
- Existing validators encode current contracts; some will need deliberate
  revision if an accepted design changes those contracts.
- `README.md` at the repository root has a stale active-cap summary. Exact
  encounter values must come from the active spec and current code.
- The optional field-boss intention exists in repository guidance and reward
  plumbing, but no live optional field-boss encounter was found.
- External feedback is advisory and cannot override code, tests, `AGENTS.md`,
  or the canonical product and visual specifications.
