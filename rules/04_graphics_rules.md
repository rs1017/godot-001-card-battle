# Graphics Rules

## 1. Production Path
1. 기본 그래픽 생산 경로는 ComfyUI 우선, KayKit 보완 순서다.
2. ComfyUI 호출은 API 방식(`http://127.0.0.1:8188`)을 기본으로 사용한다.
3. ComfyUI 루트 경로는 `D:\comfyUI`를 기준으로 한다.

## 2. Asset Structure Rules
1. 에셋은 `원본(source)`, `가공(work)`, `적용(runtime)` 상태를 구분해 관리한다.
2. 적용 에셋은 프로젝트 폴더 구조와 충돌하지 않게 도메인별 하위 폴더를 사용한다.
3. 파일명은 의미 단위(`category_theme_variant`)로 고정한다.

## 3. Reference Rules
1. 레퍼런스는 웹 검증 후 `docs/references/web_reference_pack.md`에 기록한다.
2. 계획 문서에는 외부 이미지 URL을 직접 넣지 않는다.
3. 참조 이미지는 로컬 다운로드 후 `docs/plans/images/` 하위에 저장한다.
4. 스크린샷은 배치 폴더와 해시 기반 중복 제거를 강제한다.

## 4. Request and Review Rules
1. 그래픽 요청서는 `tools/create_comfyui_image_requests.ps1`로 생성한다.
2. 산출물마다 프롬프트, 시드, 모델/노드 버전을 기록한다.
3. 시각 변경은 전/후 비교 캡처를 함께 남긴다.

## 5. Integration Rules
1. 카드/유닛/맵 리소스 매핑표(`docs/plans/data/*.csv`)를 업데이트한다.
2. 모델 경로는 `res://` 기준으로 일치해야 한다.
3. 누락/깨진 참조가 있으면 QA 단계로 넘기지 않는다.
