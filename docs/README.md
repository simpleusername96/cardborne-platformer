# Cardborne Documentation

This index prevents plans, evidence, and old prototypes from competing with active
game specifications.

For a short explanation of the current combat decision, read
`design/COMBAT_LOADOUT_DECISION_BRIEF.md`. It is a derived decision record; the
product blueprint and detailed combat spec below remain authoritative.

## Read First

| Order | Document | Authority |
| ---: | --- | --- |
| 1 | `product/2d_platform_action_card_game_prd.md` | Canonical product and fun specification. |
| 2 | `design/COMBAT_EQUIPMENT_CRAFTING.md` | Minimum complete one-hero combat, 6 tool models, blueprints, two material grades, crafting, repair, supply, and passive Spirit Stones. |
| 3 | `design/PRODUCTION_UI_CONTRACT.md` | Current production screens, HUD, feedback, focus, and responsive behavior. |
| 4 | `design/PROCEDURAL_REGION_GENERATION.md` | Stage profiles, terrain, room catalog, and deferred generation. |
| 5 | `design/MAP_AUTHORING_PIPELINE_CONTRACT.md` | Room-template and anchor schema. |
| 6 | `design/ENEMIES_TRAPS_GIMMICKS.md` | Enemy, hazard, encounter, and boss content. |
| 7 | `architecture/FIRST_SLICE_ARCHITECTURE.md` | Current runtime ownership and retained compatibility boundaries. |

## Supporting Material

- `data/RUNTIME_CATALOG_INDEX.md` maps gameplay domains to typed runtime owners.
- `release/TRAVELER_EQUIPMENT_VERTICAL_SLICE.md` records the current playable
  baseline and its verification evidence.
- `release/FIRST_COMPLETE_RUN_RC1.md` is the superseded three-class baseline.
- `.agent/execplans/2026-07-14-minimum-equipment-progression-vertical-slice.md` is
  the completed migration and validation record, not current work.
- `.agent/execplans/2026-07-12-actual-game-production-roadmap.md` is the completed
  first-run implementation record.
- `design/PLAYER_CHARACTER_SYSTEMS.md`,
  `design/PROGRESSION_EQUIPMENT_ECONOMY.md`,
  `design/ARSENAL_EQUIPMENT_PROGRESSION.md`, `design/PLAYER_FACING_FLOW.md`, and the
  2026-07-14 single-hero arsenal migration plan are superseded evidence.
- `design/PLAYER_UIUX_REFINEMENT_PLAN.md` is superseded UI research. Its accepted
  minimum UI work is incorporated into `design/PRODUCTION_UI_CONTRACT.md`.
- `design/reports/arsenal-equipment-system.html` is a superseded interactive
  snapshot of the former six-discipline direction. It is retained for comparison
  and does not define current work.
- `research/third_party_adoption_ledger.md` is the active external adoption record.
- `research/combat_loadout_reference_review_2026-07-14.md` is active advisory
  evidence only. Its former active-skill recommendation was not adopted; the
  current combat and UI specs are authoritative.
- Dated surveys/deep dives are archived evidence; `references/` contains advisory
  candidates. Neither is product authority.
- `.agent/Documentation.md` records current project state and verification paths.

## Lifecycle Rule

Active specs define required product behavior; `.agent/Documentation.md`, the
current release record, and validators distinguish what has landed. Completed
ExecPlans are historical records and do not define new work. Evidence supports
decisions but is not obeyed directly. Deleted prototype material is historical and
should be recovered from Git only for a specific investigation.
