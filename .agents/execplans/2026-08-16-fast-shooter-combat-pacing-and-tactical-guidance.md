---
type: plan
status: active
owner: BK
created: 2026-08-16
last_reviewed: 2026-08-16
scope: Shooter-first encounter structure, enemy pressure, run length, upgrade cadence, cockpit HUD, and Tactical Control guidance
related:
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../design/DESIGN.md
  - ../cardborne-performance-engineering-policy.md
  - 2026-08-15-eight-boss-combat-depth-and-run-report.md
  - ../../docs/reports/2026-08-16-fast-shooter-combat-and-guidance-en.html
---

# Shooter-First Combat and Tactical Guidance — Execution Contract

Cardborne will keep the macro progression of a survivor-like run—one persistent field,
XP collection, build growth, escalating crowds, and a run reset—but its moment-to-moment
rules will become those of a fast manual-aim shooter. The player remains fast. Encounters
will challenge direction choice, aim priority, and route planning instead of asking a
fast vehicle to drag a slow crowd behind it.

## Purpose

- Objective: turn the current ten-minute, kill-quota-driven run into a readable 18–22
  minute shooter campaign with eight bosses, deliberate combat beats, fewer upgrade
  interruptions, and enough tactical information for a first-time player to learn from a
  loss.
- Deliverable: revised product and visual contracts; encounter-beat, spawn, combat,
  progression, Tactical Control, HUD, guidebook, failure-report, localization, telemetry,
  and validation changes; production Web qualification.
- Completion state: every task and final gate below passes and this plan is marked `done`.

## Scope and Boundaries

In scope:

- The complete eight-boss campaign structure, ordinary encounter composition, spawn
  placement, enemy movement/attack pressure, boss teaching, and post-boss flow.
- XP-to-upgrade cadence and the upgrade modal's placement in the run.
- The live HUD, minimap relationship, Tactical Control messages, guidebook explanations,
  and failure-report counterplay summary.
- Korean/English parity, 100–200% text scale, telemetry, native checks, and Web release
  qualification.

Out of scope:

- Slowing the player or dash, aim assist replacing manual aim, adaptive difficulty,
  difficulty selection, endless mode, new maps, a new enemy/boss roster, procedural text,
  voice acting, a generated character portrait, new production dependencies, engine
  changes, threads, GDExtension, or a custom Web template.

Constraints and invariants:

- Preserve manual aim, held primary fire, dash, passive seekers, EMP, fixed Hard, eight
  bosses, neutral facilities, one persistent run-selected field, and complete Korean and
  English UI.
- A high-threat attack keeps at least 1.30 seconds of collision-matching warning and one
  escape corridor at least player diameter + 80 units.
- Gameplay owners publish semantic receipts. UI never derives shield truth, facility
  time, encounter completion, damage cause, or counterplay by parsing display text.
- Use the shared Theme/factory: one flat surface, one 1 px boundary, and at most one
  semantic rail. No SVG UI, local `StyleBox`, raster HUD chrome, or nested frame.
- Keep the materialized hostile caps `32/44/56/64/72/72/72/72`. The current exact-72
  native capacity case is red; this plan does not raise any actor cap or call a lower
  organic workload a performance optimization.
- The canonical visual sheet was inspected at original detail and its observed SHA-256
  matches `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
  It is a style reference, not approval of any depicted UI or asset.

Destructive or irreversible actions:

- None. Replaced count-quota and announcement code remains in Git history and is removed
  only after its replacement is reachable and validated in the same scoped change.

Exact actions requiring user approval:

- Any later portrait, voice package, new actor art, dependency, engine/native change, or
  cap increase. None is required by this contract.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Run ends near ten minutes | `VehicleStageFlow` advances after raw defeat quotas `40–68`; the clock has no cap. Four current-schema completed local sessions averaged 589.9 seconds. | `vehicle_stage_flow.gd`, `vehicle_combat_stages.gd`, session diagnostics | Remove raw-kill progression. Run authored combat beats before each boss. Target 18–22 minutes as telemetry, never a hard timer. | 1.1, 2.1, 7.2 |
| Fast vehicle creates a tail | Player speed is 280 and dash is 1,220; common pursuit actors are roughly 266–285. Current nominal role mix is 65% pursuit and most births start 1,200–2,100 units away. | player/enemy speed owners, stage role builder, spawn allocator | Spawn for time-to-contact around a predicted engagement point. Reduce pursuit share to 25%; make interception/crossfire/denial the majority. | 3.1, 3.2 |
| Many actors, little danger | Cycle caps reach 72, yet threat budgets and commit caps allow only a small subset to attack; off-screen actors can occupy cap room. | encounter director/runtime, local sessions peaking at 45–70 | Do not add bodies. Give 6/8/10 enemies explicit attack slots across early/mid/late cycles; everyone else repositions or supports a beat. | 3.3 |
| Durability is already high | Ordinary HP stacks `1.12 × 2.60 × 1.20 × cycle curve up to 3.10`. Hostile projectile speed is reduced to 0.82 and recovery is 1.28. | stage difficulty, encounter director, spawn construction | Reduce late HP inflation, increase projectile relevance and attack recovery, and add committed interceptor bursts. Difficulty comes from decisions and danger, not sponge time. | 3.4 |
| Bosses are gated by chores | Ordinary kills alone start a 1.5 s boss warning; survivors do not block entry. Boss maintenance then collapses to a generic 8–12 actors. | stage flow, encounter runtime | Boss follows the cycle's authored beat sequence. Replace generic maintenance churn with one mechanic-supporting escort pulse at each phase transition. | 2.1, 3.5 |
| Upgrade fatigue | Current completed sessions open 20–23 upgrade modals; median gap is 10.9 s and minimum 1.3 s. `VehicleRun` opens one modal for each pending XP level. | diagnostics, experience/reward runtime | XP earns charges without pausing. Choices occur only at one early resupply and after bosses 1–7; maximum eight in-run modal sessions and sixteen total choices including deployment. | 4.1–4.3 |
| HUD is unreadable | The full boss/quota string is drawn in a 34–40 px clipped panel-free status slot. | gameplay HUD and layout validator | Replace the status strip with one backed mission card plus square action/status cells. Remove total defeats from live HUD. | 5.1 |
| Messages do not teach | One clipped two-line, four-entry text queue carries danger, boss, facility, shield, and progression events. | gameplay HUD, stage UI, localization validator | Separate immediate danger from explanation. Add a fixed, event-driven `CONTROL` auxiliary AI with one observation and one action per message. | 5.2–5.4 |
| First-time players cannot diagnose failure | Guidebook is modal reference data; failure report does not identify the mechanic that caused the loss. | guidebook catalog/panel, combat report body | Reuse the same counterplay catalog in Tactical Control, Guidebook, and a top-two failure analysis. | 5.3, 5.5 |
| Cap increase is unsafe | Latest exact-72 native replay failed capacity physics p95/p99 at 7.159/9.078 ms against 6/8 ms. | retained local performance evidence and performance policy | Keep cap 72. Qualify the redesigned product workload and preserve the exact-72 capacity test as a separate red/green gate. | 6.2, 7.3 |

Readiness statement:

- The previous threat-credit proposal is rejected because it was still a kill quota with
  different arithmetic. The previous conditional cap-80 proposal is also rejected because
  exact 72 is not yet qualified.
- All material product, UX, architecture, ownership, dependency, safety, and validation
  decisions are closed. Remaining choices are implementation-local.

## Locked Product Design

### A. The run is an authored operation, not a kill counter

Each cycle consists of combat beats, boss warning, boss combat, boss cleanup, and—except
after boss 8—a service break.

| Cycle | Ordinary beats | Beat shape | Boss pressure |
| ---: | ---: | --- | --- |
| 1–2 | 2 | `teach → combine` | signature attack, then one combination |
| 3–6 | 3 | `teach → combine → power_test` | signature, combination, phase escalation |
| 7–8 | 3 | `remix → combine → power_test` | learned patterns combined without a new visual language |

- `teach` resolves after the assigned tactic commits once and either completes or is
  broken by the player.
- `combine` resolves after two different role groups commit and the tactic's anchor group
  is defeated.
- `power_test` resolves after one priority actor commits, the combined tactic resolves,
  and the priority actor is defeated.
- Ordinary kills still grant XP and remove danger; they do not directly advance the run.
- A beat that cannot resolve because its required actor/cue is invalid retries that exact
  requirement once. If it remains invalid, the runtime ends the beat after 50 seconds,
  records `beat_fallback`, withdraws its unresolved reserve, and continues. It never waits
  on an empty field.
- Every beat uses the same bounded intensity shape: `build` admits and introduces the
  assigned roles, `sustain` holds the authored attack-slot pressure, and `recover` stops
  new commits for 3–5 seconds after the resolution condition. The tactic catalog owns
  composition; this state only controls admission and commit permission and never changes
  HP, player speed, warning time, or difficulty.
- Boss warning remains 1.5 seconds. A boss phase transition may call one authored escort
  pulse of 4/6/8 ordinary actors for cycles 1–2/3–6/7–8. No generic 8–12 refill churn.
- Target active-run distribution: 15–18 minutes of movement/combat, 2–4 minutes of
  deployment/resupply/service choices, and 18–22 minutes total. This is an acceptance
  band for controlled tests, not a player-facing clock or progression gate.

### B. Pressure attacks the route, not the rear bumper

- Replace fixed-distance-first placement with time-to-contact placement. For every unit,
  select a legal off-screen point expected to produce its first meaningful attack in
  2.0–3.5 seconds, bounded by the existing 900–2,400 unit placement limits.
- Predict an engagement point 0.8–1.5 seconds along the player's velocity. Clamp the
  prediction at walls and discard a candidate that removes the final escape lane.
- Per-beat admitted threat composition:
  - pursuit: 25%;
  - interceptor/rammer: 30%;
  - ranged/crossfire: 25%;
  - denial/support: 20%.
- No more than 30% of threat cost may enter from the rear 120-degree sector. At least one
  arrival group enters from an ahead-lateral sector in every beat after the first teach.
- Attack slots are 6/8/10 for cycles 1–2/3–5/6–8. No more than three slots may attack from
  the same 90-degree sector. Non-slotted enemies reposition, screen, or support; they do
  not continue perfect homing behind the player.
- Interceptors receive a +15% approach burst for at most 1.5 seconds, then commit a fixed
  crossing route. Pursuers remain slower than the player. Rammers and denial actors lock
  their final vector/zone after the existing warning and do not retarget through a dash.
- First balance pass:
  - ordinary global health multiplier `2.60 → 2.10`;
  - cycle health curve `1.00/1.30/1.60/1.90/2.20/2.50/2.80/3.10 →
    1.00/1.15/1.30/1.45/1.60/1.75/1.90/2.05`;
  - hostile projectile speed multiplier `0.82 → 0.95`;
  - enemy recovery rate `1.28 → 1.45`;
  - global enemy damage and player movement/dash unchanged;
  - late ranged commit cap `4 → 5`; denial cap remains 3.
- Boss HP remains unchanged in the first pass. Phase 1 teaches the signature alone;
  Phase 2 adds one learned pressure layer; Phase 3 changes cadence/coverage, not visual
  language. The player must get one clean signature-only read before combination.

### C. Upgrades happen at service moments

- Deployment grants one explicit starting-card choice before the run clock starts.
- XP fills a non-modal `upgrade_charge` ledger with these 15 requirements:
  `12/20/32/48/66/86/108/132/158/186/216/248/282/318/356`.
  The current authored minimum path of 2,296 XP can earn all 15 charges; progression then
  completes through the existing shard-cleanup path.
- The first earned charge opens once, after cycle 1's `teach` beat resolves and before its
  `combine` beat begins.
- Boss cleanup 1–7 enters `SERVICE_BREAK`. One modal session spends up to two available
  charges as two sequential card choices, then continues. Boss 8 opens Result and never
  offers a dead-end upgrade.
- Missing charges do not block continuation. Excess charges carry forward. Source order,
  card compatibility, reserved active/secondary offers, and one confirmed card per charge
  remain owned by the reward/card runtimes.
- There are at most eight in-run upgrade sessions: one field resupply plus seven service
  breaks. No upgrade modal opens during ordinary combat, boss warning, boss combat, dash,
  or a committed attack.

### D. The HUD is a cockpit, not a row of clipped glyphs

- Keep full-width HP and XP meters.
- Replace `stage_progress + total_defeats` with one mission card under the meters:
  - standard `240×56`, compact `212×52`, large `260×60`, 200% `440×92`;
  - line 1: `CYCLE 3 / 8` or boss name;
  - line 2: current verb and progress, for example `BREAK CROSSFIRE · 1 / 2 ANCHORS`;
  - boss warning: `CONTACT IN 1.5`; boss combat: phase and signature state.
- Remove total defeats from live play. Keep it in Pause/Report, where it is useful.
- Dash and Active use `56×56` backed square cells; conditional statuses use `48×48` cells.
  Each uses the shared surface, 1 px boundary, semantic glyph, value, and no label when the
  glyph is unambiguous. At 200% they wrap below the mission card instead of shrinking.
- Keep the minimap at top-right. It remains the location channel; the mission card is the
  objective channel. They must never overlap at 960, 1,280, 1,920, or 200% text.

### E. `CONTROL` is a gameplay system, not flavor chatter

- Player-facing identity: `CONTROL // AUXILIARY AI` (`CONTROL` remains the callsign in
  both locales; the role label is localized). First release uses a code-native comms glyph,
  a consistent audio chirp, and text—no portrait or voice dependency.
- Layout: a right-side surface directly below the minimap, standard `336×84`, compact
  `304×78`, large `384×96`, 200% `440×132`. It has a 48 px identity well, a category label,
  and at most two text lines. It never reaches the central reticle lane.
- Message grammar is always `OBSERVATION — ACTION` and contains one actionable verb.
  Examples:
  - `FRONTAL SHIELD — BREAK CONTACT AND ATTACK FROM THE SIDE.`
  - `REPAIR FIELD ONLINE — 12 S REMAIN. STAY INSIDE THE RING.`
  - `ARTILLERY LOCK — CROSS THE AIM LINE BEFORE IT FIRES.`
  - `REPAIR FIELD OFFLINE.`
- World telegraphs and threat radar own immediate survival. A one-line danger channel may
  show boss inbound, barrier depleted, or lethal lock. Tactical Control never duplicates
  those cues.
- Queue capacity is 2. A message older than 2.5 seconds is dropped. Mechanic messages show
  for 4 seconds, coalesce by subject, and repeat at most once per encounter after a verified
  failure. State messages are replaced by the newest state; flavor messages do not exist.
- Knowledge states are `unseen`, `introduced`, `failed`, `resolved` and are run-scoped.
  The gameplay owner publishes success/failure receipts; the advisor catalog only maps a
  state and subject to localized observation/action keys.
- Guidebook enemy/boss/facility entries reuse the same observation/action keys in a
  permanent `Observed Behavior / Countermeasure` section.
- Failure Report adds `What ended the run`: the two highest-impact verified mechanic
  receipts and one countermeasure each. It never invents a cause from proximity alone.

## Tasks

### Phase 1: Amend the authoritative contracts

Goal: make the shooter-first model binding before implementation.

Source owners: `docs/product/vehicle_game_spec.md`, `docs/design/VISUAL_SYSTEM.md`,
`.agents/design/DESIGN.md`, localization catalogs, focused validators.

- [ ] **1.1 Product contract**
  - Change: replace raw quota, generic boss maintenance, immediate XP modal, panel-free
    HUD, and telemetry-only time wording with Sections A–E above.
  - Accept: product spec and data tables agree on eight cycles, beat counts, service
    breaks, 18–22 minute acceptance band, and unchanged actor caps.
- [ ] **1.2 Visual and localization contracts**
  - Change: authorize the backed mission/action/status cells and CONTROL surface through
    the shared Theme; define complete Korean/English keys and accessibility names.
  - Accept: `validate_cardborne_visual_authority.ps1` and localization parity pass; the
    spec records `actual_image_reference_used=false` and `reference_input_method=not_applicable`.

### Phase 2: Replace kill quotas with combat beats

Goal: ship one complete cycle flow before broad tuning.

Source owners: `scripts/vehicle/stages/vehicle_combat_stages.gd`, new
`scripts/encounters/vehicle_encounter_beat_catalog.gd`,
`scripts/encounters/vehicle_stage_flow.gd`, `vehicle_encounter_runtime.gd`,
`vehicle_collective_tactic_catalog.gd`, `vehicle_collective_tactic_runtime.gd`.

- [ ] **2.1 Beat data and receipts**
  - Change: promote the existing tactic rollout into the exact cycle/beat table; add
    `build/sustain/recover` state and narrow `started`, `commit`, `broken`, `resolved`,
    `fallback` receipts. Remove quota as campaign progression truth. Do not add a second
    generalized difficulty director.
  - Accept: seeded tests prove teach/combine/power-test completion, one retry, 50-second
    fallback, zero empty wait, pause/resume, save reset, and boss admission.
- [ ] **2.2 Boss and service flow**
  - Change: add phase-transition escort pulses and `SERVICE_BREAK`; remove generic boss
    maintenance and direct quota-to-warning entry.
  - Accept: bosses enter only after required beats, escorts match 4/6/8 and commit limits,
    boss 8 opens Result, and no service break appears after victory.

### Phase 3: Make speed create tactical decisions

Goal: make every beat pressure at least two directions without creating unavoidable rings.

Source owners: `vehicle_spawn_allocator.gd`, `vehicle_encounter_runtime.gd`,
`vehicle_encounter_director.gd`, `vehicle_enemy_movement_policy.gd`,
`vehicle_enemy_targeting_policy.gd`, stage difficulty and archetype owners.

- [ ] **3.1 Time-to-contact allocator**
  - Change: add bounded engagement-point prediction, role-speed arrival estimates,
    ahead-lateral/rear sector budgets, and escape-lane rejection using reusable buffers.
  - Accept: stationary, sustained movement, dash, reversal, wall-edge, and last-lane
    fixtures meet 2.0–3.5 seconds and sector limits without per-frame allocation.
- [ ] **3.2 Role mix and attack slots**
  - Change: replace the 65% pursuit build with 25/30/25/20 composition and 6/8/10
    sector-limited attack slots. Non-slotted actors use explicit reposition/support state.
  - Accept: deterministic traces show at least two attack sectors, no more than three
    same-sector attackers, no universal tail state, and no visible-threat gap over 3 s.
- [ ] **3.3 Movement, attacks, and balance**
  - Change: apply the locked interceptor burst, fixed commits, HP curve, projectile speed,
    recovery, and ranged-cap changes; update guidebook stat adapters.
  - Accept: values match debug contracts; player speed/dash, global enemy damage, warning
    time, collision, and caps are unchanged.
- [ ] **3.4 Boss teaching**
  - Change: enforce signature-alone first selection, one learned combination in phase 2,
    and cadence/coverage escalation in phase 3.
  - Accept: every boss fixture proves the order, escape corridor, no unannounced pattern
    language, and one mechanic-supporting escort pulse per transition at most.

### Phase 4: Move progression to service moments

Goal: preserve build depth with no random combat interruption.

Source owners: `vehicle_experience_runtime.gd`, `vehicle_reward_runtime.gd`,
`vehicle_run.gd` orchestration, deployment/upgrade panels, card offer owners.

- [ ] **4.1 Upgrade-charge ledger**
  - Change: implement the 15 requirements, cap, snapshot, carry, spend, and completion
    receipts; remove XP's direct permission to open UI.
  - Accept: 2,296 XP yields exactly 15 charges, accounting is lossless, and completed
    progression clears/merges shards without hidden pending levels.
- [ ] **4.2 Scheduled choice sessions**
  - Change: add the deployment choice, cycle-1 resupply, and boss-1–7 two-choice service
    sessions while preserving source order and offer reservations.
  - Accept: full campaign fixture has at most eight in-run sessions, at most sixteen total
    choices, no combat-time modal, and no boss-8 reward.
- [ ] **4.3 Compact two-choice modal**
  - Change: show `CHOICE 1 / 2`, update the shared build summary after choice 1, and keep
    one outer scroll only at 200%.
  - Accept: keyboard/controller focus and Korean/English rendered text fit at all supported
    sizes; no clipped scroll descendants.

### Phase 5: Build the cockpit and Tactical Control

Goal: make objective, action readiness, mechanic understanding, and failure learning clear.

Source owners: shared Theme/factory, `vehicle_gameplay_hud.gd`,
`vehicle_hud_presenter.gd`, new `vehicle_tactical_control_runtime.gd` and catalog,
guidebook catalog/panel, combat report builder/body.

- [ ] **5.1 Mission and action HUD**
  - Change: add the backed mission card and square cells, remove live total defeats, and
    implement responsive wrap and measured localized bounds.
  - Accept: objective/boss text never ellipsizes; HUD/minimap do not overlap; all reachable
    states fit at 960/1280/1920 and 100/200%.
- [ ] **5.2 Tactical Control runtime**
  - Change: own priority, staleness, coalescing, knowledge state, failure repeat, and the
    two-entry queue outside UI code.
  - Accept: deterministic tests prove message grammar keys, ordering, expiry, interruption,
    duplicate suppression, locale refresh, and no stale state message.
- [ ] **5.3 Semantic event adapters and presenter**
  - Change: publish exact boss, tactic, enemy, facility, barrier, and success/failure
    receipts; present CONTROL below minimap through existing HUD invalidation cadence.
  - Accept: no display-string parsing, no gameplay polling in UI, input pass-through,
    central reticle lane clear, and no duplicate danger/advisor message.
- [ ] **5.4 Guidebook and failure learning**
  - Change: reuse the counterplay catalog in discovered entries and top-two verified
    failure analysis.
  - Accept: every reported cause has a source receipt; unknown causes say evidence was
    insufficient; both locales have complete observation/action copy.

### Phase 6: Instrumentation and code quality

Goal: make the redesign measurable without creating new hot-path ownership.

Source owners: session recorder/store, encounter pacing capture, performance scenarios,
responsibility-shaped gameplay/UI modules.

- [ ] **6.1 Diagnostic schema**
  - Change: record beat durations/fallbacks, time-to-contact, sector/role shares, attack
    slot occupancy, tail-state time, upgrade sessions/charges, CONTROL delivery, mechanic
    success/failure, and service time.
  - Accept: newest-ten migration is valid; old bundles are versioned safely; no event
    flood exceeds bounded retention.
- [ ] **6.2 Quality audit**
  - Change: run `$codebase-quality-auditor`; make only small task-scoped corrections.
  - Accept: no beat/reward/advisor policy in `VehicleRun` or UI, no competing progression
    owner, no catch-all catalog, and obsolete quota/announcement paths are unreachable.

### Phase 7: Integrated qualification

Goal: prove the new game, not merely individual systems.

- [ ] **7.1 Functional and rendered gate**
  - Accept: affected focused validators, parse/import, campaign, rewards, localization,
    visual authority, UI layout, and diagnostics pass; Korean/English captures cover peak
    beat, boss warning, shield guidance, facility online/offline, service choice 1/2 and
    2/2, failure analysis, compact/standard/large/200%, grayscale, and focus.
- [ ] **7.2 Controlled play gate**
  - Accept: at least five default-build complete runs have a median 18–22 minutes; at
    least 75% of ordinary combat seconds contain a visible committed threat; rear-only
    attack time is below 20%; median upgrade sessions are 6–8; no modal opens in combat;
    first-time testers can state the current objective and boss countermeasure after one
    exposure without developer explanation.
- [ ] **7.3 Performance and Web gate**
  - Accept: establish a new clean product-workload native/Web baseline and label it only
    for that workload. Separately rerun the unchanged exact-72 capacity fixture; it must
    pass current physics/frame/capacity thresholds before release. Export Web and run the
    built app through the guarded project lane for input, pointer, audio, persistence,
    bilingual UI, and critical combat-flow smoke.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | affected focused GDScript validator through `./tools/godot.ps1` | task implementation changes | relevant owner changes |
| UI phase | visual-authority validator plus layout/localization validators and named captures | Phase 5 tasks pass | Theme/layout/copy changes |
| Campaign phase | eight-boss, encounter pacing, experience, rewards, and active-clock validators | Phases 2–4 pass | campaign/reward input changes |
| Final | clean native/Web product workload, exact-72 capacity, Web export and built smoke | all functional phases pass | final-gate input changes |

Validation rules:

- Run the narrowest check that proves the task. Do not repeat a passing gate without a
  relevant input change.
- Load `$cardborne-performance-guard` before profiling and `$npjt-port-guard` before any
  server. Do not weaken workload or thresholds to manufacture a pass.
- Treat product-workload and exact-72 capacity results as different claims.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary |
| --- | --- | --- |
| A required beat actor/cue cannot materialize twice | Use the locked 50 s fallback, log it, and continue | Replan if more than 1% of beats fall back across controlled runs |
| 18–22 minute band misses | Change beat packet size or resolution requirement, one owner at a time | Do not add HP, a hidden timer gate, or upgrade delay to pad time |
| Difficulty remains low | Increase attack-slot occupancy, role mix, or recovery within warning/escape limits | Do not raise global HP first |
| Difficulty becomes unreadable | Reduce simultaneous commit sectors or combination timing | Do not slow the player or erase authored population |
| CONTROL text is missed | Improve placement/duration/audio chirp within the locked surface | Do not make it modal or duplicate world danger |
| Exact-72 remains red | Attribute and fix the measured owner while preserving exact workload | No cap increase, threshold change, or release-performance claim |
| A material fact contradicts this contract | Stop the affected branch and revise the contract | Executor may not select a new product/UX/architecture contract |

Implementation-local discoveries may be handled inside this contract when they do not
change visible behavior, ownership, architecture, safety, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes above.
- Current phase: Phase 1.
- Next task: 1.1 Product contract.
- Last completed gate: Discovery Closure Gate on 2026-08-16.
- Update rule: record concise evidence, check the task, and advance this pointer together.
- Research effect: high-speed shooter, encounter-pacing, gameplay-first UI, side
  transmission, contextual-dialogue, and survivor-upgrade evidence changed the prior plan
  from weighted kill quotas and random safe windows to explicit combat beats and authored
  service moments.

## Completion and Stop Conditions

Complete when every task, acceptance check, phase gate, controlled-play gate, exact-72
capacity gate, and built-Web smoke passes; durable product/design decisions are moved into
their canonical specs; and frontmatter becomes `status: done`.

Replan when a verified fact invalidates a locked product, UX, ownership, workload, or
validation decision. Do not replan for contained implementation mechanics or repeat a
passing check whose inputs did not change.

## Sources and Applicability

- [Sunset Overdrive AI](https://gdcvault.com/play/1021780/AI-in-the-Awesomepocalypse-Creating): high player speed invalidates conventional chase/flank assumptions.
- [DOOM Eternal combat Q&A](https://www.gamedeveloper.com/design/q-a-evolving-the-combat-design-of-id-software-s-i-doom-eternal-i-): fast traversal required faster reactions/tells and usable combat space.
- [Combat encounter pacing](https://www.gamedeveloper.com/design/the-art-and-science-of-pacing-and-sequencing-combat-encounters): enemy type, count, location, timing, dialogue, and authored events jointly create intensity.
- [Left 4 Dead AI systems](https://steamcdn-a.akamaihd.net/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf): structured variation and visibility/flow rules are useful; adaptive difficulty is not imported.
- [Returnal enemy design](https://blog.playstation.com/2021/04/14/creating-returnals-otherworldly-enemies-vfx-driven-tentacle-tech-and-deep-sea-inspirations/): role combinations and defensive maneuvering matter more than undifferentiated density.
- [Returnal UX](https://blog.playstation.com/2021/05/11/unpacking-returnals-ux-design-gameplay-first-ui-retro-futuristic-tech-and-accessibility/): immediate survival information belongs near focus; explanation belongs at the periphery.
- [Warframe mission interface](https://support.warframe.com/hc/en-us/articles/38801911653517-Mission-Interface): side transmissions can carry objectives, updates, guidance, and threats while the minimap owns location.
- [Context-aware dialogue](https://www.gdcvault.com/play/1020951/A-Context-Aware-Character-Dialog): semantic knowledge and world state should drive contextual lines.
- [Dota 2 Nest of Thorns](https://store.steampowered.com/news/posts/?appids=570&enddate=1747260468&feed=steam_community_announcements): raw wave clearing became a chore and upgrade/difficulty pacing required playtest data. Its timer-driven survivor solution is deliberately not copied into Cardborne.
- [Ghost of Tsushima combat balance](https://blog.playstation.com/2020/11/25/honoring-the-blade-and-combat-balance-in-ghost-of-tsushima/): aggression, timing, moves, and damage are preferred before sponge health; its melee numbers do not transfer.

Visual-authority evidence for this planning task: both canonical files were inspected;
observed sheet hash matched; `actual_image_reference_used=false`;
`reference_input_method=not_applicable`; no production asset approval is claimed.
