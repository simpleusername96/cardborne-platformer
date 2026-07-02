---
type: plan
status: active
created: 2026-07-02
source: Split from docs/design/MOTION_TEST_BED_MVP_PLAN.md
scope: Attack readability, real enemy baseline, hazards, damage recovery
related:
  - ../MOTION_TEST_BED_MVP_PLAN.md
  - ../MOTION_TEST_BED_SPEC.md
  - ./01_authored_lanes.md
  - ../../design/ENEMIES_TRAPS_GIMMICKS.md
---

# 02 - Combat And Damage

## Purpose

Make combat and damage observable, repeatable, and contract-driven. The testbed must prove a real enemy, player attack timing, contact damage, hazard damage, knockback, invulnerability, death, and reset behavior.

## Progress

Already true:

- [x] `DamageInfo`, `Hitbox`, and `Hurtbox` exist.
- [x] `PlayerController` can attack with an active hitbox.
- [x] `PlayerController.receive_damage` applies health loss, knockback, and invulnerability.
- [x] `DamageDummy` can receive damage and reset.
- [x] The current scene has one hazard-like active hitbox.

Still open:

- [ ] Attack startup, active window, recovery, cooldown, and hit confirm are not readable enough.
- [ ] The combat lane lacks a real enemy with behavior and contact damage.
- [ ] Hazard behavior is scene-local rather than a named reusable stage contract.
- [ ] Damage recovery and no-chain-hit behavior are not explicitly validated.

## Tasks

### Phase 3 - Player Control Feedback And Attack Readability

Source owners touched: `scripts/player/PlayerController.gd`, `scenes/player/Player.tscn`, `scripts/combat/Hitbox.gd`, `scripts/ui/HUD.gd`, `scripts/autoload/SignalBus.gd`.

- [ ] **3.1** Add placeholder visual states for idle, run, crouch, jump/fall, dash, hurt, and attack.
- [ ] **3.2** Add a visible attack active-frame shape or arc that matches the actual hitbox position and facing.
- [ ] **3.3** Expose compact feedback for startup, active, recovery, cooldown, and hit confirm.
- [ ] **3.4** Verify attack facing follows the last movement direction and does not flip incorrectly during crouch or dash.
- [ ] **3.5** Add or tune hit flash, hit pause, or color feedback for successful hits.
- [ ] **3.6** Ensure invulnerability feedback is visible without hiding player position.

Accept:

- [ ] A tester can tell when attack is active and why it missed or hit.
- [ ] Player hurt and invulnerability states are visible.

Guard:

- [ ] Visual attack feedback must use the same timing as the damaging `Hitbox`.

### Phase 4 - Real Enemy Baseline

Source owners touched: new `scripts/enemies/EnemyBase.gd`, new `scripts/enemies/WalkerEnemy.gd`, new enemy scenes, `scripts/enemies/DamageDummy.gd`, `SignalBus.gd`, `HUD.gd`.

- [ ] **4.1** Add `EnemyBase` with max health, current health, contact damage, knockback response, damaged signal, defeated signal, and reset/death behavior.
- [ ] **4.2** Add `WalkerEnemy` that patrols between bounds or turns on wall/ledge.
- [ ] **4.3** Add contact damage through `DamageInfo`.
- [ ] **4.4** Add enemy health feedback through label, marker, or HUD event.
- [ ] **4.5** Add repeatable lane reset behavior so the player can retest without restarting the whole scene.
- [ ] **4.6** Keep `DamageDummy` as an optional measurement target only.
- [ ] **4.7** Add safe re-entry after enemy damage or death.

Accept:

- [ ] Enemy moves, damages player, takes attack damage, reacts, dies or resets, and can be retested.
- [ ] Player death/reload still works after enemy contact damage.

Guard:

- [ ] Enemy AI must not directly edit UI or player health outside the shared damage path.

### Phase 5 - Hazards And Damage Recovery

Source owners touched: new or revised `scripts/stages/Hazard.gd`, `MotionTestStage.tscn`, `PlayerController.gd`, `HUD.gd`.

- [ ] **5.1** Wrap hazard behavior in a named script instead of only a scene-local `Hitbox`.
- [ ] **5.2** Add spike or hazard strip with clear visual identity.
- [ ] **5.3** Add knockback direction and recovery space.
- [ ] **5.4** Add invulnerability test that prevents immediate repeated damage.
- [ ] **5.5** Add safe reset/re-entry after falling or taking hazard damage.
- [ ] **5.6** Add HUD/status feedback for hazard damage.

Accept:

- [ ] Player takes hazard damage once, receives readable feedback, and can recover.
- [ ] Hazard cannot trap the player in an endless damage loop.

Guard:

- [ ] Repeating hazards must have explicit timing or player invulnerability protection.

## Verification

- [ ] Manual attack test: miss, hit, cooldown, facing change.
- [ ] Manual enemy test: contact damage, player attack damage, enemy death/reset.
- [ ] Manual hazard test: damage, knockback, invulnerability, recovery.
- [ ] Manual death/reload test.
- [ ] `rg` confirms `DamageDummy` is not the only combat lane proof.
- [ ] `git diff --check` before commit.

## Risks

- Enemy and hazard damage can diverge if they bypass `DamageInfo`.
- Attack VFX can drift from actual hitbox timing.
- Hazards can create soft locks if recovery space is not tested.

## Next Steps

- [ ] Commit after combat and hazard lanes are repeatable.
- [ ] Move to `03_interaction_input_ui.md`.
