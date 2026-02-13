param(
	[int]$MaxAttempts = 2
)

$ErrorActionPreference = "Stop"

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
namespace Win32 {
	public static class NativeMethods {
		[DllImport("kernel32.dll")]
		public static extern uint SetErrorMode(uint uMode);
	}
}
"@

# Suppress Windows crash dialog boxes for this process and child processes.
[void][Win32.NativeMethods]::SetErrorMode(0x0001 -bor 0x0002)

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$enginePath = Join-Path $repoRoot "Engine\Godot_v4.5.1-stable_mono_win64\Godot_v4.5.1-stable_mono_win64_console.exe"
$tmpDir = Join-Path $repoRoot ".tmp"
$logPath = Join-Path $tmpDir "godot-headless.log"

if (-not (Test-Path $tmpDir)) {
	New-Item -ItemType Directory -Path $tmpDir | Out-Null
}

function Reset-GodotVolatileCache([string]$root) {
	$targets = @(
		Join-Path $root ".godot\editor",
		Join-Path $root ".godot\mono\temp",
		Join-Path $root ".godot\mono\metadata"
	)
	foreach ($target in $targets) {
		if (Test-Path $target) {
			Remove-Item -Path $target -Recurse -Force -ErrorAction SilentlyContinue
		}
	}
}

if (-not (Test-Path $enginePath)) {
	Write-Output "[FAIL] Godot console executable not found: $enginePath"
	exit 1
}

$lastExitCode = 1
for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
	if ($attempt -gt 1) {
		Write-Output "[RECOVER] Resetting volatile Godot cache before retry..."
		Reset-GodotVolatileCache -root $repoRoot
	}

	Write-Output "Running headless smoke check (attempt $attempt/$MaxAttempts)..."
	$args = @("--headless", "--path", ".", "--log-file", $logPath, "--quit")
	$proc = Start-Process -FilePath $enginePath -ArgumentList $args -WorkingDirectory $repoRoot -NoNewWindow -Wait -PassThru
	$lastExitCode = $proc.ExitCode
	if ($lastExitCode -eq 0) {
		Write-Output "[OK] Headless smoke check passed."
		exit 0
	}
}

Write-Output "[FAIL] Headless smoke check failed with code $lastExitCode."
Write-Output "Check `"$logPath`" for details."
exit $lastExitCode
