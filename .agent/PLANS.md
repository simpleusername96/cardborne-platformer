# .agent/PLANS.md

## ExecPlan Standard

Use an ExecPlan for:
- cross-cutting work
- API, save-data, or resource schema changes
- gameplay systems spanning more than one subsystem
- operationally risky work
- changes spanning more than 5 files

Do not use an ExecPlan for:
- simple Q&A or classification opinions
- single-note placement or linking judgments
- small one-file edits
- routine raw-note captures or append-only note saves
- work where root/local `AGENTS.md` plus a concise chat update is enough

When writing an ExecPlan:
- reference root `AGENTS.md` and the nearest local `AGENTS.md` for durable constraints
- ground scope in the PRD and current project files
- do not infer a lasting contract from a transient folder layout alone

## Lifecycle
- Active ExecPlans are working documents for the task they describe.
- At completion, promote durable lessons into root `AGENTS.md`, local `AGENTS.md`, `.agent/Documentation.md`, or a repo-local skill when they should affect future work.
- Do not treat completed ExecPlans as current operating guidance unless a current guidance file links to them.
- Stale, duplicate, or low-value completed ExecPlans may be archived or deleted only when the user explicitly approves that cleanup.

## Required Sections
- Why / Context
- Scope / Non-scope
- Assumptions
- Proposed Design
- Milestones
- Test Plan
- Rollback / Safety
- Risks
- Open Questions
- Decision Notes
