#Requires -Version 5.1
<#
.SYNOPSIS
  Collect a markdown verifier pack on stdout (does not write into the repo).
  Adds a sessions/ section for branch, staged, unstaged, and untracked files.
  An empty sessions list prints a notice and is not an error.
.PARAMETER Issue
  Issue number (required unless -TaskCardPath is set).
  With a GitHub origin, gh must be installed and authenticated, the issue title and body are included in the pack, and a gh failure fails collection. Without a GitHub origin, gh is not called and the scope section contains a stub.
.PARAMETER TaskCardPath
  Path to a filled task-card markdown file (required unless -Issue is set).
.PARAMETER MaxDiffBytes
  Truncate full cached diff above this size (default 65536).
#>
param(
    [string]$Issue = '',
    [string]$TaskCardPath = '',
    [int]$MaxDiffBytes = 65536,
    [string]$OriginMain = 'origin/main'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Keep git path/name bytes as UTF-8 text in the pack.
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch { }

if (-not $Issue -and -not $TaskCardPath) {
    Write-Error 'Provide -Issue and/or -TaskCardPath (verifier refuses packs without scope).'
}

function Invoke-GitLines {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$GitArgs)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $out = & git -c core.quotepath=off @GitArgs 2>$null
        if ($null -eq $out) { return @() }
        return @($out)
    } finally {
        $ErrorActionPreference = $prev
    }
}

function Add-NameStatusPaths {
    param(
        [string[]]$Lines,
        [System.Collections.Generic.HashSet[string]]$Paths
    )
    foreach ($line in $Lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $parts = $line.Split([char]9)
        if ($parts.Length -lt 2) { continue }
        $path = $parts[$parts.Length - 1].Trim()
        if ($path) { [void]$Paths.Add($path) }
    }
}

$branch = ((& git rev-parse --abbrev-ref HEAD 2>$null) | Out-String).Trim()
$mainSha = ((& git rev-parse $OriginMain 2>$null) | Out-String).Trim()
if (-not $branch) { Write-Error 'git rev-parse --abbrev-ref HEAD failed' }
if (-not $mainSha) { Write-Error "git rev-parse $OriginMain failed" }

$nameStatus = @(Invoke-GitLines diff --cached --name-status $OriginMain)
$porcelain = @(Invoke-GitLines status --porcelain)

$hasUnstaged = 'no'
foreach ($line in $porcelain) {
    if ($line.Length -ge 2) {
        $x = $line[0]; $y = $line[1]
        if ($y -ne ' ' -and $y -ne '') { $hasUnstaged = 'yes'; break }
        if ($x -eq '?' -and $y -eq '?') { $hasUnstaged = 'yes'; break }
    }
}

$diffLines = @(Invoke-GitLines diff --cached $OriginMain)
$diffText = ($diffLines -join "`n")
$diffBytes = [System.Text.Encoding]::UTF8.GetByteCount($diffText)
$diffMode = 'full'
$diffBody = $diffText
if ($diffBytes -gt $MaxDiffBytes) {
    $diffMode = 'truncated'
    $diffBody = "(truncated: cached diff is $diffBytes bytes > limit $MaxDiffBytes)`nVerifier must Read files listed in name-status; do not assume missing changes are absent."
}

function Test-GitHubRemote {
    # `git remote -v` is not used: -v binds to -Verbose and git then prints only the remote name.
    foreach ($line in @(Invoke-GitLines remote get-url origin)) {
        if ($line -match '(?i)github\.com') { return $true }
    }
    return $false
}

function Get-IssueScopeText {
    param([string]$Number)
    if (-not (Test-GitHubRemote)) {
        return "(no GitHub remote; issue #$Number criteria text was not collected)"
    }
    if ($Number -notmatch '^\d+$') {
        Write-Error "Issue must be digits so gh issue view can collect it: $Number"
    }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = 'gh'
    $psi.Arguments = "issue view $Number --json title,body"
    $psi.WorkingDirectory = (Get-Location).Path
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $proc = [System.Diagnostics.Process]::Start($psi)
    $errTask = $proc.StandardError.ReadToEndAsync()
    $json = $proc.StandardOutput.ReadToEnd()
    $proc.WaitForExit()
    $errText = $errTask.GetAwaiter().GetResult()
    if ($proc.ExitCode -ne 0 -or -not $json) {
        # Windows PowerShell 5.1 does not finish Write-Error of a ~1 MiB message within 90s.
        # The big-stderr case still requires this text on the process error stream.
        if (($proc.ExitCode -eq 0) -and -not $json) {
            $failText = "gh issue view $Number failed: empty stdout (exit $($proc.ExitCode)): $errText"
        } else {
            $failText = "gh issue view $Number failed (exit $($proc.ExitCode)): $errText"
        }
        [Console]::Error.WriteLine($failText)
        exit 1
    }
    $issueObj = $json | ConvertFrom-Json
    return (@(
        "### Issue #$Number"
        ([string]$issueObj.title)
        ''
        ([string]$issueObj.body)
    ) -join "`n")
}

$scopeLine = ''
if ($Issue) { $scopeLine += "issue: #$Issue" }
$chunks = New-Object System.Collections.Generic.List[string]
if ($Issue) {
    [void]$chunks.Add((Get-IssueScopeText -Number $Issue))
}
if ($TaskCardPath) {
    if ($scopeLine) { $scopeLine += ' | ' }
    $scopeLine += "task-card: $TaskCardPath"
    if (Test-Path -LiteralPath $TaskCardPath) {
        $cardFile = Get-Content -LiteralPath $TaskCardPath -Raw -Encoding UTF8
        [void]$chunks.Add((@('### Task card', $cardFile.TrimEnd()) -join "`n"))
    } else {
        Write-Error "TaskCardPath not found: $TaskCardPath"
    }
}
$card = ($chunks -join "`n`n")

$nameStatusText = if ($nameStatus.Count -eq 0) { '(empty)' } else { ($nameStatus -join "`n") }
$porcelainText = if ($porcelain.Count -eq 0) { '(empty)' } else { ($porcelain -join "`n") }

$sessionSet = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
Add-NameStatusPaths -Lines @(Invoke-GitLines diff --name-status "${OriginMain}...HEAD" -- sessions/) -Paths $sessionSet
Add-NameStatusPaths -Lines @(Invoke-GitLines diff --cached --name-status -- sessions/) -Paths $sessionSet
Add-NameStatusPaths -Lines @(Invoke-GitLines diff --name-status -- sessions/) -Paths $sessionSet
foreach ($line in @(Invoke-GitLines ls-files --others --exclude-standard -- sessions/)) {
    if (-not [string]::IsNullOrWhiteSpace($line)) {
        [void]$sessionSet.Add($line.Trim())
    }
}
$sessionPaths = New-Object 'System.Collections.Generic.List[string]'
foreach ($path in $sessionSet) { [void]$sessionPaths.Add($path) }
$sessionPaths.Sort([StringComparer]::Ordinal)
$sessionsPathsText = if ($sessionPaths.Count -eq 0) { '(none)' } else { ($sessionPaths -join ', ') }

if ($sessionPaths.Count -eq 0) {
    $sessionsBody = 'снимок сессии не найден'
} else {
    $blocks = New-Object System.Collections.Generic.List[string]
    $repoRoot = (Get-Location).Path
    foreach ($rel in $sessionPaths) {
        $relNative = $rel.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
        $full = Join-Path $repoRoot $relNative
        if (Test-Path -LiteralPath $full) {
            $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8
            if ($null -eq $text) { $text = '' }
            [void]$blocks.Add("### $rel`n$text")
        } else {
            [void]$blocks.Add("### $rel`nфайл удалён в рабочем дереве")
        }
    }
    $sessionsBody = ($blocks -join "`n`n")
}
$sessionsBytes = [System.Text.Encoding]::UTF8.GetByteCount($sessionsBody)
if ($sessionsBytes -gt $MaxDiffBytes) {
    $sessionsBody = "(warning: sessions section is $sessionsBytes bytes > limit $MaxDiffBytes; text is not truncated)`n" + $sessionsBody
}

@"
# Verifier pack
- branch: $branch
- origin_main_sha: $mainSha
- $scopeLine
- name_status_count: $($nameStatus.Count)
- has_unstaged_changes: $hasUnstaged
- diff_mode: $diffMode
- sessions_count: $($sessionPaths.Count)
- sessions_paths: $sessionsPathsText

## name-status
$nameStatusText

## status-porcelain
$porcelainText

## sessions
$sessionsBody

## task-card / issue scope
$card

## diff
$diffBody
"@
