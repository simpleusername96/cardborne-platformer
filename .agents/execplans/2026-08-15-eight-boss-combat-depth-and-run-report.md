---
type: plan
status: active
owner: BK
created: 2026-08-15
last_reviewed: 2026-08-15
scope: Eight-boss campaign flow, boss and enemy combat, boss-death cleanup, upgrades, neutral facilities, diagnostics retention, report UI, localization, visual assets, validation, and release evidence
related:
  - ../../docs/reports/2026-08-15-eight-boss-combat-design-analysis.md
  - ../../docs/reports/2026-08-15-eight-boss-combat-approval-ko.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../design/DESIGN.md
  - ../cardborne-performance-engineering-policy.md
  - ./2026-08-13-run-pacing-result-and-upgrade-slots.md
---

# Eight-Boss Combat Depth and Run Report

## Purpose

Implement the 2026-08-15 feedback as one decision-complete contract. Replace the
visible ten-stage pairing with eight continuous boss cycles, preserve ordinary-enemy
quotas before every boss, add three bosses and four active ordinary roles, replace
Shock with Target Designator, add a readable boss-death cleanup, retain only the latest
ten valid user sessions, and deliver one left-aligned stacked report shared by terminal
results and Settings.

This plan contains implementation work only. Candidate generation, comparison, and
product decisions are closed in the linked design analysis. There is no absolute run-
duration acceptance target and no agent-simulated “normal completion” cohort.

## Product Contract

### Campaign language and flow

- The player-facing progression unit is `boss_cycle`, localized as `보스 사이클` and
  `Boss Cycle`. Do not present separate bossless and boss stages.
- There are exactly eight cycles. Each cycle executes `ORDINARY_COMBAT -> BOSS_WARNING
  -> BOSS_COMBAT -> BOSS_DEATH_CLEANUP -> CYCLE_TRANSITION`.
- Every boss appears after the cycle's ordinary-enemy destruction quota is met. Layout,
  map pickups, difficulty, and cycle counters refresh only after cleanup completes.
- HUD progression reads `보스 N/8` / `Boss N/8` and shows the remaining ordinary kill
  quota. Internal stage identifiers may remain as compatibility-free implementation
  details only while owners are migrated; no player-facing `Stage N/10` remains.
- Keep first-visible-hostile and search-gap contracts: first visible hostile within
  4.0 seconds, first meaningful attack preparation within 8.0 seconds, and no empty or
  off-screen-only combat gap longer than 3.0 seconds. Do not teleport enemies or lower
  authored counts to satisfy these limits.

### Diagnostics retention

- Retain the newest ten valid user session bundles, ordered strictly by
  `(saved_unix, session_id)` descending. File modification time is not authoritative.
- Apply the same pruning during load and persistence. Quarantine invalid bundles before
  selecting the newest ten.
- Preserve the existing 25 MiB and 14-day safety caps. Whichever cap removes a bundle
  first wins.
- Keep cycle time, visible-gap summaries, boss identity, boss cleanup duration, and
  report outcome in protected summaries even when bounded detail events overflow.

## Combat Rules Shared by All Bosses

Every boss has both baseline attacks below. Identity attacks remain dominant: common
attacks may occupy at most two of any five direct pattern selections.

| Common pattern | Exact contract |
| --- | --- |
| Committed charge | 1.00–1.25 s exact corridor warning; direction locks at commit; 0.55–0.75 s active travel; stops on wall; normal damage |
| Aimed volley | 3/4/5 shots in early/mid/late cycles; direction locks per burst; 0.22/0.20/0.18 s shot interval; low per-hit pressure damage |

Baseline statistics increase monotonically. High-threat reaction windows do not shrink
with cadence.

| Boss | Health scale | Damage scale | Move speed | Cadence scale | Coverage scale |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 1.00 | 1.00 | 145 | 1.00 | 1.00 |
| 2 | 1.12 | 1.06 | 150 | 0.97 | 1.04 |
| 3 | 1.25 | 1.12 | 155 | 0.94 | 1.08 |
| 4 | 1.39 | 1.18 | 160 | 0.91 | 1.12 |
| 5 | 1.54 | 1.24 | 166 | 0.88 | 1.16 |
| 6 | 1.70 | 1.31 | 172 | 0.85 | 1.20 |
| 7 | 1.87 | 1.38 | 178 | 0.82 | 1.24 |
| 8 | 2.05 | 1.46 | 184 | 0.79 | 1.28 |

Use 5,200 as the health-scale base. A cadence scale below 1.0 shortens only recovery
and low-threat gaps; it never shortens a high-threat startup.

### Damage and fairness bands

| Band | Final player damage | Avoidability contract |
| --- | ---: | --- |
| Pressure | 10–18 | May be difficult to avoid; repeated geometry has a 0.6–1.0 s per-target hit lock |
| Normal | 22–38 | Aimed or committed attack with readable origin and direction |
| High threat | 60–85 | At least 1.30 s warning, committed collision-matching geometry, and one escape corridor at least player diameter + 80 world units |

No boss attack is a true instant kill. A high-threat pattern applies damage once per
execution, cannot cover every exit, and cannot retarget after its final commit cue.

## Eight Boss Identities

All eight bosses retain the common charge and volley in addition to these identity
patterns. Delete the current global rule that lowers one identical shield for four
seconds after every direct boss attack. Shield policy is owned by each boss profile.

| # | Boss | Identity patterns and defense/attack link |
| ---: | --- | --- |
| 1 | Foundry Colossus | `Furnace Gates` closes two warned lanes, then leaves the other lanes open. A wall collision after its common charge creates a 1.4 s vulnerability. It has no shield. |
| 2 | Archive Leviathan | Fires a fixed X-cross laser, alternating its orientation by 45 degrees on the next cast. The exact warned corridors are the damage corridors. It has no shield. |
| 3 | Drydock Titan | Has a permanent 110-degree frontal shield with 90% interception. Facing locks during attacks, exposing sides and rear. Intercepted damage charges a visible frontal counterburst, so defense always produces an attack. |
| 4 | Switchyard Behemoth | Anchors and sweeps one moving beam; below 45% health it follows with a sweep from the opposite side. The beam leaves one continuous escape route. It has no shield. |
| 5 | Crown Engine | Three body-attached relay hardpoints each own one shield sector and one bolt lane. Destroying a hardpoint removes both. The remaining hardpoints fire faster after each loss, linking defense, objective priority, and offense. |
| 6 | Siege Battery | Fires 8–10 long-lived projectiles from alternating banks. Each bank locks direction for its salvo; the next bank attacks a different lane. It has no shield. |
| 7 | Vector Loom | Translates parallel laser walls across the arena, then uses an orthogonal pass. Every wall has an explicit moving gap. It has no shield. |
| 8 | Pulse Core | Alternates expanding and contracting pulse rings with a missing wedge, then adds sparse spiral projectiles. It tests distance control without a shield. |

The Crown hardpoints are attached, destructible boss parts. They are not free-standing
objective pylons and require no new raster identity; collision and state use three
clear body anchors and code-native plates. Boss-summoned ordinary enemies and existing
facility identities may supplement patterns, but every boss keeps direct attacks and
can finish the fight without surviving summons.

## Boss-Death Cleanup

Add one owner, `VehicleBossDeathRuntime`, with `ACTIVE -> DYING -> CLEANUP -> COMPLETE`.
The transition starts exactly 2.00 seconds after the lethal receipt.

| Time | Required behavior |
| --- | --- |
| 0.00 s | Disable boss AI, collision, damage intake, spawning, and damage output. Retire boss-owned damaging projectiles and zones. Freeze final facing. |
| 0.00–0.60 s | Draw three body-centered, code-native damage-plane pulses. Reuse the priority-destruction sound at three restrained pitch offsets. |
| 0.20–1.10 s | Stagger boss-summoned enemies and facilities at 0.12 s offsets. Each contracts and fades, emits one bounded cleanup burst, grants no XP/loot/quota, and reports source `boss_cleanup`. |
| 0.90–1.60 s | Collapse/fade the boss body as 4–6 broad planes using its approved body raster plus code-native transforms. Emit at most six boss bursts. |
| 1.60–2.00 s | Clear remaining boss-owned actors and zones, freeze the report snapshot, then permit the cycle transition. |

- The player remains controllable and cannot take damage from boss-owned objects during
  cleanup. No full-screen flash is used.
- Reduced motion removes hit-stop, camera impulse, pulse scaling, and stagger motion;
  it keeps a static 2.00-second fade and state changes.
- Extend the existing 96-entry effect store with dedicated bounded cosmetic kinds:
  at most 8 boss bursts and 12 cleanup bursts. These kinds may recycle only their own
  oldest receipt and must never evict EMP or another functional effect.
- Do not add an explosion sprite sheet, effect PNG, frame animation, plugin, or package.

## Ordinary Enemy Additions

Remove Shield Breaker from the proposal. Add these four roles; every role attacks the
player directly and has an actionable priority cue.

| Enemy | Behavior |
| --- | --- |
| Mobile Rail Sniper | Relocates between shots, shows a 1.40 s exact thin-line warning, fires one high-damage shot, and recovers for 2.20 s. |
| Orbit Gunner | Moves tangentially around the player and fires a three-shot inward burst. Individual hits are pressure damage. |
| Bombing Runner | Commits to a visible pass and leaves three delayed normal-damage ground blasts. |
| Wreck Scavenger | Always attacks. When an eligible ordinary enemy dies within 360 units, gains one permanent stack, up to five. Each stack adds 12% direct damage, 5% move speed, and reduces attack interval by 4%. |

Wreck Scavenger stacks exclude bosses, facilities, summoned children, and other Wreck
Scavengers. The trigger is the death event and distance at that instant; do not add a
corpse system. Show stacks with one broad body accent per stack and a short pulse, not
small text. The role is intentionally safest when destroyed early.

## Primary Attribute Replacement

Delete Shock Disruption and its attack-lock status. Replace it with the utility primary
attribute `target_designator`, localized as `표적 지시기` / `Target Designator`.

- A direct primary hit designates exactly one hostile target for 1.5/2.0/2.5 seconds.
- A direct hit on a different valid target transfers the designation immediately.
- Seeker, Auto Laser, and Storm Barrage prefer the designated target while it remains
  valid, in range, and in line of sight.
- Electric Field, Orbiting Blades, and Drop Mines keep geometry-owned targeting and
  ignore designation. Active weapons are unaffected.
- Bosses are eligible. Neutral facilities are not.
- Offer the card only after the player owns at least one compatible automatic weapon.
  Cryo remains the other utility primary attribute.
- Render two open code-native chevrons around the target. Do not use a ring or timer
  text. Reduced motion uses static chevrons.
- Report successful designation uptime and target transfers separately. Do not mix
  these values with Arc damage or rejected hit attempts.
- Replace the existing Shock card image in place after exact visual approval. Remove
  Shock localization, status, report, and validation contracts rather than retaining a
  compatibility alias.

## Other Approved Feedback Work

### Upgrade cards and offers

- `Miss Compensation`: each primary shot group that retires without hitting a hostile
  grants one stack, maximum 5; the next hostile hit gains +8/+11/+14% damage per stack
  and consumes all stacks.
- `Hit Chain`: each consecutive primary shot group that hits a hostile grants one stack,
  maximum 8; each stack grants +3/+4/+5% primary damage. A missed retired group clears
  the chain.
- `Braced Fire`: moving at least 220 units charges one segment, maximum 5. After staying
  below 20 units/s for 0.60 s, consume the charge and grant +6/+8/+10% primary damage
  per segment for 4.0 seconds. Moving above 60 units/s ends the firing window.
- Split projectiles share one shot-group outcome. Child projectiles never add or clear
  stacks independently.
- If both an active weapon and a secondary weapon are missing, reserve one offer slot
  for each category. If one is missing, reserve one slot for it. Stop reservation for a
  category once that weapon slot is acquired.

### Neutral facilities and rewards

- Replace anomaly-on-destruction behavior with Repair, Barrier, Gravity, Cryo, and
  Weakpoint facilities that affect player and enemies by the same spatial rule.
- Repair restores one third of maximum hull per second. Barrier restores shield at the
  same rate up to 100% of maximum hull. Both remain large and long-lived.
- Gravity strongly changes movement acceleration and maximum speed but does not pull
  actors into an unavoidable center death. Cryo slows both sides. Weakpoint lowers
  defense for both sides while inside its radius.
- Player and hostile attacks can destroy facilities. Projectiles continue through a
  facility hit so facilities cannot become free projectile walls.
- Remove repair pickups. Replace their authored placements with experience shards and
  add five visible experience shards per boss cycle.

### Report UI

- Reuse one report-body component in victory, defeat, and Settings ship status.
- Use one left-aligned vertical stack and exactly one outer content scroll. Remove
  report tabs, metric sub-scrolls, and the narrow side build rail.
- Keep section order: outcome, cycle progress, build, damage, defense, enemies, bosses,
  pacing, and diagnostics limitations.
- Validate Korean and English at 960x540, 1280x720, and 1920x1080 with 100% and 200%
  text scaling. No text or control may clip or overflow.

## Visual Asset Contract

The current production manifest declares 78 images. This work adds 12 approved raster
identities and replaces Shock art without a count increase, producing a 90-image target:

| Family | New raster images | Notes |
| --- | ---: | --- |
| Boss bodies | 3 | Siege Battery, Vector Loom, Pulse Core; 352x352 |
| Ordinary enemies | 4 | Rail Sniper, Orbit Gunner, Bombing Runner, Wreck Scavenger; 112x112 unless stationary scale is required by the existing actor contract |
| Neutral facilities | 2 | Barrier and one missing facility identity; existing suitable facility identities remain reused |
| Upgrade cards | 3 | Miss Compensation, Hit Chain, Braced Fire; 192x192 |
| Target Designator | 0 net | Replaces the Shock card asset byte-for-byte through the approval workflow |
| Death effects | 0 | Existing actor rasters plus bounded code-native geometry |

Generate every new raster candidate with the exact canonical style sheet as a real
reference input. Keep candidates outside production. Promote only exact user-approved
bytes and hashes through the visual workbench and manifest. Revise `VISUAL_SYSTEM.md`
before integration to authorize eight bosses, the 90-image count, per-boss shields,
attached Crown hardpoints, the Target Designator chevrons, new role silhouettes, and
the boss-death geometry. Do not introduce SVG actors, generated effect raster, or a new
named theme.

## Execution Checklist

1. **Update product, design, terminology, and validation contracts.** Revise the product
   spec, visual system, design memory, guidebook terms, localization inventory, and
   campaign validators for eight boss cycles, per-boss defense, the exact combat bands,
   the 2.00-second cleanup, Target Designator, four enemy roles, and 90 approved images.
   Rename stage-facing symbols to cycle-facing symbols within their existing owners and
   remove obsolete ten-stage/fourteen-stage acceptance text.

2. **Produce and approve the exact raster set.** Create the 3 boss, 4 enemy, 2 facility,
   3 upgrade-card, and 1 replacement Target Designator candidates with the canonical
   reference. Build AS-IS/TO-BE sheets, collect exact user approval, promote approved
   hashes, update the semantic provider/catalog/manifest, and run the visual authority
   validator. Do not proceed with production asset integration before exact approval.

3. **Implement the eight-cycle campaign and common boss kit.** Convert progression,
   quotas, warnings, HUD, layouts, pickups, difficulty, guidebook, diagnostics, and
   report snapshots to eight cycles. Add the monotonic stat table, common committed
   charge, common aimed volley, identity-selection cap, and exact damage bands.

4. **Implement all eight boss identities.** Replace the global shield rule with profile-
   owned defense. Implement and validate Furnace Gates, alternating X-cross, frontal
   shield counterburst, moving sweep, attached relays, sustained banks, moving laser
   walls, and wedge pulse rings. Match every warning to collision geometry and preserve
   the high-threat escape corridor.

5. **Implement boss-death cleanup.** Add the dedicated runtime/state machine, owner tags,
   projectile/zone retirement, summon/facility cleanup, fixed-timeline body animation,
   reduced-motion branch, bounded effect-store kinds, audio receipts, frozen reporting,
   and transition gate. Validate no damage, loot, quota, or allocation leak during the
   cleanup window.

6. **Implement ordinary roles, pacing correction, and ten-session retention.** Add the
   four enemy runtimes/catalog entries and Wreck Scavenger death-event stacks. Expedite
   reserves and redirect nearby mobile hostiles within existing approach paths to meet
   gap limits. Change diagnostics to newest-ten ordering on load and persist while
   preserving protected summaries and existing byte/age caps.

7. **Implement upgrades, Target Designator, and offer reservations.** Add the three shot-
   outcome/movement cards in combat-owned state, replace Shock end to end, add compatible
   automatic-weapon preference, eligibility, visuals, reporting, localization, and
   validators, and enforce the missing active/secondary offer slots.

8. **Implement neutral facilities and reward changes.** Convert neutral devices to the
   five symmetric spatial effects, add destruction by both sides, preserve projectile
   passage, remove repair pickups, and add the exact experience-shard placements.

9. **Implement the shared stacked report.** Extract one report view model and one report-
   body component, reuse them in result/failure/Settings, remove nested scrolling, and
   validate alignment, order, localization, scaling, overflow, and clipping.

10. **Complete integration and release validation.** Run focused campaign, boss, enemy,
    upgrade, facility, diagnostics, report, localization, visual-authority, and ownership
    validators. Run the Web export. Capture clean comparable native/Web performance
    evidence with the same enemy counts, projectile cadence, effect limits, resolution,
    and warm-up as the baseline. Stop and fix any behavior, visual, overflow, authority,
    or capacity failure before handoff.

After each numbered item, update this plan's progress and send the user a concise
checkpoint containing completed scope, decisive evidence, remaining risks, and the next
item. Do not combine checkpoints across items.

## Validation and Acceptance

- Exactly eight boss cycles complete in order; every boss follows its ordinary quota
  and cleanup, and no player-facing stage-pair language remains.
- Every boss can charge and fire projectiles, identity patterns occupy at least three of
  five direct selections, and base health/damage/speed/cadence/coverage are monotonic.
- Every high-threat warning matches collision, lasts at least 1.30 seconds, leaves the
  required corridor, and applies damage at most once. No true instant kill exists.
- The frontal shield and relay defenses produce their linked counterattacks. No boss is
  defense-only and no global shield-down rule remains.
- Lethal boss damage yields exactly 2.00 seconds of safe cleanup before transition;
  boss-owned actors cannot damage, reward, or affect quota during cleanup.
- Wreck Scavenger uses exact death-event proximity, caps at five stacks, excludes the
  listed sources, and continues attacking at zero stacks. Shield Breaker is absent.
- Shock Disruption has no reachable resource, status, copy, report field, or offer.
  Target Designator obeys eligibility, single-target transfer, compatible targeting,
  boss validity, visuals, and separate reporting.
- The diagnostic store keeps the newest ten valid sessions after both load and persist,
  using saved time and session ID, while byte/age/quarantine contracts remain valid.
- Search gaps meet the 4/8/3-second structural contracts without teleporting enemies or
  reducing workload. Total run duration is observed in logs but is not a pass/fail goal.
- The report is one vertical left-aligned stack with one scroll and no clipping in all
  required locale, resolution, and text-scale combinations.
- The production manifest reaches exactly 90 only through exact approved asset hashes.
  Death effects remain code-native and fixed-capacity.
- Clean native/Web evidence is comparable to the recorded baseline. Any non-comparable,
  contaminated, or capacity-failing run is labeled diagnostic-only and cannot support a
  performance conclusion.

## Rollback Boundaries

- Campaign-flow, boss-pattern, death-cleanup, enemy-role, primary-attribute, facilities,
  report, diagnostics, and visual-asset commits remain separate and revertible.
- Do not retain compatibility aliases for Shock or player-facing stages. Roll back the
  whole owning slice if its replacement is not complete.
- Production visual promotion is hash-addressed. Reverting candidates must restore the
  prior manifest and bytes together.
- A failed performance checkpoint rolls back only the implicated runtime slice; it does
  not authorize lower enemy counts, slower attacks, smaller effects, or weaker visuals.

## Progress

- [x] Product candidates, public-asset comparison, current runtime inspection, and final
  design decisions were completed in the linked analysis before this plan was written.
- [ ] 1. Update product, design, terminology, and validation contracts.
- [ ] 2. Produce and approve the exact raster set.
- [ ] 3. Implement the eight-cycle campaign and common boss kit.
- [ ] 4. Implement all eight boss identities.
- [ ] 5. Implement boss-death cleanup.
- [ ] 6. Implement ordinary roles, pacing correction, and ten-session retention.
- [ ] 7. Implement upgrades, Target Designator, and offer reservations.
- [ ] 8. Implement neutral facilities and reward changes.
- [ ] 9. Implement the shared stacked report.
- [ ] 10. Complete integration and release validation.
