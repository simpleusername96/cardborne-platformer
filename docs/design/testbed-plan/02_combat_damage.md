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

Make combat and damage observable, repeatable, and contract-driven. The testbed must prove a real enemy, player attack timing, attack-destructible obstacles, contact damage, hazard damage, knockback, invulnerability, death, and reset behavior.

## Progress

Already true:

- [x] `DamageInfo`, `Hitbox`, and `Hurtbox` exist.
- [x] `PlayerController` can attack with an active hitbox.
- [x] `PlayerController.receive_damage` applies health loss, knockback, and invulnerability.
- [x] `DamageDummy` can receive damage and reset.
- [x] The current scene has one hazard-like active hitbox.

Resolved in implementation:

- [x] Attack active window and hit confirm are visible through the player hitbox and status messages.
- [x] Attack range, height, active time, knockback, and status label now come from the active character profile.
- [x] Warrior and Assassin have visible placeholder melee swing/slash motion during active frames.
- [x] Archer fires a visible damaging arrow projectile using the shared player attack collision path.
- [x] The combat lane has a reusable `WalkerEnemy` with health, patrol, contact damage, hit reaction, and defeat.
- [x] The combat lane has simple `ChargerEnemy` and `ShooterEnemy` baselines for non-walker attack patterns.
- [x] Shared enemy damage reaction includes stronger knockback, hit stun, defeat hiding, and auto-reset.
- [x] The combat lane has a reusable `DestructibleObstacle` with health, hit reaction, collision removal, and destroyed signal.
- [x] Hazard behavior is a named reusable stage contract.
- [x] Checkpoint/fall/death recovery covers hazard and combat re-entry.

Still open:

- [ ] Full placeholder state set for idle/run/jump/fall/dash/hurt remains shallow.
- [ ] Destructible reset for repeated combat testing without route regeneration is still deferred.
- [ ] Manual combat QA is still tracked in `05_qa_and_handoff.md`.

## Tasks

### Phase 3 - Player Control Feedback And Attack Readability

Source owners touched: `scripts/player/PlayerController.gd`, `scenes/player/Player.tscn`, `scripts/combat/Hitbox.gd`, `scripts/ui/HUD.gd`, `scripts/autoload/SignalBus.gd`.

- [ ] **3.1** Add placeholder visual states for idle, run, crouch, jump/fall, dash, hurt, and attack.
- [x] **3.2** Add a visible attack active-frame shape or arc that matches the actual hitbox position and facing.
- [x] **3.3** Expose compact feedback for startup, active, recovery, cooldown, and hit confirm.
- [x] **3.4** Verify attack facing follows the last movement direction and does not flip incorrectly during crouch or dash.
- [x] **3.5** Add or tune hit flash, hit pause, or color feedback for successful hits.
- [x] **3.6** Ensure invulnerability feedback is visible without hiding player position.
- [x] **3.7** Add profile-specific placeholder attack motion: heavy swing, quick slash, and arrow shot.

Accept:

- [x] A tester can tell when attack is active and why it missed or hit.
- [x] A tester can distinguish melee swings from Archer projectile shots without reading debug text.
- [x] Player hurt and invulnerability states are visible.

Guard:

- [x] Visual attack feedback must use the same timing as the damaging `Hitbox`.
- [x] Projectile attacks must still use the shared `Hitbox`/`DamageInfo` path.

### Phase 4 - Real Enemy Baseline

Source owners touched: new `scripts/enemies/EnemyBase.gd`, new `scripts/enemies/WalkerEnemy.gd`, new enemy scenes, `scripts/enemies/DamageDummy.gd`, `SignalBus.gd`, `HUD.gd`.

- [x] **4.1** Add `EnemyBase` with max health, current health, contact damage, knockback response, defeated signal, and death behavior.
- [x] **4.2** Add `WalkerEnemy` that patrols between bounds or turns on wall/ledge.
- [x] **4.3** Add contact damage through `DamageInfo`.
- [x] **4.4** Add enemy health feedback through label, marker, or HUD event.
- [x] **4.5** Add repeatable lane reset behavior so the player can retest without restarting the whole scene.
- [x] **4.6** Keep `DamageDummy` as an optional measurement target only.
- [x] **4.7** Add safe re-entry after enemy damage or death.

Accept:

- [x] Enemy moves, damages player, takes attack damage, reacts, dies or resets, and can be retested.
- [x] Player death/reload still works after enemy contact damage.

Guard:

- [x] Enemy AI must not directly edit UI or player health outside the shared damage path.

### Phase 4C - Enemy Pattern Baselines

Source owners touched: `scripts/enemies/ChargerEnemy.gd`, `scripts/enemies/ShooterEnemy.gd`, `scripts/enemies/EnemyProjectile.gd`, `scripts/enemies/EnemyBase.gd`, `MotionTestStage.gd`.

- [x] **4C.1** Add a charger enemy with patrol, visible warning, charge, and recovery states.
- [x] **4C.2** Add a shooter enemy with visible warning and projectile damage.
- [x] **4C.3** Route both new enemies through `EnemyBase`, `DamageInfo`, `Hitbox`, and `Hurtbox` instead of bespoke player-health edits.
- [x] **4C.4** Place Walker, Charger, and Shooter in the authored combat lane so profile attacks can be compared against multiple enemy shapes.

Accept:

- [x] A tester can compare basic contact, charge, and projectile patterns in one combat lane.
- [x] Enemy defeat still marks the shared combat validation instead of adding enemy-specific clear gates.

Guard:

- [x] New enemy patterns stay placeholder-sized and do not become production enemy breadth before movement/combat reliability is tested.

### Phase 4B - Destructible Obstacle Baseline

Source owners touched: new `scripts/stages/DestructibleObstacle.gd` or equivalent, `scripts/combat/DamageInfo.gd`, `Hitbox.gd`, `MotionTestStage.tscn`, `HUD.gd`.

- [x] **4B.1** Add a destructible obstacle with health, hurtbox, hit reaction, and destroyed state.
- [x] **4B.2** Route player attacks into destructibles through `DamageInfo` or a documented equivalent.
- [x] **4B.3** Make destruction visibly remove or change collision.
- [x] **4B.4** Use the destroyed obstacle to open a shortcut, reveal a small reward, or clear a blocked route.
- [ ] **4B.5** Add reset behavior so the destructible test can be repeated.

Accept:

- [x] Player can destroy an obstacle by attacking it.
- [x] Destroying the obstacle visibly changes traversal.

Guard:

- [x] Do not hard-code destructible behavior into the player attack script.

### Phase 5 - Hazards And Damage Recovery

Source owners touched: new or revised `scripts/stages/Hazard.gd`, `MotionTestStage.tscn`, `PlayerController.gd`, `HUD.gd`.

- [x] **5.1** Wrap hazard behavior in a named script instead of only a scene-local `Hitbox`.
- [x] **5.2** Add spike or hazard strip with clear visual identity.
- [x] **5.3** Add knockback direction and recovery space.
- [x] **5.4** Add invulnerability test that prevents immediate repeated damage.
- [x] **5.5** Add safe reset/re-entry after falling or taking hazard damage.
- [x] **5.6** Add HUD/status feedback for hazard damage.

Accept:

- [x] Player takes hazard damage once, receives readable feedback, and can recover.
- [x] Hazard cannot trap the player in an endless damage loop.

Guard:

- [x] Repeating hazards must have explicit timing or player invulnerability protection.

## Verification

- [ ] Manual attack test: miss, hit, cooldown, facing change, melee swing readability, Archer arrow hit.
- [ ] Manual enemy test: contact damage, player attack damage, Walker/Charger/Shooter pattern readability, enemy death/reset.
- [ ] Manual destructible test: attack damage, visual break, collision removal/change, route change, reset.
- [ ] Manual hazard test: damage, knockback, invulnerability, recovery.
- [ ] Manual death/reload test.
- [x] `rg` confirms `DamageDummy` is not the only combat lane proof.
- [x] `git diff --check` before commit.

## Risks

- Enemy and hazard damage can diverge if they bypass `DamageInfo`.
- Destructibles can become one-off scene hacks if they bypass the shared damage vocabulary.
- Attack VFX can drift from actual hitbox timing.
- Hazards can create soft locks if recovery space is not tested.

## Next Steps

- [ ] Commit after combat and hazard lanes are repeatable.
- [ ] Move to `03_interaction_input_ui.md`.
