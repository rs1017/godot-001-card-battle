# 프로젝트 지침 - Godot KayKit Card Battle

## 프로젝트 개요
- Godot 4.5.1 (Mono) 기반 카드 배틀 게임
- Godot 엔진 경로: `..\Godot_v4.5.1-stable_mono_win64\Godot_v4.5.1-stable_mono_win64\Godot_v4.5.1-stable_mono_win64_console.exe` (프로젝트 기준 상대 경로)
- 프로젝트 경로: `D:\github\godot-game\godot-003-kaykit-card-battle`

## 그래픽 에셋 생성 - ComfyUI (필수)

### 핵심 규칙
**모든 그래픽 관련 작업(이미지 생성, 텍스처, UI 아이콘, 카드 일러스트, 배경, 스프라이트 등)은 반드시 ComfyUI를 통해 생성한다.**

### ComfyUI 설치 정보
- 설치 경로: `D:\comfyUI`
- ComfyUI 코어: `D:\comfyUI`
- 실행 방식(기본): URL/API 호출
- API 엔드포인트: `http://127.0.0.1:8188`

### 디렉토리 구조
- 모델: `D:\comfyUI\models\`
- 입력 이미지: `D:\comfyUI\input\`
- 출력 이미지: `D:\comfyUI\output\`
- 커스텀 노드: `D:\comfyUI\custom_nodes\`

### 설치된 커스텀 노드
- comfyui-manager (노드/모델 관리)
- comfyui_controlnet_aux (ControlNet 전처리)
- ComfyUI-Easy-Use (편의 노드)
- ComfyUI-GGUF (GGUF 모델 지원)
- comfyui-inpaint-cropandstitch (인페인팅)
- comfyui-itools (유틸리티)
- comfyui-kjnodes (확장 노드)
- ComfyUI-QwenVL (비전 언어 모델)
- comfyui-rmbg (배경 제거)
- ComfyUI-TiledDiffusion (타일 디퓨전)
- comfyui-videohelpersuite (비디오)
- ComfyUI-WanVideoWrapper (Wan 비디오)
- controlaltai-nodes (추가 노드)
- rgthree-comfy (편의 기능)

### ComfyUI API 사용 방법
1. ComfyUI 서버가 실행 중인지 확인 (`http://127.0.0.1:8188`)
2. 워크플로우 JSON을 API 형식으로 작성
3. `/prompt` 엔드포인트로 POST 요청
4. `/history` 또는 WebSocket으로 결과 확인
5. 생성된 이미지를 프로젝트 `assets/` 디렉토리로 복사

### 실행 규칙(고정)
- ComfyUI 작업 실행은 URL 호출을 기본으로 한다.
- 그래픽 생성 자동화는 `http://127.0.0.1:8188` API 기준으로 구현한다.

### 그래픽 작업 시 워크플로우
1. 필요한 모델이 없으면 사용자에게 다운로드 안내
2. ComfyUI API를 통해 이미지 생성
3. 생성된 이미지를 프로젝트 `assets/` 폴더에 적절히 배치
4. 필요시 Godot import 실행

### 모델 상태
- **참고**: 현재 모델 파일이 설치되어 있지 않음. 이미지 생성 작업 시 필요한 모델 다운로드를 먼저 안내할 것.

## 프로젝트 구조
```
assets/       - 게임 에셋 (이미지, 모델, 사운드 등)
resources/    - Godot 리소스 파일
scenes/       - Godot 씬 파일 (.tscn)
scripts/      - GDScript 파일
themes/       - UI 테마
```

## 개발 규칙
- GDScript 사용 (C# 아님)
- Godot 4.x 문법 준수
- 에셋 경로는 `res://` 프리픽스 사용
