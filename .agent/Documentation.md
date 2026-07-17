---
type: record
status: active
owner: BK
last_reviewed: 2026-07-17
topic: Current Cardborne isometric action RPG pivot state
source: Owner pivot decision, repository reset, and active ExecPlan
related:
  - ./execplans/2026-07-17-isometric-action-rpg-pivot.md
  - ../docs/design/UI_VISUAL_SYSTEM.md
---

# Project Documentation Memory

## Context

The former side-view action-platform implementation was structurally complete but
did not meet the owner's fun target. After comparing its play with Bastion and
Hades, the owner chose to reset the runtime and explore an isometric action RPG.

## Decision

- The retired platformer runtime, typed content, scenes, stage data, validators,
  release records, and obsolete plans were removed on the pivot branch.
- Cardborne now targets a 2D top-down simulation with isometric presentation.
- The accepted art style and all project-owned art remain available.
- Traveler, weapons, defense, cards, equipment, forging, merchant, run/reward,
  persistence, and Slime King survive as product identities only; none of their
  deleted runtime behavior is implicitly accepted.
- `.agent/execplans/2026-07-17-isometric-action-rpg-pivot.md` is the active work
  source until a replacement product spec is accepted.

## Rationale

A clean runtime prevents platform movement, room geometry, contextual attacks,
and legacy validation assumptions from shaping the new combat by accident. Git
history retains the prior implementation if a specific algorithm or asset mapping
later proves worth recovering.

## Consequences

- The project currently boots an intentionally empty `PivotRoot` scene; it is not
  a playable game.
- The first implementation milestone must be a graybox combat sandbox rather than
  restoration of menus, persistence, or the former complete run.
- Old screenshots and world assets are references, not geometry or collision
  sources for the new game.
- The pre-pivot runtime can be inspected at commit `7cc069c` without reintroducing
  it into the active tree.

## Current Status

- Active branch: `agent/isometric-arpg-pivot-plan`.
- Runtime reset and research-backed plan: completed on 2026-07-17; gameplay
  implementation has not started.
- Retained authority: root `AGENTS.md`, `.agent/Prompt.md`, the active ExecPlan,
  and `docs/design/UI_VISUAL_SYSTEM.md` for art direction.

## Verification

Use `./tools/godot.ps1 --path . --headless --import` and a short headless start to
verify the empty baseline. Gameplay validation commands will be added beside the
first playable slice rather than restoring the retired release matrix.
