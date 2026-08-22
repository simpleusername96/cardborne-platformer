---
type: plan
status: completed
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
- Double experience-recall replenishment frequency by changing the initial threshold from 90 to 45 active-run seconds and the retry interval from 30 to 15 seconds.

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
8. Recall pickups replenish at twice the previous cadence when below the low-water mark.
