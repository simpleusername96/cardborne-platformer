---
type: evidence
status: active
owner: BK
created: 2026-08-15
last_reviewed: 2026-08-15
topic: Eight-boss campaign boss, ordinary-enemy, and neutral-facility image candidates
scope: ImageGen provenance, transparent candidate files, actual-size and grayscale review, hashes, and approval state
source: Built-in ImageGen with the canonical Cardborne visual authority sheet as an actual image reference
related:
  - ../../../VISUAL_SYSTEM.md
  - ../../../cardborne-universal-art-style-reference.png
  - ../../../../reports/2026-08-15-eight-boss-combat-design-analysis.md
  - ../../../../reports/2026-08-15-eight-boss-combat-approval-ko.md
  - ../../../../../.agents/execplans/2026-08-15-eight-boss-combat-depth-and-run-report.md
---

# Eight-Boss, Enemy, and Facility Image Candidates v1

## Purpose

Preserve the grounded raster source set for the three new bosses, four ordinary enemies,
and two neutral facilities selected by the eight-boss plan. On 2026-08-15, the user
approved these exact PNG bytes and SHA-256 values for production integration.

![All nine candidates](./previews/all-candidates-contact-sheet.png)

## Sources

- Binding text authority: `docs/design/VISUAL_SYSTEM.md`, read completely before
  generation.
- Actual image reference supplied to every ImageGen generation and revision call:
  `docs/design/cardborne-universal-art-style-reference.png`.
- Expected and observed reference SHA-256:
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- The reference sheet was inspected at its original 1448x1086 detail.
- Recorded original reference provenance:
  `C:/Users/BK/.codex/generated_images/019fbfe9-857e-7453-b72d-20908d848577/exec-0b8aa606-cf55-45c1-abb3-fb3df762b080.png`,
  timestamp 2026-08-02 12:13:44 KST.
- Generation mode: built-in `image_gen`; new raster generation for nine v1 images and
  precise-object revision for six candidates.
- Exact prompt construction: [`generation-prompts.md`](./generation-prompts.md).

The canonical sheet supplied style grammar only. No depicted object, silhouette,
module, glyph, text, or layout was approved or copied as an asset source.

## Findings

### Candidate files and decisions

| Candidate | Canvas | SHA-256 | Review state | Finding |
| --- | ---: | --- | --- | --- |
| [`boss_stage_06.png`](./assets/boss_stage_06.png) | 352x352 | `78a8740c37176e1150e135388835e83ad66cf698269a0771e0de76dde0ecd4fe` | `user_approved` | Selected v3 keeps two broad side banks with two large channels each while removing the v1 barrel clutter. The over-simplified v2 remains under `revisions/` as rejected evidence. |
| [`boss_stage_07.png`](./assets/boss_stage_07.png) | 352x352 | `6a14321073406be7c3b3778b1155fa27031fa2144a3fe2342e49e58bc41be26e` | `user_approved` | Selected v2 keeps perpendicular rails and adds a clear right-facing fork; no beam geometry is baked in. |
| [`boss_stage_08.png`](./assets/boss_stage_08.png) | 352x352 | `ca71f170b1b527559a758540eb5dc10aef7fd6babd1c4f51af1801d8a139a21a` | `user_approved` | Forward wedge gap and heavy core are readable without drawing the runtime pulse ring. |
| [`enemy_mobile_ordinary_beam_01.png`](./assets/enemy_mobile_ordinary_beam_01.png) | 112x112 | `4ee8d491a432fa6eeda907eb32bd9b023e7114737daa8f3386543df3795d0a81` | `user_approved` | Selected v2 shortens the rail and broadens the mobile body to 31.39% opaque canvas coverage. |
| [`enemy_ordinary_range_01.png`](./assets/enemy_ordinary_range_01.png) | 112x112 | `25fec951ea0714062feb9ff6d4177c5e3da200b4a5d070be4878c3b6a96cdef7` | `user_approved` | Crescent motion silhouette and inward muzzle mass remain readable at actual size and in grayscale. |
| [`enemy_ordinary_sweep_01.png`](./assets/enemy_ordinary_sweep_01.png) | 112x112 | `90423e781d86330345fe1c4ad9c29ece4f22b8bbbc069cc1d946c4cd5028d1b1` | `user_approved` | Selected v2 keeps the fast pass silhouette and merges the repeated cells into one broad bomb-bay plane. |
| [`enemy_ordinary_melee_02.png`](./assets/enemy_ordinary_melee_02.png) | 112x112 | `6b7be8946dd5af03c5f785dfbec6e6b3500f44587d88b400e36508ff9361cee1` | `user_approved` | Selected v2 reduces the identity to one heavy rear compression mass and one open collector jaw; stacks remain code-owned. |
| [`facility_repair_beacon.png`](./assets/facility_repair_beacon.png) | 192x192 | `62b4b1b0240940d09ca0ecb28ade36b811865770b84dd594a7727397f79ce80c` | `user_approved` | Four-way service structure and mint core distinguish recovery without baking a plus icon or effect radius. |
| [`facility_barrier_projector.png`](./assets/facility_barrier_projector.png) | 192x192 | `05b188a8def398388f7beec52bfb60086fd33339b9403085b2ea1f1d27a0fe59` | `user_approved` | Opposed protective vanes and central slab distinguish shielding without a ring or barrier bubble. |

All nine selected files are `user_approved` and production-integrated. The listed
SHA-256 values remain the approval boundary; any byte change requires a new approval.

### Mechanical post-processing

- Built-in ImageGen produced one opaque chroma-key PNG per call under
  `C:/Users/BK/.codex/generated_images/01a00142-7f77-7f60-950e-e40e7d1b27cd`.
- Exact initial chroma files are retained under `sources/`; revisions are retained under
  `revisions/` so the selected and rejected directions remain auditable.
- The installed imagegen chroma helper used border auto-key, soft matte, thresholds
  12/220, and despill. Full-resolution transparent initial results are retained under
  `alpha-masters/`. The original generated files also remain under the recorded Codex
  generated-image directory.
- ImageMagick performed only Mitchell resize to the existing 352, 112, and 192 pixel
  canvases, contact-sheet placement, plain labels, grayscale conversion, dimension
  inspection, and hash verification.
- All nine target-size files have RGBA output and `srgba(0,0,0,0)` at the top-left
  corner. Visual inspection found no remaining solid chroma background.
- No SVG, ImageMagick shape drawing, generated geometry repair, texture slicing, or
  manual paint operation was used.

### Review artifacts

- [Combined review sheet](./previews/all-candidates-contact-sheet.png), SHA-256
  `09cb9c3d8d743d0e3f00612fdb8030352b46df2d556042eaae436c9c49ddd523`.
- [Grayscale review](./previews/all-candidates-grayscale.png), SHA-256
  `231a3d2705f303a906f7ae58c2efa34ec83dd7c79cfcd5c5333395f594ff6a99`.
- [Bosses at 352x352](./previews/bosses-actual-size.png), SHA-256
  `be63b147ffacf0e22fd9fa9ff43201efc3ed05344ecd29b6c56ada971bb9606e`.
- [Enemies at 112x112](./previews/enemies-actual-size.png), SHA-256
  `a3bffc180565b63a833a2fe5e3e4aa9b1f58656a8cbe1f98b7be03456a9cca72`.
- [Facilities at 192x192](./previews/facilities-actual-size.png), SHA-256
  `719d6ddee9e3069b69123331fef109110bf199fb8f9a46bd7e3e903ae5a0d386`.

## Recommendations

- Keep attack telegraphs, laser walls, pulse fronts, growth_enemy stacks, repair range, and
  barrier range code-native. Do not bake them into these actor/facility rasters.

## Promotion state and limitations

- The visual spec now covers all eight bosses and five neutral-facility roles. The
  production manifest contains 90 approved images after this batch and the four other
  approved promotion images are included.
- The new actor and facility semantic IDs are integrated into runtime and Guidebook
  presentation. The contact sheets remain approval evidence, not runtime captures.
- The nine approved PNGs retain their reviewed canvases, hashes, and semantic mapping.
  Runtime integration does not alter their bytes.
