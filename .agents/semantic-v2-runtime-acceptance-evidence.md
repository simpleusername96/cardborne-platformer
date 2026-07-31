---
type: evidence
status: active
owner: BK
created: 2026-07-31
last_reviewed: 2026-07-31
topic: Semantic-v2 runtime integration, UI acceptance, boss guidance, and final performance
scope: Non-map semantic-v2 runtime switch and its post-acceptance validation
source: ./execplans/2026-07-30-semantic-visual-world-boss-performance-rework.md
related:
  - ../docs/design/UI_VISUAL_SYSTEM.md
  - ../docs/product/vehicle_game_spec.md
  - ../art/gameplay/semantic-v2/README.md
  - ./vehicle-performance-architecture-audit.md
---

# Semantic-v2 Runtime Acceptance Evidence

## Purpose

승인된 `semantic-v2` 이미지 팩의 runtime 연결, 전체 UI 교정, 공격 표시,
보스 피해·목표 안내와 그 뒤에 수행한 성능 안정화 결과를 기록한다. 이
문서는 구현 결과와 미통과 gate를 함께 보존하는 evidence이며 새로운
gameplay나 release policy를 만들지 않는다.

## Sources

- `art/gameplay/semantic-v2/asset-manifest.json`과 runtime semantic asset
  provider
- `build/captures/semantic-v2-acceptance/ko-1280-final2/`의 최종 native
  capture matrix
- `build/performance/semantic-v2-final/`의 final performance JSON
- `tools/validation/`의 52개 focused validator
- `build/web/index.html`을 포함한 Godot production Web export

`build/` 아래 파일은 local ignored evidence다. 아래 표에 payload 이름과
핵심 수치를 남겨 repository 문서만 읽어도 통과 여부를 알 수 있게 한다.

## Findings

### 구현 및 시각 검수

- non-map actor, boss/module, secondary, defense, projectile, status, effect,
  pickup, facility, HUD/minimap와 upgrade glyph가 하나의 manifest-backed
  provider를 소비한다. floor/wall map surface는 이번 범위에서 제외했다.
- player engine은 hull rear socket에 고정되고 aim mount만 manual aim을
  따른다. dash는 directional start/afterimage를 사용하며 danger radial을
  만들지 않는다.
- projectile은 `0.36 s` short lead, charge는 locked capsule, beam만
  full-path corridor, area와 support는 각 footprint/lifecycle을 사용한다.
- boss core는 `SEALED 0.20×`, `OPEN 1.55×/5 s`, `STABLE 1.00×`이며 HP
  floor나 objective lock 때문에 damage가 0이 되지 않는다. active module
  ID/state/health는 HUD, world cue, radar와 minimap에서 같은 snapshot을
  소비한다.
- upgrade card의 Korean/English overflow를 교정하고 deployment,
  settings, guidebook, report/result/garage와 boss practice를 같은 font,
  token과 semantic glyph 체계로 맞췄다.
- 최종 `ko-1280-final2` capture에서 peak combat, worst upgrade triplet,
  boss sealed/open/stable, all modal과 report surface를 재검토했다.
- import, 52개 focused validator, semantic coverage/separation, UI layout,
  attack, boss, pickup, spatial-grid와 integrated-run validation이 통과했다.
- Godot Web export가 성공했다. production build는 fastrun Codex lane에서
  정상 제공했지만 이 session에는 연결된 browser surface가 없어 interactive
  built-Web smoke는 수행하지 못했다.

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

### 최종 성능 결과

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
3. 연결된 browser surface가 준비되면 built Web 1280×720 smoke와 Web
   performance matrix를 실행한다.
4. capacity gate를 통과한 뒤에만 `lifecycle_pressure`의 measured interval을
   600초로 실행한다.

## Limitations

- map tile compiler, enemy coordinated tactics와 boss pattern redesign은
  이 구현과 evidence의 범위가 아니다.
- native capture는 Korean 중심이며 English/960/1920/200% text는 validator
  및 이전 rendered matrix로 확인했다.
- production replay와 boss pressure는 통과했지만 synthetic peak와
  capacity가 미통과이므로 release-wide performance 통과를 주장하지 않는다.
- interactive built-Web smoke와 600초 lifecycle soak는 수행되지 않았다.
