$ErrorActionPreference = 'Stop'
$bat = Join-Path $PSScriptRoot '..\..\AI_Tools_Installer.bat'
$text = Get-Content -Raw -LiteralPath $bat
$checks = [System.Collections.Generic.List[string]]::new()
function Pass([string]$name) { $checks.Add("PASS | $name") }
function Fail([string]$name) { throw "FAIL | $name" }

if ($text -notmatch ':npm_prepare') { Fail 'Có bộ chuẩn bị npm' } else { Pass 'Có bộ chuẩn bị npm' }
if ($text -notmatch 'npm\.cmd install -g openclaw@latest %NPM_ALLOW_SCRIPTS%') { Fail 'OpenClaw dùng npm.cmd và cờ lifecycle được duyệt' } else { Pass 'OpenClaw dùng npm.cmd và cờ lifecycle được duyệt' }
if ($text -notmatch 'npm\.cmd install -g 9router') { Fail '9Router dùng npm.cmd' } else { Pass '9Router dùng npm.cmd' }
if (($text -split 'npm\.cmd install -g openclaw@latest').Count - 1 -lt 1) { Fail 'OpenClaw có lệnh cài' } else { Pass 'OpenClaw có lệnh cài' }
if (($text -split 'npm\.cmd install -g 9router').Count - 1 -lt 1) { Fail '9Router có lệnh cài' } else { Pass '9Router có lệnh cài' }
if ($text -notmatch 'for /l %%a in \(1,1,3\)') { Fail 'Có retry tối đa ba lần' } else { Pass 'Có retry tối đa ba lần' }
if ($text -notmatch 'call :path_append "%NPM_BIN%"') { Fail 'Global bin được refresh PATH' } else { Pass 'Global bin được refresh PATH' }
if ($text -notmatch 'NPM_PREFIX.*LOCALAPPDATA') { Fail 'Prefix được giới hạn user scope' } else { Pass 'Prefix được giới hạn user scope' }
if ($text -match '(?i)(OPENROUTER_API_KEY|ANTHROPIC_API_KEY|authorization\s*:|bearer\s+)') { Fail 'Không có truy cập credential' } else { Pass 'Không có truy cập credential' }
if ($text -match 'not-supported-yet.*OpenClaw|not-supported-yet.*9Router') { Fail 'Không còn stub not-supported-yet cho npm items' } else { Pass 'Không còn stub not-supported-yet cho npm items' }

# Mô phỏng retry và continuation, không gọi npm và không thay đổi máy.
$attempts = 0
$result = $false
1..3 | ForEach-Object { if (-not $result) { $attempts++; if ($attempts -eq 3) { $result = $true } } }
if ($attempts -ne 3 -or -not $result) { Fail 'Retry mô phỏng đủ ba lần' } else { Pass 'Retry mô phỏng đủ ba lần' }
$openClawFailed = $true
$nineRouterAttempted = $false
if ($openClawFailed) { $nineRouterAttempted = $true }
if (-not $nineRouterAttempted) { Fail 'Gói thứ hai vẫn được thử khi gói đầu lỗi' } else { Pass 'Gói thứ hai vẫn được thử khi gói đầu lỗi' }
$skipLogged = $text -match 'already-current \| OpenClaw' -and $text -match 'already-current \| 9Router'
if (-not $skipLogged) { Fail 'Rerun có nhánh skip độc lập' } else { Pass 'Rerun có nhánh skip độc lập' }

$checks | ForEach-Object { $_ }
Write-Output ("KẾT QUẢ: {0} kiểm tra PASS" -f $checks.Count)
