# Repository Guidelines

## Project Structure & Module Organization
- `project.godot` is the Godot 4.5 project entry; `scenes/main.tscn` is the main scene.
- `scripts/` contains gameplay code by domain:
  - `scripts/battle/` match flow, lane logic, mana, deck, AI.
  - `scripts/entities/`, `scripts/components/`, `scripts/minion_states/`, `scripts/state_machine/` for units and behavior.
  - `scripts/ui/` for HUD, hand, and card presentation.
  - `scripts/autoload/` global singletons (`EventBus`, `GameManager`).
- `scenes/` stores scene files (`scenes/battle/`, `scenes/ui/`), `resources/cards/` stores card data `.tres`, and `assets/` stores imported art/models.
- Keep Godot-generated `.uid` and `.import` files tracked with their related assets/scripts.

## Build, Test, and Development Commands
- Start editor (safe): `tools\start_editor_safe.bat`
- Run game (console): `Engine\Godot_v4.5.1-stable_mono_win64\Godot_v4.5.1-stable_mono_win64_console.exe --path .`
- Headless quick check (safe wrapper): `tools\run_headless_smoke.bat`
- Recreate local links (`Engine`, `reference`, `godot-game`): `.\godot_setup_link.bat`
- Stable run rule: use `tools\run_game_stable.bat` (GUI + console together) and enforce windowed mode (`--windowed`).

## Runtime Error Runbook
- When runtime startup fails, run in this order:
  1) `tools\run_headless_smoke.bat`
  2) `tools\run_game_stable.bat`
  3) direct GUI fallback: `Engine\Godot_v4.5.1-stable_mono_win64\Godot_v4.5.1-stable_mono_win64.exe --path . --rendering-driver opengl3`
- If `Could not create directory: 'user://logs'` appears:
  - treat console launch as unstable for that session,
  - use GUI launch path above as default temporary run path,
  - log the failure text in QA/dev log and inspect `user://` write permissions and startup logging path configuration before re-enabling console-first runs.

## Coding Style & Naming Conventions
- Use GDScript (Godot 4 syntax), tabs for indentation, and explicit type hints where practical.
- File names: `snake_case.gd`; scene names: `snake_case.tscn`; class/type names and enums: `PascalCase`.
- Prefer `_private_member` for internal state and `UPPER_SNAKE_CASE` for constants.
- Use `res://` paths for all loads/preloads.

## Testing Guidelines
- There is no dedicated automated test suite yet; validate features in-editor and with the headless smoke command above.
- For gameplay changes, verify:
  - card select/cancel input actions,
  - mana spend/afford flow,
  - minion spawn and state transitions,
  - win/lose and pause state changes.
  - bug reporter UI flow: when bug button is pressed, `버그 보내기` button must be visible and actionable.
- When adding tests later, use a `tests/` root and mirror feature folders (for example, `tests/battle/`).

## Commit & Pull Request Guidelines
- Git history is not available in this workspace snapshot, so use this baseline convention:
  - Commit format: `type(scope): imperative summary` (for example, `feat(battle): add lane deploy cancel`).
  - Keep commits focused; include scene, script, and resource updates together when tightly coupled.
- Mandatory workflow rule:
  - after every code or content modification, create a commit and push to `origin` immediately in the same task cycle.
  - when rule-covered content changes, mirror the change in the corresponding markdown under `rules/` in the same task cycle.
- PRs should include:
  - concise behavior summary and affected paths,
  - manual test steps and results,
  - screenshots/GIFs for UI or visual changes,
  - linked issue/task when applicable.

## Ralph Workflow (Default)
- Default execution order:
  - collect references,
  - plan and publish plan,
  - define graphics production path (ComfyUI first, KayKit fallback),
  - implement code,
  - review,
  - run QA.
- Iteration rule:
  - run this cycle repeatedly until completion criteria is met,
  - after each cycle, verify outputs and QA status,
  - when one reference batch is done, move to the next reference batch automatically.
- Primary command (single cycle): `tools\run_ralph_mode.bat [feature-name]`
- Primary command (loop cycles): `tools\run_ralph_loop.bat [feature-name] [max-cycles] [required-success-cycles] [completion-flag-path]`
- Repetition policy:
  - if repeat count is omitted, default to `10` cycles,
  - if repeat count is provided, run exactly that many cycles (for example, `20`),
  - when all references are completed in one round, automatically start the next round and continue until the target cycle count is reached (or completion flag is present).
- Web reference policy:
  - references must include web-verified sources and screenshot links in `docs/references/web_reference_pack.md`,
  - main page direction starts from ComfyUI references first, then production implementation.
- Review/QA loop policy:
  - review agent must validate each cycle using `tools/review_agent_validate.ps1`,
  - if planning is rejected, re-collect references and rerun planning before development continues,
  - QA must include smoke pass and fun-score gate,
  - generate ComfyUI image request briefs for grapher team via `tools/create_comfyui_image_requests.ps1`.
- Planning output format policy:
  - planning documents must be generated as Markdown (`.md`),
  - when using images, store image files under an `images/` folder and link them from markdown,
  - planning structured data must be stored as CSV (`.csv`) under `docs/plans/data/`.
  - planning document language must be Korean by default.
  - planning structure must follow `docs/plans/templates/game_plan_format_kr.md` by default.
  - planning topic should be narrow and executable (single feature scope first, avoid broad all-in-one themes).
  - planning docs should include job-post requirement mapping when used as portfolio-style documents.
  - planning docs should include gameplay-backed evidence (observations/issues/hypotheses) before solution proposals.
  - planning docs can include reverse-design sections; use `intent -> evidence -> redesign` structure.
  - planning docs must explicitly separate fixed vs variable items and include a decision log for changes.
  - planning docs must include cover and table-of-contents sections for readability.
  - planning docs should declare frame type at the top: Frame A (content-first) or Frame B (mechanics/tech-first).
  - scenario-heavy projects should include a four-act synopsis block (기/승/전/결).
  - battle and skill systems should include programmer handoff specs (flow, rules, variables, exceptions, tech requirements).
  - skill docs should include animation/VFX/SFX timing guides.
  - map-heavy plans should include map overview, connection graph, legend/icons, map parameters, region background settings, and landmark tables.
  - for sample-derived docs, verify and report `git status --short` evidence in the same turn after edits.
  - UI planning docs must include screen list/objective, user flow, per-screen component/state/event spec, exception handling, and QA acceptance criteria.
  - UI planning docs must include at least one flow diagram (Mermaid) and one component table per screen group.
  - UI planning assets must be saved under `docs/plans/images/ui/` and UI tabular specs under `docs/plans/data/ui_*.csv`.
- ComfyUI runtime policy:
  - ComfyUI root path is fixed to `D:\comfyUI`,
  - image generation calls must use URL/API invocation (`http://127.0.0.1:8188`) as default execution method,
  - do not treat local `.bat` launch as the primary run path for generation tasks.
- The command runs:
  - web image URLs are forbidden in planning docs; download/store files under docs/plans/images and link local files only.
  - `tools\reference_ops_agent.ps1` for reference collection/reporting/planning distribution/graphics strategy/review+QA document generation,
  - `tools\run_headless_smoke.bat` for smoke QA.
- Verification gate:
  - each cycle must generate all required artifacts (inventory/plan/graphics/devlog/review/qa),
  - smoke QA must pass,
  - only then the reference success streak increases.
- Reference completion rule:
  - a reference is marked complete only after consecutive successful cycles (`required-success-cycles`).
  - if validation fails, streak resets and the same reference is repeated.
- Output locations:
  - reference inventory: `docs/reference_reports/`
  - plans: `docs\plans\`
  - graphics strategy: `docs\graphics\`
  - development/review logs: `docs\reviews\`
  - QA reports: `docs\qa\`
- Loop state/log:
  - state: `docs\ralph\state.json`
  - cycle log: `docs\ralph\cycle_log.md`
  - completion flag default: `docs\ralph\COMPLETE.flag`

## Project Management Rules
- Canonical rule document:
  - `docs/PROJECT_MANAGEMENT_RULES.md`
- Active vs archive separation:
  - keep active outputs under `docs/plans`, `docs/plans/data`, `docs/plans/images`, `docs/references`, `docs/graphics`,
  - move timestamp-heavy historical outputs to `docs/archive/ralph_runs/...`.
- Archive-first cleanup:
  - never mass-delete generated reports by default,
  - move to archive folders first, then validate.
- Screenshot reference policy:
  - prioritize gameplay screenshot references for this project,
  - use chunked collection/generation and batch folders (`batch_0001`, ...),
  - enforce hash-based dedupe.


