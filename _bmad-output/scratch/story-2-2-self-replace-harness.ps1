$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$bat = Get-Content -Raw (Join-Path $root 'AI_Tools_Installer.bat')
$start = $bat.IndexOf(':self_update_replace')
$end = $bat.LastIndexOf(':unknown_mode')
if ($start -lt 0 -or $end -le $start) { throw 'Không tìm thấy block self-update replace' }
$block = $bat.Substring($start, $end - $start)
$checks = [ordered]@{
  'temp-new' = $block.Contains('.new') -and $block.Contains('.new.tmp')
  'backup-old' = $block.Contains('.old')
  'deferred-process' = $block.Contains('start "" /b cmd /d /c') -and $block.Contains('ping 127.0.0.1')
  'rollback' = $block.Contains('move /y') -and $block.Contains('UPDATE_OLD') -and $block.Contains('UPDATE_TARGET')
  'integrity-check' = $block.Contains('^@echo off') -and $block.Contains('TOOL_VERSION=')
  'official-download' = $block.Contains('Invoke-WebRequest') -and $block.Contains('User-Agent')
  'no-direct-overwrite' = -not $block.Contains('Set-Content -LiteralPath !UPDATE_TARGET!')
  'local-log' = $block.Contains('update-replace ^| scheduled') -and $block.Contains('update-replace ^| fail')
}
$checks.GetEnumerator() | ForEach-Object { "{0}: {1}" -f $_.Key, $(if ($_.Value) { 'PASS' } else { 'FAIL' }) }
if ($checks.Values -contains $false) { exit 1 }
Write-Output 'Story 2.2 harness: PASS'
