---
type: handoff
status: active
owner: BK
created: 2026-07-21
expires: 2026-08-21
source: Repository inspection on 2026-07-21 at 4884ff4
related:
  - ./README.md
  - ../../../docs/product/isometric_action_rpg_product_brief.md
  - ../../execplans/2026-07-18-flooded-works-floor1-map-enemies.md
---

# Current Repository State

## Current State

### Git

- Branch: `master`.
- Pre-handoff HEAD: `4884ff4 docs: consolidate visual concept assets`.
- Upstream before this handoff push: `origin/master` at `37fa8d7`.
- Local `master` was 27 commits ahead and 0 behind before the handoff commit.
- The 27 commits contain the isometric reset, Godot foundation, raster Traveler
  presentation, Tiled modular kit, connected Flooded Works floor, enemy/prop/boss
  runtime, soft-lock fixes, vehicle reference analysis, and visual concepts.

### Runtime that exists

- Godot 4.7 native 3D runtime with a fixed orthographic isometric camera.
- A humanoid `Traveler3D` using arrow-key ground movement, facing, dash, melee,
  ranged fire, guard, potion, bounded targeting assistance, and raster sprite
  presentation for locomotion and actions.
- A connected Flooded Works floor generated from Tiled source:
  Movement Check, Foundry Approach, Pump Gallery, Pressure Vault, and Slime King
  Reservoir.
- Pursuer, Shooter, and Controller enemy roles, threat coordination, enemy
  projectiles, enemy health bars, encounter scripts, props, pickups, and Slime
  King boss runtime.
- Solid-world projectile collision and room-transition fixes that prevent living
  enemies or unreachable spawns from permanently blocking ordinary progression.
- Settings persistence and proof HUD surfaces.

Key runtime owners:

- `scripts/player/` — humanoid control, targeting, sprite presentation.
- `scripts/combat/` — damage requests/results and proof projectiles.
- `scripts/enemies/` — enemy actors, movement, pressure, projectiles, coordination.
- `scripts/bosses/` — Slime King and boss hazard behavior.
- `scripts/rooms/` and `scripts/encounters/` — generated-room and objective flow.
- `scripts/ui/` — enemy health and proof HUD.
- `data/rooms/flooded_works/tiled/` — authored room maps.

### Runtime that does not exist

- No vehicle actor, hull/turret relationship, manual mouse/right-stick aim, rapid
  shooter primary, passive secondary, `Z` area skill, vehicle dash/ram contract,
  or vehicle-specific enemy tuning.
- No accepted vehicle product spec or execution plan.
- No base/garage runtime, vehicle loadout screen, repair loop, or vehicle module
  inventory.
- No implemented field power-up family matching the latest discussion.
- No validated flat top-down presentation alternative.

### Authority mismatch

- Root `AGENTS.md`, `.agent/Prompt.md`,
  `docs/product/isometric_action_rpg_product_brief.md`, and the active Flooded
  Works plan still govern the humanoid proof.
- `docs/research/vehicle_led_isometric_action_reference_analysis.md` is evidence,
  not an accepted replacement spec.
- The latest owner feedback is newer than those product documents but has not yet
  been promoted through an explicit replacement decision.

### Worktree hygiene

- Numerous tracked Godot `.import` files are modified and
  `tools/component_gallery/assets/flooded-works-panorama-preview.png.import` is
  untracked.
- Those files were present before this handoff and are not staged, reverted, or
  cleaned by this task.
- Exact duplicate production UI backgrounds were already consolidated in commit
  `4884ff4`; the canonical copies are under `art/ui/production/backgrounds/`.
- External generated-image archive duplicates and stale `.codex-runtime` caches
  were identified in an earlier turn, but deletion was blocked by the tool policy
  then. Their deletion is not represented as completed repository work.

## Files Touched

This handoff task changes only
`.agent/handoffs/2026-07-21-vehicle-shooter-pivot/`.

## Verification

- No runtime or build validation is needed for a documentation-only handoff.
- `git diff --check` and a staged-file audit are required before commit.
- The push should advance `origin/master` to include all local commits and the
  handoff commit, because the owner explicitly requested the remote push.

## Next Steps

- Do not refactor the humanoid actor into a vehicle by renaming symbols.
- First accept a replacement product contract, then identify candidate technical
  infrastructure to reuse and contracts to retire.
- Use the smallest playable vehicle graybox as the first implementation slice.

## Risks

- Existing automated validators encode humanoid controls and may pass while the
  latest product hypothesis remains completely unimplemented.
- Current maps and boss spacing were tuned for the humanoid proof and cannot be
  assumed suitable for a vehicle shooter.
- Staging all changes would accidentally include unrelated `.import` churn.
