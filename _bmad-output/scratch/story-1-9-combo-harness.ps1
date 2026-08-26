$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$bat = Get-Content -Raw (Join-Path $root 'AI_Tools_Installer.bat')
$configure = $bat.Substring($bat.IndexOf(':configure_block'), $bat.IndexOf(':install_vscode') - $bat.IndexOf(':configure_block'))
$configureCode = ($configure -split "`r?`n" | Where-Object { $_ -notmatch '^\s*rem\b' }) -join "`n"
$checks = [ordered]@{
  'configure-after-execute' = ($bat.IndexOf('call :execute_block') -lt $bat.IndexOf('call :configure_block'))
  'combo-endpoint' = $bat.Contains('http://127.0.0.1:20128/api/combos')
  'combo-name' = $bat.Contains("name='my-combo'")
  'model-primary' = $bat.Contains("COMBO_VERSION=deepseek-v4-flash")
  'fallback-1' = $bat.Contains('oc/deepseek-v4-flash-free')
  'fallback-2' = $bat.Contains('openrouter/deepseek-v4-flash')
  'fallback-3' = $bat.Contains('ds/deepseek-v4-flash')
  'idempotent-get' = ($bat.Contains(' -Method Get ') -and $bat.Contains('$found=$all|?{$_.name -eq ''my-combo''}'))
  'idempotent-update' = $bat.Contains(' -Method Put ')
  'no-credential-access' = (-not ($configureCode -match '(?i)(env:(OPENROUTER|ANTHROPIC|API[_-]?KEY|SECRET|TOKEN)|authorization\s*[:=]|bearer\s+)'))
  'no-setx' = (-not ($bat -match '(?im)^\s*setx\s'))
}
$checks.GetEnumerator() | ForEach-Object {
  if (-not $_.Value) { throw "FAIL: $($_.Key)" }
  Write-Output "PASS: $($_.Key)"
}
Write-Output 'Story 1.9 combo harness: PASS'
