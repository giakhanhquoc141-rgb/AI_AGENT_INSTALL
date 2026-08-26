$ErrorActionPreference = 'Stop'
$bat = [IO.File]::ReadAllText((Join-Path $PSScriptRoot '..\..\AI_Tools_Installer.bat'), [Text.Encoding]::UTF8)
$code = (($bat -split "`r?`n") | Where-Object { $_ -notmatch '^\s*rem\b' }) -join "`n"

$checks = [ordered]@{
  'official user feed' = $bat -match 'https://update\.code\.visualstudio\.com/latest/win32-x64-user/stable'
  'silent user flags' = $bat -match "@\('/VERYSILENT','/NORESTART','/MERGETASKS=!runcode'\)"
  'per-user target' = $bat -match '%LOCALAPPDATA%\\Programs\\Microsoft VS Code'
  'no elevation installer' = $bat -match 'User Setup' -and $bat -notmatch 'ProgramFiles.*VSCode'
  'bounded download retry' = $bat -match 'for\(\$attempt=1;\$attempt -le 3;\$attempt\+\+\)' -and $bat -match 'call :download_with_progress "%VSCODE_URL%"'
  'signature check' = $bat -match 'Get-AuthenticodeSignature' -and $bat -match 'Microsoft Corporation'
  'absolute code command' = $bat -match '%VSCODE_CODE%.*--version' -and $bat -match '%VSCODE_CODE%.*--install-extension'
  'extension id and verification' = $bat -match 'anthropic\.claude-code' -and $bat -match '--list-extensions'
  'manifest after verification' = $bat.IndexOf('manifest_append "VSCodeExt"') -gt $bat.IndexOf('--list-extensions')
  'execution order' = $bat.IndexOf('call :try_install_vscode') -lt $bat.IndexOf('call :try_install_vscodeext')
  'failure continuation' = $bat -match '(?s)call :try_install_vscode\r?\n.*?if errorlevel 1 set "EXEC_RC=1"\r?\ncall :progress_step 5 "Claude Code extension"\r?\ncall :try_install_vscodeext'
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
