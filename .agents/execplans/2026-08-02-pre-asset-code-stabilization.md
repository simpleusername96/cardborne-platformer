---
type: plan
status: active
owner: BK
created: 2026-08-02
last_reviewed: 2026-08-04
topic: Urgent runtime readability and performance stabilization
scope: Upgrade choice UI, projectile visibility, enemy approach and attack-route readability, Wear Collapse tiles, and severe frame stutter
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../semantic-v2-runtime-acceptance-evidence.md
---

# Urgent Runtime Readability and Performance Stabilization

This is the single active execution plan for the urgent work. It replaces the
obsolete pre-asset checklist in this file with a compact implementation contract.
Completed historical phases are evidence, not work to repeat.

The outcome is a readable, responsive combat build in which the upgrade choice
screen uses large authored artwork and complete progression data, every projectile
is easy to see without changing its collision truth, enemy approaches and committed
attack corridors are legible, Wear Collapse tiles communicate all three states, and
the authoritative high-pressure performance gates pass.

## Why / Context

The current build has five user-prioritized problems:

1. The upgrade cards are cramped, use small code-drawn glyphs, and do not always
   make the level and current-to-next change obvious.
2. Projectiles use one suitable teardrop image, but its opaque area is too small and
   player scale is controlled by renderer literals instead of the visual profile.
3. Enemy approach lanes and committed attack routes need to read clearly at live
   speed and under pressure.
4. Wear Collapse tiles look like isolated UI panels and the collapsed image has bad
   edge treatment instead of belonging to the floor.
5. The game has severe frame stutter. The latest authoritative `peak_horde` evidence
   reports 115.974 ms median and 140.476 ms p95 frame time even though draw-call p95
   (122) and combat batches (34) already pass. This is a CPU/frame-orchestration
   problem until profiling proves otherwise.

The previous plan's completed movement, terrain logic, telegraph contract, and visual
switch phases must not be reimplemented. Its only genuinely unfinished release item
was performance qualification. Recent user feedback reopens only the four targeted
readability surfaces above.

## Scope / Non-scope

### In scope

- Upgrade choice card layout, content artwork, progression copy, localization, and
  the `seeker` versus `secondary` conflict across data, catalog, runtime, UI, and tests.
- One shared non-beam projectile PNG, visual scale ownership, and live-size
  readability. Collision radius, damage, cadence, and behavior remain unchanged.
- Enemy approach distribution plus committed projectile, charge, beam, and area
  attack corridor parity with simulation and blockers.
- The three Wear Collapse tile images and their existing state transitions.
- CPU/frame profiling, enemy scheduling, HUD work, and any other measured hot owner
  required to pass the existing performance gates.
- Focused checks during implementation and one complete release-validation pass after
  all switches are integrated.

### Explicitly out of scope

- Floor, outer wall, ordinary in-game wall, obstacle, service rail, world overlay, or
  broader map redesign. Map work is deferred.
- Pickups, experience shards, crates, facilities, player craft, enemy roster, boss
  art, and unrelated effects.
- Any UI outside the upgrade-choice flow. Existing deployment, pause, settings, HUD
  layout, menus, and shared UI chrome are protected from visual redesign.
- New gameplay content, map topology, enemy role ratios, boss patterns, difficulty,
  collision sizes, combat values, capacity reductions, workload reductions, or lower
  release thresholds.
- New engine, production dependency, or native extension.

## Verified Starting Evidence

| Area | Current fact | Required correction |
| --- | --- | --- |
| Upgrade UI | `VehicleUpgradeChoiceCard` renders `VehicleUpgradeGlyphRenderer`; the validator requires code-native artwork with zero textures. | Upgrade content art becomes semantic authored PNG. UI chrome remains shared Theme/styleboxes. |
| Upgrade data | Forty-one definitions use eight families. Six resources use `seeker`, while localization presents both `seeker` and `secondary` as “Secondary Weapons.” | `secondary` is the only upgrade family. `seeker` remains a weapon/behavior subtype. |
| Upgrade values | The presenter emits real current and next levels and at most two modifier rows. | Every card visibly shows `Lv.current → next`; numeric upgrades show real deltas and behavior-only upgrades show a concise “new behavior” row. |
| Projectile | `projectile_energy_teardrop.png` is 64×64, but its opaque body occupies roughly 36×17 pixels. Hostiles use profile scale 4.5; player projectiles use renderer literals 5.0/5.6/5.8. | Normalize the opaque body and move all visual scales into `VehicleStageVisualProfile`. |
| Attack routes | Telegraph descriptors already use attack data and can clip through a blocker resolver. | Prove every caller uses live blocker truth and make approach/commit footprints readable at actual scale. |
| Wear tiles | State logic already implements `intact → cracked → collapsed`, third-entry collapse, damage ticks, and persistence. | Replace only the three state images; preserve all behavior. |
| Performance | Latest peak: 276 enemies, 212 projectiles, 659 visible instances, 34 batches; enemy/grid p95 13.720 ms, scheduled ordinary enemies p95 11.259 ms, HUD 11.248 ms, and about 85 ms median remains unattributed. | Attribute the whole frame, remove measured repeated work/allocations, then meet the existing gates without reducing workload. |

## Assumptions

- Godot 4.7.1 stable and GL Compatibility remain the runtime authority.
- Korean and English remain complete on every touched user-facing string.
- Existing save compatibility is preserved. Renaming the data family does not rename
  card IDs, weapon IDs, or save keys.
- The canonical visual authority is the pair:
  `docs/design/VISUAL_SYSTEM.md` and
  `docs/design/cardborne-universal-art-style-reference.png` (SHA-256
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`).
- `docs/design/component-sheets/system-v1/07-projectile-telegraph-vfx.png` is a
  rejected historical direction and must not be used as generation authority.
- This plan contains no user-approval interlock. The executor proceeds through the
  final gate. It stops only if work would require a new dependency, a gameplay rule
  change, a workload/threshold reduction, or destructive scope outside this plan.

## Proposed Design

### 1. Upgrade domain and artwork ownership

`secondary` is the canonical umbrella family in product, data, UI, and runtime.
The always-equipped seeker remains its built-in subtype and the other four weapons remain
optional subtypes; seeker still consumes no optional slot. The six current seeker cards
become `family = &"secondary"`. Add
`secondary_slot_kind: StringName = &""` to `VehicleUpgradeDefinition`, with `built_in`
on those six cards and `optional` on the four optional-weapon cards. Catalog eligibility
and `VehicleRunBuild.active_optional_secondaries()` use this field instead of a duplicate
family or hard-coded optional-ID list.

Move the built-in seeker cooldown, target selection, and projectile-intent production
into `VehicleSecondaryRuntime`, which already owns the other automatic secondary
families and already lists seeker in its snapshot. Its update result gains one bounded
`projectiles` intent array; `VehicleRun` remains the owner that writes those intents to
the projectile store. HUD cooldown/availability reads the secondary snapshot. Retire
`VehicleRun.player_seeker_cooldown` and `_find_seeker_targets()` only after equivalent
deterministic coverage passes. Damage-source ID `seeker`, gameplay asset ID
`secondary/seeker`, card IDs, save keys, targeting, cadence, and combat values remain
unchanged. Remove the obsolete `UPGRADE_FAMILY_SEEKER` localization row after all family
references are gone.

Add `@export var artwork_asset_id: StringName = &""` to
`VehicleUpgradeDefinition`. Card data selects artwork; UI never infers mechanics from a
family name. Register upgrade artwork in the existing gameplay semantic asset
manifest/provider. These images are gameplay-content illustrations shown inside UI, not
UI chrome.

Use at most sixteen reusable artwork identities for all forty-one cards:

| Card group | Artwork asset ID | Source |
| --- | --- | --- |
| All nine primary cards | `projectile/energy_teardrop` | Reuse improved world projectile |
| Six seeker cards | `secondary/seeker` | Reuse existing gameplay asset |
| `escort_drone` | `secondary/escort_drone` | Reuse existing gameplay asset |
| `orbit_blades` | `secondary/orbit_blade` | Reuse existing gameplay asset |
| `wake_mines` | `secondary/wake_mine` | Reuse existing gameplay asset |
| `ion_field` | `upgrade/ion_field` | New shared artwork |
| `incendiary_core`, `thermal_compound` | `upgrade/element_thermal` | New shared artwork |
| `toxin_core`, `concentrated_toxin`, `contagion` | `upgrade/element_toxin` | New shared artwork |
| `cryo_core`, `deep_freeze` | `upgrade/element_cryo` | New shared artwork |
| All four dash cards | `upgrade/dash_wake` | New shared artwork |
| `aegis_cycle`, `siphon_matrix`, `static_aegis` | `upgrade/defense_matrix` | New shared artwork |
| `emp_aftershock`, `emp_capacitor`, `emp_focus` | `effect/emp_release` | Reuse existing gameplay asset |
| `relay_overload` | `upgrade/system_relay` | New shared artwork |
| `tuned_thrusters`, `dash_capacitor` | `upgrade/mobility_thruster` | New shared artwork |
| `pickup_magnet` | `upgrade/pickup_magnet` | New shared artwork |
| `reinforced_hull` | `upgrade/hull_reinforcement` | New shared artwork |

The ten new images are transparent 192×192 PNGs with pivot `(96, 96)`. They use one
large flat silhouette, broad matte planes, restrained charcoal separation, and role
color. They contain no text, card frame, background panel, dots, greeble, glow cloud,
or detached decorative parts.

Each new ID maps to
`art/visuals/production/gameplay/upgrades/<ID leaf>.png`; for example,
`upgrade/ion_field` maps to `upgrades/ion_field.png`. Add category `upgrade: 10`, change
the manifest total from 57 to 67, and update
`validate_vehicle_visual_asset_coverage.gd`,
`validate_vehicle_semantic_asset_provider.gd`, and `VISUAL_SYSTEM.md` to require that
exact distribution and all ten IDs. Existing categories and their counts do not change.

Replace the upgrade glyph draw control with a `TextureRect` backed by the semantic
provider. Once zero references remain, retire exactly:

- `scripts/presentation/components/vehicle_upgrade_glyph_renderer.gd`
- `scripts/presentation/components/vehicle_upgrade_glyph_renderer.gd.uid`

Do not remove or convert the separate action/minimap glyph systems.

### 2. Upgrade card layout

The prior
`docs/design/visual-replacement-workbench/previews/ui-screen-direction/03b-upgrade-card-selected.png`
is non-binding evidence of the user's chosen composition, not visual authority. M1 first
writes the following decisions into `VISUAL_SYSTEM.md`; that updated text plus the
canonical reference PNG then governs implementation. The information order is fixed:

1. family;
2. upgrade name;
3. large artwork on the left and level/change data on the right;
4. short description;
5. one fixed shared Equip action below the three cards.

There is no modal title block, instructional paragraph, card-top thumbnail, or Leave
button. Preserve one selection rail and keyboard/controller focus; do not add ornament.

| Mode | Card size | Gap | Artwork | Type minimums |
| --- | --- | --- | --- | --- |
| Compact (960 wide) | 280×378 | 12 | 88×88 | family/body 14, title 24, value 16 |
| Standard (1280 wide) | 360×456 | 16 | 112×112 | family/body 16, title 28, value 18 |
| Large (1920 wide) | 420×480 | 24 | 128×128 | family/body 18, title 32, value 18 |

The three-card container grows up to 1,308 px; it does not keep narrow cards in unused
space. Compact applies below 1,100 px, standard from 1,100 through 1,599 px, and large
from 1,600 px. The 1920 modal content maximum becomes 1,376 px; the existing 960 and
1280 safe margins remain. These values deliberately replace the current
`352×432`/20-gap wide-only contract and its validator assertions. At 200% UI scale,
cards may stack inside one outer scroll container, but card
internals never create nested scrollbars and Equip remains reachable. Numeric cards
show no more than two real `current → next` rows. Behavior-only cards use a localized
“New behavior” label plus a concise data-owned summary instead of fake numbers or a
long paragraph in the comparison lane.

### 3. Projectile visibility and ownership

Keep one 64×64 right-facing, tailless energy-teardrop PNG. Redraw it so the nontransparent
body is centered on collision truth and fits an alpha bound between 46–52 px wide and
24–30 px high. The bright collision core remains visually dominant; the outer soft
silhouette may aid recognition but must not imply a larger damaging hitbox.

`VehicleStageVisualProfile` owns all multipliers:

- `HOSTILE_PROJECTILE_ENVELOPE_SCALE = 5.50`;
- `PLAYER_PRIMARY_PROJECTILE_SCALE = 6.25`;
- `PLAYER_SEEKER_PROJECTILE_SCALE = 5.75`;
- `PLAYER_OPENING_BREACH_PROJECTILE_SCALE = 6.50`.

`VehicleCombatRenderer` consumes those constants and contains no projectile-scale
literals. Rotation and faction/affinity tint remain runtime-owned. Collision radii,
speed, lifetime, homing, damage, and capacity remain unchanged.

Add `tools/validation/validate_vehicle_projectile_readability.gd`. It loads the source
PNG as `Image`, asserts the alpha-used bound above, requires the `(32, 32)` pivot pixel
and its 3×3 neighborhood to be opaque/bright, and renders debug projectiles to prove
each of the four visual radii equals collision radius times the matching profile
constant. The AS-IS/TO-BE report includes an actual-scale collision-circle overlay for
human verification that the bright core, not the whole silhouette, communicates hit
truth.

### 4. Enemy approach and committed attack routes

“Attack route” covers two existing contracts, not map pathfinding:

- Approach: births remain distributed over the established eight sectors, enemies do
  not overlap into a single spawn point or permanent single-file lane, local separation
  remains active, and every mobile role still converges on the player.
- Commit: startup cues for projectile, charge, beam, and area attacks show origin,
  direction, width/radius, and collision-resolved endpoint before damage. The committed
  origin/target does not drift, off-screen sources still show intersecting danger, and
  active beams/areas remain visible for their damaging interval.

Keep the existing exact spawn-allocation and local-steering validators as the approach
fixture: every arrival window uses all eight sectors, sector counts differ by at most
one, cue births use four sectors, births keep the 320 px separation floor, and overlap
steering is deterministic and bounded to eight neighbors.

Add `tools/validation/validate_vehicle_attack_route_readability.gd` for commit parity.
Using fixed origin/direction/target values and one injected blocker, it exercises an
ordinary and boss example for projectile, charge, beam, and area delivery through the
runtime capture gateway. It asserts:

- descriptor origin, direction, half-width/radius, lead/startup duration, and endpoint
  equal the owning attack contract;
- projectile and beam endpoints equal the live projectile-path resolver result;
- charge endpoint equals the live movement/charge resolver result;
- area center/radius equal the committed simulation values;
- startup origin/target remain fixed through commit;
- an off-screen source whose corridor intersects the viewport produces a nonzero
  renderer cue; and
- active beam/area presentation remains present for every damaging tick and disappears
  after the active interval.

The fixture captures the actual `VehicleRun` caller path, not only direct builder output.
Current source inspection suggests that parity may already pass; if so, this phase adds
the regression contract and changes no AI or route code. If it fails, fix the existing
descriptor builder, caller, resolver, or renderer owner only. Do not add tails,
decorative lane marks, new AI rules, or a navigation system.

### 5. Wear Collapse tiles

Replace only `world/wear_tile_intact`, `world/wear_tile_cracked`, and
`world/wear_tile_collapsed`. Preserve the 240×160 canvas, `(120, 80)` pivot, placement,
state machine, damage, occupancy reset, and persistence.

All three states derive from one light-gray hangar-floor plate:

- intact: quiet floor-integrated plate, no card-like frame;
- cracked: the same plate with one unmistakable structural fracture;
- collapsed: a clean dark opening with a readable hazardous footprint and no colored
  fringe, dirty matte, halo, or cutout residue.

Damageable bulkheads receive regression coverage only. Their behavior or artwork changes
only if the focused fixture proves a current invisible/mismatched transition; this is
not permission to resume the wider map redesign.

### 6. Performance repair

Use the current `peak_horde` workload as the first diagnostic target. Capture one clean
foreground native 1280×720, 10-second warmup plus 60-second instrumented result at
`build/performance/urgent-stabilization/profiles/peak-horde-baseline.json` on the exact
starting commit. This is diagnosis, not an early release gate.

Extend `VehiclePerformanceRecorder` in diagnostic-scenario mode with a bounded
`slow_frame_samples` array containing the 64 slowest frames. Every sample records frame
serial/time, frame delta, total physics, enemy/grid, scheduled ordinary enemy,
projectile/effect, presentation, HUD build, HUD apply, engine process, engine physics,
render CPU, render GPU, and derived wait/unattributed time. The result also identifies
the sample nearest p99. The median frame and that representative p99 hitch must each be
at least 90% classified as script owner, engine process/physics, render CPU/GPU, or
scheduler/wait before M2 selects an additional hot owner. Periodic engine monitors are
diagnostic overlap and are not added to script timers as if independent. Do not optimize
from an unexplained 85 ms gap.

Two current owners already justify direct work unless the fresh profile disproves them:

- Replace `VehicleEnemyUpdateSchedule.rebuild()`'s per-physics clear/repopulate and
  dynamic carrier/rammer dictionary work with retained, bounded membership/worklists
  updated on spawn, activation, retirement, squad change, and cadence boundaries.
  Preserve committed 60 Hz behavior, ordinary 10 Hz decisions, and 30/20 Hz movement.
- Split HUD snapshot generation/application by owned channel and skip unchanged channel
  builds and Control writes. Preserve the existing maximum 20 Hz fast and 10 Hz world
  refresh cadence and current observable latency; do not invent a new event-bypass
  contract during this optimization.

After each correction, rerun only `peak_horde` as a short diagnostic. If a different
owner is the largest self-time above 2 ms p95 or 25% of measured script CPU, correct
that owner in its existing module. Do not create a catch-all optimizer. If the remaining
dominant cost requires engine replacement, native code, lower workload, or a changed
gameplay rule, record evidence and stop because that exceeds this plan's authority.

## Milestones

### M1 — Correct contracts and capture the performance baseline

- [ ] Record exact HEAD, dirty state, existing failing JSON, and a fresh native
  instrumented `peak_horde` result with the required 64 slow-frame samples and p99
  classification at the exact profile path above.
- [ ] Update `VISUAL_SYSTEM.md` so authored PNG ownership explicitly includes upgrade
  content artwork while shared UI chrome remains Theme/stylebox-owned; replace the old
  card geometry/breakpoint assertions with this plan's three modes; and change the exact
  gameplay manifest contract from 57 to 67 with category `upgrade: 10`.
- [ ] Update `vehicle_game_spec.md` to make `secondary` the sole user-facing upgrade
  family/umbrella, define built-in versus optional secondary slot kinds, and lock the
  card information order and behavior-only fallback.
- [ ] Add complete performance attribution before choosing any additional hot owner.

### M2 — Remove the measured stutter

- [ ] Implement retained enemy scheduling/worklists and channel-dirty HUD updates.
- [ ] Correct any additional profiler-proven owner within this plan's boundaries.
- [ ] Confirm short native `peak_horde` diagnostics trend under the release thresholds
  without lowering actors, projectiles, zones, effects, or visual quality.

### M3 — Produce all replacement images in one batch

- [ ] Generate the ten 192×192 upgrade artwork PNGs, the corrected 64×64 projectile
  PNG, and the three 240×160 Wear Collapse PNGs in one visual-production milestone.
- [ ] Before every generation/edit, read `VISUAL_SYSTEM.md`, inspect the canonical PNG,
  and pass `cardborne-universal-art-style-reference.png` as the actual image-reference
  input. Do not pass the Markdown file as an image.
- [ ] Update the semantic manifest and both exact-count validators to 67 assets with ten
  `upgrade` entries. Build one compact local AS-IS/TO-BE HTML report at
  `docs/design/visual-replacement-workbench/previews/urgent-runtime-stabilization/index.html`
  showing every changed image at native size and over representative gameplay/UI
  backgrounds.
- [ ] For each of the exact fourteen outputs, record AS-IS hash (or `new`), TO-BE hash,
  dimensions, pivot, alpha bounds, canonical reference path/hash, generation/edit
  provenance, and pass/fail results. Self-check silhouette, alpha edges, actual-size
  readability, and collision overlay. The user's approval-free-plan instruction
  pre-authorizes only this exact fourteen-output set once all mechanical acceptance
  checks pass; the report is evidence, not an approval stop.

### M4 — Integrate upgrade data and UI

- [ ] Add `artwork_asset_id`, migrate all forty-one definitions using the locked table,
  and validate that every ID resolves.
- [ ] Add `secondary_slot_kind`, merge the six `seeker` family resources into
  `secondary`, and replace hard-coded optional-ID eligibility with built-in/optional
  metadata. Update `VehicleRunBuild.active_optional_secondaries()` to count owned
  catalog definitions whose `secondary_slot_kind == &"optional"`; remove
  `OPTIONAL_SECONDARY_FAMILY_IDS` after all callers and focused tests use metadata.
- [ ] Move built-in seeker scheduling and projectile intents into
  `VehicleSecondaryRuntime`; update `VehicleRun`, HUD snapshots, damage reporting,
  capture fixtures, localization, and tests without changing observable weapon behavior.
- [ ] Replace code-drawn upgrade glyphs with semantic textures and retire only the exact
  zero-reference renderer pair listed above.
- [ ] Implement the compact/standard/large layout, full level/change visibility,
  behavior-only fallback, fixed Equip action, focus states, and 200% outer scrolling.
- [ ] Update upgrade validators to require one resolved authored texture per card and
  reject code-native upgrade artwork.

### M5 — Integrate combat readability

- [ ] Switch all projectile visual multipliers to `VehicleStageVisualProfile`, improve
  the shared PNG occupancy, and remove renderer literals.
- [ ] Add actual-scale projectile coverage for friendly/hostile colors and 960/1280/1920
  pressure scenes while preserving collision truth; add and pass
  `validate_vehicle_projectile_readability.gd`.
- [ ] Add deterministic approach-distribution and projectile/charge/beam/area corridor
  fixtures in `validate_vehicle_attack_route_readability.gd`; repair caller, blocker,
  descriptor, and renderer parity only if the runtime fixture fails.

### M6 — Integrate Wear Collapse tiles

- [ ] Switch the three images in place without changing IDs, canvas, pivot, or gameplay.
- [ ] Capture intact, cracked, collapse-on-third-entry, damage tick, leave/re-entry, and
  persisted-state evidence against the actual floor.
- [ ] Verify clean alpha/edge behavior over light and dark backgrounds.

### M7 — Run the one complete final gate

- [ ] Run import, all focused validators, the complete `validate_vehicle_*.gd` suite,
  `validate_cardborne_visual_authority.ps1`, Web release export, foreground native
  runtime smoke, and visible built-Web smoke once after integration. No native export
  preset exists, so the foreground Godot runtime is the strongest current native path.
- [ ] Capture Korean and English upgrade UI at 960×540, 1280×720, 1920×1080, and 200%
  UI scale; verify no clipping, overlap, tiny text, nested scroll, or unreachable Equip.
- [ ] Capture projectile/attack-route/Wear Tile states at actual gameplay scale.
- [ ] Run one authoritative native and visible Web result for `production_replay`,
  `peak_horde`, `capacity_pressure`, and `boss_pressure`.
- [ ] After capacity passes, run the one 600-second native `lifecycle_pressure` soak.
- [ ] Update the evidence record, incorporate durable decisions, mark this plan done,
  and retire it according to `.agents/PLANS.md`.

## Test Plan

### Focused checks during implementation

Run only the check owned by the changed milestone:

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_upgrade_system.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_secondary_weapons.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_upgrade_ui.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_ui_localization.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_ui_layout.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_semantic_asset_provider.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_visual_asset_coverage.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_combat_renderer.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_projectile_readability.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_attack_contract.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_attack_route_readability.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_spawn_allocation.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_enemy_local_steering.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_destructible_terrain_flow.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_wear_collapse_tiles.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_terrain_runtime.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_performance_scenarios.gd
.\tools\validation\validate_cardborne_visual_authority.ps1
```

`profile_vehicle_pressure.gd` is diagnostic only; it never counts as rendered release
evidence.

### Final gate

```powershell
.\tools\godot.ps1 --path . --headless --import

$validators = Get-ChildItem -LiteralPath 'tools/validation' -Filter 'validate_vehicle_*.gd' |
  Sort-Object Name
foreach ($validator in $validators) {
  .\tools\godot.ps1 --path . --headless --script "res://tools/validation/$($validator.Name)"
  if ($LASTEXITCODE -ne 0) { throw "validator failed: $($validator.Name)" }
}

.\tools\validation\validate_cardborne_visual_authority.ps1
if ($LASTEXITCODE -ne 0) { throw 'visual authority validation failed' }
.\tools\export_web.ps1
git diff --check
```

For each authoritative native scenario, use foreground 1280×720 GL Compatibility and
preserve the JSON:

```powershell
foreach ($scenario in @('production_replay', 'peak_horde', 'capacity_pressure', 'boss_pressure')) {
  $output = "build/performance/urgent-stabilization/native/$scenario.json"
  .\tools\godot.ps1 --path . --rendering-method gl_compatibility --resolution 1280x720 -- `
    "--performance-scenario=$scenario" `
    "--performance-output=res://$output" `
    --performance-warmup=10 --performance-duration=60
  if ($LASTEXITCODE -ne 0) { throw "native performance failed: $scenario" }
  $result = Get-Content -LiteralPath $output -Raw | ConvertFrom-Json
  if (-not $result.authoritative -or -not $result.scenario_validation.valid -or -not $result.thresholds.passed) {
    throw "valid native performance gate failed: $scenario; fix before continuing"
  }
}

# This runs only after the capacity result above is authoritative, valid, and passing.
.\tools\godot.ps1 --path . --rendering-method gl_compatibility --resolution 1280x720 -- `
  --performance-scenario=lifecycle_pressure `
  --performance-output=res://build/performance/urgent-stabilization/native/lifecycle-pressure-600s.json `
  --performance-warmup=10 --performance-duration=600
if ($LASTEXITCODE -ne 0) { throw 'native lifecycle pressure failed' }
$lifecycle = Get-Content -LiteralPath `
  'build/performance/urgent-stabilization/native/lifecycle-pressure-600s.json' `
  -Raw | ConvertFrom-Json
if (-not $lifecycle.authoritative -or -not $lifecycle.scenario_validation.valid -or -not $lifecycle.thresholds.passed) {
  throw 'valid native lifecycle gate failed'
}
```

Before the Web run, resolve the fastrun manager's `codex` lane exactly:

```powershell
$codexPort = py -3.11 `
  'C:\Users\BK\.codex\skills\npjt-port-guard\scripts\npjt_port_guard.py' `
  --project 'D:\npjt\cardborne-platformer' --service web --print-port
if ($LASTEXITCODE -ne 0 -or -not $codexPort) { throw 'codex web port unavailable' }
```

Inspect that port first. If it is unbound, start a task-owned hidden static server and
retain its PID for cleanup. If it is bound, reuse it only when the PID, command line,
project path, and served files prove it is this project's production export. A bound
unknown or mismatched listener is a stop/report condition: do not kill it, reuse it,
attempt a second bind, or choose a fallback port.

```powershell
$server = Start-Process -FilePath 'py' -ArgumentList @(
  '-3.11', '-m', 'http.server', $codexPort,
  '--bind', '127.0.0.1', '--directory', (Resolve-Path 'build/web').Path
) -PassThru -WindowStyle Hidden
```

For each of `production_replay`, `peak_horde`, `capacity_pressure`, and `boss_pressure`,
use Chrome DevTools MCP to open this exact visible tab URL:

```text
http://127.0.0.1:<codexPort>/?performance_scenario=<scenario>&performance_warmup=10&performance_duration=60
```

Before waiting, evaluate `document.hasFocus()`, `document.visibilityState`, viewport
`1280×720`, and `navigator.userAgent`; the tab must be focused/visible and the agent must
not contain `HeadlessChrome`. Wait until `window.__cardbornePerformanceResultJson` is a
nonempty string, evaluate it once, and save the exact parsed JSON as
`build/performance/urgent-stabilization/web/<scenario>.json`. Require scenario match,
`authoritative == true`, `execution_environment.authority_eligible == true`,
`scenario_validation.valid == true`, and `thresholds.passed == true` before opening the
next URL. An invalid environmental run may be discarded and rerun; a valid failure stops
the gate and requires a fix. After the last result, stop only the retained task-owned
server PID; leave a reused server running.

### Acceptance thresholds

- Native 1280×720: p95 ≤18 ms, p99 ≤25 ms, median ≥59 FPS, 1% low ≥55 FPS,
  and at most one consecutive frame above 33.3 ms.
- Visible Web: p95 ≤20 ms, p99 ≤33.3 ms, median ≥58 FPS, 1% low ≥50 FPS,
  and at most two consecutive frames above 33.3 ms.
- Capacity simulation: physics p95 ≤6 ms and p99 ≤8 ms.
- Draw-call p95 ≤200 and combat batches ≤50.
- Lifecycle: 600 measured seconds and static-memory growth below 8 MiB.
- The gameplay manifest has exactly 67 PNGs with category `upgrade: 10`; all ten new
  IDs resolve, and all previous category counts remain unchanged.
- Forty-one upgrade definitions resolve artwork; zero definitions use family `seeker`;
  all secondary cards declare `built_in` or `optional`; built-in seeker simulation is
  owned by `VehicleSecondaryRuntime`; no upgrade code-draw renderer remains; and all
  cards show a level transition plus real numeric changes or a localized new-behavior row.
- Projectile alpha/pivot checks, four scale-consumption assertions, collision-overlay
  evidence, and all attack-route fixtures pass while collision and combat values remain
  unchanged in their owning gameplay resources/contracts.
- Wear Tile state images have exact dimensions/pivots, clean edges, and unchanged state,
  damage, and persistence behavior.

## Rollback / Safety

- Work in milestone-scoped commits. Never mix deferred map changes into these commits.
- Before asset replacement, record byte size and SHA-256 for every target. Git retains
  the prior bytes; do not delete the AS-IS/TO-BE evidence report during execution.
- Change resource schema additively first, migrate all resources, then make the field
  required. This keeps intermediate imports recoverable.
- Retire the upgrade glyph renderer only after `rg` and validators prove zero references.
- Keep performance changes behind existing owners and stable public behavior. Revert an
  optimization commit if it changes deterministic results, cadence, workload, or combat.
- Do not reset, clean, or modify unrelated user work.

## Risks

- Larger projectile art can overstate collision. Mitigation: preserve the collision-core
  alignment and validate opaque core versus the real radius.
- Merging upgrade families can accidentally alter offer composition. Mitigation: retain
  card IDs and runtime weapon IDs; snapshot deterministic offer sets before/after.
- A 200% card layout can create nested scrolling. Mitigation: one outer scroll owner and
  fixed action reachability.
- Enemy scheduling optimization can change cadence or ordering. Mitigation: deterministic
  slot/generation fixtures and exact before/after decision/movement counts.
- The unattributed frame gap may be outside the currently measured owners. Mitigation:
  complete attribution before expanding implementation; do not guess or reduce workload.

## Open Questions

None at plan start. “Attack route” is deliberately defined above as approach distribution
plus committed attack-corridor parity, and “destructible tile” is the Wear Collapse family.
Any later request to include navigation, ordinary walls, bulkhead redesign, pickups, or
other UI is a separate scope decision and must not be silently absorbed here.

## Decision Notes

- 2026-08-04: Reused and rewrote the sole active ExecPlan instead of creating a second
  competing plan.
- 2026-08-04: Deferred the full map visual redesign and protected all non-upgrade UI.
- 2026-08-04: Kept one shared projectile identity and made scale/occupancy the fix.
- 2026-08-04: Chose sixteen maximum reusable upgrade artwork identities rather than one
  image per card or one generic family glyph for every mechanic.
- 2026-08-04: Made `secondary` canonical and retained `seeker` only as behavior/weapon
  terminology.
- 2026-08-04: Required one final comprehensive validation pass; milestone checks remain
  narrow and local. Performance needs one diagnostic baseline before implementation.
- 2026-08-04: Kept all existing performance thresholds, content counts, and cadences.

## Progress

- [x] Re-audited prior user requests, current code owners, active/superseded plans,
  current visual authority, runtime evidence, and recent Git history.
- [x] Identified stale completed phases in the old plan and preserved only relevant work.
- [x] Locked scope, terminology, reusable artwork mapping, target layout, projectile
  scales, tile boundaries, performance priorities, validation cadence, and stop rules.
- [ ] M1 through M7 implementation remains.

## Completion

This plan is complete only when every M1–M7 item is checked, the final evidence satisfies
all acceptance thresholds, no deferred map or unrelated UI work entered the diff, durable
product/design contracts are updated, and the plan is retired under `.agents/PLANS.md`.
