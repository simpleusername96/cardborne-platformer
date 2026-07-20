---
type: evidence
status: active
created: 2026-07-21
source: Owner discussion on 2026-07-20 and 2026-07-21
topic: Latest vehicle-led manually targeted shooter hypothesis
related:
  - ./README.md
  - ../../../docs/research/vehicle_led_isometric_action_reference_analysis.md
  - ../../../docs/design/concepts/vehicle-led-isometric/01-exploration.png
  - ../../../docs/design/concepts/vehicle-led-isometric/02-combat.png
  - ../../../docs/design/concepts/vehicle-led-isometric/03-boss-build.png
---

# Latest Product Hypothesis

## Purpose

Capture the newest design direction without falsely promoting it to an accepted
product spec. This document separates confirmed owner preferences from agent
recommendations and unresolved owner decisions.

## Sources

- Owner feedback recorded in
  [01-owner-feedback-history.md](./01-owner-feedback-history.md).
- Reference analysis in
  [vehicle_led_isometric_action_reference_analysis.md](../../../docs/research/vehicle_led_isometric_action_reference_analysis.md).
- Local concepts:
  [exploration](../../../docs/design/concepts/vehicle-led-isometric/01-exploration.png),
  [combat](../../../docs/design/concepts/vehicle-led-isometric/02-combat.png), and
  [boss/build](../../../docs/design/concepts/vehicle-led-isometric/03-boss-build.png).

## Findings

### Confirmed owner preferences

- Replace the animation-heavy humanoid action set with a vehicle-led combat
  fantasy if the vehicle proof is fun.
- Keep controls simple and shooter-like.
- Preserve Space dash. Dash is both an evasive and potentially offensive verb.
- The primary weapon is rapid, directly aimed, and fired by the player.
- The secondary weapon is passive: it auto-targets nearby enemies or fires on a
  fixed cadence.
- Equip only one active cooldown skill initially; `Z` triggers a powerful area
  attack.
- A separate held guard is not currently required. Its value must be proven
  rather than inherited from the humanoid proof.
- Manual target selection is the main distinction from a Vampire Survivors-style
  auto-combat game. The map must contain threats worth destroying early.
- Moving enemies coexist with fixed turrets, proximity attackers, traps, barrier
  generators, spawners, or other dangerous installations.
- Field pickups create immediate effects: repair/heal, damage boost, speed and
  ramming, and a barrier/repulsion state.
- Chests or stage completion offer several cards for new equipment, equipment
  upgrades, or behavior changes.
- Exploration and combat occur in one map. Field bosses and dedicated stage
  bosses are separate categories.
- Exploration puzzles and a broad exploration pillar are deferred. Crates and
  loose resources alone are not enough to claim meaningful exploration.
- The first deliverable is one complete stage, not a content roadmap.

### Recommended combat identity

The best current synthesis is a **manually targeted vehicle arena shooter with
passive support fire and card-based run upgrades**.

Its recurring decision is not merely whether to survive a crowd. The player uses
movement, line of sight, range, and dash to decide what danger to remove first:

- shoot a close chaser or preempt a distant turret;
- destroy a spawner or secure a healing pickup;
- break a barrier generator or dash through the exposed lane;
- leave fodder to passive weapons while focusing an elite weak point;
- spend the `Z` area skill now or save it for the next pressure spike.

### Minimal control hypothesis

| Intent | Proposed input | Status |
| --- | --- | --- |
| Move | Arrow keys or `WASD` | Input family unresolved |
| Aim | Mouse, right stick, or bounded keyboard target selection | Material decision unresolved |
| Rapid primary fire | Left click or Left Shift | Exact binding unresolved |
| Dash | Space | Required |
| Area skill | `Z` | Preferred |
| Passive secondary | No direct button | Required behavior |
| Interact | Automatic proximity or one key | Low-risk implementation detail |
| Pause/settings | Esc | Retained convention |

Manual aiming must permit early destruction of dangerous map elements. If a
keyboard-only path is supported, bounded assistance must preserve deliberate
target priority and line of sight rather than always choosing the nearest enemy.

### Stage-one hypothesis

One continuous authored field should be large enough not to fit in one screen and
should contain:

1. A short deployment/loadout moment with two meaningfully different primaries.
2. An open first encounter teaching movement, rapid fire, and dash.
3. A mixed encounter combining chasers, shooters, and one fixed installation.
4. A chest choice that visibly changes the next fight.
5. A riskier branch containing a bypassable field boss and stronger module.
6. A transition into a dedicated boss arena whose fight alone locks the exit.
7. A result screen returning the player to a compact base/garage or replay flow.

Ordinary progression must never require exterminating every living enemy. A room
may use an explicit objective, destroyable key installation, survival timer,
activation, or open traversal.

### Weapon and upgrade roles

- **Primary:** expresses target priority and preferred range. Initial examples:
  rapid repeater and impact cannon.
- **Passive secondary:** reduces cleanup burden and completes a build. Initial
  examples: auto-missile, orbiting drone, or projectile-intercept drone.
- **`Z` skill:** creates one deliberate high-impact moment. Initial example: a
  telegraphed radial shockwave or targeted bombardment.
- **Run cards:** change behavior rather than primarily add percentages. Examples:
  ricochet, piercing, spread, dash trail, perfect-dash pulse, stagger refund, or
  passive-fire trigger bridges.
- **Field pickups:** temporary tactical states, visually readable without opening
  inventory.

### Enemy and map roles

- Chaser: removes stationary safety and is vulnerable to timely dash/ram play.
- Mobile shooter: creates projectile lanes; ordinary shots stop on cover.
- Controller: creates temporary denied space with strict concurrency limits.
- Fixed turret: rewards early manual targeting and line-of-sight management.
- Proximity trap: changes safe routes but must telegraph activation and recovery.
- Support installation: shields, repairs, enables, or spawns other threats and
  therefore changes target priority.
- Field boss: optional, escapable, and rewards risk.
- Stage boss: dedicated arena, clear startup/active/recovery grammar, and a
  learned-rule payoff rather than a pure health sponge.

### Base/garage hypothesis

A base is useful only if it creates a clear separation between fast combat
choices and slower loadout decisions. A compact one-screen garage can support:

- primary, passive secondary, and `Z` skill selection;
- vehicle/module inspection;
- repair and permanent unlock decisions;
- next-stage selection and deployment;
- settings, codex, and tutorial access.

It should not become a large walking map, an NPC errand route, or a repair-cost
punishment that blocks play. The first proof may use a functional garage screen
instead of a traversable base map.

### Perspective alternatives still open

**Hybrid isometric:** simulate all movement, collision, projectiles, and targeting
on one 2D ground plane while rendering an oblique/isometric world. This preserves
the drowned-ruin identity but requires strict occlusion and aiming readability.

**Flat top-down 2D:** maximizes aiming, collision, asset, and camera clarity and is
cheaper to produce, but gives up some visual identity and invalidates more current
world art.

No implementation should proceed as though this choice has been made.

## Recommendations

- Ask the owner to accept the product identity and the four material choices:
  perspective, aiming input, base scope, and defense/resource model.
- If accepted, promote the result into a replacement active product spec and a
  new decision-complete graybox plan.
- Test movement and aiming for sixty seconds without rewards before producing
  equipment breadth or another visual set.
- Require the two initial primaries to create different ranges and routes.
- Require the first card choice to visibly change the immediately following
  encounter.

## Limitations

- This hypothesis is not an accepted spec.
- Exact stage duration, arena metrics, movement physics, aim model, fire cadence,
  cooldowns, health values, and upgrade pool are not locked.
- The existing three images communicate direction, not production-ready assets
  or exact level geometry.
