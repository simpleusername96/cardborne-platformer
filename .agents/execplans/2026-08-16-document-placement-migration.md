---
type: plan
status: done
created: 2026-08-16
scope: Separate authoritative Cardborne project documentation from reusable agent research and retained validation evidence
---

# Document Placement Migration - Execution Contract

## Purpose

- Objective: keep accepted product and visual knowledge under `docs/`, place reusable advisory analysis under `.agents/research/`, and place retained proof under `.agents/evidence/`.
- Deliverable: a history-preserving document move, corrected links and lifecycle paths, and explicit repository placement guidance.
- Completion state: every listed file has its predetermined owner, no stale old path remains, and the active visual workbench is unchanged.

## Scope and Boundaries

In scope:

- The exact Markdown and evidence paths named in Discovery Closure.
- Root and `.agents` placement guidance, indexes, frontmatter paths, and inbound links affected by those moves.

Out of scope:

- Runtime code, scenes, assets, tests, balance, gameplay, and UI changes.
- `docs/design/visual-replacement-workbench/**`; it is an active production design workbench, not general research.
- Historical implementation plans in `docs/reports/`, `.agents/completed-plans/**`, and unrelated document lifecycle cleanup.
- Repairing pre-existing broken `superseded_by` links in historical reports.

Constraints:

- Use `git mv` and preserve the bytes and relative structure of coherent bundles.
- Do not delete, archive, rewrite conclusions, or change lifecycle status as part of placement work.
- Preserve all unrelated worktree changes; stage only this contract's later migration paths.

## Discovery Closure

| Disposition | Exact paths | Locked reason |
| --- | --- | --- |
| Keep as authoritative project docs | `docs/README.md`; `docs/product/README.md`; `docs/product/vehicle_game_spec.md`; `docs/product/vehicle_upgrade_catalog.md`; `docs/product/vehicle_weapon_balance_spec.md`; `docs/design/VISUAL_SYSTEM.md` | Maintained product or design authority |
| Keep with production owner | `docs/design/visual-replacement-workbench/**` | Active asset-production workbench and rendered deliverable |
| Move to `.agents/research/performance/` | `.agents/research/performance/2026-08-02-enemy-movement-spawn-research.md`; `.agents/research/performance/2026-08-11-enemy-scale-performance-research.md`; `.agents/research/performance/cardborne-runtime-architecture-audit.md`; `.agents/research/performance/combat-clarity-runtime-difficulty-analysis.md`; `.agents/research/performance/2026-08-13-dense-enemy-architecture-options.md`; `.agents/research/performance/2026-08-13-enemy-arrival-and-engagement-research.md` | Reusable codebase and performance synthesis; advisory, not policy |
| Move to `.agents/research/reports/` | `.agents/research/reports/2026-08-11-vehicle-upgrade-idea-catalog.md`; `.agents/research/reports/2026-08-13-upgrade-artwork-reference-analysis-ko.md`; `.agents/research/reports/assets/upgrade-artwork-reference-analysis/**`; `.agents/research/reports/2026-08-14-game-telemetry-and-feedback-research.md`; `.agents/research/reports/2026-08-14-upgrade-category-language-review.md`; `.agents/research/reports/2026-08-15-eight-boss-combat-design-analysis.md`; `.agents/research/reports/2026-08-16-boss-pattern-density-research.md` | Reusable design and reference analysis, including the artwork study's required source bundle |
| Move to `.agents/evidence/performance/` | `.agents/evidence/performance/2026-08-13-dense-enemy-stutter-evidence.md`; `.agents/evidence/performance/2026-08-13-dense-enemy-conclusion-ko.md`; `.agents/evidence/performance/2026-08-13-enemy-arrival-conclusion-ko.md`; `.agents/evidence/performance/vehicle-performance-evidence.jsonl`; `.agents/evidence/performance/evidence/**`; `.agents/evidence/performance/semantic-v2-runtime-acceptance-evidence.md` | Measurements, conclusions tied to captures, and runtime acceptance proof |
| Move to `.agents/evidence/reports/` | `.agents/evidence/reports/2026-08-11-anomaly-device-runtime.md`; `.agents/evidence/reports/2026-08-12-player-facing-terminology-audit.md`; `.agents/evidence/reports/2026-08-15-combat-readability-pressure-review.md`; `.agents/evidence/reports/2026-08-15-eight-boss-combat-approval-ko.md`; `.agents/evidence/reports/2026-08-16-boss-pattern-density-problem-brief.md`; `.agents/evidence/reports/game-system-review/effects-upgrades-as-is.md` | Audits, approvals, and observed-state evidence |
| Leave unchanged | Other `docs/reports/**`; `.agents/completed-plans/**` | Historical plan lifecycle is a separate owner-approved cleanup |

The classification and target paths are closed. No executor research or content reclassification remains.

## Tasks

### Phase 1: Establish placement owners

- [x] **1.1 Update repository guidance.** Add the `docs` / `.agents/research` / `.agents/evidence` authority boundary to the root and `.agents` guidance without adding a full directory inventory.
  - Accept: guidance states that accepted project truth stays in its documentation owner, research is advisory synthesis, and evidence proves observations or checks.
- [x] **1.2 Capture a source manifest.** Record each source path and SHA-256 before moving bundles.
  - Accept: every listed source exists and the manifest has one unique target per source.

### Phase 2: Move the locked document sets

- [x] **2.1 Move performance research and evidence with `git mv`.** Preserve the nested `.agents/evidence/performance/evidence/**` structure under `.agents/evidence/performance/evidence/**`.
  - Accept: every old path is absent, every mapped target exists, and target hashes match the manifest.
- [x] **2.2 Move report research and evidence with `git mv`.** Preserve any companion assets required by a listed document; do not touch the visual workbench.
  - Accept: every listed document has exactly one target and no workbench path appears in the diff.

### Phase 3: Repair the document graph

- [x] **3.1 Update frontmatter and inbound links.** Repair `related`, `supersedes`, and ordinary Markdown references in moved files and their consumers, including performance reports and upgrade/boss report cross-links.
  - Accept: no tracked file references a moved old path; all changed relative links resolve.
- [x] **3.2 Preserve authority.** Update indexes only where they enumerate moved files; do not promote any research conclusion into a spec in this migration.
  - Accept: canonical product/design files are unchanged except for necessary link updates.

### Phase 4: Validate and close

- [x] **4.1 Run the final document checks.** Run `git diff --check`, `git diff --name-status -- docs .agents AGENTS.md`, and targeted `rg -n --hidden` searches for every old path stem.
  - Accept: checks pass, no runtime path is changed, and all moved targets match the source manifest.
- [x] **4.2 Close this contract.** Record concise evidence, set `status: done`, and commit only migration-owned files.

## Validation and Rework Controls

- Use `Test-Path` and SHA-256 checks after each move batch.
- Run stale-path `rg` after link repair, not repeatedly before inputs change.
- Do not run Godot or visual workbench validation because the migration does not change runtime or the workbench. If the workbench enters the diff, stop and remove that scope before continuing.
- A failed link check may be rerun only after the responsible path or link changes.

## Predetermined Contingencies and Change Control

- If a listed Markdown file requires an adjacent image or HTML asset to remain meaningful, move that coherent asset bundle to the same research or evidence subtree and add it to the manifest.
- If a target path already exists with different bytes, stop that move and revise this contract; do not overwrite or create a revision suffix.
- If an unrelated dirty file overlaps a planned path, stop the overlapping batch and obtain owner direction.
- Any new reclassification, archive, deletion, or promotion into canonical docs requires a revised contract and owner approval.

## Progress and Next Steps

- Canonical progress: the checkboxes in this contract.
- Current phase: complete.
- Source manifest: 43 files; pre-move aggregate SHA-256 `AE309D0EC44517F659497EF1881B83B85B0B3AA8D3316CDA89B294A6EDB552A9` over sorted `source|file-hash` lines.
- Last completed gate: fixed Preflight, lifecycle sections, Markdown/frontmatter links, stale-path scan, workbench exclusion, scope, and `git diff --check` passed.

## Completion and Stop Conditions

Complete only when every task and final check passes and the frontmatter is `done`. Replan if a mapped file has changed authority or a coherent bundle cannot be moved without expanding scope. Do not replan for mechanical link corrections already bounded above.
