---
type: policy
status: active
owner: BK
last_reviewed: 2026-07-22
canonical_for: Repository ExecPlan usage and lifecycle
---

# ExecPlan Standard

## Purpose

Require durable execution plans only when they materially reduce cross-system or
operational risk.

## Scope

This policy governs plans stored under `.agents/execplans/`. It does not require
a plan for small, direct, or read-only tasks.

## Rules

Use an ExecPlan for:

- cross-cutting work;
- API, save-data, or resource-schema changes;
- gameplay systems spanning more than one subsystem;
- operationally risky work;
- changes spanning more than five files.

Do not use an ExecPlan for:

- simple Q&A or classification opinions;
- single-note placement or linking judgments;
- small one-file edits;
- routine raw-note captures;
- work where the active specifications and a concise chat update are sufficient.

When writing an ExecPlan:

- reference root `AGENTS.md` and the nearest local `AGENTS.md`;
- ground scope in `docs/product/vehicle_game_spec.md` and current project files;
- include Why/Context, Scope/Non-scope, Assumptions, Proposed Design,
  Milestones, Test Plan, Rollback/Safety, Risks, Open Questions, and Decision
  Notes;
- keep it active only while its work remains;
- incorporate accepted product behavior into the active specification and
  durable operating rules into the appropriate `AGENTS.md` or repo-local skill;
- delete the completed plan after those durable decisions are incorporated.

## Exceptions

The user may explicitly request a plan for smaller work or waive a plan when the
same risk is controlled by a narrower checklist and immediate validation.
