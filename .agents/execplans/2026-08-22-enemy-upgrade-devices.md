---
type: plan
status: active
created: 2026-08-22
updated: 2026-08-22
---

# Enemy Upgrade Devices

## Goal

Add the smallest reliable map-movement incentive to the vehicle run: a visible enemy upgrade device appears at distant run-level sockets, three nearby mobile enemies attempt to activate it, and the player can travel to destroy it first.

## Scope

- Disable all neutral-facility gameplay publication without deleting the retired implementation.
- Reuse the existing six mystery-device layout sockets across the run.
- Publish only one enemy upgrade device at a time, selecting the unresolved socket farthest from the player.
- Assign the three nearest eligible mobile ordinary enemies to the active device.
- Activate after all three remain inside the capture radius for five uninterrupted seconds.
- Each activation adds flat bonuses to enemies spawned afterward: +30 health, +12% ordinary pack-owned attack damage, and +3 movement speed.
- Exclude the boss actor. Do not retrofit bonuses onto enemies that already exist.
- Let player direct, projectile, and area damage destroy the device. Hostile damage is ignored.
- Scale device health by 12% per stage index from the existing 360-health baseline.
- Publish the next unresolved device after a nine-second gap.
- Preserve experience-recall replenishment at the independent canonical threshold of 90 active-run seconds and the 30-second retry interval.

## Implementation

- [x] Add `VehicleEnemyUpgradeDeviceRuntime` as a subtype of the retired facility runtime.
- [x] Preserve the retired neutral-facility runtime and switch the run scene to a thin feature subtype.
- [x] Preserve device progress and enemy bonuses across stage transitions; reset them only for a new run.
- [x] Route assigned enemies toward the active device and temporarily prioritize that task over ordinary combat and collective tactics.
- [x] Apply future-enemy health, damage-multiplier, and speed bonuses during materialization.
- [x] Apply the future-enemy attack upgrade through the existing ordinary pack-damage multiplier.
- [x] Reuse the authored weakpoint facility symbol at 70% of the previous world size and keep the existing minimap marker contract.
- [x] Suppress the retired neutral-facility guidebook discovery in the feature run subtype.
- [x] Add English and Korean activation/destruction notifications.
- [x] Add a headless runtime validator.

## Constraints and Known Limitations

- This slice deliberately reuses an existing authored symbol. It does not establish a new approved visual asset or guidebook entry.
- Assigned enemies use direct objective steering plus the existing local collision recovery. A dedicated route field is outside this minimal slice; heavily occluded sockets may need later pathing work.
- The 12% attack increase follows the existing ordinary pack-damage path. Deliberate attack paths that bypass that multiplier remain unchanged.
- Assigned enemies prioritize movement/channeling and do not perform ordinary attacks until released from the objective.
- Device activation strengthens only enemies spawned afterward. Existing enemies and the boss actor are unchanged.
- The six existing run-level sockets bound the maximum to six activations per run.
- No economy, collection inventory, transport step, or territory layer is introduced.

## Validation

Run:

```powershell
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_enemy_upgrade_devices.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_active_run_clock.gd
./tools/godot.ps1 --headless --path . --quit-after 5
```

Manual checks:

1. No retired neutral facility appears or applies an area effect.
2. One smaller hostile device appears on the minimap at a distant socket.
3. Three mobile ordinary enemies leave normal combat and approach it.
4. Five uninterrupted seconds with all three nearby activates the device.
5. Only subsequently spawned ordinary enemies receive the accumulated bonuses.
6. Player attacks destroy the device; hostile attacks do not.
7. A new device appears at another unresolved socket after the delay.
8. Recall pickups begin replenishing after 90 active-run seconds and retry every 30 seconds when below the low-water mark.

## Canonical Default Continuation

The user accepted enemy upgrade devices as the canonical field-device system. The
neutral-facility runtime and approved assets remain in the repository as retired,
non-published fallback material; they are not deleted or reused as the production
identity of the hostile device.

Locked decisions:

- Keep `VehicleRunEnemyUpgradeDevices` as the default run scene layer.
- Restore recall replenishment to the independent canonical `90s` initial / `30s`
  retry policy; the branch's `45s/15s` experiment is not part of this feature.
- Give every cycle the late-cycle live-density contract: materialized cap `72` and
  reserve-backed refill floor `56`.
- Preserve early tiers, threat budgets, ranged/denial commit caps, defeat quotas,
  and authored reserve totals so higher density does not import late-cycle damage
  pressure into early play.
- Preserve Stage 1 teaching compositions and their original `0/15/30/45/60` tutorial
  gates. The shared `72/56` capacity contract applies without bypassing those lessons.
- Create three transparent PNG candidates for a new hostile device identity. Keep
  them review-only until the user selects an exact candidate; do not promote a
  candidate to the production manifest in this phase.

## Continuation Tasks

- [x] **C1 — Canonical gameplay and density**
  - Change the encounter pressure owner and Stage 1 admission gates.
  - Restore recall replenishment to `90s/30s`.
  - Accept when focused encounter, composition, recall, and device validators pass.
- [x] **C2 — Canonical product and visual contracts**
  - Replace active neutral-facility requirements with enemy upgrade-device rules.
  - Preserve retired implementation and asset history explicitly.
  - Accept when doc and visual-authority validation pass.
- [x] **C3 — Review-only PNG candidates**
  - Generate three distinct transparent candidates with the canonical sheet supplied
    through ImageGen's image-reference input.
  - Record prompts, hashes, authority evidence, and pending approval status in the
    visual-replacement workbench.
  - Accept when every candidate is readable at intended size and remains outside the
    production manifest.
- [x] **C4 — Integration and release gates**
  - Run the focused validators, one production Web export, and the applicable bounded
    workload check after the implementation is coherent.
  - Accept only exact partial-pass labels; do not claim release performance without
    an eligible clean native/Web performance scenario.

## Progress and Next Steps

- Canonical progress: the continuation task checkboxes above.
- Current phase: follow-up integration and validation.
- Next task: validate the selected production visual, projectile contact, objective
  routing, and restored tutorial gates.
- Completed gates: device, encounter pacing, spawn composition, guidebook,
  bilingual localization, active-run clock, full Run, and visual-authority validators;
  Godot import; four-file production Web export; `git diff --check`; and the bounded
  headless pressure sample.
- Bounded pressure result: `active_capped=72`, `cap=72`, `shards=192`,
  `queued=1`, `steps=300`. This excludes rendering and complete frame orchestration
  and is not a release-performance pass.
- Quality post-pass corrected stale guidebook ownership, boss-summon upgrade leakage,
  unrelated seeker-impact reuse, device bobbing, incomplete diagnostic snapshots,
  and stale general-run/pressure-harness assumptions. No further task-owned
  responsibility or failure-path issue remains.
- The broad visual-replacement-workbench validator still reports 30 pre-existing
  unassigned trait-family production PNGs. `replacement-workbench.json` is unchanged
  from `master`, and none of the three review-only device candidates appears in that
  failure. This is unrelated baseline inventory debt and was not expanded into this task.
- Update rule: record each checkpoint result here before moving to the next task.

## Review-only Candidate Evidence

- Candidate root: `docs/design/visual-replacement-workbench/previews/enemy-upgrade-device-candidates-2026-08-22/`
- Actual reference input: `image_gen.referenced_image_paths`
- Canonical reference: `docs/design/cardborne-universal-art-style-reference.png`
- Reference SHA-256: `96CCF5D053E66DD3A102CCDF39DAEFD0B0C54B0E88D20428B7BA1C894F002889`
- Common prompt contract: isolated orthographic top-down hostile installation;
  three broad docking approaches, dark perimeter, danger-coral main plane,
  restrained cool-neutral support plane, warm-off-white core, `3–5` broad filled
  planes, small-scale readability, and no text, badge, rings, repeated lamps,
  greeble, glow, perspective, or retired facility-role symbols.
- `candidate-a-triad-forge.png`: symmetric three-arm forge silhouette;
  SHA-256 `F4229F8EEE2CDED317C1A1198B3EEAFD3885E15EBE7C97E1C4A116F80C8B38D0`.
- `candidate-b-split-anvil.png`: asymmetric heavy split-anvil silhouette;
  SHA-256 `49E7D9EBAEBDBC5FC90F1C5CA0C653797BC72FCF65A8C99B698714B79850432B`.
- `candidate-c-vector-clamp.png`: compact swept triangular clamp silhouette;
  SHA-256 `034CE4CA80FDCAFB78A67E09BDE98BC1B9E0E5F07401E01792C9D537D688410C`.
- The generator returned opaque checkerboard-backed PNGs. A non-creative
  ImageMagick edge-connected alpha cleanup removed only the background; all
  three retained files were non-creatively resized to `512×512` and report
  `srgba`, `opaque=False`, and transparent corner/background samples.
- Approval state: BK selected `candidate-a-triad-forge.png` on 2026-08-22. The exact
  approved bytes (SHA-256
  `F4229F8EEE2CDED317C1A1198B3EEAFD3885E15EBE7C97E1C4A116F80C8B38D0`) are published
  as `art/visuals/production/gameplay/world/enemy_upgrade_device.png`; no resize,
  repaint, or other byte-changing adaptation was applied.

## Follow-up Corrections

- [x] Restore the Stage 1 tutorial defeat gates while retaining `72/56` density.
- [x] Stop player-primary rounds at the device and retain hostile pass-through.
- [x] Strengthen the body-wide hit flash against the device's coral idle body.
- [x] Give assigned enemies a shared wall-aware route to the active device and exempt
  their objective motion from player-pursuit correction.
- [x] Promote the exact user-selected Triad Forge PNG to runtime and Guidebook use.
- [ ] Run focused gameplay, presentation, asset, and visual-authority validation.
