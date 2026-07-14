# AI_INSTRUCTIONS — AI 작업 지침

이 문서는 AI가 이 프로젝트에서 **항상 따라야 하는 지침**입니다.
공통 규칙은 루트의 `AGENTS.md`, 세부 표준은 `OUTPUT_STANDARDS.md`를 함께 참조하세요.

> 이 문서는 기본 템플릿입니다. 프로젝트 초기화 시 프로젝트 성격에 맞게 보완하세요.

---

## 1. 작업 시작 전 읽을 문서 순서

1. `00_context/PROJECT_OVERVIEW.md` — 목적·범위
2. `00_context/AI_INSTRUCTIONS.md` — 본 문서
3. `00_context/SECURITY_RULES.md` — 보안 규칙
4. `00_context/WORKFLOW.md` — 작업 흐름
5. `00_context/OUTPUT_STANDARDS.md` — 산출물 표준
6. `00_context/GLOSSARY.md`, `00_context/DOCUMENT_INDEX.md` — 용어·문서 색인

---

## 2. 입력자료 우선순위

판단 근거는 다음 우선순위로 사용한다.

1. `01_inputs/standards/` — 표준·규정 (가장 우선)
2. `01_inputs/requirements/` — 요구사항·명세
3. `06_decisions/DECISION_LOG.md` — 이미 내려진 결정
4. `01_inputs/references/` — 참고자료
5. `01_inputs/samples/` — 예시·템플릿

입력자료에 근거가 없으면 일반 지식으로 임의 확정하지 말고 `확인필요`로 표시한다.

> 엑셀(.xlsx) 입력은 런처 `09_scripts/run.ps1`(또는 `09_scripts/tools/convert_excel_to_ai.py`)로
> JSON/JSONL/Markdown으로 변환해 `03_working/data/`에 두고 근거로 사용한다.
> 원본 엑셀(`01_inputs/`)은 수정하지 않는다.

---

## 3. 산출물 작성 방식

- Markdown(UTF-8)으로 작성한다.
- 중간 작업물은 `03_working/`, 공유 산출물은 `04_outputs/`에 둔다.
- 파일명·날짜·상태값은 `OUTPUT_STANDARDS.md`를 따른다.
- 모든 산출물 하단에 아래 §7 "산출물 메타 정보" 섹션을 남긴다.

---

## 4. 추정 / 확정 구분 규칙

| 표기 | 사용 조건 |
|------|-----------|
| `확정` | 입력자료·결정 로그로 확인된 사실 |
| `추정` | 근거에서 합리적으로 유추, 미확인 (가정·근거 명시) |
| `확인필요` | 사람 판단·추가 정보가 필요 |
| `미확인` | 근거 없음 / 정보 부족 |

근거 없는 내용을 `확정`으로 표기하지 않는다.

---

## 5. 질문이 필요한 경우의 기준

다음 중 하나면 임의로 결정하지 말고 질문(또는 `OPEN_QUESTIONS.md` 기록)한다.

- 요구사항이 서로 충돌하거나 모호할 때
- 범위(In/Out of Scope)에 영향을 주는 판단이 필요할 때
- 보안·개인정보 관련 처리가 필요할 때
- 입력자료에 근거가 없는 핵심 가정을 세워야 할 때
- 되돌리기 어려운 작업(대량 수정/삭제)을 하기 직전

---

## 6. 파일 생성/수정 시 주의사항

**파일 생성 전 확인:**
- 같은 목적의 파일이 이미 있는지 (`DOCUMENT_INDEX.md` 확인)
- 올바른 폴더인지 (중간물=`03_working/`, 산출물=`04_outputs/`)
- 파일명 규칙 준수 여부

**파일 수정 시 주의:**
- 원본 입력자료(`01_inputs/`, 특히 `raw/`)는 수정하지 않는다. 복사 후 작업.
- 중요한 변경은 `06_decisions/CHANGE_LOG.md`에 기록한다.
- 산출물의 상태값(`draft`/`review_requested`/`approved` 등)을 올바르게 갱신한다.

---

## 7. 산출물 메타 정보 (각 산출물에 필수 포함)

산출물 하단에 아래 항목을 남긴다.

```markdown
---
## 작업 메타
- 작업 목적:
- 사용한 입력자료:
- 판단 근거:
- 확정 사항:
- 추정 사항:
- 확인 필요 사항:
- 다음 작업:
---
```

이 메타 정보가 없는 산출물은 미완성으로 간주한다.
