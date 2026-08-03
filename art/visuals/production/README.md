# Production visual assets

이 디렉터리는 Cardborne의 현재 gameplay visual pack과 code-native UI 시각
기반을 소유한다.
art direction과 state grammar의 정본은
[`docs/design/VISUAL_SYSTEM.md`](../../../docs/design/VISUAL_SYSTEM.md)이며, 이
README는 production 파일의 ownership과 integration 계약만 설명한다.

## Ownership

- `gameplay/`은 현재 gameplay PNG와 `asset-manifest.json`을 소유한다. 진행
  중인 rationalized Phase 6 migration이 끝나면 모든 독립된 world object와
  유일한 대형 EMP effect의 authored raster만 남고, manifest는 실제 raster
  파일만 색인하며 code-native semantic ID에 가짜 path를 만들지 않는다. 그
  전에는 기존 manifest/provider가 current runtime truth다.
- `ui/`는 code-native Theme, font와 font license만 소유한다. UI chrome PNG,
  UI manifest와 UI asset provider는 사용하지 않는다.
- 최종 gameplay manifest/provider는 player, enemy, boss, secondary,
  projectile, defense/status, pickup/reward, facility/world state와 EMP authored
  raster identity 및 presentation metadata를 소유한다. HUD/minimap/combat cue,
  live telegraph/beam/radius boundary와 작은 직접 피드백만 책임별 shared
  code-native catalog가 소유하고, UI Theme와 shared component factory는 UI
  chrome을 소유한다.
- collision, navigation, damage, targeting, encounter와 state transition은
  기존 gameplay owner가 계속 소유한다.
- gameplay floor와 wall PNG는 현재 provider에 연결되지 않는다. procedural field
  surface와 wall renderer가 현재 runtime truth다.

과거 생성 source, review sheet와 prompt는 runtime contract가 아니다. 필요할
때는 Git history에서 복구하며 shipping tree에 중복 보관하지 않는다.
외부 source pack에서 선별한 원본도 review workbench에만 보관한다. license,
official URL, archive/file hash와 intended adaptation을 기록하고, Cardborne
palette/camera/pivot/detail contract로 정규화한 승인 PNG만 이 production tree로
승격한다.

## Format and import contract

- runtime PNG는 pivot 안정성을 위해 자동 trim하지 않는다.
- PNG import는 linear filtering, no mipmaps, no repeat 계약을 유지한다.
- image geometry는 collision, navigation, damage 또는 state truth를 소유하지
  않는다.
- gameplay asset ID나 path를 바꿀 때는 provider consumer와 gameplay manifest
  validator를 같은 change에서 갱신한다. UI chrome 변경은 Theme, shared
  component factory와 UI component validator를 함께 갱신한다.
- production 파일을 preview, sheet, prompt 또는 unapproved TO-BE output으로
  사용하지 않는다.

## Validation

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_semantic_asset_provider.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_semantic_visual_separation.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_visual_asset_coverage.gd
```
