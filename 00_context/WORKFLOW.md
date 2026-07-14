# WORKFLOW — 표준 작업 흐름

사람과 AI가 함께 작업할 때의 표준 흐름입니다. 각 단계에서 사용하는 폴더를 함께 표기합니다.

---

## 표준 10단계

| 단계 | 작업 | 사용 폴더 | 산출물/결과 |
|------|------|-----------|-------------|
| 1 | **프로젝트 개요 작성** | `00_context/` | `PROJECT_OVERVIEW.md` 작성 완료 |
| 2 | **입력자료 등록** | `01_inputs/` | 표준/요구사항/참고/샘플/원본 배치 |
| 3 | **문서 인덱스 갱신** | `00_context/` | `DOCUMENT_INDEX.md`에 색인 추가 |
| 4 | **AI 요청서 작성** | `02_requests/pending/` | 요청 파일 1건 |
| 5 | **AI 분석/초안 생성** | `03_working/` | 분석(`analysis/`), 초안(`drafts/`) |
| 6 | **결과 검토 요청** | `05_feedback/review_requests/` | 검토 요청서, 상태 `review_requested` |
| 7 | **피드백 반영** | `05_feedback/corrections/` | 수정 지시 반영 |
| 8 | **결정사항 기록** | `06_decisions/` | `DECISION_LOG.md`, `OPEN_QUESTIONS.md` 갱신 |
| 9 | **최종 산출물 정리** | `04_outputs/` | 공유 가능한 산출물, 상태 `approved` |
| 10 | **오래된 작업물 아카이브** | `08_archive/` | 종료된 작업물 이동 |

---

## 단계별 상세

### 1. 프로젝트 개요 작성 — `00_context/`
`PROJECT_OVERVIEW.md`의 `{작성 필요}`를 채워 프로젝트의 목적·범위·기술스택·산출물을 정의한다.

### 2. 입력자료 등록 — `01_inputs/`
자료 유형에 맞는 하위 폴더(`standards/`, `requirements/`, `references/`, `samples/`, `raw/`)에 배치한다.

### 3. 문서 인덱스 갱신 — `00_context/DOCUMENT_INDEX.md`
등록한 입력자료와 산출물을 색인에 추가한다(문서ID·위치·상태 등).

### 4. AI 요청서 작성 — `02_requests/pending/`
요청 목적, 참고 입력자료, 기대 산출물, 우선순위를 담은 요청 파일을 만든다.
작업 착수 시 `in_progress/`로 이동한다.
`completed/`로의 이동 시점: **요청서의 완료 조건(Definition of Done)이 충족되고,
필요한 검토·승인이 끝난 뒤**에 옮긴다. (검토 전/승인 전에는 `completed/`로 옮기지 않는다.)

### 5. AI 분석/초안 생성 — `03_working/`
분석 결과는 `analysis/`, 문서 초안은 `drafts/`, 작업 데이터는 `data/`, 도식은 `diagrams/`에 둔다.
이 단계 산출물은 아직 **공유 대상이 아니다.**

### 6. 결과 검토 요청 — `05_feedback/review_requests/`
검토가 필요한 산출물의 상태를 `review_requested`로 바꾸고 검토 요청서를 작성한다.

### 7. 피드백 반영 — `05_feedback/corrections/`
받은 수정 지시를 반영한다. 승인되면 기록을 `05_feedback/approved/`로 옮긴다.

### 8. 결정사항 기록 — `06_decisions/`
확정된 결정은 `DECISION_LOG.md`, 미해결 질문은 `OPEN_QUESTIONS.md`, 변경은 `CHANGE_LOG.md`에 남긴다.

### 9. 최종 산출물 정리 — `04_outputs/`
검토·승인된 결과물을 유형별 폴더(`documents/`, `spreadsheets/`, `diagrams/`, `scripts/`, `reports/`)에 정리하고 상태를 `approved`로 표기한다.

### 10. 아카이브 — `08_archive/`
종료·구버전 작업물을 옮겨 작업 폴더를 정리한다. 비공개 자료는 `08_archive/private/`에 둔다.

---

## 흐름 요약 (한 줄)

`00_context` → `01_inputs` → `DOCUMENT_INDEX` → `02_requests` → `03_working` → `05_feedback` → `06_decisions` → `04_outputs` → `08_archive`
