---
type: evidence
status: active
owner: BK
created: 2026-07-16
last_reviewed: 2026-07-16
topic: Milestones 1-7 production UI, gameplay HUD, measured world-proof, integration, and Web-export QA
source: Owner-selected UI references, active visual spec, production asset catalog, Godot 4.7 validators, deterministic OpenGL captures, final full release matrix, and served production Web build
related:
  - ./.agent/execplans/2026-07-15-master-ui-overhaul.md
  - ./docs/design/UI_VISUAL_SYSTEM.md
  - ./docs/design/visuals/player_experience_ui_concept.png
  - ./docs/design/reports/ui-raster-asset-catalog.png
---

# Production UI Milestones 1-7 Final Design QA

## Purpose

Record the final rendered-acceptance evidence for Milestones 1 through 7 of the
master UI overhaul: centralized production asset ownership, real-screen image
placements, the shared flat Theme/component foundation, all shell and economy
surfaces, the gameplay HUD/Trial migration, and one measured Flooded Works world
proof, followed by latest-baseline integration, full validation, production Web
export, and served-browser checks.

## Sources

- Owner-selected composition and visual-language references under `docs/design/`.
- The production asset catalog and manifest under `art/ui/production/`.
- Final integrated Godot scenes, UI scripts, focused validators, deterministic
  OpenGL captures, full release output, and the served production Web build.

## Result

**Passed for Milestones 1-7.** This result approves the UI asset registry, shell,
dense progression/economy surfaces, shared flat Theme/components, gameplay HUD,
feedback presentation, Arsenal Trial UI, and the bounded Flooded Works panorama,
terrain, and state-overlay proof. The integrated source passed all 77 release
checks, production Web export, and the served-browser rendering/input path. No
implementation or acceptance task remains in the UI overhaul plan.

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
- Runtime-derived stage panorama coverage, current-location lazy loading, two
  connected Flooded Works panels, five representative-room terrain types, and
  poison-vent/crumbling-platform canonical bases with separate state overlays.

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
- `tools/component_gallery/assets/flooded-poison-{baseline,proof,debug}.png`
- `.codex-runtime/uiux/component-gallery.png`
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
| Flooded Works room proof | Procedural baseline, production composite, collision debug, vent states, crumbling-platform states | Panorama seams remain visually quiet; five exact terrain signatures preserve collision; state overlays retain one body and pivot. |

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
- **Remaining warnings:** compact Settings intentionally scrolls internally; the
  `1672x941` shell images remain modestly soft at 1920x1080. Both are accepted MVP
  constraints rather than unfinished tasks in this plan.
- **Result:** passed for the complete Milestones 1-7 production UI, gameplay HUD,
  representative world-proof, integration, and Web-export scope.

## Automated Evidence

- `PRODUCTION_UI_ASSETS_OK assets=52 backgrounds=5 illustrations=19 shapes=6 icons=22`
- `PRODUCTION_UI_THEME_OK variations=15 buttons=5 panels=4 meters=3 marker=left font=ko-en`
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
- `STAGE_VISUAL_COVERAGE_OK stages=6 panels=11`
- `STAGE_VISUAL_RENDERER_VALIDATION_OK catalog=6 flooded_loaded=2 lazy=true`
- `FLOODED_TERRAIN_INVENTORY_OK representative_types=5`
- `FLOODED_WORLD_VISUAL_PROOF_OK panels=2 terrain_types=5 state_bases=2 memory_mib=24`
- `FLOODED_WORLD_ASSET_MANIFEST_OK runtime_png=15 terrain=5 components=2`
- Stage renderer, terrain presentation, hazard catalog/runtime, room composition,
  stage composition, production stage, and curated-stage-plan validators pass.
- `RELEASE_CANDIDATE_MATRIX_OK checks=77 full=True seconds=634.6`
- `WEB_EXPORT_OK`; the final served build returned HTTP 200 for all observed
  resources and produced no browser console warning or error.

## Findings

- No P0/P1/P2 defect blocks the completed Milestones 1-7 scope.
- The Theme validator and rendered evidence confirm zero-radius surfaces and no
  top/right/bottom perimeter borders. Remaining local style construction owns
  dynamic flat state only; the stable shell, progression, modal, and HUD
  composition migration is complete.
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

## Milestone 6 World-Proof Evidence

- The coverage report derives panel counts from actual assembly/world bounds,
  supported viewport envelope, 192 px horizontal and 128 px vertical overscan,
  `2048x1536` final panels, 192 px overlap, and `scroll_scale = 0.18`.
- The current six-location manifest totals eleven panels: Ruin 2, Flooded 2,
  Sanctum 3, Trial 2, Safe Intermission 1, and Slime Court 1. Only the current
  location is loaded; Flooded uses 24 MiB raw RGBA versus 132 MiB for all panels.
- Sequential Flooded source panels were normalized to exact runtime dimensions.
  Their shared overlap has a measured exit mismatch of `0.001812`, and the real
  camera proof shows no distracting seam.
- The representative poison room inventory contains five unique terrain types
  over six surface instances. The room skin maps only those exact signatures and
  leaves authored collision geometry untouched.
- Poison vent and crumbling platform each retain one raster base while warning,
  active/disabled, cooldown/respawning states are separate overlays. Runtime
  snapshots confirm invariant base texture, local position, pivot, and public
  collision/timing behavior.
- The rebuilt component gallery uses the actual production panels, terrain,
  component states, measured coverage data, and real-room proof images. Browser
  review at desktop and compact sizes found no console error, accidental document
  horizontal overflow, or broken state/seam/debug control.

## Milestone 7 Final Gate Evidence

- The latest functional/fixed-stage baseline and scoped UI/world commits were
  integrated without replacing newer gameplay or geometry wholesale.
- The integrated source passed every focused UI/input/reward/intermission/retry/
  HUD/boss/result gate and the full `77/77` release matrix.
- The exact Godot 4.7 production Web export completed and the built app passed
  served-browser boot, KO/EN glyph rendering, language persistence, remap and
  restoration, pointer interaction, stage launch, pause/resume, and live Canvas
  movement/jump/attack with no console warning or error.
- Two browser-control attempts could not provide a sustained unattended key hold
  for a complete three-stage clear. Per the ExecPlan rerun policy, deterministic
  production-stage, reward, intermission, retry/end, boss, settlement, complete-
  run, and rendered-capture gates provide that full-path evidence. This report
  does not mislabel the split evidence as one automated browser speedrun.
- Final KO/EN progression, shell, HUD, boss, and fixed-stage captures at
  `960x540`, `1280x720`, and `1920x1080` show no required-text clipping, focus
  loss, modal context break, or center-playfield obstruction.

The served build initially exposed missing Korean host-font fallback. Bundling
the reviewed Noto Sans KR Variable TTF under OFL-1.1 fixed the Web glyph failure;
the Theme validator now checks the bundled path and representative Korean and
English glyphs. The font's exact upstream revision, hash, license, and local
files are recorded in the third-party adoption ledger.
