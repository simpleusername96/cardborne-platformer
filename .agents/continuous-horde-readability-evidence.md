---
type: evidence
status: active
owner: BK
created: 2026-07-29
last_reviewed: 2026-07-30
topic: Continuous multi-sector horde, combat readability, and stage-transition implementation
scope: Implemented runtime contracts, deterministic validation, Web export, diagnostic performance, and remaining technical stabilization work
source: Git ranges a9ae769..d87520b and e9dc516^..529e915, final correction 8e6efa8, and the repository evidence named below
related:
  - ../docs/product/vehicle_game_spec.md
  - ../docs/design/UI_VISUAL_SYSTEM.md
  - ./vehicle-performance-stabilization-evidence.md
  - ./continuous-horde-rollout-problem-analysis.md
  - ./execplans/2026-07-29-horde-foundation-recovery-and-acceptance.md
  - ./execplans/2026-07-30-approved-sheet-fidelity-recovery.md
---

# 연속 다방향 대규모 적군 구현 근거

## Purpose

2026-07-29 rollout이 실제로 변경한 behavior, 통과한 구조 검증, 진단 성능과 아직
남은 기술 한계를 과장 없이 기록한다.

## Sources

- `a9ae769..d87520b`의 task-owned implementation commits;
- final visual build correction `8e6efa8`;
- current source와 `tools/validation/validate_vehicle_*.gd`;
- ignored `build/performance/2026-07-29-horde/` payload;
- ignored `build/performance/visual-system-retention/`의 paired 3×20초 payload;
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

## 2026-07-30 최종 비주얼 빌드 성능 판정

사용자 지시에 따라 asset, world, combat visual, HUD와 modal publication 및
legacy retirement를 모두 마친 뒤에만 최종 성능 gate를 실행했다. 측정 전
worktree는 commit `8e6efa8`에서 clean이었고 Godot `4.7.1`, Windows,
Intel Iris Xe, native GL Compatibility, 1280×720를 사용했다. 모든 표본은
foreground/focus 유지, scheduler unthrottled, 5초 warmup + 20초 sample이다.
20초 focused comparison이므로 payload의 `authoritative` 값은 의도대로
`false`다.

### Final bounded correction

`8e6efa8`은 gameplay value를 바꾸지 않고 다음 runtime work만 제한했다.

- minimap은 9개 semantic color channel의 fixed-capacity retained
  `ArrayMesh`를 유지하고 vertex region만 갱신한다. unchanged snapshot은
  rebuild·redraw하지 않는다.
- HUD는 responsive layout, health mesh와 action slot state를 실제 변화가 있을
  때만 갱신한다. action cooldown만 bounded dynamic arc로 남긴다.
- combat renderer allocation은 작은 initial capacity에서 기존 maximum까지만
  bounded growth한다.
- boss/special/critical path는 60Hz를 유지하고 ordinary enemy decision/motion만
  schedule worklist와 accumulated delta를 사용한다.

Godot import와 `tools/validation/validate_*.gd` 46개가 통과했고, Web export,
fastrun-manager Codex lane의 production build smoke, 960×540/1280×720/
1920×1080 canvas sizing, gameplay 진입과 ko/en 전환이 통과했다. console
warning/error는 0이었다.

### Paired focused results

| Payload | Workload valid | Frame median / p95 / p99 | 1% low / median FPS |
| --- | ---: | ---: | ---: |
| `peak-horde-01.json` | yes | `133.243 / 142.327 / 147.196ms` | `6.730 / 7.505` |
| `peak-horde-02.json` | yes | `40.073 / 132.269 / 142.295ms` | `6.926 / 24.954` |
| `peak-horde-03.json` | yes | `50.000 / 92.349 / 125.634ms` | `7.503 / 20.000` |
| `production-replay-01.json` | no | `16.667 / 16.667 / 16.667ms` | `59.901 / 60.000` |
| `production-replay-02.json` | no | `16.667 / 16.667 / 16.667ms` | `60.000 / 60.000` |
| `production-replay-03.json` | no | `16.667 / 16.667 / 22.131ms` | `36.288 / 60.000` |

세 peak 표본은 seed `12886704`, fingerprint `2787026116`, live enemy 276,
player projectile 140, hostile projectile 72, all-sector fixture qualification을
모두 유지했다. 세 표본 median 기준 physics p95 `19.831ms`,
enemy behavior p95 `8.055ms`, presentation p95 `9.578ms`, HUD p95
`4.125ms`, draw-call p95 `192`, combat batch `50`이다.

clean Phase 1 peak baseline
`build/performance/recovery/phase1-peak-horde-01.json`의 frame p95
`26.790ms`와 비교하면 final 세 표본 median은 `132.269ms`, 즉
`+393.7%`다. 같은 비교에서 physics `+64.9%`, enemy behavior `+21.6%`,
presentation `+35.4%`, HUD `+251.7%`다. target subsystem 최소 10% 개선과
frame p95 최대 5% 악화라는 retention rule을 통과하지 못한다.

세 production replay는 frame median과 p95가 모두 `16.667ms`였지만,
qualification sample이 매번 0이었다. final active 195는 각 payload의
minimum 202보다 작고 median active는 0으로 기록되어 세 workload가 모두
invalid다. 따라서 좋은 frame 수치를 release 또는 paired retention
근거로 사용할 수 없다. clean Phase 1 production baseline 대비 세 표본
median은 physics p95 `+11.0%`, behavior p95 `-5.7%`, presentation p95
`+58.9%`, HUD p95 `+184.0%`다.

payload의 `git.dirty`는 모두 `false`지만 `git.commit` 문자열은 비어 있다.
shell에서 clean `8e6efa8`을 확인한 실행 기록과 함께 focused diagnosis로는
사용하되, 이것도 authoritative release proof로 승격하지 않는다.

### 판정

한 번 허용된 final in-architecture correction 뒤 같은 paired retention gate가
다시 실패했다. 따라서 ExecPlan 5.6의 predetermined stop을 적용해
3×60초 native/Web matrix, `capacity_pressure`와 600초 lifecycle soak를
실행하지 않았다. 실패한 표본을 평균으로 숨기거나 density, speed, scale,
collision, resolution, threshold를 낮추지 않았다.

## 2026-07-30 승인 시안 복구 빌드 재측정

승인 시안 충실도 복구는 `e9dc516^..529e915`에서 algorithmic field tile,
player/enemy/boss recipe, projectile/effect, reward/facility, Upgrade UI,
HUD/minimap와 모든 modal을 교체하고 production sheet 12개를 재생성했다.
성능 측정은 ko/en × 960/1280/1920 runtime visual acceptance, 48개
non-performance validator, Godot import와 built-Web smoke를 끝낸 뒤
마지막에만 실행했다. 측정 직전 task-owned baseline은 clean commit
`529e915`였다.

Godot 4.7.1, Windows, Intel Iris Xe, native GL Compatibility, 1280×720에서
2초 warmup + 20초 sample로 `peak_horde`와 `production_replay`를 각각
3회 실행했다.

| Payload | Workload valid | Active | Median / 1% low FPS | Frame p95 / p99 | Draw p95 | Batches |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `peak_horde-01.json` | yes | 276 | `7.500 / 6.837` | `142.868 / 145.848ms` | 308 | 50 |
| `peak_horde-02.json` | yes | 276 | `7.490 / 6.762` | `142.756 / 147.275ms` | 308 | 50 |
| `peak_horde-03.json` | yes | 276 | `7.556 / 6.780` | `143.987 / 147.154ms` | 308 | 50 |
| `production_replay-01.json` | no | 192 | `60.000 / 29.704` | `27.778 / 31.786ms` | 299 | 50 |
| `production_replay-02.json` | no | 192 | `59.001 / 27.962` | `25.000 / 30.274ms` | 298 | 50 |
| `production_replay-03.json` | no | 192 | `60.000 / 27.885` | `25.378 / 33.333ms` | 299 | 50 |

세 peak 표본은 live enemy 276과 fixture qualification을 유지했지만 frame
p95 약 143ms, draw-call p95 308로 release threshold를 반복 실패했다. 세
production replay는 final active 192, qualification sample 0, median active
0으로 minimum active 202를 충족하지 못해 workload가 invalid다. 이 수치는
frame rate가 좋아 보여도 release evidence로 사용할 수 없다.

20초 focused comparison이므로 여섯 payload의 `authoritative`는 모두
`false`다. 결과는 ignored 경로
`build/performance/approved-visual-final-retention/`에 있다. 선행 paired
gate가 반복 실패했으므로 full 3×60초 native/Web matrix, 320 capacity,
boss scenario와 lifecycle soak는 실행하지 않았다. 승인된 asset/UI를
되돌리거나 density, resolution, quality와 threshold를 낮추는 방식도
사용하지 않았다.

## 남은 기술 조건과 권한 경계

- 현재 plan 안에서 두 번째 automatic optimization batch를 시작하지 않는다.
- BK가 새로운 performance architecture 범위 또는 acceptance contract를 명시한
  뒤에만 다음 correction을 설계한다.
- 새 범위가 승인되면 먼저 final `production_replay` qualification을 복구하고
  paired 3×20초 retention을 통과해야 한다. 그 뒤에만 clean commit에서
  native/Web 3회 60초 matrix와 10분 lifecycle soak를 실행한다.
- subjective 재미·압박감·성장 만족도는 별도 사용자 QA feedback으로 평가.

계획이 금지한 density, player speed, camera zoom, physics rate, resolution 축소는
성능 fallback으로 사용하지 않았다. 위 항목이 끝나기 전에는 이 evidence와 원본
ExecPlan의 lifecycle status를 `complete`로 바꾸지 않는다. 재미, 압박감, 난이도
체감과 사용자 승인은 이 technical completion의 증거 또는 gate가 아니다.
