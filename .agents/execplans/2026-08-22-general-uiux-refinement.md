---
type: plan
status: active
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

### Core-surface contract and line-removal pass

- [x] Record the user's selected HUD direction and the new line/empty-space constraints.
- [x] Refresh the complete visual-authority preflight after the canonical specification changed.
- [x] Inspect the retained current-worktree captures and source owners for all ten core surfaces.
- [x] Lock one shared density and boundary-economy grammar plus a page-specific size and information contract.
- [ ] Generate and inspect one coherent 1280×720 image for each core surface: Deployment, Upgrade, Pause, Settings, Guidebook, Stage Report, Failure Report, Result, HUD, and Message.
- [ ] Update the Korean report with the full contract, ten-screen image set, prompt provenance, and concept-only status.
- [ ] Validate the canonical authority, dimensions, hashes, local links, and task-only diff; commit only this pass.

Pass gate: every normal static separator must justify actual containment or state, no content body keeps an unexplained 48 px vertical or 64 px horizontal void, and all ten images share the selected bluegray/cyan direction without turning static rows into bordered cards.

### Required-surface correction: Upgrade, Message, and HUD

- [x] Record that Deployment, Guidebook, and Stage Report do not satisfy the required three-surface deliverable.
- [x] Refresh the complete visual-authority preflight for the expanded Upgrade, auxiliary-message, and full-HUD scope.
- [x] Capture the latest Korean 1280×720 core UI set from the current worktree and inspect the Upgrade, HUD, and live announcement states.
- [x] Trace the current Upgrade, HUD, announcement, and localization owners so generated copy and placement stay within the product contract.
- [x] Generate and inspect one independent 1280×720 concept each for Upgrade, Message, and HUD with the canonical style sheet supplied as an actual image reference.
- [x] Add the three required images and their decisions to the Korean report; explicitly demote the previous three-screen set to exploratory evidence.
- [x] Validate authority, report-local links, retained image hashes, and the task-only diff; commit only this correction.

Correction gate: the report must visibly include three separate images whose primary subjects are Upgrade, Message, and the complete HUD. The three images must share the selected bluegray/cyan system without turning every HUD element into a panel.

### Compact information-layout continuation

- [x] Record the user's preference for the bluegray/cyan palette and retain the player-craft identity preview.
- [x] Refresh the visual-authority preflight after the canonical specification hash changed.
- [x] Gather focused references for compact control legends and dense game information layouts.
- [x] Lock a shared spacing/grouping grammar that removes distributed label/value gaps.
- [x] Generate and inspect one coherent mockup each for Deployment, Guidebook, and Stage Report.
- [x] Update the Korean evidence report with the focused references and three-screen decisions.
- [x] Validate authority, image hashes, local links, and the task-only diff; commit only this continuation.

Continuation gate: all three screens must use the same bluegray/cyan system, explain every retained image and width, and keep related labels, inputs, values, and units in one perceptual group.

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
- Spec SHA-256: `c8dde49b2506d01b4ff298622b0bf31a233f141c4ea609d8a42a7a17a01fb560`.
- Canonical style reference: `docs/design/cardborne-universal-art-style-reference.png`; inspected at original 1448×1086 detail on 2026-08-22.
- Expected and observed PNG SHA-256: `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- Original provenance: `C:/Users/BK/.codex/generated_images/019fbfe9-857e-7453-b72d-20908d848577/exec-0b8aa606-cf55-45c1-abb3-fb3df762b080.png`, 2026-08-02 12:13:44 KST.
- Task constraints: information-first modals; Upgrade uses a compact current-build rail plus exactly three selectable rows and one fixed Equip action, with inline stat phrases instead of distributed blank columns; normal messages use one auxiliary AI Surface directly below the minimap; HUD uses two full-width top meters, one panel-free top-left status cluster, and only the minimap plus announcement as subtle Surfaces; one shared code-native Theme and six primitives; one boundary and at most one semantic rail; no nested frames, micro-panels, decorative seams, raster UI chrome, baked text, center banners, toast stacks, bottom-center active indicator, or redundant objective/boss/upgrade panels; Noto Sans KR; 44 px minimum targets where interactive; visible non-color focus/selection; Korean/English and 960/1280/1920 fit; dominant broad masses, matte planes, dark separation, sparse semantic accents.
- ImageGen rule: every call must receive the canonical repository PNG through `referenced_image_paths`; the prompt must state that it supplies style grammar only and must not be copied.
- Approval status: analysis evidence only; no generated image is approved for production or runtime integration.
- Receipt refresh: the expanded Upgrade/Message/HUD scope triggered a fresh preflight. The full current 952-line document and the original-detail PNG were re-inspected on 2026-08-22. Current-worktree Korean 1280×720 evidence was captured once and the three inspected frames were retained under `docs/reports/assets/2026-08-22-general-uiux-analysis/current-head-upgrade-message-hud/`: `06b-first-weapon-selected.png`, `04c-progression-max.png`, and `03-peak-horde.png`. Every retained ImageGen call received the canonical repository PNG through its actual image-reference input.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this file.
- Current phase: complete.
- Next task: none in this concept-and-evidence scope. Runtime implementation requires explicit approval because it changes the shared row primitive, three screen owners, and current visual specification wording.
- Last completed gate: the required visual set now contains one independent 1280×720 Upgrade page, one live Message state, and one complete HUD frame. Upgrade keeps three comparison rows and local stat phrases; Message stays directly beneath the minimap in one bounded Surface; HUD keeps top meters and the left status cluster panel-free. The prior Deployment/Guidebook/Stage Report set remains exploratory evidence and is no longer presented as satisfying this requirement. The Cardborne visual-authority validator passed, all 14 report-local links resolved, the three final hashes matched the report, and `git diff --check` passed with only the repository's existing LF-to-CRLF notices.
- Update rule: preserve passing evidence until a relevant owned input changes; do not repeat the full capture for reassurance.

## Completion and Stop Conditions

Complete when the current UI evidence, bounded source set, selected direction, inspected mockups, and Korean report all exist; every retained visual is labeled concept-only; and the plan status is `done` after the scoped commit succeeds.

Escalate when a canonical authority hash changes, a required current UI state cannot be captured, external evidence conflicts with product constraints, or production promotion is requested without explicit approval.
