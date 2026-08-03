---
type: evidence
status: active
owner: BK
created: 2026-08-04
last_reviewed: 2026-08-04
topic: Gameplay visual asset rationalization before Phase 6 implementation
scope: Classification of all 215 production gameplay PNGs, reusable code-native visual owners, and deferred effect polish
source: Local manifest, runtime consumer, filesystem, visual-system, workbench, and rendered-contact-sheet audit on 2026-08-04
related:
  - ../VISUAL_SYSTEM.md
  - ./README.md
  - ./replacement-workbench.json
  - ../../../art/visuals/production/gameplay/asset-manifest.json
  - ../../../.agents/execplans/2026-08-04-complete-remaining-visual-replacements.md
---

# Gameplay Visual Asset Rationalization Audit

## Purpose

This document records the preimplementation evidence used to reduce the visual
replacement program before any production image is generated, switched, or
deleted. It accounts for every current gameplay PNG, separates semantic identity
from file count, identifies reusable code-native geometry, and preserves a future
polish record for raster effects that should leave the shipping pack now.

This is evidence, not the executable switch-state authority. The durable media
boundary belongs to [`VISUAL_SYSTEM.md`](../VISUAL_SYSTEM.md), and the ordered
work belongs to the active ExecPlan. `replacement-workbench.json` remains the
only hand-authored unit, approval, and application-state source.

No production deletion or runtime switch is authorized by this audit alone.

## Sources

- `art/visuals/production/gameplay/asset-manifest.json`, including all
  attachments, ten static asset sets, and 22 animation identities.
- All 215 production gameplay PNG files and their import sidecars.
- `replacement-workbench.json`, generated `inventory.json`, and the current
  AS-IS/TO-BE directory contents.
- Direct runtime and guidebook consumers in `scripts/presentation/`,
  `scripts/ui/`, and the focused validators under `tools/validation/`.
- Existing shared geometry owners, especially projectile, reward/facility,
  action-glyph, upgrade-glyph, minimap, actor, and effect recipe catalogs.
- Rendered contact sheets for actors, weapons, states, pickups, world objects,
  HUD symbols, and effect frames at the 2026-08-04 repository state.
- `docs/product/vehicle_game_spec.md` and the current visual-system constraints.

## Findings

### Verified current truth

- Production contains exactly **215 gameplay PNGs**: 114 static images and 101
  animation-frame images.
- The folder counts are actors 35, weapons 13, states 7, pickups 6, world 10,
  HUD/combat cues 43, and effect frames 101.
- Every PNG is indexed exactly once by the manifest. There are no missing
  manifest files, unindexed production PNGs, duplicate semantic IDs, duplicate
  paths, or byte-identical PNG pairs.
- There are **zero deployable TO-BE gameplay assets**. Both TO-BE asset roots are
  empty. The 12 PNGs outside production in the workbench are two AS-IS UI sheets
  and ten screen-direction/review images; none is a promotable gameplay asset.
- Reference sheets and screen mockups may guide proportion, density, hierarchy,
  and layout only. They may not be cropped, traced, or promoted as runtime art.
- The 101 effect frames are live presentation dependencies today, but none owns
  collision, damage, targeting, timing, status, rewards, or encounter truth.
- Existing code already contains reusable geometry for all nine projectile
  identities, all six pickup identities, five facility/bulkhead identities,
  three live action glyphs, eight upgrade-family glyphs, retained minimap meshes,
  and several readability-critical effects.

### Classification vocabulary

Every current family receives one of these dispositions:

| Disposition | Meaning |
| --- | --- |
| `KEEP DISTINCT` | Preserve the semantic identity because gameplay readability depends on it. This does not automatically preserve the current bytes. |
| `REUSE EXISTING` | Keep the current production bytes because they are sufficiently compatible with the approved style and runtime contract. |
| `SHARE MASTER` | Replace multiple authored files with one shared family or parameterized state set. |
| `CODE-NATIVE` | Preserve semantic IDs, but render them from one shared geometry/catalog owner instead of one PNG per identity or state. |
| `RETIRE NOW` | Remove the production file after all consumers, manifest entries, validators, and approvals have been migrated. |
| `FUTURE BACKLOG` | Preserve the semantic polish intent in this document, not as an unused production file or current implementation task. |

### Final media boundary

Authored raster files are reserved for persistent, silhouette-rich objects whose
identity benefits from deliberate authored shape: actor bodies, boss bodies,
secondary-weapon bodies, three shared boss-node states, solid cover, and three
wear-tile states. Symbolic, collision-normalized, state-parametric, or transient
visuals use shared code-native geometry.

This reduces the intended shipping gameplay pack from 215 to **36 PNGs**:

| Change | PNG delta | Running total |
| --- | ---: | ---: |
| Current production pack | — | 215 |
| Retire all raster effect frames | -101 | 114 |
| Migrate all HUD, minimap, upgrade, action, and combat-cue symbols | -43 | 71 |
| Migrate all projectile forms to the shared projectile mesh catalog | -9 | 62 |
| Migrate all defense and persistent-status forms to one shared state catalog | -7 | 55 |
| Migrate all pickups to the shared reward recipe catalog | -6 | 49 |
| Migrate seven facility/bulkhead images to shared world recipes | -7 | 42 |
| Retire two unused world images | -2 | 40 |
| Consolidate ten boss-module files into three shared node states | -7 net | 33 |
| Add three required wear-tile state images | +3 | **36** |

The final 36 are:

| Authored raster family | Final PNGs | Current-byte action |
| --- | ---: | --- |
| Player craft | 1 | `REUSE EXISTING` |
| Ordinary enemy bodies | 19 | `KEEP DISTINCT`; replace current over-detailed bytes in place |
| Stage-boss bodies | 5 | `KEEP DISTINCT`; replace current over-detailed bytes in place |
| Shared boss nodes | 3 | `SHARE MASTER`; add `active`, `damaged`, and `resolved` |
| Secondary-weapon bodies | 4 | `KEEP DISTINCT`; replace current over-detailed bytes in place |
| Solid cover block | 1 | `REUSE EXISTING` unless final gameplay-scale evidence exposes a readability failure |
| Wear Collapse Tile states | 3 | Add `intact`, `cracked`, and `collapsed` |
| **Total** | **36** | 2 reused current PNGs, 28 in-place replacements, 6 new paths |

The result is **34 new authored raster outputs**, not 200-plus image fixes.
Code-native migrations remain real implementation work, but they are shared
component work rather than a separate art-generation task for every symbol or
frame.

### Complete static inventory classification

The following tables account for all 114 current static PNGs.

#### Actors: 35 current PNGs

| Current identities | Count | Disposition | Target |
| --- | ---: | --- | --- |
| `attachment/player_craft_body` | 1 | `REUSE EXISTING` | Keep the approved one-body craft unchanged. |
| `scrap_drone`, `needle_drone`, `spark_minelet`, `chaser`, `rammer`, `bulkhead_guard`, `shooter`, `turret`, `mine`, `artillery_spotter`, `controller`, `generator`, `shield_escort`, `repair_tender`, `drone_carrier`, `splitter_barge`, `interceptor_tower`, `beam_sentinel`, `boss_pylon` | 19 | `KEEP DISTINCT` | Keep all role identities and paths; replace their greeble-heavy bytes with 3–5-plane silhouettes. |
| `colossus`, `leviathan`, `titan`, `behemoth`, `crown` | 5 | `KEEP DISTINCT` | Keep all five boss identities and paths; replace with 4–6 large-plane bodies. |
| `forge_plate_active`, `forge_plate_disabled`, `segment_lock_active`, `segment_lock_disabled`, `relay_positive`, `relay_negative`, `route_switch`, `armor_car`, `crown_lattice`, `crown_pylon` | 10 | `SHARE MASTER` then `RETIRE NOW` | Replace all ten presentation variants with `boss_node_active`, `boss_node_damaged`, and `boss_node_resolved`; preserve module kind/index in gameplay code only. |

#### Weapons: 13 current PNGs

| Current identities | Count | Disposition | Target |
| --- | ---: | --- | --- |
| `secondary_seeker`, `secondary_escort_drone`, `secondary_orbit_blade`, `secondary_wake_mine` | 4 | `KEEP DISTINCT` | Four authored bodies remain because homing, escort, orbit, and stationary-mine motion roles need different silhouettes. Replace current detailed bytes in place. |
| `projectile_player_primary`, `projectile_player_opening_breach`, `projectile_player_seeker`, `projectile_hostile_kinetic`, `projectile_hostile_thermal`, `projectile_hostile_toxin`, `projectile_hostile_cryo`, `projectile_hostile_arc`, `projectile_hostile_hybrid` | 9 | `CODE-NATIVE` then `RETIRE NOW` | Reuse the nine existing collision-normalized projectile recipes and render them through shared batched meshes. Preserve all nine semantic IDs. |

#### Defense and status: 7 current PNGs

| Current identities | Count | Disposition | Target |
| --- | ---: | --- | --- |
| `player_barrier_plate`, `player_ion_emitter`, `enemy_generator_shield_source`, `enemy_shield_escort_plate` | 4 | `CODE-NATIVE` then `RETIRE NOW` | One defense catalog with four topology recipes: segmented plate, emitter, source nodes, and forward slab. |
| `status_burn`, `status_poison`, `status_chill` | 3 | `CODE-NATIVE` then `RETIRE NOW` | One persistent-status renderer with three shape-coded arc recipes; never distinguish them by hue alone. |

#### Pickups: 6 current PNGs

| Current identities | Count | Disposition | Target |
| --- | ---: | --- | --- |
| `pickup_experience_small`, `pickup_experience_medium`, `pickup_experience_large` | 3 | `SHARE MASTER` + `CODE-NATIVE` | One XP-shard recipe; gameplay value selects scale/emphasis without owning three files. |
| `pickup_reward_crate`, `pickup_repair`, `pickup_experience_recall` | 3 | `CODE-NATIVE` | Reuse the existing reward recipe owner; retain three semantic identities. |

#### World and facilities: 10 current PNGs

| Current identity | Disposition | Target |
| --- | --- | --- |
| `world_bulkhead_intact`, `world_bulkhead_damaged` | `CODE-NATIVE` | One breakable-bulkhead recipe parameterized by gameplay state. |
| `facility_repair_pad`, `facility_repair_pad_core` | `SHARE MASTER` + `CODE-NATIVE` | One repair-field recipe; the inset/core is part of the shared recipe, not a second authored file. |
| `facility_overdrive_lane`, `facility_arc_surge_strip`, `facility_transit_gate` | `CODE-NATIVE` | Reuse the existing three facility recipes and live gameplay footprint inputs. |
| `terrain_solid_cover_block` | `REUSE EXISTING` | Keep the current independent cover silhouette. |
| `terrain_breakable_cover_slab`, `terrain_hazard_power_relay` | `RETIRE NOW` | No direct runtime or guidebook consumer exists. Preserve no dormant production art; reintroduce only with a future product requirement. |

Add three authored world-state images after the migration:

- `world/wear_tile_intact.png`
- `world/wear_tile_cracked.png`
- `world/wear_tile_collapsed.png`

#### HUD, minimap, upgrade, action, and combat cues: 43 current PNGs

All 43 leave the raster pack. None must remain a PNG.

| Disposition | Exact identities | Count |
| --- | --- | ---: |
| Existing code-native recipe | `action_seeker`, `action_dash`, `action_emp`, `upgrade_primary`, `upgrade_secondary`, `upgrade_defense`, `upgrade_dash`, `upgrade_skill`, `upgrade_element`, `upgrade_mobility` | 10 |
| Add one shared semantic recipe owner | `minimap_marker_player`, `minimap_marker_hostile`, `minimap_marker_elite`, `minimap_marker_boss`, `minimap_marker_objective_active`, `minimap_marker_objective_locked`, `upgrade_support`, `cue_target_bracket_corner`, `cue_priority_target`, `cue_ranged_startup`, `cue_collective_gather`, `cue_collective_lock`, `cue_collective_execute`, `cue_collective_break`, `cue_elite_armored`, `cue_elite_overclocked`, `cue_elite_heavy`, `cue_boss_core_sealed`, `cue_boss_core_open`, `cue_boss_core_stable`, `cue_objective_active`, `cue_objective_resolved`, `cue_commit_locked`, `cue_commit_autonomous` | 24 |
| Direct orphan; retire without replacement | `action_primary`, `action_barrier`, `action_ion_field`, `upgrade_passive`, `cue_guide_ship`, `cue_guide_mobile`, `cue_guide_stationary`, `cue_guide_bosses`, `cue_guide_objects` | 9 |
| Must remain raster | none | 0 |

The action rail still contains only Seeker, Dash, and EMP. Primary fire does not
gain a slot. Upgrade-family and Seeker terminology remain governed by the
product specification and card data, not by icon filenames.

### Complete transient-effect inventory and future-polish register

The 22 identities below account for all 101 current raster frames. Their event
IDs remain valid. Their frame files do not.

| Event identity | Frames | Immediate code-native readability substitute | Future polish record |
| --- | ---: | --- | --- |
| `muzzle_player_primary` | 4 | Directional muzzle tick anchored to the live aim/muzzle transform | Optional 40–80 ms hard flash; never a detached radial burst. |
| `dash_start` | 3 | Existing hull afterimage and rear engine flare | Refine elongated geometry/timing only; no danger circle. |
| `emp_release` | 6 | Radius-scaled live EMP ring/disc from gameplay range | Refine edge breakup and release timing without adding decorative pulses. |
| `wake_mine_detonation` | 5 | Live mine boundary plus one impact ring | Add one concise directional breakup only if pressure tests need it. |
| `boss_module_disabled` | 4 | Shared node changes to damaged/resolved topology | Optional short rail-break motion tied to the state transition. |
| `hostile_summon_arrival` | 6 | Existing arrival footprint/telegraph | Add a single inward collapse keyed to actual activation time. |
| `bulkhead_destroy` | 5 | Intact/damaged/open state change and reward reveal | Optional brief structural breakup, never five authored frame files. |
| `reflect_deflection` | 5 | Directional contact line at the reflected trajectory | Optional one-frame hard spark aligned to the new vector. |
| `barrier_contact` | 5 | Barrier topology plus localized contact arc | Refine contact falloff while preserving the exact hit location. |
| `hull_hit` | 4 | Hull hit tint/flash | Optional directional notch; do not obscure aim or threats. |
| `seeker_impact` | 4 | Projectile removal and target hit flash | Add a small support-colored impact only if hit ownership is unclear. |
| `escort_drone_impact` | 4 | Projectile removal and target hit flash | Same shared impact grammar, parameterized by source role. |
| `orbit_blade_impact` | 4 | Blade contact and target hit flash | Same shared impact grammar, shaped along blade travel. |
| `enemy_destroy_light` | 5 | Body removal and reward/state transition | Optional minimal mass-collapse recipe for light enemies. |
| `enemy_destroy_heavy` | 6 | Body removal and reward/state transition | Optional heavier version of the same collapse recipe. |
| `crate_destroy` | 5 | Crate state removal and reward spawn | Optional latch/open snap, not a standalone frame animation. |
| `pickup_intake` | 4 | Pickup removal and immediate XP/reward UI change | Optional short travel tick only when collection ownership is unclear. |
| `support_heal` | 4 | Live support footprint and hull-meter increase | Optional inward support tick at the affected craft. |
| `lifesteal_pulse` | 4 | Existing directed transfer beam and hull gain | Refine transfer timing only; no ambient orbit. |
| `transit_shift` | 5 | Gate footprint, dwell state, and position transition | Optional one-way stretch aligned to travel direction. |
| `boss_reduced_hit` | 4 | Boss tint/guard feedback and health/guard state | Optional restrained armored deflection shared with guard feedback. |
| `impact_damage` | 5 | Target hit tint and damage feedback | One shared minimal impact recipe if later readability evidence requires it. |
| **Total** | **101** | Gameplay truth remains in existing owners | No raster-frame backlog is recreated by default. |

Every future effect must still satisfy four rules:

1. The gameplay event, timer, collision, damage, or state remains authoritative.
2. The effect explains movement, state change, impact, or objective only.
3. The implementation reuses shared code-native geometry and does not restore a
   one-file-per-frame production pack.
4. Future polish is scheduled only after gameplay-scale evidence identifies a
   readability deficiency; cosmetic completeness alone is not sufficient.

### Required consumer migrations before any deletion

- `VehicleCombatRenderer` must stop creating texture-backed projectile,
  experience, status, facility, cue, and animation-frame draws for the migrated
  families.
- `VehicleVisualEventCatalog` must classify each event as code-native retained,
  deliberately suppressed, or future-polish deferred instead of resolving an
  animation identity unconditionally.
- `VehicleUpgradeGlyphRenderer._draw()` and the action-rail slot must draw their
  existing recipes rather than fetching semantic PNG textures.
- Gameplay HUD, minimap, guidebook preview, and status orbit must use the same
  shared symbol catalogs.
- Reward, facility, projectile, defense, status, and cue descriptors must remain
  available without being falsely indexed as raster assets.
- The manifest, semantic provider, workbench, and validators must distinguish
  authored-raster IDs from code-native semantic IDs.
- Deletion happens only after a rendered actual-scale comparison and an exact
  approval report listing every PNG and `.png.import` sidecar.

## Recommendations

- Rebuild Phase 6 around shared code-native owner migration before producing any
  new raster art.
- Treat the 34 authored outputs as five reviewable families: ordinary enemies,
  secondary bodies, boss bodies, shared boss nodes, and wear tiles.
- Keep current player-craft and solid-cover bytes unless final rendered evidence
  reveals a concrete contract failure.
- Do not generate replacements for retired effects, HUD symbols, projectiles,
  states, pickups, or facilities as individual PNGs.
- Generate exact deletion reports from the revised workbench; do not turn this
  evidence document into a second approval ledger.
- Run cheap deterministic build/schema/syntax checks during migration, but run
  the complete native/Web visual and release suite once after all switches and
  asset changes are complete.

## Limitations

- This audit does not implement any renderer, catalog, manifest, validator, or
  production-file change.
- Existing code-native recipes are reusable implementation inputs, not approved
  runtime appearance. They still require actual-scale rendered evidence.
- The four defense topologies and three persistent-status shapes need a complete
  shared mesh recipe implementation; their current catalog still names raster
  assets.
- Current counts must be re-audited if production files, the manifest, or live
  consumers change after this document's repository baseline.
- Final removal is destructive and requires new exact-path approval. Earlier
  Phase approvals do not authorize the rationalized retirement sets.
