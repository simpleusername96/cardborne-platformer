---
type: plan
status: active
created: 2026-08-08
last_reviewed: 2026-08-09
scope: Cardborne combat pressure, enemy movement, progression feedback, HUD and minimap readability, elemental hit behavior, surface and boss presentation, and qualified frame pacing
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../design/DESIGN.md
  - ../cardborne-performance-engineering-policy.md
  - 2026-08-02-pre-asset-code-stabilization.md
---

# Combat Pressure, Progression Feedback, Combat Readability, and Surface Depth - Execution Contract

Deliver a harder-to-cheese but less front-loaded five-stage run and restore the missing combat
feedback loop. The completed portion removes neutral hazards, applies the selected ordinary-health
curve, makes role movement distance-aware, strengthens boss shielding, replaces Thermal Burn with
bounded Thermal Burst damage, integrates sparse approved surface detail, and replaces the boxed
straight-beam strip. The remaining portion restores unmistakable XP progress, prevents late-run level
rewards from disappearing when fewer than three legal cards remain, removes the redundant and
ambiguous live upgrade-icon rail, keeps only differently weighted hull and experience meters in the
top-center HUD, makes elemental upgrades show their real current-to-next values, restores restrained
nearby-enemy direction cues, differentiates minimap roles, makes Electric Field show its complete
damage area without reading as a shield, adds bounded elemental hit feedback, and stops the boss
shield from masking authored boss bodies. The
verified implementation baseline for this revision is `b9a41aee`; current HEAD
still has no eligible native/Web release-performance qualification, so the exact final workload is
measured once after all remaining behavior and visual work is complete.

## Purpose

- Objective: implement the requested pressure, movement, progression, HUD, minimap, shield,
  elemental, surface, beam, and frame-pacing outcomes as one decision-complete sequence with
  independent causal commits.
- Deliverable: updated gameplay and movement rules; a truthful bilingual XP and upgrade flow;
  a two-meter top-center HUD with no live upgrade icons; retained threat-radar, minimap, Electric
  Field, projectile, status, and shield presentation; approved
  production surface SVGs, beam raster, and any separately approved Thermal impact raster;
  focused validators; production Web export; and eligible native/Web performance evidence.
- Completion state: neutral hazards no longer exist; ordinary health uses the locked five-stage
  curve; mobile enemies preserve role distance continuously; shielded bosses take 15% incoming
  damage and remain visually identifiable; Thermal Burst applies bounded enemy-only splash with
  bounded impact feedback; XP progress and late-run rewards never disappear silently; upgrade
  copy shows true level deltas; the live HUD contains no acquired-upgrade icon rail while paused
  Settings > Ship Status retains the full named build; nearby off-screen enemies and distinct
  minimap roles are readable;
  Electric Field fills the exact `120/140/160` damage disk in Arc purple instead of reusing shield
  language; Toxin/Cryo states are visible as same-silhouette translucent body overlays without
  per-enemy nodes; the floor and straight beams retain the
  approved presentation; and all correctness, visual, export, and performance gates pass from the
  exact clean final commit.

## Scope and Boundaries

In scope:

- Remove the current four traversable `hazard_zone` footprints, their player/enemy/boss damage,
  lingering exposure, rendering, production assets, guidebook entry, localization, docs, and
  obsolete validator branches.
- Change only ordinary-enemy stage health scaling to `[0.85, 1.00, 1.15, 1.30, 1.45]` while
  retaining authored archetype health, the current ordinary final multiplier `2.60`, and the
  existing 1.12 swarm/standard class factor.
- Preserve existing enemy roles but make mobile pursuit, standoff, escort, and support movement
  obey continuous distance bands. Remove the far-distance route override that currently masks
  ranged standoff behavior, and smooth ordinary role turns without changing attack cadence.
- Change boss `shield_up` incoming damage from `0.25` to `0.15`; preserve the `1.0` exposed
  multiplier, four-second shield-down window, transitions, and `final_effective` bypass.
- Replace the persistent thermal condition and the `thermal_burn` card identity with
  `thermal_burst`: primary-projectile hits create enemy-only splash with radii `72/84/96` and
  flat damage `4/6/8` at levels 1/2/3.
- Introduce the presentation-only `SurfaceDetail` visual category and promote the exact approved
  `_01` deterministic SVG from each family: crack, stain/wear, and embedded debris chip. Keep
  `_02` files as review alternatives outside production so the runtime stays at three batches.
- Replace the current dark-bordered `cue/beam_strip_9` raster with a tintable flat alpha mask and
  retune the existing two-plane startup/three-plane active composition for Beam Sentinel and boss
  straight beams.
- Remove every acquired-upgrade icon and level numeral from the top-center HUD. Keep only the
  panel-free hull and XP meters there: the hull remains `player_reward` amber with a 13-pixel fill,
  while XP uses a restrained `system` blue fill at `6/8/8` pixels for compact/standard/large and
  shares the hull meter's full width. Label the XP value with the literal `EXP` so the two meters
  remain distinguishable without color. Publish XP through the reusable fast-HUD snapshot instead
  of rebuilding the full build snapshot. Preserve the complete named upgrade list in paused
  Settings > Ship Status.
- Permit one, two, or three legal upgrade choices near catalog exhaustion. Show an explicit
  localized `MAX` progression state only when zero compatible upgrades remain; never consume a
  pending level through a warning-only path.
- Make first-acquisition and enhancement cards visibly different through gameplay-owned value
  rows. Thermal, Toxin, and Cryo must display the same level arrays that drive combat.
- Restore a low-priority `nearby_enemy` off-screen direction contact without duplicating visible
  enemies or exact minimap position. Preserve incoming-attack and boss-arrival priority.
- Expand the minimap's bounded semantic roles to distinguish field pickup, reward crate, Mystery
  Device, mobile enemy, fixed priority enemy, boss, and reinforcement facility by shape as well as
  color.
- Replace the current Mint Electric Field ring with an Arc-purple, ground-attached, low-alpha filled
  disk at the exact `120/140/160` gameplay radii. The enemy body-overlap rule remains gameplay truth;
  the visual adds no collision owner and does not reuse player/enemy shield geometry.
- Add one separately approved, bounded Thermal impact identity at the direct hit point and add
  Toxin/Cryo application and persistent status tint as a same-size, actor-alpha-clipped overlay
  composed through retained enemy-batch data. Do not add one node, raster, material, or timer object
  per affected enemy.
- Reduce the shared boss-shield overlay's visual dominance and give the boss minimap marker a
  command-color notched shape. Preserve the five existing authored boss PNG identities.
- Diagnose the reported hitch from eligible evidence and make only an evidence-selected,
  task-scoped performance correction if a release gate remains red.

Out of scope:

- Boss-owned telegraphed `denied_zones`; these are attacks, not the neutral map hazards.
- Boss base-health curve or final boss-health multiplier, ordinary damage/speed curves,
  encounter counts, quotas, spawn cadence, projectile/effect store capacity, collision rules,
  and performance thresholds.
- New named material, cultural, marine, ritual, or photoreal environment theme.
- Loose stones that imply collision, navigation, cover, or pickup behavior; the approved
  debris detail is embedded, flat, non-interactive floor wear.
- TileMap adoption, a full-field texture, runtime noise/shader generation, per-detail nodes,
  animated floor detail, gameplay collision, or stage-randomized detail layouts.
- A navigation rewrite, new pathfinding dependency, boids/flocking system, per-enemy full-neighbor
  scans, 60 Hz ordinary-decision cadence, or changes to attack startup/active/recovery timing.
- A Thermal world-radius telegraph, persistent ring, particle system, new sound asset, per-splash-
  target effect, or frame-animation pack. The permitted impact is one short authored identity at
  each eligible direct hit, scaled to the actual burst radius.
- Persistent Toxin/Cryo rings, outlines, enlarged silhouettes, status icons, orbit markers,
  per-enemy labels, repeated strobing, damage numbers, or separate status rasters.
- Recoloring the Seeker as if it inherited the selected primary element; its authored identity and
  gameplay payload remain separate from player-primary affinity.
- Redrawing the five boss bodies in this pass. If shield reduction does not reveal their existing
  silhouette differences at 1x size, open separate per-boss workbench units instead of silently
  restyling them.
- General optimization, workload reduction, visual-quality reduction, or dependency changes.

Constraints and invariants:

- Preserve the connected five-stage run, manual aim, held primary fire, dash, passive Seekers,
  EMP, authored encounters, map pickups, mutually exclusive elements, card choice flow, quota-
  gated bosses, and complete Korean/English user-facing copy.
- Keep visual geometry independent from collision truth and keep card behavior out of UI code.
- Keep gameplay values in progression/combat owners. HUD and card UI consume snapshots and never
  decide offer legality, progression completion, damage, radius, duration, or stack behavior.
- `docs/design/VISUAL_SYSTEM.md` and the exact canonical style-reference sheet remain the visual
  authority pair. The sheet SHA-256 must remain
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- Player-facing raster creation must use ImageGen or another raster authoring path with the
  canonical sheet supplied as an actual image reference. SVG/ImageMagick geometric authoring is
  prohibited except for the exact deterministic `SurfaceDetail` workflow approved by the user on
  2026-08-09 and recorded in `AGENTS.md`, `$cardborne-visual-authority`, and `VISUAL_SYSTEM.md`.
  ImageMagick remains limited to non-creative conversion and evidence work.
- The surface remains a low-detail neutral matte plane. Surface detail must be lower contrast
  than every actor, projectile, pickup, telegraph, objective, and world boundary.
- Surface placement is deterministic from the run-fixed field geometry plus a fixed salt. It
  must not depend on current-stage objects or alter topology, collision, reachability, or replay
  behavior.
- The world renderer stays retained. Surface instances use at most three existing-style
  `MultiMeshInstance2D` batches, zero per-instance nodes, zero per-frame transform updates, and
  keep `MAX_VISUAL_BATCHES <= 12`.
- Minimap and threat feedback remain code-native retained meshes. Electric Field uses one bounded
  retained code-native area batch because it visualizes collision-owned radius truth; it creates no
  per-frame or per-target nodes and stays beneath actors. Status feedback is composed into existing
  enemy instance colors with the authored body alpha acting as the exact overlay mask. Thermal
  impact uses the fixed 96-state effect store with a
  dedicated live cosmetic sub-limit and must never evict EMP charge/release state.
- The five images under
  `docs/design/visual-replacement-workbench/candidates/progression-feedback-combat-readability-v1/`
  and three alternatives under
  `docs/design/visual-replacement-workbench/candidates/hud-progression-density-options-v1/` are
  approval-before-implementation composition references only. They do not approve production
  pixels, replace exact runtime capture, or override this contract. The user's later no-icon
  decision supersedes every icon-bearing top-center layout shown in those references.
- Performance claims require eligible current-commit evidence under
  `.agents/cardborne-performance-engineering-policy.md`. Historical results are diagnostic only.
- Use Godot 4.7.1 through `./tools/godot.ps1`; add no production dependency.
- Movement logic may reuse the existing pursuit field, scheduler, packed overlap cache, and
  collision recovery only. It must preserve 10 Hz decisions, 30 Hz near motion, 20 Hz far motion,
  critical-phase updates, active counts, and the eight-neighbor overlap ceiling.

Destructive or irreversible actions:

- Retire the two now-unused tracked hazard production PNGs and their manifest entries only after
  all hazard consumers are removed. Git history makes the deletion recoverable.
- Rename `data/cards/vehicle/thermal_burn.tres` to `thermal_burst.tres` and replace the stable card
  ID because the product spec confirms upgrades are run-only and no persistent build migration is
  required. Preserve the generic `upgrade/element_thermal` artwork asset.
- Retire the unused, contract-incompatible
  `scripts/presentation/vehicle_field_surface_pattern_compiler.gd` when the dedicated surface-
  detail compiler becomes the sole floor-detail owner; do not keep competing dormant owners.

Exact actions requiring owner or user approval:

- This contract authorizes no implementation by itself. Begin execution only after the user
  approves the plan or explicitly asks to implement it.
- The surface-asset approval gate is satisfied by the user's 2026-08-09 instruction to use the
  reviewed SVG family. Promote only `surface_crack_01.svg`, `surface_stain_01.svg`, and the revised
  `surface_chip_01.svg` at the hashes recorded below. Beam promotion still requires an exact
  AS-IS/TO-BE comparison with the authority sheet, 1x source, provenance, intended asset ID,
  footprint, and in-game state capture.
- The HUD, modal, minimap, status, and boss-shield mockups document expected hierarchy only. The
  user's 2026-08-09 decision locks the live top-center HUD to hull and XP meters with zero upgrade
  icons; no generated HUD image overrides that decision. Exact runtime review remains required.
  Any new Thermal impact PNG requires a dedicated workbench unit,
  actual canonical-sheet input, transparent-source inspection, exact hash, 1x in-game comparison,
  and explicit user approval before manifest promotion.
- Before the first broad native/Web qualification batch, state its purpose, clean-commit scope,
  expected duration, system impact, and stop condition; run it only after the user aligns with
  that cost. Focused validators and a user-requested manual trace are not this broad batch.
- Deleting this plan after completion or deleting the older completed plan currently blocking the
  document-authority validator requires explicit user approval at that time.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| “Neutral attack zone” identity | No such symbol exists. Four `hazard_zone` footprints are generated by `VehicleFieldLayoutGenerator`; `VehicleTerrainRuntime` applies neutral immediate, 0.75-second tick, and 2.5-second lingering damage. They hurt ordinary enemies more than the player and their kills still advance quota/drop XP. Boss `denied_zones` are separate attack telegraphs. | `scripts/vehicle/vehicle_field_layout_generator.gd`; `scripts/vehicle/vehicle_terrain_runtime.gd`; `scripts/vehicle/vehicle_run.gd`; commit `580cde2c`; product spec | Treat the request as removal of map hazard zones. Remove the mechanic and all unused presentation/product surfaces; preserve boss attack zones. | 2.1-2.3 |
| Early ordinary health and later growth | Ordinary health is authored base x optional 1.12 class factor x `[1.00,1.04,1.08,1.12,1.16]` x `2.60`. Commit `8924a877` doubled the final multiplier from 1.30 on 2026-08-08. Boss health is separate. | `VehicleStageDifficulty`; `VehicleRun._make_enemy`; git history; product spec; user revision on 2026-08-08 | Use the user-selected additive curve `[0.85,1.00,1.15,1.30,1.45]`. It lowers Stage 1 by 15% and adds 0.15 of the authored/current-final baseline per stage. Boss health is excluded. | 3.1-3.2 |
| Combined late-run pressure | Quotas, authored population, active population, role mix, and boss pressure already rise by stage. Removing enemy-damaging hazards also increases effective enemy durability. | Product spec stage tables; encounter owners; hazard damage rules | Keep the selected health direction but do not also raise quotas, counts, damage, speed, or boss HP. Treat `[0.85,1.00,1.15,1.30,1.45]` as the complete curve for this pass and validate clear-time/TTK before any further increase. | 3.2, 10.2 |
| Ordinary movement role truth | The basic algorithm exists: chasers and contact roles approach; shooters hold 330-500, controllers 390-540, artillery 520-760, escorts 300-470, and support roles 430-620. Stationary roles do not move. | `VehicleRun._desired_enemy_velocity`; `VehicleEnemyArchetypes`; `VehicleEnemyUpdateSchedule` | Preserve these bands and role identities. Centralize them in `VehicleEnemyMovementPolicy` so callers request pursuit/standoff/escort/support intent without owning threshold tables. | 3.3-3.6 |
| Unnatural movement causes | Distance bands switch instantly between full retreat, full perpendicular strafe, and full approach. Above distance 520 the pursuit field currently receives 86% weight even with line of sight, masking artillery/support standoff. Desired direction changes at 10 Hz; overlap steering reacts only after body penetration; fixed side recovery can add abrupt turns. | `VehicleRun._desired_enemy_velocity`; `_move_enemy_with_recovery`; `VehicleEnemyLocalSteering`; scheduler and steering validators | Replace hard direction switches with continuous radial/tangential weights and role turn response. Use pursuit-field guidance only for an approaching role whose direct route is blocked. Preserve packed overlap behavior and cadence; do not add boids or presentation lag. | 3.3-3.6 |
| Shielded boss durability | `VehicleBossShieldRuntime` owns `0.25` shielded, `1.0` exposed, and a four-second down window. | `scripts/bosses/vehicle_boss_shield_runtime.gd`; boss/run validators; commit `b7b9df11` | Set shielded to `0.15`. This is a 40% reduction from current shielded throughput while retaining meaningful chip damage; `0.10` is rejected for this pass because it approaches immunity during downtime. | 3.1-3.2 |
| Thermal meaning and ownership | `thermal_burn` is a persistent three-stack condition held in `VehicleStatusProfile/Runtime`; affinity is inferred from a burn condition bit. All split primary projectiles receive the profile. Seekers do not. | card resource, `VehicleRun._fire_primary`, `VehicleAttackContract`, `VehicleStatusProfile`, `VehicleStatusRuntime` | Canonical term is `Thermal Burst`: an instant elemental payload, not a status. Replace the card ID and profile owner with `VehicleElementProfile`; keep `VehicleStatusRuntime` only for Toxin/Chill. Give attack affinity an explicit element source instead of pretending thermal is a condition. | 4.1-4.4 |
| Thermal Burst hit contract | Existing `_damage_enemies_in_radius` uses the spatial grid but also damages devices/facilities. Seeker burst already excludes its direct target. | `VehicleRun._update_projectile_buffer`; `VehicleRun._damage_enemies_in_radius` | Trigger once for every direct enemy hit by a non-reflected `player_primary` projectile, including split/piercing hits. Use spatial-grid query, radius `72/84/96`, flat damage `4/6/8`, exclude the direct target, damage targetable enemies including a nearby boss through normal shield rules, exclude structures/devices/facility, and never chain or apply Toxin/Chill. | 4.2-4.4 |
| Thermal presentation | The gameplay conversion landed with the generic orange Thermal artwork, affinity-colored primary projectile, impact sound, and generic target flash only. The visual contract and validators still assert no Thermal effect, but the user subsequently requested visible radius-scaled impact feedback. | Original-detail asset inspection; `VehicleElementProfile`; effect store/renderer; user revision on 2026-08-09 | Keep the completed damage contract. Add one separately approved short Thermal impact at the eligible direct-hit point, scale it to `72/84/96`, create no effect for splash recipients, and bound it inside the existing effect-store capacity. | 4.3-4.4, 9.1-9.2 |
| Surface flatness and detail boundary | Runtime still has `VehicleWorldMeshBuilder.DECORATION_BUDGET == 0`. On 2026-08-08 the user explicitly replaced the absolute visual ban with a conditional rule; on 2026-08-09 the user explicitly approved the reviewed deterministic SVG direction and requested implementation. | Full `VISUAL_SYSTEM.md`; original-detail authority sheet; user sketch; SVG asset sheet/distribution preview; world mesh builder | `VISUAL_SYSTEM.md` authorizes only the exact deterministic `SurfaceDetail` SVG workflow as a narrow exception, with at most 192 static instances and three retained batches. No other SVG authoring is permitted. | 5.1-6.4 |
| Surface rendering choice | The world builder already caches asset/z `MultiMeshInstance2D` batches. TileMap would add a new owner; procedural shader/noise violates visual rules; a full 7200x4320 RGBA surface would be roughly 124 MB before mip/import overhead. | Local renderer; Godot 4.7 `MultiMeshInstance2D`, `MultiMesh`, TileMapLayer, GPU optimization, CanvasItem, and RNG docs | Retain the current batch path. Add 72 crack, 72 stain, and 48 embedded-chip instances maximum (192 total), one batch per asset, fixed low z, compact transparent quads, discrete 90-degree rotation and `0.75/1.0/1.25` scale variants, and no runtime updates. | 5.1-6.4 |
| Approved SurfaceDetail sources | The grounded ImageGen sheet remains concept evidence. The later deterministic SVG experiment was reviewed twice, including a flatter embedded-chip revision, and the user instructed the project to use it. | `tools/design/generate_surface_detail_svg_experiment.ps1`; candidate asset sheet/distribution preview; authority preflight; user approval on 2026-08-09 | Promote exact `_01` sources only: crack SHA-256 `87828561653B35672DC09608848FBFDA0BEFDA687CB53B93F502A4444005A2DE`, stain `955BDB5BB132775B1D331FCA86F90C01BC1F5A1B281206E3A491199F69DAD347`, chip `B5C7C0867A8C8F7B51F666875C81F8281DB44479D41FFF02601CB6CF652AB593`. Keep `_02` review-only. | 6.1-6.4 |
| Straight boss beam awkwardness | Current 128x32 `cue/beam_strip_9` is a white rectangle with a dark perimeter. Renderer startup stretches it twice and active stretches it three times, producing nested framed bars instead of energy planes. The same owner serves Beam Sentinel and boss beams. | Original-detail asset inspection; workbench unit `gameplay_code_asset_rasterization`; `VehicleCombatRenderer._sync_beam_startup/_sync_active_beam` | Preserve the exact straight collision corridor and shared semantic ID, but replace the raster with a borderless tintable alpha mask. Startup is two flat planes; active is three. No glow, gradient, endpoint cap, frame, particle, or extra batch. | 6.5-6.7 |
| Boss beam concept evidence | The first ImageGen concept was rejected because it introduced panel repetition and soft glow. A corrected second concept shows the intended startup/active hierarchy on a plain floor, but remains preview-only and is not the final 128x32 strip. | Canonical sheet, current Crown boss, and current beam strip supplied through `image_gen.referenced_image_paths` | Carry forward the corrected flat-plane hierarchy. Generate and approve an exact canvas/pivot/import-compatible strip before runtime replacement. | 6.5-6.7 |
| Comparable-game evidence | Official Into the Breach material supports deterministic, immediately readable combat; public primary sources for Into the Breach, Wasteland Kings, and Spelunky do not disclose exact floor-decal batching. | GDC postmortem and official game pages; Godot official docs | Do not claim an unverified clone technique. Use comparable games only for sparse/readable/deterministic principles; choose the renderer from Cardborne architecture and official Godot guidance. | 5.1, 6.4 |
| Reported hitch | Current HEAD has no eligible performance JSON. The last eligible older sample showed frame p95 143 ms with physics catch-up and simulation/HUD cost while render CPU/GPU were low. Later allocator prewarm improved a diagnostic but was never release-qualified. On 2026-08-08, 16 unrelated Godot processes prevented a clean run. | Active performance plan; runtime architecture audit; historical JSON | Make no current root-cause claim. First qualify clean current HEAD, then repeat after all feature work. Optimize only the subsystem selected by a valid trace/sample; never blame new PNGs by intuition. | 1.1-1.4, 10.3-10.4 |
| Performance fixture mismatch | Renderer capacity and visual contract are 28 health overlays, but the performance scenario and its validator still require 50. Release batch threshold remains at most 50. | combat renderer, visual system, renderer validator, performance scenario and validator | Change only the scenario fixture expectation from 50 to 28; retain the release threshold `batches <= 50`. A failing focused validator blocks all expensive samples. | 1.1 |
| Top-center progression feedback and redundant build icons | `VehicleExperienceRuntime` still advances levels with the capped formula `min(160, 12 + round(3n + 0.55n^2))`. `VehicleGameplayHud.HealthPips` stores XP fields, but `_fill_fast_hud_snapshot` omits them and `debug_contract()` asserts `has_experience_geometry=false`. The HUD instead instantiates the only consumer of `VehicleAcquiredUpgradeRail`, which renders up to 18 image-and-level cells whose shared category artwork cannot identify individual mechanics. Paused Settings already opens Ship Status first; `VehicleBuildSummaryPanel._refresh_upgrades()` renders every acquired upgrade by localized title and `level / max` from the frozen gameplay-owned build snapshot. | `scripts/progression/vehicle_experience_runtime.gd`; `scripts/vehicle/vehicle_run.gd`; `scripts/ui/vehicle_gameplay_hud.gd`; `scripts/ui/vehicle_acquired_upgrade_rail.gd`; `scripts/ui/vehicle_settings_panel.gd`; `scripts/ui/vehicle_build_summary_panel.gd`; product/visual specs; user decisions on 2026-08-09 | Remove the live acquired-upgrade rail and its now-ownerless component/validator. Keep Settings > Ship Status as the detailed named build surface and retain its event-driven snapshot path. Top center contains only equal-width hull and XP tracks: a 13-pixel amber hull meter and a thinner `6/8/8`-pixel system-blue XP meter with `Lv. N` and literal `EXP current / required` or `EXP MAX`. Publish only scalar level/current/required/MAX fields through the fast HUD snapshot; do not send or rebuild upgrade imagery at HUD cadence. | 7.1-7.2 |
| Stage 4 level-up symptom | XP collection and stage gains have no Stage 4 cap. The failure is the reward gate: `_open_upgrade_reward()` requires exactly three cards and otherwise logs a warning, resolves the transaction, and `consume_pending_level()` removes the pending level. Catalog compatibility shrinks late in a run due to max levels, element exclusion, and optional-secondary limits. | `VehicleRun._open_upgrade_reward/_resolve_reward_transaction`; `VehicleUpgradeCatalog.offer`; experience/upgrade validators | Accept one to three legal cards and center only visible cards. Zero legal cards enters an explicit localized progression-complete `MAX` receipt, stops future XP drops/awards, and never uses a warning-only silent consume path. | 7.1, 7.4 |
| Element card truth | The presenter can distinguish `unlock` and `enhance`, but element resources have no stat modifiers, so their visible descriptions remain static and show no real level deltas. Runtime values live only in `VehicleElementProfile`: Thermal radius `72/84/96`, damage `4/6/8`; Toxin DPS/stack `2/3/4`, duration `5/6/7`; Cryo slow/stack `6/8/10%`, duration `2/2.5/3`, with boss Chill effectiveness halved. | `vehicle_upgrade_offer_presenter.gd`; element card resources; `vehicle_element_profile.gd`; `vehicle_status_runtime.gd` | Make one gameplay-owned level-value descriptor consumable by runtime and offer presenter. First acquisition shows behavior plus initial values; enhancements show exact current-to-next rows. Korean and English remain complete; UI does not copy value arrays. | 7.3-7.4 |
| Nearby direction cue | Commit `b9e66b86` narrowed threat radar to unseen committed projectile attacks and boss arrival. The retained mesh still has 12 sectors, a 1200-unit maximum, sector aggregation, and five-hertz publication. Ordinary off-screen location is minimap-only. | `VehicleRun._threat_radar_snapshot`; `VehicleThreatRadar`; `VehicleCombatCuePolicy`; git history | Add low-priority `nearby_enemy` contacts only for nearby enemies outside the viewport. Aggregate by existing sectors, vary width by density/proximity, draw no triangle, and let incoming attack and boss arrival win the sector. Visible enemies remain excluded and the minimap owns exact location. | 8.1-8.2 |
| Minimap role collapse | Snapshot creation emits pickups, crates, and intact Mystery Devices as `item`; mobile and fixed ordinary enemies as `enemy`; builder supports only item/enemy/boss/facility plus player. The large neutral Mystery Device can therefore disappear into pickup semantics. Boss differs mainly by size. | `VehicleRun._minimap_snapshot/_runtime_minimap_snapshot`; `VehicleMinimapMeshBuilder`; UI glyph catalog | Use eight bounded roles: player, field pickup, reward crate, Mystery Device, mobile enemy, fixed priority enemy, boss, and reinforcement facility. Distinguish shape as well as semantic color; keep Mystery Device outcome hidden; use one notched command-magenta boss marker instead of arbitrary per-stage colors. | 8.1, 8.3-8.4 |
| Electric Field area and shield collision | `VehicleSecondaryRuntime` damages every eligible enemy whose body overlaps radii `120/140/160` at a `0.25s` tick and passes line of sight. `VehicleCombatRenderer` duplicates those radii in `ELECTRIC_FIELD_RADII` and draws only a Mint `cue/ring` at alpha `0.48`. Player barrier and enemy shields use the same Mint ring family, so the damage field reads as protection and its interior is visually empty. | `data/weapons/vehicle/secondary/electric_field.tres`; `scripts/player/vehicle_secondary_runtime.gd`; `scripts/presentation/vehicle_combat_renderer.gd`; `30-boss-04-stage-4-active.png` | Make the secondary definition/snapshot the single radius source. Draw one low-alpha Arc-purple filled disk below actors at `120/140/160`, with one restrained broken perimeter and at most four broad internal planes. The disk represents the field volume; damage still begins when an enemy body overlaps it. Do not reuse Mint/support shield geometry or create a second collision owner. | 8.1, 9.4, 9.6 |
| Projectile affinity and persistent status feedback | Player-primary projectile tint already follows Thermal/Toxin/Cryo; Seeker and hostile bolt intentionally keep authored identities. Generic enemy hit feedback is a short common flash. Renderer input does not expose Toxin/Chill stacks or application time, so persistent status has no direct body feedback. | `VehicleCombatRenderer`; `VehicleAttackContract`; `VehicleStatusRuntime`; current renderer/status validators | Preserve primary-only affinity tint and Seeker identity. Publish bounded status stack ratios plus one application pulse receipt in the enemy presentation frame. Visually treat the actor's authored alpha as an exact same-size overlay mask: no enlarged silhouette, perimeter, halo, or external geometry. Generic damage flash wins briefly, then the Toxin/Cryo body overlay returns. Reduced motion removes the pulse change but preserves the static overlay. | 9.2-9.3, 9.6 |
| Boss visual identity | Five boss variants already resolve separate authored PNGs. The shared large opaque magenta shield boundary masks their silhouette and makes them read alike. The minimap boss marker is a larger plain hexagon. | actor visual catalog; combat renderer; current boss captures; `boss-shield-readability-to-be.png` | Preserve all boss PNGs. Reduce shield fill/thickness/opacity to one restrained body-attached boundary, then validate all five at 1x and grayscale. Change only the minimap marker to a notched command shape. Open per-boss art replacement only if authored bodies remain indistinct after the shield fix. | 8.3-8.4, 9.5-9.6 |
| TO-BE visual evidence | The latest production capture set is the Korean 87-image `beam-production-655e0ee2` set. It predates `b9a41aee` only by documentation/workbench and Thermal-copy changes. Five progression/readability edits and three later HUD-density alternatives used the relevant current capture and the canonical sheet as actual referenced images. The first over-scaled combined HUD/field generation was rejected and not copied into the repository. The later alternatives proved that persistent build icons still consume attention and remain ambiguous when artwork is shared. | `docs/design/visual-replacement-workbench/candidates/progression-feedback-combat-readability-v1/README.md`; `docs/design/visual-replacement-workbench/candidates/hud-progression-density-options-v1/README.md`; capture manifest; git diff `655e0ee2..b9a41aee`; user decision on 2026-08-09 | Keep all eight repository images as composition evidence only. The selected runtime contract is simpler than every icon-bearing alternative: zero top-center upgrade icons, hull plus XP only, and complete named build details in paused Ship Status. Runtime owners, exact copy, supported viewports, and task acceptance below remain binding; no generated pixels are production-approved. | 7.2-9.6 |

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership, safety, and validation
  decision is closed.
- Godot 4.7.1 is available through `./tools/godot.ps1`; no bootstrap or dependency change is
  required. Surface SVG generation uses the checked-in deterministic PowerShell generator and
  the exact approved hashes above; beam raster generation continues to use the installed ImageGen
  workflow and its separate approval gate.
- Remaining unknowns are implementation-local or measured performance evidence. They cannot
  change this contract without triggering the predetermined change-control rules.
- Visual authority evidence for this revision: the full current `VISUAL_SYSTEM.md` was read;
  the canonical sheet was inspected at original detail; expected and observed SHA-256 are both
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`;
  `actual_image_reference_used=true`; reference input method was
  `image_gen.referenced_image_paths`. All eight generated images remain preview-only. For the exact
  approved SurfaceDetail SVG exception, `actual_image_reference_used=false`, reference input
  method is `deterministic_surface_detail_svg_exception`, the generator and fixed seeds are
  checked in, and the three selected hashes are recorded above.

## Tasks

### Phase 1: Qualify the current performance baseline

Goal: remove the static scenario contradiction and finish the existing performance plan's clean
current-HEAD qualification before gameplay or visual workload changes obscure causality.

Preconditions:

- The user has approved implementation of this contract.
- Work from a clean scoped branch/commit and do not disturb unrelated Godot processes.

Source owners: `scripts/performance/vehicle_performance_scenario.gd`,
`tools/validation/validate_vehicle_performance_scenarios.gd`,
`.agents/execplans/2026-08-02-pre-asset-code-stabilization.md`

- [x] **1.1** Restore a truthful performance fixture contract.
  - Change: replace the stale required health-overlay capacity `50` with renderer capacity `28`
    in the scenario and its focused validator. Do not change the release batch threshold `50`.
  - Accept: `validate_vehicle_combat_renderer.gd`,
    `validate_vehicle_performance_scenarios.gd`, and `validate_vehicle_run.gd` pass.
  - Guard: if any other renderer/scenario capacity disagrees, stop and reconcile it with the
    canonical visual contract; do not lower workload or thresholds.
  - Evidence: scenario validity now requires `Overlay_health == 28` in both fixture and
    production-replay paths while the combat-batch threshold remains `50`;
    `validate_vehicle_combat_renderer.gd`, `validate_vehicle_performance_scenarios.gd`, and
    `validate_vehicle_run.gd` passed on 2026-08-09.
- [ ] **1.2** Record one user-controlled normal-play hitch trace.
  - Change: from the clean committed fixture state, run
    `./tools/run_manual_performance_trace.ps1`; reproduce normal play until the hitch occurs, exit
    normally, and retain the JSON unchanged.
  - Accept: the trace has matching commit/dirty metadata and identifies whether slow buckets
    correlate with physics catch-up, encounter/pursuit, grid/enemies, projectiles, effects,
    presentation/HUD, render CPU/GPU, pressure, or focus. Record the conclusion as diagnostic,
    never as a release pass.
  - Guard: do not start if the wrapper detects another Godot process or if the user cannot drive
    the trace; record the deferred precondition without substituting a synthetic play claim.
  - Deferred precondition: on 2026-08-09 the wrapper started from clean commit `6323d09d` with no
    competing Godot process, but no gameplay session was entered during the 22-minute window.
    Normal window close therefore wrote no JSON, as designed. Keep this task open and retry from
    the exact clean final commit when the user can drive the game; synthetic scenarios are not a
    substitute for the requested normal-play correlation trace.
- [ ] **1.3** Complete clean native qualification owned by the active performance plan.
  - Change: after the required user cost alignment, run the exact clean-commit `peak_horde` and
    `capacity_pressure` commands in Phase 8/Test Plan of
    `.agents/execplans/2026-08-02-pre-asset-code-stabilization.md` with GL Compatibility,
    1280x720, quoted position `'40,40'`, VSync disabled, ten-second warmup, and 60-second sample.
  - Accept: both files match commit/workload/window/focus/renderer metadata and pass: frame
    p95/p99 `<=18/25 ms`, median `>=59 FPS`, 1% low `>=55 FPS`, no more than one consecutive
    frame over 33.3 ms, capacity physics p95/p99 `<=6/8 ms`, draw p95 `<=200`, batches `<=50`.
  - Guard: any overlap, focus loss, dirty commit, workload mismatch, or invalid authority field
    rejects the sample without tuning the workload.
  - Current evidence: clean commit `cc9167a2` produced authoritative, focused, workload-valid
    `peak_horde` and `capacity_pressure` results at 1280x720 with GL Compatibility. Both are valid
    failures. Peak frame p95/p99 is `143.677/147.068 ms`, median is `7.5 FPS`, 1% low is
    `6.746 FPS`, and physics p95/p99 is `29.463/36.566 ms`. Capacity frame p95/p99 is
    `144.588/149.093 ms`, median is `7.5 FPS`, 1% low is `6.690 FPS`, and physics p95/p99 is
    `39.015/49.223 ms`. Both keep 38 batches and draw p95 below 100. The first peak attempt lost
    focus and is retained separately as `invalid-cc9167a2-peak_horde-60s-focus-loss.json`.
  - Recovery requirement: follow the valid-failure contingency in the prerequisite performance
    plan. Preserve counts, cadence, renderer, and thresholds; make only a semantics-preserving
    correction inside the measured `enemy_scheduled_ordinary` / `enemies_and_grid` owner, rerun
    its focused checks, commit it, and requalify both native scenarios before Phase 2.
  - Recovery evidence: a diagnostic owner split attributed about `8.0 ms` of the saturated
    ordinary-enemy step to roughly 3,823 overlap candidates per cache build. Keeping the existing
    array buckets while restricting them to the exact possible-overlap cell rectangle and inlining
    the candidate/top-eight loop reduced the same headless 320-enemy moving-path mean from
    `12.078 ms` to `5.601 ms`. Spatial-grid, local-steering, update-schedule, Run, and performance-
    scenario validators pass without changing counts, cadence, collision predicates, ordering,
    workload, or thresholds. This diagnostic is direction evidence only; native qualification is
    still required.
  - Post-recovery evidence: clean commit `c9b1b10e` remained authoritative, focused, and workload-
    valid but still failed the unchanged release gates. Peak physics p95/p99 improved from
    `29.463/36.566 ms` to `18.084/21.903 ms`; capacity improved from `39.015/49.223 ms` to
    `20.015/23.399 ms`. Peak median improved from `7.5` to `23.077 FPS`; capacity remained at
    `7.5 FPS`. Rendering stayed below 100 draw calls p95 and at 38 batches. A diagnostic split
    then measured capacity `ordinary_due` p95 `7.83 ms`, overlap-cache p95 `2.15 ms`, combat/effects
    p95 `4.21 ms`, and player/rewards p95 `3.56 ms`; no single remaining owner supports another
    speculative micro-fix. Keep Tasks 1.3 and 1.4 open and requalify after the already-authorized
    workload changes; do not lower the gates.
- [ ] **1.4** Qualify the built Web target and close the prerequisite plan.
  - Change: only after both native samples pass, export Web from the same clean commit, load
    `$npjt-port-guard`, use the `codex` lane, collect the exact built-Web `peak_horde` result with
    visible Chrome, stop only the task-owned server, and complete/archive the prerequisite plan.
  - Accept: the Web file is commit-proven and threshold-passing; the prerequisite plan is moved
    to its completed location with its evidence links intact.

Batch gate:

- No Phase 2 edit begins until Phase 1 has an eligible clean baseline or the user explicitly
  chooses to defer the baseline after being told that later comparisons will lose causal value.
- Gate evidence: the authoritative clean `cc9167a2` before-state and `c9b1b10e` owner-correction
  results provide the eligible causal baseline. They are valid red evidence, not a release pass;
  the performance plan remains active while the separately user-approved hazard/workload removal
  proceeds.

### Phase 2: Remove neutral map hazards completely

Goal: remove the mechanic that passively kills enemies and grants quota/XP while preserving all
boss-owned attack telegraphs and transit behavior.

Preconditions:

- Phase 1 batch gate passes.

Source owners: `scripts/vehicle/vehicle_field_layout_generator.gd`,
`scripts/vehicle/vehicle_terrain_runtime.gd`, `scripts/vehicle/vehicle_run.gd`,
`scripts/vehicle/vehicle_field_geometry_snapshot.gd`,
`scripts/presentation/vehicle_world_mesh_builder.gd`,
`scripts/presentation/components/vehicle_world_visual_catalog.gd`, guidebook/localization,
production asset manifest, product/visual specs, and focused validators

- [x] **2.1** Remove hazard generation and combat behavior.
  - Change: remove four hazard footprints, exposure state/timers, player/ordinary/boss hazard
    damage, neutral hazard kill attribution, and hazard geometry snapshots. Keep terrain runtime
    transit-gate ownership and keep `VehicleRun.denied_zones` unchanged.
  - Accept: generated layouts contain zero hazards; no actor can receive hazard damage or retain
    exposure; transit gates and boss attack zones still work.
- [x] **2.2** Retire every now-unused hazard surface.
  - Change: remove hazard visual descriptors/batches, guidebook entry, Korean/English strings,
    product/visual spec clauses, manifest IDs `world/hazard_toxic_bog` and
    `world/hazard_lava_pool`, and their tracked PNGs. Replace or delete hazard-only validators;
    keep mixed validators and rewrite their exact expectations.
  - Accept: repository search finds no live `hazard_zone`, hazard asset ID, exposure, or guidebook
    contract; no asset is orphaned; visual authority validation passes.
- [x] **2.3** Commit the hazard removal as one causal change.
  - Change: stage and commit only Phase 2 files.
  - Accept: field-layout, terrain, map-mechanics, stage-layout, world-visual, guidebook,
    localization, asset-manifest, and Run validators pass; `git diff --check` passes.

### Phase 3: Rebalance ordinary health, boss shielding, and role movement

Goal: make the opening less spongy, make stage growth explicit, make mobile enemies obey their
combat distance naturally, and make the boss attack window matter without changing boss HP or
turning shielding into immunity.

Preconditions:

- Phase 2 acceptance passes.

Source owners: `scripts/enemies/vehicle_stage_difficulty.gd`,
`scripts/enemies/vehicle_enemy_movement_policy.gd`, `scripts/vehicle/vehicle_run.gd`,
`scripts/bosses/vehicle_boss_shield_runtime.gd`, product spec, and focused
difficulty/boss/movement/Run validators, including
`tools/validation/validate_vehicle_enemy_movement_policy.gd`

- [x] **3.1** Apply the locked numeric contracts at their existing owners.
  - Change: set ordinary health curve to `[0.85,1.00,1.15,1.30,1.45]` and shielded boss damage
    multiplier to `0.15`. Do not change `ORDINARY_HEALTH_MULTIPLIER`, boss HP, exposed multiplier,
    shield-down duration, damage/speed curves, or `final_effective` handling.
  - Accept: Stage 1 ordinary health is exactly 85% of the current formula; successive stages add
    exactly 0.15 of the authored/current-final baseline; 100 ordinary incoming damage applies 15
    while shielded and 100 while exposed.
- [x] **3.2** Update balance truth and regression examples.
  - Change: update the product spec and exact validator mirrors; add examples for a class-factor
    enemy and a no-class-factor enemy across stages; assert boss health is unchanged.
  - Accept: difficulty, boss-exam, boss-pattern, and Run validators pass and no stale 0.25 or old
    health-curve assertion remains outside retained history/evidence.
- [x] **3.3** Centralize role movement intent without changing combat timing.
  - Change: add `scripts/enemies/vehicle_enemy_movement_policy.gd` as the pure owner of movement
    family, existing distance bands, radial/tangential weights, route-guidance eligibility, and
    role turn response. Keep attack ranges/timing in current combat owners and keep archetype
    speed/health in `VehicleEnemyArchetypes`.
  - Accept: every mobile archetype resolves exactly one family: pursuit (`scrap_drone`, `chaser`,
    `rammer`, `bulkhead_guard`, `splitter_barge`, mobile `spark_minelet`), standoff (`needle_drone`,
    `shooter`, `controller`, `artillery_spotter`), escort (`shield_escort`), or support
    (`repair_tender`, `drone_carrier`). Fixed installations resolve stationary.
- [x] **3.4** Replace abrupt range switching with continuous steering.
  - Change: for each standoff/escort/support band, compute a signed normalized distance error around
    its midpoint. Blend radial approach/retreat continuously with the existing signed tangential
    strafe; radial weight reaches full outside the band and tangential weight peaks at the midpoint.
    Smooth ordinary move/recovery velocity toward the new intent with response `9/s` for pursuit,
    `6/s` for standoff, and `5/s` for escort/support. Charges, startup locks, active attacks,
    stun, forced Mystery Device motion, and fixed installations bypass this smoothing.
  - Accept: crossing a band edge does not flip velocity by 90/180 degrees in one decision; pursuit
    roles continue closing until their attack contract; ranged/support roles converge on and orbit
    within their existing bands; role speed remains capped.
- [x] **3.5** Stop route guidance from defeating standoff behavior.
  - Change: apply `PursuitField.direction_at` only while the policy requests approach and direct
    line of sight/navigation is blocked. Never blend a player-directed pursuit vector while a role
    is holding, strafing, or retreating inside its band. Keep overlap separation and collision
    recovery bounded and allocation-free.
  - Accept: a shooter at 415, controller at 465, artillery at 640, escort at 385, and support at
    525 world units with line of sight choose tangential/center-correcting motion rather than the
    pursuit field; blocked far attackers still route around walls; close ranged roles retreat.
- [x] **3.6** Add deterministic movement oracles and rendered feel checks.
  - Change: add `tools/validation/validate_vehicle_enemy_movement_policy.gd` with focused policy
    tests for every family, band midpoint/edge/outside cases, recovery, blocked route, role speed
    cap, deterministic strafe sign, and the unchanged scheduler/overlap ceilings. Add a bounded
    capture/harness with one pursuit and one ranged enemy following a moving player around cover.
  - Accept: movement-policy, local-steering, pursuit-field, update-schedule, attack-contract, and
    Run validators pass; rendered motion shows no band-edge ping-pong or ranged collapse into melee.
  - Guard: do not raise decision/motion cadence or add a full neighbor scan to make the capture
    look smoother.
  - Evidence: the policy validator covers every family at midpoint, edge, outside-band, and
    recovery cases while retaining 10 Hz decisions, 30/20 Hz motion, and the eight-neighbor cap.
    The real scheduler/steering capture under
    `build/visual-captures/phase3-movement-feel-ko-v9` shows a chaser travel `601.66` units and
    close to `26.94`, while a shooter travels `306.68` units and stays within `324.26-546.26`.
    Movement-policy, local-steering, navigation/pursuit, update-schedule, attack-contract,
    capture-driver, and Run validators exit zero.

### Phase 4: Replace Thermal Burn with Thermal Burst

Goal: make the thermal element an immediate on-hit crowd tool with clear ownership, bounded work,
and no persistent burn semantics.

Preconditions:

- Phase 3 acceptance passes.

Source owners: card resource/catalog/build, `scripts/combat/vehicle_element_profile.gd`,
`scripts/combat/vehicle_status_runtime.gd`, `scripts/combat/vehicle_attack_contract.gd`,
`scripts/combat/vehicle_projectile_state.gd`, `scripts/vehicle/vehicle_run.gd`, damage source,
telemetry/report owners, localization, product/catalog docs, and focused validators

- [x] **4.1** Align the elemental domain language.
  - Change: replace `thermal_burn` with `thermal_burst` in the run-only card/build/catalog
    contract; replace `VehicleStatusProfile` with immutable `VehicleElementProfile`; make thermal
    affinity explicit while condition masks contain only persistent Toxin and Chill. Keep
    `VehicleStatusRuntime` as the owner of those two statuses.
  - Accept: no live burn DPS, duration, stack, condition bit, report source, localization, or test
    remains; Toxin/Chill behavior and mutual exclusion are unchanged; generic thermal artwork is
    still the card art.
- [x] **4.2** Apply bounded enemy-only burst damage on primary hits.
  - Change: put level values `radius=[72,84,96]`, `damage=[4,6,8]` in the element profile. On each
    eligible direct hit, use the existing spatial grid to damage targetable nearby enemies once,
    excluding the direct target and all structures/devices/facility. Do not scan the full enemy
    array, recurse, chain, or allocate a per-hit node/list.
  - Accept: normal, split, and piercing primary hits follow the contract; Seekers, EMP, status
    ticks, reflected shots, splash hits, and structure-only hits do not trigger a burst; a nearby
    boss receives its normal shield multiplier.
- [x] **4.3** Preserve readable thermal feedback without expanding the visual workload.
  - Change: keep thermal projectile affinity/color, reuse current impact audio, and use existing
    per-target hit feedback for every damaged target. Add no effect-store kind or geometry.
  - Accept: combat renderer and attack-contract captures show thermal primary projectiles and
    distinct affected-target feedback without a persistent radius or extra live effects.
  - Revision note: this is the completed damage-conversion checkpoint. The user's later request for
    explicit hit feedback is a separate bounded visual extension in Phase 9 and does not reopen the
    already validated damage contract.
- [x] **4.4** Update product copy, reporting, and focused validation.
  - Change: title the card `열폭발` / `Thermal Burst`; describe primary-hit area damage in both
    languages; attribute splash as `thermal_burst`/thermal player damage; update catalog count and
    state assertions only if the rename actually changes them.
  - Accept: build/card/UI/localization, element/status stacking, attack contract, telemetry,
    report, renderer, capture-driver, and Run validators pass. Direct and splash damage are not
    double-counted and lifesteal sees only actual player-owned damage.

Batch gate:

- Run one deterministic Stage 1 dense-group capture and one shield-up boss-adjacency harness.
  Confirm direct-target exclusion, bounded target count, normal shield application, no structure
  splash, and no status-tick or chain trigger before moving to visual contract work.

### Phase 5: Authorize a narrow SurfaceDetail visual category

Goal: amend the visual contract before promoting or integrating any floor-detail image.

Preconditions:

- The text-contract task may complete during planning because the user explicitly authorized it;
  runtime-owner and validation tasks still wait for the Phase 4 batch gate.
- Reverify the authority-pair hash and inspect the sheet at original detail.

Source owners: `docs/design/VISUAL_SYSTEM.md`, production asset manifest/workbench inventory,
`.agents/execplans/2026-08-08-combat-pressure-and-surface-depth.md`

- [x] **5.1** Define the exception without weakening combat readability.
  - Change: keep flat `#9EADBC` as the dominant surface and add `SurfaceDetail` as a semantic,
    presentation-only exception. Permit only the exact deterministic crack, stain/wear, and
    embedded debris-chip SVG workflow;
    ban grids, seams, repeated panels, rivets, nested rings, lamps, random micro-noise, photoreal
    grime, raised-looking loose stones, and topology cues.
  - Accept: the contract states size/density/contrast/z/batch/placement limits, names runtime and
    approval owners, and keeps every gameplay signal above detail priority.
  - Evidence: the user-authorized 2026-08-08 `VISUAL_SYSTEM.md` revision permits at most 192
    sparse low-contrast instances across three retained batches; the 2026-08-09 approval narrows
    SVG authoring to the checked-in SurfaceDetail generator and exact selected hashes while
    continuing to ban dense noise, obvious tile repetition, collision cues, and gameplay
    interference.
- [x] **5.2** Replace the dormant competing floor-pattern owner.
  - Change: retire `vehicle_field_surface_pattern_compiler.gd` and register a dedicated
    `vehicle_surface_detail_compiler.gd` responsibility in the active plan/visual contract. The
    new compiler owns placement only; the exact approved SVGs own visible geometry and tactical
    layout owns gameplay geometry.
  - Accept: only one runtime owner can create ambient floor detail and no prohibited panel-pattern
    path remains reachable or registered.
- [x] **5.3** Validate the visual authority workflow change.
  - Change: update manifest/workbench expectations for removal of two hazards and later addition
    of three surface SVGs. Preserve `actual_image_reference_used=true` for the earlier ImageGen
    concept; for the selected SVGs record `actual_image_reference_used=false` and
    `reference_input_method=deterministic_surface_detail_svg_exception`, plus generator path,
    fixed seeds, exact hashes, and user approval. Keep `_02` variants outside production.
  - Accept: `validate_cardborne_visual_authority.ps1` and document-authority validation pass.
  - Evidence: the visual-authority validator passes. On 2026-08-09 BK approved deletion of the
    completed retired plan; it was removed after its current decisions were confirmed in this
    active contract and the durable product/visual owners. Document-authority validation passes.

### Phase 6: Promote and integrate sparse surface SVGs and the beam raster

Goal: add modest physical depth to the floor and replace the framed straight-beam bar while
keeping both surfaces deterministic, readable, and cheap.

Preconditions:

- Phase 5 passes.
- The surface SVG authority gate and exact-source approval are complete. The canonical sheet is
  supplied to ImageGen as an actual referenced image for the separate beam-raster task.

Source owners: three production SurfaceDetail SVG assets, production manifest/workbench evidence,
`scripts/presentation/vehicle_surface_detail_compiler.gd`,
`scripts/presentation/vehicle_world_mesh_builder.gd`, world visual catalog, and visual validators

- [x] **6.1** Generate grounded candidates to the locked brief.
  - Change: generate transparent deterministic SVG candidates for `world/surface_detail_crack`
    (96x96), `world/surface_detail_stain` (128x96), and
    `world/surface_detail_embedded_chip` (64x64), with neutral low-contrast colors, compact alpha
    bounds, no cast shadow/height cue, and no game-signal colors.
  - Accept: the checked-in generator reproduces identical hashes; each family is inspected at
    original detail and intended 1x footprint.
  - Evidence: commits `57f753be` and `db4adfb8`; deterministic regeneration and XML/canvas checks
    passed; the exact selected hashes are recorded in Discovery Closure.
- [x] **6.2** Obtain exact candidate approval before promotion.
  - Change: present the six-source asset sheet and sparse runtime-scale distribution; revise only
    the embedded-chip family after feedback.
  - Accept: the user explicitly approves the reviewed direction and requests these assets be used.
  - Evidence: user approval on 2026-08-09. `_01` is selected for each production identity; `_02`
    remains a review alternative to preserve the three-batch contract.
- [x] **6.3** Compile deterministic presentation-only placement.
  - Change: generate at most 72 crack, 72 stain, and 48 chip transforms from run-fixed field
    geometry plus a fixed salt. Use fixed low z, 90-degree rotations, scales
    `0.75/1.0/1.25`, minimum 140-pixel center separation, and rejection against void, walls,
    structural walls, the player-start 220-pixel clearance, and field-edge 96-pixel clearance.
    Placement must be identical across all five stages for the same field.
  - Accept: fingerprints are deterministic across rebuilds/stages; all centers are walkable and
    clear; no detail enters collision/topology data; no per-frame RNG or update occurs.
- [ ] **6.4** Integrate through retained batches and promote only approved SVGs.
  - Change: add one compact-quad `MultiMeshInstance2D` batch per selected `_01` SVG through the
    existing world builder; change `DECORATION_BUDGET` from zero to 192; retire the two hazard
    PNGs and add the three approved SVG details, producing 70 total manifest images (67 PNG and
    three SVG) if the starting exact count is still 69.
  - Accept: world batches remain `<=12`; detail instances remain `<=192`; no node-per-detail,
    shader noise, full-field texture, TileMap, collision, or runtime transform update exists.
    Native and Web captures at actual size, grayscale, and combat pressure show no lost actor,
    projectile, pickup, telegraph, boundary, or objective readability.
  - Guard: if the pre-edit manifest count is not 69, calculate and assert `starting - 2 + 3`
    rather than forcing 70. If three batches exceed 12, Godot SVG import is not stable, or
    eligible rendering evidence regresses,
    stop this branch for contract revision; do not silently add chunking or reduce thresholds.
  - Progress: asset promotion, exact hashes, 70-image manifest, stable SVG import, retained
    72/72/48 batches, and the focused code/authority gates pass. The 87-image native actual-size
    and combat-pressure capture passes; Web and explicit grayscale review remain in the Phase 10
    built-product QA pass.
- [x] **6.5** Open a dedicated per-asset beam replacement unit.
  - Change: create a workbench unit for `cue/beam_strip_9` instead of reopening the old eight-asset
    rasterization batch. Preserve semantic ID, `128x32` canvas, `[64,16]` pivot, import settings,
    retained batch, exact gameplay length/width, and all non-beam assets.
  - Accept: the unit contains current AS-IS hash
    `f30a3e2027de9e3580973d1e54051617e7b5f87e58571d768f6ad558b2924e48`, current runtime
    captures, user feedback, authority evidence, and one exact TO-BE brief.
- [x] **6.6** Generate and obtain approval for the borderless beam mask.
  - Change: with the canonical sheet supplied as an actual image reference, generate an exact
    128x32 transparent tintable flat strip with clean antialiased top/bottom alpha edges and no
    dark perimeter, embedded core, gradient, glow, cap, particle, or detached mark. Present the
    source at original detail plus Beam Sentinel and boss startup/active AS-IS/TO-BE captures.
  - Accept: the user explicitly approves the exact strip and four runtime states. Rejected outputs
    remain outside production and are never described as compliant.
  - Progress: built-in ImageGen received the authority sheet, current strip, and Crown boss as
    actual referenced images. Candidate
    `527607b4f68c950a4781b4a6dc521d086d66d752851b34320ca799be0edf23fe` is exact `128x32`
    RGBA with a centered `128x20` borderless plane. The canonical 87-image native capture passes
    and includes dedicated Beam Sentinel and Crown-beam startup/active AS-IS/TO-BE evidence. On
    2026-08-09 the user referenced this exact candidate and authorized continuation with the
    runtime-colored result; the workbench technical ledger pins the target path and exact hash.
- [x] **6.7** Retune the existing beam planes without adding a batch.
  - Change: startup uses full-width body alpha `0.16 -> 0.34` over readiness plus an ivory filament
    `min(3.5, width*0.065)` at alpha `0.32 -> 0.66`. Active uses full-width body alpha `0.92`,
    inner plane `min(20, width*0.34)` at alpha `0.88`, and ivory core
    `min(7, width*0.10)` at alpha `1.0`. Preserve straight clipping and no endpoint cap.
  - Accept: startup reads non-damaging and active reads stronger; the full active width remains
    visible; Beam Sentinel and every boss beam use the same approved strip; combat/effect counts,
    overlay batch count, damage geometry, timing, and collision are unchanged.
  - Evidence: commit `655e0ee2` promotes the approved bytes at the pinned SHA-256. Import and
    combat-renderer, attack-readability, player-presentation, semantic-provider, workbench, and
    visual-authority checks pass. The production 87-image Korean 1280x720 capture shows Beam
    Sentinel and Crown startup as a restrained two-plane corridor and active as a borderless
    three-plane corridor, with unchanged damage geometry and no added batch or endpoint cap.

Batch gate:

- Production manifest, workbench, import, world-visual, field-layout, stage-layout,
  combat-renderer, attack-readability, capture, and visual-authority validators pass; approved
  surface and beam runtime captures match the promoted files.

### Phase 7: Restore truthful XP and upgrade progression

Goal: make every XP gain and level reward observable, and make element cards explain the exact
behavior the next level will change.

Preconditions:

- Phase 6 focused gates pass. The composition references remain unapproved evidence, not runtime
  assets.
- Preserve the current XP curve, shard capacity, card catalog, mutual element exclusion, mandatory
  reward choice, and one active reward transaction.

Source owners: `scripts/progression/vehicle_experience_runtime.gd`,
`scripts/rewards/vehicle_reward_runtime.gd`, `scripts/cards/vehicle_upgrade_catalog.gd`,
`scripts/cards/vehicle_run_build.gd`, `scripts/cards/vehicle_upgrade_offer_presenter.gd`, element
card resources, `scripts/combat/vehicle_element_profile.gd`, `scripts/vehicle/vehicle_run.gd`,
`scripts/ui/vehicle_gameplay_hud.gd`, the obsolete
`scripts/ui/vehicle_acquired_upgrade_rail.gd`, `scripts/ui/vehicle_stage_ui.gd`,
`scripts/ui/vehicle_settings_panel.gd`, `scripts/ui/vehicle_build_summary_panel.gd`, upgrade choice
panel/card owners, localization, product and visual specs, and focused XP/upgrade/HUD validators

- [x] **7.1** Remove the silent late-run reward loss and define progression completion.
  - Change: accept any non-empty legal offer of one to three unique cards; remove exact-size-three
    guards from open/apply paths while retaining the mandatory selection guard. When the compatible
    catalog is empty, publish one explicit localized progression-complete receipt, mark XP `MAX`,
    clear remaining queued level rewards and uncollected XP shards through
    `VehicleExperienceRuntime`, and make future shard spawn/XP award calls no-ops. Claim the active
    reward transaction only after that receipt is visible; do not use the warning-only path.
    The receipt is `모든 업그레이드 완료` / `All upgrades complete`; the compact XP value is
    language-neutral `MAX`.
  - Accept: one-, two-, and three-card offers open, center only visible cards, accept keyboard
    shortcuts only for visible cards, and apply exactly one legal card. A zero-card state displays
    `MAX` in Korean and English, leaves no pending transaction or level reward, produces no further
    XP shards, and never logs "resolved without a selection" during a valid run.
  - Guard: a zero-card result while `VehicleUpgradeCatalog` still reports a compatible definition
    is an invariant failure, not progression completion; keep the transaction open, report exact
    seed/build evidence, and stop that branch.
- [x] **7.2** Replace the live build-icon rail with a two-meter top-center HUD.
  - Change: first amend the product and visual specs so top center owns only hull and XP. Remove
    `VehicleAcquiredUpgradeRail` from `VehicleGameplayHud`, remove the HUD's `build_snapshot`
    consumer and responsive row-height branches, then delete the ownerless rail script and its
    dedicated validator. Keep `VehicleStageUi`'s event-driven `_latest_build_snapshot` cache and
    paused Settings > Ship Status path unchanged so localized upgrade names, levels, and effective
    values remain available outside live combat. Add `level`, `experience`,
    `experience_required`, and `experience_complete` scalars to the reusable fast HUD frame and
    draw them in the existing code-native `HealthPips` owner. Hull keeps the current full center
    widths `400/520/640` for compact/standard/large, a 13-pixel `player_reward` amber fill, trailing
    damage response, and centered current/max value. XP is centered directly below it and shares
    the hull widths `400/520/640`, while retaining heights `6/8/8` and restrained `system` blue
    fill; accessibility uses the same 404-pixel width for both tracks and an 8-pixel XP fill. Show
    `Lv. N` at left and literal
    `EXP current / required` at right, or `EXP MAX` when complete. Use the dark common track and a
    four-pixel inter-meter gap; keep the toast stack four pixels below the resulting fixed-height
    two-meter cluster. Do not add icons, panels, category summaries, dividers, or another build
    receipt to the live HUD.
  - Accept: collection updates within the existing fast-HUD cadence; no full build snapshot,
    catalog scan, texture lookup, icon node rebuild, or allocation occurs per update. Debug
    contracts report `has_experience_geometry=true`, `live_upgrade_icon_count=0`, and no acquired-
    rail owner or validator remains. Both meters fit at `960x540`, `1280x720`, `1920x1080`, and
    200% text without overlapping the stage stack, minimap, each other's values, toast, or world
    view. Grayscale still distinguishes them by thickness and labels; color review shows amber hull
    and blue XP without either reading as enemy damage, shield, or a single merged meter. Paused
    Ship Status still lists the full named build after one or more upgrades.
- [x] **7.3** Make element acquisition and enhancement copy use one value source.
  - Change: register two real stat modifiers per element card and make
    `VehicleElementProfile.from_build()` read the same build-owned values used by the offer
    presenter. Thermal rows are radius `72/84/96` and burst damage `4/6/8`; Toxin rows are DPS per
    stack `2/3/4` and duration `5/6/7s`; Cryo rows are slow per stack `6/8/10%` and duration
    `2/2.5/3s`. For element cards, preserve accessible `unlock` at level zero and `enhance` after
    acquisition even though visible numeric rows exist. First acquisition shows behavior plus
    initial values without a false zero-to-value delta; later offers show current-to-next values;
    level three is never offered. Visible row labels are `효과 범위 / Effect radius`,
    `폭발 피해 / Burst damage`, `중독 피해/중첩 / Toxin damage/stack`,
    `지속 시간 / Duration`, and `감속/중첩 / Slow/stack`. Separate every card section and effect
    row with vertical spacing and alignment only. An upgrade card may contain zero horizontal
    separators, dividers, rules, underlines, row boxes, or line-like background bars in every state.
  - Accept: runtime profile values, card rows, Korean/English labels, build snapshot, stage report,
    and validators all derive identical numbers. Boss Chill's existing half-effect rule is stated
    in accessible/detail copy without changing the displayed base player-owned value.
- [x] **7.4** Prove progression reachability and the revised modal at late-run state.
  - Change: extend deterministic progression tests through catalog exhaustion, including one- and
    two-card tail offers, multiple queued levels, zero-card MAX, shard suppression after MAX, and
    Stage 4 collection. Add Korean/English captures for first Thermal acquisition, Thermal level
    1-to-2 enhancement, a two-card tail offer, the hull-plus-XP HUD in Stage 4, paused Ship Status
    with the acquired build, and MAX.
  - Accept: experience, upgrade system, upgrade UI, HUD presenter/layout, localization, capture,
    stage transition, rewards/audio, build/report, and Run validators pass. No pending level can be
    consumed without an applied card or explicit progression-complete receipt.

Batch gate:

- Current Korean and English production captures show zero live upgrade icons, a thicker amber
  hull meter above a thinner equal-width blue XP meter, and the full named build in paused Ship Status. The
  upgrade modal matches the expected hierarchy in `element-upgrade-enhance-to-be.png`; exact text
  remains Control-owned and all supported viewport/text-scale checks pass. The icon-bearing HUD
  mockups are evidence of rejected density alternatives, not the selected runtime target.

### Phase 8: Restore nearby direction cues and semantic minimap roles

Goal: tell the player where immediate off-screen pressure comes from while keeping exact world
location and map-object identity legible in the minimap.

Preconditions:

- Phase 7 passes.
- Revise the product and visual contracts before changing HUD/minimap runtime behavior.

Source owners: `docs/product/vehicle_game_spec.md`, `docs/design/VISUAL_SYSTEM.md`,
`scripts/presentation/components/vehicle_combat_cue_policy.gd`,
`scripts/presentation/components/vehicle_ui_glyph_catalog.gd`,
`scripts/ui/vehicle_threat_radar.gd`, `scripts/ui/vehicle_minimap_mesh_builder.gd`,
`scripts/ui/vehicle_retained_minimap_mesh.gd`, `scripts/ui/vehicle_gameplay_hud.gd`,
`scripts/vehicle/vehicle_run.gd`, capture gateway/driver, and focused HUD/minimap validators

- [x] **8.1** Amend the remaining visual contract before runtime changes.
  - Change: retain the Phase 7 hull-plus-XP and zero-live-upgrade-icon contract while replacing the
    incoming-only radar, five-marker minimap, shared-ring Electric Field, three-effect-only, and
    text-only persistent-status clauses with the bounded contracts in Phases 8-9. Preserve sparse
    HUD, one minimap Surface, no full radar circle, no per-enemy status node/material, no decorative
    markers, zero internal upgrade-card horizontal separators, and exact visual-authority/approval
    requirements. If the three-card-only modal clause was not already updated by Task 7.1, update
    it here before the remaining Phase 8 runtime work.
  - Accept: product and visual specs describe the same reachable states, localization, ownership,
    reduced-motion behavior, capacities, and non-goals; visual-authority validation passes.
- [x] **8.2** Add low-priority nearby-enemy contacts to the retained threat radar.
  - Change: at the existing five-hertz publication boundary, sample only active targetable ordinary
    enemies whose body is outside the visible world rectangle and within `1200` world units. Emit
    `nearby_enemy` offsets into the existing fixed contact cache; aggregate into the existing 12
    sectors. Draw dim danger arcs with width driven by proximity/density and no triangle. Incoming
    committed attacks have priority 3, boss arrival priority 2, nearby enemy priority 1; the
    winning kind owns a sector's color/triangle while counts may still widen the arc.
  - Accept: visible enemies create no radar contact; off-screen density does not create more than
    12 drawn sectors; incoming projectile triangles and boss arrival remain brighter; exact enemy
    coordinates never appear on the radar; cadence, retained mesh count, and allocation behavior
    are unchanged.
- [x] **8.3** Split minimap semantics without leaking hidden outcomes.
  - Change: emit and draw exactly eight roles: player, `field_pickup`, `reward_crate`,
    `mystery_device`, `mobile_enemy`, `priority_enemy`, `boss`, and
    `reinforcement_facility`. Intact Mystery Device uses one neutral system-notched marker and
    never reveals its result; resolved/retired devices disappear. Fixed `turret`,
    `interceptor_tower`, `beam_sentinel`, and `generator` use the priority-enemy marker. Boss uses
    one command-magenta notched marker; do not assign arbitrary per-stage colors. Preserve explored
    geometry, fog, player facing, marker capacity, borrowed buffers, and one retained mesh.
  - Accept: role is distinguishable in grayscale by silhouette: pickup lozenge, crate notched
    square, device neutral cut marker, mobile enemy wedge/round mass, fixed enemy square/cut mass,
    notched boss command mass, and two-tone facility diamond. No subtype beyond the locked roles is
    emitted.
- [x] **8.4** Add density, accessibility, and capture oracles.
  - Change: add focused snapshots containing every marker role, overlapping nearby roles, a hidden
    Mystery Device outcome, a dense off-screen enemy sector, committed projectile contact, and boss
    arrival. Extend the production capture with one HUD/minimap/radar evidence state.
  - Accept: minimap builder, retained mesh, HUD layout/presenter, threat radar, combat cue policy,
    glyph catalog, localization, capture, visual registry, and Run validators pass. Actual-size,
    grayscale, and reduced-motion review preserves the selected hull-plus-XP top center with no
    upgrade icons while matching the radar/minimap hierarchy discussed in
    `gameplay-hud-minimap-to-be.png` without reproducing its generated pixels.

### Phase 9: Add bounded elemental feedback, distinguish Electric Field, and reveal boss identity

Goal: make selected-element hits and persistent statuses visible, show the complete Electric Field
damage area without shield ambiguity, and keep boss bodies readable without creating an effect storm.

Preconditions:

- Phase 8 passes.
- The visual contract amendment passes. A Thermal raster is not promoted until its dedicated
  workbench unit receives exact approval.

Source owners: `scripts/combat/vehicle_element_profile.gd`,
`scripts/combat/vehicle_status_runtime.gd`, enemy state/presentation snapshots,
`scripts/combat/vehicle_effect_store.gd`, effect/asset catalogs and manifest,
`data/weapons/vehicle/secondary/electric_field.tres`,
`scripts/player/vehicle_secondary_runtime.gd`,
`scripts/presentation/vehicle_combat_renderer.gd`, boss actor catalog, workbench evidence,
localization, capture fixtures, and focused secondary/status/effect/renderer validators

- [x] **9.1** Author and approve one Thermal impact identity.
  - Change: open a dedicated workbench unit for a transparent `192x192` Thermal Burst impact PNG
    centered at `[96,96]`. With the canonical sheet and current combat capture supplied as actual
    ImageGen references, generate one hard-edged 2-3-plane orange burst with a compact hot center,
    no text, ring, particle field, smoke, gradient, soft glow, endpoint mark, or frame sequence.
    Review source at original detail and runtime scales `0.75/0.875/1.0` for radii `72/84/96`.
  - Accept: the exact PNG, semantic ID, hash, alpha bounds, import settings, intended footprint,
    AS-IS/TO-BE comparison, and all three 1x scales receive explicit user approval before one
    manifest entry is added. Rejected candidates remain outside production.
  - Evidence: the workbench unit holds exact candidate SHA-256
    `4cb1b15b1118a093c52ad0f5f750e38af2af0640536659ffc4dc1e19c0474904`, RGBA bounds
    `173x176+9+8`, actual-reference provenance, AS-IS evidence, and `0.75/0.875/1.0` runtime-scale
    previews. BK approved the exact bytes on 2026-08-09; commit `c2c245af` records the approval,
    `b27ef661` promotes and integrates the same hash, and `68d07e84` records application evidence.
- [x] **9.2** Integrate Thermal impact without expanding capacity or splash noise.
  - Change: create one `thermal_burst_impact` effect at each eligible direct player-primary enemy
    hit, not at splash recipients. Give it `0.18s` scale/fade and the gameplay radius. Keep overall
    effect-store capacity `96`; permit at most 24 live Thermal impacts. When that sub-limit or the
    store is full, recycle the oldest Thermal impact only or drop the new cosmetic receipt; never
    evict EMP charge/release or change damage. Reuse one retained texture batch and create no node,
    timer object, full enemy scan, or per-target list.
  - Accept: normal, split, and piercing direct hits show one impact per eligible contact; Seeker,
    reflected, structure-only, splash, DOT, and EMP damage show none. Gameplay damage/radius and
    audio remain unchanged, effect capacity validates, and EMP is present under saturated Thermal
    input.
  - Evidence: the production manifest indexes the exact approved `192x192` PNG. The existing
    direct-contact call path emits one `0.18s` radius-scaled receipt; the fixed 96-state store caps
    Thermal at 24, recycles only its oldest Thermal state, and drops a new receipt rather than
    evicting EMP when no Thermal state is available. Effect-store, Thermal damage, renderer,
    provider, visual-coverage, and workbench validators pass.
- [x] **9.3** Compose Toxin and Cryo state into existing enemy batches.
  - Change: add bounded scalar presentation fields for Toxin/Cryo stack ratio and a `0.16s`
    application pulse receipt. Compose semantic Toxin/Cryo color through the existing actor
    instance at `0.12/0.16/0.20` for stacks 1/2/3; this must look exactly like a translucent layer
    clipped by the authored sprite alpha at the same transform, scale, and silhouette. The short
    application pulse may reach `0.32`. It changes only overlay alpha and never expands the actor.
    Generic direct-damage flash wins during its existing `0.11s`, then persistent overlay returns.
    Reduced motion omits the pulse boost and keeps only the static overlay. Do not add a second
    draw, status raster, outline, halo, enlarged silhouette, ring, icon, label, node, material, or
    repeated strobe.
  - Accept: stack gain, refresh, expiry, boss half-Chill, pooled enemy retirement/reuse, generic
    damage flash, stealth/visibility, and grayscale/affinity tests all show correct state with no
    stale tint. Pixel-mask comparison confirms every colored overlay pixel remains inside the
    unchanged actor alpha and footprint. Renderer consumes staged snapshot scalars and never reads
    live status dictionaries.
- [x] **9.4** Replace the shield-like Electric Field ring with its complete damage area.
  - Change: remove renderer-owned `ELECTRIC_FIELD_RADII` duplication and publish the selected
    secondary definition radius `120/140/160` in the borrowed presentation snapshot. Add one
    capacity-one retained code-native field-area batch below actors: Arc-purple fill alpha `0.10`,
    one broken perimeter at alpha `0.28`, and at most four broad internal planes at alpha `0.04`.
    All geometry stays within the exact radius and moves with the player. It has no collision,
    query, timer, damage, or target owner. Preserve the runtime's `0.25s` tick, LOS test, and enemy-
    body overlap check `radius + enemy.radius`.
  - Accept: levels 1/2/3 measure exactly `120/140/160` world units in debug-overlay captures; the
    full interior is visible at 1x, every eligible overlapping enemy can be visually explained, and
    player barrier/enemy shield remains Mint while Electric Field is Arc purple and ground-attached.
    No cyan/mint field, hollow donut, body-hugging bubble, glow, particle spray, repeated ring, or
    second collision truth remains. The added field batch is one retained instance and the existing
    combat/draw-call budgets remain unchanged.
  - Guard: if the filled alpha causes a measurable fill-rate or readability regression, reduce only
    the locked fill/perimeter alpha within the accepted hierarchy after an eligible comparison; do
    not shrink the visual below the damage radius, reduce damage radius, or restore the shield ring.
- [x] **9.5** Reduce boss-shield dominance before considering new boss art.
  - Change: preserve the five boss PNGs and current batch. Reuse the shared authored ring but change
    the boss-only shield write from alpha `0.90` to `0.38` and radius offset from `+12` to `+8`;
    preserve shield-down absence and existing hit feedback. Add no shield node, module, objective,
    new raster, or batch in this first correction.
  - Accept: all five shield-up bosses retain a readable command boundary while their complete body
    silhouette and large planes remain dominant at 1x and grayscale. Shield state is still obvious
    beside the `0.15` damage behavior; non-boss rings are unchanged.
  - Guard: if the existing ring remains too thick or masks a boss after the exact retune, stop and
    open one dedicated shared boss-boundary raster workbench unit. Do not draw replacement geometry
    procedurally or redraw boss bodies by inference.
- [x] **9.6** Capture every elemental, Electric Field, and boss state under real pressure.
  - Change: add deterministic fixtures for Thermal levels 1-3 at direct hit and crowded splash,
    Toxin/Cryo stacks 1-3 at application/persistent/expiry, Electric Field levels 1-3 beside player
    barrier and enemy shield, reduced motion, saturated effect store with EMP, and all five bosses
    shield-up/down/hit. Capture affinity-colored player-primary shots and the unchanged authored
    Seeker identity.
  - Accept: status, attack, effect-store, combat renderer, damage feedback, boss, visual provider,
    manifest/workbench, capture, reduced-motion, visual-authority, and Run validators pass. Actual-
    size results preserve the hierarchy shown by `elemental-hit-feedback-to-be.png`,
    `electric-field-to-be.png`, and `boss-shield-readability-to-be.png` while respecting their
    documented limitations.
  - Evidence: the 103-file Korean `1280x720` matrix under
    `build/visual-captures/phase9-thermal-impact-ko-v5` covers Toxin/Cryo application, persistent,
    hit-flash, reduced-motion, and expired states; Electric Field levels 1-3 beside Mint
    player/enemy shields; all five boss families with shield-up/down/hit states; and Thermal levels
    1-3 at radii `72/84/96` in a crowd. Original-size review confirms the impact grows by level.
    The saturation frame and runtime log show `live=96`, `thermal_live=24`, one Thermal recycle,
    and one retained EMP charge plus one retained EMP release. Commit `25986e26` owns the fixture;
    commit `e7baab12` moves all 24 Thermal instances into one retained MultiMesh batch, and the
    `v5` matrix is generated from that clean runtime path.

Batch gate:

- The exact approved Thermal source, runtime captures, effect counts, boss states, and current
  visual contract agree. Combat batches remain `<=50`, world batches `<=12`, draw-call p95 remains
  `<=200`, effect capacity remains `96`, and no partial visual-budget result is called a release-
  performance pass.

### Phase 10: Consolidate correctness, feel, export, and performance

Goal: verify the exact final workload once, preserve causal evidence, and correct only a measured
hitch owner if needed.

Preconditions:

- Phases 2-9 are complete in separate coherent scoped commits.
- Task-local failures are fixed; no unrelated process overlaps broad validation.

Source owners: all task-owned files, focused validators, export tooling, performance recorder and
scenarios, active performance policy/evidence records

- [ ] **10.1** Run the named focused correctness and authority matrix.
  - Change: run the validators named in each phase, then one consolidated union without repeating
    unchanged passing checks; run Godot headless import, `git diff --check`, document authority,
    visual authority, and a production Web export.
  - Accept: all commands exit zero, Web reports `WEB_EXPORT_OK`, and known non-blocking warnings
    are recorded once.
  - Progress: before the 2026-08-09 progression-feedback revision, the consolidated gameplay,
    movement, Thermal Burst damage, world, provider, renderer, capture, workload, workbench, and
    visual-authority validators passed. Godot import and the four-file production Web export passed
    with `WEB_EXPORT_OK`. These results do not qualify the new Phases 7-9 workload. Document
    authority previously retained one known retired-plan failure. The user approved its deletion
    on 2026-08-09 and the document-authority gate now passes; the consolidated matrix and current
    production Web export remain pending.
- [ ] **10.2** Perform built-product gameplay and visual QA.
  - Change: use production-style native and built Web paths to check all five ordinary-health
    stages; absence of neutral hazards; pursuit/standoff around cover; XP collection and tail
    offers through MAX; the icon-free hull-plus-XP HUD and paused Ship Status after multiple
    upgrades; one shield-up/down boss cycle for every boss; Beam Sentinel and boss beam
    startup/active; Thermal Burst at all levels in a crowd and near a structure; Toxin/Cryo same-
    silhouette overlays; Electric Field levels 1-3 beside a barrier and shield; bilingual cards;
    radar/minimap roles; and surface readability at actual size and grayscale.
  - Accept: the opening is less spongy; later health growth is observable; melee closes and ranged
    holds distance; no level reward disappears; the live top center never shows build icons; hull
    and XP remain distinct despite equal width through thickness, label, and color; paused Ship Status retains the
    complete named build; element values match runtime; nearby direction and
    exact minimap roles do not compete; boss bodies remain readable; burst never double-hits,
    chains, or damages structures; status overlay never escapes the actor alpha or persists after
    state expiry; Electric Field fills the exact damage disk without reading as a shield; and detail
    never reads as collision or combat signal.
  - Progress: the pre-revision 87-image Korean `1280x720` native capture verifies the completed
    beam/surface/boss fixture set. User-controlled movement feel, the new progression/readability
    states, explicit grayscale review, and interactive built-Web play remain open.
- [ ] **10.3** Requalify the exact clean final native commit.
  - Change: after user cost alignment, repeat the Phase 1 `peak_horde` and `capacity_pressure`
    protocol from the exact clean final commit. Compare eligible fields with the Phase 1 baseline;
    save raw JSON unchanged.
  - Accept: both final samples pass the unchanged release thresholds and declared workloads.
  - Guard: hazard removal, steering, splash queries, three surface batches, XP/radar/minimap data,
    Thermal effects, status overlay, Electric Field area, and shield presentation all change the
    final workload. No earlier sample qualifies the final commit.
  - Deferred precondition: a pre-existing normal `Cardborne (DEBUG)` Godot run blocked the last
    isolated sample. Resume only after it closes; do not terminate it by inference.
- [ ] **10.4** Diagnose and correct only a valid red owner, then qualify built Web.
  - Change: if a valid final sample or current-commit manual trace is red, use its subsystem/slow-
    frame evidence to select one owner, make the smallest correction that preserves counts,
    cadence, collision, visuals, and thresholds, rerun affected focused validators, and repeat
    only the invalidated sample. Once native passes, collect built-Web peak through
    `$npjt-port-guard` on the `codex` lane and clean up only the task-owned server.
  - Accept: evidence links the correction to the measured owner; native and Web results are
    authority-eligible and passing; no optimization claim exceeds the evidence.
- [ ] **10.5** Close durable records and commits.
  - Change: update product/visual/performance owners with final values and evidence, create coherent
    scoped commits containing only task-owned files, then obtain explicit user approval and delete
    this completed plan as required by `.agents/AGENTS.md`.
  - Accept: working tree has no task-owned uncommitted changes, no stale active plan remains, and
    final docs do not retain superseded hazard, burn, XP, radar, minimap, status, or surface-detail
    contracts.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | The one or two focused validators named by the active task plus `git diff --check` | After that task compiles and its direct examples are implemented | A relevant source/test/input changes |
| Gameplay phase gate | Field/terrain/map/Run validators for Phase 2; difficulty/boss/movement-policy/local-steering/pursuit/schedule/Run validators for Phase 3; build/status/attack/telemetry/report/renderer/Run validators for Phase 4 | The phase's tasks pass | A phase-owned input changes |
| Visual phase gate | Production manifest, workbench, world visual, field/stage layout, combat renderer, attack readability, capture, import, and `validate_cardborne_visual_authority.ps1` | Contract changes in Phase 5 and approved surface/beam integration in Phase 6 | Visual contract, raster, manifest, placement, renderer, or capture changes |
| Progression phase gate | Experience, upgrade catalog/system/presenter/UI, HUD presenter/layout, Ship Status/build snapshot, localization, stage transition, reward/audio, build/report, capture, and Run validators; repository search proves the acquired-upgrade rail has no live owner or validator | Phase 7 tasks pass | XP, reward transaction, offer compatibility, element values/copy, HUD geometry, Ship Status snapshot ownership, or localization changes |
| HUD and minimap phase gate | Threat radar, combat cue policy, minimap builder/retained mesh, glyph catalog, HUD presenter/layout, capture, visual registry, visual authority, and Run validators | Phase 8 tasks pass | Contact sampling/priority, marker roles/geometry, HUD layout, or visual contract changes |
| Combat-feedback phase gate | Element/status, secondary weapon, attack, effect store, damage feedback, renderer, boss, provider/manifest/workbench, capture, reduced motion, visual authority, and Run validators | Phase 9 tasks and exact Thermal approval pass | Effect source/hash/import, effect allocation, status snapshot/overlay, Electric Field geometry/radius, shield overlay, or capture changes |
| Export gate | `./tools/godot.ps1 --path . --headless --import`; `./tools/export_web.ps1`; require `WEB_EXPORT_OK` | Once after all feature phases and affected focused validators pass | An imported asset, export-affecting source, or project setting changes |
| Native performance gate | Exact clean-commit `peak_horde` and `capacity_pressure` protocol in the prerequisite performance plan | Phase 1 baseline and Phase 10 final state, after user cost alignment | Workload/code/asset/instrumentation changes or a sample is invalid/red for a new evidence-backed hypothesis |
| Web performance gate | Built-Web `peak_horde` on the `codex` lane with exact JSON capture | Native qualification passes and matching Web artifact exists | Native/build/asset/workload changes or the sample is invalid |

Validation rules:

- On start or resume, read this active contract and inspect the worktree only enough to confirm
  checkpoint inputs, then continue from the first unchecked task whose prerequisites are met.
- Treat checked tasks and recorded passing evidence as complete unless a relevant input changed,
  evidence is missing, or this contract schedules a broader final gate.
- Run the narrowest check that proves the current task.
- Run each named phase gate once after its owned tasks pass.
- Treat product feel checks as evidence for the locked balance, not permission to tune numbers
  opportunistically. A requested numeric change requires a contract update.
- Do not run expensive release scenarios while another Godot/test/capture process can contaminate
  them. Do not kill unrelated processes; wait for a quiet window.
- Rerun a failed check only after a relevant implementation change or a new hypothesis can produce
  new evidence.
- Mark a task complete only after its acceptance check passes; record task state and advance the
  single progress pointer in the same plan edit.
- If reality contradicts a material decision, stop that branch and revise this contract. Handle
  implementation-local mechanics inside the locked contract without reopening planning.
- Record known non-blocking warnings once instead of rediscovering them.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| The user's “neutral attack zone” is proven to mean something other than map `hazard_zone` | Stop Phase 2 and ask the user to identify the exact visible mechanic | Never remove boss `denied_zones` or another attack family by inference |
| The additive health curve makes Stage 4/5 clear time fail the existing run contract | Report measured TTK/clear-time evidence and propose a new curve in this plan | Do not silently reduce quotas, populations, damage, speed, or the locked curve |
| Thermal Burst exceeds projectile/frame budgets in an eligible sample | Attribute spatial-query target count and subsystem time; optimize storage/query reuse within the same visible contract | Do not reduce trigger cadence, radius, damage, projectile count, or enemy count without contract revision |
| Continuous steering changes a role's attack opportunity or makes collision recovery unstable | Stop at the Phase 3 harness, preserve the locked bands/timing, and correct the pure movement policy or turn response | Do not change attack range, damage, scheduler cadence, collision radius, or pursuit-field topology |
| An exact surface candidate is rejected | Keep it outside production and regenerate from the same approved semantic/size/contrast brief | Any change to asset count, category, theme, or renderer requires plan and visual-contract revision |
| Surface detail conflicts with gameplay readability or batch cap | Remove the unapproved integration from the candidate branch and stop the visual branch | Do not lower readability/batch thresholds or invent TileMap/shader/chunking ownership |
| The exact borderless beam still reads as a flat bar in runtime | Reject the candidate and revise the one beam workbench unit within the locked two-/three-plane contract | Do not curve the damage corridor, add glow/particles/caps, or alter gameplay width/timing |
| A one- or two-card tail offer cannot fit or focus correctly | Correct centering, focus order, and visible-key handling inside the existing panel/card owners | Do not pad the offer with duplicates, incompatible cards, fake choices, skip actions, or silent reward consumption |
| Zero legal cards occurs while a compatible definition exists | Preserve the active transaction, record seed/build/catalog evidence, and fix the offer invariant | Do not mark progression MAX or consume pending levels from a contradictory catalog state |
| Hull and XP read as one meter, or either value clips at a supported viewport/text scale | Adjust only their shared track width, the locked 6/8/8-pixel XP thickness, local label placement, or the restrained system-blue alpha inside `HealthPips`; preserve equal widths, the 13-pixel amber hull hierarchy, and literal `EXP` label | Do not restore upgrade icons, add a category summary/panel/divider, hide numeric progress, or move detailed build data out of paused Ship Status |
| Removing the live rail also removes or stales paused build details | Restore the event-driven Stage UI build-snapshot cache and Settings > Ship Status consumer before continuing | Do not reintroduce live icons or publish the full build snapshot at fast-HUD cadence |
| Nearby-enemy radar arcs become a second minimap or obscure attacks | Reduce only nearby-contact alpha/width within the locked 12-sector aggregation and keep attack priority | Do not remove committed-attack triangles, expose exact coordinates, increase cadence, or add a full radar circle |
| The eight minimap roles are not distinct at 1x/grayscale | Revise marker silhouette inside the locked role set and retained mesh | Do not add per-archetype markers, hidden Mystery Device outcomes, arbitrary boss colors, labels, or a second minimap layer |
| The exact Thermal impact candidate is rejected | Keep it outside production and regenerate one candidate from the same `192x192`, footprint, plane-count, and no-particle brief | Do not ship the mockup burst, generate an animation pack, author SVG geometry, or replace gameplay values |
| Thermal impacts saturate the effect store | Recycle/drop Thermal cosmetic receipts within the 24-live sub-limit and preserve damage/EMP | Do not increase capacity, evict EMP, reduce attack activity, or suppress damage |
| Toxin/Cryo overlay hides actor identity, escapes the actor alpha, or conflicts with hit flash | Lower only the locked overlay/pulse intensity and preserve same-size actor-alpha clipping and hit-flash priority in the existing batch | Do not add outlines, halos, enlarged silhouettes, rings, icons, per-enemy nodes, materials, or repeated strobe |
| Electric Field reads as a shield or does not explain every damaging overlap | Correct only the field fill, broken perimeter, z-order, or radius-source wiring inside the locked Arc-purple full-disk contract | Do not restore the Mint ring, shrink the visual below `120/140/160`, change the enemy-body overlap rule, or add particles/glow |
| Boss remains obscured after the exact alpha/radius retune | Stop the visual branch and open one shared boss-boundary raster workbench unit under the authority pair | Do not redraw boss bodies, change collision size, or create procedural replacement geometry |
| A valid current sample is red | Select the largest evidenced owner from slow-frame/subsystem data and make one causal correction | No broad optimization pass and no claim based on historical or invalid samples |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain any required approval before resuming | Do not let the executor choose a new product, architecture, dependency, data, UX, safety, or validation contract |

Implementation-local discoveries may be handled inside the locked contract when they cannot
change scope, visible behavior, ownership, architecture, safety, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 10 - Consolidate correctness, built-product QA, and performance evidence.
- Next task: 1.2 - run the user-approved normal-play manual performance trace from the exact clean
  current commit, then complete the Phase 10 correctness/Web matrix. Tasks 1.3-1.4 remain open
  release-performance gates.
- Last completed gate: the exact user-approved Thermal impact SHA-256
  `4cb1b15b1118a093c52ad0f5f750e38af2af0640536659ffc4dc1e19c0474904` is promoted and rendered
  with a 24-live sub-limit inside the fixed 96-state store and one retained render batch; the
  103-file Korean matrix confirms radii `72/84/96` plus full-store Thermal/EMP coexistence. The
  exact user-approved crack, stain,
  and embedded-chip SVG hashes are
  promoted unchanged and compile to deterministic 72/72/48 placement across stages in three
  retained batches, and the borderless straight-beam replacement is production-integrated.
  Manifest/provider/world/workbench/visual-authority/Run gates pass for that completed workload.
  The 2026-08-09 progression/readability discovery gate is complete; its five original and three
  HUD-density TO-BE images are preview-only evidence. The user's final HUD decision supersedes the
  icon-bearing alternatives: top center keeps only a 13-pixel amber hull meter and a thinner
  6/8/8-pixel blue XP meter with a literal `EXP` label, while paused Ship Status retains named
  upgrade details. The user's subsequent alignment correction makes both tracks share the full
  `400/520/640` responsive width (404 pixels at 200% text); focused Korean evidence is under
  `build/visual-captures/xp-equal-width-ko-{960,1280}`. The Electric Field has a separate
  radius-preserving full-area reference,
  upgrade cards contain no horizontal separator, and Toxin/Cryo references use same-size body
  overlays. The approved retired-plan cleanup is complete and document authority passes.
  Phase 7 is complete: one-to-three-card tail offers and explicit `MAX` completion replace the
  silent exact-three loss path; the live acquired-upgrade rail and its validator are deleted;
  fast HUD updates publish allocation-free XP scalars into the amber-hull/blue-XP center stack;
  paused Ship Status retains the named build; and Thermal/Toxin/Cryo card rows share their exact
  runtime values. Focused experience, upgrade system/UI, HUD presenter/layout, localization,
  reward/audio, build snapshot, stage transition/report, capture-driver, Run, parse/import, and
  visual-authority gates pass. Runtime evidence is under
  `build/visual-captures/phase7-progression-{ko,en}`, with compact, large, and 200% text variants
  under the adjacent `phase7-*` directories; actual-size review found no overlap or clipped
  supported state.
  Task 3.6 is complete: deterministic family/band/cadence oracles and the real scheduler/steering
  fixture pass. Its three Korean rendered frames under
  `build/visual-captures/phase3-movement-feel-ko-v9` keep both actors and cover visible; the chaser
  closes to contact while the shooter moves without collapsing into melee.
  Phase 8 is complete: the five-hertz threat scan now republishes targetable off-screen ordinary
  enemies within 1,200 units through a fixed-capacity contact pool; 12-sector aggregation preserves
  incoming/boss/nearby priorities `3/2/1` and gives nearby pressure no triangle. The minimap emits
  exactly eight roles with no Mystery Device outcome field, fixed installations use the priority
  mass, bosses use a command-magenta notched mass, and the facility is a two-tone diamond. Focused
  combat-cue, reinforcement-facility, world-visual, HUD layout/presenter, localization, visual
  coverage, capture-driver, Run, parse/import, and visual-authority gates pass. The 88-file Korean
  production capture completed under `build/visual-captures/phase8-radar-minimap-ko`; original-size
  review of `04e-radar-minimap-roles.png` confirms the dim no-triangle nearby arc, brighter committed
  attack and boss triangles, shape-separated marker roles, unchanged hull-plus-XP stack, and zero
  live upgrade icons.
  Phase 9 is complete: pooled enemies publish fixed Toxin/Cryo ratios and one
  bounded application receipt without renderer status-Dictionary reads or extra draws; direct hit
  flash wins and reduced motion keeps static tint. Electric Field reads its exact `120/140/160`
  radius from the secondary definition snapshot and uses one below-actor Arc-purple retained mesh;
  boss-only shield presentation is exactly `+8` radius and `0.38` alpha. Focused status, secondary,
  renderer, damage-feedback, boss, attack-contract, capture-driver, Run, workbench, and visual-
  authority gates pass. The exact approved Thermal raster is integrated at direct contacts with a
  bounded 24-live cosmetic policy that preserves EMP, and the 103-file Korean capture matrix under
  `build/visual-captures/phase9-thermal-impact-ko-v5` completed and was inspected at original size.
- Update rule: after a checkpoint passes, record concise evidence, check the task, and advance this
  pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check passes.
- Every guard, phase gate, and final gate named by this contract passes.
- No placeholder or unresolved material decision remains.
- Durable product, visual, performance, and lifecycle owners contain the final contracts and
  eligible evidence.
- After implementation is complete, every final gate passes, and the user explicitly approves
  the destructive cleanup, the completed plan is deleted under `.agents/AGENTS.md`.

Replan when:

- A material discovery invalidates the locked product, semantic, visual, architecture,
  performance, safety, or validation contract.

Do not replan or stop for:

- Implementation-local mechanics already contained by this contract.
- A passing check whose relevant inputs have not changed.
