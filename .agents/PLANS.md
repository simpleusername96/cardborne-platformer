---
type: policy
status: active
canonical_for: Repository planning artifact policy
scope: .agents/execplans
---

# Planning Artifact Policy

## Purpose

Create durable planning artifacts only when they reduce material uncertainty or execution risk, and give future executors one decision-complete contract and one progress source.

## Scope

This policy applies to research checklists and execution contracts under `.agents/execplans/`. It does not make a durable artifact mandatory for every task.

## Rules

Use a durable artifact for cross-cutting or multi-phase work; API, save-data, resource-schema, or public-contract changes; operationally risky work; changes spanning more than five files; bounded research or owner decisions; and work for which the user explicitly requests a durable plan.

Do not use one for simple Q&A, single-note placement judgments, small one-file edits, routine note capture, or work where repository instructions and a concise chat update are sufficient.

- Store every durable research checklist or execution contract under `.agents/execplans/`.
- Name it `YYYY-MM-DD-<outcome-slug>.md`; update the existing artifact for the same outcome instead of creating revision copies.
- Use `$goal-checklist-builder` to author or materially revise it.
- Keep task-specific findings and decisions in the relevant plan.
- Put reusable synthesis in `.agents/research/` and record what each consuming plan accepts, rejects, or adapts.
- Put retained screenshots, logs, measurements, render comparisons, and other proof in `.agents/evidence/` and link them from the consumer.
- When a research conclusion becomes accepted project truth, update its canonical spec, record, or runbook and keep the research advisory.
- Use task checkboxes as the only progress ledger. Do not mirror active task state into policy, memory, or a second plan.
- Mark completed work `done`; archive, move, or delete stale plans only with explicit user approval.

## Exceptions

The user may explicitly request a durable plan for smaller work or waive one when a narrower checklist and immediate validation control the same risk.
