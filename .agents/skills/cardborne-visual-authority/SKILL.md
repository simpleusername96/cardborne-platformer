---
name: cardborne-visual-authority
description: Enforce Cardborne's canonical visual authority pair before creating, editing, reviewing, approving, or integrating any player-facing visual. Use for every Cardborne asset, raster, sprite, vehicle, enemy, boss, projectile, pickup, world or facility image, UI, HUD, modal, minimap, glyph, theme, layout, VFX, telegraph, effect, mockup, screenshot, component or system sheet, ImageGen prompt or output, visual-replacement workbench candidate or preview, and any other art-direction task.
---

# Cardborne Visual Authority

Use one mandatory authority pair for every Cardborne visual task:

- Text contract: `docs/design/VISUAL_SYSTEM.md`
- Visual reference: `docs/design/cardborne-universal-art-style-reference.png`

Do not substitute a recovered sheet, generated preview, workbench artifact, runtime
capture, or older design document for either member of this pair.

## Verify the authority

Complete this preflight before analysis, prompting, editing, generation, review, or
approval:

1. Resolve both paths from the repository root and confirm both files exist. Stop
   and report the missing authority file if either is absent.
2. Compute the visual reference's SHA-256. Require this exact value:
   `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
   Stop on any mismatch. Do not silently accept a replacement, update the expected
   hash, or fall back to another copy.
3. Compute and record the current `VISUAL_SYSTEM.md` SHA-256, then read the document
   completely in its current form. Do not rely on a summary, excerpt, prior-session
   memory, or the reference sheet's labels for a new root task.
4. Visually inspect the reference PNG at original or sufficient detail with an
   image-viewing tool. Reading metadata, OCR, filenames, or alt text is not visual
   inspection.
5. Extract the task-specific constraints from both sources before doing the visual
   work.

## Reuse one root-task receipt

The authority-pair preflight is required once per root task before its first material
visual action, not once per turn, candidate, validator, generation, or review step.
After the preflight, keep one task receipt in the task's existing plan/evidence owner
or active context. It must contain both canonical paths, the expected and observed
sheet hash, the observed `VISUAL_SYSTEM.md` hash, confirmation of the complete read
and visual inspection, and the extracted constraints relevant to the task.

Reuse the receipt only while all of these remain true:

- the work remains in the same root task;
- both current file hashes match the receipt;
- the visual scope does not require a constraint omitted from the receipt;
- the receipt and extracted constraints remain available after any handoff or
  compaction.

Rechecking the two hashes is sufficient to establish that the authority files did
not change; do not reread the complete document or reopen the full reference merely
for reassurance. Start a fresh preflight for a new root thread, a hash change, a
material scope expansion, or a receipt that no longer carries the needed constraints.
Do not create a child agent solely to repeat the preflight. A child that genuinely
makes an independent visual judgment must inspect the visual evidence it judges, but
may reuse the root task's unchanged document/hash receipt and extracted constraints.

This reuse rule does not weaken the raster/ImageGen input rule below: every creation
or edit call must still receive the canonical repository PNG as an actual image
reference.

The reference's recorded provenance is:

- Original Codex image-generation artifact:
  `C:/Users/BK/.codex/generated_images/019fbfe9-857e-7453-b72d-20908d848577/exec-0b8aa606-cf55-45c1-abb3-fb3df762b080.png`
- Original artifact timestamp: `2026-08-02 12:13:44 KST`
- Canonical repository copy: the visual-reference path above, preserved
  byte-for-byte under the required SHA-256
- Authority status: user-confirmed universal Cardborne style reference; explicitly
  not an approval of any depicted asset

Treat the external original path as provenance only. The repository copy is the
required working reference. `VISUAL_SYSTEM.md` is intentionally not hash-pinned so
the active specification can evolve; always read the full current file.

## Interpret the pair

Let `VISUAL_SYSTEM.md` govern semantic roles, gameplay readability, media ownership,
UI composition, responsive behavior, validation, and asset approval. Let the sheet
calibrate style grammar: dominant masses, large silhouette cuts, limited filled
planes, matte light and shadow planes, dark separation, restrained semantic accents,
sparse functional detail, and actual-size readability.

Treat the sheet as **style reference only, never asset approval**. Do not crop,
trace, extract, copy, or treat as approved any depicted silhouette, vehicle, module,
boss, projectile, pickup, facility, glyph, HUD element, card shell, ornament, or
layout. In particular, a depicted player craft does not override the current player
proportion and facing rules in `VISUAL_SYSTEM.md`.

Apply the current text contract when a sheet example and the document differ. Stop
and surface the conflict when the document does not resolve it. Preserve the
project's separate per-asset AS-IS/TO-BE comparison and approval process; style
alignment alone never promotes an asset to runtime or production.

## Enforce the authoring prohibition

SVG/ImageMagick geometric authoring is prohibited except for one user-approved,
deterministic `SurfaceDetail` SVG workflow. The exception is limited to the compact
crack, broad wear-stain, and flat embedded-chip floor-detail identities generated by
`tools/design/generate_surface_detail_svg_experiment.ps1` under the exact density,
contrast, canvas, placement, batching, collision-independence, and approval contract
in `VISUAL_SYSTEM.md`. It does not authorize SVG primitives, SVG rasterization,
ImageMagick drawing operations, generated fills, or similar shortcuts for actors,
projectiles, effects, cues, structures, UI, other world visuals, mockups, sheets, or
review artifacts.

For the exception, require the normal authority-pair preflight, record the generator
path, fixed seed contract, exact source hashes, user approval, and intended semantic
IDs, and keep unselected variants outside production. A generator or selected-source
hash change invalidates approval. Never generalize this exception by visual similarity.

ImageMagick may only perform non-creative mechanical work on already-authored
images: exact crop, resize, format conversion, alpha handling, contact-sheet
placement, plain evidence labels, pixel comparison, dimension checks, and hash
verification. Those operations must not add or repair silhouettes, planes, walls,
portals, rings, arrows, markers, effect bodies, telegraphs, icons, chrome,
highlights, shadows, or other visual geometry.

Before visual work, inspect the planned tool operations. Stop if the requested
pipeline depends on prohibited authoring and is not the exact `SurfaceDetail`
exception above. If a candidate already contains visual content made or repaired
through a prohibited workflow, mark it rejected or archived and do not approve,
promote, or integrate it. Re-author it through a permitted pipeline with the
mandatory authority pair before reconsideration.

## Use the sheet in raster and ImageGen work

For every raster creation, edit, adaptation, or ImageGen task, pass the canonical
repository PNG as an actual image reference through the tool's image-reference
input. A filename, prompt description, palette transcription, or prior visual
inspection is not a substitute.

- For a new raster, include the style sheet in the generation call's referenced
  image paths.
- For an edit, include both the target image or images and the style sheet in the
  same referenced-image input.
- State in the prompt that the sheet supplies style grammar only, that its objects
  and layout must not be reproduced, and that `VISUAL_SYSTEM.md` supplies the
  binding task constraints.
- Stop if the chosen tool cannot receive the actual reference image. Do not produce
  a text-only approximation.

After generation, inspect the result against the document and sheet at intended
runtime size and with the document's required grayscale, silhouette, state, facing,
spacing, overflow, or collision checks as applicable.

## Reject ungrounded output

Do not approve, integrate, promote to a production manifest, or describe as
compliant any visual output made without both authority sources. For raster or
ImageGen output, also require evidence that the canonical sheet was passed as the
actual image reference. Mark an ungrounded candidate as rejected or unverified; it
may remain only as clearly labeled AS-IS evidence. Regenerate or rework it under the
authority pair before reconsidering it.

## Record evidence

Record the following in the task's existing approval/evidence owner, or in the final
handoff when no such owner exists. Do not create a redundant record solely for this
check.

- Both canonical paths and confirmation that the document was read completely
- Expected and observed reference SHA-256
- Observed `VISUAL_SYSTEM.md` SHA-256
- The original artifact provenance recorded above
- Confirmation of visual inspection
- For raster or ImageGen work, confirmation that the canonical PNG was supplied as
  an actual referenced image
- For the `SurfaceDetail` SVG exception, the generator path, fixed seeds, exact
  selected SVG hashes, semantic IDs, and user-approval evidence; record
  `actual_image_reference_used=false` and
  `reference_input_method=deterministic_surface_detail_svg_exception`
- Applicable task constraints and the asset's separate approval status

For a visual-replacement workbench unit, populate its
`visual_authority_evidence` object before changing the unit to `switch_ready`.
Record both canonical paths, the required sheet hash, complete-document reading,
original-detail sheet inspection, actual image-reference use, and the concrete
reference input method. Use `actual_image_reference_used=false` with
`reference_input_method=deterministic_surface_detail_svg_exception` only for the
exact exception above. Use `actual_image_reference_used=false` and
`reference_input_method=not_applicable` only when the unit has no raster or SVG
deliverables.

If any required evidence is unavailable, do not claim visual compliance or asset
approval.
