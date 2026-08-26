param([string]$BatPath)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
if ([string]::IsNullOrWhiteSpace($BatPath)) { $BatPath = Join-Path $root 'AI_Tools_Installer.bat' }
$resolvedBat = (Resolve-Path -LiteralPath $BatPath).Path
$bat = Get-Content -Raw -LiteralPath $resolvedBat
$labelMatch = [regex]::Match($bat, '(?m)^:self_update_replace\r?$')
$start = if ($labelMatch.Success) { $labelMatch.Index } else { -1 }
$end = $bat.LastIndexOf(':unknown_mode')
if ($start -lt 0 -or $end -le $start) { throw 'Không tìm thấy block self-update replace' }
$block = $bat.Substring($start, $end - $start)
$downloadMatch = [regex]::Match($bat, '(?m)^:download_with_progress\r?$')
$downloadEndMatch = if ($downloadMatch.Success) { [regex]::Match($bat, '(?m)^:log_append\r?$', [Text.RegularExpressions.RegexOptions]::None, [timespan]::FromSeconds(1)) } else { $null }
$downloadBlock = if ($downloadMatch.Success -and $downloadEndMatch.Success -and $downloadEndMatch.Index -gt $downloadMatch.Index) { $bat.Substring($downloadMatch.Index, $downloadEndMatch.Index - $downloadMatch.Index) } else { '' }
$checks = [ordered]@{
  'temp-new' = $block.Contains('.new') -and $block.Contains('.new.tmp')
  'backup-old' = $block.Contains('.old')
  'deferred-process' = $block.Contains('start "" /b cmd /d /c') -and $block.Contains('ping 127.0.0.1')
  'rollback' = $block.Contains('move /y') -and $block.Contains('UPDATE_OLD') -and $block.Contains('UPDATE_TARGET')
  'integrity-check' = $block.Contains('^@echo off') -and $block.Contains('TOOL_VERSION=')
  'official-download' = $block.Contains('call :download_with_progress') -and $downloadBlock.Contains('HttpWebRequest') -and $downloadBlock.Contains('UserAgent')
  'no-direct-overwrite' = -not $block.Contains('Set-Content -LiteralPath !UPDATE_TARGET!')
  'local-log' = $block.Contains('update-replace ^| scheduled') -and $block.Contains('update-replace ^| fail')
}
$uiChecks = [ordered]@{
  'scan-seven-milestones' = $bat.Contains("`$items=@('Git','Node','Python','VSCode','VSCodeExt','OpenClaw','9Router')") -and $bat.Contains("`$idx*100") -and $bat.Contains('[Console]::Error.WriteLine')
  'download-real-bytes' = $bat.Contains('$read+=$count') -and $bat.Contains('$total -gt 0') -and $bat.Contains('$read/1MB')
  'download-unknown-length' = $bat.Contains("elseif(`$lastDraw.ElapsedMilliseconds -ge 100)") -and $bat.Contains("('{0:N1}' -f (`$read/1MB))+' MiB'")
  'download-retry-cleanup' = $bat.Contains('for($attempt=1;$attempt -le 3;$attempt++)') -and $bat.Contains('Remove-Item -LiteralPath $o -Force -ErrorAction SilentlyContinue')
  'installer-live-wait' = $bat.Contains('while(-not $p.HasExited)') -and $bat.Contains('$sw.Elapsed.TotalSeconds') -and $bat.Contains('exit $p.ExitCode')
  'npm-output-visible' = $bat.Contains('--progress=true --loglevel=notice') -and -not $bat.Contains('npm.cmd install -g openclaw@latest >nul 2>nul')
}
$bytes = [IO.File]::ReadAllBytes($resolvedBat)
$loneLf = 0
$loneCr = 0
for ($i = 0; $i -lt $bytes.Length; $i++) {
  if ($bytes[$i] -eq 10 -and ($i -eq 0 -or $bytes[$i - 1] -ne 13)) { $loneLf++ }
  if ($bytes[$i] -eq 13 -and ($i -eq $bytes.Length - 1 -or $bytes[$i + 1] -ne 10)) { $loneCr++ }
}
$uiChecks['crlf-only'] = ($loneLf -eq 0 -and $loneCr -eq 0)
$uiChecks['utf8-no-bom'] = -not ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191)
$checks.GetEnumerator() | ForEach-Object { "{0}: {1}" -f $_.Key, $(if ($_.Value) { 'PASS' } else { 'FAIL' }) }
$uiChecks.GetEnumerator() | ForEach-Object { "ui-{0}: {1}" -f $_.Key, $(if ($_.Value) { 'PASS' } else { 'FAIL' }) }
if ($checks.Values -contains $false -or $uiChecks.Values -contains $false) { exit 1 }
Write-Output 'Story 2.2 harness: PASS'
