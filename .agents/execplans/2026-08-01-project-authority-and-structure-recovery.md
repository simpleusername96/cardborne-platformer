---
type: plan
status: draft
owner: BK
created: 2026-08-01
last_reviewed: 2026-08-01
scope: Cardborne source-of-truth consolidation, stale artifact retirement, and VehicleRun responsibility recovery
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../semantic-v2-runtime-acceptance-evidence.md
---

# Cardborne 권위 문서·프로젝트 구조 복구 계획

## Purpose

Cardborne의 현재 제품을 이해하고 변경하는 데 필요한 읽기 경로를 하나로
고정한다. 제품 요구사항은 `docs/product/vehicle_game_spec.md` 한 곳에서만
정의하고, 시각·UI 상세는 그 문서가 위임한
`docs/design/UI_VISUAL_SYSTEM.md` 한 곳에서만 정의한다. 나머지 문서와
에셋은 현재 실행에 필요한 구현 계약, 진행 중 승인 자료, 또는 Git 이력 중
하나로 명확히 분류한다.

이 계획은 과거 파일을 별도 `archive/` 폴더로 옮기는 계획이 아니다. 활성
트리에 둔 archive도 에이전트에게는 현재 문맥으로 보인다. 제품 계약에 이미
반영된 과거 계획·조사·증거는 Git 이력을 보존소로 사용하고 작업 트리에서
제거한다.

완료 후 새 제품 작업의 기본 읽기 순서는 다음 네 단계뿐이다.

1. `AGENTS.md`: 작업 방식과 불변조건.
2. `docs/product/vehicle_game_spec.md`: 유일한 제품·게임플레이 요구사항.
3. `docs/design/UI_VISUAL_SYSTEM.md`: 제품 문서가 위임한 유일한 시각·UI 계약.
4. 변경 대상 코드·데이터와 해당 validator: 실제 구현 truth.

`docs/README.md`는 이 순서를 안내하는 짧은 색인일 뿐 요구사항을 정의하지
않는다. broad governance 또는 multi-file planning일 때는 `AGENTS.md`의 지시에
따라 `.agents/AGENTS.md`와 `.agents/PLANS.md`를 추가로 읽는다. `.agents/`는
현재 실행 계획과 아직 해소되지 않은 acceptance evidence만 보관한다.

## Why / Context

### 결론

프로젝트 전체가 제품 규모에 비해 무조건 큰 것은 아니다. 5개 stage,
authored encounter, 다수 적·카드·보스·이중 언어 UI를 가진 게임으로서 현재
도메인 모듈 수는 설명 가능하다. 문제는 다음 세 곳에 집중되어 있다.

- **문서 권위 누수**: 제품 spec은 하나지만 시각 영역에서 두 문서가 동시에
  canonical을 주장하고, stale asset README와 manifest가 현재 runtime과 다른
  사실을 말한다.
- **완료 산출물의 잔존**: `.agents/execplans/`에 완료 2개, superseded 3개,
  draft 1개와 active 1개가 함께 있어 새 세션이 과거 방향을 현재 작업으로
  오해할 수 있다.
- **책임 집중**: `scripts/vehicle/vehicle_run.gd`가 약 6.8k physical lines,
  256개 함수이며
  run orchestration뿐 아니라 combat update, snapshot 조립, debug drawing,
  performance와 600줄 이상의 capture workflow까지 소유한다.

### 감사 범위와 확인된 사실

| 범위 | 확인 결과 | 의미 |
| --- | --- | --- |
| Git | 2026-06-30~2026-08-01 사이 reachable commit 494개, local `master`는 `origin/master`보다 88개 앞섬 | 현재 제품·시각 rewrite가 원격에 아직 공개되지 않았고 변경 밀도가 높음 |
| 제품 변화 | RPG-lite, platform/action-card, isometric/3D를 거쳐 2026-07-22 이후 vehicle five-stage run으로 수렴 | 이전 방향 자료를 활성 트리에 둘 이유가 없음 |
| 문서 | 추적 Markdown 34개, `.agents/execplans` 7개 | 파일 수보다 lifecycle과 권위 충돌이 문제 |
| 코드 | gameplay script 118개, 약 33,895줄 | 전체 모듈화는 존재하지만 `vehicle_run.gd`에 약 20%가 집중 |
| 런타임 에셋 | semantic-v2 provider와 UI Theme가 PNG를 실제 사용 | semantic-v2 전체를 legacy로 간주하면 안 됨 |
| 추적 review/source | `docs/design/component-sheets` 약 66 MiB, semantic-v2 source/sheet가 gameplay art 대부분을 차지 | 승인·생성 근거와 shipping asset을 분리해야 함 |
| 로컬 산출물 | ignored `build/` 약 491 MiB, `.codex-runtime/` 약 3.68 GiB | source truth 문제와 별개인 재생성 가능한 로컬 저장공간 문제 |
| 과거 Codex 세션 | 이 repo와 연결된 session 184개 중 root 7개, subagent 177개 | 문맥 부족보다 과도한 병렬 조사·후보 생성과 반복 계획이 churn을 키움 |
| 최대 session churn | 2026-07-29 visual thread 하나에 subagent session 85개 | 승인되지 않은 방향을 넓게 생산하기 전에 범위를 잠가야 함 |

과거 세션은 `C:\Users\BK\.codex\sessions`의 repository URL과 root payload
ID로 전수 색인했다. 대표 root thread는 2026-07-14, 07-27, 07-28 2개,
07-29, 07-31, 08-01이다. 세션 transcript 자체는 repo로 복사하지 않는다.

### 구체적인 권위 충돌

1. `docs/README.md`는 active presentation contract가
   `UI_VISUAL_SYSTEM.md` 하나라고 말하지만
   `GAMEPLAY_VISUAL_TAXONOMY.md`도 active canonical spec을 주장한다.
2. taxonomy에는 현재 product spec에 없는 poison/lava floor와
   wear/collapse tile이 포함되어 phantom requirement가 된다.
3. product spec은 UI를 `non-raster` component system으로 부르지만 현재
   visual spec과 Theme는 image-backed raster composition을 요구하고 사용한다.
4. `art/gameplay/semantic-v2/README.md`와 `asset-manifest.json`은 adapter가
   연결되지 않았고 runtime이 procedural이라고 기록하지만 provider는 이미
   manifest를 읽어 texture와 mesh를 공급한다.
5. product/design/evidence 문서의 `related` 링크가 done 또는 superseded
   ExecPlan을 계속 가리킨다.
6. `.agents/AGENTS.md`는 완료·superseded 계획을 삭제하라고 하지만 현재
   구조가 그 규칙을 위반한다.

## Assumptions

- 현재 worktree, Git history, code, data와 validators가 과거 transcript보다
  우선하는 현재 사실이다.
- `master`의 88개 ahead commit은 현재 로컬 object database에만 있다. 이는
  독립 backup이 아니며, cleanup 중 `.git` 또는 branch reference를 건드리지
  않는다는 전제에서만 복구 경로가 된다.
- provider/Theme/import reference에서 도달하는 semantic-v2 파일은 runtime
  asset으로 간주한다. source/sheet라는 폴더명만으로 삭제 대상을 결정하지
  않는다.
- deferred proposal의 상세 후보는 현재 요구사항이 아니다. 다만 “현재
  non-goal이며 재개하려면 product spec revision이 필요하다”는 activation
  guard는 product spec에 남긴 뒤 원문을 Git 이력으로 보낸다.
- visual approval candidate는 approval board의 명시적 상태가 없는 한 승인된
  것으로 간주하지 않는다.
- 이 문서에 대한 승인과 G1/G2/G3 응답 전에는 실제 삭제, refactor 또는 cache
  purge를 하지 않는다.

### 구조 판단

다음은 복잡하지만 현재 제품 책임에 맞으므로 유지한다.

- stage definition, encounter coordinator, enemy runtime/store, projectile
  store/spatial grid, card resources, combat renderer, HUD presenter,
  localization과 settings의 별도 owner.
- 41개 card resource와 5개 secondary resource.
- semantic-v2 runtime pack과 provider/manifest 경계.
- focused validator 집합과 Web export workflow.

다음은 구조상 과도하거나 잘못 배치되었다.

- `vehicle_run.gd`의 capture sequence, debug evidence setup, performance CLI
  parsing과 gameplay orchestration 혼재.
- `.agents/` 안의 완료 계획, 과거 research, 이미 반영된 evidence.
- active docs 영역의 approval proposal과 canonical spec 혼재.
- shipping asset 옆의 대용량 source/review sheet가 lifecycle 설명 없이 존재.

## Scope / Non-scope

### In scope

- 제품·시각 계약의 권위와 읽기 순서 고정.
- 현재 계약에 이미 반영된 완료·superseded 계획, research, evidence의
  승인형 제거.
- semantic-v2 README/manifest의 현재 runtime truth 복구.
- 문서 lifecycle·링크·단일 권위를 자동 검사하는 validator 추가.
- orphan UID와 빈 legacy directory shell 제거.
- 진행 중 visual approval 자료를 현재 작업 또는 Git 이력 중 하나로 정리.
- `vehicle_run.gd`의 tooling/capture 책임을 우선 분리하고 추가 비대화를 막는
  구조 gate 추가.
- 모든 구조 변경 후 full validators, native capture, Web export와 built-Web
  smoke 수행.

### Non-scope

- 게임을 새로 만들거나 engine을 바꾸는 일.
- 현재 product spec의 controls, five-stage flow, encounter, card, boss,
  localization 또는 난이도 변경.
- semantic-v2 runtime PNG의 일괄 삭제·재생성.
- 승인되지 않은 새 visual direction, enemy tactic, map type, card 또는 boss
  mechanic 도입.
- Git branch·tag 삭제, history rewrite, force push.
- 이번 계획 승인만으로 원격에 push하거나 release하는 일.
- 줄 수만 줄이기 위한 거대한 `vehicle_run.gd` 재작성.

## Locked Decisions

1. 제품 요구사항의 유일한 source of truth는
   `docs/product/vehicle_game_spec.md`다.
2. 시각·UI 상세는 별도 문서가 필요한 책임이므로 product spec에 모두
   합치지 않는다. 대신 `docs/design/UI_VISUAL_SYSTEM.md` 하나만 product
   spec의 subordinate canonical contract로 둔다.
3. `GAMEPLAY_VISUAL_TAXONOMY.md`는 행 단위로 분해한다. structural wall,
   cover, bulkhead, functional terrain과 boss objective의 collision·behavior
   계약은 product spec으로, silhouette·palette·state readability와 표시명은
   visual spec으로 이동한다. 미구현 poison/lava와 wear/collapse 후보는 어느
   canonical spec에도 병합하지 않는다. 그 뒤 독립 canonical 문서를 제거한다.
4. history 보존은 Git이 담당한다. 활성 트리에 `archive/`, `old/`,
   `superseded/` 문서 폴더를 만들지 않는다.
5. `.agents/`에는 현재 plan, 미해소 acceptance evidence, repo-local
   instructions/skills만 둔다. 완료된 plan과 현재 spec에 반영된 research는
   제거한다. deferred 문서의 상세 후보는 Git 이력에 남기고 재개 조건만
   product spec의 non-goal/deferred boundary로 압축한다.
6. semantic-v2 runtime pack은 현재 구현이다. 삭제 대상이 아니라 README와
   manifest metadata를 코드에 맞게 고친다.
7. visual approval용 source/sheet는 승인 작업이 진행 중일 때만 active tree에
   둘 수 있다. 작업 종료 또는 defer 시 runtime에 필요한 파일과 최종 evidence
   외에는 Git 이력으로 보낸다.
8. `vehicle_run.gd` 분리는 기존 domain owner를 우회하는 새 catch-all manager를
   만들지 않는다. 첫 batch는 capture/tooling 책임만 떼며 gameplay behavior를
   바꾸지 않는다.
9. 88개 local commit은 보존한다. cleanup은 새 scoped commit으로 쌓고 push는
   별도 사용자 지시까지 하지 않는다.

## Target Authority Model

```text
AGENTS.md                         operating rules only
  └─ docs/product/vehicle_game_spec.md
       ├─ sole product/gameplay contract
       └─ docs/design/UI_VISUAL_SYSTEM.md
            └─ sole visual/UI/semantic contract

docs/README.md                    navigation only
README.md                         human-facing summary only
.agents/AGENTS.md + PLANS.md      governance/planning tasks when applicable
.agents/execplans/*.md            current work only
.agents/*-evidence.md             unresolved acceptance facts only
code + data + validators          implementation truth
Git history                       retired plans/research/review artifacts
```

## Approval Gates

삭제와 대용량 로컬 정리는 복구 가능하더라도 명시적 승인을 받은 뒤 실행한다.

### G1 — 역사 문서 제거

권장 승인 문구: **G1 approve**.

승인 시 G2 대상 외에 Phase 1, 2, 3A, 4에 정확히 열거된 tracked file을
작업 트리에서 삭제할 수 있다. 삭제 전에 다음 순서를 지킨다.

1. exact pre-cleanup tip hash와 `origin/master...master = 0/88`을 기록하고,
   복구가 현재 local object database 보존에 의존함을 사용자에게 알린다.
2. 삭제 후보별 inbound link와 unique requirement/disposition 표를 만든다.
3. accepted gameplay contract는 product spec, presentation contract는 visual
   spec으로 먼저 이동한다.
4. 아래 deferred 문서는 후보 상세를 옮기지 않고 activation guard만 product
   spec의 `Deferred / non-goals` 절로 압축한다.
   - combat-growth draft: 현재 41-card/5-secondary 계약 외의 후보는 비활성.
   - difficulty/meta study: current fixed difficulty를 유지하며 meta model은
     새 product revision 전까지 선택되지 않음.
   - map/tactics/boss follow-up: 현재 five-stage authored run 밖의 확장은 새
     product revision과 별도 ExecPlan 없이는 시작하지 않음.
5. canonical destination과 link migration을 같은 commit에 넣은 뒤 원문을
   삭제한다. 별도 archive 폴더는 만들지 않는다.

### G2 — 현재 visual approval lane 처분

권장 선택: **G2 defer**. 현재 제품 구조를 먼저 안정화하기 위함이다.

- `G2 continue`: 기존 active visual plan과
  `semantic-v3-approval` 자료를 그대로 유지하고 이 계획의 Phase 3B를 건너뛴다.
  visual plan 완료 후 final runtime decision만 visual spec/evidence에 반영하고
  해당 plan과 approval-only files를 삭제한다.
- `G2 defer`: approval board의 모든 scoped item을 `approved contract`,
  `verified unresolved gap`, `unapproved candidate`로 한 줄씩 분류한 ledger를
  사용자에게 제시한다. approved contract와 verified gap만
  `UI_VISUAL_SYSTEM.md`의 target/known-gap 절에 옮긴다. unapproved candidate는
  사용자가 폐기됨을 확인하면 Git 이력에만 남긴다. 그 뒤 active visual plan,
  decision catalog와 semantic-v3 approval 후보를 삭제한다. runtime
  manifest/provider는 변경하지 않는다.

두 선택 모두 새 visual generation은 이 정리 계획이 끝날 때까지 시작하지
않는다.

### G3 — 재생성 가능한 로컬 산출물 제거

권장 승인 문구: **G3 approve**.

승인 시 resolved absolute path가 repo 아래인지 다시 확인한 뒤 다음만 지운다.

- `D:\npjt\cardborne-platformer\build`
- `.codex-runtime/downloads`
- `.codex-runtime/godot-4.7.1-stable-export-templates`
- 사용되지 않는 `.codex-runtime/godot-4.7-stable`

`tools/godot.ps1`이 사용하는 `.codex-runtime/godot-4.7.1-stable`은 유지한다.
`.godot/`은 정상 import cache이므로 기본적으로 유지한다.

## Proposed Design

### Document authority validator

새 `tools/validation/validate_document_authority.ps1`은 외부 dependency 없이
다음을 실패 조건으로 검사한다.

- product spec과 visual spec이 존재하며 `type: spec`, `status: active`다.
- 그 두 파일 외의 tracked Markdown이 `canonical_for`로 product 또는 visual
  authority를 주장하지 않는다.
- root `AGENTS.md`가 product spec과 visual spec을 현재 contract로 가리키고,
  broad governance에서 `.agents/AGENTS.md`/`PLANS.md`를 읽도록 유지한다.
- `docs/README.md`의 필수 읽기 링크가 정확히 두 spec을 가리킨다.
- product spec의 gameplay/collision owner 절과 visual spec의 semantic category
  절이 존재해 제거된 taxonomy의 위임 경계를 명시한다.
- tracked Markdown의 relative links가 존재한다.
- retained agent-relevant policy/spec/plan/handoff/evidence/record 문서의
  lifecycle type/status 조합이 schema에서 허용된다.
- evidence, record와 draft가 `canonical_for`, `source_of_truth` 또는 동등한
  implementation authority 문구를 선언하지 않는다.
- `.agents/execplans/`에 `done`, `superseded`, `archived` plan이 없다.
- active plan의 `related` 링크가 존재하고 current product spec을 포함한다.
- 제거된 plan filename이 active docs에 남아 있지 않다.
- protected `AGENTS.md`에는 lifecycle frontmatter를 요구하지 않는다.

PowerShell validator는 Windows local check와 GitHub Actions에서 동일하게
실행한다. `.github/workflows/vehicle-run-validation.yml`의 checkout 직후,
Godot 설치 전에 다음 exact step을 추가한다.

```yaml
      - name: Validate document authority
        shell: pwsh
        run: ./tools/validation/validate_document_authority.ps1
```

script는 `/`와 `\`를 모두 normalize하고 Linux의 case-sensitive path에서
relative link를 확인한다. 기존 Godot `validate_*.gd` loop와 이름이 겹치지
않도록 `.ps1`로 둔다.

### Runtime documentation contract

`art/gameplay/semantic-v2/README.md`는 asset 제작 proposal이 아니라 다음만
설명하는 짧은 technical README로 다시 쓴다.

- runtime pack owner와 provider path.
- `asset-manifest.json`이 제공하는 ID/texture/mesh lookup 계약.
- collision, navigation, behavior는 asset pack이 소유하지 않는다는 경계.
- `sources/`, `sheets/`가 runtime import에서 제외되는 이유.
- 변경 후 실행할 semantic provider/visual separation validators.

`asset-manifest.json`에서는 현재와 반대인 metadata만 수정한다.
`requires_texture_instancing_adapter`는 false,
`current_runtime_is_procedural_mesh_multimesh`는 false로 고치고 floor cell은
visual spec의 288-unit contract와 일치시킨다. asset ID와 runtime path는 이
batch에서 바꾸지 않는다.

### VehicleRun responsibility boundary

첫 구조 변경은 새 `scripts/vehicle/vehicle_run_capture_driver.gd`가 다음을
소유하도록 한다.

- `--capture-*` argument parsing.
- capture sequence와 stage/boss/effect/collision evidence fixture setup.
- settle/save orchestration과 failure reporting.

단, `_debug_append_packet_enemies`는 capture-only가 아니라
`profile_vehicle_pressure.gd`가 사용하는 pressure validation support이므로
driver로 이동하지 않는다.

capture code는 현재 30개 이상의 private gameplay method와 넓은 state를
직접 조작하므로 단순 text move를 금지한다. 새
`scripts/vehicle/vehicle_run_capture_gateway.gd`를 두고 driver가 호출할 수 있는
API를 다음으로 고정한다.

- `prepare_stage(stage_index, preserve_upgrades)`
- `prepare_boss(stage_index)` / `resolve_boss_objective()`
- `set_player_fixture(fixture)` / `set_world_fixture(fixture)`
- `show_ui_fixture(fixture)` / `snapshot(kind)`
- `set_debug_overlay(kind, enabled)`
- `restore_baseline()`

gateway는 기존 domain owner를 호출하는 adapter이며 gameplay rule이나 별도
state model을 소유하지 않는다. driver는 `VehicleRun`의 underscore field/method를
직접 접근하지 않는다. `vehicle_run.gd`에는 gateway 생성과 위 작업을 기존
owner로 전달하는 이름 있는 capture hook만 남긴다. 일반 실행에서는 driver와
gateway가 생성 또는 tick되지 않는다.

driver는 시작 시 locale, reduced-motion, window size, transparent background,
camera zoom/smoothing, field override, collision overlay와 capture가 바꾸는 run
state를 snapshot한다. 성공·directory/save 실패·조기 종료 모두 하나의
`finish_capture(exit_code)` 경로와 `_exit_tree` fallback에서 원복한다. directory
생성 또는 PNG save 하나라도 실패하면 completion marker를 출력하지 않고
non-zero로 종료한다.

driver에 `FULL_CAPTURE_FILES` manifest를 두고 동적 stage/boss 이름을 실행 전에
확장한다. `ko`, `1280x720`, full-evidence 실행은 결과 filename set이 이
manifest와 정확히 같아야 하며 각 파일이 non-empty여야 한다.
`CAPTURE_SAVED`가 각 manifest entry에 한 번씩 존재하고 마지막에만
`VEHICLE_STAGE_CAPTURE_COMPLETE`가 나타나야 한다. 단순 “20장 이상”은
회귀 합격 조건으로 사용하지 않는다.

performance instrumentation은 physics/render hot path에 걸쳐 있으므로 첫
batch에서 억지로 이동하지 않는다. 대신 `vehicle_run.gd`에 새 기능을 넣을 때
다음 gate를 적용한다.

- run lifecycle/state transition인가: `vehicle_run.gd` 가능.
- enemy/projectile/encounter/UI/presentation/settings/audio owner가 이미 있는가:
  그 owner에 배치.
- capture/test/evidence 전용인가: capture driver 또는 `tools/`에 배치.
- 새 책임이 150줄 이상이거나 세 subsystem을 호출하는가: 별도 owner와
  focused validator 없이는 병합하지 않음.

capture 분리 뒤 `vehicle_run.gd`의 다음 추출 후보를 자동 실행하지 않는다.
mixed-responsibility inventory를 갱신하고, gameplay behavior를 보존하는 두 번째
ExecPlan이 필요한지 판단한다. 이는 조사 과제가 아니라 이번 계획의 명시적
중단점이다. 완료 기준은 capture/tooling 책임 제거와 비대화 guard 정착이다.

## Milestones and Tasks

### Phase 0 — 기준선 고정

- [ ] 현재 clean worktree와 `master...origin/master [ahead 88]`를 다시 기록한다.
- [ ] user-authored unrelated change가 생겼으면 중단하고 task-owned diff만
  분리한다.
- [ ] `git tag`나 branch를 만들지 않고 현재 commit hash를 plan Progress에
  기록한다. history rewrite와 push는 하지 않는다.
- [ ] 현재 full validator 목록과 Web workflow를 baseline으로 저장한다.

Acceptance:

- 변경 전 commit과 검증 명령이 기록됨.
- 제품 behavior·runtime asset diff 0.

### Phase 1 — canonical 계약 복구

- [ ] `vehicle_game_spec.md`의 `non-raster` 표현을 현재 image-backed visual
  contract로 수정한다.
- [ ] product spec의 superseded plan link를 제거하고 visual spec만 관련
  authority로 남긴다.
- [ ] taxonomy의 collision·behavior 열에서 structural wall, cover, bulkhead,
  repair/overdrive/arc terrain과 boss objective의 current rule을 product spec의
  기존 stage/terrain/boss 절에 병합한다.
- [ ] 같은 행의 silhouette, palette, display state와 Korean/English role naming만
  `UI_VISUAL_SYSTEM.md`의 semantic category 절에 병합한다.
- [ ] poison/lava와 wear/collapse 후보는 canonical 문서에 넣지 않는다.
- [ ] G1 승인 시 `GAMEPLAY_VISUAL_TAXONOMY.md`를 같은 commit에서 삭제한다.
- [ ] visual spec의 done plan link를 현재 product spec/evidence link로 바꾼다.
- [ ] `README.md`, `docs/README.md`, `docs/product/README.md`를 파생 색인으로
  축약하고 요구사항 중복을 제거한다.
- [ ] `validate_document_authority.ps1`을 만들고 GitHub workflow의 checkout
  직후, Godot 설치 전 `shell: pwsh` step으로 추가한다.

Acceptance:

- 제품 관련 질문은 product spec 한 곳, visual 질문은 위임된 visual spec 한
  곳에서 상충 없이 답할 수 있음.
- validator가 의도적으로 만든 duplicate canonical fixture를 실패시키고 현재
  tree를 통과함.
- 한국어·영어 user-facing contract는 변경 없음.

### Phase 2 — G1 승인형 역사 문서 제거

G1 승인 뒤 아래 파일을 제거한다.

삭제를 시작하기 전에 `rg`로 각 filename의 inbound link inventory를 만든다.
현재 확인된 product spec, visual spec, component-sheet docs, research/evidence의
링크를 canonical destination으로 먼저 바꾸고 authority validator를 통과시킨
뒤 원문을 삭제한다. link migration과 삭제 사이에 broken-tree commit을 만들지
않는다.

ExecPlan:

- `.agents/execplans/2026-07-29-horde-foundation-recovery-and-acceptance.md`
- `.agents/execplans/2026-07-30-approved-sheet-fidelity-recovery.md`
- `.agents/execplans/2026-07-30-full-visual-system-redesign.md`
- `.agents/execplans/2026-07-30-semantic-visual-world-boss-performance-rework.md`
- `.agents/execplans/2026-07-31-complete-visual-asset-ui-effect-replacement.md`
- `.agents/execplans/2026-07-31-deferred-map-tactics-boss-follow-up.md`

이미 canonical spec에 반영됐거나 현재 방향이 아닌 research/evidence:

- `.agents/continuous-horde-readability-evidence.md`
- `.agents/continuous-horde-rollout-problem-analysis.md`
- `.agents/survivor-shooter-combat-growth-reference-study.md`
- `.agents/vehicle-difficulty-meta-progression-decision-study.md`
- `.agents/vehicle-performance-architecture-audit.md`
- `.agents/vehicle-performance-stabilization-evidence.md`
- `.agents/vehicle-world-combat-expansion-evidence.md`
- `docs/product/combat-growth-improvement-direction.md`
- `docs/research/hidden-techniques-collective-enemies-mastery-unlocks.md`

위 목록 중 combat-growth draft, difficulty/meta study와 deferred
map/tactics/boss plan은 G1의 세 activation guard 문장을 product spec에 먼저
기록한다. 이는 후보를 채택하는 것이 아니며, 상세 candidate content는 현재
product requirement로 승격하지 않는다.

`semantic-v2-runtime-acceptance-evidence.md`에는 현재 미해결 performance gate와
built-Web smoke 상태만 남기고 과거 서술을 축약한다. 삭제되는 문서를 가리키는
모든 `related` link를 같은 commit에서 제거한다.

Acceptance:

- `.agents/execplans`에는 이 plan과 G2 선택에 따른 현재 visual plan만 존재.
- 삭제 파일에만 있던 accepted current requirement 0.
- stale link 0, lifecycle validator 통과.
- Git history에서 삭제 파일을 복원할 수 있음.

### Phase 3A — semantic-v2 runtime truth 복구

- [ ] `art/gameplay/semantic-v2/README.md`를 technical owner README로 축약한다.
- [ ] `asset-manifest.json`의 adapter/runtime/floor-cell metadata를 현재 code와
  visual spec에 맞춘다.
- [ ] approved `system-v1`의 현재 silhouette/palette/state rule을 visual spec에
  반영한 뒤 G1 승인에 따라 `docs/design/component-sheets/system-v1/`과 그
  root README의 과거 binding-evidence 내용을 제거한다.
- [ ] G1 승인에 따라
  `docs/design/component-sheets/semantic-rework-v2-proposal/`을 제거한다.
- [ ] G2 continue이면 `art/gameplay/semantic-v2/SOURCE_PROMPTS.md`, `sources/`,
  `sheets/`를 active approval/provenance input으로 유지한다.
- [ ] G2 defer 또는 visual lane 완료이면 위 세 provenance target의 inbound
  references를 `asset-manifest.json`, semantic-v3 docs와
  `validate_vehicle_visual_sheet_coverage.gd`에서 먼저 제거한 뒤 G1 승인에
  따라 작업 트리에서 삭제한다. runtime `actors/effects/hud/pickups/states/
  weapons/world`는 유지한다.
- [ ] `docs/design/component-sheets/README.md`는 G2 continue일 때 현재 approval
  lane만 안내하고, G2 defer일 때 semantic-v3 directory와 함께 제거한다.
- [ ] manifest asset ID/path diff가 metadata 외에는 0인지 검사한다.

Acceptance:

- README, manifest, provider와 visual spec이 같은 runtime 상태를 말함.
- retained approval/provenance input은 active owner와 inbound reference가 있고,
  제거된 input은 validator/manifest의 stale reference가 없음.
- `validate_vehicle_semantic_asset_provider.gd`,
  `validate_vehicle_semantic_visual_separation.gd`,
  `validate_vehicle_visual_replacement_coverage.gd` 통과.
- runtime screenshot pixel diff는 metadata-only batch에서 0.

### Phase 3B — G2 선택에 따른 approval 자료 정리

- [ ] `G2 continue`이면 active visual plan과 `semantic-v3-approval`만 유지하고
  source/sheet 삭제를 미룬다.
- [ ] `G2 defer`이면 semantic-v3 approval board의 map, wall, terrain,
  projectile, upgrade-card, XP, player, boss body와 shield node 행을 모두
  G2 ledger로 만든다. 사용자가 ledger를 확인한 뒤 approved contract와
  verified gap만 visual spec에 기록하고 다음을 제거한다.
  - `.agents/execplans/2026-07-31-approval-gated-visual-asset-replacement.md`
  - `.agents/visual-redesign-decision-catalog.md`
  - `docs/design/component-sheets/semantic-v3-approval/`
- [ ] 어느 선택에서도 semantic-v2 runtime files는 바꾸지 않는다.
- [ ] visual lane 최종 종료 시 generated candidate/source sheets와 preview를
  active tree에서 제거하고 runtime-used files와 한 장의 final acceptance
  evidence만 남긴다.

Acceptance:

- active plan이 실제로 실행 중인 작업만 설명함.
- approval-only artifact가 owner 없는 상태로 남지 않음.
- 사용자가 승인한 결정의 손실 0.
- 검증된 unresolved visual gap의 손실 0, unapproved candidate의 암묵적 승인 0.

### Phase 4 — orphan과 local artifact 정리

- [ ] G1 승인 뒤 참조가 없는
  `scripts/ui/vehicle_ui_accent_frame.gd.uid`를 제거한다.
- [ ] G1 승인 뒤 source script가 없는
  `tools/validation/validate_vehicle_horde_fronts.gd.uid`를 제거한다.
- [ ] G3 승인 시 tracked file 0인 `pixel-art-production/` 빈 directory shell과
  지정된 ignored build/download/template/4.7 runtime만 제거한다.
- [ ] 삭제 후 `tools/godot.ps1 --version`과 import가 4.7.1에서 동작하는지
  확인한다.

Acceptance:

- orphan `.uid` 0.
- runtime resource missing error 0.
- G3 미승인 시 ignored local artifact는 그대로 두고 source cleanup 완료를
  막지 않음.

### Phase 5 — VehicleRun capture 책임 분리

- [ ] capture 관련 변수·argument parsing·sequence·fixture setup·save를
  `vehicle_run_capture_driver.gd`로 이동한다.
- [ ] driver와 `VehicleRun` 사이에 위에 고정한 API만 노출하는
  `vehicle_run_capture_gateway.gd`를 추가하고 direct underscore access를 0으로
  만든다.
- [ ] 일반 실행에서 driver가 생성 또는 tick되지 않음을 검증한다.
- [ ] gateway가 기존 encounter/enemy/projectile/UI/presentation owner를
  우회해 gameplay rule을 복제하지 않는지 검토한다.
- [ ] 기존 `_build_hud_snapshot`, combat presentation과 gameplay state owner는
  이 batch에서 이동하지 않는다.
- [ ] `_debug_append_packet_enemies`는 pressure validator support로 유지하며
  capture driver로 이동하지 않는다.
- [ ] capture environment snapshot과 `finish_capture`/`_exit_tree` restore를
  구현하고 save/directory failure를 non-zero exit로 전파한다.
- [ ] `FULL_CAPTURE_FILES` set equality, non-empty file, per-file
  `CAPTURE_SAVED`, terminal completion marker를 validator에 추가한다.
- [ ] `validate_vehicle_run.gd`에 capture driver ownership/static guard를
  추가하거나 별도 `validate_vehicle_run_capture_driver.gd`를 만든다.
- [ ] `vehicle_run.gd` line/function count와 preload count를 before/after로
  기록하되 숫자 자체를 합격 기준으로 사용하지 않는다.

Acceptance:

- current capture CLI, exact full filename set, locale와 viewport behavior 동일.
- 실패·조기 종료 후 locale/settings/window/camera/overlay/run fixture가 원복되고
  false-success marker 0.
- normal play, performance scenario, stage transition behavior diff 0.
- `vehicle_run.gd`가 capture sequence implementation을 더 이상 소유하지 않음.
- 새 catch-all manager 또는 순환 dependency 0.

### Phase 6 — 최종 검증과 정리

- [ ] authority validator를 실행한다.
- [ ] Godot headless import를 실행한다.
- [ ] 모든 `tools/validation/validate_*.gd`를 정렬 순서로 실행한다.
- [ ] native Korean full capture의 filename set이 `FULL_CAPTURE_FILES`와 정확히
  같고 모든 PNG가 non-empty인지 확인한다.
- [ ] `tools/export_web.ps1`로 release Web export를 만든다.
- [ ] built Web artifact를 production-style server에서 열고 boot/navigation/
  basic combat smoke를 수행한다.
- [ ] `semantic-v2-runtime-acceptance-evidence.md`에 미해결 performance 결과를
  새로 측정한 사실로만 갱신한다. 실패를 성공으로 바꾸어 쓰지 않는다.
- [ ] 이 plan 완료 후 durable rule은 `AGENTS.md`/spec/validator에 남긴다.
  final validator는 plan이 `active`인 상태에서 실행하고, completion commit에서
  plan을 바로 삭제한다. `status: done`인 중간 commit은 만들지 않는다.

Acceptance:

- current product behavior, controls, localization과 visuals의 의도치 않은 변화
  0.
- stale/superseded plan 0, broken doc link 0, duplicate canonical claim 0.
- full validator, native capture, Web export와 built-Web smoke 통과.
- worktree clean, task-owned scoped commits만 존재.

## Test Plan

문서 batch:

```powershell
pwsh -NoProfile -File tools/validation/validate_document_authority.ps1
git diff --check
```

semantic/runtime batch:

```powershell
.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_semantic_asset_provider.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_semantic_visual_separation.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_visual_replacement_coverage.gd
```

최종 validator loop:

```powershell
Get-ChildItem tools/validation/validate_*.gd | Sort-Object Name | ForEach-Object {
  .\tools\godot.ps1 --path . --headless --script ("res://" + $_.FullName.Substring($PWD.Path.Length + 1).Replace("\", "/"))
  if ($LASTEXITCODE -ne 0) { throw "Validator failed: $($_.Name)" }
}
.\tools\export_web.ps1
```

서버를 시작하는 manual built-Web QA는 `$npjt-port-guard`를 먼저 사용해
fastrun manager의 `codex` lane에서 수행한다. 임의 port나 `user` lane을
사용하지 않는다.

## Rollback / Safety

- 각 phase는 독립 commit으로 만든다. unrelated user change는 stage하지 않는다.
- 삭제 전에 exact path와 current commit을 출력하고 승인 gate를 확인한다.
- 역사 문서는 Git에서 복구하며 별도 archive copy를 만들지 않는다.
- manifest metadata batch에서는 asset ID/path 변경을 금지한다.
- capture extraction은 behavior-preserving move로 제한하고 실패 시 그 phase의
  task-owned commit만 revert한다. hard reset은 사용하지 않는다.
- local cache 정리는 resolved path가 repo 또는 명시된 `.codex-runtime`
  subtree인지 검증한 뒤 PowerShell `Remove-Item -LiteralPath`로 수행한다.
- 원격 push, branch cleanup과 tag cleanup은 이 계획의 권한 밖이다.

## Risks and Mitigations

| 위험 | 완화 |
| --- | --- |
| 문서를 한 파일에 과도하게 합쳐 다시 거대한 catch-all spec이 됨 | product와 subordinate visual 두 책임만 유지하고 구현 상세는 code/validator에 둠 |
| 삭제된 research의 accepted requirement 손실 | G1 전 current spec 대비 unique requirement table을 만들고 accepted item만 먼저 병합 |
| active visual work 손실 | G2의 continue/defer 두 경로 외에는 삭제하지 않음 |
| source sheet 삭제로 재생성 근거 손실 | 현재 runtime에 필요한 provenance만 README/evidence에 남기고 binary history는 Git이 보존 |
| VehicleRun 분리가 새 manager 집중으로 바뀜 | capture-only owner와 gateway를 강제하고 gameplay owner는 그대로 유지 |
| 정리 중 게임 behavior가 함께 바뀜 | docs, metadata, orphan, code extraction을 별도 commit과 validator gate로 분리 |
| local 88 commits의 유실 또는 잘못된 공개 | history rewrite/push 금지, cleanup을 새 commit으로만 추가 |

## Open Questions

구현 설계에 남은 미결정 사항은 없다. 실행에는 삭제 권한에 해당하는 G1,
현재 visual lane 처분에 해당하는 G2, 로컬 재생성 산출물 삭제에 해당하는 G3
응답만 필요하다. 각 응답과 그 결과는 위에 완전히 정의되어 있다.

## Decision Notes

- 2026-08-01: “single source”는 모든 내용을 한 거대 파일에 넣는 뜻이 아니라
  제품 authority 하나와 명시적으로 위임된 visual authority 하나로 정의했다.
- 2026-08-01: Git history를 과거 계획·조사·approval artifact의 archive로
  선택했다.
- 2026-08-01: semantic-v2는 현재 runtime이므로 legacy 삭제 대상에서
  제외했다.
- 2026-08-01: 코드 복구는 capture/tooling 책임부터 시작하고 gameplay
  subsystem의 대규모 재작성은 금지했다.
- 2026-08-01: 과거 session의 transcript나 새 종합 evidence 문서를 repo에
  추가하지 않고 감사 결론만 이 plan에 기록했다.
- 2026-08-01: 기존 visual plan은 사용자 G2 선택 전 active 상태를 유지한다.
  따라서 이 recovery plan은 승인 전 `draft`다.

## Progress

- [x] instruction graph와 `.agents` lifecycle 규칙 확인.
- [x] tracked docs/code/assets, ignored build/runtime cache 감사.
- [x] git 494 commits와 local 88-commit delta의 제품 변화 추적.
- [x] repo 연결 과거 Codex session 184개 색인과 root thread 직접 검토.
- [x] canonical conflict, stale references와 runtime ownership 식별.
- [x] cleanup 및 responsibility recovery batch 설계.
- [ ] 사용자 G1/G2/G3 결정.
- [ ] Phase 0~6 실행.

## Next Steps

1. 사용자가 이 계획과 G1/G2/G3를 승인한다.
2. 승인된 gate만 반영해 plan status를 `active`로 바꾼다.
3. Phase 0부터 순서대로 실행하며 각 phase를 독립 commit으로 만든다.
4. Phase 6 통과 후 durable truth만 남기고 이 completed plan도 Git history로
   보낸다.

## Completion Criteria

- [ ] 새 세션이 `AGENTS.md`에서 시작해 제품/visual truth에 즉시 도달함.
- [ ] product requirement 중복 source 0, visual canonical 중복 source 0.
- [ ] done/superseded/archive plan이 active tree에 없음.
- [ ] stale technical README/manifest fact와 broken plan link 0.
- [ ] owner 없는 approval/research/evidence artifact 0.
- [ ] `vehicle_run.gd`가 capture workflow를 소유하지 않음.
- [ ] semantic runtime, gameplay, localization과 save behavior 회귀 0.
- [ ] authority validator, full Godot validators, native capture, Web export와
  built-Web smoke 통과.
- [ ] 모든 변경이 task-owned scoped commit이며 worktree가 clean함.
