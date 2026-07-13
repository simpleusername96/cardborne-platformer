---
type: plan
status: done
owner: BK
created: 2026-07-13
last_reviewed: 2026-07-13
topic: Character attack readability and interactive reward clarity
scope: Player attack footprint presentation and direct reward-source feedback
source: Owner feedback on 2026-07-13 and current production runtime evidence
related:
  - ../../docs/design/PLAYER_CHARACTER_SYSTEMS.md
  - ../../docs/design/PLAYER_FACING_FLOW.md
  - ../../docs/design/PROGRESSION_EQUIPMENT_ECONOMY.md
  - ../../docs/product/2d_platform_action_card_game_prd.md
---

# Combat Feedback And Reward Clarity Plan

## Why / Context

Character attacks have distinct data and runtime behavior, but their visible motion
uses a shared forward polygon whose bounds do not match the actual hit footprint.
Assassin runtime attacks additionally compare enemy origin points against an
expanded box, so visual overlap and hit confirmation can disagree in both
directions. Direct reward sources settle correctly, but normal chest and material
claims only change totals and source color; no UI identifies what was received.

The goal is to make attack commitment readable without exposing debug geometry and
to make every deliberate reward interaction produce an exact, concise receipt.

## Scope / Non-Scope

### In scope

- Warrior, Archer, and Assassin basic/heavy motion differentiation.
- One shared attack-footprint contract for generic and runtime-owned melee hits.
- Active-frame contact silhouettes derived from actual attack data.
- Projectile visuals constrained to their collision footprint.
- Non-modal receipts for chest, optional-route, route-choice, material, and generic
  interactive reward sources.
- Receipt coverage for currencies, materials, new equipment, duplicate salvage,
  Treasure equipment replacement, and Treasure forge replacement.
- Focused runtime tests plus compact, desktop, and HD rendered evidence.

### Non-scope

- Rebalancing damage, cooldown, stagger, projectile distance, or movement stats.
- Final sprite animation, skeletal animation, particles, or external assets.
- Reward popups for enemy kills, encounter clear, stage clear, or boss settlement.
- Replacing the existing modal level, card, forge, or Treasure choice flows.

## Domain Alignment

- **Attack footprint**: the local collision region that can confirm a hit at one
  instant. `AttackDefinition.hitbox_size` and `hitbox_offset` own it.
- **Attack motion**: the character-specific visual path communicating startup,
  active direction, and recovery. It may be expressive but cannot imply reach
  outside the attack footprint during active frames.
- **Swept attack**: repeated footprint checks while the player moves, such as
  Shadow Lunge. The path comes from runtime movement; each instantaneous footprint
  stays definition-owned.
- **Interactive reward receipt**: a non-modal summary emitted only after a direct
  world reward source settles successfully.
- **Treasure choice**: the existing exclusive pre-settlement modal. Its selected
  result still produces one receipt after commitment.

Ownership boundaries:

- `PlayerCombatController` owns shared hit geometry and target-overlap queries.
- Character runtimes own sequence and swept-movement timing, not alternate range
  definitions.
- `PlayerAttackPresenter` owns visual shape/timing derived from the attack contract.
- `StageRewardInteractable` owns publication of a settled interactive receipt.
- Production HUD owns receipt layout, queuing, timing, and responsive placement.
- Reward settlement remains owned by `RunState` and `RewardService`.

## Scenario And Decision Notes

| Concern | Rejected option | Selected option | Reason |
| --- | --- | --- | --- |
| Melee range | Always show a debug rectangle | Stylized motion plus a subtle exact active footprint | Preserves game feel while making contact honest. |
| Motion only | Keep independent polygons | Bound every active polygon to footprint dimensions | Current mismatch is the reported defect. |
| Assassin targeting | Keep enemy-origin point tests with padding | Intersect attack footprint with target Hurtbox bounds | Matches shared Area2D semantics and removes hidden padding. |
| Archer range | Draw an 800-1000 px aim line | Use a bounded bow release and collision-sized projectile | Full range lines add noise and imply off-screen certainty. |
| Reward feedback | Modal after every pickup | Queue a short non-modal receipt | Normal play continues and rapid claims remain legible. |
| Reward event | Listen to every `reward_applied` event | Publish only settled world-interaction receipts | Enemy and stage rewards would otherwise spam the HUD. |
| Treasure result | Keep only the pre-choice modal | Retain modal and add post-commit receipt | Selection and acquisition are separate user questions. |

## Current-State Evidence And Delta

### Attack feedback

- **As-is:** `PlayerAttackPresenter.begin()` receives the hitbox center but creates
  polygons extending mostly forward by the full width, effectively shifting reach.
- **To-be:** all active contact visuals are centered on the hitbox origin and remain
  inside `hitbox_size`; motion styles retain distinct silhouettes and transforms.
- **Accept:** tests compare contact visual bounds and hitbox bounds for both facing
  directions across all three profiles' basic and heavy attacks.

- **As-is:** Assassin Twin Cut and Shadow Lunge query enemy origin points with an
  extra 28 px vertical half-extent.
- **To-be:** runtime-owned melee queries intersect the same attack rectangle with
  authored Hurtbox bounds; Twin Cut publishes both committed visual pulses and
  Shadow Lunge sweeps that footprint over its existing 150 px path.
- **Accept:** targets whose Hurtbox overlaps the footprint are hit; targets outside
  it are not, including edge and facing-direction fixtures.

- **As-is:** `wide_slash`, `quick_slash`, and `shadow_lunge` collapse to one default
  polygon; projectile arrowheads exceed their collision shape.
- **To-be:** Warrior Cleave, Warrior Breaker, Assassin Twin Cut, Assassin Shadow
  Lunge, and Archer bow release have distinct bounded motion signatures; projectile
  visuals stay inside their collision footprint.
- **Accept:** presentation snapshots report distinct style/signature pairs and no
  visual footprint exceeds collision bounds.

### Reward interaction

- **As-is:** `StageRewardInteractable` stores a complete settlement context and emits
  only a local `claimed` signal with no production consumer.
- **To-be:** successful world claims publish one sanitized interactive-reward event
  after settlement; replay/duplicate calls publish nothing.
- **Accept:** normal, optional, replacement, material, and duplicate fixtures each
  publish exactly one receipt context.

- **As-is:** Production HUD updates aggregate totals but does not identify claim
  contents.
- **To-be:** a bottom-center receipt queues exact grants and discovery outcomes,
  stays clear of the interaction prompt, and expires without blocking input.
- **Accept:** 960x540, 1280x720, and 1920x1080 captures show no clipping or overlap;
  gameplay and focus remain active.

## Milestones

### Batch 1 - Shared attack footprint and class motion

- [x] Replace point-only runtime target checks with Hurtbox-bounds intersection.
- [x] Remove Assassin's hidden vertical query padding.
- [x] Add runtime pulse notification for committed Twin Cut hits.
- [x] Rework attack presenter into bounded contact and character motion layers.
- [x] Bound projectile art to collision dimensions.
- [x] Extend player attack motion and Assassin runtime validators.

Quick gate:

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validate_player_attack_motion.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_assassin_combat_runtime.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_warrior_combat_runtime.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_archer_combat_runtime.gd
```

### Batch 2 - Interactive reward receipt

- [x] Publish one global receipt event from successful interactive settlement.
- [x] Include committed Treasure replacement identity without leaking catalogs.
- [x] Add a responsibility-shaped receipt presenter with queue and timeout.
- [x] Format currencies, materials, equipment discovery, duplicate salvage, and
  forge replacement using catalog display names.
- [x] Add open-state chest presentation and preserve interaction idempotency.
- [x] Extend reward-source, Treasure, HUD, and screenshot fixtures.

Quick gate:

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validate_reward_source_runtime.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_remaining_cards_runtime.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_production_boot.gd
```

### Batch 3 - Integration and evidence

- [x] Render combat and reward states at compact, desktop, and HD viewports.
- [x] Inspect attack direction, active footprint, receipt text fit, queue behavior,
  interaction prompt clearance, and Treasure modal transition.
- [x] Run code quality and comment review on touched files.
- [x] Run Godot import, production stage validation, and release matrix.
- [x] Mark this plan done and commit the scoped implementation.

## Test Plan

Inner loop uses only the focused validators listed per batch. Production stage and
rendered captures run after both visible slices integrate. The 25-check release
matrix runs once before handoff. A failed slow gate is rerun only after the suspected
cause changes.

Manual scenarios:

1. Warrior Cleave and Breaker facing left/right.
2. Archer Quick Shot and charged Power Shot projectile release.
3. Assassin tap Twin Cut, held Twin Cut, and Shadow Lunge through an edge target.
4. Normal chest with currencies/materials.
5. Cache with unseen equipment and duplicate salvage.
6. Treasure normal, equipment replacement, and forge replacement choices.
7. Two receipts arriving before the first expires.
8. Compact viewport with interaction prompt visible immediately before claim.

## Rollback / Safety

- No save schema, content ID, reward table, or attack balance value changes.
- Keep the local `claimed` signal for existing fixtures and future source-local use.
- If Hurtbox bounds cannot be resolved, target queries fall back to the target origin
  rather than rejecting the target.
- If receipt formatting lacks a catalog definition, show a capitalized stable ID.
- Receipt UI failure must not roll back or duplicate an already settled transaction.

## Risks

- AABB conversion can conservatively include rotated Hurtboxes; current production
  Hurtboxes are axis-aligned rectangles.
- Exact Assassin overlap can change edge hits that depended on hidden origin padding;
  focused edge fixtures define the intended replacement behavior.
- Receipt text can grow with multi-material salvage; formatter must cap line count and
  use concise separators.

## Open Questions

None blocking. Final visual tuning may adjust alpha, duration, and bounded polygon
shape without changing footprint, settlement, or balance contracts.

## Success And Stop Conditions

Complete only when all checklist items are done, focused validators and the release
matrix pass, three viewport sizes are visually inspected, and the user can identify
both where an attack can connect and what a direct reward interaction granted.

Stop and ask only if implementation requires changing attack balance values, reward
tables, save data, or adding external assets/dependencies.
