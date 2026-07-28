---
type: evidence
status: active
owner: BK
created: 2026-07-28
last_reviewed: 2026-07-28
topic: Cardborne combat growth, horde, terrain, and boss reference study
scope: Current five-stage vehicle campaign and nine external survivor-shooter references
source: Repository state at c21c1b1 plus official and community sources reviewed on 2026-07-28
related:
  - ../docs/product/vehicle_game_spec.md
  - ../docs/product/combat-growth-improvement-direction.md
  - ./vehicle-world-combat-expansion-evidence.md
  - ./vehicle-performance-stabilization-evidence.md
---

# Cardborne 전투 성장·몰이·보스 레퍼런스 심층 연구

## Purpose

이 문서는 다음 질문에 답하기 위한 근거 자료다.

1. Cardborne에는 이미 어떤 성장, 적 생태, 지형 상호작용, 보스 규칙이 구현되어 있는가?
2. 수동 조준 슈팅과 survivor-like 성장을 결합한 레퍼런스들은 스테이지, 캐릭터, 적, 스킬, 무기, 보스를 어떻게 연결하는가?
3. 현재 게임이 수치상 적 수와 카드 수를 갖고도 `몰이 → 대량 처치 → 급격한 성장`의 쾌감을 충분히 만들지 못하는 원인은 무엇인가?
4. Cardborne의 정체성과 성능·가독성 제약을 보존하면서 어떤 구조만 선별해 옮겨야 하는가?

이 문서는 조사 결과를 보존하는 `evidence`다. 현재 제품 계약은
[`vehicle_game_spec.md`](../docs/product/vehicle_game_spec.md)이며, 이 문서 자체는
구현을 승인하거나 정본 사양을 변경하지 않는다. 조사에서 선택한 개선 방향은 별도의
[`combat-growth-improvement-direction.md`](../docs/product/combat-growth-improvement-direction.md)에
`draft` 사양으로 기록한다.

## Evidence Contract

### 사실·해석·결정의 구분

- **사실(Fact)**: 현재 저장소 코드·정본 문서 또는 링크된 외부 출처에서 확인한 내용이다.
- **해석(Inference)**: 여러 사실을 연결해 설명한 설계 진단이다.
- **결정(Decision)**: Cardborne에 전이할 원리 또는 배제할 구조다. 구현 승인이 아니라 후속 설계의 근거다.

### 출처 등급

| 등급 | 의미 | 사용 원칙 |
| --- | --- | --- |
| A | 개발사·퍼블리셔의 공식 Steam 페이지, 공식 사이트, 공식 공지 | 현재 제품의 방향, 출시 상태, 공식 콘텐츠 설명에 우선 사용 |
| B | 공식 위키 | 세부 규칙과 콘텐츠 구조에 사용하되 버전 차이를 명시 |
| C | 커뮤니티 위키 | 세부 수치·해금·예시의 보조 근거로만 사용하고, 공식 설명과 충돌하면 채택하지 않음 |

모든 외부 출처의 조회 기준일은 **2026-07-28**이다. 라이브 게임과 위키의 총 콘텐츠 수는
변할 수 있으므로, 중요한 결론은 개수보다 시스템 구조에 의존한다.

### 조사 범위

포함:

- 현재 Cardborne의 카드 제약, 성장 빈도, 주·보조 무기 규모
- 적 수, 동시 활성 상한, 스폰 공간 분포, 역할 조합
- 현재 지형 피해·Breach·지뢰·시설 상호작용
- 보스 페이즈, 패턴 문법, 보상, 일반 적과의 관계
- 9개 레퍼런스의 스테이지, 캐릭터, 적, 스킬, 무기, 보스, 보상
- 전이 가능한 설계 원리와 Cardborne에 맞지 않는 구조

제외:

- 플레이 로그 없이 확정하는 최종 피해량·쿨다운·스테이지 시간
- 외부 게임의 모든 콘텐츠 목록
- 현재 정본 제품 사양 수정
- 게임 코드 또는 아트 에셋 변경

### 완료 체크리스트

- [x] 현재 카드 선택 규칙과 성장 곡선을 코드 기준으로 확인했다.
- [x] 현재 적 쿼터, 동시 상한, 패킷과 공간 배치를 확인했다.
- [x] 현재 지형 상호작용이 실제 피해·제어 루프에 어떻게 연결되는지 확인했다.
- [x] 현재 5개 보스가 이름 외에 어떤 규칙으로 구분되는지 확인했다.
- [x] 각 레퍼런스의 스테이지·캐릭터·적·스킬·무기·보스를 개별 조사했다.
- [x] 공식 출처와 버전 민감한 보조 출처를 분리했다.
- [x] 전이할 구조, 축소해 전이할 구조, 배제할 구조를 구분했다.
- [x] 개선 방향 초안이 이 근거에서 직접 추적되도록 요구사항과 판정 지표를 도출했다.

## Sources

### 현재 저장소

주요 사실은 다음 현재 소유자에서 확인했다.

| 영역 | 현재 소유자 |
| --- | --- |
| 정본 제품 계약 | [`docs/product/vehicle_game_spec.md`](../docs/product/vehicle_game_spec.md) |
| 카드 풀과 카드 효과 | `scripts/cards/vehicle_upgrade_catalog.gd` |
| 스테이지·적·보스 정의 | `scripts/vehicle/stages/vehicle_combat_stages.gd` |
| 카드 제안 규칙 | `scripts/cards/vehicle_upgrade_catalog.gd`와 `scripts/cards/vehicle_run_build.gd` |
| 스폰 역할·앵커 배치 | `scripts/encounters/vehicle_spawn_allocator.gd`와 `scripts/encounters/vehicle_encounter_runtime.gd` |
| 플레이어 무기와 Breach | 플레이어 전투 런타임 및 projectile 소유자 |
| 지형·시설·지뢰 | 필드 런타임, world interaction, mine 소유자 |
| 보스 상태와 패턴 | stage boss 런타임 |
| 과거 구현 근거 | [`vehicle-world-combat-expansion-evidence.md`](./vehicle-world-combat-expansion-evidence.md) |
| 현재 성능 근거 | [`vehicle-performance-stabilization-evidence.md`](./vehicle-performance-stabilization-evidence.md) |

`vehicle-world-combat-expansion-evidence.md`의 앞부분은 당시의 이전 상태를 기록한 역사 자료다.
현재 상태를 판단할 때는 라이브 코드를 우선했고, 해당 문서는 왜 지형 피해·Breach·3페이즈 보스가
추가되었는지와 검증 이력을 확인하는 용도로만 사용했다.

### 외부 출처 묶음

- **20 Minutes Till Dawn**:
  [Steam](https://store.steampowered.com/app/1966900/20_Minutes_Till_Dawn/),
  [공식 뉴스](https://steamcommunity.com/app/1966900/allnews/),
  [Modes](https://20minutestilldawn.wiki.gg/wiki/Modes),
  [Characters](https://20minutestilldawn.wiki.gg/wiki/Characters),
  [Weapons](https://20minutestilldawn.wiki.gg/wiki/Weapons),
  [Upgrades](https://20minutestilldawn.wiki.gg/wiki/Upgrades),
  [Boss](https://20minutestilldawn.wiki.gg/wiki/Boss),
  [Tomes](https://20minutestilldawn.wiki.gg/wiki/Tomes),
  [Character Upgrades](https://20minutestilldawn.wiki.gg/wiki/Character_Upgrades),
  [Synergies](https://20minutestilldawn.wiki.gg/wiki/Synergies)
- **Brotato**:
  [Steam](https://store.steampowered.com/app/1942280/Brotato/),
  [Waves](https://brotato.wiki.spellsandguns.com/Waves),
  [Shop](https://brotato.wiki.spellsandguns.com/Shop),
  [Characters](https://brotato.wiki.spellsandguns.com/Characters),
  [Weapons](https://brotato.wiki.spellsandguns.com/Weapons),
  [Enemies](https://brotato.wiki.spellsandguns.com/Enemies),
  [Horde Wave](https://brotato.wiki.spellsandguns.com/Horde_Wave),
  [Crate](https://brotato.wiki.spellsandguns.com/Crate)
- **Vampire Survivors**:
  [Steam](https://store.steampowered.com/app/1794680/Vampire_Survivors/),
  [Mad Forest](https://vampire-survivors.fandom.com/wiki/Mad_Forest),
  [Weapons](https://vampire-survivors.fandom.com/wiki/Weapons),
  [Passive items](https://vampire-survivors.fandom.com/wiki/Passive_items),
  [Evolution](https://vampire-survivors.fandom.com/wiki/Evolution),
  [Level up](https://vampire-survivors.fandom.com/wiki/Level_up),
  [Enemies](https://vampire-survivors.fandom.com/wiki/Enemies)
- **Halls of Torment**:
  [Steam](https://store.steampowered.com/app/2218750/Halls_of_Torment/),
  [Hall](https://hot.fandom.com/wiki/Hall),
  [Ember Grounds](https://hot.fandom.com/wiki/Ember_Grounds),
  [Ability](https://hot.fandom.com/wiki/Ability),
  [Trait](https://hot.fandom.com/wiki/Trait),
  [Hero](https://hot.fandom.com/wiki/Hero),
  [Lord of Pain](https://hot.fandom.com/wiki/Lord_of_Pain),
  [Secret](https://hot.fandom.com/wiki/Secret),
  [The Vault](https://hot.fandom.com/wiki/The_Vault)
- **Soulstone Survivors**:
  [Steam](https://store.steampowered.com/app/2066020/Soulstone_Survivors/),
  [Void Fields](https://soulstone-survivors.fandom.com/wiki/Void_Fields),
  [Runes](https://soulstone-survivors.fandom.com/wiki/Runes),
  [Powers](https://soulstone-survivors.fandom.com/wiki/Powers),
  [Characters](https://soulstone-survivors.fandom.com/wiki/Characters),
  [Weapons](https://soulstone-survivors.fandom.com/wiki/Weapons),
  [Active Skills](https://soulstone-survivors.fandom.com/wiki/Active_Skill),
  [Titan Hunt](https://soulstone-survivors.fandom.com/wiki/Titan_Hunt),
  [Overlord](https://soulstone-survivors.fandom.com/wiki/Overlord)
- **Deep Rock Galactic: Survivor**:
  [Steam](https://store.steampowered.com/app/2321470/Deep_Rock_Galactic_Survivor/),
  [Elimination](https://deeprockgalactic.wiki.gg/wiki/Survivor%3AElimination),
  [Equipment](https://deeprockgalactic.wiki.gg/wiki/Survivor%3AEquipment),
  [Overclocks](https://deeprockgalactic.wiki.gg/wiki/Survivor%3AOverclocks),
  [Mid-dive Upgrades](https://deeprockgalactic.wiki.gg/wiki/Survivor%3AMid-dive_Upgrades),
  [Biomes](https://deeprockgalactic.wiki.gg/wiki/Survivor%3ABiomes),
  [Objectives](https://deeprockgalactic.wiki.gg/wiki/Survivor%3AObjectives)
- **Deep Rock Galactic: Survivor — Heavy Duty**:
  [Steam](https://store.steampowered.com/app/4395500/Deep_Rock_Galactic_Survivor__Heavy_Duty_Expansion/),
  [공식 출시 공지](https://store.steampowered.com/news/posts/?enddate=1773351305&feed=steam_community_announcements)
- **Yet Another Zombie Survivors**:
  [Steam](https://store.steampowered.com/app/2163330/Yet_Another_Zombie_Survivors/),
  [Wiki overview](https://yetanotherzombie.wiki.gg/wiki/Yet_Another_Zombie_Survivors),
  [Survivors](https://yetanotherzombie.wiki.gg/wiki/Survivors),
  [Enemies](https://yetanotherzombie.wiki.gg/wiki/Enemies_%28Survivors%29),
  [Game modes](https://yetanotherzombie.wiki.gg/wiki/Game_modes_%28Survivors%29),
  [Maps](https://yetanotherzombie.wiki.gg/wiki/Maps)
- **Nova Drift**:
  [Steam](https://store.steampowered.com/app/858210/Nova_Drift/),
  [공식 사이트](https://www.novadrift.io/),
  [Cosmic Powers](https://blog.novadrift.io/nova-drift-cosmic-powers/),
  [Enemies 2.0](https://blog.novadrift.io/enemies20/),
  [공식 패치 노트](https://blog.novadrift.io/patch-notes/),
  [Super Mods](https://nova-drift.fandom.com/wiki/Super_Mods),
  [Upgrade List](https://nova-drift.fandom.com/wiki/Upgrade_List)

## Findings

## 1. 현재 Cardborne의 실제 기준선

### 1.1 보존해야 할 제품 정체성

현재 제품은 단순 자동 공격 survivor-like가 아니다. 다음 입력과 진행 계약이 이미 정본이다.

- 수동 조준과 누르고 있는 주무기 발사
- 정확히 1초 유지해 여는 Breach shot
- dash와 EMP의 능동적 방어·공간 제어
- 자동 추적 seeker와 선택 가능한 수동 조준 보조 무기의 공존
- 5개 스테이지로 연결된 authored run
- 지도 픽업, 제한된 카드 선택, stage boss
- repository guidance가 보존 대상으로 지정한 optional field boss 의도
- 첫 클리어 가독성, 공정한 텔레그래프, 성능 상한

**해석:** 개선안은 자동 조준 무기 수를 늘려 입력을 지우는 방향이 아니라, 수동 조준으로 만든
표적 우선순위와 Breach 타이밍이 다수 처치의 기폭제가 되게 해야 한다.

optional field boss는 현재 실행 중인 기능으로 확인되지 않았다. reward runtime은 optional reward와
`field_boss` source를 받을 수 있고 validator도 이를 검사하지만, live field/boss runtime은
선택형 field boss를 spawn하지 않는다. 따라서 이 연구에서는 **보존하도록 지시된 미구현 제품 의도**로
취급하며 현재 플레이 가능한 시스템으로 세지 않는다.

### 1.2 카드와 성장

#### 확인된 사실

- 카드 정의는 **46개**다.
- 선택 가능한 보조 계열은 Ion, Orbit, Mines, Drone 네 가지이고, 런에서는 서로 다른 선택형
  보조 계열을 최대 2개만 얻는다. 기본 Seeker를 포함하면 총 3개 보조 계열이 동시에 존재할 수 있다.
- 카드 제안은 `[run_seed, stage_index, source_id, offer_serial]`로부터 결정되며, 섞은 뒤 중복 없는
  최대 3장을 낸다. 즉, 현재 제안은 이미 제약된 결정적 랜덤이다.
- 스테이지 1의 빈 빌드 첫 제안은 주무기, 원소, passive/mobility 범주를 하나씩 보장한다.
- 전체 업그레이드가 정확히 하나일 때 `Tuned Thrusters`가 없으면 후속 제안에 끼워 넣는다.
- 그 이후 level-up에서는 세 원소 계보 중 가장 덜 진행된 eligible child와 섞인 behavior 카드 하나를
  우선한다.
- 대부분의 카드는 `level_up`과 `boss` 양쪽 출처에 모두 들어간다. `aegis_cycle`,
  `overclock_cycle`, `siphon_matrix`만 level-up 전용이다.
- 현재 boss offer는 대체로 일반 level-up과 같은 카탈로그를 사용한다. 준비된 조합을 전용 진화로
  바꾸는 boss-only 계층은 없다.
- XP 요구량은 레벨 인덱스 `i`에 대해
  `min(160, 12 + round(3i + 0.55i²))`이며, 현재 최소 쿼터 경로의 정규 level-up 배분은
  스테이지별 **7 / 4 / 3 / 3 / 4**, 총 21회다.
- 행동 변화 카드도 존재한다. 예를 들어 관통, side shot, wall ricochet, Breach splash,
  poison spread, opening-shot finisher, dash·EMP 변형이 있다.
- 동시에 많은 카드는 피해량, 발사 간격, 투사체 크기, 이동 속도 같은 누적 수치 성장이다.

#### 해석

현재 문제는 “랜덤 카드가 완전히 무제약”인 것이 아니다. 문제는 제약의 목적이다.

1. 현재 제약은 **빌드 성립과 안전성**을 보장한다.
2. 하지만 특정 시점에 플레이 규칙이 크게 변하는 **질적 도약**을 보장하지 않는다.
3. boss offer가 일반 풀과 거의 같아, 보스를 이겨도 “준비한 빌드가 진화했다”는 사건이 약하다.
4. 첫 스테이지에 선택 7회가 몰리지만, 그 7회가 하나의 명확한 변신으로 수렴한다는 계약은 없다.
5. 따라서 카드 수와 행동 카드가 충분해도 플레이어가 체감하는 곡선은
   `조금 강함 → 조금 더 강함`에 머물 수 있다.

#### 현재 화력 규모의 의미

- 기본 주무기는 18 damage, 0.12초 간격이므로 전탄 명중 시 단일 대상 이론값은 약 150 DPS다.
- Breach는 1초 준비 후 direct health 1.85배, structure 4배, stagger 3배, radius 1.75배다.
- Seeker는 25 damage / 1.35초이고, 레벨에 따라 수가 늘지만 개별 피해 계수가 줄어든다.
- Ion은 레벨에 따라 8/12/16 DPS, 반경 120/140/160이다.
- Orbit은 2/3/4개의 blade와 대상별 재타격 제한을 사용한다.
- Mine은 48/60/72 damage, 3.2/2.8/2.4초 간격, 최대 3/4/5개, 폭발 반경
  96/108/120이다.
- Drone은 단일 표적 12/16/20 damage를 0.85/0.72/0.60초마다 발사한다.

이 값들은 개별 무기가 작동함을 보여주지만, 동시에 62~92명의 활성 적을 한 번에 처리하는
고유한 **집단 삭제 기하**가 자동으로 생기는 것은 아니다. 현재 행동 카드의 다수는 한 번의 관통,
한 번의 반사, 제한된 분산, 작은 반경 또는 보조 피해다.

### 1.3 적 수와 실제 교전 밀도

#### 확인된 사실

| 항목 | Stage 1 | Stage 2 | Stage 3 | Stage 4 | Stage 5 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Hard defeat quota | 125 | 166 | 208 | 250 | 291 |
| Authored ordinary population | 260 | 300 | 340 | 380 | 420 |

- 런 전체 Hard 최소 처치 쿼터는 **1,040**이다.
- 동시 활성 상한은 stage별 수치가 아니라 **각 stage 안에서 반복되는 encounter beat별 수치**다.
  모든 stage가 beat 0에서 4까지 진행할 수 있으며, difficulty scaling 이후 값은 다음과 같다.

| Difficulty | Beat 0 | Beat 1 | Beat 2 | Beat 3 | Beat 4 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Hard active cap | 1 | 62 | 78 | 88 | 92 |
| Normal active cap | 1 | 58 | 73 | 83 | 86 |
| Easy active cap | 1 | 55 | 69 | 78 | 81 |

- 따라서 Stage 1도 후반 beat 4에서는 Hard 92 상한에 도달할 수 있고, Stage 5도 새 stage의
  beat 1에서는 Hard 62부터 다시 상승한다.
- 스테이지 1의 첫 정찰 개체는 cue 5.1초, spawn 6.0초다.
- 이후 패킷은 2.4초 간격이며, 하나의 패킷은 8개 squad, squad당 3~5명으로 구성된다.
- 역할 allocator는 역할을 재셔플하고 각 squad에 pursuit 역할을 보장하며, projectile 역할을 분산한다.
- 많은 squad는 서로 다른 offscreen anchor를 사용한다. 목표 거리는 1,200/1,650/2,100,
  ring 범위는 900~2,400이고, 필드 전체 크기는 7,200×4,320이다.
- cohesion은 2명 또는 3명 단위의 작은 formation에는 적용되지만, 8개 squad를 하나의
  처치 가능한 덩어리로 모으는 authored front는 아니다.
- 활성 상한 때문에 queue는 지연될 수 있고, scheduler는 spawn tick마다 조건을 만족하는 개체를
  하나씩 투입한다.
- 현재 `group_clear`는 시각 효과이며 별도 보상 루프가 아니다.
- 적 역할은 swarm, chaser, shooter, controller, shield escort, artillery, rammer,
  bulkhead guard, splitter, turret, mine, tower, repair, carrier, beam, generator, pylon 등으로
  충분히 나뉘어 있다.
- 후반 일반 적의 체력 배율은 1.04에서 1.16, 피해는 1.03에서 1.12, 속도는 1.01에서
  1.04 범위다.

#### 해석

**활성 적 수는 교전 밀도와 같지 않다.**

필드가 넓고 패킷이 8개의 독립 anchor에 퍼져 들어오면, 92명이 살아 있어도 플레이어 근처에서
동시에 공격·밀집·사망하는 수는 훨씬 적을 수 있다. 현재 배치는 공정한 offscreen 유입과
원거리 역할 분산에는 유리하지만, 플레이어가 유도한 한 덩어리를 한 방향 공격이나 지형 연쇄로
쓸어버리는 장면에는 불리하다.

역할 생태 역시 존재하지만, stage role 배열을 순환해 squad를 채우므로
`방패 전열 + 회복 지원 + 저체력 군집`, `minelet fuse pack`, `controller가 미는 압축 전선`처럼
해결법이 읽히는 authored combat puzzle로 묶이지 않는다. 현재의 문제는 적 종류 부족보다
**역할을 의미 있는 진형으로 조합하는 계층 부족**에 가깝다.

### 1.4 지형과 환경 처치

#### 확인된 사실

- 세 필드는 모두 7,200×4,320이다.
- Drowned Ruins와 Tidal Archive에는 Arc Surge strip이 하나씩, Storm Drydock에는 두 개가 있다.
- 각 필드에는 breakable bulkhead 2개와 gate pair 2쌍이 있다.
- Arc Surge는 5.2초 cycle, 1.4초 warning, 0.8초 active이며, 한 창에서 player 10,
  ordinary 18, boss 6 damage를 한 번 준다.
- bulkhead health는 72이며 Breach로 즉시 파괴할 수 있다.
- gate는 플레이어만 사용하며 0.35초 dwell, 10초 cooldown, 0.45초 invulnerability를 준다.
- repair field는 반경 150, 스테이지당 예산 24, 초당 4 회복, 피격 후 1초 정지를 사용한다.
- overdrive field는 반경 180, 피해 1.2배다.
- 이동형·고정형 지뢰는 플레이어가 총격으로 기폭할 수 있고, 일반 적·boss에도 피해를 주며,
  최대 320 범위에서 연쇄 기폭한다.

#### 해석

“지형 상호작용이 없다”는 진단은 현재 구현에는 정확하지 않다. 더 정확한 진단은 다음과 같다.

- Arc strip 1~2개는 31.1 million px² 필드에서 드물고, 대부분 시간에 따라 우연히 맞는
  위험이다. 플레이어가 몰이를 끝내는 명시적 trigger가 아니다.
- bulkhead 2개는 길과 시야를 바꾸고 Breach를 가르치지만, 파괴 자체가 대량 피해나 보상으로
  이어지지 않는다.
- gate, repair, overdrive는 주로 플레이어 편의 시설이며 적을 압축하거나 처리하는 공통 동사가 아니다.
- 지뢰 연쇄는 현재 가장 가까운 `몰이 → trigger → 다수 처치` 장치지만, authored stationary mine의
  수와 배치가 적고 성장·스테이지 절정과 연결되지 않는다.
- 환경 처치가 XP, kill chain, 다음 성장으로 눈에 띄게 연결되는 피드백도 약하다.

즉, 부품은 있지만 `유도 → 압축 → 기폭 → 수확`이라는 닫힌 루프가 없다.

### 1.5 보스

#### 확인된 사실

- Hard 기준 stage boss HP는 1,250 / 1,350 / 1,450 / 1,550 / 1,650이다.
- 다섯 보스는 이름과 visual variant가 다르지만 하나의 공유 `stage_boss` 런타임과
  공통 반경 76, 속도 150을 사용한다.
- 65%와 30% HP에서 3페이즈로 나뉘며 read gap은 0.55 / 0.42 / 0.32초,
  autonomous interval은 6.0 / 4.9 / 3.9초로 짧아진다.
- 각 보스는 4개의 direct pattern과 2개의 autonomous pattern을 가진다.
- phase transition은 같은 네 패턴의 순서를 바꾸고 pattern index를 재설정하며, read gap,
  volley 제한, autonomous cadence를 강화한다.
- generic pattern 종류는 lanes, charge, fan, area, cross, beam, pylons, summon이다.
- `area`, `pylons`, `summon`은 추가 내용이 달라도 공통 aimed burst와 radial
  committed-target 검사도 수행한다.
- 각 보스는 하나의 interruptible signature startup을 가지며 Breach 반응 계약은 동일하다.
- quota 달성 후 일반 적 queue가 지워지므로 보스전 중 평상시 군집은 사라진다. summon이나
  보조 시스템만 남는다.
- 보스 처치 후 XP recall, 일반 카드와 거의 같은 3장 boss offer, Stage Report가 이어진다.

#### 해석

현재 “3페이즈”는 **스케줄러의 수치 단계**이지 **전투의 의미 상태**가 아니다.

보스마다 이름, 속성, 패턴 순서, 일부 보조 내용은 다르지만 플레이어가 수행하는 동사는 대체로
동일하다.

1. 표시된 generic geometry를 피한다.
2. 체력 바를 계속 공격한다.
3. 한 번의 signature startup을 Breach로 끊는다.
4. recovery에 피해를 넣는다.

phase가 바뀌어도 새로운 목표물, 방어 규칙, arena state, 취약 조건, 군집 관계가 생기지 않는다.
보상도 평상시 카드 선택과 크게 다르지 않다. 따라서 체력과 패턴 수를 늘리는 것으로는
“보스답다”는 체감이 생기기 어렵다.

## 2. 개별 게임 심층 분석

## 2.1 20 Minutes Till Dawn

### 시스템 구조

| 범주 | 조사 결과 |
| --- | --- |
| 스테이지·런 | 수동 방향 조준과 발사를 사용하는 20분 standard, 10분 quick, endless가 중심이다. 전투 도중 level-up을 반복하고 mini-boss와 boss가 성장 절정을 끊어 준다. |
| 캐릭터 | 캐릭터는 시작 수치만 다른 것이 아니라 고유 사건을 만든다. Shana의 reroll, Scarlett의 세 번째 사격 flame wave처럼 선택과 발사 리듬을 바꾸며, mini-boss chest의 character upgrade로 정체성이 더 강해진다. |
| 적 | 일반 군집 사이에 mini-boss와 boss가 시간 축의 시험으로 들어온다. boss 동안 좁아지는 electric barrier는 단순 체력 증가가 아니라 이동 공간 규칙을 바꾼다. |
| 스킬 | 커뮤니티 위키 기준 25개 upgrade tree, 100개 upgrade가 있으며 계보 선택이 시너지를 만든다. Synergy는 필요한 업그레이드 조합을 갖추면 별도 결합 효과를 연다. |
| 무기 | 11개 무기는 입력과 탄도 규칙부터 다르다. Grenade는 폭발과 self-damage 위험, Magic Bow는 reload 시 귀환, Batgun은 추적 summon으로 플레이 방식이 갈린다. |
| 성장 절정 | 무기 level 20에서 무기별 3개 evolution 중 하나를 고른다. mini-boss의 character upgrade와 boss의 Tome은 일반 수치 카드와 다른 보상 계층이다. Tome은 큰 이득과 trade-off를 동반한다. |
| 보스 | boss는 shrinking barrier로 arena를 바꾸고 Tome 선택을 제공한다. 공식 2024-10-28 공지는 Blessings & Curses closed beta에서 boss-specific minions, character specialization, Tome 재작업을 설명했으나 후속 정식 반영 공지는 확인되지 않아 안정 규칙으로 채택하지 않았다. |

**행별 근거:** 스테이지·런은 [A: Steam](https://store.steampowered.com/app/1966900/20_Minutes_Till_Dawn/)과
[C: Modes](https://20minutestilldawn.wiki.gg/wiki/Modes), 캐릭터는
[C: Characters](https://20minutestilldawn.wiki.gg/wiki/Characters)와
[C: Character Upgrades](https://20minutestilldawn.wiki.gg/wiki/Character_Upgrades), 적·보스는
[C: Boss](https://20minutestilldawn.wiki.gg/wiki/Boss), 스킬·진화는
[C: Upgrades](https://20minutestilldawn.wiki.gg/wiki/Upgrades),
[C: Synergies](https://20minutestilldawn.wiki.gg/wiki/Synergies),
[C: Tomes](https://20minutestilldawn.wiki.gg/wiki/Tomes), 무기는
[C: Weapons](https://20minutestilldawn.wiki.gg/wiki/Weapons), closed beta 내용은
[A: 공식 뉴스](https://steamcommunity.com/app/1966900/allnews/)에서 확인했다.

커뮤니티 위키의 안정 콘텐츠 표기는 13 characters, 11 weapons, 25 upgrade trees다. 공식 Steam은
50개 이상의 업그레이드와 수동 조준·발사를 핵심으로 설명한다
([A: Steam](https://store.steampowered.com/app/1966900/20_Minutes_Till_Dawn/),
[C: Characters](https://20minutestilldawn.wiki.gg/wiki/Characters),
[C: Weapons](https://20minutestilldawn.wiki.gg/wiki/Weapons),
[C: Upgrades](https://20minutestilldawn.wiki.gg/wiki/Upgrades)).

### Cardborne에 주는 의미

- **전이:** 수동 조준의 입력 부담은 무기 진화와 캐릭터 전용 보상처럼 분명한 질적 보상으로 상환해야 한다.
- **전이:** boss reward를 일반 풀의 한 번 더 뽑기가 아니라 prepared build를 확정하는 전용 선택으로 만든다.
- **배제:** 한 arena의 시간 생존 구조와 큰 무작위 upgrade tree를 그대로 복제하지 않는다.
- **주의:** closed beta 공지의 Blessing/Curse 규칙을 현재 정식 규칙처럼 인용하지 않는다.

## 2.2 Brotato

### 시스템 구조

| 범주 | 조사 결과 |
| --- | --- |
| 스테이지·런 | 20개의 짧은 wave와 wave 사이 shop을 반복한다. Wave 1은 20초이고 점차 길어져 9~19는 60초, 20은 90초다. 전투와 안전한 의사결정의 경계가 매우 명확하다. |
| 캐릭터 | 커뮤니티 위키 현재 표기는 62명이다. Bull은 무기를 쓰지 않고 피격 폭발, Soldier는 움직이는 동안 공격 불가, Multitasker는 최대 12무기, Loud는 적 수를 늘리는 식으로 규칙 자체를 바꾼다. |
| 적 | chaser, spitter, charger, buffer, healer, looter 등 역할이 짧은 wave 안에서 읽히며 elite와 horde wave가 서로 다른 빌드 시험을 만든다. |
| 스킬·아이템 | 아이템은 수치와 economy를 조합하지만, character rule과 weapon class bonus가 빌드 방향을 강하게 제한한다. crate는 전투 중의 보상 사건이다. |
| 무기 | 기본 최대 6개다. 같은 tier 무기 두 개를 결합해 T4까지 올리고, 같은 class를 2~6개 모으면 class bonus가 성장한다. |
| 선택 규칙 | shop은 4개 offer, reroll, lock을 제공한다. 첫 두 shop은 정확히 2 weapons + 2 items, 3~5번째 shop은 최소 1 weapon을 보장한다. 무기 후보도 같은 무기·같은 class에 확률 bias가 있다. |
| 보스·압력 | Danger 4/5의 지정 wave가 elite 또는 horde 시험이 된다. elite는 legendary T4 crate와 큰 회복을 주고, horde는 더 많은 적 대신 개체당 material을 낮춘다. |

**행별 근거:** 기본 런·무기 상한은
[A: Steam](https://store.steampowered.com/app/1942280/Brotato/), wave 시간과 특수 wave는
[C: Waves](https://brotato.wiki.spellsandguns.com/Waves)와
[C: Horde Wave](https://brotato.wiki.spellsandguns.com/Horde_Wave), 캐릭터는
[C: Characters](https://brotato.wiki.spellsandguns.com/Characters), 적 역할은
[C: Enemies](https://brotato.wiki.spellsandguns.com/Enemies), 무기 결합·class는
[C: Weapons](https://brotato.wiki.spellsandguns.com/Weapons), offer 규칙은
[C: Shop](https://brotato.wiki.spellsandguns.com/Shop), elite 보상은
[C: Crate](https://brotato.wiki.spellsandguns.com/Crate)에서 확인했다.

shop의 같은 무기 20%, 같은 class 15%, 전체 65% 같은 세부 확률은 커뮤니티 위키 기준이며
버전에 민감하다
([C: Shop](https://brotato.wiki.spellsandguns.com/Shop)). 중요한 구조는 “완전 랜덤”이 아니라
초반 성립 보장과 이미 선택한 방향 bias가 동시에 있다는 점이다.

### Cardborne에 주는 의미

- **전이:** 짧은 authored pressure test와 안전한 선택 시점을 분리한다.
- **전이:** 카드 offer는 기존 빌드 계보를 향해 bias하되 reroll이 없어도 성립 실패를 방지한다.
- **전이:** horde와 elite를 단순 난이도 차가 아니라 서로 다른 화력 시험과 보상으로 정의한다.
- **배제:** 6무기 shop economy와 자동 발사 중심의 min-max를 옮기지 않는다.

## 2.3 Vampire Survivors

### 시스템 구조

| 범주 | 조사 결과 |
| --- | --- |
| 스테이지·런 | Mad Forest 같은 기본 stage는 약 30분의 scripted timeline을 사용한다. 적은 네 방향에서 들어오고, 시간에 따라 wave, boss, chest, map event가 바뀐다. |
| 캐릭터 | 캐릭터는 시작 무기와 성장 수치 조합으로 초반 방향을 고정한다. Antonio/Whip, Imelda/Magic Wand 같은 연결이 level-up 후보와 플레이 거리의 출발점이 된다. |
| 적 | swarm, 더 단단한 wave, boss, 밀어붙이는 Bat Swarm 같은 timed event가 공격 범위와 이동 시험을 바꾼다. 개별 AI보다 wave 구성과 밀도가 위협 문법을 만든다. |
| 스킬·패시브 | 보통 6 weapon + 6 passive slot을 사용한다. level-up은 3개 또는 4개의 중복 없는 선택지를 주고, full/max 조건을 제외하며 reroll, skip, banish, seal로 풀을 통제한다. |
| 무기 | 무기는 자동이지만 공격 기하가 분명하다. Whip은 좌우 sweep, Magic Wand는 추적, Knife는 방향 사격, Axe는 포물선, Garlic은 근접 aura다. |
| 진화 | max base weapon + 대응 passive + eligible chest를 갖추면 evolution이 기존 무기를 교체한다. Whip은 lifesteal·critical, Magic Wand와 Knife는 delay 제거, Axe는 관통 원형 projectile로 질적 변화를 얻는다. |
| 보스·보상 | boss와 chest는 타임라인 punctuation인 동시에 준비된 조합을 실제 진화로 전환하는 장치다. |

**행별 근거:** 기본 run과 최소 조작 방향은
[A: Steam](https://store.steampowered.com/app/1794680/Vampire_Survivors/), Mad Forest 시간표와
wave는 [C: Mad Forest](https://vampire-survivors.fandom.com/wiki/Mad_Forest), 캐릭터의 시작
무기 연결과 적 계층은 [C: Weapons](https://vampire-survivors.fandom.com/wiki/Weapons)와
[C: Enemies](https://vampire-survivors.fandom.com/wiki/Enemies), 선택 통제는
[C: Level up](https://vampire-survivors.fandom.com/wiki/Level_up), passive·진화 조건은
[C: Passive items](https://vampire-survivors.fandom.com/wiki/Passive_items)와
[C: Evolution](https://vampire-survivors.fandom.com/wiki/Evolution)에서 확인했다.

### Cardborne에 주는 의미

- **전이:** 준비 조건과 boss/chest 시점을 연결해 예측 가능한 “변신 시점”을 만든다.
- **전이:** scripted wave는 단지 적을 공급하지 않고 방금 얻은 성장의 power test가 되어야 한다.
- **배제:** 자동 전투, 6+6 slot, 화면 전체를 덮는 이펙트 양을 그대로 옮기지 않는다.

## 2.4 Halls of Torment

### 시스템 구조

| 범주 | 조사 결과 |
| --- | --- |
| 스테이지·런 | 공식 기본 설명은 6 stages와 약 30분 run을 제시한다. Ember Grounds는 커뮤니티 위키 기준 23:50, 13:50, 5:50에 boss, 0:00에 Lord가 등장하며 중간 elite가 리듬을 나눈다. |
| 캐릭터 | 공식 기본 범위는 11 characters/marks다. 각 hero는 고유 main weapon과 trait를 가진다. 예를 들어 Norseman은 dual axes와 반복 hit 기반 Frost Nova처럼 공격 리듬이 캐릭터 사건으로 이어진다. DLC를 포함한 위키 총량과 공식 기본 총량은 구분해야 한다. |
| 적 | 70+ monsters와 35+ bosses를 공식 표기한다. 일반 군집, elite, 여러 boss, final Lord가 시간표상 서로 다른 압력 계층이다. |
| 스킬 | 최대 6 abilities를 들 수 있고 Tome/Scroll 획득으로 능력을 추가한다. ability rank III/VI가 upgrade 조건이 되며 보통 능력별 두 갈래 강화가 있다. |
| 무기 | hero main weapon이 기본 행동을 고정하고, ability가 별도 공격 축을 만든다. 1,000+ traits라는 공식 규모는 작은 변화의 누적 폭을 담당한다. |
| 지형·비밀 | 각 hall의 Secret은 final boss에 직접 영향을 준다. invulnerability 제거, 공격 단순화, bomb damage 비활성, relay monolith로 Lord와 일반 적에게 큰 피해 같은 방식이다. |
| 보스 | Lord of Pain은 mounted/on-foot 두 상태와 두 HP bar를 사용한다. The Vault는 네 pylon을 파괴해야 boss가 열리는 objective boss다. 즉 phase가 새 상태나 목표로 바뀐다. |

**행별 근거:** 공식 기본 콘텐츠 수와 run 방향은
[A: Steam](https://store.steampowered.com/app/2218750/Halls_of_Torment/), hall과 Ember Grounds
시간표는 [C: Hall](https://hot.fandom.com/wiki/Hall)과
[C: Ember Grounds](https://hot.fandom.com/wiki/Ember_Grounds), hero는
[C: Hero](https://hot.fandom.com/wiki/Hero), ability·trait 단계는
[C: Ability](https://hot.fandom.com/wiki/Ability)와
[C: Trait](https://hot.fandom.com/wiki/Trait), 환경 비밀은
[C: Secret](https://hot.fandom.com/wiki/Secret), boss의 상태·objective는
[C: Lord of Pain](https://hot.fandom.com/wiki/Lord_of_Pain)과
[C: The Vault](https://hot.fandom.com/wiki/The_Vault)에서 확인했다.

### Cardborne에 주는 의미

- **전이:** stage에서 준비한 환경 행동이 final boss의 방어·공격 규칙을 바꾸게 한다.
- **전이:** phase는 패턴 재배열이 아니라 탈것 상실, shield 해제, objective 전환 같은 semantic state여야 한다.
- **배제:** 1,000+ traits와 수백 변종 아이템의 콘텐츠 폭은 옮기지 않는다.

## 2.5 Soulstone Survivors

### 시스템 구조

| 범주 | 조사 결과 |
| --- | --- |
| 스테이지·런 | Void Fields는 다섯 map에서 quota와 1~4 Void Lord를 반복하며 단계별로 더 높은 soulstone을 준다. 13분 이내면 Overlord red portal, 15분 이내면 endless yellow portal처럼 clear speed가 선택형 고난도 경로를 연다. |
| 캐릭터 | 커뮤니티 위키 현재 표기는 23 characters다. 각 캐릭터는 weapon rarity progression을 가지며 weapon이 시작·special skill과 이후 skill pool에 영향을 준다. |
| 적 | 대량 일반 적과 반복 Void Lord, Titan, Overlord가 계층을 이룬다. Curse가 같은 map의 압력과 보상을 바꾼다. |
| 스킬 | 최대 6 active skills와 passive powers를 사용한다. reroll, banish, lock으로 후보를 통제하며 rune은 유연성과 힘 사이의 trade-off를 만든다. |
| 무기 | 공식 표기는 100+ crafted weapons다. 무기는 단순 damage item이 아니라 시작 스킬과 후보 풀을 함께 바꾼다. |
| 성장 | 공식 표기는 350+ skills다. 방대한 태그·시너지로 공격 규모가 급격히 커지지만, 핵심은 보스와 mode가 별도 보상 계층을 연다는 점이다. |
| 보스 | Titan Hunt는 Titanic Power를 주고, 후속 Netherworld 경로를 연다. Void King은 새 공격, 겹치는 AoE, 환경 위협을 더하는 3 phases를 사용한다. |

**행별 근거:** 공식 skill·weapon 규모와 boss 방향은
[A: Steam](https://store.steampowered.com/app/2066020/Soulstone_Survivors/), map·Lord 진행은
[C: Void Fields](https://soulstone-survivors.fandom.com/wiki/Void_Fields), 캐릭터·무기는
[C: Characters](https://soulstone-survivors.fandom.com/wiki/Characters)와
[C: Weapons](https://soulstone-survivors.fandom.com/wiki/Weapons), active/passive 선택 통제는
[C: Active Skills](https://soulstone-survivors.fandom.com/wiki/Active_Skill),
[C: Powers](https://soulstone-survivors.fandom.com/wiki/Powers),
[C: Runes](https://soulstone-survivors.fandom.com/wiki/Runes), boss·보상 경로는
[C: Titan Hunt](https://soulstone-survivors.fandom.com/wiki/Titan_Hunt)와
[C: Overlord](https://soulstone-survivors.fandom.com/wiki/Overlord)에서 확인했다.

### Cardborne에 주는 의미

- **전이:** boss reward를 일반 수치 카드와 다른 power class로 분리한다.
- **전이:** 빠른 처치 속도가 optional challenge와 보상으로 이어지게 하면 성장의 효용을 시간으로 체감할 수 있다.
- **배제:** 350+ skills, 100+ weapons, 여러 meta tree를 목표 규모로 삼지 않는다.

## 2.6 Deep Rock Galactic: Survivor

### 시스템 구조

| 범주 | 조사 결과 |
| --- | --- |
| 스테이지·런 | Elimination은 5 stages다. Stage 1~4는 각각 1/2/3/3 wave와 elite를 거치고 Stage 5에서 네 elite와 Dreadnought를 상대한다. cocoon은 일찍 터뜨려 위험을 앞당길 수도 있다. |
| 캐릭터 | class mod가 starting weapon과 weapon pool을 정한다. 따라서 캐릭터 선택은 외형보다 런의 후보 공간을 조절한다. |
| 적 | swarm, elite, Dreadnought가 objective와 extraction 사이에 들어온다. 동굴 지형 때문에 같은 적도 접근 방향과 포위가 달라진다. |
| 스킬 | mid-dive upgrades 외에 weapon level 6/12/18에서 overclock이 열린다. 캐릭터 level 5/15/25에서 새 weapon을 얻어 성장 시점이 예측 가능하다. |
| 무기 | 자동 공격이지만 방향, 범위, elemental tag, overclock으로 역할이 갈린다. 성장 milestone이 무기 규칙을 바꾼다. |
| 지형 | terrain을 파서 길, arena, 자원 접근을 직접 만든다. Magma Core의 lava/explosive plants, Salt Pits의 crystal을 캐서 떨어뜨리는 stalactite처럼 지형이 적 처리 수단이 된다. |
| 보스·목표 | wave, elite, objective, supply pod, extraction, Dreadnought가 한 stage 안의 서로 다른 의사결정 사건이다. |

**행별 근거:** 기본 게임 방향은
[A: Steam](https://store.steampowered.com/app/2321470/Deep_Rock_Galactic_Survivor/), 5-stage
Elimination과 boss 흐름은
[B: Elimination](https://deeprockgalactic.wiki.gg/wiki/Survivor%3AElimination), class mod와
무기는 [B: Equipment](https://deeprockgalactic.wiki.gg/wiki/Survivor%3AEquipment), 성장 milestone은
[B: Overclocks](https://deeprockgalactic.wiki.gg/wiki/Survivor%3AOverclocks)와
[B: Mid-dive Upgrades](https://deeprockgalactic.wiki.gg/wiki/Survivor%3AMid-dive_Upgrades), 지형은
[B: Biomes](https://deeprockgalactic.wiki.gg/wiki/Survivor%3ABiomes), objective는
[B: Objectives](https://deeprockgalactic.wiki.gg/wiki/Survivor%3AObjectives)에서 확인했다.

### Cardborne에 주는 의미

- **전이:** 환경은 배경이 아니라 길 만들기, 자원, 적 처리, objective 중 둘 이상을 연결해야 한다.
- **전이:** overclock처럼 모든 런에서 읽히는 고정 milestone을 둔다.
- **배제:** 전면 자동 공격, procedural cave mining, extraction game 전체를 옮기지 않는다.

## 2.7 Deep Rock Galactic: Survivor — Heavy Duty

Heavy Duty는 2026-04-30 출시된 vehicle-specific 공식 확장으로, Cardborne과 입력 방식은 다르지만
차량의 방향성과 무리 처리 방식에서는 가장 가까운 외부 비교다.

### 시스템 구조

| 범주 | 조사 결과 |
| --- | --- |
| 스테이지·런 | 별도 campaign에서 Glacial Strata와 Egg Hunt objective를 사용한다. Egg를 수집한 뒤 pod로 돌아오는 star route와 quota 이후 추가 보상을 위한 grace가 있다. |
| 차량 정체성 | Demolisher Rockdozer 자체가 swarm을 깔아뭉갠다. Contractor는 fire/structure, Gridrunner는 speed/electric, Operator는 drones/control에 집중한다. |
| 적 | cryo enemies와 relentless waves가 지형·objective를 압박한다. 마지막 Brood Nexus는 일반 적을 완전히 지우지 않고 boss와 swarm을 결합한다. |
| 무기 | 공식 공지는 11개를 열거한다. 전면 saw, carrier drone, 후방 flame trail, chain lightning, side beams, proximity mine, ground sludge, slither drones, scattergun, branching frag cannon, rear persistent electric field가 차량의 전후좌우를 무기 문법으로 사용한다. |
| 스킬·성장 | 각 vehicle mod와 weapon pool이 공격 방향, 상태 효과, 소환, 지면 hazard를 조합한다. 무기 수보다 “차체 어느 면과 이동 궤적이 공격인가”가 중요하다. |
| 지형 | ice는 속도와 제어를 바꾸고, crystal을 부수면 icicle이 떨어져 monster를 처치한다. 이동과 파괴가 같은 전투 행동으로 묶인다. |
| 보스 | Brood Nexus는 multi-phase이며, Nexus Sprouts를 파괴하기 전에는 core가 invulnerable이다. relentless swarm 속에서 objective target을 골라야 한다. |

**행별 근거:** 출시일, campaign·vehicle mod·11 weapons·Glacial Strata·Egg Hunt·Brood Nexus는
[A: Heavy Duty Steam](https://store.steampowered.com/app/4395500/Deep_Rock_Galactic_Survivor__Heavy_Duty_Expansion/)과
[A: 공식 출시 공지](https://store.steampowered.com/news/posts/?enddate=1773351305&feed=steam_community_announcements)를
교차 확인했다. 이 표는 커뮤니티 위키 수치를 사용하지 않는다.

### Cardborne에 주는 의미

- **전이:** 차체 전면, 측면, 후방, 이동 궤적을 서로 다른 공격 geometry로 사용한다.
- **전이:** boss, swarm, objective를 동시에 두어 주무기의 표적 우선순위와 자동 보조 무기의 군집 처리를 함께 시험한다.
- **전이:** 지형 파괴가 즉시 적 처치로 이어지는 읽기 쉬운 one-shot interaction을 만든다.
- **배제:** 전면 자동 조준, 완전 파괴 지형, 한 차량에 11무기를 모두 쌓는 구조를 옮기지 않는다.

## 2.8 Yet Another Zombie Survivors

### 시스템 구조

| 범주 | 조사 결과 |
| --- | --- |
| 스테이지·런 | 공식 현재 표기는 3 maps, 5 modes다. default 20분, hardcore 10분, one-hit 5분, endurance, boss rush로 같은 핵심 전투를 다른 압력 곡선에서 시험한다. 정식 출시 예정일은 2026-08-20이다. |
| 캐릭터 | 최대 3명의 survivor squad를 구성한다. leader는 perk를 전부, 구조된 동료는 절반만 적용받아 조합과 순서가 역할을 만든다. |
| 적 | Boomer의 사후 gas, spider/slime의 slow field, scarab explosion처럼 죽은 뒤에도 공간 상태를 남기는 적이 있다. Mummy는 포위하고 Charger는 명확한 돌진을 예고한다. |
| 스킬 | 공식 현재 표기는 8 characters, 32 abilities와 능력별 2 evolutions다. 자동화된 squad 안에서도 evolution이 역할을 확대한다. |
| 무기 | 공식 현재 표기는 40 weapons다. squad 구성원과 weapon/ability 조합이 화면 역할을 분담한다. |
| 지형 | Desert Worm은 죽일 수 없는 map hazard이며 zombie도 피해를 입는다. 맵 장치가 플레이어와 적 모두에게 공간 위험이 된다. |
| 보스 | Witch의 비행, Charger의 telegraph 등 이동 규칙이 일반 군집과 다른 target-priority 사건을 만든다. boss rush는 그 사건만 압축한다. |

**행별 근거:** 현재 콘텐츠 총량·출시 상태는
[A: Steam](https://store.steampowered.com/app/2163330/Yet_Another_Zombie_Survivors/), squad·캐릭터는
[C: Survivors](https://yetanotherzombie.wiki.gg/wiki/Survivors), 적의 사후 상태와 boss 행동은
[C: Enemies](https://yetanotherzombie.wiki.gg/wiki/Enemies_%28Survivors%29), mode 시간은
[C: Game modes](https://yetanotherzombie.wiki.gg/wiki/Game_modes_%28Survivors%29), Desert Worm과
map 구조는 [C: Maps](https://yetanotherzombie.wiki.gg/wiki/Maps)에서 확인했다.

현재 Steam 총량과 일부 위키의 7 characters/2 maps 표기는 시점이 다르므로 현재 총량은 공식 Steam을
우선했다
([A: Steam](https://store.steampowered.com/app/2163330/Yet_Another_Zombie_Survivors/),
[C: overview](https://yetanotherzombie.wiki.gg/wiki/Yet_Another_Zombie_Survivors)).

### Cardborne에 주는 의미

- **전이:** 적의 사망이 gas, slow, chain explosion처럼 다음 공간 상태를 만들게 하면 군집을 어디서
  죽일지가 중요해진다.
- **전이:** 각 field에 하나의 강한 shared hazard를 두고 적에게도 작용하게 한다.
- **배제:** 3인 squad와 자동 조준·자동 발사로 수동 차량 정체성을 대체하지 않는다.

## 2.9 Nova Drift

Nova Drift는 survivor-like보다 arcade shooter 쪽에 가깝지만, 수동 차량 조작과 짧은 런 안의
모듈식 성장이라는 점에서 Cardborne의 성장 질을 판단하는 핵심 비교다.

### 시스템 구조

| 범주 | 조사 결과 |
| --- | --- |
| 스테이지·런 | 빠른 campaign/endless run에서 전투 중 upgrade를 고른다. arena가 이어지며 enemy formation과 boss가 build를 시험한다. |
| 차체 정체성 | Gear의 세 축은 Weapon + Shield + Body다. Carrier는 summon, Leviathan은 성장하는 body, Firefly는 thruster burn, Halo는 burn radius, Warp는 teleport blast처럼 이동·방어·공격을 서로 바꾼다. |
| 적 | 공식 Enemies 2.0 설명은 Orbit, Flank, Support 같은 curated formation과 동적 조합을 강조한다. 적 수보다 형성이 player build의 약점을 찌른다. |
| 스킬 | 200+ modular upgrades가 있지만 무작위 수치만 쌓지 않는다. prerequisite를 갖추면 Super Mod가 후보 풀에 들어와 여러 계보를 하나의 새 규칙으로 결합한다. |
| 무기 | Thermal Lance, Swords, grenade 등 입력·거리·위험이 다르다. 공식 build 예시는 Grenade + Heat Seeking + splinter로 elite focus와 crowd clear를 함께 만들고, Hullbreaker + Amp + Volatile Shield는 collision과 shield break를 공격으로 바꾼다. |
| 질적 진화 | Barrage는 bullet hose, Singular Strike는 투사체를 거대한 한 발로 합치고, Charged Mines는 mine detonation에 weapon을 발사한다. Dying Star, Void Slice, Sanctuary, Antimatter처럼 기존 subsystem 사이의 관계를 바꾸는 Super Mod가 있다. |
| 보스 | boss는 formation 전투 사이의 build check다. 정확한 최신 spawn schedule은 공식 자료에서 확정하지 않고, 패턴 수치보다 준비한 modular rule의 상호작용에 주목했다. |

**행별 근거:** 기본 run과 200+ modular upgrades는
[A: Steam](https://store.steampowered.com/app/858210/Nova_Drift/)과
[A: 공식 사이트](https://www.novadrift.io/), Gear·공식 build 예시는
[A: Cosmic Powers](https://blog.novadrift.io/nova-drift-cosmic-powers/), enemy formation은
[A: Enemies 2.0](https://blog.novadrift.io/enemies20/), 현재 변화 확인은
[A: 패치 노트](https://blog.novadrift.io/patch-notes/), Super Mod 세부 예시는
[C: Super Mods](https://nova-drift.fandom.com/wiki/Super_Mods)와
[C: Upgrade List](https://nova-drift.fandom.com/wiki/Upgrade_List)에서 확인했다.

### Cardborne에 주는 의미

- **전이:** prerequisite를 충족한 두 계보를 이름 있는 rule-changing evolution으로 결합한다.
- **전이:** movement, defense, primary fire, mine 같은 기존 subsystem 사이의 관계를 바꿔야 진화가 된다.
- **전이:** 적 formation을 단위로 authored해 단일 대상과 crowd clear 양쪽을 시험한다.
- **배제:** 200+ 모듈, 화면 wrap, 과도한 self-damage, 무작위 campaign 폭을 목표로 삼지 않는다.

## 3. 교차 비교

### 3.1 시스템별 핵심 역할

| 시스템 | 강한 레퍼런스에서 하는 일 | Cardborne 현재 상태 | 핵심 격차 |
| --- | --- | --- | --- |
| 스테이지 | 성장 전후를 구분하는 scripted test, elite/horde/boss punctuation, objective | authored quota와 패킷, stage boss, optional reward plumbing | 패킷은 성장 전후의 시험으로 명명·배치되지 않고 optional field boss 의도는 live encounter에 미구현 |
| 캐릭터·차체 | 시작 후보 풀과 플레이 규칙을 잠금 | 하나의 차량과 런 중 카드 방향 | 고정 캐릭터가 문제는 아니지만 run 초반 방향 lock이 약함 |
| 적 | 개별 역할을 formation과 wave 문법으로 조합 | 역할은 풍부하나 cyclic role fill과 분산 anchor | 읽히는 전선과 한 번에 지울 수 있는 덩어리 부족 |
| 스킬·카드 | 성립 보장 → 계보 투자 → 예측 가능한 evolution | 성립 보장과 behavior bias는 있으나 boss 전용 진화 없음 | 수치 성장과 규칙 변화 사이의 milestone 부재 |
| 무기 | 사거리·방향·위험·차체 이동을 서로 다른 geometry로 사용 | 수동 primary + 자동 seeker + 최대 2 optional | 무기 수보다 계보 결합과 대량 처리 geometry가 부족 |
| 지형 | 길·자원·적 처리·objective 중 둘 이상 연결 | Arc, bulkhead, gate, repair, overdrive, mine chain | 플레이어가 닫는 환경 처치 루프와 성장 보상 연결 부족 |
| 보스 | arena rule, semantic phase, objective, 전용 보상 | generic pattern ordering, 수치 cadence, 일반 카드 offer | 보스마다 새로 배울 규칙과 전투 후 변신이 약함 |

### 3.2 반복해서 확인된 여섯 가지 구조

1. **초반 방향 고정**
   - 시작 무기·캐릭터·class mod 또는 초반 보장 shop이 후보 공간을 빠르게 줄인다.
   - 선택지가 많아도 플레이어는 “이번 런은 무엇을 하는 빌드인가”를 일찍 안다.

2. **예측 가능한 질적 breakpoint**
   - weapon level 20, overclock level 6/12/18, max weapon + passive + chest,
     prerequisite Super Mod처럼 준비와 도착 시점이 연결된다.
   - 단순 damage 증가가 아니라 탄도, 공격 방향, 대상 수, 위험과 보상의 관계가 바뀐다.

3. **성장 직후의 power test**
   - horde wave, elite, scripted wave, objective가 방금 얻은 힘을 확인시킨다.
   - 강해졌음을 UI 수치가 아니라 이전에 막히던 적 덩어리가 무너지는 속도로 보여 준다.

4. **보상 계층 분리**
   - 일반 level-up, chest, character upgrade, Tome, evolution, Titanic Power는 역할이 다르다.
   - boss reward가 일반 제안과 같으면 boss의 진행·성장 의미가 약해진다.

5. **환경의 전투 동사화**
   - 지형은 단순 피해 장판이 아니라 길을 만들고, 적을 모으고, 위험을 앞당기고,
     대량 처치를 만들거나 boss 상태를 바꾼다.

6. **semantic boss phase**
   - 새 HP bar, 탈것 상실, shield objective, invulnerable core와 adds, arena rule처럼
     phase 전환 후 플레이어의 목표 문장이 달라진다.
   - “같은 네 패턴이 더 빠르게 나옴”은 phase가 아니라 난이도 ramp다.

### 3.3 Cardborne의 근본적인 하이브리드 부담

Cardborne은 두 장르의 비용을 동시에 받는다.

- 수동 shooter의 비용: 조준, 이동, Breach 준비, dash, EMP, 우선 표적 판단
- survivor-like의 비용: 많은 적, 반복 성장, 긴 run 동안 누적되는 쿼터

하지만 현재 보상은 각 장르의 가장 강한 보상에 아직 충분히 도달하지 않는다.

- Nova Drift와 20 Minutes Till Dawn 수준의 **수동 공격 규칙 변신**
- Vampire Survivors와 Soulstone Survivors 수준의 **군집 삭제 가속**
- Halls of Torment와 Heavy Duty 수준의 **보스·지형 규칙 결합**

따라서 단순히 적 수나 카드 수를 더하면 두 비용만 더 커질 수 있다. 필요한 것은 기존 시스템 사이의
연결 강도를 높이는 것이다.

## 4. 원인 우선순위

### P0 — 질적 성장 시점이 보장되지 않는다

현재 offer는 제약 랜덤이 맞고 행동 카드도 있다. 그러나 제약이 “안전한 세 장”을 만들 뿐,
“이 시점에 이번 빌드가 다른 규칙으로 변한다”를 보장하지 않는다. boss가 같은 풀을 다시 제시해
이 약점을 강화한다.

### P0 — 활성 수가 전투 가능한 군집으로 나타나지 않는다

후반 beat의 최대 92 active enemies와 8 squad packet이 있어도 넓은 필드와 분산 anchor 때문에
한 화면·한 방향의 engaged density가 낮을 수 있다. 이는 성능 상한을 올리지 않고도 encounter
authoring으로 개선할 수 있는 가장 큰 여지다.

### P0 — 보스 phase가 목표를 바꾸지 않는다

공통 패턴 문법과 수치 ramp는 가독성과 제작 효율에는 좋지만, 다섯 보스의 전투 문장을 같게 만든다.
보스별 arena rule, objective target, 취약 상태, 군집 관계, reward class가 필요하다.

### P1 — 환경 상호작용이 닫힌 처치 루프가 아니다

Arc, bulkhead, gate, mine chain은 존재하지만 `몰기 → 압축 → 의도적 trigger → 다수 처치 →
XP 수확`을 하나의 읽히는 사건으로 만들지 않는다.

### P1 — 대량 처치가 성장의 증거로 계측·보상되지 않는다

현재 성능 측정과 encounter contract는 actor count와 안정성은 확인하지만, 다음은 확인하지 않는다.

- 플레이어 주변 600/900px의 실제 engaged count
- 1초·2초 내 최대 처치 수
- rolling 5-second kills per second
- environment chain 길이와 피해 기여
- 진화 전후 동일 formation의 처리 시간
- boss phase별 유효 행동 시간과 무력한 대기 시간

### P2 — 콘텐츠 폭

새 캐릭터 수십 명, 무기 수백 개, meta tree는 현재 핵심 문제를 해결하지 않는다. 기존 46개 카드,
현재 적 역할, 세 필드, 다섯 보스를 재조합해도 먼저 검증할 수 있다.

## 5. 전이 결정

| 판단 | 구조 | 이유 |
| --- | --- | --- |
| 유지 | 수동 조준, held primary, 1초 Breach, dash, EMP, 자동 seeker | 현재 게임의 능동적 target-priority 정체성 |
| 유지 | 5-stage authored run과 제한된 카드 제안 | 짧은 캠페인과 의사결정 경계를 이미 제공 |
| 복구·구현 | repository guidance의 optional field boss 의도 | reward plumbing은 있으나 live encounter가 없으므로 기존 기능처럼 가장하지 않고 별도 범위로 구현 |
| 유지 | 적 역할과 active cap | 역할 폭과 성능 예산은 이미 충분한 출발점 |
| 강화 | 카드 제약 랜덤 | 성립 보장뿐 아니라 계보·진화 eligibility를 명시 |
| 강화 | packet authoring | 8개의 흩어진 anchor보다 2~3개의 읽히는 pressure front로 군집화 |
| 강화 | Breach, Arc, bulkhead, mine | 같은 동사를 적 압축·기폭·보상에 연결 |
| 교체 | 일반 카드와 거의 같은 boss offer | prepared build를 바꾸는 boss-only evolution offer |
| 교체 | 패턴 순서·속도만 바뀌는 phase | objective·취약 조건·arena state가 바뀌는 semantic phase |
| 추가 | engaged-density와 kill-burst telemetry | “적이 많다”와 “쓸어버렸다”를 분리 측정 |
| 배제 | 우선 active cap 상향 | 현재 병목이 밀도인지 수량인지 측정 전에는 성능과 가독성만 악화 |
| 배제 | 전면 자동 조준·6개 이상 무기 | 수동 슈팅 정체성과 첫 클리어 판독성을 희석 |
| 배제 | full procedural destruction/mining | 세 authored field와 collision truth를 과도하게 확장 |
| 배제 | HP·속도만 올린 boss | 현재 보스의 동일성 문제를 해결하지 않음 |
| 배제 | 수백 카드·캐릭터·meta currency | 연결 구조보다 콘텐츠 폭을 먼저 늘리는 해결책 |

## Recommendations

조사에서 도출한 Cardborne의 목표 전투 문장은 다음과 같다.

> **유도한다 → 압축한다 → 기폭한다 → 한 덩어리를 지운다 → XP를 수확한다 →
> 준비한 빌드가 진화한다 → 다음 보스가 그 규칙을 시험한다.**

이를 위해 후속 초안은 다음 다섯 축을 동시에 다뤄야 한다.

1. **Foundation → Specialization → Evolution**의 세 성장 계층
2. 같은 active cap 안에서 2~3개 front로 밀집하는 authored formation
3. field마다 하나씩 있는 의도적 enemy-processing interaction
4. objective와 arena state가 바뀌는 boss phase
5. boss 전용 evolution reward와 kill-burst telemetry

한 축만 고치면 루프가 닫히지 않는다. 예를 들어 evolution만 추가하고 적이 흩어져 있으면 대량 처치를
보여 줄 대상이 없고, 지형 피해만 늘리고 보상과 growth를 연결하지 않으면 우연한 무료 피해가 된다.

구체 요구사항과 vertical-slice 판정 기준은
[`combat-growth-improvement-direction.md`](../docs/product/combat-growth-improvement-direction.md)에
기록한다.

## Limitations

- 현재 분석에는 실제 플레이어 세션의 stage duration, engaged density, KPS, build 선택률 로그가 없다.
  따라서 쿼터와 피해량의 최종 수치는 구현 전 deterministic simulation과 플레이테스트가 필요하다.
- 외부 게임의 세부 수치와 총 콘텐츠 수 일부는 B/C 등급 위키 근거다. 구조적 비교에는 사용했지만
  Cardborne의 수치 목표로 직접 복사하지 않았다.
- 20 Minutes Till Dawn의 Blessings & Curses는 공식 closed beta 공지까지만 확인되었으며
  안정 출시 규칙으로 취급하지 않았다.
- Halls of Torment와 Yet Another Zombie Survivors의 공식 총량과 위키 총량은 DLC·업데이트 시점이
  달라, 현재 수량은 공식 Steam을 우선했다.
- 기존 성능 근거는 현재 구현의 actor budget을 지지한다. 새 horde formation과 boss adds는 같은
  cap 안에서 먼저 검증해야 하며, cap 증가는 별도 근거가 생기기 전까지 권고하지 않는다.

## Research Completion

조사의 stop condition은 충족되었다. 현재 구현의 네 핵심 영역을 코드로 확인했고, 각 외부 게임을
요청된 일곱 범주로 분해했으며, 모든 추천을 하나 이상의 현재 사실과 하나 이상의 외부 구조에
연결했다. 남은 불확실성은 조사 누락이 아니라 플레이 데이터가 필요한 tuning 문제다.
