---
type: plan
status: done
created: 2026-07-03
source: User request to improve dungeon feel, attack key ergonomics, character attack identity, and enemy variety
scope: Motion testbed input, combat identity, enemy pattern, and dungeon framing pass
related:
  - ../../AGENTS.md
  - ../PLANS.md
  - ../../docs/design/MOTION_TEST_BED_SPEC.md
  - ../../docs/design/PLAYER_CHARACTER_SYSTEMS.md
  - ../../docs/design/ENEMIES_TRAPS_GIMMICKS.md
  - ../../docs/design/testbed-plan/02_combat_damage.md
  - ../../docs/design/testbed-plan/03_interaction_input_ui.md
  - ../../docs/design/testbed-plan/05_qa_and_handoff.md
---

# Testbed Dungeon Combat Identity Pass

## Why / Context

The motion testbed has a working clear gate, but the current player profiles feel too similar, combat uses only one walker enemy, and the map reads as a floating gray test space instead of a dungeon. The default attack binding also uses `J` / mouse click, which is awkward with the current keyboard layout.

## Scope / Non-scope

In scope:

- Make `F` the default attack key and update HUD/settings binding display.
- Add lightweight per-profile attack identity through data-driven attack range, height, active time, knockback, and labels.
- Improve enemy hit reaction and reset behavior.
- Add two simple enemy pattern baselines: charger and shooter.
- Add dungeon framing/background shapes around the authored and generated route without changing core collision routing.
- Update active plan docs to reflect this pass.

Out of scope:

- Full character select screen.
- Separate player controllers per character.
- Final sprites, animation sets, audio, particles, or external assets.
- Full production Stage01/02/03 content.
- Full procedural segment-template architecture.

## Assumptions

- "Character" in this pass means a shared-controller profile with distinct attack tuning and HUD/world labels.
- Dungeon feel can use placeholder shapes, parallax-free silhouettes, columns, arches, and side/bottom walls.
- Charger and shooter should be simple enough to prove pattern contracts, not final enemy balance.

## Proposed Design

- Extend `CharacterProfile` with attack shape/offset/knockback/active-time/display-label fields.
- Keep attack timing and hitbox placement owned by `PlayerController`; profile data only supplies numbers and labels.
- Keep enemy common health, contact damage, hit reaction, defeat, and reset behavior in `EnemyBase`.
- Add `ChargerEnemy` and `ShooterEnemy` scripts under `scripts/enemies/`, using the existing `Hitbox`/`DamageInfo` path.
- Keep dungeon framing in `MotionTestStage` as visual-only `Polygon2D` and non-gameplay `StaticBody2D` walls where needed.
- Use existing HUD/settings functions for input display so binding text cannot drift.

## Milestones

1. [x] Create this ExecPlan.
2. [x] Implement input, attack profile, enemy reaction/reset, charger/shooter, and dungeon framing.
3. [x] Update active plan docs.
4. [x] Validate with Godot import/runtime, screenshot evidence, UIUX hook, static checks, and diff hygiene.
5. [x] Mark this plan done and commit.

## Test Plan

- [x] `.\tools\godot.ps1 --path . --headless --import`
- [x] `.\tools\godot.ps1 --path . --headless --quit-after 3`
- [x] `.\tools\godot.ps1 --path . --script res://tools/capture_ui_screenshots.gd`
- [x] Rendered screenshot inspection for HUD/settings and dungeon framing.
- [x] UIUX gate hook after screenshot inspection.
- [x] Static `rg` checks for attack binding and enemy scripts.
- [x] `git diff --check`

## Validation Results

- Godot import and short headless runtime both completed without reported script errors.
- Screenshots confirmed `Attack F` in HUD and `attack: F` in settings, with text contained in desktop and narrow captures.
- Screenshots confirmed the placeholder dungeon rear wall, ceiling mass, columns, and lower masonry are visible behind the route.
- Static search found no stale legacy keyboard/mouse attack default binding path in active code or product/design docs.
- Full manual route clear and combat feel tuning remain covered by `docs/design/testbed-plan/05_qa_and_handoff.md`.

## Rollback / Safety

- Input change is isolated to `Game.ensure_input_map()` and display helpers.
- Character attack identity is additive profile data with fallback defaults.
- New enemies are additive scripts; existing walker stays intact.
- Dungeon framing is visual placeholder geometry and should not own gameplay routing.

## Risks

- Too much enemy variety can outpace movement/combat reliability; keep patterns minimal.
- Dungeon visuals can hide lane readability if too dense.
- Attack identity may require later tuning after manual QA.

## Open Questions

- Whether primary mouse attack should remain as an optional secondary binding later; this pass removes it from the default binding path because the user called it hard to use.
- Whether archer should eventually use true projectiles; this pass uses extended hitbox range first to avoid broad projectile systems.

## Decision Notes

- Use `F` as the default attack key.
- Treat Warrior, Archer, and Assassin as combat profiles for now, not production separate characters.
