---
type: evidence
status: active
owner: BK
created: 2026-07-29
last_reviewed: 2026-07-29
topic: Continuous multi-sector horde, combat readability, and stage-transition implementation
scope: Implemented runtime contracts, deterministic validation, Web export, diagnostic performance, and remaining acceptance work
source: ./execplans/2026-07-29-continuous-multidirectional-horde-readability.md
related:
  - ../docs/product/vehicle_game_spec.md
  - ../docs/design/UI_VISUAL_SYSTEM.md
  - ./vehicle-performance-stabilization-evidence.md
---

# 연속 다방향 대규모 적군 구현 근거

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
짧은 dirty-worktree 진단이므로 release authority가 없지만, 목표 부하가 실제로
구성되고 성능 문턱에 미달한다는 사실은 숨기지 않는다.

## 남은 수용 조건

- Stage 1/3/5 × Easy/Normal/Hard 고정 seed 실플레이 telemetry;
- 한국어/영어, 960×540/1280×720/1920×1080, 일반/reduced-motion rendered
  capture와 grayscale/색각 simulation;
- clean commit에서 native/Web 3회 60초 matrix와 10분 lifecycle soak;
- 280기 목표를 유지한 채 frame gate를 통과시키는 추가 measured optimization.

계획이 금지한 density, player speed, camera zoom, physics rate, resolution 축소는
성능 fallback으로 사용하지 않았다. 위 항목이 끝나기 전에는 이 evidence와 원본
ExecPlan의 lifecycle status를 `complete`로 바꾸지 않는다.
