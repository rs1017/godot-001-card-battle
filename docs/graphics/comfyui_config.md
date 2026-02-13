# ComfyUI 실행 설정

- ComfyUI 루트 경로: `D:\comfyUI`
- API URL: `http://127.0.0.1:8188`
- 실행 기본 방식: URL/API 호출

## 고정 규칙
- 그래픽 생성 요청은 ComfyUI API(`POST /prompt`)를 기본 경로로 사용한다.
- 결과 조회는 `/history` 또는 WebSocket을 사용한다.
- 기획서/문서에는 웹 이미지 URL을 직접 링크하지 않고, 로컬 파일(`docs/plans/images/`)만 사용한다.
