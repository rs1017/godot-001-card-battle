param(
	[string]$CodexDir = ".codex"
)

$ErrorActionPreference = "Stop"

$targetRoot = if ([System.IO.Path]::IsPathRooted($CodexDir)) {
	$CodexDir
} else {
	Join-Path (Get-Location) $CodexDir
}

$subDirs = @(
	".sandbox",
	"log",
	"rules",
	"sessions",
	"skills",
	"tmp"
)

if (-not (Test-Path -Path $targetRoot)) {
	New-Item -ItemType Directory -Path $targetRoot -ErrorAction Stop | Out-Null
}

$created = @()
$failed = @()

foreach ($subDir in $subDirs) {
	$fullPath = Join-Path $targetRoot $subDir
	if (-not (Test-Path -Path $fullPath)) {
		try {
			New-Item -ItemType Directory -Path $fullPath -ErrorAction Stop | Out-Null
			$created += $fullPath
		} catch {
			$failed += $fullPath
			Write-Warning ("Failed to create: {0} ({1})" -f $fullPath, $_.Exception.Message)
		}
	}
}

Write-Output "Initialized Codex local directories at: $targetRoot"
if ($created.Count -gt 0) {
	Write-Output ("Created {0} directories." -f $created.Count)
}
if ($failed.Count -gt 0) {
	Write-Error ("Could not create {0} directories. Check ACL/permissions on {1}" -f $failed.Count, $targetRoot)
}
