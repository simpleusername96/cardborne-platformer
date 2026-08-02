---
type: evidence
status: active
owner: BK
created: 2026-08-02
last_reviewed: 2026-08-02
topic: Complete runtime visual asset inventory and AS-IS/TO-BE review
scope: Current runtime visual ledger plus selectively restored historical review candidates
source: Git snapshot 9b309ce
related:
  - ../UI_VISUAL_SYSTEM.md
  - ../../product/vehicle_game_spec.md
  - ../../../.agents/semantic-v2-runtime-acceptance-evidence.md
---

# Visual Asset Inventory

## Purpose

[`index.html`](./index.html)은 Cardborne의 현재 runtime visual asset 전수
장부와, 실제 이미지가 만들어진 항목의 AS-IS/TO-BE 비교를 한 화면에서
검토하기 위한 evidence workspace다.

## Sources

- 현재 AS-IS: `art/gameplay/semantic-v2/asset-manifest.json`,
  `art/ui/production/semantic-v2/ui-asset-manifest.json`, 실제 runtime 파일
- 복원된 비교 데이터와 후보: Git commit `9b309ce`
- 현재 미적용 후보 연결: `current-review-overrides.json`과
  `review-images/candidates/player-vehicle-v1/`의 기체 시트 3종
- 현재 디자인 정본: [`UI_VISUAL_SYSTEM.md`](../UI_VISUAL_SYSTEM.md)
- 현재 제품 정본: [`vehicle_game_spec.md`](../../product/vehicle_game_spec.md)

## Findings

- `inventory.json`과 HTML은 runtime raster 296개와 font 1개, 별도 staged
  map raster 8개를 포함한 305-record 장부를 제공한다.
- 기존 보고서가 실제로 화면에 표시하던 누락 이미지 41개를 복원하고, 현재
  검토용 player vehicle 후보 시트 3개를 더해 `review-images/`에는 44개가 있다.
- AS-IS runtime asset은 이 폴더에 복제하지 않고 현재 production 경로를
  직접 참조한다.
- TO-BE가 없거나 폐기·보류·미검토인 항목은 빈칸으로 숨기지 않고 그 상태를
  명시한다.

## Authority And Approval

이 폴더는 검토 evidence이며 정본 사양이나 승인안이 아닙니다. 복원된
`approved`, `hold`, `revise`, `unreviewed` 판단은 그대로 보존하고, 현재
오버레이가 추가한 기체 후보는 `개별 승인 전·미적용`으로 별도 표시한다.
이미지가 존재한다는 사실만으로 runtime 적용 승인을 뜻하지 않는다. player
vehicle 시트도 art style만 승인된 상태이며 sheet 안의 개별 silhouette,
module과 marker는 개별 asset 승인 전이다. 충돌 시 root `AGENTS.md`,
`vehicle_game_spec.md`, `UI_VISUAL_SYSTEM.md` 순서가 우선한다.

## Refresh And Verification

선별 복원물과 현재 검토 오버레이를 결정적으로 다시 연결하려면:

```powershell
.\tools\design\restore_visual_asset_inventory.ps1
```

링크, embedded JSON, current ledger hash와 표시 이미지 누락을 검증하려면:

```powershell
.\tools\validation\validate_visual_asset_inventory.ps1
```

## Limitations

- 보고서의 후보 판단은 2026-08-01 snapshot이다. 이후 정본에 반영된 결정과
  현재 `current-review-overrides.json`의 미적용 후보를 구분하기 위해 상단
  복원 배너와 개별 상태 label을 함께 읽어야 한다.
- source-generation 원본, 중복 approval HTML, 과거 CSV, superseded 계획서는
  보고서를 열고 검증하는 데 필요하지 않아 복원하지 않았다.
- 보고서의 `provider reachable`은 특정 gameplay 상태에서 실제 draw됐다는
  증거와 동일하지 않다. runtime 수용 결과는 관련 acceptance evidence를
  함께 확인한다.
