#Requires -Version 5.1
<#
.SYNOPSIS
  Run guard-git.cases.json against a target guard script via stdin JSON.
#>
param(
    [string]$Target = (Join-Path $PSScriptRoot '..\guard-git.ps1'),
    [string]$Cases = (Join-Path $PSScriptRoot 'guard-git.cases.json')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Target = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Target)
$Cases = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Cases)

if (-not (Test-Path -LiteralPath $Target)) {
    Write-Error "Target not found: $Target"
}
if (-not (Test-Path -LiteralPath $Cases)) {
    Write-Error "Cases not found: $Cases"
}

$caseList = Get-Content -LiteralPath $Cases -Raw -Encoding UTF8 | ConvertFrom-Json
$passed = 0
$failed = 0
$failures = @()

function Invoke-GuardCase {
    param(
        [string]$Command,
        [string]$Branch,
        [string]$Expect
    )
    $payloadObj = @{ command = $Command }
    $payload = ($payloadObj | ConvertTo-Json -Compress)
    $psiArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$Target`""
    if ($Branch) { $psiArgs += " -CurrentBranch `"$Branch`"" }

    $tmpIn = [System.IO.Path]::GetTempFileName()
    $tmpOut = [System.IO.Path]::GetTempFileName()
    $tmpErr = [System.IO.Path]::GetTempFileName()
    try {
        [System.IO.File]::WriteAllText($tmpIn, $payload)
        $p = Start-Process -FilePath 'powershell' -ArgumentList $psiArgs `
            -RedirectStandardInput $tmpIn -RedirectStandardOutput $tmpOut `
            -RedirectStandardError $tmpErr -Wait -PassThru -NoNewWindow
        $text = ''
        if (Test-Path $tmpOut) { $text = [System.IO.File]::ReadAllText($tmpOut).Trim() }
        $code = $p.ExitCode
        $perm = $null
        try {
            $j = $text | ConvertFrom-Json
            if ($j.PSObject.Properties.Name -contains 'permission') { $perm = [string]$j.permission }
        } catch { }

        $ok = $false
        if ($Expect -eq 'deny') {
            $ok = ($code -eq 2 -and $perm -eq 'deny')
        } elseif ($Expect -eq 'allow') {
            $ok = ($code -eq 0 -and $perm -eq 'allow')
        } elseif ($Expect -eq 'ask') {
            $ok = ($code -eq 0 -and $perm -eq 'ask')
        }
        return [pscustomobject]@{
            Ok = [bool]$ok
            Exit = $code
            Permission = $perm
            Out = $text
        }
    } finally {
        Remove-Item -LiteralPath $tmpIn, $tmpOut, $tmpErr -Force -ErrorAction SilentlyContinue
    }
}

$index = 0
foreach ($c in $caseList) {
    $index += 1
    $branch = ''
    if ($c.PSObject.Properties.Name -contains 'branch' -and $c.branch) { $branch = [string]$c.branch }
    $result = Invoke-GuardCase -Command ([string]$c.command) -Branch $branch -Expect ([string]$c.expect)
    if ($result.Ok) {
        $passed += 1
        Write-Host ("PASS [{0}] {1}" -f $index, $c.why)
    } else {
        $failed += 1
        $msg = "FAIL [{0}] expect={1} exit={2} perm={3} why={4} cmd={5} out={6}" -f `
            $index, $c.expect, $result.Exit, $result.Permission, $c.why, $c.command, $result.Out
        Write-Host $msg
        $failures += $msg
    }
}

$total = $passed + $failed
Write-Host ""
Write-Host ("RESULT: {0} passed / {1} failed (total {2}) target={3}" -f $passed, $failed, $total, $Target)

if ($failed -gt 0) { exit 1 }
exit 0
