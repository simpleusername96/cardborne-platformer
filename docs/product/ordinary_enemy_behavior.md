---
type: spec
status: active
owner: BK
created: 2026-08-19
last_reviewed: 2026-08-19
canonical_for: Default ordinary-enemy movement and attack ownership
scope: Mobile and fixed ordinary enemies in the current vehicle run
related:
  - ./vehicle_game_spec.md
  - ../../scripts/enemies/vehicle_enemy_movement_policy.gd
  - ../../scripts/enemies/vehicle_enemy_targeting_policy.gd
  - ../../.agents/execplans/2026-08-19-simplify-ordinary-enemy-ai.md
---

# Ordinary Enemy Behavior

## Decision

A mobile ordinary enemy has one default movement goal: seek the player's current
craft position.

The attack system remains separate. Each role keeps its existing attack range,
startup, cooldown, damage, projectile, telegraph, and commitment rules. When an
attack owner says the enemy can attack, that authored attack executes. Otherwise
the enemy continues seeking the player.

## Runtime Contract

- Every mobile ordinary archetype resolves to the `pursuit` movement family.
- Fixed ordinary installations and bosses remain `stationary`.
- Default movement uses the normalized vector from the enemy to the player's
  current position. It does not lead the player's velocity.
- Existing route guidance may replace the direct vector only when a wall blocks
  the direct path.
- Existing local separation, wall collision, velocity smoothing, update cadence,
  and speed caps remain movement safety mechanisms.
- Default movement has no role-specific standoff band, retreat band, orbit,
  escort position, support position, tangential firing-lane recovery, or
  movement prediction.
- Predictive targeting remains legal inside attack commitment. It is not used to
  choose the ordinary enemy's default movement destination.
- A committed authored attack or collective attack execution may temporarily
  override default pursuit. This is attack execution, not a persistent movement
  family.

## Why This Replaces the Previous Design

The previous policy encoded four mobile movement families, nine distance bands,
tangential strafing, close-range retreat, role-specific recovery, predictive
movement lead, and line-of-fire repositioning. Those decisions duplicated facts
already owned by attack contracts and could keep an enemy repositioning instead
of presenting a readable threat.

The simpler contract keeps role identity where the player can observe it:
attacks, warning timing, projectile behavior, contact rules, durability, and
support effects. Movement only delivers the enemy into those attack conditions.

## External References

The implementation adapts these references without copying their architecture:

- Craig Reynolds, *Steering Behaviors For Autonomous Characters* (GDC 1999):
  https://www.red3d.com/cwr/steer/gdc99/
  - Accepted: separate action selection, steering, and locomotion; use `seek` as
    a desired velocity toward a target; keep obstacle avoidance separate.
  - Rejected: layering additional pursuit, offset-pursuit, flocking, or blended
    steering into ordinary role identity before gameplay proves a need.
- GDQuest Vampire Survivor open-source port:
  https://github.com/paulfioravanti/gdquest-vampire-survivor/blob/main/mob.gd
  - Accepted: a survivor-style mob can remain effective with a direct
    `direction_to(player)` movement rule.
  - Rejected: copying its actor structure or replacing Cardborne's existing
    spatial grid, collision, attack, and pooling owners.
- Godot `NavigationAgent2D` documentation:
  https://docs.godotengine.org/en/stable/classes/class_navigationagent2d.html
  - Accepted: target selection, path following, and avoidance are separable
    responsibilities.
  - Rejected: introducing a new navigation dependency when the current route
    and local-steering owners already provide the required safety behavior.
- Manual Vampire Survivors ranged-enemy example:
  https://github.com/IgorMianowany/Manual-Vampire-Survivors/blob/56dbb8d2c1de38997cd4cd1a6ed3e5d737c64bd5/skeleton_archer.gd
  - Accepted: movement and attack gating can remain separate.
  - Rejected: its retreat and standoff band, because that would restore the
    complexity removed by this decision.

## Preserved Product Constraints

- Manual player aim and target prioritization remain central.
- Ordinary and fixed threats remain continuously interactive.
- Hostile attacks retain readable startup and collision truth.
- Terrain still blocks actors and projectiles according to the existing product
  contract.
- Traversal does not require defeating every living ordinary enemy.
- No UI, visual, localization, progression, encounter, or save-data behavior
  changes under this specification.

## Reassessment Rule

Add a new default movement behavior only after a recorded playtest shows a
specific failure that cannot be corrected through attack range, startup,
cooldown, speed, spawn placement, or obstacle routing. The new behavior must
solve that named failure and receive its own focused validator.
