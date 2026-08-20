---
type: plan
status: active
owner: BK
created: 2026-08-20
last_reviewed: 2026-08-20
topic: Ordinary-enemy family, trait, pack, and remote pursuit-branch restructuring
scope: Research and decision checklist for replacing fragmented ordinary-enemy IDs with nine readable families, two traits per family, and pack-owned coordination
related:
  - ../../docs/reports/2026-08-20-ordinary-enemy-branch-and-restructure-review-ko.html
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../cardborne-performance-engineering-policy.md
  - ../research/performance/cardborne-runtime-architecture-audit.md
---

# Ordinary Enemy Family and Pack Restructure

Mode: research and decision checklist. This is not yet an execution contract. It records
verified current state, proposed decisions, unresolved product choices, and the work needed
before implementation can be safely authorized.

## Outcome

Prepare a merge-safe ordinary-enemy restructure that:

- keeps the nine-family taxonomy as the player-facing vocabulary;
- limits the initial active pool to two family-exclusive traits per family;
- makes every ordinary enemy a member of a persistent pack;
- guarantees at least one Defender in every pack containing a long-range ordinary enemy;
- reuses the current bounded squad coordinator instead of adding a second coordination owner;
- migrates useful behavior before deleting campaign-unreachable or duplicate archetype IDs;
- makes mobile tier size visibly larger than the current 48 px radius while keeping visual,
  projectile-hit, and body-collision contracts separate; and
- adapts the useful parts of `origin/agent/simplify-ordinary-enemy-ai` without merging its
  universal direct-pursuit decision as-is.

## Fixed user constraints

- Work on ordinary enemies only. Map exploration and tower-defense expansion are out of
  scope for this plan.
- The report must show the remote branch, its validity, current categories, and deletion
  candidates.
- Each family starts with no more than two active traits. Other candidates remain future
  notes only.
- Traits must not duplicate another family's core identity. In particular, Pursuer must not
  receive Armored or Heavy behavior that belongs to Defender/durability space.
- Coordinator keeps Blink in the initial pair.
- Long-range ordinary enemies never spawn without a Defender in the same pack.
- Existing user PNGs and current production PNGs may illustrate the report. Concept images
  are evidence only and are not approved production assets.

## Verified local evidence

### Runtime reachability

- `VehicleEnemyArchetypes` defines 26 ordinary archetypes.
- Normal 12-cycle packets directly use 14 archetypes.
- Boss add rosters add `ordinary_edge_01`, `ordinary_pull_01`,
  `ordinary_range_01`, and `ordinary_support_01`, for 18 campaign-reachable mobile
  archetypes.
- `ordinary_fixed_beam_01` is additionally reachable only as the Stage 3 boss's autonomous
  summon.
- Seven definitions do not spawn in the normal campaign:

  - `ordinary_support_02`
  - `ordinary_support_03`
  - `ordinary_melee_02`
  - `ordinary_fixed_ranged_01`
  - `ordinary_fixed_area_01`
  - `ordinary_fixed_ranged_02`
  - `ordinary_fixed_support_01`

The seven IDs are not safe one-line deletions. They are referenced by Guidebook entries,
presentation descriptors, semantic assets, combat branches, fixtures, or validators.
`ordinary_fixed_area_01` is also used as the behavior role of the reachable mobile
`ordinary_area_01` minelet.

### Current Controller and Coordinator truth

- No `controller` family or `coordinator` actor ID exists.
- `ordinary_gap_01` is presented as command-like, but its live attack is only a slow,
  low-damage projectile. It does not itself control a corridor or coordinate allies.
- `ordinary_compression_01` reuses Gap movement and art, but it replaces the projectile
  with a moving compression corridor. It is the only current ordinary archetype that
  clearly realizes the proposed Controller response.
- `ordinary_support_03` is an unreachable carrier prototype that spawns up to three
  `ordinary_melee_01` children. It is not a pack Coordinator.
- `VehicleCollectiveTacticRuntime` is a global bounded squad coordinator, not an enemy.
  It already owns member IDs, leaders, formations, and the Dormant → Gather → Lock →
  Execute → Break → Cooldown lifecycle.
- Blink, Invisible, Shrink, Like Rock, and pack-wide 몰아주기 are not currently implemented.
- `ordinary_melee_02` contains the closest existing primitive to 몰아주기: it gains bounded
  stacks when nearby enemies die. The current behavior buffs only itself and does not heal
  or buff surviving pack members.

### Existing pack boundary

- Every scheduled squad already receives `group_id`, `squad_id`, `squad_leader`,
  `formation_slot`, and `formation_size`.
- The current allocator redistributes all packet roles among squads. It tries to give each
  squad a pursuit member and limits projectile users, but it does not preserve authored
  family composition or guarantee a Defender.
- Only one squad per packet currently receives `collective_tactic_id`.
- The collective runtime registers at most 32 squads and grants Lock/Execute permission to
  only one squad at a time.

### Current trait and visual boundary

- The current global elite traits are `armored`, `overclocked`, and `heavy`. They apply to
  individual actors and are not family-exclusive.
- All mobile ordinary enemies currently share a 48 px visible/projectile target radius;
  installations use 62 px and bosses 146 px.
- Production ordinary-enemy PNGs use 112×112 mobile canvases and 160×160 installation
  canvases. Late aliases reuse earlier assets instead of owning tier art.
- Visual radius currently contributes to projectile hit radius. Tier-size implementation
  must separate those contracts before changing the visual footprint.

## Remote branch review

Candidate: `origin/agent/simplify-ordinary-enemy-ai` at `bd9f72f7`

PR: `#4 Simplify ordinary enemy pursuit`

Base: `origin/master` at `4d6bb2dc`

The branch is three commits ahead of its base. Local `master` is four commits ahead of the
same base. A merge-tree inspection against local `master` found no conflict markers, and
GitHub reports the PR as mechanically mergeable. The PR is still a draft and its merge
state is `UNSTABLE`.

The branch makes every mobile ordinary archetype resolve to one pursuit family. It targets
the player's current position for movement, removes movement prediction, standoff bands,
retreat, orbit, escort, and support positioning, and keeps blocked-route guidance, local
separation, velocity smoothing, speed caps, and attack-owned targeting prediction.

The recorded workflow failed at `Capture native rendered evidence`; later Web checks were
skipped and the expired log no longer exposes a useful root cause. This branch therefore
has neither a green workflow nor current evidence for the requested pack design.

### Merge decision

Do not merge the branch as-is. Its universal per-actor direct pursuit conflicts with:

- pack-owned anchor movement;
- long-range formation slots behind a Defender;
- support and Coordinator positioning;
- authored attack ranges that require room for warning and counterplay; and
- the requested family-specific response vocabulary.

Adapt these parts after the pack contract exists:

- movement focus uses the current objective/anchor position, not predictive movement;
- route guidance is requested only when the direct approach is blocked;
- local separation, velocity smoothing, and speed caps remain;
- attack commitment keeps its independent prediction and telegraph contract.

Reject or rewrite these branch parts:

- every member directly pursues the player;
- standoff, escort, and support ownership is removed;
- `docs/product/ordinary_enemy_behavior.md` records universal pursuit as the accepted
  product decision; and
- compatibility constants survive while their live meaning is removed.

## Proposed family contract

Each pack has one primary family, one tier, and at most one active trait. Required support
slots such as Defender use their base family behavior and do not add a second visible
trait. A Coordinator-primary pack may apply its trait to the whole pack.

| # | Family | Core response | Initial active traits | Current behavior seeds |
| --- | --- | --- | --- | --- |
| 01 | Pursuer | Maintain movement and escape space | Splitter, Frenzy | `melee_01`, `pulse_01` |
| 02 | Charger | Read the locked lane, dodge sideways, punish recovery | Overload, Double | `edge_01`, `pull_01`, `overload_01` |
| 03 | Bomber | Clear the fuse radius before detonation | Chain, Delayed | mobile `area_01` minelet |
| 04 | Gunner | Read the firing direction and break the lane | Burst, Piercing | `ranged_01`, `lane_01`, `range_01`, `beam_01` |
| 05 | Artillery | Leave the marked impact area and reach the backline | Cluster Shell, Lingering | `growth_01`, ground-burst primitives |
| 06 | Controller | Find or create a safe corridor | Compression, Sweep | `compression_01`; `sweep_01` denial zones |
| 07 | Defender | Change firing angle and target order | Bulwark, Reflector | `shield_01`, `reflect_01`, `support_02` prototype |
| 08 | Sustainer | Break repair links before attrition compounds | Repair Beam, Pulse Repair | `support_01`, fixed-support prototype |
| 09 | Coordinator | Break the pack-level tactic source | Blink, 몰아주기 | collective runtime; `support_03`/`melee_02` prototypes |

The initial pair is an implementation cap, not a promise that both ship immediately.
Invisible and Shrink remain future experiments because they weaken silhouette and hitbox
readability. Like Rock is not a Coordinator trait because extreme defense and slow movement
duplicate Defender and the current Armored/Heavy space. It may be reconsidered only as a
future Defender stance with explicit telegraph and collision rules.

## Tier and size proposal

Tier changes durability, threat budget, footprint, and at most one large family module. It
does not introduce a second behavior stack.

- T1: 52 px visible radius
- T2: 60 px visible radius
- T3: 68 px visible radius

These are prototype targets, not current visual authority. Before implementation:

- separate `visual_radius`, `projectile_hit_radius`, and body collision radius;
- verify that the 112×112 mobile sources remain acceptable at the proposed on-screen size;
- keep collision and projectile hitboxes unchanged until separately approved;
- test mixed 4–8 member packs at 16:9 and narrow Web viewports for overlap and threat
  readability; and
- update `docs/design/VISUAL_SYSTEM.md` only after the rendered comparison is approved.

Defender may use a larger family offset after the common tier step is validated. Do not
start with nine unrelated size curves.

## Pack composition contract

### Atomic admission

- Every ordinary actor belongs to exactly one persistent pack from cue to retirement.
- The default pack size remains 4–8 because the current scheduler and tactic runtime are
  already authored around that range.
- Admit, delay, substitute, or cancel the pack atomically. Do not materialize an orphan
  ranged actor while waiting for its Defender.
- Preserve authored population and threat budget. A mandatory Defender replaces a filler
  slot; it is not added above the current count or cap.

### Long-range Defender invariant

- Any pack containing Gunner, Artillery, or a long-range Controller contains at least one
  Defender.
- A pack with more than four long-range members requires a second Defender unless playtest
  evidence approves another ratio.
- The allocator consumes an authored pack blueprint. It must not rebuild all packet roles
  from one global bag after composition validation.
- The Defender occupies a front or flank formation slot; ranged units occupy protected
  rear slots. The protection must remain directional and breakable.
- Boss-summoned ordinary long-range installations must satisfy the same invariant or be
  reclassified as a boss pattern with its own explicit defense/counterplay contract.

### Pack trait state

- Store objective, family, tier, trait, leader, membership, formation, and shared cooldown
  once per pack.
- Keep health, collision, attack commitment, damage, status effects, and rendering per
  actor.
- Blink requires a readable warning, a collision-safe destination, and formation-preserving
  relocation. It must not place a member inside the player, cover, or another actor.
- 몰아주기 receives one bounded stack when an eligible, non-summoned member of the same pack
  dies. It heals and strengthens survivors within a cap. Child summons and repeated
  retirement receipts cannot create stacks. Killing the Coordinator disables future stacks.

## Deletion and migration matrix

No production enemy file is deleted during research. Use this order during implementation.

| Current item | Reachability | Target | Deletion condition |
| --- | --- | --- | --- |
| `ordinary_support_02` | Unreachable | Reuse behavior/art as Defender escort seed | New Defender family and pack invariant pass |
| `ordinary_support_03` | Unreachable | Reuse visual/ carrier ideas only if Coordinator needs an actor | Coordinator decision and migration complete |
| `ordinary_melee_02` | Unreachable | Move bounded death-stack primitive into 몰아주기 pack state | Pack trait tests replace actor tests |
| `ordinary_fixed_ranged_01` | Unreachable | Remove or move to a future installation catalog | Guidebook, combat, visual, fixture, and asset consumers removed |
| `ordinary_fixed_area_01` archetype | Unreachable directly | Split reachable mobile mine behavior from fixed deployment | `ordinary_area_01` no longer depends on the fixed role name |
| `ordinary_fixed_ranged_02` | Unreachable | Remove or move to future installation catalog | Interceptor branches and fixtures retired or relocated |
| `ordinary_fixed_support_01` | Unreachable | Retain repair primitive only if Sustainer uses it | Support/shield branches migrated |
| `ordinary_compression_01` | Reachable alias | Controller Compression trait | Stage 9–12 roster and Guidebook migrate to family/tier/trait data |
| `ordinary_reflect_01` | Reachable alias | Defender Reflector trait | Stage 10–12 roster and reflection tests migrate |
| `ordinary_resonance_01` | Reachable alias | Future Gunner candidate or delete | Two-trait decision remains fixed and stage roster has replacement |
| `ordinary_overload_01` | Reachable alias | Charger Overload trait | Stage 12 roster and vulnerability logic migrate |
| global `armored`, `overclocked`, `heavy` | Reachable elite system | Replace with family-owned two-trait pools | Guidebook, thresholds, visuals, and deterministic selection migrate |

When an ID is retired, remove or update all of its archetype data, stage/boss references,
movement/attack branches, Guidebook entries, localization keys, visual descriptors,
semantic manifest records, renderer branches, validation fixtures, and tests in the same
coherent migration. Production PNG deletion is a separate visual-authority step and must
follow an explicit asset-use audit.

## Responsibility boundaries

- `VehicleCombatStages`: authored family/tier/pack blueprints and rollout.
- `VehicleSpawnAllocator`: geometry-safe placement of already-valid pack blueprints; no
  family bag reshuffle.
- `VehicleCollectiveTacticCatalog`: formation/tactic recipes only.
- `VehicleCollectiveTacticRuntime`: persistent pack membership, shared phase, objective,
  trait timer/stacks, and formation slots.
- New or existing enemy catalogs: family, tier, trait, and base behavior data.
- `VehicleEnemyMovementPolicy`: member movement toward a pack anchor/slot plus local
  recovery; not universal player pursuit.
- Attack contracts and specialist runtimes: attack startup, commitment, projectile, area,
  defense, repair, and collision truth.
- `VehicleRun`: orchestration only. Do not add another family/pack switch table to the
  existing large script.
- Presentation catalogs/renderers: family/tier/trait appearance and telegraph state only;
  visuals never own damage, collision, AI, or trait eligibility.

## Performance claim boundary

Pack IDs already exist. Therefore pack spawning alone is not an optimization. Actor count,
collision, projectile checks, health, XP, and rendering remain per actor. The only plausible
saving is moving shared objective selection, formation decisions, and trait timers out of
per-actor loops.

Before claiming improvement:

- capture a comparable clean baseline at the exact pre-change commit;
- preserve actor, projectile, effect, cadence, collision, and threat workloads;
- add or reuse named timing for pack coordination versus ordinary member updates;
- run focused functional validators during implementation;
- run the active plan's authoritative native and built-Web scenarios only at the declared
  clean checkpoint; and
- report exact labels such as `focused validator passed` or `native release performance
  passed`, never a generic performance pass.

## External evidence and applicability

- Godot 4.7 performance guidance supports profiling the named bottleneck, compact/reused
  data, and moving invariant work out of loops. It does not prove that pack state will
  improve this project's frame time.
- GDC's *Squad Coordination in Days Gone* supports a virtual squad representation that
  analyzes shared friendly/enemy space and positions members as a group. Cardborne can use
  the same ownership idea without copying an open-world combat model.
- GDC's *Three States and a Plan: The AI of F.E.A.R.* supports readable squad cooperation
  emerging from coordinated roles instead of many unrelated individual behaviors.
- Riot's *Clarity in League* supports unique silhouettes, visual hierarchy, and matching
  visible effects to gameplay impact. This conflicts with shipping true invisibility,
  frequent shrinking, or hidden defense spikes without strong warning.

## Rejected alternatives

- Merge the remote branch unchanged: rejected because universal direct pursuit removes
  necessary pack and long-range positioning.
- Keep all 26 IDs and add family metadata on top: rejected because duplicate aliases and
  unreachable prototypes would remain competing authorities.
- Delete the seven unreachable definitions immediately: rejected because three contain
  useful migration seeds and the fixed-area role currently owns reachable mobile-mine
  behavior.
- Give every family five traits at launch: rejected by the explicit two-trait cap and
  readability budget.
- Add a Node per pack: rejected until profiling proves the current bounded RefCounted
  runtime inadequate.
- Claim a performance win from grouped spawning: rejected without a comparable baseline and
  named owner evidence.

## Open product decisions

- [ ] Approve or revise the two-trait family table.
- [ ] Confirm that Coordinator uses Blink + 몰아주기 for the first implementation.
- [ ] Confirm that Invisible and Shrink are future-only, and Like Rock is excluded from
  Coordinator.
- [ ] Confirm the common 52 / 60 / 68 prototype size ladder before visual production.
- [ ] Decide whether the four unreachable fixed installations are deleted or retained in a
  separate future-expansion catalog.
- [ ] Decide whether `ordinary_fixed_beam_01` remains an ordinary enemy with a mandatory
  Defender or becomes a boss-owned pattern object.
- [ ] Approve replacing a filler slot with Defender so pack admission does not increase
  authored counts or threat budget.

## Implementation workstreams after approval

### A. Lock data and compatibility contracts

- [ ] Create the family/tier/trait schema and migration map.
- [ ] Add validators for family-exclusive traits, two-trait caps, one active pack trait,
  and long-range Defender membership.
- [ ] Separate visual, projectile-hit, and body-collision radius ownership.

### B. Make every squad a semantic pack

- [ ] Replace role-bag redistribution with authored pack blueprints.
- [ ] Assign collective state to every pack while preserving bounded permissions.
- [ ] Move objective and formation decisions to pack state; keep fairness-critical actor
  state per member.
- [ ] Add atomic delay/substitution/cancel behavior when a full pack cannot materialize.

### C. Implement the first family slice

- [ ] Implement one long-range Gunner pack with one Defender.
- [ ] Adapt current-position anchor movement, blocked-route guidance, separation,
  smoothing, and speed caps from the remote branch.
- [ ] Verify attack prediction, standoff room, telegraphs, collision, and pack break rules.

### D. Implement Coordinator traits

- [ ] Add Blink with warning, safe destination validation, and formation preservation.
- [ ] Migrate the bounded `ordinary_melee_02` death receipt into pack-owned 몰아주기.
- [ ] Add Coordinator-death shutdown, summon exclusions, stack cap, and duplicate-receipt
  tests.

### E. Migrate and retire old IDs

- [ ] Convert Compression, Reflect, and Overload aliases to family traits.
- [ ] Replace or retire Resonance under the two-trait cap.
- [ ] Migrate useful unreachable prototypes, then remove their old IDs and all consumers.
- [ ] Replace the global elite catalog and Guidebook entries with family-owned traits.

### F. Visual and runtime validation

- [ ] Produce actual-size T1/T2/T3 comparisons under the visual-authority workflow.
- [ ] Validate family, tier, facing, trait, and telegraph recognition at combat scale.
- [ ] Run targeted family, pack, spawn-allocation, collective-tactic, Guidebook, semantic
  asset, and twelve-cycle validators.
- [ ] Run native and built-Web smoke/qualification only at the clean plan checkpoint.

## Exit criteria for converting this to an execution contract

The plan may move to implementation mode only when all open product decisions are resolved,
the first family slice is named, the fixed-installation disposition is explicit, the
compatibility/deletion map is accepted, and the validation checkpoint names exact focused,
native, and Web gates.
