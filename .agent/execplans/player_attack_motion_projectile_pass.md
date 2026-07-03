---
type: plan
status: done
created: 2026-07-03
source: User correction that character attacks need visible motion and arrows, not only profile numbers
scope: Player attack motion, profile attack style, and player projectile proof for the motion testbed
related:
  - ../../AGENTS.md
  - ../PLANS.md
  - ../../docs/design/MOTION_TEST_BED_SPEC.md
  - ../../docs/design/testbed-plan/02_combat_damage.md
  - ../../docs/design/testbed-plan/FEATURE_PRIORITY.md
---

# Player Attack Motion And Projectile Pass

## Why / Context

The prior combat identity pass changed attack numbers and hitbox dimensions, but it did not make the character's attack itself read like a sword swing or an arrow shot. The testbed needs visible character attack motion so combat can be evaluated without reading debug text.

## Scope / Non-scope

In scope:

- Add a profile-owned attack motion style such as heavy melee swing, quick slash, or arrow projectile.
- Animate the existing attack visual during active frames so melee attacks visibly swing up/down or slash.
- Add a lightweight player projectile for Archer-style attacks using the existing `Hitbox` and `DamageInfo` contract.
- Update character profiles and active planning docs.

Out of scope:

- Final sprite sheets, skeletal animation, particles, sound, or external art assets.
- Combo systems, charged attacks, animation cancel rules, or full weapon equipment integration.
- Separate character controllers.

## Assumptions

- Placeholder `Polygon2D` geometry is acceptable for this MVP testbed.
- Archer should fire a real damaging arrow projectile now, while melee profiles can keep direct hitbox damage.
- Player attack visuals should remain data-driven enough that later profiles can change style without rewriting stage code.

## Proposed Design

- Extend `CharacterProfile` with `attack_motion_style`, `attack_visual_color`, projectile speed, projectile lifetime, and projectile size fields.
- Keep melee damage on the existing `AttackHitbox`.
- Add `PlayerAttackProjectile` under `scripts/player/` for profile-driven projectile attacks.
- Let `PlayerController` choose between melee hitbox activation and projectile firing based on `attack_motion_style`.
- Keep hit confirmation connected through `Hitbox.target_hit` for both melee and projectile attacks.

## Milestones

1. [x] Create this ExecPlan.
2. [x] Add attack motion/profile fields and profile data.
3. [x] Add melee swing visual animation and Archer projectile firing.
4. [x] Update plan/spec docs.
5. [x] Validate with Godot import/runtime, screenshot evidence where practical, static checks, and diff hygiene.
6. [x] Mark this plan done and commit.

## Test Plan

- [x] `.\tools\godot.ps1 --path . --headless --import`
- [x] `.\tools\godot.ps1 --path . --headless --quit-after 3`
- [x] `.\tools\godot.ps1 --path . --headless --script res://tools/validate_player_attack_motion.gd`
- [x] `.\tools\godot.ps1 --path . --script res://tools/capture_ui_screenshots.gd`
- [x] `.\tools\godot.ps1 --path . --script res://tools/capture_attack_motion_screenshots.gd`
- [x] Rendered screenshot inspection for non-overlapping HUD and visible attack placeholder readiness.
- [x] Static `rg` checks for new attack motion fields and stale legacy binding data.
- [x] `git diff --check`

## Validation Results

- Godot import and short headless runtime completed without reported script errors.
- `validate_player_attack_motion.gd` confirmed Warrior uses melee hitbox + `heavy_swing`, Archer uses projectile + `arrow_projectile`, and Assassin uses melee hitbox + `quick_slash`.
- Attack screenshots confirmed visible Warrior downward swing, Archer arrow projectile, and Assassin quick slash.
- UI screenshots confirmed HUD/settings remained readable and still show `attack: F`.
- Static search found new attack motion/projectile fields and no stale legacy attack binding data.
- Full manual combat-lane feel tuning remains tracked in `docs/design/testbed-plan/05_qa_and_handoff.md`.

## Rollback / Safety

- The projectile class is additive and uses the same collision layer/mask as the existing player attack hitbox.
- Melee hitbox behavior remains the fallback for unknown styles.
- Profile fields have defaults, so existing or future profiles can load without manual scene edits.

## Risks

- A projectile can bypass destructibles or enemies if its collision layer/mask diverges from `AttackHitbox`.
- Swing visuals can drift from damaging hitbox timing if animation uses a separate timer.
- Archer projectile tuning may need manual combat-lane feel testing after this implementation.

## Open Questions

- Whether Archer should later have aim angles, gravity, or charged shots.
- Whether Warrior and Assassin should eventually receive separate animation sprites instead of placeholder polygons.

## Decision Notes

- Use `F` as the existing attack input.
- Implement true projectile firing for Archer now because the user explicitly called out arrows as expected and cheap.
