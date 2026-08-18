---
type: evidence
status: archived
owner: BK
created: 2026-08-14
last_reviewed: 2026-08-14
topic: Anomaly Device outcome silhouette references and review candidates
scope: Rejected Gravity Pull, Cryo Lock, and Decoy Signal raster candidates retained for comparison history
source: User rejection of mystery-device-outcomes-v2-simple for weak functional distinction on 2026-08-14
related:
  - ../../../VISUAL_SYSTEM.md
  - ../../../cardborne-universal-art-style-reference.png
  - ../../replacement-workbench.json
  - ../mystery-device-outcomes-v2-simple/candidate-evidence.md
  - ../../../../product/vehicle_game_spec.md
---

# Semantic Anomaly Device Candidate Evidence

This set was archived on 2026-08-14 after the user replaced Decoy Signal with
Weakpoint Expose. It is not a current approval candidate. The active replacement
evidence is `../mystery-device-outcomes-v4-symbols/candidate-evidence.md`.

## Purpose

Retain the external reference synthesis, visual-authority evidence, and third
review set for three Anomaly Device outcomes. The set uses three opposing shape
verbs so function remains legible without color: converge, lock, and lure.

## Sources

### Canonical and production references

- `docs/design/VISUAL_SYSTEM.md`, read completely before research and generation.
- `docs/design/cardborne-universal-art-style-reference.png`, inspected at
  original detail and supplied to every generation or edit. Its observed and
  required SHA-256 is
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- Current production simplicity references supplied directly to ImageGen:
  `facility_repair_pad.png`, `facility_transit_gate.png`,
  `mystery_device_intact.png`, and `actor_enemy_ordinary_fixed_support_01_base.png`.

### External reference families

| Outcome | Reference | Observed mechanism | Transferred abstraction | Copying boundary |
| --- | --- | --- | --- | --- |
| Gravity Pull | [NASA black-hole accretion visualization](https://www.nasa.gov/image-article/accretion-disk-of-black-hole-glows-new-simulation/) | Matter visibly converges on a dominant dark center. | Preserve central negative space and make every large mass terminate toward it. | Do not reproduce the accretion disk, lensing, color, or composition. |
| Gravity Pull | [Warframe Vauban](https://www.warframe.com/en/game/warframes/vauban) | A deployed device collapses containment into a vortex that draws enemies inward. | The device must read as a sink, not merely as a circular field. | Do not reproduce Vauban, the deployed orb, or ability effects. |
| Cryo Lock | [ISO 7010 W010](https://www.iso.org/obp/ui?_escaped_fragment_=iso%3Agrs%3A7010%3AW010) | A snowflake is the registered image content for low temperature or freezing conditions. | Make the complete outer body a broad six-arm snowflake instead of placing a small icon on a box. | Do not copy the ISO sign, triangle, proportions, or safety colors. |
| Cryo Lock | [Overwatch Mei](https://overwatch.blizzard.com/en-us/heroes/mei/) | Blizzard freezes enemies across a wide area. | Pair the cold silhouette with the existing exact-area field and frozen actor state. | Do not reproduce Mei's drone, ice wall, or ability artwork. |
| Cryo Lock | [OSHA lockout/tagout](https://www.osha.gov/control-hazardous-energy) | Lockout prevents unexpected movement or energy release. | Use rigid, evenly spaced arms that visually block motion rather than fluid or rotating parts. | Do not reuse OSHA labels, locks, or signage. |
| Decoy Signal | [NOAA deep-sea anglerfish](https://oceanexplorer.noaa.gov/expedition-feature/19biolum-background-midnight-zone/) | A single remote light on a stalk attracts prey toward a false target. | Use one asymmetrical curved mast and one isolated bright lure. | Do not copy an animal body, teeth, fins, or natural texture. |
| Decoy Signal | [U.S. Navy Nulka decoy](https://www.navy.mil/DesktopModules/ArticleCS/Print.aspx?Article=2167877&ModuleId=724&PortalId=1) | A separate emitter redirects a threat away from the real target. | Emphasize a remote attention point and directional redirection, not inward compression. | Do not reproduce military hardware, launchers, or vessel shapes. |
| Decoy Signal | [EA Apex Mirage](https://help.ea.com/en/articles/apex-legends/abilities/) | A false target draws and confuses enemy attention. | Treat the device as an attention source rather than a damaging or pulling machine. | Do not reproduce Mirage, a humanoid duplicate, or hologram styling. |

External sources informed only the abstract functional relationship. No external
image was copied into the repository or supplied to ImageGen.

## Findings

- The current renderer gives all three effects the same filled disk and ring;
  Cryo changes color while Gravity and Decoy share system color. Radius alone is
  not a stable identity cue.
- The v2 candidates reduced detail but still used three generic compact machine
  bodies. Their internal accent carried too much of the meaning.
- The v3 candidates put the mechanic in the complete outer silhouette:
  - Gravity: four massive inward arrowheads and one empty central sink.
  - Cryo: one broad six-arm snowflake body and one frozen hexagonal core.
  - Decoy: one asymmetrical lure mast, one isolated bright orb, and a low base.
- [`comparison.png`](./comparison.png) compares rejected v2 and review-only v3
  at the same scale. [`reference-scale-comparison.png`](./reference-scale-comparison.png)
  compares v3 with real production assets. [`grayscale-comparison.png`](./grayscale-comparison.png)
  confirms that the v3 identities remain separate without semantic color.
- The candidates remain outside the gameplay manifest, semantic provider, and
  runtime. They are not approved production assets.
- The active visual specification currently keeps one unchanged Anomaly Device
  body and uses code-native full-area effects. Approving outcome-specific body
  images therefore requires a deliberate specification change; candidate
  artwork alone does not authorize that change.

## Candidate records

| Outcome | Review file | SHA-256 | Shape verb |
| --- | --- | --- | --- |
| Gravity Pull | `candidates/mystery_device_gravity.png` | `f554b64006051c863510c0209c45b85027a72721c84791b2b6e92545af4fb714` | converge inward |
| Cryo Lock | `candidates/mystery_device_cryo.png` | `d5a4f8f493d3afc368ee91d6b4398b8779309b650ed2c3fc6a59e7a4277ac3ea` | lock motion |
| Decoy Signal | `candidates/mystery_device_decoy.png` | `9b679ae28f6956cad1f427ee6d72338c19bcc4bc088f44d15410341500f9876c` | lure attention |

OpenAI ImageGen generated and then simplified the sources in built-in tool
mode. The tool did not expose a model revision. The canonical sheet was an
actual referenced image in every call. The installed chroma-key helper removed
the uniform generation background. ImageMagick performed only transparent
trim, resize, contact-sheet placement, labels, and validation; it authored no
visual geometry.

The retained source hashes are:

- Gravity chroma: `40fac6ee3e12bf94c508a2a4b5a21a90c66616a683a0600b39558433cb57630d`
- Gravity alpha: `1ab0923df5a9896ed529597634a8ebe65349110b6ade6c8645f5e4d6b2a48ea1`
- Cryo chroma: `45d8be04e074e5d3928305a2d02005d22dab70126e572cb5ccc0848c091e99fc`
- Cryo alpha: `bcc233af8191f8b5a9aabda6468ea82ade3d818267267ecda11c24b06e80a9ee`
- Decoy chroma: `3d80fd032211ce2ca59cbda875b8f6e91c2027bc3206dba6ae97b0372f6467be`
- Decoy alpha: `1680adf227c85bcb0eb4debee9380d32ce8bb2d74a5dce4cc2d717482d35dd2c`

## Recommendations

- Review the set in grayscale and at the scale in `comparison.png`, judging
  whether the three outer silhouettes communicate inward pull, frozen lock,
  and attention lure before reading the labels.
- If approved, revise the visual and product specifications so the generic
  intact body hides the outcome until the first accepted hit, then switches to
  the outcome-specific revealed body. Keep the exact full-area effect for range
  truth and retire the body when its effect ends.
- Preserve Decoy as target-facing and aim redirection. Do not animate enemies as
  if a second Gravity Pull were moving them into the center.

## Limitations

- This pass verifies semantic silhouette separation, not live battlefield
  contrast or comprehension by external players.
- ISO notes that snowflake comprehension may need supporting text. Cardborne's
  existing first-hit localized reveal supplies that support.
- Runtime integration, specification edits, manifest changes, and production
  replacement are intentionally deferred until explicit approval.
