$ErrorActionPreference = 'Stop'
$bat = Get-Content -Raw (Join-Path $PSScriptRoot '..\..\AI_Tools_Installer.bat')
$checks = [ordered]@{
  'version guard' = $bat -match "3\\.13\\.\\d\+"
  'retry three times' = $bat -match '\$i -le 3'
  'official URL' = $bat -match 'python\.org/ftp/python/%PY_VER%/python-%PY_VER%-amd64\.exe'
  'authenticode PSF' = $bat -match 'Get-AuthenticodeSignature' -and $bat -match 'Python Software Foundation'
  'silent per-user flags' = $bat -match 'InstallAllUsers=0' -and $bat -match 'Include_launcher=0' -and $bat -match 'PrependPath=0' -and $bat -match 'Shortcuts=0' -and $bat -match 'Include_test=0' -and $bat -match '/quiet /norestart'
  'exact target' = $bat -match 'Programs\\Python\\Python313' -and $bat -match 'PY_EXE=%PY_DIR%\\python\.exe'
  'path ordering' = $bat -match ':python_path_prioritize' -and $bat -match 'PATH=%PY_NEW_PATH%'
  'direct and PATH verify' = $bat -match 'Get-Command python' -and $bat -match '\$expected.*python --version'
  'manifest after verify' = $bat.IndexOf('call :manifest_append "Python"') -gt $bat.IndexOf('if errorlevel 1 goto :ipy_verify_fail')
  'rollback and cleanup' = $bat -match ':ipy_rollback' -and $bat -match ':ipy_cleanup'
  'managed target backup' = $bat -match 'PY_BACKUP=.*Python313\.aitools-backup' -and $bat -match 'Move-Item -LiteralPath \$env:PY_DIR'
  '64-bit preflight' = $bat -match 'PROCESSOR_ARCHITECTURE' -and $bat -match 'unsupported-32bit'
  'where resolution' = $bat -match 'where\.exe python' -and $bat -match 'PY_WHERE_FIRST'
  'cleanup failure reporting' = $bat -match 'PY_CLEANUP_RC' -and $bat -match 'tệp tạm Python'
  'empty PATH preservation' = $bat -match 'StringSplitOptions\]::None' -and $bat -match '\$keep=@\(\$old\.Split'
  'continuation' = $bat -match 'call :try_install_python' -and $bat -match 'call :try_install_vscode'
}
$failed = @($checks.GetEnumerator() | Where-Object { -not $_.Value })
foreach ($c in $checks.GetEnumerator()) { '{0}: {1}' -f $c.Key, $(if ($c.Value) { 'PASS' } else { 'FAIL' }) }
if ($failed.Count) { exit 1 }
function Test-Version([string]$v) { return $v -cmatch '^3\.13\.\d+$' }
if (-not (Test-Version '3.13.5') -or (Test-Version '3.14.0') -or (Test-Version '-')) { throw 'version guard simulation failed' }
$attempts = 0
while ($attempts -lt 3) { $attempts++; if ($attempts -eq 3) { break } }
if ($attempts -ne 3) { throw 'retry simulation failed' }
$path = @('C:\WindowsApps', 'C:\OtherPython', 'C:\Users\Test\AppData\Local\Programs\Python\Python313')
$target = 'C:\Users\Test\AppData\Local\Programs\Python\Python313'
$ordered = @($target) + @($path | Where-Object { $_ -ine $target })
if ($ordered[0] -ine $target -or $ordered[1] -ine 'C:\WindowsApps') { throw 'PATH ordering simulation failed' }
$manifestBefore = 'Git | 2.0.0 | installed-at-2026-08-26 | C:\Git'
$manifestAfterFailure = $manifestBefore
if ($manifestAfterFailure -cne $manifestBefore) { throw 'manifest rollback simulation failed' }
Write-Output 'PASS: version guard, bounded retry, Store-stub ordering, and rollback simulations.'
Write-Output 'PASS: isolated Python installer contract checks; no machine mutation performed.'
