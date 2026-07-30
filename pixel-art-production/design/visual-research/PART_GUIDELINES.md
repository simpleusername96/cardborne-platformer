---
type: spec
status: active
created: 2026-07-26
last_reviewed: 2026-07-30
canonical_for: Existing Cardborne pixel world, UI chrome, and legacy combat-atlas maintenance
topic: Pixel space-hangar visual production
scope: Pixel production rules for the existing world and UI; legacy combat sections are compatibility records and cannot direct new component design
source: ./reference-manifest.json
related:
  - ../../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../README.md
  - ../../../docs/product/vehicle_game_spec.md
  - ./mvp/round-1/mvp-round-1-comparison.png
  - ./mvp/round-2/source/mvp-e-refined-readability.png
  - ./mvp/round-2/source/mvp-f-refined-hangar-identity.png
---

# Pixel Space-Hangar Part Guidelines

## Purpose

Define the approved simple, familiar, and production-feasible pixel-art grammar
for Cardborne's existing top-down space-hangar world and image-backed UI. This
guide owns native pixel shapes, semantic parts, atlas production, and authoring
review only inside that boundary. The active
[`UI_VISUAL_SYSTEM.md`](../../../docs/design/UI_VISUAL_SYSTEM.md) remains the
sole runtime-presentation authority and owns layout, live state, localization,
and semantic visual hierarchy.

The shipped combat atlas remains documented below only for reproducibility and
maintenance until migration. It is not a visual reference: do not create new
player, enemy, boss, pickup, projectile, effect, or upgrade-glyph art from its
pixel grid, silhouettes, prompts, or named source assets. New combat components
follow `UI_VISUAL_SYSTEM.md` and the active combat-rework ExecPlan.

The guide converts the reference study and MVP failures into part-level
constraints. It favors first-clear gameplay information over novelty,
decoration, realism, or dense science-fiction detail.

## Scope

This guide covers:

- top-down floor, void, blockers, facilities, props, and restrained UI
  ornament;
- native logical size, silhouette, palette ownership, state treatment, and
  validation for each visual family;
- ImageGen draft boundaries and the deterministic cleanup path into semantic
  layers and atlases.

Existing combat-family sections cover compatibility validation only. They do
not authorize visual iteration or expansion.

This guide does not change gameplay geometry, collision, navigation, spawn
legality, attack timing, localization, accessibility, batching, or any live
Godot UI behavior.

### Candidate baseline

Round-2 MVP E is the current **research candidate** because its single quiet
deck plane, consistent perimeter, and large actor shapes preserve the clearest
play hierarchy. It is not approved production art: its gradients, soft shadows,
and generated finish still require part-by-part pixel reconstruction.

Round-2 MVP F is not a production baseline. Its multiple dark floor bays add
hangar identity, but they can be mistaken for pits, cover, or different
collision zones. Hangar identity SHOULD instead come from the perimeter,
stateful facilities, and a few sparse props while the walkable deck remains one
continuous value family.

## Requirements

### Readability hierarchy

- The candidate scene MUST read in this order: walkable deck, void and solid
  blockers, player, hostile actors and attacks, rewards/support, then
  atmosphere.
- The void MUST be the darkest near-black mass. Walkable deck MUST be visibly
  lighter deep gray. Every impassable wall and internal blocker MUST use one
  consistent lighter-gray top and dark contact-edge grammar.
- The player MUST retain mustard ownership, ordinary enemies MUST retain coral
  ownership, bosses MUST retain magenta ownership, and repair/support MUST
  retain mint ownership unless the active visual specification is explicitly
  replaced.
- Ownership MUST remain readable from silhouette and motion when color is
  removed. Glow, gradient, opacity, or saturation MUST NOT be the sole
  ownership cue.
- Functional shapes MUST remain readable at native scale and under the game's
  supported maximum combat pressure. Decorative identity is secondary.
- Large contiguous pixel regions SHOULD carry primary meaning. One-pixel
  accents MAY support a shape but MUST NOT be the only role, direction, or state
  cue.

### Camera and material grammar

- World art MUST use a true 90-degree top-down camera grammar.
- Walls MAY use a one- or two-pixel contact edge to distinguish their footprint,
  but MUST NOT use side-view platform faces, long cast shadows, or perspective
  depth that implies false collision.
- Base art MUST use flat palette colors with nearest-neighbor sampling. It MUST
  NOT use gradients, antialiasing, dithering, bloom baked into sprites, texture
  speckles, scratches, stains, dense panel lines, or micro-panel overload.
- A short runtime effect MAY use a restrained halo or alpha change for timing,
  but the underlying shape MUST remain understandable with that effect removed.
- Outlines MUST NOT surround every object. A local dark separation pixel MAY be
  used only where two adjacent semantic parts would otherwise merge.
- Decoration MUST NOT resemble a blocker, opening, pickup, projectile, hazard,
  telegraph, target marker, or usable facility.

### Production-unit boundary

- Image generation MUST produce one asset or one deliberately related animation
  frame at a time. Production MUST NOT use an AI-generated sheet of unrelated
  assets.
- A whole-scene MVP MAY test composition and ownership, but it MUST NOT be
  snapped into a production `64 x 64` scene. The first-round comparison proved
  that whole-scene snapping erases actor and prop identity.
- Each generated draft MUST use the exact logical-grid guide for its declared
  family, then pass deterministic palette mapping, semantic masking, layer
  extraction, exact reassembly, and atlas packing from the active
  [pixel-art pipeline](../../README.md).
- Every visible source pixel MUST belong to exactly one semantic part.
- Direction and animation variations SHOULD edit an approved base frame instead
  of regenerating the complete object.
- Production art MUST use an approved limited palette. Each individual frame
  SHOULD use the smallest useful subset rather than all available colors.

### Gameplay and runtime boundaries

- Visual geometry MUST NOT become collision truth. Floor polygons, blockers,
  navigation, line of sight, attack footprints, pickup areas, and spawn
  legality remain gameplay-owned.
- Visible openings MUST agree with traversable openings, and visible blockers
  MUST agree with the authoritative collision footprint.
- Exact telegraph borders, progress arcs, cooldowns, focus, selection,
  localized text, and changing values MUST remain live geometry or live UI.
- Raster integration MUST preserve the current retained batching strategy. It
  MUST NOT introduce one scene node, draw call, or independent update loop per
  actor, projectile, shard, marker, or effect.
- Raster art MUST NOT contain Korean or English text, key bindings, numbers,
  percentages, cooldown values, health values, or other live data.
- Every asset MUST declare a stable pivot and any required muzzle, nozzle,
  orbit, status, or impact anchors in logical-pixel coordinates.

## Floor And Void

- **Role / use:** The floor establishes the safe, traversable hangar deck; void
  establishes non-traversable outer space or deep structural recess.
- **Avoid:** MUST NOT use decorative paths, arrows, cracks, circuitry, stains,
  stars, or repeated panel motifs. Floor variation MUST NOT look like cover,
  damage, a pickup, a facility, or a telegraph.
- **Logical native size:** `24 x 24` base tiles; a sparse floor break MAY use an
  authored `2 x 2` tile module.
- **Silhouette / shape:** Floor MUST form broad uninterrupted planes. Void MUST
  form one quiet continuous mass. Floor-to-void edges MUST have all required
  straight, inner-corner, outer-corner, and cap connections.
- **Palette / ownership:** Void MUST use the darkest value. Floor MUST use at
  most three neighboring gray values and remain less contrast-heavy than actors
  or attacks.
- **Animation / state:** Floor SHOULD be static. Any void motion MUST be
  slow, sparse, and limited to an edge band; it MUST NOT animate the full play
  surface.
- **Validation:** Repeat every tile in a `3 x 3` proof, test every neighbor
  combination, inspect at native scale and grayscale, and confirm that no floor
  mark is mistaken for collision or a gameplay object.

## Walls, Blockers, And Doors

- **Role / use:** This family communicates every impassable boundary, internal
  cover piece, breakable bulkhead, and genuine traversable opening. A transit
  gate is a facility, not a decorative door.
- **Avoid:** MUST NOT mix wall colors by stage or prop type, draw side-view
  platforms, create fake open seams, use long shadows, or add decorative doors
  that imply unavailable travel. This guide does not add a stage gate or boss
  room.
- **Logical native size:** `24 x 24` connected wall tiles; `48 x 48` breakable
  bulkheads and transit-gate fixtures.
- **Silhouette / shape:** Static wall tops MUST share one thickness and one
  contact-edge language. A breakable bulkhead MUST use the same outer contour
  plus one large fracture. A traversable opening MUST be at least as visually
  wide as its authoritative clearance.
- **Palette / ownership:** All solid cover MUST use the same blocker palette.
  Breakability or activation MUST use a large fracture, open center, or moving
  part rather than a new wall color.
- **Animation / state:** Connected walls remain static. Bulkheads use `intact`,
  `cracked`, `breach_armed`, and `destroyed`; gates use `ready`, `dwelling`, and
  `cooldown`. Destroyed/open frames MUST expose the actual traversable gap.
- **Validation:** Test all 16 orthogonal neighbor combinations, `3 x 3` seams,
  both actor radii, projectile blocking, line of sight, minimap agreement, and
  open/closed state agreement with collision.

## Props And Terrain

- **Role / use:** Props provide sparse hangar identity; functional terrain
  includes Arc Surge, breakable bulkheads, transit gates, repair and overdrive
  fixtures, and reward crates.
- **Avoid:** MUST NOT use incidental barrels, cables, vents, consoles, floor
  decals, or debris unless they serve a declared gameplay or composition role.
  Props and functional footprints MUST NOT overlap one another or block a legal
  lane accidentally.
- **Logical native size:** Reward crate `32 x 32`; Arc Surge segment, bulkhead,
  and transit fixture `48 x 48`; repair and overdrive fixtures up to `64 x 64`.
- **Silhouette / shape:** Each function MUST use one large familiar cue: mint
  plus for repair, stacked mustard chevrons for overdrive, violet conductor
  zigzag for Arc Surge, open paired center for transit, fracture for bulkhead,
  and latched box for a crate.
- **Palette / ownership:** Static shell colors MUST stay subordinate to actors.
  Support uses mint, overdrive/reward uses mustard, and danger uses its active
  affinity. A crate MUST NOT reveal its exact contents while closed.
- **Animation / state:** Facilities MAY animate only their large state-bearing
  part. Radius, lifetime, exact hazard area, and countdown remain procedural.
  Crates use `intact`, `damaged`, `opening`, and `opened`.
- **Validation:** Check shape recognition without color, exact footprint
  reservation, non-overlap, clear traversable gaps, facility timer pairing, and
  differentiation from pickups and ordinary cover.

## Legacy Pixel Player Craft — Compatibility Only

- **Role / use:** The craft is the persistent visual anchor for movement,
  facing, manual aim, damage, armor, engines, weapon state, and dash.
- **Avoid:** MUST NOT use a generic enemy contour, ambiguous front/rear, human
  limbs, dense mechanical paneling, outlines around every part, or shadows that
  enlarge the apparent hit area.
- **Logical native size:** `64 x 64`, with 16 directional frames where required.
- **Silhouette / shape:** The chassis MUST have one unmistakable nose, broad
  paired wings, and a clear rear engine line. Chassis, left/right wings,
  cockpit, armor, primary mount, engine modules, and flame MUST remain separate
  semantic layers with stable anchors.
- **Palette / ownership:** The outer ownership mass MUST remain mustard. Hull and
  primary-power upgrades MAY use controlled darker tiers. Cockpit and recess
  colors MUST not make the craft read as hostile.
- **Animation / state:** Movement SHOULD use stable translation plus restrained
  engine-flame frames, not body deformation. Recoil, opening-shot readiness,
  muzzle flash, hit tint, invulnerability, engine modules, and dash effects
  remain separable from the chassis.
- **Validation:** At native scale, verify front/rear recognition in all 16
  directions, stable pivot/muzzle/nozzles, exact semantic reassembly, player
  recognition in grayscale, and visibility under maximum enemy pressure.

## Legacy Pixel Mobile Enemies — Compatibility Only

- **Role / use:** Mobile enemies expose current role, movement intent, attack
  preparation, and ownership before fine detail.
- **Avoid:** Different tactical roles MUST NOT share the same outer contour.
  Enemies MUST NOT resemble the player, pickups, turrets, or harmless props, and
  MUST NOT depend on tiny weapon icons for role recognition.
- **Logical native size:** Common mobile enemy `32 x 32`; eight directions for
  asymmetric actors. Symmetric swarm units MAY be directionless.
- **Silhouette / shape:** Every archetype MUST have one dominant readable
  feature such as a needle nose, ram wedge, shield crescent, carrier bay, split
  body, or repair arm. Body, role accent, tool/weapon, and mobility part MUST be
  separable.
- **Palette / ownership:** The outer hostile mass MUST remain coral or its
  approved danger value. Role accents MAY use a restrained secondary color but
  MUST NOT erase hostile ownership.
- **Animation / state:** Use `move`, `attack_startup`, `attack_active`,
  `recover`, and `destroyed` only where the state is visible in play. Idle
  micro-animation SHOULD be omitted. Startup MUST emphasize the real attacking
  part.
- **Validation:** Compare all current archetypes as black silhouettes, at native
  scale, in small groups, and during startup. Confirm each role remains
  distinguishable without names, permanent paths, or color.

## Legacy Pixel Stationary Enemies And Bosses — Compatibility Only

- **Role / use:** Stationary enemies establish fixed target priority; bosses
  communicate phase, attack preparation, module ownership, and exceptional
  threat at field scale.
- **Avoid:** MUST NOT make a turret from a mobile enemy with a small base, make a
  boss only by enlarging a common enemy, or bake exact attack ranges and paths
  into actor sprites. Boss detail MUST NOT become unreadable texture.
- **Logical native size:** Stationary enemy `48 x 48`; boss `96 x 96`. Only
  rotating heads need directional frames; boss and turret heads use up to eight.
- **Silhouette / shape:** A stationary enemy MUST have a planted base and a
  distinct head/tool. A boss MUST have a large central mass plus separately
  readable armor, weapons, and phase core. Its front and active weapon MUST be
  recognizable at a glance.
- **Palette / ownership:** Stationary threats retain coral ownership. Boss body,
  warning ownership, core, and health retain magenta, while a specific attack
  MAY use its affinity shape and color.
- **Animation / state:** Stationary roles use `idle`, `startup`, `active`,
  `recover`, and `destroyed`. Bosses add `read`, `phase_transition`, and visible
  module damage. Autonomous attacks remain visually independent of the boss
  body.
- **Validation:** Test silhouette uniqueness, planted versus mobile reading,
  boss recognition at partial off-screen positions, startup readability,
  separate module anchors, and agreement between visible preparation and the
  gameplay-owned attack contract.

## Legacy Pixel Player Projectiles — Compatibility Only

- **Role / use:** Player projectiles communicate friendly ownership, direction,
  physical ammunition, ordinary fire, and the distinct opening Breach Shot.
- **Avoid:** MUST NOT draw a centered upgrade, pierce, poison, ricochet, or
  status icon inside a bullet. MUST NOT recolor every modifier combination,
  bake glow into the head, or imply a smaller safe collision area than the real
  projectile.
- **Logical native size:** `32 x 32`; eight directions; two flight frames for
  ordinary and opening-shot ammunition.
- **Silhouette / shape:** Each projectile MUST have a leading edge, connected
  body/core, rear wake anchor, and stable direction. The opening shot MUST add a
  large breach collar or mass change rather than a tiny badge.
- **Palette / ownership:** The head MUST use a mustard ownership shell with a
  dark cobalt core. Modifier information SHOULD use edge motion, wake behavior,
  impact, and live status rather than changing the ownership shell.
- **Animation / state:** Use two restrained flight frames plus separate
  wall/enemy/Breach-interrupt impacts. Modifier overlays MUST be composable and
  MUST NOT multiply every upgrade combination into unique atlas frames.
- **Validation:** Compare rendered head extent to collision, verify leading and
  rear anchors in all directions, test against floor/wall/enemy colors, and
  confirm ordinary versus Breach recognition without HUD text.

## Legacy Pixel Hostile Projectiles — Compatibility Only

- **Role / use:** Hostile shots communicate danger ownership, travel direction,
  damage weight, and affinity early enough to dodge.
- **Avoid:** MUST NOT use literal fire, poison, ice, or lightning icons inside
  ordinary bullets. MUST NOT rely on glow, color alone, or a trail wider than
  the damaging head. MUST NOT disappear against floor, wall, void, player, or
  telegraph colors.
- **Logical native size:** `32 x 32`; directionless two-frame pulses for light
  and standard shots and a three-frame pulse for heavy shots.
- **Silhouette / shape:** Collision and visible head radii MUST match: five
  pixels for light, six for standard, and seven for heavy. Affinity shape MUST
  be disk for kinetic, ember for thermal, drop for toxin, shard for cryo, bolt
  for arc, and split diamond for hybrid. The trail is non-damaging.
- **Palette / ownership:** The head uses affinity color plus the approved hostile
  danger relationship. Damage weight MUST also change size, not merely
  saturation. Hybrid uses a bright split shape, not a white glow.
- **Animation / state:** Affinity variation SHOULD animate the edge or wake of a
  complete head. Impacts remain separate clips. Projectile startup and exact
  corridor remain gameplay-owned telegraphs.
- **Validation:** Test all weights and affinities at native scale over every
  world value, in grayscale, and in dense groups. Confirm head/collision
  equality, wall termination, readable direction, and no confusion with player
  fire or pickups.

## Legacy Pixel Secondary Weapons — Compatibility Only

- **Role / use:** Automatic secondaries provide five immediately distinct
  behaviors: seeker missile, ion field, orbit blades, wake mines, and escort
  drone.
- **Avoid:** MUST NOT force all five into one bullet silhouette, use color depth
  when count or radius already exposes an upgrade, or make a friendly mine/drone
  resemble a hostile stationary enemy.
- **Logical native size:** Seeker, ion emitter, wake mine, escort drone, and
  drone shot `32 x 32`; orbit blade `24 x 24`.
- **Silhouette / shape:** Seeker is a finned missile; ion is a central emitter
  plus live ring; blades are slim orbiting crescents; mines are planted shapes
  with a clear fuse; drone has a compact following body and separate weapon.
- **Palette / ownership:** Seeker and drone MUST retain a friendly ownership
  part. Ion uses mint, orbit blades use mustard, and wake mines use a
  shape-distinct armed core. Count-readable upgrades MUST NOT receive redundant
  shade tiers.
- **Animation / state:** Seeker uses two flight frames; ion uses a procedural
  damage ring; blades use runtime orbit; mines use `idle`, `armed`, and
  `detonating`; drone uses `follow`, `fire`, and `recover`.
- **Validation:** Identify all five from black silhouettes and one native-scale
  gameplay capture. Verify orbit/radius/explosion truth remains procedural,
  friendly ownership survives grayscale, and simultaneous secondaries remain
  readable without extra HUD labels.

## Legacy Pixel Pickups — Compatibility Only

- **Role / use:** Pickups communicate collectible experience, hull repair, and
  whole-field experience recall. No other field-item behavior is implied.
- **Avoid:** MUST NOT make pickups look like projectiles, enemy cores, floor
  decoration, support fields, or closed crate contents. MUST NOT depend on
  particle sparkle to be locatable.
- **Logical native size:** Experience shard `16 x 16`; repair and recall pickup
  `24 x 24`.
- **Silhouette / shape:** Experience uses one shard family with three
  value-scaled shells. Repair uses a container plus large plus. Recall uses a
  container plus inward-gathering or concentric shape distinct from repair.
- **Palette / ownership:** Experience/reward uses mustard; repair/support uses
  mint; recall MAY combine mint and ivory while retaining its unique shape.
- **Animation / state:** Idle motion MUST be restrained and bounded. Recall
  travel remains a gameplay-owned movement path that retargets the player; a
  collected frame is optional and must be brief.
- **Validation:** Test recognition on all world surfaces, separation from every
  projectile class, three experience value tiers, minimap-marker pairing, and
  visibility without animation.

## Legacy Pixel VFX And Telegraphs — Compatibility Only

- **Role / use:** VFX confirm contact and state change; telegraphs show exact
  hostile startup, damage footprint, readiness, and active duration.
- **Avoid:** MUST NOT use permanent enemy trajectory overlays, moving warned
  geometry, thick rails that dominate the field, full-screen particles, or
  decorative warning shapes larger or smaller than damage truth. MUST NOT use
  gradients or glow as the only timing cue.
- **Logical native size:** Telegraph fill/boundary tile `24 x 24` positioned
  procedurally; impact frames `32 x 32`; player dash effect `64 x 64`.
- **Silhouette / shape:** Telegraphs use exact corridor, area, fan, cross, beam,
  charge, pylon, or summon geometry. Affinity MAY add one large interior rhythm
  without changing the boundary. Impacts use contact, expansion, fragments, and
  fade.
- **Palette / ownership:** Startup uses a pale restrained affinity tint and
  strengthens monotonically toward impact through live tint/opacity. The exact
  outer boundary remains visible. Friendly dash and impacts retain player
  ownership.
- **Animation / state:** Warning position and geometry MUST freeze on the first
  visible frame. Readiness MAY change continuously; damage geometry MUST NOT
  chase the player. Active persistent areas retain their boundary for the full
  damaging window.
- **Validation:** Overlay rendered geometry on authoritative collision, inspect
  off-screen-owner cases, wall clipping, rounded corridor caps, area falloff,
  reduced-motion treatment, and maximum-pressure visibility.

## HUD Ornament And UI Frames

- **Role / use:** Raster pixels provide small glyphs, minimap markers, guidebook
  previews, upgrade icons, and restrained scalable corners/edges around live
  controls.
- **Avoid:** MUST NOT rasterize Korean/English text, bindings, numbers,
  percentages, progress, focus, selection, cooldowns, or live values. MUST NOT
  use thick cockpit frames, dense circuitry, noisy panel borders, decorative
  grids, repeated bolts, scan lines, glows, or nested bordered panels.
- **Logical native size:** Minimap marker `16 x 16`; HUD/action/upgrade glyph and
  scalable corner/edge unit `24 x 24`; guidebook preview `64 x 64`.
- **Silhouette / shape:** Glyphs MUST use one familiar outer shape and one
  dominant action cue. Frames MUST use a minimal corner/edge system that scales
  without stretching pixels. Routine controls MUST remain standard live
  controls.
- **Palette / ownership:** UI ornament SHOULD use quiet neutral structure and
  reserve semantic colors for state. Text contrast, focus, selected, disabled,
  and danger states remain theme-owned, not baked into a bitmap.
- **Animation / state:** Cooldown fills, radial timers, focus, selection, hover,
  disabled, and reduced-motion states remain live. A raster glyph MAY have
  static variants only when its silhouette itself changes.
- **Validation:** Review Korean and English at `960 x 540`, `1280 x 720`, and
  `1920 x 1080`; verify nearest filtering, no clipping or overflow, stable
  focus/selection, scalable frame seams, and no rasterized live content.

## Acceptance Criteria

Actor, projectile, pickup, and effect checks below apply only when confirming
that the currently shipped compatibility atlas still reproduces its existing
runtime contract. They are not acceptance criteria for new combat components.

- [ ] Every production family uses the native logical size and target mode in
      `assets/asset-inventory.json`.
- [ ] Every approved raster frame is authored or generated as one asset or one
      related frame, never as a full unrelated sheet or snapped whole scene.
- [ ] Every raster frame uses flat approved palette colors with no antialiasing,
      dithering, gradients, texture noise, or baked glow.
- [ ] Every visible pixel has one semantic owner, every required semantic layer
      is populated, and exact reassembly changes zero pixels.
- [ ] Walkable deck, void, blockers, player, ordinary danger, boss danger,
      support, pickups, and telegraphs remain distinguishable at native scale
      and in grayscale.
- [ ] Player and enemy contours are distinct; each tactical enemy role and each
      secondary family has one recognizable outer shape.
- [ ] Visible openings, blocker edges, projectile heads, and telegraph
      boundaries agree with gameplay-owned geometry.
- [ ] Connected tiles pass all adjacency and `3 x 3` seam proofs.
- [ ] Pivots and muzzle, nozzle, orbit, status, and impact anchors remain stable
      across direction and animation frames.
- [ ] Raster integration preserves retained batching and introduces no
      per-actor, per-projectile, per-shard, or per-marker node ownership.
- [ ] Korean/English text, live values, cooldowns, focus, selection, minimap
      position, and accessibility remain live.
- [ ] Gameplay-scale review passes at supported viewports and maximum supported
      combat pressure before any family is declared migrated.

## Part-Review Checklist

For each proposed asset or frame:

- [ ] Can a first-time player name its broad role from shape at native scale?
- [ ] Is its front, danger edge, usable side, or blocked side unambiguous?
- [ ] Does it remain distinct in grayscale and over every permitted background?
- [ ] Does it use only the approved palette subset and flat whole pixels?
- [ ] Is every primary cue large and contiguous rather than a micro-detail?
- [ ] Does it avoid false collision, false pickup, false hazard, and false
      interaction cues?
- [ ] Are pivot, semantic layers, and gameplay anchors declared and stable?
- [ ] Does its state change match real gameplay state rather than decoration?
- [ ] Can it be batched within the existing renderer ownership?
- [ ] Does exact layer reassembly and any required seam proof pass?

## Non-Goals

- Realistic spacecraft materials, cinematic lighting, dense industrial panels,
  or an unprecedented visual language.
- A full-scene bitmap, hand-painted background, side-view platform tiles, or
  perspective/isometric wall art.
- Production-ready assets generated as one AI sheet or recovered by snapping a
  complete scene to `64 x 64`.
- Texture speckles, scratches, stains, micro-panels, decorative circuitry,
  universal outlines, gradients, dithering, or glow-led ownership.
- Literal upgrade, modifier, status, or affinity icons placed inside ordinary
  bullets.
- Decorations that resemble collision, openings, items, facilities, hazards,
  projectiles, or attack warnings.
- Player and enemy variants that share one contour and depend on recoloring.
- One node or draw path per actor, projectile, shard, marker, facility, or
  repeated effect.
- Rasterized localization, live combat values, focus, selection, cooldown,
  progress, or accessibility state.
- Runtime integration, active-spec replacement, or gameplay-rule changes in
  this research phase.
