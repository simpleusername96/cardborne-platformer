---
type: spec
status: draft
owner: BK
created: 2026-07-20
scope: Complete manually targeted vehicle-shooter experiment replacing the humanoid proof on this feature branch
source: Owner authorization on 2026-07-20 plus the vehicle-shooter pivot handoff
related:
  - ../../.agent/handoffs/2026-07-21-vehicle-shooter-pivot/README.md
  - ../research/vehicle_led_isometric_action_reference_analysis.md
  - ../design/UI_VISUAL_SYSTEM.md
  - ../../.agent/execplans/2026-07-20-vehicle-stage-one.md
---

# Vehicle Stage One Experimental Specification

## Purpose

Test whether Cardborne is stronger as a manually targeted vehicle action shooter with passive support fire and card-based upgrades. This document governs only the feature branch experiment. It does not rewrite the history of the humanoid proof or make a permanent product decision before owner review.

## Presentation Decision

Stage 1 uses a flat top-down 2D ground plane. The choice deliberately retires fake isometric collision and occlusion from this experiment while retaining the drowned-ruin/flooded-foundry setting, flat color families, simple silhouettes, minimal texture noise, and borderless live UI.

The hover skiff has two readable orientations: the hull follows movement or last travel heading, and the turret/barrel follows direct aim. Projectiles, cursor, cover collision, and target feedback use the same world-space direction.

## Controls

| Intent | Keyboard and mouse | Gamepad |
| --- | --- | --- |
| Move | Arrow keys or WASD | Left stick |
| Aim | Mouse | Right stick |
| Primary fire | Left mouse or Left Shift | Right trigger or right shoulder |
| Dash | Space | South face button |
| Active EMP | `Z` | North face button |
| Passive seeker | Automatic | Automatic |
| Pause/settings | Escape | Menu/Start |

## Vehicle Combat Contract

The vehicle has 120 health and responsive strafe movement. The rapid primary has no ammunition limit. The Repeater favors sustained precision and the Scatter Array favors closer multi-projectile pressure. Every shot produces a muzzle cue, projectile trail, cover hit, target impact, hit response, and generated sound.

The passive Auto Seeker scans eligible nearby targets at a visible cadence, requires line of sight, and fires one support missile without replacing manual priority decisions. Cards can alter its count, cadence, or target preference.

Space dash provides predictable displacement, temporary invulnerability, cooldown feedback, trail and sound. `Ion Wake` gives the dash a damaging trail and `Ram Pulse` gives it an offensive endpoint burst.

`Z` starts an EMP charge cue, then damages and stuns enemies in a large radius while clearing nearby hostile projectiles. Its long cooldown makes timing meaningful. Cards can add an aftershock or link installation destruction to cooldown recovery.

## Authored Stage Structure

Stage 1 is one continuous 5,200 × 2,200 world larger than the viewport:

1. Deployment selects Repeater or Scatter Array.
2. A safe dock teaches movement, aim, fire, and dash.
3. An open yard mixes chasers, mobile shooters, and a controller while the eastern route remains traversable.
4. A flooded installation district presents upper and lower routes, fixed turrets, proximity mines, cover, and two shield/repair generators that are explicit priority targets.
5. The upper branch contains the optional Dredge Warden and a persistent field-module reward; the lower branch is safer and longer.
6. Destroying both generators exposes a relay cache. Opening it safely suspends combat and presents three upgrade cards.
7. The dedicated eastern basin locks only after entry and contains the Foundry Colossus.
8. Boss defeat produces a result screen, persistent Colossus Relay module, and compact garage/loadout surface.

Ordinary living enemies never gate the boss route once both generators and the cache objective are complete. Unreachable or skipped ordinary enemies cannot block progression.

## Enemy and Hazard Roles

- Chaser: tracks, telegraphs, commits to a lunge, then recovers.
- Mobile shooter: maintains range, strafes for line of sight, and fires cover-blocked bolts.
- Controller: samples the player position and creates a temporary denied zone with warning, active, and recovery states.
- Turret: fixed burst installation that rewards early manual targeting.
- Arc mine: proximity startup and close-range detonation with recovery.
- Generator: shields or repairs linked threats and is required stage infrastructure.
- Dredge Warden: optional and escapable elite with fan fire and shock control.
- Foundry Colossus: two-phase stage boss using projectile lanes, a committed charge, repair/zone pylons, stagger windows, and combined second-phase pressure.

Hostile pressure uses a small commit budget so warnings remain attributable. Moving enemies reposition while waiting and attempt alternate movement when obstructed instead of becoming permanently idle.

## Field Pickups

- Repair: immediately restores health.
- Attack boost: temporarily improves primary output.
- Overdrive: increases speed, sharply reduces collision damage, and enables ramming damage.
- Barrier: grants limited absorption/repulsion and clears nearby hostile projectiles.

Pickups apply immediately, never open inventory, and show duration or remaining barrier strength in the HUD.

## Run Upgrades

The relay cache offers three cards from a ten-card pool. Each applies once and resets on replay. The pool changes projectile behavior, passive support, dash offense, EMP behavior, or cross-system triggers: Ricochet Matrix, Phase Lance, Forked Muzzle, Twin Seekers, Hunter Firmware, Ion Wake, Ram Pulse, EMP Aftershock, Circuit Harvest, and Field Converter.

## UI and Persistence

The HUD shows health, objective, boss state and health, selected/aimed target health, primary cadence, passive cadence, dash cooldown, EMP cooldown, active buffs, and a fogged minimap with discovered route objectives, rewards, field boss, and stage boss.

Korean is the deterministic first-run language. Deployment, pause/settings, and garage expose a persistent `한국어 / EN` selector that switches the complete Stage 1 interface immediately without restarting or resetting the run. Missing or unsupported locale preferences fall back to Korean.

The combat safe frame anchors hull state at upper left, one concise objective at upper center, the explored minimap at upper right, a unified action rail at bottom center, and the current target at lower right. During the stage boss, one boss strip replaces the ordinary objective and minimap instead of stacking duplicate information.

Pause retains the live game under a dim layer and provides functional Master/SFX controls through the existing settings store. Deployment, upgrade, pause, result, and garage hide the gameplay HUD while their modal is active. The result and garage allow primary inspection/selection, module review, repair/reset, Stage 1 replay, and settings access.

Persistence is deliberately small: clear count, selected primary, Colossus Relay unlock, and optional Dredge Capacitor unlock. It never creates a repair cost or prevents another run.

## Asset Provenance

No external art, audio, code package, or runtime dependency is adopted. Vehicle, enemy, terrain, UI symbols, effects, and sound waveforms are project-owned Godot geometry/code. Existing project font and UI theme remain repository-owned dependencies. Therefore the third-party adoption ledger requires no new entry.

## Acceptance Criteria

- The complete route reaches result and garage, then replays with clean temporary state.
- Manual aim makes distant fixed installations valuable targets.
- Primary and hostile projectiles stop at ordinary solid cover.
- Passive support respects range and line of sight.
- Dash gives predictable defensive displacement and gains an offensive behavior through a card.
- All four pickup families apply visibly and report state.
- A three-card choice applies exactly once and visibly changes the next encounter.
- Boss entry succeeds with ordinary enemies alive; only the boss basin locks.
- The optional elite can be bypassed or escaped.
- Every boss damage action has startup, active, and recovery, with a second phase that combines learned rules.
- HUD and interactive surfaces fit 960×540, 1280×720, and 1920×1080.
- Korean and English copy fit those viewports; Korean is the default and locale changes persist.
- Every modal hides the gameplay HUD, and the boss strip replaces rather than overlaps the objective and minimap.
- Headless import, focused validators, Web export, native captures, and built-browser boot evidence pass before PR completion.
