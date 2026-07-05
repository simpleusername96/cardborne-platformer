---
type: evidence
status: active
created: 2026-07-05
source: docs/research/external_codebase_deep_dive_2026-07-05.md and docs/design/testbed-plan/06_external_foundation_replacement.md
topic: Third-party package adoption and reference tracking
scope: External code, plugins, examples, and assets considered for the Godot testbed foundation
related:
  - ./external_codebase_deep_dive_2026-07-05.md
  - ./foundation_resource_survey_2026-07-05.md
  - ../design/testbed-plan/06_external_foundation_replacement.md
---

# Third-Party Adoption Ledger

## Purpose

Track which external packages are copied into the repo, which are only reference material, and which are deferred. This ledger is evidence, not approval to import a package. Any copied package must update this file in the same commit as the copied files.

## Sources

- `docs/research/external_codebase_deep_dive_2026-07-05.md`
- `docs/research/foundation_resource_survey_2026-07-05.md`
- `docs/design/testbed-plan/06_external_foundation_replacement.md`

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
| Godot LDtk Importer | Primary candidate for authored map import and typed entity markers. | `https://github.com/heygleeson/godot-ldtk-importer` | `0ecab8d` from local deep dive | MIT | none | none | Deep dive reported importer import/boot OK in external clone; not yet validated inside this repo. | none known | candidate |
| KoBeWi ControlsRemap | Candidate/reference for small persistent input remap core. | `https://github.com/KoBeWi/Godot-Input-Remap` | `0d7204b` from local deep dive | MIT | none | Local implementation in `scripts/autoload/InputBindings.gd` follows the small resource-pattern idea without copying files. | Pending project import and manual remap QA in this repo. | none known | reference-only |
| GDQuest Godot 4 Procedural Generation | Reference for deterministic path-first room/chunk generation. | `https://github.com/gdquest-demos/godot-4-procedural-generation` | `19c98ce` from local deep dive | Source MIT; assets CC-BY 4.0 | none | none | Deep dive source inspection only for this repo. | CC-BY attribution required if assets are copied; no assets copied. | reference-only |
| Ultimate Platformer Controller 2D | Movement feature checklist and formulas. | `https://github.com/Noah-Erz/ultimate-platformer-controller-2d` | `9ce6580` from local deep dive | MIT | none | none | Source inspection only. | none known | reference-only |
| LimboAI demo components | Combat/enemy component reference for health, hitbox, hurtbox, knockback, and AI interruption. | `https://github.com/limbonaut/limboai` | `f94763e` from local deep dive | MIT source; demo art has attribution requirements | none | none | Source inspection only; full plugin not adopted. | Demo art attribution required if copied; no assets copied. | reference-only |
| Maaack Godot Game Template | Full shell/menu/options template candidate after map/controller blockers. | `https://github.com/Maaack/Godot-Game-Template` | `1953b35` from local deep dive | MIT | none | none | Deep dive import OK; boot reported example scene parse error in external clone. | none known | deferred |
| Maaack Input Remapping | Rich input-remapping UI candidate if local settings popup becomes insufficient. | `https://github.com/Maaack/Godot-Input-Remapping` | `736bb20` from local deep dive | MIT | none | none | Deep dive import OK; headless display-server warnings in external clone. | none known | deferred |
| Metroidvania System | Later minimap/world-map/exploration-state candidate. | `https://github.com/KoBeWi/Metroidvania-System` | `d9e456d` from local deep dive | MIT | none | none | Deep dive import ran with plugin warning/leak signals in external clone. | none known | deferred |
| YATI | Tiled importer fallback if LDtk spike fails. | `https://github.com/Kiamo2/YATI` | `72a3716` from local deep dive | MIT | none | none | Source inspection only. | none known | deferred |
| Dialogic 2 | Later dialogue/NPC/shop content candidate. | `https://github.com/dialogic-godot/dialogic` | `e127f85` from local deep dive | MIT; some bundled assets/fonts have separate notices | none | none | Source inspection only. | Verify bundled asset/font notices before copying. | deferred |

## Recommendations

- Do not copy any external package until this ledger has source URL, commit or release, license, copied paths, local modifications, and validation commands ready for that package.
- Keep external map/editor terms behind local resolver or wrapper code so player, combat, enemy, and UI scripts use project vocabulary.
- Re-check license files at copy time because this ledger reflects the reviewed clone state, not a permanent upstream guarantee.

## Limitations

- No external package files are copied into this repo in this ledger pass.
- Commit hashes come from the local deep-dive evidence and should be re-verified before copying from upstream.
- Mouse, gamepad, and axis remapping remain deferred in the local input implementation.
