param(
	[string]$OutputPath,
	[string]$ReferenceFocus = "global",
	[int]$CycleId = 1
)

$ErrorActionPreference = "Stop"

$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$body = @"
# ComfyUI Image Requests

- GeneratedAt: $now
- CycleId: $CycleId
- ReferenceFocus: $ReferenceFocus
- Owner: Grapher Team

## Request 1: Main Page Hero
- Prompt: stylized card battle main menu, cinematic lighting, clear CTA area, fantasy arena atmosphere
- Output: 1920x1080 PNG

## Request 2: Battle Map Overview
- Prompt: top-down readable dual-lane arena, strong lane contrast, bridge and tower landmarks
- Output: 1920x1080 PNG

## Request 3: Victory Screen
- Prompt: celebratory card battle victory composition, confetti particles, strong focal title
- Output: 1920x1080 PNG

## Request 4: Defeat Screen
- Prompt: dramatic defeat composition, desaturated mood, readable retry CTA
- Output: 1920x1080 PNG

## Request 5: Card Deck UI Concepts
- Prompt: tactical deck builder interface, card rarity chips, mana curve visualization
- Output: 1920x1080 PNG
"@
Set-Content -Path $OutputPath -Value $body -Encoding UTF8
Write-Output "COMFYUI_REQUEST_FILE=$OutputPath"
