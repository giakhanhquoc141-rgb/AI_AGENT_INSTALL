$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$bat = Get-Content -Raw (Join-Path $root 'AI_Tools_Installer.bat')
$configureStart = $bat.IndexOf(':configure_block', $bat.IndexOf('rem --------------------------- configure'))
$configureEnd = $bat.IndexOf(':try_install_node', $configureStart)
$configure = $bat.Substring($configureStart, $configureEnd - $configureStart)
$credentialLines = @($configure -split "`r?`n" | Where-Object { $_ -match '(?i)(env:(api[_-])?(key|secret|token)|authorization\s*:|bearer\s+|headers\s*=)' })
$checks = [ordered]@{
  'configure-after-execute' = ($bat.IndexOf('call :execute_block') -lt $bat.IndexOf('call :configure_block'))
  'hkcu-run-key' = ($configure.Contains('Software\Microsoft\Windows\CurrentVersion\Run') -and $configure.Contains('CurrentUser.CreateSubKey'))
  'nine-router-command' = $configure.Contains('9router.cmd') -and $configure.Contains('--no-browser') -and $configure.Contains('--skip-update')
  'hidden-nine-router' = $configure.Contains('-WindowStyle Hidden')
  'official-openclaw-gateway' = $configure.Contains("openclaw gateway install") -and $configure.Contains("ArgumentList @('gateway','install')")
  'manifest-nine-router-artifact' = $configure.Contains('Autostart:HKCU Run:AI Tools Installer - 9Router')
  'manifest-openclaw-artifact' = $configure.Contains('Autostart:OpenClaw gateway')
  'dashboard-nine-router' = $configure.Contains('http://localhost:20128')
  'dashboard-openclaw' = $configure.Contains('http://127.0.0.1:18789')
  'idempotent-run-value' = $configure.Contains('$changed=($old -cne $target)') -and $configure.Contains('if($changed)')
  'no-credential-access' = ($credentialLines.Count -eq 0)
  'no-console-window' = $configure.Contains('Start-Process') -and $configure.Contains('-WindowStyle Hidden')
}
$checks.GetEnumerator() | ForEach-Object {
  if (-not $_.Value) { throw "FAIL: $($_.Key)" }
  Write-Output "PASS: $($_.Key)"
}
Write-Output 'Story 1.10 autostart/onboarding harness: PASS'
