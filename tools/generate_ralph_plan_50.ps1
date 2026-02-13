param(
	[int]$CycleCount = 50
)
$ErrorActionPreference = "Stop"

$root = Get-Location
$planPath = Join-Path $root "docs/plans/latest_plan.md"
$csvPath = Join-Path $root ("docs/plans/data/ralph_cycle_{0}.csv" -f $CycleCount)
$planDir = Split-Path -Parent $planPath

$web = Get-ChildItem (Join-Path $root "docs/plans/images/web_refs") -File | Sort-Object Name
$gen = Get-ChildItem (Join-Path $root "docs/plans/images/game_screenshots_generated") -Recurse -File | Sort-Object FullName

if ($web.Count -lt $CycleCount) {
	throw "web_refs images are fewer than ${CycleCount}: $($web.Count)"
}
if ($gen.Count -lt 20) {
	throw "generated images are fewer than 20: $($gen.Count)"
}

function To-Rel([string]$path) {
	$prefix = $planDir + [System.IO.Path]::DirectorySeparatorChar
	if ($path.StartsWith($prefix)) {
		return $path.Substring($prefix.Length).Replace([char]92, "/")
	}
	$rootPrefix = $root.Path + [System.IO.Path]::DirectorySeparatorChar
	if ($path.StartsWith($rootPrefix)) {
		return $path.Substring($rootPrefix.Length).Replace([char]92, "/")
	}
	return $path.Replace([char]92, "/")
}

$planningFocus = @(
	"메인 UI 가독성",
	"카드핸드 조작성",
	"레인 배치 규칙",
	"마나 템포 밸런스",
	"소환 이펙트 일관성",
	"승리 연출 명확성",
	"실패 연출 명확성",
	"카운터플레이 유도",
	"덱 다양성 보장",
	"오버타임 안정화"
)

$devFocus = @(
	"상태머신 이벤트 연결",
	"카드 데이터 검증기",
	"전투 공식 파라미터",
	"맵 충돌 및 배치 영역",
	"결과 화면 흐름"
)

$reviewFocus = @(
	"Null 접근과 전이 누락",
	"코스트 대비 성능 역전",
	"과도한 이펙트 중첩",
	"승패 판정 경계값"
)

$qaFocus = @(
	"재미도 4점 척도",
	"입력 정확도",
	"프레임 안정성",
	"튜토리얼 없이 플레이 가능성"
)

$generatedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

$header = @'
# 랄프 방식 통합 기획서 ({1}회 반복 실행)

- 문서 버전: v1.0
- 작성일: {0}
- 작성 언어: 한국어
- 작업 모드: 레퍼런스 수집 -> 기획 -> 그래픽(ComfyUI 우선, KayKit 보조) -> 개발 -> 리뷰 -> QA -> 재검증
- 반복 횟수: {1}회
- 이미지 정책: 외부 URL 직접 링크 금지, 로컬 파일 링크만 사용

## 1. 기획 목표

- 장르: 실시간 2레인 카드 배틀
- 핵심 경험: 짧은 전투(3~5분), 높은 선택 밀도, 명확한 카운터플레이
- 개발 방향: 기획 데이터 표준화, 상태머신 안정화, QA 반복 기반 개선

## 2. 레퍼런스 샘플

### 2.1 웹 레퍼런스 + 생성 이미지 샘플
'@ -f $generatedAt, $CycleCount

$sampleLines = New-Object System.Collections.Generic.List[string]
for ($i = 0; $i -lt 6; $i++) {
	$wRel = To-Rel $web[$i].FullName
	$gRel = To-Rel $gen[$i].FullName
	$sampleLines.Add("![웹 레퍼런스 $($i + 1)]($wRel)") | Out-Null
	$sampleLines.Add("![ComfyUI 샘플 $($i + 1)]($gRel)") | Out-Null
}

$middle = @'

### 2.2 레퍼런스 적용 기준

| 항목 | 체크 기준 | 개발 반영 |
|---|---|---|
| 전장 가독성 | 유닛 실루엣, 팀 색상 구분 | 타일 명도 대비와 이펙트 상한선 적용 |
| 카드 UX | 선택, 취소, 배치 피드백 | 핸드 하이라이트 및 배치 오버레이 |
| 전투 속도 | 마나 순환, TTK, 역전 타이밍 | 전투 공식과 코스트 커브 동시 조정 |
| 승패 전달 | 결과 인지 속도 | 승리/실패 연출과 결과 UI 고정 |

## 3. 시스템 상세 기획

### 3.1 카드 덱 구성 규칙

| 항목 | 규칙 | 검증 로직 |
|---|---|---|
| 덱 크기 | 8장 고정 | 저장 시 8장 검증 |
| 코스트 분포 | 1~2코 2장 이상, 5코 이상 2장 이하 | 덱 컴파일 단계 검증 |
| 역할 분포 | 탱커/딜러/유틸/스펠 최소 1종 | 태그 누락 검사 |
| 중복 제한 | 동일 카드 최대 2장 | 카드 ID 카운트 검사 |

### 3.2 카드 룰 및 전투 공식

| 항목 | 공식 또는 규칙 | 설명 |
|---|---|---|
| 최종 피해량 | `final_damage = (base_attack * skill_coeff) * (1 - armor_reduction)` | 최소값 1 보정 |
| DPS | `dps = final_damage / attack_interval` | 밸런스 비교 지표 |
| 마나 회복 | `mana_next = min(max_mana, mana_now + regen * dt)` | 기본 regen 1.0/s |
| 오버타임 | 120초 이후 타워 피해 1.25배 | 장기전 억제 |
| 서든데스 | 180초 이후 타워 피해 1.5배, 힐 50% | 강제 결판 |

### 3.3 맵/승패/애니메이션

| 요소 | 기획 | 구현 포인트 |
|---|---|---|
| 맵 | 좌/우 2레인, 중앙 시야 확보 | 배치 가능 영역 시각화 |
| 승리 | 상대 본진 HP 0 또는 시간 종료 시 우위 | 종료 판정 단일 모듈 |
| 실패 | 내 본진 HP 0 또는 열세 | 결과 화면 전환 고정 |
| 애니메이션 | 소환/피격/사망/스킬 4상태 | 상태 전이 로그 |

### 3.4 카드 인벤토리/캐릭터 설명

| 데이터 | 필드 | 목적 |
|---|---|---|
| CardInventory | card_id, rarity, owned, level, tags | 보유/성장 추적 |
| CharacterProfile | unit_id, role, strengths, weaknesses, countered_by | 역할과 상성 문서화 |
| BalanceLog | patch_ver, target, before, after, reason | 밸런스 변경 근거 |

## 4. UI 흐름

```mermaid
flowchart TD
A[메인 페이지] --> B[덱 편성]
B --> C[매치 진입]
C --> D[전투 진행]
D --> E{종료 조건 충족}
E -- 아니오 --> D
E -- 예 --> F[결과 화면]
F --> G[재시작 또는 로비]
```

| 화면 | 필수 요소 | QA 체크 |
|---|---|---|
| 메인 | 시작, 덱, 설정 | 해상도별 배치 확인 |
| 전투 HUD | 마나, 핸드, HP, 타이머 | 선택/취소 입력 정확도 |
| 결과 | 승패 문구, 보상, 재시작 | 중복 입력 방지 |

## 5. 랄프 __CYCLE_COUNT__회 반복 사이클

| 사이클 | 레퍼런스 이미지 | 기획 초점 | 그래픽 샘플 | 개발 초점 | 리뷰 초점 | QA 초점 |
|---|---|---|---|---|---|---|
'@
$middle = $middle.Replace("__CYCLE_COUNT__", [string]$CycleCount)

$tableRows = New-Object System.Collections.Generic.List[string]
$csvRows = New-Object System.Collections.Generic.List[object]

for ($i = 1; $i -le $CycleCount; $i++) {
	$w = $web[($i - 1) % $web.Count]
	$g = $gen[($i - 1) % $gen.Count]
	$wRel = To-Rel $w.FullName
	$gRel = To-Rel $g.FullName

	$p = $planningFocus[($i - 1) % $planningFocus.Count]
	$d = $devFocus[($i - 1) % $devFocus.Count]
	$r = $reviewFocus[($i - 1) % $reviewFocus.Count]
	$q = $qaFocus[($i - 1) % $qaFocus.Count]

	$tableRows.Add("| $i | ![R$i-W]($wRel) | $p | ![R$i-G]($gRel) | $d | $r | $q |") | Out-Null
	$csvRows.Add([PSCustomObject]@{
		cycle = $i
		web_reference = $wRel
		generated_reference = $gRel
		planning_focus = $p
		dev_focus = $d
		review_focus = $r
		qa_focus = $q
	}) | Out-Null
}

$tail = @'

## 6. 품질 게이트

| 게이트 | 통과 기준 | 실패 시 조치 |
|---|---|---|
| 레퍼런스 적합성 | 목표와 직접 관련된 이미지 2장 이상 | 재수집 후 재기획 |
| 리뷰 | 치명/높음 이슈 0건 | 수정 후 동일 케이스 재검증 |
| QA 기능 | 배치, 전투, 승패, 재시작 정상 | 실패 로그 첨부 후 수정 |
| QA 재미 | 평균 3.0/4.0 이상 | 카드 룰과 수치 재조정 |

## 7. 산출물 링크

- 반복 데이터: `docs/plans/data/ralph_cycle___CYCLE_COUNT__.csv`
- 페이지 데이터: `docs/plans/data/master_plan_pages.csv`
- 웹 레퍼런스 소스: `docs/plans/data/web_reference_sources.csv`
- ComfyUI 매니페스트: `docs/plans/data/game_screenshot_generated_manifest.csv`

## 8. 개발 착수 항목

1. `scripts/battle/` 전투 공식 파라미터 테이블 적용
2. `scripts/ui/` 카드 선택/취소 피드백 통일
3. `resources/cards/` 카드 태그 표준화와 덱 검증 훅 추가
4. 사이클별 헤드리스 스모크와 수동 QA 병행 실행
'@
$tail = $tail.Replace("__CYCLE_COUNT__", [string]$CycleCount)

$doc = New-Object System.Collections.Generic.List[string]
$doc.Add($header) | Out-Null
$sampleLines | ForEach-Object { $doc.Add($_) | Out-Null }
$doc.Add($middle) | Out-Null
$tableRows | ForEach-Object { $doc.Add($_) | Out-Null }
$doc.Add($tail) | Out-Null

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($planPath, ($doc -join "`r`n"), $utf8NoBom)
$csvRows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

Write-Output "UPDATED: docs/plans/latest_plan.md"
Write-Output ("UPDATED: docs/plans/data/ralph_cycle_{0}.csv" -f $CycleCount)

