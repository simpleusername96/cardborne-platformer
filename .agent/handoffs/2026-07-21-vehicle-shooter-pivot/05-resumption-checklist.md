---
type: handoff
status: active
owner: BK
created: 2026-07-21
expires: 2026-08-21
source: Synthesis of current repository state and unresolved owner decisions
related:
  - ./README.md
  - ./02-current-repository-state.md
  - ./03-latest-product-hypothesis.md
---

# Resumption Checklist

## Current State

The repository has a playable humanoid isometric proof, while the newest product
discussion proposes a different vehicle shooter. This checklist is a handoff
gate, not an implementation plan. It prevents another broad build before the
product contract is accepted.

## Next Steps

### Consume and reconcile

- [ ] Read all five files in this handoff folder.
- [ ] Inspect the running humanoid proof only to identify reusable infrastructure;
      do not use it as evidence that the vehicle controls are fun.
- [ ] Present the latest vehicle hypothesis to the owner in concise Korean and
      explicitly label recommendations versus owner-confirmed requirements.

### Obtain the four material product decisions

- [ ] Perspective: hybrid isometric ground-plane presentation or flat top-down 2D.
- [ ] Aim/input: mouse/right-stick direct aim, keyboard target selection, or both.
- [ ] Base: functional garage screen for the proof or a traversable base map.
- [ ] Survival model: dash only, dash plus automatic barrier/resource, or a second
      explicit defense verb. A held humanoid guard is not a default.

### Promote accepted direction

- [ ] If the owner accepts the vehicle direction, create a replacement product
      spec with lifecycle metadata and explicit acceptance criteria.
- [ ] Explicitly supersede the humanoid proof spec/policy/plan only with owner
      approval; do not rewrite their history in place.
- [ ] Create a decision-complete ExecPlan for one graybox stage after the product
      choices are locked and current source owners/validators are inspected.

### First proof boundary after acceptance

- [ ] One vehicle with readable hull and weapon direction.
- [ ] Direct rapid primary fire and one meaningfully different alternate primary.
- [ ] One passive secondary, Space dash, and one `Z` area skill.
- [ ] One open arena and one installation-focused arena in a continuous field.
- [ ] Chaser, mobile shooter, controller, and one fixed turret/installation.
- [ ] One temporary field pickup from each essential family: repair, overdrive,
      attack boost, and barrier/repulsion.
- [ ] One three-card chest choice that changes the next encounter visibly.
- [ ] One optional field boss and one dedicated stage boss.
- [ ] Minimal HUD for health, dash, primary, passive secondary, `Z` cooldown,
      target, enemy HP, pickup state, and boss state.

### Evidence gate before expansion

- [ ] Movement remains enjoyable for sixty seconds without enemies or rewards.
- [ ] Manual aim makes distant dangerous installations worth prioritizing.
- [ ] The two primaries produce different preferred ranges or routes.
- [ ] Dash has a predictable evasive and/or offensive use.
- [ ] Ordinary projectiles obey cover and every damaging attack has readable
      startup, active, and recovery phases.
- [ ] The first card choice visibly changes behavior in the next encounter.
- [ ] A player can explain why damage occurred and voluntarily retry.

Do not add broad exploration puzzles, crafting, merchant breadth, a permanent
skill tree, multiple vehicles, procedural maps, story content, or a large base
until the evidence gate passes.

## Risks

- The four product choices above can materially change controls, assets, map
  metrics, camera, UI, and reuse boundaries. They cannot be deferred into an
  implementation plan.
- A vehicle reskin of `Traveler3D` would preserve the wrong melee/guard/potion
  assumptions.
- A Vampire Survivors-like enemy count without target-priority installations
  would erase the intended manual-targeting distinction.
- A broad garage or progression system could mask weak core shooting rather than
  improve it.

## Files Touched

No runtime files are touched by this checklist.

## Verification

This checklist is consumed when the four decisions are recorded in an accepted
replacement spec or the owner rejects the vehicle direction. Mark this handoff
folder `done` or archive it after that transition.
