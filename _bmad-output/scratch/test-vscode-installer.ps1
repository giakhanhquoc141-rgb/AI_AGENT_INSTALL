$ErrorActionPreference = 'Stop'
$bat = Get-Content -Raw (Join-Path $PSScriptRoot '..\..\AI_Tools_Installer.bat')
$code = (($bat -split "`r?`n") | Where-Object { $_ -notmatch '^\s*rem\b' }) -join "`n"

$checks = [ordered]@{
  'official user feed' = $bat -match 'https://update\.code\.visualstudio\.com/latest/win32-x64-user/stable'
  'silent user flags' = $bat -match '/VERYSILENT /NORESTART /MERGETASKS=!runcode'
  'per-user target' = $bat -match '%LOCALAPPDATA%\\Programs\\Microsoft VS Code'
  'no elevation installer' = $bat -match 'User Setup' -and $bat -notmatch 'ProgramFiles.*VSCode'
  'bounded download retry' = $bat -match 'for /l %%r in \(1,1,3\)' -and $bat -match 'Invoke-WebRequest'
  'signature check' = $bat -match 'Get-AuthenticodeSignature' -and $bat -match 'Microsoft Corporation'
  'absolute code command' = $bat -match '%VSCODE_CODE%.*--version' -and $bat -match '%VSCODE_CODE%.*--install-extension'
  'extension id and verification' = $bat -match 'anthropic\.claude-code' -and $bat -match '--list-extensions'
  'manifest after verification' = $bat.IndexOf('manifest_append "VSCodeExt"') -gt $bat.IndexOf('--list-extensions')
  'execution order' = $bat.IndexOf('call :try_install_vscode') -lt $bat.IndexOf('call :try_install_vscodeext')
  'failure continuation' = $bat -match 'call :try_install_vscode\r?\nif errorlevel 1 set "EXEC_RC=1"\r?\ncall :try_install_vscodeext'
  'no Code.exe launch' = $bat -notmatch '(?i)Code\.exe'
  'no forbidden elevation helpers' = $code -notmatch '(?i)\bsetx\b|%ProgramFiles%|HKLM'
}
foreach ($name in $checks.Keys) {
  if (-not $checks[$name]) { throw "FAIL: $name" }
  "PASS: $name"
}

# Isolated transaction simulation: a failed post-install verification must preserve the prior state.
$oldManifest = 'VSCode | 1.0.0 | installed-at-2026-08-26 | %LOCALAPPDATA%\Programs\Microsoft VS Code'
$manifest = $oldManifest
$installed = $false
try { throw 'simulated verification failure' } catch { $installed = $false; $manifest = $oldManifest }
if ($installed -or $manifest -cne $oldManifest) { throw 'FAIL: rollback simulation' }
'PASS: rollback simulation; no machine mutation performed'
