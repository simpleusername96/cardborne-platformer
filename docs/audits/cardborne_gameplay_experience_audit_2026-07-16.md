---
type: evidence
status: active
owner: BK
created: 2026-07-16
last_reviewed: 2026-07-17
topic: Cross-discipline diagnosis of Cardborne's current play experience and improvement priorities
scope: Repository state at master commit 37fa8d7 plus external game-design references
source: Repository specifications, production resources, key runtime scripts, release evidence, and external developer research
related:
  - ../product/2d_platform_action_card_game_prd.md
  - ../design/CORE_PLAY_FOUNDATIONS.md
  - ../design/COMBAT_EQUIPMENT_CRAFTING.md
  - ../design/PROCEDURAL_REGION_GENERATION.md
  - ../architecture/FIRST_SLICE_ARCHITECTURE.md
  - ../../.agent/execplans/2026-07-16-core-play-experience-roadmap.md
---

# Cardborne Gameplay Experience Audit

## Purpose

Record the current repository-backed diagnosis and recommended experiments for
improving Cardborne's moment-to-moment play. This document is evidence to consult,
not an accepted product specification or an instruction to execute the roadmap.

## Executive conclusion

Cardborne has passed the point where its main problem is missing infrastructure. It already has a complete fixed-run shell, deterministic state and reward contracts, typed content catalogs, validated room assembly, a persistent equipment economy, a card layer, a six-role enemy vocabulary, a two-phase boss, responsive-layout rules, and extensive automated release checks.

The remaining problem is that **system completeness is ahead of expressive play**.

The current build asks the player to operate many surrounding systems—cards, run levels, coins, materials, blueprints, crafted grades, condition, ammunition, armor, Spirit Stones, consumables, intermissions, a Forge, a minimap, and persistence—while the moment-to-moment action is still concentrated into one contextual attack button, one guard button, and mostly independent enemy responses. The repository is therefore good at proving that the run is valid, deterministic, readable in a formal sense, and settleable. It does not yet prove that the player repeatedly makes satisfying, visible, consequential decisions.

The most important next milestone is not another content expansion. It is an **eight-to-ten minute proof of play** in which:

1. movement is enjoyable with no rewards or enemies present;
2. combat has a repeatable rhythm of observation, decision, commitment, impact, and repositioning;
3. three build directions change player behavior rather than only numbers;
4. one stage creates curiosity, route choice, escalation, and a memorable release beat;
5. one boss tests the verbs taught by that stage and recognizes the player's build;
6. players can explain why they succeeded or failed.

Until that slice is successful in human playtests, additional maps, enemies, currencies, permanent progression, and procedural topology will make the project broader without solving its central weakness.

## Sources

This audit reviewed the canonical product, combat, map, enemy, procedural-generation, UI, visual-system, data-ownership, architecture, and release documents; the active input, movement, combat, card, progression, boss, stage, and validation resources; and the current repository history on `master` as of commit `37fa8d78a0c7ed64bb4f7a05834a599c9a803001`.

The external comparison focused on reusable design principles rather than copying feature lists:

- [Celeste game-feel techniques](https://threadreaderapp.com/thread/1238338574220546049.html): widen timing and positioning windows so difficult movement still respects player intent.
- [Specter of Torment level-design deep dive](https://www.yachtclubgames.com/blog/specter-of-torment-level-design-deep-dive-2-5/): introduce, transform, test, then cool down; every enemy and object placement serves the room's intention.
- [Hollow Knight map interview](https://www.pcgamer.com/how-to-design-a-great-metroidvania-map/): spatial coherence, shortcuts, unique discoveries, and believable geography make traversal worth repeating.
- [Dead Cells hybrid procedural design](https://www.gamedeveloper.com/design/building-the-level-design-of-a-procedurally-generated-metroidvania-a-hybrid-approach-): fixed world logic, purpose-built authored chunks, biome-specific graphs, constrained enemy placement, and dramatic peaks/breaks.
- [Spelunky 2 creator interview](https://blog.playstation.com/2018/08/29/first-look-spelunky-2-gameplay-mossmouth-interview/): first guarantee a safe template-based path, then layer systemic uncertainty and personal run stories around it.
- [Hades design goals and update history](https://www.supergiantgames.com/blog/hades-faq/): replayability comes from player expression, changing runs, reactive worldbuilding, and upgrades that create different play styles.
- [Cuphead developer interview](https://www.gamedeveloper.com/business/road-to-the-igf-studio-mdhr-s-i-cuphead-i-): boss gameplay and timing were established before final animation, then animation was revised to make those patterns readable and memorable.

## Limitations

This is a repository and design audit, not a substitute for hands-on playtesting. Subjective conclusions below are hypotheses backed by the present mechanics and evidence. They must be confirmed with continuous play sessions, recordings, and player interviews.

## Current product shape

The current first run is coherent on paper:

```text
prepare Traveler
 -> clear Ruin Approach
 -> choose card
 -> use Safe Intermission
 -> clear Flooded Works
 -> choose card
 -> use Safe Intermission
 -> clear Broken Sanctum
 -> choose card
 -> use Safe Intermission
 -> defeat Giant Slime King
 -> settle run and persistent rewards
```

The repository's foundations are unusually disciplined for a small game:

- `RunDirector`, `RunState`, and `ProfileState` have explicit ownership boundaries.
- Reward settlement is deterministic and intended to be exactly-once.
- Fixed Stage Plans and authored room templates protect the current run from invalid procedural output.
- `MovementMetrics.gd`, `StageGeometryValidator.gd`, stage-composition validation, and room contracts provide a strong safety net.
- Enemy archetypes define a tell, intended response, punish window, geometry contract, and composition role.
- The UI reads snapshots and emits narrow commands instead of editing gameplay dictionaries.
- The production UI has coherent visual tokens, responsive targets, focus behavior, bilingual copy rules, and dedicated asset ownership.
- The boss scheduler prevents illegal pattern overlap and immediate repetition.

These systems should be preserved. The audit does not recommend replacing the project with a different genre, adding a class system, introducing random affixes, or abandoning the one-Traveler premise.

## Findings

- The fixed-run, persistence, content, map, UI, and validation foundations are
  substantially more mature than the expressive action core.
- Control intent, interaction-rich enemy states, behavior-changing builds, stage
  memory, boss culmination, and human playtest evidence remain the main risks.
- The recommendations below are hypotheses to test behind reversible development
  paths; they do not supersede the active PRD or production contracts.

## Primary diagnosis: why the current game can feel functional but dull

### 1. Too many surrounding systems depend on an unproven action core

The run includes multiple progression and resource layers, but the player's combat vocabulary remains intentionally narrow. A narrow vocabulary can produce a deep game—`N++`, `Celeste`, and classic action games prove that—but only when each input has high expressive range and strongly interacts with space, enemies, timing, and player intention.

Cardborne currently pays the cognitive and implementation cost of an equipment economy before it has shown that sword versus spear, bow versus matchlock, or round shield versus tower shield creates consistently different decisions in ordinary rooms. Condition, ammunition, coins, materials, grades, blueprints, Spirit Stones, cards, and level upgrades can become bookkeeping when the underlying fights resolve through the same approach-and-hit pattern.

**Consequence:** rewards look numerous but do not reliably produce anticipation. The player may understand that a value improved without feeling that the next room will be played differently.

### 2. The contextual attack reduces input burden but also hides agency

The current resolver chooses melee when a qualified close target exists and ranged otherwise, with a small retention window near the boundary. This is technically careful. It also means the game may decide which tool is used, which target qualifies, and whether ammunition is spent at the exact moment the player presses the only attack button.

A contextual action is enjoyable when the result is both predictable and aligned with intent. In a multi-height room, a close enemy, an elevated shooter, line-of-sight rules, and the melee/ranged threshold can make the next action difficult to predict. The HUD's `AttackIntent` preview is therefore not optional presentation; it is part of the control scheme.

**Consequence:** an incorrect tool selection feels like loss of control rather than a tactical mistake. Because attack choice is implicit, the player has less room to express preference or mastery.

### 3. The first card set is more incremental than transformational

`Dash Wake` adds a new offensive route through enemies and is the clearest example of a behavior-changing card. `Aerial Opener` rewards an existing extra-jump sequence with damage and stagger. `Perfect Punish` adds damage to a recovery hit. `Second Wind` heals after a no-damage room. `Last Stand` grants a safety window near death.

These are understandable and implementable, but three of the five mainly alter damage, healing, or survival. The set does not yet create three builds that a spectator could identify from play. The same issue appears in run-level upgrades: direct damage, maximum health, dash cooldown, move speed/air control, and immediate healing are sensible micro-rewards, but they should not carry the promise that builds change verbs.

**Consequence:** card choices may optimize efficiency without opening new plans. The player sees a stronger character but not a different character.

### 4. Enemies are fair but mostly ask isolated questions

The six archetypes cover useful pressure roles. Their specifications emphasize tells, safety floors, recovery, caps, and legal geometry. This is a strong fairness foundation.

The roster is weaker at creating interactions the player can manipulate. Most responses are variations of move, jump, dash, approach, use cover, or attack during recovery. The Shield Guard changes frontal offense and the boss has stagger, but the ordinary roster has few shared states such as breach, reflection, launch, friendly fire, environmental vulnerability, interrupted startup, or positional exposure.

**Consequence:** encounter variety depends heavily on geometry and simultaneous threat lanes. When geometry is simple, enemies can feel like separate timers rather than a system the player learns to control.

### 5. Stage validity has improved faster than stage memory

The current map work correctly distinguishes structural, navigational, tactical, perceptual, rhythmic, and thematic verticality. The repository has also improved branch distribution, elevation, fall recovery, and room composition.

The remaining test is not whether a stage has enough height changes or optional rooms. It is whether a player remembers a place and a decision: the exposed upper route above a flooded basin, the shortcut opened from the far side of a sanctum gate, the ruined ascent where a charger forces a deliberate drop, or the quiet overlook before the boss.

**Consequence:** a route can be legal, readable, and numerically varied while still feeling like a sequence of production templates. A minimap can help orientation but cannot manufacture curiosity or spatial identity.

### 6. The boss is a valid pattern scheduler before it is a culmination

The Giant Slime King has a solid technical contract: four authored pattern families, phase rules, warning floors, no illegal overlaps, add caps, deterministic cleanup, stagger, and exactly-once rewards. The current arena supports melee, ranged, dash, jump, and add cleanup.

Its patterns are still generic action tests unless each one deliberately recalls a lesson and exposes a build-specific opportunity. A boss should not only ask whether the player can dodge four attacks. It should ask whether the player learned to recognize recovery, use elevation, control target priority, guard a committed lane, and exploit the tool/card choices made during the run.

**Consequence:** the boss can feel detached from the preceding stages and can collapse into an 80-health endurance test.

### 7. World presentation is split between a maturing shell UI and prototype action scenes

The UI direction is coherent: flat borderless planes, a restrained drowned-ruin palette, purpose-specific backdrops, production illustrations, and clear semantic roles. By contrast, current stage and boss scenes still rely heavily on `Polygon2D`, flat color masses, procedural shapes, scale changes, and color flashes for actors and terrain.

Placeholder presentation is acceptable while mechanics change. The problem is not that final art is absent. The problem is that impact, material, motion, danger, and place are also gameplay information. A flat polygon can prove collision and timing but cannot fully prove silhouette recognition, anticipation, hit confirmation, atmosphere, or emotional escalation.

**Consequence:** the shell can promise a specific ancient-industrial world that the playable scene does not yet deliver. Players spend most of the run in the less-developed presentation layer.

### 8. Automated confidence is high while experience evidence is thin

The repository's 81-check release gate is valuable and should remain. The release notes correctly state that those checks cannot determine subjective fun, pacing, reward pressure, or build satisfaction.

The process now needs equally explicit human gates. Without them, the project risks responding to dullness by adding more validated content and more rules, because those are the kinds of improvements the current evidence system can measure.

**Consequence:** technical progress remains visible while the most important product risk stays anecdotal.

## Priority classification

### A. Essential foundations

These are required for the game to behave predictably and support fair evaluation:

1. gamepad support, action glyph switching, and parity with keyboard navigation;
2. buffered attack/dash input and explicit cancel/commit rules;
3. a reliable next-attack forecast tied to the exact `AttackIntent` that will execute;
4. clear damage source, invulnerability, stagger, guard, ammunition, and condition feedback;
5. short, stable retry paths and deterministic stage snapshots;
6. removal or quarantine of production-path legacy class/skill compatibility;
7. playtest telemetry and repeatable combat/stage fixtures;
8. no softlocks, invalid stages, reward duplication, or persistence corruption.

### B. Improvements that directly create enjoyment

These should receive most design and engineering attention:

1. a satisfying movement-only course;
2. an explicit combat rhythm with meaningful commitment and hit confirmation;
3. three recognizable build families built from existing tools, guard, movement, and cards;
4. enemies that create manipulable states and interact with terrain;
5. one stage with a memorable spatial thesis, visible route consequences, and tension/release pacing;
6. rewards that announce a new future decision;
7. a boss that tests learned verbs and build identity;
8. action-scene animation, sound, camera, and effects sufficient to make timing and impact legible;
9. compact worldbuilding that explains why the player is here and why the places differ.

### C. Secondary polish to postpone

These should not lead the next milestone:

- more normal enemy archetypes;
- more currencies, grades, equipment slots, Spirit Stones, or card rarity tiers;
- multiple heroes or classes;
- active-skill bars;
- random affixes;
- additional regions or bosses;
- final commercial art across the whole run;
- full procedural stage topology;
- multiple save slots, mid-run continue, seed selection, leaderboards, or daily runs;
- a generic behavior-tree framework;
- a broad rewrite of stable state and persistence systems.

## Area-by-area evaluation

## Core gameplay loop

### What works

The run has clear macro cadence, bounded duration, stage rewards, intermissions, a final boss, and persistent settlement. The separation between run growth and profile growth is understandable. The death choice preserves player agency without allowing reward rerolls.

### What weakens the experience

The loop currently emphasizes acquisition before demonstrating why the acquired item will make the next minute more interesting. Multiple reward types arrive in a short first run, especially equipment blueprints and permanent items, so individual discoveries can lose significance.

### Intended player experience

Every major reward should create a specific anticipation sentence: “Now I can cross chargers instead of retreating,” “My precise guard creates a ranged punish,” or “The upper route is worth taking because this build converts air attacks into dash resets.”

### Practical change

For the core-play milestone, temporarily reduce the visible economy to:

- one run currency with a safety-versus-power spending choice;
- one persistent material family used only after the run;
- one consumable;
- cards and equipment models that visibly change behavior.

Keep the existing broader data and persistence implementation dormant behind feature flags. Do not delete it before the playtest result is known.

### Small test

Run an eight-minute Ruin slice with only coins, one potion, one card reward, and preselected equipment. Ask players what changed after each reward.

### Success criteria

- At least 80% of testers can describe the next decision created by the reward without reading its numeric values again.
- No tester names more than three currencies/resources as relevant during the slice.
- Reward-screen time decreases while post-reward experimentation increases.

## Player controls and movement

### What works

The controller already implements acceleration, air control, coyote time, jump buffering, variable jump, extra jump, dash, crouch, fast fall, one-way drop-through, rope climbing, knockback, and fall recovery. Movement metrics are centralized and consumed by map validation.

### What is missing or weak

- No production gamepad path is defined.
- Arrow-key defaults are valid but should not be the only familiar desktop option; WASD aliases should ship by default.
- Jump has buffering, but equivalent queue behavior is not clearly established for attack and dash after recovery or landing.
- Corner correction, landing forgiveness, and intent-friendly ledge behavior are not part of the current movement contract.
- Crouch, fast fall, extra jump, dash, rope, and one-way drop are all present before the game has proven that each has a distinct recurring job.
- Rope climbing refills aerial resources, which may trivialize adjacent route commitments unless explicitly authored around that rule.

### Intended player experience

The player should feel that the character obeys the intended action even when the physical input is a few frames or pixels imperfect. Difficulty should come from choosing and sequencing movement, not from losing a correct intention at an input boundary.

### Practical change

- Add gamepad bindings and automatic keyboard/gamepad glyph switching.
- Add 80–120 ms buffers for dash and attack where they do not violate committed recovery.
- Prototype jump and dash corner correction using conservative values derived from the current collider.
- Define a movement-role matrix: single jump for ordinary traversal, extra jump for correction/vertical continuation, dash for horizontal commitment and combat repositioning, fast fall for timing, rope for safe vertical navigation, crouch only where it creates a meaningful route or defense choice.
- Disable any movement verb in the first proof stage that does not receive teach/transform/test use.

### Small test

Build a three-room movement dojo with no enemies or rewards: flow course, correction course, and speed route. Record input, failure location, and retry count.

### Success criteria

- Median first-clear time improves on the second attempt without instruction text.
- At least 80% of failures are attributed by the player to a visible timing/route mistake rather than “the input did not come out.”
- Movement-only enjoyment reaches at least 4/5 for the target audience.
- Accidental crouch/drop-through and unintended rope attachment occur less than once per complete course.

## Combat and enemy interactions

### What works

Combat phases are deterministic, guard timing is explicit, equipment models have real reach/cadence/resource differences, enemy attacks have warning and recovery floors, and the roster covers occupier, burst, ranged, guard, vertical, zone, and summoner pressure.

### What is moving in the wrong direction

The combat implementation has accumulated too many responsibilities in `PlayerCombatController.gd`, while the design asks one contextual attack to carry melee/ranged choice, target resolution, ammunition use, card triggers, Spirit effects, projectile spawning, legacy compatibility, and presentation snapshots. Enemy fairness rules are stronger than enemy interaction rules.

### Intended player experience

A normal exchange should have a readable five-beat rhythm:

```text
observe tell
 -> choose response and position
 -> commit to attack/guard/movement
 -> receive strong confirmation
 -> exploit recovery or reposition
```

The player should be able to explain not only what attack occurred, but why that tool was chosen and what opportunity it created.

### Practical change

Prototype three attack-control variants in the same combat fixture:

- **A: improved contextual attack.** Keep current resolution, but show a persistent world-space target bracket and melee/ranged forecast before input. Never spend ammunition unless the preview already showed ranged.
- **B: one-button explicit split.** Tap `Attack` for melee; hold past a short threshold for ranged. The hold must not add a charge mechanic; it only states intent. Keep guard on its own button.
- **C: dedicated melee and ranged actions.** Give each tool its own remappable
  action while keeping automatic target selection. This directly tests whether
  the one-button constraint, rather than only its forecast, causes lost agency.

Do not choose by preference alone. Test prediction accuracy, accidental ammunition use, response time, and player confidence.

Add three shared interaction states before adding enemies:

1. **Exposed:** an enemy in authored recovery takes enhanced stagger and shows a distinct pose.
2. **Breach:** a precise guard or correct flank temporarily opens defense.
3. **Interruptible:** a small set of startups can be stopped by the correct tool, while others remain committed.

Use these states across existing archetypes. For example, a Charger becomes Exposed after a wall/endpoint stop; a Shield Guard becomes Breached after precise guard or rear contact; a Shooter startup is Interruptible at close range; a Leaper is Exposed on landing; a Sentry's final aim lock is committed but its post-shot recovery is open.

Add the minimum impact package: hitstop, attacker/enemy recoil, one clear hit flash, distinct guard/precise-guard sounds, enemy defeat timing, and a small camera impulse with an accessibility toggle. Text such as “TOO EARLY” should be reserved for the Trial or an optional training overlay, not ordinary repeated combat.

### Small test

Create one combat dojo containing Walker, Charger, Shooter, and Shield Guard fixtures plus a two-enemy mixed encounter. Run all three input variants and the shared-state pass with identical stats.

### Success criteria

- Players predict the executed tool correctly on at least 95% of attacks.
- Accidental ranged-resource spending is below 2% of attacks.
- At least 80% of testers identify Exposed and Breach without reading debug labels.
- Testers use movement, guard, melee, and ranged in the mixed encounter; no single response resolves every actor safely.
- Damage taken while the player reports “I could not see what happened” falls below 10% of damage events.

## Map structure and exploration

### What works

The authored-room pipeline, movement-derived constraints, safe entries, branch/return sockets, fall recovery, stage-specific profiles, and room-intention guideline are the correct foundation. The recent map pass has already improved elevation and route distribution.

### What remains weak

The project still needs proof that route choices remain meaningful during continuous play, that landmarks survive placeholder art, and that exploration produces information and anticipation rather than short detours for another pickup.

### Intended player experience

Each stage should be remembered as a physical event, not a color set:

- **Ruin Approach:** climb a broken outer ascent, deliberately drop through a collapsed section, then rejoin above a known landmark.
- **Flooded Works:** descend into a basin, learn a timing cycle, then escape through a pump shaft while choosing exposed dry routes or slower hazard-managed routes.
- **Broken Sanctum:** cross and reopen an interlocked gate complex, then traverse earlier space from a new height using a visible shortcut.

### Practical change

For the next milestone, fully author only Ruin Approach. Give it:

- one landmark visible from at least three rooms;
- one route split lasting more than one room;
- an exposed fast line and a sheltered slow line with different enemies and reward information;
- one world-state change such as a gate, collapse, or shortcut;
- one quiet overlook/recovery beat;
- one final encounter that combines only previously taught elements.

Every room must retain a one-sentence intention and name the enemy-terrain relationship. Remove enemies that do not support that sentence.

### Small test

After one blind run, give players a blank seven-node sketch and ask them to mark the landmark, split, reward route, shortcut, and final room.

### Success criteria

- At least 70% reconstruct the macro route and landmark correctly.
- Route choice is not lopsided beyond 70/30 unless one route is intentionally expert-only.
- Players can state a non-numeric reason for their chosen route.
- No required room exceeds eight seconds without a decision, anticipation cue, or meaningful traversal action.
- The stage shows a clear tension/release waveform in room time, damage, and player-reported intensity.

## Equipment, skills, upgrades, and resource progression

### What works

The six equipment models are a compact sidegrade framework. Deterministic crafting avoids failed-roll frustration. Persistent unlocks, material grades, and exactly-once settlement are technically robust. Passive Spirit Stones fit the limited input scope.

### What is weak or unnecessary now

- Grade upgrades lean toward direct numerical improvement.
- The current card pool does not yet establish distinct builds.
- Condition wear, ammunition, potion charges, coins, run salvage, materials, blueprints, grades, stones, armor, run levels, and cards can all demand attention in a short run.
- Fixed early rewards risk turning discovery into onboarding inventory.
- “Skills” exist mainly as historical compatibility concepts; active skills are out of scope and should not remain visible in production architecture or UI.

### Intended player experience

The player should choose among three recognizable approaches without selecting a class:

1. **Pursuit:** convert dash and aerial movement into close-range pressure.
2. **Counter:** create openings through precise guard and recovery recognition.
3. **Control:** manage lanes, ammunition, and target priority at range.

Equipment, cards, and Spirit Stones should reinforce these approaches while allowing hybrids.

### Practical change

- Treat run-level upgrades as deliberately small maintenance choices.
- Make cards the primary behavior-changing run layer.
- Give each equipment model one rule-changing identity before increasing grade power.
- Temporarily disable condition wear during the core-combat tests; re-enable it only if repair creates an interesting expedition decision rather than a maintenance tax.
- Keep ammunition because it differentiates ranged tools, but ensure field recovery and UI make spending intentional.
- Spread permanent equipment discoveries across milestones instead of granting most models during Stage 1.

Recommended first card pass:

- **Dash Wake:** keep; it creates a new route through combat.
- **Aerial Opener → Aerial Relay:** the first attack after the extra jump gains stagger and, on an Exposed target, restores the air dash. This creates a loop rather than only damage.
- **Perfect Punish → Counterclaim:** a precise guard Breaches the attacker; the next hit during that window gains a tool-specific effect, not generic damage.
- **Second Wind → Clean Momentum:** clearing a required encounter without health damage grants one visible momentum charge used by the next dash or guard. Avoid passive healing as the headline.
- **Last Stand:** keep as an accessibility/safety card, but do not label it the most exciting rarity merely because it is rare.
- Add one Control card that changes projectile behavior or ammunition economy only when the player hits an authored recovery/weak point.

### Small test

Offer three prebuilt loadouts with equal total power in the same two-room gauntlet. Hide build names and ask observers to identify the approach from recorded play.

### Success criteria

- Observers identify Pursuit, Counter, and Control correctly in at least 80% of clips.
- Each build changes route, target priority, or timing—not only clear speed.
- No option exceeds the others by more than 15% in median clear time without paying a clear safety/resource cost.
- Players voluntarily experiment with the selected effect within the first room after acquisition.

## Monsters and bosses

### What works

The enemy catalog has strong readability and geometry constraints. The boss scheduler, cleanup, warning floors, add caps, and authored arena protect fairness.

### What needs improvement

Enemy variants mainly adjust timing, health, range, and presentation. They need more stage-specific relationships with terrain and shared interaction states. The boss patterns need explicit learning provenance from earlier rooms.

### Intended player experience

A boss phase should feel like a compressed review of the player's journey, followed by a novel combination. Players should recognize the component questions, then discover that their build changes the best punish opportunity.

### Practical change

Map the Slime King patterns to learned verbs:

- **Body Bump:** lane commitment; jump/elevation avoids it, precise guard causes a large Breach, endpoint recovery supports melee.
- **Jump Slam:** movement/readability test; shadow exit then shockwave timing; landing creates an Exposed close-range window.
- **Poison Bands:** route and ranged-control test; guaranteed safe space remains, but the boss exposes a ranged weak point while separated.
- **Small Slime Summon:** target-priority test; adds interact with Dash Wake and area control but cannot body-block both legal responses.

Phase 1 teaches one pattern at a time with generous recovery. Phase 2 chains only learned pairs and changes positioning, not merely speed. The phase transition should alter arena use or boss vulnerability, not only tint and tempo.

### Small test

Run the boss with baseline equipment and the three prebuilt loadouts. After each death, ask the player to name the failed response and the next intended adjustment.

### Success criteria

- After one exposure, at least 80% identify the correct response to each pattern.
- At least 70% of deaths are correctly explained by the player.
- Baseline players win within two to five attempts; experienced players can win cleanly without the fight becoming trivial.
- Every build has at least one advantageous punish window and one pattern that still requires execution.
- Time spent damaging a non-interactive health sponge is minimized; the fight's duration comes from decisions and pattern resolution.

## User interface and game-state communication

### What works

The snapshot/command architecture, responsive layout, focus rules, bilingual copy, exact cost comparison, minimap contract, attack-intent consistency, and field receipts are strong.

### What is missing or excessive

- Gamepad input and glyphs are absent from the production contract.
- Repeated combat-state text can compete with world-space tells.
- Build effects need previews that explain changed behavior, not only descriptions.
- The game needs a concise death explanation and source history.
- The large number of bottom-dock states can turn the HUD into an equipment dashboard during simple fights.

### Practical change

- Add automatic device detection and glyph sets.
- Keep the next attack/tool forecast close to the target or player, with the bottom dock as confirmation.
- Replace repeated guard timing text with animation, sound, meter response, and optional training text.
- Card rewards should show a tiny live demonstration or before/after diagram for the changed action.
- Add a death recap with the final damage source, missed response category, and retained/lost state.
- During early playtests, log every HUD element noticed by players; remove elements that do not affect an immediate decision.

### Success criteria

- Players correctly predict attack tool, guard state, and damage source without debug text.
- Keyboard and gamepad complete the full required flow with identical commands.
- No more than one persistent HUD element is present without supporting a decision expected in the next few seconds.

## Visual presentation, atmosphere, worldbuilding, and narrative

### What works

The selected drowned ancient-industrial ruin direction is coherent and constrained. The shell UI has a consistent palette, asset strategy, and separation between expressive raster art and structural live controls.

### What is missing

Playable world actors and terrain remain prototype geometry. There is not yet enough animation, sound, material response, landmark art, or environmental narrative to judge immersion. The run also needs a compact dramatic premise connecting materials, blueprints, the ruined machinery, the Traveler, and the Slime King.

### Intended player experience

The player should understand the expedition's immediate purpose in one sentence, then learn the world's history from what the stages do: a broken approach, failed drainage works, a sanctum that sealed or worshipped the guardian, and a boss whose behavior belongs to that place.

### Practical change

Create one production-quality Ruin visual/audio slice, not a whole-game art pass:

- a final-enough Traveler silhouette with readable anticipation, attack, guard, hurt, landing, and dash states;
- final-enough Walker, Charger, and Shooter silhouettes and tells;
- one terrain kit with collision-readable mass, foreground rules, and three depth planes;
- one landmark and one world-state-change animation;
- footsteps, jump, dash, melee, ranged, guard, hit, enemy tell, defeat, reward, ambience, and short musical intensity layers;
- sparse environmental evidence tied to equipment/material acquisition.

A possible narrative spine—not yet canonical—is that the Traveler enters a drowned industrial sanctuary to recover a guardian core needed to restore or contain the ruin's machinery. Blueprints and equipment traces belong to failed prior expeditions; the Slime King is a transformed guardian rather than an unrelated final monster. The exact fiction can change, but every existing noun should belong to one causal place.

### Success criteria

- Players distinguish enemy roles from silhouette and motion before reading UI.
- Players identify the stage's landmark and describe one inferred world event.
- Audio alone communicates at least startup, precise guard, player hit, enemy defeat, and boss phase transition.
- Final art work does not begin for later stages until this slice proves the target readability and production cost.

## Difficulty, pacing, rewards, repetition, and replayability

### What works

The PRD sets a bounded run, room-duration targets, stage-entry retries, teaching constraints, and peak/recovery intent. Enemy health growth is limited, and later difficulty is meant to come from composition.

### What needs improvement

Replayability is currently expected from cards, equipment, and future procedural maps, but those layers will not help if room solutions and combat rhythms remain similar. A fixed run with three strong builds is more replayable than randomized rooms with one dominant response.

### Practical change

Use a pacing trace per run:

- room duration;
- time since last meaningful decision;
- damage source;
- retries;
- action mix;
- optional-route choice;
- reward seen/chosen;
- immediate post-reward experimentation;
- reported intensity and confidence.

Target a waveform: preview, transformation, focused test, release, then a stronger cycle. Do not make every room denser. Use easy mastery beats to let the player feel growth.

### Success criteria

- The target 28–38 minute run has no repeated five-minute stretch with the same dominant response and reward type.
- At least half of repeat testers choose a different build or route for a behavioral reason.
- The second run is faster because of learning, but still presents decisions rather than rote execution.

## Code structure, maintainability, and technical limitations

### What works

The architecture documents define sensible domain owners, immutable snapshots, narrow UI commands, deterministic Stage Plans, typed content, validation, and exactly-once transactions.

### Primary technical risks

1. `PlayerCombatController.gd` is a large concentration point for input, phases, target resolution, defense, loadout resources, cards, Spirit effects, projectiles, feedback snapshots, and legacy compatibility.
2. Production combat still contains historical class/skill branches that should no longer shape active code.
3. Per-attack enemy-group scans and line-of-sight checks are acceptable at current scale but should be owned by a query service before content grows.
4. Profile-level supply/condition mutation is coupled too closely to frame-level combat behavior.
5. The validation suite measures many contracts but lacks a first-class playtest record and experience metrics.
6. Large design documents are strong, but implementation can satisfy their numeric acceptance criteria without satisfying their intended player experience.

### Practical change

Use a strangler refactor rather than a rewrite:

- `PlayerCombatInput`: actions, buffering, and command queue.
- `AttackIntentService`: target snapshot, melee/ranged forecast, line of sight, and intent retention.
- `AttackExecutor`: startup/active/recovery, hitbox/projectile dispatch, and cancellation rules.
- `PlayerDefenseController`: guard, precise timing, stability, and defensive reactions.
- `CombatLoadoutRuntime`: current ammunition, condition, Spirit progress, and stage-local equipment state.
- `PlayerCombatFeedbackBridge`: immutable presentation snapshots and semantic cue emission.
- `LegacyCombatAdapter`: migration/test-only compatibility outside the production path.

Persist combat resources at explicit transaction boundaries while retaining crash-safe snapshots, rather than making `ProfileState` a dependency of every attack.

Add `PlaytestRecorder` with a stable schema and opt-in development output. It should record room enter/exit, action commands, resolved intents, damage, enemy state transitions, rewards, route choices, retries, and boss patterns. It must never be a shipping analytics dependency for the first slice.

### Success criteria

- No new behavior is added directly to the monolith after extraction starts.
- Each extracted owner has deterministic fixture tests and no UI dependency.
- Production code no longer branches on retired classes or active skills.
- A complete run can be reconstructed as a compact event timeline for playtest review.

## Procedural generation: intended role and re-entry gates

The dormant generator's intended role is sound: choose compatible authored rooms, encounters, hazards, and rewards under a stage grammar; do not draw arbitrary platforms. Its deterministic retries, named random streams, full-stage validation, generation report, and curated fallback are valuable.

It should not return merely because 1,000 seeds are traversable. Procedural generation multiplies the quality of the authored grammar. If the grammar produces low-impact choices, the generator creates more low-impact combinations and makes diagnosis harder.

### What must be established first

1. **Frozen movement envelope.** The final baseline verbs, buffers, corner rules, dash role, and rope-resource behavior are stable.
2. **Proven combat grammar.** Exposed, Breach, Interruptible, target priority, and tool intent are readable in fixed fixtures.
3. **Approved room library.** Every eligible room passes human playtest for intention, pacing, camera, and enemy-terrain relation—not only schema and geometry.
4. **Stage rhythm grammar.** The generator knows teach, transform, test, release, landmark, set-piece, and recovery roles.
5. **Encounter packages.** Reviewed combinations define threats, safe responses, required geometry, and duration bands.
6. **Reward grammar.** Optional risk predicts reward value and future decision; random placement cannot create decorative branches.
7. **Navigation language.** Landmarks, route previews, rejoin rules, and map discovery remain coherent under variation.
8. **Experience telemetry.** Seed reports include repetition, decision gaps, route imbalance, encounter duration, damage concentration, and fallback reasons.
9. **Curated fixed benchmark.** The fixed Ruin slice remains the quality baseline against which generated variants are compared.

### Recommended re-entry sequence

1. **Encounter variation inside fixed rooms.** Vary only reviewed encounter packages and rewards at compatible anchors.
2. **Optional-route offer variation.** Keep the macro critical path fixed; select among approved optional branches and route rewards.
3. **Slot-bounded room variation.** Swap rooms only within authored rhythm slots such as `teach_charger`, `route_choice`, or `release_overlook`.
4. **Constrained graph variation.** Allow bounded room order and branch/rejoin changes after the earlier layers preserve stage identity.

The boss arena, first tutorial, major landmark rooms, world-state set pieces, and narrative anchors should remain authored.

### Additional generation quality checks

Do not collapse these into one score. Report them separately:

- repeated primary lesson within a rolling window;
- consecutive rooms with no meaningful decision;
- repeated silhouette or traversal verb;
- route-choice risk/reward differential;
- high-attention threat overlap;
- expected encounter duration;
- damage-source concentration;
- landmark visibility and distance;
- branch divergence and rejoin distance;
- reward drought and reward clustering;
- safe-entry and recovery spacing;
- generated content not previously taught;
- fallback frequency by stage profile.

### Re-entry success criteria

- Generated seeds match the fixed benchmark on player-rated clarity, pacing, and enjoyment within an agreed tolerance.
- Players can still name the stage identity and landmark after different seeds.
- Variation changes decisions, not only room order.
- No seed introduces a new lesson in a mixed-pressure room.
- The generator can be disabled without invalidating progression or narrative.

## Recommendations

The next release target should be renamed internally from “complete first run” to **Core Play Proof**. Its purpose is not to expose all existing systems. It is to answer one question:

> Is moving, fighting, choosing a build, exploring one stage, and defeating one boss enjoyable enough that players voluntarily restart to try a different approach?

A positive answer unlocks economy refinement, additional stage production, and constrained procedural variation. A negative answer means the project should continue iterating on movement, combat, rooms, and build interactions without adding breadth.

## Final priority order

1. Instrument and playtest the current baseline.
2. Add gamepad parity and intent-friendly input buffering.
3. Compare contextual, tap/hold, and dedicated melee/ranged attack intent in a combat dojo.
4. Add shared enemy states and the minimum impact-feedback package.
5. Build one excellent Ruin stage around a memorable spatial thesis.
6. Replace primarily numerical cards with three recognizable build directions.
7. Rework Slime King as a learned-verb and build-expression exam.
8. Reduce or defer resource layers that do not create decisions.
9. Produce one final-enough world/animation/audio slice.
10. Split the combat monolith behind stable interfaces.
11. Reintroduce procedural variation in layers, beginning with encounter packages.
12. Expand content only after the Core Play Proof passes human gates.
