# godot-001-card-battle

Godot 4.5 기반 카드 배틀 프로젝트입니다.  
기본 개발 방식은 Ralph 반복 워크플로우(레퍼런스 -> 기획 -> 그래픽 -> 개발 -> 리뷰 -> QA)입니다.

## 1. 실행

### 에디터 실행
```bat
tools\start_editor_safe.bat
```

### 콘솔 실행
```bat
Engine\Godot_v4.5.1-stable_mono_win64\Godot_v4.5.1-stable_mono_win64_console.exe --path .
```

### 헤드리스 스모크 테스트
```bat
tools\run_headless_smoke.bat
```

## 2. 주요 폴더

- `scenes/`: Godot 씬 파일
- `scripts/`: 게임 로직(GDScript)
- `resources/cards/`: 카드 데이터 리소스
- `assets/`: 아트/모델 에셋
- `docs/`: 기획/리뷰/QA/레퍼런스 문서
- `tools/`: 자동화 스크립트

## 3. 문서 운영 규칙

프로젝트 문서 관리 기준:
- `docs/PROJECT_MANAGEMENT_RULES.md`
- `docs/readmd.md`

핵심 원칙:
- 최신 산출물과 이력 산출물을 분리
- 대량 이력 파일은 `docs/archive/ralph_runs/`로 이동
- 기획서 이미지는 로컬 파일 링크만 사용(외부 이미지 URL 직접 링크 금지)

## 4. Ralph 워크플로우

### 단일 사이클
```bat
tools\run_ralph_mode.bat [feature-name]
```

### 반복 사이클
```bat
tools\run_ralph_loop.bat [feature-name] [max-cycles] [required-success-cycles] [completion-flag-path]
```

기본 정책:
- 반복 횟수 미지정 시 기본 10회
- 리뷰/QA 게이트 통과 기준으로 다음 사이클 진행

## 5. 그래픽/레퍼런스

- ComfyUI 설정: `docs/graphics/comfyui_config.md`
- ComfyUI API 기본 URL: `http://127.0.0.1:8188`
- 레퍼런스/이미지 데이터:
  - `docs/plans/images/`
  - `docs/plans/data/`
  - `docs/references/`

## 6. 참고

- 저장소 지침: `AGENTS.md`
- 현재 메인 씬: `scenes/main.tscn`
