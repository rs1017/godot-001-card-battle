param(
	[string]$KaykitRoot = "assets/kaykit",
	[string]$CardsRoot = "resources/cards",
	[string]$OutManifest = "docs/plans/data/kaykit_resource_manifest.csv",
	[string]$OutCardMap = "docs/plans/data/kaykit_card_model_map.csv"
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$kaykitPath = Join-Path $repoRoot $KaykitRoot
$cardsPath = Join-Path $repoRoot $CardsRoot
$manifestPath = Join-Path $repoRoot $OutManifest
$cardMapPath = Join-Path $repoRoot $OutCardMap

if (-not (Test-Path $kaykitPath)) {
	throw "KayKit root not found: $kaykitPath"
}
if (-not (Test-Path $cardsPath)) {
	throw "Cards root not found: $cardsPath"
}

New-Item -ItemType Directory -Force -Path (Split-Path $manifestPath -Parent) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $cardMapPath -Parent) | Out-Null

function To-ResPath([string]$fullPath) {
	$relative = $fullPath.Substring($repoRoot.Length).TrimStart('\').Replace('\', '/')
	return "res://$relative"
}

$files = Get-ChildItem -Path $kaykitPath -Recurse -File |
	Where-Object { $_.Extension -in @(".glb", ".fbx", ".png") } |
	Sort-Object FullName

$manifestRows = @()
foreach ($f in $files) {
	$manifestRows += [PSCustomObject]@{
		resource_path = To-ResPath $f.FullName
		ext = $f.Extension.TrimStart(".").ToLower()
		size_bytes = $f.Length
	}
}
$manifestRows | Export-Csv -Path $manifestPath -NoTypeInformation -Encoding UTF8

$cards = Get-ChildItem -Path $cardsPath -Filter *.tres | Sort-Object Name
$cardRows = @()
foreach ($card in $cards) {
	$content = Get-Content -Path $card.FullName -Raw
	$mName = [regex]::Match($content, '(?m)^\s*card_name\s*=\s*"([^"]+)"')
	$mModel = [regex]::Match($content, '(?m)^\s*kaykit_model_path\s*=\s*"([^"]*)"')
	$cardName = if ($mName.Success) { $mName.Groups[1].Value } else { $card.BaseName }
	$modelPath = if ($mModel.Success) { $mModel.Groups[1].Value } else { "" }
	$exists = $false
	if ($modelPath -ne "") {
		$local = $modelPath.Replace("res://", "").Replace("/", "\")
		$exists = Test-Path (Join-Path $repoRoot $local)
	}
	$cardRows += [PSCustomObject]@{
		card_file = $card.Name
		card_name = $cardName
		kaykit_model_path = $modelPath
		model_exists = $exists
	}
}
$cardRows | Export-Csv -Path $cardMapPath -NoTypeInformation -Encoding UTF8

$missing = ($cardRows | Where-Object { -not $_.model_exists }).Count
Write-Output "KAYKIT_MANIFEST=$manifestPath"
Write-Output "KAYKIT_CARD_MAP=$cardMapPath"
Write-Output "KAYKIT_TOTAL_FILES=$($manifestRows.Count)"
Write-Output "KAYKIT_MISSING_CARD_MODELS=$missing"
