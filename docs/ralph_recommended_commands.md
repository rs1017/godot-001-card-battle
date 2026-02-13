# Ralph Recommended Commands

## 1) Standard loop (recommended default)
```
tools\run_ralph_recommended.bat lane-deploy-fix standard
```

## 2) Quick single cycle
```
tools\run_ralph_recommended.bat lane-deploy-fix quick
```

## 3) Deep loop (long run)
```
tools\run_ralph_recommended.bat lane-deploy-fix deep
```

## 4) Reference-only pass
```
tools\run_ralph_recommended.bat lane-deploy-fix refs
```

## 5) Smoke QA only
```
tools\run_ralph_recommended.bat lane-deploy-fix smoke
```

## Profile summary
- `quick`: one cycle via `tools\run_ralph_mode.bat`
- `standard`: `10` cycles, `required-success=2`
- `deep`: `20` cycles, `required-success=3`
- `refs`: reference ops only
- `smoke`: headless smoke only
