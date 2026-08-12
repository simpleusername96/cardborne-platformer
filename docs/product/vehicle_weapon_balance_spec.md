---
type: spec
status: active
owner: BK
created: 2026-08-12
last_reviewed: 2026-08-12
canonical_for: Cardborne vehicle weapon roles, authored balance values, and deterministic comparison rules
scope: Primary fire, damage and utility attributes, built-in and optional secondary weapons, and active weapons
related:
  - ./vehicle_game_spec.md
  - ./vehicle_upgrade_catalog.md
---

# Vehicle Weapon Balance Specification

## Purpose

This specification keeps each weapon useful without collapsing different jobs into
one score. Damage, cadence, coverage, reliability, control, targeting burden, and
player exposure remain separate comparison axes. Runtime resources own the values;
`validate_vehicle_weapon_balance_contract.gd` checks those resources against this
contract with pure data and geometry.

The unupgraded primary deals 18 damage every 0.12 seconds, or 150 raw DPS. This is
only a normalization point. It is not a target that every automatic or area weapon
must match.

## Canonical roles

| Slot | Family | Intended job |
| --- | --- | --- |
| Primary | Base primary | Reliable manual sustained damage to one target |
| Primary | Split Muzzle | Wider lane coverage with less reliable side shots |
| Primary | Piercing Rounds | Aligned multi-target damage that rewards positioning |
| Damage attribute | Thermal Burst | Immediate damage to a nearby cluster after a primary hit |
| Damage attribute | Bio Toxin | Sustained damage after repeated application |
| Utility attribute | Cryo Slow | Movement control without raw damage |
| Utility attribute | Shock Disruption | Attack-start control without raw damage |
| Built-in secondary | Seeker | Reliable automatic ranged damage |
| Optional secondary | Electric Field | Continuous close area pressure |
| Optional secondary | Orbiting Blades | High-exposure contact damage and interception |
| Optional secondary | Drop Mines | Route and pursuit punishment |
| Optional secondary | Auto Laser | Automatic line selection through dense enemies |
| Optional secondary | Storm Barrage | Distant clustered ordinary-enemy damage |
| Active | EMP | Reliable emergency control and projectile clearing |
| Active | Black Hole | Remote grouping followed by delayed area damage |
| Active | Shockwave | Frequent close defense and knockback |
| Active | Cross Beam | Map-spanning, cover-piercing aimed damage |

## Authored values

### Primary and attributes

| Family | Levels | Damage or control | Coverage or count |
| --- | --- | --- | --- |
| Split Muzzle | L1-L3 | Total volley damage 140% / 165% / 180% | 2 / 3 / 3 projectiles, side angle ±7° |
| Piercing Rounds | L1-L4 | Base projectile damage is unchanged | 1 / 2 / 3 / 4 additional penetrations |
| Thermal Burst | L1-L4 | 4 / 5.75 / 8 / 11 damage per affected target | Radius 72 / 84 / 96 / 96 |
| Bio Toxin | L1-L4 | 2 / 2.85 / 4 / 5.5 DPS per stack | Three stacks; duration 5 / 6 / 7 / 7 seconds |
| Cryo Slow | L1-L3 | 6% / 8% / 10% slow per stack | Duration 2 / 2.5 / 3 seconds |
| Shock Disruption | L1-L3 | 0.6 / 0.8 / 1.0 second attack lock | Attack-start control only |

### Secondary weapons

| Weapon | States | Damage | Cadence | Coverage or count |
| --- | --- | --- | --- | --- |
| Seeker | Base, L1-L3 | 25 / 28 / 32 / 38 per missile | 1.35 seconds | 2 / 3 / 4 / 4 missiles |
| Electric Field | L1-L4 | 8 / 11.5 / 16 / 22 DPS | 0.25-second ticks | Radius 120 / 140 / 160 / 160 |
| Orbiting Blades | L1-L4 | 14 / 18 / 22 / 28 per blade contact | 0.55-second target lockout | 2 / 3 / 4 / 4 blades; orbit radius 88 |
| Drop Mines | L1-L4 | 48 / 60 / 72 / 88 per target | 3.2 / 2.8 / 2.4 / 2.4 seconds | 3 / 4 / 5 / 5 live mines; blast radius 96 / 108 / 120 / 120 |
| Auto Laser | L1-L3 | 48 / 66 / 86 per target on the selected line | 0.9 seconds | Length 760; half-width 18 |
| Storm Barrage | L1-L3 | 70 / 95 / 125 per target | 4.5 seconds | Radius 140; targets clusters 480-960 units away |

### Active weapons

| Weapon | Levels | Damage | Size | Startup | Cooldown | Reliability and control |
| --- | --- | --- | --- | --- | --- | --- |
| EMP | Base | 62 | Damage radius 285; projectile clear 325 | 0.42 | 13.0 | Omnidirectional stun and projectile clear |
| Black Hole | L1-L4 | 60 / 85 / 115 / 150 | Radius 150 / 175 / 200 / 225 | 0.35 | 12.0 | Remote grouping, 1.2-second active pull, delayed collapse |
| Shockwave | L1-L4 | 45 / 65 / 90 / 120 | Radius 180 / 210 / 240 / 270 | 0.20 | 9.0 | Close knockback and frequent defensive use |
| Cross Beam | L1-L4 | 80 / 110 / 145 / 185 | Half-width 24 / 32 / 40 / 48 | 0.30 | 10.5 | Map-spanning, cover-piercing, one hit per target |

Cross Beam uses its exact half-width for both the startup cue and collision. Its
greater damage and shorter cooldown compensate for manual alignment, while its
wider level progression raises multi-target reliability without removing that
aiming requirement.

## Deterministic fixtures

The validator does not start a gameplay scene. It uses five fixed point sets:

1. One large target 480 units away for boss damage, startup, cooldown, and restrictions.
2. Eight targets on the aim axis for piercing and line weapons.
3. Twelve targets inside 285 units for EMP, fields, mines, and Thermal Burst.
4. Thirty-two dispersed targets for automatic selection and global coverage.
5. Eight targets around the hull for blades, close defense, and movement control.

Every approved state emits separate fields for damage per use, damage over ten
seconds, distinct contacts, startup, cooldown, coverage, control, targeting burden,
and exposure. A qualitative axis can justify a damage difference, but it cannot be
converted into hidden damage points.

## Adjustment rules

- A numeric level must improve its intended job by at least 15% and at most 45%.
- A discrete projectile, blade, mine, target, or penetration breakpoint can replace
  the numeric minimum. The added count cannot exceed 65% of the resulting count and
  cannot arrive with a separate damage or cadence increase above 45%.
- Equal-investment peers with the same role stay within 20% intended damage unless
  a named restriction, control benefit, reliability difference, safety difference,
  or targeting burden explains the gap.
- A same-slot option cannot equal or exceed another option in damage, coverage,
  reliability, control, safety, and cadence with at least one strict advantage.
- Shared damage and cooldown modifiers apply once after authored base values.
- Reliability problems are corrected in this order: cue/collision agreement, width
  or radius, targeting, cooldown, then damage.
- Numeric corrections use the smallest practical five-percent step that enters the
  accepted band. Only one axis changes per failed iteration unless cue and collision
  must change together.

## Active combat recharge

Active weapons also gain cooldown from accepted combat actions. One direct primary,
secondary, or dash action that damages one or more enemies removes 0.10 seconds once
for its action ID. Periodic field or dash damage removes 0.025 seconds once per tick
identity. Outgoing recharge is limited to 0.40 seconds per real second, including a
0.10-second periodic sub-limit. One hostile hit that removes barrier or hull removes
0.20 seconds and starts a 1.25-second lockout.

Active self-damage, poison or other status ticks, derived Thermal Burst damage,
reflection, structures, devices, and zero-damage events give no recharge. A ready
active weapon discards credits instead of storing them. Coolant and map relay effects
modify the normal cooldown once; combat recharge then subtracts exact seconds from
the remaining cooldown.
