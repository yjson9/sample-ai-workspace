<#
.SYNOPSIS
    워크스페이스의 폴더/파일 구조를 읽어 트리 형태로 Markdown에 기록합니다.

.DESCRIPTION
    현재 워크스페이스(sample-ai-workspace 또는 ai-workspace)의 구조를 스캔하여
    00_context/WORKSPACE_STRUCTURE.md 파일로 저장합니다.
    .git, node_modules, .venv, __pycache__, dist, build, target 등은 제외합니다.

.PARAMETER MaxDepth
    스캔할 최대 깊이. 기본값 4. 루트가 depth 0.

.PARAMETER Root
    스캔 기준 루트 경로. 기본값은 이 스크립트의 두 단계 상위 폴더(워크스페이스 루트).
    (이 스크립트는 09_scripts/tools/ 안에 있음)

.EXAMPLE
    .\09_scripts\tools\update_workspace_structure.ps1

.EXAMPLE
    .\09_scripts\tools\update_workspace_structure.ps1 -MaxDepth 5

.NOTES
    Windows PowerShell 5.1 이상에서 실행 가능합니다.
    보통은 런처 09_scripts\run.ps1 로 실행합니다.
#>

[CmdletBinding()]
param(
    [int]$MaxDepth = 4,
    [string]$Root
)

# --- 기준 경로 결정: 이 스크립트는 09_scripts/tools/ 안에 있으므로 두 단계 위가 워크스페이스 루트 ---
if (-not $Root -or $Root -eq '') {
    $Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
$Root = (Resolve-Path -LiteralPath $Root).Path

# --- 제외 대상 폴더명 ---
$ExcludeDirs = @('.git', 'node_modules', '.venv', '__pycache__', 'dist', 'build', 'target')

$OutputFile = Join-Path $Root '00_context\WORKSPACE_STRUCTURE.md'

# --- 재귀적으로 트리 라인을 생성 ---
function Get-TreeLines {
    param(
        [string]$Path,
        [int]$Depth,
        [int]$MaxDepth
    )

    $lines = @()
    if ($Depth -ge $MaxDepth) { return $lines }

    # 폴더 먼저, 그다음 파일 (이름 오름차순)
    $items = Get-ChildItem -LiteralPath $Path -Force |
        Sort-Object -Property @{Expression = { -not $_.PSIsContainer } }, Name

    foreach ($item in $items) {
        if ($item.PSIsContainer -and ($ExcludeDirs -contains $item.Name)) {
            continue
        }

        $indent = ('  ' * $Depth)
        if ($item.PSIsContainer) {
            $lines += "$indent- **$($item.Name)/**"
            $lines += Get-TreeLines -Path $item.FullName -Depth ($Depth + 1) -MaxDepth $MaxDepth
        }
        else {
            $lines += "$indent- $($item.Name)"
        }
    }

    return $lines
}

Write-Host "Scanning: $Root (MaxDepth=$MaxDepth)"

$rootName = Split-Path -Leaf $Root
$treeLines = Get-TreeLines -Path $Root -Depth 0 -MaxDepth $MaxDepth

# --- Markdown 본문 구성 ---
$stamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
$header = @()
$header += '# WORKSPACE_STRUCTURE — 워크스페이스 구조'
$header += ''
$header += '> 이 파일은 `09_scripts/tools/update_workspace_structure.ps1`(런처 `run.ps1`)로 자동 생성됩니다.'
$header += '> 직접 편집하지 말고 스크립트를 다시 실행하세요.'
$header += ''
$header += "- 생성 시각: $stamp"
$header += "- 기준 루트: ``$rootName/``"
$header += "- MaxDepth: $MaxDepth"
$header += ("- 제외 폴더: " + (($ExcludeDirs | ForEach-Object { "``$_``" }) -join ', '))
$header += ''
$header += '---'
$header += ''
$header += "- **$rootName/**"

$body = @()
foreach ($line in $treeLines) {
    $body += ('  ' + $line)   # 루트 아래로 한 단계 들여쓰기
}

$content = ($header + $body) -join "`r`n"

# --- 출력 폴더 보장 후 UTF-8로 저장 ---
$outDir = Split-Path -Parent $OutputFile
if (-not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$content | Out-File -FilePath $OutputFile -Encoding utf8

Write-Host "Written: $OutputFile"
