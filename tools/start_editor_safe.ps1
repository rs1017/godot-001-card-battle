param(
	[string[]]$ExtraArgs,
	[switch]$SkipRecovery
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

[void][Win32.NativeMethods]::SetErrorMode(0x0001 -bor 0x0002)

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$editorPath = Join-Path $repoRoot "Engine\Godot_v4.5.1-stable_mono_win64\Godot_v4.5.1-stable_mono_win64.exe"

if (-not (Test-Path $editorPath)) {
	Write-Output "[FAIL] Godot editor executable not found: $editorPath"
	exit 1
}

$args = @("--path", ".")
if (-not $SkipRecovery) {
	$targets = @(
		(Join-Path $repoRoot ".godot\editor"),
		(Join-Path $repoRoot ".godot\mono")
	)
	foreach ($target in $targets) {
		if (Test-Path $target) {
			Remove-Item -Path $target -Recurse -Force -ErrorAction SilentlyContinue
		}
	}
}

# Safe mode disables editor plugins and unstable editor state.
$args += "--safe-mode"
if ($ExtraArgs) {
	$args += $ExtraArgs
}

Start-Process -FilePath $editorPath -ArgumentList $args -WorkingDirectory $repoRoot | Out-Null
Write-Output "[OK] Godot editor started in safe mode."
