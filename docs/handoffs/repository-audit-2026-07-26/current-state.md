# Current State

## User Intent

The user wants an independent inspection of the repository as it exists now,
not another implementation pass. The review should identify concrete defects,
architectural risks, mismatches between design intent and executable behavior,
test blind spots, performance hazards, and the most valuable next work.

## Implemented Product

Cardborne is a top-down vehicle action shooter with:

- one run-selected large field reused across five connected combat stages;
- manual mouse aim, held primary fire, a one-second Breach Shot, dash, passive
  seekers, and EMP;
- deterministic encounter scheduling, ordinary-enemy quotas, roaming stage
  bosses, optional field bosses, map pickups, experience shards, and card
  upgrades;
- 46 upgrade definitions, stackable elemental branches, and five automatic
  secondary families;
- Easy, Normal, and Hard selected before a run;
- Korean-default and English-complete runtime UI;
- settings, guidebook, stage/failure report, garage, minimap, and boss-practice
  surfaces;
- retained/batched flat-color combat and tactical rendering.

The canonical gameplay contract is `docs/product/vehicle_game_spec.md`. The
canonical presentation contract is `docs/design/UI_VISUAL_SYSTEM.md`.

## Relevant Runtime Flow

```text
GameRoot.tscn
  -> VehicleRun.tscn / scripts/vehicle/vehicle_run.gd
  -> field layout + stage tactical layout
  -> encounter director/runtime + stage flow
  -> enemy/boss/projectile/combat state
  -> combat renderer + stage UI snapshots
  -> reward queue + upgrade catalog/run build
  -> stage report / transition / final result
```

`vehicle_run.gd` remains the main orchestration owner. Domain-specific behavior
is split into `scripts/bosses`, `cards`, `combat`, `encounters`, `enemies`,
`player`, `presentation`, `progression`, `ui`, and `vehicle`.

## Recent Completed Work

- Performance architecture was stabilized around bounded stores, spatial
  queries, retained mesh batches, and deterministic pressure scenarios.
- The campaign changed to one persistent run-selected field with five tactical
  stage arrangements.
- Enemy silhouettes, combat readability, minimap markers, support fields,
  guidebook, reporting, and UI hierarchy were revised.
- The latest fix closed dynamic localization-key leaks and card overflow across
  91 selectable card states, three slots, selected/unselected states, Korean
  and English, and three supported viewport sizes.

## Validation Baseline

At code baseline `faf8dfc`:

- all 38 scripts under `tools/validation/` pass;
- the UI layout validator checks 3,276 card-placement states;
- deterministic Korean and English captures exist at 960x540, 1280x720, and
  1920x1080;
- `tools/export_web.ps1` succeeds;
- the pressure microbenchmark reports a bounded hard-pressure scenario, but it
  explicitly excludes complete rendered frame orchestration.

## Review Questions

- Does the implemented runtime actually match the canonical product and visual
  specifications, or do the documents overstate guarantees?
- Are ownership boundaries real, or is `vehicle_run.gd` still a fragile
  catch-all despite extracted helpers?
- Which failure paths, state transitions, and performance costs are not covered
  by current validators?
- Are tests validating behavior or merely restating constants and debug
  contracts?
- Which findings are release-blocking, which should be near-term, and which are
  optional refactors?

