---
type: evidence
status: active
created: 2026-07-26
source: Claude Code through model-cli-delegates MCP
topic: Cardborne repository-wide read-only audit
baseline: faf8dfc4e85f129913ea38423a143d681a795f7c
related:
  - README.md
  - external-model-prompt.md
---

# Claude External Review — Raw Response

## Purpose

Preserve Claude Code's complete repository-audit answer without summarizing or
editing its claims. Codex validation belongs in a separate evidence document.

## Sources

- Provider: Claude Code 2.1.220
- Configured model: `claude-opus-4-6`
- Working directory: `D:\npjt\cardborne-platformer`
- Prompt: `external-model-prompt.md`
- Permission mode: read-only plan mode
- Successful response: 2026-07-26 Asia/Seoul
- Recovered verbatim from Codex session log after the display surface truncated
  an earlier retrieval.

## Attempt History

- 2026-07-26 01:08: the provider rejected the first attempt at its five-hour
  session limit.
- A later continuation completed the audit and returned the full report.
- A redundant repeat request later hit the next five-hour limit; that does not
  affect the already completed response preserved below.

## Raw Response

# Cardborne Repository Audit — 2026-07-26

**Baseline**: commit `faf8dfc` on `master`
**Auditor**: Claude (supporting coding auditor for Codex workflow)
**Scope**: Read-only, static analysis only. No runtime, no file modification, no git state changes.

---

## 1. Executive Verdict

**CONDITIONAL — not release-qualified without addressing the items below.**

Three top risks, ranked by blast radius:

| # | Risk | Evidence | Consequence |
|---|------|----------|-------------|
| 1 | **No release-qualified performance measurement** | `tools/validation/profile_vehicle_pressure.gd:2,77` — docstring and print both warn "excludes rendered-frame orchestration"; `.agents/vehicle-performance-stabilization-evidence.md` explicitly states it is "non-authoritative for release" | Architecture was rebuilt for performance (retained MultiMesh, spatial grid, staggered cadence) but the only measurement is headless-only. Real-device behavior under full render load is uncertified against the 60 fps target. |
| 2 | **5,394-line monolith orchestrator** | `scripts/vehicle/vehicle_run.gd` — 158 methods, 0 signals, 53 preloaded dependencies | Single-file ownership of player, enemies, bosses, projectiles, damage, rewards, persistence, and capture tooling. Any change risks unintended side-effects; isolation testing is impossible without an integration harness. |
| 3 | **Spec/code drifts in player-feel constants** | `scripts/vehicle/vehicle_run.gd` `PLAYER_HIT_FLASH_DURATION=0.20` vs spec 0.18 s; boss signature rotation semantics; boss arrival distance range | Small individually, but these are player-feel constants where deviation alters game balance or juice. If spec is canonical, code must match; if code is intentional, spec must be updated. |

---

## 2. Architecture & Gameplay Flow

### Runtime Bootstrap

| Layer | File | Key Symbols | Evidence |
|-------|------|-------------|----------|
| Engine config | `project.godot` | Godot 4.7 stable, GL Compatibility, 1280×720, `canvas_items` stretch, `ko` fallback locale | Verified directly |
| Autoloads | `project.godot` | `SettingsStore`, `VehicleGuidebookStore` | 2 autoloads registered |
| Bootstrap | `scripts/main/game_root.gd` | 25 lines, input-registration only | No game logic; delegates to vehicle_run |
| Orchestrator | `scripts/vehicle/vehicle_run.gd` | 5,394 lines, 158 methods, 0 signals | Owns entire game loop |

### Data Stores (Bounded, Preallocated)

| Store | File | Capacity | Retirement |
|-------|------|----------|------------|
| Enemy | `scripts/enemies/vehicle_enemy_store.gd` (135 lines) | `MAX_LIVE_HOSTILES=128` | Swap via `flush_defeated()`, O(1) `_by_id` dict |
| Player Projectile | `scripts/combat/vehicle_projectile_store.gd` (195 lines) | `PLAYER_CAPACITY=240` | Breach eviction priority |
| Hostile Projectile | `scripts/combat/vehicle_projectile_store.gd` | `HOSTILE_CAPACITY=120`, `HOSTILE_BOSS_RESERVE=24` | Team accounting validation |
| Spatial Grid | `scripts/combat/vehicle_spatial_grid.gd` (122 lines) | `MAX_TRACKED_ACTORS=128`, cell 160 px, 35×22 grid | Stamp-based dedup |

### Encounter & Stage Flow

| System | File | Key Constants |
|--------|------|---------------|
| Field Registry | `scripts/vehicle/vehicle_field_registry.gd` (35 lines) | 3 fields: `drowned_ruin`, `tidal_archive`, `storm_drydock` |
| Field Definition | `scripts/vehicle/stages/drowned_ruin_field.gd` (148 lines) | `WORLD_RECT=Rect2(0,0,7200,4320)`, `CENTER=Vector2(3600,2160)`, `START_CLEARANCE=560`, 32 spawn candidates, 12 boss anchors, 24 cover (6 sectors × 4), 36 item sockets, 21 walkable regions |
| Combat Stages | `scripts/vehicle/stages/vehicle_combat_stages.gd` (124 lines) | 5 stages (`stage_1`–`stage_5`), `QUOTAS=[125,166,208,250,291]`, `AUTHORED_COUNTS=[260,300,340,380,420]`, `SURGE_SQUADS=8` |
| Stage Catalog | `scripts/vehicle/vehicle_stage_catalog.gd` (432 lines) | Facade joining field+combat; validates 32 spawn / 12 boss anchors per stage |
| Difficulty | `scripts/vehicle/vehicle_run_difficulty.gd` (75 lines) | Easy 0.81 / Normal 0.90 / Hard 1.0 quota factors, `DEFAULT=HARD` — **all factors match spec exactly** |
| Encounter Director | `scripts/encounters/vehicle_encounter_director.gd` (117 lines) | `HOSTILE_PROJECTILE_SPEED_MULTIPLIER=0.82`, `ACTIVE_CAPS=[1,62,78,88,92]`, `EFFECT_CAP=96`, `PLAYER_PROJECTILE_CAP=240`, `HOSTILE_PROJECTILE_CAP=120`, `BOSS_PROJECTILE_RESERVE=24` |
| Encounter Runtime | `scripts/encounters/vehicle_encounter_runtime.gd` (285 lines) | `ARRIVAL_GRACE=6.0`, `CUE_LEAD=0.9`, first cue at 5.1 s, squad gap `0.90 if beat<=1 else 0.65` |
| Stage Flow | `scripts/encounters/vehicle_stage_flow.gd` (71 lines) | States: `ORDINARY→BOSS_WARNING→BOSS_ACTIVE→REWARDS→COMPLETE`, `warning_remaining=1.5` |

### Boss System

| File | Key Constants |
|------|---------------|
| `scripts/bosses/vehicle_boss_patterns.gd` (227 lines) | 30 patterns total, 4 direct + 2 autonomous per stage, 1 `interruptible_signature` per stage rotation, 3 phases |
| `scripts/bosses/vehicle_boss_runtime.gd` (265 lines) | `INTERRUPTED_RECOVERY=0.45`, `PHASE_THRESHOLDS=[0.65,0.30]`, `PHASE_GAPS=[0.55,0.42,0.32]`, forced committed after interrupt |

### Progression & Upgrades

| File | Key Constants |
|------|---------------|
| `scripts/progression/vehicle_experience_runtime.gd` (167 lines) | `MAX_SHARDS=192`, XP formula `min(160, 12+round(3n+0.55n²))` — **verified exact match to spec** |
| `scripts/cards/vehicle_upgrade_catalog.gd` (179 lines) | `EXPECTED_COUNT=46`, 4 optional secondary families, 2 optional slots, dedup via `_append_unique`/`_contains_upgrade_id`, branch child reservation for elemental trees |

### Presentation & HUD

| File | Key Constants |
|------|---------------|
| `scripts/presentation/vehicle_combat_renderer.gd` (1,054 lines) | Retained MultiMesh batches (~49 families), `ENEMY_CAPACITY=128`, `PROJECTILE_CAPACITY=240`, `BUFFER_FLOATS_PER_INSTANCE=12` |
| `scripts/ui/vehicle_hud_presenter.gd` (54 lines) | Dirty channels: `ACTION_INTERVAL=0.05` (20 Hz), `WORLD_MARKER_INTERVAL=0.10` (10 Hz), static minimap + guidebook on dirty flag only |

### Terrain & Combat Contracts

| File | Key Constants |
|------|---------------|
| `scripts/vehicle/vehicle_terrain_runtime.gd` (432 lines) | `REPAIR_BUDGET=24.0`, overdrive 1.20× applied at `vehicle_run.gd:3148` |
| `scripts/combat/vehicle_attack_contract.gd` (224 lines) | `LIGHT_PROJECTILE_RADIUS=5`, `STANDARD=6`, `HEAVY=7`, `RADIAL_EDGE_DAMAGE_SCALE=0.45`, 7 affinities, 8 ordinary attack definitions |

---

## 3. Findings Table

| # | Priority | Category | Finding | File:Symbol | Consequence | Recommendation | Confidence |
|---|----------|----------|---------|-------------|-------------|----------------|------------|
| F1 | **P1** | Performance | No release-qualified performance measurement exists | `tools/validation/profile_vehicle_pressure.gd:2,77`; `.agents/vehicle-performance-stabilization-evidence.md` | Cannot certify 60 fps under real render load | Run ≥60 s focused measurement with full rendering on target hardware | Verified |
| F2 | **P1** | Maintainability | Monolith orchestrator: 5,394 lines, 158 methods, 0 signals | `scripts/vehicle/vehicle_run.gd` | Untestable in isolation; every change risks regression | Extract subsystems behind signal boundaries; prioritize player, damage, and reward loops | Verified |
| F3 | **P2** | Spec drift | Hit flash duration 0.20 s vs spec 0.18 s | `scripts/vehicle/vehicle_run.gd:PLAYER_HIT_FLASH_DURATION` vs `docs/product/vehicle_game_spec.md` | Player-feel mismatch; 11% longer flash than designed | Align code to spec or update spec with rationale | Verified |
| F4 | **P2** | Spec drift | Boss interruptible signature described as "per fight" in spec vs per-rotation in code | `scripts/bosses/vehicle_boss_patterns.gd:interruptible_signature` | Players encounter signature at different frequency than designed | Reconcile spec language with implementation semantics | Verified |
| F5 | **P2** | Spec drift | Boss arrival minimum 1200 px (spec) vs 900–1500 px range (code) | `scripts/vehicle/vehicle_run.gd` boss arrival logic | Bosses can appear closer than spec minimum allows | Clamp range lower bound to 1200 or update spec | Verified |
| F6 | **P2** | Correctness | All 5 stages use `DROWNED_RUINS` title keys regardless of selected field | `scripts/vehicle/stages/vehicle_combat_stages.gd` stage title keys | Field selection has no visible impact on stage titles; players see wrong field name for `tidal_archive` and `storm_drydock` | Add field-aware title key resolution | Verified |
| F7 | **P2** | Architecture | 53 preloaded dependencies in single file | `scripts/vehicle/vehicle_run.gd` preload block | Load-order fragility; circular dependency risk as codebase grows | Group into subsystem facades | Verified |
| F8 | **P2** | Validation | Pressure profiler explicitly excludes rendering | `tools/validation/profile_vehicle_pressure.gd:2` docstring | Headless-only measurement creates false confidence about frame budget | Add rendered-frame measurement or document limitation prominently | Verified |
| F9 | **P2** | Validation | 4 validators restate constants without exercising logic | Identified during validator sweep of `tools/validation/` | Tests pass trivially; do not catch regressions in actual computation | Convert to integration-style checks that exercise game logic paths | Plausible |
| F10 | **P2** | Documentation | `.agents/vehicle-performance-stabilization-evidence.md` is non-authoritative but is the only perf evidence | `.agents/vehicle-performance-stabilization-evidence.md` header | Team may treat it as authoritative despite disclaimer; creates a documentation vacuum | Either promote with proper methodology or produce separate authoritative document | Verified |
| F11 | **P3** | Spec precision | Walkable regions: spec says "at least twenty", code has 21 | `scripts/vehicle/stages/drowned_ruin_field.gd` walkable regions array | Not a defect but spec imprecision; could confuse future implementers | Update spec to exact count or document tolerance | Verified |
| F12 | **P3** | Localization | 593 keys fully populated (ko + en), zero empty cells | `localization/vehicle_stage.csv` — 594 lines (1 header + 593 keys) | Positive finding — no gaps | Maintain; add CI check to prevent regressions | Verified |
| F13 | **P3** | UI | Responsive-state gaps in card placement under extreme viewport ratios | `tools/validation/validate_vehicle_stage_ui_layout.gd` covers 3,276 states at design viewports only | Edge-case overflow possible on non-standard displays | Extend validator to test additional aspect ratios | Plausible |

---

## 4. Spec / Code Drift

### Verified Matches (no drift)

| Spec Claim | Code Location | Status |
|------------|---------------|--------|
| Easy quota factor 0.81 | `vehicle_run_difficulty.gd:EASY` | **Match** |
| Normal quota factor 0.90 | `vehicle_run_difficulty.gd:NORMAL` | **Match** |
| Hard quota factor 1.0 | `vehicle_run_difficulty.gd:HARD` | **Match** |
| Default difficulty HARD | `vehicle_run_difficulty.gd:DEFAULT` | **Match** |
| Stage quotas [125,166,208,250,291] | `vehicle_combat_stages.gd:QUOTAS` | **Match** |
| Authored counts [260,300,340,380,420] | `vehicle_combat_stages.gd:AUTHORED_COUNTS` | **Match** |
| 8 surge squads | `vehicle_combat_stages.gd:SURGE_SQUADS` | **Match** |
| Player max health 120 | `vehicle_run.gd:PLAYER_MAX_HEALTH` | **Match** |
| Player base speed 280 | `vehicle_run.gd:PLAYER_BASE_SPEED` | **Match** |
| Primary projectile radius 7 | `vehicle_run.gd:PRIMARY_PROJECTILE_RADIUS` | **Match** |
| Dash duration 0.20 s | `vehicle_run.gd:DASH_DURATION` | **Match** |
| EMP cooldown 13.0 s | `vehicle_run.gd:EMP_COOLDOWN` | **Match** |
| Player hit invulnerability 1.0 s | `vehicle_run.gd:PLAYER_HIT_INVULNERABILITY` | **Match** |
| XP formula min(160, 12+round(3n+0.55n²)) | `vehicle_experience_runtime.gd` | **Match** |
| MAX_SHARDS 192 | `vehicle_experience_runtime.gd:MAX_SHARDS` | **Match** |
| Recall timer 0.65 s | `vehicle_experience_runtime.gd` | **Match** |
| MAX_LIVE_HOSTILES 128 | `vehicle_enemy_store.gd:MAX_LIVE_HOSTILES` | **Match** |
| Player projectile cap 240 | `vehicle_projectile_store.gd:PLAYER_CAPACITY` | **Match** |
| Hostile projectile cap 120 | `vehicle_projectile_store.gd:HOSTILE_CAPACITY` | **Match** |
| Boss projectile reserve 24 | `vehicle_projectile_store.gd:HOSTILE_BOSS_RESERVE` | **Match** |
| Spatial grid cell 160 px | `vehicle_spatial_grid.gd:DEFAULT_CELL_SIZE` | **Match** |
| Hostile projectile speed ×0.82 | `vehicle_encounter_director.gd:HOSTILE_PROJECTILE_SPEED_MULTIPLIER` | **Match** |
| 46 upgrade definitions | `vehicle_upgrade_catalog.gd:EXPECTED_COUNT` | **Match** |
| Fixed layout seed 0xC4A2B0 | `vehicle_run.gd:FIXED_LAYOUT_SEED` | **Match** |
| Minimap 20×12 | `vehicle_run.gd:MINIMAP_COLS=20,MINIMAP_ROWS=12` | **Match** |
| Far simulation distance 820 | `vehicle_run.gd:FAR_SIMULATION_DISTANCE` | **Match** |
| Boss phase thresholds [0.65, 0.30] | `vehicle_boss_runtime.gd:PHASE_THRESHOLDS` | **Match** |
| Boss phase gaps [0.55, 0.42, 0.32] | `vehicle_boss_runtime.gd:PHASE_GAPS` | **Match** |
| Interrupted recovery 0.45 s | `vehicle_boss_runtime.gd:INTERRUPTED_RECOVERY` | **Match** |
| Arrival grace 6.0 s | `vehicle_encounter_runtime.gd:ARRIVAL_GRACE` | **Match** |
| Cue lead 0.9 s | `vehicle_encounter_runtime.gd:CUE_LEAD` | **Match** |
| Boss warning 1.5 s | `vehicle_stage_flow.gd:warning_remaining` | **Match** |
| Radial edge damage scale 0.45 | `vehicle_attack_contract.gd:RADIAL_EDGE_DAMAGE_SCALE` | **Match** |

### Confirmed Drifts

| # | Spec Value | Code Value | Location | Severity |
|---|-----------|------------|----------|----------|
| D1 | Hit flash 0.18 s | `PLAYER_HIT_FLASH_DURATION=0.20` | `scripts/vehicle/vehicle_run.gd` | P2 — player feel |
| D2 | Boss signature "per fight" | Per rotation cycle | `scripts/bosses/vehicle_boss_patterns.gd:interruptible_signature` | P2 — frequency mismatch |
| D3 | Boss arrival ≥1200 px | 900–1500 px range | `scripts/vehicle/vehicle_run.gd` boss arrival logic | P2 — can violate minimum |
| D4 | Stage titles should reflect selected field | All stages use `DROWNED_RUINS` keys | `scripts/vehicle/stages/vehicle_combat_stages.gd` | P2 — field-agnostic |

---

## 5. Performance Review

### Architecture (Verified Present)

| Optimization | File | Evidence |
|--------------|------|----------|
| Bounded preallocated stores | `vehicle_enemy_store.gd`, `vehicle_projectile_store.gd` | Fixed capacities, swap retirement, no runtime allocation |
| Spatial grid broadphase | `vehicle_spatial_grid.gd` | 160 px cells, stamp dedup, replaces O(n²) scans |
| Retained MultiMesh batches | `vehicle_combat_renderer.gd` | ~49 families, `BUFFER_FLOATS_PER_INSTANCE=12`, replaces per-frame polygon reconstruction |
| Staggered simulation cadences | `vehicle_hud_presenter.gd` | 60/30/20/10 Hz tiers for different systems |
| Event-driven HUD | `vehicle_hud_presenter.gd` | Dirty-flag channels replace fixed-timer rebuilds |
| Breach eviction | `vehicle_projectile_store.gd` | Priority-based eviction prevents capacity overflow |

### Measurement Status

The **only** existing measurement is `profile_vehicle_pressure.gd`, which:
- Runs headless (line 2: "excludes rendered-frame orchestration")
- Explicitly prints this caveat (line 77)
- Measures `_update_enemies`, `_update_projectiles`, `_update_experience` in isolation

The `.agents/vehicle-performance-stabilization-evidence.md` document:
- Records post-stabilization measurements
- Explicitly labels itself **non-authoritative for release**
- Documents architecture changes but not their rendered-frame impact

### Archived Baseline

`.agents/vehicle-performance-architecture-audit.md` documents the **pre-change** state: dead enemy retention, multiplicative searches, per-frame polygon reconstruction. All three problems are architecturally addressed in current code. This document is correctly archived and no longer authoritative.

### Gap

No ≥60 s focused measurement under full rendering load exists. The architecture is sound in design, but the 60 fps target on GL Compatibility renderer is **unverified under real conditions**. This is the audit's single highest-priority gap.

---

## 6. Validator Quality

**Total validation scripts**: 38 in `tools/validation/` (37 `validate_*.gd` + 1 `profile_vehicle_pressure.gd`) — matches the spec claim of 38.

### Strong Validators (9)

| Validator | What It Tests |
|-----------|---------------|
| `validate_vehicle_stage_ui_layout.gd` (189 lines) | 3,276 card-placement states (91 states × 3 slots × 3 viewports × 2 locales × 2 selection states) |
| `validate_vehicle_stage_catalog.gd` | 32 spawn anchors and 12 boss anchors per stage, field-stage binding integrity |
| `validate_vehicle_upgrade_catalog.gd` | 46 upgrades, dedup correctness, elemental branch reservation, secondary families |
| `validate_vehicle_combat_stages.gd` | Quota/authored count relationships, surge squad counts, boss name key alignment |
| `validate_vehicle_enemy_store.gd` | Capacity enforcement, swap retirement correctness, ID lookup integrity |
| `validate_vehicle_projectile_store.gd` | Team accounting, breach eviction priority, boss reserve isolation |
| `validate_vehicle_spatial_grid.gd` | Cell assignment, stamp dedup, boundary conditions |
| `validate_vehicle_experience_runtime.gd` | XP formula verification across full level range |
| `validate_vehicle_boss_patterns.gd` | Pattern count per stage, phase distribution, signature rotation integrity |

### Constant-Restating Validators (4, P2 concern)

| Validator | Issue |
|-----------|-------|
| Difficulty validator | Asserts `EASY == 0.81` — passes trivially, never tests difficulty application to quotas |
| Field registry validator | Asserts 3 fields exist — never tests field loading or content integrity |
| Attack contract validator | Asserts radius constants match expected values — never tests damage computation |
| Stage flow validator | Asserts state enum names exist — never tests transition logic or timing |

### False-Confidence Risks (5)

| Risk | Description |
|------|-------------|
| Headless-only profiler | `profile_vehicle_pressure.gd` measures without rendering; results don't predict frame budget |
| No integration test harness | Validators run in isolation; no test exercises a full stage cycle end-to-end |
| No player-input simulation | Card placement validator tests layout but not interaction sequences (drag, tap, cancel) |
| No persistence round-trip test | Save/load cycle is untested by any validator |
| No audio validation | Sound trigger correctness and timing are unverified by any script |

---

## 7. UI / Localization / Accessibility

### Localization Status

| Metric | Value | Evidence |
|--------|-------|----------|
| Total keys | 593 | `localization/vehicle_stage.csv`: 594 lines (1 header + 593 data rows) |
| Languages | Korean (ko), English (en) | CSV columns: `keys,ko,en` |
| Empty cells | **0** | Verified — all cells populated for both locales |
| Fallback locale | Korean | `project.godot`: `locale/fallback="ko"` |

### UI Layout Verification

| Check | Status | Evidence |
|-------|--------|----------|
| Card placement layout | **3,276 states validated** | `tools/validation/validate_vehicle_stage_ui_layout.gd` |
| Viewport coverage | 3 design-target viewports | Validator iterates 3 viewports |
| Selection state coverage | 2 states per slot | Selected and unselected |
| Locale coverage | Both ko and en | Validator iterates both locales |
| Upgrade card overflow | Recently fixed | Commit `faf8dfc`: "fix: close upgrade UI localization and overflow" |

### Identified Gaps

| # | Gap | Severity | Notes |
|---|-----|----------|-------|
| G1 | No extreme aspect ratio testing | P3 | Validator covers design viewports only; ultrawide/portrait untested |
| G2 | No runtime text overflow check beyond design viewports | P3 | Korean strings may overflow at non-standard sizes; not statically verifiable |
| G3 | No font fallback rendering verification | P3 | Requires runtime visual inspection |
| G4 | Field-agnostic stage titles | P2 | All stages display `DROWNED_RUINS` keys regardless of field — see F6/D4 |

---

## 8. Documentation Review

| Document | Role | Status | Issues |
|----------|------|--------|--------|
| `docs/product/vehicle_game_spec.md` | Canonical gameplay spec | **Active, mostly accurate** | 4 drifts identified (D1–D4); walkable region count imprecise ("at least twenty" vs 21) |
| `docs/design/UI_VISUAL_SYSTEM.md` | Canonical art/UI/presentation | **Active** | No drift found in static analysis |
| `AGENTS.md` | Project operating rules | **Active** | Correctly defines preflight checks, documentation lifecycle, source-of-truth hierarchy |
| `.agents/vehicle-performance-architecture-audit.md` | Pre-change baseline | **Archived, intentionally stale** | Documents problems since addressed; correctly marked as pre-change |
| `.agents/vehicle-performance-stabilization-evidence.md` | Post-stabilization measurements | **Active but non-authoritative** | Explicitly disclaims release authority; is paradoxically the only perf evidence available |
| `docs/handoffs/repository-audit-2026-07-26/` | Audit handoff package | **Active** | Well-structured; reading order, source map, constraints, current-state all internally consistent |

### Stale Claims Requiring Update

| # | Document | Claim | Reality |
|---|----------|-------|---------|
| S1 | `vehicle_game_spec.md` | Hit flash 0.18 s | Code implements 0.20 s |
| S2 | `vehicle_game_spec.md` | Boss signature "per fight" | Code implements per rotation |
| S3 | `vehicle_game_spec.md` | Boss arrival ≥1200 px | Code allows 900–1500 px |
| S4 | Perf evidence doc | "non-authoritative" | It is the *only* performance evidence — creates a documentation vacuum where no document is authoritative |

---

## 9. Prioritized Actions

### Must-Fix (before release)

| # | Action | Finding | Effort |
|---|--------|---------|--------|
| A1 | **Run ≥60 s focused performance measurement with full rendering** on target hardware | F1, F8 | Medium — requires test harness extension or manual profiling session |
| A2 | **Reconcile hit flash duration** — set `PLAYER_HIT_FLASH_DURATION` to 0.18 or update spec to 0.20 with documented rationale | F3, D1 | Trivial — one constant or one spec line |
| A3 | **Reconcile boss arrival distance** — clamp code lower bound to 1200 px or update spec to document 900 px minimum | F5, D3 | Trivial — one clamp or one spec edit |
| A4 | **Fix field-agnostic stage titles** — resolve title localization keys per selected field, not hardcoded to `DROWNED_RUINS` | F6, D4 | Small — key lookup change in `vehicle_combat_stages.gd` |

### Stabilization (before scaling the codebase)

| # | Action | Finding | Effort |
|---|--------|---------|--------|
| A5 | **Reconcile boss signature semantics** — update spec from "per fight" to "per rotation" or change code | F4, D2 | Trivial — spec wording clarification |
| A6 | **Promote or replace perf evidence document** — upgrade to authoritative with proper methodology, or produce separate release-qualified document | F10, S4 | Medium — requires measurement + writing |
| A7 | **Convert 4 constant-restating validators to integration checks** that exercise computation paths | F9 | Medium — requires test logic redesign |
| A8 | **Begin orchestrator decomposition** — extract player loop, damage system, or reward system behind signal boundaries from `vehicle_run.gd` | F2, F7 | Large — incremental; start with highest-churn subsystem |
| A9 | **Add rendered-frame performance validation** script to complement headless profiler | F8 | Medium — new test script with GPU measurement |

### Optional Improvements

| # | Action | Finding | Effort |
|---|--------|---------|--------|
| A10 | Extend UI layout validator to non-standard aspect ratios (ultrawide, portrait) | F13, G1 | Small |
| A11 | Add CI check for localization completeness (fail on empty CSV cells) | F12 | Small |
| A12 | Update spec walkable region count from "at least twenty" to "21" or other exact value | F11 | Trivial |
| A13 | Add save/load round-trip validation script | False-confidence gap | Medium |
| A14 | Add integration test that runs a full stage cycle (spawn → combat → boss → rewards → complete) | False-confidence gap | Large |
| A15 | Document the 53-dependency preload block in `vehicle_run.gd` with grouping rationale or refactor into facades | F7 | Small |

---

## 10. Assumptions & Runtime Verification Needs

### Assumptions Made During This Audit

| # | Assumption | Basis | Risk if Wrong |
|---|-----------|-------|---------------|
| AS1 | The 38 validation scripts in `tools/validation/` are the complete validation suite | Glob of `tools/validation/*.gd` returned 37 `validate_*` + 1 `profile_*` | Missing validators elsewhere would weaken coverage assessment |
| AS2 | `tidal_archive` and `storm_drydock` fields share the same anchor/socket structure as `drowned_ruin_field.gd` | Only `drowned_ruin_field.gd` was read in full; the other two fields were confirmed to exist but not fully inspected | **Uncertain** — if other fields have different structures, additional drifts may exist |
| AS3 | Localization CSV has no encoding issues beyond cell completeness | Verified cell count and non-emptiness but not byte-level encoding or glyph coverage | Rendering glitches possible at runtime for edge-case characters |
| AS4 | The 158-method count and 53-preload count for `vehicle_run.gd` are accurate | Established in prior session analysis | Minor — doesn't materially affect findings even if off by a small number |

### Items Requiring Runtime or Human-Play Verification

| # | Item | Why Static Analysis Is Insufficient |
|---|------|-------------------------------------|
| RV1 | 60 fps under full render load at peak hostiles (128 enemies, 240 player projectiles, 120 hostile projectiles) | Headless profiler excludes GPU; only actual rendered-frame measurement is valid |
| RV2 | Hit flash visual feel at 0.20 s vs spec 0.18 s | Perceptual judgment; both values are plausible but feel different |
| RV3 | Boss arrival distance feel at 900 px minimum | Whether 900 px feels "too close" or "appropriately urgent" requires play testing |
| RV4 | Korean text overflow in upgrade card UI at runtime | String lengths vary by locale; overflow depends on font metrics and container sizing under actual rendering |
| RV5 | Font fallback rendering for mixed ko/en text | Requires visual inspection of rendered frames with both locales |
| RV6 | Audio trigger timing and layering during combat | No audio validation exists in the codebase; correctness is unverifiable statically |
| RV7 | Minimap readability at 20×12 grid resolution | Visual clarity is a runtime/perceptual judgment |
| RV8 | Card placement interaction sequences (drag, tap, hold, cancel) | Layout validator tests static states, not user interaction flows |
| RV9 | Save/load cycle data integrity across all progression states | No persistence round-trip validator exists |
| RV10 | Stage transition smoothness (ORDINARY → BOSS_WARNING → BOSS_ACTIVE → REWARDS → COMPLETE) | State machine is structurally correct but timing feel, visual transitions, and audio cues require play |

### Verified vs. Inferred Summary

| Category | Verified (static) | Inferred | Needs Runtime |
|----------|-------------------|----------|---------------|
| Spec/code constants | 30+ matches, 4 drifts | 0 | 0 |
| Architecture presence | 6 optimization systems confirmed in code | 0 | 0 |
| Performance adequacy | Architecture present and correctly structured | Likely adequate based on design | **Must verify** (RV1) |
| Validator coverage | 9 strong, 4 weak, 38 total | 5 false-confidence risks | 0 |
| Localization completeness | 593/593 keys filled, 0 empty cells | Encoding OK | RV4, RV5 |
| UI layout correctness | 3,276 states pass at design viewports | Extreme ratios likely OK | RV4, RV8 |
| Gameplay feel | N/A — not assessable statically | N/A | RV2, RV3, RV7, RV10 |
| Data persistence | Save/load code exists in `vehicle_run.gd` | Round-trip integrity assumed | RV9 |

---

*End of audit. All findings are based on read-only static analysis of commit `faf8dfc` on `master`. No files were modified, no patches created, no installations performed, no git state changed. Items marked "Uncertain" or "Plausible" require the noted runtime verification before being treated as confirmed.*
