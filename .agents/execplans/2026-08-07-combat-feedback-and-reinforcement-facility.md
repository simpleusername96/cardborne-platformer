---
type: plan
status: active
owner: BK
created: 2026-08-07
last_reviewed: 2026-08-08
topic: HUD upgrade rail, upgrade-card hierarchy, boss shield loop, attack-cue clarity, and prior-delivery audit
scope: Top HUD alternatives and integration, upgrade-card order, enemy and boss durability, removal of boss objective modules, boss-owned shield windows, hostile area-attack grammar, and verification of the 2026-08-07 delivery
related:
  - ../../AGENTS.md
  - ../PLANS.md
  - ../design/DESIGN.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/product/vehicle_upgrade_catalog.md
---

# HUD, Boss Shield, and Combat Readability - Execution Contract

## Why and context

The 2026-08-07 delivery added the requested combat-scale, projectile, upgrade,
EMP, reward, reinforcement-facility, and Stage 5 changes. User review then found
that the top HUD did not expose the acquired build, the upgrade-card body order
was still wrong, boss objective modules made the vulnerability rule harder to
read than intended, and hostile circular attacks still used several colors and
ordinary-enemy sources.

This revision keeps one active progress owner. It first repairs the current
validation baseline, then implements the user-selected linear top-HUD reference
with the lower-coupling card and balance changes before the cross-system boss,
minimap-marker, and attack-grammar changes.

## Scope and non-scope

In scope:

- The user-selected linear top-HUD reference using the current Theme, component
  factory, semantic upgrade artwork, and localization.
- One production top-HUD layout with player hull centered above an acquired-
  upgrade rail, and stage/message information moved into the former top-left
  hull zone.
- A clearer minimap threat hierarchy: ordinary enemy markers become smaller and
  the boss marker becomes substantially larger, while the minimap frame and map
  geometry stay unchanged.
- Event-driven acquired-build delivery to the HUD; upgrade arrays must not be
  rebuilt or deep-copied by the 10 Hz fast HUD path.
- Upgrade-card body order and typography correction.
- Exact preservation of the already-applied final `1.30` ordinary-enemy health
  multiplier, plus a new `1.30` boss-health multiplier over the current authored
  five-stage curve.
- Removal of external boss objective modules and replacement with a timed,
  boss-owned shield state.
- A single hostile circular-bombardment grammar: only boss damaging area attacks
  use a ground circle, and every such circle uses the same orange warning family.
- A current-HEAD audit of the prior plan, including repair of any stale or
  hanging focused validators before they can be used as evidence.
- Korean and English copy, product/visual contracts, focused validators,
  deterministic captures, Web export, and built-Web smoke for the changed flow.

Out of scope:

- New raster artwork, SVG geometry, ImageMagick-authored visuals, a new UI Theme,
  new dependencies, or a redesign of the minimap frame, map geometry, or marker
  role set.
- Changes to player collision, projectile collision, global capacities, boss
  pattern cadence, stage quota, reinforcement-facility policy, or the fixed Hard
  difficulty.
- A release-performance claim. The authorized removal of two boss-module actors
  changes workload and must be recorded as a product change, not an optimization.
- New ordinary enemy roles or new boss patterns.

## Assumptions and locked decisions

- The phrase “enemy health +30%” refers to a final total multiplier of `1.30`,
  not another `1.30` multiplication on the already-modified value. Ordinary
  health therefore remains at the current total value and receives regression
  coverage rather than another balance increase.
- “Boss health stronger” uses the same bounded first-pass increase: the authored
  values `[1250, 1350, 1450, 1550, 1650]` are multiplied by `1.30`, producing
  `[1625, 1755, 1885, 2015, 2145]`.
- A boss shield is not a separate actor, target, health pool, minimap marker, or
  projectile blocker. It is one state on the boss entity.
- The shield is active at boss entry and every phase transition. Completion of a
  committed direct boss attack drops it for `4.0` seconds. Autonomous pressure
  does not independently open or extend the window. A phase transition cancels
  an open window and reactivates the shield.
- Shielded boss damage uses `0.25x`; unshielded damage uses `1.00x`. There is no
  hidden `1.55x` bonus, HP floor, or immunity. The active shield uses one retained
  boss-attached boundary in `boss_command` color with no ambient pulse; the
  boundary is absent while the shield is down.
- The top-left mission surface keeps the current hull-zone footprint as its
  baseline. It shows stage/quota, one current message or shield state, compact XP
  progress, and conditional boss health. It does not duplicate those values in
  the center zone.
- The center player-health bar is panel-free and responsive: `400x10` at compact,
  `520x12` at standard, and `640x14` at large. It shows the current/max value
  without adding a large label block.
- Acquired-upgrade icons are sorted by existing catalog category and stable
  catalog order. Only acquired upgrades appear. Each icon may carry one plain
  corner level numeral, without a pill, badge panel, or repeated text label.
- Full upgrade names and values remain available in the paused Ship Status
  surface. The live rail is for fast build recognition, not full inspection.
- The user selected Candidate A / Image 1 on 2026-08-08. Production uses one
  centered linear rail. Up to 12 icons remain on one row; 13-18 wrap into a
  second centered row. Candidate B and Candidate C are rejected for this pass and
  do not become runtime options.
- Ordinary minimap enemy markers use outer/inner radii `4.0/2.6`; the boss uses
  outer/inner radii `10.0/7.6`. Item, player, and reinforcement-facility markers
  retain their current geometry.
- No blocking design question remains. Tuning beyond the locked first pass is a
  later playtest decision, not an implementation guess.

## Proposed design

### Common top-HUD frame

- Top-left: one restrained mission surface in the old hull location. Normal play
  shows stage/quota, the current objective or transient message, and a thin XP
  meter. During a boss encounter the same surface adds the compact boss-health
  meter and replaces the objective detail with `방어막 전개/해제` or its English
  equivalent.
- Top-center: the panel-free player-health bar. Acquired upgrades appear directly
  below it using the existing semantic upgrade artwork provider.
- Top-right: the existing minimap and conditional target content. Its footprint,
  map geometry, and five-role grammar stay unchanged; only the ordinary-enemy
  and boss marker radii change to strengthen threat hierarchy.
- Bottom-center: the existing panel-free `88x88` EMP indicator stays unchanged.
- No full-width dock or full-rail background is allowed. Standard top-center
  height targets `72 px` with one icon row and may reach `104 px` only after a
  real second row is needed. Empty future slots are never rendered.
- Candidate fixtures must cover 0, 6, 12, and 18 acquired upgrades so the design
  is judged on growth rather than on one convenient build.

### Candidate A - Linear rail (selected)

- One centered row of `30 px` icons at standard size.
- The first 12 upgrades stay in one row; 13-18 wrap into a second centered row.
- Strength: fastest single-scan reading and the smallest early-run footprint.
- Tradeoff: later upgrades can shift position when the second row appears.

### Candidate B - Category clusters (rejected for this pass)

- Four centered clusters follow the current user-facing categories: Primary,
  Elements, Secondary Weapons, and Ship Systems.
- Only clusters with acquired upgrades are shown. A restrained semantic notch and
  inter-cluster spacing identify the category; repeated category words are not
  shown on the live HUD.
- A cluster keeps its icon order as it grows and wraps as a complete cluster when
  necessary. This supports the current 12 upgrades and an 18-upgrade fixture
  without mixing mechanic families.
- Strength: acquired and future content keeps a predictable semantic location.
- Tradeoff: slightly more horizontal spacing than Candidate A in the middle run.

### Candidate C - Fixed two-row matrix (rejected for this pass)

- A centered `9 x 2` matrix uses `28 px` icons and preserves a constant maximum
  footprint from the first upgrade onward, while still hiding empty cells.
- Stable insertion positions avoid reflow during combat and give 18 visible
  upgrade positions at every supported desktop width.
- Strength: the best high-count capacity and the least layout movement.
- Tradeoff: it consumes two-row vertical space earlier than the other candidates.

### Selection and production rule

The three ImageGen previews used the same current gameplay capture, canonical
style-reference sheet, and existing upgrade-card artwork as actual image inputs.
The user selected the first displayed result at
`C:/Users/BK/.codex/generated_images/019fdc36-5189-72f2-9e47-9834db637d7e/exec-6eed99e2-bcba-43f5-aaa3-8c01f8c09b1f.png`.
It is a visual target, not a production raster: runtime recreates its hierarchy
with existing Godot Controls and semantic upgrade textures. No preview image is
copied into the game or production manifest.

### Upgrade card

The card header and artwork remain above the change body. Inside the body the
order becomes exactly:

1. `Lv.current -> next`
2. real current-to-next values, or the existing small icon-only unlock marker for
   a first behavior acquisition
3. the concise localized description as the final row

Both `HSeparator` controls and their layout/debug contracts are removed. The
description font increases from `14` to `16` in compact/standard layouts and to
`18` in the large/200% profile. Descriptions keep the approved roughly ten-
character Korean and two-to-five-word English copy, use center alignment, and do
not become a footer panel.

### Boss shield and boss modules

- Replace the objective-module catalog/runtime with one narrow boss-shield state
  owner. Boss pattern ownership remains in `VehicleBossRuntime` and
  `VehicleBossPatterns`; the run orchestrator only forwards direct-pattern and
  phase-transition receipts.
- Remove `boss_pylon` creation, targeting, collision, damage, XP exception,
  minimap/threat-radar contacts, renderer branches, guidebook identity,
  localization, captures, and objective snapshots.
- Remove orphaned boss-node raster/manifest entries only after consumer search
  proves zero live references. Recompute the production manifest count instead
  of preserving the current exact-count assertion by adding unused assets.
- The boss HUD snapshot exposes only boss health, shield active/down state, and
  remaining down-window seconds. No module IDs or module health cross the UI
  boundary.
- Existing phase floors continue to select phase changes but never clamp or
  cancel accepted damage.

### Hostile area attacks

- Boss `area` telegraphs ignore attack affinity for presentation and always use
  the same orange hostile-bombardment color. Purple arc and red kinetic boss
  circles disappear.
- `controller` and `artillery_spotter` stop using targeted `area` attacks. Their
  existing attack slots become direct hostile-projectile attacks using the
  existing hostile projectile family; no new projectile image is added.
- Stationary mine damage remains local area damage, but its world-space danger
  circle is removed. One-shot actor state changes communicate arming and imminent
  detonation without a ground bombardment ring or attack route.
- Non-damaging actor-attached support/shield boundaries may remain in their
  support color. They must never use the orange bombardment grammar.
- Charge routes, projectile entry lanes, ranged startup ticks, collective attack
  directions, floating damage text, and yellow enemy selection overlays remain
  absent and receive regression coverage.

## Prior delivery audit - 2026-08-08

| Prior requirement | Current evidence | Audit result |
| --- | --- | --- |
| Player/projectile/XP size and dedicated projectile families | Visual-profile constants remain `35`, `0.70`, `0.50`, and XP `17/20/23`; projectile catalog has Primary, Seeker, and Hostile identities | Implemented in source; current focused proof is blocked by a stale validator parse error |
| Mine/orbit presentation enlargement | Secondary visual constants and renderer routing remain in the prior delivery | Implemented in source; must be rechecked by the repaired projectile/renderer validation batch |
| Concise card descriptions and exclusive element choice | Localized summaries are present; catalog compatibility excludes the two unchosen elements after selection | Implemented; card row order is superseded by this plan |
| EMP-only bottom indicator | HUD owns one panel-free `88x88` action slot and no dash/secondary slots | Implemented |
| Yellow enemy overlays and attack-route removal | Follow-up commit `b3be088b` removed vulnerability crosshair, reward-color markers, entry previews, startup ticks, and collective direction indicators | Implemented in source; preserve with regression tests |
| EMP/summon XP, ordinary health, doubled healing | Enemy defeats use the normal XP path; ordinary multiplier is `1.30`; repair/generator values are doubled to `8` | Implemented in source |
| Reinforcement facility | A separate facility runtime owns activation, health, spawn interval, child cap, and minimap snapshot | Implemented in source |
| Stage 5 completion | Exhausted offers resolve without a modal and final completion calls the result flow | Implemented in source |

The prior delivery is therefore present, but it cannot be called fully reverified
on current HEAD. `validate_vehicle_projectile_readability.gd` does not parse
because it calls `descriptor()` without the now-required semantic ID, and
`validate_vehicle_damage_feedback.gd` did not terminate within the bounded audit
window. These are the first implementation blockers to repair and diagnose.

## Milestones and work order

Prior completed delivery:

- [x] 1. Apply the original scale, health, healing, XP, feedback-removal, and
  telegraph changes.
- [x] 2. Split projectile families and add the dedicated hostile and facility
  rasters through the visual-authority workflow.
- [x] 3. Make element selection exclusive and bind primary projectile color.
- [x] 4. Simplify the upgrade and EMP HUD surfaces.
- [x] 5. Add the separate reinforcement-facility runtime and minimap role.
- [x] 6. Repair Stage 5 exhausted-offer completion.
- [x] 7. Run the original focused, visual, Web, and workload checks.
- [x] 8. Restore concise descriptions and remove residual yellow markers/routes.

Current follow-up, ordered from lower coupling to higher coupling:

- [ ] 9. Repair the stale projectile-readability validator and diagnose the
  bounded non-termination in damage-feedback validation. Run the prior-scope
  focused audit before using its earlier “complete” status as current evidence.
- [ ] 10. Correct the upgrade-card row order, remove both separators, raise the
  description type size, and lock ordinary/boss health constants with focused
  tests. Do not touch boss mechanics in this milestone.
- [ ] 11. Build the selected linear acquired-upgrade rail, move
  stage/message/XP/boss summary into the top-left mission surface, and deliver
  build changes to the HUD only on upgrade/reset. No alternative runtime branch
  is created.
- [ ] 12. Apply the locked minimap marker radii and produce the complete selected-
  HUD responsive/localized capture set, including ordinary and boss marker
  evidence.
- [ ] 13. Replace external boss modules with the boss-owned timed shield, apply
  the boss-health multiplier, remove every module consumer, and update boss HUD,
  radar, minimap, guidebook, localization, captures, and workload fixtures.
- [ ] 14. Unify boss circles to orange, convert ordinary targeted area attacks to
  direct projectiles, replace the mine ground circle with actor-state cues, and
  prove no ordinary hostile can create a damaging ground circle.
- [ ] 15. Update `vehicle_game_spec.md`, `VISUAL_SYSTEM.md`, and upgrade contracts
  to the approved HUD, card hierarchy, shield loop, health values, and attack
  grammar. Remove obsolete objective-module wording and exact asset-count claims.
- [ ] 16. Run focused gameplay/UI/authority validation, deterministic Korean and
  English captures, Web export, built-Web smoke, and the task-scoped quality
  audit. Commit coherent task-owned slices only.

## Progress and next step

- Canonical progress: the checkboxes above.
- Current milestone: 9.
- Next action after plan approval: repair the two current-HEAD validation blockers,
  then implement Milestone 10 before any HUD or boss refactor.
- Update rule: check a milestone only when its source change, focused validation,
  and named evidence are present. Do not reuse a historical pass after its owner
  changes.

## Test plan and acceptance criteria

### Focused correctness

- Upgrade cards report body order `level -> effects/unlock -> summary`, contain no
  separators, keep one summary per card, and fit Korean/English at all three
  card profiles and 200% text.
- The ordinary-health contract reports exactly `1.30`. Boss health reports the
  five locked values after the `1.30` multiplier.
- Boss-shield tests cover entry, direct-pattern completion, the exact `4.0`
  second down window, `0.25x/1.00x` damage, phase reactivation, no HP floor, and
  removal of all module actors/targets/snapshots.
- Attack-contract tests prove that only a stage boss can emit a damaging
  world-space `area` telegraph. Every boss area warning resolves to the same
  orange color regardless of affinity. Controller and artillery attacks resolve
  to direct projectiles; mine startup produces no ground ring.
- Prior-plan focused tests cover projectile visual families/scales, element
  exclusivity, EMP-only HUD, XP drops, doubled healing, facility lifecycle/caps,
  route/overlay suppression, and final-result progression.

### HUD and visual evidence

- Selected linear-rail captures cover 0/6/12/18 upgrades at `960x540`, `1280x720`, and
  `1920x1080`, in Korean and English, plus 200% text.
- No icon, level numeral, health value, stage/message line, boss meter, target
  block, or minimap child clips, overlaps, or leaves its container.
- The top center uses no full-width or full-rail background. One-row standard
  height is at most `72 px`; a second row appears only when the real build needs
  it and stays at or below `104 px`.
- The active boss shield is visually attached to the boss, clearly different
  from the orange ground attack circle, and absent during the down window.
- Ordinary minimap markers resolve at `4.0/2.6` radii and the boss resolves at
  `10.0/7.6`; boss and ordinary markers remain distinct in grayscale without
  changing item, player, or facility geometry.
- The visual-authority validator passes after the canonical HUD/boss contracts
  and manifest are updated.

### Runtime handoff

- Focused HUD presentation checks show that acquired-upgrade arrays update only
  after build/reset changes and are not copied by the 10 Hz fast clusters.
- Global enemy/projectile/effect capacities and thresholds remain unchanged.
  Performance fixtures record the authorized removal of boss-module workload;
  no lower workload is presented as an optimization win.
- The Web export succeeds. The production-style built app loads, reaches the
  changed HUD/card/boss flows, returns no console errors, and is closed together
  with task-owned browser/server helpers after review.
- `codebase-quality-auditor` finds no remaining task-owned responsibility creep,
  stale module API, unreachable failure path, or missing focused contract.

## Rollback and safety

- Keep the three HUD alternatives behind a debug/capture selector until one is
  promoted. Production never owns multiple switchable HUD architectures.
- Land the card/balance, HUD, boss shield, and attack grammar as separate coherent
  commits so a regression can be isolated without reverting unrelated user work.
- Before removing boss-module assets, search manifest, provider, guidebook,
  renderer, capture, localization, and validation consumers. Delete only proven
  task-owned orphans and report their removal.
- Preserve current collision radii, capacities, stage saves, upgrade IDs, and
  localization columns. No dependency, schema migration, or destructive user-
  data action is required.
- If a built flow cannot expose a required state deterministically, stop that QA
  branch and report the missing fixture rather than weakening the assertion.

## Risks and mitigations

- **HUD rail allocations:** reusing the frozen build snapshot at fast cadence
  would reintroduce snapshot cost. Mitigation: event-driven build receipts and a
  retained icon pool owned by the HUD component.
- **Future upgrade count:** one convenient 12-card fixture can hide overflow.
  Mitigation: 18-upgrade captures and a two-row bound in every candidate.
- **Boss difficulty spike:** higher HP plus shielded damage reduction may lengthen
  fights. Mitigation: lock the first pass, preserve a readable `4.0` second full-
  damage window, and record playtest duration separately from correctness.
- **Hidden mine danger:** removing its ring can reduce reaction clarity.
  Mitigation: use explicit actor arming/imminent states and validate the full
  startup duration without adding another ground attack symbol.
- **Large obsolete surface:** `boss_pylon` crosses many owners. Mitigation: remove
  it by consumer class with zero-reference searches and dedicated no-module
  acceptance checks, not a broad `VehicleRun` rewrite.
- **Evidence drift:** the previous plan recorded passes that current validators no
  longer reproduce. Mitigation: repair the validator API and non-termination first
  and label historical evidence as historical.

## Open questions

No blocking implementation question remains. Candidate A / Image 1 is selected.
Boss health or shield timing changes beyond the locked first pass require later
playtest evidence and a separate tuning note.

## Decision notes and provenance

- 2026-08-07: The original delivery was implemented in `75dc8edd` and the first
  user-review cleanup in `b3be088b`.
- 2026-08-07: Canonical visual authority was inspected at original detail. The
  expected and observed SHA-256 were
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- 2026-08-07: The hostile bolt and reinforcement-facility rasters used the
  canonical sheet as an actual ImageGen reference and were promoted after review.
- 2026-08-08: The authority document and original-detail style sheet were
  rechecked before planning this HUD/card/boss visual revision. The sheet remains
  a style reference, never asset approval. This plan adds no new raster output.
- 2026-08-08: Source audit confirmed the final ordinary-health multiplier is
  already `1.30`; applying another 30% would produce an unintended `1.69` total.
- 2026-08-08: Purple and red circular warnings were traced to affinity-colored
  boss area patterns and ordinary controller/mine/artillery area contracts. The
  plan replaces that mixed grammar with boss-only orange bombardment circles.
- 2026-08-08: The current-HEAD audit found one validator parse failure and one
  bounded non-termination. Prior implementation remains present in source, but
  full re-verification is deliberately not claimed until Milestone 9 passes.
- 2026-08-08: The user selected the first displayed top-HUD preview and required
  minimum map occlusion plus a larger boss and smaller ordinary-enemy minimap
  hierarchy. The locked runtime radii are `10.0/7.6` for boss and `4.0/2.6` for
  ordinary enemies.
