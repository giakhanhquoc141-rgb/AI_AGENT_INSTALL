$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$bat = Join-Path $repo 'AI_Tools_Installer.bat'
$sandbox = Join-Path $env:TEMP ('aitools-uninstall-harness-' + [guid]::NewGuid().ToString('N'))
$managed = Join-Path $sandbox 'Programs\Git'
$outside = Join-Path $sandbox 'outside.txt'
$manifestRoot = Join-Path $sandbox 'AITools'
New-Item -ItemType Directory -Force -Path $managed,$manifestRoot | Out-Null
Set-Content -LiteralPath (Join-Path $managed 'git.exe') -Value 'managed' -Encoding UTF8
Set-Content -LiteralPath $outside -Value 'must-survive' -Encoding UTF8
$today = Get-Date -Format 'yyyy-MM-dd'
Set-Content -LiteralPath (Join-Path $manifestRoot 'manifest.txt') -Value @(
  "Git | 2.55.0.windows.5 | $today | %LOCALAPPDATA%\Programs\Git",
  "External sentinel | 1.0.0 | $today | $outside"
) -Encoding UTF8
$p = Start-Process -FilePath 'cmd.exe' -ArgumentList @('/d','/c',"set LOCALAPPDATA=$sandbox&& set UPDATE_API=http://127.0.0.1:9&& `"$bat`" --uninstall") -Wait -PassThru -WindowStyle Hidden
if ($p.ExitCode -ne 0) { throw "uninstall exited $($p.ExitCode)" }
if (Test-Path -LiteralPath $managed) { throw 'managed artifact remains' }
if (-not (Test-Path -LiteralPath $outside)) { throw 'external artifact was deleted' }
if (Test-Path -LiteralPath (Join-Path $manifestRoot 'manifest.txt')) { throw 'manifest remains' }
Write-Output 'PASS story-3-2 uninstall removes only managed artifacts and preserves external paths'
Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue
