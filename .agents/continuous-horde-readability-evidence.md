---
type: evidence
status: active
owner: BK
created: 2026-07-29
last_reviewed: 2026-07-29
topic: Continuous multi-sector horde, combat readability, and stage-transition implementation
scope: Implemented runtime contracts, deterministic validation, Web export, diagnostic performance, and remaining technical stabilization work
source: ./execplans/2026-07-29-continuous-multidirectional-horde-readability.md
related:
  - ../docs/product/vehicle_game_spec.md
  - ../docs/design/UI_VISUAL_SYSTEM.md
  - ./vehicle-performance-stabilization-evidence.md
  - ./continuous-horde-rollout-problem-analysis.md
  - ./execplans/2026-07-29-horde-foundation-recovery-and-acceptance.md
---

# 연속 다방향 대규모 적군 구현 근거

## Purpose

2026-07-29 rollout이 실제로 변경한 behavior, 통과한 구조 검증, 진단 성능과 아직
남은 기술 한계를 과장 없이 기록한다.

## Sources

- `a9ae769..d87520b`의 task-owned implementation commits;
- current source와 `tools/validation/validate_vehicle_*.gd`;
- ignored `build/performance/2026-07-29-horde/` payload;
- `docs/product/vehicle_game_spec.md`와 `docs/design/UI_VISUAL_SYSTEM.md`;
- 후속 감사 `continuous-horde-rollout-problem-analysis.md`.

## Findings

Density, multi-sector spawn, item frequency와 continuous transition은 source와 구조
validator 수준에서 구현됐다. 하지만 production-aligned rendered evidence와
authoritative maximum-load performance/lifecycle 검증은 아직 완료되지 않았다.

## 구현 결과

| 범위 | 현재 구현 |
| --- | --- |
| 적 밀도 | hostile store와 renderer capacity 320, Hard active cap `1/124/172/224/276`, stage authored population `520/660/816/1026/1260` |
| 배치 | 모든 본 전투 packet이 네 사분면과 최소 4/8 sector를 점유하며, 한 physics tick에 due spawn을 최대 4대 처리 |
| 압력 제한 | projectile-firing mobile share 최대 15%, ranged commit 3, denial commit 2, boss용 hostile projectile 24칸 예약 유지 |
| 가독성 | player/enemy/installation/boss/pickup/XP presentation footprint 확대, hostile projectile은 collision core와 비피격 halo/trail 분리 |
| 아이템 | stage당 loose pickup 6개와 crate 8개, 최소 네 sector 분산, 기존 245 repair 총량 재분배 |
| 연속성 | Stage 1–4 성공 modal 제거, XP recall → reward → full heal → 1.2초 보호 → 같은 위치에서 다음 stage 시작 |
| 상태 보존 | player position/facing/aim, build, difficulty, exploration, cover, persistent terrain 유지 |
| 성능 구조 | movement cover/crate broadphase, bounded shield assignment, inactive status/terrain work skip, atlas family coalescing으로 최대 압력 retained combat batch 23개 |

Player base speed는 `280 px/s`, camera zoom은 `1`로 유지했다. 적 이동 속도, 개별
체력·피해, telegraph 시간, projectile 속도도 이 작업에서 상향하거나 하향하지 않았다.

## 변경 커밋

- `a9ae769` — capacity와 pressure 관측값
- `2263014` — authored population과 multi-sector spawn
- `50bd8c2` — actor/projectile/item 가독성
- `9485560` — 비모달 연속 stage transition
- `d87520b` — 280/320 workload와 hot-path/batch 최적화

## 검증

- `validate_vehicle_*.gd` 40개를 2026-07-29 현재 작업 상태에서 전부 실행했고
  `VALIDATOR_COUNT=40`으로 통과했다.
- transition validator는 Stage 1→2→3에서 위치, 체력, XP, build, difficulty,
  exploration, cover/terrain, item refresh, success modal 부재와 다음 cue/spawn
  timing을 확인한다.
- multi-sector validator는 모든 field와 bounded seed matrix에서 사분면·sector
  분산, deterministic fallback, cue lead, composition과 commit 제한을 확인한다.
- production Web export가 성공했고 `build/web/index.html`과 필수 산출물 4개를
  생성했다.

## 최대 압력 진단

로컬 Intel Iris Xe, native `1280x720`, 2초 warmup + 5초 diagnostic sample:

- workload: ordinary enemies 280, player projectiles 140, hostile projectiles 72;
- pressure: visible 240, near-600 267, near-900 270, ranged commits 3,
  denial commits 2;
- retained combat batches 23, draw-call p95 117;
- median 약 42.28 FPS, frame p95 64.84 ms, p99 76.40 ms;
- physics median 10.23 ms, p95 15.13 ms;
- presentation median 6.24 ms, p95 8.91 ms;
- scenario counts와 store/projectile capacity는 유효하지만 frame gate는 실패.

로컬 payload는 ignored 경로
`build/performance/2026-07-29-horde/smoke-current-cached.json`에 있다. 이 결과는
5초짜리 non-authoritative 진단이고 payload의 git commit attribution이 비어 있어
release authority가 없다. 목표 최대 부하가 구성되고 해당 fixture가 성능 문턱에
미달한다는 사실은 숨기지 않되, 실제 production play의 frame rate라고 해석하지
않는다.

## 2026-07-29 후속 감사 정정

후속 source/rendered 감사에서 현재 evidence가 수용 근거로 사용할 수 없는 추가
이유를 확인했다.

- `current_pressure`는 실제 multi-sector scheduler가 아니라 340px부터 적을 채우는
  수동 동심원 fixture이며, 280기 중 240기를 visible, 267기를 near-600에 둔다.
- maximum-pressure capture는 production allocator 대신 한쪽으로 긴 수동 grid를
  사용한다.
- field-item capture는 production의 6 loose pickup + 8 crate가 아니라 pickup 두
  개만 보여 준다.
- capture sequence는 실제 transition banner를 찍지 않고, 제거된 Stage 1 success
  report를 계속 생성한다.

따라서 이 문서는 “구현된 계약과 발견된 최대 fixture failure”의 현재 기록으로만
active다. 대표 플레이, 최대 몰이, capacity/lifecycle 부하를 분리하고 production과
동일한 fixture owner를 쓰는 작업은
`execplans/2026-07-29-horde-foundation-recovery-and-acceptance.md`가 이어받는다.

## 2026-07-29 최대 부하 recovery 실행 결과

후속 계획의 구현 커밋은 `bc1bbf0`, `38786dd`, `32e3305`, `20cb2b4`,
`1f6cc97`, `5d58312`, `780aa37`이다.

### Workload authority

- `current_pressure`를 제거하고 `production_replay`, `peak_horde`,
  `capacity_pressure`, `lifecycle_pressure`, `boss_pressure`를 분리했다.
- performance와 `03-peak-horde.png` capture는 seed `12886704`,
  fingerprint `2787026116`인 동일 `VehiclePressureFixture`를 사용한다.
- peak initial qualification은 active 276, visible 124, near-600 124,
  near-900 224, sector `42/29/29/42/40/27/27/40`이다.
- production replay는 synthetic enemy fill 없이 실제 Stage 5 Hard scheduler와
  입력 route를 사용한다. beat 4의 최근 10개 1초 표본에서 ordinary authored
  reserve 1260, active cap 276, median active 276, 최소 요구 249, 4사분면과
  8 sector, 최대 allocation sector 비중 19.53%, ranged commit 3,
  denial commit 1, enemy capacity rejection 0으로 qualification을 통과했다.

### Simulation and presentation

- `VehicleEnemyUpdateSchedule`이 한 tick의 active/support/critical/due workset과
  active-cap, commit, rammer, carrier counter를 한 번에 만든다.
- ordinary decision은 10 Hz, near/far motion은 30/20 Hz이며 startup, active,
  interrupted recovery와 boss/special path는 60 Hz를 유지한다.
- actor-owned elapsed 값은 pool reuse 때 0으로 초기화된다. rammer/carrier의
  per-enemy full-array helper scan은 제거됐다.
- 276체 기준 `enemy_behavior_and_motion` p95는 초기 6.62ms에서 후속 표본
  4.88–5.88ms로 낮아졌다.
- ordinary body는 모두 남기면서 health bar 12개와 extra priority marker 8개로
  제한했다. visible retained instances는 초기 1,233개에서 964–978개로 줄었다.
- 별도 60/30 Hz retained channel 구현 세 가지는 presentation p95를
  10.82–13.85ms로 악화시켜 전부 제거했다. 현재 source에 channel split은 없다.

### Verification and limits

- Godot import와 `tools/validation/validate_*.gd` 43개가 모두 통과했다.
- production Web export가 필수 네 파일을 생성했고, fastrun-manager Codex lane의
  built-Web smoke가 1280×720에서 부팅되어 console error 없이 peak workload를
  완료했다. 해당 Chrome은 headless scheduler-throttled였으므로 Web frame 수치는
  release evidence가 아니다.
- production replay 20초 진단은 median 60 FPS, frame p95 16.67ms였지만
  1% low 50.65 FPS로 55 FPS gate를 통과하지 못했다.
- 276체 peak 후속 표본은 median 43.56–46.15 FPS, frame p95
  26.67–42.23ms, physics p95 10.70–14.00ms였다. workload는 유효하지만
  native release gate는 실패했다.
- capacity 진단은 320 enemies, 240/120 projectiles, 192 shards와 96 effects를
  정확히 유지하고 enemy capacity rejection 0으로 무결성을 통과했다. 그러나
  physics p95 15.52ms, p99 18.09ms로 6/8ms timing gate를 실패했다.
- timing gate가 이미 반복 실패했으므로 성공을 가장하는 10분 soak와 전체
  native/Web 60초 matrix는 실행하지 않았다. QA package는 ignored
  `build/evidence/horde-recovery/qa-package/`에 있다.

## 남은 기술 조건

- 276기 peak frame p95와 320 capacity physics p95/p99를 현재 threshold까지
  낮추는 다음 architecture batch;
- 그 batch가 3회 retention rule을 통과한 뒤 clean commit에서 native/Web
  3회 60초 matrix와 10분 lifecycle soak;
- subjective 재미·압박감·성장 만족도는 별도 사용자 QA feedback으로 평가.

계획이 금지한 density, player speed, camera zoom, physics rate, resolution 축소는
성능 fallback으로 사용하지 않았다. 위 항목이 끝나기 전에는 이 evidence와 원본
ExecPlan의 lifecycle status를 `complete`로 바꾸지 않는다. 재미, 압박감, 난이도
체감과 사용자 승인은 이 technical completion의 증거 또는 gate가 아니다.
