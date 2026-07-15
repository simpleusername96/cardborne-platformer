---
type: plan
status: done
owner: BK
created: 2026-07-15
last_reviewed: 2026-07-15
topic: Repair active control guidance and audit plan validity against the current web input direction
source: Owner feedback on 2026-07-15, active product specs, current runtime inspection, and cited external control research
related:
  - ../../docs/product/2d_platform_action_card_game_prd.md
  - ../../docs/design/COMBAT_EQUIPMENT_CRAFTING.md
  - ../../docs/design/PRODUCTION_UI_CONTRACT.md
  - ../../docs/research/player_input_and_ui_followup_audit_2026-07-15.md
---

# Web Input Contract Repair And Validity Audit

## Purpose

Active specifications and a new research note incorrectly promoted fixed gamepad
support and `F/G/H` combat bindings into current product guidance. Completed plans
also remained linked as active work. The owner requires a compact keyboard-first
control model for browser play and a broader check of whether completed-plan claims
match the current runtime.

## Scope / Non-scope

In scope:

- repair active product, combat, UI, documentation-routing, and research guidance;
- choose a keyboard control candidate from current web and action-platformer evidence;
- preserve UI readability and popup feedback as a separate-branch handoff;
- record runtime gaps in death/retry, guard, stage content, rest/Forge flow, and input;
- distinguish authoritative current documents from completed historical plans.

Out of scope:

- changing gameplay input code, Settings UI, or prompt assets;
- implementing death/retry, guard, stage, merchant, Forge, or UI fixes;
- rewriting completed or superseded documents to make history look current.

## Assumptions

- Keyboard owns gameplay input; mouse is available for menus.
- Current active-skill count remains zero. A later experiment may add at most one
  active skill only when playtesting identifies a missing combat decision.
- `E` means world interaction: chest, NPC, altar, Forge, and exit.
- UI typography, bilingual copy, and centered popup implementation stay deferred.

## Proposed Design

The default candidate splits simultaneous work across both hands:

| Action | Default |
| --- | --- |
| Move / climb / drop | `WASD` |
| Jump / drop through | `Space` / `S + Space` |
| Dash | `Left Shift` |
| Context attack | `J` |
| Guard / precise guard | `K` |
| Future single active skill | `L`, only if adopted |
| Interact | `E` |
| Consumable | `R` |
| Pause / back | `Escape` |

`J/K/L` avoids the `D`+`F` finger collision, avoids browser right-click behavior,
and keeps high-frequency combat away from the movement hand. All implemented
gameplay actions remain remappable; unused future actions are not shown.

## Tasks

1. Inventory active and historical control claims; correct authority routing.
2. Replace the controller-centric research note with web keyboard/mouse evidence.
3. Update active product/combat/UI contracts and archive the rejected multi-skill
   recommendation.
4. Record broader implementation validity findings without implementing fixes.
5. Validate links, lifecycle metadata, terminology, diffs, and focused runtime
   evidence; commit only task-owned changes.

## Progress

- [x] Audited active and historical control claims and documentation authority.
- [x] Researched browser constraints and comparable keyboard-first action controls.
- [x] Repaired active product, combat, UI, release, and documentation guidance.
- [x] Recorded broader product-validity findings and the deferred UI handoff.
- [x] Completed lifecycle, terminology, link-target, and diff checks; scoped docs
  are ready for commit.

## Test Plan

- `rg` for active `gamepad`, `controller`, `R3`, `F/G/H`, and multi-skill claims;
- direct review of every changed Markdown file and documentation index;
- `git diff --check` and lifecycle/frontmatter review;
- focused existing validators for shield, run result, stage plans, and input where
  they provide relevant evidence;
- mark current runtime/gamepad validators as implementation drift rather than
  silently claiming the new input contract has landed.

## Rollback / Safety

Changes are documentation-only. Historical completed plans and superseded specs
stay intact. Runtime behavior and existing save data are untouched.

## Risks

- The current build will still expose fixed gamepad support and old key defaults
  until a separate input implementation pass changes code and validators.
- Automated validators may prove internal consistency while missing poor feel,
  discoverability, visual clarity, or an unnatural retry flow.

## Open Questions

- Whether one active skill adds enough combat value to justify its extra input.
- Whether an optional mouse-combat preset is worth browser-specific right-click
  handling and testing; it is not the default recommendation.

## Next Steps

- Implement the approved input contract and remove runtime gamepad assumptions in
  a gameplay-input pass.
- Address death/retry and live guard proof before expanding stage content.
- Apply the stored readability and popup requirements on the separate UI branch.

## Decision Notes

- Owner decision: gameplay uses remappable keyboard input; menus accept keyboard
  and mouse.
- Owner decision: keep `Space` jump and `Shift` dash.
- Owner preference: combat actions remain minimal; no multi-slot skill bar.
- Suggested default: `J` attack, `K` guard, with `L` reserved for at most one
  future active skill.
