---
type: evidence
status: active
owner: BK
created: 2026-07-20
last_reviewed: 2026-07-20
topic: Vehicle-led isometric action combat and progression
scope: Evidence for deciding whether Cardborne should replace humanoid action combat with a vehicle-led isometric game
source: Owner request on 2026-07-20 plus the primary and developer sources listed below
related:
  - ../product/isometric_action_rpg_product_brief.md
  - ../product/progression_upgrade_system_spec.md
  - ../design/UI_VISUAL_SYSTEM.md
  - ../../.agent/execplans/2026-07-18-flooded-works-floor1-map-enemies.md
---

# Vehicle-Led Isometric Action Game Reference Analysis

## Purpose

Determine what a vehicle-led isometric action game would need to be enjoyable,
feasible, and internally coherent. This is decision evidence, not an accepted
pivot specification. It does not authorize replacing the current product brief
or mapping the existing Traveler actions one-to-one onto a vehicle.

The analysis separates three things that are easy to conflate:

1. **Vehicle presentation** — a rigid actor is cheaper to depict than a humanoid.
2. **Vehicle control fantasy** — thrust, grip, turn rate, turret or weapon facing,
   boost, recoil, heat, and damage state make the actor feel mechanical.
3. **Game structure** — authored exploration, run-based buildcraft, tactical
   missions, or survival escalation determine what the player repeatedly does.

Changing only the first item would reduce animation cost but would not repair the
current gameplay. The control and game structures must be selected deliberately.

## Sources

The comparison favors official developer or publisher descriptions, current
developer material, inspectable open-source documentation, and professional
design talks. Store review counts are not used as causal proof of good design.
Older games are included only where they remain unusually direct references;
recent sources carry more weight for production direction.

| Reference | Release/source context | Why it is included | Important limit |
| --- | --- | --- | --- |
| [Minishoot' Adventures](https://store.steampowered.com/app/1634860/Minishoot_Adventures/) | 2024, official store page | Closest recent example of a small, responsive ship in a handcrafted top-down action-adventure | It is top-down rather than the project's exact isometric presentation |
| [Nova Drift](https://www.novadrift.pixeljam.com/presskit.html) | 1.0 in 2024, official press kit | Strong small-team example of turning a ship into a fast, expressive action-RPG build platform | Abstract survival arenas do not provide authored world exploration |
| [Hades](https://www.supergiantgames.com/games/hades/) and [official update notes](https://www.supergiantgames.com/blog/hades-updates/) | 2020 release, developer material still current | Benchmark for responsive isometric action, behavior-changing upgrades, encounter rhythm, and input polish | Its humanoid melee animation and narrative scale are not feasible targets |
| [Enter the Gungeon](https://store.steampowered.com/app/311690/Enter_the_Gungeon/) | 2016, official store page | Durable example of readable projectile combat, a universal evasive verb, differentiated weapons, and hand-authored rooms assembled into runs | Its content volume and gun count should not be copied |
| [Risk of Rain 2](https://store.steampowered.com/app/632360/Risk_of_Rain_2/) | 2020 with ongoing content, official store page | Clear example of stacking effects, escalating player power, enemy scaling, and replayable combat identities | Its 3D hordes and combinatorial content scale exceed this project's capacity |
| [Armored Core VI official combat guide](https://www.bandainamcoent.com/news/armored-core-6-fires-of-rubicon-beginners-guide) | 2023, publisher guide | Shows how movement parts, weapons, impact, stagger, and simultaneous actions form one vehicle combat system | Full 3D mech motion, four weapon mounts, and assembly breadth are out of scope |
| [FUMES](https://store.steampowered.com/app/1920430/FUMES/) | 2025 Early Access, official store page | Recent evidence that a simple vehicle, weapon, roaming, upgrade, and boss fantasy can be immediately legible | Third-person driving physics and an endless wasteland are not the intended camera or map model |
| [Brigador](https://stellarjockeys.com/) | Older exact-view comparator, current developer site | Demonstrates that isometric vehicles, destructible terrain, and multiple chassis can create strong tactical silhouettes | It is not the primary contemporary scope or control reference |
| [Endless Sky player manual](https://github.com/endless-sky/endless-sky/wiki/PlayersManual) and [source repository](https://github.com/endless-sky/endless-sky) | Active open-source project; manual reviewed in 2026 | Inspectable model for hulls, hardpoints, steering/thrust tradeoffs, energy, heat, shields, ammunition, auto-aim, cover, and range | It is a large systemic space simulation, not the desired moment-to-moment action pace |
| [Stonefly combat design talk](https://www.gdcvault.com/play/1027918/Independent-Game-Summit-These-Non) | GDC 2022 | Useful process example: theme and scale drove a distinct king-of-the-hill mech combat loop instead of inheriting generic combat | The talk supports design method, not a full feature template |
| [Design Sandbox: Analog vs Digital Systems](https://www.gdcvault.com/play/1027580/Design-Sandbox-Analog-vs-Digital) | GDC 2022 | Frames the need to balance player expression, readability, intuitive control, and expected physical behavior | AAA examples must be reduced to small-team principles |
| [VFX as a Game Design Language](https://www.gdcvault.com/play/1027899/Visual-Effects-Summit-VFX-as) | GDC 2022 | Supports treating VFX as communication of game state and feel, not decoration after mechanics | It does not prescribe Cardborne-specific effects |

## Findings

### Executive finding

A vehicle-led pivot is viable, but a vehicle skin over the existing Traveler is
not. The strongest feasible direction is a **single responsive hover vehicle in
an authored, interconnected drowned-ruin world, with a compact run or expedition
layer of behavior-changing modules**. This combines the world clarity and low
animation burden demonstrated by Minishoot' Adventures with the rapid build
expression demonstrated by Nova Drift and Hades.

The first question is therefore not "tank or spaceship art?" It is:

> What repeatable decision should feel good every ten seconds?

For the recommended direction, the answer is: **steer through a readable threat
field, choose a firing angle and range, spend boost or defense at the right time,
then convert the opening into a weapon-specific payoff**. Exploration and module
choices should change the conditions around that decision.

### Reference-by-reference functional analysis

#### Minishoot' Adventures: the closest scope and actor reference

**Observed:** The official page presents a swift, responsive spaceship, handmade
encounters, bullet-hell bosses, a fully handcrafted interconnected world,
combat/exploration abilities that open paths and shortcuts, ship improvements
through levels/items/equipment, and aim-assist and auto-fire options.

**Design contribution:**

- The vehicle has no walking animation, but still communicates intent through
  rotation, acceleration, firing, impact, and motion trails.
- Movement, combat, and navigation use the same compact actor. New abilities are
  valuable twice: they improve combat and reveal world access.
- A handcrafted world lets a small content set be recombined through shortcuts,
  revisits, secrets, and changed traversal capability.
- Accessibility assistance is compatible with difficult projectile patterns;
  precision can be tuned without removing the pattern itself.

**Do not copy:** A generic floating ship in empty rectangular rooms. Its success
depends on tight control, legible encounters, and dense authored discovery—not on
the absence of character animation alone.

#### Nova Drift: the build-expression reference

**Observed:** The official press kit describes a ship that rapidly evolves as
enemies are defeated, letting the player shape abilities and weaponry within
minutes and take a build from inception to execution in one session. Developer
material describes exceptionally powerful upgrades that can also carry a heavy
price.

**Design contribution:**

- The ship body, weapon, shield, and upgrade graph are behavior layers, not
  independent percentage tables.
- A build becomes memorable when it changes projectile count, firing geometry,
  collision behavior, summons, shield behavior, or the safe engagement range.
- Strong tradeoffs create authorship: gaining power while accepting heat,
  fragility, recoil, reduced control, or a lost capability produces a distinct
  machine rather than a statistically improved default machine.
- A short time from choice to visible consequence lets players learn builds by
  playing, not by reading a long metagame screen.

**Do not copy:** Hundreds of upgrades, screen-filling late-run effects, or
inertia-heavy controls before the base vehicle is satisfying. Upgrade volume
cannot compensate for a weak five-second control loop.

#### Hades: the responsiveness and encounter-rhythm reference

**Observed:** Supergiant's own update history repeatedly adjusted input buffering,
dash fluidity, attack recovery, hitboxes matching graphics, obstacle interaction,
boon compatibility, duo combinations, encounter length, reward pacing, and boss
phase downtime.

**Design contribution:**

- Responsiveness is a system: buffering, cancellation rules, recovery, collision,
  hit timing, and visual alignment must agree. It is not only movement speed.
- Each base weapon establishes a different positioning problem before upgrades
  are added. Upgrades then bend that identity instead of replacing it with raw
  damage.
- Short combat chambers, reward decisions, non-combat relief, and bosses create a
  pulse. Continuous undifferentiated combat exhausts rather than excites.
- A defensive movement verb can also become a build surface, but its readable
  timing and reliability must exist before upgrade effects are attached.

**Do not copy:** The existing Traveler's melee/ranged/guard/dash labels merely
because Hades has several action buttons. A vehicle needs actions that express its
own motion and weapon system.

#### Enter the Gungeon: the threat-field and weapon-identity reference

**Observed:** The official description centers on shooting, looting, dodge rolling,
and using room objects as cover. It combines hand-designed rooms into a changing
labyrinth and differentiates weapons through tactics and ammunition, not only
damage values.

**Design contribution:**

- A universal, dependable evasive action gives the player a way to cross an
  otherwise invalid threat field.
- Enemy bullets are gameplay geometry. Their speed, spacing, color, persistence,
  and overlap determine whether the room is understandable.
- Cover and destructible/interactable objects create temporary safety and spatial
  decisions without needing complex level elevation.
- A weapon is a new rule: spread, cadence, travel, area denial, homing, charge,
  ammunition pressure, or environmental interaction.

**Do not copy:** Random rooms without encounter composition rules. Hand-authored
room quality remains essential even when sequencing is procedural.

#### Risk of Rain 2: the escalation and synergy reference

**Observed:** The official description highlights handcrafted locations,
simultaneously escalating player and enemy power, more than 110 combinable items,
distinct survivors, alternate skills, and randomized stages, enemies, and items.

**Design contribution:**

- Repetition becomes exciting when accumulated effects create a visibly new
  combat machine and the threat scale rises to test it.
- An item is more legible when the same rule stacks consistently; players can
  predict how another stack affects their plan.
- Character or chassis identity should constrain the build enough that random
  rewards have context.
- Escalation needs both power and danger. Power without a changing test becomes
  automatic cleanup; danger without expressive power becomes attrition.

**Do not copy:** Unbounded proc chains or horde density. In an isometric small-team
game they can destroy projectile readability and make balance opaque.

#### Armored Core VI: the integrated-machine reference

**Observed:** The official guide ties desired action to frame, generator, booster,
and weapon choices. It distinguishes power from impact, uses impact to create a
stagger damage opportunity, and permits movement, boosting, firing, dodging, and
defense to overlap rather than assigning separate turns to offense and defense.

**Design contribution:**

- Mobility is part of the build, not a neutral delivery system for weapons.
- Different weapons can cooperate over time: one creates pressure or stagger,
  another consumes the opening.
- Offense and survival can be simultaneous spatial acts. Strafing, boosting, and
  firing feel mechanical because the machine keeps operating as a coordinated
  whole.
- A build should be tested against a problem that reveals its strengths and
  weaknesses, not only a higher health total.

**Do not copy:** A four-hardpoint control scheme or detailed part assembly. One
primary weapon, one secondary/tool, and one mobility/defense resource are enough
to test the principle.

#### FUMES and Brigador: the vehicle-fantasy references

**Observed:** FUMES communicates a concise loop—arm a vehicle, roam, fight, collect
upgrades, defeat bosses. Brigador presents many isometric vehicles within
destructible environments.

**Design contribution:**

- Vehicle feel comes from the relation between chassis motion, weapon orientation,
  recoil, terrain contact, and destruction—not from a wheel or hull sprite alone.
- Destruction can turn shooting into navigation: breaking cover, opening a line,
  or creating danger changes the room.
- A small set of clearly different chassis can later provide replay value, but
  the first chassis needs a complete identity before variants are added.

**Do not copy:** An open wasteland or large roster as a substitute for encounter
authorship. Roaming plus waves plus upgrades plus a boss is a feature list, not a
complete fun loop.

#### Endless Sky: the inspectable systems reference

**Observed:** Its current manual separates steering and thrust; distinguishes
forward guns, omnidirectional turrets, and hardpoint capacity; models energy,
batteries, heat, engines, shields, ammunition, speed, and range; allows asteroid
cover; and offers automatic aiming when the ship is roughly aligned with a target.

**Design contribution:**

- Weapon orientation should affect the value of turn speed. A fixed gun and a
  turret are not merely two visuals; they produce different movement strategies.
- Energy and heat are useful only when they create a temporary tactical state:
  burst now and retreat, keep movement power in reserve, or accept overheat risk.
- Auto-aim can preserve player intent without automating positioning. Requiring
  rough alignment, target eligibility, and line of sight keeps assistance bounded.
- World obstacles must block ordinary projectiles consistently if cover is part
  of the rules.

**Do not copy:** Its simulation depth, travel economy, or long equipment list. The
value here is inspectable responsibility boundaries and tradeoff models.

#### Stonefly and the design talks: the method reference

**Observed:** Stonefly's designers used theme and microscale setting to derive
king-of-the-hill encounters and non-lethal wind abilities. Bungie's sandbox talk
frames intuitive controls, expression, readability, and expected physical behavior
as a joint problem. The VFX talk treats effects as a language for communicating
game design concepts.

**Design contribution:**

- Choose the desired player fantasy and emotional rhythm before choosing a combat
  feature list.
- Retain enough expected physics for the vehicle to be understandable, then
  simplify aggressively for responsiveness.
- Every effect needs a communication job: action started, direction committed,
  resource spent, hit confirmed, armor resisted, danger active, or recovery open.

### Universal elements across successful references

These are synthesis from the sources, not claims that any single feature causes
commercial success.

#### 1. A clear movement identity

The player should understand the machine within seconds. Acceleration, braking,
turn rate, lateral control, collision response, and boost must produce one coherent
fantasy. A hover vehicle is the lowest-risk fit because it can strafe and rotate
without wheel, track, leg, or terrain-conformance animation.

The vehicle should not drift accidentally. If inertia is used, it must create
predictable mastery and useful maneuvers. Otherwise, strong braking and a small
visual lean can communicate weight without compromising control.

#### 2. Deliberate separation of movement and attack direction

Independent aim supports circle-strafing, retreat fire, flanking, and target
prioritization. Coupled aim can work for a forward-gun ship, but then fast turning
and facing clarity become core constraints. A useful compact model is:

- movement vector from keyboard or left stick;
- aim vector from mouse, right stick, or bounded target assistance;
- hull follows movement or recent heading;
- weapon mount follows aim within explicit arc and turn-speed rules.

The game should not silently switch between these rules. Hull direction, weapon
direction, and selected/assisted target need distinct readable cues.

#### 3. A small expressive verb set

More buttons do not guarantee depth. The minimum useful set is:

- move/steer;
- aim and primary fire;
- a secondary weapon or tactical tool;
- boost/evasive burst;
- one defensive resource or special state.

Depth should come from overlap and timing: fire while strafing, boost through a
lane, deploy a shield while turning, or spend secondary fire to create an opening.
Actions that lock each other out need a clear balance reason.

#### 4. Weapons that change positioning

At least these dimensions should distinguish weapon families:

- desired range and firing arc;
- cadence, charge, burst, or sustained fire;
- projectile speed and footprint;
- recoil or movement cost;
- heat, energy, cooldown, or ammunition rhythm;
- effect on armor, shields, stagger, groups, or terrain.

If two weapons ask the player to stand in the same place and hold the same button,
they are one weapon with different numbers.

#### 5. Readable threats and fair recovery windows

The player must be able to infer what caused damage and what would have prevented
it. Enemy attacks need a visible startup, committed direction or area, active
window, and recovery. Projectiles need contrast against both floor and VFX.
Ordinary shots must respect world collision when cover is advertised.

Fairness does not mean slowness. Fast attacks remain fair when their source,
timing family, range, and counter are learned consistently.

#### 6. Layered action feedback

A satisfying shot is a chain:

`input → muzzle/charge cue → recoil or hull response → projectile motion → impact
shape → target response → sound → resource/state update`

Not every layer needs expensive art. Rotation, scale pulses, particles, trails,
decals, light, shader flashes, brief hit-stop, camera impulse, and audio variants
can provide most of the feedback around one rigid vehicle image. Effects must stay
short, directional, and subordinate to hostile telegraphs.

#### 7. Enemy roles that create a combined spatial problem

A useful small roster is role-based:

- **Chaser:** removes stationary safety and tests steering.
- **Shooter:** establishes lanes and tests cover or lateral movement.
- **Controller:** creates temporary denied zones or forces displacement.
- **Guard/support:** changes target priority by shielding, repairing, or enabling.
- **Elite/boss:** remixes learned rules and creates explicit payoff windows.

The encounter director must control simultaneous attack pressure. Five readable
enemies are better than fifteen enemies whose warnings overlap into noise.

#### 8. Arenas that support multiple lines of play

Good combat spaces provide sightlines, circulation loops, at least one escape
route, temporary safety, flank opportunities, and meaningful obstacles. Cover must
not become a trap corridor. Camera-facing occluders should be absent, cut away, or
made transparent before they hide the player or hostile attacks.

Objectives should vary the spatial question. Useful forms include survival,
activation, escort/tow, hold-and-defend, moving pursuit, salvage under pressure,
optional hunt, and boss escape. Killing every enemy should be one encounter type,
not the universal door key.

#### 9. Behavior-changing progression with tradeoffs

The strongest upgrade categories are:

- **Conversion:** projectile becomes beam, mine, orbiting drone, ricochet, or
  terrain-breaking shot.
- **Trigger:** boost, shield break, critical hit, near miss, or overheat causes a
  new effect.
- **Rule change:** fire during boost, shield converts damage to heat, secondary
  consumes primary charge, or pickups become temporary weapons.
- **Synergy bridge:** heat improves damage, ricochets apply stagger, or repair
  pickups recharge defense.
- **Tradeoff:** more power for narrower arc, more projectiles for lower control,
  stronger shield for slower recharge, or speed for hull fragility.

Small percentage improvements can support tuning, but they should not dominate
choice screens. The player should be able to describe what changed without reading
the final damage total.

#### 10. A controlled resource economy

One combat resource is usually enough for the first proof. Heat is a strong fit
because it can unify sustained fire, boost, and defensive bursts while remaining
visible on the vehicle and HUD. Energy can do the same but may feel more abstract.
Finite ammunition is appropriate only when weapon identity and resupply decisions
justify the UI and failure state.

Health recovery should produce route and risk decisions. Repair pickups, salvage,
limited repair charges, or a workshop can replace a humanoid potion without
pretending the vehicle drinks it.

#### 11. Bosses that test understanding rather than endurance

A boss should:

1. expose a recognizable threat family;
2. let the player practice the counter;
3. combine it with a second pressure source;
4. open a readable damage or stagger window;
5. change one rule in a later phase without discarding all prior learning.

Large health pools are justified only if the player's positioning and build keep
producing new decisions. Invulnerability and transitions should be brief and
communicated.

#### 12. Rhythm, relief, and meaningful anticipation

Enjoyment depends on contrast: navigation before danger, warning before action,
pressure before payoff, combat before a reward choice, and a difficult room before
safe repair or discovery. Constant maximum intensity removes anticipation and
makes upgrades feel like interruptions.

### What players are likely to find fun

The research does not prove a universal recipe for fun, but the references support
six recurring experiential outcomes:

1. **Agency:** input quickly and reliably produces the intended action.
2. **Mastery:** the player can explain why damage happened and improve next time.
3. **Expression:** weapon, chassis, and module choices create visibly different
   solutions rather than a single optimal numeric path.
4. **Fair pressure:** danger forces decisions without obscuring its own rules.
5. **Escalating consequence:** a good maneuver, target choice, or build synergy
   produces a strong, readable payoff.
6. **Rhythmic novelty:** rooms, objectives, enemies, and rewards vary the problem
   before repetition becomes obvious.

Vehicle art helps only where it improves these outcomes. The main production
advantage is that a rigid actor can communicate state through transforms and
effects, freeing limited art effort for weapons, enemies, impact, and encounter
readability.

### Vehicle archetype comparison

| Archetype | Control identity | Art/animation burden | Design burden | Fit for Cardborne |
| --- | --- | ---: | ---: | --- |
| Hover skiff / salvage craft | Strafe, rotate, boost, glide over shallow water; optional turret | Low | Medium | **Best fit**: preserves drowned ruins and supports tight action without locomotion animation |
| Tracked tank | Heavy acceleration, hull/turret separation, cover, recoil | Medium | High | Strong vehicle identity, but track behavior, turning, narrow corridors, and terrain contact add friction |
| Free-space ship | Thrust, rotation, drift, no ground contact | Lowest | Medium-high | Easy to render, but weakens the current world theme and makes room/obstacle logic more abstract |
| Wheeled combat car | Forward speed, grip, drift, mounted weapon | Medium | High | Works for open arenas like FUMES; poor fit for tight authored ruin rooms |
| Mech / walker | Omnidirectional combat with hardpoints | High | Very high | Defeats the animation-cost purpose unless represented as an extremely simple hovering machine |

### Three coherent product models

#### Model A — Authored vehicle adventure

**Reference center:** Minishoot' Adventures.

- One hover vehicle explores connected drowned ruins.
- Combat and traversal upgrades open shortcuts and optional rooms.
- Encounter order is authored; revisits gain new meaning.
- Equipment is persistent and the campaign is finite.

**Strengths:** Best use of the current theme and room work; clear learning curve;
lower combinatorial balance risk.

**Risks:** Requires dense world design and enough secrets; weaker run-to-run build
novelty unless equipment choices remain meaningful.

#### Model B — Expedition buildcraft shooter

**Reference center:** Nova Drift, Hades, and Risk of Rain 2.

- A short route samples authored rooms and objectives.
- The player chooses behavior-changing modules during each expedition.
- A small amount of persistent salvage unlocks options, not raw mandatory power.
- The boss tests the assembled machine.

**Strengths:** Preserves cards/rewards in a vehicle-native form; supports repeated
play with a modest map pool; quickly exposes whether combinations are enjoyable.

**Risks:** Upgrade design and interaction testing can grow rapidly; random rewards
must not brick a run or obscure the base controls.

#### Model C — Tactical vehicle missions

**Reference center:** Brigador and reduced Armored Core principles.

- Hull and weapon facing differ; cover, destructibility, noise, range, and target
  priority dominate.
- Missions have explicit objectives and extraction rather than room clearing.
- Loadout choice occurs before the mission, with limited changes during play.

**Strengths:** Strongest machine fantasy and deliberate level play.

**Risks:** Higher AI, collision, map, and control burden; slower feedback loop;
less compatible with casual keyboard-only action.

### Recommended synthesis for this project

Use a restrained **Model A/B hybrid**:

- one compact hover skiff in the existing flat-color drowned-ruin theme;
- authored connected rooms and visible landmarks;
- independent aim with bounded assistance;
- primary weapon, secondary tool, boost, and a heat- or shield-based defense;
- three enemy roles plus one boss;
- varied encounter objectives with exits that are not universally kill-gated;
- a short expedition where 6–9 possible modules can produce at least three
  recognizable build directions;
- salvage/forge/merchant identities reinterpreted only after the core loop works.

This is not yet a product decision. It is the lowest-risk hypothesis because it
keeps the view, art direction, ground-plane simulation, and authored-room work
while removing the humanoid sprite burden and replacing the combat contract with
one designed for a machine.

### Current-system reuse boundary

The repository contains useful infrastructure, but not a vehicle combat design.

**Candidate infrastructure to retain after review:**

- ground-plane `CharacterBody3D` collision and movement plumbing;
- isometric camera follow, clamping, and occlusion rules;
- Tiled-authored room data and room transition runtime;
- generic damage request/result concepts;
- projectile world collision and line-of-sight queries;
- enemy role/coordinator boundaries;
- settings persistence, audio defaults, and reusable HUD primitives;
- flat-color drowned-ruin art and UI direction.

**Contracts that should be replaced rather than renamed:**

- Traveler sprite-state and humanoid facing presentation;
- melee chain, bow-like ranged action, held guard, and potion semantics;
- attack-specific soft targeting assumptions tied to those actions;
- Slime King patterns whose spacing was tuned for the humanoid move set;
- cards or equipment that trigger from melee, guarding, or humanoid animation
  states;
- encounter tuning based on current speed, range, and recovery values.

**New contracts that must be decided from first principles:**

- movement model: direct strafe, hull steering, or limited inertia;
- hull-facing and weapon-facing relationship;
- primary/secondary weapon cadence and resource model;
- boost/evasion and defense relationship;
- vehicle health, shields, heat, repair, and visible damage states;
- module slots, behavior changes, exclusions, and tradeoffs;
- enemy projectile grammar and attack concurrency budget;
- arena metrics derived from vehicle size, range, speed, and camera framing.

### Decision experiment before a full pivot

A full rewrite should follow evidence from one graybox combat experiment, not
precede it. The smallest useful experiment contains:

- one hover vehicle with stable scale and unmistakable hull/weapon facing;
- one compact arena plus one circulation-focused arena;
- three primary weapon prototypes: rapid fixed gun, slower impact cannon, and
  short-range spread or beam;
- one boost and one shield/heat interaction;
- chaser, shooter, and controller enemies under an attack budget;
- one two-phase boss that exposes and then combines learned threat rules;
- six behavior-changing modules forming three obvious pairs or synergies;
- no meta progression, merchant, crafting tree, story, or additional chassis.

Evidence to collect:

- Is movement enjoyable for sixty seconds with no enemies or rewards?
- Does each weapon cause a different preferred range or route?
- Can a player identify hull direction, weapon direction, danger, hit, and safe
  recovery without explanatory UI?
- Can the player explain why damage occurred?
- Does each module visibly change behavior within the next encounter?
- Does the player voluntarily retry to test another weapon or module combination?

Failure on the first four questions means content and progression should not be
expanded. Failure on the last two means the action may be serviceable but the
replay structure is not yet compelling.

## Recommendations

- Treat the vehicle direction as a new combat product built on selected technical
  infrastructure, not as an actor replacement.
- Prefer a hover skiff over a tank, wheeled car, free-space ship, or mech for the
  first experiment.
- Choose the authored-adventure versus expedition-buildcraft balance before
  revising the active product spec.
- Define movement, aim, primary fire, secondary tool, boost, and defense together;
  do not finalize one without testing their overlap.
- Prototype weapon identity and enemy threat readability before cards, forging,
  merchants, persistent progression, or additional rooms.
- Promote accepted conclusions into a replacement product spec only after the
  owner reviews the experiment and explicitly accepts the pivot.

## Limitations

- This is a structural analysis of published descriptions, developer material,
  inspectable documentation, and the current repository. It is not a complete
  reverse-engineering of each reference's frame data, AI code, economy, or level
  metrics.
- Most referenced commercial games do not publish source code. Their detailed
  internal implementation should not be inferred from visible behavior.
- “Fun” remains an experiential hypothesis. The proposed synthesis needs direct
  playtesting, ideally including someone other than the developer.
- No license in these sources authorizes copying commercial art, audio, code, or
  data. Endless Sky is open source, but its code and art have separate license
  considerations that must be reviewed before any adoption.
- The active humanoid product brief remains authoritative until the owner accepts
  a replacement specification.
