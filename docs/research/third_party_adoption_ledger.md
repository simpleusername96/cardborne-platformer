---
type: evidence
status: active
created: 2026-07-05
last_reviewed: 2026-07-17
owner: BK
source: Repository asset inventory and upstream font source
topic: Third-party content currently retained in Cardborne
scope: Copied third-party files that remain after the isometric action RPG reset
related:
  - ../design/UI_VISUAL_SYSTEM.md
  - ../../.agent/execplans/2026-07-17-isometric-action-rpg-pivot.md
---

# Third-Party Adoption Ledger

## Purpose

Record third-party files that are actually present in the repository. A package
being mentioned in research or in the pivot plan does not authorize copying it.

## Sources

- Repository inventory under `art/ui/production/fonts/`.
- Google Fonts source at commit
  `26c5c976d82d50c24a8f0a7ac455e0a7c639c226`.

## Findings

| Package | Purpose | Source | Version / hash | License | Copied paths | Local modifications | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Noto Sans KR variable font | Korean and English UI glyph coverage | `https://github.com/google/fonts/tree/26c5c976d82d50c24a8f0a7ac455e0a7c639c226/ofl/notosanskr` | Git blob `b386890ba945e1f39448a6b59f20c5d194f58808`; SHA-256 `194018e6b2b293a7964f037b25c0249ce1418bc9ab3c971060a03aa57861e252` | SIL OFL-1.1 | `art/ui/production/fonts/NotoSansKR-Variable.ttf`; `art/ui/production/fonts/NotoSansKR-OFL.txt` | Binary unchanged; local filename normalized | copied |

All reference-only platformer packages from the former implementation were
removed from this active ledger during the genre reset. Their historical review
remains recoverable from Git commit `7cc069c`.

## Recommendations

- Add a row in the same commit whenever a third-party file is copied.
- Record an exact source revision, license, copied paths, modifications, and a
  local validation command before adoption.
- Prefer built-in Godot 4.7 facilities for the first combat proof. Reconsider
  plugins only when a measured limitation justifies the added dependency.

## Limitations

- This ledger covers copied third-party content, not every external design or
  documentation source cited by the active plan.
- Upstream license and compatibility must be checked again at copy time.
