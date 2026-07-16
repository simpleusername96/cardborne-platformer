---
type: spec
status: proposed
owner: BK
created: 2026-07-16
last_reviewed: 2026-07-16
canonical_for: Core Play Proof controls, movement, combat, builds, encounters, stage rhythm, boss testing, and player-experience gates
source: Cardborne gameplay experience audit, current PRD and runtime contracts, and cross-genre developer research
related:
  - ../audits/cardborne_gameplay_experience_audit_2026-07-16.md
  - ./COMBAT_EQUIPMENT_CRAFTING.md
  - ./ENEMIES_TRAPS_GIMMICKS.md
  - ./2D_PLATFORMER_MAP_DESIGN_GUIDELINE.md
  - ./PROCEDURAL_REGION_GENERATION.md
  - ../product/2d_platform_action_card_game_prd.md
  - ../../.agent/execplans/2026-07-16-core-play-experience-roadmap.md
---

# Core Play Foundations

## Status and authority

This specification is a proposed replacement foundation for the next gameplay milestone, named **Core Play Proof**. It does not immediately supersede numeric equipment values, production stage plans, or release contracts. Those remain active until an implementation plan explicitly adopts a section of this document.

The purpose of Core Play Proof is to establish whether Cardborne's central activity is enjoyable before the project expands content or restores procedural topology.

## Product thesis

Cardborne is a compact 2D action-platform expedition in which the player reads space and enemy intent, commits to movement or defense, creates an opening, and converts that opening through a chosen tool and card build.

The player should finish a run remembering:

- a movement sequence they learned to execute cleanly;
- an enemy interaction they learned to manipulate;
- a route they chose for a clear reason;
- a reward that changed a later decision;
- a boss pattern that tested a lesson from the stage;
- one visual or narrative landmark from the world.

## Core player promise

1. **The character respects intent.** Small timing or positioning errors are forgiven where the intended action is unambiguous.
2. **Every hit is explainable.** The game communicates the threat, response window, damage event, and recovery.
3. **Every major reward changes future play.** Cards and equipment create routes, timings, target priorities, or resource plans—not only larger values.
4. **Space is part of combat.** Elevation, cover, approach width, escape routes, and hazards change which enemy matters and which response is safe.
5. **Difficulty comes from known questions in stronger combinations.** New rules are taught safely before they are mixed.
6. **The world remains authored even when variation returns.** Procedural systems select reviewed content under a stage grammar.

## Core Play Proof scope

The proof includes:

- one Traveler;
- one movement dojo;
- one combat dojo;
- one final-quality blockout of Ruin Approach lasting roughly eight to ten minutes;
- Walker, Charger, Shooter, Shield Guard, and only the hazards required by the stage thesis;
- three prebuilt but mixable build directions;
- one card reward before the boss;
- one Safe Intermission decision only if it changes the boss plan;
- Giant Slime King with four learned-verb patterns;
- keyboard and gamepad parity;
- minimum viable animation, audio, camera, and effects for readability;
- playtest recording and human acceptance gates.

The existing three-stage run may remain operational, but it is not the quality target for this milestone.

## Non-goals

- more heroes, classes, active skills, or weapon slots;
- more normal enemy archetypes;
- more material families, grades, rarities, or random affixes;
- final art for all stages;
- full procedural stage topology;
- leaderboards, daily runs, seed selection, multiple save slots, or mid-run continue;
- replacing stable run/profile/reward architecture;
- balancing the full economy before the proof loop is enjoyable.

## Control contract

## Required actions

| Action | Keyboard defaults | Gamepad default | Rule |
| --- | --- | --- | --- |
| Move / climb / crouch | Arrow keys and WASD | Left stick and D-pad | Both desktop layouts ship simultaneously. |
| Jump / release rope | Space | South face button | Uses coyote time, jump buffer, variable height, and conservative corner correction. |
| Dash | Shift | East face button | Horizontal commitment and combat repositioning; no hidden invulnerability by default. |
| Attack | X | West face button | Final melee/ranged intent model is selected by the control experiment gate below. |
| Guard | C | Left shoulder | Immediate defensive command unless already inside a committed attack active phase. |
| Interact | E | North face button | Context prompt always shows the current device glyph. |
| Potion | A | D-pad down | Never shares a context with attack or interact. |
| Pause / back | Escape | Menu button | Same meaning across gameplay and shell UI. |

Every action is remappable. The UI automatically switches glyph sets based on the last meaningful input device and avoids rapid flicker from stick noise.

## Input forgiveness

Baseline values are starting points, not tuning conclusions:

| Forgiveness | Starting value | Purpose |
| --- | ---: | --- |
| Coyote time | `0.10 s` | Preserve intended edge jumps. |
| Jump buffer | `0.12 s` | Preserve intended jumps before landing. |
| Dash buffer | `0.10 s` | Preserve intended dash after landing or legal recovery. |
| Attack buffer | `0.10 s` | Queue one attack during the final legal portion of recovery. |
| Guard buffer | `0.06 s` | Permit an intended guard at the end of non-cancellable recovery without making guard retroactive. |
| Intent retention | `0.15 s` | Prevent tool/target flicker near contextual thresholds. |

Only one buffered command of each combat category is retained. Inputs expire visibly and never execute after a modal, death, room transition, or unrelated long animation.

## Attack-control experiment gate

Two variants must be implemented behind a development setting and tested with identical encounters.

### Variant A: forecasted contextual attack

- The existing resolver remains authoritative.
- A world-space target bracket and tool glyph show the exact pending `AttackIntent` before the button is pressed.
- The bottom dock mirrors the same intent.
- Ranged supply is never spent unless ranged was already forecast.
- A close-target threshold cannot change during committed startup.

### Variant B: tap melee, hold ranged

- A tap begins melee.
- Holding Attack beyond approximately `0.12 s` requests ranged.
- The threshold states intent only; it does not charge damage.
- A valid ranged target and supply are still required.
- If ranged is unavailable, the game preserves the input as a clearly signaled melee fallback only when the player has enabled that fallback in settings; otherwise it rejects the command with a concise cue.

### Selection criteria

Choose the variant that produces:

- at least 95% correct pre-action prediction;
- less than 2% accidental ammunition spending;
- lower reported loss of control;
- no material increase in average response time;
- equal or better accessibility for keyboard and gamepad;
- cleaner behavior in multi-height mixed encounters.

Do not combine both schemes into a permanent complex hybrid.

## Movement grammar

Each movement verb has one primary job. Rooms may combine jobs only after they are taught separately.

| Verb | Primary job | Secondary expression | Forbidden use |
| --- | --- | --- | --- |
| Run | establish approach, spacing, and momentum | bait horizontal attacks | long empty transit without information |
| Single jump | ordinary gap and enemy avoidance | preserve horizontal momentum | hidden landing or camera-exit commitment |
| Extra jump | correct or extend a route | activate aerial-build interactions | required route that leaves no correction margin |
| Dash | cross a committed horizontal lane; reposition through pressure | build-trigger and speed route | universal answer to every hazard and enemy |
| Fast fall | change aerial timing and landing point | punish an opening sooner | required use before safe teaching |
| Rope | deliberate vertical navigation and observation | choose an exit height | free reset that trivializes a nearby required commitment |
| Crouch / drop-through | change clearance or vertical layer | evade a clearly authored high lane | decorative tunnel or accidental one-way fall |

### Movement rules

- Required routes remain possible with the baseline Traveler and no build effects.
- Optional expert routes may demand cleaner sequencing but not hidden equipment or card requirements.
- Corner correction may rescue a clear intended landing; it must not move the player through a hazard or over a deliberately blocking wall.
- Landing, turn, dash-end, rope attach, and drop-through states receive distinct audiovisual cues.
- A room that includes a verb must answer why that verb is preferable to simply walking and jumping.

## Combat grammar

## Exchange rhythm

Every ordinary exchange is designed around five beats:

```text
1. Observe: identify tell, lane, target, and available space.
2. Decide: choose movement, guard, attack intent, or disengagement.
3. Commit: enter a move with authored startup and cancellation rules.
4. Confirm: receive readable hit, guard, miss, breach, or damage feedback.
5. Convert: exploit recovery, spend a build effect, or reposition for the next question.
```

A combat room should contain a sequence of these exchanges, not uninterrupted enemy contact.

## Shared enemy states

The first proof uses three shared states. They are data-driven tags exposed through combat snapshots.

### Exposed

An authored recovery state in which the enemy is clearly vulnerable to stagger or a tool-specific punish.

- Trigger examples: Charger reaches endpoint or wall; Leaper lands; Shooter completes a shot; Slime King completes a slam.
- Visual rule: silhouette and pose change, not only color.
- Audio rule: one short recovery cue distinct from startup.
- Default duration: long enough for a nearby baseline player to act after recognizing it.

### Breach

A temporary defensive opening created by the player's correct response.

- Trigger examples: precise guard against a supported attack; rear contact on Shield Guard; authored environmental interaction.
- Effect: defense/mitigation rule changes and one build-specific conversion may trigger.
- Breach is not generic stun. The enemy may still move or recover according to its archetype.

### Interruptible

A startup that the correct tool can cancel before the committed active phase.

- Only selected attacks are Interruptible.
- The tell must distinguish interruptible and committed attacks by pose and sound.
- Failed interrupt attempts follow normal damage and recovery rules; no hidden exception.

## Hit and damage feedback

The minimum required package is:

- low-duration hitstop scaled by attack weight;
- attacker recoil and enemy reaction separated from knockback physics;
- one readable hit flash and one critical/precise variant;
- distinct sounds for melee hit, ranged hit, guarded hit, precise guard, player damage, breach, enemy defeat, and boss stagger;
- restrained camera impulse with an independent toggle;
- damage direction and source in the runtime snapshot;
- no repeated combat-result sentences during production play.

The Trial may display teaching labels. Ordinary combat relies on pose, sound, effect, meter response, and concise first-occurrence help.

## Cancellation and commitment

- Attack startup may allow movement tuning but does not silently switch tool or target.
- Active attack frames are committed unless a specific card or equipment rule states otherwise.
- Guard does not erase a clearly committed heavy attack.
- Dash can cancel only explicitly tagged recovery, never every recovery.
- Taking damage clears queued attacks and dashes.
- A successful precise guard may grant an authored immediate response window but not freeze unrelated enemies.

## Build foundations

Cardborne has no classes. The three directions below are recognizable interaction packages created from equipment, cards, and Spirit Stones. Players may hybridize them.

## Pursuit

**Question:** How can movement become offense without making dash a universal answer?

Typical behavior:

- closes distance through safe lanes;
- uses extra jump or dash to create attack angles;
- converts Exposed enemies into renewed mobility;
- accepts higher positional risk for tempo.

Compatible identities:

- sword as fast close conversion;
- spear as spacing/sweet-spot conversion;
- Dash Wake;
- Aerial Relay;
- Ember-style repeated direct-hit payoff.

## Counter

**Question:** How can reading an attack create a stronger opening than passive blocking?

Typical behavior:

- holds favorable ground;
- chooses which committed attack to guard;
- creates Breach through precise timing;
- converts recovery with a deliberate tool choice.

Compatible identities:

- round shield as mobile precise defense;
- tower shield as slow lane ownership and stability;
- Counterclaim;
- Frost-style control after precise guard;
- armor that trades mobility for reliability.

## Control

**Question:** How can ammunition and range change target priority rather than become a damage tax?

Typical behavior:

- preserves lanes and sightlines;
- spends ammunition on high-value startups, recoveries, or weak points;
- uses elevation and cover to manage simultaneous roles;
- accepts reload or supply pressure for safety and precision.

Compatible identities:

- bow as quick flexible pressure;
- matchlock as scarce committed interruption/stagger;
- a recovery-hit ammunition or projectile-behavior card;
- route choices that trade supply for positional advantage.

## Equipment identity rules

- Every model is a sidegrade before it is an upgrade.
- A grade may improve one value and one authored identity, but cannot erase the model's cost.
- Two models in the same role must cause a player to change timing, spacing, route, or target priority.
- A model is not accepted because its aggregate DPS differs.
- Equipment UI explains the changed decision in one sentence before showing secondary numbers.

## Card design rules

A card is build-defining only when at least one is true:

- it creates a new legal sequence;
- it changes which enemy or state is prioritized;
- it changes the risk/reward of a route or position;
- it converts one mastered action into another resource or opportunity;
- it makes an existing tool solve a different authored problem.

A card is a micro-upgrade when it only changes damage, health, cooldown, speed, stagger amount, or recovery amount. Micro-upgrades are allowed, but they must not occupy the same reward tier or presentation emphasis as build-defining cards.

### Proposed first proof cards

| Card | Trigger | Effect purpose |
| --- | --- | --- |
| Dash Wake | Dash completed | Leaves a short one-hit trail; turns a reposition line into an offensive line. |
| Aerial Relay | First attack after extra jump | Adds stagger; hitting an Exposed target restores air dash once. |
| Counterclaim | Precise guard | Breaches the attacker; next valid hit receives a tool-specific conversion. |
| Clean Momentum | Required encounter cleared without health damage | Grants one visible charge consumed by the next dash or guard; rewards mastery without passive healing. |
| Last Stand | Damage leaves exactly one health | Once per stage, grants a short safety window; explicit recovery/accessibility choice. |
| Controlled Shot | Ranged hit during authored recovery | Returns or preserves supply under a capped rule; rewards target/state recognition. |

Card stacks must create a qualitative extension before larger numbers. A stack that only doubles damage is not a sufficient second tier.

## Progression and resource budget

## Immediate gameplay resources

The gameplay HUD may show only resources that affect a decision expected in the next few seconds:

- health;
- ammunition/reload state;
- shield stability/precise window feedback;
- potion charges;
- one charged Spirit or card effect;
- current attack intent.

## Run resources

- Coins create one explicit safety-versus-power decision at intermission.
- Run salvage remains hidden or deferred during Core Play Proof unless selling it changes the boss plan.
- Run level offers small maintenance upgrades and never substitutes for card identity.

## Persistent resources

- Materials, blueprints, crafted grades, and Boss Core remain profile systems.
- They do not occupy the combat HUD.
- Persistent unlocks broaden starting choices; permanent numerical growth is bounded.
- Stage 1 grants at most one headline permanent discovery during the proof path.

## Condition policy

Condition wear is feature-flagged off during initial combat/build tests. It returns only when playtests show that repair creates a meaningful expedition plan.

Acceptance questions before re-enabling:

- Did the player change a route, purchase, or tool plan because of condition?
- Was the consequence readable before failure?
- Did condition create tension without discouraging use of the interesting tool?
- Is repair competing with another desirable purchase rather than merely charging a maintenance fee?

## Enemy design contract

Each enemy owns:

- one primary pressure role;
- one unmistakable startup tell;
- one intended baseline response;
- one authored recovery or state interaction;
- one geometry requirement;
- one composition rule;
- one stage-specific variant purpose.

### First proof roles

| Enemy | Core question | Shared-state use | Terrain relation |
| --- | --- | --- | --- |
| Walker | Can the player maintain spacing while acting? | Simple Exposed recovery after committed swing. | Occupies landings and recovery lanes without surprise burst. |
| Charger | Will the player leave or change the horizontal lane? | Exposed at endpoint; selected startup may be guard-Breached. | Requires approach and endpoint space; walls/ledges make the commitment meaningful. |
| Shooter | Will the player use cover, elevation, interrupt, or a ranged answer? | Close startup Interruptible; post-shot Exposed. | Sightline and cover are authored with the room. |
| Shield Guard | Will the player flank, create Breach, or change height? | Primary Breach tutorial. | Needs a route or space that makes frontal defense matter. |

No new normal archetype is added until these four create at least six distinct reviewed encounter questions through terrain and composition.

## Encounter contract

Every combat room answers this sentence:

> Enemy A, because of terrain B and supporting pressure C, asks the player to choose response D; success creates recovery/reward E.

Rules:

- first control frames are safe and show the primary question;
- no more than two high-attention roles overlap;
- a new enemy or state appears alone or under low pressure first;
- mixed encounters use only previously taught questions;
- the exit cannot create unavoidable contact damage;
- enemies are removed when they do not support the room sentence;
- easy mastery encounters are allowed after peaks.

## Stage and exploration contract

## Stage thesis

Before blockout, write:

> This stage places the Traveler in **[place/situation]**, teaches **[signature spatial/combat verb]**, transforms it through **[two variations]**, and culminates in **[known combination]** before a **[release/landmark]**.

For Core Play Proof:

> Ruin Approach places the Traveler on a broken outer ascent, teaches deliberate lane changes between exposed upper and sheltered lower routes, transforms them through a controlled drop and forward rejoin, and culminates in a mixed charger/shooter test before a quiet overlook and boss approach.

## Required macro beats

1. **Arrival and landmark:** establish place, direction, and one distant objective.
2. **Movement teach:** safe traversal using the stage's signature verb.
3. **Enemy teach:** one enemy relationship with the terrain.
4. **Route preview:** show two lines and a visible consequence before commitment.
5. **Transform:** change height, direction, timing, or threat ownership.
6. **Set-piece state change:** gate, collapse, shortcut, or other persistent room change.
7. **Combine/test:** use only known elements under focused pressure.
8. **Release:** reward, view, story clue, safe mastery beat, or short intermission.

## Route-choice rules

Two routes count as distinct only when at least two differ:

- movement verb/timing;
- enemy or hazard exposure;
- traversal duration;
- resource cost;
- reward or positional advantage;
- information gained;
- recovery cost.

The optional line should usually rejoin forward. Full return to the same hub requires a reward or world change that justifies the return.

## Curiosity rules

- Show a landmark from multiple positions and change the player's relationship to it.
- Show at least one reward, shortcut, or safe landing before the player knows how to reach it.
- Secrets reward observation or system use; they do not depend on invisible walls with no clue.
- A discovered path should yield a unique sight, encounter, character, state change, or build decision—not only another quantity pickup.
- The minimap confirms learned geography; it does not reveal every interesting answer in advance.

## Difficulty and pacing contract

The default rhythm group is:

```text
preview/teach -> transform -> combine/test -> release
```

Target bands for the proof:

| Beat | Target |
| --- | --- |
| Ordinary room | 20–60 seconds first clear |
| Required Ruin path | 8–10 minutes blind first clear |
| Quiet release | 10–25 seconds with optional interaction |
| Boss | 3–5 minutes on a successful learning run |
| Retry to regained control | as short as the current stage-snapshot contract permits, with no repeated reward animation |

Difficulty is raised by combining learned lanes, timing, and priorities—not by multiplying health or hiding information.

## Boss contract

The Giant Slime King is a learning exam and dramatic payoff.

### Pattern provenance

| Pattern | Earlier lesson | Primary response | Build opportunity |
| --- | --- | --- | --- |
| Body Bump | Charger lane commitment | change height/line or precise guard | Counter creates major Breach; Pursuit punishes endpoint recovery |
| Jump Slam | visible commitment and fast-fall/dash timing | leave shadow, clear shockwave | landing becomes Exposed; aerial/dash cards convert |
| Poison Bands | safe-zone reading and Shooter sightline | occupy guaranteed safe lane; use range while separated | Control gains a weak-point/supply opportunity |
| Small Slime Summon | mixed target priority | remove or route through adds without losing boss tell | Dash Wake and controlled shots alter cleanup line |

### Phase rules

- Phase 1 presents each family separately with generous recovery.
- Phase 2 combines only legal, learned pairs.
- Phase transition changes arena use, vulnerability, or route—not only speed and color.
- No combination removes all legal responses.
- The boss cannot queue a new high-attention tell while required add cleanup fully occupies the player.
- Stagger is a visible consequence of correct play, not a hidden damage meter race.
- Every build has one favorable conversion and still faces one execution check.

## UI and communication contract

## Gameplay HUD hierarchy

1. health and immediate survival;
2. current objective/boss state;
3. world-space threat and attack intent;
4. current tool/supply/guard state;
5. charged card/Spirit effect;
6. minimap and route state;
7. secondary progression only outside combat.

Rules:

- World-space cues precede text.
- The attack preview and executed intent are the same object.
- State is not communicated by color alone.
- Repeated labels are replaced by pose, sound, shape, meter, and animation once learned.
- Card choice screens show changed behavior with a short demonstration or before/after diagram.
- Death recap names the final source and response category without blaming the player.
- Accessibility toggles separately cover screen shake, damage flash, hold/tap attack fallback, and training labels.

## Visual, audio, and world contract

The first final-enough art pass is limited to the proof path.

Required readable states:

- Traveler: idle, run, turn, jump rise/fall, land, extra jump, dash start/end, melee startup/active/recovery, ranged startup/active/recovery, guard startup/hold/precise/break, hurt, defeat.
- Enemies: idle/locomotion, startup, committed attack, Exposed, Breach where relevant, hurt, defeat.
- Boss: one unique silhouette/timing phrase per pattern and a distinct phase transition.

World requirements:

- terrain silhouette matches collision;
- foreground never hides landing, threat, reward, or route edge;
- one landmark binds multiple rooms;
- ambient motion and sound establish the drowned industrial ruin without visual noise;
- stage music supports preview, pressure, release, and boss transition with a small number of layers;
- materials, blueprints, and machinery share one fictional cause.

## Playtest and evidence contract

Automated validation remains mandatory for correctness. Human evidence is mandatory for experience.

### Required telemetry events

- session/run/stage/room start and end;
- input command and buffered-command result;
- forecasted and committed `AttackIntent`;
- attack hit/miss/guard/breach/interrupt;
- damage source and player state;
- enemy state transition and defeat;
- route commitment and rejoin;
- reward viewed/chosen;
- first use of a new card/equipment effect;
- death, retry, boss pattern, stagger, phase, and victory.

The recorder is development-only and writes deterministic local evidence. It is not a shipping online analytics requirement.

### Required human questions

After a room or death:

- What was the room asking you to do?
- What information did you use?
- What caused the damage or failure?
- What will you try next?

After a reward:

- What does this let you do differently?
- Where do you expect to use it?

After the stage:

- Draw or describe the route, landmark, branch, and shortcut.
- Name the most tense and most restful moments.

After the boss:

- Match each pattern to the response you learned.
- Explain how the build changed one punish window.

## Core Play Proof acceptance gates

The milestone passes only when all categories pass.

### Control and movement

- Attack-tool prediction at least 95%.
- Accidental ammunition spend below 2% of attacks.
- At least 80% of movement failures are described as visible execution/route errors rather than ignored input.
- Movement-only enjoyment at least 4/5 median.
- Keyboard and gamepad complete all required paths.

### Combat

- At least 80% identify Exposed and Breach without debug text.
- No single response safely solves every proof encounter.
- Unexplained damage below 10% of damage events.
- All four actions—movement, attack, guard, and ranged resource planning—appear in successful mixed-encounter play.

### Builds and rewards

- Observers identify Pursuit, Counter, and Control from play at least 80% of the time.
- At least 80% describe a behavioral consequence of the selected card.
- Players test the new effect in the first eligible room.
- Median performance between builds remains within an agreed band unless the difference is paid for by safety or resource cost.

### Stage

- At least 70% reconstruct the macro route and landmark after one blind run.
- Route selection is not more lopsided than 70/30 without an intentional expert-route rationale.
- Players give a non-numeric reason for route choice.
- The stage trace shows teach, transform, test, and release rather than uniform pressure.

### Boss

- At least 80% identify the correct response after one exposure to each pattern.
- At least 70% correctly explain their deaths.
- Baseline target is victory within two to five attempts for genre-familiar players.
- Every build has an advantageous conversion and no build bypasses all execution.

### Motivation

- A majority of target testers voluntarily begin another run or explicitly choose another build/route when offered.
- Their stated reason concerns movement, combat, build, route, boss, or discovery—not only completion rewards.

## Procedural-generation handoff

Procedural variation remains dormant until Core Play Proof passes. Re-entry follows this order:

1. reviewed encounter-package variation in fixed rooms;
2. reviewed reward and optional-route offer variation;
3. rhythm-slot room substitution;
4. constrained graph variation;
5. broader stage-profile generation only after generated seeds match the fixed benchmark in human tests.

Generation Reports add experience guardrails—repetition, decision gaps, branch differential, threat overlap, reward clustering, and landmark spacing—but no automated aggregate score may be treated as proof of fun.
