---
type: evidence
status: active
owner: BK
created: 2026-07-28
last_reviewed: 2026-07-28
topic: Source map for Cardborne combat-growth external review
scope: Bounded current code, tests, specifications, and evidence relevant to the issue
source: Current repository at 57346d9f6c645aaa80d6b5ca3f0a909bb7898fc2
related:
  - ./README.md
  - ./current-state.md
  - ./constraints-and-decisions.md
  - ../../product/vehicle_game_spec.md
---

# Source Map

## Purpose

This map identifies the smallest source set needed to verify the handoff. It
does not copy source files or make this folder authoritative.

## Sources

### Source-of-truth reading order

1. `../../../AGENTS.md`

   Repository-wide product, architecture, validation, localization, and
   operating constraints.

2. `../../product/vehicle_game_spec.md`

   The single active product contract. Use it for current five-stage behavior,
   not for proof that a runtime path exists.

3. Current code and resources named below

   The executable source of truth for implemented behavior.

4. Current validators named below

   Evidence of encoded contracts, not proof of subjective fun or complete
   runtime coverage.

5. `../../../.agents/survivor-shooter-combat-growth-reference-study.md`

   Active evidence: current-state audit and nine-game source-backed comparison.
   Consult; do not obey.

6. `../../product/combat-growth-improvement-direction.md`

   Draft proposal. Challenge it; do not treat it as accepted product behavior.

### Growth, offers, and rewards

| File | Why inspect it |
| --- | --- |
| `../../../scripts/cards/vehicle_upgrade_catalog.gd` | Loads 46 definitions, filters compatibility, and owns deterministic three-card offer construction. Inspect `offer`, first-offer guarantees, branch-child bias, and source filtering. |
| `../../../scripts/cards/vehicle_run_build.gd` | Owns acquired levels, optional-secondary slot state, and upgrade application state. |
| `../../../data/cards/vehicle/` | Data-side proof of current effects and source tags. Start with Breach, pierce, seeker, mine, element, dash, and EMP-related definitions rather than reading every file first. |
| `../../../scripts/progression/vehicle_experience_runtime.gd` | Owns XP shards, thresholds, collection, pending level-ups, and recall behavior. |
| `../../../scripts/rewards/vehicle_reward_runtime.gd` | Owns reward source, offer serial, optional/mandatory outcome, and pending reward transitions. |
| `../../../scripts/player/vehicle_secondary_runtime.gd` | Current bounded Seeker, Ion, Orbit, Mine, and Drone behavior and scale. |
| `../../../scripts/cards/vehicle_upgrade_offer_presenter.gd` | Converts card definitions and current levels into UI-facing offer snapshots; behavior must remain outside UI. |

### Encounter density and enemy ecology

| File | Why inspect it |
| --- | --- |
| `../../../scripts/vehicle/stages/vehicle_combat_stages.gd` | Owns quotas, authored populations, eight-squad packets, roles, beat assignment, and stage boss identities. |
| `../../../scripts/vehicle/vehicle_stage_catalog.gd` | Resolves current stage and run-selected field profiles used by the runtime. |
| `../../../scripts/encounters/vehicle_encounter_director.gd` | Owns beat caps `[1,62,78,88,92]`, threat budgets, ranged/denial commitment limits, and squad steering policy. |
| `../../../scripts/encounters/vehicle_encounter_runtime.gd` | Owns timed packet activation, cue and spawn queues, active-cap delays, quota state, and current pacing telemetry. |
| `../../../scripts/encounters/vehicle_spawn_allocator.gd` | Owns deterministic role bags, pursuit guarantees, projectile-role distribution, and separate off-screen anchors. |
| `../../../scripts/enemies/vehicle_enemy_archetypes.gd` | Inventory of existing swarm, standard, support, priority, stationary, and boss roles available for formation authoring. |
| `../../../scripts/enemies/vehicle_pursuit_field.gd` | Shared low-frequency routing around cover; relevant to front compression and congestion. |

### Terrain and field layout

| File | Why inspect it |
| --- | --- |
| `../../../scripts/vehicle/vehicle_terrain_runtime.gd` | Owns Arc timing and attribution, bulkhead health, gates, repair, overdrive, and current terrain state. |
| `../../../scripts/vehicle/vehicle_terrain_definition.gd` | Terrain data contract and feature invariants. |
| `../../../scripts/vehicle/vehicle_field_layout_generator.gd` | Validates cover, feature, spawn, item, support, and boss sockets for deterministic tactical layouts. |
| `../../../scripts/vehicle/vehicle_stage_tactical_layout.gd` | Runtime boundary for one selected stage layout. |
| `../../../scripts/vehicle/stages/drowned_ruin_field.gd` | Drowned Ruins authored Arc, bulkheads, gates, cover candidates, and anchors. |
| `../../../scripts/vehicle/stages/tidal_archive_field.gd` | Tidal Archive authored terrain and layout candidates. |
| `../../../scripts/vehicle/stages/storm_drydock_field.gd` | Storm Drydock authored terrain and layout candidates. |

### Boss state and integration

| File | Why inspect it |
| --- | --- |
| `../../../scripts/bosses/vehicle_boss_patterns.gd` | Stage-specific pattern data, generic pattern kinds, sequences, signatures, and volley limits. |
| `../../../scripts/bosses/vehicle_boss_runtime.gd` | Phase thresholds, sequence selection, signature interruption, direct-pattern state, and autonomous cadence. |
| `../../../scripts/vehicle/vehicle_run.gd` | Integration owner for encounters, player combat, terrain, defeat attribution, reward opening, boss spawning, and stage completion. Inspect integration points; do not recommend adding all new policy here. |
| `../../../scripts/combat/vehicle_stage_telemetry.gd` | Current damage and defeat aggregation; starting point for new engagement and burst metrics. |
| `../../../scripts/combat/vehicle_damage_source_catalog.gd` | Stable source normalization for player, secondary, terrain, and reflected damage. |

### Focused validators

| Validator | What it proves and what it does not prove |
| --- | --- |
| `../../../tools/validation/validate_vehicle_upgrade_system.gd` | Proves catalog size, deterministic unique offers, compatibility, and slot rules; not evolution quality. |
| `../../../tools/validation/validate_vehicle_experience.gd` | Proves XP thresholds, shards, recall, and expected choice counts; not perceived pacing. |
| `../../../tools/validation/validate_vehicle_rewards_ui_audio.gd` | Proves reward transactions and optional outcomes; not a live optional field boss. |
| `../../../tools/validation/validate_vehicle_encounter_pacing.gd` | Proves current opening, eight-squad packet, quotas, authored counts, and caps; it currently locks some behavior under review. |
| `../../../tools/validation/validate_vehicle_spawn_allocation.gd` | Proves deterministic valid anchors and role distribution; not engaged-density quality. |
| `../../../tools/validation/validate_vehicle_enemy_expansion.gd` | Proves enemy-role data contracts. |
| `../../../tools/validation/validate_vehicle_terrain_runtime.gd` | Proves present Arc, gate, support-field, and bulkhead behavior; not intentional mass-kill usability. |
| `../../../tools/validation/validate_vehicle_field_layout_generation.gd` | Proves deterministic, collision-safe layout generation. |
| `../../../tools/validation/validate_vehicle_navigation_clearance.gd` | Proves required actor clearances; important when evaluating compressed fronts. |
| `../../../tools/validation/validate_vehicle_boss_patterns.gd` | Proves pattern data and stage sequences; not semantic phase distinction. |
| `../../../tools/validation/validate_vehicle_boss_runtime.gd` | Proves current phase and interrupt state transitions. |
| `../../../tools/validation/validate_vehicle_boss_practice.gd` | Provides deterministic boss pattern inspection. |
| `../../../tools/validation/profile_vehicle_pressure.gd` | Current pressure profiling entry point. |
| `../../../tools/validation/validate_vehicle_performance_scenarios.gd` | Guards bounded performance scenarios; formation proposals must not bypass it by raising caps. |
| `../../../tools/validation/validate_vehicle_stage_telemetry.gd` | Proves current aggregate telemetry shape; not the missing engaged-density and kill-burst metrics. |

### Relevant evidence

| File | Use |
| --- | --- |
| `../../../.agents/survivor-shooter-combat-growth-reference-study.md` | Primary issue evidence with current code facts, source grades, nine reference games, transfer decisions, and limitations. |
| `../../../.agents/vehicle-performance-stabilization-evidence.md` | Current runtime-performance evidence and limits. |
| `../../../.agents/vehicle-world-combat-expansion-evidence.md` | Archived historical rationale for terrain, Breach, enemies, and bosses. Its early “current state” is stale; use only as history. |
| `../../design/UI_VISUAL_SYSTEM.md` | Active visual/readability contract that any new effects or boss objectives must preserve. |

### Recent relevant commits

| Commit | Why it matters |
| --- | --- |
| `624f807` | Adds the current deep survivor-shooter research and draft direction. |
| `c7e02c3` | Integrates weapon art and changes upgrade-offer variation; useful offer-history context. |
| `f118a38` | Isolates reward transaction state from the run orchestrator. |
| `b939eda` | Makes the current validator suite part of CI. |
| `b7a034f` | Increases field pressure and terrain clarity. |
| `79fad1d` | Introduces distinct boss runtime and practice mode. |
| `fbb115c` | Introduces functional terrain and Breach Shot. |
| `51b2168` | Closes the prior vehicle world/combat expansion and documents its accepted scope. |

## Findings

### Known freshness warnings

- Root `README.md` says Hard preserves a `48-to-72` active-enemy baseline. Current
  code and the active spec use beat caps `1/62/78/88/92`; do not repeat the root
  summary as an exact fact.
- `combat-growth-improvement-direction.md` is `spec + draft`; none of its
  Evolution, clustered-front, field-signature, or semantic-boss behavior is
  implemented.
- `vehicle-world-combat-expansion-evidence.md` is archived. Its earlier baseline
  descriptions predate current terrain and boss work.
- Reward validation mentions a `field_boss` source, but this proves transaction
  plumbing only.
- Passing validators prove their encoded contracts. They do not prove fun,
  readable mass kills, actual player engagement density, or meaningful boss
  identity.

### Intentionally excluded

- `.env` files, credentials, tokens, private account data, databases, and
  personal exports
- `.godot/`, `.codex-runtime/`, build caches, local temporary files, and ignored
  runtime artifacts
- bulk generated pixel-art evidence unrelated to the gameplay-design question
- unrelated map/UI visual-direction option files from the latest docs-only
  commit
- raw browser or model transcripts

The excluded items are not needed to evaluate this issue. If a reviewer needs
another current source file, it should name the path and reason instead of
assuming the omitted file is irrelevant.

## Recommendations

- Read only the high-value files first, then follow concrete symbols.
- Use code and active specs to correct this handoff where needed.
- Treat design targets as hypotheses that require telemetry and playtests.
- Keep external recommendations advisory until locally reconciled.

## Limitations

- This map is an orientation aid, not a dependency graph.
- It does not reproduce source contents or runtime captures.
- Line numbers are intentionally omitted because current symbols and paths are
  more stable across the forthcoming review.
