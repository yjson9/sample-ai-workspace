<#
.SYNOPSIS
    09_scripts의 도구들을 메뉴에서 골라 실행하는 런처.

.DESCRIPTION
    실행하면 사용 가능한 작업 목록이 번호로 표시됩니다.
    번호를 고르면 해당 작업을 실행합니다.
      - 구조 문서화(structure) : 추가 질문 없이 바로 생성
      - 엑셀 변환(convert)     : 옵션을 하나씩 질문. Enter를 누르면 기본값 사용.
                                 (기본값 = 03_working/data 에 모든 시트 변환, Markdown 생성)

    [ 새 스크립트를 추가하는 방법 ]
    아래 $Tasks 배열에 항목 한 줄만 추가하면 메뉴에 자동 반영됩니다.
      @{ Name='메뉴에 보일 이름'; Script='스크립트파일명'; Type='handler종류' }
    - Type='structure' 또는 'convert'는 이미 처리 로직이 있습니다.
    - 새로운 종류의 처리가 필요하면 Invoke-Task 아래에 handler를 추가하세요.

.PARAMETER Path
    (선택) 엑셀 파일 경로를 바로 주면 메뉴 없이 곧바로 변환합니다.
    예: .\09_scripts\run.ps1 -Path 01_inputs\samples\data.xlsx

.PARAMETER OutputDir
    (선택) 변환 결과 폴더. 기본값 03_working/data.

.PARAMETER SingleSheet
    (선택) 지정 시 첫 시트만 변환. 기본은 모든 시트 변환.

.PARAMETER NoMd
    (선택) 지정 시 Markdown을 생성하지 않음.

.EXAMPLE
    .\09_scripts\run.ps1

.EXAMPLE
    .\09_scripts\run.ps1 -Path 01_inputs\samples\data.xlsx

.NOTES
    Windows PowerShell 5.1 이상에서 실행 가능합니다.
#>

[CmdletBinding()]
param(
    [string]$Path,
    [string]$OutputDir = '03_working/data',
    [switch]$SingleSheet,
    [switch]$NoMd
)

# 한글/파이썬(UTF-8) 출력이 콘솔에서 깨지지 않도록 설정
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch { }

# --- 경로 기준: 이 스크립트(run.ps1)는 09_scripts/ 안, 상위가 워크스페이스 루트 ---
$Root = (Resolve-Path -LiteralPath (Split-Path -Parent $PSScriptRoot)).Path

# --- 실행 대상 스크립트들은 09_scripts/tools/ 안에 있음 ---
$ToolsDir = Join-Path $PSScriptRoot 'tools'

# ================================================================
# 실행 가능한 작업 목록 (새 스크립트는 tools/ 에 두고 여기에 한 줄 추가)
# ================================================================
$Tasks = @(
    @{ Name = '워크스페이스 구조 문서화 (WORKSPACE_STRUCTURE.md 생성)'; Script = 'update_workspace_structure.ps1'; Type = 'structure' },
    @{ Name = '엑셀 -> AI 변환 (JSON / JSONL / Markdown)';              Script = 'convert_excel_to_ai.py';        Type = 'convert'   },
    @{ Name = '입력 삭제 후 정리 (고아 파생물 정리)';                    Script = 'clean_orphans.py';              Type = 'clean'     }
)

# ---------------------------------------------------------------
# 공통 입력 헬퍼
# ---------------------------------------------------------------
$script:NonInteractiveExit = $false

# Read-Host 안전 래퍼: 대화형이 아니면(예: 파이프/-NonInteractive) 무한 루프 대신 종료 플래그를 세운다.
function Prompt-Line {
    param([string]$Prompt)
    try {
        return Read-Host $Prompt
    }
    catch {
        Write-Host '대화형 입력을 사용할 수 없는 환경입니다. 런처를 종료합니다.' -ForegroundColor Yellow
        Write-Host '(엑셀 변환만 바로 하려면: .\09_scripts\run.ps1 -Path <파일.xlsx>)' -ForegroundColor DarkGray
        $script:NonInteractiveExit = $true
        return $null
    }
}

function Read-WithDefault {
    param([string]$Prompt, [string]$Default)
    $v = Prompt-Line "$Prompt [$Default]"
    if ($script:NonInteractiveExit -or [string]::IsNullOrWhiteSpace($v)) { return $Default }
    return $v.Trim()
}

function Read-YesNo {
    param([string]$Prompt, [bool]$DefaultYes = $true)
    $suffix = if ($DefaultYes) { 'Y/n' } else { 'y/N' }
    $v = Prompt-Line "$Prompt [$suffix]"
    if ($script:NonInteractiveExit -or [string]::IsNullOrWhiteSpace($v)) { return $DefaultYes }
    return ($v.Trim() -match '^[Yy]')
}

# ---------------------------------------------------------------
# python 실행 명령 탐색 (python -> py)
# ---------------------------------------------------------------
function Get-PythonCommand {
    foreach ($c in @('python', 'py')) {
        if (Get-Command $c -ErrorAction SilentlyContinue) { return $c }
    }
    return $null
}

# ---------------------------------------------------------------
# 경로를 워크스페이스 루트 기준 절대경로로 변환
# ---------------------------------------------------------------
function Resolve-UnderRoot {
    param([string]$InputPath)
    if ([System.IO.Path]::IsPathRooted($InputPath)) { return $InputPath }
    return (Join-Path $Root $InputPath)
}

# ---------------------------------------------------------------
# 워크스페이스에서 .xlsx 파일 검색 (출력/아카이브/캐시 제외)
# ---------------------------------------------------------------
function Find-XlsxFiles {
    $excludeTop = @('04_outputs', '08_archive', '.git', 'node_modules', '.venv', '__pycache__')
    Get-ChildItem -LiteralPath $Root -Recurse -File -Filter *.xlsx -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -notlike '~$*' -and
            ($excludeTop -notcontains (($_.FullName.Substring($Root.Length).TrimStart('\', '/') -split '[\\/]')[0]))
        } | Sort-Object FullName
}

# ================================================================
# Handler: 구조 문서화 — 추가 질문 없이 바로 실행
# ================================================================
function Invoke-StructureTask {
    param([string]$ScriptPath)
    Write-Host ''
    Write-Host '>> 워크스페이스 구조를 문서화합니다...' -ForegroundColor Cyan
    & $ScriptPath
}

# ================================================================
# Handler: 엑셀 변환 — 옵션을 질문(Enter=기본값)하고 python 실행
# ================================================================
function Invoke-ConvertTask {
    param(
        [string]$Converter,
        [string]$InputFile = $null,   # 미리 정해진 입력(있으면 파일 선택 건너뜀)
        [string]$OutDir,
        [Nullable[bool]]$AllSheets = $null,
        [Nullable[bool]]$GenMd = $null
    )

    $py = Get-PythonCommand
    if (-not $py) {
        Write-Host 'python을 찾을 수 없습니다. Python 설치 후 다시 시도하세요.' -ForegroundColor Red
        return
    }

    # 1) 입력 파일 결정
    if (-not $InputFile) {
        $files = Find-XlsxFiles
        if ($files.Count -gt 0) {
            Write-Host ''
            Write-Host '변환할 .xlsx 파일을 선택하세요:' -ForegroundColor Cyan
            for ($i = 0; $i -lt $files.Count; $i++) {
                $rel = $files[$i].FullName.Substring($Root.Length).TrimStart('\', '/')
                Write-Host ("  [{0}] {1}" -f ($i + 1), $rel)
            }
            $sel = Prompt-Line '번호 선택 (또는 파일 경로 직접 입력)'
            if ($script:NonInteractiveExit) { return }
            if ($sel -match '^\d+$' -and [int]$sel -ge 1 -and [int]$sel -le $files.Count) {
                $InputFile = $files[[int]$sel - 1].FullName
            }
            else {
                $InputFile = $sel
            }
        }
        else {
            Write-Host '01_inputs 등에서 .xlsx 파일을 찾지 못했습니다.' -ForegroundColor Yellow
            $InputFile = Prompt-Line '변환할 .xlsx 파일 경로를 입력하세요'
            if ($script:NonInteractiveExit) { return }
        }
    }

    $InputFile = Resolve-UnderRoot $InputFile.Trim('"').Trim()
    if (-not (Test-Path -LiteralPath $InputFile)) {
        Write-Host "파일을 찾을 수 없습니다: $InputFile" -ForegroundColor Red
        return
    }

    # 2) 옵션 결정 (대화형이면 질문, 값이 주어졌으면 그대로)
    if ($null -eq $OutDir -or $OutDir -eq '') {
        $OutDir = Read-WithDefault '출력 폴더' '03_working/data'
    }
    if ($null -eq $AllSheets) {
        # 시트 개수를 먼저 확인 — 시트가 하나뿐이면 묻지 않는다.
        $sheetCount = 1
        try {
            $names = & $py $Converter '--list-sheets' $InputFile 2>$null
            $sheetCount = (@($names | Where-Object { $_ -and "$_".Trim() -ne '' })).Count
        }
        catch { $sheetCount = 1 }
        if ($sheetCount -lt 1) { $sheetCount = 1 }

        if ($sheetCount -le 1) {
            $AllSheets = $true   # 시트 1개 → 질문 생략(결과 파일명에 시트명도 안 붙음)
            Write-Host '  (시트 1개 — 전체/부분 질문 생략)' -ForegroundColor DarkGray
        }
        else {
            $AllSheets = Read-YesNo "모든 시트($sheetCount개)를 변환할까요? (아니오=첫 시트만)" $true
        }
    }
    if ($null -eq $GenMd) {
        $GenMd = Read-YesNo 'Markdown 파일도 생성할까요?' $true
    }

    $outAbs = Resolve-UnderRoot $OutDir

    # 3) python 인자 구성
    $pyArgs = @($Converter, $InputFile, '-o', $outAbs)
    if ($AllSheets) { $pyArgs += '--all-sheets' }
    if (-not $GenMd) { $pyArgs += '--no-md' }

    Write-Host ''
    Write-Host ">> 실행: $py $($pyArgs -join ' ')" -ForegroundColor Cyan
    & $py @pyArgs
}

# ================================================================
# Handler: 입력 삭제 후 정리 — 미리보기 → 확인 → 삭제 → 구조 재생성
# ================================================================
function Invoke-CleanTask {
    param([string]$ScriptPath)

    $py = Get-PythonCommand
    if (-not $py) {
        Write-Host 'python을 찾을 수 없습니다. Python 설치 후 다시 시도하세요.' -ForegroundColor Red
        return
    }

    # 1) 미리보기(삭제 안 함) — 고아 파생물 + DOCUMENT_INDEX stale 참조를 함께 스캔
    Write-Host ''
    Write-Host '>> 정리 대상 스캔(미리보기)...' -ForegroundColor Cyan
    & $py $ScriptPath
    $code = $LASTEXITCODE                        # 비트마스크: 2=고아 있음, 1=문서 갱신 필요
    $orphansExist = (($code -band 2) -ne 0)
    $docsNeed     = (($code -band 1) -ne 0)

    if (-not $orphansExist -and -not $docsNeed) {
        Write-Host ''
        Write-Host '정리할 것이 없습니다. 종료합니다.' -ForegroundColor Green
        return
    }

    # 2) 고아 파생물이 있을 때만 삭제 질문 → 삭제 → 구조 재생성
    if ($orphansExist) {
        Write-Host ''
        $ok = Read-YesNo '위 고아 파생물을 실제로 삭제할까요?' $false
        if ($script:NonInteractiveExit) { return }
        if ($ok) {
            Write-Host ''
            Write-Host '>> 삭제 실행...' -ForegroundColor Cyan
            & $py $ScriptPath '--apply'
            $structure = Join-Path $ToolsDir 'update_workspace_structure.ps1'
            if (Test-Path -LiteralPath $structure) {
                Write-Host ''
                Write-Host '>> WORKSPACE_STRUCTURE.md 재생성...' -ForegroundColor Cyan
                & $structure | Out-Null
                Write-Host '  완료.' -ForegroundColor DarkGray
            }
        }
        else {
            Write-Host '고아 파생물은 삭제하지 않았습니다.' -ForegroundColor Yellow
        }
    }

    # 3) 문서 갱신 안내 — 필요할 때만 (cleanup_request.md는 스캔 단계에서 이미 생성됨)
    Write-Host ''
    if ($docsNeed) {
        Write-Host '문서(색인/결정/분석 등)에 삭제된 자료 참조가 남아 갱신이 필요합니다.' -ForegroundColor Yellow
        Write-Host '빈칸이 이미 채워진 정리 요청서를 만들어 뒀습니다:' -ForegroundColor Yellow
        Write-Host '  03_working/cleanup_request.md' -ForegroundColor Yellow
        Write-Host 'AI에게 "입력 삭제 정리해줘"라고 하며 이 파일을 전달하면 됩니다(빈칸 채울 필요 없음).' -ForegroundColor Yellow
    }
    else {
        Write-Host '문서 참조가 없어 추가 갱신 없이 정리가 끝났습니다.' -ForegroundColor Green
    }
}

# ================================================================
# 작업 디스패치
# ================================================================
function Invoke-Task {
    param([hashtable]$Task)
    $scriptPath = Join-Path $ToolsDir $Task.Script
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        Write-Host "스크립트를 찾을 수 없습니다: $scriptPath" -ForegroundColor Red
        return
    }

    switch ($Task.Type) {
        'structure' { Invoke-StructureTask -ScriptPath $scriptPath }
        'convert'   { Invoke-ConvertTask   -Converter  $scriptPath }
        'clean'     { Invoke-CleanTask     -ScriptPath $scriptPath }
        default     { Write-Host "알 수 없는 작업 종류: $($Task.Type)" -ForegroundColor Red }
    }
}

# ================================================================
# 직접 실행 모드: -Path 가 주어지면 메뉴 없이 바로 엑셀 변환
# ================================================================
if ($PSBoundParameters.ContainsKey('Path') -and $Path) {
    $converter = Join-Path $ToolsDir 'convert_excel_to_ai.py'
    Invoke-ConvertTask -Converter $converter -InputFile $Path -OutDir $OutputDir `
        -AllSheets (-not $SingleSheet) -GenMd (-not $NoMd)
    return
}

# ================================================================
# 대화형 메뉴 루프
# ================================================================
while ($true) {
    Write-Host ''
    Write-Host '==================================================' -ForegroundColor DarkGray
    Write-Host ' 09_scripts 런처 — 실행할 작업을 선택하세요' -ForegroundColor Green
    Write-Host '==================================================' -ForegroundColor DarkGray
    for ($i = 0; $i -lt $Tasks.Count; $i++) {
        Write-Host ("  [{0}] {1}" -f ($i + 1), $Tasks[$i].Name)
    }
    Write-Host '  [Q] 종료'
    Write-Host ''

    $choice = Prompt-Line '작업 번호'
    if ($script:NonInteractiveExit) { break }
    if ($choice -match '^[Qq]') { break }

    if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $Tasks.Count) {
        Invoke-Task -Task $Tasks[[int]$choice - 1]
        if ($script:NonInteractiveExit) { break }
        Write-Host ''
        Write-Host '--- 작업 완료. Enter를 누르면 메뉴로 돌아갑니다 (종료: Q) ---' -ForegroundColor DarkGray
        $again = Prompt-Line ''
        if ($script:NonInteractiveExit) { break }
        if ($again -match '^[Qq]') { break }
    }
    else {
        Write-Host '올바른 번호를 입력하세요.' -ForegroundColor Yellow
    }
}

Write-Host '종료합니다.'
