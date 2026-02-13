param(
	[string]$GuiExe = "Engine\Godot_v4.5.1-stable_mono_win64\Godot_v4.5.1-stable_mono_win64.exe",
	[string]$LogFile = "docs\qa\bug_reports\godot-live.log",
	[string]$ErrorLog = "docs\qa\bug_reports\godot-errors.log",
	[string]$Resolution = "1600x900",
	[string]$Position = "120,60"
)

$ErrorActionPreference = "Stop"

Write-Host "[LIVE GAME LOG]" -ForegroundColor Cyan
Write-Host "[ERROR LOG] $ErrorLog" -ForegroundColor Yellow

$argList = @(
	"--path", ".",
	"--rendering-driver", "opengl3",
	"--windowed",
	"--resolution", $Resolution,
	"--position", $Position,
	"--log-file", $LogFile
)

$proc = Start-Process -FilePath $GuiExe -ArgumentList $argList -WorkingDirectory (Get-Location).Path -PassThru

while (-not (Test-Path $LogFile)) {
	if ($proc.HasExited) {
		exit 0
	}
	Start-Sleep -Milliseconds 200
}

$fs = [System.IO.File]::Open($LogFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
$sr = New-Object System.IO.StreamReader($fs)

try {
	while ($true) {
		while (-not $sr.EndOfStream) {
			$line = $sr.ReadLine()
			if ($null -eq $line) {
				continue
			}
			Write-Host $line
			if ($line.StartsWith("ERROR:")) {
				Add-Content -Path $ErrorLog -Value $line
			}
		}

		if ($proc.HasExited) {
			break
		}
		Start-Sleep -Milliseconds 200
	}
}
finally {
	$sr.Close()
	$fs.Close()
}
