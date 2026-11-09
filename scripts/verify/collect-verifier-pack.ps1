#Requires -Version 5.1
<#
.SYNOPSIS
  Collect a markdown verifier pack on stdout (does not write into the repo).
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
        if (($proc.ExitCode -eq 0) -and -not $json) {
            Write-Error "gh issue view $Number failed: empty stdout (exit $($proc.ExitCode)): $errText"
        } else {
            Write-Error "gh issue view $Number failed (exit $($proc.ExitCode)): $errText"
        }
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

@"
# Verifier pack
- branch: $branch
- origin_main_sha: $mainSha
- $scopeLine
- name_status_count: $($nameStatus.Count)
- has_unstaged_changes: $hasUnstaged
- diff_mode: $diffMode

## name-status
$nameStatusText

## status-porcelain
$porcelainText

## task-card / issue scope
$card

## diff
$diffBody
"@
