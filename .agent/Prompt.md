---
type: policy
status: active
owner: BK
last_reviewed: 2026-07-15
topic: Durable product direction and implementation constraints for Cardborne
source: Active PRD, project guidance, and owner decisions through 2026-07-15
related:
  - ../docs/product/2d_platform_action_card_game_prd.md
  - ./execplans/2026-07-15-gameplay-validity-repair.md
---

# .agent/Prompt.md

## Purpose
- Build Cardborne's first complete run: a compact 2D action-platform roguelite where readable movement and combat earn choices that visibly change the rest of the run.

## Scope
- Durable product direction and implementation constraints for the one-Traveler,
  three-stage, browser-delivered vertical slice.

## Goals
- Responsive traversal and minimal contextual combat for one persistent Traveler.
- One contextual attack, one shield guard, one potion action, and no active skill
  unless a later playtest justifies at most one.
- Three approved fixed stages assembled from validated authored room templates.
- Six readable enemy archetypes with exact stage variants, hazards, optional
  risk/reward routes, fall-recovery points, meaningful verticality, and no soft locks.
- Run levels, behavior-changing cards, equipment, a safe intermission merchant,
  and deterministic forging with clear ownership.
- One authored, readable two-phase Giant Slime King fight.
- A 28-38 minute run that is fun to replay before content breadth or presentation polish expands.

## Non-Goals
- Online multiplayer.
- Arbitrary platform scattering or unrestricted procedural geometry.
- Open-world exploration, live service, monetization, or final production-scale content.
- Random upgrade failure, item destruction, downgrade outcomes, or grind required to finish a first run.
- New external dependencies or assets without explicit approval and adoption evidence.

## Rules
- Use the PRD in `docs/product/2d_platform_action_card_game_prd.md` as active spec.
- Use `docs/README.md` for the complete authority order and the active ExecPlan for implementation order.
- Use GDScript for MVP implementation.
- Keep cards, equipment, encounters, and room metadata data-driven and separate
  from UI/player special cases.
- Derive required traversal limits from the least-capable baseline profile and reject invalid stages before play.
- Resolve enemy generation as pressure role -> archetype -> exact stage variant;
  never roll hidden per-instance combat stats.
- Keep direct damage deterministic and critical hits tied to declared player-earned
  conditions rather than baseline luck.
- Every damaging boss pattern must telegraph before damage.
- Every gameplay milestone must produce a visible playable path and be checked against the PRD fun contract.
- Validate the shipped path as a browser export with keyboard gameplay and
  keyboard/mouse menus.
- Player-facing explanations support concise Korean and English.

## Common Flows
- Check Godot with `.\tools\godot.ps1 --version`.
- Use `.\tools\godot.ps1 --path . --headless --import` for a fast project sanity check.
- Use the Godot editor for scene-heavy work when possible, then inspect generated diffs.

## Local Guidance Boundaries
- Root `AGENTS.md` carries repo-wide guidance.
- `.agent/*` carries durable working memory and milestone planning.
- No subtree-specific `AGENTS.md` files exist yet.
