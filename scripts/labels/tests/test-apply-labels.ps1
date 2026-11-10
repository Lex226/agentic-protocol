#Requires -Version 5.1
<#
.SYNOPSIS
  Fake-gh tests for scripts/labels/apply-labels.ps1.
.NOTES
  The gh.exe shim is compiled with csc.exe from the Windows PowerShell 5.1 runtime directory. If that csc.exe is missing, the shim cases FAIL.
#>
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ApplyScript = (Resolve-Path (Join-Path $PSScriptRoot '..\apply-labels.ps1')).Path
$ValidRef = '0123456789abcdef0123456789abcdef01234567'

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

function ConvertTo-WindowsCommandLine {
    param([string[]]$Parts)
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($part in $Parts) {
        if ($null -eq $part) { $part = '' }
        if ($part -match '[\s"]') {
            $escaped = $part.Replace('"', '\"')
            [void]$out.Add('"' + $escaped + '"')
        } else {
            [void]$out.Add($part)
        }
    }
    return ($out -join ' ')
}

function Get-ShimLogText {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return '' }
    return [System.IO.File]::ReadAllText($Path)
}

function Test-LogHasWrite {
    param([string]$LogText)
    return $LogText -match '(?i)(--method\s+(POST|PATCH|DELETE)|label\s+delete|\bDELETE\b)'
}

function Set-ShimLabelsJson {
    param([string]$Json)
    $utf8 = New-Object System.Text.UTF8Encoding $false
    $env:GH_SHIM_LABELS_B64 = [Convert]::ToBase64String($utf8.GetBytes($Json))
}

function Invoke-Apply {
    param([string[]]$ScriptArgs)
    $psCmd = Get-Command powershell.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $psCmd) {
        return @{ TimedOut = $false; Exit = $null; Text = ''; ReadsFinished = $true; StartError = 'powershell.exe not found' }
    }
    $argList = New-Object System.Collections.Generic.List[string]
    [void]$argList.Add('-NoProfile')
    [void]$argList.Add('-ExecutionPolicy')
    [void]$argList.Add('Bypass')
    [void]$argList.Add('-File')
    [void]$argList.Add($ApplyScript)
    foreach ($a in $ScriptArgs) { [void]$argList.Add($a) }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = [string]$psCmd.Source
    $psi.Arguments = (ConvertTo-WindowsCommandLine -Parts $argList.ToArray())
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = New-Object System.Text.UTF8Encoding $false
    $psi.StandardErrorEncoding = New-Object System.Text.UTF8Encoding $false
    $psi.CreateNoWindow = $true
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

function Assert-RunFinished {
    param($Run, [string]$Name)
    if ($Run.StartError) {
        Write-CaseResult -Name $Name -Ok:$false -Detail $Run.StartError
        return $false
    }
    if ($Run.TimedOut) {
        Write-CaseResult -Name $Name -Ok:$false -Detail 'timeout'
        return $false
    }
    if (-not $Run.ReadsFinished) {
        Write-CaseResult -Name $Name -Ok:$false -Detail 'reads=incomplete'
        return $false
    }
    return $true
}

$bytes = [System.IO.File]::ReadAllBytes($ApplyScript)
$scriptText = [System.IO.File]::ReadAllText($ApplyScript)
$bomOk = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
$contractOk = $bomOk -and
    ($scriptText -match '\[switch\]\$WhatIf') -and
    ($scriptText -match 'Mandatory\s*=\s*\$true') -and
    ($scriptText -match '\[regex\]::IsMatch\(\$LabelsRef, ''\^\[0-9a-f\]\{40\}\$''\)') -and
    ($scriptText -notmatch '\[CmdletBinding') -and
    ($scriptText -notmatch 'SupportsShouldProcess') -and
    ($scriptText -notmatch 'RemoveExtra') -and
    ($scriptText -notmatch '(?i)label\s+delete') -and
    ($scriptText -notmatch '(?m)^\s*Write-Error\b')
Write-CaseResult -Name 'script-contract' -Ok:$contractOk -Detail ("bom={0}" -f $bomOk)

$savedPath = $env:PATH
$hadShimLog = Test-Path Env:GH_SHIM_LOG
$savedShimLog = $env:GH_SHIM_LOG
$hadShimMode = Test-Path Env:GH_SHIM_MODE
$savedShimMode = $env:GH_SHIM_MODE
$hadLabelsB64 = Test-Path Env:GH_SHIM_LABELS_B64
$savedLabelsB64 = $env:GH_SHIM_LABELS_B64
$hadExisting = Test-Path Env:GH_SHIM_EXISTING
$savedExisting = $env:GH_SHIM_EXISTING
$shimRoot = $null

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
        Write-CaseResult -Name 'gh-shim' -Ok:$false -Detail ("csc.exe not found in Windows PowerShell runtime directory: {0}" -f $runtimeDir)
    } else {
        $shimRoot = Join-Path $env:TEMP ('c13-gh-shim-' + [guid]::NewGuid().ToString('N'))
        [void][System.IO.Directory]::CreateDirectory($shimRoot)
        $csPath = Join-Path $shimRoot 'gh.cs'
        $shimExe = Join-Path $shimRoot 'gh.exe'
        $shimSource = @'
using System;
using System.IO;
using System.Text;

internal static class GhShim
{
    private static int Main(string[] args)
    {
        Console.OutputEncoding = new UTF8Encoding(false);
        Console.InputEncoding = new UTF8Encoding(false);
        string logPath = Environment.GetEnvironmentVariable("GH_SHIM_LOG");
        if (!string.IsNullOrEmpty(logPath))
        {
            File.AppendAllText(logPath, string.Join(" ", args) + Environment.NewLine);
        }
        string mode = Environment.GetEnvironmentVariable("GH_SHIM_MODE") ?? "";
        bool isContents = false;
        bool isList = false;
        for (int i = 0; i < args.Length; i++)
        {
            string a = args[i] ?? "";
            if (a.IndexOf("contents/standards/labels.json", StringComparison.OrdinalIgnoreCase) >= 0)
            {
                isContents = true;
            }
            if (string.Equals(a, "label", StringComparison.OrdinalIgnoreCase) &&
                i + 1 < args.Length &&
                string.Equals(args[i + 1], "list", StringComparison.OrdinalIgnoreCase))
            {
                isList = true;
            }
        }
        if (isContents)
        {
            if (string.Equals(mode, "missing", StringComparison.Ordinal))
            {
                Console.Error.WriteLine("Not Found");
                return 1;
            }
            if (string.Equals(mode, "bigerr", StringComparison.Ordinal))
            {
                Console.Error.Write("c13-shim-bigerr" + new string('x', 1048576));
                return 4;
            }
            string b64 = Environment.GetEnvironmentVariable("GH_SHIM_LABELS_B64") ?? "";
            var wrapped = new StringBuilder();
            for (int i = 0; i < b64.Length; i++)
            {
                if (i > 0 && (i % 60) == 0) wrapped.Append('\n');
                wrapped.Append(b64[i]);
            }
            Console.WriteLine("{\"encoding\":\"base64\",\"content\":\"" + JsonEscape(wrapped.ToString()) + "\"}");
            return 0;
        }
        if (isList)
        {
            string existing = Environment.GetEnvironmentVariable("GH_SHIM_EXISTING");
            if (string.IsNullOrEmpty(existing)) existing = "[]";
            Console.WriteLine(existing);
            return 0;
        }
        Console.WriteLine("{}");
        return 0;
    }

    private static string JsonEscape(string value)
    {
        return value.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\r", "\\r").Replace("\n", "\\n");
    }
}
'@
        [System.IO.File]::WriteAllText($csPath, $shimSource.TrimStart("`r", "`n"), [System.Text.Encoding]::ASCII)
        $compileOut = & $csc /nologo /target:exe "/out:$shimExe" $csPath 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $shimExe)) {
            Write-CaseResult -Name 'gh-shim' -Ok:$false -Detail ("csc.exe failed to build gh.exe: {0}" -f $compileOut.Trim())
        } else {
            $env:PATH = $shimRoot + ';' + $savedPath
            $demoSame = '{"labels":[{"name":"demo","color":"aaaaaa","description":"same"},{"name":"fresh","color":"bbbbbb","description":"new"}]}'
            $demoOnly = '{"labels":[{"name":"demo","color":"aaaaaa","description":"same"}]}'
            $utf8Set = '{"labels":[{"name":"demo","color":"aaaaaa","description":"то же"}]}'
            $emptyDesc = '{"labels":[{"name":"demo","color":"aaaaaa","description":""}]}'

            $logWhatIf = Join-Path $shimRoot 'whatif.log'
            [System.IO.File]::WriteAllText($logWhatIf, '')
            $env:GH_SHIM_LOG = $logWhatIf
            $env:GH_SHIM_MODE = 'ok'
            Set-ShimLabelsJson -Json $demoSame
            $env:GH_SHIM_EXISTING = '[{"name":"demo","color":"aaaaaa","description":"same"},{"name":"local-extra","color":"cccccc","description":"keep"}]'
            $runWhatIf = Invoke-Apply -ScriptArgs @('-Repo', 'fixture/repo', '-LabelsRef', $ValidRef, '-WhatIf')
            if (Assert-RunFinished -Run $runWhatIf -Name 'whatif-readonly') {
                $logWhatIfText = Get-ShimLogText -Path $logWhatIf
                $okWhatIf = ($runWhatIf.Exit -eq 0) -and
                    ($runWhatIf.Text.Contains('Режим: WhatIf')) -and
                    ($runWhatIf.Text.Contains('без изменений: demo')) -and
                    ($runWhatIf.Text.Contains('создать: fresh')) -and
                    (-not (Test-LogHasWrite -LogText $logWhatIfText)) -and
                    ($logWhatIfText.Contains('contents/standards/labels.json')) -and
                    ($logWhatIfText.Contains('label list'))
                Write-CaseResult -Name 'whatif-readonly' -Ok:$okWhatIf -Detail ("exit={0}; log={1}" -f $runWhatIf.Exit, (($logWhatIfText -replace '\s+', ' ').Trim()))
            }

            $logCreate = Join-Path $shimRoot 'create.log'
            [System.IO.File]::WriteAllText($logCreate, '')
            $env:GH_SHIM_LOG = $logCreate
            $env:GH_SHIM_MODE = 'ok'
            Set-ShimLabelsJson -Json $demoOnly
            $env:GH_SHIM_EXISTING = '[]'
            $runCreate = Invoke-Apply -ScriptArgs @('-Repo', 'fixture/repo', '-LabelsRef', $ValidRef)
            if (Assert-RunFinished -Run $runCreate -Name 'create') {
                $logCreateText = Get-ShimLogText -Path $logCreate
                $okCreate = ($runCreate.Exit -eq 0) -and
                    ($runCreate.Text.Contains('создать: demo')) -and
                    ($runCreate.Text.Contains('Режим: применение')) -and
                    ($logCreateText -match '(?i)--method POST') -and
                    (-not ($logCreateText -match '(?i)(--method\s+DELETE|label\s+delete|\bDELETE\b)'))
                Write-CaseResult -Name 'create' -Ok:$okCreate -Detail ("exit={0}; log={1}" -f $runCreate.Exit, (($logCreateText -replace '\s+', ' ').Trim()))
            }

            $logUpdate = Join-Path $shimRoot 'update.log'
            [System.IO.File]::WriteAllText($logUpdate, '')
            $env:GH_SHIM_LOG = $logUpdate
            $env:GH_SHIM_MODE = 'ok'
            Set-ShimLabelsJson -Json $demoOnly
            $env:GH_SHIM_EXISTING = '[{"name":"demo","color":"ffffff","description":"same"}]'
            $runUpdate = Invoke-Apply -ScriptArgs @('-Repo', 'fixture/repo', '-LabelsRef', $ValidRef)
            if (Assert-RunFinished -Run $runUpdate -Name 'update') {
                $logUpdateText = Get-ShimLogText -Path $logUpdate
                $okUpdate = ($runUpdate.Exit -eq 0) -and
                    ($runUpdate.Text.Contains('обновить: demo')) -and
                    ($logUpdateText -match '(?i)--method PATCH') -and
                    (-not ($logUpdateText -match '(?i)(--method\s+DELETE|label\s+delete|\bDELETE\b)'))
                Write-CaseResult -Name 'update' -Ok:$okUpdate -Detail ("exit={0}; log={1}" -f $runUpdate.Exit, (($logUpdateText -replace '\s+', ' ').Trim()))
            }

            $logExtra = Join-Path $shimRoot 'extra.log'
            [System.IO.File]::WriteAllText($logExtra, '')
            $env:GH_SHIM_LOG = $logExtra
            $env:GH_SHIM_MODE = 'ok'
            Set-ShimLabelsJson -Json $demoOnly
            $env:GH_SHIM_EXISTING = '[{"name":"demo","color":"aaaaaa","description":"same"},{"name":"local-extra","color":"cccccc","description":"keep"}]'
            $runExtra = Invoke-Apply -ScriptArgs @('-Repo', 'fixture/repo', '-LabelsRef', $ValidRef)
            if (Assert-RunFinished -Run $runExtra -Name 'extra-not-deleted') {
                $logExtraText = Get-ShimLogText -Path $logExtra
                $okExtra = ($runExtra.Exit -eq 0) -and
                    ($runExtra.Text.Contains('без изменений: demo')) -and
                    (-not ($runExtra.Text.Contains('local-extra'))) -and
                    (-not (Test-LogHasWrite -LogText $logExtraText))
                Write-CaseResult -Name 'extra-not-deleted' -Ok:$okExtra -Detail ("exit={0}; log={1}" -f $runExtra.Exit, (($logExtraText -replace '\s+', ' ').Trim()))
            }

            $logNull = Join-Path $shimRoot 'null.log'
            [System.IO.File]::WriteAllText($logNull, '')
            $env:GH_SHIM_LOG = $logNull
            $env:GH_SHIM_MODE = 'ok'
            Set-ShimLabelsJson -Json $emptyDesc
            $env:GH_SHIM_EXISTING = '[{"name":"demo","color":"aaaaaa","description":null}]'
            $runNull = Invoke-Apply -ScriptArgs @('-Repo', 'fixture/repo', '-LabelsRef', $ValidRef)
            if (Assert-RunFinished -Run $runNull -Name 'null-description-equals-empty') {
                $logNullText = Get-ShimLogText -Path $logNull
                $okNull = ($runNull.Exit -eq 0) -and
                    ($runNull.Text.Contains('без изменений: demo')) -and
                    (-not ($logNullText -match '(?i)--method PATCH')) -and
                    (-not (Test-LogHasWrite -LogText $logNullText))
                Write-CaseResult -Name 'null-description-equals-empty' -Ok:$okNull -Detail ("exit={0}; out={1}" -f $runNull.Exit, (($runNull.Text -replace '\s+', ' ').Trim()))
            }

            $logUtf = Join-Path $shimRoot 'utf.log'
            [System.IO.File]::WriteAllText($logUtf, '')
            $env:GH_SHIM_LOG = $logUtf
            $env:GH_SHIM_MODE = 'ok'
            Set-ShimLabelsJson -Json $utf8Set
            $env:GH_SHIM_EXISTING = '[{"name":"demo","color":"aaaaaa","description":"то же"}]'
            $runUtf = Invoke-Apply -ScriptArgs @('-Repo', 'fixture/repo', '-LabelsRef', $ValidRef)
            if (Assert-RunFinished -Run $runUtf -Name 'utf8-description') {
                $logUtfText = Get-ShimLogText -Path $logUtf
                $okUtf = ($runUtf.Exit -eq 0) -and
                    ($runUtf.Text.Contains('без изменений: demo')) -and
                    (-not ($logUtfText -match '(?i)--method PATCH'))
                Write-CaseResult -Name 'utf8-description' -Ok:$okUtf -Detail ("exit={0}; out={1}" -f $runUtf.Exit, (($runUtf.Text -replace '\s+', ' ').Trim()))
            }

            $logShort = Join-Path $shimRoot 'short.log'
            [System.IO.File]::WriteAllText($logShort, '')
            $env:GH_SHIM_LOG = $logShort
            $env:GH_SHIM_MODE = 'ok'
            Set-ShimLabelsJson -Json $demoOnly
            $env:GH_SHIM_EXISTING = '[]'
            $runShort = Invoke-Apply -ScriptArgs @('-Repo', 'fixture/repo', '-LabelsRef', 'fa01bdf')
            if (Assert-RunFinished -Run $runShort -Name 'short-labelsref') {
                $logShortText = Get-ShimLogText -Path $logShort
                $okShort = ($runShort.Exit -ne 0) -and ([string]::IsNullOrWhiteSpace($logShortText)) -and
                    ($runShort.Text.Contains('LabelsRef'))
                Write-CaseResult -Name 'short-labelsref' -Ok:$okShort -Detail ("exit={0}; logLen={1}; out={2}" -f $runShort.Exit, $logShortText.Length, (($runShort.Text -replace '\s+', ' ').Trim()))
            }

            $logBad = Join-Path $shimRoot 'bad.log'
            [System.IO.File]::WriteAllText($logBad, '')
            $env:GH_SHIM_LOG = $logBad
            $env:GH_SHIM_MODE = 'ok'
            $runBad = Invoke-Apply -ScriptArgs @('-Repo', 'fixture/repo', '-LabelsRef', ('g' * 40))
            if (Assert-RunFinished -Run $runBad -Name 'invalid-labelsref') {
                $logBadText = Get-ShimLogText -Path $logBad
                $okBad = ($runBad.Exit -ne 0) -and ([string]::IsNullOrWhiteSpace($logBadText))
                Write-CaseResult -Name 'invalid-labelsref' -Ok:$okBad -Detail ("exit={0}; logLen={1}; out={2}" -f $runBad.Exit, $logBadText.Length, (($runBad.Text -replace '\s+', ' ').Trim()))
            }

            $logMissing = Join-Path $shimRoot 'missing.log'
            [System.IO.File]::WriteAllText($logMissing, '')
            $env:GH_SHIM_LOG = $logMissing
            $env:GH_SHIM_MODE = 'missing'
            Set-ShimLabelsJson -Json $demoOnly
            $env:GH_SHIM_EXISTING = '[]'
            $runMissing = Invoke-Apply -ScriptArgs @('-Repo', 'fixture/repo', '-LabelsRef', $ValidRef)
            if (Assert-RunFinished -Run $runMissing -Name 'missing-labels-json') {
                $logMissingText = Get-ShimLogText -Path $logMissing
                $okMissing = ($runMissing.Exit -ne 0) -and
                    ($logMissingText.Contains('contents/standards/labels.json')) -and
                    (-not (Test-LogHasWrite -LogText $logMissingText)) -and
                    ($runMissing.Text.Contains('Not Found'))
                Write-CaseResult -Name 'missing-labels-json' -Ok:$okMissing -Detail ("exit={0}; log={1}" -f $runMissing.Exit, (($logMissingText -replace '\s+', ' ').Trim()))
            }

            $logBig = Join-Path $shimRoot 'big.log'
            [System.IO.File]::WriteAllText($logBig, '')
            $env:GH_SHIM_LOG = $logBig
            $env:GH_SHIM_MODE = 'bigerr'
            $runBig = Invoke-Apply -ScriptArgs @('-Repo', 'fixture/repo', '-LabelsRef', $ValidRef)
            if (Assert-RunFinished -Run $runBig -Name 'big-stderr') {
                $okBig = ($runBig.Exit -ne 0) -and ($runBig.Text.Contains('c13-shim-bigerr'))
                Write-CaseResult -Name 'big-stderr' -Ok:$okBig -Detail ("exit={0}; marker={1}" -f $runBig.Exit, $runBig.Text.Contains('c13-shim-bigerr'))
            }

            $limitItems = New-Object System.Collections.Generic.List[string]
            [void]$limitItems.Add('{"name":"demo","color":"aaaaaa","description":"same"}')
            for ($i = 1; $i -lt 200; $i++) {
                [void]$limitItems.Add(('{{"name":"extra-{0:d3}","color":"cccccc","description":"keep"}}' -f $i))
            }
            $logLimit = Join-Path $shimRoot 'limit.log'
            [System.IO.File]::WriteAllText($logLimit, '')
            $env:GH_SHIM_LOG = $logLimit
            $env:GH_SHIM_MODE = 'ok'
            Set-ShimLabelsJson -Json $demoOnly
            $env:GH_SHIM_EXISTING = '[' + ($limitItems -join ',') + ']'
            $runLimit = Invoke-Apply -ScriptArgs @('-Repo', 'fixture/repo', '-LabelsRef', $ValidRef, '-WhatIf')
            if (Assert-RunFinished -Run $runLimit -Name 'limit-200-warning') {
                $logLimitText = Get-ShimLogText -Path $logLimit
                $okLimit = ($runLimit.Exit -eq 0) -and
                    ($runLimit.Text.Contains('Предупреждение: получено 200 меток')) -and
                    ($runLimit.Text.Contains('без изменений: demo')) -and
                    (-not (Test-LogHasWrite -LogText $logLimitText))
                Write-CaseResult -Name 'limit-200-warning' -Ok:$okLimit -Detail ("exit={0}" -f $runLimit.Exit)
            }
        }
    }
} finally {
    $env:PATH = $savedPath
    if ($hadShimLog) { $env:GH_SHIM_LOG = $savedShimLog } else { Remove-Item Env:GH_SHIM_LOG -ErrorAction SilentlyContinue }
    if ($hadShimMode) { $env:GH_SHIM_MODE = $savedShimMode } else { Remove-Item Env:GH_SHIM_MODE -ErrorAction SilentlyContinue }
    if ($hadLabelsB64) { $env:GH_SHIM_LABELS_B64 = $savedLabelsB64 } else { Remove-Item Env:GH_SHIM_LABELS_B64 -ErrorAction SilentlyContinue }
    if ($hadExisting) { $env:GH_SHIM_EXISTING = $savedExisting } else { Remove-Item Env:GH_SHIM_EXISTING -ErrorAction SilentlyContinue }
    if ($shimRoot -and (Test-Path -LiteralPath $shimRoot)) {
        Remove-Item -LiteralPath $shimRoot -Recurse -Force -ErrorAction SilentlyContinue
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
