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
| 3 | `../.agent/execplans/2026-07-14-minimum-equipment-progression-vertical-slice.md` | Active As-Is/To-Be implementation checklist and validation gates. |
| 4 | `design/PROCEDURAL_REGION_GENERATION.md` | Stage profiles, terrain, room catalog, and generation. |
| 5 | `design/MAP_AUTHORING_PIPELINE_CONTRACT.md` | Room-template and anchor schema. |
| 6 | `design/ENEMIES_TRAPS_GIMMICKS.md` | Enemy, hazard, encounter, and boss content. |
| 7 | `architecture/FIRST_SLICE_ARCHITECTURE.md` | Current runtime ownership and migration boundaries. |

## Supporting Material

- `data/RUNTIME_CATALOG_INDEX.md` maps gameplay domains to typed runtime owners.
- `release/FIRST_COMPLETE_RUN_RC1.md` records the playable release candidate and
  its player/operator verification paths.
- `.agent/execplans/2026-07-12-actual-game-production-roadmap.md` is the completed
  first-run implementation record.
- `design/PLAYER_CHARACTER_SYSTEMS.md`,
  `design/PROGRESSION_EQUIPMENT_ECONOMY.md`,
  `design/ARSENAL_EQUIPMENT_PROGRESSION.md`, `design/PLAYER_FACING_FLOW.md`, and the
  2026-07-14 single-hero arsenal migration plan are superseded evidence.
- `design/PLAYER_UIUX_REFINEMENT_PLAN.md` is superseded UI research. Its accepted
  minimum UI work is incorporated into the active equipment-progression ExecPlan.
- `design/reports/arsenal-equipment-system.html` is a superseded interactive
  snapshot of the former six-discipline direction. It is retained for comparison
  and does not define current work.
- `research/third_party_adoption_ledger.md` is the active external adoption record.
- `research/combat_loadout_reference_review_2026-07-14.md` is active advisory
  evidence only. Its former active-skill recommendation was not adopted; the
  current minimum decision record and ExecPlan are authoritative.
- Dated surveys/deep dives are archived evidence; `references/` contains advisory
  candidates. Neither is product authority.
- `.agent/Documentation.md` records current project state and verification paths.

## Lifecycle Rule

Active specs define the required product target; `.agent/Documentation.md` and
current validators distinguish what has landed. The active minimum equipment-
progression ExecPlan defines implementation order and UI gates. Evidence supports
decisions but is not obeyed directly. Deleted prototype material is historical and
should be recovered from Git only for a specific investigation.
