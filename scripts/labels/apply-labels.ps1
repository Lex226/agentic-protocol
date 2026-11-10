#Requires -Version 5.1
<#
.SYNOPSIS
  Additively apply standards/labels.json from Lex226/github-playbook.
.DESCRIPTION
  Creates labels that are missing from the target repository and updates the
  color and description of labels that belong to the set. Labels outside the
  set stay. -WhatIf is this script's own switch: there is no CmdletBinding
  and no ShouldProcess.
.PARAMETER Repo
  Target repository, owner/name.
.PARAMETER LabelsRef
  Full lowercase 40-hex commit SHA of Lex226/github-playbook. Mandatory, no default.
.PARAMETER WhatIf
  Print создать / обновить / без изменений for each label in the set. Read-only.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Repo,

    [Parameter(Mandatory = $true)]
    [string]$LabelsRef,

    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try {
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [Console]::OutputEncoding = $utf8NoBom
} catch { }

$LabelsSource = 'Lex226/github-playbook'
$LabelsPath = 'standards/labels.json'
$LabelListLimit = 200

function Write-OutLine {
    param([string]$Message)
    [Console]::Out.WriteLine($Message)
}

function Write-ErrLine {
    param([string]$Message)
    [Console]::Error.WriteLine($Message)
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

function Get-PropertyValue {
    param($Object, [string]$Name)
    if ($null -eq $Object) { return $null }
    $prop = $Object.PSObject.Properties[$Name]
    if ($null -eq $prop) { return $null }
    return $prop.Value
}

function ConvertTo-ObjectArray {
    param($Value)
    $list = New-Object System.Collections.Generic.List[object]
    if ($null -eq $Value) {
        return ,$list.ToArray()
    }
    if ($Value -is [System.Array]) {
        foreach ($item in $Value) {
            if ($null -ne $item) { [void]$list.Add($item) }
        }
        return ,$list.ToArray()
    }
    [void]$list.Add($Value)
    return ,$list.ToArray()
}

function Get-NormalizedColor {
    param($Value)
    if ($null -eq $Value) { return '' }
    return ([string]$Value).Trim().TrimStart('#').ToLowerInvariant()
}

function Get-NormalizedDescription {
    param($Value)
    if ($null -eq $Value) { return '' }
    return [string]$Value
}

function Invoke-Gh {
    param([string[]]$GhArgs)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $script:GhExe
    $psi.Arguments = (ConvertTo-WindowsCommandLine -Parts $GhArgs)
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = New-Object System.Text.UTF8Encoding $false
    $psi.StandardErrorEncoding = New-Object System.Text.UTF8Encoding $false
    $psi.CreateNoWindow = $true
    $proc = $null
    try {
        $proc = [System.Diagnostics.Process]::Start($psi)
        $outTask = $proc.StandardOutput.ReadToEndAsync()
        $errTask = $proc.StandardError.ReadToEndAsync()
        $proc.WaitForExit()
        $outText = [string]$outTask.GetAwaiter().GetResult()
        $errText = [string]$errTask.GetAwaiter().GetResult()
        if ($proc.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($outText)) {
            $shown = ConvertTo-WindowsCommandLine -Parts $GhArgs
            if (($proc.ExitCode -eq 0) -and [string]::IsNullOrWhiteSpace($outText)) {
                $failText = "gh $shown failed: empty stdout (exit $($proc.ExitCode)): $errText"
            } else {
                $failText = "gh $shown failed (exit $($proc.ExitCode)): $errText"
            }
            # Large gh stderr must not go through Write-Error (Windows PowerShell 5.1 hang).
            Write-ErrLine $failText
            exit 1
        }
        return $outText
    } finally {
        if ($proc) { $proc.Dispose() }
    }
}

function ConvertFrom-GitHubFileContent {
    param($Payload, [string]$RefShown)
    $encoding = [string](Get-PropertyValue -Object $Payload -Name 'encoding')
    if ($encoding -ne 'base64') {
        Write-ErrLine "standards/labels.json at ${RefShown}: encoding is not base64."
        exit 1
    }
    $content = Get-PropertyValue -Object $Payload -Name 'content'
    if ($null -eq $content -or [string]::IsNullOrWhiteSpace([string]$content)) {
        Write-ErrLine "standards/labels.json is absent or empty at $RefShown."
        exit 1
    }
    $b64 = ([string]$content) -replace '\s', ''
    try {
        $bytes = [Convert]::FromBase64String($b64)
    } catch {
        Write-ErrLine "standards/labels.json at ${RefShown}: base64 decode failed."
        exit 1
    }
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    if ($text.Length -gt 0 -and [int][char]$text[0] -eq 0xFEFF) {
        $text = $text.Substring(1)
    }
    return $text
}

if ($Repo -notmatch '^[^/\s]+/[^/\s]+$') {
    Write-ErrLine "Repo must be owner/name. Got: $Repo"
    exit 1
}

if (-not [regex]::IsMatch($LabelsRef, '^[0-9a-f]{40}$')) {
    Write-ErrLine "LabelsRef must match ^[0-9a-f]{40}$ (full lowercase SHA). Got: $LabelsRef"
    exit 1
}

$ghCmd = @(Get-Command gh -CommandType Application -ErrorAction SilentlyContinue) | Select-Object -First 1
if (-not $ghCmd) {
    Write-ErrLine 'GitHub CLI (gh) не найден в PATH.'
    exit 1
}
$script:GhExe = [string]$ghCmd.Source

$contentsPath = "repos/$LabelsSource/contents/${LabelsPath}?ref=$LabelsRef"
$contentsJson = Invoke-Gh -GhArgs @('api', $contentsPath)
try {
    $contentsPayload = $contentsJson | ConvertFrom-Json
} catch {
    Write-ErrLine "standards/labels.json at ${LabelsRef}: gh returned non-JSON."
    exit 1
}
$labelsText = ConvertFrom-GitHubFileContent -Payload $contentsPayload -RefShown $LabelsRef
try {
    $standardDoc = $labelsText | ConvertFrom-Json
} catch {
    Write-ErrLine "standards/labels.json at ${LabelsRef}: JSON parse failed."
    exit 1
}
if ($null -eq (Get-PropertyValue -Object $standardDoc -Name 'labels')) {
    Write-ErrLine "standards/labels.json at ${LabelsRef}: field labels is absent."
    exit 1
}
$standardLabels = ConvertTo-ObjectArray (Get-PropertyValue -Object $standardDoc -Name 'labels')

$listJson = Invoke-Gh -GhArgs @(
    'label', 'list', '-R', $Repo,
    '--json', 'name,color,description',
    '--limit', "$LabelListLimit"
)
try {
    $parsedList = $listJson | ConvertFrom-Json
} catch {
    Write-ErrLine "Не удалось разобрать список меток $Repo."
    exit 1
}
$existing = ConvertTo-ObjectArray $parsedList

Write-OutLine "Репозиторий: $Repo"
Write-OutLine "Набор: $LabelsSource $LabelsPath @ $LabelsRef"
if ($WhatIf) {
    Write-OutLine 'Режим: WhatIf'
} else {
    Write-OutLine 'Режим: применение'
}
if ($existing.Count -ge $LabelListLimit) {
    Write-OutLine "Предупреждение: получено $($existing.Count) меток (лимит $LabelListLimit). Список может быть неполным."
}

$existingByName = @{}
foreach ($item in $existing) {
    $existingName = [string](Get-PropertyValue -Object $item -Name 'name')
    if (-not [string]::IsNullOrWhiteSpace($existingName)) {
        $existingByName[$existingName] = $item
    }
}

$created = 0
$updated = 0
$unchanged = 0

foreach ($label in $standardLabels) {
    $name = [string](Get-PropertyValue -Object $label -Name 'name')
    if ([string]::IsNullOrWhiteSpace($name)) {
        Write-ErrLine "standards/labels.json at ${LabelsRef}: a label has no name."
        exit 1
    }
    $color = Get-NormalizedColor (Get-PropertyValue -Object $label -Name 'color')
    $description = Get-NormalizedDescription (Get-PropertyValue -Object $label -Name 'description')
    $action = 'создать'
    if ($existingByName.ContainsKey($name)) {
        $current = $existingByName[$name]
        $currentColor = Get-NormalizedColor (Get-PropertyValue -Object $current -Name 'color')
        $currentDescription = Get-NormalizedDescription (Get-PropertyValue -Object $current -Name 'description')
        $sameColor = [string]::Equals($currentColor, $color, [System.StringComparison]::Ordinal)
        $sameDescription = [string]::Equals($currentDescription, $description, [System.StringComparison]::Ordinal)
        if ($sameColor -and $sameDescription) {
            $action = 'без изменений'
        } else {
            $action = 'обновить'
        }
    }
    Write-OutLine "${action}: $name"
    if ($action -eq 'без изменений') {
        $unchanged++
        continue
    }
    if ($WhatIf) {
        if ($action -eq 'создать') { $created++ } else { $updated++ }
        continue
    }
    $body = @{ name = $name; color = $color; description = $description } | ConvertTo-Json -Compress
    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        $utf8File = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($tempFile, $body, $utf8File)
        if ($action -eq 'создать') {
            Invoke-Gh -GhArgs @('api', '--method', 'POST', "repos/$Repo/labels", '--input', $tempFile) | Out-Null
            $created++
        } else {
            $escapedName = [System.Uri]::EscapeDataString($name)
            Invoke-Gh -GhArgs @('api', '--method', 'PATCH', "repos/$Repo/labels/$escapedName", '--input', $tempFile) | Out-Null
            $updated++
        }
    } finally {
        if (Test-Path -LiteralPath $tempFile) {
            Remove-Item -LiteralPath $tempFile -Force
        }
    }
}

Write-OutLine ("Итог: создать {0}, обновить {1}, без изменений {2}." -f $created, $updated, $unchanged)
exit 0
