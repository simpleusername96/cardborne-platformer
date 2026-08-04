---
type: evidence
status: active
owner: BK
created: 2026-08-04
last_reviewed: 2026-08-04
topic: Gameplay visual asset rationalization and external-source intake before Phase 6 implementation
scope: Classification of all 215 production gameplay PNGs, the revised 49-PNG target boundary, external source candidates, and deferred small-effect polish
source: Local manifest, runtime consumer, filesystem, Git history, visual-system, workbench, rendered-contact-sheet, and official-license audit on 2026-08-04
related:
  - ../VISUAL_SYSTEM.md
  - ./README.md
  - ./external-candidates/README.md
  - ./replacement-workbench.json
  - ../../../art/visuals/production/gameplay/asset-manifest.json
  - ../../../.agents/execplans/2026-08-04-complete-remaining-visual-replacements.md
---

# Gameplay Visual Asset Rationalization Audit

## Purpose

This document records the preimplementation evidence used to reduce and regroup
the remaining visual replacement program before production images are switched
or deleted. It accounts for every current gameplay PNG, fixes the former
over-conversion to code-native graphics, records the external-source search, and
defines a verifiable final media count.

This is evidence, not switch authorization. The durable media boundary belongs
to [`VISUAL_SYSTEM.md`](../VISUAL_SYSTEM.md), the ordered work belongs to the
active ExecPlan, and `replacement-workbench.json` remains the only hand-authored
unit, approval, and application-state source. No production deletion or runtime
switch is authorized by this audit alone.

## Sources

- `art/visuals/production/gameplay/asset-manifest.json`, including all static
  asset sets and 22 animation identities.
- All 215 current production gameplay PNG files and their import sidecars.
- Direct runtime and guidebook consumers under `scripts/` and focused validators
  under `tools/validation/`.
- Current workbench units, generated inventory, AS-IS media, and review sheets.
- `docs/product/vehicle_game_spec.md` and the active visual-system contract.
- Git history for the semantic-v2 generation and import commits.
- Official Kenney, Quaternius, and KayKit source pages and included license files.
- The curated source files and contact sheet under `external-candidates/`.

## Findings

### Verified current truth

- Production contains exactly **215 gameplay PNGs**: 114 static images and 101
  animation-frame images.
- Folder counts are actors 35, weapons 13, states 7, pickups 6, world 10,
  HUD/combat cues 43, and effect frames 101.
- Every current PNG is indexed once by the manifest. There are no missing files,
  unindexed production PNGs, duplicate semantic IDs, duplicate paths, or
  byte-identical PNG pairs.
- There are still zero approved, directly promotable TO-BE gameplay PNGs. Review
  sheets, mockups, external sources, and the EMP review candidate are not TO-BE
  deliverables.
- Project history contains no prior third-party gameplay/UI art-pack evaluation
  or import. The semantic-v2 pack was generated from project-approved sheets and
  prompts. Noto Sans KR is the only pre-existing external production visual
  dependency and is already covered by its SIL OFL license.
- The former 64-PNG target over-specified nine projectile identities and seven
  presentation-only defense/status overlays. The current product needs one
  shared authored projectile body, code-native protection feedback, and no
  dedicated burn/poison/chill raster icons. Pickups, crates, facilities, and
  bulkheads remain complete authored PNGs.

### Classification vocabulary

| Disposition | Meaning |
| --- | --- |
| `REUSE EXISTING` | Keep current production bytes because they already satisfy the approved contract. |
| `REPLACE PNG` | Preserve the semantic identity and target path, but replace the current bytes with one complete authored PNG. |
| `SHARE MASTER PNG` | Consolidate multiple files into one authored PNG that runtime may scale or select by state. |
| `ADD PNG` | Add a missing authored world object, state, or the one approved large effect. |
| `CODE-NATIVE` | Preserve the semantic role through shared geometry because it is a HUD/minimap/cue or live dynamic boundary, not a world object. |
| `SUPPRESS NOW` | Keep the gameplay event but ship no dedicated cosmetic image or frame sequence for it. |
| `RETIRE AFTER SWITCH` | Delete exact current files and sidecars only after their replacement or absence has been applied and explicitly approved. |
| `FUTURE POLISH` | Preserve only the event-level intent in documentation; do not keep dormant production files. |

### Correct final media boundary

All independently readable actors, the shared projectile body, pickups, crates,
facilities, bulkheads, and world-state surfaces are authored PNG assets.
HUD/minimap/combat symbols, defense/status feedback, and live attack boundaries
remain code-native. EMP is the only retained large raster effect; all other
small effect-frame art is suppressed for the current pass.

The final target is exactly **49 gameplay PNGs**:

| Final family | PNGs | Required action |
| --- | ---: | --- |
| Player craft | 1 | Reuse current bytes. |
| Ordinary enemy bodies | 19 | Replace in place. |
| Stage-boss bodies | 5 | Replace in place. |
| Shared boss-node states | 3 | Replace ten boss-specific module variants with `active`, `damaged`, and `resolved`. |
| Secondary-weapon bodies | 4 | Replace in place. |
| Shared projectile | 1 | Consolidate all nine identities into one tailless energy-teardrop master. |
| Defense and persistent status | 0 | Preserve gameplay through existing code-native ring, tint, state, and text feedback. |
| Pickups and reward crate | 4 | Consolidate three XP sizes to one master; keep crate, repair, and recall distinct. |
| World and functional facilities | 11 | Keep functional states as PNGs, consolidate repair pad/core, and add required states. |
| EMP | 1 | Add one transparent 512 x 512 authored pulse image. |
| HUD/minimap/combat cues | 0 | Use shared code-native symbols or verified absence. |
| Other small effects | 0 | Suppress now; document future event-level polish only. |
| **Total** | **49** | |

Exact reconciliation:

```text
215 current PNGs
- 43 HUD/minimap/combat-cue PNGs
- 101 current effect-frame PNGs, including the six old EMP frames
- 10 boss-specific module PNGs
- 3 old XP-size PNGs
- 1 repair-pad-core PNG
- 2 unused world PNGs
- 9 old projectile PNGs
- 7 defense/status overlay PNGs
- 1 old overdrive-lane PNG
+ 3 shared boss-node state PNGs
+ 1 shared XP-master PNG
+ 1 bulkhead-open PNG
+ 3 Wear Collapse Tile PNGs
+ 1 EMP PNG
+ 1 shared energy-teardrop PNG
+ 1 circular overdrive-pad PNG
= 49 final PNGs
```

Current-file disposition is also exact:

- **Reuse unchanged: 2** — player craft and solid cover.
- **Replace in place: 36** — 19 enemies, five bosses, four secondaries, three
  non-XP pickups, two current bulkhead states, repair pad, Arc Surge, and transit.
- **Retire after approved switches: 177** — 43 HUD/cues, 101 effect frames, ten
  boss modules, three XP variants, nine projectiles, seven defense/status overlays,
  repair-pad core, old overdrive lane, and two unused world files.
- **Add: 11** — three boss nodes, XP master, bulkhead open, three wear tiles, one
  EMP image, one shared energy-teardrop projectile, and one circular overdrive
  pad that replaces the retired lane path.

The result requires **47 newly authored or adapted PNG outputs** plus two reused
outputs. It does not require 200 independent redesigns.

### Complete static-family classification

#### Actors: 35 current PNGs

| Current family | Count | Disposition | Target |
| --- | ---: | --- | --- |
| Player craft | 1 | `REUSE EXISTING` | Keep the approved one-body craft. |
| Ordinary enemies | 19 | `REPLACE PNG` | Preserve every role/path; simplify to one dominant silhouette, at most two functional modules, and 3-5 large planes. |
| Stage bosses | 5 | `REPLACE PNG` | Preserve every boss identity/path; use 4-6 large planes without nested outlines or greeble. |
| Boss-specific modules | 10 | `RETIRE AFTER SWITCH` | Replace with three shared boss-node state PNGs while gameplay retains module kind/index. |

#### Weapons: 13 current PNGs

| Current family | Count | Disposition | Target |
| --- | ---: | --- | --- |
| Seeker, escort drone, orbit blade, wake mine | 4 | `REPLACE PNG` | Keep four motion-role silhouettes as complete bodies. |
| Player and hostile projectile identities | 9 | `SHARE MASTER PNG` then retire old files | One right-facing energy-teardrop master with an opaque collision core and no tail; runtime owns rotation, scale, and faction/affinity tint. |

#### Defense and status: 7 current PNGs

| Current family | Count | Disposition | Target |
| --- | ---: | --- | --- |
| Barrier plate, ion emitter, generator shield source, escort shield plate | 4 | `RETIRE AFTER SWITCH` | Preserve protection through existing code-native support ring and actor tint; no separate emitter or plate art. |
| Burn, poison, chill | 3 | `RETIRE AFTER SWITCH` | Preserve status gameplay, stacks, damage, slow, tint, and localized status text; no orbit icon or raster overlay. |

#### Pickups: 6 current PNGs

| Current family | Count | Disposition | Target |
| --- | ---: | --- | --- |
| XP small/medium/large | 3 | `SHARE MASTER PNG` then retire old files | Add one authored XP master; gameplay value selects scale/emphasis. |
| Reward crate, repair pickup, experience recall | 3 | `REPLACE PNG` | Keep each distinct because collection meaning and silhouette differ. |

#### World and facilities: 10 current PNGs

| Current identity | Disposition | Target |
| --- | --- | --- |
| Bulkhead intact/damaged | `REPLACE PNG` | Keep both paths and add authored `open`. |
| Repair pad + repair-pad core | `SHARE MASTER PNG` | One complete repair-pad PNG owns its inset/core. |
| Overdrive lane | `RETIRE AFTER SWITCH` then `ADD PNG` | Replace the lane path with one circular overdrive-pad PNG; live radius remains code-owned and visibly aligned. |
| Arc Surge strip, transit gate | `REPLACE PNG` | Complete authored facility images; live footprint/radius remains code-owned and visibly aligned. |
| Solid cover | `REUSE EXISTING` | Keep current independent-cover silhouette. |
| Breakable cover slab, hazard power relay | `RETIRE AFTER SWITCH` | No live consumer; do not preserve dormant production art. |

Add `wear_tile_intact`, `wear_tile_cracked`, and `wear_tile_collapsed` as three
authored 240 x 160 state PNGs.

#### HUD, minimap, upgrade, action, and combat cues: 43 current PNGs

All 43 leave the raster pack after their exact consumers are migrated or proven
absent. They become shared code-native glyphs/markers/cues or deliberate absence.
This boundary does not include the shared projectile, pickups, world facilities,
or EMP. Defense/status overlays are deliberately included in code-native or
verified-absence handling because they are presentation feedback, not world bodies.

### Effect classification: one authored EMP, 21 suppressed small effects

The 22 current event identities account for all 101 frame PNGs. All old frame
files retire. EMP receives one new authored PNG; the other 21 events use existing
direct gameplay feedback or are visually suppressed for now.

| Event identity | Current frames | Current-pass result | Future-polish note |
| --- | ---: | --- | --- |
| `emp_release` | 6 | Add one 512 x 512 authored PNG; scale/fade to live radius. | Keep one strong ring/pulse; no sprite sequence. |
| `muzzle_player_primary` | 4 | Suppress cosmetic frames; projectile spawn preserves direction. | Optional short hard flash only if aim ownership is unclear. |
| `dash_start` | 3 | Use existing hull afterimage/rear flare only. | No radial ring. |
| `wake_mine_detonation` | 5 | Use mine boundary/removal and damage feedback. | Revisit only after pressure testing. |
| `boss_module_disabled` | 4 | Use boss-node state swap. | Optional rail-break motion later. |
| `hostile_summon_arrival` | 6 | Suppress frame art; keep authored encounter timing. | Add a dedicated telegraph only if fairness evidence fails. |
| `bulkhead_destroy` | 5 | Use intact/damaged/open swap and reward reveal. | Optional brief structural breakup later. |
| `reflect_deflection` | 5 | Use trajectory change and direct hit feedback. | Optional one-frame directional spark later. |
| `barrier_contact` | 5 | Use barrier PNG and localized direct response. | No five-frame contact pack. |
| `hull_hit` | 4 | Use hull hit tint/flash. | Optional directional notch later. |
| `seeker_impact` | 4 | Use projectile removal and target hit feedback. | Shared minimal impact only if needed. |
| `escort_drone_impact` | 4 | Same direct feedback rule. | Shared minimal impact only if needed. |
| `orbit_blade_impact` | 4 | Same direct feedback rule. | Align later polish to blade travel. |
| `enemy_destroy_light` | 5 | Use body removal/reward transition. | Optional shared mass collapse later. |
| `enemy_destroy_heavy` | 6 | Use body removal/reward transition. | Optional heavier shared collapse later. |
| `crate_destroy` | 5 | Use crate removal and reward spawn. | Optional latch/open snap later. |
| `pickup_intake` | 4 | Use pickup removal and immediate UI/value change. | Optional travel tick later. |
| `support_heal` | 4 | Use live support footprint and hull-meter change. | Optional inward support tick later. |
| `lifesteal_pulse` | 4 | Use existing directed transfer and hull gain. | No ambient orbit. |
| `transit_shift` | 5 | Use gate footprint, dwell, and position transition. | Optional one-way stretch later. |
| `boss_reduced_hit` | 4 | Use boss guard/tint and state UI. | Optional shared armored deflection later. |
| `impact_damage` | 5 | Use target hit tint and damage feedback. | Shared minimal impact only if readability fails. |
| **Total** | **101** | One new EMP PNG; no other effect images. | No dormant frame backlog. |

### External-source history and intake result

No external gameplay pack had been evaluated or imported before this audit. Four
official CC0 Kenney archives were inspected locally; two contributed six curated
source PNGs, while Particle Pack and Sci-Fi RTS were rejected in full.

| Pack | Archive SHA-256 | Result |
| --- | --- | --- |
| Kenney Space Shooter Remastered | `0edbe0ab5cda6c44901d8c42f150268fdfa0c8d48492098669f37e9c296929b5` | Three 2D silhouette sources retained for projectile, XP, and crate adaptation. |
| Kenney Space Kit | `d5d7cdf2635ed5a43a9187deaf409b6f47484e402321128341d3c3698e9ef4d9` | Three side-render sources retained for bulkhead and facility adaptation. |
| Kenney Particle Pack | `b631d4b07f7002549fdcf155f01141ad482f79f3440e4e301eed49ce5f1d8958` | Rejected: soft glow, blur, swirl, and generic particle language conflict with the hard-edged EMP contract. |
| Kenney Sci-Fi RTS | `093cb6adbd5aa3ae49da1c91ca3045251656df254c11903b3bfa8594a7a160ea` | Rejected: isometric/pixel treatment and theme-specific vegetation/terrain do not fit the top-down general-SF target. |

The six retained files are source material, not runtime-ready assets. Every one
must be redrawn or re-rendered into the exact Cardborne canvas, pivot, camera,
palette, outline, and detail contract. The contact sheet and exact file hashes are
recorded in [`external-candidates/README.md`](./external-candidates/README.md).

Quaternius Ultimate Space Kit, Quaternius Sci-Fi Essentials Kit, and KayKit Space
Base Bits remain optional future 3D silhouette sources. They were not imported
because the current pass can proceed with the six curated PNG references and
project-authored shapes; importing entire 3D packs would add noise rather than a
direct production deliverable.

The EMP review candidate is project-generated, not derived from Particle Pack.
It remains review-only until it is compared at actual gameplay scale and copied
to the exact TO-BE target with a recorded hash.

### Required migrations before any retirement

- Workbench units must partition all 215 current PNGs exactly once and forecast
  the 49-PNG target without fake paths for code-native HUD/cue or defense/status identities.
- Runtime, guidebook, preview, report, manifest, provider, and validators must
  resolve every retained world-object identity to its authored PNG.
- XP values must share one authored master without merging reward crate, repair,
  or recall semantics.
- Repair-pad core must be absorbed into the one repair-pad PNG without changing
  live repair radius or behavior.
- Old EMP frames must stop resolving before the new one-image EMP path becomes
  authoritative. The gameplay timer/radius remains the source of truth.
- Every small effect event must be explicitly mapped to existing direct feedback,
  `suppressed`, or a documented future-polish note.
- Deletion occurs only after actual-scale evidence and an exact approval report
  listing every PNG and `.png.import` sidecar.

## Recommendations

- Rebuild Phase 6 around the authored world-object boundary, not around what can
  technically be drawn with code.
- Use the six curated CC0 PNGs only as silhouette seeds. Never copy their palette,
  shading, isometric camera, or pack branding into production.
- Produce and review assets by coherent families: projectiles, defense/status,
  pickups/rewards, facilities/world states, EMP, secondaries/wear tiles, ordinary
  enemies, then bosses/shared nodes.
- Keep HUD/minimap/combat symbols as the sole raster-to-code-native migration.
- Run cheap deterministic/schema/import checks after each family, but run the one
  full native/Web visual, workflow, performance, and release validation only
  after every approved visual switch is complete.

## Limitations

- This audit does not switch runtime assets, edit the gameplay manifest, or
  authorize deletion.
- External source suitability was judged as adaptation material, not as proof of
  final in-game appearance.
- The current EMP candidate is a visual proposal and has not passed gameplay-scale
  review or exact switch approval.
- Counts must be re-audited if production files, the manifest, or live consumers
  change after the recorded baseline.
- Earlier Phase approvals do not authorize the corrected 177-file retirement set.
