# Semantic V2 runtime asset pack

이 디렉터리는 Cardborne gameplay raster asset의 현재 runtime pack이다.
`scripts/presentation/components/vehicle_semantic_asset_provider.gd`가
[`asset-manifest.json`](./asset-manifest.json)을 읽어 texture, mesh, pivot과
attachment metadata를 제공한다.

## Ownership

- `actors/`, `effects/`, `hud/`, `pickups/`, `states/`, `weapons/`, `world/`의
  runtime PNG와 atlas가 이 pack의 배포 대상이다.
- manifest와 provider는 asset identity와 presentation metadata만 소유한다.
- collision, navigation, damage, targeting, encounter와 state transition은
  기존 gameplay owner가 계속 소유한다.
- floor와 wall PNG는 현재 provider에 연결되지 않는다. procedural field
  surface와 wall renderer가 현재 runtime truth다.

과거 생성 source, review sheet와 prompt는 runtime contract가 아니다. 필요할
때는 Git history에서 복구하며 shipping tree에 중복 보관하지 않는다.

## Change contract

- 방향성 asset의 authored facing은 `+X/right`다.
- runtime PNG는 pivot 안정성을 위해 자동 trim하지 않는다.
- image geometry가 collision truth를 바꾸지 않는다.
- projectile core와 live telegraph footprint는 gameplay geometry와 일치해야
  하며 tail/effect는 non-damaging presentation이다.
- asset ID나 path를 바꿀 때는 provider consumer와 manifest validator를 같은
  change에서 갱신한다.

## Validation

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_semantic_asset_provider.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_semantic_visual_separation.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_visual_asset_coverage.gd
```
