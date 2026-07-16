---
type: evidence
status: active
owner: BK
created: 2026-07-16
last_reviewed: 2026-07-16
topic: Milestones 1-5 production UI and gameplay HUD rendered QA
source: Owner-selected UI references, active visual spec, production asset catalog, Godot 4.7 validators, and deterministic OpenGL captures
related:
  - ./.agent/execplans/2026-07-15-master-ui-overhaul.md
  - ./docs/design/UI_VISUAL_SYSTEM.md
  - ./docs/design/visuals/player_experience_ui_concept.png
  - ./docs/design/reports/ui-raster-asset-catalog.png
---

# Production UI Milestones 1-5 Design QA

## Purpose

Record the bounded rendered-acceptance evidence for Milestones 1 through 5 of the
master UI overhaul: centralized production asset ownership, real-screen image
placements, the shared flat Theme/component foundation, all shell and economy
surfaces, and the gameplay HUD/Trial migration. This document is evidence for the
active ExecPlan, not a replacement for the remaining world proof and integration
milestones.

## Sources

- Owner-selected composition and visual-language references under `docs/design/`.
- The production asset catalog and manifest under `art/ui/production/`.
- Current Godot scenes, UI scripts, focused validators, and deterministic OpenGL
  captures produced from this isolated worktree.

## Result

**Passed for Milestones 1-5.** This result approves the UI asset registry, shell,
dense progression/economy surfaces, shared flat Theme/components, gameplay HUD,
feedback presentation, and Arsenal Trial UI. It does not approve the complete UI
overhaul: measured world presentation, production Web export, integration, and
full-run QA remain open milestones.

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
- The project Theme and its fifteen semantic variations for buttons, panels,
  meters, and text.
- Flat-plane and shared-component treatment across Main Menu, Hero Preparation,
  Settings, Card Reward, and gameplay HUD states.

## Reference Comparison

The review placed the source references and runtime captures into the same visual
comparison input at matching supported viewports. The UI concept was treated as a
composition reference only because its Warrior and active-skill content is no
longer part of the product contract. The raster catalog was the identity, palette,
alpha, and readable-size reference for detailed assets.

Runtime captures:

- `.codex-runtime/uiux/shell/{compact,desktop,hd}_{main_menu,settings,pause_settings,victory,defeat}.png`
- `.codex-runtime/uiux/progression/{compact,desktop,hd}_{hero_preparation,card_reward,run_result}.png`
- `.codex-runtime/uiux/gameplay_hud/{compact,desktop,hd}_*.png`
- `user://hero_preparation_ui_validation/hero_preparation_{en,ko}_{960x540,1280x720,1920x1080}.png`
- `user://reward_choice_ui_validation/{card,level}_{offer,error,committed}_{en,ko}_{960x540,1280x720,1920x1080}.png`

## Evidence Matrix

| Surface | States and viewports | Result |
| --- | --- | --- |
| Main Menu | Initial focus at 960x540, 1280x720, 1920x1080 | Background cover, quiet text zone, focus, and actions remain clear. |
| Settings | Shell, pause/in-run, remap; EN/KO automated copy checks | Shell image appears only outside a run; live-stage context is preserved in-run. |
| Hero Preparation | EN/KO at all three viewports; equipment and consumable selection | All required values remain available; compact mode uses its existing internal scroll without viewport escape. |
| Card Reward | EN/KO offer, reroll, error, committed, focus at all three viewports | Vignettes stay inside the cards; live copy and state remain readable and keyboard-operable. |
| Run Result | Victory, defeat, stage retry, boss retry | Identity art supports the summary; Boss Core art is hidden when it was not secured. |
| Shared Theme | Normal, focus, selected, disabled, error, committed, guard, boss, and modal states | Zero-radius flat planes remain coherent; focus/selection uses a stable inside-left marker plus fill/text state. |

## UIUX Gate Evidence

- **Surface:** project Theme plus Main Menu, Hero Preparation, Settings modal,
  Card Reward/choice components, and gameplay HUD.
- **Invocation depth:** Level 4 system redesign evidence.
- **Viewports:** `960x540`, `1280x720`, and `1920x1080`.
- **States:** focus, selected, disabled, error, committed, guard/block, boss, and
  shell/in-run modal context.
- **Accessibility:** keyboard focus remains visible without layout shift; primary
  targets remain at least 48 px; English and Korean fit checks pass; state does
  not depend on color alone because the left marker and live text accompany fill.
- **Exception:** a left border property is used only as a reserved four-pixel
  inside marker lane for focus/selection/prompt state. It is not a perimeter
  outline and the lane exists in every state, so bounds remain stable.
- **Remaining warnings:** Milestone 6 still owns measured world presentation and
  Milestone 7 owns integration/export/full-run QA; compact Settings intentionally
  scrolls internally; the
  `1672x941` shell images remain modestly soft at 1920x1080.
- **Result:** passed for the Milestones 1-5 production UI and gameplay HUD scope.

## Automated Evidence

- `PRODUCTION_UI_ASSETS_OK assets=52 backgrounds=5 illustrations=19 shapes=6 icons=22`
- `PRODUCTION_UI_THEME_OK variations=15 buttons=5 panels=4 meters=3 marker=left`
- `SHELL_UI_VALIDATION_OK locales=2 viewports=3 screens=4`
- `HERO_PREPARATION_UI_VALIDATION_OK`
- `CARD_REWARD_VALIDATION_OK ... ui_locales=2 ui_viewports=3 targets=48px`
- `GAMEPLAY_HUD_VALIDATION_OK locales=2 viewports=3`
- Forge, Merchant, Safe Intermission, boss HUD, reward receipt, input-remap, and
  pause-flow focused validators passed after the Theme migration.
- `RUN_RESULT_UI_VALIDATION_OK`
- `PRODUCTION_BOOT_VALIDATION_OK`
- Real OpenGL capture scripts completed for shell, progression, and gameplay HUD
  surfaces; Hero Preparation and reward state captures completed in both locales.

## Findings

- No P0/P1/P2 defect blocks the Milestones 1-2 batch.
- The Theme validator and rendered evidence confirm zero-radius surfaces and no
  top/right/bottom perimeter borders. Remaining local style construction owns
  dynamic flat state only; Milestones 3-5 still own composition migration on the
  surfaces outside this representative spike.
- The `1672x941` shell images are modestly upscaled at 1920x1080. The reviewed HD
  captures remain usable for the MVP, but native-size replacement remains a
  targeted option if later Theme simplification makes softness more visible.
- Detailed art remains at 48px or larger in selection slots and 64px or larger in
  identity slots; smaller semantic use continues to fall back to SVG.
- Forge artwork remains deferred because the live Safe Intermission view provides
  clearer gameplay context than a full-screen workshop background.

## Milestones 3-5 Incremental Evidence

- Shell validation covers Main Menu, Pause, destructive confirmation, shell and
  in-run Settings, victory, defeat, retry, and ended-expedition states in English
  and Korean at `960x540`, `1280x720`, and `1920x1080`.
- Merchant, Forge, transaction, safe-intermission, receipt, Card Reward, Level
  Reward, and production boot gates pass. Forge commands are fully inside the
  detail scroll viewport and the live stage remains visible behind both economy
  overlays.
- `ProductionHUD.gd` no longer constructs its stable Health, Objective, Boss,
  Combat, or Context node trees. These are authored reusable scenes; the script
  owns responsive placement and event/snapshot binding.
- Existing semantic SVGs replace the removed procedural HUD glyph renderer at
  16-32 px. Detailed raster remains reserved for reviewed `64 px+` identity slots.
- Gameplay HUD captures cover low health, interaction, field pickup, five guard
  outcomes, and boss state in both locales. Trial captures cover both locales at
  every supported viewport.
- Real-world captures reviewed:
  `.codex-runtime/uiux/fixed_stage/ruin_route_choice.png`,
  `.codex-runtime/uiux/fixed_stage/sanctum_crypt_recovery_compact.png`, and
  `.codex-runtime/uiux/boss/{desktop_jump_startup,compact_poison_active,hd_summon_startup}.png`.
  Player, landing edges, hazards, boss telegraphs, and the center-safe gap remain
  visible.
- Focused results include `GAMEPLAY_HUD_VALIDATION_OK locales=2 viewports=3`,
  `BOSS_HUD_VALIDATION_OK viewport=960x540`,
  `GUARD_PRODUCTION_PATH_VALIDATION_OK outcomes=9`,
  `ARSENAL_TRIAL_VALIDATION_OK ... ui=960x540,1280x720,1920x1080`, and passing
  feedback/pickup/boot gates.

## Unrun Gates

The full release matrix, production Web export, served-browser path, and complete
run are intentionally not claimed here. They belong to later overhaul milestones
after the remaining surfaces and world presentation change.
