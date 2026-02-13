param(
	[int]$TargetCount = 1200,
	[string]$OutDir = "docs/plans/images/web_refs",
	[string]$CsvPath = "docs/plans/data/web_reference_sources.csv",
	[string]$IndexMdPath = "docs/references/web_reference_pack.md",
	[int]$MaxAppsToScan = 2500
)

$ErrorActionPreference = "Stop"

function Test-IsImageFile {
	param([string]$Path)
	if (-not (Test-Path $Path)) { return $false }
	$bytes = [System.IO.File]::ReadAllBytes($Path)
	if ($bytes.Length -lt 1024) { return $false }
	# JPEG
	if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xD8 -and $bytes[2] -eq 0xFF) { return $true }
	# PNG
	if ($bytes.Length -ge 8 -and $bytes[0] -eq 0x89 -and $bytes[1] -eq 0x50 -and $bytes[2] -eq 0x4E -and $bytes[3] -eq 0x47) { return $true }
	# WEBP (RIFF....WEBP)
	if ($bytes.Length -ge 12 -and $bytes[0] -eq 0x52 -and $bytes[1] -eq 0x49 -and $bytes[2] -eq 0x46 -and $bytes[3] -eq 0x46 -and $bytes[8] -eq 0x57 -and $bytes[9] -eq 0x45 -and $bytes[10] -eq 0x42 -and $bytes[11] -eq 0x50) { return $true }
	return $false
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $CsvPath) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $IndexMdPath) | Out-Null

$assetNames = @(
	"header.jpg",
	"capsule_616x353.jpg",
	"library_hero.jpg",
	"capsule_231x87.jpg",
	"page_bg_generated_v6b.jpg"
)

function Get-AppCandidates {
	param([int]$Limit = 2500)
	$targets = @(
		"https://steamspy.com/api.php?request=top100in2weeks",
		"https://steamspy.com/api.php?request=top100forever",
		"https://steamspy.com/api.php?request=top100owned"
	)
	$dict = @{}
	foreach ($u in $targets) {
		try {
			$res = Invoke-RestMethod -Uri $u -Method Get -TimeoutSec 60
			foreach ($p in $res.PSObject.Properties) {
				$v = $p.Value
				if ($null -eq $v) { continue }
				$id = [int]$v.appid
				if ($id -le 0) { continue }
				if (-not $dict.ContainsKey($id)) {
					$dict[$id] = [PSCustomObject]@{ appid = $id; name = [string]$v.name }
				}
			}
		} catch {
			continue
		}
	}

	# Fallback pool if API result size is small.
	if ($dict.Count -lt 500) {
		foreach ($id in 10..12000) {
			if (-not $dict.ContainsKey($id)) {
				$dict[$id] = [PSCustomObject]@{ appid = $id; name = "" }
			}
			if ($dict.Count -ge $Limit) { break }
		}
	}

	return $dict.Values | Select-Object -First $Limit
}

$apps = Get-AppCandidates -Limit $MaxAppsToScan

$existingHashes = @{}
$existingRows = @()
if (Test-Path $CsvPath) {
	$existingRows = Import-Csv $CsvPath
	foreach ($r in $existingRows) {
		if ($r.sha1) { $existingHashes[$r.sha1] = $true }
	}
}

$rows = @()
if ($existingRows.Count -gt 0) {
	$rows += $existingRows
}

$nextId = 1
if ($rows.Count -gt 0) {
	$nextId = ([int](($rows | Measure-Object id -Maximum).Maximum)) + 1
}

foreach ($app in $apps) {
	if ($rows.Count -ge $TargetCount) { break }
	$appId = [int]$app.appid
	$appName = [string]$app.name

	foreach ($asset in $assetNames) {
		if ($rows.Count -ge $TargetCount) { break }
		$url = "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/$appId/$asset"
		$tmp = Join-Path $OutDir "_tmp_$($appId)_$asset"

		try {
			curl.exe -L $url -o $tmp | Out-Null
		} catch {
			if (Test-Path $tmp) { Remove-Item $tmp -Force }
			continue
		}

		if (-not (Test-IsImageFile -Path $tmp)) {
			if (Test-Path $tmp) { Remove-Item $tmp -Force }
			continue
		}

		$hash = (Get-FileHash -Path $tmp -Algorithm SHA1).Hash
		if ($existingHashes.ContainsKey($hash)) {
			Remove-Item $tmp -Force
			continue
		}

		$fileName = ("web_ref_{0:D5}.jpg" -f $nextId)
		$finalPath = Join-Path $OutDir $fileName
		Move-Item -Path $tmp -Destination $finalPath -Force

		$bytes = (Get-Item $finalPath).Length
		$rows += [PSCustomObject]@{
			id         = $nextId
			app_id     = $appId
			app_name   = $appName
			asset      = $asset
			source_url = $url
			local_path = ("docs/plans/images/web_refs/" + $fileName)
			sha1       = $hash
			bytes      = $bytes
		}
		$existingHashes[$hash] = $true
		$nextId++
	}
}

$rows = $rows | Sort-Object {[int]$_.id}
$rows | Export-Csv -NoTypeInformation -Encoding UTF8 $CsvPath

$md = @()
$md += "# Web Reference Pack"
$md += ""
$md += "- GeneratedAt: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$md += "- Rule: 웹 크롤링으로 레퍼런스 이미지를 수집하고, 로컬 파일로 저장 후 기획서에는 로컬 링크만 사용"
$md += "- Total downloaded: $($rows.Count)"
$md += ('- Source CSV: `' + $CsvPath + '`')
$md += ""
$md += "## 샘플 미리보기 (최신 48개)"

$preview = $rows | Sort-Object {[int]$_.id} -Descending | Select-Object -First 48 | Sort-Object {[int]$_.id}
foreach ($r in $preview) {
	$rel = $r.local_path.Replace("docs/plans/", "../plans/")
	$md += "### Ref $($r.id) - $($r.app_name) / $($r.asset)"
	$md += "- Source URL: $($r.source_url)"
	$md += ('- Local File: `' + $r.local_path + '`')
	$md += "![ref_$($r.id)]($rel)"
	$md += ""
}

Set-Content -Path $IndexMdPath -Value $md -Encoding UTF8

Write-Output "CRAWL_DONE"
Write-Output "TOTAL=$($rows.Count)"
Write-Output "CSV=$CsvPath"
Write-Output "INDEX=$IndexMdPath"
