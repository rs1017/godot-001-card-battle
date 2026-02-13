param(
	[string]$PlanPath,
	[string]$QaPath,
	[string]$ReviewOutPath,
	[string]$ReferenceFocus = "global",
	[int]$CycleId = 1
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $PlanPath)) { throw "Plan file not found: $PlanPath" }
if (-not (Test-Path $QaPath)) { throw "QA file not found: $QaPath" }

$planText = Get-Content -Path $PlanPath -Raw
$qaText = Get-Content -Path $QaPath -Raw

$requiredPlanKeywords = @(
	"deck",
	"formula",
	"map",
	"victory",
	"defeat",
	"animation",
	"inventory",
	"character"
)

$missing = @()
foreach ($k in $requiredPlanKeywords) {
	if ($planText.ToLower().IndexOf($k) -lt 0) {
		$missing += $k
	}
}

$smokePass = ($qaText -match "HeadlessSmokeResult:\s*PASS")
$funSignals = @("fun", "combo", "counterplay", "variety", "pace")
$funHits = 0
foreach ($f in $funSignals) {
	if ($planText.ToLower().Contains($f)) { $funHits++ }
}
$funScore = [Math]::Min(100, 40 + ($funHits * 12))

$status = "PASS"
$reason = "ok"
if ($missing.Count -gt 0) {
	$status = "REJECT"
	$reason = "plan_missing_keywords:" + ($missing -join ",")
}
if (-not $smokePass) {
	$status = "REJECT"
	$reason = "qa_smoke_not_passed"
}
if ($funScore -lt 60) {
	$status = "REJECT"
	$reason = "qa_fun_score_low:$funScore"
}

$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$body = @"
# Review Agent Validation

- GeneratedAt: $now
- CycleId: $CycleId
- ReferenceFocus: $ReferenceFocus
- Status: $status
- Reason: $reason
- FunScore: $funScore
- SmokePass: $smokePass
"@
Set-Content -Path $ReviewOutPath -Value $body -Encoding UTF8

Write-Output "REVIEW_STATUS=$status"
Write-Output "REVIEW_REASON=$reason"
Write-Output "FUN_SCORE=$funScore"
Write-Output "REVIEW_FILE=$ReviewOutPath"
