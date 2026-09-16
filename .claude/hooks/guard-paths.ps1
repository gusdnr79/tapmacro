# 역할별 파일 수정 경로 제한 (PreToolUse 훅)
# 종료 코드 2 = 차단 (stderr 내용이 에이전트에게 전달됨)
# 주의: 셸 명령을 통한 파일 변경은 막지 못한다. 최종 경계 확인은 reviewer가 git diff로 한다.
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('developer', 'tester', 'reviewer')]
    [string]$Role
)

$ErrorActionPreference = 'Stop'

try {
    $raw = [Console]::In.ReadToEnd()
    $data = $raw | ConvertFrom-Json
} catch {
    [Console]::Error.WriteLine("guard-paths: 훅 입력을 읽지 못해 차단합니다.")
    exit 2
}

$target = $data.tool_input.file_path
if (-not $target) { $target = $data.tool_input.notebook_path }
if (-not $target) { exit 0 }

$root = $env:CLAUDE_PROJECT_DIR
if (-not $root) { $root = (Get-Location).Path }

$rootFull = [System.IO.Path]::GetFullPath($root).TrimEnd('\', '/')
if ([System.IO.Path]::IsPathRooted($target)) {
    $full = [System.IO.Path]::GetFullPath($target)
} else {
    $full = [System.IO.Path]::GetFullPath((Join-Path $rootFull $target))
}

# 에이전트 메모리 디렉터리는 항상 허용
$rel = $null
if ($full.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
    $rel = $full.Substring($rootFull.Length).TrimStart('\', '/') -replace '\\', '/'
}
$userMemory = Join-Path $env:USERPROFILE '.claude\agent-memory'
if ($full.StartsWith($userMemory, [System.StringComparison]::OrdinalIgnoreCase)) { exit 0 }

if ($null -eq $rel) {
    [Console]::Error.WriteLine("guard-paths: 프로젝트 밖 경로는 수정할 수 없습니다: $full")
    exit 2
}

$common = @(
    '.claude/agent-memory/*'
)

$rules = @{
    developer = @{
        allow = @(
            'shared/*', 'androidApp/*', 'desktopApp/*', 'native/*',
            'gradle/*', '*.gradle.kts', 'gradle.properties', 'gradlew', 'gradlew.bat',
            '.gitignore', 'docs/DECISIONS.md', 'docs/reports/stage-*/dev.md'
        )
        deny = @(
            'androidApp/src/androidTest/*', 'testing/*', 'testTargetApp/*', 'desktopTestTarget/*'
        )
    }
    tester = @{
        allow = @(
            'testing/*', 'testTargetApp/*', 'desktopTestTarget/*', 'androidApp/src/androidTest/*',
            'docs/reports/stage-*/test-plan.md', 'docs/reports/stage-*/test.md',
            'docs/reports/stage-*/evidence/*'
        )
        deny = @()
    }
    reviewer = @{
        allow = @()
        deny = @()
    }
}

foreach ($p in $common) { if ($rel -like $p) { exit 0 } }

$r = $rules[$Role]
foreach ($p in $r.deny) {
    if ($rel -like $p) {
        [Console]::Error.WriteLine("guard-paths: [$Role] 역할은 '$rel' 을(를) 수정할 수 없습니다 (금지 경로 $p). 필요하면 보고서에 요청으로 남기세요.")
        exit 2
    }
}
foreach ($p in $r.allow) {
    if ($rel -like $p) { exit 0 }
}

[Console]::Error.WriteLine("guard-paths: [$Role] 역할의 허용 경로가 아닙니다: '$rel'. 필요하면 보고서에 요청으로 남기세요.")
exit 2
