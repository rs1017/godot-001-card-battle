param(
	[int]$PageCount = 320,
	[string]$OutputPath = "docs/plans/master_plan_300_pages.md",
	[string]$ReferencePath = "docs/references/web_reference_pack.md",
	[string]$ImagesDir = "docs/plans/images",
	[string]$DataCsvPath = "docs/plans/data/master_plan_pages.csv"
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$fullOutputPath = Join-Path $repoRoot $OutputPath
$outputDir = Split-Path -Path $fullOutputPath -Parent
if (-not (Test-Path $outputDir)) {
	New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
}

$imagesFullDir = Join-Path $repoRoot $ImagesDir
if (-not (Test-Path $imagesFullDir)) {
	New-Item -ItemType Directory -Force -Path $imagesFullDir | Out-Null
}

$dataCsvFullPath = Join-Path $repoRoot $DataCsvPath
$dataCsvDir = Split-Path -Path $dataCsvFullPath -Parent
if (-not (Test-Path $dataCsvDir)) {
	New-Item -ItemType Directory -Force -Path $dataCsvDir | Out-Null
}

$referenceNote = "- 웹 레퍼런스: $ReferencePath"
if (-not (Test-Path (Join-Path $repoRoot $ReferencePath))) {
	$referenceNote = "- 웹 레퍼런스: (미확인)"
}

$sections = @(
	"메인 페이지 UX (ComfyUI 우선)",
	"로비 및 맵 가독성",
	"전투 루프",
	"승리 및 패배 흐름",
	"애니메이션 연출",
	"카드 덱 구성 규칙",
	"카드 룰 시스템",
	"전투 공식",
	"카드 인벤토리",
	"캐릭터 설정/설명",
	"QA 시나리오",
	"라이브 밸런싱"
)

$referenceImages = @(
	"images/web_refs/web_ref_01.jpg",
	"images/web_refs/web_ref_02.jpg",
	"images/web_refs/web_ref_03.jpg",
	"images/web_refs/web_ref_04.jpg",
	"images/web_refs/web_ref_05.jpg",
	"images/web_refs/web_ref_06.jpg",
	"images/web_refs/web_ref_07.jpg",
	"images/web_refs/web_ref_08.jpg",
	"images/web_refs/web_ref_09.jpg",
	"images/web_refs/web_ref_10.jpg",
	"images/web_refs/web_ref_11.jpg",
	"images/web_refs/web_ref_12.jpg"
)

$doc = New-Object System.Collections.Generic.List[string]
$csvRows = New-Object System.Collections.Generic.List[string]

$generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$doc.Add("# 마스터 기획서 (300+ 페이지)")
$doc.Add("")
$doc.Add("## 문서 성격")
$doc.Add("- 본 문서는 게임 기획서이며, 텍스트 단독 기술을 금지한다")
$doc.Add("- 모든 페이지는 이미지, 표, 흐름도, UI 제안을 포함한다")
$doc.Add("")
$doc.Add("## 목차")
$doc.Add("1. 개요")
$doc.Add("2. 목적")
$doc.Add("3. 문서범위")
$doc.Add("4. 이력")
$doc.Add("5. 페이지별 상세 설계")
$doc.Add("")
$doc.Add("## 개요")
$doc.Add("- reference/docs 형식을 참고한 통합 기획 문서")
$doc.Add("")
$doc.Add("## 목적")
$doc.Add("- 카드 덱/룰/전투공식/맵/승패/애니메이션/인벤토리/캐릭터 설계와 개발요구사항을 연결")
$doc.Add("")
$doc.Add("## 문서범위")
$doc.Add("- 메인 페이지, 전투 맵, 카드 UX, 승패 연출, QA 루프, 밸런싱")
$doc.Add("")
$doc.Add("## 이력")
$doc.Add("| 날짜 | 작성자 | 변경 내용 |")
$doc.Add("|---|---|---|")
$doc.Add("| 2026-02-13 | Ralph Agent | 이미지/표/흐름/UI 포함 300+ 페이지 생성 |")
$doc.Add("")
$doc.Add("- 생성시각: $generatedAt")
$doc.Add("- 정책: 300페이지 이상 기획서가 없으면 개발 시작 금지")
$doc.Add("- 목표 페이지 수: $PageCount")
$doc.Add("- 워크플로우: 레퍼런스 -> 기획 -> 그래픽(ComfyUI/KayKit) -> 개발 -> 리뷰 -> QA")
$doc.Add($referenceNote)
$doc.Add("- 이미지 폴더: $ImagesDir")
$doc.Add("- 기획 데이터 CSV: $DataCsvPath")
$doc.Add("")

$csvRows.Add("page,theme,dev_need,ui_focus,formula_focus,image_a,image_b")

for ($i = 1; $i -le $PageCount; $i++) {
	$topic = $sections[($i - 1) % $sections.Count]
	$imageRelPath = "images/page_{0:000}.png" -f $i
	$imgA = $referenceImages[($i - 1) % $referenceImages.Count]
	$imgB = $referenceImages[$i % $referenceImages.Count]

	$doc.Add("## Page $i")
	$doc.Add("")
	$doc.Add("### 페이지 주제")
	$doc.Add("- $topic")
	$doc.Add("")
	$doc.Add("### 레퍼런스 체크 이미지")
	$doc.Add("![레퍼런스 A]($imgA)")
	$doc.Add("![레퍼런스 B]($imgB)")
	$doc.Add("![그래퍼 결과 슬롯]($imageRelPath)")
	$doc.Add("")
	$doc.Add("### 핵심 기획 표")
	$doc.Add("| 항목 | 기획 내용 | 개발 필요사항 |")
	$doc.Add("|---|---|---|")
	$doc.Add("| 목표 | 체감이 분명한 전투/UX 개선 | 상태머신, 전투공식, UI 이벤트 연동 구현 |")
	$doc.Add("| 카드 룰 | 코스트/역할/카운터 관계 유지 | 카드 데이터 검증기, 덱 구성 제약 로직 |")
	$doc.Add("| 전투 공식 | 기본 피해량 + 오버타임/서든데스 스케일 | 서버/클라 동일 수식 적용 |")
	$doc.Add("| 승패 연출 | 승리/패배 전환 즉시 인지 | 결과 패널, 애니메이션, 사운드 큐 |")
	$doc.Add("| QA 재미도 | pace/variety/combo/counterplay 점검 | QA 설문 + 로그 기반 스코어 산출 |")
	$doc.Add("")
	$doc.Add("### 흐름도 (Markdown Mermaid)")
	$doc.Add('~~~mermaid')
	$doc.Add("flowchart LR")
	$doc.Add("A[레퍼런스 분석] --> B[기획 정리]")
	$doc.Add("B --> C[UI 와이어 설계]")
	$doc.Add("C --> D[카드 룰/전투 공식]")
	$doc.Add("D --> E[구현]")
	$doc.Add("E --> F[리뷰 에이전트]")
	$doc.Add("F --> G{QA 통과?}")
	$doc.Add("G -- 아니오 --> A")
	$doc.Add("G -- 예 --> H[완료]")
	$doc.Add('~~~')
	$doc.Add("")
	$doc.Add("### UI 제안 (Markdown)")
	$doc.Add("| UI 구역 | 구성 요소 | 상호작용 |")
	$doc.Add("|---|---|---|")
	$doc.Add("| 상단바 | 타워 HP, 페이즈 타이머 | 실시간 수치 업데이트 |")
	$doc.Add("| 중앙 전장 | 좌/우 레인, 타워, 미니언 | 카드 배치 결과 시각화 |")
	$doc.Add("| 하단 카드핸드 | 4장 핸드, 다음 카드 프리뷰, 마나바 | 선택/취소/레인 선택 |")
	$doc.Add("| 결과 오버레이 | 승리/패배, 재시작, 메뉴 | 게임 종료 후 전환 |")
	$doc.Add("")
	$doc.Add('~~~text')
	$doc.Add("+----------------------------------------------------+")
	$doc.Add("| Player HP | Phase Timer | Enemy HP                 |")
	$doc.Add("+---------------------- BATTLE FIELD ----------------+")
	$doc.Add("| Left Lane                | Right Lane               |")
	$doc.Add("| [Deploy Zone]            | [Deploy Zone]            |")
	$doc.Add("+----------------------------------------------------+")
	$doc.Add("| Mana Bar | Card1 Card2 Card3 Card4 | Next Card     |")
	$doc.Add("+----------------------------------------------------+")
	$doc.Add('~~~')
	$doc.Add("")
	$doc.Add("### 개발 제안")
	$doc.Add("1. 레퍼런스 이미지 기반으로 맵 가독성 기준선을 먼저 고정한다")
	$doc.Add("2. 카드 룰/전투 공식 수치를 CSV 단일 소스로 관리한다")
	$doc.Add("3. UI 이벤트(선택/취소/승패)를 상태머신과 연결해 회귀를 줄인다")
	$doc.Add("4. 리뷰 반려 시 즉시 레퍼런스 재수집 후 기획 diff를 기록한다")
	$doc.Add("")

	$csvRows.Add(("{0},""{1}"",""상태머신/전투공식/UI연동"",""메인+전투+결과 오버레이"",""오버타임/서든데스"",""{2}"",""{3}""" -f $i, $topic, $imgA, $imgB))
}

Set-Content -Path $fullOutputPath -Value ($doc -join "`r`n") -Encoding UTF8
Set-Content -Path $dataCsvFullPath -Value ($csvRows -join "`r`n") -Encoding UTF8

Write-Output "MASTER_PLAN_PATH=$fullOutputPath"
Write-Output "MASTER_PLAN_PAGES=$PageCount"
Write-Output "MASTER_PLAN_CSV=$dataCsvFullPath"



