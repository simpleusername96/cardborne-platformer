---
type: spec
status: draft
source: User request on 2026-07-01; docs/design/MAP_DATA_AND_VISUALIZATION.md
scope: Preimplementation procedural region graph generation
---

# Procedural Region Generation

## Purpose

Define how Cardborne Platformer should generate a similar-feeling exploration map each run while changing the actual room order, side paths, reward positions, and local traversal shape.

The target is not a fully random maze. The target is a controlled region generator:

- same approximate difficulty,
- same completion requirements,
- same boss outcome,
- different room graph and local route texture per seed.

## Scope

This applies to first-slice map planning before Godot runtime implementation.

It adds a procedural layer above authored room templates:

1. Generate a **mission graph**: what the player must do.
2. Generate a **region graph**: where rooms connect.
3. Assign **room roles**: combat, traversal, shop, rest, key, gate, reward, boss.
4. Assign **difficulty and reward budgets**.
5. Later implementation maps each generated room role to an authored Godot room template.

## Design Principle

For a Silksong/Hollow Knight-like structure, the generator should not start by placing tiles. It should first place intentions.

Good order:

```text
run seed
 -> region profile
 -> mission graph
 -> room graph
 -> gate/key/shortcut validation
 -> room template selection
 -> encounter/reward budget placement
 -> Godot room scene assembly
```

Bad order:

```text
random tiles
 -> hope it is fun and winnable
```

## Requirements

- Use a deterministic seed so a generated region can be reproduced.
- Keep generation controlled by data in `data/design/first_slice/procedural_region_rules.json`.
- Guarantee a playable critical path from entrance to boss.
- Include at least one lock/key or route-gate relationship in the first slice.
- Include at least one shortcut that reconnects later progress to an earlier hub or shaft.
- Include one safe room with rest/shop function.
- Include optional reward rooms that are not required for boss access.
- Keep total reward, enemy, and hazard budget inside the selected difficulty band.
- Keep boss access gated by the intended condition, not by accidental geometry.
- Output generated region examples as JSON and SVG for review.

## Canonical Terms

- **Seed**: Integer or string used to reproduce a generated region.
- **Region Profile**: Data contract for a generated area, such as room count, required specials, difficulty curve, and biome flavor.
- **Mission Graph**: Abstract progression requirements: start, find key, open gate, unlock shortcut, reach boss.
- **Region Graph**: Connected rooms and exits that realize the mission graph.
- **Room Role**: The primary job of a room: entrance, combat, traversal, key, gate, shop, rest, reward, shortcut, boss approach, boss.
- **Critical Path**: Required route from entrance to boss.
- **Side Branch**: Optional route for rewards, resources, challenge, or discovery.
- **Gate**: A rule that blocks progress until a requirement is met. First-slice gates may be key-based; future gates may require movement abilities.
- **Shortcut**: A connection that opens from the far side after progress, reducing backtracking.
- **Budget**: Numerical target for danger, rewards, verticality, and length.

## First-Slice Algorithm

Use a controlled graph generator:

1. Pick a region profile.
2. Create a critical path with fixed role anchors:
   - entrance,
   - early combat,
   - vertical traversal,
   - locked gate,
   - boss approach,
   - boss.
3. Place a key room on a side branch reachable before the locked gate.
4. Place a safe room near the early or mid region.
5. Place one or more optional reward branches.
6. Place a shortcut from a later room back to the hub/shaft.
7. Assign coordinates to rooms with vertical bias.
8. Assign difficulty budgets increasing along the critical path.
9. Validate:
   - all rooms reachable,
   - key before gate,
   - boss after gate,
   - shortcut does not skip required key/gate sequence before it is unlocked,
   - counts and budgets inside profile range.

## Runtime Boundary

The generator should output data such as:

```json
{
  "seed": 1001,
  "region_id": "lower_ruins",
  "rooms": [],
  "connections": [],
  "requirements": [],
  "budgets": {}
}
```

Godot runtime should not depend on the Python prototype. Later GDScript can port the same algorithm or consume exported JSON while the first playable slice is being built.

## Acceptance Criteria

- `python tools/generate_region_graph.py --seed 1001` produces the same graph every time.
- Different seeds produce different layouts while preserving required room roles and completion path.
- Generated JSON includes room roles, coordinates, difficulty, reward budget, and connections.
- Generated SVG makes critical path, side branches, gates, keys, shop/rest, shortcut, and boss readable.
- The generation rules explain which randomness is allowed and which outcomes are invariant.

## Related

- `data/design/first_slice/procedural_region_rules.json`
- `tools/generate_region_graph.py`
- `docs/maps/generated/procedural/`
- `docs/design/MAP_DATA_AND_VISUALIZATION.md`
