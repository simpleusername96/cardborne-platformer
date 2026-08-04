# Production Visual Assets

This directory owns Cardborne's active authored gameplay rasters and code-native
UI foundation. The mandatory art-direction authority is the pair of
[`docs/design/VISUAL_SYSTEM.md`](../../../docs/design/VISUAL_SYSTEM.md) and
[`docs/design/cardborne-universal-art-style-reference.png`](../../../docs/design/cardborne-universal-art-style-reference.png).
Read the complete specification and inspect the sheet at original detail before
creating, reviewing, approving, or integrating production visuals. The sheet is
style reference only, never asset approval.

## Ownership

- `gameplay/asset-manifest.json` explicitly indexes the final 49 gameplay PNGs:
  player 1, ordinary enemies 19, bosses 5, shared boss-node states 3,
  secondaries 4, shared projectile 1, pickups/rewards 4, world/facilities 11,
  and EMP 1.
- All non-beam projectiles reuse `projectile/energy_teardrop`. Runtime owns
  rotation, scale, faction or affinity tint, collision, cadence, range, homing,
  and damage.
- Experience values reuse `pickup/experience_master`. Runtime owns value and
  scale emphasis.
- Boss objectives reuse `boss/node_active`, `boss/node_damaged`, and
  `boss/node_resolved`; gameplay retains module kind, index, health, and state.
- Repair and overdrive are complete circular authored pads. Gameplay owns their
  live radii, and presentation scales the pad to the live footprint.
- `effect/emp_release` is the only authored raster effect. Runtime owns its
  live-radius scale and short fade.
- HUD, minimap, combat cues, defense feedback, status feedback, telegraphs,
  beams, and live radius boundaries are code-native and have no manifest entry.
- `ui/` owns the shared code-native Theme, font, and font license. It contains
  no UI chrome PNG, UI image manifest, or UI image provider.
- Collision, navigation, damage, targeting, encounters, values, and state
  transitions remain in their existing gameplay owners.
- Gameplay floor and wall surfaces remain procedural and are not indexed as
  deferred raster alternatives.

Historical generation sources, review sheets, and prompts are not runtime
contracts. Recover obsolete sources from Git history when needed instead of
duplicating them in the shipping tree. External source files stay in the review
workbench with license, official URL, archive/file hashes, and adaptation scope;
only approved Cardborne-normalized outputs enter this directory.

## Format and import contract

- Do not automatically trim runtime PNG canvases; pivots depend on stable canvas
  geometry.
- Import PNGs with linear filtering, no mipmaps, and no repeat.
- Image geometry never owns collision, navigation, damage, value, or state truth.
- Change a gameplay asset ID or path only with its provider consumers and
  coverage validators in the same batch.
- Do not use production files as previews, prompt references, or unapproved
  TO-BE outputs.
- Do not accept a raster without evidence that the canonical sheet was supplied
  as an actual image reference and that the separate AS-IS/TO-BE approval
  contract passed.

## Validation

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_semantic_asset_provider.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_semantic_visual_separation.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_visual_asset_coverage.gd
```
