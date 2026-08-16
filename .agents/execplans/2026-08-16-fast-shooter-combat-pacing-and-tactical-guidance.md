---
type: plan
status: active
owner: BK
created: 2026-08-16
last_reviewed: 2026-08-16
scope: Fast-vehicle combat pacing, boss readiness, role-based spawn pressure, bounded upgrade cadence, backed top HUD, and bilingual tactical-advisor guidance
related:
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../design/DESIGN.md
  - ../cardborne-performance-engineering-policy.md
  - 2026-08-15-eight-boss-combat-depth-and-run-report.md
  - ../../docs/reports/2026-08-16-fast-shooter-combat-and-guidance-ko.html
---

# Fast-Shooter Combat Pacing and Tactical Guidance — Execution Contract

Cardborne remains a fast manual-aim vehicle shooter with survivor-like progression, not a
Vampire-Survivors ruleset with a faster avatar. The implementation keeps player speed and
dash, replaces tail-following pressure with interception and lane control, makes boss
readiness depend on demonstrated encounter breadth as well as combat progress, reduces
modal upgrade decisions, rebuilds the top HUD on compact backed cells, and adds a
bilingual tactical-advisor channel that explains unfamiliar threats without becoming a
required reading task.

## Purpose and Completion State

- Objective: make an eight-boss run sustain readable, varied pressure for an observed
  controlled-play median of 14–18 minutes without an absolute run timer or player-speed
  reduction.
- Deliverable: updated product and visual contracts, encounter/balance/reward runtimes,
  HUD and tactical-advisor UI, Korean/English copy, diagnostics, focused validators,
  rendered evidence, native qualification, and a production Web export.
- Completion: all tasks and gates below pass; the performance contingency resolves to
  either a proven 80-hostile late-cycle cap or the preserved 72 cap; this plan is then
  marked `done`.

## Scope, Boundaries, and Invariants

In scope:

- Eight existing boss cycles, ordinary pressure before and during bosses, boss signature
  teaching, enemy role statistics, sector allocation, and collective tactics.
- XP threshold and reward-opening policy, one fixed Hard difficulty, and run diagnostics.
- Full-width HP/XP meters, compact backed HUD cells, boss progress, minimap coexistence,
  and responsive Korean/English/accessibility layouts.
- A new semantic tactical-advisor runtime and a peripheral, non-modal comms surface for
  boss mechanics, priority enemies, facilities, and critical state changes.

Out of scope:

- Slower player movement or dash, auto-aim replacing manual aim, adaptive difficulty,
  difficulty selection, endless mode, a hard minimum/maximum run timer, new maps, new
  enemy or boss raster art, voice acting, a named/culturally themed officer, production
  dependencies, engine changes, threads, GDExtension, or a custom Web template.

Invariants:

- Player movement, dash distance, manual aim, held primary fire, passive seekers, EMP,
  eight authored bosses, facility truth, and fixed Hard remain intact.
- Gameplay events own truth. HUD and advisor code render semantic receipts; they do not
  infer boss shields, facility timers, attack geometry, or encounter eligibility.
- A high-threat attack keeps at least 1.30 seconds of collision-matching warning and one
  escape corridor at least player diameter + 80 units. Spawn allocation never places an
  unavoidable closed ring around the player.
- Korean is the default and every new player-facing key is complete in Korean and English.
- UI uses the shared Theme/factory. No local improvised `StyleBox`, SVG chrome, or
  unapproved raster portrait enters production.
- Current workload is preserved until the performance experiment in Task 5.3. No
  performance claim is valid without comparable clean native and Web evidence.

## Discovery Closure

| Concern | Current evidence | Locked decision | Tasks |
| --- | --- | --- | --- |
| Ten-minute ceiling | The active clock has no cap, but the run ends after eight count-gated bosses. Four current-schema completed local sessions last 478.5–655.5 seconds, mean 589.9 seconds. | Target 14–18 minutes as an observational controlled-play band, never as a timer gate. Replace raw-kill-only readiness with threat credits plus authored assault breadth. | 1.1, 2.1, 6.2 |
| Boss gate | `VehicleStageFlow` enters a 1.5-second warning when ordinary defeats reach quota; quotas are `40/44/48/52/56/60/64/68`. | Boss readiness requires cycle threat credits, three distinct assault families, and one priority-role engagement. A fast player accelerates the next assault; the game never waits on an empty clock. | 2.1 |
| Tail chase | Spawn allocation is velocity-aware, but pursuit-heavy authored ratios and direct pursuit still consume much of the live body count. | Score spawn sectors for projected interception, lateral crossfire, denial usefulness, visibility, and a preserved escape lane. Direct rear pursuit is capped, not removed. | 2.2, 2.3 |
| Difficulty | Ordinary health already stacks a global `2.60`, director `1.12`, durability `1.20`, and cycle curve up to `3.10`. Projectile speed is globally reduced to `0.82`; recovery is `1.28`. | Do not increase ordinary global HP in the first pass. Raise attack relevance through projectile speed, recovery, selected interceptor mobility, commit budgets, and compositions. Use a bounded priority-HP contingency only if measured time-to-kill is too low. | 2.4, 6.1 |
| Simultaneous enemies | Materialized cycle caps are `32/44/56/64/72/72/72/72`; pool capacity is 320. Recent sessions peaked at 45–70 live enemies. The latest exact-72 native replay already failed capacity physics p95/p99 (`7.159/9.078 ms` versus `6/8 ms`). | Improve role use inside current caps and make exact 72 pass without reducing workload. Only after that result may a separate 80-cap candidate be tested; otherwise keep 72. | 2.3, 5.3 |
| Upgrade fatigue | Current sessions opened 20–23 upgrade modals, mean 21.2; median gap 10.9 seconds and minimum 1.3 seconds. The authored minimum path is 2,296 XP and 32 levels. `VehicleRun` immediately opens one modal per pending level. | Cap XP level-up decisions at 16, use a new curve, and open them only at safe cadence points. Pending XP is never lost. Non-XP authored rewards keep source order. | 3.1–3.3 |
| HUD clipping | Normal stage cells are only 34–40 px wide while they render the full localized boss/quota string with clipping. Current contract and validator require panel-free cells. | Amend the visual contract: one flat backed cell per top-HUD datum, explicit measured widths, and a separate boss-progress cell. Update validators before runtime layout. | 1.2, 4.1 |
| Messages | One text-only two-line channel has a four-entry queue and currently carries five event families. It can ellipsize Korean/English and would make advisor lines compete with danger alerts. | Split immediate danger from tactical explanation. Existing world telegraphs/radar stay primary; a dedicated advisor runtime publishes bounded, interruptible semantic guidance to a side surface. | 4.2–4.4 |
| Facility explanation | Facilities have 360 HP and activate for 12 seconds, but only activation is announced and expiration has no dedicated guidance receipt. | Publish discovered, activated, expiring, and ended receipts with exact effect/duration data from `VehicleMysteryDeviceRuntime`. | 4.3 |
| Visual authority | `VISUAL_SYSTEM.md` and canonical sheet hash `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889` were inspected. Current panel-free wording conflicts with the user's backed-cell direction. | The user request authorizes a contract revision, not an asset approval. Use code-native Theme surfaces first. A future portrait requires a canonical PNG reference, ImageGen, provenance, and exact-file approval. | 1.2, 4.1, 4.4 |

Readiness statement:

- Product, architecture, data, UI, localization, performance, and validation owners are
  known. No dependency or visual-asset approval is required for the code-native first
  release.
- The 14–18-minute band and the numbers below are initial tuning targets grounded in
  current local telemetry, not claims that external games provide Cardborne values.
- The stale root phrase “ten-stage paired run” conflicts with the current canonical
  eight-cycle spec and code. Do not edit protected `AGENTS.md` within this gameplay task;
  raise a separate governance correction after implementation.

## Locked Behavior Contracts

### 1. Combat identity and run pacing

- Genre rule: survivor-like progression supplies build growth and field persistence;
  shooter rules own movement, aim, attack tells, interception, space control, and tempo.
- Controlled reference build: default starting vehicle, fixed Hard, no debug grants,
  1280×720, current Godot 4.7.1. Record at least five complete runs per tuning candidate.
- Acceptance band: median completion 14–18 minutes; no more than one of five reference
  wins below 12 minutes; no hard time gate. A skilled clear can remain faster.
- Replace raw quota with threat credits `56/64/72/80/88/96/104/112`.
  - pursuit/standard defeat: 1 credit;
  - ranged, support, denial, or specialist defeat: 2 credits;
  - priority/elite defeat: 3 credits;
  - summons, cleanup, facilities, and non-countable actors: 0 credits.
- Boss readiness also requires three distinct authored assault families to have begun
  (`intercept`, `crossfire`, `denial`) and at least one priority unit to have committed an
  attack. If credits advance early, schedule the missing family at the next legal cue;
  never hold an empty field to satisfy the contract.
- Boss warning remains 1.5 seconds. During boss combat, maintain ordinary reinforcement
  pressure up to 25% of the cycle cap, with at most one ranged and one denial commit and
  the same escape-corridor rule. Boss death cleanup retires remaining owned danger safely.

### 2. Spawn and attack policy

- Every arrival window scores legal off-screen sectors using the player's current
  velocity and a 1.2-second bounded projection.
- Sector weights: 35% projected intercept/crossing value, 25% role-compatible standoff or
  denial geometry, 20% visibility/off-screen legality, 20% escape-lane preservation.
- Direct rear pursuit may occupy at most 35% of admitted threat cost in a window. At least
  40% must be intercept/crossfire/denial from cycle 2 onward; support remains bounded by
  its existing category limits.
- Never spawn inside the existing 900-unit safe radius or beyond the 2,400-unit useful
  range. Never choose a sector that closes the last safe lane.
- Preserve current materialized caps during the behavior pass. Refill floors remain the
  low-water mark, not a target to fill with irrelevant chasers.
- First stat pass:
  - `HOSTILE_PROJECTILE_SPEED_MULTIPLIER`: `0.82 → 0.90`;
  - `ENEMY_RECOVERY_RATE`: `1.28 → 1.38`;
  - interceptor/rammer approach speed: +10%; direct pursuit speed unchanged;
  - cycles 5–8 ranged commit cap: `4 → 5`; denial commit cap stays 3;
  - global ordinary HP, global enemy damage, player speed, and dash stay unchanged.
- Priority-HP contingency: only if a default-build reference kills a priority unit before
  its first committed attack in more than 30% of samples, add +8% health to that role,
  never to the global ordinary multiplier.
- Each boss demonstrates its signature attack alone once, then combines it with one
  learned pressure layer. Do not add new attack languages or random freeform selection.

### 3. Upgrade cadence

- Replace the unbounded 96-cap curve with 16 level-up thresholds:
  `10,16,24,34,46,60,76,94,114,136,160,186,214,244,276,310`.
  Run level 17 is XP-complete; field XP then stops spawning/merges through the existing
  completion path. Authored non-XP rewards remain available.
- The first two level-up rewards may open immediately only when no committed high-threat
  attack is active. Later level-ups open at the first safe window satisfying all rules:
  no boss warning/active boss/high-threat commit, no damage received for 2.5 seconds, and
  at least 45 seconds since the prior level-up modal.
- Pending levels accumulate. One modal session resolves at most two pending level choices
  sequentially, shows `1/2` or `2/2`, and returns to play after the second choice. No two
  separate level-up modal sessions occur within 45 seconds.
- If a boss starts first, defer pending level-ups until the 2.0-second boss cleanup ends.
  Do not discard XP, reorder non-XP sources, or open a modal during aiming pressure.
- Acceptance: 12–16 level-up modal sessions in a complete reference run, median interval
  at least 45 seconds after the first two, minimum interval at least 30 seconds, and no
  `upgrade_opened` event while a high-threat receipt is committed.

### 4. Backed HUD and tactical advisor

- Keep full-width HP and XP meters. Place a left-aligned row below them using one shared
  Theme-backed surface per datum: one flat near-black fill, one 1 px boundary, no nested
  border, no texture chrome.
- Standard sizes: boss progress `168×48`, total defeats `52×48`, dash `76×48`, active
  `76×48`, conditional status `52×48`; 8 px gap and 24 px safe margin. Compact sizes use
  `144×42/46×42/68×42`; 200% uses two rows within the left top band instead of clipping.
- Boss progress always displays `보스 N/8 · 출현까지 C` / `Boss N/8 · C to contact`.
  During warning it displays the countdown; during combat it displays the localized boss
  name and phase. Defeats remain a separate icon/value cell.
- Use measured localized text bounds in validation. Ellipsis is not acceptance for boss,
  dash, active, facility time, or advisor action text.
- Replace the central generic announcement lane with two channels:
  - `danger cue`: immediate, maximum 1 line, centered below the top meters for at most
    1.8 seconds; only boss inbound, barrier depleted, and lethal/high-threat warnings;
  - `tactical advisor`: right side below the minimap, standard `360×76`, compact
    `300×68`, 200% `440×104`; 48 px identity well plus at most two lines and a small
    category label. It never pauses play or covers the reticle/escape corridor.
- Semantic priority is `critical > mechanic > state > flavor`. Queue capacity is 3.
  Critical lines interrupt; mechanic/state lines coalesce by subject; flavor is dropped
  under pressure. Repeated lines have a 45-second cooldown unless the player repeats the
  relevant failure.
- Guidance is event-driven and knowledge-aware:
  - first encounter: explain one actionable mechanic;
  - first failed response: repeat with a more direct verb;
  - mastered/repeated encounter: show only phase/state changes;
  - boss mechanics speak at telegraph/recovery boundaries, never over the first required
    dodge;
  - facility lines report exact outcome and remaining duration from runtime truth.
- Required Korean examples and equivalent English keys:
  - frontal shield: `전면 보호막 감지. 측면으로 돌아 사격하세요.`
  - repair active: `수리 시설 가동. 12초 동안 범위 내 선체를 복구합니다.`
  - repair ended: `수리 지원 종료.`
  - denial enemy first-seen: `진로 차단 신호 감지. 사격 지점을 먼저 제거하세요.`
- First release uses a semantic comms glyph and identity well, text, and the existing
  subtle UI audio family. It is portrait-ready but has no generated portrait or VO.

## Tasks

### Phase 1 — Amend authoritative contracts

Goal: remove conflicts before runtime work.

- [ ] **1.1 Product contract.** Update `docs/product/vehicle_game_spec.md` with the hybrid
  fast-shooter identity, observational 14–18-minute band, threat-credit readiness,
  reinforcement rule, and 16-choice XP cadence. Remove raw-quota-only and “time has no
  target” claims that conflict with this plan; keep the no-hard-timer invariant.
  - Accept: product spec, stage data, guidebook terminology, and validators agree on eight
    cycles, credit labels, and progression cap.
- [ ] **1.2 Visual contract.** Update `docs/design/VISUAL_SYSTEM.md` and
  `.agents/design/DESIGN.md` to authorize code-native backed top-HUD cells and the tactical
  advisor surface. Resolve the omitted facility-announcement contract.
  - Accept: `validate_cardborne_visual_authority.ps1` passes; document says concept glyph
    is not raster approval; no panel-free assertion remains for status cells.
- [ ] **1.3 Localization inventory.** Define stable semantic IDs and Korean/English keys
  for threat credits, boss states, advisor categories, the required event matrix, and
  settings/accessibility names.
  - Accept: localization validator reports complete key parity and no runtime English
    literals (`READY` included) on the changed HUD path.

### Phase 2 — Rebuild encounter pressure

Goal: make speed create tactical vector choices instead of distance from followers.

- [ ] **2.1 Boss readiness owner.** Extend `vehicle_stage_flow.gd` with credit totals and
  assault-family receipts; update stage definitions from quotas to the locked credit table.
  `VehicleRun` only orchestrates receipts.
  - Accept: focused fixtures prove credits, three families, priority commit, warning, boss
    entry, boss cleanup, and zero-credit exclusions.
- [ ] **2.2 Spawn scoring.** Extend `vehicle_spawn_allocator.gd` to score velocity-projected
  intercept, role geometry, visibility, and escape lanes. Feed semantic sector decisions
  from `vehicle_encounter_runtime.gd`; do not add per-frame allocation scans.
  - Accept: seeded fixtures cover stationary, sustained dash, reversal, wall-edge, and last
    safe-lane cases; direct-rear share and minimum intercept share remain within contract.
- [ ] **2.3 Composition and boss maintenance.** Update encounter/tactic catalogs and runtime
  to enforce role budgets, accelerated missing assault families, and bounded boss escorts.
  - Accept: no visible-hostile gap exceeds 3 seconds, first meaningful preparation stays
    within 8 seconds, and boss pressure never exceeds commit/corridor limits.
- [ ] **2.4 Stat tuning.** Apply the locked projectile/recovery/interceptor/ranged-cap
  changes in existing balance owners. Add per-role HP contingency without activating it.
  - Accept: debug contracts, guidebook values, tests, and diagnostics expose exact values;
    no global ordinary-health or player-mobility value changes.

### Phase 3 — Reduce upgrade interruption

Goal: keep build decisions meaningful without repeatedly stopping manual combat.

- [ ] **3.1 XP curve.** Implement the 16-threshold table and XP-complete behavior in
  `vehicle_experience_runtime.gd`; update drop/placement and guidebook tests as required.
  - Accept: the authored minimum path reaches exactly 16 choices, pending XP accounting is
    lossless, and complete progression does not retain hidden shards.
- [ ] **3.2 Safe-window policy.** Give `VehicleRewardRuntime` a bounded level-up cadence
  receipt and let `VehicleRun` supply damage/threat/boss state. Preserve source ordering.
  - Accept: deterministic tests cover early rewards, cooldown, pending accumulation, boss
    deferral, non-XP rewards, pause/resume, and run end.
- [ ] **3.3 Batched choice UI.** Let the existing modal resolve at most two choices per
  session and show progress. Reconcile modal/row geometry with the visual contract,
  including one outer scroll at 200% and no clipped descendants.
  - Accept: Korean/English at 960×540, 1280×720, 1920×1080, and 200% have complete text,
    one focus path, one scroll owner, and no overflow.

### Phase 4 — HUD and tactical guidance

Goal: expose run truth and unfamiliar mechanics at a glance without obscuring combat.

- [ ] **4.1 Backed status cells.** Extend the shared Theme/factory and refactor
  `vehicle_gameplay_hud.gd` to use the locked cell sizes, safe margins, boss-progress
  states, and responsive two-row accessibility layout.
  - Accept: actual glyph-bound checks pass in both locales; status/minimap never overlap;
    boss text, defeats, dash, active, and five conditional statuses remain visible.
- [ ] **4.2 Advisor domain owner.** Add responsibility-shaped `VehicleTacticalAdvisorRuntime`
  and catalog files. Consume semantic event receipts and own priority, knowledge, failure
  escalation, coalescing, cooldown, and queue state. Do not put policy in HUD code.
  - Accept: deterministic tests prove event ordering, interruption, cooldown, first-seen,
    repeat failure, localization key validity, and bounded queue capacity.
- [ ] **4.3 Gameplay event adapters.** Publish narrow receipts from stage flow, boss shield/
  pattern owners, enemy/tactic commits, barrier state, and facility lifecycle. Include
  exact duration/phase data; never parse display strings.
  - Accept: boss shield, phase, priority enemy, facility discovered/active/expiring/ended,
    barrier depleted, and all-upgrades-complete routes have one truth owner each.
- [ ] **4.4 Advisor presenter.** Add the right-side comms surface to `VehicleGameplayHud`
  through `VehicleHudPresenter`'s existing invalidation cadence. Add reduced-motion,
  subtitle visibility, and advisor-detail settings; clear/retranslate safely on locale
  change.
  - Accept: combat remains input-pass-through; reticle and escape corridor stay clear;
    danger and advisor lanes never overlap; no unapproved raster is referenced.

### Phase 5 — Diagnostics, quality, and capacity

Goal: make pacing claims reproducible and prevent a visually successful change from
shipping a runtime regression.

- [ ] **5.1 Diagnostics.** Add threat credits, assault families, rear/intercept spawn share,
  attack commits, safe-lane rejections, upgrade deferral reason/session size, advisor
  queued/shown/interrupted/dropped, and facility lifecycle to session summaries.
  - Accept: schema migration preserves newest-ten retention and old sessions remain
    readable or are explicitly versioned out without quarantine noise.
- [ ] **5.2 Quality audit.** Run `$codebase-quality-auditor` after multi-module work. Split
  policy/catalog/presenter responsibilities and remove obsolete generic announcement paths
  only after replacements are reachable.
  - Accept: no card behavior in UI, no advisor policy in presenter, no competing quota
    owner, no catch-all expansion without extraction, and no stale validator contract.
- [ ] **5.3 Capacity qualification.** Under `$cardborne-performance-guard`, first reproduce
  and fix the exact-72 native/Web capacity failure without lowering actor count, attack
  activity, collision truth, cadence, or visual workload. Re-run the same clean scenario.
  - Gate A: 72 must pass current native and Web policy thresholds with equal functional
    output, no capacity rejection, and bounded memory/projectile/effect reserves.
  - Gate B: only after Gate A passes, run a separate cycles-5–8 cap-80 experiment that
    changes only the active-cap table. Promote 80 only if it passes the same rules;
    otherwise ship 72. Do not reduce encounter composition to make either gate pass.

### Phase 6 — Integrated validation and release evidence

Goal: prove the complete player experience on the shipped path.

- [ ] **6.1 Targeted and broad checks.** Run affected unit/focused validators, script parse,
  localization, visual authority, campaign flow, reward integrity, UI layout, diagnostics,
  and combat pressure suites through `./tools/godot.ps1`.
- [ ] **6.2 Controlled playtest.** Run at least five default-build complete sessions and
  record completion time, deaths/damage, boss-ready time, role/sector shares, priority unit
  first-commit survival, upgrade sessions/intervals, and advisor delivery/failure repeats.
  - Pass: timing and upgrade bands meet the locked contract; no test reports universal
    tail chase, empty clock waiting, unreadable mechanic, or clipped HUD text.
- [ ] **6.3 Rendered evidence.** Capture Korean and English at compact/standard/large/200%,
  including peak horde, boss warning, shield advice, facility activation/expiration,
  stacked conditional states, upgrade batch 1/2 and 2/2, and pause/resume.
  - Store evidence in `.agents/evidence/` with build identity and thresholds. Compare exact
    file provenance; do not call a concept or style reference approved production art.
- [ ] **6.4 Production Web path.** Export Web, start the built app through the guarded
  project lane, repeat the critical interaction/visual paths, record the final performance
  verdict, and stop task-owned helpers.

## Validation Commands

Use exact existing validator names discovered at implementation time; the minimum command
families are:

```powershell
./tools/validation/validate_cardborne_visual_authority.ps1
./tools/godot.ps1 --headless --path . --script <affected focused validator>
./tools/godot.ps1 --headless --path . --editor --quit
./tools/godot.ps1 --headless --path . --export-release Web build/web/index.html
```

Before the production-style start, load `$npjt-port-guard`; before profiling or changing
the capacity table, load `$cardborne-performance-guard`.

## External Evidence and Applicability

- [Sunset Overdrive — GDC AI talk](https://gdcvault.com/play/1021780/AI-in-the-Awesomepocalypse-Creating): fast/vertical players invalidate conventional flank-and-chase assumptions; supports interception and role redesign.
- [DOOM Eternal combat Q&A](https://www.gamedeveloper.com/design/q-a-evolving-the-combat-design-of-id-software-s-i-doom-eternal-i-): player traversal speed required faster reactions/tells and larger usable combat space; supports attack relevance without slowing the player.
- [Left 4 Dead AI systems paper](https://steamcdn-a.akamaihd.net/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf): supports visibility/flow-aware structured variation, not Cardborne-adaptive difficulty.
- [F.E.A.R. — Three States and a Plan](https://gdcvault.com/play/1013394/Three-States-and-a-Plan): supports coordinated suppression, advance, and flushing tactics.
- [Ghost of Tsushima combat balance](https://blog.playstation.com/2020/11/25/honoring-the-blade-and-combat-balance-in-ghost-of-tsushima/): supports aggression, timing, moves, and damage before HP inflation; melee-specific, so numbers do not transfer.
- [Returnal enemy design](https://blog.playstation.com/2021/04/14/creating-returnals-otherworldly-enemies-vfx-driven-tentacle-tech-and-deep-sea-inspirations/): supports readable role combinations and deliberate defensive maneuvering.
- [Returnal UX](https://blog.playstation.com/2021/05/11/unpacking-returnals-ux-design-gameplay-first-ui-retro-futuristic-tech-and-accessibility/): supports critical information near focus and explanatory information at the periphery.
- [Warframe mission interface](https://support.warframe.com/hc/en-us/articles/38801911653517-Mission-Interface): supports side transmissions for objectives, guidance, exposition, and threats while persistent progress stays near the minimap.
- [Psychonauts 2 modular bosses](https://www.gamedeveloper.com/marketing/using-a-modular-system-of-maneuvers-to-design-i-psychonauts-2-i-s-boss-fights-in-a-hurry): supports telegraph–attack–recovery maneuvers and safe dialogue timing.
- [Dota 2 Nest of Thorns development](https://store.steampowered.com/news/posts/?appids=570&enddate=1747260468&feed=steam_community_announcements): supports reducing upgrade distraction and preserving breathing room; reverse-bullet-hell context means Cardborne must validate cadence locally.
- [Firewatch dialogue systems](https://media.gdcvault.com/gdc2017/Presentations/Armstrong_Do_you_copy.pdf): supports event/fact-driven, interruptible contextual lines.

Rejected alternatives:

- Slow the vehicle, remove dash, or increase turn inertia to let chasers catch up.
- Spawn mainly behind the player, teleport enemies, or fill every lane.
- Raise global ordinary HP again or use boss health as the main run-length control.
- Use adaptive health/difficulty that weakens the fixed-Hard authored contract.
- Raise simultaneous actor caps before isolated clean capacity evidence.
- Keep one modal per level, move all upgrades to run end, or discard queued XP.
- Put tactical advice into the existing four-entry generic announcement queue.
- Make a portrait/voice package a dependency of the first guidance release.

## Progress Ledger

- 2026-08-16 — Discovery complete. Inspected product/design authorities, canonical style
  sheet at original detail and hash, current runtime owners, recent diagnostics, relevant
  captures, performance policy/audit, recent git history, and primary/official external
  examples. No runtime or production visual was changed.
- 2026-08-16 — Plan created. Implementation has not started.

## Handoff Notes

- This contract amends pacing, HUD, and guidance portions of the active eight-boss plan;
  it does not reopen its boss roster, facility roster, map set, or approved production
  assets.
- `actual_image_reference_used=false`; `reference_input_method=not_applicable` for this
  planning/report task. The canonical sheet was inspected as authority, not attached to a
  generation call. No asset approval is claimed.
- Do not tune multiple global combat multipliers and actor caps in one benchmark. Preserve
  the exact workload under comparison and record native/Web verdicts separately.
