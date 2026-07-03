# PRD: 2D Platform Action + Random Upgrade Card Game

**Working title:** Cardborne Platformer  
**Target engine:** Godot 4.x  
**Primary language:** GDScript  
**Target platform for MVP:** Desktop keyboard controls  
**Document purpose:** Give Codex enough product, gameplay, and technical direction to start building a real playable prototype without inventing core requirements.

---

## 1. Product Summary

Build a compact, stable, and extensible 2D side-view action platformer where the player clears short stages, avoids hazards, fights enemies, and receives a random upgrade card after each stage. Every run should feel slightly different because the player’s stats, mobility, and combat options change through card choices.

The MVP should focus on excellent core movement, simple but reliable combat, a small stage loop, and one pattern-based boss fight inspired by MMORPG boss encounters such as MapleStory: telegraphed attacks, floor warnings, safe zones, multiple phases, and short damage windows.

This is not a content-heavy roguelike yet. The first goal is to create a clean gameplay foundation that can later support more maps, enemies, cards, characters, weapons, bosses, and permanent skill trees.

---

## 2. Product Goals

### 2.1 Primary Goals

1. Create a playable 2D action platformer prototype with reliable player controls.
2. Implement a run loop:
   - Enter stage.
   - Fight enemies and avoid hazards.
   - Clear stage.
   - Choose 1 of 3 random upgrade cards.
   - Continue to next stage.
   - Fight a boss after several stages.
3. Implement an extensible card system that can modify player stats and unlock simple mechanics.
4. Implement a boss fight using visible warning zones and repeatable attack patterns.
5. Use a modular project structure so additional stages, cards, enemies, and bosses can be added without rewriting core systems.

### 2.2 Non-Goals for MVP

Do not build these in the first implementation unless all MVP goals are complete:

- Online multiplayer.
- Save files beyond simple local debug persistence.
- Full roguelike procedural generation.
- Complex inventory.
- Dialogue system.
- Shop system.
- Multiple playable characters.
- Full permanent skill tree.
- Final art, VFX, sound design, localization, or monetization.

---

## 3. Target Player Experience

The player should feel that the game is:

- Easy to understand within 30 seconds.
- Responsive when moving, jumping, dashing, and attacking.
- Fair when taking damage because attacks have visible tells.
- Replayable because upgrade cards change the build direction.
- Expandable because new content can be added naturally.

The core promise is:

> “Clear short platform-action stages, choose random upgrades, and survive pattern-heavy boss fights.”

---

## 4. Core Gameplay Loop

### 4.1 Run-Level Loop

1. Start new run.
2. Load Stage 1.
3. Player reaches the stage exit while fighting enemies and avoiding hazards.
4. Stage clear screen appears.
5. Reward screen shows 3 random upgrade cards.
6. Player selects 1 card.
7. Card effect applies immediately.
8. Next stage loads.
9. After Stage 3, load Boss Stage 1.
10. Boss clear gives a stronger reward.
11. Prototype run ends after boss clear.

### 4.2 MVP Stage Flow

MVP should include:

- Stage 1: basic movement, basic enemies.
- Stage 2: hazards and moving platforms.
- Stage 3: mixed enemies and tighter platforming.
- Boss Stage 1: large boss with 2 phases.

### 4.3 Clear Conditions

For MVP, a normal stage is cleared when the player reaches the exit portal.

Boss stage is cleared when the boss health reaches 0.

---

## 5. Core Controls

### 5.1 Keyboard Controls

| Action | Input |
|---|---|
| Move left | A / Left Arrow |
| Move right | D / Right Arrow |
| Jump | Space |
| Attack | F |
| Dash | K / Shift |
| Crouch | S / Down Arrow |
| Drop through one-way platform | Down + Jump |
| Pause | Esc |

### 5.2 Gamepad Controls

Gamepad support is optional for MVP but the input map should be designed so gamepad can be added later.

Suggested mapping:

| Action | Input |
|---|---|
| Move | Left stick / D-pad |
| Jump | South face button |
| Attack | West face button |
| Dash | East face button |
| Crouch | Down |
| Pause | Start |

---

## 6. Player Controller Requirements

The player controller is the highest-priority system. It must be stable before expanding content.

### 6.1 Required Movement Features

MVP player movement must include:

- Left/right movement.
- Acceleration and deceleration.
- Ground jump.
- Variable jump height.
- Coyote time.
- Jump buffering.
- Dash.
- Crouch.
- Fast fall while holding down in air.
- One-way platform drop.
- Damage knockback.
- Temporary invulnerability after damage.

### 6.2 Recommended Starting Values

Use exported variables so these can be tuned in the Godot editor.

| Variable | Starting Value |
|---|---:|
| Move speed | 220 px/s |
| Acceleration | 1800 px/s² |
| Deceleration | 2200 px/s² |
| Air acceleration | 1200 px/s² |
| Gravity | 1200 px/s² |
| Max fall speed | 700 px/s |
| Jump velocity | -420 px/s |
| Jump cut multiplier | 0.45 |
| Coyote time | 0.10 s |
| Jump buffer time | 0.12 s |
| Dash speed | 520 px/s |
| Dash duration | 0.13 s |
| Dash cooldown | 0.45 s |
| Post-hit invulnerability | 1.00 s |
| Damage knockback X | 220 px/s |
| Damage knockback Y | -220 px/s |

### 6.3 Acceptance Criteria

- Player can move, jump, dash, attack, crouch, and take damage in a test stage.
- Jump input shortly before landing still triggers a jump.
- Jump input shortly after leaving a ledge still works.
- Releasing jump early produces a lower jump.
- Dash cannot be spammed beyond cooldown rules.
- Player does not get stuck on normal tile corners in the MVP test stage.
- Player respawns or game-over flow triggers correctly after death.

---

## 7. Combat System

### 7.1 Player Combat

MVP combat should be simple and reliable.

Required:

- Basic melee attack.
- Attack hitbox appears briefly in front of player.
- Attack has cooldown.
- Attack direction follows facing direction.
- Air attack uses same attack initially.
- Enemies receive damage and knockback.
- Player cannot attack infinitely faster than the defined cooldown.
- Attack damage can be modified by cards.

Optional after MVP:

- Downward strike.
- Charged attack.
- Combo chain.
- Projectile slash.
- Critical hit.
- Attack cancel rules.

### 7.2 Player Health

MVP health:

| Property | Value |
|---|---:|
| Max health | 5 |
| Contact damage from normal enemy | 1 |
| Projectile damage | 1 |
| Boss attack damage | 1 |
| Hazard damage | 1 |
| Death condition | Current health <= 0 |

After taking damage, the player becomes briefly invulnerable.

### 7.3 Damage Model

Use a simple damage event structure:

```gdscript
class_name DamageInfo
var amount: int
var source: Node
var knockback: Vector2
var tags: Array[String]
```

Damage tags can later support effects like fire, poison, boss damage, melee damage, projectile damage, etc.

For MVP, only amount and knockback are required.

---

## 8. Card Upgrade System

### 8.1 Card Reward Flow

After each normal stage:

1. Pause gameplay.
2. Show reward screen.
3. Randomly select 3 cards from the card pool.
4. Player chooses 1.
5. Apply card effect.
6. Continue to next stage.

After boss clear:

- Show 3 cards with improved rarity weights.
- Then end prototype or return to main menu.

### 8.2 Card Rarities

MVP rarities:

| Rarity | Approx. Weight |
|---|---:|
| Common | 70 |
| Rare | 25 |
| Legendary | 5 |

Boss reward weights:

| Rarity | Approx. Weight |
|---|---:|
| Common | 40 |
| Rare | 45 |
| Legendary | 15 |

### 8.3 Card Data Fields

Implement cards as data resources, not hard-coded UI objects.

Recommended Godot Resource:

```gdscript
class_name CardData
extends Resource

@export var id: String
@export var display_name: String
@export_multiline var description: String
@export_enum("common", "rare", "legendary") var rarity: String = "common"
@export var icon: Texture2D
@export var max_stacks: int = 99
@export var effect_type: String
@export var effect_value: float
@export var tags: Array[String]
```

The card application code should interpret `effect_type`.

### 8.4 MVP Effect Types

Implement these effect types first:

| Effect Type | Meaning |
|---|---|
| `add_max_health` | Increase max health and heal by same amount. |
| `add_attack_damage` | Increase player melee damage. |
| `multiply_attack_speed` | Reduce attack cooldown. |
| `add_move_speed` | Increase movement speed. |
| `add_jump_power` | Increase jump height by making jump velocity more negative. |
| `reduce_dash_cooldown` | Lower dash cooldown. |
| `add_dash_charge` | Add one extra air dash or dash charge. |
| `add_invulnerability_time` | Increase post-hit invulnerability. |
| `heal_now` | Heal immediately. |
| `add_card_choice` | Future-facing effect; can be implemented later. |

### 8.5 MVP Card List

Implement at least 15 cards.

#### Common Cards

1. **Sharp Edge**
   - Effect: `add_attack_damage`
   - Value: +1
   - Description: Basic attacks deal +1 damage.

2. **Light Boots**
   - Effect: `add_move_speed`
   - Value: +20
   - Description: Move slightly faster.

3. **Spring Legs**
   - Effect: `add_jump_power`
   - Value: -25
   - Description: Jump slightly higher.

4. **First Aid**
   - Effect: `heal_now`
   - Value: +2
   - Description: Heal 2 health.

5. **Tough Skin**
   - Effect: `add_max_health`
   - Value: +1
   - Description: Gain +1 max health and heal 1.

#### Rare Cards

6. **Quick Hands**
   - Effect: `multiply_attack_speed`
   - Value: 0.90
   - Description: Attack cooldown reduced by 10%.

7. **Dash Tuning**
   - Effect: `reduce_dash_cooldown`
   - Value: 0.10
   - Description: Dash cooldown reduced by 0.10 seconds.

8. **Iron Nerve**
   - Effect: `add_invulnerability_time`
   - Value: +0.25
   - Description: After being hit, stay invulnerable slightly longer.

9. **Double Step**
   - Effect: `add_dash_charge`
   - Value: +1
   - Description: Gain one additional dash charge.

10. **Boss Breaker**
   - Effect: `add_attack_damage`
   - Value: +2
   - Tags: `boss_focused`
   - Description: Attacks deal +2 damage.

#### Legendary Cards

11. **Glass Blade**
   - Effect: `add_attack_damage`
   - Value: +4
   - Description: Greatly increase attack damage. Future version may reduce max health.

12. **Blink Rhythm**
   - Effect: `reduce_dash_cooldown`
   - Value: 0.25
   - Description: Greatly reduce dash cooldown.

13. **Giant Heart**
   - Effect: `add_max_health`
   - Value: +3
   - Description: Gain +3 max health and heal 3.

14. **Air Master**
   - Effect: `add_dash_charge`
   - Value: +2
   - Description: Gain two additional dash charges.

15. **Relentless**
   - Effect: `multiply_attack_speed`
   - Value: 0.75
   - Description: Attack cooldown reduced by 25%.

### 8.6 Card System Acceptance Criteria

- Reward screen shows exactly 3 cards after a normal stage.
- Clicking or confirming a card applies its effect.
- Applied effects persist through the current run.
- Multiple cards can stack unless max stack says otherwise.
- Card UI displays name, rarity, and description.
- Card reward can be skipped only if a debug flag is enabled.
- The card system should be extendable by adding new `CardData` resources.

---

## 9. Enemy System

### 9.1 Enemy Architecture

Use a shared base enemy script with common properties:

- Max health.
- Current health.
- Contact damage.
- Move speed.
- Knockback handling.
- Death event.
- Damage receiving function.

Each enemy type can implement its own AI.

### 9.2 MVP Enemy Types

#### Enemy 1: Walker

Purpose: Basic target and movement obstacle.

Behavior:

- Patrols left and right.
- Turns around at walls or ledges.
- Damages player on contact.
- Dies after a few hits.

Recommended stats:

| Stat | Value |
|---|---:|
| Health | 3 |
| Contact damage | 1 |
| Move speed | 60 px/s |

#### Enemy 2: Charger

Purpose: Teaches dash/jump evasion.

Behavior:

- Idles until player enters detection range.
- Briefly telegraphs.
- Charges horizontally.
- Has recovery time after charge.

Recommended stats:

| Stat | Value |
|---|---:|
| Health | 5 |
| Contact damage | 1 |
| Move speed during charge | 280 px/s |
| Telegraph time | 0.45 s |
| Recovery time | 0.70 s |

#### Enemy 3: Shooter

Purpose: Adds projectile avoidance.

Behavior:

- Stays still or patrols slightly.
- Fires projectile toward player every few seconds.
- Projectile is destroyed on wall impact.
- Projectile damages player.

Recommended stats:

| Stat | Value |
|---|---:|
| Health | 4 |
| Projectile damage | 1 |
| Fire interval | 1.6 s |
| Projectile speed | 220 px/s |

### 9.3 Enemy Acceptance Criteria

- All three enemies can be placed in a stage scene.
- Enemies damage the player.
- Player attacks damage enemies.
- Enemies die and disappear or play a placeholder death animation.
- Shooter projectiles collide with walls and player.
- Charger has a visible warning before charging.

---

## 10. Boss System

### 10.1 Boss Design Direction

The MVP boss should be a readable pattern fight.

Reference direction:

- Large boss health bar.
- Repeating attack patterns.
- Clear telegraphs before damage.
- Floor warning markers.
- Safe zones.
- Phase change at 50% health.
- Adds or hazards during phase 2.
- Short windows where the player can safely attack.

Do not copy assets, names, or exact patterns from any existing game. Use the general idea of telegraphed MMORPG-style boss mechanics.

### 10.2 MVP Boss: Giant Slime King

#### Basic Properties

| Property | Value |
|---|---:|
| Max health | 80 |
| Contact damage | 1 |
| Phase 2 threshold | 50% health |
| Arena size | One screen wide or slightly wider |
| Player respawn | Restart boss stage |

#### Phase 1 Patterns

1. **Jump Slam**
   - Boss jumps upward.
   - Shadow or marker shows landing area.
   - On landing, creates shockwave moving left and right.
   - Player avoids by jumping over shockwave or dashing away.

2. **Floor Poison**
   - Warning rectangles appear on floor.
   - After delay, poison zones activate.
   - Standing in zone damages player once per tick or once per activation.

3. **Body Bump**
   - Boss leans back.
   - Boss dashes horizontally.
   - Player avoids by jumping or dashing.

#### Phase 2 Additions

1. **Small Slime Summon**
   - Boss spawns two small walker enemies.
   - Summons should not overwhelm the player.
   - Limit active summoned enemies.

2. **Faster Pattern Timing**
   - Reduce delay between attacks slightly.

3. **Wider Shockwave**
   - Jump Slam shockwave travels farther or faster.

### 10.3 Boss Attack Telegraph Requirements

Every damaging boss attack must have:

- Startup warning.
- Active damage window.
- Recovery.
- Clear visual placeholder, even if only colored rectangles are used.

### 10.4 Boss Acceptance Criteria

- Boss fight starts when boss stage loads.
- Boss health bar appears.
- Boss uses at least 3 attack patterns.
- Boss changes behavior below 50% health.
- Boss can kill the player.
- Player can kill the boss.
- Boss clear triggers reward screen or prototype completion screen.

---

## 11. Map and Level Design

### 11.1 MVP Level Format

Use Godot scenes for authored stages.

Each stage scene should include:

- TileMapLayer or equivalent for solid ground.
- One-way platforms.
- Hazards.
- Enemy spawn points or directly placed enemy scenes.
- Player spawn point.
- Exit portal.
- Camera bounds.
- Optional checkpoint.

### 11.2 Tile / Collision Layers

Recommended collision layers:

| Layer | Purpose |
|---|---|
| World | Solid ground and walls |
| OneWayPlatform | Drop-through platforms |
| Player | Player body |
| Enemy | Enemy bodies |
| PlayerHitbox | Player attack hitboxes |
| EnemyHitbox | Enemy attacks |
| Hazard | Spikes, poison, kill zones |
| Projectile | Bullets and magic shots |

### 11.3 Stage 1 Requirements

Theme: Training field / ruins placeholder.

Includes:

- Flat start area.
- Small jump gap.
- 2 Walker enemies.
- 1 ledge.
- Exit portal.

### 11.4 Stage 2 Requirements

Includes:

- Spikes.
- Moving platform.
- 1 Walker.
- 1 Shooter.
- Slightly longer route.
- Exit portal.

### 11.5 Stage 3 Requirements

Includes:

- Mixed platforming.
- 1 Charger.
- 1 Shooter.
- Hazard gap.
- Optional checkpoint.
- Exit portal.

### 11.6 Boss Stage Requirements

Includes:

- Flat or mostly flat arena.
- 2-3 platforms if needed.
- Walls on both sides.
- Boss spawn.
- Player spawn.
- Camera locked to arena.
- No exit portal until boss is defeated.

---

## 12. UI / UX Requirements

### 12.1 HUD

HUD must show:

- Player health.
- Current stage number.
- Current cards or active card count.
- Boss health bar during boss stage.
- Optional dash cooldown indicator.

### 12.2 Card Reward Screen

Card screen must show:

- 3 card panels.
- Card name.
- Rarity.
- Description.
- Confirm selection.
- Continue to next stage.

### 12.3 Menus

MVP menus:

- Main menu.
- Pause menu.
- Game over screen.
- Prototype clear screen.

### 12.4 UI Acceptance Criteria

- HUD updates when health changes.
- Boss health bar updates when boss takes damage.
- Card selection can be performed with mouse.
- Game can be restarted after death.
- Pause stops gameplay and resumes correctly.

---

## 13. Run State and Progression

### 13.1 Run State

Maintain a run state object or autoload with:

- Current stage index.
- Current health.
- Max health.
- Player stat modifiers.
- Owned cards.
- RNG seed.
- Boss defeated flag.
- Run ended flag.

### 13.2 Permanent Progression

Permanent skill tree is post-MVP.

However, design the code so it can later support persistent upgrades. Do not hard-code all stats only inside the Player scene.

Future skill tree branches:

- Combat:
  - Reduced attack cooldown.
  - Unlock charged attack.
  - Boss damage bonus.
- Mobility:
  - Unlock air dash.
  - Unlock wall jump.
  - Reduce dash cooldown.
- Survival:
  - Max health +1.
  - Better healing.
  - Longer invulnerability.
- Card:
  - Extra card choice.
  - One reroll per run.
  - Higher rare-card chance.

### 13.3 MVP Persistence

No full save system required.

Optional debug persistence:

- Store highest cleared stage.
- Store last selected cards.
- Store simple settings.

---

## 14. Technical Architecture

### 14.1 Suggested Project Structure

```text
res://
  project.godot
  README.md

  scenes/
    main/
      Main.tscn
      MainMenu.tscn
      GameOverScreen.tscn
      PrototypeClearScreen.tscn

    player/
      Player.tscn
      PlayerAttackHitbox.tscn

    enemies/
      EnemyBase.tscn
      WalkerEnemy.tscn
      ChargerEnemy.tscn
      ShooterEnemy.tscn
      EnemyProjectile.tscn

    bosses/
      SlimeKingBoss.tscn
      BossWarningZone.tscn
      Shockwave.tscn
      PoisonZone.tscn

    stages/
      Stage01.tscn
      Stage02.tscn
      Stage03.tscn
      BossStage01.tscn

    ui/
      HUD.tscn
      CardRewardScreen.tscn
      CardPanel.tscn
      PauseMenu.tscn

  scripts/
    autoload/
      Game.gd
      RunState.gd
      CardDatabase.gd
      SignalBus.gd

    player/
      Player.gd
      PlayerStats.gd
      PlayerCombat.gd

    combat/
      DamageInfo.gd
      Hurtbox.gd
      Hitbox.gd

    enemies/
      EnemyBase.gd
      WalkerEnemy.gd
      ChargerEnemy.gd
      ShooterEnemy.gd
      EnemyProjectile.gd

    bosses/
      SlimeKingBoss.gd
      BossWarningZone.gd
      Shockwave.gd
      PoisonZone.gd

    cards/
      CardData.gd
      CardEffectApplier.gd

    stages/
      StageManager.gd
      ExitPortal.gd
      Hazard.gd
      Checkpoint.gd

    ui/
      HUD.gd
      CardRewardScreen.gd
      CardPanel.gd
      PauseMenu.gd

  data/
    cards/
      sharp_edge.tres
      light_boots.tres
      spring_legs.tres
      first_aid.tres
      tough_skin.tres
      quick_hands.tres
      dash_tuning.tres
      iron_nerve.tres
      double_step.tres
      boss_breaker.tres
      glass_blade.tres
      blink_rhythm.tres
      giant_heart.tres
      air_master.tres
      relentless.tres

  art/
    placeholder/
      player.png
      enemy.png
      boss.png
      tiles.png

  audio/
    placeholder/
```

### 14.2 Autoloads

Recommended autoloads:

#### Game.gd

Responsible for:

- Loading stages.
- Restarting runs.
- Transitioning between menu, stage, card reward, boss, and clear screen.
- Holding high-level game mode.

#### RunState.gd

Responsible for:

- Current run stats.
- Owned cards.
- Current stage number.
- RNG seed.
- Resetting run data.

#### CardDatabase.gd

Responsible for:

- Loading all card resources.
- Returning random card choices based on rarity weights.
- Preventing invalid duplicates if max stacks reached.

#### SignalBus.gd

Responsible for shared signals:

- `player_health_changed`
- `player_died`
- `stage_cleared`
- `card_selected`
- `boss_health_changed`
- `boss_defeated`

### 14.3 Code Principles

- Prefer data-driven cards over hard-coded card selection.
- Use signals for UI updates.
- Keep Player movement separate from UI and stage flow.
- Keep enemy base behavior reusable.
- Use exported variables for tuning.
- Make placeholder art acceptable.
- Avoid building a giant abstract framework before the MVP works.
- Write readable names and comments where gameplay tuning is non-obvious.

---

## 15. Implementation Milestones

### Milestone 1: Project Skeleton

Deliverables:

- Godot project opens.
- Main menu loads.
- Test stage loads from Start button.
- Player scene exists.
- Basic HUD exists.

Acceptance criteria:

- User can press Start and enter Stage 1.
- No missing script errors.
- Project has README with run instructions.

### Milestone 2: Player Controller

Deliverables:

- Move.
- Jump.
- Variable jump.
- Coyote time.
- Jump buffer.
- Dash.
- Crouch.
- Fast fall.
- Health and damage.

Acceptance criteria:

- Player can complete a simple platforming test room.
- Movement variables are tunable from editor.

### Milestone 3: Combat and Enemies

Deliverables:

- Basic attack hitbox.
- Enemy base class.
- Walker enemy.
- Charger enemy.
- Shooter enemy.
- Projectile.

Acceptance criteria:

- Player can kill all three enemy types.
- Enemies can damage and kill player.
- Game over screen works.

### Milestone 4: Stage Flow

Deliverables:

- Stage01, Stage02, Stage03.
- Exit portal.
- StageManager.
- Game loads next stage.

Acceptance criteria:

- Player can clear three normal stages in sequence.

### Milestone 5: Card Reward System

Deliverables:

- CardData resource.
- CardDatabase.
- CardRewardScreen.
- CardEffectApplier.
- 15 MVP cards.

Acceptance criteria:

- After each normal stage, player chooses 1 of 3 cards.
- Effects apply and persist through run.
- Card choice affects actual gameplay.

### Milestone 6: Boss Fight

Deliverables:

- Boss stage.
- Slime King boss.
- Boss health bar.
- Jump Slam.
- Floor Poison.
- Body Bump.
- Phase 2 behavior.
- Boss defeat flow.

Acceptance criteria:

- Player can fight and defeat the boss.
- Boss can defeat the player.
- Boss uses visible warnings before attacks.
- Prototype clear screen appears after boss reward or boss death.

### Milestone 7: Polish Pass

Deliverables:

- Basic placeholder animations or color flashes.
- Damage feedback.
- Camera smoothing.
- Pause menu.
- Basic sound placeholders if available.
- Balance tuning.

Acceptance criteria:

- Full MVP run is playable from main menu to prototype clear.
- No major soft locks.
- Death and restart work.

---

## 16. Difficulty Design Rules

MVP should avoid unfair one-shot design.

Rules:

- Most damage should remove 1 health.
- Every boss attack must be telegraphed.
- The player should survive several mistakes.
- Hazards should teach before punishing heavily.
- Stage 1 should be easy enough to clear on first or second try.
- Stage 3 can demand combined use of jump, dash, and attack.
- Boss phase 2 should be more intense but not chaotic.

Difficulty should increase through pattern combinations, enemy placement, and reduced safety, not just inflated damage.

---

## 17. Content Expansion Direction

After the MVP works, expand in this order:

### 17.1 v0.2

- Add air dash as a real unlockable mechanic.
- Add wall jump.
- Add elite room.
- Add card reroll.
- Add 10 more cards.
- Add one new enemy.

### 17.2 v0.3

- Add second world theme.
- Add second boss.
- Add room-based stage assembly.
- Add more hazard types.
- Add card synergies.

### 17.3 v0.4

- Add permanent skill tree.
- Add run currency.
- Add second playable character.
- Add weapon variants.

### 17.4 v1.0 Direction

- Multiple worlds.
- Multiple bosses.
- Complete card pool.
- Permanent progression.
- Challenge modes.
- Balanced difficulty modes.
- Final art/audio pass.

---

## 18. Initial Codex Task Prompt

Use the following prompt to start implementation:

```text
Create a Godot 4.x GDScript project for a 2D side-view action platformer with random upgrade cards.

Use the PRD in this repository as the source of truth.

Build the MVP in milestones:
1. Project skeleton with Main menu, Stage01, HUD, and Player scene.
2. Player controller with left/right movement, jump, variable jump height, coyote time, jump buffer, dash, crouch, fast fall, health, damage, and death.
3. Combat with a basic melee hitbox.
4. Three enemy types: Walker, Charger, Shooter.
5. Stage flow through Stage01, Stage02, Stage03.
6. Card reward screen after each normal stage, showing 3 random cards. Selecting a card applies a stat effect.
7. BossStage01 with SlimeKingBoss using telegraphed attacks and phase 2 at 50% health.
8. Prototype clear screen after boss defeat.

Use placeholder shapes or simple placeholder sprites. Do not depend on external assets.

Keep code modular:
- Player logic in scripts/player.
- Combat helpers in scripts/combat.
- Enemy logic in scripts/enemies.
- Boss logic in scripts/bosses.
- Card resources and application logic in scripts/cards and data/cards.
- Stage flow in scripts/stages.
- UI in scripts/ui.
- Global state in scripts/autoload.

Prioritize a working playable vertical slice over visual polish.
Include README.md with how to run the project.
Use exported variables for gameplay tuning.
```

---

## 19. Definition of Done for MVP

The MVP is done when:

- The project opens in Godot 4.x without errors.
- Starting a new run loads Stage 1.
- Player can move, jump, dash, crouch, attack, take damage, and die.
- Stage 1, Stage 2, and Stage 3 are playable.
- At least three enemy types exist and work.
- Stage clear opens a 3-card reward screen.
- Selecting a card changes gameplay stats.
- Boss stage loads after Stage 3.
- Boss has a visible health bar, at least 3 attacks, and phase 2 behavior.
- Boss defeat leads to a clear screen.
- Restarting from death works.
- Code is structured so new cards, stages, enemies, and bosses can be added without editing unrelated systems.

---

## 20. Key Risk Areas

### 20.1 Player Movement Risk

If movement feels unreliable, the whole game fails. Implement player controller carefully before adding many cards or enemies.

### 20.2 Card System Risk

If cards are hard-coded directly into UI or player code, scaling will become painful. Keep card data separate from card effect application.

### 20.3 Boss Readability Risk

Boss attacks must show warnings before damage. Placeholder warning rectangles are acceptable for MVP.

### 20.4 Scope Risk

Do not build the permanent skill tree, procedural generation, or multiple characters before the MVP vertical slice works.

---

## 21. Recommended First Development Order

Codex should start with this exact order:

1. Create project folders and README.
2. Create autoload scripts: Game, RunState, CardDatabase, SignalBus.
3. Create Main scene and MainMenu.
4. Create Player scene and movement script.
5. Create Stage01 with TileMap placeholders or simple StaticBody2D platforms.
6. Create HUD.
7. Add player health/damage/death.
8. Add player attack hitbox.
9. Add EnemyBase and Walker.
10. Add Charger and Shooter.
11. Add stage exit and stage loading.
12. Add CardData and 15 card resources.
13. Add card reward screen and effect application.
14. Add Stage02 and Stage03.
15. Add BossStage01 and SlimeKingBoss.
16. Add pause, game over, and clear screens.
17. Tune values and fix soft locks.

The implementation should produce a playable vertical slice before adding extra content.
