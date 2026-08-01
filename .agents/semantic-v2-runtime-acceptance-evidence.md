---
type: evidence
status: active
owner: BK
created: 2026-07-31
last_reviewed: 2026-08-02
topic: Semantic-v2 runtime integration, UI acceptance, boss guidance, and final performance
scope: Non-map semantic-v2 runtime switch and its post-acceptance validation
related:
  - ../docs/design/UI_VISUAL_SYSTEM.md
  - ../docs/product/vehicle_game_spec.md
  - ../art/gameplay/semantic-v2/README.md
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
- `tools/validation/`의 53개 focused validator
- `build/web/index.html`을 포함한 Godot production Web export

`build/` 아래 파일은 local ignored evidence다. 아래 표에 payload 이름과
핵심 수치를 남겨 repository 문서만 읽어도 통과 여부를 알 수 있게 한다.

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
