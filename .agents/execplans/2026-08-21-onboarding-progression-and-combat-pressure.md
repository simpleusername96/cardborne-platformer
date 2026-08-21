---
type: plan
status: active
owner: BK
created: 2026-08-21
last_reviewed: 2026-08-21
topic: Enemy onboarding, spawn composition, progression pacing, combat pressure, visual warnings, terminology, and performance proof
scope: Cardborne twelve-stage vehicle run, ordinary enemy families and traits, XP thresholds, ordinary and boss pressure, bombardment readability, telemetry, validators, and release evidence
related:
  - ../../AGENTS.md
  - ../PLANS.md
  - ../design/DESIGN.md
  - ../cardborne-performance-engineering-policy.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/reports/2026-08-21-onboarding-progression-and-combat-pressure-ko.html
---

# Onboarding, Progression, and Combat Pressure Execution Plan

## Outcome

Deliver a twelve-stage run that teaches all five ordinary enemy families through kill-gated opening waves, then switches to a constrained but varied spawn system. Preserve early build formation while reducing late upgrade interruptions, make every family visibly threaten or support combat, increase ordinary and boss pressure without shortening fair startup warnings, and prove the resulting load with valid native and Web performance evidence.

The canonical neutral name for the ranged ordinary family is emitter. The Korean player-facing label is 방출형. This plan includes a repository-wide migration from the legacy ranged-family token to that name.

## Status and Progress

- [x] Inspected the current stage authoring, squad construction, family and trait catalogs, movement policies, attack state machine, XP runtime, drop rewards, renderer, visual authority, retained captures, and performance logs.
- [x] Compared local findings with relevant pacing, XP, VFX readability, and profiling references.
- [x] Locked the design values and responsibility boundaries below.
- [x] Removed predicted route geometry from hostile projectile startup descriptors, including the stage-8 broad barrage, while preserving source readiness and active damage truth.
- [x] Replaced the capped tier multipliers with a smooth XP curve that reaches level 49 after stage 10 and level 55 after stage 12 on the connected composed-identity path.
- [x] Implement the terminology migration and semantic validators.
- [x] Implement onboarding, post-onboarding composition, family behavior, progression, pressure, and bombardment changes.
- [ ] Capture valid gameplay telemetry and performance evidence, then update accepted product documentation.

The projectile-route correction, XP curve, terminology migration, encounter composition, family behavior, combat pressure, and bombardment readability are implemented. Full-run telemetry, integrated validation, and performance proof remain in the decision-complete execution contract below.

Phase 0 checkpoint (2026-08-21): all tracked runtime IDs, localization stems, semantic asset IDs, PNG paths, reports, workbench references, and validators now use emitter / 방출형. Nine runtime PNG files and eighteen retained report/workbench PNG files kept identical SHA-256 content across their path rename. Godot 4.7.1 reimported the runtime textures without error. The guidebook store now migrates schema-v1 discovery IDs and rewrites them as schema v2. The tracked text/path scan returned zero legacy-token matches; guidebook, semantic-asset, combat-renderer, and visual-authority validators passed.

Phase 1–2 checkpoint (2026-08-21): VehicleEnemySpawnComposition now owns the five base-only onboarding templates, seed-driven 4:3:3 normal pack bags, one eligible coordinator overlay, per-family 4:3:3 trait bags, exact emitter-defender members, and maintenance-safe atomic splitting. VehicleEncounterRuntime owns typed run-global defeat and bridge progress, per-enemy spawn metadata, bounded emitted-pack evidence, invariant failures, and attack-family counts. Stage/session reports retain family/trait defeats, attack commits, XP, level, upgrade-modal count and duration, and pack composition. The first 65 stage-1 slots are kill-gated at 15/30/45/60; normal admission follows the bridge. Focused composition, family, catalog, arrival, maintenance, pacing, engagement replay, telemetry, and report validators pass without changing quota, authored counts, caps, or cadence.

Phase 3 checkpoint (2026-08-21): Pursuers and chargers retain individual approach ownership during collective gather and lock, and their recovery vectors keep the locked 65/35 and 55/45 forward-to-tangent weights with positive playerward motion. Defenders bind to an exact same-squad emitter, hold its player-facing screen point, and gain the 0.60/0.24-second, 14-damage, 500-speed bash only after that emitter is gone. Coordinators now commit a 0.80-second warned, 12-damage, 420-speed direct projectile with 1.50-second recovery. Artillery creates a delayed marked ground impact rather than a moving shell. Normal and boss-add spawns retain per-enemy family, tier, trait, and escort identity. All 45 family-tier-trait mappings resolve unique approved 256x256 PNG paths, and base/trait sibling hashes differ. Focused movement, attack, contact, specialist integration, semantic asset, renderer, and visual-authority validators pass.

Phase 4 checkpoint (2026-08-21): `build/performance/progression-c76fbfb2-20260821-115650.json` is a clean exact-commit progression capture for `c76fbfb2d3ed9dfbd369d8bb413bb4ed672b32ed`, content fingerprint `808c34030f4bbf5be96919f0f6fa079845713d84db6fb400866e27e759c48d26`. It records all twelve cycles, 13,498 XP, level 49 after cycle 10, level 55 after cycle 12, and 54 upgrade opens/confirmations. The capture explicitly records human modal duration and confirmation time as unmeasured instead of manufacturing timing. The XP and progression-capture validators pass.

Phase 5 checkpoint (2026-08-21): Ordinary movement is 1.48x; ordinary post-active downtime uses 0.90x and emitter downtime an additional 0.85x. Boss speeds, phase gaps, autonomous gaps, and direct recovery use the locked values. Hostile projectile collision radii are 6/7.5/9 with a 4.20 visual envelope. VehicleAttackContract now owns the shared 0.75-second bombardment addition, warned startup transformation, and exact two-band or three-band radial damage. Warning areas render from the first warning frame and cannot commit damage until a later active update; retained concentric disks and boundaries match gameplay radii. Projectile startup remains source-only, including stage 8. Combat performance fixtures now use the canonical 80-batch visual ceiling. Attack, specialist, boss, route-readability, difficulty, renderer, damage-feedback, performance-scenario, and visual-authority validators pass. A diff-scoped responsibility audit consolidated startup-warning policy into the attack contract and found no remaining competing owner in the task-owned surface.

Phase 6 implementation checkpoint (2026-08-21): Production replay now completes the typed 60-defeat onboarding and bridge on the same run-global encounter owner before final-stage reconfiguration. Qualification requires all five normal families, direct commits from every attacking ordinary family, ranged and denial commits, and live hostile projectiles. Artillery is classified into the denial lane at canonical enemy construction. The performance-scenario and specialist integration validators pass. A deterministic progression evidence owner now replays production family traits, the connected-run seed, the initial authored XP once, and the production XP runtime; it records modal count but explicitly leaves human modal timing unmeasured. This trace exposed and removed the earlier trait-free/per-cycle-map-XP projection error. The corrected curve reaches level 49 after cycle 10 and 55 after cycle 12 with 13,498 XP. Exact-commit progression JSON and integrated validation are complete; built-Web interaction and final performance qualification remain.

Phase 6 validation checkpoint (2026-08-21): Commit `a6572569f2273cdfa4cde852a7f4dec6e93c5d6e` exports the complete nine-file Web artifact. Static itch verification passes at 24,537,942 gzip bytes against the 26,949,682-byte allowance, and guarded HTTP delivery returns 200 for the document, JavaScript, WASM, and PCK. The browser-control bridge was unavailable in this session, so rendered interaction and Web performance remain unqualified; HTTP delivery is not substituted for a built-app boot claim. The clean exact-commit native payload is `build/performance/onboarding-progression-combat/a6572569-production-replay-native-60s.json`, SHA-256 `91d82a358f720a80f778e5c9bf2a26776346be3548cb18e9fe0b368f90b59417`, content fingerprint `0d8be41029c48f9754cbc0673f353496bd8a18aea42d62934c6fd66a5b3c6865`. It has a valid production workload with ordinary-family commits pursuer 80, charger 68, emitter 80, defender 3, coordinator 13; maximum ranged commits 2, denial commits 1, and hostile projectiles 5. Frame p95/p99 is 16.667/16.667 ms, maximum consecutive frames above 33.3 ms is 0, draw-call p95 is 71, and combat batches are 66. Physics p95/p99 is 7.799/9.713 ms and 1% low is 53.38 FPS, so the unchanged 6/8 ms and 55 FPS gates fail. Persistent unrelated Chrome and PicPick activity meant the machine was not quiescent; despite the recorder's source/runtime authority flag, this plan classifies the payload as diagnostic and does not select an optimization owner from it. A final native qualification requires the same command on a quiescent machine, and the built-Web interaction/performance checks still require an available browser bridge.

## Evidence Inspected

### Local implementation facts

1. VehicleCombatStages currently authors twelve stages and hard-locks each stage to a rotating set of three ordinary families. Stage 1 currently rotates pursuer, charger, and the ranged family. Family introduction is not tied to player kills.
2. Stage 1 has a 90-kill boss quota and 260 authored ordinary enemies. A 60-kill onboarding sequence can therefore finish before the first boss without changing the quota.
3. VehicleEncounterRuntime opens with six enemies. Stage 1 then schedules twelve arrival windows; later stages schedule three windows with four squads each. Pack sizes are four through eight.
4. Pack family and trait are currently stored at pack level. Defenders appended to a ranged pack inherit the ranged family and trait metadata. This breaks per-enemy family behavior and can select an incorrect visual asset.
5. The trait selector already forms distinct family-and-trait asset IDs. The selection path works when enemy metadata is correct; the pack metadata bug prevents reliable use for appended defenders.
6. Defender and coordinator ordinary roles return from their update branches after movement and never enter a direct attack state. Their contribution is therefore difficult to see, and neither can damage the player directly.
7. Defender movement already attempts to stand between an assigned ranged ally and the player. When no protected ally exists, it falls back toward the player. The metadata and pairing defects make this contract unreliable.
8. Collective gather, lock, and execute states can take position ownership from pursuer and charger movement. Their recovery vectors also include lateral movement or retreat. These paths explain close-range units visibly avoiding the player.
9. The current XP formula leaves levels 1 through 5 unchanged, applies 1.5 times at levels 6 through 10, applies 2 times after that, and caps every later requirement at 192 XP. The low cap, not only the early multipliers, causes repeated late upgrade interruptions.
10. The renderer suppresses hostile-area geometry while its warning timer is positive. It first shows the area when damage becomes active. This is a direct mismatch with the visual system requirement that startup show the exact danger footprint and readiness.
11. The artillery trait currently becomes a moving hostile projectile. The product contract describes a marked impact attack. The runtime behavior and intended behavior are not aligned.
12. No retained log records the number or total duration of upgrade-modal interruptions. Existing performance counts labeled experience are shard counts, not level-up measurements.

### Current XP reference points

| Reached level | Current next requirement | Current cumulative XP | Current upgrade count |
| ---: | ---: | ---: | ---: |
| 5 | 25 | 94 | 4 |
| 10 | 80 | 401 | 9 |
| 15 | 180 | 1,109 | 14 |
| 31 | 192 cap | about 4,000 | 30 |
| 51 | 192 cap | about 8,000 | 50 |
| 93 | 192 cap | about 16,000 | 92 |

### Performance receipt

The diagnostic file is build/performance/diagnostics/current-8bcdd3f2-production-replay-native-30s.json. It was captured from commit 8bcdd3f2 with 10 seconds of warmup and 30 seconds of sampling.

| Measure | Current diagnostic |
| --- | ---: |
| Median active enemies | 72 |
| Frame p95 / p99 | 3.333 / 7.920 ms |
| 1% low | 94.87 FPS |
| Physics p95 / p99 | 6.505 / 8.269 ms |
| Render CPU / GPU | 0.495 / 1.052 ms |
| Draw calls p95 | 63 |
| Combat batches | 66 |
| Longest frame above 33.3 ms | 0 consecutive frames |

This run is diagnostic only. The source tree had three unrelated untracked files, the machine was not quiescent, and scenario validation failed because ranged commits, denial commits, and hostile-projectile pressure were zero or near zero. The current frame data supports the user's observation that presentation feels smoother, but it does not prove full-combat performance. Older valid cap-48 logs are not causal comparisons because the active population and workload differ.

### External evidence and applicability

- Valve's Left 4 Dead AI Director presentation describes pacing through changes in encounter frequency and population and warns against constant undifferentiated combat. It supports a clear authored teaching sequence followed by varied constrained packs. It does not justify adding adaptive difficulty in this task.
- Riot's VFX style guide treats gameplay space, power, function, shape, color, and timing as one readability contract. It supports drawing the exact danger area during warning and showing concentric damage zones. It does not override Cardborne's own visual authority.
- Brotato's documented quadratic XP requirement is a comparable survivor-style example that avoids a low flat late-game requirement. This plan uses Cardborne-specific piecewise multipliers rather than copying that formula.
- Godot's profiler documentation separates frame, physics, rendering, and custom script costs. It supports measuring the changed workload by subsystem and on the exact implementation commit.

## Domain and Ownership Alignment

| Concept | Canonical term | Owner | Invariant |
| --- | --- | --- | --- |
| Ranged ordinary family | emitter / 방출형 | VehicleEnemyFamilyTraitCatalog | One runtime ID, one localization stem, one asset stem |
| Opening teaching state | onboarding phase | VehicleEncounterRuntime | Run-global; resets only on a new run |
| Squad composition policy | spawn composition | New VehicleEnemySpawnComposition | Pure templates and deterministic weighted bags; no admission timing |
| Squad admission and quota | encounter admission | VehicleEncounterRuntime | Preserves authored population and boss quota |
| Family and trait identity | per-enemy spawn metadata | Spawn packet and VehicleRun | Never inherited from an unrelated pack member |
| XP threshold | level requirement | VehicleExperienceRuntime | Piecewise curve; no low late flat cap |
| Bombardment warning | warning phase | Combat attack data and renderer | Exact footprint is visible before any damage |
| Bombardment damage | radial damage bands | Combat gameplay state | Collision and damage never derive from pixels |
| Performance truth | exact-commit evidence | Performance capture and policy | Valid workload, clean source identity, named platform |

VehicleCombatStages continues to own stage quota, tier, authored population, and pressure budgets. It must stop owning a hard post-onboarding family rotation. UI code must not own progression or combat behavior.

## Visual Authority Receipt

- Specification: docs/design/VISUAL_SYSTEM.md
- Reference sheet: docs/design/cardborne-universal-art-style-reference.png
- Specification SHA-256: ff4e626c98a72e16caf975199af1dd5895951e885cf6e2e910dd0a24e75994ab
- Reference sheet SHA-256: 96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889
- Inspected scope: original 1448 by 1086 reference sheet and the full visual specification relevant to actors, hostile projectiles, hostile circular areas, warning timing, batches, and asset provenance.

Visual constraints for implementation:

1. Keep 45 ordinary enemy identities: five families, three tiers, and base, trait A, and trait B variants.
2. Family and trait must select the exact PNG texture. Do not recolor one family texture at runtime to simulate traits.
3. Keep the authored hostile bolt and change its runtime scale and collision truth together.
4. Implement bombardment warnings and damage bands with retained code-native geometry. Do not create a new raster or SVG effect.
5. Show the full danger-red body, thin dark perimeter, inward notches, readiness change, and exact band boundaries.
6. Gameplay owns collision and damage. Visual geometry reads that truth and never defines it.
7. Keep combat batches at or below the canonical limit of 80.
8. The terminology migration renames semantic asset files and IDs but does not change approved pixels.

## Scope

### Included

- Full tracked-repository terminology migration to emitter and 방출형.
- Five-step, kill-gated, run-global onboarding.
- Post-onboarding pack and trait weighted bags with pairing constraints.
- Per-enemy family and trait metadata.
- Pursuer, charger, defender, coordinator, and emitter behavior corrections.
- Trait-specific PNG selection and complete identity validation.
- Piecewise XP requirements and late cap increase.
- Ordinary and boss movement and attack-frequency changes.
- Hostile projectile sizing.
- Marked bombardment warning, radial damage bands, and matching effects.
- Gameplay telemetry and exact-commit performance validation.
- Korean and English localization completeness.

### Excluded

- Adaptive difficulty or a player-specific dynamic intensity director.
- New enemy families, traits, stages, cards, bosses, or production dependencies.
- Changes to XP drop values in this pass.
- New player-facing raster art or AI-generated art.
- Rebalancing player weapons or boss health.
- Replacing the modal upgrade-selection interaction. This plan reduces its frequency and measures its cost.

## Locked Design

### 1. Run-opening onboarding

Onboarding is run-global and resets on a new run. Ordinary kill count, not stage number or elapsed time, opens each phase. Tutorial squads replace the first 65 authored slots; they do not add population above the stage budget.

| Ordinary kills before spawn | Phase | Five-unit squad template | Trait policy | Completion |
| ---: | --- | --- | --- | --- |
| 0–14 | Pursuit | 5 pursuers | base only | Three squads; open at 15 kills |
| 15–29 | Ranged pressure | 3 pursuers + 2 emitters | base only | Three squads; open at 30 kills |
| 30–44 | Charge pressure | 2 pursuers + 1 emitter + 2 chargers | base only | Three squads; open at 45 kills |
| 45–59 | Protection | 2 pursuers + 1 charger + 1 emitter + 1 defender | base only | Three squads; open at 60 kills |
| 60 bridge | Coordination | 2 pursuers + 2 chargers + 1 coordinator | base only | One squad, then normal rules |

The bridge squad is queued at the 60th ordinary defeat. Normal composition cannot admit a squad until that bridge squad has been admitted. Stage 1's 90-kill quota remains unchanged, so every family appears before the first boss.

The encounter runtime receives explicit ordinary-defeat progress through a typed API. It must not infer onboarding state from arbitrary string events.

### 2. Post-onboarding composition

Use a deterministic, seed-driven weighted shuffle bag of ten pack templates:

- Four pursuer packs.
- Three charger packs.
- Three emitter-and-defender paired packs.
- Add one coordinator overlay to exactly one eligible pursuer or charger pack in each bag by replacing one member.

Emitter and defender slots are always emitted as pairs. For an odd-sized paired pack, fill the remaining slot with a pursuer. A coordinator can never appear alone and can never overlay an emitter-and-defender pack.

At representative pack size six, one ten-pack bag produces approximately 38% pursuers, 30% chargers, 15% emitters, 15% defenders, and 2% coordinators. This retains pursuer as the largest family, charger second, exact emitter-to-defender equality, and a rare coordinator presence. Pack order remains variable within the bag.

Stage data continues to control tier, pack size, active cap, timing pressure, authored count, and boss quota. It no longer excludes two families after onboarding.

### 3. Trait distribution and visuals

For each family independently, use a deterministic shuffled bag across ten eligible occurrences:

- Four base identities.
- Three trait A identities.
- Three trait B identities.

This realizes a 4:3:3 distribution without long random droughts. The onboarding phase uses base identities only. Every spawned enemy stores its own family and trait. A defender appended to a paired pack therefore remains a defender and selects its defender texture.

Validate all 45 family, tier, and trait combinations by loading the resolved texture and comparing their declared identity and content hash. A family can share a silhouette, but base and trait variants must not resolve to the same PNG file.

### 4. Family movement and attacks

#### Pursuer and charger

- Pursuit families ignore collective gather and lock position ownership.
- Only a committed charge or fuse attack and an actual collision or geometry block may temporarily override approach movement.
- Pursuer recovery direction is 65% toward the player and 35% tangent.
- Charger recovery direction is 55% toward the player and 45% tangent.
- During normal and recovery motion, the desired-velocity dot product toward the player must remain positive when no collision or committed attack exception applies.

#### Defender

- When a paired emitter is alive, the defender targets a point between that emitter and the player, stays in front, and does not abandon protection to chase.
- The target must be the emitter from the same squad.
- When the paired emitter is missing or defeated, the defender pursues the player and gains a shield bash: 0.60-second startup, 0.24-second active window, 14 damage, 500 speed, and 1.40-second recovery.

#### Coordinator

- Keep existing support traits.
- Add a visible direct projectile attack: 0.80-second startup, 12 damage, 420 projectile speed, 34-pixel origin offset, and 1.50-second recovery.
- The attack must participate in ordinary attack telemetry and the production replay.

#### Emitter

- Keep its direct ranged role.
- Convert the artillery trait to a marked ground impact instead of a moving shell.
- Preserve the slow trait's semantic behavior while migrating its family ID and asset paths.

### 5. Progression curve

Keep the exact level-1-through-5 requirements at 14, 16, 18, 21, and 25 XP. From level 6 onward, let `k = current level - 5` and calculate `min(1,536, ceil(25 + 4.01k + 0.176k²))`. This removes multiplier cliffs and the reachable 192-XP plateau while preserving the first five choices. The coefficients were corrected after the composed-family trace proved that the earlier projection had treated every ordinary identity as trait-free and had incorrectly repopulated ten authored XP shards on every cycle.

The deterministic connected-run trace below uses the production composition traits, quota-limited authored defeat order, the initial ten 5-XP authored map shards once, the initial tactical-layout encounter seed retained by cycle continuation, no boss XP because boss cleanup disables it, and no boss-add XP. Boss adds can raise the result while missed initial map shards lower it.

| Stage cleared | Trace stage XP | Cumulative XP | Expected level |
| ---: | ---: | ---: | ---: |
| 1 | 726 | 726 | 16 |
| 2 | 633 | 1,359 | 22 |
| 3 | 682 | 2,041 | 26 |
| 4 | 741 | 2,782 | 30 |
| 5 | 902 | 3,684 | 33 |
| 6 | 956 | 4,640 | 36 |
| 7 | 1,037 | 5,677 | 39 |
| 8 | 1,112 | 6,789 | 42 |
| 9 | 1,569 | 8,358 | 46 |
| 10 | 1,642 | 10,000 | 49 |
| 11 | 1,687 | 11,687 | 52 |
| 12 | 1,811 | 13,498 | 55 |

| Reached level | Next requirement | Cumulative XP spent to reach level | Upgrade count |
| ---: | ---: | ---: | ---: |
| 5 | 25 | 69 | 4 |
| 10 | 50 | 241 | 9 |
| 15 | 83 | 554 | 14 |
| 20 | 125 | 1,050 | 19 |
| 30 | 236 | 2,771 | 29 |
| 40 | 381 | 5,755 | 39 |
| 50 | 562 | 10,354 | 49 |
| 55 | 666 | 13,369 | 54 |

The current deterministic connected-run path reaches level 49 after stage 10, within one level of the requested approximate level-50 target, and level 55 after stage 12. Record upgrade-modal open count, total open time, confirmation time, XP collected, level reached, and upgrades by stage. Deterministic evidence records modal count but labels human modal and confirmation time as unmeasured. If valid gameplay telemetry differs by more than two levels at stage 10, reopen the curve with the measured XP total instead of silently tuning it.

### 6. Attack pressure and movement

- Increase the ordinary global movement multiplier from 1.40 to 1.48.
- Increase each boss movement speed by 6%, rounded to the nearest 5: 405, 420, 435, 450, 465, 480, 500, 515, 525, 535, 545, and 555.
- Do not reduce ordinary or boss startup warnings.
- Apply a 0.90 ordinary post-active recovery scale globally.
- Apply an additional 0.85 recovery scale to emitter attacks. Combined recurring emitter downtime becomes about 23.5% shorter while startup remains unchanged.
- Change boss direct recovery scale from 0.80 to 0.72.
- Change boss phase gaps from 0.45, 0.34, 0.26 seconds to 0.40, 0.30, 0.24 seconds.
- Change autonomous boss gaps from 5.4, 4.4, 3.5 seconds to 4.8, 3.9, 3.1 seconds.
- Leave internal volley spacing and startup values unchanged in the first implementation pass.

### 7. Hostile projectiles and bombardment

- Increase hostile projectile collision radii from 5, 6, and 7 to 6, 7.5, and 9.
- Increase the projectile visual envelope scale from 3.85 to 4.20.
- Derive the visible danger width from the actual collision radius.
- Add 0.75 seconds to marked bombardment warnings. The ordinary ground-burst warning changes from 0.48 to 1.23 seconds. Boss area events receive the same added warning through the shared bombardment owner.
- Render the exact hostile area for the full warning period, then transition to the active impact state.

Damage bands are exact gameplay radii:

| Bombardment size | Radial band | Damage scale |
| --- | --- | ---: |
| Radius below 120 | 0–50% | 100% |
| Radius below 120 | 50–100% | 45% |
| Radius 120 or above | 0–33% | 100% |
| Radius 120 or above | 33–67% | 70% |
| Radius 120 or above | 67–100% | 40% |

The renderer draws matching concentric boundaries and a stronger active center. The warning must never apply damage. The active effect must not conceal the outer collision boundary.

## Execution Tasks

### Phase 0 — Canonical terminology migration

- [x] Rename the runtime family ID, archetype IDs, localization stems, constants, semantic asset IDs, PNG filenames, imports, tests, reports, workbench references, manifests, and current telemetry fixtures to emitter.
- [x] Use Emitter T1/T2/T3 in English and 방출형 T1/T2/T3 in Korean.
- [x] Rename the family pairing constant to EMITTERS_PER_DEFENDER.
- [x] Keep artillery and slow trait names and behavior.
- [x] Regenerate Godot import sidecars after PNG path changes; do not change image pixels.
- [x] Confirm the guidebook discovery save boundary and migrate schema-v1 IDs to schema v2 before removing the retired identifier.
- [x] Require zero matches in tracked text and paths with git grep -Iin -E 'g[u]nner' and git ls-files | rg -i 'g[u]nner'.

Acceptance: all tracked repository content, semantic paths, new release artifacts, localization, validators, and runtime capture schemas use emitter or 방출형. Historical ignored outputs are not evidence and are regenerated when task-owned.

### Phase 1 — Telemetry and composition owner

- [x] Add scripts/encounters/vehicle_enemy_spawn_composition.gd as the pure owner of onboarding templates, post-onboarding pack bags, trait bags, pair construction, and coordinator eligibility.
- [x] Add typed encounter-runtime progress for run-global ordinary defeats and bridge admission.
- [x] Extend stage/session telemetry with kills by family and trait, emitted pack contents, pair and coordinator invariants, XP collected, level, upgrades, modal opens, modal duration, and attack commits by family.
- [x] Extend the deterministic capture format without making UI code a gameplay owner.

Acceptance: a headless deterministic capture can reconstruct every onboarding transition, pack membership, family-trait identity, level-up interruption, and family attack count.

### Phase 2 — Onboarding and normal spawn composition

- [x] Replace the first 65 authored slots with the locked onboarding templates.
- [x] Gate phases at 15, 30, 45, and 60 ordinary defeats and gate normal admission on the bridge squad.
- [x] Replace post-onboarding stage family rotation with the locked ten-pack shuffle bag.
- [x] Enforce exact emitter-defender pairs and coordinator overlay eligibility, including quota-seal maintenance rosters.
- [x] Preserve stage quota, tier, active cap, admission cadence, and authored population.
- [x] Store family and trait per enemy rather than only per pack.

Acceptance: repeated seeded simulations show the exact tutorial order, 4:3:3 pack bag, one eligible coordinator overlay, exact emitter-defender equality, no standalone coordinator, no coordinator paired pack, and no quota or population drift.

### Phase 3 — Family behavior and trait visual identity

- [x] Remove collective-position preemption from pursuer and charger approach paths.
- [x] Apply the locked forward recovery vectors and add direction-invariant tests.
- [x] Make defenders bind to the paired emitter, hold the player-facing front position, and switch to bash only after losing that target.
- [x] Add the coordinator direct projectile attack.
- [x] Convert emitter artillery to marked bombardment.
- [x] Correct per-enemy family and trait metadata from spawn through rendering.
- [x] Validate all 45 ordinary family-tier-trait PNG resolutions and hashes.

Acceptance: pursuit units continuously close, protected emitters remain behind their defender, unpaired defenders visibly attack, coordinators visibly attack, and every trait variant selects its distinct approved PNG.

### Phase 4 — Progression pacing

- [x] Apply the smooth post-level-5 quadratic curve and 1,536 cap in VehicleExperienceRuntime.
- [x] Update progression validators with exact thresholds and all twelve current-path stage levels.
- [x] Keep XP drops unchanged.
- [x] Run one valid full-run telemetry capture.

Acceptance: threshold tests match every locked checkpoint, the deterministic connected-run path reaches level 49 after stage 10 and level 55 after stage 12, and valid full-run telemetry stays within two levels of the stage-10 target.

### Phase 5 — Combat pressure, projectile scale, and bombardment readability

- [x] Apply ordinary and boss movement values and recovery/cadence values.
- [x] Apply projectile collision and visual scale together.
- [x] Make every hostile projectile startup descriptor source-only: retain origin, committed direction, damage, affinity, lead time, and readiness, but never publish a predicted endpoint, corridor width, or future path. This includes the stage-8 broad barrage and alternating-sector projectile release.
- [x] Render hostile-area warning geometry before damage.
- [x] Apply the 0.75-second bombardment warning addition through one shared owner.
- [x] Implement two-band and three-band radial damage falloff and matching retained visual geometry.
- [x] Keep startup warnings and collision truth separate from effect pixels.
- [x] Validate warning-to-hit time, radial damage samples, visual footprint, and combat batch count.

Acceptance: no bombardment can damage during warning; sampled center, middle, and edge points receive the exact locked scales; projectile visuals cover collision truth; no hostile projectile startup descriptor or renderer exposes predicted route geometry; off-screen source readiness remains available; actual active beams and damage areas remain visible; ordinary and boss attack commits increase without reducing source readability.

### Phase 6 — Integrated validation, performance proof, and documentation

- [x] Update production replay so onboarding is complete before the measured interval and the ten-pack composition produces nonzero pursuer, charger, emitter, defender, coordinator, ranged, denial, and hostile-projectile activity.
- [x] Run focused spawn, movement, combat, XP, localization, asset, renderer, and visual-authority validators after their relevant implementation batches.
- [x] Export Web once the implementation is coherent.
- [ ] On a committed, clean, quiescent source tree, run one native production replay with 10 seconds warmup and 60 seconds sampling.
- [ ] Use the built Web app for the final production-style smoke and the strongest available Web performance capture.
- [x] Compare exact-commit evidence with the performance policy. Keep physics, frame pacing, draw, and scenario-validity gates intact. Align only the combat-batch validator to the canonical visual limit of 80.
- [x] Update accepted product documentation and this plan's progress with measured results, applicability, and any remaining risk.

Acceptance: native scenario validation passes with real attack load; no frame is above 33.3 ms for two consecutive frames; combat batches are at or below 80; the Web export completes and the built run preserves onboarding, combat, localization, and warning behavior.

## Validation Cadence

Use the least expensive evidence layer first and retain passing results until a relevant input changes.

1. Static scans: terminology, IDs, paths, imports, localization, and ownership.
2. Pure deterministic validators: tutorial transitions, weighted bags, pairing, coordinator eligibility, trait bags, XP table, attack parameters, radial damage samples.
3. Focused headless Godot validators: spawn-to-runtime metadata, movement direction, attack state transitions, texture resolution, warning state, damage state.
4. One integrated deterministic gameplay capture after all behavior changes are coherent.
5. One Web export and built-app smoke.
6. One final valid native performance capture on the exact committed tree.

Do not rerun a passing expensive check unless a relevant input changes. Do not use the invalid current diagnostic to claim release performance.

## Risks and Contingencies

| Risk | Detection | Locked response |
| --- | --- | --- |
| Tutorial admission stalls at a kill gate | No queued squad while active enemies are zero | Admit the already-qualified next tutorial squad; do not relax kill count |
| Stage 1 quota seals before the bridge | Deterministic quota simulation | Tutorial slots replace authored slots and have priority before normal packs |
| Emitter-defender equality breaks near quota | Pack ledger mismatch | Admit or defer the whole pair; never admit one member alone |
| Coordinator becomes invisible support | Zero direct commits in capture | Fail scenario validation; do not accept the run |
| Trait variants still look identical | Same resolved path or content hash within one family and tier | Fail asset validation and fix metadata or path mapping |
| XP target misses after valid run | Telemetry outside locked bands | Reopen this plan and change the curve explicitly; no silent tuning |
| Larger projectiles or denser attacks exceed performance limits | Exact-commit production replay failure | Profile projectile, overlay, and collision owners; preserve warning and collision truth while optimizing implementation |
| Damage-band visuals exceed batch limit | Combat batches above 80 | Merge retained geometry by material/state; do not remove gameplay boundaries |
| A persisted legacy ID is found | Save or migration test fails | Add an explicit compatibility migration before the hard rename |

## Rejected Alternatives

1. Keep rotating three-family stage rosters: rejected because two families can remain absent or unreadable, and it conflicts with teaching all five before normal play.
2. Independent random rolls for every family and trait: rejected because short runs can produce long droughts, broken pair ratios, and coordinator-only packs.
3. A global 3:3:3:1 unit roll: rejected because it cannot guarantee emitter-defender equality or coordinator companions and makes pack intent hard to read.
4. Preserve the 192 XP cap and only raise early multipliers: rejected because the late flat cap is the primary source of repeated upgrades.
5. Increase attack frequency by shortening startup: rejected because it makes threats less fair. Recovery and inter-attack gaps are the pressure levers.
6. Keep artillery as a moving projectile: rejected because it contradicts the marked-impact contract and cannot solve the invisible warning problem cleanly.
7. Claim performance from the current 30-second run: rejected because the measured scenario had no meaningful ranged or denial attacks.

## Completion Definition

This plan is complete only when every phase acceptance condition passes on one coherent commit, the terminology scan has zero tracked matches, Korean and English surfaces are complete, the valid native and built-Web evidence is linked here, and the accepted product documents reflect the shipped rules. A smoother-feeling frame trace without real attack load is not completion.

## References

- Valve, AI Systems of Left 4 Dead: https://steamcdn-a.akamaihd.net/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf
- Riot Games, League of Legends VFX Style Guide: https://nexus.leagueoflegends.com/en-us/2017/10/dev-leagues-vfx-style-guide/
- Brotato Wiki, Experience: https://brotato.wiki.spellsandguns.com/Experience
- Godot Engine documentation, The Profiler: https://docs.godotengine.org/en/4.5/tutorials/scripting/debug/the_profiler.html
