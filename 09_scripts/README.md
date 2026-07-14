# 09_scripts — 워크스페이스 도구

워크스페이스를 유지·자동화하는 스크립트를 모아 둡니다.

**구성**
- `run.ps1` — **런처**(메뉴에서 골라 실행). 상위에 둡니다. 진입점은 이 파일 하나입니다.
- `tools/` — 런처가 실행하는 **실제 작업 스크립트**들을 모아 둡니다.
- `requirements.txt` — Python 의존성.

| 위치 | 스크립트 | 언어 | 역할 |
|------|----------|------|------|
| `09_scripts/` | `run.ps1` | PowerShell | **런처.** `tools/`의 도구들을 메뉴에서 골라 실행 (가장 쉬운 진입점) |
| `09_scripts/tools/` | `update_workspace_structure.ps1` | PowerShell | 폴더/파일 구조를 스캔해 `00_context/WORKSPACE_STRUCTURE.md`로 저장 |
| `09_scripts/tools/` | `convert_excel_to_ai.py` | Python | 엑셀(.xlsx)을 AI가 읽기 쉬운 JSON/JSONL/Markdown으로 변환 |
| `09_scripts/tools/` | `clean_orphans.py` | Python | 입력 삭제 후 남은 고아 파생물(`03_working/data`) 정리 |

> 직접 실행도 가능하지만(`python 09_scripts/tools/convert_excel_to_ai.py ...`),
> 보통은 `run.ps1`로 실행합니다.

---

## 0. run.ps1 — 런처 (권장 진입점)

긴 명령을 외울 필요 없이, 런처를 실행하면 **작업 목록이 번호로** 뜨고 골라서 실행합니다.

```powershell
.\09_scripts\run.ps1
```

- 번호를 고르면:
  - **구조 문서화** → 추가 질문 없이 바로 생성
  - **엑셀 변환** → 옵션을 하나씩 질문. **Enter를 누르면 기본값**으로 진행
    (기본값 = `03_working/data`에 **모든 시트** 변환, Markdown 생성)
- 엑셀 파일은 워크스페이스 안의 `.xlsx`를 자동으로 찾아 **번호로 선택**합니다.
- **시트가 여러 개일 때만** "모든 시트 변환?"을 묻습니다. 시트가 1개면 묻지 않고 바로 변환합니다.
- 결과 파일명은 **시트가 여러 개일 때만** `_시트명`이 붙습니다(시트 1개면 접미사 없음).

### 메뉴 없이 바로 변환 (선택)

```powershell
# 기본값(모든 시트, MD 생성, 03_working/data)으로 즉시 변환
.\09_scripts\run.ps1 -Path 01_inputs\samples\data.xlsx

# 첫 시트만 / Markdown 생략 / 출력 폴더 지정
.\09_scripts\run.ps1 -Path data.xlsx -SingleSheet -NoMd -OutputDir 03_working\data
```

### 새 스크립트를 런처에 추가하는 법

1. 새 스크립트 파일을 **`09_scripts/tools/`** 에 둡니다.
2. `run.ps1` 상단의 `$Tasks` 배열에 **한 줄만 추가**하면 메뉴에 자동으로 나타납니다.

```powershell
@{ Name = '메뉴에 보일 이름'; Script = '스크립트파일명'; Type = 'structure' }
```

- `Script`에는 `tools/` 안의 파일명만 적습니다(런처가 `tools/` 경로를 붙여 실행).
- `Type`이 `structure`(질문 없이 실행)나 `convert`(엑셀 변환)면 기존 로직을 그대로 씁니다.
- 완전히 새로운 방식이 필요하면 `Invoke-Task`의 `switch`에 handler를 추가하세요.

> PowerShell 스크립트(`*.ps1`)는 Windows PowerShell 5.1이 한글을 깨뜨리지 않도록
> **UTF-8 BOM**으로 저장되어 있습니다. 편집 후 저장 시 인코딩을 유지하세요.

---

## 1. update_workspace_structure.ps1

현재 워크스페이스 구조를 트리 형태로 문서화합니다. `.git`, `node_modules`,
`.venv`, `__pycache__`, `dist`, `build`, `target`은 제외합니다.
(보통 `run.ps1` 메뉴로 실행합니다.)

```powershell
.\09_scripts\tools\update_workspace_structure.ps1
.\09_scripts\tools\update_workspace_structure.ps1 -MaxDepth 5
```

- Windows PowerShell 5.1 이상에서 실행 가능합니다.
- 결과는 `00_context/WORKSPACE_STRUCTURE.md`에 저장됩니다(자동 생성 파일, 직접 편집 금지).

---

## 2. convert_excel_to_ai.py

엑셀 각 시트의 **첫 행을 속성명(header)**으로 사용해 행 단위 데이터를
JSON / JSONL / Markdown으로 변환합니다. 셀의 개행·공백을 정규화하고 빈 행은 제외합니다.
(보통 `run.ps1` 메뉴로 실행합니다.)

**파일명 접미사:** 시트가 **여러 개일 때만** 결과 파일명에 `_시트명`이 붙습니다.
시트가 1개면 접미사 없이 원본 파일명 그대로 만듭니다.

### 사전 준비

```bash
pip install -r 09_scripts/requirements.txt
```

### 사용법

```bash
# 기본: 첫 시트만 변환, 입력 파일과 같은 폴더에 출력
python 09_scripts/tools/convert_excel_to_ai.py 01_inputs/samples/data.xlsx

# 권장: 변환 결과를 중간 작업 폴더에 저장
python 09_scripts/tools/convert_excel_to_ai.py 01_inputs/samples/data.xlsx -o 03_working/data

# 특정 시트만
python 09_scripts/tools/convert_excel_to_ai.py data.xlsx --sheet Sheet1

# 모든 시트를 각각 변환 (시트가 2개 이상이면 파일명에 시트명 접미사)
python 09_scripts/tools/convert_excel_to_ai.py data.xlsx --all-sheets

# Markdown은 생성하지 않음 (JSON/JSONL만)
python 09_scripts/tools/convert_excel_to_ai.py data.xlsx --no-md

# 변환하지 않고 시트 이름만 확인
python 09_scripts/tools/convert_excel_to_ai.py data.xlsx --list-sheets
```

### 출력

- `<파일명>.jsonl` — 한 행당 한 객체(대용량·스트리밍 처리에 적합)
- `<파일명>.json` — 전체 행 배열(사람이 훑어보기 좋음)
- `<파일명>.md` — 행별 섹션 문서(AI/사람이 읽기 좋음, `--no-md`로 생략 가능)

### 권장 워크플로우

1. 원본 엑셀은 `01_inputs/`(예: `samples/`, `raw/`)에 그대로 둔다. **원본은 수정하지 않는다.**
2. 이 스크립트로 `03_working/data/`에 AI 친화적 데이터로 변환한다.
3. 변환 결과를 근거로 분석·초안 작업을 진행한다.

### 보안 주의

- 실데이터·개인정보·접속정보가 담긴 엑셀은 `00_context/SECURITY_RULES.md`를 따른다.
- 민감 자료의 변환 결과(`03_working/data/`)는 Git에 커밋하지 않는다.
  필요 시 해당 경로를 루트 `.gitignore`에 추가한다.
- 현재는 `.xlsx`만 지원한다(`.xls`/`.csv` 미지원).

---

## 3. clean_orphans.py — 입력 삭제 후 정리

`01_inputs/`의 엑셀을 지운 뒤, `03_working/data/`에 남은 **고아 파생물**(원본이 사라진 변환 결과)을
찾아 정리합니다. 보통 `run.ps1` 메뉴의 **"입력 삭제 후 정리"** 로 실행합니다.

```bash
python 09_scripts/tools/clean_orphans.py          # 미리보기(삭제 안 함)
python 09_scripts/tools/clean_orphans.py --apply  # 실제 삭제
```

두 가지를 함께 감지합니다:
- **고아 파생물**: `03_working/data/`의 `.json/.jsonl/.md` 중 원본 xlsx가 없는 파일
  (단일 시트 `<stem>.*`, 다중 시트 `<stem>_<시트>.*` 모두 인식)
- **stale 색인**: `DOCUMENT_INDEX.md`가 가리키는 경로가 실제로 없는 항목
  (→ 파생 파일이 이미 없어도 색인에 남은 참조를 잡아냄)

동작:
1. 위 두 가지를 스캔해 목록/리포트 출력
2. **미리보기 기본** — 고아 파생물은 `--apply`가 있어야 삭제
3. 자료명을 '언급'하는 문서 위치를 **리포트**(자동 수정하지 않음)
4. 런처로 실행하면 삭제 후 `WORKSPACE_STRUCTURE.md`를 자동 재생성
5. **문서 갱신이 필요하면**(stale 색인 또는 문서 참조), 정리 프롬프트의 빈칸
   (`{경로/파일명}`·`{붙여넣기}`)이 **이미 채워진 완성본**을 `03_working/cleanup_request.md`로 생성
   → 그대로 AI에게 전달 (`--no-prompt` 생성 생략, `--prompt-out <경로>` 위치 변경)

**종료 코드(비트마스크):** `0`=정리할 것 없음 / `1`=문서 갱신만 필요(고아 없음) /
`2`=고아만 있음 / `3`=고아+문서 갱신. (런처가 이 코드로 삭제 질문·문서 안내를 분기)

안전 규칙:
- `03_working/data/` 밖은 삭제하지 않는다. `04_outputs/`(승인 산출물)는 건드리지 않는다.
- **문서는 자동 편집하지 않는다.** 색인·결정·분석 갱신은 판단이 필요하므로
  `07_prompts/reusable/clean_after_input_removal_prompt.md`로 사람이 확인하며 처리한다.
  (파일명이 '단순 예시'로 등장한 경우 등은 지우면 안 되기 때문)
