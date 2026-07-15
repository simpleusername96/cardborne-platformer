---
type: evidence
status: active
created: 2026-07-05
last_reviewed: 2026-07-15
source: Local deep-dive evidence plus current official upstream release and compatibility documentation
topic: Third-party package adoption and reference tracking
scope: External code, plugins, examples, and assets considered for the production foundation
related:
  - ./external_codebase_deep_dive_2026-07-05.md
  - ./foundation_resource_survey_2026-07-05.md
  - ./component_ui_foundation_research_2026-07-13.md
  - ../design/MAP_AUTHORING_PIPELINE_CONTRACT.md
  - ../../.agent/execplans/2026-07-12-actual-game-production-roadmap.md
---

# Third-Party Adoption Ledger

## Purpose

Track which external packages are copied into the repo, which are only reference material, and which are deferred. This ledger is evidence, not approval to import a package. Any copied package must update this file in the same commit as the copied files.

## Sources

- `docs/research/external_codebase_deep_dive_2026-07-05.md`
- `docs/research/foundation_resource_survey_2026-07-05.md`
- `docs/design/MAP_AUTHORING_PIPELINE_CONTRACT.md`

## Entry Template

| Field | Required content |
| --- | --- |
| Package | Package or source name. |
| Purpose | Why the project is evaluating or adopting it. |
| Source URL | Upstream URL used for review or copy. |
| Commit or release | Exact commit hash, tag, or release. |
| License | License signal and local copied license path when copied. |
| Copied paths | Every copied file or folder in this repo. Use `none` for reference-only entries. |
| Local modifications | Any local patches or compatibility changes. |
| Validation commands | Import, boot, test, or review checks used locally. |
| Attribution needs | Required attribution text or `none known`. |
| Adoption status | `candidate`, `copied`, `reference-only`, `deferred`, `blocked`, or `removed`. |

## Findings

| Package | Purpose | Source URL | Commit or release | License | Copied paths | Local modifications | Validation commands | Attribution needs | Adoption status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| LDtk + Godot LDtk Importer | Deferred candidate for authored room geometry and typed markers behind a local resolver; Godot-native TileMapLayer is the first foundation spike. | `https://github.com/deepnight/ldtk`; `https://github.com/heygleeson/godot-ldtk-importer` | LDtk `v1.5.3` (`72c75f1`); importer release `2.0.1` (`92803cc`); use locally reviewed importer `0ecab8d` for any isolated spike | MIT | none | none | Importer `0ecab8d` imported and booted in an external Godot 4.7 clone. Cardborne typed-marker, collision, stable-ID, deterministic reimport, and generated-output tests remain required. Native authoring measurements must justify reopening the spike. | none known | deferred-candidate |
| KoBeWi ControlsRemap | Candidate/reference for small persistent input remap core. | `https://github.com/KoBeWi/Godot-Input-Remap` | `0d7204b` from local deep dive | MIT | none | Local implementation in `scripts/autoload/InputBindings.gd` follows the small resource-pattern idea without copying files. | `.\tools\godot.ps1 --path . --headless --import`; `.\tools\godot.ps1 --path . --headless --script res://tools/validate_input_remap.gd`; rendered settings popup at 1280x720 and 390x720. | none known | reference-only |
| GDQuest Godot 4 Procedural Generation | Reference for deterministic path-first room/chunk generation. | `https://github.com/gdquest-demos/godot-4-procedural-generation` | `19c98ce` from local deep dive | Source MIT; assets CC-BY 4.0 | none | none | Deep dive source inspection only for this repo. | CC-BY attribution required if assets are copied; no assets copied. | reference-only |
| Ultimate Platformer Controller 2D | Movement feature checklist and formulas. | `https://github.com/Noah-Erz/ultimate-platformer-controller-2d` | `9ce6580` from local deep dive | MIT | none | none | Source inspection only. | none known | reference-only |
| LimboAI demo components | Combat/enemy component reference for health, hitbox, hurtbox, knockback, and AI interruption. | `https://github.com/limbonaut/limboai` | `f94763e` from local deep dive | MIT source; demo art has attribution requirements | none | none | Source inspection only; full plugin not adopted. | Demo art attribution required if copied; no assets copied. | reference-only |
| Godot State Charts | Reference for explicit enemy or boss warning/active/recovery state ownership. | `https://github.com/derkork/godot-statecharts` | `v0.22.5` (`76d226a`) | MIT | none | none | Official changelog states Godot 4.7 compatibility fix; compare one actor against a local typed-state implementation before any adoption. | none known | reference-only |
| GdUnit4 | Candidate test framework after a stable Godot 4.7-compatible release. | `https://github.com/godot-gdunit-labs/gdUnit4` | stable `v6.1.3` (`1579130`) | MIT | none | none | Stable compatibility currently ends at Godot 4.6.3; defer until `v6.2` or another tagged 4.7-compatible release is verified locally. | none known | deferred |
| Phantom Camera | Possible later camera rig if built-in `Camera2D` cannot satisfy room transitions and boss framing. | `https://github.com/ramokz/phantom-camera` | `v0.11.0.2` (`e468862`) | MIT | none | none | Upstream documents Godot 4.3 minimum but no explicit 4.7 certification; current project camera already supports smoothing and limits. | none known | deferred |
| Maaack Godot Game Template | Reference for SceneLoader, pause, settings, and production-shell comparison; do not adopt the whole template. | `https://github.com/Maaack/Godot-Game-Template` | `v1.4.7` (`93e66a0`) | MIT | none | none | Upstream identifies Godot 4.7 support. Prior `v1.4.6` external clone imported but an example scene had a parse error; `v1.4.7` is not locally retested. | none known | reference-only |
| Kenney Pixel Platformer | Coherent prototype art family candidate for one-room readability and integer-scale evaluation. | `https://kenney.nl/assets/pixel-platformer` | `1.2` | CC0 | none | none | No files imported. One-room 18 px versus 36 px integer-scale spike and explicit asset approval remain required. | none known | candidate |
| Maaack Input Remapping | Rich input-remapping UI candidate if local settings popup becomes insufficient. | `https://github.com/Maaack/Godot-Input-Remapping` | `736bb20` from local deep dive | MIT | none | none | Deep dive import OK; headless display-server warnings in external clone. | none known | deferred |
| Metroidvania System | Later minimap/world-map/exploration-state candidate. | `https://github.com/KoBeWi/Metroidvania-System` | `d9e456d` from local deep dive | MIT | none | none | Deep dive import ran with plugin warning/leak signals in external clone. | none known | deferred |
| YATI | Tiled importer fallback if LDtk spike fails. | `https://github.com/Kiamo2/YATI` | `72a3716` from local deep dive | MIT | none | none | Source inspection only. | none known | deferred |
| Dialogic 2 | Later dialogue/NPC/shop content candidate. | `https://github.com/dialogic-godot/dialogic` | `e127f85` from local deep dive | MIT; some bundled assets/fonts have separate notices | none | none | Source inspection only. | Verify bundled asset/font notices before copying. | deferred |

## Project-Original Presentation Set

The first release candidate uses one local procedural presentation family instead
of importing a third-party prototype pack. This set was accepted through the
owner-authorized Milestone 9 implementation and may be replaced later without
changing collision, combat, or content IDs.

| Set | Purpose | Owned paths | Rights and attribution | Validation | Status |
| --- | --- | --- | --- | --- | --- |
| Cardborne procedural prototype family | Distinct player/enemy silhouettes, regional terrain, hit feedback, and ten gameplay audio cues. | `scripts/visuals/PlayerVisualOverlay.gd`; `scripts/visuals/EnemyDetailOverlay.gd`; `scripts/visuals/TerrainPresentationStyler.gd`; `scripts/presentation/FeedbackCueSynthesizer.gd`; `scripts/presentation/FeedbackHitBurst.gd`; `scripts/presentation/FeedbackDirector.gd` | Created in this repository from vector drawing primitives and deterministic PCM synthesis. No copied art/audio and no attribution requirement. | `validate_actor_presentation.gd`; `validate_terrain_presentation.gd`; `validate_feedback_cues.gd`; `validate_feedback_director.gd`; rendered 960x540, 1280x720, and 1920x1080 inspection. | accepted for first release candidate |

## Recommendations

- Do not copy any external package until this ledger has source URL, commit or release, license, copied paths, local modifications, and validation commands ready for that package.
- Keep external map/editor terms behind local resolver or wrapper code so player, combat, enemy, and UI scripts use project vocabulary.
- Re-check license files at copy time because this ledger reflects the reviewed clone state, not a permanent upstream guarantee.

## Limitations

- No external package files are copied into this repo in this ledger pass.
- The accepted procedural family is production-readable prototype presentation,
  not a claim that final commercial art direction is complete.
- Commit hashes come from the local deep-dive evidence and should be re-verified before copying from upstream.
- Browser-export input behavior and the revised keyboard defaults remain deferred
  in the local input implementation.
