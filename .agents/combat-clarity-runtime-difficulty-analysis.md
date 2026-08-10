---
type: evidence
status: active
owner: BK
created: 2026-08-10
last_reviewed: 2026-08-11
topic: Combat effect clarity, runtime smoothness, health bars, and difficulty
scope: Current five-stage Cardborne run; analysis and recommendations only
source: Local source/capture/trace inspection plus official external references
related:
  - ../docs/product/vehicle_game_spec.md
  - ../docs/design/VISUAL_SYSTEM.md
  - ./cardborne-runtime-architecture-audit.md
  - ./semantic-v2-runtime-acceptance-evidence.md
  - ./2026-08-02-enemy-movement-spawn-research.md
---

# Combat Clarity, Runtime Smoothness, and Difficulty Analysis

## Purpose

This report analyzes the current Cardborne project against three requested
outcomes:

1. combat effects must be intuitive, internally consistent, and geometrically
   faithful to gameplay;
2. visible bugs, movement jitter, and health-bar failures must be separated from
   true frame-rate problems and fixed at the correct owner;
3. ordinary enemies and bosses must become materially more threatening without
   making normal pursuers faster than the player's base vehicle or invalidating
   authored reaction windows.

This is evidence, not a product specification or an execution plan. It records
the current implementation, observed failures, external design evidence, and a
recommended decision set for the next implementation contract.

The local baseline is clean commit `428a1c40` (`docs: record procedural renderer
qualification`). The main visual evidence is the latest
`build/captures/execplan-2026-08-10-procedural-v1` capture set. The manual runtime
evidence is
`build/performance/manual/manual-428a1c40-20260810-232556.json`.

## Sources

Local sources include the current gameplay, combat, enemy scheduling, boss,
presentation, and validation code; the canonical product and visual
specifications; the latest procedural-v1 capture set; recent Git history; the
manual trace above; and the retained native stress evidence. External sources
are restricted to official engine documentation, developer/first-party game
material, public accessibility standards/guidance, government human-factors
examples, and a developer GDC presentation. They are listed with direct links
under [External evidence](#external-evidence).

## Findings

1. Code-native geometry is suitable for final production use, but only after
   damage, protection, corridor, support, utility, and instant-impact families
   receive a strict repeated grammar.
2. Electric Field currently gives its perimeter more contrast than its full
   damaging disk. EMP accurately carries two gameplay radii, but represents
   them as unexplained nested planes. Beam startup/active is the best existing
   model because both states preserve the exact corridor.
3. The reported enemy “lag” is reproducible by inspection as 20/30 Hz movement
   stair-stepping presented without interpolation. The observed manual run did
   not show sustained frame-rate collapse.
4. Health fills have incorrect left-edge math. Their rendered thickness also
   does not equal the nominal `16/18` height passed by callers, and large
   world-attached bars have no safe-edge placement.
5. A blanket speed increase is unsafe because two common ordinary pursuers are
   already faster than the base player. Difficulty should raise slow role
   speeds selectively, then apply staged ordinary health/damage increases and
   the full requested boss increase.

## Executive decision

### 1. Keep code-native geometry as a production visual layer

Disks, rings, strips, segments, and simple markers should be the final runtime
representation when their purpose is to communicate exact gameplay geometry.
They should not be replaced with raster images merely to add polish. Raster
assets remain appropriate for authored silhouettes and irregular surface
content, but not for a circle, corridor, health fill, shield boundary, or
source-to-target link whose dimensions change at runtime.

The current implementation failed because the primitives do not yet share one
strict semantic grammar, not because primitives are inherently temporary.

### 2. Adopt one effect grammar based on gameplay meaning

- A **filled footprint** means the complete region currently or imminently
  affected.
- A **body-attached boundary** means protection around that body.
- A **filled corridor** means a directional region with width and length.
- A **source-to-target link** means a relationship, not a collision width.
- A **brief full-footprint impulse** means an instantaneous area event.

Color identifies affinity only after shape and lifecycle identify meaning. A
free-standing ring must not be allowed to mean shield in one case, damage in a
second case, and projectile purge in a third without another differentiator.

### 3. Treat enemy jitter as a presentation-cadence defect first

The manual play trace averaged `59.88 FPS` for `226.62 s`, with no sustained
combat hitch sequence. However, ordinary enemy positions update at `30 Hz`
within `820 px` and `20 Hz` outside it, while the retained renderer directly
copies `enemy.pos` with no presentation interpolation. A moving enemy can
therefore remain at the same screen position for one or two 60 FPS frames and
then jump. This exactly matches the reported “standing still and moving as if
lagging” impression even when the game itself is maintaining 60 FPS.

Do not respond by moving the entire enemy simulation to 60 Hz. The stress
qualification remains release-red under peak workloads. Preserve scheduled
simulation and interpolate only presentation state.

### 4. Fix health bars before tuning bosses

The shared health fill does not remain anchored to the left edge. The current
translation uses only half of the required offset, so a partially depleted bar
shrinks toward an incorrect moving center. Boss bars also derive width from the
large boss visual radius and are not clamped to the viewport safe area, so they
can appear oversized or clipped near an edge. Health values and capacity are
otherwise sourced coherently.

### 5. Raise difficulty without another global speed multiplier

The current ordinary movement multiplier is already `1.40`. As a result,
`scrap_drone` moves at `315 px/s` in Stage 1 and `chaser` at `287 px/s`, both
above the player's base `280 px/s`. Another global increase would violate the
requested constraint. Replace the global speed result with role-family targets:
raise the slow ranged, support, and heavy roles, but cap common continuous
pursuers below the player. Only explicit special motion such as a Rammer charge
may exceed that speed.

The requested health and damage increases are viable, but together they nearly
double static encounter pressure before speed changes. Ramp ordinary bonuses by
stage, while applying the full boss increase and a modest shield-armor increase.

## Terms and invariants

The following terms should remain distinct in implementation and review:

| Term | Meaning | Owner |
| --- | --- | --- |
| Gameplay footprint | Exact world positions accepted by a damage, heal, protection, or purge query | combat/runtime |
| Semantic family | Danger, protection, support, utility, or navigation relationship | visual policy/catalog |
| Lifecycle state | Warning, active, resolved/impact, or persistent | runtime state plus renderer |
| Affinity | Thermal, arc, kinetic, toxin, cryo, support, or system identity | combat contract/palette |
| Presentation footprint | The visible geometry derived from gameplay footprint and lifecycle | combat renderer |

Required invariants:

1. The presentation footprint never understates or overstates the gameplay
   footprint for a dodgeable or damaging action.
2. A decorative plane must not create a second plausible hitbox.
3. Fill answers “where”; attachment and boundary answer “what is protected”;
   direction and motion answer “how and when.”
4. Similar effects use the same shape and lifecycle even when their affinity
   colors differ.
5. The effect ends when the gameplay state ends. A fading gameplay marker must
   not imply a still-active area after the state is off.
6. Reduced-motion mode preserves shape and state, removing only nonessential
   travel, pulse, or shake.

## Current visual implementation

### Current effect matrix

| Mechanic | Gameplay truth | Current presentation | Assessment |
| --- | --- | --- | --- |
| Electric Field | The complete player-centered disk deals periodic damage | Full arc-purple disk at `0.18` alpha, a stronger broken perimeter at `0.30`, and four narrow internal spokes | Footprint exists, but the perimeter dominates and makes edge-only damage plausible |
| Enemy circular area warning/zone | Complete disk is the warning or damaging area | Thermal disk at `0.10–0.20` plus a very faint ring | Mostly correct; fill must remain authoritative and any boundary must be subordinate |
| EMP charge | Startup cue for damage/stun radius `285` and projectile-clear radius `325` | Two filled disks plus an outer ring, all centered on current player presentation | Two real radii exist, but nested solid planes do not explain that they perform different actions |
| EMP release | Damage/stun is applied immediately at `285`; hostile projectiles clear immediately at `325` | Two fixed-radius disks fade together | Accurate radii, weak lifecycle; the opacity step reads as an arbitrary inner circle |
| Thermal Burst | Instant damage inside one complete disk | One low-alpha thermal disk fading uniformly | Geometry is correct; contrast and impact staging are too weak |
| Drop Mine detonation | Instant damage inside one complete disk | One low-alpha reward-color disk fading uniformly | Geometry is correct; affinity/readability and impact staging are weak |
| Explosive Seeker detonation | Instant damage inside a `95 px` disk | No transient effect receipt or renderer branch | Gameplay feedback is missing entirely |
| Mystery projectile purge | Projectile-only utility inside a complete disk | System disk plus a ring | Footprint is present, but the ring is not differentiated from protection or danger |
| Player barrier | Damage absorption attached to player | One mint body-attached ring; hit increases radius/alpha briefly | Correct family and lifecycle |
| Enemy shield | Damage reduction attached to protected enemy | Mint body tint plus one body-attached ring | Correct family; attachment makes the boundary meaningful |
| Boss shield | Boss damage reduction while shield-up | Command-magenta body-attached ring | Correct family, although it competes spatially with the oversized boss health bar |
| Beam/laser startup | Future damage corridor with exact width and end | Low-alpha filled corridor plus a narrow bright filament | Strongest current example of correct grammar |
| Beam/laser active | Current damage corridor with exact width and end | Saturated filled corridor, inner plane, and bright core | Correct; the complete corridor remains visible |
| Repair Tender heal | Relationship from healer to current recipient | Continuous `14 px` mint line drawn outside the retained combat renderer | Ambiguous with a beam, has no direction/readout, and splits visual ownership |
| Health bars | Current/max health for approved structures and boss | Backing and fill use shared code-native geometry | Correct owner and capacity, but partial-fill anchoring and edge placement are wrong |

Relevant implementation locations:

- `scripts/presentation/vehicle_combat_renderer.gd:580` builds the Electric
  Field; the stronger perimeter is defined at lines `584–607`.
- `scripts/presentation/vehicle_combat_renderer.gd:1085`, `1119`, and `1140`
  own beam startup, active beam, and area footprints.
- `scripts/presentation/vehicle_combat_renderer.gd:1167–1257` owns buffered
  EMP, Thermal Burst, Drop Mine, and purge effects.
- `scripts/vehicle/vehicle_run.gd:5994–6006` draws the Repair Tender link in a
  second presentation path.
- `scripts/presentation/vehicle_combat_renderer.gd:741–819` selects boss,
  facility, and installation health bars; `935–964` builds their geometry.

### Recommended production grammar

| Family | Required geometry | Lifecycle | Allowed accent | Prohibited ambiguity |
| --- | --- | --- | --- | --- |
| Persistent damaging area | One filled footprint equal to the full active query | Stable while active; one restrained application pulse | Two or three broad internal value planes that never hide the fill | Dominant perimeter, spokes that imply damage lanes, empty center |
| Warned area attack | Same filled footprint as the future active query | Low-alpha warning increases in value; active state changes value, not size | One low-contrast edge aid when exact dodge limits need it | Ring-only warning, shrinking warning, oversized glow |
| Protection | One closed boundary attached to the protected body | Stable boundary; short hit receipt and clear break/reform event | Body tint or a small shield tab | Free-standing shield ring, filled danger-like disk, nested rings |
| Beam/laser | One filled rectangle/capsule equal to the damage corridor and its end | Low-alpha startup; high-alpha active; immediate retirement | Thin central filament/core | Centerline-only collision cue, decorative width outside hit corridor |
| Support link/heal | Segmented narrow link from source anchor to target anchor | Directional packets or three-step value progression; recipient pulse on accepted heal | Small recipient bracket or plus/chevron marker | Solid high-alpha beam, area-sized fill when only one target is healed |
| Instant area impact | Complete filled footprint appears at impact time | Fast attack, short hold, uniform release; all planes end together | One brightness front may travel over an already-visible full footprint | Ring-only explosion, shrinking inner disk, one plane disappearing early |
| Utility/purge area | Complete footprint with a utility-specific internal pattern | Brief full-area pulse at the actual state transition | Sparse projectile/diamond markers or segmented outer fringe | Reusing shield boundary or damage fill without a utility cue |

#### Electric Field

Remove the broken perimeter entirely. Keep one full disk as the authoritative
damage footprint. Replace the four narrow spokes with at most two broad,
low-contrast internal value planes or a restrained alternating-sector value
change. The internal treatment distinguishes “electric field” from a thermal
disk, but no internal feature may be stronger than the complete fill.

This directly implements the user's rule: everywhere that looks affected deals
damage, and the whole damage area looks affected.

#### Shields

A shield may remain line-based, but only under a stricter rule: it is one closed
boundary attached to one protected body. Attachment, a mint/command family
color, and a hit receipt distinguish it from a free-standing radius. The
boundary should brighten or deform only when it absorbs a hit, and should
clearly disappear or break when protection is gone.

The rule is therefore not “every line is a shield.” It is “one body-attached
closed boundary is protection.”

#### Laser cannon and other beams

The current beam direction should be retained. Startup shows the complete
future corridor at low value and a narrow alignment filament. Active fire fills
the exact same corridor at high value with a bright core. Both sides and the end
must match collision truth. A laser is a directional area attack, so its filled
corridor follows the same “filled means affected” rule as a circular area.

#### Healing

The current solid mint line is not sufficient. It resembles a low-power laser
and does not state which direction health is moving. Use a segmented link or
two-to-three hard packets that progress from healer to recipient, then show a
brief recipient-attached repair tick. In reduced-motion mode, keep static
segments plus the recipient marker. If a future heal affects a region rather
than one target, that separate mechanic must use a filled support footprint.

The Repair Tender visual should move into the retained combat renderer. Keeping
it in `VehicleRun._draw_enemy_overlay()` creates two competing owners for combat
effect grammar.

#### Explosions, Thermal Burst, and mine detonation

Keep the exact full disk. At the instant gameplay damage is accepted, bring the
whole disk to readable value. A single broad brightness front may travel from
the source to the edge, but it rides over an already-visible filled footprint;
it does not replace the footprint. Then all planes fade together.

This fixes the unfinished appearance caused by an inner region changing or
disappearing independently. A useful timing envelope is:

- `0–35 ms`: full-footprint attack to peak value;
- `35–90 ms`: short hold with the optional broad front;
- `90–180 ms`: synchronized release to zero.

Reduced-motion uses the same full disk and synchronized fade without a moving
front.

#### EMP's two real radii

EMP is not one arbitrary double circle. Runtime applies damage/stun immediately
within `285 px` and clears hostile projectiles immediately within `325 px`.
Those actions need distinct semantics:

- the inner `285 px` region is the authoritative filled impact footprint;
- the outer `40 px` fringe is a projectile-purge utility band, encoded with
  sparse segmented marks or projectile/diamond interruptions rather than a
  second solid damage disk;
- the complete effect appears at release time because gameplay is immediate;
- an optional single outward luminance front may communicate origin and energy
  flow, but it must not imply delayed damage at the edge.

During charge, show the same geometry at warning value and keep it attached to
the current player position. This also avoids the earlier charge-center versus
release-center mismatch.

## Runtime and bug findings

### Manual trace result

The latest manual trace is diagnostic rather than authoritative, but it is
strong evidence about the reported play session:

| Metric | Result |
| --- | ---: |
| Active duration | `226.62 s` |
| Average FPS | `59.88` |
| Average/max frame | `16.70 / 133.33 ms` |
| Frames over `20 ms` | `15` of `13,570` |
| Frames over `33.3 ms` | `4` |
| Longest consecutive run over `33.3 ms` | `1` frame |
| Average/max physics | `3.26 / 35.15 ms` |
| Average/max presentation | `0.51 / 1.65 ms` |
| Average/max render CPU | `0.62 / 2.18 ms` |
| Average/max render GPU | `2.50 / 4.85 ms` |
| Maximum live enemies observed | `154` |
| Maximum ordinary enemies centered in viewport | `75` |

Three large isolated stalls happened at run/stage boundaries with zero live
enemies. Their `wait_or_unattributed` time was `87–123 ms`, so they do not
support an enemy-spawn CPU attribution. Only one combat frame exceeded `20 ms`
after enemies arrived: `23.96 ms` with `90` live enemies, and its physics work
was `3.92 ms`. The trace therefore does not show sustained runtime stutter in
the observed workload.

This does not make the project performance-qualified. The current native
stress records at commit `982fef4c` remain release-red: focused peak-horde
median was `12.13 FPS`, and capacity-pressure median was `7.50 FPS`. The manual
session peaked far below the synthetic capacity case. Large-scale simulation
changes must continue to use the performance guard.

### Additional effect-state defect

EMP charge is drawn at the current player position, but the renderer performs
visibility culling earlier against the effect's original `effect.pos`. If the
player moves far enough during the `0.42 s` charge to cross a viewport boundary,
the live charge footprint can be culled using the wrong position. Culling and
drawing must use the same current center. Spawn/teleport interpolation resets
must also use that center.

### Confirmed visible movement defect

`VehicleEnemyUpdateSchedule` uses:

- a `0.10 s` decision interval;
- `30 Hz` near motion;
- `20 Hz` far motion outside `820 px`.

See `scripts/enemies/vehicle_enemy_update_schedule.gd:13–15` and `143–169`.
The renderer receives the latest `enemy.pos` in
`scripts/vehicle/vehicle_run.gd:585–647` and directly writes that position in
`scripts/presentation/vehicle_combat_renderer.gd:741–819`. There is no stored
previous presentation position and no interpolation fraction in this path.

At 60 FPS, near enemies can visibly hold for one frame and far enemies for two,
then jump by their accumulated motion. This is movement stair-stepping, not a
frame-rate collapse.

Godot's official physics-interpolation documentation describes the same
low-tick/high-render-rate stair-step and recommends interpolation between the
previous and current transform. Cardborne uses pooled RefCounted enemy state
and a retained MultiMesh rather than per-enemy Nodes, so this path needs manual
presentation interpolation rather than merely enabling Node interpolation.

### Secondary movement risks

These are plausible contributors that need a deterministic fixture before they
are called root causes:

1. Local separation is a strong `45%` of final velocity and can reuse cached
   overlap direction. Dense same-origin spawns can alternate between pursuit
   intent and separation intent (`vehicle_enemy_local_steering.gd:9–10`,
   `24–99`).
2. Collision recovery can side-step and later flip strafe direction after a
   blocked interval (`vehicle_run.gd:3130–3170`). This is correct recovery in
   isolation but can look like local oscillation in a dense pack.
3. Collective `gather` and `lock` intentionally stop an enemy. A player should
   see a readable tactic state rather than infer lag.
4. The manual trace has aggregate pressure but no per-enemy motion history, so
   it cannot prove whether a specific freshly spawned mobile enemy remained at
   zero velocity too long.

### Recommended movement fix

1. Keep collision, damage, decision, and scheduled motion truth unchanged.
2. Give each visible mobile enemy presentation-owned previous/current
   positions and the duration of its scheduled motion interval.
3. Interpolate the MultiMesh transform between those samples in `_process()`.
   Use previous=current on spawn, teleport, reactivation, knockback, or other
   discontinuities.
4. Do not interpolate fixed structures, armed stationary mines, explicit
   collective locks, or startup states intended to hold still.
5. Add a spawn-motion fixture that records zero-velocity duration, visible
   repeated-position frames, direction reversals, overlap count, collective
   phase, and collision recovery state.
6. Only after interpolation is verified, tune separation and recovery if
   remaining oscillation is measurable.

This preserves simulation cost while improving visual smoothness. Raising all
enemy simulation to 60 Hz would be an unjustified hot-path expansion while the
stress gate is red.

### Confirmed boss-entry progression failure

There is a separate deterministic bug that can make a run appear stuck rather
than merely visually unsmooth. When the warning timer ends,
`VehicleStageFlow.tick()` changes state from `BOSS_WARNING` to `BOSS_ACTIVE`
and `_update_stage_progression()` calls `_start_stage_boss()` once. If more than
`307` enemies are live, `_start_stage_boss()` returns to preserve the boss plus
twelve add slots. The flow is already `BOSS_ACTIVE`, so the warning-tick branch
never calls it again. The stage can remain boss-active without a boss.

Keep the capacity guard, but make boss entry a retryable pending transition or
reserve/drain the required slots before committing `BOSS_ACTIVE`. Add a fixture
for live counts `307`, `308`, and `320` that proves the boss eventually appears
without exceeding the `320` hostile capacity.

### Health-bar audit

Approved bars are currently limited to:

- one stage boss;
- one reinforcement facility;
- up to twelve fixed installations with roles `turret`,
  `interceptor_tower`, `beam_sentinel`, and `generator`.

Mobile ordinary enemies, mines, Mystery Devices, and crates receive no bars.
The shared capacity is exactly sufficient: fourteen possible bars times two
instances (backing and fill) equals `28`. The current health ratio clamps safely
and guards a zero maximum. This entity policy and capacity are coherent with the
product specification.

The Mystery Device runtime still updates and validates a
`health_visible_timer`, even though the current renderer and visual contract
forbid a Mystery Device health bar. That is stale presentation-contract data,
not evidence that the renderer should restore the excluded bar. Retire the
field and its obsolete assertion during implementation unless another current
consumer is found.

Three geometry failures remain:

1. **Incorrect left anchoring.** The fill scale is `bar_width * ratio`, but its
   center moves by only `-bar_width * (1-ratio) * 0.5`. With a unit mesh spanning
   `-1..1`, the correct offset is the full `-bar_width * (1-ratio)`. The current
   fill shrinks around a moving point instead of keeping the left edge fixed.
2. **Unsafe world-space placement.** Boss width is derived from its large visual
   radius with scale `1.9`; facilities and installations do the same. There is
   no screen-safe clamp or width ceiling. A body near the top or side can have a
   clipped or disproportionately large bar, as seen in
   `30-boss-01-stage-1-shield-up-hit.png`.
3. **Nominal height does not equal rendered height.** The shared mesh has local
   Y bounds of `±1/6`, while callers pass Y scale `16` or `18`. The visible full
   height is therefore about `5.33` or `6` world units, not `16` or `18`. The
   current validator checks the transform-buffer scale value rather than final
   mesh bounds, so it cannot catch this discrepancy. Either the bar must render
   at the intended authored thickness or the API/validator must name and verify
   the actual thickness explicitly.

Recommended correction:

- fix the fill offset and validate ratios `0`, `0.25`, `0.5`, `0.75`, and `1`;
- verify final mesh bounds and visible thickness, not only transform scale;
- define explicit min/max world widths per bar class instead of allowing boss
  art scale to grow the bar without a ceiling;
- clamp the final bar rectangle to the visible safe area while keeping a short
  leader offset to its body when necessary;
- preserve one shared renderer and one shared capacity calculation;
- verify every approved entity class in one capture fixture, including a body
  at each viewport edge.

## Difficulty analysis

### Current speed state

Player base speed is `280 px/s`. Current ordinary speed is archetype base speed
times the global `1.40` movement multiplier and the stage speed curve
`[1.00, 1.01, 1.02, 1.03, 1.04]`.

| Role | Stage 1 | Stage 5 | Stage 5 / player | Result |
| --- | ---: | ---: | ---: | --- |
| scrap_drone | `315.0` | `327.6` | `1.17` | already too fast for an ordinary pursuer |
| chaser | `287.0` | `298.5` | `1.07` | already too fast for an ordinary pursuer |
| rammer cruise | `259.0` | `269.4` | `0.96` | appropriate cruise; explicit charge may exceed player |
| needle_drone | `238.0` | `247.5` | `0.88` | reasonable |
| shield_escort | `231.0` | `240.2` | `0.86` | reasonable |
| shooter | `217.0` | `225.7` | `0.81` | can rise slightly |
| repair_tender | `203.0` | `211.1` | `0.75` | can rise |
| bulkhead_guard | `196.0` | `203.8` | `0.73` | can rise |
| controller | `189.0` | `196.6` | `0.70` | can rise |
| splitter_barge | `168.0` | `174.7` | `0.62` | too passive |
| artillery_spotter | `161.0` | `167.4` | `0.60` | too passive during relocation |
| drone_carrier | `147.0` | `152.9` | `0.55` | too passive |
| spark_minelet | `126.0` | `131.0` | `0.47` | special deploy/arm role |

This explains why another scalar is the wrong tool: the two fastest ordinary
roles already violate the constraint while the slow half of the roster still
creates little pressure.

### Recommended continuous-speed targets

Use explicit role/family targets and interpolate between Stage 1 and Stage 5.
These are starting values for a deterministic fixture, not final balance
guarantees:

| Role/family | Stage 1 target | Stage 5 target | Intent |
| --- | ---: | ---: | --- |
| scrap_drone | `266` | `277` | fast ordinary ceiling, always below base player |
| chaser | `266` | `277` | same readable pursuit ceiling |
| rammer cruise | `266` | `277` | charge remains the explicit faster exception |
| needle_drone | `246` | `258` | slightly faster ranged repositioning |
| shield_escort | `238` | `250` | keeps pace with supported pack |
| shooter | `232` | `244` | closes dead space faster |
| repair_tender | `222` | `234` | support remains reachable but active |
| bulkhead_guard | `230` | `244` | heavier approach without outrunning player |
| controller | `210` | `224` | stronger denial positioning |
| splitter_barge | `220` | `234` | removes excessively passive heavy motion |
| artillery_spotter | `196` | `210` | relocates without becoming a pursuer |
| drone_carrier | `190` | `204` | improves pressure while preserving support identity |
| spark_minelet | `140` | `150` | modest approach increase before arming |

The apparent speed improvement should be judged after presentation
interpolation. Smooth `232 px/s` motion can feel more intentional than a
stepwise `260 px/s` motion.

### Current health and damage

Current ordinary health combines:

- archetype base health;
- an extra `1.12` for swarm/standard classes;
- stage health curve `[0.85, 1.00, 1.15, 1.30, 1.45]`;
- final ordinary multiplier `2.60`.

Current ordinary hostile damage combines base attack damage, global `1.755`,
and stage curve `[1.00, 1.03, 1.06, 1.09, 1.12]`. Boss pattern damage is already
stored as final Standard damage and deliberately bypasses ordinary and stage
multipliers. Boss health is `[1250, 1350, 1450, 1550, 1650] * 2.60`, resulting
in `[3250, 3510, 3770, 4030, 4290]`.

Applying a flat `+50%` health and `+30%` damage everywhere would produce:

| Stage | Standard ordinary health factor, current → flat target | Ordinary damage factor, current → flat target | Boss HP, current → flat target |
| --- | --- | --- | --- |
| 1 | `2.475 → 3.713` | `1.755 → 2.282` | `3250 → 4875` |
| 2 | `2.912 → 4.368` | `1.808 → 2.350` | `3510 → 5265` |
| 3 | `3.349 → 5.023` | `1.860 → 2.419` | `3770 → 5655` |
| 4 | `3.786 → 5.678` | `1.913 → 2.487` | `4030 → 6045` |
| 5 | `4.222 → 6.334` | `1.966 → 2.555` | `4290 → 6435` |

Health times damage alone becomes `1.95×` current pressure. Adding faster
closing and better interpolation raises effective pressure further.

### Recommended ordinary progression

Use the user's requested increases as the late-run target, but preserve a
teaching ramp:

| Stage | Additional health over current | Additional damage over current |
| --- | ---: | ---: |
| 1 | `+35%` | `+15%` |
| 2 | `+40%` | `+20%` |
| 3 | `+45%` | `+25%` |
| 4 | `+50%` | `+30%` |
| 5 | `+50%` | `+30%` |

Do not shorten warning times or increase hostile projectile speed in the same
pass. Higher health, contact frequency, and accepted damage are enough to raise
difficulty while preserving fair reaction windows.

### Recommended boss progression

Bosses are explicit exams and can take the full increase immediately:

- boss health multiplier: `2.60 → 3.90` (`+50%`);
- boss pattern damage: apply one explicit `1.30` boss-only multiplier to the
  current final-effective pattern and autonomous damage values; the ordinary
  hostile-damage multiplier does not affect them;
- shield-up incoming-damage multiplier: `0.15 → 0.12`, changing mitigation
  from `85%` to `88%` without making the shield fully invulnerable;
- exposed multiplier remains `1.00`;
- shield-down window initially remains `4.0 s` so the learned punish window is
  not silently invalidated;
- pattern startup, active corridor, and projectile speed remain unchanged in
  the first tuning pass.

Do not edit every pattern or increase the global hostile multiplier to achieve
the boss increase. The explicit boss-only knob is required so final-effective
pattern data remains coherent and independently tunable.

## External evidence

The external material is used for principles, not for copying another game's
surface style.

| Source | Relevant evidence | Cardborne use |
| --- | --- | --- |
| [Riot Games, Clarity in League](https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/) | Effects that disagree with hitboxes create clarity failures; visual attention should track damage, control, dodgeability, and impact; established shape language should remain stable | Make gameplay footprint authoritative and keep a stable family grammar |
| [League of Legends Patch 9.24](https://www.leagueoflegends.com/en-us/news/game-updates/patch-9-24-notes/) | Lux's beam received side indicators for actual width and an end indicator for actual range | Preserve the full beam corridor and exact end, not only a centerline |
| [VALORANT Patch 10.10](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-10-10/) | Explosion VFX was revised to match hitboxes more accurately and remain in the world for less time | Use exact full-footprint impacts with short, synchronized retirement |
| [VALORANT Patch 11.07](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-11-07/) | Similar abilities were made information-consistent; effect/map markers retire with the actual area state | Use the same grammar for the same mechanic and end cues with gameplay |
| [Xbox Accessibility Guideline 102](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/102) | Contrast and outlines can preserve readability against changing backgrounds | Use hard-edged contrast where necessary, but do not let an outline override footprint semantics |
| [Xbox Accessibility Guideline 103](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/103) | Color alone must not carry information; shapes and multiple channels reinforce meaning | Distinguish damage, shield, heal, and utility by geometry, lifecycle, sound, and color together |
| [Xbox Accessibility Guideline 117](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/117) | Repetitive motion, flash, blur, and shake should be avoidable or controllable | Keep one brief purposeful pulse and preserve reduced-motion alternatives |
| [W3C WCAG 2.2, Use of Color](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color) | Shape or another visual means must complement color | Require grayscale-readable semantic families |
| [UK HSE, Safety signs](https://www.hse.gov.uk/workplacetransport/safetysigns/) | Standardized combinations of shape, fill, border, and symbol keep meanings stable | Treat the effect system as a small repeated sign language, not isolated decoration |
| [U.S. Web Design System, Data visualizations](https://designsystem.digital.gov/components/data-visualizations/) | Limit each visual to a central idea; avoid color reuse for different variables; use patterns/shapes when needed | Give one effect one gameplay message and cap internal planes/patterns |
| [Godot, Physics interpolation introduction](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/physics_interpolation_introduction.html) | Low-rate position updates rendered at a higher rate create visible stair-stepping; interpolation uses previous/current samples | Manually interpolate pooled MultiMesh enemy presentation samples |
| [Godot, Using physics interpolation](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/using_physics_interpolation.html) | Interpolation should preserve fixed simulation timing, reset on teleports, and be tested at deliberately low rates | Keep scheduled gameplay truth, reset samples at discontinuities, and test 20/30 Hz visibly |
| [Marie Mejerwall, GDC 2025, Growing an AI Director into a Full Adventure Director](https://media.gdcvault.com/gdc2025/Slides/Mejerwall_Marie_Growing_an_AI.pdf) | Felt intensity, combat budget, enemy value, spawn direction, and pacing are separate levers; dynamic difficulty needs limits and playtest iteration | Do not equate difficulty with one speed/count scalar; tune health, damage, arrival, role movement, and budget separately |

## Implementation boundaries for the next contract

The next implementation should remain responsibility-shaped:

- `vehicle_combat_renderer.gd` owns final primitive geometry, health-bar
  transforms, and presentation interpolation consumption.
- The visual event/catalog layer should name semantic family and lifecycle; it
  must not own collision radii or damage truth.
- Update the effect catalog's stale `authored EMP` comment. The current EMP is
  a code-native exact-footprint effect, and the old wording can incorrectly
  suggest that a raster or radial-blade asset remains authoritative.
- `vehicle_run.gd` and combat runtimes continue to own actual footprints and
  state transitions. The Repair Tender link should be published as presentation
  state and removed from the separate immediate `_draw` path.
- Explosive Seeker must publish the same instant-impact family receipt as other
  exact-radius detonations instead of remaining visually silent.
- `vehicle_enemy_update_schedule.gd` continues to own work cadence. It should
  not absorb visual smoothing.
- Enemy role speeds belong with archetype/movement tuning, while stage health
  and damage curves remain in the stage difficulty owner.
- Boss shield armor remains in `vehicle_boss_shield_runtime.gd`; boss attack
  scaling must use one explicit boss knob because boss patterns bypass ordinary
  damage scaling.

Avoid the following changes:

- no new raster image for a plain disk, ring, strip, health bar, or link;
- no dominant perimeter on a full-area damage effect;
- no second visual radius unless gameplay has a second radius with a different
  meaning;
- no global enemy-speed increase on top of `1.40`;
- no all-enemy 60 Hz simulation rewrite to hide presentation stair-stepping;
- no difficulty increase through shorter telegraphs in the same pass;
- no broad `VehicleRun` expansion when an existing presentation, movement, or
  difficulty owner already exists.

## Verification contract

### Visual grammar

1. Capture Electric Field levels 1–3 and prove the full disk is the dominant
   visible plane with no perimeter.
2. Capture EMP charge/release in standard and reduced-motion modes, with both
   `285` and `325` gameplay semantics visibly distinct but not confused as two
   damage disks.
3. Capture Thermal Burst and Drop Mine at their minimum/maximum radii at impact,
   hold, and final fade frames.
4. Capture Explosive Seeker and prove that its complete `95 px` gameplay disk
   receives one instant-impact presentation without inventing another radius.
5. Capture beam startup and active states and compare both sides and endpoint to
   collision truth.
6. Capture player, enemy, and boss shields at stable, hit, break, and restored
   states.
7. Capture Repair Tender source/target, accepted repair, target change, target
   loss, and reduced-motion state.
8. Review the full matrix in grayscale and against the lightest/darkest stage
   backgrounds. Color may reinforce but not define the family.

### Movement and spawn behavior

1. At 60 FPS rendering, record screen positions for near `30 Hz` and far `20 Hz`
   mobile enemies. A moving actor must not visibly hold-and-jump between samples.
2. Reset interpolation on spawn, reactivation, knockback, teleport, and defeat.
3. Record zero-velocity duration for every mobile role after it becomes visible.
   Any hold over the approved threshold must be explained by startup, collective
   lock, stun, collision recovery, or role policy.
4. Record direction reversals and overlap count for dense spawn fixtures to
   detect separation oscillation independently of frame timing.
5. At live counts `307`, `308`, and `320`, complete the boss warning and prove
   that boss entry retries or drains capacity until the boss appears.
6. Re-run the focused movement, spawn distribution, contact, and collision
   validators before broad qualification.

### Health bars

1. Pixel/transform assertions at ratios `0`, `0.25`, `0.5`, `0.75`, and `1`
   prove an invariant left edge and exact fill ratio.
2. One fixture covers boss, facility, turret, interceptor tower, beam sentinel,
   and generator, and proves zero bars for excluded entities.
3. Edge fixtures cover top, bottom, left, and right safe-area placement without
   clipping or body detachment.
4. Capacity remains `28` instances unless the approved entity policy changes.

### Difficulty and performance

1. Validate exact stage health/damage factors and the role speed matrix.
2. Assert that ordinary continuous speed remains below `280 px/s` at Stage 5;
   explicit special charge speed is tested separately.
3. Measure time to first pressure, ordinary time-to-kill, damage taken per
   minute, boss duration, exposed-window damage share, and player defeat stage.
4. Use targeted checks during implementation. After the full feature set is
   stable, run the native peak-horde and capacity workloads, Web export/build
   smoke, production-style start, and a new manual play trace.
5. Do not claim performance success from the current manual trace alone; the
   synthetic release gate remains red until requalified.

## Limitations

- The manual trace did not record individual enemy position histories, so it
  proves a stable observed frame rate and exposes the scheduled/rendered cadence
  mismatch, but it cannot identify which specific role the user saw oscillate.
- The recommended speed and stat values are bounded starting points. They need
  deterministic fixtures and real playtesting; external sources cannot choose
  final Cardborne balance values.
- Current captures are staged evidence rather than a recording of the exact
  user's reported moment. They are sufficient to diagnose visual grammar and
  health-bar geometry, not every encounter sequence.
- This report does not authorize production edits or replace the active visual
  and product specifications. Accepted decisions must be promoted into those
  authoritative documents and a decision-complete ExecPlan before broad
  implementation.
