---
type: evidence
status: active
owner: BK
created: 2026-07-31
last_reviewed: 2026-08-10
topic: Semantic-v2 runtime integration, UI acceptance, boss guidance, and final performance
scope: Non-map semantic-v2 runtime switch and its post-acceptance validation
related:
  - ../docs/design/VISUAL_SYSTEM.md
  - ../docs/product/vehicle_game_spec.md
  - ../art/visuals/production/README.md
  - ./execplans/2026-08-10-non-boss-combat-and-upgrade-integrity.md
---

# Semantic-v2 Runtime Acceptance Evidence

## Purpose

승인된 `semantic-v2` 이미지 팩의 runtime 연결 범위, UI와 공격 표시의
현재 상태, 보스 피해·목표 안내와 당시 수행한 성능 안정화 결과를 기록한다.
이 문서는 source asset 존재와 실제 runtime 연결을 구분하고, 구현 결과와
미통과 gate를 함께 보존한다. 새로운 gameplay나 release policy를 만들지
않는다.

## Sources

- `art/gameplay/semantic-v2/asset-manifest.json`과 runtime semantic asset
  provider
- `build/captures/semantic-v2-acceptance/ko-1280-final2/`의 최종 native
  AS-IS baseline capture matrix
- `build/captures/complete-visual-replacement/`의 Phase 7 native
  TO-BE capture matrix
- `build/performance/complete-visual-final/`의 Phase 8 final visual build
  smoke와 rejected correction payload
- `build/performance/semantic-v2-final/`의 final performance JSON
- `tools/validation/`의 56개 vehicle validator
- `build/web/index.html`을 포함한 Godot production Web export
- `build/performance/pre-asset/native/`의 pre-asset gameplay stabilization
  baseline과 final capacity payload

`build/` 아래 파일은 local ignored evidence다. 아래 표에 payload 이름과
핵심 수치를 남겨 repository 문서만 읽어도 통과 여부를 알 수 있게 한다.

## 2026-08-07 minimal transient checkpoint

- Runtime and focused validation commit: `f3dbcc5b`.
- Production `VehicleVisualEventCatalog` now contains exactly four buffered
  transients: dash afterimage, EMP charge radius, EMP release, and reduced boss
  damage text. The previous suppressed, direct-feedback, HUD-only, and directed
  transfer entries and their producers are absent.
- Attack geometry, projectiles, actor hit tint, barrier absorption, Marked,
  Sheared, arrival, death, pickup, reward, HUD, and audio remain with their
  direct runtime owners. Barrier absorption publishes a 0.16-second ring flash;
  Marked and Sheared use four amber brackets and two mint side bars.
- Native full capture completed at
  `build/captures/effects-minimal-20260807/`: Korean 1280×720, 78 files, with
  `09-effects-essential-transients.png` covering the four catalog IDs exactly
  once. `08-player-barrier-only.png` confirms the direct barrier ring state.
- The canonical authority pair was rechecked. The sheet remained
  `docs/design/cardborne-universal-art-style-reference.png`, SHA-256
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`,
  1448×1086. No raster was created or edited, so actual raster/ImageGen
  reference input and new provenance are not applicable.
- Focused validators passed for effect store, visual-event coverage, secondary
  weapons, combat renderer, player presentation, status stacking, capture
  manifest, and integrated VehicleRun. Godot editor import and production Web
  export also passed; output is `build/web/index.html`.
- `validate_vehicle_damage_feedback.gd` again produced no error but did not
  terminate within 180 seconds, matching the pre-change timeout. This checkpoint
  does not qualify release performance or claim that long-running validator as
  passed.

## Complete visual replacement checkpoint

Phase 3–7 구현과 visual acceptance의 clean baseline은 commit
`ade84a8`이다.

- gameplay manifest SHA-256:
  `756076d7ba2164464749272143bf4f43027c4c1447af14e1470817f6baa0afe5`
- UI manifest SHA-256:
  `2ce75df98280ec00b9c31715c76d53396388be5626c1f089f25ac4dd3a9f79fe`
- 모든 world-space visual event는
  `VehicleVisualEventCatalog`의 descriptor를 사용한다. broad
  `spawn/shock/secondary/destroy/support` emit과 renderer generic
  ring/beam/diamond fallback은 제거됐다.
- EMP, wake mine, summon arrival, boss module resolved와 bulkhead destroy를
  포함한 모든 event는 `09-effects-player`, `secondary`,
  `projectile-hostile`, `destroy-boss`, `pickup-support`의 다섯 runtime
  capture group에 정확히 한 번 포함된다. `group_clear`는 의도된
  HUD-only event라 world capture에서 제외된다.
- hit, reflection, barrier contact와 seeker/escort/orbit/wake secondary는
  서로 다른 animation family다. dash afterimage는 player hull image를
  재사용하며 red danger radial을 만들지 않는다.
- resolved boss module은 one-shot disabled effect 뒤 persistent disabled
  body와 resolved objective cue를 사용한다.
- production Theme의 `StyleBoxFlat` 수는 0이다. modal/HUD/card/button/
  tab/meter/preview는 image-backed texture state를 사용하고 localized
  text, icon, value와 progress는 child control 또는 live geometry로
  유지된다.
- ko/en × 960×540, 1280×720, 1920×1080, English 200% dynamic-text
  magnification, reduced-motion, grayscale, peak horde, all five bosses와
  modal state를 capture했다. 확인된 clipping/overflow blocker는 0이다.
- `16-effects-runtime-asis-tobe.png`,
  `17-ui-panels-asis-tobe.png`,
  `18-pressure-readability-asis-tobe.png`는 동일 locale/viewport/fixture의
  baseline과 Phase 7 runtime을 비교한다.
- 52개 non-performance focused validator가 통과했다. performance
  scenario, native/Web authoritative matrix와 lifecycle soak는 사용자
  지시대로 이 checkpoint 뒤 Phase 8에만 실행한다.

## Findings

### 구현 및 시각 검수

- non-map actor, boss/module, secondary, defense, projectile, status, pickup,
  facility, HUD/minimap와 upgrade glyph가 하나의 manifest-backed provider를
  소비한다. floor/wall map surface는 이번 범위에서 제외했다.
- effect source와 manifest에는 8개 animation family가 존재하지만 당시
  combat renderer가 실제 event lifecycle에 연결한 것은
  `muzzle_player_primary`, `impact_reflect`, `dash_start` 3개뿐이다.
  `emp_release`, `wake_mine_detonation`, `boss_module_disabled`,
  `hostile_summon_arrival`, `bulkhead_destroy` 5개는 source가 존재해도
  production event에서 재생된 것으로 인정할 runtime evidence가 없다.
- 당시 hit, reflect와 barrier contact는 같은 `impact_reflect` animation을
  공유했고 broad `spawn`, `shock`, `secondary`, `destroy`, `support` event는
  generic ring/diamond/beam/afterimage fallback으로 표시됐다. 따라서 effect
  integration은 완료 상태가 아니었다.
- player engine은 hull rear socket에 고정되고 aim mount만 manual aim을
  따른다. dash는 directional start/afterimage를 사용하며 danger radial을
  만들지 않는다.
- projectile은 `0.36 s` short lead, charge는 locked capsule, beam만
  full-path corridor, area와 support는 각 footprint/lifecycle을 사용한다.
- boss core는 `SEALED 0.20×`, `OPEN 1.55×/5 s`, `STABLE 1.00×`이며 HP
  floor나 objective lock 때문에 damage가 0이 되지 않는다. active module
  ID/state/health는 HUD, world cue, radar와 minimap에서 같은 snapshot을
  소비한다.
- upgrade card의 Korean/English overflow와 modal layout을 당시 validator
  기준으로 교정했지만 production chrome은
  `art/ui/production/vehicle_stage_theme.tres`의 `StyleBoxFlat`과
  `VehicleModalSurface._draw()` 등 procedural perimeter에 남아 있었다.
  사용자가 지정한 image panel/frame/background 위에 동적 text/icon/value를
  조합하는 UI 전환은 완료되지 않았다.
- `ko-1280-final2` capture는 당시 runtime 상태를 보존하는 baseline
  evidence다. peak combat에서 generic overlay가 판독을 방해하고 UI chrome이
  image-backed가 아니므로 최종 visual acceptance 증거로 사용하지 않는다.
- import, 52개 focused validator, semantic coverage/separation, UI layout,
  attack, boss, pickup, spatial-grid와 integrated-run validation이 당시
  계약에서 통과했다. source 수와 code path 존재를 확인한 결과이며 누락된
  producer event→catalog→asset→frame chain 또는 UI texture state coverage를
  증명하지 않는다.
- Godot release Web export가 성공했다. commit `7f9c554`의 production build를
  fastrun Codex lane `13029`에서 제공하고 실제 브라우저로 배치 화면, 전투
  진입, primary 연속 사격, 이동·dash·EMP 입력, 실패 report와 garage 복귀를
  확인했다. 브라우저 console warning/error는 0건이었다.

### 성능 구조

- `VehicleSpatialGrid`는 stable slot과 generation stamp를 사용해 spawn,
  movement, deactivation과 defeat 때 membership을 증분 갱신한다.
- query buffer, shield assignment cache, cover-hit receipt와 secondary
  damage intent를 재사용한다. non-piercing projectile은 ordered cell
  traversal에서 첫 contact 뒤 중단한다.
- renderer는 actor scan과 top-N overlay selection을 통합하고 semantic
  draw object와 MultiMesh buffer를 미리 할당한다. support timer는 8개
  segment를 사용하며 중복 shield ring과 translucent overlay를 줄였다.
- authoritative production replay에서 active ordinary enemy는 최소 249,
  중앙값 276이었고 scenario qualification이 유효했다.
- capacity fixture가 real attack zone을 artificial fixture zone 위에
  추가하던 문제를 고쳤다. real zone은 보존하고 fixture-owned zone만
  retire/backfill하여 320 scenario가 항상 정확히 16 zone을 유지한다.

### Complete visual replacement 최종 성능 결과

Phase 7 clean visual baseline `ade84a8`에서 native 1280×720,
5초 warmup + 20초 focused smoke를 실행했다. 네 workload는 모두
qualification이 유효하다. 짧은 smoke라 payload의 `authoritative`는
`false`이며, 아래 판정은 개별 threshold check와 subsystem 진단이다.

| Payload | Frame p95/p99 | 1% low | Physics p95/p99 | 판정 |
| --- | ---: | ---: | ---: | --- |
| `smoke/production_replay.json` | `16.67/16.67 ms` | `60.00 FPS` | `8.88/10.79 ms` | workload와 non-authority threshold check 통과 |
| `smoke/boss_pressure.json` | `16.67/16.67 ms` | `56.89 FPS` | `4.20/6.29 ms` | workload와 non-authority threshold check 통과 |
| `smoke/peak_horde.json` | `16.67/18.06 ms` | `53.80 FPS` | `9.35/11.72 ms` | 1% low `55 FPS` gate 미통과 |
| `smoke/capacity_pressure.json` | `36.50/47.27 ms` | `20.20 FPS` | `13.47/16.13 ms` | frame, tail과 capacity simulation `6/8 ms` gate 미통과 |

capacity의 가장 큰 measured subsystem은 `enemies_and_grid`
p95 `5.61 ms`였고, `combat_and_effects`도 `4.61 ms`였다. 계획이 허용한
한 번의 bounded correction으로 ordinary actor의 중복 traversal을
worklist로 제한했지만 `corrected-smoke/capacity_pressure.json`에서
physics p95 `13.02 ms`, enemy p95 `6.08 ms`로 measured improvement를
만들지 못했다. 실험 코드는 제거했으며 final source는 `ade84a8`의
simulation behavior를 유지한다.

capacity smoke가 실패했으므로 guard에 따라 authoritative native/Web
performance matrix와 600초 lifecycle soak를 실행하지 않았다. production
Web export와 built-Web interaction smoke는 통과했지만 Web performance
측정을 release 통과로 주장하지 않는다.

### 이전 semantic-v2 성능 결과

| Payload | 자격 | 결과 |
| --- | --- | --- |
| `production-replay-authoritative-01.json` | native 1280×720, 10 s warmup + 60 s, focused, valid | **통과**. active 249–276, frame p95/p99 `16.67/16.67 ms`, 1% low `58.93 FPS`, physics p95 `10.03 ms`, presentation p95 `1.17 ms`, draw-call p95 `89`, consecutive `>33.3 ms` `0` |
| `boss-pressure-authoritative-01.json` | 같은 조건, 77 actors/1 boss/8 zones, valid | **통과**. frame p95/p99 `16.67/16.67 ms`, 1% low `59.77 FPS`, physics p95 `0.04 ms`, presentation p95 `0.63 ms` |
| `peak-horde-authoritative-02.json` | 같은 조건, 276 actors/212 projectiles, valid | **미통과**. frame p95/p99 `20.87/33.33 ms`, 1% low `27.04 FPS`, physics p95 `11.84 ms`, draw-call p95 `114`, consecutive `>33.3 ms` `22` |
| `capacity-pressure-authoritative-03.json` | 같은 조건, 320 actors/360 projectiles/16 zones, valid | **미통과**. frame p95/p99 `30.79/50.00 ms`, 1% low `14.06 FPS`, physics p95/p99 `13.20/16.84 ms`; capacity simulation limit은 `6/8 ms` |
| `lifecycle-pressure-60s-diagnostic-01.json` | 같은 조건, 320 actors, 551 reuse cycles, valid | **진단 미통과**. memory growth `2.59 MB`는 bounded였지만 frame/physics가 capacity gate를 넘었고 required `600 s` soak를 실행하지 않았다 |

짧은 `peak-horde-final-06.json`은 모든 release threshold를 통과했지만
warmup이 5초라 authoritative claim에 사용하지 않는다. 긴 peak/capacity
결과가 strict tail-latency 실패를 재현하므로 현재 build를 complete
performance release로 판정할 수 없다.

## Pre-asset gameplay stabilization checkpoint

2026-08-02 plan의 gameplay 구현은 commits `6d9d6c2`, `5aceddf`, `0f5eb6e`에
나뉘어 있다. asset/UI 외관은 바꾸지 않았다.

- ordinary 이동 배율 `1.40`, unit별 sparse offscreen birth, 3 arrival windows,
  exact first-unit cue/reservation, packet fence와 overlap-only nearest-8 steering을
  구현했다. birth 뒤에는 squad cohesion이나 local density cap 없이 role behavior로
  player에게 수렴한다.
- field당 wear-collapse tile 4개, distinct crossing 3회 collapse, entry 즉시 및
  0.75초마다 8 damage, run-scoped `state/wear` persistence를 구현했다.
- spatial grid swap-remove와 local overlap center grid, projectile interceptor의
  exact broadphase radius, wear traversal allocation 제거, body/telegraph culling
  분리로 workload나 gameplay 수치를 낮추지 않고 hot path를 줄였다.
- 56개 `validate_vehicle_*.gd`, document authority, Godot import와 production Web
  export가 모두 exit code 0이었다.

### Capacity before/after

Native 1280×720, 10초 warmup + 60초, 320 enemies/360 projectiles/16 zones의
같은 workload다. baseline은 `6d9d6c2`, final은 clean `0f5eb6e`다.

| Payload 묶음 | 자격 | Frame p95/p99 | Physics p95/p99 | 판정 |
| --- | --- | ---: | ---: | --- |
| `capacity-baseline-1..3.json` | 3회 authoritative, workload valid | worst `141.46/146.92 ms` | worst `54.71/90.36 ms` | 미통과 |
| `capacity-selection-final-1..3.json` | 3회 authoritative, focused, clean commit, workload valid | worst `138.16/144.44 ms` | worst `20.77/26.40 ms` | 미통과 |

final 세 run의 physics p95/p99는 각각 `19.22/23.86`, `20.76/24.59`,
`20.77/26.40 ms`다. 정해진 GDScript owner 최적화로 baseline보다 크게
줄었지만 release limit `6/8 ms`에는 도달하지 못했다. frame p95/p99,
1% low와 consecutive slow-frame gate도 함께 실패했다. actor/projectile 수,
해상도, visual quality와 threshold는 변경하지 않았다.

따라서 native capacity 이후 순서인 나머지 native/Web matrix, Web performance,
600초 lifecycle과 새 built-Web interaction smoke는 실행하지 않았다. production
Web export 자체는 성공했다. 남은 격차는 현재 plan의 허용된 GDScript 경계를
넘어 native/dependency work 또는 workload/threshold 결정을 요구하므로 별도
사용자 승인 전에는 `code_ready_for_asset_ui_switch`로 판정할 수 없다.

## Recommendations

1. 다음 성능 작업은 이 evidence를 시작점으로 별도 승인한다. actor 수,
   projectile 수, 해상도, 언어, visual quality 또는 threshold를 낮추지
   않는다.
2. synthetic capacity에서 physics `6/8 ms`와 frame-tail을 동시에 줄일
   구조를 먼저 설계하고, native/dependency rewrite는 별도 권한 없이
   시작하지 않는다.
3. native capacity gate를 통과한 뒤 Web performance matrix를 실행한다.
4. capacity gate를 통과한 뒤에만 `lifecycle_pressure`의 measured interval을
   600초로 실행한다.

## Limitations

- map tile compiler, enemy coordinated tactics와 boss pattern redesign은
  이 구현과 evidence의 범위가 아니다.
- `ko-1280-final2` AS-IS baseline에서는 effect runtime wiring이 3/8
  family였고 UI chrome이 procedural이었다. 해당 제한은 위
  `ade84a8` Phase 7 checkpoint에서 해소됐다.
- native capture는 Korean 중심이며 English/960/1920/200% text는 validator
  및 이전 rendered matrix로 확인했다.
- production replay와 boss pressure는 통과했지만 synthetic peak와
  capacity가 미통과이므로 release-wide performance 통과를 주장하지 않는다.
- interactive built-Web smoke는 통과했지만 600초 lifecycle soak는 수행하지
  않았다.
- 2026-08-02 gameplay stabilization build는 production Web export까지 통과했지만
  native capacity gate가 먼저 실패해 새 built-Web smoke와 Web matrix를 실행하지
  않았다.
## 2026-08-03 Visual authority path normalization

- The active visual specification moved from
  `docs/design/UI_VISUAL_SYSTEM.md` to `docs/design/VISUAL_SYSTEM.md` during the
  approved Phase 1 path normalization.
- Earlier occurrences of the former path in this append-only evidence remain
  historical. The move changes no recorded acceptance verdict or failed release
  threshold.

## 2026-08-03 Shared UI reconstruction acceptance

Corrective implementation commit
`c72984ec8494ba224a6ed2924035dea600660719` completes the shared UI reconstruction
on Godot `4.7.1.stable.official.a13da4feb`. UI chrome now has one code-native
Theme and shared component factory, while meaningful craft,
upgrade, enemy, boss, object, minimap, and action imagery remains gameplay
content. Deployment has no difficulty choice and always starts the fixed Hard
profile. Upgrade offers have three mandatory selectable cards, one relevant
image per card, no exit or decline action, and a fixed Equip action. Pause is an
equal-width vertical stack.

### Deterministic and rendered evidence

- The pre-retirement document-authority gate passed with `markdown=15`; after
  deleting the completed ExecPlan it passed again with `markdown=14`. All 58
  sorted Godot validators passed. Godot import, `git diff --check`, Web export,
  workbench check, and workbench validation also exited zero.
- The final workbench contains 36 units and 216 media records: 215 gameplay
  PNGs and one font. It contains zero production UI chrome PNGs and four retired
  units. Status totals are `keep_current=2`, `target_required=30`, and
  `retired=4`.
- Complete manifests and captures are under
  `build/ui-reconstruction-final/{ko,en}-{960x540,1280x720,1920x1080}` and
  `build/ui-reconstruction-final/{ko,en}-1280x720-text2`. Each capture manifest
  records the requested logical viewport and the PNG dimensions match it.
- Level 4 review found no missing information, overlap, clipping, decorative
  chrome regression, difficulty control, or inaccessible primary action. At
  200% text scale, upgrade cards remain non-scrolling inside one outer offer
  body scroll with fixed Equip. Failure report likewise uses one outer body
  scroll with a fixed action. HUD objective, boss, notification, and transition
  regions do not overlap.
- Final logs are retained under `build/ui-reconstruction-final/logs`. The only
  validator warnings are intentional malformed-data fixtures that prove
  `SettingsStore` fallback behavior; they are not runtime warnings.

### Production Web smoke

`tools/export_web.ps1` produced `build/web/index.html` and the complete four-file
Web artifact. The built artifact was served on the fastrun-manager Codex lane at
port `13029`. Chrome interaction covered Deployment, live HUD, Pause, Settings,
Guidebook and back navigation, resume, Korean/English switching, mouse,
keyboard/Escape focus behavior, visible focus states, and the compact 960x540
viewport. The browser console contained no UI warnings or errors. The exact
task-owned server PID `23816` was stopped and the port was confirmed clean.

Upgrade, report, result, and Garage were not naturally triggered during the
built-Web interaction path. Their production scene behavior is covered by the
complete deterministic capture matrix and focused validators rather than an
interactive Web claim.

## 2026-08-04 Final 49-asset visual replacement acceptance

The visual replacement program completed on clean runtime/art commit
`138642ec7595d99c039513dd6dbe1b7d77dfb1d7`. This checkpoint supersedes older
asset-count and remaining-switch statements in this append-only record.

### Reconciled output

- Production contains exactly 49 gameplay PNGs: 47 authored replacements and
  two reused files. It contains zero authored HUD/cue PNGs and one authored
  effect PNG, the EMP release.
- The ten applied units and six keep/retire-only units reconcile with the
  workbench. The exact 177 legacy PNGs and their 177 literal sidecars were
  retired after a zero-consumer scan.
- All projectile behavior resolves through `projectile/energy_teardrop`; all
  experience values use `pickup/experience_master` with runtime scale; repair
  and overdrive use complete circular-pad PNGs with distinct function glyphs.
- Minimap semantics are exactly player, item, enemy, and boss. Defense/status
  raster overlays and non-EMP effect frames remain absent.
- Gameplay manifest SHA-256:
  `0105d9f1675aa61bf4506ed706f9cde052d539828239a04af2bb097f41858816`.
- Workbench inventory SHA-256:
  `b3351015b9759c81e2f4d79c651a1143102e0ff9f6010e7da77381a03996a30e`.
- Comparison report SHA-256:
  `6fbcae00006abd6bac93bd964912f958d2c0ae26967f9d16e839d7d243cd9794`.
- Canonical style-reference SHA-256:
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.

### Structural and rendered evidence

- Workbench build/check, visual-authority validation, workbench validation,
  Godot import, `git diff --check`, and all 20 focused visual/runtime validators
  passed. The final workbench result is `units=16`, `current=49`, `final=49`,
  `authored=47`, `retired=0`, with statuses `keep_current=2`, `applied=8`, and
  `retired=6`.
- Capture root: `build/captures/visual-final/`. Korean 1280x720 contains the
  complete 77-capture set. Korean/English 960x540, 1280x720, and 1920x1080 plus
  Korean/English 960x540 at 200% text each contain the expected 30 core
  captures and a matching manifest.
- Manual review covered deployment, upgrade cards, pause, peak horde, pickups,
  EMP, boss/node states, HUD, four-role minimap, Korean/English, and 200% text.
  Scrollable compact content remained reachable, fixed actions remained visible,
  and no unintended overflow or missing raster was found.
- `tools/export_web.ps1` passed. The built game was served through the Codex
  lane on `127.0.0.1:13029`; Chrome loaded every core Web resource with HTTP
  200, reached deployment and live gameplay, and reported no console warning or
  error. The exact task-owned server was then stopped and the port verified
  clean.
- The HTTP-served workbench loaded all 104 non-empty image sources with no
  broken source, reported 49 gameplay PNGs and zero UI PNGs, and had no
  horizontal overflow at the checked 960px viewport. No optional anomaly was
  recorded.

### Visual performance and separate release gap

`build/performance/visual-final/peak-horde.json` is an authoritative clean run
for commit `138642ec7595d99c039513dd6dbe1b7d77dfb1d7`. Visual thresholds passed:
draw-call p95 was `122 <= 200`, and retained combat batches were `34 <= 50`.
The payload's overall release result remains false because frame p95 was
`140.476 ms` and physics p95 was `21.32 ms`. That previously recorded
frame/physics gap is owned by the separate pre-asset stabilization plan and does
not invalidate this visual replacement acceptance.

Task-scoped quality review found and closed the final competing effect/status
catalog ownership, stale tier-specific XP batch, missing circular-pad raster
assertion, and missing shared-XP-batch assertion. No remaining task-scoped
quality finding was accepted as open.

## 2026-08-07 minimal combat-cue checkpoint

Commit `b9e66b86` centralized combat-cue visibility in one presentation-only
policy without changing attack geometry, damage, collision, cadence, or
encounter rules. Visible projectile sources now rely on muzzle feedback and the
actual projectile. A short world path is limited to an off-screen startup or
live hostile projectile entering the viewport. Area, charge, and beam warnings
retain only their exact outer boundary family. The threat radar no longer
duplicates general enemy presence from the minimap and contains only an unseen
committed projectile attack, the active boss objective, or boss arrival.

Focused attack-route, combat-renderer, run, attack-contract, HUD,
capture-driver, and visual-authority validation passed under Godot 4.7.1. The
full Korean 1280×720 capture set contains 78 files at
`build/captures/combat-cues-minimal-20260807/`. Manual review covered threat
radar, hostile projectile startup and flight, the exact area boundary, charge
boundaries, and representative boss startup/active states. No missing essential
cue or restored decorative path was found.

Full import and `tools/export_web.ps1` passed. The built output loaded through
the registered Codex Web lane at `127.0.0.1:13029`; its document, image,
JavaScript, WASM, PCK, icon, and blob requests returned HTTP 200, the deployment
screen rendered, and Chrome reported no warning or error. The exact task-owned
server was stopped and port 13029 was verified clean. This checkpoint is
functional and visual evidence only; it does not qualify performance.

## 2026-08-10 combat, upgrade, and area-effect integrity checkpoint

Commit `0d220ae2604dd62110badd07fd584a8a0bfa41b5` contains the final feature
checkpoint for the active combat-integrity plan. Nineteen focused upgrade,
contact, reinforcement, area-effect, capture, fixed-capacity, and performance-
structure validators passed. Godot import, visual authority, and Web export also
passed. The built Web product loaded through the guarded Codex lane, switched
from Korean to English, rendered the complete EMP footprint, and produced an
ordinary collision/melee failure receipt without browser warnings or errors.

The exact-radius runtime evidence is under
`build/evidence/execplan-2026-08-10-area-effects/`. It contains color and
grayscale sheets for Electric Field levels 1-3, EMP charge/release in standard
and reduced motion, Thermal Burst and Drop Mine levels 1-3, all four Mystery
outcomes, boss circular startup/active, and beam startup/active. The production
EMP and other production raster bytes were not changed. The unchanged 128x128
cue disk now records its measured visible-alpha `content_rect` of
`Rect2i(7, 6, 113, 115)` so the retained mesh normalizes visible content to the
gameplay radius. Runtime effect capacity remained `96`; the peak and capacity
fixtures held `48` and `96` effects with zero capacity rejection.

### Final native qualification

The clean native 1280x720 `gl_compatibility` pair used 10 seconds of warmup and
60 seconds of sampling per scenario. Both payloads are workload-valid,
authority-eligible, focused, and tied to the exact clean commit. Neither passed
the native release thresholds:

| Scenario | Median / 1% low FPS | Frame p95 / p99 | Physics p95 | Enemies + grid p95 | Contact p95 | Combat/effects p95 | Draw p95 / batches | Render CPU / GPU |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `peak_horde` | `19.09 / 8.18` | `82.86 / 116.84 ms` | `17.86 ms` | `11.84 ms` | `0.584 ms` | `2.72 ms` | `89 / 41` | `0.60 / 1.61 ms` |
| `capacity_pressure` | `7.50 / 6.73` | `144.44 / 147.50 ms` | `22.54 ms` | `14.17 ms` | `0.680 ms` | `5.12 ms` | `100 / 41` | `0.58 / 1.70 ms` |

Native rendering budgets remained green: draw-call p95 stayed below `200`,
combat batches stayed below `50`, and GPU time stayed below `1.70 ms`. The new
contact owner was not the dominant named section. The larger named cost was
`enemies_and_grid`, while measured-work medians of `17.17/21.02 ms` caused
physics catch-up and frame medians of `52.38/133.33 ms`. Wait-or-unattributed
medians were also material at `35.21/112.31 ms`; this evidence does not by
itself select a safe implementation change.

The plan intentionally collected no comparable pre-change baseline, so these
results do not prove that the combat-integrity changes caused or avoided a
regression. They diagnose the final workload only. The full-area effect body is
not identified as the measured owner, and no visual quality, gameplay workload,
collision, cadence, capacity, or threshold was reduced to manufacture a pass.

### Built-Web diagnostic and remaining manual trace

The built-Web `peak_horde` fixture produced the correct workload and exact
60-second payload, but the connected automation browser identified itself as
`HeadlessChrome` and the recorder reported `authority_eligible=false` and
`scheduler_throttled=true`. Its `7.50` median FPS and `6.68` 1% low are retained
only as an ineligible diagnostic; they are not a Web release-performance claim.
The exact ignored payloads are:

- `build/performance/combat-upgrade-effect-integrity/0d220ae2-peak_horde-60s.json`
- `build/performance/combat-upgrade-effect-integrity/0d220ae2-capacity_pressure-60s.json`
- `build/performance/combat-upgrade-effect-integrity/0d220ae2-web-peak-horde-60s.json`

A normal-play manual trace was launched only after all fixes and final synthetic
tests. No user gameplay or normal close occurred during the bounded wait, so no
manual JSON was produced and no synthetic input was substituted. The user-
reported slow period still requires one user-driven normal-play trace before
the active plan's performance task can close.

## 2026-08-10 code-native combat-primitive checkpoint

Commits `3c166a03e6924f917a4dafd12acfa863ddb6dd2e` and `639e4532` retire the
nine production PNGs whose only runtime job was geometry and color. Dynamic
disks, rings, beam corridors, health rectangles, and diamond markers now use
startup-built retained meshes; the Transit Gate ring and Repair Tender beam use
code-native arc/line drawing. The EMP, Thermal Burst, and Drop Mine raster
accents and the two dedicated transient raster batches are absent. Gameplay
centers, radii, recipients, timing, batch capacities, and boss behavior remain
unchanged.

The revised manifest contains 63 production images: 60 semantic PNGs and three
approved `SurfaceDetail` SVGs. It contains zero cue, EMP, Thermal Burst, or Drop
Mine raster IDs. The retirement unit preserves all 18 deleted paths and their
provenance in the workbench; git history and the prior TO-BE copies remain the
recovery path.

### Revised rendered and build evidence

- All 12 contract validators, visual-authority validation, Godot import, and
  `git diff --check` passed after the renderer change. Workbench build/check and
  validation also pass with 24 units, 60 current PNGs, 63 production images,
  and seven retire-only units.
- The native capture root is
  `build/captures/execplan-2026-08-10-procedural-v1/` and contains 115 captures.
  The consolidated 24-case color and grayscale sheets are under
  `build/evidence/execplan-2026-08-10-procedural-area-effects/`.
- Review confirmed continuous center-to-boundary bodies for Electric Field,
  Thermal Burst, Drop Mine, EMP, all four Mystery outcomes, boss circular
  footprints, and beam corridors. EMP charge/release shows the complete inner
  `285` damage/stun disk and outer `325` projectile-clear disk immediately; it
  does not show an outward wavefront or authored octagon.
- `tools/export_web.ps1` returned `WEB_EXPORT_OK` and produced the four required
  files. The built artifact ran on the guarded Codex lane at
  `127.0.0.1:13029`, switched Korean to English, entered live gameplay, showed
  the complete EMP charge footprint, and recorded ordinary collision/melee
  damage in the failure report. Chrome reported only the Godot/WebGL startup
  logs, with zero warnings or errors. The exact task-owned Python server was
  stopped and port `13029` was verified free.

The native and Web performance payloads in the preceding checkpoint predate
this renderer input and remain historical only. A clean final qualification is
required before issuing a current performance label.
