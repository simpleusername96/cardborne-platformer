---
type: evidence
status: active
owner: BK
created: 2026-08-15
last_reviewed: 2026-08-15
topic: Combat readability, neutral-facility influence, enemy engagement, boss identity, encounter pressure, and failure-report completeness
scope: Read-only review of the current eight-cycle Cardborne build at commit ad7d23d6; no gameplay, UI, product-spec, visual-spec, asset, or balance changes
related:
  - ../../execplans/2026-08-15-combat-readability-and-pressure-decisions.md
  - ../../../docs/product/vehicle_game_spec.md
  - ../../../docs/design/VISUAL_SYSTEM.md
  - ../../design/DESIGN.md
  - ../../cardborne-performance-engineering-policy.md
  - ../../execplans/2026-08-15-eight-boss-combat-depth-and-run-report.md
---

# Combat Readability and Pressure Review

## Purpose

This report checks the reported failure-summary, neutral-facility, combat-cue,
conditional-upgrade, enemy-movement, boss, projectile, and encounter-pressure problems
against the current code, contracts, validators, captures, and relevant external primary
sources. It separates confirmed defects from intentional behavior with poor feedback and
from requested product changes. It recommends a coherent direction but does not authorize
or implement gameplay or visual changes.

## Findings

> Owner decision update, 2026-08-15: implementation uses one top-left HUD row, facility
> duration clips the large effect-footprint perimeter rather than a facility-body contour,
> every hostile damaging area uses danger-red fill with a thin near-black perimeter, and
> the exact live ordinary cap is 72. These decisions supersede lower-cap, two-row, and
> body-contour recommendations below where they conflict.

Four material implementation gaps are confirmed:

1. A defeat report cannot receive build rows because the failure-stage context omits a
   build snapshot. The current report validator does not cover that failure path.
2. Neutral facilities take projectile damage, but the projectile intentionally continues
   and the damage path discards its hit position, color, and direction. The result can look
   identical to a miss or pass-through.
3. The Drydock and Crown boss profiles declare frontal and sector defenses, but the runtime
   implements only one global binary damage multiplier and the renderer displays a full
   closed ring. Directional shields are not implemented.
4. Hostile area descriptors carry owner data in gameplay, but the retained area renderer
   discards it and renders all hostile denied zones with the same thermal-orange disk
   grammar. This collides with player-owned orange circular effects.

The other observations are also well grounded, but some are current design choices rather
than isolated bugs:

- Ranged and support enemies intentionally maintain distance, and recovering enemies can
  reverse. A separate one-shot engagement gate can also send a newly materialized enemy
  toward a stale predicted anchor for up to 18 seconds. The last case is the strongest
  explanation for movement that looks purposeless.
- The newer facility contract and runtime explicitly use projectile pass-through, although
  an older product-spec paragraph still says player shots are blocked. Changing the
  coherent newer rule changes combat; adding clear impact receipt does not.
- Repair and Barrier share the same mint color. Gravity uses a system-blue treatment, not
  black. Color alone is not permitted to carry role under the current accessibility and
  visual contracts.
- Stage 1 materializes at most 18 ordinary enemies and later stages at most 48 even though
  the authored reserve is much larger. Continuous refill within the existing cap is the
  lowest-risk way to increase pressure before raising capacity.
- Boss death explosion, the present facility radii, the exact top-left HUD contents, and
  boss threat/fairness values are explicit current contracts. The requested changes need
  those owners revised together rather than code-only patches.

The wider audit found four additional defects or evidence gaps outside the original list:

- boss cleanup receipts explicitly deny boss-owned rewards, but finalization still
  increments defeats, spawns XP, and calls the group-reward path;
- the shared boss broad barrage fires without an attack descriptor/radar cue;
- gameplay creates a `wedge_ring` denied zone for the Pulse boss, but the overlay renderer
  handles only corridor and area shapes, so that exact hazard can be invisible;
- the report builder labels every recorded boss ID `CLEARED` even when its cleanup has not
  completed.

There is also unresolved authority drift: the product spec requires `Boss N/8` plus
remaining quota, while the visual spec, root instructions, HUD fallback, and validator
still retain parts of a ten-stage or no-quota model. Ordinary difficulty likewise has ten
product-spec values but eight runtime values. Pressure work must resolve these owners
before changing encounter curves.

The product spec is also internally inconsistent about facilities: its general projectile
section says an intact Anomaly Device blocks actors and player projectiles, while the later
facility section says facilities accept both factions' damage and never block projectiles.
The newer eight-cycle plan, runtime, and facility validator implement pass-through. That
newer coherent set is the recommendation, but the stale earlier paragraph must be removed
during contract revision.

A targeted validation run found an additional repository problem: seven focused validators
passed, but `validate_vehicle_engagement_replay.gd` fails for both representative seeds at
`preserves authored count`. Its fixture assumes a packet can fully materialize during the
sample even though the newer stage cap can prevent that. This is a stale validation
contract, not evidence that the reported movement is correct.

Documentation authority validation also fails on current HEAD because it still requires
the retired heading `Inner walls, Transit Gates, and Anomaly Devices`, while the product
spec now uses `Inner walls, Transit Gates, and neutral facilities`. This is another stale
validator assertion; the two new documents did not change either file.

## Sources

### Local authority and implementation

- `docs/product/vehicle_game_spec.md`: run, facility, encounter, boss, report, fairness, and
  capacity contracts.
- `docs/design/VISUAL_SYSTEM.md` and the canonical style sheet: semantic palette,
  silhouette-first readability, facility footprints, HUD ownership, area cues, and boss
  death presentation.
- `.agents/design/DESIGN.md`: player-facing intent and authority order.
- `.agents/cardborne-performance-engineering-policy.md` and
  `.agents/research/performance/cardborne-runtime-architecture-audit.md`: fixed-capacity and qualification
  requirements.
- `scripts/vehicle/vehicle_run.gd`, `scripts/combat/vehicle_stage_report_builder.gd`, and
  `scripts/results/vehicle_run_result_builder.gd`: report data flow.
- `scripts/vehicle/vehicle_mystery_device_runtime.gd` and
  `scripts/presentation/vehicle_combat_renderer.gd`: facility collision and presentation.
- `scripts/enemies/vehicle_enemy_movement_policy.gd`,
  `scripts/encounters/vehicle_engagement_director.gd`, and
  `scripts/encounters/vehicle_encounter_director.gd`: movement and pressure.
- `scripts/bosses/vehicle_boss_phase_catalog.gd`,
  `scripts/bosses/vehicle_boss_shield_runtime.gd`, and
  `scripts/bosses/vehicle_boss_patterns.gd`: boss identities and implemented mechanics.
- `scripts/combat/vehicle_primary_combo_runtime.gd`,
  `scripts/player/vehicle_dash_upgrade_runtime.gd`, and
  `scripts/player/vehicle_player_recovery_policy.gd`: conditional upgrade state.
- Existing rendered captures under
  `build/captures/facility-activation-xp-health-fix-muted/`, especially the active HUD,
  two-facility field, boss startup, and failure-report frames.
- Git history through commit `ad7d23d6`.

### External primary and authoritative guidance

- [Microsoft Xbox Accessibility Guideline 102: Contrast](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/102)
  supports high-contrast outlines for critical cues across changing backgrounds.
- [Microsoft Xbox Accessibility Guideline 103: Additional channels](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/103)
  says color-coded information also needs shape, pattern, icon, text, or audio.
- [W3C WCAG 2.2: Use of Color](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color)
  likewise rejects color as the only information channel.
- [Riot's Resistance Illaoi VFX review](https://nexus.leagueoflegends.com/en-us/2018/02/resistance-illaoi-the-final-update/)
  describes damage-area clarity, restrained opacity/detail, and contrast at the important
  projectile feature.
- [VALORANT Patch Notes 8.01](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-8-01/)
  records restoration of a directional warning after an interaction became unclear.
- [Ubisoft's Far Cry 6 accessibility review](https://news.ubisoft.com/en-ca/article/43Uvc8MM55rAsvq8JgaVXU/accessibility-spotlight-far-cry-6)
  documents configurable outlines/colors and independently toggleable temporary-buff HUD
  modules.
- [Ubisoft on communicating game information](https://news.ubisoft.com/en-us/article/3FpgxppxEUmS0dciV2vsY7/create-the-unknown-communicating-information-in-games-is-more-complicated-than-you-think)
  supports combining UI, world signifiers, feedback, and sound without showing every fact
  all the time.
- [GDC 2025: Growing an AI Director into a Full Adventure Director](https://gdcvault.com/play/1035589/Game-AI-Summit-Growing-an)
  supports combining tracked pacing with authored gates. It does not provide Cardborne
  values.
- [Godot 4.7 CPU optimization guidance](https://docs.godotengine.org/en/4.7/tutorials/performance/cpu_optimization.html)
  supports profiling first and reusing or removing inactive physics objects.
- [Bungie's Season 22 weapons preview](https://www.bungie.net/7/en/News/article/season-22-weapons-preview)
  is evidence for intentionally bounded engagement ranges and projectile-velocity tuning,
  not for Cardborne's proposed distance-growth mechanic.

## Finding Matrix

| Concern | Classification | Severity | Current truth | Recommended direction |
| --- | --- | --- | --- | --- |
| Defeat report omits build | Confirmed defect and test gap | High | `_stage_report_context(false)` supplies no `build_rows` or `build_snapshot`; the builder defaults to an empty array | Freeze one gameplay-owned build snapshot for victory and defeat; assert non-empty owned-build rows in the defeat validator |
| Facilities feel too small | Requested balance/spec change | High | Current radii are 360-480 and affect both factions for 12 seconds | Test an approximately 3x strategic footprint with reduced magnitude and explicit overlap rules |
| Facility/projectile colors collide | Confirmed readability gap plus visual-spec change | High | Repair and Barrier both use mint; role is not consistently carried by projectile/effect grammar | Give each effect a stable hue plus unique contour/glyph; never use hue alone |
| Own versus hostile circles are unclear | Confirmed presentation-data loss | Critical | Owner exists in the gameplay descriptor but is not represented by the renderer | Encode owner in the outer boundary and affinity in the interior; preserve exact collision footprint |
| Conditional upgrades are invisible in HUD | Confirmed feedback gap plus HUD-spec change | High | Gameplay owns stacks/timers, but the HUD snapshot exposes only stage, defeats, dash, and active cooldowns | Add a compact, bounded conditional-status strip below the current top-left row |
| Enemies travel away or elsewhere | Mixed: intended standoff/recovery plus likely stale-gate UX defect | High | One-shot gates target a predicted birth-time anchor and can remain active for 18 seconds | Add an early relevance-release rule and diagnostics; do not erase intentional standoff behavior |
| Shots appear to pass through facilities | Intentional pass-through plus missing hit receipt | High | Damage applies once per projectile/facility, then the shot continues; hit metadata is discarded | Keep pass-through initially; add local impact receipt and optional projectile energy-loss cue |
| Remove boss death explosion | Locked user direction; product/visual contract revision | Medium | One authored explosion is currently required | Remove explosion presentation and retain a body-only shutdown/fade during the existing safe cleanup |
| Increase boss ranges/speeds by about 50% | Requested balance/spec change | High | A blanket 1.5x radius creates 2.25x area and boss movement can approach player base speed | Use axis-specific multipliers and preserve warning/corridor invariants |
| Distance-growing projectile | New mechanic | Medium | No current implementation or direct external validation | Introduce first as one boss/elite identity with a capped curve, not as a global projectile rule |
| Directional shields | Confirmed boss-design implementation gap | Critical | Shield catalog names are directional, runtime damage is global | Implement Drydock frontal interception and Crown body-attached sectors with directional hit tests |
| Boss design differs from implementation | Confirmed in defense; partial elsewhere | High | Eight patterns exist, but the most explicit directional-defense identities collapse to one binary shield | Close defense gap before expanding pattern count; validate each boss identity from input to rendered cue |
| Too few enemies / keep spawning | Pressure/capacity change | High | Active caps are 18, 32, 40, 40, then 48; the large authored population is a reserve | Continuously refill an engaged-visible floor within cap 48, then consider cap increases only after Web qualification |
| Engagement replay validator fails | Confirmed validation regression | Medium | Both fixed seeds fail authored-count preservation on current HEAD | Align the fixture with admission caps or assert deterministic reserve preservation instead |
| Boss reward granted despite no-reward cleanup | Confirmed contract violation | Critical | Death receipt says `grant_rewards:false`, but finalization still grants XP/group reward | Make one owner decide terminal reward effects and test zero boss-owned reward |
| Shared broad barrage has no descriptor/radar cue | Confirmed telegraph gap | Critical | Barrage fires directly; telegraph builder has no broad-barrage branch | Publish exact startup descriptor and offscreen warning before its first projectile |
| Pulse wedge-ring hazard is skipped by renderer | Confirmed exact-footprint gap | Critical | Gameplay creates `wedge_ring`; overlay renderer handles only corridor and area | Add an exact wedge-ring presentation path and focused rendered validation |
| Boss row can report `CLEARED` too early | Confirmed report-truth defect | High | Any recorded boss ID is labeled cleared even if cleanup is incomplete | Derive status from completed cleanup/flow state, not ID presence |
| Eight-cycle HUD and difficulty authority drift | Contract contradiction | High | Product requires `Boss N/8` plus quota and ten difficulty values; runtime/visual owners differ | Resolve canonical cycle/progress and curve owners before pacing edits |
| First-attack-prep deadline lacks evidence | Validation gap | Medium | Runtime records cue/spawn/damage but no explicit first preparation time | Add the required 8-second metric and deterministic validator |
| Facility projectile rule contradicts itself | Product-spec defect | High | Earlier section blocks player shots; later facility section and runtime pass both factions through | Select pass-through plus hit receipt and delete the stale blocking paragraph |
| Archive Cross is not an X-laser | Confirmed boss-identity gap | High | Approved design describes an X-cross laser; runtime emits four ordinary projectiles | Implement the committed X corridor/beam identity or revise the approved boss design explicitly |
| Document-authority validator expects retired heading | Confirmed validation regression | Low | Validator searches for `Anomaly Devices`; current spec heading says `neutral facilities` | Update the authority assertion to the canonical current heading/owner contract |

## Detailed Analysis and Recommendations

### 1. Failure report and adjacent report risks

`VehicleRun._handle_player_defeat()` passes `_stage_report_context(false)` to the stage
report builder. That context contains stage, time, hull, pacing, and diagnostics fields but
not the current build. `VehicleStageReportBuilder` accepts `build_rows`, yet defaults the
missing field to an empty array. Final victory takes a separate route through
`_build_snapshot()`, so the two terminal outcomes have drifted.

The repair should not make the report UI inspect `run_build`. A gameplay-owned terminal
snapshot should be frozen before modal presentation and shared by defeat, stage-clear, and
final-result builders. Tests should cover at least: empty starting build, a partial build,
three-level cards, active/secondary weapons, Korean and English labels, and defeat after a
card selection. The visible capture confirms the current failure report prints `기록 없음`.

Adjacent risks found during review:

- report validators accept an empty failure build and therefore certify the defect;
- final and failure report assembly have competing paths, which invites further drift;
- the current report contract requires the same section order across result surfaces, but
  data parity is not asserted at the producer boundary.

### 2. Neutral facilities: strategic area, identity, and hit receipt

The user's approximate 3x request translates to these first-pass target radii:

| Facility | Current radius | Approximate 3x target | Proposed role treatment |
| --- | ---: | ---: | --- |
| Repair | 420 | 1260 | green core/fill, medical cross or four inward repair cuts |
| Barrier | 420 | 1260 | light-blue fill, opposed shield vanes or bracket contour |
| Gravity | 480 | 1440 | near-black center with pale high-contrast rim and inward pull ticks |
| Cryo | 360 | 1080 | ice blue, broken angular/faceted contour |
| Weakpoint | 420 | 1260 | danger red, open target cut or converging marks |

Black cannot be the only gravity signal because the world and structural masses include
dark values. Use black as the interior identity, with a light system rim and a unique
inward-motion pattern. Likewise, do not make every projectile subtype a different arbitrary
hue. Preserve a hierarchy: owner silhouette first, effect/affinity color second, phase or
power third.

A 3x radius is not a small linear buff. It substantially increases screen and encounter
coverage, allows more facility overlap, and multiplies per-tick actor checks. To keep the
feature strategic instead of automatic, the first playtest should:

- use the approximate 3x footprint requested by the user;
- reduce continuous effect magnitude by roughly 30-50 percent as a tuning hypothesis,
  while keeping the 12-second decision window initially;
- make same-kind overlaps choose the strongest value instead of multiplying;
- permit at most two distinct facility modifiers to affect one actor at once, with a
  deterministic priority rule;
- profile the worst case with two overlapping facilities and the active-enemy cap;
- retain symmetry: facilities continue to affect player and hostile actors.

Facility collision should initially remain pass-through. On a hit, render one small,
short-lived receipt at the actual impact point: a high-contrast core flash, a brief local
contour compression, and an effect-colored fragment/tick oriented from the hit direction.
The projectile can lose brightness for one frame after the accepted hit so continuation
does not read as no contact. This cue must be pooled and capped.

### 3. A readable ownership grammar for projectiles and circular attacks

The current ambiguity comes from overloading orange circles, not merely from insufficient
brightness. The renderer should use this invariant:

| Information | Player-owned | Hostile-owned | Neutral/facility |
| --- | --- | --- | --- |
| Outer boundary | Broken perimeter with outward-facing cuts | Solid danger edge with four inward notches/teeth | Clockwise segmented timer contour |
| Projectile silhouette | Teardrop/body with a bright rear tail | Barbed spearhead with a dark outline | Compact role glyph or pulse packet |
| Affinity interior | Thermal orange, cryo blue, toxin green, arc purple, kinetic off-white | Same affinity family at lower fill opacity; danger remains on the owner edge | Facility role color |
| Startup motion | Expands or pushes outward | Converges inward and completes a countdown sweep | Rotates or drains with remaining duration |
| Audio supplement | player launch/activation family | hostile warning/impact family | facility activation/hit family |

The boundary must match the real collision footprint. Avoid additional decorative rings,
opaque interiors, and dense fine lines. This preserves the current visual-system rule that
color is secondary, while making a black gravity effect and same-affinity opposing attacks
readable in grayscale.

### 4. Top-left conditional-status strip

The runtime already owns the facts needed for feedback:

- Dash Overdrive: `overdrive_remaining`, maximum 2 seconds;
- Miss Compensation: `miss_stacks`, maximum 5;
- Hit Chain: `hit_stacks`, maximum 8;
- Braced Fire: travel segments, active segments, and a 4-second active timer;
- Overflow Barrier: barrier strength and an 8-second timer;
- Last Stand: hull threshold and the gameplay-owned damage bonus.

Add a second compact strip directly below the existing top-left stage/defeat/dash/active
row. Do not add a permanent full build rail. Only show status slots for owned cards, with a
maximum of five visible slots and stable priority:

1. expiring defense or harmful state;
2. active timed damage state;
3. charged/ready next-hit state;
4. maintained combo stacks;
5. threshold state.

Each slot needs a semantic glyph or contour, numeric stacks/segments when applicable, and
remaining time for timed effects. Braced Fire should show charge as `N/5`, then switch to
the active segment count and timer. Miss Compensation and Hit Chain need a brief consumed
or reset flash. Last Stand should appear only while its threshold is active. The HUD must
render a bounded gameplay-owned `conditional_statuses` snapshot; it must not calculate
card rules. Korean/English full names belong in the Settings/build surface, not in combat.

### 5. Enemy movement and engagement relevance

Not every enemy should always approach. Rangers and support roles have authored distance
bands; recovery can reverse; stationary roles can hold. Removing those rules would erase
role identity. The separate engagement gate is the likely bad-looking case: it is selected
from the player's predicted heading at materialization, remains immutable, and can guide an
enemy sideways or away after the player reverses.

Keep immutable gates for deterministic admission, but release them early when they are no
longer relevant. A first implementation hypothesis is to release after 0.75-1.0 seconds of
increasing player distance when the gate direction opposes the current player direction,
or when reaching the gate would add more than roughly 300 units compared with entering the
role policy immediately. Do not retarget or teleport. Add a bounded `movement_reason`
diagnostic for engagement gate, standoff, recovery, wall reposition, and ordinary pursuit,
then capture distance delta during representative play.

The failing engagement replay validator should be corrected before this change so it does
not hide a real movement regression. Its count assertion should respect the admission cap
and deterministic reserve rather than require every authored enemy to materialize in one
fixed sample.

### 6. Boss defense identity and attack tuning

Directional defense is the clearest design-to-code gap.

- Drydock: use a body-attached frontal arc, locked to the boss facing during a committed
  attack. Resolve incoming hit direction against that arc. Blocked damage should feed the
  existing counter-attack/charge identity. Hits from the rear bypass it.
- Crown: use three body-attached sector-integrity values rather than separate free-standing
  objective actors. Render active sectors as one segmented boundary recipe. This preserves
  the current ban on external objective nodes while creating real flank choices.

Both need tests for front/rear hits, sector depletion, facing lock, damage routing, and the
defense-to-attack link. A full closed ring must not claim omnidirectional protection when
the collision rule is directional.

The gap is broader than shields. Titan currently lacks the approved frontal
interception-to-counterburst coupling, Crown lacks its three relay/sector integrity
mechanic, and Archive Cross resolves as four projectiles rather than the approved X-cross
laser. The current eight-pattern sequence exists, so this is not wholesale absence; it is
loss of the mechanics that make those bosses strategically distinct. Close those identity
gaps before adding more boss patterns.

Do not apply a blanket 1.5 multiplier to every boss dimension. The following first pass
honors the request for a broad increase while protecting escape and first-clear rules:

| Axis | Proposed first pass | Reason |
| --- | ---: | --- |
| Ordinary boss locomotion | 1.25x | 1.5x would put late bosses near the player's base movement speed |
| Projectile speed | 1.40x | Substantial pressure increase without making every shot effectively instantaneous |
| Beam/projectile reach | 1.45x | Close to the requested 50 percent and directly affects engagement range |
| Charge speed | 1.30x | Keeps the charge readable with existing warning constraints |
| Circular/wedge radius | 1.25x | Radius already converts to 1.56x area; 1.5x radius would create 2.25x area |
| High-threat startup | no reduction; add 0.15s when footprint exceeds the old maximum | Preserves the minimum 1.30-second warning and escape corridor |

Keep existing late-stage coverage scaling; do not multiply it a second time. Tune per boss
after each attack passes the exact-footprint, one-hit, no-retarget, and escape-corridor
contracts.

The boss death explosion should be removed as requested, but cleanup timing and danger
shutdown should remain. Use a body-only shutdown: immediate attack disable, brief hit tint,
desaturation/dimming, and fade during the existing two-second safe cleanup. Reduced-motion
mode should skip scale motion. This requires coordinated updates to the product spec,
visual spec, production manifest/workbench counts, semantic provider, renderer, captures,
and validators.

### 7. Distance-growing projectile and encounter pressure

Do not make distance growth a global projectile rule. It would make off-screen and kiting
shots the strongest throughout the game, obscure ordinary role learning, and expand the
hot path for every bullet. Start with one Siege Battery boss or later elite identity:

- reduced threat inside an explicit close safety band;
- arming distance around 320-400 units;
- capped two-stage growth ending around 800-900 units;
- illustrative curve: speed `0.75x -> 1.35x`, radius `1.0x -> 1.5x`, damage
  `1.0x -> 1.6x`;
- visible size/trail-stage change before damage increases;
- no growth through walls, no uncapped scaling, and a threat-radar cue before an off-screen
  projectile becomes dangerous.

Those numbers are hypotheses, not sourced balance facts. The external evidence supports
bounded engagement ranges, not this exact mechanic.

For enemy density, first make admission continuously refill a target engaged-visible floor
while ordinary combat is active. Keep attack-commit and denial budgets separate so more
bodies do not mean simultaneous unavoidable attacks. A first cap hypothesis is
`28, 36, 44, 48, 48, 48, 48, 48`, but do not exceed 48 until a current built-Web sample
qualifies worst-case actors, projectiles, overlapping facilities, HUD statuses, and boss
effects. Seal ordinary admission when the quota boss begins, as the current stage contract
requires.

The active execution record contains a passing native release sample for an earlier commit,
but no matching current built-Web qualification. Therefore this review makes no global
performance-pass claim.

### 8. Additional boss, report, and authority defects

The boss death runtime publishes cleanup receipts with `grant_rewards:false`, but
`VehicleRun._finalize_boss_destruction()` independently increments defeat totals, spawns
XP, and calls group reward. That is a competing owner and can contaminate XP, progression,
and terminal report totals. The later implementation should make the death receipt or flow
owner authoritative and remove the duplicate finalizer decision.

The shared broad barrage bypasses the attack-telegraph builder, so it lacks the same startup
descriptor and offscreen radar path used by other boss attacks. Separately, the Pulse
boss creates a gameplay-owned `wedge_ring` hazard that the retained overlay renderer does
not recognize. Both defects violate the exact committed-geometry and hostile-warning
contracts and should be corrected before increasing projectile speed or reach.

Report truth has another edge case: `_boss_rows()` treats the presence of a recorded boss
ID as cleared even if the safe cleanup has not completed. The report producer should use
the completed stage-flow state. It should also assert that XP/reward totals agree with the
no-boss-reward contract.

Finally, the current sources disagree on run vocabulary and curves. The product spec owns
eight boss cycles and `Boss N/8` with remaining quota; parts of the visual spec, root
instructions, HUD fallback, and tests still describe ten stages or deliberately omit quota.
The product spec also contains a ten-value ordinary difficulty curve while runtime owns
eight values. These contradictions are not a reason to choose silently. A later contract
must nominate one eight-cycle HUD/progression vocabulary and one eight-entry runtime curve,
then update every owner and validator together.

## Recommended Priority

1. Fix boss reward ownership, missing broad-barrage/wedge-ring cues, and report snapshot
   truth, including the premature `CLEARED` status.
2. Repair the stale engagement replay validator, then add movement-reason evidence and
   engagement relevance release.
3. Resolve eight-cycle HUD/quota and difficulty-curve authority drift.
4. Establish the owner/affinity/phase cue grammar and facility hit receipt before changing
   projectile or AOE volumes.
5. Add the bounded conditional-status snapshot and top-left strip.
6. Implement real directional boss defense and remove the boss-death explosion after the
   owning specs are revised.
7. Apply approximate 3x facility footprints with overlap and magnitude safeguards.
8. Apply axis-specific boss pressure tuning and continuous refill within cap 48.
9. Prototype the distance-growing projectile on one boss, then qualify the combined Web
   workload before considering higher simultaneous enemy caps.

## Validation Evidence

Run on Godot `4.7.1-stable` at commit `ad7d23d6`:

- passed: `validate_vehicle_stage_report.gd`;
- passed: `validate_vehicle_upgrade_facilities.gd`;
- passed: `validate_vehicle_enemy_movement_policy.gd`;
- failed: `validate_vehicle_engagement_replay.gd`, both fixed seeds at authored-count
  preservation;
- passed: `validate_vehicle_boss_patterns.gd`;
- passed: `validate_vehicle_boss_exams.gd`;
- passed: `validate_vehicle_encounter_pacing.gd`;
- passed: `validate_vehicle_combat_renderer.gd`.

Documentation checks after writing this report:

- passed: `validate_cardborne_visual_authority.ps1`, including canonical sheet hash and
  dimensions;
- passed: `git diff --check`;
- failed on a pre-existing stale assertion: `validate_document_authority.ps1` expects the
  retired Anomaly Device section heading rather than the current neutral-facility heading.

Passing means the current validator contract passes; it does not refute the gaps above.
For example, the boss exam validates binary shield state but not directional interception,
and the stage-report validator accepts an empty failure build.

## Limitations

- No gameplay, UI, spec, or asset was changed or prototyped.
- No live manual run, new rendered capture, Web export, or new performance sample was
  produced. Existing captures were inspected at original detail.
- Exact balance numbers require playtests and current built-Web profiling.
- The external sources provide readability, accessibility, pacing, and performance
  principles. They do not validate Cardborne-specific multipliers or the distance-growing
  projectile mechanic.
- The product spec, visual spec, and active eight-boss execution record currently disagree
  in parts of boss defense presentation. The implementation should not proceed until one
  revised authority set resolves those conflicts.
