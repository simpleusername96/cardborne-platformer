---
type: spec
status: active
canonical_for: first-slice enemies, traps, and map gimmicks
source: docs/product/FIRST_SLICE_EXPANSION.md
scope: Encounter and traversal content for the first playable version
---

# Enemies, Traps, And Gimmicks

## Purpose

Define the first-slice encounter vocabulary so stages can teach combat, traversal, and reward collection without inventing behavior during implementation.

## Scope

This guide covers normal enemies, boss-related actors, traps, and map gimmicks planned for the first playable version. It intentionally favors clear teaching roles over content volume.

## Requirements

### Enemy Design Rules

- Every enemy type must have a clear player lesson.
- Enemy drops must reference a drop table or reward source ID.
- Contact damage should be predictable and usually deal 1 health.
- Enemy tells should be visible before sudden burst movement or projectile pressure.
- The first slice should avoid enemies that require advanced movement not yet taught.

### Trap Design Rules

- Traps must be readable before they punish the player.
- Traps should usually deal 1 health in the first slice.
- Repeating traps need consistent timing.
- Trap placement should teach before combining with enemy pressure.
- Boss and major stage hazards must have a warning/startup phase before active damage.
- Traps do not need their own rewards, but the data should state whether they guard or pressure reward access.

### Gimmick Design Rules

- Gimmicks should change traversal, route choice, or reward access.
- A gimmick must not permanently block stage completion unless it is a deliberate key/gate challenge.
- Optional reward paths may be riskier than the main route.
- Moving platforms must have stable timing and safe boarding space.
- Reward-bearing gimmicks should point to a drop table or clear reward trigger instead of duplicating amounts in stage layouts.

## First-Slice Content

**Enemies**

- Walker: basic patrol target, teaches attack timing and contact damage.
- Charger: warning then horizontal burst, teaches dodge and jump spacing.
- Shooter: fires projectile, teaches movement under ranged pressure.
- Small Slime: weak summoned enemy, used by boss phase 2 and simple swarm moments.

**Boss**

- Giant Slime King: two-phase pattern boss with jump slam, floor poison, body bump, summons, and faster phase-2 timing.

**Traps**

- Spike row: immediate contact hazard.
- Poison floor: delayed warning and active damage floor.
- Falling pit: reposition or damage/respawn pressure.
- Crushing block: future hook; only use if warning timing is implemented.

**Gimmicks**

- One-way platform: supports drop-through movement.
- Moving platform: teaches timing and patience.
- Coin cluster: direct pickup reward for teaching currency collection.
- Key pickup: route unlock object paired with a locked gate.
- Locked gate/key: optional route or simple required routing.
- Breakable wall: optional reward access.
- Chest: visible reward container.
- Material node: interactable or breakable resource source.
- Exit portal: normal stage clear.
- Boss warning zone: telegraph area before boss damage.

## Acceptance Criteria

- Enemy, trap, and gimmick IDs exist in `data/design/first_slice/enemy_trap_gimmick_catalog.json`.
- Stage layout data references only documented encounter/gimmick concepts.
- Future implementation can place content from the guide without redefining its teaching purpose.
- Boss attacks preserve the PRD rule: visible startup warning, active damage window, and recovery.
- Reward-bearing enemies and gimmicks reference economy data rather than embedding reward quantities in stage layout rows.

## Related

- `data/design/first_slice/enemy_trap_gimmick_catalog.json`
- `data/design/first_slice/stage_layouts.json`
- `docs/product/2d_platform_action_card_game_prd.md`
