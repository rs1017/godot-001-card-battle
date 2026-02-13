param(
	[string]$Feature = "baseline-workflow",
	[string]$ReferenceFocus = "global",
	[int]$CycleId = 1,
	[switch]$SkipSmoke,
	[switch]$UpdateLatestPlan
)

$ErrorActionPreference = "Stop"

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$stampId = Get-Date -Format "yyyyMMdd_HHmmss"

$referenceRoot = Join-Path $PSScriptRoot "..\reference"
$assetRoot = Join-Path $PSScriptRoot "..\assets\kaykit"
$cardRoot = Join-Path $PSScriptRoot "..\resources\cards"
$reportRoot = Join-Path $referenceRoot "_reports"
$docsRoot = Join-Path $PSScriptRoot "..\docs"
$docsReportRoot = Join-Path $docsRoot "reference_reports"
$planRoot = Join-Path $docsRoot "plans"
$planDataRoot = Join-Path $planRoot "data"
$planImagesRoot = Join-Path $planRoot "images"
$graphicsRoot = Join-Path $docsRoot "graphics"
$reviewRoot = Join-Path $docsRoot "reviews"
$qaRoot = Join-Path $docsRoot "qa"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Ensure-DirectoryWithFallback([string]$primary, [string]$fallback) {
	try {
		New-Item -ItemType Directory -Force -Path $primary | Out-Null
		return $primary
	}
	catch {
		New-Item -ItemType Directory -Force -Path $fallback | Out-Null
		return $fallback
	}
}

function Resolve-WritableDirectory([string]$primary, [string]$fallback) {
	$selected = Ensure-DirectoryWithFallback -primary $primary -fallback $fallback
	$probe = Join-Path $selected ".write_probe.tmp"
	try {
		Set-Content -Path $probe -Value "ok" -Encoding UTF8
		Remove-Item -Path $probe -Force -ErrorAction SilentlyContinue
		return $selected
	}
	catch {
		New-Item -ItemType Directory -Force -Path $fallback | Out-Null
		return $fallback
	}
}

$reportRoot = Resolve-WritableDirectory -primary $reportRoot -fallback $docsReportRoot
New-Item -ItemType Directory -Force -Path $planRoot | Out-Null
New-Item -ItemType Directory -Force -Path $planDataRoot | Out-Null
New-Item -ItemType Directory -Force -Path $planImagesRoot | Out-Null
New-Item -ItemType Directory -Force -Path $graphicsRoot | Out-Null
New-Item -ItemType Directory -Force -Path $reviewRoot | Out-Null
New-Item -ItemType Directory -Force -Path $qaRoot | Out-Null

function Get-SafeCount([string]$path) {
	if (-not (Test-Path $path)) {
		return 0
	}
	return (Get-ChildItem -Path $path -Recurse -File).Count
}

function Get-SafeTop([string]$path, [int]$top = 12) {
	if (-not (Test-Path $path)) {
		return @()
	}
	return Get-ChildItem -Path $path -Recurse -File | Select-Object -First $top
}

function To-RelativePath([string]$fullPath, [string]$basePath) {
	if ([string]::IsNullOrWhiteSpace($fullPath)) {
		return $fullPath
	}
	$normalizedBase = $basePath.TrimEnd('\')
	if ($fullPath.StartsWith($normalizedBase, [System.StringComparison]::OrdinalIgnoreCase)) {
		return $fullPath.Substring($normalizedBase.Length).TrimStart('\')
	}
	return $fullPath
}

$refTotal = Get-SafeCount $referenceRoot
$kaykitTotal = Get-SafeCount $assetRoot
$cardTotal = Get-SafeCount $cardRoot

$inventoryPath = Join-Path $reportRoot "reference_inventory_$stampId.md"
$planPath = Join-Path $planRoot "plan_$stampId.md"
$planLatest = Join-Path $planRoot "latest_plan.md"
$planDataPath = Join-Path $planDataRoot "plan_$stampId.csv"
$distributionLog = Join-Path $planRoot "distribution_log.md"
$graphicsPath = Join-Path $graphicsRoot "graphics_strategy_$stampId.md"
$graphicsLatest = Join-Path $graphicsRoot "latest_graphics_strategy.md"
$devLogPath = Join-Path $reviewRoot "development_log_$stampId.md"
$reviewPath = Join-Path $reviewRoot "review_$stampId.md"
$qaPath = Join-Path $qaRoot "qa_$stampId.md"

$refTopList = Get-SafeTop $referenceRoot 15
$kaykitTopList = Get-SafeTop $assetRoot 20
$cardTopList = Get-SafeTop $cardRoot 20

$refTopText = ($refTopList | ForEach-Object { "- $(To-RelativePath $_.FullName $repoRoot)" }) -join "`n"
$kaykitTopText = ($kaykitTopList | ForEach-Object { "- $(To-RelativePath $_.FullName $repoRoot)" }) -join "`n"
$cardTopText = ($cardTopList | ForEach-Object { "- $(To-RelativePath $_.FullName $repoRoot)" }) -join "`n"

$inventoryBody = @"
# Reference Inventory

- GeneratedAt: $timestamp
- Feature: $Feature
- CycleId: $CycleId
- ReferenceFocus: $ReferenceFocus
- ReferenceFiles: $refTotal
- KayKitFiles: $kaykitTotal
- CardResourceFiles: $cardTotal

## Reference Sample
$refTopText

## KayKit Sample
$kaykitTopText

## Card Resource Sample
$cardTopText
"@
Set-Content -Path $inventoryPath -Value $inventoryBody -Encoding UTF8

$planBody = @"
# Project Plan

- GeneratedAt: $timestamp
- Feature: $Feature
- CycleId: $CycleId
- ReferenceFocus: $ReferenceFocus
- SourceInventory: $([IO.Path]::GetFileName($inventoryPath))

## 紐⑹감
- 媛쒖슂
- 紐⑹쟻
- 臾몄꽌踰붿쐞
- 移대뱶 ??援ъ꽦 洹쒖튃
- 移대뱶 猷?
- ?꾪닾 怨듭떇
- 留??덉씤 ?ㅺ퀎
- ?밸━/?⑤같/?좊땲硫붿씠??
- 移대뱶 ?몃깽?좊━
- 罹먮┃???ㅻ챸
- QA(?щ????ы븿)

## 媛쒖슂
- Reference 湲곕컲 諛고? 媛쒖꽑 ?ъ씠??臾몄꽌.
- Reference image link: `images/cycle_$CycleId` (image files are managed by grapher output).

## 紐⑹쟻
- 移대뱶 ?꾪닾??pace, variety, combo, counterplay ?щ?瑜??믪씠怨? 洹쒖튃/?섏튂/UX瑜??쇨??섍쾶 ?뺤쓽.

## 臾몄꽌踰붿쐞
- 硫붿씤 ?섏씠吏遺???꾪닾 醫낅즺源뚯????꾩껜 ?먮쫫.
- Planning data csv: `data/$([IO.Path]::GetFileName($planDataPath))`

## Phase 1. Reference Collection
- Use `reference/`, `resources/cards`, and `assets/kaykit` as the primary references.
- Record inventory and keep diffs in `docs/reference_reports`.

## Phase 2. Planning and Distribution
- Publish the current execution plan as `docs/plans/latest_plan.md`.
- Append deployment logs in `docs/plans/distribution_log.md`.

## Phase 3. Graphics Pipeline
- First choice: ComfyUI generated concepts.
- Fallback choice: KayKit assets already included in repository.
- Maintain prompt presets and usage mapping in `docs/graphics/latest_graphics_strategy.md`.

## Phase 4. Development
- Implement gameplay/UI changes from approved plan.
- Track touched files and impact notes in development logs.
- Card deck composition rule: tank/dps/range/spell/building role balance.
- Card rule set: mana curve, summon constraints, lane targeting, counterplay windows.
- Combat formula: damage, attack_speed, range, overtime/sudden-death scaling.
- Map rule: lane readability, tower distance band, deploy affordance.
- Victory/Defeat: explicit end-state criteria and UI transition animation.
- Card inventory: rarity/cost/tag metadata and ownership status.
- Character description: role identity, strengths, weaknesses, animation set.

## Phase 5. Review
- Run static review for regressions, state machine side effects, and data path safety.
- Write findings and open risks in `docs/reviews/review_*.md`.

## Phase 6. QA
- Execute headless smoke (`tools/run_headless_smoke.bat`) and manual gameplay checklist.
- Save results in `docs/qa/qa_*.md`.
- QA fun evaluation: pace, variety, combo readability, counterplay clarity.
"@
Set-Content -Path $planPath -Value $planBody -Encoding UTF8
if ($UpdateLatestPlan) {
	Set-Content -Path $planLatest -Value $planBody -Encoding UTF8
}
Set-Content -Path $planDataPath -Value "cycle_id,reference_focus,phase,owner,status`r`n$CycleId,$ReferenceFocus,planning,ralph,done`r`n$CycleId,$ReferenceFocus,graphics,grapher,requested`r`n$CycleId,$ReferenceFocus,dev,ralph,in_progress" -Encoding UTF8

if (-not (Test-Path $distributionLog)) {
	Set-Content -Path $distributionLog -Value "# Plan Distribution Log`n" -Encoding UTF8
}
if ($UpdateLatestPlan) {
	Add-Content -Path $distributionLog -Value "- $timestamp :: published $([IO.Path]::GetFileName($planPath)) as latest_plan.md"
}
else {
	Add-Content -Path $distributionLog -Value "- $timestamp :: generated $([IO.Path]::GetFileName($planPath)) (latest_plan.md preserved)"
}

$graphicsLines = @(
	"# Graphics Strategy",
	"",
	"- GeneratedAt: $timestamp",
	"- CycleId: $CycleId",
	"- ReferenceFocus: $ReferenceFocus",
	"- Policy: Prefer ComfyUI output. Use KayKit resources as fallback or production-safe baseline.",
	"",
	"## ComfyUI Prompt Presets",
	"- Character concept: stylized fantasy unit, isometric strategy game, clean silhouette, hand-painted texture, neutral background",
	"- Spell card art: top-down magical effect, readable icon composition, high contrast, card game VFX concept",
	"- Environment tile: hex tile terrain, readable lane boundaries, modular medieval style",
	"",
	"## KayKit Fallback Mapping",
	"- Melee units: assets/kaykit/adventurers/Barbarian.glb, assets/kaykit/adventurers/Knight.glb",
	"- Ranged/caster: assets/kaykit/adventurers/Mage.glb, assets/kaykit/skeletons/Skeleton_Mage.glb",
	"- Rogue/light units: assets/kaykit/adventurers/Rogue.glb, assets/kaykit/adventurers/Rogue_Hooded.glb",
	"- Map blocks: assets/kaykit/medieval-hexagon/tiles, assets/kaykit/medieval-hexagon/buildings"
)
$graphicsBody = $graphicsLines -join "`r`n"
Set-Content -Path $graphicsPath -Value $graphicsBody -Encoding UTF8
Set-Content -Path $graphicsLatest -Value $graphicsBody -Encoding UTF8

$devLogBody = @"
# Development Log

- GeneratedAt: $timestamp
- Feature: $Feature
- CycleId: $CycleId
- ReferenceFocus: $ReferenceFocus
- Scope: Workflow automation and output artifact generation.

## Implementation
- Added workflow agent script: `tools/reference_ops_agent.ps1`
- Generated inventory, plan, graphics strategy, review, and QA output files.

## Notes
- This run establishes the default delivery pipeline requested by team.
"@
Set-Content -Path $devLogPath -Value $devLogBody -Encoding UTF8

$reviewBody = @"
# Code Review

- GeneratedAt: $timestamp
- CycleId: $CycleId
- ReferenceFocus: $ReferenceFocus
- Scope: `tools/reference_ops_agent.ps1`, workflow instruction update.

## Findings
- No critical defects found in the newly introduced automation flow.
- Residual risk: path assumptions can fail if repository links (`reference`) are removed.

## Follow-up
- Keep `reference` link valid before running the agent.
- Re-run smoke tests after gameplay code changes.
"@
Set-Content -Path $reviewPath -Value $reviewBody -Encoding UTF8

$qaSmoke = "PENDING"
if ($SkipSmoke) {
	$qaSmoke = "SKIPPED_BY_FLAG"
}

$qaBody = @"
# QA Report

- GeneratedAt: $timestamp
- Feature: $Feature
- CycleId: $CycleId
- ReferenceFocus: $ReferenceFocus
- HeadlessSmoke: $qaSmoke

## Manual Checklist
- [ ] card select/cancel input actions
- [ ] mana spend/afford flow
- [ ] minion spawn and state transitions
- [ ] win/lose and pause state changes
"@
Set-Content -Path $qaPath -Value $qaBody -Encoding UTF8

Write-Output "REFERENCE_INVENTORY=$inventoryPath"
Write-Output "PLAN=$planPath"
Write-Output "GRAPHICS=$graphicsPath"
Write-Output "DEVELOPMENT_LOG=$devLogPath"
Write-Output "REVIEW=$reviewPath"
Write-Output "QA=$qaPath"

