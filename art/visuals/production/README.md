# Production visual assets

이 디렉터리는 Cardborne의 현재 gameplay visual pack과 code-native UI 시각
기반을 소유한다.
art direction과 state grammar의 정본은
[`docs/design/VISUAL_SYSTEM.md`](../../../docs/design/VISUAL_SYSTEM.md)이며, 이
README는 production 파일의 ownership과 integration 계약만 설명한다.

## Ownership

- `gameplay/`은 gameplay PNG와 `asset-manifest.json`을 소유한다.
- `ui/`는 code-native Theme, font와 font license만 소유한다. UI chrome PNG,
  UI manifest와 UI asset provider는 사용하지 않는다.
- gameplay manifest/provider는 gameplay asset identity와 presentation
  metadata를 소유하고, UI Theme와 shared component factory는 UI chrome을
  소유한다.
- collision, navigation, damage, targeting, encounter와 state transition은
  기존 gameplay owner가 계속 소유한다.
- gameplay floor와 wall PNG는 현재 provider에 연결되지 않는다. procedural field
  surface와 wall renderer가 현재 runtime truth다.

과거 생성 source, review sheet와 prompt는 runtime contract가 아니다. 필요할
때는 Git history에서 복구하며 shipping tree에 중복 보관하지 않는다.

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
