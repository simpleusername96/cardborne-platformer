---
type: evidence
status: active
owner: BK
created: 2026-08-14
last_reviewed: 2026-08-14
scope: Review-only Gravity, Cryo, and Decoy Mystery Device raster candidates awaiting explicit user approval
related:
  - ../../../VISUAL_SYSTEM.md
  - ../../../cardborne-universal-art-style-reference.png
  - ../../replacement-workbench.json
  - ../../../../product/vehicle_game_spec.md
  - ../../../../../.agents/execplans/2026-08-13-evidence-category-slots-and-scalable-swarm.md
---

# Mystery Device Outcome Candidate Evidence

## Status

These files are review candidates only. They are not production assets, are not
listed in the gameplay manifest, and must not be promoted until the user
explicitly approves the three-image set.

[`comparison.png`](./comparison.png) is the mechanical AS-IS/TO-BE contact
sheet. It places the current generic resolved device beside the three proposed
outcome states without changing the authored images.

## Visual authority evidence

- Specification read completely:
  `docs/design/VISUAL_SYSTEM.md`
- Canonical sheet inspected at original detail:
  `docs/design/cardborne-universal-art-style-reference.png`
- Canonical sheet SHA-256:
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`
- Actual image references supplied to ImageGen: the canonical sheet and the
  current production `mystery_device_resolved.png`.
- Reference input method: `image_gen.referenced_image_paths`.
- Generation date: 2026-08-14.
- Tool: OpenAI ImageGen. The tool did not expose a model revision, so none is
  guessed here.

## Retained generation brief

All three prompts requested a transparent, orthographic top-down science-fiction
device state that remains readable at small gameplay scale, follows Cardborne's
charcoal metal and restrained accent language, avoids text and logos, and uses
the current device as a family reference rather than copying its generic center.

- Gravity: a dark inward well, converging angular vanes, and a restrained violet
  energy accent. The silhouette must communicate inward pull without hue alone.
- Cryo: a fractured cold chamber held by opposing clamps, using pale cyan only
  as a secondary cue. The mechanism must communicate locking/freezing without
  relying on color alone.
- Decoy: a central signal beacon with directional fins and sparse cyan emitters.
  The mechanism must communicate broadcast/misdirection without text or a
  screen-like UI symbol.

ImageGen source outputs used a removable green background. The project image
helper converted that background to alpha. ImageMagick then performed only
mechanical resize and contact-sheet placement; it did not author geometry.

## Candidate records

| Outcome | Review file | SHA-256 | Proposed semantic ID | Proposed production target |
| --- | --- | --- | --- | --- |
| Gravity Pull | `candidates/mystery_device_gravity.png` | `782339cf5703fe3860d003ef24e8f0797a2e348d58824c4c10a85df507641d93` | `world/mystery_device_gravity` | `art/visuals/production/gameplay/world/mystery_device_gravity.png` |
| Cryo Lock | `candidates/mystery_device_cryo.png` | `98e81923c2eff24b5b45a25087bea318e32a2b9c8204154c55d0878e8959ed0d` | `world/mystery_device_cryo` | `art/visuals/production/gameplay/world/mystery_device_cryo.png` |
| Decoy Signal | `candidates/mystery_device_decoy.png` | `7272c55eba1ba34c19565f1f832592abcc6d1a7d25dbf4517b7c24e36e93626e` | `world/mystery_device_decoy` | `art/visuals/production/gameplay/world/mystery_device_decoy.png` |

The retained 1024-pixel intermediates and original ImageGen sources stay in the
same review folder. Their hashes are:

- Gravity 1024: `eba8a8ce0b304971dd9d20a68d3aa35f438ce35437f6a03b8cacb03bf9c7ef19`
- Cryo 1024: `88c992c1a12cc1dd8d7b3ecfb8b654108b43cbe38c124075ffa69b1909095abe`
- Decoy 1024: `14d8613a1e9fc94ad254e04a882595bc27c902b88539e82bb06cd62e4a0c8460`
- Gravity source: `1bf5faeb0aa60312c42c5cfc5c50e57eeb27c21df6cf66c760e486a0724882bb`
- Cryo source: `675a82630a221d02996ea630b19934a317be065a0d60ee29ded088c0ed049e71`
- Decoy source: `266eceba64ff73aa87d577ef242029b49a8ecdf654bae2e3164eee0af4e61ca6`

## Proposed switch

The runtime keeps the current intact device hidden. After first accepted damage,
the renderer routes the revealed/resolved state to one of the three approved
semantic assets. Only after all consumers have switched may the generic
`world/mystery_device_resolved` asset and its production file be retired.

Approval must cover the set, not one isolated image, because gameplay requires
the three outcomes to be distinguishable by mechanism at the same camera scale.
