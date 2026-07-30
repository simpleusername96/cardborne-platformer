---
type: evidence
status: active
source: User-approved TO-BE component sheets
topic: Semantic V2 image-generation prompt record
scope: art/gameplay/semantic-v2/sources
related:
  - docs/design/component-sheets/semantic-rework-v2-proposal/13-visual-taxonomy-asis-tobe.png
  - docs/design/component-sheets/semantic-rework-v2-proposal/14-attack-telegraph-asis-tobe.png
  - docs/design/component-sheets/semantic-rework-v2-proposal/15-world-layering-asis-tobe.png
---

# Semantic V2 Source Prompt Record

## Purpose

Record the prompt set used to generate the preserved high-resolution chroma sources. This is provenance and regeneration evidence, not a runtime asset contract; runtime dimensions and pivots live in `asset-manifest.json`.

## Sources

- `13-visual-taxonomy-asis-tobe.png`: actor, secondary, field, status, and projectile identity.
- `14-attack-telegraph-asis-tobe.png`: attack lifecycle, boss objective, and minimap grammar.
- `15-world-layering-asis-tobe.png`: floor, raised wall, and functional-terrain grammar.
- Direct user approval of the TO-BE direction and the requirement to limit identities per generated image.

No external visual theme or unapproved ceramic, oceanic, or ritual motif was used.

## Findings

### Shared production prompt

Every static source used this base contract:

> Orthographic top-down 2D game asset for a general science-fiction vehicle shooter. Clean hard-surface vector/raster hybrid; flat controlled colors; dark graphite structure; clear near-black outline; restrained highlights; no pixel-art constraint. Directional assets face +X/right. Isolate each asset on an exact solid chroma background, with wide gaps and no overlap. No text, labels, grid, UI panel, scene background, cast shadow, decorative symbol, ceramic motif, ocean motif, or ritual motif. Preserve the approved Cardborne TO-BE role palette and make identities differ by silhouette, internal pattern, and topology rather than color alone.

Static sources contain no more than three semantic identities. Single bosses use one image each. Animation sources contain one named effect; multiple frames are a single evolving identity.

### Player, weapons, and support

- `player-weapons/01-player-hull.png` — one mustard player hull with rear engine socket and central aim hardpoint.
- `player-weapons/02-player-modules.png` — rear engine housing; rotating aim mount.
- `player-weapons/03-secondary-guidance.png` — seeker missile; escort drone.
- `player-weapons/04-secondary-area-control.png` — crescent orbit blade; four-arm wake mine.
- `player-weapons/05-player-defense.png` — segmented barrier plate; angular ion-field emitter.
- `player-weapons/06-support-sources.png` — generator shield anchor; shield-escort plate source; repair-pad core. Magenta chroma preserves mint.
- `player-weapons/07-projectiles-player.png` — primary shot; opening-breach shot; seeker projectile.
- `player-weapons/08-projectiles-hostile-a.png` — kinetic silver spear; thermal orange chevron; toxin olive bead-chain arrow.

### Ordinary enemies and pickups

- `enemies-pickups/01-enemy-swarm.png` — scrap drone; needle drone; spark minelet.
- `enemies-pickups/02-enemy-melee.png` — chaser; rammer; bulkhead guard.
- `enemies-pickups/03-enemy-ranged.png` — shooter; turret; artillery spotter.
- `enemies-pickups/04-enemy-support.png` — controller; generator; shield escort.
- `enemies-pickups/05-enemy-utility.png` — repair tender; drone carrier; splitter barge.
- `enemies-pickups/06-enemy-special.png` — interceptor tower; beam sentinel; boss pylon.
- `enemies-pickups/07-pickup-experience.png` — small, medium, and large experience objects.
- `enemies-pickups/08-pickup-utilities.png` — reward crate; repair pickup; experience-recall beacon.

### Bosses and primary world sources

- `bosses-world/01-boss-colossus.png` — single frontal armor wedge with rear forge-plate topology.
- `bosses-world/02-boss-leviathan.png` — single long segmented machine with a wake-fan rear silhouette.
- `bosses-world/03-boss-titan.png` — single broad machine with symmetric relay sockets.
- `bosses-world/04-boss-behemoth.png` — single armored convoy-like machine with armor-car topology.
- `bosses-world/05-boss-crown.png` — single radial command fortress with outer lattice sockets.
- `bosses-world/06-world-floor-tile.png` — one simple functional industrial slab without decorative decals.
- `bosses-world/07-world-wall-modules.png` — straight raised wall; convex corner; end cap.
- `bosses-world/08-world-functional-terrain.png` — repair pad; overdrive lane; arc-surge strip.

### Combat additions and boss modules

- `combat-additions/01-projectiles-hostile-b.png` — cryo faceted arrow; arc forked bolt; hybrid outlined spear.
- `combat-additions/02-status-vfx.png` — burn broken triangle; poison bead chain; chill split bars. Magenta chroma preserves green/cyan.
- `combat-additions/03-dash-start.png` — one three-frame cyan directional shell; no red circle.
- `combat-additions/04-bulkhead-destroy.png` — one five-frame intact-to-passable bulkhead sequence.
- `combat-additions/05-boss-module-colossus.png` — forge plate active; forge plate disabled/open.
- `combat-additions/06-boss-module-leviathan.png` — segment lock active; segment lock disabled/open.
- `combat-additions/07-boss-module-titan.png` — positive relay; negative relay.
- `combat-additions/08-boss-module-behemoth-crown.png` — armor-car module; crown lattice; crown pylon.

### One-effect animation sources

- `effects/01-muzzle-player-primary.png` — four-frame directional ignition, expansion, peak, fade.
- `effects/02-impact-reflect.png` — five-frame centered contact and outward shard burst.
- `effects/03-emp-release.png` — six-frame centered segmented shock ring in a 3×2 sequence.
- `effects/04-wake-mine-detonation.png` — five-frame four-lobed mine break and outward fade.
- `effects/05-boss-module-disabled.png` — four-frame crack, open, shard burst, fade.
- `effects/06-hostile-summon-arrival.png` — six-frame bracket, wireframe, assembly, complete sequence.

### HUD and world-state sources

- `ui-world-additions/01-minimap-units.png` — player; hostile; elite markers.
- `ui-world-additions/02-minimap-objectives.png` — boss; active objective; locked objective.
- `ui-world-additions/03-action-glyphs-a.png` — primary; seeker; dash.
- `ui-world-additions/04-action-glyphs-b.png` — EMP; barrier; ion field.
- `ui-world-additions/05-upgrade-glyphs-a.png` — primary; passive; secondary.
- `ui-world-additions/06-upgrade-glyphs-b.png` — defense; dash; skill.
- `ui-world-additions/07-upgrade-glyphs-c.png` — element; mobility; support.
- `ui-world-additions/08-world-state-modules.png` — transit gate; intact bulkhead; damaged bulkhead.

### Structural additions

- `world-structural-additions/01-world-wall-junctions.png` — concave corner; T-junction; cross junction.
- `world-structural-additions/02-world-functional-obstacles.png` — solid cover; breakable cover; hazardous power relay.

### Source preservation

- Generated images were copied into `sources/` and the original generator outputs were not deleted.
- Chroma removal was applied only to exported runtime assets. The exact chroma sources remain intact for future recropping.
- Ordinary sources were normalized to 1024×1024. Effect sources retain the generator's higher 1254×1254 output because their frame export already records explicit cells and pivots.

## Recommendations

- Regenerate one source at a time when identity changes; do not add identities to an existing three-item sheet.
- For a boss redesign, keep one boss per image and keep detachable objective modules in a separate source.
- Do not regenerate live beam, charge, area, or persistent-zone footprints as painted frames. Their geometry must remain simulation-driven.
