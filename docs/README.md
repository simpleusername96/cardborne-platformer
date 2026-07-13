# Cardborne Documentation

This index prevents plans, evidence, and old prototypes from competing with active
game specifications.

## Read First

| Order | Document | Authority |
| ---: | --- | --- |
| 1 | `product/2d_platform_action_card_game_prd.md` | Canonical product and fun specification. |
| 2 | `design/PLAYER_CHARACTER_SYSTEMS.md` | Character kits, controls, combat, and mastery. |
| 3 | `design/PROCEDURAL_REGION_GENERATION.md` | Stage profiles, terrain, room catalog, and generation. |
| 4 | `design/MAP_AUTHORING_PIPELINE_CONTRACT.md` | Room-template and anchor schema. |
| 5 | `design/ENEMIES_TRAPS_GIMMICKS.md` | Enemy, hazard, encounter, and boss content. |
| 6 | `design/PROGRESSION_EQUIPMENT_ECONOMY.md` | Levels, cards, equipment, currencies, and settlement. |
| 7 | `design/PLAYER_FACING_FLOW.md` | Navigation, HUD, choices, rest, settings, and result behavior. |
| 8 | `architecture/FIRST_SLICE_ARCHITECTURE.md` | Runtime ownership and implementation contracts. |
| 9 | `../.agent/execplans/2026-07-13-player-experience-refinement.md` | Active traversal, combat, field-item, and production UI refinement plan. |

## Supporting Material

- `data/RUNTIME_CATALOG_INDEX.md` maps gameplay domains to typed runtime owners.
- `release/FIRST_COMPLETE_RUN_RC1.md` records the playable release candidate and
  its player/operator verification paths.
- `.agent/execplans/2026-07-12-actual-game-production-roadmap.md` is the completed
  first-run implementation record.
- `research/third_party_adoption_ledger.md` is the active external adoption record.
- Dated surveys/deep dives are archived evidence; `references/` contains advisory
  candidates. Neither is product authority.
- `.agent/Documentation.md` records current project state and verification paths.

## Lifecycle Rule

Active specs define released behavior. An active plan defines what to do next only
when one exists. Evidence supports decisions but is not obeyed directly. Deleted
prototype material is historical and should be recovered from Git only for a
specific investigation.
