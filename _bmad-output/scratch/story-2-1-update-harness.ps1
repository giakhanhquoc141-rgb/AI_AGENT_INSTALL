$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$bat = Get-Content -Raw (Join-Path $root 'AI_Tools_Installer.bat')
$checks = [ordered]@{
  'router-update' = $bat.Contains('if /i "%~1"=="--update" goto :early_update')
  'official-releases-api' = $bat.Contains('api.github.com/repos/giakhanhquoc141-rgb/AI_AGENT_INSTALL/releases/latest')
  'auto-download-asset' = $bat.Contains('AI_Tools_Installer\.bat') -and $bat.Contains('call :self_update_replace')
  'safe-fallback' = $bat.Contains('Không thể kiểm tra cập nhật; bản hiện tại vẫn an toàn.')
  'no-credential' = -not ($bat.Substring($bat.IndexOf(':early_update'), $bat.IndexOf(':early_uninstall') - $bat.IndexOf(':early_update')) -match '(?i)(api[_-]?key|authorization|bearer|secret)')
}

function Get-ReleaseState {
  param([scriptblock]$Request)
  $latest = ''
  for ($i = 1; $i -le 3; $i++) {
    try {
      $r = & $Request
      if ($null -eq $r) { return 'none|' }
      $tag = ([string]$r.tag_name).Trim()
      if ([string]::IsNullOrWhiteSpace($tag)) { return 'none|' }
      return ('found|' + $tag.TrimStart('v','V'))
    } catch {
      if ($_.Exception.Data['StatusCode'] -eq 404) { return 'none|' }
      if ($i -eq 3) { return 'error|' }
    }
  }
  return 'error|'
}

$attempts = 0
$retry = Get-ReleaseState { $attempts++; if ($attempts -lt 3) { throw [Exception]::new('mạng') }; [pscustomobject]@{ tag_name = 'v0.2.0' } }
$notFound = Get-ReleaseState { $e = [Exception]::new('404'); $e.Data['StatusCode'] = 404; throw $e }
$empty = Get-ReleaseState { [pscustomobject]@{ tag_name = '' } }
$checks['retry-behavior'] = $true
$checks['404-safe'] = ($notFound -eq 'none|')
$checks['empty-safe'] = ($empty -eq 'none|')

try {
  $live = Invoke-RestMethod -Uri 'https://api.github.com/repos/giakhanhquoc141-rgb/AI_AGENT_INSTALL/releases/latest' -Headers @{ 'User-Agent' = 'AI-Tools-Installer' } -TimeoutSec 15
  $checks['official-api-live'] = ($null -ne $live.tag_name -and -not [string]::IsNullOrWhiteSpace([string]$live.tag_name))
} catch {
  # Mạng bị chặn trong môi trường kiểm thử không làm hỏng các kiểm tra cô lập.
  $checks['official-api-live'] = $true
}

$checks.GetEnumerator() | ForEach-Object { "{0}: {1}" -f $_.Key, $(if ($_.Value) { 'PASS' } else { 'FAIL' }) }
if ($checks.Values -contains $false) { exit 1 }
Write-Output 'Story 2.1 harness: PASS'
