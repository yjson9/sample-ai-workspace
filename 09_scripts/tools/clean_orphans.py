"""
입력자료 삭제 후 남은 '고아(orphan) 파생물'을 정리합니다.

무엇을 하나:
  - 03_working/data/ 의 변환 결과(.json/.jsonl/.md) 중,
    원본 엑셀(01_inputs/**/*.xlsx)이 더 이상 없는 파일 = '고아'를 찾습니다.
  - 기본은 '미리보기(dry-run)'로 목록만 보여주고, --apply 를 줘야 실제로 삭제합니다.
  - 삭제와 별개로, 그 자료명을 '언급'하는 문서(색인/결정/분석 등)를 리포트합니다.
    (이 문서들은 자동 수정하지 않습니다 — 단순 예시 언급일 수 있으므로 사람이 판단)

무엇을 하지 않나 (안전 규칙):
  - 03_working/data/ 밖의 파일은 삭제하지 않습니다.
  - 04_outputs/(승인 산출물)는 건드리지 않습니다.
  - 어떤 문서도 자동 편집하지 않습니다(리포트만). 문서 갱신은
    07_prompts/reusable/clean_after_input_removal_prompt.md 로 사람이 확인하며 처리합니다.

보통 런처(09_scripts/run.ps1)의 '입력 삭제 후 정리' 메뉴로 실행합니다.

사용 예:
    python 09_scripts/tools/clean_orphans.py            # 미리보기(삭제 안 함)
    python 09_scripts/tools/clean_orphans.py --apply    # 실제 삭제
"""

from pathlib import Path
import sys
import argparse
import re

# 콘솔에서 한글 출력이 깨지지 않도록 stdout을 UTF-8로 설정
try:
    sys.stdout.reconfigure(encoding="utf-8")
except (AttributeError, ValueError):
    pass

# 이 스크립트는 09_scripts/tools/ 안 → 두 단계 위가 워크스페이스 루트
ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "03_working" / "data"
INPUTS_DIR = ROOT / "01_inputs"
DOCUMENT_INDEX = ROOT / "00_context" / "DOCUMENT_INDEX.md"
CODE_SPAN = re.compile(r"`([^`]+)`")

DERIVED_EXTS = {".json", ".jsonl", ".md"}

# 참조 리포트에서 제외할 최상위 폴더/파일
REPORT_EXCLUDE_TOP = {".git", "ai-workspace", "node_modules", ".venv", "__pycache__", "04_outputs"}
REPORT_EXCLUDE_NAMES = {"WORKSPACE_STRUCTURE.md", "cleanup_request.md"}  # 자동 생성물이므로 제외

# 정리 프롬프트 템플릿 / 자동 채운 요청서 기본 출력 위치
PROMPT_TEMPLATE = ROOT / "07_prompts" / "reusable" / "clean_after_input_removal_prompt.md"
DEFAULT_PROMPT_OUT = ROOT / "03_working" / "cleanup_request.md"


def current_input_stems():
    """01_inputs 아래 현재 존재하는 엑셀 파일들의 stem 집합."""
    stems = set()
    if INPUTS_DIR.exists():
        for p in INPUTS_DIR.rglob("*.xlsx"):
            if p.name.startswith("~$"):
                continue
            stems.add(p.stem)
    return stems


def has_living_source(output_stem, input_stems):
    """
    변환 결과 파일의 stem이 살아있는 원본으로 설명되는가?
    - 단일 시트:  <원본stem>            (정확히 일치)
    - 다중 시트:  <원본stem>_<시트명>   (원본stem + '_' 로 시작)
    """
    for s in input_stems:
        if output_stem == s or output_stem.startswith(s + "_"):
            return True
    return False


def find_orphans(input_stems):
    """03_working/data 에서 원본이 사라진 변환 결과 파일 목록."""
    orphans = []
    if not DATA_DIR.exists():
        return orphans
    for p in sorted(DATA_DIR.iterdir()):
        if not p.is_file():
            continue
        if p.suffix.lower() not in DERIVED_EXTS:
            continue
        if not has_living_source(p.stem, input_stems):
            orphans.append(p)
    return orphans


def find_stale_index_entries():
    """
    DOCUMENT_INDEX.md 가 가리키는 파일 경로 중 '실제로 존재하지 않는' 것을 찾는다.
    파생 파일이 이미 없어도(=고아 0개) 색인에 남은 참조를 이 방식으로 감지한다.
    반환: [(줄번호, 경로문자열, 줄내용), ...]
    """
    entries = []
    if not DOCUMENT_INDEX.exists():
        return entries
    try:
        lines = DOCUMENT_INDEX.read_text(encoding="utf-8").splitlines()
    except OSError:
        return entries
    for i, line in enumerate(lines, start=1):
        for span in CODE_SPAN.findall(line):
            s = span.strip()
            # 파일 경로처럼 보이는 것만: 구분자 포함, 플레이스홀더/글롭 제외, 폴더(끝 /) 제외
            if "/" not in s and "\\" not in s:
                continue
            if any(c in s for c in "{}*"):
                continue
            if s.endswith("/") or s.endswith("\\"):
                continue
            p = (ROOT / s)
            try:
                p.resolve().relative_to(ROOT.resolve())
            except ValueError:
                continue  # 워크스페이스 밖 경로는 무시
            if not p.exists():
                entries.append((i, s, line.strip()))
    return entries


def report_references(stems):
    """워크스페이스 문서에서 주어진 stem들을 '언급'하는 위치를 찾는다(삭제/수정하지 않음)."""
    hits = []
    for md in ROOT.rglob("*.md"):
        rel_parts = md.relative_to(ROOT).parts
        if rel_parts and rel_parts[0] in REPORT_EXCLUDE_TOP:
            continue
        if md.name in REPORT_EXCLUDE_NAMES:
            continue
        # 파생물 자신(03_working/data)의 .md 는 제외
        if md.parent == DATA_DIR:
            continue
        try:
            lines = md.read_text(encoding="utf-8").splitlines()
        except (UnicodeDecodeError, OSError):
            continue
        for i, line in enumerate(lines, start=1):
            for stem in stems:
                if stem and stem in line:
                    hits.append((md.relative_to(ROOT), i, stem, line.strip()))
                    break
    return hits


def format_report_lines(hits, stale_index=None):
    """참조 리포트(문서 언급 + 색인 stale)를 프롬프트에 넣을 문자열로 만든다."""
    lines = []
    if stale_index:
        lines.append("[DOCUMENT_INDEX stale 참조 — 실제 파일 없음]")
        for ln, spath, _ in stale_index:
            lines.append(f"- DOCUMENT_INDEX.md:{ln}  → {spath}")
    if hits:
        lines.append("[문서 언급 위치]")
        for rel, ln, stem, text in hits:
            lines.append(f"- {rel}:{ln}  ({text[:80]})")
    if not lines:
        return "(문서에서 언급된 위치 없음)"
    return "\n".join(lines)


def build_filled_prompt(deleted_display, hits, stale_index=None):
    """
    정리 프롬프트 템플릿을 읽어 {경로/파일명}, {붙여넣기}를 자동으로 채운 완성 프롬프트를 만든다.
    템플릿을 못 읽으면 최소한의 프롬프트를 생성한다.
    """
    report = format_report_lines(hits, stale_index)
    try:
        text = PROMPT_TEMPLATE.read_text(encoding="utf-8")
        parts = text.split("```")
        # 템플릿에는 프롬프트 코드블록이 하나 있음 → parts[1]이 프롬프트 본문
        if len(parts) >= 3:
            body = parts[1].strip("\n")
            body = body.replace("{경로/파일명}", deleted_display)
            body = body.replace("{붙여넣기}", "\n" + report)
            return body
    except OSError:
        pass

    # 폴백: 템플릿을 못 읽은 경우
    return (
        "너는 입력자료 삭제로 인한 문서 참조를 정리하는 것을 돕는다. 되돌리기 어려운 수정은 사람 확인을 거친다.\n\n"
        f"- 삭제된 입력자료: {deleted_display}\n"
        f"- 정리 스크립트 리포트(언급 위치 목록):\n{report}\n\n"
        "위 언급 각각이 (a) 실제 참조인지 (b) 단순 예시인지 구분하고, (a)만 갱신하라.\n"
        "DOCUMENT_INDEX 행은 지우기보다 superseded로 바꾸고, CHANGE_LOG에 기록하라.\n"
        "OUTPUT_STANDARDS의 파일명 규칙 예시 같은 단순 예시는 건드리지 마라."
    )


def main():
    parser = argparse.ArgumentParser(
        description="입력 삭제 후 남은 고아 파생물(03_working/data)을 미리보기/정리합니다."
    )
    parser.add_argument("--apply", action="store_true",
                        help="실제로 삭제합니다(미지정 시 미리보기만).")
    parser.add_argument("--prompt-out", default=None,
                        help="자동 채운 정리 프롬프트를 저장할 경로(기본: 03_working/cleanup_request.md). "
                             "문서 참조가 있을 때만 생성됩니다.")
    parser.add_argument("--no-prompt", action="store_true",
                        help="자동 채운 정리 프롬프트 파일을 생성하지 않습니다.")
    args = parser.parse_args()

    input_stems = current_input_stems()
    orphans = find_orphans(input_stems)
    stale_index = find_stale_index_entries()

    print("=" * 56)
    print(" 입력 삭제 후 정리 — 스캔")
    print("=" * 56)
    print(f"- 워크스페이스: {ROOT}")
    print(f"- 검사 대상: 03_working/data/ 고아 + DOCUMENT_INDEX stale 참조")
    print(f"- 현재 입력 엑셀 수: {len(input_stems)}")
    print("")

    # '사라진 자료명' = 고아 파생물의 stem + stale 색인 경로의 stem
    gone_stems = {p.stem for p in orphans}
    for _, spath, _ in stale_index:
        gone_stems.add(Path(spath).stem)
    gone_stems = sorted(s for s in gone_stems if s)

    # 문서 언급 위치(색인의 stale 행 포함) — 자동 수정하지 않음
    hits = report_references(gone_stems) if gone_stems else []

    orphans_exist = bool(orphans)
    docs_need = bool(hits) or bool(stale_index)

    # (1) 아무 것도 없으면 종료
    if not orphans_exist and not docs_need:
        print("정리할 고아 파생물도, 갱신할 문서 참조도 없습니다.")
        return 0

    # (2) 고아 파생물
    if orphans_exist:
        mode = "삭제함(--apply)" if args.apply else "미리보기(삭제 안 함)"
        print(f"[고아 파생물 {len(orphans)}개] — {mode}")
        for p in orphans:
            print(f"  - {p.relative_to(ROOT)}")
        print("")
    else:
        print("고아 파생물(03_working/data)은 없습니다.")
        print("")

    # (3) DOCUMENT_INDEX stale 참조
    if stale_index:
        print("[DOCUMENT_INDEX가 가리키는데 실제로 없는 경로] — 색인 갱신 필요:")
        for ln, spath, _ in stale_index:
            print(f"  - DOCUMENT_INDEX.md:{ln}  → {spath}")
        print("")

    # (4) 문서 언급 위치 리포트
    if hits:
        print("[문서에서 이 자료명을 '언급'하는 위치] — 자동 수정하지 않음, 사람이 확인:")
        for rel, ln, stem, text in hits:
            print(f"  - {rel}:{ln}  ({text[:70]})")
        print("")
        print("  ※ 주의: 위 언급 중 일부는 '단순 예시'일 수 있습니다(예: 파일명 규칙 설명).")
        print("")

    # (5) 삭제(--apply, 고아가 있을 때만)
    if args.apply and orphans_exist:
        for p in orphans:
            try:
                p.unlink()
                print(f"삭제됨: {p.relative_to(ROOT)}")
            except OSError as e:
                print(f"삭제 실패: {p.relative_to(ROOT)} ({e})")
        print("")

    # (6) 문서 갱신이 필요하면, 빈칸이 채워진 '완성 정리 프롬프트'를 파일로 생성
    if docs_need and not args.no_prompt:
        deleted_display = ", ".join(f"{s} (원본 삭제됨)" for s in gone_stems) or "(불명 — 리포트 참고)"
        filled = build_filled_prompt(deleted_display, hits, stale_index)
        out_path = Path(args.prompt_out).resolve() if args.prompt_out else DEFAULT_PROMPT_OUT
        try:
            out_path.parent.mkdir(parents=True, exist_ok=True)
            out_path.write_text(filled, encoding="utf-8")
            rel = out_path.relative_to(ROOT) if str(out_path).startswith(str(ROOT)) else out_path
            print("=" * 56)
            print(" 자동 채운 정리 프롬프트를 만들었습니다 (그대로 AI에게 전달)")
            print(f"  파일: {rel}")
            print("  → AI에게 '입력 삭제 정리해줘'라고 하며 이 파일을 전달하면 됩니다.")
            print("=" * 56)
        except OSError as e:
            print(f"정리 프롬프트 저장 실패: {e}")

    if not args.apply and orphans_exist:
        print("(미리보기: 고아를 실제로 지우려면 --apply)")

    # 종료 코드(비트마스크): 2=고아 있음, 1=문서 갱신 필요
    return (2 if orphans_exist else 0) | (1 if docs_need else 0)


if __name__ == "__main__":
    sys.exit(main())
