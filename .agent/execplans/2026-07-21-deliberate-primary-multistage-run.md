---
type: plan
status: done
owner: BK
created: 2026-07-21
topic: Deliberate primary-fire rhythm and a three-stage vehicle combat run
scope: Primary attack energy, combat HUD feedback, shared stage data, two additional authored stages, three enemy roles, progression, validation, and documentation alignment
related:
  - ../../docs/product/vehicle_stage_one_experimental_spec.md
  - ../../docs/product/vehicle_content_expansion_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
---

# Deliberate Primary and Multistage Run ExecPlan

## Outcome

The player can no longer hold the primary-fire input to attack continuously. Each press releases the currently stored attack energy; a usable shot returns after roughly one second, while waiting three seconds produces a visibly stronger full-charge attack. The HUD communicates current energy and the resulting weak/charged/full power tier before the player presses.

The current Flooded Works encounter becomes Stage 1 of a continuous three-stage run. Tidal Archive and Storm Drydock use distinct authored traversal layouts and enemy mixes while sharing the same simulation and presentation systems. Completing Stage 1 or 2 offers an explicit next-stage command and preserves acquired upgrades; Stage 3 ends the run.

## Constraints and ownership

- `VehiclePrimaryCharge` owns attack-energy recovery and consumption. UI does not infer combat state.
- `VehicleStageCatalog` owns stage identity, geometry, population, and environment data. The runtime must not duplicate a complete scene or monolithic script per stage.
- `VehicleStageRules` remains the shared geometry/combat-data boundary and consumes the selected catalog entry.
- Korean remains the default locale; every new string has Korean and English values.
- Preserve the accepted flat-color Sunken Ceramic Fresco palette and large readable silhouettes. No new external assets or dependencies.
- Ordinary threats remain bypassable; only active boss arenas seal progression.

## Gameplay decisions

### Deliberate primary

- Use `is_action_just_pressed`: holding never creates a second shot.
- Attack energy recovers linearly from `0.0` to `1.0` over `3.0s`.
- A shot becomes available at `0.34` energy (about `1.02s`). Firing consumes all stored energy.
- Damage and projectile presence scale with released energy. Full charge adds an explicit behavior benefit: Repeater gains one extra pierce; Scatter releases five pellets instead of three.
- The primary rail shows a continuous energy meter and localized `Unavailable`, `Quick shot`, `Charged`, or `Full power` state. It no longer uses ammunition pips or round counts.

### Stages

- Stage 1: Flooded Works — baseline mixed combat and the existing layout.
- Stage 2: Tidal Archive — broad current lanes, artillery pressure, and projectile interception.
- Stage 3: Storm Drydock — divided safe lanes, shield formations, and periodic storm strips.
- All three retain the readable route cadence: open field, two required installations, upgrade cache, optional field boss, and a sealed stage boss arena.
- Stage transition resets transient combat/health and exploration state but preserves selected primary and run upgrades.

### New enemy roles

- Shield Escort: follows an ally and grants one nearby ordinary enemy a visible temporary shield. Killing or separating the escort removes the protection.
- Artillery Spotter: commits a large ground target after a long warning; line-of-sight and movement provide the counterplay.
- Interceptor Tower: stationary installation with three visible interception charges that destroy incoming player projectiles before the tower can be pressured normally.

## Milestones

- [x] **1. Replace the magazine contract with attack energy.**
  - Add a focused attack-energy owner and migrate player input, projectile scaling, reset behavior, HUD snapshot, localized copy, and debug validation.
  - Remove round/capacity/release-latch terminology and stale contracts.

- [x] **2. Separate authored stage data from the shared runtime.**
  - Add the three-stage catalog and make geometry, line-of-sight, movement, drawing, minimap, population, and landmarks stage-aware.
  - Validate every stage for spawn safety and required-landmark reachability.

- [x] **3. Implement stage progression and new combat roles.**
  - Add next-stage result flow, transient reset with run-upgrade preservation, stage-specific titles/bosses, current/storm environment behavior, and the three new enemy roles.
  - Ensure every damaging attack has warning, active, and recovery phases.

- [x] **4. Verify, align documentation, and hand off.**
  - Update product/UI specs to the implemented energy and three-stage contracts.
  - Run gameplay/settings validation, Web export/build, production-style boot checks, Korean/English and compact rendered evidence, and a task-scoped code-quality audit.
  - Mark this plan done and create one scoped commit excluding pre-existing `.import` churn.

## Validation

- A held primary input produces exactly one shot; releasing and pressing before minimum energy produces none.
- A shot at minimum energy is weaker than a full-charge shot; a full Repeater shot pierces and a full Scatter shot has five pellets.
- HUD energy and power state are sourced from the combat owner and fit without clipping at 1280x720 and 960x540.
- All three stage blueprints have collision-safe player, required installation, cache, field-boss, boss, enemy, pickup, and crate positions.
- Required landmarks are grid-reachable with the boss gate open; boss confinement still works when closed.
- Stage advance preserves applied upgrades and selected weapon, resets transient combat state, and Stage 3 resolves to the final result.
- New roles appear in live blueprints, render distinct silhouettes/state, and expose readable counters.
- `./tools/godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_one.gd`
- `./tools/godot.ps1 --path . --headless --script res://tools/validation/validate_pivot_settings.gd`
- `./tools/godot.ps1 --headless --path . --export-release Web build/web/index.html`
- `git diff --check` and explicit staged-file audit.

## Safety and rollback

No save-schema migration or dependency change is required. Stage selection is run-local. Existing persistence fields remain compatible. Reverting the catalog, energy owner, runtime/UI/localization, validation, and documentation changes restores the single-stage magazine version. Pre-existing generated `.import` changes are not task-owned and remain unstaged.

## Decision log

- 2026-07-21: Rejected the previous finite magazine as a mismatch for the desired “press only when useful” behavior. Stored attack energy makes the benefit of waiting visible before the action rather than only punishing the player after depletion.
- 2026-07-21: Chose three total authored stages because it is enough to verify continuity and escalating enemy composition without inventing a procedural content system.
- 2026-07-21: Promoted Tidal Archive and Storm Drydock from the draft expansion spec because the user explicitly authorized actual additional stages and enemies in this turn.
- 2026-07-21: Render review retained the low action rail, replaced ammunition pips with a continuous energy bar, and confirmed readable Korean/English layouts at 1280x720 plus Korean at 960x540.
- 2026-07-21: Post-implementation quality review limited Shield Escort to one nearest ally, made artillery startup cancel when cover breaks line of sight, and gave the primary meter a direct energy-fill contract.
- 2026-07-21: Final automated validation passed 125 gameplay/UI/geometry checks and settings validation. The Godot Web release export completed, and `index.html`, `.wasm`, `.pck`, and `.js` returned HTTP 200 from the registered Codex port.
