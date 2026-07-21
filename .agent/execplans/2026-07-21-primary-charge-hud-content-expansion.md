---
type: plan
status: complete
owner: BK
created: 2026-07-21
topic: Primary charge cycle, combat HUD hierarchy, and future content expansion contract
scope: Vehicle Stage 1 primary-fire behavior, shared typography, bottom action rail, validation, and durable expansion documentation
related:
  - ../../docs/product/vehicle_stage_one_experimental_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../docs/design/vehicle_stage_one_future_directions.md
---

# Primary Charge HUD and Content Expansion ExecPlan

## Why / Context

The current bottom HUD renders four equally weighted ornamental medallions. The primary weapon, passive seeker, dash, and EMP therefore compete for the same attention, while key labels and state text overlap or become too faint in Korean and English. The primary also fires indefinitely while its input is held, so neither the weapon nor the HUD creates a readable attack/rest rhythm.

This pass makes the primary weapon the dominant bottom-rail resource, applies a real variable-font weight instead of relying on nominal font size, and records an implementation-ready boundary for later stages, upgrades, and enemies. It preserves the accepted Sunken Ceramic Fresco palette and the current authored Stage 1 world.

## Scope / Non-scope

In scope:

- replace the four-medallion bottom HUD with one low horizontal combat rail;
- make the primary weapon's remaining burst and recharge progress immediately readable;
- apply medium/bold variable-font weights to shared Stage 1 labels and commands;
- replace unrestricted held primary fire with a finite burst and three-second full recharge;
- require a release-and-press cycle after depletion so holding cannot restart fire automatically;
- add automated gameplay, localization, theme, and HUD-contract checks;
- render Korean and English evidence at 1280x720 and Korean compact evidence at 960x540;
- write a durable, concrete content-expansion spec for stages, enemy roles, and upgrade families.

Out of scope:

- a new stage, enemy implementation, persistent economy, or save migration;
- external art, font, audio, or code dependencies;
- changing the accepted world palette, map geometry, player silhouette, or existing encounter progression;
- replacing mouse aim or the current primary weapon choices.

## Assumptions

- “About three seconds without firing to become fully loaded” means a burst magazine that refills as one full unit three seconds after the most recent shot.
- Repeater uses six rounds and scatter uses three volleys. This preserves their current cadence and identity while ending indefinite fire.
- Holding after depletion may continue charging, but cannot fire after the refill until the player releases and presses again.
- Firing before the magazine is full is allowed when rounds remain; it resets the three-second recharge timer.
- Korean remains the default locale and every new player-facing string receives Korean and English translations.

## Proposed Design

### Primary charge state

The stage owns `rounds`, `capacity`, `recharge_elapsed`, and a trigger-release latch. Every successful shot consumes one round and resets recharge time. If the magazine is not full, it refills to capacity after `3.0s` without a successful shot. Attempting to fire with no rounds locks the trigger until the input is released. Dash continues to suppress firing.

The HUD snapshot exposes capacity, rounds, recharge ratio, and a localized state. Validation calls a focused debug contract instead of synthesizing input events.

### Bottom combat rail

The rail is a centered, low ceramic band rather than four framed icons:

- the primary cell owns roughly forty percent of the width and shows binding, weapon name, segmented rounds, and recharge/full state;
- the passive seeker, dash, and EMP use compact cells with one binding, one title, and one precise state/cooldown bar;
- color remains semantic and restrained: mustard for primary, moss for passive, cyan for dash, violet for EMP;
- buffs sit above the rail and do not compete inside it;
- the rail fits 960x540 without clipping or overlapping the lower-right target panel.

### Typography

The repository Noto Sans KR variable font remains the only type asset. The scoped theme uses a medium body variation (`wght` 600) and a bold command variation (`wght` 700). Label size may remain compact where necessary, but no Stage 1 label relies on thin outlines or low-opacity text.

### Future content contract

A new draft product spec defines:

- the authored stage template and route/encounter/reward cadence;
- enemy role budgets, telegraph and counter requirements, and coordination rules;
- behavior-changing upgrade families and offer constraints;
- concrete Stage 2 and Stage 3 candidates as examples, not committed production scope;
- data ownership, asset needs, validation, and acceptance gates before implementation.

## Milestones

- [x] **1. Implement and validate the primary charge cycle.**
  - Add magazine/recharge/latch state and reset behavior.
  - Expose precise localized HUD state and a focused debug contract.
  - Add validator assertions for capacity, depletion, three-second recharge, and release-to-refire.

- [x] **2. Rebuild the bottom HUD and typography.**
  - Replace `ActionMedallion` with a responsibility-shaped action-rail cell.
  - Make primary rounds/recharge visually dominant and compact the other actions.
  - Apply real variable-font weights and update the UI debug contract.
  - Verify Korean and English copy, clipping, contrast, and 960/1280 layout.

- [x] **3. Record future content architecture.**
  - Add a lifecycle-stamped draft expansion spec.
  - Update the active Stage 1 and UI contracts for charge fire and the revised rail.
  - Keep speculative themes separate from accepted implementation scope.

- [x] **4. Verify and hand off.**
  - Run Stage 1 and settings validators, Web export/build, and production-style boot.
  - Capture 1280x720 Korean/English and 960x540 Korean gameplay evidence.
  - Run a task-scoped quality audit, make only safe adjacent corrections, update this plan truthfully, and create one scoped commit.

## Test Plan

- `./tools/godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_one.gd`
- `./tools/godot.ps1 --path . --headless --script res://tools/validation/validate_pivot_settings.gd`
- `./tools/godot.ps1 --headless --path . --export-release Web build/web/index.html`
- built-app boot through the repository Godot wrapper with the Web export present;
- native captures for Korean and English gameplay at 1280x720 and Korean gameplay at 960x540;
- visual checks: no cropped text, no thin Korean labels, primary charge legible without reading all four cells, no target-panel overlap, and stable hierarchy at both supported widths;
- `git diff --check`, explicit staged-file audit, and a scoped commit that excludes pre-existing `.import` churn.

## Rollback / Safety

The gameplay state is run-local and does not change the save schema. Reverting the stage, UI, theme, localization, validator, and contract changes restores the previous behavior. No external dependency or asset adoption is involved. Existing user-owned `.import` changes remain untouched and unstaged.

## Risks

- A three-second refill can feel slow if six repeater rounds do not create enough meaningful uptime. Keep capacity and recharge as named constants for tuning.
- Applying one bold weight everywhere can reduce hierarchy. Use medium for body copy and bold for commands/critical state.
- Custom-drawn text can ignore type variations if it does not inherit the scoped default font. Rendered captures must verify the actual result.
- The future-content spec can accidentally look like approved implementation scope. It remains `draft` and explicitly marks examples versus requirements.

## Open Questions

- Playtesting may later change capacities or recharge duration, but the finite-burst/release-latch contract remains the accepted direction for this pass.
- Stage 2/3 theme choices and production order remain owner decisions after the Stage 1 loop is played.

## Decision Notes

- 2026-07-21: Replaced continuous-fire intent with a magazine-like charge cycle because it gives the requested three-second rest window a precise gameplay and HUD representation.
- 2026-07-21: Kept both current primaries, using six repeater rounds and three scatter volleys, rather than introducing a new weapon schema.
- 2026-07-21: Chose a low horizontal rail over another icon sheet or panel texture; exact charge/cooldown data is better owned by live Godot controls and drawing.
- 2026-07-21: New stages, enemies, and upgrades are documented but not implemented in this pass.
- 2026-07-21: Render review showed that the variable weight axis alone remained visually thin, so the scoped font variations also use controlled emboldening. The second capture confirmed materially stronger Korean and English text without clipping.
- 2026-07-21: Final validation passed 113 Stage 1 checks, settings/localization checks, Web release export, and 27 native captures. Built Web artifacts returned HTTP 200 on the registered Codex port; interactive in-app browser boot could not be claimed because the browser runtime's local kernel-asset path was unavailable.
