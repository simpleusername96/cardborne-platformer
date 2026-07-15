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
| 4 | `design/UI_VISUAL_SYSTEM.md` | Accepted UI art direction, asset boundaries, shell backgrounds, panels, state visuals, and validation. |
| 5 | `design/PROCEDURAL_REGION_GENERATION.md` | Stage profiles, terrain, room catalog, and deferred generation. |
| 6 | `design/2D_PLATFORMER_MAP_DESIGN_GUIDELINE.md` | Canonical room intention, gameplay verticality, routing, pacing, and map acceptance rules. |
| 7 | `design/MAP_AUTHORING_PIPELINE_CONTRACT.md` | Room-template and anchor schema. |
| 8 | `design/ENEMIES_TRAPS_GIMMICKS.md` | Enemy, hazard, encounter, and boss content. |
| 9 | `architecture/FIRST_SLICE_ARCHITECTURE.md` | Current runtime ownership and retained compatibility boundaries. |

## Supporting Material

- `data/RUNTIME_CATALOG_INDEX.md` maps gameplay domains to typed runtime owners.
- `release/TRAVELER_EQUIPMENT_VERTICAL_SLICE.md` records the current playable
  baseline and its verification evidence.
- `release/FIRST_COMPLETE_RUN_RC1.md` is the superseded three-class baseline.
- `.agent/execplans/2026-07-14-minimum-equipment-progression-vertical-slice.md` is
  the completed migration and validation record, not current work.
- `.agent/execplans/2026-07-15-gameplay-validity-repair.md` is the active
  implementation plan for input, death/retry, guard, stages, safe intermission,
  the separate UI branch, and browser-export validation.
- `.agent/execplans/2026-07-15-master-ui-overhaul.md` is the active `master`-
  targeted plan for selective adoption of the existing UI asset branches, the
  complete production-screen/HUD visual migration, and measurement-backed world
  presentation dependencies.
- `.agent/execplans/2026-07-15-fixed-stage-map-enhancement.md` is the active
  checklist plan for meaningful vertical routes, stage-specific height profiles,
  encounter composition, and continuous traversal validation.
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
- `research/combat_loadout_reference_review_2026-07-14.md` is archived evidence.
  Its former three-active-skill recommendation was rejected and must not guide
  current work.
- `research/player_input_and_ui_followup_audit_2026-07-15.md` is archived evidence
  from a rejected control recommendation; it does not define current work.
- `research/plan_validity_audit_2026-07-15.md` is the archived evidence audit that
  created the active gameplay-validity plan; it does not describe current gaps.
- `research/2d_platformer_map_design_research_2026-07-15.md` is the active
  cross-case evidence and current-stage diagnosis behind the canonical map
  guideline and fixed-stage enhancement plan.
- Dated surveys/deep dives are archived evidence; `references/` contains advisory
  candidates. Neither is product authority.
- `.agent/Documentation.md` records current project state and verification paths.

## Preproduction Drafts

These documents are intentionally non-canonical until the owner accepts the proposed
production-art and UI foundation:

- `design/GAME_COMPONENT_ART_SYSTEM.md` proposes the tile, reusable component,
  stage-skin, decoration, actor, and unique-set-piece boundaries.
- `design/WORLD_COMPONENT_IMAGE_PRODUCTION_PLAN.md` defines image-generation batch
  size, per-family production order, candidate approval, cleanup, and temporary HTML
  gallery review before Godot integration.
- `research/component_ui_foundation_research_2026-07-13.md` records local and
  external evidence behind those proposals.
- `.agent/execplans/2026-07-13-component-ui-foundation.md` is the draft future
  implementation sequence. It authorizes no work unless explicitly activated
  against the current `master`.
- `.agent/handoffs/2026-07-14-world-component-imagegen-session.md` is the active
  continuation record for the latest terrain-first, canonical-base, and state-overlay
  correction. Read it before executing the older image-generation call matrix.
- `design/references/README.md` classifies generated boards as references rather
  than production-ready atlases or sprites.
- `tools/component_gallery/` is a static review prototype, not shipped UI. Its
  background coverage model and inline SVG world objects are historical evidence;
  production backgrounds and world components remain raster assets.

## Lifecycle Rule

Active specs define required product behavior; `.agent/Documentation.md`, the
current release record, and validators distinguish what has landed. Completed
ExecPlans are historical records and do not define new work. Evidence supports
decisions but is not obeyed directly. Deleted prototype material is historical and
should be recovered from Git only for a specific investigation.
