$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$cardsDir = Join-Path $projectRoot "resources/cards"

if (-not (Test-Path $cardsDir)) {
	Write-Error "cards directory not found: $cardsDir"
}

$requiredFields = @(
	"card_name", "mana_cost", "card_category", "minion_type", "health", "damage",
	"attack_speed", "move_speed", "attack_range", "aggro_range", "kaykit_model_path"
)

$results = @()
$files = Get-ChildItem -Path $cardsDir -Filter *.tres | Sort-Object Name

foreach ($file in $files) {
	$content = Get-Content -Raw $file.FullName
	$data = @{}

	foreach ($field in $requiredFields) {
		$pattern = "(?m)^\s*$field\s*=\s*(.+)$"
		$m = [regex]::Match($content, $pattern)
		if ($m.Success) {
			$data[$field] = $m.Groups[1].Value.Trim()
		}
	}

	$errors = @()
	foreach ($field in $requiredFields) {
		if (-not $data.ContainsKey($field)) {
			$errors += "missing field: $field"
		}
	}

	if ($data.ContainsKey("mana_cost")) {
		$mana = [int]$data["mana_cost"]
		if ($mana -lt 1 -or $mana -gt 10) { $errors += "mana_cost out of range (1-10): $mana" }
	}
	if ($data.ContainsKey("card_category")) {
		$category = [int]$data["card_category"]
		if ($category -lt 0 -or $category -gt 2) { $errors += "card_category out of range (0-2): $category" }
	}
	if ($data.ContainsKey("minion_type")) {
		$type = [int]$data["minion_type"]
		if ($type -lt 0 -or $type -gt 2) { $errors += "minion_type out of range (0-2): $type" }
	}
	if ($data.ContainsKey("health")) {
		$health = [int]$data["health"]
		if ($health -le 0) { $errors += "health must be > 0: $health" }
	}
	if ($data.ContainsKey("damage")) {
		$damage = [int]$data["damage"]
		if ($damage -le 0) { $errors += "damage must be > 0: $damage" }
	}
	if ($data.ContainsKey("attack_speed")) {
		$as = [double]$data["attack_speed"]
		if ($as -le 0) { $errors += "attack_speed must be > 0: $as" }
	}
	if ($data.ContainsKey("move_speed")) {
		$ms = [double]$data["move_speed"]
		if ($ms -le 0) { $errors += "move_speed must be > 0: $ms" }
	}
	if ($data.ContainsKey("attack_range")) {
		$ar = [double]$data["attack_range"]
		if ($ar -le 0) { $errors += "attack_range must be > 0: $ar" }
	}
	if ($data.ContainsKey("aggro_range")) {
		$agr = [double]$data["aggro_range"]
		if ($agr -le 0) { $errors += "aggro_range must be > 0: $agr" }
	}

	if ($data.ContainsKey("kaykit_model_path")) {
		$modelPath = $data["kaykit_model_path"].Trim('"')
		if ($modelPath.StartsWith("res://")) {
			$relative = $modelPath.Replace("res://", "").Replace("/", "\")
			$fullPath = Join-Path $projectRoot $relative
			if (-not (Test-Path $fullPath)) {
				$errors += "model path not found: $modelPath"
			}
		} else {
			$errors += "model path must start with res://: $modelPath"
		}
	}

	$results += [PSCustomObject]@{
		File = $file.Name
		Card = ($data["card_name"] -replace '^"|"$')
		Mana = $data["mana_cost"]
		Category = $data["card_category"]
		Type = $data["minion_type"]
		Health = $data["health"]
		Damage = $data["damage"]
		Status = $(if ($errors.Count -eq 0) { "OK" } else { "FAIL" })
		Issues = ($errors -join "; ")
	}
}

$results | Format-Table -AutoSize

if ($results.Where({ $_.Status -eq "FAIL" }).Count -gt 0) {
	exit 1
}

exit 0
