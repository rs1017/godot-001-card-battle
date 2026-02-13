param(
	[int]$ChunkSize = 500,
	[int]$MaxTotal = 10000,
	[int]$Width = 832,
	[int]$Height = 468,
	[int]$Steps = 4
)

$ErrorActionPreference = "Stop"
$manifest = "docs/plans/data/game_screenshot_generated_manifest.csv"

function Get-CurrentCount {
	param([string]$CsvPath)
	if (-not (Test-Path $CsvPath)) { return 0 }
	return (Import-Csv $CsvPath | Measure-Object).Count
}

while ($true) {
	$current = Get-CurrentCount -CsvPath $manifest
	if ($current -ge $MaxTotal) {
		Write-Output "DONE current=$current"
		break
	}

	$target = $current + $ChunkSize
	if ($target -gt $MaxTotal) { $target = $MaxTotal }
	Write-Output "RUN chunk current=$current target=$target"

	& "$PSScriptRoot\generate_comfy_screenshot_refs.ps1" `
		-TargetCount $target `
		-BatchSize 500 `
		-Width $Width `
		-Height $Height `
		-Steps $Steps | Out-Host

	$after = Get-CurrentCount -CsvPath $manifest
	if ($after -le $current) {
		Write-Output "NO_PROGRESS current=$current after=$after"
		break
	}
}
