---
type: plan
status: done
created: 2026-08-22
scope: General Cardborne UI/UX analysis and to-be mockups
related:
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/reports/2026-08-22-general-uiux-analysis-ko.md
---

# General UI/UX Refinement - Research Checklist

## Purpose

- Decision: define a clear, simple, Cardborne-native direction for Deployment, Upgrade, Pause, Settings, Guidebook, Stage Report, Failure Report, and Result.
- Why it matters: the current panels are hard to scan and do not yet express one coherent information hierarchy.
- Decision owner: BK.
- Final output: a Korean analysis report, current-version capture evidence, and ImageGen to-be UI mockups. This checklist does not authorize runtime UI implementation or asset approval.

## Scope and Evidence Contract

- In scope: current UI hierarchy and ownership, supported modal states, Korean-first comprehension, keyboard/controller focus, responsive behavior, cross-screen visual grammar, and concept mockups.
- Out of scope: runtime implementation, gameplay changes, new dependencies, production asset promotion, and approval of generated pixels.
- Destructive or irreversible actions: none.
- Approval required before: promoting any generated mockup or derived asset into production.
- Search budget: 12-18 high-quality external sources across at least six comparable products or systems, plus current local design/product authority and current-HEAD captures.
- Conflict rule: current product and visual specs override external references; the canonical style sheet is grammar-only and never asset approval.
- Stop rule: stop gathering when each panel family has at least one actionable reference pattern and new sources no longer change a recommendation.

| Evidence category | Primary source | Freshness requirement | What it must establish | Sufficient evidence |
| --- | --- | --- | --- | --- |
| Product intent | `docs/product/vehicle_game_spec.md` | current worktree | required flow and player tasks | all analyzed panels mapped to real tasks |
| Visual authority | `docs/design/VISUAL_SYSTEM.md` + canonical PNG | current hash | binding style, layout, state, and accessibility constraints | complete read, original-detail inspection, hash receipt |
| Current UI | current source owners + Godot capture harness | current HEAD/worktree identity | actual hierarchy, density, clipping, and cross-screen consistency | Korean 1280×720 core capture set and focused source trace |
| External patterns | official pages, manuals, accessibility guidance, reputable UX sources | current or stable | transferable information architecture and control patterns | 12-18 sources, 6+ comparable systems, applicability recorded |
| To-be direction | ImageGen using the canonical PNG as actual reference | generated in this task | whether the proposed hierarchy and style can coexist | at least two panel-family mockups inspected and labeled unapproved |

## Viable Options

| Option | Why materially viable | Decision criteria | Disqualifier |
| --- | --- | --- | --- |
| A. One shared utilitarian shell | maximum consistency and low implementation risk | task clarity, density, responsiveness | feels generic or loses game identity |
| B. Shared shell with role-coded rails | keeps one component grammar while distinguishing screen purpose | comprehension, Cardborne fit, restrained semantics | ornamental chrome or color-only meaning |
| C. Screen-specific themed panels | strongest per-screen expression | theme and immediate recognition | competing owners, nested frames, inconsistent navigation |

## Tasks

### Correction pass: challenge foundational assumptions

- [x] Record the user's rejection of the previous wide navy/amber, asset-heavy direction.
- [x] Refresh the complete visual-authority preflight for the expanded scope.
- [x] Decide asset use by information value instead of decoration.
- [x] Compare neutral palette directions instead of inheriting navy/amber by default.
- [x] Replace maximum-width defaults with content-fit width bands per panel family.
- [x] Generate and inspect corrected ImageGen concepts under the revised assumptions.
- [x] Revise the Korean report, mark the prior concepts rejected, validate, and commit only task-owned changes.

Correction gate: the revised direction must explicitly answer why each retained asset, accent color, and panel width exists.

### Phase 1: Establish current truth

- [x] Create `feat/general-uiux-refinement` without disturbing pre-existing worktree changes.
- [x] Complete the UI/UX and visual-authority preflight.
- [x] Inspect the latest valid Korean UI capture set and the current source owners; record the current-HEAD capture blocker.

Phase gate: every panel is mapped to current rendered and source evidence.

### Phase 2: Gather decisive references

- [x] Gather and classify the bounded external reference set.
- [x] Record concrete transferable patterns and rejected/non-applicable patterns.

Phase gate: each panel family has evidence that can change or support a recommendation.

### Phase 3: Diagnose and decide

- [x] Compare current panels against task hierarchy, consistency, accessibility, and the canonical visual grammar.
- [x] Select one cross-screen direction and record screen-specific priorities and implementation boundaries.

Phase gate: facts, inferences, recommendations, and user approval boundaries are separated.

### Phase 4: Visualize and report

- [x] Generate project-bound to-be UI mockups with the canonical style PNG supplied as an actual reference.
- [x] Inspect generated images at intended presentation size and label them concept-only/unapproved.
- [x] Write the Korean analysis report with local evidence, external links, rejected alternatives, and phased recommendations.
- [x] Validate the report, authority evidence, retained files, and task-only diff.
- [x] Commit only task-owned files with a scoped commit body.

Phase gate: the report links current evidence and mockups, and all retained files are reproducible and correctly classified.

## Visual Authority Receipt

- Canonical spec: `docs/design/VISUAL_SYSTEM.md`; read completely on 2026-08-22.
- Spec SHA-256: `cd44b5f672043d68af4ee5c7bdc140ff81cadcd4a05cf3a9ed4850bad458e798`.
- Canonical style reference: `docs/design/cardborne-universal-art-style-reference.png`; inspected at original 1448×1086 detail on 2026-08-22.
- Expected and observed PNG SHA-256: `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- Original provenance: `C:/Users/BK/.codex/generated_images/019fbfe9-857e-7453-b72d-20908d848577/exec-0b8aa606-cf55-45c1-abb3-fb3df762b080.png`, 2026-08-02 12:13:44 KST.
- Task constraints: information-first modals; one shared code-native Theme and six primitives; one boundary and at most one semantic rail; no nested frames, micro-panels, decorative seams, raster UI chrome, or baked text; Noto Sans KR; 44 px minimum targets; visible non-color focus/selection; Korean/English and 960/1280/1920 fit; dominant broad masses, matte planes, dark separation, sparse semantic accents.
- ImageGen rule: every call must receive the canonical repository PNG through `referenced_image_paths`; the prompt must state that it supplies style grammar only and must not be copied.
- Approval status: analysis evidence only; no generated image is approved for production or runtime integration.
- Receipt refresh: the spec changed concurrently after generation. The full 952-line document and the original-detail PNG were re-inspected on 2026-08-22. The change updates enemy-upgrade-device publication behavior and does not alter the modal, typography, responsive, focus, or media-ownership constraints used by these concepts, so regeneration is not required.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this file.
- Current phase: complete.
- Next task: none in this analysis scope. Runtime implementation requires a new approval decision because it changes the canonical visual specification and shared UI owners.
- Last completed gate: the corrected Korean report, current-worktree snapshots, three inspected palette/density experiments, and rejected prior concepts are retained. Local links and the three correction image hashes passed; the Cardborne visual-authority validator passed with the expected canonical sheet hash; the task-only diff passed `git diff --check`.
- Update rule: preserve passing evidence until a relevant owned input changes; do not repeat the full capture for reassurance.

## Completion and Stop Conditions

Complete when the current UI evidence, bounded source set, selected direction, inspected mockups, and Korean report all exist; every retained visual is labeled concept-only; and the plan status is `done` after the scoped commit succeeds.

Escalate when a canonical authority hash changes, a required current UI state cannot be captured, external evidence conflicts with product constraints, or production promotion is requested without explicit approval.
