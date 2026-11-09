#Requires -Version 5.1
<#
.SYNOPSIS
  Cursor beforeShellExecution guard for forbidden git/gh merge and main-push ops.
.NOTES
  Reads hook JSON from stdin via [Console]::In.ReadToEnd().
  Dry-run: -CommandString and optional -CurrentBranch without Cursor.
  Test-McpCall remains for possible future MCP wiring (not connected; ADR-0005).
  It is not registered in .cursor/hooks.json.
#>
param(
    [string]$CommandString = '',
    [string]$CurrentBranch = '',
    [string]$ToolName = '',
    [string]$ToolInput = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-HookResult {
    param(
        [ValidateSet('allow', 'deny', 'ask')]
        [string]$Permission,
        [string]$UserMessage = '',
        [string]$AgentMessage = ''
    )
    $obj = [ordered]@{ permission = $Permission }
    if ($UserMessage) { $obj.user_message = $UserMessage }
    if ($AgentMessage) { $obj.agent_message = $AgentMessage }
    $json = ($obj | ConvertTo-Json -Compress)
    [Console]::Out.Write($json)
    if ($Permission -eq 'deny') { exit 2 }
    exit 0
}

function Get-ActiveBranch {
    if ($CurrentBranch) { return $CurrentBranch.Trim() }
    try {
        $b = & git rev-parse --abbrev-ref HEAD 2>$null
        if ($LASTEXITCODE -eq 0 -and $b) { return "$b".Trim() }
    } catch { }
    return ''
}

function Split-CommandChain {
    param([string]$Command)
    if (-not $Command) { return @() }
    # Split on newlines / && || ; & | outside of double/single quotes (best-effort).
    $parts = [System.Collections.Generic.List[string]]::new()
    $buf = New-Object System.Text.StringBuilder
    $quote = [char]0
    $i = 0
    $s = $Command
    while ($i -lt $s.Length) {
        $ch = $s[$i]
        if ($quote -ne [char]0) {
            [void]$buf.Append($ch)
            if ($ch -eq $quote) { $quote = [char]0 }
            $i += 1
            continue
        }
        if ($ch -eq '"' -or $ch -eq "'") {
            $quote = $ch
            [void]$buf.Append($ch)
            $i += 1
            continue
        }
        if ($ch -eq "`n" -or $ch -eq "`r") {
            $piece = $buf.ToString().Trim()
            if ($piece) { [void]$parts.Add($piece) }
            [void]$buf.Clear()
            if ($ch -eq "`r" -and ($i + 1) -lt $s.Length -and $s[$i + 1] -eq "`n") { $i += 1 }
            $i += 1
            continue
        }
        $two = if (($i + 1) -lt $s.Length) { $s.Substring($i, 2) } else { '' }
        if ($two -eq '&&' -or $two -eq '||') {
            $piece = $buf.ToString().Trim()
            if ($piece) { [void]$parts.Add($piece) }
            [void]$buf.Clear()
            $i += 2
            continue
        }
        if ($ch -eq ';' -or $ch -eq '&' -or $ch -eq '|') {
            $piece = $buf.ToString().Trim()
            if ($piece) { [void]$parts.Add($piece) }
            [void]$buf.Clear()
            $i += 1
            continue
        }
        [void]$buf.Append($ch)
        $i += 1
    }
    $tail = $buf.ToString().Trim()
    if ($tail) { [void]$parts.Add($tail) }
    return @($parts.ToArray())
}

function Test-LooksLikeGitExe {
    param([string]$Token)
    if (-not $Token) { return $false }
    $t = $Token.Trim('"').Trim("'")
    if ($t -match '(?i)^git(\.exe)?$') { return $true }
    if ($t -match '(?i)(^|[\\/])git(\.exe)?$') { return $true }
    return $false
}

function Test-LooksLikeGhExe {
    param([string]$Token)
    if (-not $Token) { return $false }
    $t = $Token.Trim('"').Trim("'")
    if ($t -match '(?i)^gh(\.exe)?$') { return $true }
    if ($t -match '(?i)(^|[\\/])gh(\.exe)?$') { return $true }
    return $false
}

function Get-NormalizedGhCommand {
    param([string]$Part)
    # Rewrite leading gh.exe / path\gh.exe to bare "gh " for downstream regexes.
    $s = $Part.Trim()
    $tokens = [System.Collections.Generic.List[string]]::new()
    $re = [regex]'"([^"]*)"|''([^'']*)''|(\S+)'
    foreach ($m in $re.Matches($s)) {
        $t = if ($m.Groups[1].Success) { $m.Groups[1].Value }
             elseif ($m.Groups[2].Success) { $m.Groups[2].Value }
             else { $m.Groups[3].Value }
        [void]$tokens.Add($t)
    }
    if ($tokens.Count -eq 0) { return $Part }
    if (-not (Test-LooksLikeGhExe -Token $tokens[0])) { return $Part }
    $rest = New-Object System.Collections.Generic.List[string]
    for ($i = 1; $i -lt $tokens.Count; $i++) { [void]$rest.Add($tokens[$i]) }
    return ('gh ' + ($rest -join ' ')).Trim()
}

function Strip-OuterQuotes {
    param([string]$Text)
    $t = $Text.Trim()
    if ($t.Length -ge 2 -and ((($t.StartsWith('"') -and $t.EndsWith('"')) -or ($t.StartsWith("'") -and $t.EndsWith("'"))))) {
        return $t.Substring(1, $t.Length - 2).Trim()
    }
    return $t
}

function Expand-PsScriptBlockText {
    param([string]$Text)
    $t = $Text.Trim()
    # Strip one or more leading call operators and script-block braces: & { ... }
    for ($n = 0; $n -lt 4; $n++) {
        $t = $t.Trim()
        if ($t.StartsWith('&')) {
            $t = $t.Substring(1).Trim()
            continue
        }
        if ($t.Length -ge 2 -and $t.StartsWith('{') -and $t.EndsWith('}')) {
            $t = $t.Substring(1, $t.Length - 2).Trim()
            continue
        }
        break
    }
    return $t
}

function Get-GitArgTokens {
    param([string]$Part)
    $s = $Part -replace '^(?:[A-Za-z_][A-Za-z0-9_]*=\S*\s+)+', ''
    $tokens = [System.Collections.Generic.List[string]]::new()
    $re = [regex]'"([^"]*)"|''([^'']*)''|(\S+)'
    foreach ($m in $re.Matches($s)) {
        $t = if ($m.Groups[1].Success) { $m.Groups[1].Value }
             elseif ($m.Groups[2].Success) { $m.Groups[2].Value }
             else { $m.Groups[3].Value }
        [void]$tokens.Add($t)
    }
    if ($tokens.Count -eq 0) { return $null }
    if (-not (Test-LooksLikeGitExe -Token $tokens[0])) { return $null }

    # Options that take a separate argument (must skip value too).
    $optWithArg = @(
        '-c', '-C', '--git-dir', '--work-tree', '--namespace',
        '--config-env', '--exec-path', '--super-prefix',
        '--upload-pack', '--receive-pack'
    )

    $i = 1
    while ($i -lt $tokens.Count) {
        $t = $tokens[$i]
        if ($t -eq '--') { $i += 1; break }

        # --opt=value forms
        if ($t -match '^--(git-dir|work-tree|namespace|config-env|exec-path|super-prefix)=') {
            $i += 1
            continue
        }
        # -Cpath glued
        if ($t -like '-C*' -and $t.Length -gt 2 -and $t -ne '-c') {
            $i += 1
            continue
        }
        if ($optWithArg -contains $t) {
            $i += 2
            continue
        }
        if ($t.StartsWith('-')) {
            $i += 1
            continue
        }
        break
    }
    if ($i -ge $tokens.Count) { return @{ Verb = ''; GitArgs = @() } }
    $rest = New-Object System.Collections.Generic.List[string]
    for ($j = $i + 1; $j -lt $tokens.Count; $j++) {
        [void]$rest.Add($tokens[$j])
    }
    return @{
        Verb = $tokens[$i]
        GitArgs = @($rest.ToArray())
    }
}

function Test-ForceRefspec {
    param([string[]]$GitArgs)
    foreach ($a in $GitArgs) {
        if ($a -match '^\+[^\s]*') { return $true }
    }
    return $false
}

function Test-IsMainRef {
    param([string]$Spec)
    $spec = $Spec.TrimStart('+')
    return (
        $spec -eq 'main' -or
        $spec -eq 'HEAD:main' -or
        $spec -eq '@:main' -or
        $spec -eq 'refs/heads/main' -or
        $spec -eq ':main' -or
        $spec -eq ':refs/heads/main' -or
        $spec -match '^[^\s:]+:(?:refs/heads/)?main$'
    )
}

function Test-PushTargetsMain {
    param(
        [string[]]$GitArgs,
        [string]$Branch
    )
    $hasForceFlag = $false
    $hasMirror = $false
    $hasAll = $false
    $deleteMode = $false
    $positionals = [System.Collections.Generic.List[string]]::new()
    $i = 0
    $arr = @($GitArgs)
    while ($i -lt $arr.Count) {
        $a = $arr[$i]
        if ($a -eq '--force' -or $a -eq '-f' -or $a -eq '--force-with-lease' -or $a -like '--force-with-lease=*') {
            $hasForceFlag = $true
            $i += 1
            continue
        }
        if ($a -eq '--mirror') { $hasMirror = $true; $i += 1; continue }
        if ($a -eq '--all') { $hasAll = $true; $i += 1; continue }
        if ($a -eq '--delete' -or $a -eq '-d') {
            $deleteMode = $true
            $i += 1
            continue
        }
        if ($a -eq '--') { $i += 1; continue }
        if ($a -in @(
                '-u', '--set-upstream', '--atomic', '--tags',
                '--prune', '--verbose', '-v', '-q', '--quiet', '--no-verify',
                '--follow-tags', '--thin', '--ipv4', '--ipv6'
            )) {
            $i += 1
            continue
        }
        if ($a.StartsWith('-')) { $i += 1; continue }
        [void]$positionals.Add($a)
        $i += 1
    }

    if ($hasForceFlag -or (Test-ForceRefspec -GitArgs $GitArgs)) {
        return @{ Deny = $true; Reason = 'force push is blocked (AGENTS.md / ADR-0003)' }
    }
    if ($hasMirror) {
        return @{ Deny = $true; Reason = 'git push --mirror is blocked' }
    }
    if ($hasAll) {
        return @{ Deny = $true; Reason = 'git push --all is blocked' }
    }

    if ($deleteMode) {
        foreach ($p in $positionals) {
            if ($p -eq 'main' -or $p -eq 'refs/heads/main' -or (Test-IsMainRef -Spec $p)) {
                return @{ Deny = $true; Reason = 'git push --delete main is blocked' }
            }
        }
        # remote then branch: origin main
        if ($positionals.Count -ge 2) {
            $br = $positionals[$positionals.Count - 1]
            if ($br -eq 'main' -or $br -eq 'refs/heads/main') {
                return @{ Deny = $true; Reason = 'git push --delete main is blocked' }
            }
        }
    }

    if ($positionals.Count -eq 0) {
        if ($Branch -eq 'main') {
            return @{ Deny = $true; Reason = 'bare git push on main is blocked' }
        }
        return @{ Deny = $false }
    }

    # remote only, no refspec → current branch
    if ($positionals.Count -eq 1 -and $positionals[0] -notmatch ':') {
        if ($positionals[0] -eq 'main') {
            return @{ Deny = $true; Reason = 'git push targeting main is blocked' }
        }
        if ($Branch -eq 'main') {
            return @{ Deny = $true; Reason = 'bare git push on main is blocked' }
        }
        return @{ Deny = $false }
    }

    $refspecs = if ($positionals.Count -ge 2) {
        @($positionals[1..($positionals.Count - 1)])
    } else {
        @($positionals)
    }
    foreach ($rs in $refspecs) {
        if (Test-IsMainRef -Spec $rs) {
            return @{ Deny = $true; Reason = "git push to main is blocked: $rs" }
        }
        # delete via :main already in Test-IsMainRef
        $trimmed = $rs.TrimStart('+')
        if (($trimmed -eq 'HEAD' -or $trimmed -eq '@') -and $Branch -eq 'main') {
            return @{ Deny = $true; Reason = 'git push HEAD/@ on main is blocked' }
        }
    }
    return @{ Deny = $false }
}

function Test-GhApiDanger {
    param([string]$Part)
    $p = $Part
    if ($p -notmatch '(?i)^\s*gh(\s+\S+)*\s+api\b') { return $null }

    if ($p -match '(?i)/pulls/\d+/merge') {
        return 'gh api pull merge endpoint is blocked'
    }
    if ($p -match '(?i)auto_merge') {
        return 'gh api auto_merge is blocked'
    }
    if ($p -match '(?i)(/|\s)merges(\s|"|''|$)') {
        return 'gh api /merges endpoint is blocked'
    }
    if ($p -match '(?i)git/refs/heads/main' -and $p -match '(?i)(-X\s+(PUT|PATCH)|--method\s+(PUT|PATCH)|-X(PUT|PATCH))') {
        return 'gh api update of refs/heads/main is blocked'
    }
    # Method may appear before path: gh api -X PATCH .../git/refs/heads/main
    if ($p -match '(?i)git/refs/heads/main' -and $p -match '(?i)\b(PUT|PATCH)\b') {
        return 'gh api update of refs/heads/main is blocked'
    }
    if ($p -match '(?i)mergePullRequest') {
        return 'gh api graphql mergePullRequest is blocked'
    }
    if ($p -match '(?i)enablePullRequestAutoMerge') {
        return 'gh api graphql enablePullRequestAutoMerge is blocked'
    }
    return $null
}

function Try-UnwrapWrapper {
    param([string]$Part)
    $p = $Part.Trim()

    # cmd /c|/k
    if ($p -match '(?i)^\s*(cmd|cmd\.exe)\s+(/c|/k)\s+(.+)$') {
        $inner = Strip-OuterQuotes -Text $Matches[3]
        return @{ Kind = 'inner'; Command = (Expand-PsScriptBlockText -Text $inner) }
    }

    # bash|sh -c
    if ($p -match '(?i)^\s*(bash|sh|bash\.exe|sh\.exe)\s+-c\s+(.+)$') {
        $inner = Strip-OuterQuotes -Text $Matches[2]
        return @{ Kind = 'inner'; Command = (Expand-PsScriptBlockText -Text $inner) }
    }

    # powershell|pwsh
    if ($p -match '(?i)^\s*(powershell|pwsh|powershell\.exe|pwsh\.exe)\b') {
        if ($p -match '(?i)(-EncodedCommand|-enc)\b') {
            return @{ Kind = 'deny'; Reason = 'powershell -EncodedCommand is blocked (opaque wrapper)' }
        }

        $hasFile = $p -match '(?i)(^|\s)-File(\s|/|$)'
        $hasCommand = $p -match '(?i)(^|\s)(-Command\b|-c\b)(\s|$)'

        # -File only (no -Command/-c): do not ask just because path contains "git"
        if ($hasFile -and -not $hasCommand) {
            return @{ Kind = 'none' }
        }

        if ($hasCommand -and $p -match '(?i)(?:-Command\b|-c\b)\s+(.+)$') {
            $inner = Strip-OuterQuotes -Text $Matches[1]
            $inner = Expand-PsScriptBlockText -Text $inner
            # iex / Invoke-Expression with git/gh not as leading exe → ask
            if ($inner -match '(?i)\b(iex|Invoke-Expression)\b' -and $inner -match '(?i)\b(git|gh)(\.exe)?\b') {
                return @{ Kind = 'ask'; Reason = 'powershell Invoke-Expression/iex with git/gh needs confirmation' }
            }
            return @{ Kind = 'inner'; Command = $inner }
        }

        # Implicit -Command: positional args after powershell switches (e.g. powershell -NoProfile git merge x)
        $tokens = [System.Collections.Generic.List[string]]::new()
        $re = [regex]'"([^"]*)"|''([^'']*)''|(\S+)'
        foreach ($m in $re.Matches($p)) {
            $t = if ($m.Groups[1].Success) { $m.Groups[1].Value }
                 elseif ($m.Groups[2].Success) { $m.Groups[2].Value }
                 else { $m.Groups[3].Value }
            [void]$tokens.Add($t)
        }
        $i = 1
        $psSwitchWithArg = @('-File', '-Command', '-c', '-EncodedCommand', '-enc', '-ExecutionPolicy', '-InputFormat', '-OutputFormat', '-PSConsoleFile', '-Version', '-WorkingDirectory', '-WindowStyle')
        while ($i -lt $tokens.Count) {
            $t = $tokens[$i]
            if ($psSwitchWithArg -contains $t -or $t -match '(?i)^-(File|Command|c|EncodedCommand|enc|ExecutionPolicy)$') {
                # Should have been handled above for -File/-Command; skip pair for other switches
                if ($t -match '(?i)^-c$' -or $t -match '(?i)^-Command$' -or $t -match '(?i)^-File$') { break }
                $i += 2
                continue
            }
            if ($t.StartsWith('-')) { $i += 1; continue }
            break
        }
        if ($i -lt $tokens.Count) {
            $positional = New-Object System.Collections.Generic.List[string]
            for ($j = $i; $j -lt $tokens.Count; $j++) { [void]$positional.Add($tokens[$j]) }
            $inner = ($positional -join ' ')
            $inner = Expand-PsScriptBlockText -Text $inner
            if ($inner -match '(?i)\b(iex|Invoke-Expression)\b' -and $inner -match '(?i)\b(git|gh)(\.exe)?\b') {
                return @{ Kind = 'ask'; Reason = 'powershell Invoke-Expression/iex with git/gh needs confirmation' }
            }
            return @{ Kind = 'inner'; Command = $inner }
        }

        if ($p -match '(?i)\b(git|gh)(\.exe)?\b') {
            return @{ Kind = 'ask'; Reason = 'unparsed powershell wrapper containing git/gh' }
        }
        return @{ Kind = 'none' }
    }

    # Bare iex / Invoke-Expression (not under powershell.exe wrapper)
    if ($p -match '(?i)^\s*(iex|Invoke-Expression)\b' -and $p -match '(?i)\b(git|gh)(\.exe)?\b') {
        return @{ Kind = 'ask'; Reason = 'Invoke-Expression/iex with git/gh needs confirmation' }
    }

    return @{ Kind = 'none' }
}

function Test-ShellPart {
    param(
        [string]$Part,
        [string]$Branch,
        [int]$Depth = 0
    )
    if ($Depth -gt 6) {
        if ($Part -match '(?i)\b(git|gh)(\.exe)?\b') {
            return @{ Permission = 'ask'; Reason = 'wrapper nesting too deep with git/gh' }
        }
        return $null
    }

    $p = $Part.Trim()
    if (-not $p) { return $null }

    $wrap = Try-UnwrapWrapper -Part $p
    if ($wrap.Kind -eq 'deny') {
        return @{ Permission = 'deny'; Reason = $wrap.Reason }
    }
    if ($wrap.Kind -eq 'ask') {
        return @{ Permission = 'ask'; Reason = $wrap.Reason }
    }
    if ($wrap.Kind -eq 'inner') {
        # Re-check inner as its own chain
        foreach ($sub in (Split-CommandChain -Command $wrap.Command)) {
            $r = Test-ShellPart -Part $sub -Branch $Branch -Depth ($Depth + 1)
            if ($null -ne $r) { return $r }
        }
        return $null
    }

    $ghCmd = Get-NormalizedGhCommand -Part $p

    if ($ghCmd -match '(?i)^\s*gh(\s+\S+)*\s+pr\s+merge(\s|$)') {
        return @{ Permission = 'deny'; Reason = 'gh pr merge is blocked (Cursor must not merge; ADR-0003)' }
    }

    $apiReason = Test-GhApiDanger -Part $ghCmd
    if ($apiReason) {
        return @{ Permission = 'deny'; Reason = $apiReason }
    }

    $git = Get-GitArgTokens -Part $p
    if ($null -ne $git) {
        $verb = $git.Verb
        $gargs = @($git.GitArgs)

        if ($verb -eq 'merge') {
            return @{ Permission = 'deny'; Reason = 'git merge is blocked for Cursor (ADR-0003)' }
        }

        if ($verb -eq 'push') {
            $r = Test-PushTargetsMain -GitArgs $gargs -Branch $Branch
            if ($r.Deny) {
                return @{ Permission = 'deny'; Reason = $r.Reason }
            }
        }
        return $null
    }

    # git/gh as a non-leading token (e.g. iex "git …" left unparsed) → ask, not allow
    $tokList = [System.Collections.Generic.List[string]]::new()
    $reTok = [regex]'"([^"]*)"|''([^'']*)''|(\S+)'
    foreach ($m in $reTok.Matches($p)) {
        $t = if ($m.Groups[1].Success) { $m.Groups[1].Value }
             elseif ($m.Groups[2].Success) { $m.Groups[2].Value }
             else { $m.Groups[3].Value }
        [void]$tokList.Add($t)
    }
    for ($ti = 1; $ti -lt $tokList.Count; $ti++) {
        if ((Test-LooksLikeGitExe -Token $tokList[$ti]) -or (Test-LooksLikeGhExe -Token $tokList[$ti])) {
            return @{ Permission = 'ask'; Reason = 'git/gh appears mid-command; needs confirmation' }
        }
    }

    return $null
}

function Test-McpCall {
    param(
        [string]$Name,
        [string]$InputJson
    )
    # Not wired in hooks.json (GitHub MCP not connected; ADR-0005). Kept for future use.
    $n = "$Name".ToLowerInvariant()
    $blob = "$Name $InputJson".ToLowerInvariant()
    if ($n -match 'merge_pull_request' -or $n -match 'merge_pr' -or $blob -match '\bmerge_pull_request\b') {
        return 'MCP merge_pull_request is blocked (ADR-0003)'
    }
    if ($blob -match 'auto[_-]?merge' -and ($blob -match 'enable|create|update|put|merge')) {
        return 'MCP auto-merge is blocked (ADR-0003)'
    }
    if ($n -match 'pull.*merge' -or ($n -match 'github' -and $blob -match '/merge')) {
        return 'MCP GitHub merge tool is blocked (ADR-0003)'
    }
    return $null
}

# --- main ---
$rawCommand = ''
$toolName = $ToolName
$toolInput = $ToolInput

if ($CommandString) {
    $rawCommand = $CommandString
} else {
    $raw = [Console]::In.ReadToEnd()
    if ($raw) {
        try {
            $payload = $raw | ConvertFrom-Json
            if ($payload.PSObject.Properties.Name -contains 'command' -and $payload.command) {
                $rawCommand = [string]$payload.command
            }
            if ($payload.PSObject.Properties.Name -contains 'tool_name' -and $payload.tool_name) {
                $toolName = [string]$payload.tool_name
            }
            if ($payload.PSObject.Properties.Name -contains 'tool_input') {
                $toolInput = ($payload.tool_input | ConvertTo-Json -Compress)
            }
        } catch {
            Write-HookResult -Permission deny -UserMessage 'guard-git: invalid hook JSON' -AgentMessage 'Hook input was not valid JSON; fail closed.'
        }
    }
}

if ($toolName) {
    $mcpReason = Test-McpCall -Name $toolName -InputJson $toolInput
    if ($mcpReason) {
        Write-HookResult -Permission deny -UserMessage $mcpReason -AgentMessage $mcpReason
    }
}

if (-not $rawCommand) {
    Write-HookResult -Permission allow
}

$branch = Get-ActiveBranch
$askHit = $null
foreach ($part in (Split-CommandChain -Command $rawCommand)) {
    $result = Test-ShellPart -Part $part -Branch $branch
    if ($null -eq $result) { continue }
    if ($result.Permission -eq 'deny') {
        Write-HookResult -Permission deny -UserMessage $result.Reason -AgentMessage $result.Reason
    }
    if ($result.Permission -eq 'ask' -and -not $askHit) {
        $askHit = $result.Reason
    }
}
if ($askHit) {
    Write-HookResult -Permission ask -UserMessage $askHit -AgentMessage $askHit
}

Write-HookResult -Permission allow
