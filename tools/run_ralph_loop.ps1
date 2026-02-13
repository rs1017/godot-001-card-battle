param(
	[string]$Feature = "ralph-loop",
	[int]$MaxCycles = 10,
	[int]$RequiredSuccessCycles = 2,
	[string]$CompletionFlag = "docs/ralph/COMPLETE.flag",
	[int]$StopOnQaComplete = 1,
	[switch]$SkipPlanReadinessGate,
	[string]$PlanReadinessPath = "docs/plans/latest_plan.md"
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$referenceRoot = Join-Path $repoRoot "reference"
$ralphRoot = Join-Path $repoRoot "docs\ralph"
$statePath = Join-Path $ralphRoot "state.json"
$cycleLogPath = Join-Path $ralphRoot "cycle_log.md"
$completionFlagPath = Join-Path $repoRoot $CompletionFlag
$planReadinessFullPath = Join-Path $repoRoot $PlanReadinessPath
$featureBacklogPath = Join-Path $repoRoot "docs\plans\data\auto_feature_backlog.csv"

New-Item -ItemType Directory -Force -Path $ralphRoot | Out-Null
if (-not (Test-Path $cycleLogPath)) {
	Set-Content -Path $cycleLogPath -Encoding UTF8 -Value "# Ralph Cycle Log`n"
}

function Assert-PlanReady([string]$path) {
	if (-not (Test-Path $path)) {
		throw "Plan readiness file not found: $path"
	}
	$content = Get-Content -Path $path -Raw
	if ([string]::IsNullOrWhiteSpace($content)) {
		throw "Plan readiness file is empty: $path"
	}
	$requiredPatterns = @("## 3. 메인 루프", "## 5. UI 실행 명세", "## 7. QA 판정 기준")
	foreach ($pattern in $requiredPatterns) {
		if ($content -notmatch [regex]::Escape($pattern)) {
			throw "Plan readiness missing required section: $pattern"
		}
	}
	Write-Output "[RALPH] plan readiness gate passed ($path)"
}

function Assert-PlayableGate([string]$rootPath) {
	$projectFile = Join-Path $rootPath "project.godot"
	if (-not (Test-Path $projectFile)) {
		throw "Playable gate failed: project.godot missing"
	}
	$projectText = Get-Content -Path $projectFile -Raw
	$mainSceneMatch = [regex]::Match($projectText, '(?m)^\s*run/main_scene\s*=\s*"([^"]+)"')
	if (-not $mainSceneMatch.Success) {
		throw "Playable gate failed: run/main_scene not configured"
	}
	$sceneRes = $mainSceneMatch.Groups[1].Value
	$sceneLocal = $sceneRes.Replace("res://", "").Replace("/", "\")
	$sceneFullPath = Join-Path $rootPath $sceneLocal
	if (-not (Test-Path $sceneFullPath)) {
		throw "Playable gate failed: main scene missing ($sceneRes)"
	}
	Write-Output "[RALPH] playable gate passed ($sceneRes)"
}

function Ensure-FeatureBacklog([string]$path) {
	$dir = Split-Path -Path $path -Parent
	New-Item -ItemType Directory -Force -Path $dir | Out-Null
	if (-not (Test-Path $path)) {
		Set-Content -Path $path -Encoding UTF8 -Value "created_at,cycle,focus,trigger,feature_name,status,owner`r`n"
	}
}

function Add-FeatureBacklog([string]$path, [int]$cycle, [string]$focus, [string]$trigger, [string]$featureName) {
	Ensure-FeatureBacklog -path $path
	$row = "{0},{1},{2},{3},{4},pending,ralph" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $cycle, $focus, $trigger, $featureName
	Add-Content -Path $path -Value $row
}

function Get-ReferenceBuckets([string]$rootPath) {
	if (-not (Test-Path $rootPath)) {
		return @("global")
	}
	$dirs = Get-ChildItem -Path $rootPath -Directory |
		Where-Object { -not $_.Name.StartsWith("_") } |
		Select-Object -ExpandProperty Name
	if (-not $dirs -or $dirs.Count -eq 0) {
		return @("global")
	}
	return $dirs
}

function Load-State([string]$path) {
	if (-not (Test-Path $path)) {
		return @{
			total_cycles = 0
			total_rounds = 1
			completed_references = @()
			reference_streaks = @{}
		}
	}
	$json = Get-Content -Path $path -Raw | ConvertFrom-Json
	$streaks = @{}
	if ($json.reference_streaks) {
		$json.reference_streaks.PSObject.Properties | ForEach-Object {
			$streaks[$_.Name] = [int]$_.Value
		}
	}
	$rounds = 1
	if ($null -ne $json.total_rounds) {
		$rounds = [int]$json.total_rounds
	}
	return @{
		total_cycles = [int]$json.total_cycles
		total_rounds = $rounds
		completed_references = @($json.completed_references | Where-Object { $_ })
		reference_streaks = $streaks
	}
}

function Save-State([string]$path, [hashtable]$state) {
	$state | ConvertTo-Json -Depth 5 | Set-Content -Path $path -Encoding UTF8
}

function Pick-Reference([string[]]$allRefs, [object[]]$completedRefs) {
	$next = $allRefs | Where-Object { $_ -notin $completedRefs } | Select-Object -First 1
	if ($next) {
		return $next
	}
	return $null
}

function Parse-ArtifactMap([object[]]$lines) {
	$map = @{}
	foreach ($line in $lines) {
		$lineText = "$line"
		$chunks = $lineText -split "`r?`n"
		foreach ($chunk in $chunks) {
			$row = $chunk.Trim()
			if ($row -match "^([A-Z_]+)=(.+)$") {
				$map[$matches[1]] = $matches[2].Trim()
			}
		}
	}
	return $map
}

function Validate-Artifacts([hashtable]$artifactMap) {
	$requiredKeys = @("REFERENCE_INVENTORY", "PLAN", "GRAPHICS", "DEVELOPMENT_LOG", "REVIEW", "QA")
	foreach ($key in $requiredKeys) {
		if (-not $artifactMap.ContainsKey($key)) {
			return $false
		}
		$path = $artifactMap[$key]
		if (-not (Test-Path $path)) {
			return $false
		}
		$file = Get-Item $path
		if ($file.Length -le 0) {
			return $false
		}
	}
	return $true
}

function Parse-KeyValues([object[]]$lines) {
	$map = @{}
	foreach ($line in $lines) {
		$row = "$line"
		$chunks = $row -split "`r?`n"
		foreach ($c in $chunks) {
			$t = $c.Trim()
			if ($t -match "^([A-Z_]+)=(.+)$") {
				$map[$matches[1]] = $matches[2].Trim()
			}
		}
	}
	return $map
}

function Mark-SmokePassInQA([hashtable]$artifactMap) {
	if (-not $artifactMap.ContainsKey("QA")) {
		return
	}
	$qaPath = $artifactMap["QA"]
	if (Test-Path $qaPath) {
		Add-Content -Path $qaPath -Value "- HeadlessSmokeResult: PASS ($(Get-Date -Format "yyyy-MM-dd HH:mm:ss"))"
	}
}

$state = Load-State $statePath
$refs = Get-ReferenceBuckets $referenceRoot
if (-not $SkipPlanReadinessGate) {
	Assert-PlanReady -path $planReadinessFullPath
}
Assert-PlayableGate -rootPath $repoRoot

for ($i = 1; $i -le $MaxCycles; $i++) {
	if ($refs.Count -gt 0) {
		$remaining = @($refs | Where-Object { $_ -notin $state.completed_references })
		if ($remaining.Count -eq 0) {
			if ($StopOnQaComplete -ne 0) {
				Add-Content -Path $cycleLogPath -Value "- $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") :: QA completed for all references, stop."
				Write-Output "RALPH_LOOP_COMPLETED=TRUE"
				Write-Output "REASON=QA_COMPLETED"
				Write-Output "TOTAL_CYCLES=$($state.total_cycles)"
				Write-Output "TOTAL_ROUNDS=$($state.total_rounds)"
				exit 0
			}
			$state.total_rounds = [int]$state.total_rounds + 1
			$state.completed_references = @()
			$state.reference_streaks = @{}
			Save-State -path $statePath -state $state
			Add-Content -Path $cycleLogPath -Value "- $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") :: all references completed, advance to round $($state.total_rounds)"
		}
	}

	if (Test-Path $completionFlagPath) {
		Add-Content -Path $cycleLogPath -Value "- $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") :: completion flag detected before cycle $i, stop."
		Write-Output "RALPH_LOOP_COMPLETED=TRUE"
		Write-Output "CYCLES_EXECUTED=$($i - 1)"
		exit 0
	}

	$cycleNo = $state.total_cycles + 1
	$focus = Pick-Reference -allRefs $refs -completedRefs $state.completed_references
	if (-not $focus) {
		Write-Output "RALPH_LOOP_COMPLETED=TRUE"
		Write-Output "REASON=NO_REFERENCE_FOCUS"
		exit 0
	}
	$featureId = "$Feature-cycle-$cycleNo-$focus"

	Write-Output "[RALPH] cycle=$cycleNo focus=$focus"

	$cyclePassed = $true
	$failReason = ""
	$agentOutput = & powershell -ExecutionPolicy Bypass -File (Join-Path $repoRoot "tools\reference_ops_agent.ps1") -Feature $featureId -ReferenceFocus $focus -CycleId $cycleNo 2>&1
	$artifactMap = Parse-ArtifactMap -lines $agentOutput
	if ($LASTEXITCODE -ne 0 -or -not (Validate-Artifacts -artifactMap $artifactMap)) {
		$cyclePassed = $false
		$failReason = "artifact_generation_or_validation_failed"
	}

	if ($cyclePassed) {
		& powershell -ExecutionPolicy Bypass -File (Join-Path $repoRoot "tools\validate_cards.ps1") | Out-Null
		if ($LASTEXITCODE -ne 0) {
			$cyclePassed = $false
			$failReason = "card_validation_failed"
		}
	}

	if ($cyclePassed) {
		& cmd /c (Join-Path $repoRoot "tools\run_headless_smoke.bat")
		if ($LASTEXITCODE -ne 0) {
			$cyclePassed = $false
			$failReason = "headless_smoke_failed"
		}
		else {
			Mark-SmokePassInQA -artifactMap $artifactMap
		}
	}

	if ($cyclePassed) {
		$reviewDir = Join-Path $repoRoot "docs\reviews"
		New-Item -ItemType Directory -Force -Path $reviewDir | Out-Null
		$reviewAgentOut = Join-Path $reviewDir ("review_agent_cycle_{0:000}.md" -f $cycleNo)
		$reviewOutput = & powershell -ExecutionPolicy Bypass -File (Join-Path $repoRoot "tools\review_agent_validate.ps1") `
			-PlanPath $artifactMap["PLAN"] `
			-QaPath $artifactMap["QA"] `
			-ReviewOutPath $reviewAgentOut `
			-ReferenceFocus $focus `
			-CycleId $cycleNo 2>&1
		$reviewKv = Parse-KeyValues -lines $reviewOutput
		if (($LASTEXITCODE -ne 0) -or (-not $reviewKv.ContainsKey("REVIEW_STATUS")) -or ($reviewKv["REVIEW_STATUS"] -ne "PASS")) {
			$cyclePassed = $false
			$failReason = "review_agent_rejected"
			# plan rejected -> immediately trigger reference refresh artifact
			& powershell -ExecutionPolicy Bypass -File (Join-Path $repoRoot "tools\reference_ops_agent.ps1") -Feature "$featureId-refetch" -ReferenceFocus $focus -CycleId $cycleNo | Out-Null
		}
	}

	if ($cyclePassed) {
		$graphicsReqDir = Join-Path $repoRoot "docs\graphics\requests"
		New-Item -ItemType Directory -Force -Path $graphicsReqDir | Out-Null
		$requestPath = Join-Path $graphicsReqDir ("comfyui_request_cycle_{0:000}.md" -f $cycleNo)
		& powershell -ExecutionPolicy Bypass -File (Join-Path $repoRoot "tools\create_comfyui_image_requests.ps1") -OutputPath $requestPath -ReferenceFocus $focus -CycleId $cycleNo | Out-Null
	}

	if (-not $state.reference_streaks.ContainsKey($focus)) {
		$state.reference_streaks[$focus] = 0
	}
	if ($cyclePassed) {
		$state.reference_streaks[$focus] = [int]$state.reference_streaks[$focus] + 1
		$streak = [int]$state.reference_streaks[$focus]
		Add-Content -Path $cycleLogPath -Value "- $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") :: cycle $cycleNo ok (focus=$focus, streak=$streak/$RequiredSuccessCycles)"
		if ($streak -ge $RequiredSuccessCycles -and $focus -notin $state.completed_references) {
			$state.completed_references += $focus
			Add-Content -Path $cycleLogPath -Value "- $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") :: reference completed ($focus)"
		}
	}
	else {
		$state.reference_streaks[$focus] = 0
		if (-not $failReason) {
			$failReason = "unknown_failure"
		}
		switch ($failReason) {
			"card_validation_failed" { Add-FeatureBacklog -path $featureBacklogPath -cycle $cycleNo -focus $focus -trigger $failReason -featureName "card_data_schema_repair" }
			"headless_smoke_failed" { Add-FeatureBacklog -path $featureBacklogPath -cycle $cycleNo -focus $focus -trigger $failReason -featureName "runtime_boot_stability" }
			"review_agent_rejected" { Add-FeatureBacklog -path $featureBacklogPath -cycle $cycleNo -focus $focus -trigger $failReason -featureName "plan_spec_clarity_upgrade" }
			default { Add-FeatureBacklog -path $featureBacklogPath -cycle $cycleNo -focus $focus -trigger $failReason -featureName "investigate_unknown_failure" }
		}
		Add-Content -Path $cycleLogPath -Value "- $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") :: cycle $cycleNo failed (focus=$focus, reason=$failReason, streak reset)"
	}
	$state.total_cycles = $cycleNo
	Save-State -path $statePath -state $state
}

Write-Output "RALPH_LOOP_COMPLETED=FALSE"
Write-Output "REASON=MAX_CYCLES_REACHED"
Write-Output "NEXT_ACTION=rerun loop or create $CompletionFlag to force stop"
Write-Output "TOTAL_CYCLES=$($state.total_cycles)"
Write-Output "TOTAL_ROUNDS=$($state.total_rounds)"
