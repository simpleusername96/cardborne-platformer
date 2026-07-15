---
type: evidence
status: active
owner: BK
created: 2026-07-16
last_reviewed: 2026-07-16
topic: Milestone 1 production UI asset-adoption rendered QA
source: Owner-selected UI references, production asset catalog, Godot 4.7 validators, and deterministic OpenGL captures
related:
  - ./.agent/execplans/2026-07-15-master-ui-overhaul.md
  - ./docs/design/UI_VISUAL_SYSTEM.md
  - ./docs/design/visuals/player_experience_ui_concept.png
  - ./docs/design/reports/ui-raster-asset-catalog.png
---

# UI Easy-Adoption Design QA

## Purpose

Record the bounded rendered-acceptance evidence for Milestone 1 of the master UI
overhaul: centralized production asset ownership and the first real-screen image
placements. This document is evidence for the active ExecPlan, not a replacement
for the remaining implementation milestones.

## Sources

- Owner-selected composition and visual-language references under `docs/design/`.
- The production asset catalog and manifest under `art/ui/production/`.
- Current Godot scenes, UI scripts, focused validators, and deterministic OpenGL
  captures produced from this isolated worktree.

## Result

**Passed for Milestone 1.** This result approves asset resolution and the first
real-screen placements. It does not approve the complete UI overhaul: the shared
flat Theme, border reduction, all-screen migration, HUD migration, production Web
export, and full-run QA remain open milestones.

## Reviewed Scope

- Main Menu and shell-only Settings background behavior.
- Hero Preparation background, Traveler portrait, six loadout icons, all equipment
  model choices, Spirit Stones, potion, and selected-detail art.
- Card Reward use of all five active card vignettes with live rarity, selection,
  stack, reroll, error, and committed states.
- Run Result use of Traveler, Slime King, and Boss Core imagery without replacing
  metrics, build, retained rewards, retry, or exit choices.
- In-run Settings and Forge context preservation: both continue to reveal the
  live world rather than impersonating full-screen navigation.

## Reference Comparison

The review placed the source references and runtime captures into the same visual
comparison input at matching supported viewports. The UI concept was treated as a
composition reference only because its Warrior and active-skill content is no
longer part of the product contract. The raster catalog was the identity, palette,
alpha, and readable-size reference for detailed assets.

Runtime captures:

- `.codex-runtime/uiux/shell/{compact,desktop,hd}_{main_menu,settings,pause_settings,victory,defeat}.png`
- `.codex-runtime/uiux/progression/{compact,desktop,hd}_{hero_preparation,card_reward,run_result}.png`
- `user://hero_preparation_ui_validation/hero_preparation_{en,ko}_{960x540,1280x720,1920x1080}.png`
- `user://reward_choice_ui_validation/card_offer_{en,ko}_{960x540,1280x720,1920x1080}.png`

## Evidence Matrix

| Surface | States and viewports | Result |
| --- | --- | --- |
| Main Menu | Initial focus at 960x540, 1280x720, 1920x1080 | Background cover, quiet text zone, focus, and actions remain clear. |
| Settings | Shell, pause/in-run, remap; EN/KO automated copy checks | Shell image appears only outside a run; live-stage context is preserved in-run. |
| Hero Preparation | EN/KO at all three viewports; equipment and consumable selection | All required values remain available; compact mode uses its existing internal scroll without viewport escape. |
| Card Reward | EN/KO offer, reroll, error, committed, focus at all three viewports | Vignettes stay inside the cards; live copy and state remain readable and keyboard-operable. |
| Run Result | Victory, defeat, stage retry, boss retry | Identity art supports the summary; Boss Core art is hidden when it was not secured. |

## Automated Evidence

- `PRODUCTION_UI_ASSETS_OK assets=52 backgrounds=5 illustrations=19 shapes=6 icons=22`
- `SHELL_UI_VALIDATION_OK locales=2 viewports=3 screens=4`
- `HERO_PREPARATION_UI_VALIDATION_OK`
- `CARD_REWARD_VALIDATION_OK ... ui_locales=2 ui_viewports=3 targets=48px`
- `RUN_RESULT_UI_VALIDATION_OK`
- `PRODUCTION_BOOT_VALIDATION_OK`
- Real OpenGL capture scripts completed for shell and progression surfaces.

## Findings

- No P0/P1/P2 defect blocks the Milestone 1 asset-adoption batch.
- Existing thin borders, rounded local styleboxes, and nested panel treatment are
  visibly still present. This is the explicit starting condition for Milestone 2,
  not accepted final styling.
- The `1672x941` shell images are modestly upscaled at 1920x1080. The reviewed HD
  captures remain usable for the MVP, but native-size replacement remains a
  targeted option if later Theme simplification makes softness more visible.
- Detailed art remains at 48px or larger in selection slots and 64px or larger in
  identity slots; smaller semantic use continues to fall back to SVG.
- Forge artwork remains deferred because the live Safe Intermission view provides
  clearer gameplay context than a full-screen workshop background.

## Unrun Gates

The full release matrix, production Web export, served-browser path, and complete
run are intentionally not claimed here. They belong to later overhaul milestones
after the Theme and remaining surfaces change.
