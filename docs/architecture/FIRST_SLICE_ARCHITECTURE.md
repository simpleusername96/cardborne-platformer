---
type: spec
status: active
canonical_for: first-slice architecture before implementation
source: docs/product/FIRST_SLICE_EXPANSION.md
scope: Godot 4.x GDScript first playable slice
---

# First Slice Architecture

## Purpose

Describe the ownership boundaries that should shape the first implementation after the expanded data and design docs are accepted. The goal is to keep RPG-lite systems modular without building a large abstract framework before the game is playable.

## Scope

This is a preimplementation architecture guide for the first slice. It covers the major domains and the contracts they should expose. Concrete GDScript class names may change during implementation if Godot scene constraints make another shape cleaner.

## Domain Brief

- Request interpretation: expand the first version from a card-only platformer loop into a 2D action-platform RPG-lite loop with drops, economy, player build systems, map data, and encounter guides.
- Likely bounded contexts: run flow, player build, reward economy, authored stages, encounter actors, and UI feedback.
- Ambiguous terms resolved: money means run-local coin; budget should not become a separate currency unless a shop system needs a planning limit; material means named crafting/upgrade resource, not generic loot flavor; item means a collectible object, while equipment means something that occupies a slot.
- Ownership boundaries: run state owns temporary growth; economy owns drop/reward calculation; player build owns stats, skills, and equipment; stage systems own map progression; enemies/traps own damage sources and drops; UI observes signals and renders state.
- Public interfaces: use domain-language functions such as `grant_xp`, `add_coin`, `add_material`, `apply_card`, `equip_item`, `complete_stage`, and `spawn_drop`.
- Hidden implementation decisions: exact Godot node shapes, resource file format, save path, RNG implementation, and UI widget layout should stay behind their owning systems.
- Invariants: rewards cannot apply twice; stage clear cannot soft-lock behind an uncollectable drop; damage sources must be telegraphed when they are boss or trap patterns; currencies must be distinguishable in state and UI.
- State transitions: run start -> stage active -> reward/shop/level-up pause -> next stage -> boss -> clear/death.
- Open questions: whether materials persist in the first playable build or only in debug/profile scaffolding; whether level-up rewards reuse cards or use a separate micro-upgrade pool.
- Is this simple CRUD?: no. The feature set touches gameplay state, reward economy, run transitions, player build rules, and authored encounter design.

## Requirements

### Contexts

**Run Flow**

Owns high-level state transitions:

- Main menu.
- New run.
- Stage loading.
- Stage clear.
- Reward selection.
- Optional shop/rest point.
- Boss stage.
- Death.
- Prototype clear.

It should expose narrow commands such as `start_new_run`, `load_stage`, `clear_stage`, `enter_reward`, `enter_shop`, `enter_boss`, `end_run_death`, and `end_run_clear`.

**Run State**

Owns run-local facts:

- Current stage index.
- Current health and max health snapshot.
- Current run level and XP.
- Current coins.
- Current run materials if persistence is not implemented yet.
- Owned cards for this run.
- Temporary equipment and stat modifiers.
- RNG seed.

It should hide the storage structure from UI and stage scripts.

**Reward Economy**

Owns reward calculations:

- Drop table lookup.
- XP grants.
- Coin grants.
- Material grants.
- Chest rewards.
- Stage clear rewards.
- Boss rewards.
- Shop price calculation.

It should not directly move the player, open UI panels, or know map geometry.

**Player Build**

Owns player capability and build state:

- Base stats.
- Effective stats after cards, level-up perks, skills, and equipment.
- Movement and combat verbs unlocked.
- Equipment slots.
- Skill node unlock state.

It should expose effective values to player movement/combat while hiding how each source stacked.

**Authored Stage and Map**

Owns stage layout and progression objects:

- Spawn points.
- Exit portals.
- Camera bounds.
- Enemy placements.
- Trap placements.
- Gimmick placements.
- Chests and reward nodes.
- Optional map preview metadata.

Stage code should not hard-code economic values; it should reference reward source IDs or drop table IDs.

**Encounter Actors**

Own enemy, boss, projectile, trap, and hazard behavior:

- Health and damage.
- Telegraph/startup/active/recovery windows where needed.
- Death events.
- Drop source IDs.
- Contact damage and hitbox timing.

They emit combat and defeat events rather than directly editing UI.

**UI Feedback**

Owns presentation:

- HUD.
- XP bar.
- Coin/material counters.
- Health display.
- Card reward screen.
- Level-up reward screen.
- Equipment/skill tree surfaces.
- Boss health bar.

UI observes signals and calls narrow commands; it should not own gameplay rules.

## Information Hiding

- Player movement should depend on effective stats, not on card IDs, equipment IDs, or skill node IDs.
- Reward screens should display reward data but call economy/build services to apply effects.
- Enemies should declare a drop source ID rather than embedding coin/material quantities in AI code.
- Stages should place enemy and reward source IDs, not duplicate drop tables.
- Map preview tooling should consume design data and never become required for runtime scene loading unless the implementation explicitly promotes it.

## First Implementation Shape

The existing PRD folder split remains appropriate:

- `scripts/autoload/` for global orchestration and run state.
- `scripts/player/` for movement, combat, stats, and build adapters.
- `scripts/combat/` for damage events, hitboxes, and hurtboxes.
- `scripts/enemies/` for common enemy behavior and enemy types.
- `scripts/bosses/` for boss attack states and telegraphs.
- `scripts/cards/` for card data and effect application.
- `scripts/stages/` for stage flow, exit portals, hazards, and reward triggers.
- `scripts/ui/` for HUD, reward, skill, equipment, and menu UI.
- `data/cards/` for Godot card resources once implementation starts.
- `data/design/first_slice/` for preimplementation design seed data.

## Acceptance Criteria

- Future code can add economy and progression without placing reward logic inside UI or player movement.
- Player stats can be modified by cards, level-ups, skills, and equipment through one effective-stat path.
- Enemy/trap/boss damage sources can all produce `DamageInfo` or equivalent combat events.
- Drop and reward definitions can be tuned without editing enemy AI scripts.
- Stage layouts can be documented visually before Godot scenes are complete.

## Related

- `docs/product/FIRST_SLICE_EXPANSION.md`
- `docs/data/FIRST_SLICE_DATA_README.md`
- `data/design/first_slice/economy_tables.json`
- `data/design/first_slice/player_progression.json`
