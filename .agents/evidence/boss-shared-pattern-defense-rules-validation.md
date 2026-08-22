---
type: evidence
status: done
created: 2026-08-22
scope: Shared boss-pattern progression, rapid attack commitment, Stage 6 proximity ordnance, segmented defenses, and Stage 7/9 wall tuning
related:
  - ../completed-plans/2026-08-22-boss-shared-pattern-defense-rules.md
  - ../../scripts/bosses/vehicle_boss_progression_catalog.gd
  - ../../scripts/bosses/vehicle_boss_shield_runtime.gd
  - ../../scripts/combat/vehicle_projectile_state.gd
---

# Shared Boss Pattern and Defense Validation Evidence

## Verified implementation

- Stage 1 resolves four direct common attacks plus the periodic squad call.
- Stage 2 and every later boss resolve the complete six-attack direct common pool.
- Common and signature pattern IDs are independently queryable.
- Live attack selection uses two common attacks before an available signature attack.
- Squad calls use a ten-second timer and the current phase packet instead of an immediate health-threshold add wave.
- Projectile volleys commit after at most `0.18 s`, broad barrages and Stage 6 long banks after at most `0.22 s`, and charges after at most `0.28 s`.
- Beam, radial, crossing-wall, radial-volley, and compression warnings retain their authored longer startup.
- Stage 6 projectiles start at normal speed, size, and damage; grow after travel; arm at `720` world units; and use one proximity-or-contact retirement path.
- Stage 3 keeps its existing segmented absorption values and complete down window.
- Stage 10 uses body-attached segmented reflection with attackable gaps, a one-second cue, five seconds active, and fifteen seconds fully down.
- Stage 7 crossing-wall speed and damage and Stage 9 compression-wall speed and damage are each multiplied by `0.70`.
- All twelve boss health, ordinary movement, and attack-movement profile values remain unchanged.

## Completed gates

The branch-specific verification workflow completed all of the following before this evidence record was committed:

- document authority validation;
- canonical Cardborne visual-authority validation;
- Godot 4.7.1 headless import;
- every production `validate_*.gd` contract except the repository's explicitly excluded manual/performance drivers;
- native `1280x720` rendered capture;
- Web release export;
- built-Web HTTP and headless-browser boot;
- `git diff --check`.

The one-shot migration and verification workflows were removed after the gate passed. This permanent record and the archived ExecPlan are the retained evidence owners.
