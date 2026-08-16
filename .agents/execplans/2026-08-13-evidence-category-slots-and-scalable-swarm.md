---
type: plan
status: active
owner: BK
created: 2026-08-13
last_reviewed: 2026-08-14
topic: Versioned play evidence, intuitive category slots, continuous enemy pressure, readable world feedback, and a scalable exact-enemy runtime
scope: Cardborne performance and session provenance, upgrade build summaries and EMP legibility, encounter continuity and boss-transition pacing, secondary-weapon footprints, Anomaly outcomes and symbols, Transit Gate replacement, gameplay announcements, collectible feedback, ordinary-enemy scheduling and spatial work, native/Web qualification, and capacity exploration
related:
  - ../../AGENTS.md
  - ../PLANS.md
  - ../design/DESIGN.md
  - ../cardborne-performance-engineering-policy.md
  - ../research/performance/cardborne-runtime-architecture-audit.md
  - ./2026-08-11-dense-combat-progression-and-run-completion.md
  - ./2026-08-13-dense-combat-and-engagement-flow.md
  - ./2026-08-13-run-pacing-result-and-upgrade-slots.md
  - ./2026-08-11-half-scale-continuous-stage-flow.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/product/vehicle_upgrade_catalog.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/design/visual-replacement-workbench/previews/mystery-device-outcomes-v4-symbols/candidate-evidence.md
  - ../../docs/design/visual-replacement-workbench/previews/transit-gate-v2-clean/candidate-evidence.md
  - ../../.agents/evidence/performance/2026-08-13-dense-enemy-stutter-evidence.md
  - ../../.agents/research/performance/2026-08-13-dense-enemy-architecture-options.md
  - ../../.agents/research/performance/2026-08-13-enemy-arrival-and-engagement-research.md
  - ../../.agents/research/reports/2026-08-14-game-telemetry-and-feedback-research.md
  - ../../.agents/research/reports/2026-08-14-upgrade-category-language-review.md
---

# Evidence, Continuous Pressure, Readable Feedback, and Scalable Swarm - Execution Contract

Make performance and play-session evidence reproducible from an exact source build, replace the
acquisition-order upgrade grid with six intuitive category-owned slot groups, remove long empty
enemy intervals around stage start and bosses, and give Anomaly Devices, the Transit Gate,
announcements, and map pickups one readable feedback language. Then remove the remaining
production-replay p99 spikes
before exploring higher exact-enemy capacities. Keep the approved virtual reserve and current 48
exact-ordinary ceiling during optimization. Do not simulate fake visible enemies, weaken combat
truth, or raise shipping difficulty merely to claim a larger crowd.

For this request, this plan owns the unresolved performance follow-up shared by the three related
predecessor plans and corrects their flat progressive-grid decision. Their completed gameplay,
engagement, result, and run-clock changes remain current; this plan does not undo them. The
predecessor documents remain in the active tree because removing project records requires explicit
approval, and each now points executors to this plan for the overlapping follow-up scope.

## Purpose

- Objective: make each important performance and play-behavior claim traceable, make the build panel
  express the actual upgrade categories in ordinary player language, keep meaningful enemies
  present through the opening and boss transitions, and give the exact enemy simulation enough
  headroom for stable play and later density growth.
- Deliverable: a tracked evidence ledger, bounded exportable local session diagnostics, selected raw
  evidence, grouped category slots reused by Upgrade and Result, continuous encounter-pressure
  rules, outcome-specific Anomaly feedback, one gameplay-announcement channel, restrained
  collectible/facility motion, tail-correlated profiling, measured hot-owner corrections,
  native/Web qualification, and a non-shipping 48/64/96/128 capacity envelope.
- Completion state: the same clean commit passes the existing native `production_replay` physics
  gates (p95 at most `6 ms`, p99 at most `8 ms`), passes built-Web checks, renders all six upgrade
  categories correctly in Korean and English, meets the opening/boss visibility gates, renders the
  approved Anomaly and interaction feedback without clipping or timing regressions, and records
  every final artifact under one evidence ID. A higher shipping cap remains a separate balance
  approval even if a larger diagnostic tier passes.

## Plain-language Starting Point

The game does not become slow because 43 images are hard to draw. The latest valid run drew the
scene comfortably, but some physics updates performed several expensive enemy jobs together. Those
rare updates reached `11.593 ms`, above the current `8 ms` p99 limit.

Other crowd games can show many enemies because a visible sprite does not necessarily receive the
same amount of work as a Cardborne vehicle. Cardborne currently combines manual-aim projectile
truth, swept motion, cover and line-of-sight, local overlap, statuses, contact, role coordination,
authored arrival rules, rewards, and boss quota accounting. The engineering target is therefore not
"draw more sprites". It is "do less repeated bookkeeping, spread non-urgent work, and keep one
compact exact truth for actors that can affect combat."

The empty-map complaint has a separate verified cause. The first ordinary cue currently waits until
`5.1s`, the first actor materializes at `6.0s`, and births are placed `900-2400` world units away and
outside the camera. After the quota is reached, `seal_for_quota()` stops new ordinary admissions;
after boss defeat the next stage cues immediately but its actors still begin offscreen. The game can
therefore be doing scheduler work while the player sees no threat.

The Anomaly and message complaints were also concrete. Gravity Pull lasted `1.2s`, Cryo Lock `0.8s`,
Projectile Purge was an immediate clear followed by only a `0.18s` visual pulse, and Decoy Signal
lasted `6s`. The user subsequently rejected Decoy because its visible result overlapped Gravity and
selected Weakpoint Expose as the third outcome. Three effects currently share the same device image
family. The HUD announcement uses an 18 px
label inside a thin ToastSurface, while the renderer adds a separate world-chip text path and a
5 Hz target-count scan. Map pickups already bob, but their phase advances by update count instead of
elapsed time; Anomaly Devices have no equivalent idle cue.

The latest clean native evidence is
`build/performance/run-pacing-result-slots-production-replay-final.json`, produced from commit
`4f7f7acd1fdfc8b0265469520d29a0fdd13fea23`. It is scenario-valid and authority-eligible, with 43
median/minimum exact active actors and 269 virtual-reserve units. Its key values are:

| Metric | Value | Current gate | Result |
| --- | ---: | ---: | --- |
| Physics median | `2.828 ms` | diagnostic | green |
| Physics p95 | `5.211 ms` | `6 ms` | green |
| Physics p99 | `11.593 ms` | `8 ms` | red |
| Frame p95 / p99 | `2.381 / 4.718 ms` | `18 / 25 ms` | green |
| Enemy/grid p99 | `3.432 ms` | attribution | largest named owner |
| Encounter/pursuit p99 | `2.867 ms` | attribution | second named owner |
| Scheduled ordinary p99 | `2.860 ms` | attribution | overlapping enemy work |
| Draw calls p95 | `95` | `200` | green |

## Assumptions

- Current `HEAD` includes the completed quota seal, active-run clock, final Result, virtual reserve,
  engagement flow, larger ordinary presentation, and the first image-based flat build rail.
- The user's category-slot correction changes build presentation, not card eligibility or a hidden
  equipment system.
- The current source tree and Git history are authoritative for behavior; ignored local logs are
  evidence only when their embedded provenance and workload are valid.
- Public GitHub Pages and itch.io builds have no telemetry receiver. Local Web diagnostics stay in
  browser IndexedDB through `user://` until the player explicitly exports them.
- There is no persistent mid-run build save that requires a category-slot migration.
- The current native and single-threaded Web release targets remain required.

## Scope and Boundaries

In scope:

- Provenance for synthetic performance JSON, manual traces, visual captures, Web builds, and the
  concise conclusions that future agents use.
- A tracked append-only evidence ledger plus selected decision-changing raw JSON.
- Versioned, bounded local session diagnostics for encounter pacing, performance, upgrade choices,
  announcement delivery, Anomaly use, and supported UI configurations, with explicit export and no
  background upload.
- Six localized category groups in the build rail: Primary, Secondary, Element, Activated,
  Chassis, and Combat.
- Opening pressure, bounded ordinary maintenance during boss play, and immediate post-boss
  continuation without on-screen spawning or extra fabricated authored population.
- Removal of the unclear Projectile Purge and Decoy outcomes; exact Gravity/Cryo/Weakpoint
  lifetimes and radii; three outcome-specific PNG symbols; a clean Transit Gate replacement;
  a single text-only announcement queue; and bounded interaction/collectible motion.
- Tail-correlated profiling of the existing shipping workload.
- Removal or staggering of measured repeated scans, pursuit rebuild work, schedule construction,
  and overlap snapshot work.
- A diagnostic exact-cap staircase after the 48-cap release gate is green.
- Native, locally built Web, GitHub Pages, and itch.io verification from one final commit.

Out of scope:

- New upgrade artwork; reuse the 28 approved `upgrade/<id>` raster assets.
- A new equipment, unequip, replacement, inventory, or save-data system.
- Changing card compatibility, maximum card level, upgrade offer rules, boss quotas, XP, enemy HP,
  enemy speed, contact damage, attacks, or stage geometry. This plan may change the timing and
  admission grouping of existing authored ordinary identities but not their total authored count.
- Presentation-only enemies that appear attackable but have no hit, damage, status, reward, or
  collision truth.
- Raising the shipping exact cap during this plan. Higher tiers are capability evidence only.
- Changing the engine, adding a production dependency, enabling Web threads, or adding a
  GDExtension without a separate explicit user approval.
- Silent remote analytics, a telemetry vendor, a backend, stable cross-install player identity, raw
  route recording, or per-frame/per-actor production logging.
- Retaining CI artifacts longer than one day. Durable evidence belongs in Git, not paid Actions
  artifact storage.

Constraints and invariants:

- Godot `4.7.1` through `./tools/godot.ps1`; no project-local runtime.
- Manual aim, held primary fire, dash, seekers, EMP, exact earliest-hit behavior, fair contact,
  authored encounters, pickups, cards, five connected stages, and quota-gated bosses remain intact.
- The overall exact-ordinary ceiling remains 48. The beat-zero opening cap and authored-pressure
  cap change from `1` to `6`; later beat caps remain `40/48/48/48` and authored-pressure caps remain
  `124/172/224/276`.
- Renderer, batching, and pooling are not selected as primary work unless new evidence contradicts
  the current green measurements.
- Existing upgrade art is reorganized, not regenerated. Three Anomaly outcome-symbol PNGs and the
  Transit Gate replacement are separate visual replacement units. Their current review candidates
  were generated with the canonical sheet as actual ImageGen input and still require exact user
  approval plus technical validation before production promotion.
- Korean and English remain complete at `960x540`, `1280x720`, `1920x1080`, and 200% text scale.
- Performance comparisons use the same scenario, seed, viewport, renderer, warmup, sample duration,
  process-isolation rules, and authority checks.

Destructive or irreversible actions:

- None. Old raw local evidence remains ignored and is not deleted by this plan.

Exact actions requiring owner or user approval:

- Promotion of the three Anomaly outcome symbols or the Transit Gate candidate from the review
  workbench into `art/visuals/production`.
- A Web-capable GDExtension, custom Web export templates, Web threads/COOP/COEP deployment, engine
  change, or a higher shipping enemy cap.
- Any remote telemetry endpoint/vendor or automatic upload, including its consent, retention,
  deletion, security, and cost contract.

## Domain and Ownership Contract

| Term | Exact meaning | Canonical owner |
| --- | --- | --- |
| Evidence ID | Immutable ID linking one run or related artifact set to provenance, metrics, hashes, and a plan checkpoint. | New evidence recorder/ledger tooling |
| Authority-eligible | A run with the required environment, source cleanliness, workload, focus, viewport, warmup, and duration. It may still fail thresholds. | Performance recorder policy |
| Authoritative pass/fail | An authority-eligible run whose threshold result is explicitly pass or fail. | Performance recorder plus ledger |
| Diagnostic | A useful measurement that cannot pass or fail a release gate. | Ledger status, never inferred from filename |
| Category build slot | A presentation position inside one upgrade category. It mirrors simultaneous unique-card capacity but does not add an equipment action or limit. | Catalog contract and frozen build snapshot |
| Category occupancy | Unique acquired cards mapped into catalog-owned semantic positions inside that category; a level-up updates its existing position. | Catalog, `VehicleRunBuild`, and snapshot builder |
| Exact actor | One materialized enemy with authoritative health, position, collision, attacks, status, damage, reward, and quota behavior. | Enemy store and combat runtime |
| Virtual reserve | Authored ordinary identity and schedule data that has not materialized and cannot affect combat. | Encounter runtime |
| Capacity envelope | Diagnostic highest exact tier that meets unchanged correctness and timing gates. It is not a shipping balance decision. | Performance evidence |
| Session diagnostic | A bounded local record of one play session's lifecycle events and stage/run summaries. It is not automatically uploaded and is not a release gate. | New session signal recorder/store |
| Content fingerprint | Hash of gameplay/configuration inputs used to reject invalid comparisons between behaviorally different builds. | Build identity and evidence tooling |
| Visible-threat gap | Continuous active-run time with no ordinary or boss center inside the visible world. It is distinct from no live actor and no committed attack. | Encounter signal recorder |
| Boss maintenance pressure | A low/high-watermark ordinary reinforcement mode that consumes existing authored reserve during boss warning/active without changing quota. | Encounter runtime/director |
| Interaction motion | Presentation-only bob and edge breathing for bounded map pickups and Anomaly Devices; collision and gameplay positions never move. | Renderer/HUD presentation owners |

Do not use `slot` alone when it is unclear whether it means a category build slot, an optional
secondary gameplay slot, an attribute slot, an active-weapon slot, or a pooled runtime slot.

## Locked Upgrade Slot Design

The build rail contains six sections in existing catalog order. Each section owns a fixed maximum
simultaneous unique-card capacity derived from current compatibility rules:

| Internal category | Korean / English heading | Localized key | Slot count | Why this is the maximum simultaneous occupancy |
| --- | --- | --- | ---: | --- |
| Primary | `주무장 / Main Gun` | `UPGRADE_CATEGORY_PRIMARY` | 2 | Both primary modification cards can coexist. |
| Secondary | `자동 무장 / Auto Weapons` | `UPGRADE_CATEGORY_SECONDARY` | 5 | Built-in Homing Missiles, two optional automatic weapons, and two global secondary enhancements. |
| Element | `공격 효과 / Attack Effects` | `UPGRADE_CATEGORY_ELEMENT` | 2 | One damage effect and one utility/control effect. |
| Activated | `직접 발동 / Active Skill` | `UPGRADE_CATEGORY_ACTIVATED` | 3 | One manually activated EMP replacement and two active enhancements. |
| Chassis | `차체 강화 / Chassis` | `UPGRADE_CATEGORY_CHASSIS` | 5 | All five chassis/support cards can coexist. |
| Combat | `전술 특성 / Combat Perks` | `UPGRADE_CATEGORY_COMBAT` | 4 | All four condition-triggered player benefits can coexist. |

There are 21 simultaneous presentation positions, not 28 catalog identity positions and not one
global progressive capacity. Positions are semantic rather than a loose per-category queue:

- Primary owns fixed `split_muzzle` and `piercing_rounds` positions.
- Secondary owns fixed `homing_missiles`, `secondary_coolant`, and `secondary_amplifier` positions
  plus generic `optional_0` and `optional_1` positions for the two legal optional weapon roots.
- Element owns `damage` and `utility`, using the existing `attribute_slot_kind` contract.
- Activated owns `kind`, `active_coolant`, and `active_amplifier`, using the existing
  `active_slot_kind` contract.
- Chassis and Combat own fixed catalog-order card positions.

Leveling a card updates the same position. A new acquisition in another category never shifts an
existing image. Empty positions are outlined and not focusable. Filled positions use only the
existing semantic image in the cell; level text stays in the shared popover with keyboard/controller
focus and hover/pin behavior.

The rail uses category heading plus a left-aligned maximum four-column slot grid. Five-slot categories wrap the
fifth position to a second row. The build rail has no internal scrollbar; all six categories fit in
the supported modal body. Cells are `22/24/26 px` and artwork is `16/18/20 px` in
compact/standard/large modes. The Result reuses the same rail component and frozen snapshot.

`VehicleRunBuild.acquisition_order` remains only to keep the two generic optional-secondary
positions stable when the second optional weapon is acquired. It does not decide category order,
fixed semantic positions, the flat summary order, or gameplay eligibility, and it is not an
equipment limit. A later save-data contract may replace it with explicit optional-slot assignment;
this run has no persistent mid-run save that requires migration.

The internal IDs and existing localization keys remain. Their player-facing values use the table
above. Catalog-owned category descriptors also publish localized accessibility descriptions. The
visible rail uses only the short heading; a tooltip/screen reader can explain automatic fire,
attack-added effects, direct activation, chassis improvement, or condition-triggered perks without
adding six permanent explanatory paragraphs.

This wording was reviewed through Antigravity after the requested `Gemini 3.7 Flash (High)` label
proved unavailable in Antigravity CLI `1.1.11`; `Gemini 3.6 Flash (High)` supplied the external
review. The selected set corrects that draft against the actual card roster: Bio Toxin makes
`Element` too narrow, and `직접 발동` communicates the control distinction more clearly than
`특수 모듈`.

## Locked Local Logging and Evidence Design

Use the three-layer contract documented in
`.agents/research/reports/2026-08-14-game-telemetry-and-feedback-research.md`:

1. Release evidence promotes only decision-changing artifacts into Git and links them with a full
   commit, content fingerprint, evidence ID, environment, authority status, path, size, and SHA-256.
2. A session signal recorder keeps versioned low-cardinality lifecycle events plus bounded stage/run
   summaries under `user://diagnostics/`. It is local by default on native and Web.
3. A user-triggered `Export Diagnostics` action produces a redacted bundle. There is no background
   network request, analytics SDK, telemetry vendor, or stable cross-install player ID in this plan.

The local ring keeps the newest 20 completed sessions subject to a 25 MB total cap and 14-day
maximum age. It evicts the oldest completed session first. Stage summaries remain in bounded memory;
flush only on Result, explicit export, a settled pause surface, or normal exit. A continuous stage
transition is not a safe flush point. Enemy, projectile, collision, renderer, and input hot paths
never perform file I/O or JSON serialization.

Required signal families are session/run lifecycle, stage/arrival/boss lifecycle, visible-threat
gap summaries, diagnostic slow-tail receipts, Upgrade offer/confirm summaries, announcement queue
summaries, Anomaly reveal/activation summaries, and development-only layout faults. Persist semantic
IDs and numeric aggregates, not localized strings, raw coordinates, pointer trails, free-form text,
IP addresses, device fingerprints, or one event per frame/actor/projectile/hit.

The build envelope contains full commit when known, dirty state, release version, content
fingerprint, Godot/renderer/platform, viewport, locale, text scale, input family, and reduced-motion
state. A direct editor run without injected build identity is labeled `dev_unknown` and cannot be
used for authoritative cross-version comparison.

The session recorder is an observer, not a competing gameplay or performance owner. Performance
recorders continue to own thresholds, detailed samples, and slow-tail receipts; stage telemetry
continues to own combat-report aggregates; the encounter runtime owns arrivals/caps; the Upgrade
panel owns focus/confirmation; and the HUD owns its queue. Each owner publishes a narrow receipt or
finalized summary to the session recorder. The recorder never scans enemies, recomputes damage,
decides admission, changes UI state, or controls gameplay from telemetry.

## Locked Encounter Continuity

Opening pressure and boss pressure are separate policies from quota counting:

- Replace the one-unit `5.1s` opening scout with six low-risk pursuit identities from the existing
  authored stage sequence. Cue at `0.0s`, begin births at `0.9s`, stagger at the current `0.16s`, and
  use the nearest safe offscreen perimeter with the existing minimum visibility clearance. Never
  spawn an actor inside the visible world.
- Change beat-zero materialized/authored-pressure caps from `1` to `6`. Preserve later caps and the
  stage-authored total. Begin normal surge cueing at `4.0s`; the opening six are subtracted from the
  normal sequence.
- A deterministic no-input opening must show the first ordinary center by `3.5s`, at least three by
  `6s`, and a meaningful hostile commitment or player contact by `8s`. If geometry prevents one
  sector, the allocator chooses another nearest safe sector rather than increasing the delay.
- Reaching quota stops quota progression, not ordinary presence. Replace destructive quota sealing
  with boss maintenance pressure. Drain any already-cued window, then use existing authored reserve
  to maintain 8-12 exact ordinary actors during boss warning/active. When the exact ordinary count
  drops below 8, cue at most four next-authored identities; do not cue another maintenance group for
  4 seconds and never exceed 12, the global exact cap, or the reserved boss slot margin.
- Boss maintenance enemies give their normal combat rewards and exact interactions but cannot change
  the already-reached quota. No extra authored identity is fabricated. Existing attack-commit gates
  still constrain simultaneous ranged/denial danger.
- Boss defeat stops maintenance, retires only boss-owned state, preserves ordinary actors,
  projectiles, XP, player state, and active time, and starts the next stage's six-unit continuation
  opening immediately. If no ordinary survivor is visible, a new-stage ordinary must enter view
  within `3.0s` of boss defeat.

This design follows the useful part of Left 4 Dead/AI Director references: placement, visibility,
and pacing are explicit owner policies. It does not copy their deliberate long quiet periods because
Cardborne's current product request is continuous visible pressure.

## Locked Anomaly, Announcement, and Interaction Feedback

Anomaly outcome contract:

- `projectile_purge` remains removed. It duplicated the base EMP projectile-clear idea, had no
  gameplay duration, and its `0.18s` pulse did not explain its value. `decoy_signal` is also removed:
  its movement/aim redirection read too similarly to Gravity Pull during normal play.
- Each stage assigns Gravity Pull, Cryo Lock, and Weakpoint Expose exactly once. Gravity lasts
  `5.0s` at radius `480`; Cryo lasts `3.0s` at radius `360`; Weakpoint lasts `5.0s` at radius `420`.
  Weakpoint marks ordinary mobile enemies admitted by the existing bounded membership refresh for
  the remaining field lifetime and multiplies player-owned received damage by `1.25`. It does not
  change movement or targeting and excludes bosses and fixed hostile structures. Gameplay state and
  the visible footprint retire on the same tick.
- Keep one neutral `384x384` pristine device body until the first accepted player hit. That hit
  reveals the outcome in text and switches the still-live device to a same-footprint neutral
  `384x384` damaged body with broad central fractures. Destruction removes every body and enables
  exactly one centered authored symbol at `288` world-unit optical size as the sole authored device
  image. The symbol persists through the active effect and retires with it. Exact effect radii
  remain code-native gameplay geometry.
- The review candidates are
  `docs/design/visual-replacement-workbench/previews/mystery-device-outcomes-v4-symbols/candidates/`
  `mystery_device_gravity.png`, `mystery_device_cryo.png`, and
  `mystery_device_weakpoint.png`. Their production targets are the matching filenames under
  `art/visuals/production/gameplay/world/`, with semantic IDs
  `world/mystery_device_gravity`, `world/mystery_device_cryo`, and
  `world/mystery_device_weakpoint`. Promotion requires exact user approval.
- Hidden pristine devices and revealed-but-unbroken damaged devices keep one neutral image.
  Destroyed devices show only their outcome symbol, without another authored body underneath. The
  minimap remains neutral before and after reveal;
  it does not leak outcome through tint. Outcome differences use the centered symbol, localized
  text, full-area effect, enemy same-size compositor state, and semantic color rather than hue alone.
- Replace `facility_transit_gate.png` only with the approved candidate at
  `docs/design/visual-replacement-workbench/previews/transit-gate-v2-clean/candidates/`
  `facility_transit_gate.png`. Preserve the existing `192x192` canvas, pivot, semantic ID, runtime
  footprint, behavior, guidebook owner, and circular identity. The replacement changes only edge
  smoothness and broad-plane clarity.

Announcement contract:

- `VehicleGameplayHUD.notify` remains the sole gameplay text queue. Remove the ToastSurface panel
  chrome and the renderer world-chip text/continuous target-count path.
- Use one centered text-only label at 22 px, Noto Sans weight 800, with the existing shadow or one
  restrained contrast outline. Semantic kinds choose color; they do not choose a different box or
  font structure.
- Keep a bounded priority/dedup queue. Boss/danger messages may interrupt system messages; repeated
  identical messages coalesce; queue/shown/interrupted/dropped counts feed the session summary.
- Reveal messages name the outcome. Activation messages report the one-time affected count computed
  at activation. No 5 Hz world-chip target-count scan remains.

Interaction motion contract:

- Apply only to bounded map repair/recall pickups and intact/revealed Anomaly Devices. Do not apply
  it to XP shards, enemies, projectiles, effects, Transit Gates, or floor structures.
- Use elapsed-time sine motion: pickups bob by `6` world units over `1.8s`; Anomaly Devices bob by
  `4` world units over `2.2s`. Stable per-object phase offsets prevent synchronized motion. Collision,
  hit tests, minimap positions, effect centers, and pickup collection truth remain stationary.
- Use one shared alpha-mask edge material per presentation family, with a two-world-unit contour and
  a slow opacity breath from `0.32` to `0.52` over `2.4s`. Do not add a halo, floor ring, scale pulse,
  or per-instance material allocation.
- Reduced Motion removes bob and opacity animation but keeps a static `0.42` contour. A finite
  reveal/hit response may briefly strengthen the same contour; the active effect footprint itself
  never blinks.

The selected mechanism is the smallest readable combination among three candidates: bob plus a
breathing silhouette contour, bob plus a floor shadow, and finite reveal pulse only. A floor shadow
would imply unsupported height and a finite pulse alone would not satisfy persistent findability.
Godot Tween/sine mechanisms, Unreal interaction outlines, Apple motion guidance, WCAG reduced-motion
and blinking guidance, and Xbox text/cue accessibility provide the implementation constraints; none
of them is an art-style reference.

Mechanism and accessibility references:

- [Godot Tween](https://docs.godotengine.org/en/stable/classes/class_tween.html)
- [Unreal InteractionTargetComponent outline mechanism](https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/InteractionTargetComponent.html?application_version=5.7)
- [Apple Human Interface Guidelines: Motion](https://developer.apple.com/design/human-interface-guidelines/motion)
- [W3C `prefers-reduced-motion`](https://www.w3.org/TR/mediaqueries-5/)
- [WCAG 2.2 Pause, Stop, Hide](https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide.html)
- [WCAG 2.2 Use of Color](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color)
- [Xbox Accessibility Guideline 101: Text display](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/101)
- [Xbox Accessibility Guideline 103: Additional channels](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/103)

## Why Survivor-like Games Are Not a Contradiction

The comparison supports the following mechanisms, not claims about undisclosed internals of a
specific game:

1. **Rendering and simulation are separate costs.** Godot documents MultiMesh as a way to draw huge
   instance counts efficiently, but Cardborne rendering is already green. More batching does not
   remove enemy decisions, collision, LOS, or encounter work.
2. **Crowd systems change fidelity by relevance.** Epic's Mass system separates representation LOD
   and simulation LOD, with configurable distance and count limits. Network engines similarly use
   relevancy and lower update frequency for less important actors.
3. **Large systems choose a coarser model away from the important boundary.** SUMO's mesoscopic
   traffic mode uses queues and reports substantially faster execution than microscopic per-vehicle
   dynamics. Cardborne's virtual reserve is the analogous safe boundary: authored pressure remains,
   but only combat-relevant arrivals become exact.
4. **Data layout matters after the product boundary is correct.** Unity and Unreal document
   data-oriented, chunk/archetype processing. Cardborne's earlier broad typed-GDScript migration
   regressed because it retained compatibility mirroring and maintenance work. A future hot-core
   migration must replace one truth owner, not create a second copy of the same world.
5. **Successful survivor games also hit this problem.** poncle reported that Vampire Survivors'
   earlier physics was limited by one CPU core and later moved to a new engine; the official post
   reported a large benchmark improvement. Deep Rock Galactic: Survivor publicly described an ECS
   rebuild for longer runs and Steam Deck performance, then set it aside because the engineering
   cost threatened its schedule. There is no honest basis for assuming that any engine makes rich
   exact actors free.

Primary references:

- [Godot general optimization](https://docs.godotengine.org/en/stable/tutorials/performance/general_optimization.html)
- [Godot MultiMesh optimization](https://docs.godotengine.org/en/latest/tutorials/performance/using_multimesh.html)
- [Godot low-level Servers](https://docs.godotengine.org/en/stable/tutorials/performance/using_servers.html)
- [Epic Mass Gameplay and simulation LOD](https://dev.epicgames.com/documentation/unreal-engine/overview-of-mass-gameplay-in-unreal-engine?lang=en-US)
- [Unity chunk iteration](https://docs.unity.cn/Packages/com.unity.entities%401.0/manual/iterating-data-ijobchunk.html)
- [Unreal actor relevancy](https://dev.epicgames.com/documentation/en-us/unreal-engine/actor-relevancy-in-unreal-engine)
- [SUMO microscopic and mesoscopic models](https://sumo.dlr.de/docs/Theory/Traffic_Simulations.html)
- [SUMO mesoscopic runtime model](https://sumo.dlr.de/docs/Simulation/Meso.html)
- [Reynolds, local flocking behavior](https://www.red3d.com/cwr/papers/1987/boids.html)
- [Valve, The AI Systems of Left 4 Dead](https://steamcdn-a.akamaihd.net/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf)
- [Riot Games, The Tech Behind Swarm](https://www.riotgames.com/en/news/the-tech-behind-swarm)
- [poncle development roadmap](https://store.steampowered.com/news/posts/?enddate=1648165599&feed=steam_community_announcements)
- [Deep Rock Galactic: Survivor, Endless Mode Postponed](https://store.steampowered.com/news/posts/?enddate=1742819828&feed=steam_community_announcements)
- [Godot Web export constraints](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_web.html)

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Are all logs commit/version linked and durable? | No. Raw `build/**` is ignored; 163 local performance JSON files include 105 full commits, one short commit, and 57 missing commits. Capture manifests omit commit data. CI evidence expires after one day. | `.gitignore`, recorder/manual wrapper, capture driver, CI workflow, local census | Auto-create common provenance, track a ledger and selected decision-changing raw JSON, keep noisy/local artifacts ignored. | 1.1-1.4 |
| Can a future agent compare evidence? | Selected metrics are manually pinned in plans, but there is no central machine-readable index or artifact hash. | Current plans and evidence docs | Plans reference evidence IDs; comparison tooling rejects incomplete provenance. | 1.2-1.4 |
| Can normal play explain performance and UI/UX problems? | No. Combat and engagement telemetry is in-memory, and UI signals are not persisted. No HTTP/analytics/consent path exists. | Runtime signal audit and logging research | Add bounded local session summaries plus explicit export; do not add remote upload. | 1.5-1.8 |
| What does category slot mean? | The catalog owns six categories and real compatibility subslots; current UI flattens acquisition order into a global grid. | Catalog, RunBuild, snapshot builder, build rail | Six grouped capacities `2/5/2/3/5/4` with semantic positions; no equipment action or rule change. | 2.1-2.4 |
| Are the current category labels ordinary-player language? | Not fully. Secondary sounds manual, Activated does not explain input, Element is inaccurate for Bio Toxin, and Combat Conditions sounds like a stage rule. | Actual 28-card catalog plus Antigravity 3.6 Flash review | `주무장 / Main Gun`, `자동 무장 / Auto Weapons`, `공격 효과 / Attack Effects`, `직접 발동 / Active Skill`, `차체 강화 / Chassis`, `전술 특성 / Combat Perks`. | 2.1-2.4 |
| Why can the opening feel empty? | First cue is `5.1s`, birth is `6.0s`, and births remain offscreen at long distance. | Stage packets, pacing validator, allocator | Six-unit immediate offscreen opening; visible by `3.5s`, three visible by `6s`. | 3.1, 4.1 |
| Do ordinary enemies continue through the boss? | Existing actors do, but quota seal blocks all new ordinary admission. Post-boss cue is immediate yet still offscreen. | `VehicleRun`, encounter runtime, continuity validator | Maintain 8-12 ordinary exact actors from authored reserve during boss; immediate next-stage refill. | 3.2, 4.2-4.3 |
| Are irrelevant enemy-related calculations still running? | Yes. Full aggregate, schedule, pressure, contact, and capacity scans repeat; a 5 Hz Anomaly target-count scan exists only for world-chip text. | Runtime trace and current performance evidence | Instrument scan counts, remove the world-chip scan, disable diagnostic pressure work when unconsumed, then optimize only measured owners. | 3.3, 4.4-4.7 |
| Are Anomaly effects and images readable? | Purge is removed and Gravity/Cryo now last `5/3s`, but Decoy still overlaps Gravity semantically and all outcomes share body art. | Mystery runtime/renderer/spec plus user decision | Remove Decoy; add Weakpoint `420px/5s/1.25x`; approve and integrate three centered PNG symbols after reveal. | 5.1-5.5 |
| Is the Transit Gate visually clean? | The current 192x192 PNG has an uneven stepped outer contour while its circular identity and runtime footprint are correct. | Production asset, original-detail inspection, workbench comparison | Approve one cleaner same-size PNG and replace only the visual asset without changing behavior or geometry. | 5.3-5.5 |
| Why do gameplay messages look inconsistent? | HUD uses an 18 px label inside ToastSurface; renderer owns separate world-chip text and continuous target counts. | HUD/renderer/run trace | One 22 px bold text-only HUD queue with semantic colors; remove world chips. | 5.6 |
| Which objects should hover/pulse? | Map pickups have frame-rate-dependent bob; Anomaly Devices have none. XP shards and effects can be numerous. | Pickup/device renderer trace and accessibility references | Time-based bounded motion for map pickups and Anomaly only; shared subtle contour and static reduced-motion replacement. | 5.7 |
| Is rendering the current crowd bottleneck? | No. Latest draw/frame/render values pass while physics p99 fails. | `4f7f7acd` production replay and dense-enemy evidence | Do not prioritize MultiMesh, art reduction, or renderer replacement. | 3.1, 4.4-4.7 |
| Why does p99 fail at only 43 actors? | Several rich exact-simulation jobs coincide; current detailed timing samples every seventh physics tick and is not inherently correlated with the slowest ticks. | `VehicleRun`, recorder JSON | Add low-overhead every-tick coarse attribution and a bounded top-32 slow-tick receipt before choosing more code. | 3.1-3.3 |
| Which current owners deserve first inspection? | Enemy/grid, encounter/pursuit, and scheduled ordinary are the three largest named p99 owners. Schedule, pressure, and overlap code still include repeated or capacity-wide work. | Current source and JSON | Correct one measured owner at a time; keep exact narrow phase and deterministic behavior. | 4.4-4.7 |
| Should all 320 authored units become exact again? | The previous dual-state typed-GDScript migration was slower; current virtual reserve fixed catastrophic density but p99 remains red. | Dense architecture option study and implementation history | First make 48 exact stable. Then measure 64/96/128 without shipping them. Native code is an approval-only escalation. | 6.1-6.3 |
| Do native fixes automatically fix GitHub Pages and itch.io? | Source fixes export to both, but Web is single-threaded WebAssembly/Compatibility and must be measured separately. | Export preset, workflow, Godot Web docs | Same-commit local built-Web and deployed verification are mandatory. | 7.1-7.4 |

Readiness statement:

- Product behavior, category capacity, evidence retention, hot-owner selection, escalation, and
  validation decisions are closed.
- The existing Godot runtime, PowerShell, Git, capture/export tooling, and current assets are enough
  for Phases 1-4 and 6-7. Phase 5 may promote three new outcome-symbol PNGs and one replacement
  Transit Gate PNG through the existing visual workflow. No new dependency is authorized.
- The only conditional implementation branch is evidence-driven owner selection in Phase 4; its
  allowed responses and rejection rules are fixed below.

## Tasks

### Phase 1: Durable commit-linked evidence

Goal: ensure every decision-changing result can be found, verified, and compared without relying on
a filename or one agent's memory.

Preconditions:

- Current raw artifacts remain untouched under ignored `build/`.
- Existing Actions artifact retention remains one day.

Source owners: `scripts/performance/vehicle_performance_recorder.gd`,
`scripts/performance/vehicle_manual_performance_trace.gd`,
`scripts/vehicle/vehicle_run_capture_driver.gd`, `tools/run_manual_performance_trace.ps1`, new
`scripts/diagnostics/vehicle_build_identity.gd`,
`scripts/diagnostics/vehicle_session_signal_recorder.gd`,
`scripts/diagnostics/vehicle_session_diagnostic_store.gd`,
`scripts/diagnostics/vehicle_diagnostic_exporter.gd`, Settings/Result export consumers,
`tools/performance/`, new `tools/diagnostics/`, new `.agents/evidence/performance/evidence/`, and new
`.agents/evidence/performance/vehicle-performance-evidence.jsonl`

- [x] **1.1 Define and validate one provenance envelope.**
  - Change: add an evidence ID and common fields for full commit, source cleanliness including
    untracked source files, branch/ref, UTC start/end, command, artifact kind, schema/tool version,
    scenario, seed/fingerprint, warmup/sample duration, OS/Godot/GPU/renderer, logical/window
    viewport, focus/visibility/headless state, Web user agent/build hash when applicable, and
    process-isolation preflight. Record `scenario_valid`, `authority_eligible`,
    `thresholds_passed`, and final status separately. Export tooling writes an ignored
    `data/generated/vehicle_build_identity.json` before packaging; runtime reads it through the
    build-identity owner. Direct editor play without the generated file or wrapper environment uses
    `dev_unknown`, never a guessed commit.
  - Accept: a validator rejects a missing/short commit, unknown cleanliness, absent workload,
    unsupported viewport, missing authority data, or a status inferred only from a filename.
  - Guard: generated output under ignored `build/` does not itself make source cleanliness dirty.
- [x] **1.2 Add the tracked append-only ledger.**
  - Change: add one JSON Lines entry per retained evidence set. Store metrics, raw artifact paths,
    SHA-256, byte size, plan checkpoint, and supersedes relation. Plans cite evidence IDs.
  - Accept: tooling can select comparable records by scenario and reject different seeds,
    workloads, viewports, renderer modes, or authority classes.
- [x] **1.3 Promote only evidence that changes a decision.**
  - Change: copy authoritative pass/fail JSON and any diagnostic explicitly cited by a durable plan
    into `.agents/evidence/performance/evidence/<evidence-id>.json`; keep routine logs, screenshots, invalid
    experiments, and repeated raw output ignored. The ledger hashes both tracked and local raw data.
  - Accept: if the original `4f7f7acd` raw result is present, import it with its original hash and
    explicit `authoritative_fail` status. If it remains unavailable, the final same-release-source
    authority evidence records its own evidence ID, SHA-256 and full commit plus
    `supersedes: 4f7f7acd historical checkpoint unavailable`; never reconstruct the missing bytes
    from prose.
  - Guard: no bulk import of all 163 historical files and no CI retention increase.
- [x] **1.4 Make all producers use the envelope.**
  - Change: synthetic recorder, manual wrapper, capture manifest, Web build info, and evidence
    promotion command share one evidence ID. Remove optional environment-only commit provenance;
    the wrapper resolves it and the recorder refuses release authority when it is missing.
  - Accept: a synthetic run, manual diagnostic, capture, and Web build each pass focused provenance
    validators and emit linked metadata.
- [x] **1.5 Add a versioned bounded session signal recorder.**
  - Change: add the immutable event envelope and registry from the logging research report. Record
    only declared lifecycle events; accumulate 1 Hz encounter state, Upgrade focus behavior,
    announcement delivery, Anomaly results, and performance context into bounded stage/run summaries.
    Use monotonic sequence/time and semantic IDs, never localized text or dynamic event names.
  - Accept: reset/reuse tests prove no state leaks between runs; event/schema versions are explicit;
    a fixture reproduces opening, boss, Upgrade, announcement, Anomaly, and Result summaries; normal
    play allocates no per-frame event Dictionary and performs no event file I/O.
- [x] **1.6 Persist a capped local session ring.**
  - Change: write completed session bundles under `user://diagnostics/`, retaining the newest 20
    completed sessions subject to 25 MB and 14 days. Flush at safe lifecycle boundaries and normal
    exit. Record incomplete termination when it can be detected; never touch saves or settings.
  - Accept: native and Web storage round trips pass; oldest-first eviction is deterministic; a
    corrupt/incompatible record is quarantined or skipped without blocking the game.
- [x] **1.7 Add explicit redacted export, not upload.**
  - Change: add one localized `Export Diagnostics` action in Settings and Result. Native writes a
    chosen bundle; Web downloads it. The bundle contains selected session JSONL, summary, registry
    version, and build identity. It excludes raw paths, free-form text, stable device/player IDs,
    exact routes, IP/browser fingerprinting, and secrets.
  - Accept: export is user-triggered, works in Korean/English and supported layouts, and no
    `HTTPRequest`, analytics SDK, background retry, or automatic network path is reachable.
- [x] **1.8 Add comparison and interpretation tooling.**
  - Change: validate a diagnostic bundle, summarize the signal-to-hypothesis table, and compare only
    records with compatible schema, content fingerprint, scenario/phase, viewport class, locale/UI
    configuration, renderer, and sampling mode. Preserve sample weights when sampling exists.
  - Accept: tooling rejects an incompatible comparison and produces concise opening-gap, boss-gap,
    slow-tail, category-decision, announcement, and Anomaly summaries from the canonical fixture.

Batch gate:

- Ledger/session parsers, provenance/privacy/retention/export validators, `git diff --check`, and
  round trips from temporary raw evidence and local session records pass. No authoritative timing
  run occurs in this phase.

### Phase 2: Six category-owned upgrade slot groups

Goal: make Upgrade and Result show what kind of build the player owns, not merely when cards were
picked.

Preconditions:

- Phase 1 source changes are committed or otherwise isolated from UI timing work.
- The visual authority pair remains unchanged and the 28 current raster assets are reused.

Source owners: `scripts/cards/vehicle_upgrade_catalog.gd`, `scripts/cards/vehicle_run_build.gd`,
`scripts/cards/vehicle_build_snapshot_builder.gd`, `scripts/ui/vehicle_upgrade_build_rail.gd`,
`scripts/ui/vehicle_upgrade_build_cell.gd`, Upgrade/Result consumers, localization, product/visual
specs, and focused upgrade/capture validators

- [x] **2.1 Put capacity truth beside compatibility truth.**
  - Change: publish catalog-order category descriptors and simultaneous capacities
    `2/5/2/3/5/4`, including the exact semantic position keys, selected localized heading keys, and
    accessible description keys defined above. Validate them against the 28-card roster and
    optional-secondary, attribute, and active-kind compatibility rules.
  - Accept: no UI file counts cards or infers compatibility from localized category text.
- [x] **2.2 Freeze grouped build records.**
  - Change: snapshot builder emits ordered category records with category ID/key, capacity, and
    fixed slot entries `{slot_key, record}`. Optional-secondary acquisition order assigns only
    `optional_0/1`; every other record maps by catalog ID or existing slot-kind metadata. Preserve a
    deterministic flat `upgrades` projection in category/slot order for the current Ship Status
    summary; it is not a rail-layout source.
  - Accept: every unique card appears once, fixed positions never move, optional positions remain
    stable, a level-up updates in place, and occupancy never exceeds capacity.
- [x] **2.3 Render grouped sections in the shared rail.**
  - Change: replace the global progressive capacity with six labeled grids. Use at most four
    columns per group; five-slot groups wrap from one shared left edge. Use `22/24/26 px` cells and
    `16/18/20 px` artwork in compact/standard/large modes, no in-cell level text, and no internal
    scrollbar. Keep filled-only focus and one popover.
  - Accept: zero upgrades shows all 21 empty categorized positions; a mixed fixture fills the exact
    category positions with existing artwork; headings distinguish automatic weapons, attack-added
    effects, direct activation, and conditional perks; no image or popover is clipped.
- [x] **2.4 Reuse and localize the corrected rail everywhere.**
  - Change: Upgrade and Result use the same grouped snapshot/rail. Update Korean/English strings only
    to the locked label/description set; update `DESIGN.md`, `VISUAL_SYSTEM.md`, product and upgrade
    specs to retire the global progressive-grid and old category-copy contracts.
  - Accept: keyboard/controller traversal never lands on an empty slot, locale switching refreshes
    headings and popover content, and choice selection remains the only mandatory action owner.

Batch gate:

- Focused upgrade-system, build-snapshot, upgrade-UI, result-builder, result-UI, localization,
  accessibility, capture, headless import, and visual-authority checks pass.
- Rendered Korean/English evidence covers empty, mixed, full-capacity-category, Result, compact, and
  200% text states. Inspect alignment, padding, scroll containment, focus, clipping, and popover
  placement.

### Phase 3: Gameplay truth and tail-correlated baselines

Goal: prove the opening, boss, post-boss, UI, Anomaly, and slow-tick problems under the new evidence
schema before changing their behavior.

Preconditions:

- Phase 1 provenance/session signals are available.
- Phase 2 is complete and broad UI/capture work is quiet.

Source owners: `scripts/vehicle/vehicle_run.gd`, performance recorder/manual trace, session signal
recorder, scenario fixtures, engagement telemetry, and their validators

- [x] **3.1 Add bounded slow-tick receipts.**
  - Change: while a recorder/manual trace is active, measure the five coarse physics sections on
    every tick. Retain only the top 32 ticks in fixed preallocated columns. Each receipt includes
    physics serial, total and coarse section times, exact/visible counts, due/critical counts,
    decision/motion phase, pursuit rebuild state and processed cells, overlap owners/candidates,
    spawn/cue counts, projectile/effect counts, and scan counts by owner.
  - Accept: no per-tick Dictionary/Array allocation is added to shipping play; output Dictionaries
    are created only when the report is finalized.
- [x] **3.2 Keep deep attribution opt-in and reproducible.**
  - Change: retain current low-rate detailed timers for the first run. Add a named deep mode that
    times only the selected coarse owner on every tick in a same-seed rerun.
  - Accept: a receipt identifies whether current p99 aligns with pursuit rebuild, frame aggregate,
    pressure scan, schedule/due phase, contact scan, overlap snapshot/query, spawn materialization,
    Anomaly query, or a non-enemy section.
  - Guard: no profiler mode may change actor cadence, spawn order, collision, or decisions.
- [x] **3.3 Add deterministic opening and boss-overlap captures.**
  - Change: capture cue, birth, first-visible, first-commit/damage, visible-gap state, exact/active
    counts, reserve/queue, boss slot margin, and scan counts at `0/1/3.5/5/6/8/15/30s`; add quota,
    boss-warning, boss-active, boss-defeat, and three-second post-boss checkpoints.
  - Accept: the baseline demonstrates current behavior without using the stage-5 steady-state
    `production_replay` as proof of opening or boss pacing. Capture output is one session/evidence ID.
- [x] **3.4 Record clean performance and UI/Anomaly baselines.**
  - Change: run one 10-second warmup plus 30-second diagnostic `production_replay` at `1280x720`,
    native Compatibility, cap 48. Record Upgrade decision fixture, announcement burst fixture, and
    each current Anomaly outcome under the same schema family.
  - Accept: workload/authority fields and top-tick receipts are valid; selected Phase 4 hot owners
    and Phase 5 visual baselines are written into this plan before behavior/source changes.

Batch gate:

- Performance, session-signal, encounter-pacing, boss-overlap, Upgrade, announcement, and Anomaly
  validators pass. Instrumentation-off normal play has zero receipt/scan-count work;
  instrumentation-on fixture gameplay counts remain identical.

### Phase 4: Continuous pressure and measured runtime corrections

Goal: remove the visible empty intervals, keep bounded ordinary pressure during bosses, and bring the
new exact-48 workload below the existing p99 limit without weakening combat truth.

Preconditions:

- Phase 3 proves the baseline and identifies selected hot owners.
- Only one performance candidate owner changes between comparable measurements after the locked
  encounter behavior lands.

Source owners: stage packet data, encounter director/runtime, spawn allocator, stage flow,
`VehicleRun`, and the selected subset of pursuit field, enemy update schedule, spatial grid, contact,
and enemy store

- [x] **4.1 Replace the delayed one-unit opening.**
  - Change: implement the locked six-unit `0.0s` cue/`0.9s` birth opening, beat-zero caps of six,
    `4.0s` normal surge start, nearest safe offscreen placement, and authored-sequence subtraction.
  - Accept: deterministic no-input first visible at most `3.5s`, at least three visible by `6s`, and
    first commitment/contact at most `8s`; no on-screen birth, authored total, quota, role identity,
    or max-four-births-per-tick invariant changes.
- [x] **4.2 Replace quota seal with boss maintenance pressure.**
  - Change: add the locked 8/12 low/high watermark mode. It drains admitted rounds, consumes next
    authored reserve identities in groups of at most four no more frequently than every four seconds,
    holds the boss slot margin, and stops when the boss phase ends.
  - Accept: boss and ordinary actors coexist; quota remains sealed at its reached value; exact count
    and attack commits stay bounded; a long boss fixture never fabricates identities or deadlocks the
    boss arrival.
- [x] **4.3 Guarantee immediate post-boss continuation.**
  - Change: preserve surviving ordinary state, stop old-stage maintenance, configure the next stage,
    and cue its six-unit continuation opening in the same gameplay frame.
  - Accept: if no survivor is visible, an ordinary center enters view within `3.0s`; player state,
    projectiles, XP, active-run clock, ordinary survivors, and Result timing retain their contracts.
- [x] **4.4 Remove unconsumed scans and event-own cheap aggregates.**
  - Change: stop building diagnostic pressure sectors/near/visible data at 60 Hz when no recorder or
    HUD consumer needs it. Replace unconditional frame count/family recounts with spawn/death/
    activation-owned counters where receipts select them. Keep threat radar readiness on its declared
    cadence until parity proves a safe index.
  - Accept: normal play performs no diagnostic pressure scan; authoritative cap/admission/commit
    counts remain exact; pressure signals keep their schema/cadence when recording is enabled.
- [x] **4.5 Make pursuit rebuild cost explicit and phase-bounded when selected.**
  - Change: preserve exact walkability and the `0.20s` refresh contract, but give each rebuild a hard
    per-tick work budget and stable phase that does not coincide with session sampling or the largest
    ordinary-decision group. Never discard a pending player target. Record `not selected` if receipts
    do not choose this owner.
  - Accept: reachability/direction oracles pass and top-32 receipts contain no pursuit burst above its
    selected budget.
  - Result: not selected. The clean cap-48 deep-pursuit diagnostic reports p95/p99
    `0.969/1.339 ms`; the current owner already preserves the `0.20s` refresh, pending target and a
    hard `512`-cell-per-tick budget. The larger selected costs remain scheduled ordinary/enemy work,
    so adding another pursuit phase owner would not satisfy the candidate gate.
- [x] **4.6 Snapshot only live local-overlap members when selected.**
  - Change: maintain a compact active-slot list on membership changes and snapshot only those slots;
    rebuild only marked owner rows. Keep exact distance/body predicates, stable tie order, maximum
    eight neighbors, and stale-generation rejection. Record `not selected` if appropriate.
  - Accept: 320-slot capacity buffers remain fixed but work scales with live members; grid and
    steering parity fixtures pass.
- [x] **4.7 Replace full schedule/contact reconstruction only when receipts still select it.**
  - Change: use persistent membership plus due stamps for existing `60/30/20/10 Hz` lanes and/or a
    revision-driven active contact list only for the owner that remains material after 4.4-4.6. One
    canonical enemy truth remains; do not mirror a second complete mutable state.
  - Accept: membership updates once, due order/accumulated delta/contact semantics match oracles,
    deterministic replay matches, and no per-tick sort/Dictionary rebuild is introduced.

Candidate measurement gate:

- First record the changed opening/boss workload as the new comparable baseline; do not compare its
  timing directly with the old sparse workload as an optimization claim.
- Use one same-environment 30-second diagnostic before and after each selected runtime correction.
- Retain a candidate only when its named-owner p99 improves at least 15%, overall physics p99 does
  not worsen by more than `0.25 ms`, fixture counts match, and no other coarse owner absorbs the
  removed cost. Otherwise revert only that task-owned candidate before the next hypothesis.
- After all retained corrections, run one clean 10-second warmup plus 60-second authoritative native
  `production_replay`. Phase 4 passes only at physics p95 at most `6 ms` and p99 at most `8 ms`, and
  the opening/boss/post-boss visibility gates still pass.

### Phase 5: Readable Anomaly, announcement, and interaction feedback

Goal: make neutral objects and gameplay messages readable without creating a second UI language or
moving gameplay truth.

Preconditions:

- Phase 4 encounter continuity and runtime-owner corrections are stable.
- The canonical visual authority pair has been re-read and its reference image hash verified before
  generating or reviewing any Anomaly raster.

Source owners: Mystery Device runtime, `VehicleEnemyState`, VehicleRun damage and targeting,
outcome assignment/spec, world asset manifest/catalog/provider, combat renderer, Transit Gate
presentation, HUD notification queue, map-pickup presentation, localization, accessibility,
capture/workbench, and focused validators

- [x] **5.1 Remove Projectile Purge and lengthen Gravity/Cryo.**
  - Change: remove Projectile Purge from assignment/runtime/presentation/localization/guidebook;
    set Gravity Pull to `5.0s` and Cryo Lock to `3.0s`; keep reused membership buffers and the
    bounded entrant refresh.
  - Accept: Gravity/Cryo state and footprints retire on the same tick; boss/fixed-structure
    exclusions remain; no purge event/asset/string/capture branch remains; five-second Gravity adds
    no per-tick allocation or unbounded radius scan.
- [x] **5.2 Replace Decoy Signal with Weakpoint Expose.**
  - Change: update `VehicleMysteryDeviceRuntime.OUTCOME_IDS` and `OUTCOME_PROFILE` to
    `weakpoint_expose` at radius `420` for `5.0s`. Replace VehicleRun's `_mystery_decoy_*` target and
    membership state with a reused Weakpoint membership buffer. Add and pool-reset
    `VehicleEnemyState.mystery_weakpoint_remaining`; refresh it from current field membership and
    decrement it with the other scalar enemy timers. In `_damage_enemy`, multiply non-final,
    player-owned damage to an affected ordinary mobile enemy by `1.25`; preserve existing shield and
    rammer multipliers, boss damage rules, telemetry, lifesteal, recharge, and mine behavior. Remove
    Decoy-only pressure-focus, movement-focus, route-bypass, attack-target, facing, capture,
    localization, guidebook, and validator branches. Add Korean `약점 노출` and English
    `Weakpoint Expose` strings and describe `받는 피해 +25% / Damage taken +25%`.
  - Accept: each stage assigns Gravity/Cryo/Weakpoint exactly once; enemies inside radius at
    activation or a bounded refresh retain Weakpoint for the remaining field lifetime; player-owned
    direct, area, secondary, active, and status damage receive the same multiplier; hostile and
    environmental damage do not; bosses/fixed structures do not; movement, targeting, attack timing,
    quota, XP, drops, and collision remain unchanged; no `decoy_signal` runtime/string/capture/test
    branch remains.
- [x] **5.3 Generate grounded symbol and Transit Gate review PNGs.**
  - Change: use the canonical reference PNG as actual ImageGen reference input to generate Gravity,
    Cryo, and Weakpoint centered symbols plus one clean Transit Gate replacement. Store transparent
    192x192 candidates, source/provenance hashes, exact prompts, grayscale views, runtime-scale views,
    and AS-IS/TO-BE comparisons under
    `docs/design/visual-replacement-workbench/previews/mystery-device-outcomes-v4-symbols/` and
    `docs/design/visual-replacement-workbench/previews/transit-gate-v2-clean/`. Archive the rejected
    Decoy V3 evidence. Do not use SVG or ImageMagick drawing.
  - Accept: the three symbols read as converge/freeze/open-armor at the original comparison scale and in
    grayscale; the gate is a smooth uniform circle at 192x192; all candidates have transparent alpha,
    recorded hashes, canonical-reference evidence, and remain outside production. Evidence passed on
    2026-08-14; production approval is intentionally separate.
- [x] **5.4 Obtain exact approval and promote the four PNGs.**
  - Change: present `device-overlay-preview.png`, Anomaly full/runtime/grayscale comparisons, and the
    Transit Gate AS-IS/TO-BE comparison. The user explicitly approved both complete comparison sets
    on 2026-08-14. Copy the three symbols to
    `art/visuals/production/gameplay/world/mystery_device_gravity.png`,
    `art/visuals/production/gameplay/world/mystery_device_cryo.png`, and
    `art/visuals/production/gameplay/world/mystery_device_weakpoint.png`; replace
    `art/visuals/production/gameplay/world/facility_transit_gate.png`; add the three semantic
    manifest/provider/catalog descriptors; and update workbench technical ledgers with exact
    production hashes. Do not promote a partial or modified set without refreshing the comparison
    and approval evidence.
  - Accept: approved bytes and ledger hashes match production exactly; the three new symbol IDs and
    existing Transit Gate ID resolve once; the manifest contains 80 semantic PNGs plus three approved
    SurfaceDetail SVGs; rejected/intermediate/chroma files remain outside production.
- [x] **5.5 Integrate visible attackable symbols, Weakpoint feedback, and the clean Gate.**
  - Change: render exactly one assigned approved Gravity/Cryo/Weakpoint symbol alone at `288`
    world units from initial placement through active-effect retirement. The symbol itself is the
    attackable facility. Never draw a black casing, pristine/damaged body, wreck, or first-hit
    reveal. Reuse the existing enemy
    status compositor for a restrained same-size Weakpoint danger layer. Keep the full code-native
    Gravity/Cryo/Weakpoint disks at exact `480/360/420` radii for `5/3/5s`. Preserve the neutral
    minimap marker and Transit Gate geometry/behavior. Update capture fixtures, guidebook preview,
    asset coverage, accessibility, localization, map integration, renderer, and visual-authority
    validators.
  - Accept: the assigned outcome is visible before any hit; visible authored-image count is exactly
    one; the symbol bobs with one thin breathing contour while collision stays fixed; destruction
    alone activates the effect; symbol/effect lifetimes are correct;
    full areas remain visible; color-blind and reduced-motion captures retain shape/text/footprint
    cues; the Gate has no wobble at actual size; no asset is stretched or clipped; no per-enemy node,
    material, batch, allocation, or extra radius scan is added.
- [x] **5.6 Collapse gameplay announcements into one text-only queue.**
  - Change: remove ToastSurface chrome and renderer world chips; render one 22 px weight-800 centered
    HUD label with semantic color and restrained contrast treatment. Add semantic kind, priority,
    dedup/coalescing, and queue receipts; compute Anomaly affected count once at activation.
  - Accept: boss, danger, system, reveal, activation, barrier, upgrade-complete, and shield-down
    messages all use one structure; priority is deterministic; no 5 Hz target-count scan or duplicate
    text remains; Korean/English and 200% text do not clip.
- [x] **5.7 Add bounded time-based interaction motion.**
  - Change: implement the locked bob amplitudes/periods and one reused alpha-mask contour material for
    map repair/recall pickups and Anomaly Devices only. Stable ID phase offsets drive presentation
    from elapsed run time.
  - Accept: collision, collection, damage, effect, and minimap positions never move; Reduced Motion is
    static; no XP-shard/enemy/projectile/gate path is added; draw-call, batch, frame, and GPU gates do
    not regress.

Batch gate:

- Mystery runtime, assignment, facility, projectile store, renderer, HUD notification, pickup,
  minimap, localization, guidebook, accessibility, capture, asset-manifest, visual-authority,
  headless import, and diff checks pass.
- Rendered Korean/English evidence covers hidden, each reveal, each active effect near start/end,
  message priority burst, pickups/devices in motion, Reduced Motion, compact/large viewports, and
  200% text. Inspect silhouette, edge restraint, collision/footprint truth, clipping, and contrast.

### Phase 6: Measure scalable exact-enemy headroom

Goal: answer how many rich Cardborne enemies the corrected portable runtime can truly support,
without changing the shipping balance.

Preconditions:

- Tasks through 6.1 and the final focused source batch pass. Run the clean cap-48 native authority
  gate from the release-source commit before starting the staircase; that one result also satisfies
  Task 7.2. Do not rerun it after the staircase unless a release-source input changes.
- No design, capture, export, browser, or unrelated Godot process contaminates timing.

Source owners: performance scenario overrides and evidence ledger only; production stage caps remain
unchanged

- [x] **6.1 Add non-shipping exact-cap overrides.**
  - Change: performance scenario can request 48, 64, 96, or 128 exact ordinary actors while keeping
    the same role mix, deterministic seed, combat truth, viewport, and timing gates. The override is
    unreachable from normal play and excluded from saved product data.
  - Accept: each result labels exact count, authored reserve, workload fingerprint, and
    `diagnostic_only` status; scenario validation rejects a missed target count.
- [x] **6.2 Run the capacity staircase with an early stop.**
  - Change: run 30-second diagnostics in ascending order. Stop at the first tier whose p95 exceeds
    `6 ms`, p99 exceeds `8 ms`, or correctness/count validation fails. Do not run higher tiers.
  - Accept: ledger records the last passing and first failing tier with comparable provenance.
- [x] **6.3 Make the next architecture decision from the envelope.**
  - Change: if 96 or 128 passes, document the technical headroom and leave shipping cap 48 pending a
    separate gameplay/balance decision. If 64 fails, prepare a narrow approval request for a
    single-truth packed native kernel; do not implement it in this plan.
  - Accept: the conclusion distinguishes technical capacity, visible pressure, authored reserve,
    and shipping difficulty.

Batch gate:

- The staircase cannot modify product resources or export presets. `git diff` after the run contains
  only ledger/evidence additions.

### Phase 7: Same-commit native and Web release proof

Goal: prove the corrected source behaves in the local editor/runtime and in both deployed Web copies.

Preconditions:

- Phases 1-5 and Task 6.1 pass. Run 7.1 and 7.2 first; their clean release-source checkpoint unlocks
  Tasks 6.2-6.3, followed by 7.3-7.4. This dependency order avoids a second unchanged authority run.
- All release source, UI and runtime documentation changes are committed; worktree source is clean.
  Staircase and authority evidence are appended afterward without changing the release-source tree.

Source owners: focused validators, capture driver, `tools/export_web.ps1`, export preset, GitHub
workflow, evidence ledger, deployment build info

- [x] **7.1 Run the final focused and integration batches.**
  - Change: run affected performance, evidence/session, encounter opening/boss/continuity, pursuit,
    schedule, spatial, combat, Anomaly, upgrade, result, HUD, localization, accessibility, capture,
    asset, and document-authority validators; then headless import and diff checks.
  - Accept: all pass with no parser error or new warning attributable to this work.
- [x] **7.2 Run final native authority once.**
  - Change: on the final clean release-source commit, run the 10-second warmup plus 60-second cap-48
    `production_replay`; preserve raw JSON for later promotion and ledger entry. This result is also
    the Phase 6 cap-48 prerequisite and is not repeated when the source tree is unchanged.
  - Accept: scenario/authority/count checks pass; physics p95/p99 pass `6/8 ms`; frame, render,
    memory, draw-call, and batch gates pass.
- [ ] **7.3 Export and test the built Web game.**
  - Change: run the Web export, production-style local host, and one focused/visible 10-second
    warmup plus 60-second `production_replay` at `1280x720`. Read the published Web result, and
    record browser user agent, headless state, Web build/PCK hash, focus, scheduler throttling, and
    exact commit.
  - Accept: the built-Web result is authority-eligible, scenario/count-valid, and
    `thresholds.passed == true`; opening/boss/post-boss, diagnostic export, controls, and UI smoke
    pass with no console/runtime error. A headless, hidden, throttled, or incomplete run is diagnostic
    only and cannot satisfy this task.
  - Status: the exact `e0962d7e` Web export and authority capture are complete, but the valid visible
    result failed both simulation and frame thresholds. Per the release stop rule, the remaining
    manual smoke and Task 7.4 are blocked until an approved architecture change produces a new clean
    release-source commit.
- [ ] **7.4 Verify GitHub Pages and itch.io from the same build.**
  - Change: deploy only after 7.1-7.3 pass. Deploy the exact release-source commit qualified by 7.2
    and verify both public surfaces report the same commit/build
    hash and complete a short manual combat smoke including early visibility, boss overlap or its
    deterministic fixture, Upgrade category slots, Anomaly/messages/motion, diagnostics export, and
    Result.
  - Accept: neither deployment uses stale assets/code; observed behavior matches the local built
    Web artifact; evidence IDs and URLs are recorded without increasing artifact retention.

Final gate:

- Run the diff-scoped codebase-quality audit. Correct only small task-owned ownership, unreachable
  failure, competing-owner, or contract gaps.
- After public verification, append durable product/visual/performance findings, promoted evidence,
  ledger rows and final plan state in one record-only commit. That commit may follow the deployed
  release-source commit because evidence cannot include its own future commit hash. Do not rebuild or
  redeploy the unchanged game for the record-only commit. Mark this plan `done` only when the release
  source commit, record commit, evidence IDs, native result, built-Web result and both deployment
  hashes are recorded.

### Phase 8: Player-visible combat and build corrections before release proof

Goal: correct the remaining live-play regressions before any further performance qualification or
public release. This phase supersedes Phase 2's fixed visual slot positions while preserving its six
category capacities and compatibility rules. It also reopens Phase 4's visible-pressure acceptance
because live play still reports empty intervals despite the earlier deterministic fixture passing.

Execution order: 8.1-8.2 may land together; 8.3 must land before 8.4; 8.5 lands after gameplay radii
are authoritative; 8.6 is the final source and rendered gate. Do not run a performance scenario
until every Phase 8 source, visual, and focused validation task is complete on one clean commit.

Source owners: upgrade catalog/build snapshot/shared build rail and localization; encounter
runtime/director/stage-flow integration; one narrow stage-transition coordinator owned by
`VehicleRun`; secondary definitions/runtime/renderer; product and visual contracts; focused
validators and the existing capture gateways.

- [x] **8.1 Make acquired category records fill from the left.**
  - Change: keep category capacities `2/5/2/3/5/4` and gameplay compatibility unchanged, but stop
    exposing compatibility slot keys as visual gaps. Pack acquired records from index zero in stable
    first-acquisition order inside each category. A level-up updates the same record and never moves
    it; empty cells follow all filled cells.
  - Change: preserve a deterministic fallback for old in-memory builds without acquisition history,
    and use the same packed snapshot in Upgrade and Result. The rail remains image-only,
    left-aligned, four columns at most, `22/24/26 px`, without internal scrolling or empty-cell focus.
  - Accept: mixed-category fixtures prove no empty cell precedes a filled cell, the newest
    acquisition appends at the right in its category, a level-up does not reorder cells, and
    Korean/English Upgrade and Result layouts fit without clipping or scrolling.

- [x] **8.2 Make the existing EMP growth path unmistakable.**
  - Change: keep EMP as a base action, not a fake acquired upgrade. Publish a display-only equipped
    action record in the first Active Skill cell using the existing EMP action glyph; it never enters
    `levels`, `acquisition_order`, or the flat acquired-upgrade projection. An EMP replacement swaps
    that same display record.
  - Change: retain `active_coolant` and `active_amplifier`, their approved artwork, mechanics, and
    maximum levels. Rename Korean/English player copy so it explicitly states that each affects the
    default EMP and follows an EMP replacement. The first Stage 1 level-up offer while EMP is still
    equipped must contain exactly one unfinished Active enhancement, selected deterministically;
    later offers keep the normal catalog rules.
  - Accept: a fresh run shows EMP but counts zero acquired upgrades; the first eligible offer exposes
    one EMP-relevant enhancement; authored damage `62 -> 93` and cooldown `13s -> 9.75s` remain true
    at maximum enhancement; a replacement receives each shared modifier exactly once.

- [x] **8.3 Remove ordinary-enemy visibility gaps.**
  - Change: treat visible pressure as a maintained invariant, not only a cue/queue invariant. Keep
    the authored time-zero opening, but select the nearest valid offscreen approach anchors so the
    first ordinary actor becomes visible by `3.0s`. During boss warning/active, when no ordinary is
    visible and authored maintenance reserve remains, admit the smallest authored reinforcement
    group without waiting for the current four-second maintenance interval.
  - Change: after boss defeat, preserve surviving ordinary actors and require next-stage ordinary
    visibility by `1.5s`; if none survived, the next authored opening group uses the same nearest
    valid offscreen approach path immediately. Preserve exact cap, boss-entry margin, attack-commit
    gate, quota identity, and offscreen birth rules. Do not fabricate population or spawn on camera.
  - Change: extend diagnostic-only pacing receipts with explicit reasons: no authored reserve,
    offscreen travel, queued window/spawn, capacity block, maintenance cooldown, boss warning, and
    stage transition. Normal play must not add a new whole-store scan.
  - Accept: deterministic opening, long-boss, zero-survivor, and post-boss fixtures meet the limits;
    maintenance actors never advance quota; every gap is either below the limit or has one recorded
    bounded reason; irrelevant scheduler/maintenance work stops with its lifecycle.

- [x] **8.4 Remove duplicate boss-defeat boundary work and bound the remaining transition.**
  - Change: first add diagnostic-only receipts around boss teardown, stage-report freeze, continuation
    setup, enemy flush/grid synchronization, and final Result construction. The source already proves
    that stages 1-4 call `enemy_grid.rebuild(enemies)` before queued boss defeats flush and later sync
    the grid again; replace this with one authoritative post-flush grid update.
  - Change: the lethal-damage call stack only seals the completed stage and schedules transition
    work. A small idempotent `VehicleRun` transition state performs boss teardown/report capture,
    gameplay continuation configuration, and presentation refresh in separate bounded steps if the
    receipts show they cannot safely share one frame. Surviving ordinary actors remain valid.
  - Change: final-stage Result construction is a separate step from enemy defeat and opens exactly
    once. No step scans or allocates diagnostics in normal play.
  - Accept: one boss defeat produces one report and one next-stage setup; no enemy/grid operation is
    duplicated; repeated callbacks cannot duplicate rewards or transitions; focused receipts name
    every remaining transition owner without running a broad performance scenario.

- [x] **8.5 Double optional area-secondary footprints and improve Orbiting Blades motion.**
  - Change: double linear gameplay and presentation radii for Electric Field
    (`240/280/320/320`), Drop Mines (`192/216/240/240`), and Storm Barrage (`280`). Collision,
    spatial query, telegraph, impact, snapshot, localized copy, and product/visual contracts use the
    same values. Do not change EMP, Thermal Burst, Dash Afterburn, or active replacements.
  - Change: Orbiting Blades are the only rotating optional secondary and already repeat contact
    damage. Increase angular speed from `2.45` to `3.4 rad/s` and orbit radius from `88` to `112`;
    retain blade radius `52`, per-target cooldown `0.55s`, damage, count, and authored image.
  - Guard: larger areas may increase candidate counts, but query/target/object caps, damage, cooldown,
    and update cadence do not change. This task makes no performance claim.
  - Accept: boundary tests hit at each new exact radius and miss immediately outside it; renderer
    snapshots match; mine/storm warnings match impact truth; orbit positions, angular speed, and
    per-target cooldown are deterministic.

- [x] **8.6 Run the correction gate, then defer broad performance proof.**
  - Change: run affected catalog/build/Upgrade/Result, active-weapon, secondary, encounter,
    boss-transition, renderer, localization, visual-authority, headless import, and Web-export checks.
    Capture supported Korean and English Upgrade/Result views at normal text scale and inspect
    alignment, empty-before-filled gaps, clipping, and scroll state.
  - Accept: all focused checks pass on one clean commit and rendered evidence shows the intended
    result. Only then decide whether all remaining feature/image work is complete enough to authorize
    the final native/Web performance run.
  - Stop: do not run `production_replay`, capacity tiers, or any performance scenario in Phase 8.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | One changed-owner validator plus `git diff --check` | After a coherent local change | Its relevant source changes |
| Session phase | Evidence/session/privacy/retention/export validators | Phase 1 tasks pass | Envelope, registry, persistence, or export input changes |
| UI phase | Upgrade/build/result/HUD/Anomaly/localization/accessibility validators and selected rendered states | Phase 2 or 5 tasks pass | UI/snapshot/theme/localization/asset input changes |
| Performance diagnostic | One 30-second same-scenario comparison | A measured candidate is ready | The selected owner or hypothesis changes |
| Native authority | 10-second warmup + 60-second cap-48 production replay | Final source is clean and quiet | A runtime/resource/export input changes |
| Capacity staircase | Ascending 48/64/96/128 diagnostics with early stop | Native cap-48 authority passes | Runtime or scenario input changes |
| Web final | Export, local built-Web trace, then deployed smoke | Native and source gates pass | Web/runtime/resource input changes |

Validation rules:

- Track implementation correctness and timing qualification separately.
- A valid workload can still be an authoritative failure; `authority_eligible` is not `passed`.
- Do not compare records with different workload, seed, viewport, renderer, duration, focus, or
  environment status.
- Do not rerun an expensive check after a failure until code or a named hypothesis changes.
- Do not claim Web success from native evidence, or native success from a headless Web smoke.
- Stop a timing run if unrelated heavy work, focus loss, scheduler throttling, or source dirtiness
  invalidates authority.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A retained raw artifact lacks a full commit or required workload fields | Import it as `diagnostic` or `invalid`, never authoritative | Do not repair provenance by trusting the filename |
| Category occupancy exceeds the proposed capacity | Stop Phase 2 and correct the catalog-derived capacity | Do not silently hide an acquired card or add scrolling inside one category |
| Five-slot category cannot fit at a supported width | Left-align every row, wrap after four positions, use `22/24/26 px` cells, and remove the rail's internal scrollbar | Do not move offer actions into scroll |
| Renderer becomes a measured failing owner | Record the contradiction and replan that owner | Do not preemptively replace the renderer or assets |
| Opening visibility passes but first commitment remains late | Adjust only nearest safe approach placement/entry gate within the locked `8s` acceptance | Do not spawn on-screen or raise attack-commit caps |
| Boss maintenance makes the boss unreadable or violates slot margin | Stop new maintenance admission and correct the low/high-watermark policy | Do not remove existing exact ordinary actors or bypass boss reservation |
| 4.4-4.6 make schedule/contact no longer material | Skip 4.7 and record why | Do not implement persistent membership without selection evidence |
| A candidate improves its bucket but worsens total p99 | Reject/revert the candidate and inspect transferred work | Do not keep local-looking wins |
| Cap 48 remains above p99 8 ms after Phase 4 | Stop before Web release and request approval for a narrow Web-capable native-kernel spike | Do not add threads, GDExtension, or custom templates automatically |
| Anomaly raster candidate is rejected | Keep current approved asset live, revise the candidate through the same workbench | Do not promote or hand-edit the rejected output |
| 64 fails in Phase 6 | Record 48 as the portable envelope and stop the staircase | Do not lower correctness or timing gates |
| 96/128 passes | Record technical headroom only | Shipping cap/difficulty requires a separate product decision |
| Built Web is materially slower or invalid while native passes | Keep release blocked and isolate Web-only environment/runtime cost | Do not publish a native-only performance claim |
| A verified material fact contradicts this contract | Stop the affected branch, update the plan, and obtain required approval | Executor cannot choose a new product/architecture/dependency contract |

## Risks

- The current seventh-tick detail sampling may have misranked the actual p99 trigger. Phase 3 is
  deliberately before structural work.
- Profiling itself can add cost. Coarse timing is bounded and enabled only for evidence runs; its
  overhead must be reported.
- Persistent structures can cost more than rebuilding at only 48 actors. Phase 4 retains them only
  if the measured candidate gate passes.
- A category capacity expresses maximum simultaneous unique cards, not the number of catalog cards.
  Documentation and accessibility names must make this distinction clear.
- Web single-thread performance can differ from native even when the same GDScript is exported.
  Both public deployments therefore need same-build verification.
- Selected raw JSON in Git grows repository history. Promotion is limited to authority results and
  decision-changing diagnostics; routine output remains local.
- Session logging can perturb the game if it serializes in hot paths. The selected recorder
  accumulates bounded summaries and flushes only at safe lifecycle boundaries; its disabled and
  enabled overhead must be measured.
- Five-second Gravity and three-second Cryo increase active-effect work. Membership queries must be
  reused and bounded, and the new workload must pass the same native/Web timing gates.
- Continuous edge breathing can distract or violate Reduced Motion intent. It is limited to 17
  bounded map objects, uses low amplitude/opacity, and has a static reduced-motion replacement.

## Rollback and Safety

- Implement each phase in a coherent scoped commit. Never stage, revert, clean, or overwrite
  unrelated work.
- Provenance and category-snapshot additions land before their consumers. Until migration is
  complete, the current flat snapshot remains a derived compatibility view.
- Preserve all ignored historical raw evidence. Evidence promotion copies selected files and never
  moves or deletes the originals.
- Reject and revert only a task-owned performance candidate that fails its comparison gate; never
  reset the whole worktree or weaken the benchmark.
- Keep the overall production ceiling and export settings unchanged. Only the declared beat-zero
  cap changes to six; diagnostic capacity overrides remain unreachable from normal play.
- Do not deploy until the final native and local built-Web gates pass. A failed public smoke rolls
  forward with a corrected build or uses the repository's existing recoverable deployment path; it
  never force-pushes or rewrites release history.

## Decision Notes

- 2026-08-13: raw performance/capture output is not currently a durable versioned record. The
  latest important results are manually summarized in plans, which is useful but insufficient.
- 2026-08-13: keep one-day Actions artifact retention. Durable small evidence moves into Git; CI
  storage is not used as a long-term archive.
- 2026-08-13: replace the flat 4-column progressive grid with six category sections and 21 maximum
  simultaneous positions. This corrects presentation only.
- 2026-08-13: semantic category positions replace general acquisition ordering. Retain acquisition
  order only for stable assignment of the two generic optional-secondary positions.
- 2026-08-13: keep the current virtual reserve and cap 48 while fixing p99. It solved the catastrophic
  exact-320 overload but did not meet the final tail gate.
- 2026-08-13: rendering, generic pooling, and a generic "add a spatial grid" answer are rejected as
  first work because those facilities already exist and the measured render path passes.
- 2026-08-13: do not repeat the broad dual-state typed-GDScript migration. Any future packed/native
  core must replace one canonical owner and requires approval if it changes deployment shape.
- 2026-08-13: higher exact capacity is measured only after cap 48 passes, and does not automatically
  ship.
- 2026-08-14: normal play, UI actions, and capture manifests are not currently durable
  commit/version-linked evidence. Add a bounded local `user://` session ring plus explicit export;
  remote upload remains unapproved.
- 2026-08-14: Antigravity CLI `1.1.11` does not recognize `Gemini 3.7 Flash (High)`. The requested
  fallback `Gemini 3.6 Flash (High)` reviewed category wording; repository verification selected
  `주무장`, `자동 무장`, `공격 효과`, `직접 발동`, `차체 강화`, and `전술 특성`.
- 2026-08-14: replace the delayed one-actor opening with six low-risk authored actors and preserve a
  48-actor ceiling. Maintain 8-12 authored-reserve ordinary actors during boss play and begin the
  next stage refill immediately after boss defeat.
- 2026-08-14: remove Projectile Purge and lengthen Gravity/Cryo to `5/3s`.
- 2026-08-14: replace Decoy Signal with Weakpoint Expose at `420px/5s/1.25x` player-owned received
  damage because Decoy and Gravity produced overlapping player perception. Preserve movement and
  targeting under Weakpoint and exclude bosses/fixed structures.
- 2026-08-14: use three centered triggered-state PNG symbols after the hidden neutral state rather than
  three full replacement bodies. Generate converge/freeze/open-armor candidates at 192x192 and
  separately generate a clean same-footprint Transit Gate replacement.
  The user approved the complete V4 symbol comparison and clean Transit Gate AS-IS/TO-BE comparison
  on 2026-08-14; the exact reviewed bytes may now be promoted together.
- 2026-08-14: one text-only HUD queue owns gameplay announcements. Map repair/recall pickups and
  Anomaly Devices use restrained time-based bob plus one shared contour; gameplay positions remain
  stationary and Reduced Motion uses a static contour.
- 2026-08-14: the raw `4f7f7acd` artifact is absent from both retained and ignored evidence roots.
  Promotion tooling must not reconstruct it from prose; task 1.3 remains open until a real hashable
  source exists or the final same-commit authority evidence supersedes that historical checkpoint.
- 2026-08-14: focused import, diagnostics, comparison, slow-receipt, arrival, encounter, run,
  continuity, Anomaly, HUD, renderer, map, localization, capture, and visual-authority validators
  pass on the integrated source. The final performance, rendered-evidence, Web, and deployment gates
  remain open.
- 2026-08-14: direct pacing capture initially exposed a stale generated build identity. Commit
  `934c0d72` added the canonical clean-tree wrapper and requires the runtime to match both the full
  commit and content fingerprint before recording, so a stale identity now fails instead of being
  mislabeled.
- 2026-08-14: clean pacing evidence `encounter-pacing-7ae1e2b5.json` passes all declared gates:
  cue `0.017s`, birth `0.917s`, first visible `3.05s`, five visible ordinary actors at `6s`, first
  commitment `7.17s`, and nine visible ordinary actors three seconds after boss defeat. The capture
  re-enables its diagnostic-only pressure observation after stage reconfiguration; normal play
  keeps that scan disabled.
- 2026-08-14: clean focused cap-48 diagnostic
  `934c0d72-production-replay-native-30s-deep-pursuit.json` is scenario-valid, focused, and carries
  workload fingerprint `627232438`. Physics p95/p99 are `4.598/5.741ms`; deep pursuit p95/p99 are
  `0.969/1.339ms`. It is diagnostic because the sample is 30 seconds, not a final authority run.
- 2026-08-14: the pre-switch `run-pacing-result-slots` fixture set and approved V4/Gate review
  comparisons preserve the Korean/English Upgrade, announcement, Anomaly, and Result baselines. The
  post-switch Korean 1280x720 full capture at
  `build/captures/execplan-2026-08-14-weakpoint-gate-ko-1280` provides the matching corrected
  diagnostic comparison without treating capture output as release authority.
- 2026-08-14: local-overlap snapshot work is not selected: its measured p99 is `0.584ms` at cap 48.
  Full schedule/contact reconstruction is also not selected: budget scan p99 is `0.316ms` and
  contact resolution p99 is `0.176ms`. The larger scheduled-ordinary bucket is actor policy work,
  not evidence that these two reconstruction paths should gain another mutable membership owner.
- 2026-08-14: the approved Gravity/Cryo/Weakpoint and clean Transit Gate PNG bytes are promoted with
  matching production/workbench hashes. A real-render capture found that parent CanvasItem drawing
  placed outcome symbols behind the device batch; one retained z=2 semantic layer now keeps them
  above the body and below combat overlays. That intermediate composition is superseded by BK's
  later standalone-symbol clarification below; the current renderer omits the body after reveal.
- 2026-08-14: exact-cap overrides are accepted only for diagnostic `capacity_pressure` targets
  `48/64/96/128`. Results label the observed ordinary count, authored reserve, workload fingerprint,
  and diagnostic-only state; normal play and saved product data cannot reach the override.
- 2026-08-14: the final source batch passed affected evidence, encounter, pursuit, schedule, spatial,
  combat, Anomaly, Upgrade, Result, HUD, localization, capture, asset, workbench, visual-authority,
  headless-import, and diff checks. The diff-scoped quality audit found no competing gameplay owner,
  unbounded hot-path work, stale Decoy branch, or reachable exact-cap override in normal play.
- 2026-08-14: the first clean cap-48 native authority observation on `e0962d7e` missed only the 1%
  low gate (`54.03 FPS`) while its slow tail was dominated by OS/vsync wait. One unchanged,
  process-isolated confirmation is retained rather than hiding the red result; it passed with
  physics p95/p99 `3.344/4.127ms`, frame p95/p99 `16.667/16.667ms`, and 1% low `58.79 FPS`.
- 2026-08-14: the capacity staircase used that authority pass as the 48 tier and stopped at 64 as
  required. The exact-64 diagnostic was count-valid but failed at physics p95/p99
  `9.623/12.062ms`; 96 and 128 were not run. Technical exact capacity is therefore last-pass 48 and
  first-fail 64. This does not change the shipping cap, visible-pressure rules, or authored reserve.
- 2026-08-14: the visible built-Web `e0962d7e` run was `1280x720`, ordinary count 43, normal Chrome
  (`headless=false`), focused throughout, and not scheduler-throttled. It failed at physics p95/p99
  `11.0/13.6ms`, frame p95/p99 `47.8/63.89ms`, and 1% low `14.27 FPS`. The exported PCK SHA-256 is
  `d1d01cedc612f6cc7ec7b471022b97511f0039426fa193c2037ad319c2be9281`. GitHub Pages and itch.io
  were deliberately not updated with this failing build.
- 2026-08-14: six decision-changing records are promoted: the pre-optimization native authority
  failure, the live-overlap-index diagnostic, both same-commit native authority observations, the
  exact-64 early-stop failure, and the visible built-Web failure. The passing native record
  explicitly supersedes the unavailable `4f7f7acd` checkpoint without reconstructing its bytes.
- 2026-08-14: direct inspection of the post-switch capture contradicted the checked Phase 2/5
  state: initial Upgrade captures omitted the grouped snapshot, Result constrained the shared rail
  to 96 pixels, and VehicleRun drew a legacy ring over a half-scale tinted Transit Gate PNG. Tasks
  2.3, 2.4, and 5.5 were reopened. The corrected runtime always captures real grouped snapshots,
  shows the wide Result report and build rail side by side, uses a vertical-scroll offer layout at
  200% text, and draws only the approved neutral Gate PNG across the full 192-world-unit footprint
  with dynamic progress/cooldown overlays. Clean commit-linked Korean 1280x720 evidence is in
  `build/captures/category-gate-26d90690-ko-1280-final`; the supported English 960x540, 200% text
  accessibility check is in `build/captures/category-gate-26d90690-en-960-text200-final`. Both
  manifests resolve commit `26d90690e4ea8756e227cf2b1c9486ee9a3ac12f`, content fingerprint
  `a408a416811a056d0d3b62e0016f3a83237ef9556bfc05e6919201f79dc5e2a6`, and clean source. Focused
  Upgrade, Result, layout, localization, map, capture, visual-authority, headless-import, and the
  refreshed isolated Web export checks pass.
  The unrelated rewards/UI/audio validator still reports its pre-existing announcement-queue
  assertion and is not used as evidence for this correction.
- 2026-08-14: BK clarified that the approved Gravity/Cryo/Weakpoint comparison images are complete
  standalone revealed visuals, not overlays for the neutral/resolved device art. Task 5.5 is
  corrected so the body appears only before reveal. The category grids are also corrected from
  centered `44/52/56 px` cells to a shared left edge and `36/40/44 px` cells. Focused renderer,
  Upgrade, Result, layout, map, capture, world, runtime, visual-separation, workbench,
  visual-authority, and headless-import checks pass; a Korean 1280x720, 100%-text rendered pass
  confirms both corrected compositions. Clean commit-linked evidence is in
  `build/captures/standalone-symbol-left-slots-2dbc6191-ko-1280`; its manifest resolves commit
  `2dbc61914773bd9f1a6f1471b346ae5eabf52231`, fingerprint
  `dc53096757d6ebe578b0c0a2bb36f4fc35b62756e4beefb79ec9cfb06cd2e2a6`, and clean source. The
  isolated Web export also completes. No performance scenario was run for this visual correction.
- 2026-08-14: BK further clarified that an attacked-but-unbroken Anomaly Device needs an obvious
  cracked middle state, and that the standalone outcome symbol must be at least four times the
  previous linear size. The final state sequence is pristine neutral body → broad-cracked neutral
  body → body-free `288`-world-unit outcome symbol. The shared build rail is corrected again to
  image-only `22/24/26 px` cells with `16/18/20 px` art and no internal scrollbar so all six
  categories fit without the oversized text/slot stack. Focused Upgrade, capture, renderer, runtime,
  asset, visual-authority, and Web-export checks pass. Clean Korean 1280×720, 100%-text evidence is
  in `build/captures/damaged-anomaly-compact-rail-01184b25-ko-1280-final`; its 121-file manifest
  resolves commit `01184b25c0b983a9b009e7ebcf4957c01304e237`, fingerprint
  `7ef053cfac1215fd742cfde1b4e35dbe9d7d27a2b4c520d34415547abaf5cbab`, clean source, and a valid
  scenario. Performance scenarios remain deferred until all feature and image work is done.
- 2026-08-14: BK superseded the neutral-body sequence completely. The black pristine/damaged casing
  is retired from production; its approved outcome symbol is visible and attackable immediately,
  bobs with a thin breathing contour like a direct pickup, and remains the only authored image until
  effect retirement. Hits only reduce health. Destruction alone starts the already visible
  Gravity/Cryo/Weakpoint effect and its trigger announcement. Historical damaged-device workbench
  evidence remains an explicitly superseded record, not an active production candidate. No
  performance scenario is authorized before the remaining feature and image work is complete.
  Runtime/assets landed in `90d3beb6de78f65f849725ee75fe57ee0f904b8a`; headless import and the focused
  runtime, map, renderer, world, asset, guidebook, localization, capture, run, workbench, and
  visual-authority validators pass. Web export and performance scenarios were intentionally
  deferred.

## Open Questions

No Phase 8 product decision remains open. The earlier packed native-kernel/custom-Web-template
approval question is deferred until Phase 8 is complete and its final focused/Web-export gate is
green. This plan still does not authorize a production dependency, custom Web template, threading,
threshold weakening, or hidden enemy-count reduction. The three Phase 5 symbols and clean Transit
Gate remain approved.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 8 player-visible combat and build corrections are complete.
- Next task: retain the architecture approval stop. Run the deferred final native/Web performance
  qualification only after the user confirms that remaining feature and image work is complete.
- Last completed gate: final source validation, promoted decision evidence, cap-48 native authority,
  and the 48-pass/64-fail capacity envelope are complete. Built-Web capture is valid but red; public
  deployment remains intentionally blocked.
- 2026-08-14 Phase 8 completion: Tasks 8.1-8.6 are implemented. Focused upgrade/build/active,
  secondary/renderer/balance, encounter/arrival/allocation, transition/continuity/result,
  localization, capture-driver, visual-authority, headless import, and Web export checks pass. No
  performance scenario ran. Normal-scale 1280x720 Korean and English evidence from clean commit
  `b404f310` confirms left-packed category cells, the equipped EMP glyph, all six Result build
  categories, and no build-grid clipping. Evidence is under `build/captures/phase8-b404f310-{ko,en}`.
- Update rule: after a checkpoint passes, record its concise evidence, check the task, and advance
  this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every required task acceptance check and final gate passes.
- Category slots are correct on Upgrade and Result in both locales and supported layouts.
- Opening, boss, and post-boss visible-pressure gates pass without on-screen births or fabricated
  population.
- Gravity/Cryo/Weakpoint use approved distinct symbols and exact `480/360/420` radii with `5/3/5s`
  lifetimes; Weakpoint applies exactly `1.25x` player-owned damage without changing enemy movement or
  targeting; the approved Transit Gate has a smooth circular edge; one text-only message queue and
  bounded pickup/device interaction motion pass accessibility and performance gates.
- The final cap-48 native p95/p99 are at most `6/8 ms` and built Web is valid.
- The evidence ledger can reconstruct the final claim from full commit and artifact hashes.
- A redacted native/Web session bundle can be exported and compared without remote upload.
- The capacity envelope is recorded without silently changing shipping balance.
- Durable product, visual, and performance decisions are incorporated into their owning specs.

Replan when:

- New tail receipts contradict the selected owner set.
- Category compatibility changes the maximum simultaneous capacities.
- A native extension, Web threading, custom template, or higher shipping cap becomes necessary.
- A remote telemetry endpoint or a different Anomaly outcome roster becomes necessary.

Do not replan or stop for:

- Local implementation mechanics inside the locked category/evidence/runtime boundaries.
- A rejected measured candidate; revert it and continue with the next selected hypothesis.
- A normal Phase 6 early stop after the first failing capacity tier.
