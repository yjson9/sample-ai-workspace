# DIRECTORY_GUIDE — 폴더별 안내 (무엇을 어디에 두는가)

이 문서는 **각 폴더에 어떤 파일을 넣는지**를 한눈에 정리한 지도입니다.
전체 트리는 `WORKSPACE_STRUCTURE.md`(자동 생성), 작업 순서는 `WORKFLOW.md`를 참고하세요.

- `추가 주체`: 파일을 주로 만드는 사람 — 🧑 사람 / 🤖 AI / ⚙️ 스크립트
- 경로는 슬래시(`/`)로 표기하며 Windows에서는 역슬래시로 읽어도 됩니다.

---

## 한눈에 보기

| 폴더 | 무엇을 넣나 | 추가 주체 | 공유 |
|------|-------------|-----------|------|
| `00_context/` | 프로젝트 기준 문서(개요·지침·보안·표준·색인) | 🧑🤖 | 내부 |
| `01_inputs/` | 사람이 제공하는 입력 자료(원본) | 🧑 | 원본 |
| `02_requests/` | 요청 단위 작업 파일 | 🧑🤖 | 내부 |
| `03_working/` | AI 중간 분석·초안·작업 데이터 | 🤖 | 내부(공유 X) |
| `04_outputs/` | 검토를 거친 공유용 산출물 | 🤖🧑 | 공유 O |
| `05_feedback/` | 검토 요청·수정 지시·승인 기록 | 🧑🤖 | 내부 |
| `06_decisions/` | 결정·미해결 질문·변경 이력 | 🧑🤖 | 내부 |
| `07_prompts/` | 재사용 프롬프트·사용 이력 | 🧑🤖 | 내부 |
| `08_archive/` | 종료·구버전 보관 | 🧑🤖 | 보관 |
| `09_scripts/` | 유지·자동화 스크립트 | 🧑 | 도구 |

---

## 00_context/ — 프로젝트 기준 문서
AI가 작업 전 반드시 읽는 문서. 주로 프로젝트당 1개씩 유지(새 파일을 마구 늘리지 않음).

| 파일 | 내용 |
|------|------|
| `PROJECT_OVERVIEW.md` | 프로젝트 목적·범위·기술스택·산출물 (템플릿, `{작성 필요}` 채우기) |
| `AI_INSTRUCTIONS.md` | AI 작업 지침(읽는 순서, 추정/확정 규칙, 메타 정보) |
| `SECURITY_RULES.md` | 보안 규칙(개인정보·접속정보 미저장 등) |
| `WORKFLOW.md` | 표준 작업 흐름(단계별 폴더) |
| `OUTPUT_STANDARDS.md` | 산출물 표준(파일명·날짜·상태값·신뢰도) |
| `GLOSSARY.md` | 용어집 |
| `DOCUMENT_INDEX.md` | 입력·산출물 색인 |
| `DIRECTORY_GUIDE.md` | (이 문서) 폴더별 안내 |
| `WORKSPACE_STRUCTURE.md` | 자동 생성 트리(직접 편집 금지) |

**여기에 넣지 말 것:** 입력 원본, 작업 초안, 산출물.

---

## 01_inputs/ — 입력 자료 (원본)
사람이 제공하는 자료. **원본은 수정하지 않는다.** 등록하면 `DOCUMENT_INDEX.md`에 색인 추가.

| 하위 폴더 | 무엇을 넣나 | 예시 |
|-----------|-------------|------|
| `standards/` | 표준·규정·가이드라인 | 코딩 규칙, 문서 표준 |
| `requirements/` | 요구사항·기획·명세 | 기능명세, 요구사항 목록 |
| `references/` | 참고자료·외부 문서 | 참고 논문, 벤더 문서 |
| `samples/` | 예시·템플릿·샘플 | 샘플 엑셀, 예시 양식 |
| `raw/` | 가공 전 원본 파일 | 내려받은 원본 데이터 |

**팁:** 엑셀(.xlsx)은 `09_scripts/run.ps1` → 엑셀 변환으로 `03_working/data/`에 AI 친화적 형태로 변환해 사용.
민감 자료가 있으면 `raw/`를 `.gitignore`에 추가(→ `SECURITY_RULES.md`).

---

## 02_requests/ — 요청 단위 작업
요청 1건 = 파일 1개(Markdown). 진행에 따라 폴더를 이동시킨다.

| 하위 폴더 | 의미 | 파일명 예시 |
|-----------|------|-------------|
| `pending/` | 대기 중(작성됨, 미착수) | `REQ-001_api-문서화.md` |
| `in_progress/` | 진행 중 | (pending에서 이동) |
| `completed/` | 완료 | (in_progress에서 이동) |

**요청서 템플릿:** `02_requests/_TEMPLATE_request.md` 를 복사해 `pending/REQ-001_주제.md`로 사용.
요청ID(`REQ-###`)는 `DOCUMENT_INDEX.md`의 "관련 요청ID"와 연결.

---

## 03_working/ — 중간 작업물 (공유 전)
AI의 작업 과정. 추정·메모·미완성 허용. **외부 공유 대상 아님.**

| 하위 폴더 | 무엇을 넣나 |
|-----------|-------------|
| `analysis/` | 입력 문서 분석 결과 |
| `drafts/` | 문서 초안 (상태 `draft`) |
| `data/` | 작업 데이터(예: 엑셀 변환 결과 JSON/JSONL/MD) |
| `diagrams/` | 작업 중 도식 |

같은 문서라도 여기의 초안과 `04_outputs/`의 산출물은 **다른 파일**로 관리.

---

## 04_outputs/ — 최종 산출물 (공유용)
검토를 거친 공유 가능 결과물. 상태 `approved`. 내부 추정 과정은 정리하고 확인 필요 사항은 명시.

| 하위 폴더 | 무엇을 넣나 |
|-----------|-------------|
| `documents/` | 문서(설명서, 명세, 보고서 형식 문서) |
| `spreadsheets/` | 표/스프레드시트 산출물 |
| `diagrams/` | 다이어그램·도식 |
| `scripts/` | 전달용 스크립트/코드 산출물 |
| `reports/` | 리포트·요약본 |

`03_working/`(초안)에서 검토를 통과한 것만 여기로 승격.

---

## 05_feedback/ — 검토·수정·승인
각 하위 폴더에 `_TEMPLATE_*.md`가 있습니다. 복사해서 사용하세요.

| 하위 폴더 | 무엇을 넣나 | 템플릿 |
|-----------|-------------|--------|
| `review_requests/` | 검토 요청서(상태 `review_requested`) | `_TEMPLATE_review_request.md` |
| `corrections/` | 받은 수정 지시·반영 기록 | `_TEMPLATE_correction.md` |
| `approved/` | 승인 기록(상태 `approved`) | `_TEMPLATE_approval.md` |

> **승인 흐름:** 산출물은 `03_working/drafts/`에서 `review_requested`로 검토 요청 →
> 사람이 승인하면 `04_outputs/{유형}/`로 **이동(승격)**하고 상태 `approved`. (승인 전 `04_outputs/` 금지)

---

## 06_decisions/ — 결정·질문·변경
| 파일 | 무엇을 기록 |
|------|-------------|
| `DECISION_LOG.md` | 확정된 결정(`DEC-###`) |
| `OPEN_QUESTIONS.md` | 미해결 질문(`Q-###`) — AI가 임의 판단 대신 여기에 기록 |
| `CHANGE_LOG.md` | 문서·구조·주요 산출물 변경 이력 |

---

## 07_prompts/ — 프롬프트
| 하위 폴더 | 무엇을 넣나 |
|-----------|-------------|
| `reusable/` | 재사용 프롬프트(`setup_workspace`, `analyze_document`, `review_output`, `create_deliverable`, `clean_after_input_removal`) |
| `history/` | 실제 사용한 프롬프트·결과 기록 |

---

## 08_archive/ — 보관
종료·구버전 작업물 이동. 비공개 민감 자료는 `08_archive/private/`(=`.gitignore` 대상).

---

## 09_scripts/ — 도구
| 위치 | 파일 | 역할 |
|------|------|------|
| `09_scripts/` | `run.ps1` | 런처(메뉴에서 골라 실행) — **권장 진입점** |
| `09_scripts/` | `requirements.txt` | Python 의존성(openpyxl) |
| `09_scripts/` | `README.md` | 스크립트 사용법·확장법 |
| `09_scripts/tools/` | `update_workspace_structure.ps1` | 구조 트리를 `WORKSPACE_STRUCTURE.md`로 생성 |
| `09_scripts/tools/` | `convert_excel_to_ai.py` | 엑셀 → JSON/JSONL/Markdown 변환 (시트 2개↑일 때만 `_시트명` 접미사) |
| `09_scripts/tools/` | `clean_orphans.py` | 입력 삭제 후 남은 고아 파생물(`03_working/data`) 정리 (dry-run 기본) |

- 런처가 실행하는 실제 스크립트는 모두 `09_scripts/tools/`에 둡니다.
- 새 도구 추가: `tools/`에 파일을 넣고 `run.ps1`의 `$Tasks`에 한 줄 추가.

---

## 파일이 폴더를 옮겨가는 흐름 (요약)

```
01_inputs (원본)
   └─(요청)→ 02_requests/pending → in_progress → completed
                     │
                     ▼
   03_working (분석·초안)  ──검토요청──▶ 05_feedback/review_requests
        │                                     │
        │                              (수정)  ▼  (승인)
        └───────────승격(승인 후)───────────▶ 04_outputs (공유용)
                                              │
                     결정/질문/변경 → 06_decisions
                                              │
                          오래되면 → 08_archive
```

---

## 루트 파일

| 파일 | 역할 |
|------|------|
| `README.md` | 워크스페이스 전체 안내(사용법·보안·흐름) |
| `AGENTS.md` | AI 에이전트 공통 작업 규칙 |
| `.gitignore` | 로그·비밀값·캐시 등 Git 제외 규칙 |
