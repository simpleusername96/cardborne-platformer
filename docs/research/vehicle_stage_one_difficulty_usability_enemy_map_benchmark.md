---
type: evidence
status: active
owner: BK
created: 2026-07-22
last_reviewed: 2026-07-22
topic: Vehicle Stage 1 difficulty, usability, enemy behavior, encounter composition, and map structure
scope: Advisory evidence for improving the implemented vehicle run without replacing its core combat identity
source: Owner play feedback on 2026-07-22, current master code and specs, rendered captures, and linked external references
related:
  - ./vehicle_led_isometric_action_reference_analysis.md
  - ../product/vehicle_content_expansion_spec.md
  - ../product/vehicle_stage_one_experimental_spec.md
  - ../design/vehicle_stage_one_future_directions.md
---

# Making Stage 1 Learnable Without Making It Flat

## Purpose

This report examines why the current first stage can remain enjoyable while still being too difficult to clear, and recommends changes to usability, enemy behavior, encounter composition, and map structure. It combines the implemented game state on `master`, the owner's July 22 play feedback, current product documents, rendered captures, and lessons from adjacent genres.

This is an evidence and design-recommendation document, not an accepted product specification or implementation plan. Exact tuning values below are test hypotheses. They should be accepted, revised, or rejected through playtesting rather than treated as facts.

## Executive Summary

The current game should not be made easier by removing manual aim, flattening enemy behavior, or drifting into a passive survivor-like loop. The owner's feedback that the game is hard **but not unfun** is important: the held primary fire, manual threat selection, dash, opening-shot rhythm, passive seekers, EMP, pickups, installations, and card rewards already produce a viable action core.

The main problem is that Stage 1 behaves like a high-pressure challenge preset before it has completed its teaching job. The current configuration combines a 204-enemy population, a 48-enemy active cap, a 6.5 threat budget, up to three ranged commits, up to two denial commits, and simultaneous increases to enemy movement, projectile speed, damage, and recovery. The first swarm activation rectangle already overlaps the player start. From the catalog and activation rules, it is reasonable to infer that roughly 27 swarm enemies plus a nearby authored chaser can activate at or immediately after deployment. A small move toward a neighboring region can then fill the active cap. This is a code-derived inference, not captured player telemetry.

The strongest comparable games do not rely on low difficulty. They make pressure legible and staged:

- *Minishoot' Adventures* preserves manually directed ship combat while offering aim assistance, auto-fire, game-speed options, and multiple difficulty modes.
- *Hades* keeps the core combat intact while offering an opt-in, failure-responsive resilience system and permanent progress.
- *Dead Cells* exposes granular assist settings instead of forcing one binary easy mode.
- *Assault Android Cactus* uses patterned projectile series and transforming arenas to turn high enemy density into readable spatial problems.
- *DOOM (2016)* uses resource incentives and attack-token coordination so aggression is rewarding without every enemy attacking at once.
- *Enter the Gungeon* and modern encounter-design practice show that authored room structure, readable cover, and controlled role sequencing matter as much as raw enemy statistics.

The recommended direction is therefore:

1. Keep the current high-pressure tuning as an optional **Onslaught** preset instead of using it as the first-clear baseline.
2. Re-author Stage 1 as a pressure curriculum: safe arrival, one enemy language at a time, an early behavior-changing reward, one mixed-role decision, a generator compound, an optional retreatable field boss, and an isolated boss exam.
3. Coordinate enemies at four layers: encounter beat, attack tokens, spatial sectors, and individual behavior. This should stop crowd clumping and simultaneous unreadable commitments without making enemies passive.
4. Replace large overlapping activation rectangles with authored gateways and combat pockets connected inside the same continuous map.
5. Add optional usability controls—light aim friction, game-speed adjustment, hold/toggle fire, stronger damage-source feedback, and checkpoint/adaptive-resilience assists—without changing the default identity of manual targeting.
6. Instrument first-run failures before broad tuning. The project currently has no natural-play telemetry, so exact population and damage values should remain provisional.

## Sources

### Current project evidence

The current-state analysis was based on these implementation and product sources:

- `scripts/vehicle/vehicle_stage_one.gd`: player health and actions, tutorials, progression, defeat flow, minimap integration, settings access, upgrade cadence, and target presentation.
- `scripts/player/vehicle_primary_weapon.gd`: held-fire cadence and the one-second charged opening shot.
- `scripts/encounters/vehicle_encounter_director.gd`: active threat budget and simultaneous attack-family limits.
- `scripts/vehicle/vehicle_stage_catalog.gd`: Stage 1 world bounds, spawn groups, activation regions, cover, objectives, pickups, and crates.
- `scripts/enemies/vehicle_enemy.gd` and `scripts/enemies/vehicle_enemy_archetypes.gd`: individual state machines, role statistics, telegraphs, projectile behavior, and recoveries.
- `scripts/autoload/pivot_settings_store.gd`: currently available language and audio settings.
- `docs/product/vehicle_content_expansion_spec.md`: active content and difficulty targets.
- `docs/product/vehicle_stage_one_experimental_spec.md`: the accepted Stage 1 interaction model.
- `docs/design/vehicle_stage_one_future_directions.md`: later-stage design direction.
- `.godot/threat-arcs-ko-final2/01-deployment.png`, `02-open-combat.png`, and `03-installations-route.png`: recent rendered evidence of deployment, combat density, and route presentation.
- Owner play feedback on July 22, 2026: Stage 1 is too difficult to clear, but the combat is not inherently unfun; usability, enemy behavior and composition, and map composition remain weak.

No natural-play event log, death heatmap, input recording, or cohort telemetry was available. Any numerical recommendation is therefore an expert tuning hypothesis rather than an observed performance threshold.

### External references

The comparison set intentionally spans several adjacent genres rather than copying one game:

- [*Minishoot' Adventures* official product page](https://store.playstation.com/en-us/product/EP4425-PPSA34242_00-PEWPEWPEWPEWPEEW): handcrafted top-down ship action, exploration upgrades, multiple difficulties, aim assistance, auto-fire, and game-speed options.
- [*Hades* official FAQ](https://www.supergiantgames.com/blog/hades-faq/) and [*Hades II* official FAQ](https://www.supergiantgames.com/blog/hades2-faq/): failure-integrated progression and optional God Mode rather than a separate diminished combat game.
- [*Dead Cells* Update 29 notes](https://dead-cells.com/patchnotes/29): granular Assist Mode controls for damage, health, and continuing from a biome.
- [*Assault Android Cactus* official site](https://www.assaultandroidcactus.com/), [GDC accessibility/depth talk](https://media.gdcvault.com/gdc2016/Presentations/Dawson_Tim_Balancing_Accessibility_Against.pdf), and a [developer interview about projectile readability](https://themanshu.wordpress.com/2016/11/20/assault-android-cactus-interview/): high-density twin-stick combat, pressure clocks, transforming spaces, and designed projectile patterns.
- [*Enter the Gungeon* developer Q&A](https://www.gamedeveloper.com/design/q-a-the-guns-and-dungeons-of-i-enter-the-gungeon-i-): structured procedural-room grammar and defensive environmental interaction.
- [*DOOM (2016)* push-forward combat talk](https://www.gdcvault.com/play/1024940/Embracing-Push-Forward-) and [AI analysis](https://www.gamedeveloper.com/design/cyber-demons-the-ai-of-doom-2016-): aggressive resource loops and limited attack-type tokens.
- [Rocksteady's 2024 enemy-AI talk](https://www.gdcvault.com/play/1034777/AI-Summit-Enemy-AI-in) and [presentation slides](https://media.gdcvault.com/gdc2024/Slides/GDC%2Bslide%2Bpresentations/Campo_Tucci_EnemyAIIn.pdf): activity-, group-, and agent-level coordination in fights with many enemies.
- [Enemy design for group melee combat](https://www.gamedeveloper.com/design/enemy-design-and-enemy-ai-for-melee-combat-systems): tells, attack slots, offscreen behavior, and group rhythm.
- [Combat encounter pacing and sequencing](https://www.gamedeveloper.com/design/the-art-and-science-of-pacing-and-sequencing-combat-encounters): role changes as an intensity lever and the value of staged escalation.
- [Game Accessibility Guidelines: game speed](https://gameaccessibilityguidelines.com/include-an-option-to-adjust-the-game-speed/), [aim/steering assistance](https://gameaccessibilityguidelines.com/include-assist-modes-such-as-auto-aim-and-assisted-steering/), and [control sensitivity](https://gameaccessibilityguidelines.com/include-an-option-to-adjust-the-sensitivity-of-controls/): optional assistance that preserves player choice.
- [*God of War Ragnarök* accessibility options](https://www.playstation.com/en-us/games/god-of-war-ragnarok/accessibility/) and [*The Last of Us Part II* accessibility options](https://www.playstation.com/en-us/games/the-last-of-us-part-ii/accessibility/): graduated aim support, lock-on behavior, game speed, and combat readability controls.
- [Level Design Book: combat and cover](https://book.leveldesignbook.com/process/combat/cover) and [The Door Problem of Combat Design](https://www.gamedeveloper.com/design/the-door-problem-of-combat-design): training arenas, sightlines, entrances, cover, and geometry that encourages entry rather than doorway camping.

These games solve different problems and should not be treated as feature checklists. The useful comparison is the design pattern each one demonstrates.

## Current Implemented Baseline

### What is already working

The current combat has several properties worth protecting:

- **Direct agency:** the player decides where the primary weapon points and may hold fire continuously.
- **Rhythm inside continuous fire:** after one second without firing, the next opening shot gains higher health damage and much higher structure/stagger effectiveness. This creates a real decision between constant pressure and a deliberate re-entry shot.
- **Mobility:** the dash is fast, short, and frequent enough to be a core positioning action rather than a rare panic button.
- **Layered loadout:** passive seekers and the manual EMP add background pressure and one explicit area-control decision without demanding many action buttons.
- **Priority targeting:** installations, ranged enemies, bosses, pickups, and objectives can make manual targeting meaningful.
- **Continuous authored field:** exploration, ordinary fighting, upgrades, field objectives, and a boss can coexist without becoming disconnected menus or isolated wave boxes.
- **Readable systemic hooks:** the implementation already has role metadata, telegraph states, recovery states, threat budgets, target HUD, minimap, threat arcs, upgrade cards, and damage-source tracking. The project does not need to invent all of these foundations again.

The correct question is not “How do we replace the combat?” It is “How do we stage and explain this combat so a first-time player can learn to use it?”

### Where the current first-clear experience conflicts with the specification

The product specification describes a safe read followed by open pressure, a meaningful installation decision, a reward, and a boss. The runtime currently front-loads too many pressure variables:

| Current contract | Stage 1 value | First-clear consequence |
|---|---:|---|
| Total population | 204 | Attrition and visual density dominate a stage that still needs to teach. |
| Active cap | 48 | A novice can face a crowd large enough to hide individual roles and openings. |
| Threat budget | 6.5 | Multiple expensive commitments can overlap even when the enemy count is bounded. |
| Ranged commit limit | 3 | Projectile lanes can arrive from several sources before the player has learned target priority. |
| Denial commit limit | 2 | Mines/zones can remove escape space while ranged and contact pressure continue. |
| Enemy movement multiplier | 1.15× | Less time to parse silhouettes and reposition. |
| Projectile-speed multiplier | 1.12× | Less reaction time. |
| Damage multiplier | 1.25× | Fewer recoverable mistakes. |
| Recovery multiplier | 1.20× | Shorter player punish windows. |

The difficulty is not caused by one number. Five different difficulty dimensions—population, concurrency, movement, projectile reaction time, punishment, and recovery—were raised together. When a novice dies, the game cannot show which skill should improve because several skill checks fail at once.

### Entry-pressure finding

The Stage 1 catalog places the player near `(330, 1100)`. The first 27-unit swarm group is centered near `(900, 1110)` and uses an activation rectangle extending approximately 620 pixels horizontally and 430 pixels vertically from that anchor. That rectangle includes the start position. A separately authored chaser near `(900, 1110)` is also within its activation distance.

Accordingly, the code implies that roughly 28 enemies may become active at or immediately after deployment. A small movement toward the next activation region can push the population toward the 48-enemy cap. This is a particularly severe onboarding mismatch: the tutorial checklist asks the player to learn movement, aim, fire, and dash while the encounter system may already be running a dense combat problem.

### Role-overload finding

Before the first calibration reward at approximately `x >= 1600`, the player can encounter scrap drones, needle drones, minelets, a chaser, a shooter, and a controller. These represent at least six distinct threat languages:

- contact pursuit,
- ranged lane pressure,
- delayed proximity punishment,
- committed lunge,
- standoff shooting,
- area denial/support.

This is not merely “more enemies.” It is more types of attention. A first stage should usually teach a role in isolation or with low-cost fodder before combining it with a second decision-making role.

### Failure-feedback finding

The runtime records `_last_damage_source`, but the defeat flow does not explain the source, the avoidable behavior, or the objective progress that the player achieved. Defeat returns the player to the garage. A pause-menu restart can preserve more immediate run context, while a post-defeat replay performs a broader run reset. This creates a risk that failure feels both informationally thin and more costly than intended.

### Settings finding

The current settings surface mainly covers language and master/SFX volume. It does not yet expose aim assistance, fire mode, control sensitivity, game speed, incoming-damage scaling, projectile-speed scaling, telegraph contrast, camera shake, flash intensity, or checkpoint/adaptive-resilience assistance. For this game, those options are not cosmetic extras: they allow different players to access the same manual-targeting combat identity.

## Comparative Genre Analysis

### 1. Handcrafted Top-Down Ship Action: *Minishoot' Adventures*

#### Pattern

This is the closest broad reference because it combines a small vehicle silhouette, manually directed shooting, authored navigation, progression-gated routes, and accessible difficulty controls. Its official feature list includes three difficulty modes, aim assistance, auto-fire, and game-speed options.

#### Why it matters here

The reference shows that manual aim and authored exploration do not require a single uncompromising input or speed profile. Assistance can reduce motor demand while leaving target priority, positioning, and route choice intact.

#### Application

- Preserve free manual aim as the default combat identity.
- Add a narrow, line-of-sight-respecting aim-friction cone rather than a full forced lock-on.
- Offer Off / Light / Strong assistance and Hold / Toggle fire.
- Offer 100% / 90% / 80% game speed as an explicit assist, while keeping timers and telegraphs internally consistent.
- Use upgrades to open visible shortcuts and optional branches, not just to raise damage numbers.

### 2. Failure-Integrated Action Roguelikes: *Hades* and *Dead Cells*

#### Pattern

*Hades* treats failure as part of the progression loop and offers an opt-in God Mode whose resilience grows with repeated deaths. *Dead Cells* exposes granular Assist Mode values, including enemy health/damage and continuation behavior. Neither approach requires deleting enemy patterns or replacing the player's actions.

#### Why it matters here

The owner is enjoying the fight but cannot clear Stage 1. That is exactly the case where a transparent, optional bridge is preferable to secretly weakening the combat for everyone.

#### Application

- Add an optional **Adaptive Hull** assist: after each failed Stage 1 attempt, grant +5% incoming-damage resistance, capped at 30%. Make the current value visible, reversible, and resettable.
- Add a checkpoint-assist option after the first upgrade or relay objective. On defeat, let the player choose “Fresh Deployment” or “Resume from Relay.”
- Keep granular controls separate: incoming damage, projectile speed, aim friction, game speed, and checkpoint behavior should not be bundled into one opaque Easy mode.
- Preserve run progression and explain what is retained or reset before the player confirms a retry.

This does not mean every default clear should use assistance. It means a player who already enjoys the core does not have to abandon it because one pressure curve is mismatched.

### 3. Dense Twin-Stick Combat: *Assault Android Cactus*

#### Pattern

The game creates intensity with many enemies, but its developers explicitly identified the readability problem caused by numerous fast, independent small bullets. Designed projectile series produce recognizable safe and dangerous zones. Transforming stages also change the positioning question rather than only adding more health.

#### Why it matters here

The current Stage 1 visual captures show a large, close cluster of small enemies. If each unit also makes independent movement and attack decisions, density becomes noise instead of strategy.

#### Application

- Convert ranged swarms from independent random shots into short, authored volleys: fan, sweep, alternating lane, or delayed pair.
- Ensure a volley creates at least one readable safe route.
- Change arena conditions at authored beats—open a shortcut, retract a barrier, disable a turret lane, flood/clear a channel—instead of using additional population as the only escalation tool.
- Keep small fodder numerous only when their behavior is visually and mechanically compressible. A flock that moves as one pressure mass costs less attention than 20 individually improvising attackers.

### 4. Aggressive Arena Combat: *DOOM (2016)*

#### Pattern

The push-forward loop rewards aggression with resources. AI coordination limits how many enemies can perform particular attack types simultaneously, producing rhythm inside apparent chaos.

#### Why it matters here

The current game already has a threat budget and commit limits, which is the right foundation. The problem is that the budget is tuned for a high-pressure state and does not yet coordinate spatial occupation.

#### Application

- Preserve the director, but add separate token pools for contact commit, ranged lane, denial, and offscreen attack.
- Scale token availability by encounter beat, not merely stage number.
- Reward destroying high-risk targets with immediate tactical relief: repair shard, EMP charge, opening-shot refresh, or a brief movement boost.
- Make aggression a survival option. A player who identifies and destroys a needle drone or tower should regain space, not merely reduce a distant total counter.

### 5. Structured Bullet-Hell Rooms: *Enter the Gungeon*

#### Pattern

The developers describe the need to teach procedural generation a structured room grammar. Environmental defense such as table flipping provides an immediate answer to nearby bullets. The larger lesson is that fair action rooms are authored spatial arguments, not empty rectangles populated by random threats.

#### Why it matters here

The current map has many rectangular cover pieces and a very large central obstruction. Cover exists, but encounter activation and enemy steering do not consistently turn that geometry into readable tactical choices.

#### Application

- Give every combat pocket one obvious first cover relationship, one escape loop, and one risky flank.
- Avoid narrow entrances that let the player or enemies become stuck at the boundary.
- Tie spawns and role positions to the pocket's spatial grammar: shooters own lanes, chasers own approach arcs, controllers own anchors, and fodder circulates.
- Allow a limited environmental defensive interaction—for example, breaking a coolant pod clears nearby hostile projectiles—if it reinforces the map rather than adding another UI system.

### 6. Large-Group Enemy Coordination

#### Pattern

Modern group-AI practice separates encounter activity, group coordination, and individual agent behavior. Combat-design interviews also emphasize tells, limited attack slots, and restrictions on unfair offscreen attacks.

#### Why it matters here

The current enemies have useful individual startup, active, and recovery phases, but most mobile roles steer directly from their relationship to the player. Without sector ownership or separation, several agents can collapse into the same screen region and obscure one another.

#### Application

Use four coordination layers:

1. **Encounter beat controller** — decides what the current room is teaching, its active population range, and whether reinforcements are allowed.
2. **Threat-token director** — grants permission for contact, ranged, denial, and offscreen commitments.
3. **Spatial coordinator** — assigns approach sectors, firing anchors, support anchors, and a deliberately under-occupied escape hemisphere.
4. **Individual finite-state machine** — executes anticipation, movement, active attack, and recovery.

The individual enemy remains responsive, but it no longer has permission to independently turn every frame into a new group-level decision.

## Findings

### Finding 1: The combat identity is stronger than the onboarding structure

The game has direct target selection, high mobility, useful weapon rhythm, and multiple priority targets. The owner explicitly reports that the game remains fun despite failing Stage 1. Those are signals to preserve the core loop.

The first intervention should be encounter sequencing, not a combat-system replacement.

### Finding 2: Current difficulty is compound, not singular

Population, concurrency, enemy speed, projectile speed, damage, and shortened punish windows all rise together. The player is asked to learn movement, aim, firing rhythm, dash timing, target priority, projectile reading, denial avoidance, and objective routing under nearly immediate crowd pressure.

Reducing only enemy health would likely make the stage faster without making failure more understandable. Reducing only population might still leave unfair multi-role or offscreen combinations. The pressure curriculum must change as a whole.

### Finding 3: The map and encounter director are not yet one system

The map contains routes, cover, installations, and objectives, while the director limits abstract threat costs. However, group activation rectangles overlap the start and neighboring areas, and individual movement does not strongly respect authored combat lanes. The result can look like enemies spilling across a map rather than encounters being designed for it.

### Finding 4: Density needs visual compression and behavioral coordination

Small enemies can be numerous, but only if several of them read as one coherent unit of pressure. Current individual steering and shooting can create a dense clump whose members are difficult to classify or prioritize. The answer is not necessarily fewer enemies everywhere; it is fewer simultaneous independent decisions.

### Finding 5: Failure lacks actionable information

The code knows at least the last damage source, but the player receives little explanation. A difficult first stage needs especially strong failure teaching: what killed the player, what could counter it, how far the player progressed, and what will be preserved on retry.

## Recommendations

### A. Establish Two Pressure Presets

Do not discard the current tuning. Reframe it.

| Contract | First-clear Standard hypothesis | Current tuning / Onslaught |
|---|---:|---:|
| Active at deployment | 0 | approximately 28 may activate |
| Active cap | ramp 12 → 16 → 20 → 24 | 48 |
| Total pre-boss population | approximately 108–132 | 204 |
| Threat budget | 4.0 | 6.5 |
| Ranged commits | 2 | 3 |
| Denial commits | 1 | 2 |
| Enemy movement | 1.10× | 1.15× |
| Projectile speed | 1.00× | 1.12× |
| Incoming damage | 1.00× | 1.25× |
| Enemy recovery speed | 1.00× | 1.20× |

These Standard values are starting hypotheses. In particular, total population should not remain a product goal if encounters are already achieving the intended rhythm with fewer units.

The Standard preset should still demand aiming, movement, target selection, and dash timing. It simply presents those tests in a sequence that a first-time player can parse. Onslaught can preserve the current crowd pressure for later mastery and for players who already understand the threat languages.

### B. Re-author Stage 1 as a Continuous Six-Beat Curriculum

The whole level can remain one connected map. “Combat pocket” describes an authored pressure region, not a separate loading screen.

#### Beat 0 — Arrival and calibration

- Duration target: 15–25 seconds before incoming damage is possible.
- No live enemy activation at deployment.
- Let the player move, aim, hold primary fire, observe the one-second opening-shot charge, and dash through a visible safe lane.
- Use one or two inert destructible targets to demonstrate structure damage.
- Show the first objective and the route landmark from the deployment point.

#### Beat 1 — First contact

- Introduce 10–14 scrap drones as a simple movement-and-spacing problem.
- After a short recovery seam, introduce 6–8 needle drones with a single repeated volley language.
- Do not combine denial, tower fire, and standard enemies yet.
- Cap active pressure near 12.
- Drop a deterministic repair after the learning beat.

#### Beat 2 — Mixed approach and first build choice

- Use 16–20 total enemies, with scrap/needle fodder plus either one standard chaser or one standard shooter.
- Cap active pressure near 16–18.
- Deliver the first upgrade after this beat, ideally 45–75 seconds into natural play.
- Offer a curated starter pool with immediately visible behaviors rather than the full card catalog.

#### Beat 3 — Readable route fork

- Upper route: turret or shooter lane plus mobile fodder.
- Lower route: minelet or chaser pressure plus mobile fodder.
- Each route teaches one relationship between a fixed hazard and a moving enemy.
- The route choice should be visible before commitment, and neither branch should pull critical-path enemies from the other.
- Cap active pressure near 20.

#### Beat 4 — Generator compounds and relay

- Introduce one controller/support language with familiar fodder.
- Cap active pressure near 24.
- Destroying a generator should produce immediate spatial relief and open a return shortcut.
- Place a deterministic repair or defensive pickup before the boss route.
- Keep ordinary enemies from hard-gating progression once the field objective is complete.

#### Beat 5 — Optional field boss and boss exam

- Make the field boss visibly optional and retreatable. Its activation boundary must not overlap the critical path.
- Isolate the stage boss from residual ordinary mobs.
- The boss should examine learned actions: aiming under movement, one clear dash test, one priority target or structure break, and one punish window after a readable recovery.
- Do not introduce an entirely new screen-wide rule in the final phase unless the previous arena has foreshadowed it.

### C. Redesign Enemy Movement by Role

#### Scrap drones and other contact fodder

- Move as loose flocks with separation and a preferred approach sector.
- Reserve at least one low-density hemisphere around the player.
- Commit in small waves rather than all converging on the exact player coordinate.
- After a missed rush, travel past the player and recover before turning. This creates a readable punish window.

#### Needle drones and shooters

- Select authored firing anchors or lanes instead of orbiting purely from a preferred radius.
- Fire recognizable bursts, then relocate during recovery.
- Early Stage 1 should permit at most two active ranged lanes and at most one offscreen commit.
- A damaging offscreen projectile must have a distinct directional cue and enough travel time to react.

#### Minelets and denial enemies

- Treat a denial placement as a group-level token, not an individual entitlement.
- Never allow denial to close every escape route.
- Use a strong pre-placement marker and a stable active-area color.
- Early combinations should pair denial with fodder, not denial plus multiple ranged and lunge threats.

#### Controllers and supports

- Hold an authored anchor instead of continuously drifting with the player.
- Show the supported relationship through one bold tether or shared pulse.
- Breaking the controller should immediately and visibly weaken the group.

#### Towers and installations

- Aim through readable arcs or lanes tied to floor markings.
- Projectiles from basic towers should collide with solid cover.
- If an advanced tower can bypass cover, that exception needs a distinct silhouette, telegraph, and projectile language.

#### Bosses

- Every damaging attack already needs startup, active, and recovery states; preserve this rule.
- Also budget boss adds and boss attacks together. A boss phase should not independently schedule screen-filling pressure while a full ordinary-enemy budget remains active.

### D. Make Map Geometry Teach Combat

#### Replace broad activation rectangles with authored gateways

- Use polygons or explicit gateway volumes aligned to bridges, thresholds, sightline reveals, and objective interactions.
- Activation should occur after the player has enough visible space to enter the pocket, not while standing in the previous pocket or deployment zone.
- Neighboring optional regions should not activate from small lateral movement on the critical path.

#### Give each pocket a readable spatial sentence

Every major combat area should provide:

1. one obvious entry and first safe read,
2. one reliable escape loop,
3. one protected approach to a dangerous ranged or fixed target,
4. one riskier flank with a faster reward,
5. one landmark visible from the previous area,
6. one clean return route after completion.

#### Establish a lane-width test

As a starting hypothesis, critical movement lanes should provide approximately 420–480 pixels of usable width where the player is expected to dash while enemies are present. The actual value should be validated against vehicle collision radius, dash distance, and enemy body sizes. The important rule is behavioral: a player should be able to pass a stalled enemy cluster without relying on perfect collision threading.

#### Use cover as a relationship, not decoration

- A cover block should explain which threat it answers.
- Avoid one massive central block if it creates two long channels with poor cross-reading.
- Prefer convex corners and staggered smaller masses that allow the player to enter, rotate around a threat, and rejoin the main route.
- Keep floor markings, walkable color, blocking edges, and hazard colors consistent so navigation is readable before collision.

#### Separate optional risk from critical progress

- The field boss branch, treasure branch, and critical generator route should have visibly different landmarks.
- Optional threat activation should stop at a clear leash boundary.
- A retreating player should not drag an optional boss into the main objective pocket.

### E. Improve Usability Without Automating the Game

#### Aim support

Default to **Light Aim Friction**:

- Search only within a narrow cone around the manual aim vector.
- Require line of sight.
- Weight the current target, nearest threat to the reticle, dangerous ranged/installations, and recently damaged targets.
- Bend projectile direction only slightly; never turn a backward shot into a forward one.
- Release assistance immediately when the player strongly moves the aim away.

Expose Off / Light / Strong settings. Full lock-on can remain a separate optional mode if later testing justifies it.

#### Fire input

- Preserve hold-to-fire as the default because the owner finds it more enjoyable.
- Offer toggle fire for accessibility.
- Make the one-second opening-shot charge unmistakable through a single bold ring, reticle change, or vehicle pulse—not several small indicators.

#### Damage and defeat feedback

- Add a directional hit indicator that distinguishes contact, projectile, denial, and hazard damage.
- On defeat, show the last and largest recent damage source, one concise counter-tip, furthest objective reached, and whether a retry preserves the current build.
- Use existing damage-source data rather than adding a speculative analytics service first.

#### Combat readability controls

Expose:

- telegraph contrast,
- camera shake intensity,
- hit flash intensity,
- threat-arc visibility,
- aim sensitivity,
- game speed,
- incoming damage,
- hostile projectile speed.

The UI should label assist-modified clears transparently if that matters to later challenge records, but should not shame the player or remove progression.

#### Navigation clarity

- Keep the minimap's visited-cell fog.
- Add a compact legend for player, critical objective, optional boss, upgrade/reward, repair, and unopened cache.
- Use an edge-of-screen objective arrow when the critical landmark is outside the camera.
- Dim completed objectives rather than removing all spatial context.

### F. Turn Rewards into the Teaching Rhythm

The project already has a broad card catalog with primary, opening-shot, elemental, passive, dash, skill, and mobility families. The problem is less the number of cards than the timing and first-run comprehension burden.

#### First-clear reward cadence

- First behavior-changing card after Beat 2, not after several overlapping combat languages.
- One reward at the relay/generator milestone.
- One post-boss reward.
- Optional field boss or cache rewards remain bonus choices.

This avoids turning a short stage into nine mandatory modal interruptions while still letting the player feel a build emerge.

#### Curated starter pool

Use six to eight cards whose effects are immediately visible:

- forked muzzle,
- ricochet,
- opening-shot blast,
- opening-shot stagger/structure bonus,
- one clear elemental status,
- additional passive seeker,
- dash impact or dash recharge,
- EMP radius or recharge.

Do not show several mathematically similar percentage upgrades together during the first choice. Broaden the pool after the first clear or after the player has seen the associated system.

### G. Add Transparent Assistance, Not Hidden Dynamic Difficulty

Recommended optional systems:

#### Adaptive Hull

- +5% incoming-damage resistance after each failed Stage 1 attempt.
- Maximum 30%.
- Visible in the garage and pause menu.
- Toggleable and resettable at any time.
- Explain that enemy behaviors and rewards remain unchanged.

#### Relay resume

- In Assist Mode, unlock a checkpoint after the first major upgrade or relay.
- On defeat, offer Fresh Deployment or Resume from Relay.
- Clearly state which build, objectives, and consumables are restored.

#### Independent sliders/presets

- Enemy damage: 50–100%.
- Enemy health: 75–100% if needed after testing.
- Hostile projectile speed: 80–100%.
- Game speed: 80–100%.
- Aim assistance: Off / Light / Strong.

These ranges are hypotheses and should be calibrated. Their value is that the player can solve the particular barrier they have without making unrelated parts of the game trivial.

## Proposed Stage 1 Contract

The following is a concise target state for a first-clear Standard run:

| Dimension | Proposed contract |
|---|---|
| First incoming-damage opportunity | 15–25 seconds after deployment |
| First upgrade | 45–75 seconds into natural play |
| Roles introduced before first upgrade | Fodder plus one ranged language; at most one standard role |
| Simultaneous attack families in first 3 minutes | At most two |
| Standard active-cap ramp | 12 → 16 → 20 → 24 |
| Standard threat budget | 4.0 starting hypothesis |
| Offscreen damaging commits | At most one early; always distinctly cued |
| Mandatory repairs | After first learning beat and before generator/boss compound |
| Ordinary-enemy gating | No full-clear requirement for critical progression |
| Field boss | Optional, telegraphed, and retreatable |
| Stage boss | Isolated exam of previously taught actions |
| Retry information | Damage source, counter-tip, progress, and retained/reset state |

## Validation and Telemetry Plan

The next tuning pass should add small local debug instrumentation before broad content expansion. This does not require external analytics.

### Capture per attempt

- time to first incoming damage,
- time and location of death,
- damage by source family,
- percentage of damage originating offscreen,
- active-enemy count over time, including median and 95th percentile,
- number of simultaneous attack families,
- time to first repair and first upgrade,
- time spent without advancing the critical objective,
- dash use immediately before damage,
- selected reward and stage progress at defeat.

### First validation sample

Use five to eight players who have not learned the current stage. This is a directional design test, not a statistically representative study.

Ask them to play Standard without coaching, then optionally retry with Light Aim Friction or Adaptive Hull. Observe behavior before asking for opinions.

### Initial acceptance hypotheses

- Every player receives at least 15 seconds of safe control reading.
- The first upgrade appears within 45–75 seconds for a player moving along the critical route.
- No more than two attack families overlap during the first three minutes.
- Less than 5% of Stage 1 damage is caused by an offscreen source.
- The 95th-percentile active population stays at or below 24 on Standard.
- A deterministic repair appears before the generator compound.
- After a defeat, a player can correctly name the threat that killed them and one response they could try next.

If the stage becomes clearable but players stop using dash, target priority, or opening shots, it has become too flat. If players still cannot explain their deaths, reducing health or damage alone has not solved the problem.

## Prioritized Application to the Current Game

### Priority 0 — Preserve fun and repair the first-clear curve

1. Remove deployment-zone activation and guarantee a safe calibration interval.
2. Add a Standard pressure ramp and preserve current values as Onslaught.
3. Move the first curated upgrade earlier.
4. Add deterministic repairs at learning milestones.
5. Surface a concise damage-source and retry-state recap on defeat.

These changes should produce the largest immediate improvement without rewriting the combat identity.

### Priority 1 — Make enemy and map composition deliberate

1. Add encounter-beat and spatial-sector coordination above individual AI.
2. Convert early ranged behavior to authored volleys.
3. Replace broad overlapping activation rectangles with gateway-aligned combat pockets.
4. Give every pocket an escape loop, cover relationship, landmark, and clean return route.
5. Add Light Aim Friction and essential readability controls.

### Priority 2 — Make learning persistent and measurable

1. Implement Adaptive Hull and optional relay resume.
2. Add local attempt telemetry and a debug review screen/file.
3. Refine the starter reward pool from observed first-run choices.
4. Use Stage 2 and Stage 3 to introduce genuinely new role relationships rather than only larger populations.

## What Not to Do

- Do not turn primary fire or targeting into fully passive survivor-style combat.
- Do not remove dash, opening-shot rhythm, installations, or manual priority selection.
- Do not solve difficulty only by lowering enemy health.
- Do not increase intensity only by adding more units of an already learned role.
- Do not let several independent enemies improvise tiny fast projectiles without a shared pattern.
- Do not hide dynamic difficulty changes from the player.
- Do not make every assist option part of one irreversible Easy mode.
- Do not require clearing every ordinary enemy to proceed.
- Do not let optional encounters activate across the critical path.
- Do not add more upgrade families until the first reward cadence and comprehension problem are tested.

## Recommendation Matrix

The following 1–5 impact ratings are an expert design assessment, not player telemetry.

| Workstream | First-clear learning impact | Relative effort | Confidence | Phase |
|---|---:|---:|---:|---|
| Stage 1 pressure curriculum | 5 | 3 | 5 | P0 |
| Failure and retry feedback | 5 | 2 | 4 | P0 |
| Enemy spatial coordination | 5 | 4 | 4 | P1 |
| Combat readability and QOL | 4 | 2 | 5 | P1 |
| Map pocket and activation redesign | 4 | 4 | 4 | P1 |
| Upgrade curriculum and telemetry | 3 | 3 | 4 | P2 |

## Final Recommendation

The game has crossed an important threshold: its core fight can be enjoyable even when the first stage is currently too hard. The best next move is not another pivot. It is to make Stage 1 accurately represent the combat the project wants to teach.

Treat the present 48-active, 204-population configuration as a later-mastery preset. Give Standard a safe deployment, a 12-to-24 pressure ramp, one enemy language at a time, an early meaningful card, map pockets with clean activation boundaries, coordinated attack and spatial tokens, and transparent failure assistance. Then measure whether players can explain their deaths and improve on the next attempt.

The target experience is not “easy.” It is **legible pressure with recoverable mistakes and visible mastery**.

## Limitations

- This analysis includes one owner feedback report, current code/specification inspection, and scripted/rendered captures; it does not include natural-play telemetry or a multi-player test.
- The inferred deployment activation count follows current catalog positions and activation rules but has not been validated through an event log.
- Exact population, timing, lane-width, and multiplier recommendations are tuning hypotheses.
- Reference games use different cameras, progression structures, budgets, and audience expectations. Their patterns are transferable; their exact values are not.
- This report does not authorize implementation. Product decisions should be recorded in the active specification and implementation work should use the repository's planning process when warranted.
