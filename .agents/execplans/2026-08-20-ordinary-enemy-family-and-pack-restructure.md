---
type: plan
status: active
owner: BK
created: 2026-08-20
last_reviewed: 2026-08-20
topic: Ordinary-enemy family, trait, pack, and remote pursuit-branch restructuring
scope: Research and decision checklist for replacing fragmented ordinary-enemy IDs with five readable families, two traits per family, and pack-owned coordination
related:
  - ../../docs/reports/2026-08-20-ordinary-enemy-branch-and-restructure-review-ko.html
  - ../../docs/reports/2026-08-20-ordinary-enemy-five-family-revision-en.html
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/design/visual-replacement-workbench/README.md
  - ../cardborne-performance-engineering-policy.md
  - ../research/performance/cardborne-runtime-architecture-audit.md
---

# Ordinary Enemy Family and Pack Restructure

Mode: research and decision checklist. This is not yet an execution contract. It records
verified current state, proposed decisions, unresolved product choices, and the work needed
before implementation can be safely authorized.

## Outcome

Prepare a merge-safe ordinary-enemy restructure that:

- replaces the earlier nine-family proposal with five player-facing families;
- limits the initial active pool to two family-exclusive traits per family;
- makes every ordinary enemy a member of a persistent pack;
- guarantees at least one Defender in every pack containing a long-range ordinary enemy;
- reuses the current bounded squad coordinator instead of adding a second coordination owner;
- migrates useful behavior before deleting campaign-unreachable or duplicate archetype IDs;
- makes mobile tier size grow through the integer 100 / 125 / 150 percentage ladder while
  keeping visual, projectile-hit, and body-collision contracts separate; and
- creates and approves the complete five-family base-and-trait visual set before any
  runtime enemy schema, behavior, roster, or production-asset switch; and
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
- User-provided concept PNGs may illustrate the revision report. Concept images are evidence
  only and are not approved production assets.
- The revision report uses the newer user-provided concept sheets only. It does not use the
  current production ordinary-enemy PNGs as family examples.
- This ExecPlan is the source for every derived ordinary-enemy report. Update and commit the
  ExecPlan before changing a report. Each report names the exact plan commit it follows.
- Each family section shows exactly three PNG files: one T1 image, one T2 image, and one T3
  image. Do not show trait thumbnails, a full nine-cell matrix, or extra actor images inside
  a family section.
- Tier size uses integer percentages relative to the family T1 visual: T1 `100%`, T2 `125%`,
  and T3 `150%`. Do not store or present the tier contract as absolute pixel radii.
- Replace the previous orange triangular Coordinator concepts with the simpler circular
  three-tier concept formerly placed in the removed Bomber cell. This is a visual reuse
  decision only; it does not carry Bomber or Self-Destruct behavior into Coordinator.
- Controller and Sustainer are removed from the ordinary-enemy family set.
- Bomber is removed as a family. Self-Destruct replaces Overload as one Charger trait.
- Gunner and Artillery are one Gunner family. Its two traits are Artillery and Slow.
- Defender Bulwark periodically grows and projects a large shield over nearby enemies.
- Defender Reflector normally uses a standard shield and reflects only during a periodic,
  clearly warned active window.
- Every Gunner pack includes a Defender, including packs whose Gunner has the Artillery
  trait.
- The report-only concept crops are not the target art. Generate a new, simpler visual set
  under the canonical visual authority pair before changing the enemy implementation.
- A trait-applied actor must be identifiable from its own body at combat scale. Do not use
  floating labels, trait badges, permanent halos, detached icons, or color alone.
- Complete and approve all 45 staged actor images first: five families × three tiers ×
  (`base` + two family traits). Runtime and production integration starts only after this
  visual gate is complete.

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

Decision update: this evidence does not justify a Controller family. Remove the Controller
label and its dedicated actor IDs. Reuse only generic impact or warning primitives when an
approved Gunner Artillery attack needs them. Sustainer is also removed; ordinary repair
actors and their unused prototypes do not survive as a separate family.

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

The branch is three commits ahead of its base. Local `master` has separately diverged from
the same base; its exact ahead count changes whenever this plan or its derived report is
committed. A merge-tree inspection found no structural conflict signal, and GitHub reports
the PR as mechanically mergeable. The PR is still a draft and its merge state is
`UNSTABLE`.

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

## Approved five-family contract

Each pack has one primary family, one tier, and at most one active trait. A required
Defender slot uses base Defender behavior unless the authored pack explicitly assigns one
of the two Defender traits. A Coordinator-primary pack may apply its trait to the whole
pack.

| # | Family | Core response | Initial active traits | Current behavior seeds |
| --- | --- | --- | --- | --- |
| 01 | Pursuer | Maintain movement and escape space | Splitter, Frenzy | `melee_01`, `pulse_01` |
| 02 | Charger | Read the locked lane, dodge sideways, then clear the fuse area when needed | Double, Self-Destruct | `edge_01`, `pull_01`; mobile `area_01` explosion seed |
| 03 | Gunner | Break direct fire lanes or leave a marked impact area | Artillery, Slow | `ranged_01`, `lane_01`, `range_01`, `beam_01`, `growth_01`, ground-burst primitives |
| 04 | Defender | Change firing angle and target order | Bulwark, Reflector | `shield_01`, `reflect_01`, `support_02` prototype |
| 05 | Coordinator | Break the pack-level tactic source | Blink, 몰아주기 | collective runtime; `support_03`/`melee_02` prototypes |

The initial pair is an implementation cap, not a promise that both traits ship in one
slice. Controller, Sustainer, and Bomber are not future launch families. Separate
Artillery is also removed; Artillery is a Gunner trait.

### Trait behavior contract

- Charger / Double: execute a readable second charge after the first recovery window.
- Charger / Self-Destruct: replace Overload. After a normal charge ends, show a short fuse,
  then explode and retire the Charger. A kill before fuse commitment prevents the
  explosion unless playtesting proves that counter too easy.
- Gunner / Artillery: replace direct fire with a clearly marked lobbed or ground-impact
  shot. It remains a Gunner and therefore still requires a Defender in its pack.
- Gunner / Slow: a hit applies one bounded slow. Later hits refresh the same effect instead
  of stacking it into a movement lock. The projectile needs a distinct warning color or
  trail before this trait can ship.
- Defender / Bulwark: on an `M`-second cadence, the Defender visibly grows for `N` seconds
  and projects a larger shield that also protects nearby pack members. The growth and
  shield boundary must be readable before protection starts.
- Defender / Reflector: the normal state is a standard shield. On an `M`-second cadence, a
  warned `N`-second window changes it into a reflective shield. Reflection is never always
  active.
- Coordinator / Blink: relocate the pack only after a warning and collision-safe
  destination check.
- Coordinator / 몰아주기: an eligible pack-member death heals and strengthens the
  survivors within a strict cap. Coordinator death stops future gains.

Invisible and Shrink remain future experiments because they weaken silhouette and hitbox
readability. Like Rock remains excluded because it duplicates Defender's defense space.

## Pre-integration visual asset gate

This gate must finish before implementation workstream A. It creates reviewable final
candidates, not production-integrated files. The existing `ordinary_enemy_family`
workbench unit is an already-applied 19-ID replacement and must not be overwritten. A new
switch unit and exact production target paths can be authored only after the five-family
runtime schema names its stable semantic IDs.

### Authority and staging

- Mandatory authority:
  `docs/design/VISUAL_SYSTEM.md` plus
  `docs/design/cardborne-universal-art-style-reference.png`.
- The canonical sheet is style grammar only. Do not reproduce its example objects or
  layout.
- The user-provided lineup is a role-and-progression concept reference only. Do not copy
  its white report background, labels, shadows, rejected Coordinator design, or exact
  object rendering.
- Save generated review material under
  `docs/design/visual-replacement-workbench/previews/ordinary-enemy-five-family-v1/`.
  Do not write to `to-be/assets/`, the production visual root, the gameplay manifest, or a
  runtime provider in this gate.
- Use five family master sheets. Each sheet is a strict 3×3 transparent grid with equal
  cell bounds: columns T1/T2/T3; rows base/trait A/trait B. Mechanically extract the grid
  into 45 individual transparent PNG candidates after inspecting each sheet.
- Normalize every extracted actor to the same family canvas and pivot convention. The PNG
  itself does not encode the 100/125/150 tier size. A non-creative comparison sheet renders
  the normalized files at those three percentages; runtime will later own the percentage
  scale.

### Shared actor grammar

- Exact top-down view and right-facing forward direction.
- One dominant silhouette, three to five large filled planes, a dark perimeter, matte main
  mass, one light plane, one shadow plane, and at most two large functional modules.
- Danger coral owns the ordinary-hostile main semantic plane. Cyan or mint may appear only
  as one restrained state/function accent when the trait needs it.
- Use broad cuts, plates, prongs, barrels, and negative space that survive grayscale and
  combat-scale inspection.
- Do not use decorative rivets, tiny circles, clusters of lamps, random panel seams,
  concentric rings, nested frames, text, labels, badges, logos, watermarks, bloom, or a
  scene background.
- Keep transparent padding around the complete body. No shadow, glow, trail, shield ring,
  explosion radius, projectile path, or blink afterimage may extend beyond the actor
  footprint.

### Trait-owned body cues

Each trait owns one permanent body cue so the player can identify the applied trait even
while its timed behavior is inactive. Later runtime presentation may animate or tint that
same cue, but gameplay radius and timing remain code-owned.

| Family | State | Required permanent body cue | Later code-owned cue |
| --- | --- | --- | --- |
| Pursuer | Splitter | One deep forward cleft that divides the main nose into two broad lobes | split timing and child placement |
| Pursuer | Frenzy | Two long swept side blades that make the silhouette visibly more aggressive | speed/attack pulse within actor alpha |
| Charger | Double | Two parallel forward charge prongs with one clear gap | second-charge warning and lane |
| Charger | Self-Destruct | One large exposed central core held by two broad shutters | fuse pulse, blast area, and retirement |
| Gunner | Artillery | One short, wide mortar-like barrel and enlarged breech instead of the direct-fire barrel | impact marker and lob trajectory |
| Gunner | Slow | One broad forked muzzle plus one cyan chamber plane | projectile trail/hit slow state |
| Defender | Bulwark | Two folded outer shield shoulders around one broad front plate | timed body growth and shared closed shield boundary |
| Defender | Reflector | One angular mirror-like inset across the normal front shield | warned reflective-window material state |
| Coordinator | Blink | One large offset cut through the round body and one transverse cyan slit | destination warning and relocation |
| Coordinator | 몰아주기 | One thick Y-shaped receiver plate inside the body, without small nodes | bounded pack-feed pulse within actor alpha |

The transient shield boundary, artillery impact area, Self-Destruct blast area, Blink
destination, projectile trails, and other timing geometry are not raster deliverables.
They remain retained code-native presentation tied to gameplay truth during later
implementation.

### Required review deliverables

- Five transparent family master sheets.
- Forty-five extracted transparent actor PNGs using
  `<family>/<state>/<family>-<state>-t<tier>.png` naming.
- Five non-creative family comparison sheets that render every state row at T1 `100%`, T2
  `125%`, and T3 `150%`.
- One prompt/provenance record containing the exact prompt for each family, reference image
  paths, authority hashes, generation method, output hashes, and the AS-IS/TO-BE judgment.
- One grayscale contact sheet proving that family, tier, and trait cues are not color-only.

No candidate is called production-ready merely because it was generated or cropped. The
user must approve the five family comparisons before a new workbench switch unit can move
the selected files toward `to-be/assets/`.

## Report image derivation contract

The report is a view of this ExecPlan, not a second design authority. The plan must be
updated and committed first. The report then records that exact plan commit as its basis.

Use only non-creative crops from
`docs/reports/assets/2026-08-20-game-structure-ordinary-enemies/enemy-tier-family-lineup.png`
(SHA-256 `47dc723c6349336725dece97e672d5a1c3949e17be355bce9e0b17895151fe18`).
Store the derived report-only files under
`docs/reports/assets/2026-08-20-game-structure-ordinary-enemies/five-family-tiers/`.

| Family | Source trio in the provided lineup | Required report files |
| --- | --- | --- |
| Pursuer | upper-left trio | `pursuer-t1.png`, `pursuer-t2.png`, `pursuer-t3.png` |
| Charger | upper-center trio | `charger-t1.png`, `charger-t2.png`, `charger-t3.png` |
| Gunner | middle-left trio | `gunner-t1.png`, `gunner-t2.png`, `gunner-t3.png` |
| Defender | lower-left trio | `defender-t1.png`, `defender-t2.png`, `defender-t3.png` |
| Coordinator | upper-right simple circular trio, formerly the removed Bomber visual cell | `coordinator-t1.png`, `coordinator-t2.png`, `coordinator-t3.png` |

The orange triangular lower-right trio is rejected for Coordinator because its T2/T3
silhouettes add too many competing modules compared with the other families. Reusing the
upper-right circular trio does not reuse Bomber behavior, color meaning, fuse effects, or
trait thumbnails. The later production-art task must still approve or replace all concept
assets under the visual-authority workflow.

Each family card contains exactly the three listed `<img>` elements in T1 → T2 → T3 order.
Trait effects remain text-only in this report. The source lineup and nine-cell matrix may be
named in provenance text but are not displayed as extra report images.

## Tier and percentage-size contract

Tier changes durability, threat budget, visual scale, and at most one large family module.
It does not introduce a second behavior stack.

| Tier | Integer `size_percent` | Meaning |
| --- | ---: | --- |
| T1 | `100` | Family baseline visual size |
| T2 | `125` | 25% larger than the same family's T1 baseline |
| T3 | `150` | 50% larger than the same family's T1 baseline |

Runtime data stores the integer percentage. Presentation derives a scale factor only at the
render boundary: `visual_scale = size_percent / 100.0`. Do not place absolute pixel radii in
family/tier product data or the report.

Before implementation:

- separate visual scale, `projectile_hit_radius`, and body collision radius;
- keep collision and projectile hitboxes unchanged until separately approved;
- treat Bulwark's temporary growth as a separate timed percentage modifier, not a fourth
  tier;
- verify mixed 4–8 member packs for overlap and threat readability; and
- update `docs/design/VISUAL_SYSTEM.md` only after a rendered production-art comparison is
  approved.

Defender may receive a family-specific baseline offset only after the shared 100/125/150
ladder is validated. Do not create separate tier curves for every family.

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

- Every pack containing a Gunner contains at least one Defender. This includes direct-fire,
  Artillery-trait, and Slow-trait Gunners without exception.
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
| `ordinary_gap_01` | Reachable | Delete with Controller family | Stage roster and Guidebook use a five-family replacement |
| `ordinary_compression_01` | Reachable alias | Delete with Controller family | Corridor code and all presentation/test consumers are removed or explicitly reused by an approved Gunner attack |
| `ordinary_sweep_01` | Reachable | Delete Controller-style actor ID; reuse only generic ground-impact code for Gunner Artillery | Stage roster and Guidebook migrate to Gunner family data |
| `ordinary_support_01` | Campaign-reachable in boss add rosters | Delete with Sustainer family | Boss add rosters and support branches use an approved five-family replacement |
| `ordinary_support_02` | Unreachable | Migrate only the useful shield primitive to Defender, then delete | Defender Bulwark tests replace prototype tests |
| `ordinary_fixed_support_01` | Unreachable | Delete with Sustainer family | Repair/support branches, fixtures, Guidebook, and assets have no remaining consumers |
| `ordinary_support_03` | Unreachable | Delete the carrier actor; keep coordination in pack state | Coordinator pack tests no longer depend on carrier spawning |
| `ordinary_melee_02` | Unreachable | Move bounded death-stack primitive into 몰아주기 pack state, then delete | Pack trait tests replace actor tests |
| `ordinary_area_01` | Reachable | Move the readable fuse/explosion into Charger Self-Destruct, then delete the Bomber-style actor ID | Charger trait and stage migration pass |
| `ordinary_fixed_area_01` archetype | Unreachable directly | Remove after `ordinary_area_01` no longer depends on its role name | Area-role consumers are migrated or deleted |
| `ordinary_growth_01` | Reachable | Move marked impact behavior into Gunner Artillery, then delete the separate Artillery actor ID | Gunner Artillery tests and stage migration pass |
| `ordinary_reflect_01` | Reachable alias | Convert to periodic Defender Reflector state, then delete the alias ID | Stage roster and reflection tests use family/trait data |
| `ordinary_resonance_01` | Reachable alias | Delete under the two-trait Gunner cap | Stage roster has a Gunner Artillery or Slow replacement |
| `ordinary_overload_01` | Reachable alias | Delete; Self-Destruct replaces Overload | Stage 12 roster and vulnerability logic migrate |
| `ordinary_fixed_ranged_01` | Unreachable | Delete from ordinary-enemy code unless a later installation expansion explicitly adopts it | Guidebook, combat, visual, fixture, and asset consumers removed |
| `ordinary_fixed_ranged_02` | Unreachable | Delete from ordinary-enemy code unless a later installation expansion explicitly adopts it | Interceptor branches and fixtures retired or relocated |
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

### Provenance of performance-related decisions

`origin/agent/simplify-ordinary-enemy-ai` is not a game-wide performance branch. Its own
ExecPlan limits scope to ordinary-enemy movement policy, movement targeting, and two focused
validators, and explicitly excludes performance claims that require profiling or a
full-load benchmark. Therefore this plan does not attribute any general performance
improvement to that branch.

The branch contributes only behavior-simplification candidates:

- target the current pack objective rather than predict movement destination;
- request existing route guidance only when the direct approach is blocked;
- preserve local separation, velocity smoothing, speed caps, and attack-owned prediction.

The performance safeguards in this plan come from
`.agents/cardborne-performance-engineering-policy.md` and
`.agents/research/performance/cardborne-runtime-architecture-audit.md`:

- reuse the existing bounded pack/squad runtime instead of adding a Node per pack;
- move only invariant objective, formation, and trait-timer work from members to pack state;
- keep actor count, projectile count, collision, cadence, attack activity, visual quality,
  and thresholds unchanged during a behavior-preserving comparison;
- keep visual scale separate from projectile-hit and body-collision ownership; and
- require a clean comparable baseline and named subsystem timings before claiming any
  performance improvement.

Game-wide performance architecture, renderer batching, projectile collision, HUD staging,
and `VehicleRun` extraction remain outside this ordinary-enemy restructure. They stay under
their separate performance policy, evidence, and active performance plans.

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

- [x] Approve the revised five-family, two-trait table.
- [x] Confirm that Coordinator uses Blink + 몰아주기 for the first implementation.
- [x] Confirm that Invisible and Shrink are future-only, and Like Rock is excluded from
  Coordinator.
- [x] Replace absolute tier radii with the integer 100 / 125 / 150 percentage ladder.
- [x] Delete the four unreachable fixed installations from ordinary-enemy code after their
  consumers are audited. A later tower-defense expansion must define new installation data
  instead of preserving inactive ordinary-enemy IDs.
- [ ] Decide whether `ordinary_fixed_beam_01` remains an ordinary enemy with a mandatory
  Defender or becomes a boss-owned pattern object.
- [x] Approve replacing a filler slot with Defender so pack admission does not increase
  authored counts or threat budget.

## Implementation workstreams after approval

### V. Complete the visual gate before project changes

- [x] Generate five authority-grounded 3×3 family master sheets.
- [x] Inspect and reject any sheet with non-transparent background, perspective drift,
  duplicated/missing cells, tiny decorative noise, or trait cues outside the body.
- [x] Extract and normalize all 45 actor candidates without creative repainting.
- [x] Build percentage-scale and grayscale comparison sheets.
- [x] Record prompt, reference, authority, and output provenance.
- [ ] Obtain explicit user approval for the five family comparisons.

Do not begin workstream A, edit the current `ordinary_enemy_family` switch unit, or change
runtime/production files while any item in workstream V remains incomplete.

Checkpoint: the review set is staged under
`docs/design/visual-replacement-workbench/previews/ordinary-enemy-five-family-v1/` with five
masters, 45 normalized transparent actors, five family comparisons, color/grayscale
overviews, and prompt/hash provenance. User approval remains the only incomplete item in
this gate. No production or runtime file changed.

### A. Lock data and compatibility contracts

- [ ] Create the family/tier/trait schema and migration map.
- [ ] Add validators for family-exclusive traits, two-trait caps, one active pack trait,
  and long-range Defender membership.
- [ ] Store integer `size_percent` values 100 / 125 / 150 and derive presentation scale at
  the render boundary.
- [ ] Separate visual scale, projectile-hit radius, and body-collision radius ownership.

### B. Make every squad a semantic pack

- [ ] Replace role-bag redistribution with authored pack blueprints.
- [ ] Assign collective state to every pack while preserving bounded permissions.
- [ ] Move objective and formation decisions to pack state; keep fairness-critical actor
  state per member.
- [ ] Add atomic delay/substitution/cancel behavior when a full pack cannot materialize.

### C. Implement the first family slice

- [ ] Implement one Gunner pack with one Defender and verify the invariant for direct-fire,
  Artillery, and Slow variants.
- [ ] Implement Artillery as a Gunner trait and migrate the approved marked-impact
  primitives from `ordinary_growth_01` or `ordinary_sweep_01` without retaining a separate
  Artillery family.
- [ ] Implement Slow as a non-stacking, bounded on-hit state with a distinct projectile cue.
- [ ] Implement periodic Bulwark growth/shared protection and periodic Reflector activation
  over a normal shield baseline.
- [ ] Adapt current-position anchor movement, blocked-route guidance, separation,
  smoothing, and speed caps from the remote branch.
- [ ] Verify attack prediction, standoff room, telegraphs, collision, and pack break rules.

### D. Implement Coordinator traits

- [ ] Add Blink with warning, safe destination validation, and formation preservation.
- [ ] Migrate the bounded `ordinary_melee_02` death receipt into pack-owned 몰아주기.
- [ ] Add Coordinator-death shutdown, summon exclusions, stack cap, and duplicate-receipt
  tests.

### E. Migrate and retire old IDs

- [ ] Remove Controller and Sustainer family IDs and migrate only approved generic attack or
  shield primitives.
- [ ] Move the Bomber fuse/explosion into Charger Self-Destruct, delete the Bomber-style
  actor ID, and remove Overload.
- [ ] Merge Artillery into Gunner and retire separate Artillery actor IDs after stage and
  Guidebook migration.
- [ ] Convert Reflect into the periodic Defender Reflector trait and retire its alias ID.
- [ ] Retire Resonance under the two-trait Gunner cap.
- [ ] Migrate useful unreachable prototypes, then remove their old IDs and all consumers.
- [ ] Replace the global elite catalog and Guidebook entries with family-owned traits.

### F. Visual and runtime validation

- [ ] Promote only the user-approved workstream-V files through a new exact workbench switch
  unit after stable semantic IDs and production target paths exist.
- [ ] Validate family, tier, facing, trait, and telegraph recognition at combat scale.
- [ ] Run targeted family, pack, spawn-allocation, collective-tactic, Guidebook, semantic
  asset, and twelve-cycle validators.
- [ ] Run native and built-Web smoke/qualification only at the clean plan checkpoint.

## Exit criteria for converting this to an execution contract

The plan may move to implementation mode only when all open product decisions are resolved,
the first family slice is named, the fixed-installation disposition is explicit, the
compatibility/deletion map is accepted, and the validation checkpoint names exact focused,
native, and Web gates.
