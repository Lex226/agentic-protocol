#Requires -Version 5.1
<#
.SYNOPSIS
  Temp-repo tests for collect-verifier-pack.ps1 (multiline diff, truncation, Cyrillic, Issue scope).
.NOTES
  Issue-scope cases compile gh.exe with csc.exe from the Windows PowerShell 5.1 runtime directory (queried from powershell.exe). The collector in those cases still runs under Windows PowerShell. If that csc.exe is missing, those cases FAIL.
#>
param(
    [string]$Collector = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
if (-not $Collector) {
    $Collector = Join-Path $projectRoot 'scripts\verify\collect-verifier-pack.ps1'
}
$Collector = (Resolve-Path -LiteralPath $Collector).Path

$passed = 0
$failed = 0
$failures = New-Object System.Collections.Generic.List[string]

function Write-CaseResult {
    param([string]$Name, [bool]$Ok, [string]$Detail = '')
    if ($Ok) {
        $script:passed += 1
        Write-Host ("PASS {0}" -f $Name)
    } else {
        $script:failed += 1
        $msg = "FAIL {0}: {1}" -f $Name, $Detail
        Write-Host $msg
        [void]$script:failures.Add($msg)
    }
}

function Get-Section {
    param([string]$Pack, [string]$Heading)
    $marker = "## $Heading"
    $idx = $Pack.IndexOf($marker)
    if ($idx -lt 0) { return '' }
    $start = $idx + $marker.Length
    $rest = $Pack.Substring($start)
    $next = $rest.IndexOf("`n## ")
    if ($next -ge 0) { return $rest.Substring(0, $next).Trim("`r", "`n") }
    return $rest.Trim("`r", "`n")
}

function Invoke-GitQuiet {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$GitArgs)
    # Discard stderr so PS 5.1 + Stop does not treat git noise as terminating.
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & git @GitArgs 2>$null
        return $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $prev
    }
}

$tmp = Join-Path $env:TEMP ('c04-pack-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null

try {
    Push-Location $tmp
    try {
        $code = Invoke-GitQuiet -c init.defaultBranch=main init -q
        if ($code -ne 0) { throw "git init failed exit=$code" }

        Set-Content -Path (Join-Path $tmp 'README.md') -Value "base`n" -Encoding utf8
        Invoke-GitQuiet add README.md | Out-Null
        $code = Invoke-GitQuiet -c user.name=c04-test -c user.email=c04@test.local commit -q -m 'init'
        if ($code -ne 0) { throw "git commit init failed exit=$code" }

        # Multilingual staged file
        $cyrName = 'файл-кириллица.txt'
        $cyrPath = Join-Path $tmp $cyrName
        $content = @(
            'line-one'
            'Проверка кириллицы'
            'line-three'
        ) -join "`n"
        [System.IO.File]::WriteAllText($cyrPath, $content + "`n", [System.Text.UTF8Encoding]::new($false))
        Invoke-GitQuiet -c core.quotepath=off add -- $cyrName | Out-Null

        $packOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $Collector `
            -Issue 18 -OriginMain main 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            throw "collector failed exit=$LASTEXITCODE out=$packOut"
        }
        $pack = [string]$packOut

        $diffSec = Get-Section -Pack $pack -Heading 'diff'
        $diffLines = @($diffSec -split "`r?`n" | Where-Object { $_ -ne '' })

        $hasAt = $false
        foreach ($ln in $diffLines) { if ($ln -match '^@@') { $hasAt = $true; break } }
        $plusLines = @($diffLines | Where-Object { $_ -match '^\+' -and $_ -notmatch '^\+\+\+' })

        Write-CaseResult -Name 'multiline-has-@@' -Ok:$hasAt -Detail 'no @@ line in ## diff (likely space-joined hunks)'
        Write-CaseResult -Name 'multiline-plus-separate' -Ok:($plusLines.Count -ge 2) -Detail ("expected >=2 separate + lines, got {0}; sample={1}" -f $plusLines.Count, ($plusLines -join ' | '))
        Write-CaseResult -Name 'multiline-line-count' -Ok:($diffLines.Count -gt 1) -Detail ("diff line count={0}" -f $diffLines.Count)

        $cyrNameOk = $pack.Contains($cyrName)
        $cyrPlusOk = $false
        foreach ($ln in $diffLines) {
            if ($ln -eq '+Проверка кириллицы') { $cyrPlusOk = $true; break }
        }
        # Also accept if Cyrillic survived but was space-joined (pre-fix may fail separate +)
        if (-not $cyrPlusOk -and $pack.Contains('Проверка кириллицы')) {
            # present somewhere but not as own + line
            $cyrPlusOk = $false
        }
        Write-CaseResult -Name 'cyrillic-filename' -Ok:$cyrNameOk -Detail 'Cyrillic filename missing/garbled in pack'
        Write-CaseResult -Name 'cyrillic-plus-line' -Ok:$cyrPlusOk -Detail 'expected exact line +Проверка кириллицы in ## diff'

        # Truncation with tiny MaxDiffBytes
        $packT = & powershell -NoProfile -ExecutionPolicy Bypass -File $Collector `
            -Issue 18 -OriginMain main -MaxDiffBytes 50 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            throw "collector truncated run failed exit=$LASTEXITCODE out=$packT"
        }
        $modeOk = $packT -match '(?m)^- diff_mode: truncated\s*$'
        $tDiff = Get-Section -Pack $packT -Heading 'diff'
        $tLines = @($tDiff -split "`r?`n")
        $rawAt = $false
        $rawPlus = $false
        foreach ($ln in $tLines) {
            if ($ln -match '^@@') { $rawAt = $true }
            if ($ln -match '^\+' -and $ln -notmatch '^\+\+\+') { $rawPlus = $true }
        }
        Write-CaseResult -Name 'truncated-mode' -Ok:$modeOk -Detail 'diff_mode: truncated missing'
        Write-CaseResult -Name 'truncated-no-raw-hunks' -Ok:(-not $rawAt -and -not $rawPlus) -Detail 'truncated ## diff still contains @@ or + hunk lines'
    }
    finally {
        Pop-Location
    }
}
finally {
    if (Test-Path -LiteralPath $tmp) {
        Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Add-IssueCaseFailures {
    param([string]$Detail)
    foreach ($name in @(
            'no-github-remote-stub',
            'github-origin-issue-body',
            'github-origin-gh-fail',
            'github-origin-gh-empty-stdout',
            'github-origin-gh-big-stderr',
            'non-digit-issue-before-gh'
        )) {
        Write-CaseResult -Name $name -Ok:$false -Detail $Detail
    }
}

function Get-ShimLogLines {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return @() }
    $text = [System.IO.File]::ReadAllText($Path)
    if ([string]::IsNullOrEmpty($text)) { return @() }
    return @($text -split "`r?`n" | Where-Object { $_ -ne '' })
}

function Invoke-IssuePack {
    param([string]$IssueArg)
    # Continue: collector failures write to stderr, and Stop would abort the suite
    # before the case result is recorded.
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $lines = @(
            & powershell -NoProfile -ExecutionPolicy Bypass -File $Collector `
                -Issue $IssueArg -OriginMain main 2>&1 | ForEach-Object {
                if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.ToString() } else { [string]$_ }
            }
        )
        return @{ Exit = $LASTEXITCODE; Text = ($lines -join "`n") }
    } finally {
        $ErrorActionPreference = $prev
    }
}

function Invoke-BigStderrPack {
    param([string]$WorkingDirectory)
    # This case starts powershell.exe itself. The other cases keep `& powershell`.
    $psCmd = Get-Command powershell.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $psCmd) {
        return @{ TimedOut = $false; Exit = $null; Text = ''; ReadsFinished = $true; StartError = 'powershell.exe not found' }
    }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = [string]$psCmd.Source
    $quotedCollector = $Collector.Replace('"', '""')
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$quotedCollector`" -Issue 41 -OriginMain main"
    $psi.WorkingDirectory = $WorkingDirectory
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
    $psi.CreateNoWindow = $true
    # pwsh removes PowerShell 7 module paths only for Windows PowerShell it starts
    # itself. This process inherits the environment, so drop PSModulePath and let
    # Windows PowerShell build its own. PATH, including the shim directory, stays.
    [void]$psi.EnvironmentVariables.Remove('PSModulePath')
    $proc = $null
    $prev = $ErrorActionPreference
    try {
        $proc = [System.Diagnostics.Process]::Start($psi)
        $outTask = $proc.StandardOutput.ReadToEndAsync()
        $errTask = $proc.StandardError.ReadToEndAsync()
        if (-not $proc.WaitForExit(30000)) {
            $ErrorActionPreference = 'Continue'
            & taskkill /PID $proc.Id /T /F 2>$null | Out-Null
            [void]$outTask.Wait(5000)
            [void]$errTask.Wait(5000)
            return @{ TimedOut = $true; Exit = $null; Text = ''; ReadsFinished = $true; StartError = '' }
        }
        $outDone = $outTask.Wait(5000)
        $errDone = $errTask.Wait(5000)
        $outText = ''
        $errText = ''
        if ($outDone) { $outText = [string]$outTask.Result }
        if ($errDone) { $errText = [string]$errTask.Result }
        return @{
            TimedOut = $false
            Exit = $proc.ExitCode
            Text = ((@($outText, $errText) | Where-Object { $_ -ne '' }) -join "`n")
            ReadsFinished = ($outDone -and $errDone)
            StartError = ''
        }
    } catch {
        return @{ TimedOut = $false; Exit = $null; Text = ''; ReadsFinished = $true; StartError = $_.Exception.Message }
    } finally {
        $ErrorActionPreference = $prev
        if ($proc) { $proc.Dispose() }
    }
}

# Issue-scope cases use a temp gh.exe. The real gh stays off PATH.
# csc.exe comes from the Windows PowerShell 5.1 runtime directory.
$savedPath = $env:PATH
$hadShimLog = Test-Path Env:GH_SHIM_LOG
$savedShimLog = $env:GH_SHIM_LOG
$hadShimMode = Test-Path Env:GH_SHIM_MODE
$savedShimMode = $env:GH_SHIM_MODE
$shimRoot = $null
$issueRepo = $null
$pushedIssueRepo = $false

try {
    $runtimeDir = ''
    $runtimePrev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $runtimeRaw = & powershell.exe -NoProfile -Command "[System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()" 2>$null
        if ($LASTEXITCODE -eq 0 -and $null -ne $runtimeRaw) {
            foreach ($runtimeLine in @($runtimeRaw)) {
                $runtimeText = ([string]$runtimeLine).Trim()
                if ($runtimeText) { $runtimeDir = $runtimeText }
            }
        }
    } finally {
        $ErrorActionPreference = $runtimePrev
    }
    $csc = Join-Path $runtimeDir 'csc.exe'
    if (-not $runtimeDir -or -not (Test-Path -LiteralPath $csc)) {
        Add-IssueCaseFailures -Detail ("csc.exe not found in Windows PowerShell runtime directory: {0}" -f $runtimeDir)
    } else {
        $shimRoot = Join-Path $env:TEMP ('c08-gh-shim-' + [guid]::NewGuid().ToString('N'))
        $issueRepo = Join-Path $env:TEMP ('c08-pack-' + [guid]::NewGuid().ToString('N'))
        [void][System.IO.Directory]::CreateDirectory($shimRoot)
        [void][System.IO.Directory]::CreateDirectory($issueRepo)
        $csPath = Join-Path $shimRoot 'gh.cs'
        $shimExe = Join-Path $shimRoot 'gh.exe'
        $shimSource = @'
using System;
using System.IO;

internal static class GhShim
{
    private static int Main(string[] args)
    {
        string logPath = Environment.GetEnvironmentVariable("GH_SHIM_LOG");
        if (!string.IsNullOrEmpty(logPath))
        {
            File.AppendAllText(logPath, string.Join(" ", args) + Environment.NewLine);
        }
        string mode = Environment.GetEnvironmentVariable("GH_SHIM_MODE");
        if (string.Equals(mode, "fail", StringComparison.Ordinal))
        {
            Console.Error.WriteLine("c08-shim-fail");
            return 3;
        }
        if (string.Equals(mode, "empty", StringComparison.Ordinal))
        {
            return 0;
        }
        if (string.Equals(mode, "bigerr", StringComparison.Ordinal))
        {
            Console.Error.Write("c10-shim-bigerr" + new string('x', 1048576));
            return 4;
        }
        Console.WriteLine("{\"title\":\"C08-SHIM-TITLE\",\"body\":\"C08-SHIM-BODY\"}");
        return 0;
    }
}
'@
        [System.IO.File]::WriteAllText($csPath, $shimSource.TrimStart("`r", "`n"), [System.Text.Encoding]::ASCII)
        $compileOut = & $csc /nologo /target:exe "/out:$shimExe" $csPath 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $shimExe)) {
            Add-IssueCaseFailures -Detail ("csc.exe failed to build gh.exe: {0}" -f $compileOut.Trim())
        } else {
            Push-Location $issueRepo
            $pushedIssueRepo = $true
            $initCode = Invoke-GitQuiet -c init.defaultBranch=main init -q
            Set-Content -Path (Join-Path $issueRepo 'README.md') -Value "base`n" -Encoding utf8
            Invoke-GitQuiet add README.md | Out-Null
            $commitCode = Invoke-GitQuiet -c user.name=c08-test -c user.email=c08@test.local commit -q -m 'init'
            if ($initCode -ne 0 -or $commitCode -ne 0) {
                Add-IssueCaseFailures -Detail ("temp git init/commit failed init={0} commit={1}" -f $initCode, $commitCode)
            } else {
                $env:PATH = $shimRoot + ';' + $savedPath
                $boundary = New-Object System.Collections.Generic.List[string]
                $hostDirs = New-Object System.Collections.Generic.List[string]
                [void]$hostDirs.Add($PSHOME)
                $spawnedPwsh = Get-Command powershell.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($spawnedPwsh) {
                    $spawnedDir = Split-Path -Parent ([string]$spawnedPwsh.Source)
                    $knownHost = $false
                    foreach ($dir in $hostDirs) {
                        if ([string]::Equals($dir, $spawnedDir, [System.StringComparison]::OrdinalIgnoreCase)) { $knownHost = $true }
                    }
                    if (-not $knownHost) { [void]$hostDirs.Add($spawnedDir) }
                }
                foreach ($dir in $hostDirs) {
                    $hostGh = Join-Path $dir 'gh.exe'
                    if (Test-Path -LiteralPath $hostGh) {
                        [void]$boundary.Add("gh.exe exists next to powershell.exe: $hostGh")
                    }
                }
                $cwdGh = Join-Path (Get-Location).Path 'gh.exe'
                if (Test-Path -LiteralPath $cwdGh) {
                    [void]$boundary.Add("gh.exe exists in the test working directory: $cwdGh")
                }
                $ghApps = @(Get-Command gh -CommandType Application -All -ErrorAction SilentlyContinue)
                if ($ghApps.Count -lt 1 -or $null -eq $ghApps[0]) {
                    [void]$boundary.Add('Get-Command gh -CommandType Application returned no application')
                } else {
                    $firstGh = [System.IO.Path]::GetFullPath([string]$ghApps[0].Source)
                    $expectedGh = [System.IO.Path]::GetFullPath($shimExe)
                    if (-not [string]::Equals($firstGh, $expectedGh, [System.StringComparison]::OrdinalIgnoreCase)) {
                        [void]$boundary.Add("first gh application is '$firstGh', expected shim '$expectedGh'")
                    }
                }
                if ($boundary.Count -gt 0) {
                    Add-IssueCaseFailures -Detail ($boundary -join '; ')
                } else {
                    $logA = Join-Path $shimRoot 'case-a.log'
                    [System.IO.File]::WriteAllText($logA, '')
                    $env:GH_SHIM_LOG = $logA
                    $env:GH_SHIM_MODE = 'ok'
                    $runA = Invoke-IssuePack -IssueArg '41'
                    $scopeA = Get-Section -Pack $runA.Text -Heading 'task-card / issue scope'
                    $linesA = @(Get-ShimLogLines -Path $logA)
                    $okA = ($runA.Exit -eq 0) -and ($scopeA.Contains('no GitHub remote')) -and ($linesA.Count -eq 0)
                    Write-CaseResult -Name 'no-github-remote-stub' -Ok:$okA -Detail ("exit={0}; logLines={1}; scope={2}" -f $runA.Exit, $linesA.Count, $scopeA)

                    $remoteCode = Invoke-GitQuiet remote add origin https://github.com/offline-fixture/c08.git
                    if ($remoteCode -ne 0) {
                        Write-CaseResult -Name 'github-origin-issue-body' -Ok:$false -Detail ("git remote add exit={0}" -f $remoteCode)
                        Write-CaseResult -Name 'github-origin-gh-fail' -Ok:$false -Detail ("git remote add exit={0}" -f $remoteCode)
                        Write-CaseResult -Name 'github-origin-gh-empty-stdout' -Ok:$false -Detail ("git remote add exit={0}" -f $remoteCode)
                        Write-CaseResult -Name 'github-origin-gh-big-stderr' -Ok:$false -Detail ("git remote add exit={0}" -f $remoteCode)
                        Write-CaseResult -Name 'non-digit-issue-before-gh' -Ok:$false -Detail ("git remote add exit={0}" -f $remoteCode)
                    } else {
                        $logB = Join-Path $shimRoot 'case-b.log'
                        [System.IO.File]::WriteAllText($logB, '')
                        $env:GH_SHIM_LOG = $logB
                        $env:GH_SHIM_MODE = 'ok'
                        $runB = Invoke-IssuePack -IssueArg '41'
                        $scopeB = Get-Section -Pack $runB.Text -Heading 'task-card / issue scope'
                        $linesB = @(Get-ShimLogLines -Path $logB)
                        $logBOk = ($linesB.Count -eq 1) -and ($linesB[0].Contains('issue view 41 --json title,body'))
                        $okB = ($runB.Exit -eq 0) -and $logBOk -and
                            $scopeB.Contains('### Issue #41') -and
                            $scopeB.Contains('C08-SHIM-TITLE') -and
                            $scopeB.Contains('C08-SHIM-BODY')
                        Write-CaseResult -Name 'github-origin-issue-body' -Ok:$okB -Detail ("exit={0}; log={1}" -f $runB.Exit, ($linesB -join ' | '))

                        $logC = Join-Path $shimRoot 'case-c.log'
                        [System.IO.File]::WriteAllText($logC, '')
                        $env:GH_SHIM_LOG = $logC
                        $env:GH_SHIM_MODE = 'fail'
                        $runC = Invoke-IssuePack -IssueArg '41'
                        $linesC = @(Get-ShimLogLines -Path $logC)
                        $okC = ($runC.Exit -ne 0) -and ($linesC.Count -eq 1) -and
                            $runC.Text.Contains('gh issue view') -and
                            $runC.Text.Contains('failed') -and
                            $runC.Text.Contains('c08-shim-fail')
                        Write-CaseResult -Name 'github-origin-gh-fail' -Ok:$okC -Detail ("exit={0}; logLines={1}; out={2}" -f $runC.Exit, $linesC.Count, $runC.Text.Trim())

                        $logE = Join-Path $shimRoot 'case-e.log'
                        [System.IO.File]::WriteAllText($logE, '')
                        $env:GH_SHIM_LOG = $logE
                        $env:GH_SHIM_MODE = 'empty'
                        $runE = Invoke-IssuePack -IssueArg '41'
                        $linesE = @(Get-ShimLogLines -Path $logE)
                        $logEOk = ($linesE.Count -eq 1) -and ($linesE[0].Contains('issue view 41 --json title,body'))
                        $okE = ($runE.Exit -ne 0) -and $logEOk -and $runE.Text.Contains('empty stdout')
                        Write-CaseResult -Name 'github-origin-gh-empty-stdout' -Ok:$okE -Detail ("exit={0}; logLines={1}; out={2}" -f $runE.Exit, $linesE.Count, $runE.Text.Trim())

                        $logF = Join-Path $shimRoot 'case-f.log'
                        [System.IO.File]::WriteAllText($logF, '')
                        $env:GH_SHIM_LOG = $logF
                        $env:GH_SHIM_MODE = 'bigerr'
                        $runF = Invoke-BigStderrPack -WorkingDirectory $issueRepo
                        $linesF = @(Get-ShimLogLines -Path $logF)
                        if ($runF.StartError) {
                            Write-CaseResult -Name 'github-origin-gh-big-stderr' -Ok:$false -Detail $runF.StartError
                        } elseif ($runF.TimedOut) {
                            Write-CaseResult -Name 'github-origin-gh-big-stderr' -Ok:$false -Detail 'timeout'
                        } else {
                            $markerF = $runF.Text.Contains('c10-shim-bigerr')
                            $logFOk = ($linesF.Count -eq 1) -and ($linesF[0].Contains('issue view 41 --json title,body'))
                            $okF = ($runF.Exit -ne 0) -and $logFOk -and $markerF -and $runF.ReadsFinished
                            $detailF = "exit={0}; logLines={1}; marker={2}" -f $runF.Exit, $linesF.Count, $markerF
                            if (-not $runF.ReadsFinished) { $detailF += '; reads=incomplete' }
                            Write-CaseResult -Name 'github-origin-gh-big-stderr' -Ok:$okF -Detail $detailF
                        }

                        $logD = Join-Path $shimRoot 'case-d.log'
                        [System.IO.File]::WriteAllText($logD, '')
                        $env:GH_SHIM_LOG = $logD
                        $env:GH_SHIM_MODE = 'ok'
                        $runD = Invoke-IssuePack -IssueArg 'abc'
                        $linesD = @(Get-ShimLogLines -Path $logD)
                        $okD = ($runD.Exit -ne 0) -and ($linesD.Count -eq 0) -and $runD.Text.Contains('Issue must be digits')
                        Write-CaseResult -Name 'non-digit-issue-before-gh' -Ok:$okD -Detail ("exit={0}; logLines={1}; out={2}" -f $runD.Exit, $linesD.Count, $runD.Text.Trim())
                    }
                }
            }
        }
    }
} finally {
    if ($pushedIssueRepo) { Pop-Location }
    $env:PATH = $savedPath
    if ($hadShimLog) { $env:GH_SHIM_LOG = $savedShimLog } else { Remove-Item Env:GH_SHIM_LOG -ErrorAction SilentlyContinue }
    if ($hadShimMode) { $env:GH_SHIM_MODE = $savedShimMode } else { Remove-Item Env:GH_SHIM_MODE -ErrorAction SilentlyContinue }
    if ($shimRoot -and (Test-Path -LiteralPath $shimRoot)) {
        Remove-Item -LiteralPath $shimRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    if ($issueRepo -and (Test-Path -LiteralPath $issueRepo)) {
        Remove-Item -LiteralPath $issueRepo -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ''
Write-Host ("RESULT: {0} passed / {1} failed (total {2})" -f $passed, $failed, ($passed + $failed))
if ($failed -gt 0) {
    Write-Host 'Failures:'
    $failures | ForEach-Object { Write-Host $_ }
    exit 1
}
exit 0
