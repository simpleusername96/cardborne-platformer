---
type: evidence
status: archived
owner: BK
created: 2026-07-23
last_reviewed: 2026-07-23
scope: Current vehicle-run frame architecture, scalability limits, profiler validity, and Godot 4.7 performance practices
related:
  - ./PLANS.md
  - ./execplans/2026-07-23-single-field-campaign-secondaries-guidebook.md
  - ./execplans/2026-07-23-vehicle-performance-architecture-stabilization.md
  - ./vehicle-performance-stabilization-evidence.md
  - ../docs/product/vehicle_game_spec.md
---

# Vehicle Runtime Performance Architecture Audit

## Outcome

This is the archived pre-change baseline that justified the stabilization work.
Its observations describe commit `aa2d9eb` and earlier, not the current runtime.
The implemented architecture, measurements, validation results, and remaining
acceptance limits are recorded in
`vehicle-performance-stabilization-evidence.md`.

## Purpose

This evidence report answered one historical question: **did the implementation
before the 2026-07-23 stabilization provide a credible basis for smooth play
after ordinary additions such as more enemies, projectiles, upgrades, statuses,
and boss patterns?**

The answer at that baseline was **no**. Recent changes had improved several isolated loops and bounded
the active enemy count, but the runtime still scales with cumulative dead
enemies, repeatedly performs projectile-by-enemy searches, rebuilds complex
dynamic drawing commands every rendered frame, and validates itself with a
headless microbenchmark that excludes the loads the player actually sees.

This is not a claim that Godot, GDScript, flat-color graphics, or the laptop is
inherently unable to run the intended game. The current game has no runtime SVG
or PNG combat atlas and no 3D scene load. Its pressure is generated mainly by
GDScript-side container access, search complexity, transient allocations, and
CanvasItem command reconstruction. The selected correction is therefore a
bounded, data-oriented GDScript simulation with spatial queries, live-only
entity storage, retained batched presentation, event-driven HUD updates, and
end-to-end native and Web frame gates.

No gameplay or runtime code was changed while this baseline audit was produced.

## Questions Answered

1. Is the reported lag plausible despite the simple flat visual style?
   - Yes. Visual asset complexity is not the dominant complexity in the current
     implementation.
2. Did the current `≤8 ms` pressure check establish smooth gameplay?
   - No. It does not run the real frame, render, audio, combat projectile load,
     boss load, or cumulative-death state.
3. Will small content increases remain cheap under the current architecture?
   - No. Several normal content changes increase work multiplicatively or
     increase an array that is never compacted during a stage.
4. Is a language or engine rewrite required?
   - No. The verified scale is modest enough for Godot 4.7 and GDScript after
     the algorithm, lifecycle, and presentation paths are corrected.
5. What architecture is selected?
   - A hybrid data-oriented GDScript runtime with a bounded live actor store, a
     uniform spatial grid, a packed projectile buffer, staggered ordinary AI,
     prebuilt flat-color meshes rendered in batches, event-driven UI snapshots,
     and repeatable rendered performance scenarios.

## Sources

### Repository and Runtime Sources

| Source | Observed fact | Confidence |
| --- | --- | --- |
| `project.godot` | Godot 4.7, `gl_compatibility`, a logical `1280×720` viewport, and `canvas_items` stretch are configured. | Direct |
| `scenes/run/VehicleRun.tscn` | The run scene contains one scripted `Node2D`; almost all runtime objects are data and custom draw commands, not individual 3D or sprite nodes. | Direct |
| `scripts/vehicle/vehicle_run.gd` | The 3,909-line owner runs player, enemy, projectile, reward, effect, stage, camera, draw, capture, and HUD-snapshot behavior. | Direct |
| `scripts/vehicle/vehicle_run.gd::_physics_process()` | Every 60 Hz tick serially updates player, upgrades, pickups, XP, encounters, pursuit, enemies, radar, projectiles, zones, trails, effects, progression, and camera. | Direct |
| `scripts/vehicle/vehicle_run.gd::_process()` | Active play queues a full dynamic redraw every rendered frame and builds a full HUD snapshot every 0.05 seconds. | Direct |
| `scripts/vehicle/vehicle_run.gd::_defeat_enemy()` | Defeat marks an enemy dead and inactive but does not remove it from `enemies`. | Direct |
| `scripts/vehicle/vehicle_run.gd::_update_projectiles()` | Each player projectile can scan every enemy for interception and again for the first segment hit; homing can perform another full ID scan. | Direct |
| `scripts/player/vehicle_secondary_runtime.gd` | Ion, orbit, mine, and drone behavior each iterate the supplied complete enemy array; orbit is blades × enemies. | Direct |
| `scripts/progression/vehicle_experience_runtime.gd` | Up to 192 dictionary shards are updated at 60 Hz; overflow merging scans all shards for the nearest one. | Direct |
| `scripts/ui/vehicle_stage_ui.gd` | HUD updates redraw health/action slots/minimap/radar and deep-copy the guidebook snapshot at 20 Hz. | Direct |
| `scripts/vehicle/vehicle_stage_backdrop.gd` | Authored field geometry is already isolated in a cached, non-processing CanvasItem. | Direct |
| `scripts/presentation/vehicle_audio_director.gd` | Audio uses six general voices, two impact voices, and one held-fire loop instead of creating a player per sound. | Direct |
| `scripts/encounters/vehicle_encounter_director.gd` | Current caps are 72 active mobile enemies, 240 player projectiles, 120 hostile projectiles, and 96 effects. | Direct |
| `scripts/vehicle/stages/vehicle_combat_stages.gd` | Stage quotas are `96/128/160/192/224`, and Stage 5 authors up to 420 mobile enemies. | Direct |
| `tools/validation/profile_vehicle_pressure.gd` | The current pressure script disables real process callbacks, prevents enemy attacks, creates no saturated projectile load, performs no rendered frame, and reports an average of selected method calls. | Direct |
| Recent commits `c5b0880`, `b763fa5`, `4bef999`, `1e7759f` | Local loop improvements were followed by larger active pressure, more boss work, and doubled quotas without replacing lifecycle, collision broadphase, or rendered validation. | Direct |

### Local Audit Environment

Observed on 2026-07-23:

| Concern | Value |
| --- | --- |
| Godot | `4.7.stable.official.5b4e0cb0f` |
| CPU | Intel Core i5-1135G7, 4 cores / 8 logical processors |
| GPU | Intel Iris Xe Graphics, driver `30.0.100.9836` |
| Display | `2560×1600` |
| Memory | approximately 15.7 GiB visible |
| OS | Windows 11 Enterprise `10.0.26200` |

This is not workstation-class hardware, but it is a reasonable minimum
development target for a flat 2D action game with roughly one hundred live
actors and several hundred projectiles. The intended scale does not justify the
current severe stutter by itself.

### External Primary and First-Hand Sources

All sources were accessed on 2026-07-23.

1. [Godot 4.7 general optimization](https://docs.godotengine.org/en/stable/tutorials/performance/general_optimization.html)
   says to profile first, improve algorithms and data structures before local
   micro-optimizations, favor compact/local access, precalculate work, and
   remove nested loops when possible.
2. [Godot 4.7 CPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/cpu_optimization.html)
   explains that the built-in profiler is useful but may omit time spent
   waiting on built-in servers. A single microtimer is therefore insufficient
   for a release conclusion.
3. [Godot 4.7 data preferences](https://docs.godotengine.org/en/stable/tutorials/best_practices/data_preferences.html)
   documents that script values are Variants, Arrays store contiguous Variant
   entries, and Dictionaries are hash maps with key hashing and maintenance.
   This supports removing string-keyed dictionaries from the hottest repeated
   paths; it does not imply that every dictionary in the product is wrong.
4. [Godot 4.7 custom drawing](https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html)
   says `_draw()` commands are normally cached and only reconstructed after
   `queue_redraw()`. The current run deliberately invalidates the full dynamic
   CanvasItem every active rendered frame.
5. [Godot 4.7 CanvasItem](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html)
   recommends precalculated triangulation with `draw_mesh()`,
   `draw_multimesh()`, or a RenderingServer triangle array when the same
   polygons are frequently redrawn.
6. [Godot 4.7 debugger and Visual Profiler](https://docs.godotengine.org/en/stable/tutorials/scripting/debug/debugger_panel.html)
   separates script/physics profiling from rendering CPU/GPU profiling and
   warns that viewport resolution must remain equal across comparisons.
7. [Godot 4.7 Performance monitors](https://docs.godotengine.org/en/stable/classes/class_performance.html)
   exposes full-frame time, physics time, draw calls, rendered objects, memory,
   and custom monitors. Some values are debug-only or update slowly, so the
   selected harness records both engine monitors and direct subsystem timings.
8. [Godot 4.7 RenderingServer render timing](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html)
   exposes measured viewport CPU and GPU render time after measurement is
   explicitly enabled.
9. [Godot 4.7 optimization using Servers](https://docs.godotengine.org/en/stable/tutorials/performance/using_servers.html)
   describes lower-level RIDs as an escalation path after simpler optimization
   avenues are exhausted, especially for very large instance counts.
10. The official [Godot Bullet Shower demo](https://github.com/godotengine/godot-demo-projects/tree/master/2d/bullet_shower)
    manages 500 bullets from one script, uses one shared physics shape and
    low-level body RIDs, disables bullet-to-bullet collision, performs one
    linear motion pass, and draws one texture per bullet from one manager.
11. Godot's [thread-safe API guidance](https://docs.godotengine.org/en/stable/tutorials/performance/thread_safe_apis.html)
    states that the active SceneTree is not thread-safe. Threading the current
    monolith is not a safe first correction.
12. Godot's [physics tick and interpolation introduction](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/physics_interpolation_introduction.html)
    distinguishes fixed 60 Hz simulation from rendered frames and notes that
    missing a 60 Hz V-Sync deadline can fall visibly to 30 FPS.
13. Godot's [jitter and stutter guide](https://docs.godotengine.org/en/stable/tutorials/rendering/jitter_stutter.html)
    distinguishes timing mismatch from CPU/GPU deadline misses. Interpolation
    does not repair an overloaded frame.
14. The official [Godot demo repository](https://github.com/godotengine/godot-demo-projects)
    states that browser performance is lower than native performance. A Web
    export boot check cannot substitute for a Web frame-performance gate.
15. A first-hand Godot developer
    [polygon/polyline benchmark discussion](https://github.com/godotengine/godot-proposals/discussions/8618)
    reports large overhead differences between many individual draw calls and
    cached/batched point sets. This is supporting evidence, not an engine
    contract or a substitute for profiling this project.

## Findings

### 1. The Runtime Is Not SVG- or Texture-Bound

The user's intuition is correct: this content should not be expensive merely
because of its appearance. The exact repository inventory makes the mismatch
even stronger:

- there are no runtime `.svg` files;
- the only `.png` is the design reference under `docs/design/`;
- the UI theme uses `StyleBoxFlat` plus one Noto Sans KR font;
- the combat field, actors, projectiles, XP, effects, and telegraphs are created
  by `draw_*` calls;
- the run scene has no 3D model or 3D node graph;
- static field geometry is already cached in `VehicleStageBackdrop`.

The performance question is therefore not “can Iris Xe render these art
assets?” The relevant questions are:

1. how many GDScript entries are visited each tick;
2. how many dictionary lookups, transient arrays, sorts, and shifts occur;
3. how many CanvasItem commands and polygon point arrays are regenerated;
4. whether dead state and UI snapshots remain in hot paths; and
5. whether the shipped Web path meets a real frame budget.

### 2. The Current Frame Has One Serial Hot Path

`VehicleRun._physics_process()` runs nearly the whole product in one sequential
60 Hz callback. `VehicleRun._process()` then rebuilds the HUD at 20 Hz and
invalidates the dynamic CanvasItem on every active rendered frame.

This is not automatically slow. One centralized manager can be efficient, as
the official Bullet Shower demonstrates. The problem is that this manager also
owns:

- unbounded-within-stage historical enemy entries;
- repeated global queries;
- dictionary-heavy state;
- projectile collision;
- role-specific AI;
- AoE and secondary scans;
- full dynamic procedural presentation;
- HUD assembly and guidebook duplication;
- stage/capture/debug responsibilities.

The architecture provides no stable performance boundary. A new mechanic can
quietly add another complete enemy scan or another set of per-frame draw
commands without an owner or budget rejecting it.

### 3. Dead Enemies Remain in Every Enemy Scan

`_defeat_enemy()` sets:

```gdscript
enemy["alive"] = false
enemy["active"] = false
```

It does not remove or recycle the entry. `enemies.clear()` only occurs during
run/stage reset and capture/debug preparation.

Stage 5 requires 224 countable defeats before the boss. At boss entry, a
plausible hot array is therefore:

- approximately 224 retained dead ordinary enemies;
- up to 72 live capped mobile enemies;
- four stationary actors;
- a boss, pylons, and carrier summons.

The array can approach or exceed 300 dictionary entries even though only about
one quarter are live. Every full-array loop still reads `alive` from every dead
dictionary. This makes the cost depend on **how long the stage has progressed**,
not only on what the player can currently see or fight.

This is a direct architectural regression from the doubled quotas in
`1e7759f`: the change improves the desired boss gate, but it also approximately
doubles the historical entries retained before each later boss.

### 4. Projectile Collision Is a Multiplicative Search

For every player projectile, `_update_projectiles()` can call:

1. `_projectile_intercepted()` — scans all enemies;
2. `_first_enemy_on_segment()` — scans all enemies;
3. `_find_enemy_by_id()` — another full scan for homing projectiles;
4. an AoE full scan after some impacts.

At the configured player projectile cap of 240 and an approximately 300-entry
late-stage enemy array, only the first two searches imply:

```text
240 projectiles × 2 searches × 300 enemy entries
= 144,000 enemy-dictionary visits per physics tick
≈ 8.64 million visits per second at 60 Hz
```

This estimate excludes:

- hostile projectile work;
- homing lookups;
- crates and cover;
- enemy AI;
- shields/support;
- orbit blades, mines, drone, ion field, dash, EMP, trails, poison spread;
- drawing, UI, audio, and engine overhead.

The exact time share requires a rendered profile, but the growth law is already
known: raising both enemy history and projectile density multiplies cost.
Changing only one cap or one cooldown can temporarily mask this path but cannot
make it scale safely.

### 5. Enemy and Secondary Relationships Add More Whole-Array Work

Every physics tick, enemy processing currently includes at least:

- active-cap collection;
- committed-attack counting;
- timer and activation update;
- squad snapshot construction;
- shield candidate/support construction;
- active enemy role update.

Additional paths scan all enemies for:

- generator healing;
- repair-tender target selection and ID resolution;
- carrier living-child counts;
- rammer coordination;
- group-completion checks;
- target aim assist;
- dash collision and repulsion;
- EMP, AoE, trails, poison contagion, and target marking.

The secondary runtime adds:

- ion field: enemies per 0.25-second tick;
- orbit blades: blade count × enemies every physics tick;
- wake mines: mine detection plus mine explosion × enemies;
- escort drone: full nearest-target scan on its interval.

Several of these are logically local-radius queries. They currently pay for
every retained entry because no shared spatial-query service exists.

### 6. Dynamic Presentation Rebuilds Geometry Instead of Reusing It

Every active rendered frame, the run calls `queue_redraw()`. `_draw()` then
reissues zones, pickups, secondaries, enemies, projectiles, effects, player, aim,
and optional debug geometry.

There is useful world-rectangle culling for enemies, projectiles, and effects.
That should be preserved. However, each visible object can still create new
point arrays and multiple commands:

- enemy hulls use rotated or regular polygons plus circles/lines;
- shields and statuses use multi-segment arcs;
- telegraphs use polygons, circles, arcs, lines, and filled zones;
- each projectile uses a line plus a freshly generated diamond;
- each XP shard constructs a polygon and sometimes an inner circle;
- effects repeatedly generate expanding polygons/arcs;
- the player hull is rebuilt from local arrays.

This means “flat shapes” are not equivalent to “free rendering.” The CPU must
recreate and submit the drawing command stream. Godot's documentation explicitly
identifies prebuilt meshes or MultiMeshes as the appropriate path for frequently
redrawn polygons.

The official Bullet Shower is an important counterexample: it also calls
`queue_redraw()` every frame, but it updates a typed bullet object linearly and
submits one already-loaded texture draw per bullet. The current project combines
full redraw with substantially more command construction and collision search.

### 7. The HUD Performs Work Unrelated to What Changed

At 20 Hz, `_build_hud_snapshot()` constructs:

- health, XP, action, objective, target, and boss values;
- a minimap snapshot with floor/water/blocker polygons, visited cells, and
  markers;
- threat radar and cycle states;
- the entire guidebook catalog, current upgrades, secondary summary, and a deep
  copy in `VehicleStageUI`.

The guidebook is normally closed. Static minimap geometry normally does not
change during a stage. Objective copy changes infrequently. These should not be
rebuilt on the same fixed timer as the player's cooldown rings.

The current microbenchmark reports only about 0.17 ms for one HUD update on this
machine, so HUD assembly is not established as the primary bottleneck. It is
nevertheless allocation churn and an unsafe extension point: adding more guide
entries or map geometry makes a hidden modal more expensive during combat.

### 8. Audio and the Static Field Are Not Leading Suspects

Two subsystems already have appropriate boundaries:

- `VehicleStageBackdrop` is cached and non-processing;
- `VehicleAudioDirector` uses bounded voice pools and a dedicated loop.

They still belong in the final end-to-end measurement, but no inspected code
supports removing audio, simplifying the static field, or reducing visual
resolution as the first fix.

### 9. The Existing Pressure Profile Cannot Validate Smooth Play

The current profiler returned on this machine:

```text
standard moving=4.402 ms hud=0.168 ms scheduler=0.023 ms combined=4.593 ms
onslaught moving=4.600 ms hud=0.173 ms scheduler=0.021 ms combined=4.794 ms
```

Those numbers are real for the methods the script invokes, but the conclusion
`within_8ms=true` is not a gameplay-performance result. The script:

- disables `_process()` and `_physics_process()`;
- invokes only `_update_enemies()`, `_update_projectiles()`, and
  `_update_experience()` manually;
- creates only `active_cap + 12` enemies, then caps them at 72;
- does not create the 224 retained dead entries expected before the Stage 5
  boss;
- sets `attack_cooldown = 999`, suppressing enemy attacks;
- does not saturate 240 player and 120 hostile projectiles;
- excludes zones, trails, effects, player, camera, boss logic, audio, stage
  progression, and actual input;
- calls `update_hud()` but does not measure the queued Control drawing;
- runs headless and therefore measures no CanvasItem rendering or GPU work;
- averages 300 calls and reports no median, p95, p99, spike sequence, memory
  slope, draw calls, or resolution-specific result.

The test is useful as a narrow CPU regression microbenchmark. It must not remain
the release performance gate.

### 10. Recent Fixes Were Useful but Did Not Stabilize the Architecture

The recent history shows a recognizable pattern:

| Commit | Useful change | Remaining architectural issue |
| --- | --- | --- |
| `c5b0880` | Bounded caps, reduced HUD frequency, replaced a squad N² relationship with a shared snapshot. | Live/dead lifecycle, projectile broadphase, procedural redraw, and real frame measurement remained. |
| `b763fa5` | Raised intended density and repaired boss behavior. | Increased pressure against the same hot data model. |
| `4bef999` | Made boss movement/aim/fire more threatening. | Added more boss and projectile work without a rendered capacity gate. |
| `1e7759f` | Correctly prevented early boss completion and doubled quotas. | Doubled the maximum retained dead history before bosses. |

This supports the user's concern about temporary fixes. The fixes were not
worthless; they improved behavior and some local costs. They were insufficient
because the acceptance test did not expose the cross-product and presentation
paths.

## Scale and Change-Risk Analysis

### Current Complexity Shape

Let:

- `L` = live enemies;
- `D` = retained dead enemies;
- `E = L + D`;
- `P` = player projectiles;
- `S` = supports;
- `B` = orbit blades/mines/other secondary instances;
- `V` = visible dynamic objects.

The important current terms are approximately:

```text
enemy base update          O(E)
shield assignment          O(E + S × E)
player projectile hits     O(P × E)
secondary local effects    O(B × E)
ID resolution              O(E) per lookup
dynamic command rebuild    O(V × commands-per-visual)
HUD snapshot allocation    fixed 20 Hz + catalog/map size
```

The desired architecture changes the important terms to:

```text
enemy base update          O(L)
shield/local relationships O(L + local candidates)
player projectile hits     O(P × local grid candidates)
secondary local effects    O(local grid candidates)
ID resolution              expected O(1)
base dynamic presentation  O(visible batch instances)
HUD                         event-driven + 10 Hz position-only channels
```

### How Ordinary Future Changes Behave Today

| Reasonable change | Current consequence | Why it is unsafe |
| --- | --- | --- |
| Raise ordinary active cap from 72 to 90 | More AI, more visible draw commands, more candidates in every projectile and secondary scan. | Multiple costs rise together with no measured headroom. |
| Add a multi-shot card | Projectile count multiplies the full enemy scan. | A content card can become a frame architecture change. |
| Add a longer stage or higher boss quota | More dead enemy dictionaries remain in every later scan. | Cost rises over play time even if live pressure is unchanged. |
| Add a new aura or passive weapon | The easiest current implementation is another `for enemy in enemies`. | Each feature adds permanent per-tick global work. |
| Add a support enemy | Shield/heal/repair relationships can add support × candidates work. | Local interactions are implemented globally. |
| Add statuses or richer telegraphs | More dictionary fields and more per-frame arcs/polygons. | Simulation and presentation costs both rise without a budget. |
| Add guidebook entries or minimap detail | Full hidden catalog/static geometry is regenerated at 20 Hz. | Closed UI content affects combat frames. |
| Run through the Web export | Same single-threaded script pressure with generally lower browser performance. | Current Web gate checks export success, not frame behavior. |

### What “Safe for Reasonable Changes” Can Truthfully Mean

No architecture can promise smooth play after arbitrary future content. A
truthful guarantee must state a capacity envelope and extension rules.

The selected envelope is:

- at most **128 live hostile actors total**, including ordinary enemies,
  stationary threats, a boss, pylons, and summons;
- the ordinary content cap remains at or below **96** unless the performance
  contract is deliberately revised;
- at most **240 player + 120 hostile projectiles**;
- at most **192 XP shards**;
- at most **96 transient effects**;
- at most **16 simultaneous zones/trails**;
- at most **three active secondary families**;
- at least **300 cumulative kills** before the sustained scenario, with no dead
  actors retained in live stores;
- the existing `5600×3400` field, `1280×720` logical viewport, Compatibility
  renderer, Korean HUD, audio, and complete combat presentation active.

Within that envelope, future mechanics are required to use shared lifecycle,
query, projectile, rendering, and HUD interfaces. Raising a capacity or adding a
new unbounded family is change control and must extend the stress scenario
before merge.

## External Practice Comparison

### Practices the Current Project Already Follows

- Static field drawing is cached.
- Active mobile count, projectile count, effect count, shard count, and audio
  voices are bounded.
- The pursuit field is shared and rebuilt at a lower frequency instead of
  solving a full path independently for every enemy.
- Enemy/projectile/effect drawing is world-rectangle culled.
- Combat simulation is centralized rather than creating hundreds of
  independently processing nodes.

These are worth preserving.

### Practices the Current Project Violates

- The release gate does not profile the actual bottleneck or rendered frame.
- Historical dead state remains in hot containers.
- Local collision and support questions scan the global actor collection.
- Hot homogeneous objects use dictionary records and string keys throughout.
- Frequently redrawn polygons are reconstructed instead of retained/prebuilt.
- Static and modal UI data is rebuilt at a combat timer frequency.
- Native and Web paths have no percentile frame-time contract.
- No extension rule prevents a new mechanic from adding another global scan.

### Lessons from the Official Bullet Shower

The correct lesson is not “replace everything with PhysicsServer2D.” It is:

1. keep homogeneous high-count objects under one explicit owner;
2. keep their state small and typed;
3. reuse shared resources;
4. prevent irrelevant collision pairs;
5. update them in a linear bounded pass;
6. clean server/state objects explicitly; and
7. draw reusable visuals instead of reconstructing complex shapes.

This project needs richer swept collision, cover rules, damage attribution,
statuses, and boss mechanics. A project-owned uniform grid is more direct and
testable at 128 actors than moving all gameplay semantics into server RIDs.
PhysicsServer2D remains an escalation option only if the implemented grid still
misses the locked budget.

## Viable Options and Decision

| Option | Why it was viable | Decision |
| --- | --- | --- |
| Keep the current monolith and reduce caps/tick rate | Small patch and immediate frame relief. | Rejected. It changes game density, leaves cost dependent on dead history, and repeats the temporary-fix pattern. |
| Convert every actor/projectile to Node2D/Area2D scenes | Godot broadphase and editor visibility become available. | Rejected as a blanket migration. It adds scene/node/callback overhead and does not by itself fix lifetime, global secondary scans, snapshots, or draw behavior. |
| Use PhysicsServer2D RIDs for all actors/projectiles | Official high-count pattern with engine broadphase. | Rejected for the first stabilization pass. The intended counts are modest, while custom cover, swept hits, statuses, and damage ownership remain easier to verify in the project runtime. |
| Switch to C#, C++, GDExtension, or an ECS | Can lower per-operation cost and support large data-oriented systems. | Rejected. It preserves bad algorithms, expands build/deployment risk, and conflicts with the current GDScript operating contract. |
| Move simulation to worker threads | Could use more CPU cores. | Rejected. SceneTree interaction is unsafe, synchronization adds complexity, and single-thread algorithmic waste remains. |
| Replace flat visuals with simpler art or disable audio | Reduces some rendering/audio work. | Rejected. The static art and bounded audio are not established bottlenecks, and the product should not pay a visual/gameplay cost before fixing avoidable CPU work. |
| Hybrid data-oriented GDScript runtime | Fixes lifecycle and search growth while preserving Godot, gameplay, art, and iteration speed. | **Selected.** |

## Selected Architecture

The execution plan locks these decisions:

1. Keep Godot 4.7 stable, GDScript, the Compatibility renderer, the 60 Hz
   physics rate, and the current art direction.
2. Keep only live actors in a bounded typed store. Defeats emit immutable events
   and are swap-removed after the tick; cumulative stats do not retain actor
   records.
3. Add a reusable `160 px` uniform spatial grid over the field. Projectile
   segments, AoE, target acquisition, aura, support, dash, and local enemy
   relationships query cells and then perform exact geometry checks.
4. Store high-count projectiles in fixed-capacity packed arrays with an active
   count and swap removal. Use O(1) actor ID lookup for homing.
5. Run movement, projectile motion/collision, damage, boss phase timing, and
   telegraph windows at 60 Hz. Run ordinary target/support/squad decisions at
   20 Hz in three stable buckets while reusing the last steering intent between
   decisions.
6. Prebuild the accepted flat silhouettes as reusable vertex-colored meshes.
   Batch base enemies by archetype and batch projectiles, shards, and effects by
   visual family with MultiMesh. Keep the low-count telegraph/status/health
   overlay in a separate renderer.
7. Stop rebuilding hidden/static UI data on the combat timer. Health/XP,
   objective/boss, discovery/guidebook, minimap geometry, minimap markers, and
   cooldown/position channels update only at their locked event or frequency.
8. Reduce `VehicleRun` to orchestration. Enemy state/AI, projectiles/spatial
   queries, presentation, and HUD each receive one responsibility-shaped owner.
9. Replace the false release metric with deterministic native and Web rendered
   scenarios that record subsystem time, full-frame percentiles, render CPU/GPU
   time, draw calls, counts, and memory stability.
10. Do not use global tick reduction, C#/GDExtension, new dependencies,
    multithreading, custom shaders, or external assets in this stabilization.

## Recommendations

### Immediate Governance Recommendation

Treat the current build as **functionally implemented but performance
unaccepted**. The existing `profile_vehicle_pressure.gd` result may remain as a
microbenchmark, but no active spec, README, plan, or handoff should describe it
as proof of smooth gameplay.

### Implementation Order

The safe order is:

1. land the real rendered benchmark and capture an as-is baseline;
2. fix actor lifecycle and direct ID lookup;
3. add the spatial query contract and packed projectile runtime;
4. migrate ordinary AI/secondary local queries and stagger decisions;
5. replace dynamic base-shape reconstruction with retained batches;
6. split HUD update channels;
7. finish orchestrator decomposition;
8. run the exact native/Web capacity gates and reconcile canonical docs.

This order makes every phase measurable and avoids changing simulation,
presentation, and validation simultaneously.

### Change-Control Recommendation

After stabilization, every new high-count mechanic must declare:

- maximum live instances;
- update frequency;
- spatial query kind;
- presentation batch or retained view owner;
- spawn/despawn lifecycle;
- benchmark scenario coverage.

A new global `for enemy in all_enemies`, a new uncapped dynamic array, or a new
per-frame deep UI snapshot is a rejected design unless the owner explicitly
changes the performance contract with measured evidence.

## Limitations

1. The repository has no valid end-to-end rendered pressure recorder today, so
   this audit cannot truthfully assign an exact percentage of the player's lag
   to simulation versus rendering versus browser overhead.
2. The current 4.4–4.8 ms pressure figures were reproduced, but only for the
   narrow headless method-call workload described above.
3. The user-observed severe lag is the decisive product symptom. Static code
   evidence establishes multiple mechanisms capable of producing it, but the
   selected plan still requires an as-is rendered baseline before any
   implementation to quantify each subsystem.
4. Windows windowed-mode scheduling, browser overhead, and the older Intel
   driver can add stutter. They cannot explain away the repository's
   multiplicative searches and invalid release gate. Native and Web are
   therefore measured separately at fixed resolutions.
5. MultiMesh and retained meshes are selected for predictable presentation
   cost, but their exact improvement must be verified on the current
   Compatibility renderer. If a locked batch fails its phase acceptance gate,
   the contingency is a pooled retained `MeshInstance2D` view, not a return to
   per-frame polygon construction.
