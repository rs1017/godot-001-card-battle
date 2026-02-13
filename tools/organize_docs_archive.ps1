param()

$ErrorActionPreference = "Stop"

$root = "docs/archive/ralph_runs"
$rules = @(
	@{ from = "docs/plans"; pattern = "plan_*.md"; to = "plans" },
	@{ from = "docs/plans/data"; pattern = "plan_*.csv"; to = "plans/data" },
	@{ from = "docs/qa"; pattern = "qa_*.md"; to = "qa" },
	@{ from = "docs/reviews"; pattern = "development_log_*.md"; to = "reviews" },
	@{ from = "docs/reviews"; pattern = "review_20*.md"; to = "reviews" },
	@{ from = "docs/reviews"; pattern = "review_agent_cycle_*.md"; to = "review_agent" },
	@{ from = "docs/graphics"; pattern = "graphics_strategy_20*.md"; to = "graphics" },
	@{ from = "docs/graphics"; pattern = "*_test.md"; to = "graphics_tests" },
	@{ from = "docs/reference_reports"; pattern = "reference_inventory_20*.md"; to = "reference_reports" }
)

foreach ($r in $rules) {
	$dest = Join-Path $root $r.to
	New-Item -ItemType Directory -Force -Path $dest | Out-Null
	Get-ChildItem -Path $r.from -Filter $r.pattern -File -ErrorAction SilentlyContinue | ForEach-Object {
		Move-Item -Path $_.FullName -Destination (Join-Path $dest $_.Name) -Force
	}
}

Write-Output "DOCS_ARCHIVE_ORGANIZED"
