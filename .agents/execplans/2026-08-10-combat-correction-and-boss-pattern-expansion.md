---
type: plan
status: active
owner: BK
created: 2026-08-10
last_reviewed: 2026-08-10
topic: Remaining combat presentation, pressure, boss-pattern, Mystery Device, and release-qualification corrections
scope: Dash-stable presentation, truthful facing, distinct Drop Mine feedback, minimap scale, ordinary damage, diverse bounded boss maneuvers, Mystery Device readability, and final performance qualification
supersedes:
  - ../../docs/reports/2026-08-02-pre-asset-code-stabilization.md
  - ../../docs/reports/2026-08-08-combat-pressure-and-surface-depth.md
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/design/visual-replacement-workbench/candidates/boss-signature-pattern-concepts-v1/README.md
  - ../design/DESIGN.md
  - ../cardborne-performance-engineering-policy.md
  - ../cardborne-runtime-architecture-audit.md
---

# Combat Correction and Boss Pattern Expansion - Execution Contract

## Outcome

Finish only the unresolved work after the 2026-08-08 combat revision. Make attached
player visuals stable during dash, make enemy intent readable, give Drop Mine its own
detonation identity, correct minimap scale, raise ordinary-enemy outgoing damage by exactly
30 percent from the current value, replace collapsed boss autonomous attacks with five
stage-specific maneuvers, make Mystery Device outcomes legible, and then qualify the final
built workload.

The superseded plans remain under `docs/reports/` as historical evidence. Their completed
tasks are not repeated here. This file is the only active execution contract for this
outcome.

## Why and Current Evidence

- The earlier plan accumulated 42 completed and 17 unresolved tasks. Re-reading all of it
  obscures the remaining decisions and wastes active context.
- Drop Mine currently applies one `48/60/72` area hit at radius `96/108/120` after proximity
  or timeout, removes itself, and emits no origin receipt. Thermal Burst is a different
  system: an eligible player-primary direct hit adds only `4/6/8` elemental splash at
  radius `72/84/96`.
- Cryo exists. It does not spawn a separate ice-projectile body. Selecting Cryo tints the
  normal player-primary projectile blue and applies Chill stacks. Slow per stack is
  `6/8/10%`, duration is `2/2.5/3s`, and the cap is three stacks. The current same-size
  blue actor compositor presents the persistent state.
- Boss data declares distinct `area`, `lanes`, `beam`, and `summon` autonomous kinds, but
  the run owner currently routes every non-summon kind to the same circular denied zone.
  This implementation defect erases much of the authored variety.
- There is no engine-level reason Cardborne cannot use richer boss compositions. The former
  plan was intentionally limited to fixing the dispatcher and existing geometries; it did
  not include a complete genre-pattern design pass.
- External design evidence supports teachable patterns, committed warnings, reliable cover,
  vulnerability windows, and combinations of reusable maneuvers rather than unreadable
  density: [Dead Cells patch 19](https://deadcells.com/patchnotes/19),
  [Dead Cells patch 31](https://deadcells.com/patchnotes/31),
  [Hades Big Bad Update](https://www.supergiantgames.com/blog/hades-big-bad-update-patch-notes/),
  [Hades Long Winter Update](https://www.supergiantgames.com/blog/hades-long-winter-update-patch-notes/),
  [Psychonauts 2 modular boss maneuvers](https://www.gamedeveloper.com/marketing/using-a-modular-system-of-maneuvers-to-design-i-psychonauts-2-i-s-boss-fights-in-a-hurry),
  and [Returnal's action-roguelike bullet-hell production account](https://www.gamedeveloper.com/marketing/a-third-person-action-roguelike-bullet-hell-arcade-thriller-the-making-of-returnal).

## Scope

### In scope

- The unresolved presentation, minimap, ordinary-damage, boss, Mystery Device, and
  performance-qualification work listed below.
- Product and visual-contract amendments required before player-facing changes.
- One separately authored and approved Drop Mine detonation raster.
- Focused validators, production-style Web export, rendered evidence, and one final clean
  performance qualification after feature work stops changing.

### Out of scope

- Reopening the completed health curve, spawn scheduler, XP/HUD, upgrade copy, elemental
  combat values, surface detail, Thermal effect, boss shield, or beam-strip work.
- Making Drop Mine a Thermal weapon, adding a separate Cryo projectile asset, or allowing
  more than one active element.
- Raising boss damage, boss HP, ordinary HP, enemy counts, projectile capacity, effect
  capacity, or boss-add capacity in this pass.
- Copying platformer-only jump patterns, tiny-hitbox bullet curtains, live post-warning
  homing, unbounded survivor-style swarms, mandatory EMP checks, or terrain mutation.
- A fifth Mystery Device outcome or effects that harm or move the player.

## Locked Design Contracts

### Effect semantics

| Feature | Gameplay identity | Visual identity | Sharing rule |
| --- | --- | --- | --- |
| Thermal Burst | Player-primary elemental direct-hit modifier; `4/6/8` splash; `72/84/96` radius | Existing orange Thermal impact at the direct-hit point | Keep unchanged |
| Drop Mine | Optional stationary secondary; proximity/timeout trap; `48/60/72` damage; `96/108/120` radius | New `effect/drop_mine_detonation` raster and receipt at the mine origin | May share only the bounded effect-store infrastructure; do not share semantic ID, raster, batch, color language, or sound identity with Thermal |
| Cryo | Mutually exclusive player-primary affinity plus Chill condition | Existing blue primary tint and exact same-size translucent enemy-body compositor | Do not create an independent ice bullet or external halo |

The Drop Mine candidate is one transparent `256x256` authored PNG centered at
`[128,128]`. It uses a compact ivory impact core and restrained amber kinetic pressure or
shrapnel planes. It must not use Thermal orange flame, smoke, soft bloom, particle clutter,
a persistent range ring, or an animation atlas. Generate it through ImageGen with both the
canonical reference sheet and a current combat capture as actual image references. Promote
only an exact user-approved byte/hash through the visual workbench and production manifest.
Runtime scale `0.80/0.90/1.00` maps to exact gameplay radii `96/108/120`; lifetime is
`0.18s`. Reduced motion shows the final radius and fades. At most eight mine cosmetics may
be live inside the unchanged total effect capacity of 96; they may recycle only their own
cosmetic slots and never gameplay, EMP, or Thermal receipts.

### Boss-pattern architecture

Keep four direct and two autonomous slots per stage boss. Replace one generic autonomous
slot per boss with the following signature maneuver; do not add net slots. One fixed-cap
`VehicleBossRuntime` maneuver state owns a bounded step array. Every step is
`startup -> committed active -> recovery`; target position or bearing freezes at the end of
startup, and cover/collision truth stays authoritative.

The review-only left-to-right storyboards for this matrix are recorded in
`docs/design/visual-replacement-workbench/candidates/boss-signature-pattern-concepts-v1/`.
They explain timing and safe-space topology but do not approve generated pixels, actor
replacements, collision geometry, or VFX.

| Stage | Signature maneuver | Locked composition and cap |
| --- | --- | --- |
| 1 | Radial safe-gap burst | Two ten-direction waves, `0.45s` apart. Omit the two directions nearest the frozen player escape bearing in each wave and rotate wave two by `18 degrees`; at most 16 live boss projectiles. |
| 2 | Chained delayed zones | Three warned circles at the frozen player position and two velocity-lead samples capped at 96 units, `0.32s` apart; at most two active denied zones. Every warning must allow radius plus 40 units of base-walk escape. |
| 3 | Rotating fan chain | Three five-projectile committed fans, `0.32s` apart, rotating `30 degrees` per step; at most 15 live boss projectiles and no homing after warning. |
| 4 | Stepped beam sweep | Three independently warned static beam bearings at `-32/0/+32 degrees` around the frozen bearing; `0.24s` active each, never overlapping, at the existing `920` range and `72` width with cover clipping. |
| 5 | Crossed lane gates | Two sequential lane walls rotated `90 degrees`; each wall has one obvious gap and the second shifts the gap by one lane; use existing lane speed/damage and remain below the 24-projectile boss reservation. |

The remaining autonomous slot keeps one existing distinct kind for each boss. The runtime
must also make every declared `area`, `lanes`, `beam`, and `summon` kind execute its own
geometry. One autonomous maneuver may be active at a time. Preserve current per-contact
damage, boss health, shield, phase thresholds, exposure windows, global projectile cap 120,
boss reservation 24, effect cap 96, and boss-add cap 12. Difficulty comes from spatial
decisions and chained commitments, not hidden tracking or higher boss damage.

### Other gameplay and presentation contracts

- During the `0.20s` dash, the craft and every craft-attached directional cue use the
  frozen dash direction. Suppress craft-only positional recoil during dash. Orbiting
  secondaries, Electric Field truth, and deployed mines remain player/world centered.
- Each directional enemy publishes one effective facing vector. Use committed direction
  only during startup/active; otherwise face the player or active Decoy target. Controller
  spin and nondirectional mine/generator actors remain exceptions.
- Keep current minimap silhouettes. Set pickup to `12 x 7.6`, crate to `9 x 9` with its
  existing notch, and scale every Mystery Device outer point by `1.20`; pickup/crate
  perceived polygon areas must differ by no more than 10 percent.
- Set the ordinary global outgoing-damage multiplier from `1.35` to `1.755`, preserving the
  stage curve `[1.00,1.03,1.06,1.09,1.12]`. Resulting multipliers are
  `1.755/1.80765/1.8603/1.91295/1.9656`. Boss final damage bypass remains unchanged.
- Mystery Device keeps exactly three deterministic placements and four existing outcomes.
  First accepted hit reveals the assigned outcome; break triggers it. The result receipt
  reports affected count. Cryo uses the shared blue body compositor, Projectile Purge gets
  one short System pulse after the clear, Decoy becomes readable through enemy facing, and
  Gravity retains visible forced motion. The minimap never reveals the outcome.

## Milestones

### Phase 1 - Bind contracts and presentation corrections

- [ ] **1.1 Amend authoritative specifications.** Update
  `docs/product/vehicle_game_spec.md` and `docs/design/VISUAL_SYSTEM.md` with the effect
  distinction, Cryo truth, boss maneuver matrix, minimap hierarchy, Mystery lifecycle, and
  expected production raster count after approval. Reconcile the stale minimap-role text.
- [ ] **1.2 Author and approve the Drop Mine candidate.** Use the visual-authority
  workflow and required raster references. Record prompt, source hashes, output hash,
  original-size sheet, and the user's exact approval. Stop asset promotion if approval is
  absent; continue unrelated nonvisual code only.
- [ ] **1.3 Stabilize dash and enemy facing.** Change the player presentation snapshot and
  pooled enemy presentation records. Renderer consumes published truth and does not infer AI
  state.
- [ ] **1.4 Add the distinct Drop Mine receipt.** Return position/radius only after damage
  resolution, register `effect/drop_mine_detonation`, add a distinct existing-impact sound,
  enforce the mine subcap, and cover proximity, timeout, all levels, full store, and reduced
  motion.
- [ ] **1.5 Normalize minimap scale.** Change only the retained marker mesh data and add
  area-order assertions.
- [ ] **1.6 Close the presentation gate.** Run focused unit/source validators and capture
  dash, facing/Decoy, mine levels, reduced motion, minimap overlap, 1x, and grayscale states.

### Phase 2 - Pressure, boss maneuvers, and Mystery Device

- [ ] **2.1 Raise ordinary damage only.** Apply `1.755` at the shared ordinary incoming-
  damage boundary and prove boss/friendly/environmental/final-effective paths are unchanged.
- [ ] **2.2 Implement the bounded boss maneuver executor.** Fix the autonomous-kind
  dispatcher, add one allocation-stable step state, freeze targets after startup, and serialize
  steps under the existing capacities.
- [ ] **2.3 Implement the five signature maneuvers.** Replace one autonomous slot per boss
  with the locked matrix. Add deterministic seeds and boss-practice coverage for every step,
  phase, cover interaction, safe route, and cap boundary.
- [ ] **2.4 Make Mystery outcomes legible.** Implement reveal-on-first-hit, break activation,
  affected-count receipts, shared Cryo compositor input, post-clear purge pulse, and
  Decoy-facing integration without changing outcome mechanics.
- [ ] **2.5 Close the combat gate.** Validate exact damage math, all ten autonomous slots,
  five signatures, no immediate repeat, safe route at base movement, no live retargeting,
  Mystery zero/one/many targets, localization, reduced motion, and capacity invariants.

### Phase 3 - Final product and performance qualification

- [ ] **3.1 Build and inspect the final product.** Run the focused validator set, visual and
  document authority checks, Godot import validation, Web export, and production-style built
  start. Capture supported viewports in Korean and English under real combat pressure.
- [ ] **3.2 Collect one user-controlled manual hitch trace.** Start only after feature code
  and assets stop changing; preserve the trace as evidence rather than guessing a cause.
- [ ] **3.3 Run clean authoritative performance scenarios.** With user alignment on the
  expected runtime cost, run native `peak_horde` and `capacity`, then built-Web peak-horde.
  Reuse the canonical fastrun lane and record commit, hardware, renderer, thresholds, and raw
  artifacts.
- [ ] **3.4 Fix only a measured red owner.** If a release threshold fails, attribute it to
  simulation, presentation, loading, or environment before changing code. Preserve all locked
  gameplay/capacity contracts. Repeat only the affected focused scenario, then one final gate.
- [ ] **3.5 Close durable records.** Update product/visual/performance evidence, archive final
  reports, remove task-owned temporary helpers, mark every checkbox truthfully, and set this
  plan to `done` only when no required work remains.

## Test Plan

- Focused gameplay: secondary weapons, effect store, run difficulty, attack contract, boss
  patterns/runtime/practice/exams, Mystery Device, stage layouts, minimap, status, renderer,
  capture driver, localization, and main run validators under `tools/validation/`.
- Visual: original-size and 1x comparisons, alpha/extent checks, grayscale, reduced motion,
  Korean/English, overlapping minimap markers, all five bosses, and each mine level.
- Capacity: boss projectile reservation never exceeds 24; boss adds never exceed 12; total
  effects never exceed 96; mine cosmetics never exceed eight; no per-frame node/material or
  unbounded container growth.
- Product: Web export plus production-style start before handoff. Native and built-Web
  performance qualification occurs once against the final workload.

## Rollback and Safety

- Keep gameplay damage resolution independent from visual receipts. A missing or recycled mine
  cosmetic can never cancel or duplicate damage.
- Each feature lands in a coherent scoped commit. Revert the affected commit if a focused gate
  fails; do not reset unrelated user work.
- Do not promote an unapproved raster. The fallback is no new mine presentation, not a generated
  geometric stand-in or reuse of the Thermal asset.
- Do not change capacities or reduce authored workload to make a performance number pass.

## Risks and Stop Conditions

- If a signature maneuver has no base-movement escape in deterministic practice, preserve the
  evidence and adjust only warning, spacing, or step timing within its locked identity. Do not
  compensate with hidden invulnerability or lower global pressure.
- If the 30 percent ordinary-damage increase creates an evidenced unavoidable one-hit, stop for
  a user-owned balance decision; do not silently change HP, cadence, or a single enemy role.
- If the mine candidate is visually confused with Thermal, shields, or hostile danger, reject it
  and author a new candidate under the same semantic contract.
- If clean qualification remains red, do not claim a performance fix until a measured owner and
  before/after trace exist.

## Open Questions

- No gameplay or architecture decision is open. The exact Drop Mine candidate bytes require the
  user's visual approval before production promotion.

## Decision Notes

- 2026-08-10: Split unresolved work into this plan. Preserve both former active plans as
  superseded reports so completed history remains available without occupying the active contract.
- 2026-08-10: Drop Mine and Thermal Burst are different gameplay concepts. Share infrastructure,
  not art or semantic identity.
- 2026-08-10: Cryo remains a primary-projectile affinity plus Chill condition, not a separate
  projectile family.
- 2026-08-10: Boss variety is expanded with five bounded, stage-specific maneuver compositions.
  The limit is readability and runtime capacity, not genre precedent or Godot capability.

## Progress

- Current phase: Phase 1.
- Next task: 1.1 authoritative specification amendments, followed by the separate Drop Mine
  candidate approval lane.
- Last completed gate: prior combat feedback and timed-arrival work recorded in the superseded
  2026-08-08 report.
