---
type: plan
status: complete
owner: BK
created: 2026-08-07
last_reviewed: 2026-08-07
topic: Combat readability feedback and reinforcement facility
scope: Projectile and actor scale, combat feedback removal, exclusive elements, upgrade and EMP HUD layout, enemy rewards and balance, reinforcement facility, and final-run completion
related:
  - ../../AGENTS.md
  - ../PLANS.md
  - ../design/DESIGN.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/product/vehicle_upgrade_catalog.md
---

# Combat Feedback and Reinforcement Facility - Execution Contract

This plan applies the 2026-08-07 gameplay feedback in low-coupling order, then adds one
bounded reinforcement facility without merging it into enemy AI, ordinary defeat quota,
or boss progression. It is complete when every checkbox is checked, focused validators
and the Web export pass, the final-stage no-offer path reaches the result screen, and
rendered Korean/English UI evidence has no clipping at the supported viewports.

## Locked decisions

- Player craft visual radius becomes 70% of its current value; collision truth is unchanged.
- Projectile visuals use 70% length and 50% thickness. Player primary, player seeker,
  and hostile shots use separate semantic assets/batches; collision truth is unchanged.
- The existing approved `secondary/seeker` raster becomes the runtime seeker identity.
  No other projectile family may consume it. New hostile-projectile and facility rasters
  require the canonical style sheet as an actual ImageGen reference and visual-authority
  review before production promotion. SVG geometry is not permitted by project policy.
- Mine and orbit-blade visuals become 200% of current size; XP visuals become 70%.
- Enemy/player elemental actor tints, attacked-enemy target brackets and yellow priority
  markers, floating damage text, and charge-route lines are removed. Charge endpoints
  remain. All hostile circular bombardment telegraphs use the danger-coral family.
- Upgrade cards use a centered vertical hierarchy: category/title, artwork, level,
  compact unlock icon, then stat deltas. Visible change-kind and description prose is
  removed; descriptive text remains available to assistive metadata.
- The action rail becomes one panel-free, 88 px round EMP cooldown/ready indicator.
- Thermal, toxin, and cryo are mutually exclusive. Before selection all three may be
  offered; after selection only the chosen element can reappear. Player primary color
  follows the selected element.
- Every defeated hostile except boss objective pylons drops its bounded health-class XP,
  including EMP kills and summoned/reinforcement units. Summons remain outside quota.
- Non-boss enemy health is multiplied by 1.30 after existing stage/role scaling. Generator
  and repair-tender healing is multiplied by 2.0. Boss health is unchanged.
- One `reinforcement_fabricator` world facility may appear per stage after 35% of the
  ordinary quota is defeated. It is a destructible world facility, not `EnemyState`:
  it does not join enemy AI, count toward ordinary quota, or drop enemy XP.
- The facility selects a deterministic clear ordinary anchor, is always visible on the
  minimap with a dedicated facility marker, and spawns existing mobile roles at 8/7/6/5/4
  second intervals for stages 1-5. Roles progress through chaser, shooter, rammer,
  bulkhead guard, and splitter barge. It may own at most 2/3/4/5/6 live reinforcements
  and must obey the unchanged global enemy capacity.
- If a reward transaction cannot produce three valid cards, it is claimed without a
  selection and the reward queue continues. This prevents a maxed or element-locked
  stage-5 build from becoming stuck before the final result.

## Work order

- [x] 1. Apply independent scale, health, healing, XP-drop, telegraph-color, charge-line,
  damage-text, target-marker, and elemental-actor-feedback changes with focused tests.
- [x] 2. Split projectile visual families, bind the dedicated seeker, create/review the
  hostile projectile candidate, and preserve bounded retained batches.
- [x] 3. Make element selection exclusive and bind primary projectile color to affinity;
  update product contracts and upgrade-system tests.
- [x] 4. Recompose upgrade cards vertically and replace the action rail with the round
  EMP-only indicator; verify Korean/English overflow, focus, and 200% text behavior.
- [x] 5. Implement the separate reinforcement-facility runtime, authored raster, world
  damage/render path, stage-scaled spawn policy, global/live-child caps, and minimap role.
- [x] 6. Repair and validate incomplete reward-offer recovery and stage-5 final-result
  presentation.
- [x] 7. Run visual-authority and focused gameplay/UI validators, Web export, built-app
  smoke/visual QA, performance workload re-baseline where the new facility changes load,
  and a task-scoped quality audit. Commit coherent task-owned changes only.

## Validation contract

- Focused headless validators cover visual-profile constants, projectile-family routing,
  element exclusivity, XP on summoned/EMP defeat paths, enemy balance, charge/telegraph
  cues, HUD/card contracts, minimap geometry, facility lifecycle/caps, and final reward flow.
- Visual captures cover upgrade and HUD surfaces at 960x540, 1280x720, and 1920x1080 in
  Korean and English, plus the existing 200% UI scale case. No content may clip or overlap.
- `./tools/validation/validate_cardborne_visual_authority.ps1` passes after asset/contract
  changes. The final `./tools/export_web.ps1` succeeds before handoff.
- Performance thresholds and capacities are not lowered. Because the facility adds a new
  live workload, old frame-time evidence is not reused as a claim; affected scenarios are
  re-measured after implementation.

## Progress notes

- 2026-08-07: Discovery confirmed one shared projectile batch, coexistable element cards,
  summoned-hostile XP suppression, split upgrade cards, a three-slot action rail, and an
  invalid-offer path that can leave stage completion in `UPGRADE` mode. Execution started.
- 2026-08-07: Canonical visual authority was inspected at original detail. Expected and
  observed SHA-256 were both
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`;
  its recorded provenance is
  `C:/Users/BK/.codex/generated_images/019fbfe9-857e-7453-b72d-20908d848577/exec-0b8aa606-cf55-45c1-abb3-fb3df762b080.png`
  at 2026-08-02 12:13:44 KST.
- 2026-08-07: Hostile bolt and reinforcement-facility ImageGen calls used the canonical
  sheet as an actual raster reference. The reviewed source outputs are
  `C:/Users/BK/.codex/generated_images/019fdc36-5189-72f2-9e47-9834db637d7e/exec-8b9aba17-b1be-485f-87a5-1e61f33abb63.png`
  and
  `C:/Users/BK/.codex/generated_images/019fdc36-5189-72f2-9e47-9834db637d7e/exec-5f438fac-7b62-4ff2-ae72-6b2a536f6792.png`.
  Both passed style-family, silhouette-role, alpha-boundary, and runtime-size review and
  were promoted to the production manifest. An earlier craft-like hostile bolt candidate
  was rejected and never promoted.
- 2026-08-07: Focused facility lifecycle/cap/minimap validation and the exhausted Stage 5
  reward-to-result regression pass. UI, reward, projectile, XP, catalog, renderer, and
  core run validators pass after their contracts were updated.
- 2026-08-07: Final visual-authority and document-authority checks, focused gameplay/UI
  validators, Web export, and the affected pressure microbenchmark passed. Deterministic
  rendered evidence was reviewed at Korean 1280x720 full coverage, English 960x540 with
  200% text, and English 1920x1080 core coverage. The exported Web build served from the
  registered Codex lane with all seven requests returning 200, no console warnings or
  errors, and a correctly rendered deployment surface. The task-owned preview server and
  browser tab were then closed.
