param(
	[int]$PageCount = 320,
	[string]$OutputPath = "docs/plans/master_plan_generated.md",
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

$referenceNote = "- ???덊띁?곗뒪: $ReferencePath"
if (-not (Test-Path (Join-Path $repoRoot $ReferencePath))) {
	$referenceNote = "- ???덊띁?곗뒪: (誘명솗??"
}

$sections = @(
	"硫붿씤 ?섏씠吏 UX (ComfyUI ?곗꽑)",
	"濡쒕퉬 諛?留?媛?낆꽦",
	"?꾪닾 猷⑦봽",
	"?밸━ 諛??⑤같 ?먮쫫",
	"?좊땲硫붿씠???곗텧",
	"移대뱶 ??援ъ꽦 洹쒖튃",
	"移대뱶 猷??쒖뒪??,
	"?꾪닾 怨듭떇",
	"移대뱶 ?몃깽?좊━",
	"罹먮┃???ㅼ젙/?ㅻ챸",
	"QA ?쒕굹由ъ삤",
	"?쇱씠釉?諛몃윴??
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
$doc.Add("# 留덉뒪??湲고쉷??(300+ ?섏씠吏)")
$doc.Add("")
$doc.Add("## 臾몄꽌 ?깃꺽")
$doc.Add("- 蹂?臾몄꽌??寃뚯엫 湲고쉷?쒖씠硫? ?띿뒪???⑤룆 湲곗닠??湲덉??쒕떎")
$doc.Add("- 紐⑤뱺 ?섏씠吏???대?吏, ?? ?먮쫫?? UI ?쒖븞???ы븿?쒕떎")
$doc.Add("")
$doc.Add("## 紐⑹감")
$doc.Add("1. 媛쒖슂")
$doc.Add("2. 紐⑹쟻")
$doc.Add("3. 臾몄꽌踰붿쐞")
$doc.Add("4. ?대젰")
$doc.Add("5. ?섏씠吏蹂??곸꽭 ?ㅺ퀎")
$doc.Add("")
$doc.Add("## 媛쒖슂")
$doc.Add("- docs/references ?뺤떇??李멸퀬???듯빀 湲고쉷 臾몄꽌")
$doc.Add("")
$doc.Add("## 紐⑹쟻")
$doc.Add("- 移대뱶 ??猷??꾪닾怨듭떇/留??뱁뙣/?좊땲硫붿씠???몃깽?좊━/罹먮┃???ㅺ퀎? 媛쒕컻?붽뎄?ы빆???곌껐")
$doc.Add("")
$doc.Add("## 臾몄꽌踰붿쐞")
$doc.Add("- 硫붿씤 ?섏씠吏, ?꾪닾 留? 移대뱶 UX, ?뱁뙣 ?곗텧, QA 猷⑦봽, 諛몃윴??)
$doc.Add("")
$doc.Add("## ?대젰")
$doc.Add("| ?좎쭨 | ?묒꽦??| 蹂寃??댁슜 |")
$doc.Add("|---|---|---|")
$doc.Add("| 2026-02-13 | Ralph Agent | ?대?吏/???먮쫫/UI ?ы븿 300+ ?섏씠吏 ?앹꽦 |")
$doc.Add("")
$doc.Add("- ?앹꽦?쒓컖: $generatedAt")
$doc.Add("- ?뺤콉: 300?섏씠吏 ?댁긽 湲고쉷?쒓? ?놁쑝硫?媛쒕컻 ?쒖옉 湲덉?")
$doc.Add("- 紐⑺몴 ?섏씠吏 ?? $PageCount")
$doc.Add("- ?뚰겕?뚮줈?? ?덊띁?곗뒪 -> 湲고쉷 -> 洹몃옒??ComfyUI/KayKit) -> 媛쒕컻 -> 由щ럭 -> QA")
$doc.Add($referenceNote)
$doc.Add("- ?대?吏 ?대뜑: $ImagesDir")
$doc.Add("- 湲고쉷 ?곗씠??CSV: $DataCsvPath")
$doc.Add("")

$csvRows.Add("page,theme,dev_need,ui_focus,formula_focus,image_a,image_b")

for ($i = 1; $i -le $PageCount; $i++) {
	$topic = $sections[($i - 1) % $sections.Count]
	$imageRelPath = "images/page_{0:000}.png" -f $i
	$imgA = $referenceImages[($i - 1) % $referenceImages.Count]
	$imgB = $referenceImages[$i % $referenceImages.Count]

	$doc.Add("## Page $i")
	$doc.Add("")
	$doc.Add("### ?섏씠吏 二쇱젣")
	$doc.Add("- $topic")
	$doc.Add("")
	$doc.Add("### ?덊띁?곗뒪 泥댄겕 ?대?吏")
	$doc.Add("![?덊띁?곗뒪 A]($imgA)")
	$doc.Add("![?덊띁?곗뒪 B]($imgB)")
	$doc.Add("![洹몃옒??寃곌낵 ?щ’]($imageRelPath)")
	$doc.Add("")
	$doc.Add("### ?듭떖 湲고쉷 ??)
	$doc.Add("| ??ぉ | 湲고쉷 ?댁슜 | 媛쒕컻 ?꾩슂?ы빆 |")
	$doc.Add("|---|---|---|")
	$doc.Add("| 紐⑺몴 | 泥닿컧??遺꾨챸???꾪닾/UX 媛쒖꽑 | ?곹깭癒몄떊, ?꾪닾怨듭떇, UI ?대깽???곕룞 援ы쁽 |")
	$doc.Add("| 移대뱶 猷?| 肄붿뒪????븷/移댁슫??愿怨??좎? | 移대뱶 ?곗씠??寃利앷린, ??援ъ꽦 ?쒖빟 濡쒖쭅 |")
	$doc.Add("| ?꾪닾 怨듭떇 | 湲곕낯 ?쇳빐??+ ?ㅻ쾭????쒕뱺?곗뒪 ?ㅼ???| ?쒕쾭/?대씪 ?숈씪 ?섏떇 ?곸슜 |")
	$doc.Add("| ?뱁뙣 ?곗텧 | ?밸━/?⑤같 ?꾪솚 利됱떆 ?몄? | 寃곌낵 ?⑤꼸, ?좊땲硫붿씠?? ?ъ슫????|")
	$doc.Add("| QA ?щ???| pace/variety/combo/counterplay ?먭? | QA ?ㅻЦ + 濡쒓렇 湲곕컲 ?ㅼ퐫???곗텧 |")
	$doc.Add("")
	$doc.Add("### ?먮쫫??(Markdown Mermaid)")
	$doc.Add('~~~mermaid')
	$doc.Add("flowchart LR")
	$doc.Add("A[?덊띁?곗뒪 遺꾩꽍] --> B[湲고쉷 ?뺣━]")
	$doc.Add("B --> C[UI ??댁뼱 ?ㅺ퀎]")
	$doc.Add("C --> D[移대뱶 猷??꾪닾 怨듭떇]")
	$doc.Add("D --> E[援ы쁽]")
	$doc.Add("E --> F[由щ럭 ?먯씠?꾪듃]")
	$doc.Add("F --> G{QA ?듦낵?}")
	$doc.Add("G -- ?꾨땲??--> A")
	$doc.Add("G -- ??--> H[?꾨즺]")
	$doc.Add('~~~')
	$doc.Add("")
	$doc.Add("### UI ?쒖븞 (Markdown)")
	$doc.Add("| UI 援ъ뿭 | 援ъ꽦 ?붿냼 | ?곹샇?묒슜 |")
	$doc.Add("|---|---|---|")
	$doc.Add("| ?곷떒諛?| ???HP, ?섏씠利???대㉧ | ?ㅼ떆媛??섏튂 ?낅뜲?댄듃 |")
	$doc.Add("| 以묒븰 ?꾩옣 | 醫????덉씤, ??? 誘몃땲??| 移대뱶 諛곗튂 寃곌낵 ?쒓컖??|")
	$doc.Add("| ?섎떒 移대뱶?몃뱶 | 4???몃뱶, ?ㅼ쓬 移대뱶 ?꾨━酉? 留덈굹諛?| ?좏깮/痍⑥냼/?덉씤 ?좏깮 |")
	$doc.Add("| 寃곌낵 ?ㅻ쾭?덉씠 | ?밸━/?⑤같, ?ъ떆?? 硫붾돱 | 寃뚯엫 醫낅즺 ???꾪솚 |")
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
	$doc.Add("### 媛쒕컻 ?쒖븞")
	$doc.Add("1. ?덊띁?곗뒪 ?대?吏 湲곕컲?쇰줈 留?媛?낆꽦 湲곗??좎쓣 癒쇱? 怨좎젙?쒕떎")
	$doc.Add("2. 移대뱶 猷??꾪닾 怨듭떇 ?섏튂瑜?CSV ?⑥씪 ?뚯뒪濡?愿由ы븳??)
	$doc.Add("3. UI ?대깽???좏깮/痍⑥냼/?뱁뙣)瑜??곹깭癒몄떊怨??곌껐???뚭?瑜?以꾩씤??)
	$doc.Add("4. 由щ럭 諛섎젮 ??利됱떆 ?덊띁?곗뒪 ?ъ닔吏???湲고쉷 diff瑜?湲곕줉?쒕떎")
	$doc.Add("")

	$csvRows.Add(("{0},""{1}"",""?곹깭癒몄떊/?꾪닾怨듭떇/UI?곕룞"",""硫붿씤+?꾪닾+寃곌낵 ?ㅻ쾭?덉씠"",""?ㅻ쾭????쒕뱺?곗뒪"",""{2}"",""{3}""" -f $i, $topic, $imgA, $imgB))
}

Set-Content -Path $fullOutputPath -Value ($doc -join "`r`n") -Encoding UTF8
Set-Content -Path $dataCsvFullPath -Value ($csvRows -join "`r`n") -Encoding UTF8

Write-Output "MASTER_PLAN_PATH=$fullOutputPath"
Write-Output "MASTER_PLAN_PAGES=$PageCount"
Write-Output "MASTER_PLAN_CSV=$dataCsvFullPath"




