param(
	[int]$TargetCount = 1000,
	[int]$BatchSize = 500,
	[string]$ApiBase = "http://127.0.0.1:8188",
	[string]$OutRoot = "docs/plans/images/game_screenshots_generated",
	[string]$ManifestCsv = "docs/plans/data/game_screenshot_generated_manifest.csv",
	[int]$Width = 960,
	[int]$Height = 540,
	[int]$Steps = 6
)

$ErrorActionPreference = "Stop"

function Invoke-ComfyPrompt {
	param(
		[string]$ApiBase,
		[string]$PositivePrompt,
		[string]$NegativePrompt,
		[UInt64]$Seed,
		[int]$Width,
		[int]$Height,
		[int]$Steps
	)

	$workflow = @{
		"1"  = @{ class_type = "UNETLoader"; inputs = @{ unet_name = "flux1-schnell-fp8.safetensors"; weight_dtype = "default" } }
		"2"  = @{ class_type = "DualCLIPLoader"; inputs = @{ clip_name1 = "clip_l.safetensors"; clip_name2 = "t5xxl_fp8_e4m3fn.safetensors"; type = "flux" } }
		"3"  = @{ class_type = "VAELoader"; inputs = @{ vae_name = "ae.safetensors" } }
		"4"  = @{ class_type = "CLIPTextEncode"; inputs = @{ clip = @("2", 0); text = $PositivePrompt } }
		"5"  = @{ class_type = "FluxGuidance"; inputs = @{ conditioning = @("4", 0); guidance = 3.5 } }
		"6"  = @{ class_type = "CLIPTextEncode"; inputs = @{ clip = @("2", 0); text = $NegativePrompt } }
		"7"  = @{ class_type = "EmptyLatentImage"; inputs = @{ width = $Width; height = $Height; batch_size = 1 } }
		"8"  = @{ class_type = "ModelSamplingFlux"; inputs = @{ model = @("1", 0); max_shift = 1.15; base_shift = 0.5; width = $Width; height = $Height } }
		"9"  = @{ class_type = "KSampler"; inputs = @{ model = @("8", 0); seed = $Seed; steps = $Steps; cfg = 1.0; sampler_name = "euler"; scheduler = "simple"; positive = @("5", 0); negative = @("6", 0); latent_image = @("7", 0); denoise = 1.0 } }
		"10" = @{ class_type = "VAEDecode"; inputs = @{ samples = @("9", 0); vae = @("3", 0) } }
		"11" = @{ class_type = "SaveImage"; inputs = @{ images = @("10", 0); filename_prefix = "ralph_screenshot_ref" } }
	}

	$body = @{
		prompt = $workflow
		client_id = "ralph-screenshot-agent"
	} | ConvertTo-Json -Depth 20

	$res = Invoke-RestMethod -Uri "$ApiBase/prompt" -Method Post -ContentType "application/json" -Body $body
	return $res.prompt_id
}

function Wait-ComfyImage {
	param(
		[string]$ApiBase,
		[string]$PromptId,
		[int]$TimeoutSec = 180
	)
	$start = Get-Date
	while (((Get-Date) - $start).TotalSeconds -lt $TimeoutSec) {
		Start-Sleep -Milliseconds 1200
		$h = Invoke-RestMethod -Uri "$ApiBase/history/$PromptId" -Method Get
		if ($null -eq $h) { continue }
		if (-not $h.PSObject.Properties.Name -contains $PromptId) { continue }
		$item = $h.$PromptId
		if ($null -eq $item.outputs) { continue }
		if (-not $item.outputs.PSObject.Properties.Name -contains "11") { continue }
		$imgs = $item.outputs."11".images
		if ($null -eq $imgs -or $imgs.Count -eq 0) { continue }
		return $imgs[0]
	}
	return $null
}

function Download-ComfyImage {
	param(
		[string]$ApiBase,
		[object]$ImageMeta,
		[string]$OutPath
	)
	$fname = [uri]::EscapeDataString([string]$ImageMeta.filename)
	$sub = [uri]::EscapeDataString([string]$ImageMeta.subfolder)
	$type = [uri]::EscapeDataString([string]$ImageMeta.type)
	$url = "$ApiBase/view?filename=$fname&subfolder=$sub&type=$type"
	curl.exe -L $url -o $OutPath | Out-Null
}

function Test-IsImageFile {
	param([string]$Path)
	if (-not (Test-Path $Path)) { return $false }
	$bytes = [System.IO.File]::ReadAllBytes($Path)
	if ($bytes.Length -lt 10240) { return $false }
	if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xD8 -and $bytes[2] -eq 0xFF) { return $true }
	if ($bytes.Length -ge 8 -and $bytes[0] -eq 0x89 -and $bytes[1] -eq 0x50 -and $bytes[2] -eq 0x4E -and $bytes[3] -eq 0x47) { return $true }
	return $false
}

New-Item -ItemType Directory -Force -Path $OutRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $ManifestCsv) | Out-Null

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

$prompts = @(
	"top-down fantasy card battle arena screenshot, two lanes, minions fighting, UI readable, gameplay capture, high clarity",
	"card battle gameplay screenshot, tactical lane combat, vivid spell effects, readable units, esports style broadcast frame",
	"deck-based arena battle screenshot, hero tower and summoned units, clear battlefield silhouettes, gameplay camera",
	"real-time card tactics gameplay screenshot, lane push and counterplay moment, balanced composition, game HUD feel",
	"competitive card battler screenshot, action freeze-frame, clear health bars and mana cues, polished game scene"
)
$neg = "logo, watermark, text wall, blurry, lowres, jpeg artifacts, deformed ui, poster, concept art sheet"

while ($rows.Count -lt $TargetCount) {
	$seed = [UInt64](Get-Random -Minimum 1 -Maximum 2147483647)
	$prompt = $prompts[(Get-Random -Minimum 0 -Maximum $prompts.Count)]
	$promptId = Invoke-ComfyPrompt -ApiBase $ApiBase -PositivePrompt $prompt -NegativePrompt $neg -Seed $seed -Width $Width -Height $Height -Steps $Steps
	$imgMeta = Wait-ComfyImage -ApiBase $ApiBase -PromptId $promptId -TimeoutSec 240
	if ($null -eq $imgMeta) { continue }

	$batchNo = [int][math]::Floor(($nextId - 1) / $BatchSize) + 1
	$batchDirName = ("batch_{0:D4}" -f $batchNo)
	$batchDir = Join-Path $OutRoot $batchDirName
	New-Item -ItemType Directory -Force -Path $batchDir | Out-Null

	$fileName = ("shot_{0:D5}.png" -f $nextId)
	$filePath = Join-Path $batchDir $fileName
	Download-ComfyImage -ApiBase $ApiBase -ImageMeta $imgMeta -OutPath $filePath
	if (-not (Test-IsImageFile -Path $filePath)) {
		if (Test-Path $filePath) { Remove-Item $filePath -Force }
		continue
	}

	$sha1 = (Get-FileHash -Path $filePath -Algorithm SHA1).Hash
	if ($hashSet.ContainsKey($sha1)) {
		Remove-Item $filePath -Force
		continue
	}

	$rows += [PSCustomObject]@{
		id = $nextId
		source = "comfyui"
		prompt = $prompt
		seed = $seed
		local_path = ("docs/plans/images/game_screenshots_generated/$batchDirName/$fileName")
		sha1 = $sha1
		bytes = (Get-Item $filePath).Length
	}
	$hashSet[$sha1] = $true
	$nextId++

	if (($rows.Count % 20) -eq 0) {
		$rows | Export-Csv -NoTypeInformation -Encoding UTF8 $ManifestCsv
	}
}

$rows = $rows | Sort-Object {[int]$_.id}
$rows | Export-Csv -NoTypeInformation -Encoding UTF8 $ManifestCsv

Write-Output "COMFY_SCREENSHOT_GEN_DONE"
Write-Output "TOTAL=$($rows.Count)"
Write-Output "MANIFEST=$ManifestCsv"
