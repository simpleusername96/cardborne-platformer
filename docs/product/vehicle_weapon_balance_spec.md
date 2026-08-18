---
type: spec
status: active
owner: BK
created: 2026-08-12
last_reviewed: 2026-08-18
scope: Primary fire, two unrestricted attributes, automatic weapons, and active weapons
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
| Attribute | Thermal Burst | Immediate damage to a nearby cluster after a primary hit |
| Attribute | Bio Toxin | Sustained damage after repeated application |
| Attribute | Cryo Slow | Stacking movement control followed by a three-stack shatter |
| Auto weapon | Seeker | Reliable automatic ranged damage |
| Auto weapon | Electric Field | Continuous close area pressure |
| Auto weapon | Orbiting Blades | High-exposure contact damage and interception |
| Auto weapon | Drop Mines | Route and pursuit punishment |
| Auto weapon | Auto Laser | Automatic line selection through dense enemies |
| Auto weapon | Storm Barrage | Distant clustered ordinary-enemy damage |
| Active | EMP | Reliable emergency control and projectile clearing |
| Active | Black Hole | Remote grouping followed by delayed area damage |
| Active | Shockwave | Frequent close defense and knockback |
| Active | Cross Beam | Map-spanning, cover-piercing aimed damage |

## Authored values

### Primary and attributes

| Family | Levels | Damage or control | Coverage or count |
| --- | --- | --- | --- |
| Split Muzzle | L1-L6 | Total volley damage 140% / 155% / 165% / 184% / 204% / 234% | 2 / 2 / 3 / 3 / 3 / 3 projectiles, side angle ±7° |
| Piercing Rounds | L1-L7 | Base projectile damage 105% / 111% / 118% / 126% / 135% / 145% / 156% | 1 / 1 / 2 / 2 / 3 / 3 / 4 additional penetrations |
| Thermal Burst | L1-L7 | 4 / 6 / 8 / 9 / 11 / 12 / 14 damage per affected target | Radius 72 / 79 / 86 / 93 / 100 / 108 / 115 |
| Bio Toxin | L1-L7 | 2 / 2.8 / 3.6 / 4.4 / 5.2 / 6.1 / 7 DPS per stack | Three stacks; duration 5 / 5.6 / 6.2 / 6.8 / 7.4 / 8 / 8.4 seconds |
| Cryo Slow | L1-L6 | 4% / 6% / 8% / 9% / 11% / 12% slow per stack; 18 / 25 / 32 / 39 / 47 / 55 damage on third-stack shatter | Duration 1.8 / 2.2 / 2.6 / 3 / 3.3 / 3.6 seconds |

A run may equip any two distinct attributes in first-acquisition order. A third distinct
attribute is blocked, while either equipped attribute remains levelable.

### Secondary weapons

| Weapon | States | Damage | Cadence | Coverage or count |
| --- | --- | --- | --- | --- |
| Seeker | L1-L7 | 25 / 31 / 37 / 43 / 50 / 57 / 64 per missile | 1.35 / 1.29 / 1.23 / 1.17 / 1.11 / 1.06 / 1.01 seconds | 2 / 2 / 3 / 3 / 4 / 4 / 4 missiles |
| Electric Field | L1-L7 | 8 / 13 / 18 / 24 / 29 / 35 / 40 per tick | 0.250 / 0.240 / 0.229 / 0.219 / 0.208 / 0.198 / 0.188-second ticks | Radius 240 / 253 / 267 / 280 / 293 / 307 / 320 |
| Orbiting Blades | L1-L7 | 14 / 20 / 26 / 32 / 38 / 44 / 51 per blade contact | 0.55 / 0.53 / 0.51 / 0.49 / 0.46 / 0.44 / 0.41-second lockout | 2 / 2 / 3 / 3 / 4 / 4 / 4 blades; orbit radius 112; angular speed 3.4 rad/s |
| Drop Mines | L1-L7 | 48 / 67 / 86 / 104 / 123 / 142 / 160 per target | 3.20 / 2.97 / 2.73 / 2.50 / 2.27 / 2.03 / 1.80 seconds | 3 / 3 / 4 / 4 / 5 / 5 / 5 live mines; blast radius 192 / 204 / 216 / 228 / 240 / 240 / 240 |
| Auto Laser | L1-L6 | 48 / 70 / 92 / 114 / 136 / 157 per target on the selected line | 0.90 / 0.84 / 0.78 / 0.72 / 0.66 / 0.60 seconds | Length 760; half-width 18 |
| Storm Barrage | L1-L6 | 70 / 102 / 133 / 165 / 196 / 228 per target | 4.50 / 4.14 / 3.78 / 3.42 / 3.06 / 2.70 seconds | Radius 280; targets clusters 480-960 units away |

### Active weapons

| Weapon | Levels | Damage | Size | Startup | Cooldown | Reliability and control |
| --- | --- | --- | --- | --- | --- | --- |
| EMP | L1-L7 | Runtime-owned | Radius 285 / 315 / 345 / 375 / 405 / 435 / 465 | 0.42 | 13 / 12.3 / 11.6 / 10.9 / 10.2 / 9.5 / 8.8 | Omnidirectional stun and projectile clearing; duration 1.4-2.6 seconds |
| Black Hole | L1-L7 | Runtime-owned | Radius 180 / 200 / 220 / 240 / 260 / 280 / 300 | 0.35 | 12 / 11.4 / 10.8 / 10.2 / 9.6 / 9 / 8.4 | Remote grouping; duration 1.6-2.8 seconds; strength 0.25-0.40 |
| Shockwave | L1-L7 | Runtime-owned | Radius 200 / 220 / 240 / 260 / 280 / 300 / 320 | 0.20 | 9 / 8.55 / 8.1 / 7.65 / 7.2 / 6.75 / 6.3 | Close knockback; duration 0.4-1.0 seconds |
| Cross Beam | L1-L7 | Runtime-owned | Half-width 28 / 34 / 40 / 46 / 52 / 58 / 64 | 0.30 | 10.5 / 9.95 / 9.4 / 8.85 / 8.3 / 7.75 / 7.2 | Map-spanning, cover-piercing; duration 1.5-3.0 seconds |

Cross Beam uses its exact half-width for collision and active presentation. Startup
shows only source state and does not expose the future map-spanning corridors. Its
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

- A numeric level must improve its intended job by at least 5% and at most 50%.
- A discrete projectile, blade, mine, target, or penetration breakpoint can replace
  the numeric minimum. The added count cannot exceed 65% of the resulting count and
  cannot arrive with a separate damage or cadence increase above 50%.
- Equal-investment peers with the same role stay within 20% intended damage unless
  a named restriction, control benefit, reliability difference, safety difference,
  or targeting burden explains the gap.
- A same-slot option cannot equal or exceed another option in damage, coverage,
  reliability, control, safety, and cadence with at least one strict advantage.
- Each weapon level owns its final damage, cadence, and size values; there are no shared weapon modifiers.
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
