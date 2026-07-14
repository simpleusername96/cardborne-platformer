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
| 2 | `design/COMBAT_EQUIPMENT_CRAFTING.md` | One hero, 12 distinct combat-tool models, active/passive boundaries, crafting, ranged resources, Spirit Stones, and unlocks. |
| 3 | `design/PROCEDURAL_REGION_GENERATION.md` | Stage profiles, terrain, room catalog, and generation. |
| 4 | `design/MAP_AUTHORING_PIPELINE_CONTRACT.md` | Room-template and anchor schema. |
| 5 | `design/ENEMIES_TRAPS_GIMMICKS.md` | Enemy, hazard, encounter, and boss content. |
| 6 | `design/PLAYER_UIUX_REFINEMENT_PLAN.md` | Active As-Is/To-Be UI/UX checklist for profiles, preparation, HUD, loot, crafting, replay, saves, and results. |
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
- `design/reports/arsenal-equipment-system.html` is a superseded interactive
  snapshot of the former six-discipline direction. It is retained for comparison
  and does not define current work.
- `research/third_party_adoption_ledger.md` is the active external adoption record.
- `research/combat_loadout_reference_review_2026-07-14.md` is active advisory
  evidence for the combat-slot and active/passive decisions.
- Dated surveys/deep dives are archived evidence; `references/` contains advisory
  candidates. Neither is product authority.
- `.agent/Documentation.md` records current project state and verification paths.

## Lifecycle Rule

Active specs define the required product target; `.agent/Documentation.md` and
current validators distinguish what has landed. The active UI/UX plan defines its
own execution order. There is no active cross-code gameplay ExecPlan after the
latest redesign; create one from the active specs before implementation. Evidence
supports decisions but is not obeyed directly. Deleted prototype material is
historical and should be recovered from Git only for a specific investigation.
