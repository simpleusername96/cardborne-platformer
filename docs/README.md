# Cardborne Documentation

This index prevents plans, evidence, and old prototypes from competing with active
game specifications.

## Read First

| Order | Document | Authority |
| ---: | --- | --- |
| 1 | `product/2d_platform_action_card_game_prd.md` | Canonical product and fun specification. |
| 2 | `design/ARSENAL_EQUIPMENT_PROGRESSION.md` | One hero, weapon disciplines, full equipment, progression, tutorial, and saves. |
| 3 | `design/PROCEDURAL_REGION_GENERATION.md` | Stage profiles, terrain, room catalog, and generation. |
| 4 | `design/MAP_AUTHORING_PIPELINE_CONTRACT.md` | Room-template and anchor schema. |
| 5 | `design/ENEMIES_TRAPS_GIMMICKS.md` | Enemy, hazard, encounter, and boss content. |
| 6 | `design/PLAYER_FACING_FLOW.md` | Profiles, Armory, HUD, choices, saves, settings, and results. |
| 7 | `architecture/FIRST_SLICE_ARCHITECTURE.md` | Current runtime ownership and migration boundaries. |
| 8 | `../.agent/execplans/2026-07-14-single-hero-arsenal-migration.md` | Active implementation checklist and batch gates. |

## Supporting Material

- `data/RUNTIME_CATALOG_INDEX.md` maps gameplay domains to typed runtime owners.
- `release/FIRST_COMPLETE_RUN_RC1.md` records the playable release candidate and
  its player/operator verification paths.
- `.agent/execplans/2026-07-12-actual-game-production-roadmap.md` is the completed
  first-run implementation record.
- `design/PLAYER_CHARACTER_SYSTEMS.md`,
  `design/PROGRESSION_EQUIPMENT_ECONOMY.md`, and the 2026-07-13 refinement plan are
  superseded v1 implementation/migration evidence.
- `design/reports/arsenal-equipment-system.html` is the interactive design report;
  it explains the active specs but does not override them.
- `research/third_party_adoption_ledger.md` is the active external adoption record.
- Dated surveys/deep dives are archived evidence; `references/` contains advisory
  candidates. Neither is product authority.
- `.agent/Documentation.md` records current project state and verification paths.

## Lifecycle Rule

Active specs define the required product target; `.agent/Documentation.md` and
current validators distinguish what has landed. An active plan defines execution
order. Evidence supports decisions but is not obeyed directly. Deleted prototype
material is historical and should be recovered from Git only for a specific
investigation.
