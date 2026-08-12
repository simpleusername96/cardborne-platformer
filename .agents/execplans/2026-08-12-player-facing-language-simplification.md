---
type: plan
status: active
created: 2026-08-12
scope: Decide the canonical Korean and English names for Cardborne enemies, bosses, field objects, upgrades, and shared combat concepts
related:
  - ../../docs/reports/2026-08-12-player-facing-terminology-audit.md
  - ../../docs/reports/2026-08-12-vehicle-upgrade-categories-and-skill-tree-ko.html
  - ../../docs/reports/2026-08-12-cardborne-upgrade-feedback.json
  - ./2026-08-12-approved-upgrade-feedback-implementation.md
  - ../../localization/vehicle_stage.csv
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/product/vehicle_upgrade_catalog.md
---

# Player-Facing Language Simplification - Research Checklist

## Purpose

- Decision or research question: Which function-first vocabulary should replace the remaining flavor-heavy or conflicting player-facing terms in Korean and English?
- Why it matters: First-time players must understand threats, rewards, and state without decoding internal lore or treating synonyms as separate mechanics.
- Decision owner: BK.
- Final output: An approved bilingual terminology table that is ready for a separate implementation plan.

## Scope and Evidence Contract

- In scope: Shared combat terms, ordinary enemy and boss display names, field-object names, upgrade names, result/report labels, and Korean-English parity.
- Out of scope: Combat behavior, numeric balance, internal IDs, resource paths, save schema, and new visual assets.
- Destructive or irreversible actions: None in this decision checklist.
- Approval required before: Bulk renaming of live localization values or any internal identifier.
- Search budget or reassessment point: Use the bounded local source set; add external references only if a specific naming decision cannot be resolved from clarity and consistency criteria.
- Conflict-resolution rule: Runtime behavior and product specs define meaning; the decision owner defines the acceptable amount of flavor.
- Stop rule for unproductive exploration: Stop after every term has one recommended name and at most one materially distinct alternative.

| Evidence category | Primary source | Freshness requirement | What it must establish | Sufficient evidence |
| --- | --- | --- | --- | --- |
| Current visible vocabulary | `localization/vehicle_stage.csv` | Current worktree | Every live Korean-English label and collision | All 392 current rows grouped and reviewed |
| Runtime meaning | Gameplay owners and guidebook adapter | Current worktree | What each ambiguous label actually does | Each rename candidate maps to one observed mechanic |
| Product language | Product and upgrade specs | Active revisions | Intended public concepts and preserved distinctions | No recommendation collapses two real mechanics |
| Owner preference | BK review | Current decision | Allowed balance of clarity and flavor | One option selected and exceptions recorded |

## Viable Options

| Option | Why materially viable | Decision criteria | Disqualifier |
| --- | --- | --- | --- |
| Function-first names (recommended) | Maximizes first-clear recognition and localization consistency | A name predicts behavior without reading its description | Different mechanics become indistinguishable |
| Hybrid function plus limited flavor | Preserves boss and landmark memory while making ordinary actions clear | Flavor is limited to proper nouns and the functional role remains visible | Flavor again dominates HUD, alerts, or common categories |
| Keep current flavor-heavy names | Avoids broad copy churn and preserves existing identity | Every current name proves understandable and internally consistent | Synonyms or invented names still obscure behavior |

## Tasks

### Phase 1: Establish current truth

- [x] Read and verify the bounded source set.
- [x] Record current constraints, ownership, term collisions, and approval boundaries.
- [x] Remove the option of changing internal IDs together with display names; no current evidence justifies that migration risk.

Phase gate:

- Complete. The active terminology audit records the 392-row inventory, current collisions, immediate safe changes, and unresolved naming groups.

### Phase 2: Gather decisive evidence

- [ ] BK reviews the audit's canonical shared-term table and selects function-first or hybrid naming.
- [x] BK checks approved upgrade candidates and saves notes in the interactive upgrade HTML report.
- [ ] Convert the selected option into one bilingual candidate table for enemies, bosses, field objects, and upgrade cards.
- [ ] Record explicit exceptions where a flavor name is worth keeping.

Phase gate:

- Every naming group has one approved rule, and every exception has an owner rationale.

### Phase 3: Decide and record

- [ ] Compare surviving names against first-clear meaning, consistency, distinctiveness, and Korean-English parity.
- [ ] Separate inspected facts, naming inference, recommendation, and BK's final decision.
- [ ] Select one name per live display concept or name the exact unresolved group.
- [ ] Record rejected alternatives only when their rationale prevents future re-litigation.
- [ ] Mark whether any term needs rechecking after new enemies or upgrades are added.

Phase gate:

- The terminology table is approved or the single specific blocker is named; no implementation readiness is implied otherwise.

## Progress and Next Steps

- Canonical progress: The task checkboxes in this checklist.
- Current phase: Phase 2.
- Next task: BK reviews the audit's shared-term table and selects function-first or hybrid naming.
- Last completed gate: Current terminology and ownership are established from local primary sources.
- Upgrade-review evidence is preserved in `docs/reports/2026-08-12-cardborne-upgrade-feedback.json`;
  its implementation contract is the separate active approved-upgrade ExecPlan.
- Update rule: Check an item only when its evidence exists, and do not repeat the audit unless live localization or the decision criteria change.

## Completion and Stop Conditions

Complete when:

- Every required local source has been inspected.
- Every surviving option has been evaluated against the same clarity and consistency criteria.
- BK has selected the vocabulary rule and approved exceptions, or one exact unresolved naming group is recorded.
- The final output identifies the approved bilingual terms and the boundary between display-name and internal-ID work.
- Frontmatter status is changed to `done` after the decision or one specific blocker is recorded.

Escalate when:

- Two distinct mechanics would receive the same display name.
- Korean and English require materially different information structures.
- A requested rename would require save-data or resource-path migration.

If implementation follows, invoke the planning workflow again in implementation-refinement mode. Do not extend this checklist into a bulk rename implementation while material naming decisions remain open.
