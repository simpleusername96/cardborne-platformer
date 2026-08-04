---
type: spec
status: active
owner: BK
created: 2026-08-03
last_reviewed: 2026-08-04
scope: Current AS-IS references, authored-raster targets, rendered legacy evidence, exact technical records, and generated review UI
related:
  - ../VISUAL_SYSTEM.md
  - ../cardborne-universal-art-style-reference.png
  - ./asset-rationalization.md
  - ./external-candidates/README.md
  - ../../product/vehicle_game_spec.md
  - ../../../art/visuals/production/README.md
---

# Visual Replacement Workbench

## Purpose

This folder is the sole active workspace for reviewing and switching Cardborne
production visuals. It shows current runtime files directly as AS-IS and maps
each authored TO-BE deliverable or code-native ownership switch to exact
production, runtime-change, and retirement targets.

## Scope

- `replacement-workbench.json` is the only hand-authored unit/status source.
- `inventory.json` and `index.html` are deterministic generated outputs.
- `index-template.html` owns the read-only bilingual file-URL interface.
- `previews/` contains review-only comparisons and contact sheets.
- `external-candidates/` contains a curated, license-recorded subset of external
  source material and review-only derivative candidates. It is never a TO-BE or
  production root.
- `to-be/assets/` may contain only directly promotable production files whose
  suffix exactly mirrors their production target path.
- [`asset-rationalization.md`](./asset-rationalization.md) records the audited
  evidence behind the pre-Phase-6 media boundary. It is not a second unit,
  technical-readiness, or application-state authority.

The workbench never owns gameplay rules or art direction. Those remain in the
product specification and the mandatory visual authority pair:
[`VISUAL_SYSTEM.md`](../VISUAL_SYSTEM.md) plus
[`cardborne-universal-art-style-reference.png`](../cardborne-universal-art-style-reference.png).
Their canonical repository paths are `docs/design/VISUAL_SYSTEM.md` and
`docs/design/cardborne-universal-art-style-reference.png`.

## Requirements

- AS-IS media is referenced from `art/visuals/production`; it is not copied
  into this folder.
- Before candidate creation, review, technical acceptance, or application, read the complete
  visual specification and inspect the canonical reference sheet at original
  detail with its recorded SHA-256. Raster and ImageGen candidates must record
  that the canonical sheet was supplied as an actual image reference.
- A candidate created without the authority pair cannot become `switch_ready`,
  receive a technical record, or enter production. Keep it outside active TO-BE paths until
  it is regenerated or reworked under the pair.
- Before any unit becomes `switch_ready`, record `visual_authority_evidence` in
  that unit with the exact canonical spec path, sheet path, sheet SHA-256,
  `document_read_complete=true`, and `sheet_inspected_original=true`. A unit with
  raster PNG deliverables also requires `actual_image_reference_used=true` and a
  concrete `reference_input_method` such as `image_gen.referenced_image_paths`;
  non-raster units use `false` and `not_applicable`.
- A preview never satisfies a deliverable or technical-readiness requirement.
- An external candidate never satisfies a deliverable or technical-readiness requirement.
  It must first be adapted to the Cardborne camera, palette, silhouette, canvas,
  pivot, and detail contract and saved under the exact `to-be/assets/` target.
- A follow-up rasterization switch may declare `rendered_as_is_paths` so the
  report preserves screenshots of the former code-drawn result after the new
  PNG becomes current production. These paths are review evidence only and
  must remain under `previews/`.
- `approved_for_switch` is the retained internal name for an exact technical
  ledger, not a user approval or response gate. Historical `approved_by=BK`
  records remain valid; autonomous runs use `approved_by=autonomous-executor`.
- A technical ledger is valid only when its target-path set, SHA-256 map, and
  ordered retirement paths exactly match one switch unit. Extra, missing, or
  changed paths and hashes fail closed.
- Raster deletion must follow, never precede, the consumer, descriptor,
  manifest, provider, and validator migration for that unit.
- The browser UI works without networking or a server. Its optional per-target
  Needs attention flags and short notes stay in browser-local storage, never
  change repository truth, and never pause autonomous execution.
- Korean and English labels, keyboard operation, visible focus, responsive
  layout, image dialogs, and reduced-motion behavior remain complete.

Build and verify with:

```powershell
.\tools\design\build_visual_replacement_workbench.ps1
.\tools\design\build_visual_replacement_workbench.ps1 -Check
.\tools\validation\validate_cardborne_visual_authority.ps1
.\tools\validation\validate_visual_replacement_workbench.ps1
```

Preview an exact technically ready unit without writing production files:

```powershell
.\tools\design\promote_visual_replacement_unit.ps1 -UnitId <unit_id>
```

## Acceptance Criteria

- Every production PNG and font belongs to exactly one switch unit.
- Every generated byte matches a fresh deterministic build.
- Every current, preview, consumer, runtime-change, and retirement path is
  repository-contained and resolves.
- Every TO-BE target is unique and under the production visual root.
- Every reusable fixed gameplay-asset identity in a rasterization unit has one
  authored-raster owner. This does not change the separate code-native UI
  contract. Runtime gameplay code retains live placement, transform, tint,
  clip, value, topology, collision, and timing truth.
- The generated review UI exposes the exact canonical specification and sheet,
  and every ready unit has schema-validated authority-pair provenance.
- No historical snapshot or review-pipeline dependency appears in active
  workbench inputs or generated output.
