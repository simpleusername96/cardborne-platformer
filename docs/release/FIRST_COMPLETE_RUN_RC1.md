---
type: record
status: active
owner: BK
created: 2026-07-12
last_reviewed: 2026-07-12
topic: First complete Cardborne run release candidate
scope: Playable content, verification evidence, and known limitations
source: Completed production roadmap and validated Godot runtime
related:
  - ../product/2d_platform_action_card_game_prd.md
  - ../../.agent/execplans/2026-07-12-actual-game-production-roadmap.md
  - ../data/RUNTIME_CATALOG_INDEX.md
---

# First Complete Run RC1

## Context

The retired integration testbed has been replaced by one production run. This
record identifies what a player can complete, how an operator verifies it, and the
remaining presentation limitation of the first release candidate.

## Decision

RC1 contains one complete run with:

- Warrior, Archer, and Assassin, each with a Basic, Heavy, three active skills,
  passive identity, cards, compatible equipment, and six mastery nodes.
- Three deterministic stages assembled from 30 authored room templates under
  movement, recovery, encounter, and reward constraints.
- Six normal enemy archetypes, exact stage variants, hazards, optional branches,
  stage caches, coins, levels, 15 cards, shops, consumables, and temporary forging.
- `Treasure Instinct` turns an optional chest into an exclusive normal-versus-
  equipment/free-forge choice instead of granting both rewards.
- Persistent loadouts, 12 equipment items, shared materials, safe save recovery,
  and exactly-once terminal settlement.
- An authored Slime Court with four warned patterns, two phases, stagger punish,
  capped adds, player death, victory, Boss Core settlement, and replay.
- Keyboard remapping, fixed gamepad controls, automatic prompts, pause/settings,
  readable production UI, and project-original procedural presentation/audio.

## Player Test Path

1. Run `./tools/godot.ps1 --path .`.
2. Choose **New Run**, select any character and available loadout, then start.
3. Clear Ruin Approach, choose a level upgrade and card, and continue.
4. Clear Flooded Works; use Rest & Forge to weigh healing, a consumable, and a
   deterministic forge choice before continuing.
5. Clear Broken Sanctum, including any optional branch or cache desired, then
   enter Slime Court.
6. Read and punish the Slime King's four telegraphed patterns through both phases.
7. On victory or death, inspect the run summary, persistent rewards, and then use
   **Run Again** or **Main Menu**.

When `Treasure Instinct` appears in a stage card offer, take it and open an
optional-route chest to verify the exclusive reward-choice modal.

## Operator Test Path

```powershell
# Import plus the 24 release-critical integration checks.
.\tools\validate_release_candidate.ps1

# All 75 focused validators. Use before a release handoff.
.\tools\validate_release_candidate.ps1 -Full
```

The accepted RC1 evidence is 75/75 focused validators passing, including 1,000
generated seeds with zero fallbacks, 54 complete-run balance scenarios, all three
characters across generated stages, save recovery, keyboard/gamepad input, boss
victory/death, exactly-once settlement, restart, and catalog reconciliation.
Rendered UI/gameplay inspection passed at 960x540, 1280x720, and 1920x1080,
including the exclusive optional-chest choice and reviewed safe-entry rooms.

## Rationale

The release boundary is a complete decision loop rather than a count of isolated
systems. Every shipped mechanic is reachable from production flow and backed by
typed data, deterministic resolution, focused runtime validation, and final
cross-system matrices.

## Consequences

- This is a playable first-run baseline for owner playtesting and further tuning.
- Procedural vector actors, terrain, effects, and synthesized cues are coherent
  prototype presentation, not final commercial art or recorded audio.
- New content or rule changes must preserve the least-mobile traversal envelope,
  deterministic damage/reward ownership, save safety, and release matrices.
- Future work requires a new scoped plan; the completed production roadmap no
  longer drives implementation.
