param(
	[string]$TargetsCsv = "docs/references/target_games.csv",
	[int]$TargetCount = 3000,
	[int]$BatchSize = 500,
	[string]$OutRoot = "docs/plans/images/game_screenshots",
	[string]$ManifestCsv = "docs/plans/data/game_screenshot_manifest.csv",
	[string]$ReportMd = "docs/references/game_screenshot_pack.md"
)

$ErrorActionPreference = "Stop"

function Test-IsImageFile {
	param([string]$Path)
	if (-not (Test-Path $Path)) { return $false }
	$bytes = [System.IO.File]::ReadAllBytes($Path)
	if ($bytes.Length -lt 10240) { return $false }
	if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xD8 -and $bytes[2] -eq 0xFF) { return $true }
	if ($bytes.Length -ge 8 -and $bytes[0] -eq 0x89 -and $bytes[1] -eq 0x50 -and $bytes[2] -eq 0x4E -and $bytes[3] -eq 0x47) { return $true }
	return $false
}

function Get-ScreenshotUrlsFromHtml {
	param([string]$Html)
	$matches = [regex]::Matches($Html, "https://shared\.fastly\.steamstatic\.com/store_item_assets/steam/apps/\d+/ss_[a-zA-Z0-9_]+\.(jpg|png)(\?t=\d+)?")
	$urls = @()
	foreach ($m in $matches) {
		$u = $m.Value -replace "\?t=\d+$", ""
		$urls += $u
	}
	return $urls | Sort-Object -Unique
}

New-Item -ItemType Directory -Force -Path $OutRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $ManifestCsv) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $ReportMd) | Out-Null

if (-not (Test-Path $TargetsCsv)) {
	throw "Missing target list: $TargetsCsv"
}
$targets = Import-Csv $TargetsCsv

$rows = @()
$hashes = @{}
if (Test-Path $ManifestCsv) {
	$rows = Import-Csv $ManifestCsv
	foreach ($r in $rows) {
		if ($r.sha1) { $hashes[$r.sha1] = $true }
	}
}

$nextId = 1
if ($rows.Count -gt 0) {
	$nextId = ([int](($rows | Measure-Object id -Maximum).Maximum)) + 1
}

foreach ($t in $targets) {
	if ($rows.Count -ge $TargetCount) { break }
	$appId = [int]$t.app_id
	$name = [string]$t.game_name
	$reason = [string]$t.reason
	$pageUrl = "https://store.steampowered.com/app/$appId/?l=english"
	$htmlPath = Join-Path $OutRoot ("_page_{0}.html" -f $appId)
	try {
		curl.exe -L $pageUrl -o $htmlPath | Out-Null
	} catch {
		if (Test-Path $htmlPath) { Remove-Item $htmlPath -Force }
		continue
	}

	if (-not (Test-Path $htmlPath)) { continue }
	$html = Get-Content $htmlPath -Raw
	Remove-Item $htmlPath -Force

	$urls = Get-ScreenshotUrlsFromHtml -Html $html
	foreach ($u in $urls) {
		if ($rows.Count -ge $TargetCount) { break }
		$tmp = Join-Path $OutRoot ("_tmp_{0}.jpg" -f $nextId)
		try {
			curl.exe -L $u -o $tmp | Out-Null
		} catch {
			if (Test-Path $tmp) { Remove-Item $tmp -Force }
			continue
		}

		if (-not (Test-IsImageFile -Path $tmp)) {
			if (Test-Path $tmp) { Remove-Item $tmp -Force }
			continue
		}

		$sha1 = (Get-FileHash -Path $tmp -Algorithm SHA1).Hash
		if ($hashes.ContainsKey($sha1)) {
			Remove-Item $tmp -Force
			continue
		}

		$batchNo = [int][math]::Floor(($nextId - 1) / $BatchSize) + 1
		$batchDirName = ("batch_{0:D4}" -f $batchNo)
		$batchDir = Join-Path $OutRoot $batchDirName
		New-Item -ItemType Directory -Force -Path $batchDir | Out-Null

		$fileName = ("shot_{0:D5}.jpg" -f $nextId)
		$finalPath = Join-Path $batchDir $fileName
		Move-Item -Path $tmp -Destination $finalPath -Force

		$rows += [PSCustomObject]@{
			id = $nextId
			app_id = $appId
			game_name = $name
			reason = $reason
			source_page = $pageUrl
			source_url = $u
			local_path = ("docs/plans/images/game_screenshots/{0}/{1}" -f $batchDirName, $fileName)
			sha1 = $sha1
			bytes = (Get-Item $finalPath).Length
		}
		$hashes[$sha1] = $true
		$nextId++
	}
}

$rows = $rows | Sort-Object {[int]$_.id}
$rows | Export-Csv -NoTypeInformation -Encoding UTF8 $ManifestCsv

$md = @()
$md += "# Game Screenshot Reference Pack"
$md += ""
$md += "- GeneratedAt: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$md += "- Total screenshots: $($rows.Count)"
$md += ('- Target list: `' + $TargetsCsv + '`')
$md += ('- Manifest: `' + $ManifestCsv + '`')
$md += "- Rule: gameplay screenshots only (ss_*.jpg)"
$md += ""
$md += "## Batch Summary"
$g = $rows | Group-Object { ($_.local_path -split "/")[4] } | Sort-Object Name
foreach ($b in $g) {
	$md += "- $($b.Name): $($b.Count)"
}
$md += ""
$md += "## Latest 30"
$preview = $rows | Sort-Object {[int]$_.id} -Descending | Select-Object -First 30 | Sort-Object {[int]$_.id}
foreach ($r in $preview) {
	$rel = $r.local_path.Replace("docs/plans/", "../plans/")
	$md += "### Ref $($r.id) - $($r.game_name)"
	$md += "- Source URL: $($r.source_url)"
	$md += ('- Local File: `' + $r.local_path + '`')
	$md += "![shot_$($r.id)]($rel)"
	$md += ""
}
Set-Content -Path $ReportMd -Value $md -Encoding UTF8

Write-Output "SCREENSHOT_CRAWL_DONE"
Write-Output "TOTAL=$($rows.Count)"
Write-Output "MANIFEST=$ManifestCsv"
Write-Output "REPORT=$ReportMd"
