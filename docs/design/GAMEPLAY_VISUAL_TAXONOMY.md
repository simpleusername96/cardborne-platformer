---
type: spec
status: active
owner: BK
created: 2026-07-31
last_reviewed: 2026-08-01
canonical_for: Cardborne gameplay visual categories, terminology, semantic distinctions, and visible state contracts
scope: Player-facing map surfaces, structures, terrain, containers, pickups, projectiles, attack feedback, upgrade cards, and vehicle exhaust
related:
  - ./UI_VISUAL_SYSTEM.md
  - ./component-sheets/semantic-v3-approval/asset-switch-approval-report.html
  - ../product/vehicle_game_spec.md
---

# Cardborne 게임플레이 비주얼 분류 사전

## Purpose

맵과 전투 요소를 외형이 아니라 **게임에서 수행하는 역할**로 분류한다.
승인 리포트, 에셋 ID, 충돌 규칙, 맵 생성기와 UI는 아래 이름을 같은 뜻으로
사용한다. 서로 다른 역할을 모두 `벽`, `장판`, `이펙트`라고 부르지 않는다.

## Scope

현재 승인 대상인 맵 바닥, 구조물, 기능 지형, 보상, 전투 전달체와 피해
피드백을 다룬다. 적 AI, 보스 패턴, 스테이지 진행 규칙과 성능 개선은 이번
에셋 승인 범위가 아니다.

## Requirements

### 맵과 월드 요소

| 정본 이름 | 무엇인가 | 충돌·게임플레이 계약 | 시각 계약 | 무엇이 아닌가 |
| --- | --- | --- | --- | --- |
| **바닥 타일** | 이동 가능한 맵 표면을 구성하는 반복 단위 | 보행 가능 영역 안에서 알고리즘으로 배치 | 어두운 저대비 산업 패널, 기능 없는 문양 없음 | 벽, 장판, 장식 decal |
| **구조벽** | 맵 가장자리 또는 중앙 구역의 연속 경계 | 통과 불가, 맵 topology와 collision의 일부 | 바닥보다 확실히 밝은 pale-metal mass와 어두운 외곽선 | 줄지어 놓은 엄폐물 |
| **엄폐물** | 열린 바닥에 놓이는 독립 장애물 | 국소적으로 이동·탄환·시야를 끊음 | 단독 실루엣, 구조벽보다 작은 footprint, 연속 배치 금지 | 맵 경계, 임시 벽 대용 |
| **파괴 장벽** | 보상 구역을 막는 파괴 가능한 벽 구간 | `봉쇄 → 손상 → 개방`; 부순 뒤 안쪽 상자에 접근 | 구조벽 계열의 밝은 재질, 균열과 파손 상태가 같은 footprint에서 이어짐 | 상자, 엄폐물, 장식 패널 |
| **통과형 에너지 장벽** | 통과할 수 있지만 위험한 넓은 에너지 구간 | solid collision 없음, 진입 중 감속과 낮은 주기 피해 | 양끝 장치와 전체 판정 폭을 채우는 밝은 에너지 curtain/rung | 구조벽, 레이저 한 줄, 순간이동 게이트 |
| **기능 장판** | 밟는 동안 이로운 효과를 주는 고정 영역 | 회복 또는 공격력 증가 등 명시된 효과만 제공 | 효과 범위 전체와 일치하는 밝은 표면, 고유 shape/glyph | 통과형 장벽, 단순 장식 |
| **위험 장판** | 기체와 적 모두에게 피해를 주는 고정 영역 | 같은 판정 규칙으로 양 진영 피해 | 독성은 녹색 액체, 용암은 주황·황색 열원처럼 재질과 경계를 구분 | 적 공격 telegraph, 무해한 바닥 문양 |
| **마모·붕괴 타일** | 반복 통행으로 상태가 변하는 바닥 타일 | `정상 → 마모 → 균열 → 붕괴`; 기체와 적의 통행을 모두 누적 | 동일 타일이 단계적으로 갈라지고 붕괴 후 위험 장판이 노출 | 시간만 지나면 바뀌는 장식 animation |
| **순간이동 게이트** | 짝을 이룬 위치 이동 장치 | 체류 조건을 만족하면 연결된 게이트로 이동 | 완전한 원형 floor portal과 활성 내부 면; 입구 방향을 요구하지 않음 | 문 모양 통로, chevron 표지, 에너지 장벽 |
| **상자** | 파괴하면 보상 pickup을 내는 컨테이너 | 공격으로 파괴, 내용물 방출, 파괴 전에는 작은 blocker | 밝은 amber 몸체, 잠금 seam과 파손 가능한 외곽 | 바닥 장식, 업그레이드 카드 |
| **픽업** | 기체가 접촉해 즉시 획득하는 작은 보상 | 기체의 직접 충돌과 끌어당김 도착 모두 수집 가능 | 역할별 색과 silhouette; 배경과 적 공격보다 밝고 작게 | 기능 장판, 상자 |

구조벽과 엄폐물은 함께 타일처럼 반복하지 않는다. 구조벽은 topology를
설명하고, 엄폐물은 열린 공간에서 순간적인 우회와 사격 차단을 만든다.
독립 엄폐물이 일렬로 이어져 구조벽처럼 보이는 배치는 사용하지 않는다.

`bright larva`라는 피드백 표현은 현재 위험 바닥 문맥에서 **bright lava
(밝은 용암)**로 해석한다. 생물성 유충(`larva`) motif는 승인된 요구사항이
아니다.

### 전투 전달체와 피해 피드백

공격 표현은 한 단어의 `속성 탄환`으로 분류하지 않고 다음 축을 분리한다.

| 축 | 값 | 시각 책임 |
| --- | --- | --- |
| 소유 진영 | player / hostile | 기본 hue와 outline 관계 |
| 전달 방식 | bolt / homing missile / charge / beam / area / summon·support | 탄두 silhouette, 이동 꼬리, 사전 경고 footprint |
| 위협 등급 | ordinary / elite / boss | 크기, 분절, 시작 cap과 그룹 문법 |
| payload | kinetic / thermal / toxin / cryo / arc / hybrid / support | 실제 상태·효과가 있을 때만 보조 색과 상태 표식 |
| 위력 등급 | light / standard / heavy | 실제 판정 core 크기와 impact 강도 |

- 탄환은 밝고 불투명한 **판정 core**, 진행 방향을 보여주는 낮은 불투명도의
  **tail**, 짧은 발사 flash와 방향성 impact로 구성한다. CSS 선이나 원처럼
  보이는 기본 도형 하나만으로 완성하지 않는다.
- 레이저는 길고 연속적인 corridor, bolt는 짧고 빠른 core, missile은
  물리적인 탄두와 추진 꼬리로 구분한다. 색만 바꿔 전달 방식을 구분하지 않는다.
- 연속 beam은 code가 실제 길이와 폭을 소유하고 authored 시작 cap, 반복
  core·edge와 종단 contact component를 조립한다. 기본 선 하나로 그리지 않는다.
- 현재 적 공격의 `thermal/toxin/cryo/arc` 값은 렌더 선택에는 쓰이지만
  플레이어에게 서로 다른 상태 효과를 적용하지 않는다. 따라서 승인 전
  리포트와 실제 화면에서 **기계적 속성처럼 과장해 표시하지 않는다**.
- 플레이어의 burn/poison/chill 업그레이드는 실제 상태 효과가 있으므로 해당
  payload를 색과 작은 상태 표식으로 보조할 수 있다.
- 피해를 받으면 발사체 진행 방향 또는 피격 normal을 따르는 짧은 spark,
  접점 flash와 source 방향 cue를 사용한다. 의미 없는 방사형 꽃무늬나 큰
  원형 burst를 반복하지 않는다.
- 경고 표시는 실제 판정 영역과 일치한다. 선 하나로 축약하지 않고 면의
  경계·시작점·진행 방향을 함께 보여준다.

### UI와 기체 motion

- 업그레이드 카드는 이미지 기반 panel 위에 `상단 약 1/3의 업그레이드
  이미지 → 이름과 현재 레벨 → 설명 → 실제 수치/효과` 순서로 배치한다.
- 현재 레벨을 텍스트로 표시하므로 3개의 빈/채움 단계 pip는 제거한다.
- 엔진 body는 기체 rear socket에 고정한다. idle과 일반 이동에는 불꽃을
  표시하지 않고, dash 동안에만 짧고 밝은 rear flare와 잔상을 표시한다.
- 보조무기 sprite 방향은 배치 방식이 소유한다. 궤도 칼날과 호위 드론은
  `player → weapon` 벡터를 따라 바깥을 향하고, 발사된 seeker는 속도 방향을
  향한다. 고정 wake mine과 원형 ion field에는 임의 heading을 부여하지 않는다.

### 현재 내부 ID와 표시 이름

| 현재 내부 ID·표현 | 승인 리포트 표시 이름 | 처리 원칙 |
| --- | --- | --- |
| `wall_*`, procedural wall segment | 구조벽 | 가장자리와 중앙 모두 같은 밝은 wall family 사용 |
| repeated fixed blocker | 엄폐물 | 일렬 배치를 없애고 독립 장애물로만 사용 |
| `breakable_bulkhead` | 파괴 장벽 | 보상 구역 봉쇄 목적과 파손 상태를 명시 |
| `arc_surge` | 통과형 에너지 장벽 | 내부 ID는 임시 유지 가능; 넓은 판정과 감속·피해를 표현 |
| `repair_pad` | 회복 장판 | loose repair pickup과 구분 |
| `overdrive_lane` | 공격 증폭 장판 | 내부 이름과 달리 반경 180 원형 판정 전체를 표시; 좁은 lane과 이동 화살표 사용 금지 |
| `transit_gate` | 순간이동 게이트 | 원형 floor portal로 교체 |
| `reward_crate` | 보상 상자 | pickup과 분리 |

## Acceptance Criteria

- 승인 리포트의 모든 항목이 정확히 한 카테고리와 하나의 정본 이름을 가진다.
- 구조벽, 엄폐물, 파괴 장벽, 통과형 에너지 장벽과 순간이동 게이트가 제목,
  이미지와 설명만으로 서로 구분된다.
- 외곽벽과 중앙 구조벽은 바닥보다 명백히 밝으며 collision topology와 맞는다.
- 기능·위험 지형의 이미지 면적과 실제 판정 footprint가 맞는다.
- projectile의 전달 방식과 위협 등급을 grayscale silhouette만으로도 구분한다.
- 실제 gameplay 효과가 없는 hostile payload를 색만으로 약속하지 않는다.
- 업그레이드 카드에는 level pip 중복이 없고 지원 언어에서 overflow가 없다.

## Non-Goals

- 승인 전에 후보 이미지를 runtime asset으로 교체하지 않는다.
- 이번 분류 작업에서 적 AI, 보스 패턴, 스테이지 흐름 또는 성능 수치를
  변경하지 않는다.
- 모든 기존 기체·적 asset을 백지에서 다시 만들지 않는다.
