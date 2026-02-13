param(
	[int]$TargetCount = 10000,
	[int]$BatchSize = 500,
	[string]$OutRoot = "docs/plans/images/web_refs_relevant",
	[string]$ManifestCsv = "docs/plans/data/web_reference_relevant.csv",
	[string]$ReportMd = "docs/references/web_reference_relevant_pack.md"
)

$ErrorActionPreference = "Stop"

function Test-IsImageFile {
	param([string]$Path)
	if (-not (Test-Path $Path)) { return $false }
	$bytes = [System.IO.File]::ReadAllBytes($Path)
	if ($bytes.Length -lt 10240) { return $false }
	# JPEG
	if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xD8 -and $bytes[2] -eq 0xFF) { return $true }
	# PNG
	if ($bytes.Length -ge 8 -and $bytes[0] -eq 0x89 -and $bytes[1] -eq 0x50 -and $bytes[2] -eq 0x4E -and $bytes[3] -eq 0x47) { return $true }
	# WEBP
	if ($bytes.Length -ge 12 -and $bytes[0] -eq 0x52 -and $bytes[1] -eq 0x49 -and $bytes[2] -eq 0x46 -and $bytes[3] -eq 0x46 -and $bytes[8] -eq 0x57 -and $bytes[9] -eq 0x45 -and $bytes[10] -eq 0x42 -and $bytes[11] -eq 0x50) { return $true }
	return $false
}

function Get-RelevanceScore {
	param(
		[string]$Name,
		[string[]]$Tags
	)
	$nameL = ($Name | ForEach-Object { $_.ToLowerInvariant() })
	$score = 0
	$reasons = @()

	$kwStrong = @("card", "deck", "battle", "tactics", "strategy", "duel", "arena", "auto battler")
	$kwSoft = @("tower", "roguelike", "turn-based", "lane", "summon")
	foreach ($k in $kwStrong) {
		if ($nameL -like "*$k*") { $score += 8; $reasons += "name:$k" }
	}
	foreach ($k in $kwSoft) {
		if ($nameL -like "*$k*") { $score += 3; $reasons += "name:$k" }
	}

	$tagStrong = @("Card Game", "Deckbuilding", "Strategy", "Auto Battler", "Tower Defense", "Turn-Based Strategy", "PvP")
	$tagSoft = @("Roguelike", "Fantasy", "Competitive", "RTS")
	foreach ($t in $Tags) {
		if ($tagStrong -contains $t) { $score += 10; $reasons += "tag:$t" }
		if ($tagSoft -contains $t) { $score += 4; $reasons += "tag:$t" }
	}

	return [PSCustomObject]@{
		score = $score
		reason = ($reasons -join ";")
	}
}

function Get-TagApps {
	param([string]$Tag)
	$u = "https://steamspy.com/api.php?request=tag&tag=$([uri]::EscapeDataString($Tag))"
	try {
		$res = Invoke-RestMethod -Uri $u -Method Get -TimeoutSec 90
		return $res
	} catch {
		return $null
	}
}

New-Item -ItemType Directory -Force -Path $OutRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $ManifestCsv) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $ReportMd) | Out-Null

$rows = @()
$hashSet = @{}
if (Test-Path $ManifestCsv) {
	$rows = Import-Csv $ManifestCsv
	foreach ($r in $rows) {
		if ($r.sha1) { $hashSet[$r.sha1] = $true }
	}
}

$nextId = 1
if ($rows.Count -gt 0) {
	$nextId = ([int](($rows | Measure-Object id -Maximum).Maximum)) + 1
}

$tagTargets = @(
	"Card Game",
	"Deckbuilding",
	"Strategy",
	"Auto Battler",
	"Tower Defense",
	"Turn-Based Strategy",
	"RTS",
	"PvP",
	"Tactical"
)

$candidates = @{}
foreach ($tag in $tagTargets) {
	$res = Get-TagApps -Tag $tag
	if ($null -eq $res) { continue }
	foreach ($p in $res.PSObject.Properties) {
		$v = $p.Value
		if ($null -eq $v) { continue }
		$id = [int]$v.appid
		if ($id -le 0) { continue }
		if (-not $candidates.ContainsKey($id)) {
			$candidates[$id] = [PSCustomObject]@{
				appid = $id
				name = [string]$v.name
				tags = @($tag)
			}
		} else {
			$c = $candidates[$id]
			if (-not ($c.tags -contains $tag)) { $c.tags += $tag }
		}
	}
}

$assetNames = @(
	"header.jpg",
	"capsule_616x353.jpg",
	"library_hero.jpg",
	"library_600x900.jpg"
)

$sorted = $candidates.Values | Sort-Object {
	$rv = Get-RelevanceScore -Name $_.name -Tags $_.tags
	-$rv.score
}

foreach ($app in $sorted) {
	if ($rows.Count -ge $TargetCount) { break }
	$rv = Get-RelevanceScore -Name $app.name -Tags $app.tags
	# Relevance gate: drop low-score/noisy entries.
	if ($rv.score -lt 12) { continue }

	foreach ($asset in $assetNames) {
		if ($rows.Count -ge $TargetCount) { break }
		$url = "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/$($app.appid)/$asset"
		$tmp = Join-Path $OutRoot "_tmp_$($app.appid)_$asset"
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

		$sha1 = (Get-FileHash -Path $tmp -Algorithm SHA1).Hash
		if ($hashSet.ContainsKey($sha1)) {
			Remove-Item $tmp -Force
			continue
		}

		$batchNo = [int][math]::Floor(($nextId - 1) / $BatchSize) + 1
		$batchDirName = ("batch_{0:D4}" -f $batchNo)
		$batchDir = Join-Path $OutRoot $batchDirName
		New-Item -ItemType Directory -Force -Path $batchDir | Out-Null

		$fileName = ("web_ref_{0:D5}.jpg" -f $nextId)
		$finalPath = Join-Path $batchDir $fileName
		Move-Item -Path $tmp -Destination $finalPath -Force

		$rows += [PSCustomObject]@{
			id = $nextId
			app_id = $app.appid
			app_name = $app.name
			tags = ($app.tags -join "|")
			relevance_score = $rv.score
			relevance_reason = $rv.reason
			asset = $asset
			source_url = $url
			local_path = ("docs/plans/images/web_refs_relevant/$batchDirName/$fileName")
			sha1 = $sha1
			bytes = (Get-Item $finalPath).Length
		}
		$hashSet[$sha1] = $true
		$nextId++
	}
}

$rows = $rows | Sort-Object {[int]$_.id}
$rows | Export-Csv -NoTypeInformation -Encoding UTF8 $ManifestCsv

$md = @()
$md += "# Web Reference Relevant Pack"
$md += ""
$md += "- GeneratedAt: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$md += "- Target: 카드배틀/전략 장르 관련성 높은 레퍼런스 우선 수집"
$md += "- Total: $($rows.Count)"
$md += "- BatchSize: $BatchSize"
$md += "- Manifest: `$ManifestCsv`"
$md += ""
$md += "## 배치 폴더 요약"
$group = $rows | Group-Object { ($_ .local_path -split '/')[4] } | Sort-Object Name
foreach ($g in $group) {
	$md += "- $($g.Name): $($g.Count) files"
}
$md += ""
$md += "## 최신 샘플 24개"
$preview = $rows | Sort-Object {[int]$_.id} -Descending | Select-Object -First 24 | Sort-Object {[int]$_.id}
foreach ($r in $preview) {
	$rel = $r.local_path.Replace("docs/plans/", "../plans/")
	$md += "### Ref $($r.id) / Score $($r.relevance_score) / $($r.app_name)"
	$md += "- Tags: $($r.tags)"
	$md += "- Source URL: $($r.source_url)"
	$md += "- Local File: `$($r.local_path)`"
	$md += "![ref_$($r.id)]($rel)"
	$md += ""
}
Set-Content -Path $ReportMd -Value $md -Encoding UTF8

Write-Output "RELEVANT_CRAWL_DONE"
Write-Output "TOTAL=$($rows.Count)"
Write-Output "MANIFEST=$ManifestCsv"
Write-Output "REPORT=$ReportMd"
