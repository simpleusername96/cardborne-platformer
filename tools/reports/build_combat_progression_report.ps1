$ErrorActionPreference = "Stop"

$repo = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$output = Join-Path $repo "docs/reports/2026-08-18-combat-progression-and-upgrades-ko.html"
$locale = @{}
Import-Csv (Join-Path $repo "localization/vehicle_stage.csv") | ForEach-Object { $locale[$_.keys] = $_.ko }

function Encode([string]$value) { [System.Net.WebUtility]::HtmlEncode($value) }
function Match-One([string]$text, [string]$pattern) {
    $match = [regex]::Match($text, $pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if ($match.Success) { return $match.Groups[1].Value }
    return ""
}
function Array-Text([string]$text, [string]$name) {
    return Match-One $text ("(?m)^" + [regex]::Escape($name) + "\s*=\s*Array\[[^\]]+\]\(\[([^\]]*)\]\)")
}

$categoryNames = @{ primary='주무기'; secondary='자동 무기'; element='속성'; activated='발동 무기(CC 전용)'; chassis='기체'; combat='전투 조건' }
$cards = @()
Get-ChildItem (Join-Path $repo "data/cards/vehicle") -Filter *.tres | Sort-Object Name | ForEach-Object {
    $text = [IO.File]::ReadAllText($_.FullName)
    $id = Match-One $text '(?m)^id = &"([^"]+)"'
    $titleKey = Match-One $text '(?m)^title_key = "([^"]+)"'
    $category = Match-One $text '(?m)^category = &"([^"]+)"'
    $max = [int](Match-One $text '(?m)^max_level = (\d+)')
    $rows = @()
    [regex]::Matches($text, '(?ms)\[sub_resource[^\]]+\]\s*(.*?)(?=\[sub_resource|\[resource\])') | ForEach-Object {
        $block = $_.Groups[1].Value
        $stat = Match-One $block '(?m)^stat_id = &"([^"]+)"'
        $values = Array-Text $block 'values_by_level'
        if ($stat -and $values) { $rows += "$(Encode $stat): $(Encode $values)" }
    }
    Get-ChildItem (Join-Path $repo "data/weapons/vehicle") -Recurse -Filter *.tres | ForEach-Object {
        $weapon = [IO.File]::ReadAllText($_.FullName)
        if ($weapon -match ('(?m)^upgrade_id = &"' + [regex]::Escape($id) + '"')) {
            [regex]::Matches($weapon, '(?m)^(\w+_by_level)\s*=\s*Array\[[^\]]+\]\(\[([^\]]*)\]\)') | ForEach-Object {
                $rows += "$(Encode $_.Groups[1].Value): $(Encode $_.Groups[2].Value)"
            }
        }
    }
    if ($id -eq 'split_muzzle') { $rows += '총 탄환 수: 2, 2, 3, 3, 3, 3 · 총 피해: 140%, 155%, 165%, 184%, 204%, 234%' }
    if ($id -eq 'piercing_rounds') { $rows += '추가 관통 수: 1, 1, 2, 2, 3, 3, 4' }
    if ($rows.Count -eq 0) { $rows += '런타임 효과가 레벨별로 점진 강화됨' }
    $cards += [pscustomobject]@{ Id=$id; Title=($locale[$titleKey] ?? $id); Category=$category; Max=$max; Rows=$rows }
}

$roles = @(
 @('근거리 일반 적 Lv.1',18,190),@('원거리 일반 적 Lv.1',14,176),@('범위 일반 적 Lv.1',12,100),
 @('탄막 일반 적 Lv.1',40,166),@('방어 일반 적 Lv.1',90,164),@('휩쓸기 일반 적 Lv.1',66,238),
 @('광선 일반 적 Lv.1',72,148),@('성장 일반 적 Lv.1',62,140),@('틈새 일반 적 Lv.1',60,150),
 @('파동 일반 적 Lv.1',96,157),@('측면 일반 적 Lv.1',48,190),@('끌어당김 일반 적 Lv.1',82,190),
 @('거리 일반 적 Lv.1',56,172),@('지원 일반 적 Lv.1',74,159)
)
$stageRoles = @(
 @('근거리 1','원거리 1','범위 1'),@('원거리 1','범위 1','탄막 1'),@('범위 1','탄막 1','방어 1'),
 @('탄막 1','방어 1','휩쓸기 1'),@('방어 1','휩쓸기 1','광선 1'),@('휩쓸기 1','광선 1','성장 1'),
 @('광선 1','성장 1','틈새 1'),@('성장 1','틈새 1','파동 1'),@('틈새 1','파동 1','측면 1'),
 @('파동 1','측면 1','끌어당김 1'),@('측면 1','끌어당김 1','거리 1'),@('끌어당김 1','거리 1','지원 1')
)
$bossHealth = @(33800,37856,42250,46982,52052,57460,63206,69290,74360,79430,84500,91260)
$bossSpeed = @(380,395,410,425,440,455,470,485,495,505,515,525)
$bossDamage = @(1.00,1.06,1.12,1.18,1.24,1.31,1.38,1.46,1.54,1.62,1.70,1.78)
$bossCadence = @(0.67,0.65,0.63,0.61,0.59,0.57,0.55,0.53,0.52,0.51,0.50,0.49)
$ordinaryHealth = @(1.00,1.00,1.00,1.06,1.12,1.19,1.25,1.31,1.38,1.44,1.47,1.50)

$builder = [Text.StringBuilder]::new()
[void]$builder.AppendLine('<!doctype html><html lang="ko"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">')
[void]$builder.AppendLine('<title>Cardborne 전투 진행·업그레이드 보고서</title><style>:root{color-scheme:dark;--bg:#0e141b;--panel:#17212b;--line:#344554;--text:#edf4f7;--muted:#a9bac4;--accent:#72d6c4}*{box-sizing:border-box}html,body{max-width:100%;overflow-x:hidden}body{margin:0;background:var(--bg);color:var(--text);font:15px/1.55 system-ui,sans-serif}main{width:100%;max-width:1440px;min-width:0;margin:auto;padding:28px}h1,h2{line-height:1.2;overflow-wrap:anywhere}h2{margin-top:34px;color:var(--accent)}p{color:var(--muted)}.note{max-width:100%;padding:14px 16px;background:#11232a;border-left:4px solid var(--accent);overflow-wrap:anywhere}.table-wrap{display:block;width:100%;max-width:100%;min-width:0;overflow-x:auto;border:1px solid var(--line);border-radius:8px;margin:12px 0 22px}table{width:100%;min-width:760px;border-collapse:collapse;background:var(--panel)}th,td{padding:10px 12px;text-align:left;vertical-align:top;border-bottom:1px solid var(--line);overflow-wrap:anywhere}th{background:#1e2c37;color:var(--accent);white-space:nowrap}.levels{min-width:420px}.category{white-space:nowrap}@media(max-width:600px){main{max-width:390px;margin:0;padding:16px}h1{font-size:25px}table{font-size:13px}}</style></head><body><main>')
[void]$builder.AppendLine('<h1>전투 진행·업그레이드 데이터 보고서</h1><p>현재 구현 데이터를 한국어로 정리한 개발용 보고서입니다. 표는 화면 폭을 넘으면 가로 스크롤되며 셀 내용은 잘리지 않습니다.</p>')
[void]$builder.AppendLine('<div class="note">보스 처치 시 지형과 기존 일반 적은 유지됩니다. 이후 스폰 로스터만 바뀝니다. 각 단계는 3개 역할을 유지하고 마지막 역할이 해당 보스의 핵심 기믹을 미리 가르칩니다. 기본 비중은 25%(최소 4기), 12단계 지원 역할은 12%입니다.</div>')
[void]$builder.AppendLine('<h2>12단계 진행과 보스 수치</h2><div class="table-wrap"><table><thead><tr><th>단계</th><th>일반 적 로스터</th><th>보스 인트로</th><th>일반 적 체력 압력</th><th>보스 체력</th><th>속도</th><th>피해 배율</th><th>공격 간격 배율</th></tr></thead><tbody>')
for($i=0;$i -lt 12;$i++){ $r=$stageRoles[$i]; [void]$builder.AppendLine("<tr><td>$($i+1)</td><td>$($r -join ' · ')</td><td>$($r[2])</td><td>$([math]::Round($ordinaryHealth[$i]*100))%</td><td>$($bossHealth[$i])</td><td>$($bossSpeed[$i])</td><td>$($bossDamage[$i])×</td><td>$($bossCadence[$i])×</td></tr>") }
[void]$builder.AppendLine('</tbody></table></div><p>3단계 보스 방어막: 3분할, 분할 사이 틈, 8초 활성/2초 해제. 방어막 적중 피해는 15%만 적용됩니다. 후반 일반 적 이동 속도는 최대 1.30배, 체력은 최대 2배입니다.</p>')
[void]$builder.AppendLine('<h2>일반 적 기본 수치</h2><div class="table-wrap"><table><thead><tr><th>범용 이름</th><th>기본 체력</th><th>기본 속도</th></tr></thead><tbody>')
foreach($role in $roles){ [void]$builder.AppendLine("<tr><td>$($role[0])</td><td>$($role[1])</td><td>$($role[2])</td></tr>") }
[void]$builder.AppendLine('</tbody></table></div>')
[void]$builder.AppendLine('<h2>업그레이드 카드</h2><p>모든 카드는 기존보다 최대 레벨이 3단계 늘었습니다. 수치형 효과는 레벨마다 점진적으로 증가합니다. 투사체·관통 개수는 정해진 구간에서만 늘고, 같은 구간에서는 개별 피해나 다른 수치가 증가합니다.</p><div class="table-wrap"><table><thead><tr><th>카테고리</th><th>카드</th><th>최대</th><th class="levels">레벨별 변화</th></tr></thead><tbody>')
foreach($card in ($cards | Sort-Object Category,Title)){ $rows=($card.Rows -join '<br>'); [void]$builder.AppendLine("<tr><td class='category'>$(Encode $categoryNames[$card.Category])</td><td>$(Encode $card.Title)</td><td>Lv.$($card.Max)</td><td class='levels'>$rows</td></tr>") }
[void]$builder.AppendLine('</tbody></table></div><h2>보급과 발동 무기</h2><p>맵당 중립시설 6개, 경험치 회수 아이템 4개를 배치합니다. 90초 이후 활성 회수 아이템이 2개 미만이면 30초마다 소모된 항목 하나를 최대 4개까지 다시 활성화합니다. 발동 무기는 직접 피해 없이 경직·둔화·밀치기·투사체 제거 등 CC만 적용하며, 레벨업은 범위·재사용 대기시간·효과 지속시간을 강화합니다.</p>')
[void]$builder.AppendLine('</main></body></html>')
[IO.File]::WriteAllText($output, $builder.ToString(), [Text.UTF8Encoding]::new($false))
Write-Output $output
