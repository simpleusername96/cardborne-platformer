# Source Map

## Source Of Truth

1. `AGENTS.md` — repository operating and product-preservation rules.
2. `docs/product/vehicle_game_spec.md` — canonical executable gameplay
   contract.
3. `docs/design/UI_VISUAL_SYSTEM.md` — canonical art, UI, and presentation
   contract.
4. Current code and resources — implementation truth when documentation claims
   are tested.

## Runtime Entry And Orchestration

- `project.godot`
- `scenes/main/GameRoot.tscn`
- `scenes/run/VehicleRun.tscn`
- `scripts/main/game_root.gd`
- `scripts/vehicle/vehicle_run.gd`

## Gameplay Systems

- `scripts/vehicle/vehicle_stage_catalog.gd`
- `scripts/vehicle/vehicle_field_registry.gd`
- `scripts/vehicle/vehicle_field_layout_generator.gd`
- `scripts/vehicle/vehicle_terrain_runtime.gd`
- `scripts/encounters/vehicle_encounter_director.gd`
- `scripts/encounters/vehicle_encounter_runtime.gd`
- `scripts/encounters/vehicle_stage_flow.gd`
- `scripts/enemies/vehicle_enemy_archetypes.gd`
- `scripts/enemies/vehicle_enemy_store.gd`
- `scripts/enemies/vehicle_pursuit_field.gd`
- `scripts/bosses/vehicle_boss_patterns.gd`
- `scripts/bosses/vehicle_boss_runtime.gd`
- `scripts/combat/vehicle_projectile_store.gd`
- `scripts/combat/vehicle_attack_contract.gd`
- `scripts/progression/vehicle_experience_runtime.gd`

## Progression And Presentation

- `scripts/cards/vehicle_upgrade_catalog.gd`
- `scripts/cards/vehicle_run_build.gd`
- `data/cards/vehicle/*.tres`
- `scripts/ui/vehicle_stage_ui.gd`
- `scripts/ui/vehicle_upgrade_choice_panel.gd`
- `scripts/ui/vehicle_settings_panel.gd`
- `scripts/ui/vehicle_guidebook_panel.gd`
- `scripts/ui/vehicle_stage_report_panel.gd`
- `scripts/presentation/vehicle_combat_renderer.gd`
- `scripts/presentation/vehicle_combat_visual_library.gd`
- `localization/vehicle_stage.csv`
- `art/ui/production/vehicle_stage_theme.tres`

## Performance And Validation

- `.agents/vehicle-performance-architecture-audit.md`
- `.agents/vehicle-performance-stabilization-evidence.md`
- `scripts/performance/vehicle_performance_scenario.gd`
- `scripts/performance/vehicle_performance_recorder.gd`
- `tools/validation/profile_vehicle_pressure.gd`
- all 38 `tools/validation/validate_*.gd` scripts
- especially:
  - `validate_vehicle_run.gd`
  - `validate_vehicle_stage_ui_layout.gd`
  - `validate_vehicle_performance_scenarios.gd`
  - `validate_vehicle_field_layout_generation.gd`
  - `validate_vehicle_navigation_clearance.gd`
  - `validate_vehicle_boss_runtime.gd`
  - `validate_vehicle_ui_localization.gd`

## Recent Commits

- `faf8dfc` fix: close upgrade UI localization and overflow
- `5c4baf1` feat(ui): rebuild modal visual hierarchy
- `3085827` feat(combat): distinguish hostile silhouettes
- `231cb61` feat(ui): refine vehicle interface hierarchy
- `6383596` perf: snapshot support fields independently
- `f98891f` perf: batch tactical map and support visuals

## Intentionally Excluded

- `.godot/` imported cache and editor state
- `build/` generated exports, captures, and audit images
- `.codex-runtime/`
- user settings, credentials, environment variables, and local process state
- historical chat transcripts and unrelated prior branches

