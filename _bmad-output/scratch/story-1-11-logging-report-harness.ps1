$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$batPath = Join-Path $root 'AI_Tools_Installer.bat'
$bat = Get-Content -Raw -LiteralPath $batPath

function Assert([bool]$condition, [string]$message) {
  if (-not $condition) { throw "Story 1.11: $message" }
}

$configureCall = $bat.IndexOf('call :configure_block')
$reportCall = $bat.IndexOf('call :report_block')
$reportStart = $bat.LastIndexOf("`n:report_block") + 1
$reportEnd = $bat.IndexOf("`n:onboarding_fail", $reportStart)
$reportBlock = $bat.Substring($reportStart, $reportEnd - $reportStart)
$logHelper = $bat.Substring($bat.IndexOf(':log_append'), $bat.IndexOf(':run_step') - $bat.IndexOf(':log_append'))

Assert ($configureCall -ge 0 -and $reportCall -gt $configureCall) 'report must run after configure.'
Assert ($reportBlock -match '(?m)^:report_block\s*$') 'report_block missing.'
Assert ($reportBlock -match '6/6') 'report must show step 6/6.'
Assert ($reportBlock -match '\!REPORT_OK\!/\!REPORT_TOTAL\!') 'report must show X/Y.'
Assert ($reportBlock -match 'AITools') 'report must show log location.'
Assert ($reportBlock -match 'report \| \!REPORT_STATUS\! \|') 'report must write one standard result line.'
Assert (($reportBlock -split "`r?`n" | Where-Object { $_ -match 'call :log_append' }).Count -eq 1) 'report must append exactly one log line.'
Assert ($logHelper -match 'AITools\\logs') 'log must be under %LOCALAPPDATA%\\AITools\\logs.'
Assert ($logHelper -match '>>.*ai-tools-installer\.log') 'log must append and preserve old entries.'

$forbidden = '(?i)(Invoke-RestMethod|Invoke-WebRequest|authorization|bearer|api[_-]?key|api[_-]?secret|telemetry|analytics|ApplicationInsights)'
Assert (-not ($reportBlock -match $forbidden)) 'report/logging must not call network or touch credentials/telemetry.'

Write-Output 'Story 1.11 isolated harness: PASS'
