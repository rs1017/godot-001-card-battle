# docs Folder Guide

## Overview
- This folder stores planning, reference, review, and QA outputs used by the Ralph workflow.
- Primary language for planning documents is Korean.
- Project management rules: `docs/PROJECT_MANAGEMENT_RULES.md`

## Folders
- `docs/plans/`
  - Main planning documents (`.md`)
  - Current master plan: `docs/plans/master_plan_300_pages.md`
  - Latest cycle plan: `docs/plans/latest_plan.md`
- `docs/plans/data/`
  - Structured planning datasets (`.csv`)
  - Current dataset: `docs/plans/data/master_plan_pages.csv`
- `docs/plans/images/`
  - Planning image slots and final image assets
  - Markdown plans reference images from this folder
  - Screenshot reference batches:
    - `docs/plans/images/game_screenshots_generated/batch_0001/` ...
- `docs/references/`
  - Web reference packs and screenshot source links
  - Current pack: `docs/references/web_reference_pack.md`
- `docs/graphics/`
  - Graphics strategy documents
  - ComfyUI/KayKit direction docs and request files
- `docs/reviews/`
  - Development logs, review reports, review-agent validation results
- `docs/qa/`
  - QA reports per cycle
- `docs/ralph/`
  - Ralph loop state and cycle logs
  - `state.json`: progress state
  - `cycle_log.md`: cycle history
- `docs/archive/ralph_runs/`
  - Archived timestamp outputs from repeated Ralph cycles
  - Subfolders:
    - `plans/`, `plans/data/`, `qa/`, `reviews/`, `review_agent/`, `graphics/`, `graphics_tests/`, `reference_reports/`

## Workflow Output Mapping
- Reference collection report: `docs/reference_reports/`
- Planning outputs: `docs/plans/`, `docs/plans/data/`, `docs/plans/images/`
- Graphics requests: `docs/graphics/requests/`
- Review outputs: `docs/reviews/`
- QA outputs: `docs/qa/`
- Archived historical outputs: `docs/archive/ralph_runs/`

## Notes
- Do not start development loop without the 300+ page master plan.
- If a review is rejected, refresh references and regenerate planning artifacts before continuing.
- For screenshot references, prefer gameplay-context images and keep chunked/batched folder organization.
