---
type: plan
status: active
owner: BK
created: 2026-08-19
last_reviewed: 2026-08-19
topic: Simplify ordinary enemy movement to direct player pursuit
scope: Ordinary-enemy movement policy, movement targeting, focused validators, and supporting product documentation
related:
  - ../../docs/product/ordinary_enemy_behavior.md
  - ../../scripts/enemies/vehicle_enemy_movement_policy.gd
  - ../../scripts/enemies/vehicle_enemy_targeting_policy.gd
  - ../../tools/validation/validate_vehicle_enemy_movement_policy.gd
  - ../../tools/validation/validate_vehicle_enemy_targeting_policy.gd
---

# Simplify Ordinary Enemy AI - Execution Checklist

## Goal

Replace the overdesigned default movement behavior of ordinary enemies with one
clear rule: mobile ordinary enemies seek the player's current craft position,
while the existing attack owners decide when and how an attack can start.

## Scope

In scope:

- Default movement-family resolution for mobile ordinary enemies.
- Movement direction and movement-target prediction.
- Blocked-route fallback and local collision separation.
- Focused validators for movement and targeting.
- A canonical product note that records the decision and external references.

Out of scope:

- Attack ranges, startup, cooldown, damage, projectile behavior, or telegraphs.
- Fixed installations, boss behavior, encounter composition, spawn pacing, UI,
  visuals, localization, progression, or save data.
- Removing authored committed-attack movement or collective attack execution.
- Performance claims that require a profiler or full-load benchmark.

## Evidence and Decision

- [x] Read `AGENTS.md` and `.agents/PLANS.md`.
- [x] Inspect the current movement policy, movement targeting, runtime call path,
  and focused validators.
- [x] Confirm that the current policy contains four mobile movement families,
  role-specific distance bands, tangential strafing, retreat, predictive
  movement lead, and line-of-fire recovery.
- [x] Review external references for seek steering, navigation/avoidance
  separation, and survivor-style direct pursuit.
- [x] Select direct seek as the default mobile ordinary-enemy behavior.
- [x] Preserve attack ownership and fixed/boss exceptions.

## Implementation

- [ ] Map every mobile ordinary archetype to the pursuit family.
- [ ] Remove active distance-band, retreat, orbit, escort, support-positioning,
  and line-of-fire-recovery decisions from the default movement policy.
- [ ] Make movement target the player's current position without prediction.
- [ ] Preserve route guidance only when the direct path is blocked.
- [ ] Preserve local separation, velocity smoothing, and speed caps.
- [ ] Keep attack-target prediction unchanged.

## Validation

- [ ] Update the movement-policy validator for direct pursuit and fixed actors.
- [ ] Update the targeting-policy validator for unpredicted movement and bounded
  predictive attacks.
- [ ] Run repository diff review and focused contract review.
- [ ] Run the repository pull-request validation workflow.
- [ ] Record the validation result and mark this plan `done`.

## Acceptance Criteria

- Every mobile ordinary archetype resolves to `pursuit`.
- Fixed ordinary installations and bosses resolve to `stationary`.
- A mobile ordinary enemy's desired direction is the normalized vector from its
  position to the player's current position.
- Strafe sign, old range bands, attack recovery flags, and firing-lane blockage
  do not change the default seek direction.
- Blocked direct pursuit may request existing route guidance.
- Attack contracts, predictive attack aim, fixed threats, bosses, and committed
  authored attacks remain unchanged.
- Focused validators and the pull-request workflow pass.

## Progress

- Current phase: Implementation.
- Next task: Replace the movement and movement-target policies, then update the
  focused validators.
- Canonical progress ledger: The checkboxes in this file.
