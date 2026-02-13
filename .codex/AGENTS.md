# Codex Local Project Rules

## Scope
- Repository: `godot-001-card-battle`
- Engine: Godot 4.5 mono build

## Default Commands
- Editor: `tools\\start_editor_safe.bat`
- Headless smoke: `tools\\run_headless_smoke.bat`
- Run game: `Engine\\Godot_v4.5.1-stable_mono_win64\\Godot_v4.5.1-stable_mono_win64_console.exe --path .`

## Coding Conventions
- GDScript 4 syntax, tabs for indentation.
- Prefer type hints when practical.
- File naming: `snake_case.gd` / `snake_case.tscn`.
- Keep resource paths as `res://...`.

## Gameplay Validation Focus
- Card select/cancel input flow
- Mana spend/afford logic
- Minion spawn + state transitions
- Win/lose + pause state changes

## Workflow Notes
- Keep generated historical outputs in `docs/archive/ralph_runs/`.
- Keep active outputs in `docs/plans`, `docs/references`, `docs/graphics`, `docs/reviews`, `docs/qa`.
- For web references in planning docs, store local screenshots under `docs/plans/images/` and link local files.

## Prompt Logging
- For Codex CLI turns, save every incoming user prompt automatically in the same response cycle.
- Path: `docs/prompts/prompt_YYYYMMDD_HHMMSS.txt`
- Format:
  - line 1: `[Saved Prompt]`
  - line 2+: raw user prompt text
