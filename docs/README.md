# Cardborne Documentation

이 문서는 현재 Cardborne의 권위 문서로 가는 짧은 색인이다. 제품 요구사항을
여기에 중복해서 정의하지 않는다.

## Authority

| Order | Document | Role |
| ---: | --- | --- |
| 1 | `../AGENTS.md` | Repository operating guidance. |
| 2 | `product/vehicle_game_spec.md` | Canonical current gameplay contract. |
| 3 | `product/ordinary_enemy_behavior.md` | Canonical default ordinary-enemy movement and attack ownership. |
| 4 | `product/vehicle_upgrade_catalog.md` | Canonical live upgrade catalog and effect values. |
| 5 | `docs/design/VISUAL_SYSTEM.md` + `docs/design/cardborne-universal-art-style-reference.png` | Mandatory visual authority pair: the binding text contract and its style-only visual reference. |

그 밖의 문서는 active game이나 presentation을 정의하지 않는다. broad
governance 또는 multi-file planning 작업은 root `AGENTS.md`의 지시에 따라
`.agents/AGENTS.md`와 `.agents/PLANS.md`도 읽는다.

## Visual Replacement Workbench

현재 runtime AS-IS와 바로 교체 가능한 TO-BE 대상의 장부 및 검토 화면은
[`design/visual-replacement-workbench/`](./design/visual-replacement-workbench/README.md)에
있다. 이 workspace는 교체 작업의 active spec이며, gameplay 또는 visual style
정본의 권위를 대신하지 않는다.

Every visual task must run the `$cardborne-visual-authority` preflight before
analysis, generation, review, approval, or integration. The reference sheet is
mandatory style evidence, but it never approves the individual objects or layouts
shown inside it.
