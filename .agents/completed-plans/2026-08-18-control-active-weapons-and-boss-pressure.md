---
type: plan
status: done
created: 2026-08-18
scope: CC-only active weapons and close-pressure stage bosses
---

# CC-Only Active Weapons And Close-Pressure Bosses

## Goal

Make every active weapon a zero-damage crowd-control tool whose upgrades improve control reach, duration, and cooldown. Make stage bosses durable and fast enough to close on the player, and remove shield behavior that does not create a meaningful positional decision.

## User Decisions And Boundaries

- Active weapons deal no damage to enemies, bosses, neutral facilities, or structures.
- Active weapon upgrades improve range, cooldown, and control duration or strength.
- Boss health becomes exactly five times the current authored baseline.
- Bosses move faster than a fully upgraded non-dashing player and actively close distance.
- Boss shields remain restrained. Stage 5 boss loses the relay-sector shield whose player-facing sector becomes permanently irrelevant after breaking. Stage 3 boss keeps a narrower, weaker frontal intercept.
- Do not change enemy quotas again in this task.
- Do not perform run-duration or result measurement. Functional, contract, visual, and export validation remain in scope.
- Preserve active weapon IDs, names, art, input, and four-level ownership. Preserve boss attack cadence, damage, warnings, encounter caps, and authored role identities.

## Evidence And Decisions

- `VehicleRun._boss_combat_move()` currently approaches only beyond 560 px and retreats below 340 px. Bosses therefore maintain ranged standoff through their dedicated boss path; ordinary ranged-enemy classification is not the cause.
- Current boss speeds are 181.25–230 while the player reaches 347.2 without dash. The boss cannot catch a continuously moving upgraded player.
- Stage 5 boss uses three 120-degree shield sectors, and boss presentation normally faces the player. After the front sector breaks, the remaining side/rear sectors rarely affect incoming player fire.
- Stage 3 boss currently blocks 90% damage across a 110-degree frontal arc without a normal shield-down window, which explains its disproportionate difficulty.
- Active weapon resources and previews currently encode damage as a first-class upgrade axis. The damage field and damage calls must be removed, not retained at zero.
- `VehicleStatusRuntime` already owns enemy slow state. Extend that owner for active-weapon slow instead of adding a competing status system.
- `docs/product/vehicle_game_spec.md`, `docs/design/VISUAL_SYSTEM.md`, and their validation scripts are canonical consumers that must change with the runtime contract.
- External research is intentionally skipped: this is a self-contained product decision, and current code/spec evidence resolves the implementation owners and failure causes.

## Locked Balance Contract

| Weapon | Level range/size | Level cooldown | Level control duration | Level strength/auxiliary |
| --- | --- | --- | --- | --- |
| EMP | 285 / 325 / 365 / 405 radius | 13.0 / 11.7 / 10.4 / 9.1 s | 1.4 / 1.8 / 2.2 / 2.6 s stun | projectile-clear radius 325 / 365 / 405 / 445 |
| Black Hole | 180 / 220 / 260 / 300 radius | 12.0 / 10.8 / 9.6 / 8.4 s | 1.6 / 2.0 / 2.4 / 2.8 s field and slow | 25% / 30% / 35% / 40% slow; ordinary-enemy pull only |
| Shockwave | 200 / 240 / 280 / 320 radius | 9.0 / 8.1 / 7.2 / 6.3 s | 0.35 / 0.50 / 0.65 / 0.80 s stagger | 180 / 220 / 260 / 300 push; mobile ordinary-enemy push only |
| Cross Beam | 28 / 40 / 52 / 64 half-width | 10.5 / 9.4 / 8.3 / 7.2 s | 1.5 / 2.0 / 2.5 / 3.0 s slow | 25% / 30% / 35% / 40% slow |

- Boss control duration is 50% of authored duration, matching existing boss chill resistance.
- EMP stuns and clears hostile projectiles. Black Hole pulls ordinary mobile enemies and slows every targetable enemy. Shockwave pushes ordinary mobile enemies and staggers every targetable enemy. Cross Beam slows enemies in its map-spanning cross and does not damage facilities.
- Stun/stagger pauses boss movement and behavior for its resistant duration. Slow changes movement speed only, not boss attack timers.
- Boss base health changes from 5,200 to 26,000 while existing stage multipliers remain.
- Boss speeds become 380 / 395 / 410 / 425 / 440 / 455 / 470 / 485.
- Boss movement approaches above 240 px, strafes from 140–240 px, and retreats only below 140 px.
- Stage 3 boss frontal intercept changes from a 55-degree half-angle and 90% block to a 35-degree half-angle and 50% block. Stage 5 boss shield kind becomes `none`.

## Execution Checklist

- [x] Update canonical product/design contracts and active-weapon resource schema; migrate all four resources and runtime snapshots to range, duration, strength, and cooldown.
- [x] Replace every active-weapon damage path with bounded CC application, including boss resistance and boss stun/slow integration.
- [x] Increase boss health/speed, change its close-pressure movement band, weaken Stage 3 boss shielding, and remove Stage 5 boss relay shielding.
- [x] Update Korean/English descriptions, upgrade previews, and Ship Status rows so all visible claims match the CC-only contract.
- [x] Update focused validators and validate imports, runtime contracts, affected rendered UI in Korean and English, visual authority, and Web export without run-result measurement.

## Validation Contract

- Import and parse through `./tools/godot.ps1` before focused validators.
- Active weapon: `validate_vehicle_active_weapons.gd`, `validate_vehicle_weapon_balance_contract.gd`, `validate_vehicle_active_recharge.gd`, and `validate_vehicle_damage_feedback.gd`.
- Status and boss: `validate_vehicle_status_stacking.gd`, `validate_vehicle_boss_exams.gd`, `validate_vehicle_boss_patterns.gd`, `validate_vehicle_eight_boss_campaign.gd`, `validate_vehicle_eight_cycle_catalog.gd`, and `validate_vehicle_run_difficulty.gd`.
- UI/localization: `validate_vehicle_upgrade_ui.gd`, `validate_vehicle_stage_ui_layout.gd`, and `validate_vehicle_ui_localization.gd`; render affected upgrade and Ship Status surfaces in both languages using the existing harness.
- Visual governance: `./tools/validation/validate_cardborne_visual_authority.ps1`.
- Final broad gate: Web export and production-style built smoke path if the repository harness supports it. Stop after functional readiness; do not collect elapsed-run or kill-count outcome measurements.

## Progress Notes

- 2026-08-18: Created from current code, product spec, design authority, and the user's revised combat direction. Existing quotas are explicitly outside this implementation.
- 2026-08-18: Canonical specs, four active resources, and the active definition/runtime contract now contain no active-weapon damage axis. Godot 4.7.1 imports the migrated resources and scripts successfully.
- 2026-08-18: EMP, Black Hole, Shockwave, and Cross Beam now mutate only bounded control state or projectile clearance. Boss slow/stagger resistance is integrated, boss behavior pauses during stagger, and no active-weapon enemy/facility damage call remains. Focused active, status, and balance validators pass.
- 2026-08-18: Boss health is five times the prior baseline, movement exceeds maximum non-dash player speed, and the dedicated movement band now closes to 140–240 px. Stage 3 boss alone retains a 70-degree, 50% frontal intercept; Stage 5 boss relay state is removed. Shield, campaign, difficulty, and boss-pattern validators pass.
- 2026-08-18: Active offers now show range, control duration, and cooldown as three compact values; Ship Status replaces active damage with range and duration while retaining cooldown. Korean and English layout/localization validators pass. Final 1280x720 captures are retained under `.agents/evidence/2026-08-18-control-active-weapons/{ko-final-1280,en-final-1280}` and show all three offer values without clipping.
- 2026-08-18: Final focused combat, boss, UI, localization, capture-driver, visual-authority, import, and Web export gates pass. The built Web index returned HTTP 200 on the fastrun-manager Codex port and the task-owned server was stopped. No run-duration, defeat-count, or performance qualification measurement was performed.
- 2026-08-18: The diff-scoped quality audit found no competing owner or responsibility creep. It corrected center-overlap Shockwave stagger handling and removed obsolete shield-restored capture paths before final validation.
