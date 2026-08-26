@echo off
rem ============================================================
rem  AI Tools Installer - Phien ban 0.1.0
rem  Cau truc mot file, tu bao gom: [init] -> [helpers] -> [router]
rem  Dinh dang file: UTF-8 (khong BOM), xuat dong CRLF, chcp 65001
rem ============================================================

setlocal
chcp 65001 >nul

rem --------------------------- [init] ---------------------------
set "TOOL_NAME=AI Tools Installer"
set "TOOL_VERSION=0.1.0"
set "TOOL_SLOGAN=Cài bộ AI · Tự kiểm tra · Gỡ sạch"
set "TOOL_INTRO=Công cụ giúp bạn cài bộ AI vào máy trong một lần chạy — không cần kiến thức kỹ thuật."

goto :router

rem ========================= [helpers] ==========================

rem ------------------------------------------------------------
rem  Bật màu ANSI nếu console hỗ trợ. Nếu không hỗ trợ (hoặc
rem  đang chuyển hướng ra file/ống dẫn), màu tự giảm về mặc định
rem  — không bao giờ in mã màu thô ra màn hình.
rem ------------------------------------------------------------
:init_colors
set "ESC="
set "VT_OK="
for /f "delims=" %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
if not defined ESC goto :eof
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "try { Add-Type -TypeDefinition 'using System;using System.Runtime.InteropServices;public class VT{[DllImport(\"kernel32.dll\")]public static extern IntPtr GetStdHandle(int n);[DllImport(\"kernel32.dll\",SetLastError=true)]public static extern bool GetConsoleMode(IntPtr h,out uint m);[DllImport(\"kernel32.dll\",SetLastError=true)]public static extern bool SetConsoleMode(IntPtr h,uint m);}'; $h=[VT]::GetStdHandle(-11); $m=0; if(-not [VT]::GetConsoleMode($h,[ref]$m)){exit 1}; if(-not [VT]::SetConsoleMode($h,($m -bor 4))){exit 1}; exit 0 } catch { exit 1 }" >nul 2>&1
if not errorlevel 1 set "VT_OK=1"
goto :eof

rem ------------------------------------------------------------
rem  In một dòng theo màu. %1 = mã SGR (kết thúc bằng "m"),
rem  %2 = nội dung. Nếu không có VT, in trắng mặc định.
rem ------------------------------------------------------------
:color_echo
if "%~2"=="" exit /b
setlocal
if defined VT_OK (
  echo %ESC%[%~1%~2%ESC%[0m
) else (
  echo %~2
)
endlocal
exit /b

rem ------------------------------------------------------------
rem  Ghi một dòng log tại %LOCALAPPDATA%\AITools\logs\
rem ------------------------------------------------------------
:log_append
setlocal EnableDelayedExpansion
if not defined LOCALAPPDATA set "LOCALAPPDATA=%TEMP%"
if not exist "%LOCALAPPDATA%\AITools\logs\" mkdir "%LOCALAPPDATA%\AITools\logs" 2>nul
set "LINE=%~1"
>>"%LOCALAPPDATA%\AITools\logs\ai-tools-installer.log" echo !LINE!
endlocal
exit /b

rem ------------------------------------------------------------
rem  Hợp đồng bước: %1 = tên bước, %2 = lệnh chạy.
rem  Ghi đúng một dòng log (ok/fail), thoát 0/nonzero.
rem ------------------------------------------------------------
:run_step
setlocal EnableDelayedExpansion
set "STEP=%~1"
set "CMD=%~2"
call %CMD%
set "RC=!errorlevel!"
if "!RC!"=="0" (
  call :log_append "!STEP! | ok | - | - | %date% %time%"
) else (
  call :log_append "!STEP! | fail | - | - | %date% %time%"
  set "FAIL_MSG=Đã xảy ra lỗi ở bước !STEP!. Công cụ thoát an toàn. Vui lòng chạy lại để thử lại."
  call :color_echo "1;31m" "!FAIL_MSG!"
)
endlocal & exit /b %RC%

rem ------------------------------------------------------------
rem  Dừng đợi một phím bất kỳ (không hiện dòng tiếng Anh).
rem ------------------------------------------------------------
:press_any_key
<nul set /p "=Bấm phím bất kỳ để tiếp tục... "
pause >nul 2>nul
echo.
exit /b

rem ------------------------------------------------------------
rem  PATH-controller: thêm một mục vào PATH người dùng.
rem  %1 = mục PATH dạng mở rộng (ví dụ %%LOCALAPPDATA%%\node).
rem  Đọc HKCU\Environment Path -> append-if-absent (không phân biệt
rem  hoa thường) -> ghi lại giữ REG_EXPAND_SZ -> refresh %PATH% trong
rem  phiên từ registry. Không setx, không cắt/truncate, không trùng.
rem ------------------------------------------------------------
:path_append
setlocal DisableDelayedExpansion
set "PA_ENTRY=%~1"
if not defined PA_ENTRY endlocal & exit /b 0
for /f "delims=" %%g in ('powershell -NoProfile -Command "[guid]::NewGuid().ToString('N')"') do set "PA_ID=%%g"
if not defined PA_ID endlocal & exit /b 1
set "PA_OUT=%TEMP%\aitools-path-%PA_ID%.txt"
if exist "%PA_OUT%" endlocal & exit /b 1
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ErrorActionPreference='Stop';$entry=$env:PA_ENTRY;$local=$env:LOCALAPPDATA;if([string]::IsNullOrWhiteSpace($entry)){exit 0};$prefix='%%LOCALAPPDATA%%';if($entry.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){$expanded=$local+$entry.Substring($prefix.Length);$store=$entry}elseif($entry.StartsWith($local,[StringComparison]::OrdinalIgnoreCase)){$expanded=$entry;$store=$prefix+$entry.Substring($local.Length)}else{$expanded=[Environment]::ExpandEnvironmentVariables($entry);$store=$entry};$key=[Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Environment');try{$exists=$true;try{$kind=$key.GetValueKind('Path');$old=$key.GetValue('Path','',[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)}catch{$exists=$false;$kind=[Microsoft.Win32.RegistryValueKind]::ExpandString;$old=''};$norm={param($v)([Environment]::ExpandEnvironmentVariables([string]$v)).Trim().TrimEnd('\')};$parts=if($exists){@(([string]$old).Split([char]';',[StringSplitOptions]::None))}else{@()};if(-not ($parts|?{$_ -ne '' -and (& $norm $_) -ieq (& $norm $store)})){$parts+=$store};$value=$parts -join ';';if($kind -eq [Microsoft.Win32.RegistryValueKind]::String){$value=[Environment]::ExpandEnvironmentVariables($value)}else{$kind=[Microsoft.Win32.RegistryValueKind]::ExpandString};$session=@(([string]$env:Path).Split([char]';',[StringSplitOptions]::None));if(-not ($session|?{$_ -ne '' -and (& $norm $_) -ieq (& $norm $expanded)})){$session=@($expanded)+$session};[IO.File]::WriteAllText($env:PA_OUT,($session -join ';'),[Text.UTF8Encoding]::new($false));$null=[IO.File]::ReadAllText($env:PA_OUT,[Text.Encoding]::UTF8);$key.SetValue('Path',$value,$kind)}finally{$key.Dispose()}" >nul 2>nul
if errorlevel 1 (
  if exist "%PA_OUT%" del /f /q "%PA_OUT%" >nul 2>nul
  endlocal & exit /b 1
)
if not exist "%PA_OUT%" endlocal & exit /b 1
for /f "usebackq delims=" %%p in ("%PA_OUT%") do set "PA_NEW_PATH=%%p"
del /f /q "%PA_OUT%" >nul 2>nul
if not defined PA_NEW_PATH endlocal & exit /b 1
endlocal & set "PATH=%PA_NEW_PATH%"
exit /b 0

rem ------------------------------------------------------------
rem  Ghi manifest %LOCALAPPDATA%\AITools\manifest.txt (append nếu
rem  chưa có dòng này). %1 = item, %2 = phiên bản, %3 = đường dẫn.
rem  Định dạng: item | version | installed-at-YYYY-MM-DD | path (AD-5).
rem ------------------------------------------------------------
:manifest_append
setlocal DisableDelayedExpansion
set "MA_ITEM=%~1"
set "MA_VER=%~2"
set "MA_PATH=%~3"
if not defined LOCALAPPDATA endlocal & exit /b 1
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ErrorActionPreference='Stop';$root=Join-Path $env:LOCALAPPDATA 'AITools';[IO.Directory]::CreateDirectory($root)|Out-Null;$file=Join-Path $root 'manifest.txt';$path=$env:MA_PATH;$local=$env:LOCALAPPDATA;if($path -ieq $local){$path='%%LOCALAPPDATA%%'}elseif($path.StartsWith($local+'\',[StringComparison]::OrdinalIgnoreCase)){$path='%%LOCALAPPDATA%%'+$path.Substring($local.Length)};$norm={param($v)([Environment]::ExpandEnvironmentVariables([string]$v)).Trim().TrimEnd('\')};if(Test-Path -LiteralPath $file){$found=[IO.File]::ReadLines($file)|?{$f=$_.Split(@(' | '),[StringSplitOptions]::None);$f.Count -ge 4 -and $f[0] -ieq $env:MA_ITEM -and $f[1] -ieq $env:MA_VER -and (& $norm $f[3]) -ieq (& $norm $path)}|Select-Object -First 1;if($found){exit 0}};$line=$env:MA_ITEM+' | '+$env:MA_VER+' | '+(Get-Date -Format yyyy-MM-dd)+' | '+$path+[Environment]::NewLine;[IO.File]::AppendAllText($file,$line,[Text.UTF8Encoding]::new($false))" >nul 2>nul
set "MA_RC=%errorlevel%"
endlocal & exit /b %MA_RC%

rem ========================= [router] ==========================

:router
call :init_colors
if /i "%~1"=="--uninstall" goto :stub_uninstall
if /i "%~1"=="--update"    goto :stub_update
if "%~1"==""               goto :run_install
goto :unknown_mode

rem --------------------------- install ---------------------------
:run_install
set "PIPELINE_RC=0"
set "PLAN_ABORT="
call :run_step "welcome" ":welcome_block"
if errorlevel 1 set "PIPELINE_RC=1"
call :scan_block
if errorlevel 1 set "PIPELINE_RC=1"
call :plan_block
if errorlevel 1 set "PIPELINE_RC=1"
if defined PLAN_ABORT goto :run_install_end
call :execute_block
if errorlevel 1 set "PIPELINE_RC=1"
:run_install_end
exit /b %PIPELINE_RC%

:welcome_block
call :color_echo "38;5;214m" "         *"
call :color_echo "38;5;214m" "        / \"
call :color_echo "38;5;214m" "       /   \"
call :color_echo "38;5;214m" "      /     \"
call :color_echo "38;5;214m" "     /       \"
call :color_echo "38;5;214m" "     *********"
call :color_echo "38;5;214m" "     \       /"
call :color_echo "38;5;214m" "      \     /"
call :color_echo "38;5;214m" "       \   /"
call :color_echo "38;5;214m" "        \ /"
call :color_echo "38;5;214m" "         *"
echo.
call :color_echo "1;97m" "      %TOOL_NAME%"
call :color_echo "1;97m" "     ────────────────────"
call :color_echo "2;90m" "   %TOOL_SLOGAN%"
call :color_echo "1;97m" "     Phiên bản %TOOL_VERSION%"
echo.
call :color_echo "1;97m" "   %TOOL_INTRO%"
echo.
call :press_any_key
exit /b 0

:scan_block
setlocal EnableDelayedExpansion
call :color_echo "1;97m" "Bước quét máy — kiểm tra 7 mục..."
echo.

rem --- PowerShell version-check: phát hiện, lấy bản mới nhất, quyết định (AD-2/AD-6) ---
set "S1=$ErrorActionPreference='SilentlyContinue';function P($s){[Console]::WriteLine($s)};function Sen($x){if($x -eq ''){return '-'};return $x};"
set "S2=function S3($v){$m=[regex]::Match([string]$v,'\d+\.\d+\.\d+');if($m.Success){return $m.Value};return ''};"
set "S3=function Cmp3($a,$b){$A=($a -split '\.');$B=($b -split '\.');for($i=0;$i -lt 3;$i++){$x=[int]$A[$i];$y=[int]$B[$i];if($x -gt $y){return 1};if($x -lt $y){return -1}};return 0};"
set "S4=function RetryC($cb){for($i=0;$i -lt 3;$i++){try{return (& $cb)}catch{if($i -ge 2){throw};Start-Sleep -Milliseconds 300}};throw 'retry-failed'};"
set "S5=function Cur($it){switch($it){'Git'{$c=Get-Command git -ErrorAction SilentlyContinue;if($null -eq $c){return ''};$o=(& git --version 2>$null)|Out-String;$m=[regex]::Match($o,'\d+\.\d+\.\d+(\.windows\.[0-9]+)?');if($m.Success){return $m.Value};return ''};'Node'{$c=Get-Command node -ErrorAction SilentlyContinue;if($null -eq $c){return ''};if($c.Source -match '(?i)openclaw'){return ''};$o=(& node --version 2>$null)|Out-String;return (S3 $o)};'Python'{$c=Get-Command python -ErrorAction SilentlyContinue;if($null -eq $c){return ''};$o=(& python --version 2>&1)|Out-String;$m=[regex]::Match($o,'Python\s+(\d+\.\d+(\.\d+)?)');if(-not $m.Success){return ''};return $m.Groups[1].Value};'VSCode'{$c=Get-Command code -ErrorAction SilentlyContinue;if($null -eq $c){return ''};$o=@(& code --version 2>$null);if($o.Count -ge 1){return ($o[0].Trim())};return ''};'VSCodeExt'{$c=Get-Command code -ErrorAction SilentlyContinue;if($null -eq $c){return ''};$o=@(& code --list-extensions --show-versions 2>$null);foreach($l in $o){if($l -match '(?i)anthropic\.claude-code'){$m=[regex]::Match($l,'@([0-9][^@ ]*)');if($m.Success){return $m.Groups[1].Value};return 'installed'}};return ''};'OpenClaw'{$c=Get-Command openclaw -ErrorAction SilentlyContinue;if($null -eq $c){return ''};$o=((& openclaw --version 2>$null)|Out-String).Trim();$t=@($o -split '\s+');if($t.Count -ge 2){return $t[1]};return $o};'9Router'{$c=Get-Command 9router -ErrorAction SilentlyContinue;if($null -eq $c){return ''};$o=(& 9router --version 2>$null)|Out-String;return (S3 $o)}};return ''};"
set "S6=function Latest($it){switch($it){'Git'{$d=RetryC {(Invoke-RestMethod -Uri 'https://api.github.com/repos/git-for-windows/git/releases/latest' -UseBasicParsing -ErrorAction Stop -TimeoutSec 15 -Headers @{'User-Agent'='AI-Tools-Installer'})};return ([string]$d.tag_name).TrimStart('v')};'Node'{$d=RetryC {(Invoke-RestMethod -Uri 'https://nodejs.org/dist/index.json' -UseBasicParsing -ErrorAction Stop -TimeoutSec 15)};$best='';foreach($e in @($d)){if($e.lts -eq $false){continue};$v=S3 $e.version;if($v -eq ''){continue};if((Cmp3 $v '22.22.3') -ge 0 -and (Cmp3 $v '23.0.0') -lt 0){}elseif((Cmp3 $v '24.15.0') -ge 0 -and (Cmp3 $v '25.0.0') -lt 0){}else{continue};if($best -eq '' -or (Cmp3 $v $best) -gt 0){$best=$v}};return $best};'Python'{$d=RetryC {(Invoke-RestMethod -Uri 'https://www.python.org/api/v2/downloads/release/' -UseBasicParsing -ErrorAction Stop -TimeoutSec 15)};$best='';foreach($e in @($d)){if($e.is_prerelease){continue};$v=S3 $e.name;if($v -notmatch '^3\.13\.'){continue};if($best -eq '' -or (Cmp3 $v $best) -gt 0){$best=$v}};return $best};'VSCode'{$d=RetryC {(Invoke-RestMethod -Uri 'https://api.github.com/repos/microsoft/vscode/releases/latest' -UseBasicParsing -ErrorAction Stop -TimeoutSec 15 -Headers @{'User-Agent'='AI-Tools-Installer'})};return ([string]$d.tag_name).TrimStart('v')};'OpenClaw'{$d=RetryC {(Invoke-RestMethod -Uri 'https://registry.npmjs.org/-/package/openclaw/dist-tags' -UseBasicParsing -ErrorAction Stop -TimeoutSec 15)};return ([string]$d.latest)};'9Router'{$d=RetryC {(Invoke-RestMethod -Uri 'https://registry.npmjs.org/-/package/9router/dist-tags' -UseBasicParsing -ErrorAction Stop -TimeoutSec 15)};return (S3 $d.latest)}};return ''};"
set "S7=function Decide($it,$cur,$lat){if($it -eq 'VSCodeExt'){if($cur -ne ''){return 'SKIP'};return 'INSTALL'};if($cur -eq ''){return 'INSTALL'};if($lat -eq ''){return 'SKIP'};if($it -eq 'OpenClaw'){if($cur.CompareTo($lat) -ge 0){return 'SKIP'};return 'UPDATE'};if($it -eq 'Git'){$gc=$cur -replace '\.windows\.','.';$gl=$lat -replace '\.windows\.','.';try{if(([version]$gc).CompareTo([version]$gl) -ge 0){return 'SKIP'};return 'UPDATE'}catch{return 'SKIP'}};$c=S3 $cur;$l=S3 $lat;if($c -eq '' -or $l -eq ''){return 'SKIP'};if((Cmp3 $c $l) -ge 0){return 'SKIP'};return 'UPDATE'};"
set "S8=[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$neterr=0;foreach($it in @('Git','Node','Python','VSCode','VSCodeExt','OpenClaw','9Router')){$cur='';try{$cur=Cur $it}catch{$cur=''};$lat='';if($it -ne 'VSCodeExt'){try{$lat=Latest $it}catch{$lat='';$neterr++}};$dec=Decide $it $cur $lat;P ('{0}|{1}|{2}|{3}' -f $it,(Sen $cur),(Sen $lat),$dec)};P ('NETERR|{0}' -f $neterr)"

set "PSCMD=powershell -NoProfile -ExecutionPolicy Bypass -Command "!S1!!S2!!S3!!S4!!S5!!S6!!S7!!S8!""
for /f "usebackq delims=" %%L in (`!PSCMD!`) do call :scan_parse "%%L"

set "SCAN_MISSING="
if not defined ST_Git set "SCAN_MISSING=1"
if not defined ST_Node set "SCAN_MISSING=1"
if not defined ST_Python set "SCAN_MISSING=1"
if not defined ST_VSCode set "SCAN_MISSING=1"
if not defined ST_VSCodeExt set "SCAN_MISSING=1"
if not defined ST_OpenClaw set "SCAN_MISSING=1"
if not defined ST_9Router set "SCAN_MISSING=1"
if defined SCAN_MISSING (
  call :color_echo "1;31m" "Không thể đọc kết quả quét máy. Công cụ thoát an toàn."
  call :log_append "scan | fail | - | - | %date% %time%"
  endlocal
  exit /b 1
)

echo.
call :color_echo "1;97m" "Kết quả quét:"
call :show_item "Git" "!ST_Git!" "!VR_Git!" "!VL_Git!" 1
call :show_item "Node.js" "!ST_Node!" "!VR_Node!" "!VL_Node!" 1
call :show_item "Python" "!ST_Python!" "!VR_Python!" "!VL_Python!" 1
call :show_item "Visual Studio Code" "!ST_VSCode!" "!VR_VSCode!" "!VL_VSCode!" 1
call :show_item "Phần mở rộng Claude Code" "!ST_VSCodeExt!" "!VR_VSCodeExt!" "!VL_VSCodeExt!" 0
call :show_item "OpenClaw" "!ST_OpenClaw!" "!VR_OpenClaw!" "!VL_OpenClaw!" 1
call :show_item "9Router" "!ST_9Router!" "!VR_9Router!" "!VL_9Router!" 1

set "SCAN_LOG_VER=git=!VR_Git!;node=!VR_Node!;python=!VR_Python!;vscode=!VR_VSCode!;claude-code=!VR_VSCodeExt!;openclaw=!VR_OpenClaw!;9router=!VR_9Router!"
set "SCAN_RC=0"
if defined NET_ERR if not "!NET_ERR!"=="0" set "SCAN_RC=1"
if "!SCAN_RC!"=="1" (
  echo.
  call :color_echo "1;31m" "Không thể kết nối nguồn chính thức để kiểm tra phiên bản mới nhất."
  call :color_echo "2;90m" "Vui lòng kiểm tra kết nối mạng rồi chạy lại. Không có gì trên máy bị thay đổi."
  call :log_append "scan | fail | !SCAN_LOG_VER! | - | %date% %time%"
) else (
  call :log_append "scan | ok | !SCAN_LOG_VER! | - | %date% %time%"
)
endlocal & set "ST_Git=%ST_Git%" & set "VR_Git=%VR_Git%" & set "VL_Git=%VL_Git%" & set "ST_Node=%ST_Node%" & set "VR_Node=%VR_Node%" & set "VL_Node=%VL_Node%" & set "ST_Python=%ST_Python%" & set "VR_Python=%VR_Python%" & set "VL_Python=%VL_Python%" & set "ST_VSCode=%ST_VSCode%" & set "VR_VSCode=%VR_VSCode%" & set "VL_VSCode=%VL_VSCode%" & set "ST_VSCodeExt=%ST_VSCodeExt%" & set "VR_VSCodeExt=%VR_VSCodeExt%" & set "VL_VSCodeExt=%VL_VSCodeExt%" & set "ST_OpenClaw=%ST_OpenClaw%" & set "VR_OpenClaw=%VR_OpenClaw%" & set "VL_OpenClaw=%VL_OpenClaw%" & set "ST_9Router=%ST_9Router%" & set "VR_9Router=%VR_9Router%" & set "VL_9Router=%VL_9Router%" & set "NET_ERR=%NET_ERR%" & exit /b %SCAN_RC%

:scan_parse
for /f "tokens=1-4 delims=|" %%a in ("%~1") do (
  if /i "%%a"=="NETERR" (set "NET_ERR=%%b")
  if /i "%%a"=="Git" (set "ST_Git=%%d"&set "VR_Git=%%b"&set "VL_Git=%%c")
  if /i "%%a"=="Node" (set "ST_Node=%%d"&set "VR_Node=%%b"&set "VL_Node=%%c")
  if /i "%%a"=="Python" (set "ST_Python=%%d"&set "VR_Python=%%b"&set "VL_Python=%%c")
  if /i "%%a"=="VSCode" (set "ST_VSCode=%%d"&set "VR_VSCode=%%b"&set "VL_VSCode=%%c")
  if /i "%%a"=="VSCodeExt" (set "ST_VSCodeExt=%%d"&set "VR_VSCodeExt=%%b"&set "VL_VSCodeExt=%%c")
  if /i "%%a"=="OpenClaw" (set "ST_OpenClaw=%%d"&set "VR_OpenClaw=%%b"&set "VL_OpenClaw=%%c")
  if /i "%%a"=="9Router" (set "ST_9Router=%%d"&set "VR_9Router=%%b"&set "VL_9Router=%%c")
)
exit /b 0

:show_item
rem %1 = tên hiển thị, %2 = quyết định, %3 = phiên bản hiện tại, %4 = phiên bản mới nhất, %5 = có kiểm tra bản mới nhất (1/0)
setlocal EnableDelayedExpansion
set "NAME=%~1"
set "ST=%~2"
set "VR=%~3"
set "VL=%~4"
set "NO_LAT=%~5"
if /i "!ST!"=="INSTALL" (
  call :color_echo "1;97m" "  !NAME! — chưa cài — cần cài đặt"
) else if /i "!ST!"=="UPDATE" (
  call :color_echo "1;97m" "  !NAME! — đã cài !VR! — bản mới nhất !VL! — cần cập nhật"
) else if /i "!VR!"=="installed" (
  call :color_echo "2;90m" "  !NAME! — đã cài — bỏ qua"
) else if "!NO_LAT!"=="0" (
  call :color_echo "2;90m" "  !NAME! — đã cài !VR! — bỏ qua"
) else if "!VL!"=="-" (
  call :color_echo "2;90m" "  !NAME! — đã cài !VR! — chưa xác định được bản mới nhất — bỏ qua"
) else (
  call :color_echo "2;90m" "  !NAME! — đã cài !VR! — bản mới nhất !VL! — bỏ qua"
)
endlocal
exit /b 0

rem --------------------------- plan ---------------------------
:plan_block
setlocal EnableDelayedExpansion
rem --- Guard: cần đủ run-state scan (ST_*) mới lập kế hoạch ---
set "PLAN_MISSING="
if not defined ST_Git set "PLAN_MISSING=1"
if not defined ST_Node set "PLAN_MISSING=1"
if not defined ST_Python set "PLAN_MISSING=1"
if not defined ST_VSCode set "PLAN_MISSING=1"
if not defined ST_VSCodeExt set "PLAN_MISSING=1"
if not defined ST_OpenClaw set "PLAN_MISSING=1"
if not defined ST_9Router set "PLAN_MISSING=1"
if defined PLAN_MISSING (
  call :color_echo "1;31m" "Không đủ dữ liệu quét máy để lập kế hoạch. Công cụ thoát an toàn."
  call :log_append "plan | skip | insufficient-scan | - | %date% %time%"
  endlocal & set "PLAN_ABORT=1" & exit /b 0
)

call :color_echo "1;97m" "Bước 3/6 — Kế hoạch cài đặt — còn 3 bước"
call :color_echo "2;90m" "Chưa có gì thay đổi trên máy cho tới khi bạn xác nhận."
echo.

set "PLAN_INSTALL=0"
set "PLAN_UPDATE=0"
set "PLAN_SKIP=0"

call :plan_item "Git" "!ST_Git!" "!VR_Git!" "!VL_Git!"
call :plan_count "!ST_Git!"
call :plan_item "Node.js" "!ST_Node!" "!VR_Node!" "!VL_Node!"
call :plan_count "!ST_Node!"
call :plan_item "Python" "!ST_Python!" "!VR_Python!" "!VL_Python!"
call :plan_count "!ST_Python!"
call :plan_item "Visual Studio Code" "!ST_VSCode!" "!VR_VSCode!" "!VL_VSCode!"
call :plan_count "!ST_VSCode!"
call :plan_item "Phần mở rộng Claude Code" "!ST_VSCodeExt!" "!VR_VSCodeExt!" "!VL_VSCodeExt!"
call :plan_count "!ST_VSCodeExt!"
call :plan_item "OpenClaw" "!ST_OpenClaw!" "!VR_OpenClaw!" "!VL_OpenClaw!"
call :plan_count "!ST_OpenClaw!"
call :plan_item "9Router" "!ST_9Router!" "!VR_9Router!" "!VL_9Router!"
call :plan_count "!ST_9Router!"

echo.
call :color_echo "1;97m" "Tổng kết: !PLAN_INSTALL! cài mới · !PLAN_UPDATE! cập nhật · !PLAN_SKIP! bỏ qua"
echo.
call :color_echo "2;90m" "Bấm C để tiếp tục, H để hủy an toàn."
choice /c CH /n /m "  (C/H) "
if errorlevel 2 goto :plan_cancel
call :color_echo "1;32m" "Đã xác nhận. Bắt đầu cài đặt..."
call :log_append "plan | ok | confirmed | - | %date% %time%"
endlocal & set "PLAN_ABORT=" & exit /b 0

:plan_cancel
call :color_echo "1;33m" "Đã hủy. Không có gì trên máy bị thay đổi."
call :color_echo "2;90m" "Bạn có thể chạy lại bất cứ lúc nào."
call :log_append "plan | skip | cancelled | - | %date% %time%"
endlocal & set "PLAN_ABORT=1" & exit /b 0

:plan_item
rem %1 = tên hiển thị, %2 = quyết định, %3 = phiên bản hiện tại, %4 = phiên bản mới nhất
setlocal EnableDelayedExpansion
set "PNAME=%~1"
set "PST=%~2"
set "PVR=%~3"
set "PVL=%~4"
if /i "!PST!"=="INSTALL" (
  if "!PVL!"=="-" (
    call :color_echo "1;97m" "  !PNAME! — cài mới"
  ) else (
    call :color_echo "1;97m" "  !PNAME! — cài mới — bản mới nhất !PVL!"
  )
) else if /i "!PST!"=="UPDATE" (
  if "!PVL!"=="-" (
    call :color_echo "1;97m" "  !PNAME! — cập nhật — !PVR!"
  ) else (
    call :color_echo "1;97m" "  !PNAME! — cập nhật — !PVR! sang !PVL!"
  )
) else if /i "!PVR!"=="installed" (
  call :color_echo "2;90m" "  !PNAME! — bỏ qua — đã cài"
) else (
  call :color_echo "2;90m" "  !PNAME! — bỏ qua — đã cài !PVR!"
)
endlocal
exit /b 0

:plan_count
if /i "%~1"=="INSTALL" set /a PLAN_INSTALL+=1
if /i "%~1"=="UPDATE" set /a PLAN_UPDATE+=1
if /i "%~1"=="SKIP" set /a PLAN_SKIP+=1
exit /b 0

rem --------------------------- execute ---------------------------
:execute_block
set "EXEC_RC=0"
call :color_echo "1;97m" "Bước 4/6 — Cài đặt — còn 2 bước"
echo.
call :color_echo "2;90m" "Đang cài đặt các mục trong kế hoạch..."
echo.
call :try_install_node
if errorlevel 1 set "EXEC_RC=1"
call :try_install_git
if errorlevel 1 set "EXEC_RC=1"
call :try_install_python
if errorlevel 1 set "EXEC_RC=1"
call :try_install_vscode
if errorlevel 1 set "EXEC_RC=1"
call :try_install_vscodeext
if errorlevel 1 set "EXEC_RC=1"
call :try_install_openclaw
if errorlevel 1 set "EXEC_RC=1"
call :try_install_9router
if errorlevel 1 set "EXEC_RC=1"
echo.
if "%EXEC_RC%"=="0" (
  call :color_echo "1;32m" "Bước cài đặt hoàn tất."
) else (
  call :color_echo "1;31m" "Bước cài đặt có lỗi ở một hoặc nhiều mục. Xem log để biết chi tiết."
)
exit /b %EXEC_RC%

:try_install_node
if /i "%ST_Node%"=="INSTALL" goto :try_install_node_run
if /i "%ST_Node%"=="UPDATE" goto :try_install_node_run
call :color_echo "2;90m" "  Node.js — đã có sẵn — bỏ qua"
call :log_append "install | skip | already-current | Node | %date% %time%"
exit /b 0
:try_install_node_run
call :color_echo "1;97m" "  Node.js — đang cài đặt..."
call :install_node
exit /b %errorlevel%

:try_install_git
if /i "%ST_Git%"=="INSTALL" goto :try_install_git_run
if /i "%ST_Git%"=="UPDATE" goto :try_install_git_run
call :color_echo "2;90m" "  Git — đã có sẵn — bỏ qua"
call :log_append "install | skip | already-current | Git | %date% %time%"
exit /b 0
:try_install_git_run
call :color_echo "1;97m" "  Git — đang cài đặt..."
call :install_git
exit /b %errorlevel%

:try_install_python
if /i "%ST_Python%"=="INSTALL" goto :try_install_python_run
if /i "%ST_Python%"=="UPDATE" goto :try_install_python_run
call :color_echo "2;90m" "  Python — đã có sẵn — bỏ qua"
call :log_append "install | skip | already-current | Python | %date% %time%"
exit /b 0
:try_install_python_run
call :color_echo "1;97m" "  Python — đang cài đặt..."
call :install_python
exit /b %errorlevel%
:try_install_vscode
if /i "%ST_VSCode%"=="INSTALL" goto :try_install_vscode_run
if /i "%ST_VSCode%"=="UPDATE" goto :try_install_vscode_run
call :color_echo "2;90m" "  Visual Studio Code — đã có sẵn — bỏ qua"
call :log_append "install | skip | already-current | VSCode | %date% %time%"
exit /b 0
:try_install_vscode_run
call :color_echo "1;97m" "  Visual Studio Code — đang cài đặt..."
call :install_vscode
exit /b %errorlevel%
:try_install_vscodeext
if /i "%ST_VSCodeExt%"=="INSTALL" goto :try_install_vscodeext_run
if /i "%ST_VSCodeExt%"=="UPDATE" goto :try_install_vscodeext_run
call :color_echo "2;90m" "  Claude Code — đã có sẵn — bỏ qua"
call :log_append "install | skip | already-current | VSCodeExt | %date% %time%"
exit /b 0
:try_install_vscodeext_run
call :color_echo "1;97m" "  Claude Code — đang cài đặt..."
call :install_vscodeext
exit /b %errorlevel%
:try_install_openclaw
if /i "%ST_OpenClaw%"=="INSTALL" goto :try_install_openclaw_run
if /i "%ST_OpenClaw%"=="UPDATE" goto :try_install_openclaw_run
call :color_echo "2;90m" "  OpenClaw — đã có sẵn — bỏ qua"
call :log_append "install | skip | already-current | OpenClaw | %date% %time%"
exit /b 0
:try_install_openclaw_run
call :color_echo "1;97m" "  OpenClaw — đang cài đặt qua npm..."
call :npm_install_openclaw
exit /b %errorlevel%
:try_install_9router
if /i "%ST_9Router%"=="INSTALL" goto :try_install_9router_run
if /i "%ST_9Router%"=="UPDATE" goto :try_install_9router_run
call :color_echo "2;90m" "  9Router — đã có sẵn — bỏ qua"
call :log_append "install | skip | already-current | 9Router | %date% %time%"
exit /b 0
:try_install_9router_run
call :color_echo "1;97m" "  9Router — đang cài đặt qua npm..."
call :npm_install_9router
exit /b %errorlevel%

:try_install_stub
exit /b 0

rem ---------------------- npm package installers -------------------
rem Chuẩn bị npm.cmd từ PATH hiện tại, kiểm tra nguồn per-user, rồi
rem xác định global prefix/bin và refresh PATH trong phiên. Không ghi log.
:npm_prepare
set "NPM_CMD="
set "NPM_SOURCE="
set "NPM_PREFIX="
set "NPM_BIN="
set "NPM_VERSION="
for /f "delims=" %%p in ('where npm.cmd 2^>nul') do if not defined NPM_SOURCE set "NPM_SOURCE=%%p"
if not defined NPM_SOURCE exit /b 1
if not defined LOCALAPPDATA exit /b 1
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=[IO.Path]::GetFullPath($env:NPM_SOURCE);$u=[IO.Path]::GetFullPath($env:LOCALAPPDATA);$a=[IO.Path]::GetFullPath($env:APPDATA);if($p.StartsWith($u+'\\',[StringComparison]::OrdinalIgnoreCase) -or ($a -and $p.StartsWith($a+'\\',[StringComparison]::OrdinalIgnoreCase))){exit 0};exit 1" >nul 2>nul
if errorlevel 1 exit /b 1
set "NPM_CMD=npm.cmd"
for /f "delims=" %%p in ('npm.cmd prefix -g 2^>nul') do if not defined NPM_PREFIX set "NPM_PREFIX=%%p"
if not defined NPM_PREFIX exit /b 1
for /f "delims=" %%p in ('npm.cmd bin -g 2^>nul') do if not defined NPM_BIN set "NPM_BIN=%%p"
if not defined NPM_BIN set "NPM_BIN=%NPM_PREFIX%"
for /f "delims=" %%p in ("%NPM_PREFIX%") do set "NPM_PREFIX=%%p"
for /f "delims=" %%p in ("%NPM_BIN%") do set "NPM_BIN=%%p"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=[IO.Path]::GetFullPath($env:NPM_PREFIX);$u=[IO.Path]::GetFullPath($env:LOCALAPPDATA);$a=[IO.Path]::GetFullPath($env:APPDATA);if($p.StartsWith($u+'\\',[StringComparison]::OrdinalIgnoreCase) -or ($a -and $p.StartsWith($a+'\\',[StringComparison]::OrdinalIgnoreCase))){exit 0};exit 1" >nul 2>nul
if errorlevel 1 exit /b 1
call :path_append "%NPM_BIN%"
if errorlevel 1 exit /b 1
for /f "delims=" %%v in ('npm.cmd --version 2^>nul') do if not defined NPM_VERSION set "NPM_VERSION=%%v"
if not defined NPM_VERSION exit /b 1
exit /b 0

:npm_install_openclaw
set "NPM_RESULT_VERSION="
set "NPM_RESULT_RC=1"
call :npm_prepare
if errorlevel 1 goto :npm_openclaw_fail
set "NPM_ALLOW_SCRIPTS="
for /f "tokens=1 delims=." %%m in ("%NPM_VERSION%") do set "NPM_MAJOR=%%m"
if defined NPM_MAJOR powershell -NoProfile -ExecutionPolicy Bypass -Command "if([int]$env:NPM_MAJOR -ge 12){exit 0}else{exit 1}" >nul 2>nul
if not errorlevel 1 set "NPM_ALLOW_SCRIPTS=--allow-scripts openclaw"
if "%NPM_MAJOR%"=="12" if not defined NPM_ALLOW_SCRIPTS goto :npm_openclaw_fail
for /l %%a in (1,1,3) do (
  if "%NPM_ALLOW_SCRIPTS%"=="" (npm.cmd install -g openclaw@latest >nul 2>nul) else (npm.cmd install -g openclaw@latest %NPM_ALLOW_SCRIPTS% >nul 2>nul)
  if not errorlevel 1 goto :npm_openclaw_verify
)
goto :npm_openclaw_fail
:npm_openclaw_verify
for /f "tokens=1,2" %%a in ('openclaw --version 2^>nul') do if not defined NPM_RESULT_VERSION set "NPM_RESULT_VERSION=%%b"
if not defined NPM_RESULT_VERSION for /f "delims=" %%a in ('openclaw --version 2^>nul') do if not defined NPM_RESULT_VERSION set "NPM_RESULT_VERSION=%%a"
if not defined NPM_RESULT_VERSION goto :npm_openclaw_fail
where openclaw >nul 2>nul
if errorlevel 1 goto :npm_openclaw_fail
cmd /d /c "openclaw --version" >nul 2>nul
if errorlevel 1 goto :npm_openclaw_fail
call :manifest_append "OpenClaw" "%NPM_RESULT_VERSION%" "%NPM_BIN%"
if errorlevel 1 goto :npm_openclaw_fail
call :log_append "install | ok | %NPM_RESULT_VERSION% | OpenClaw | %date% %time%"
call :color_echo "1;32m" "  OpenClaw %NPM_RESULT_VERSION% đã cài xong."
exit /b 0
:npm_openclaw_fail
call :color_echo "1;31m" "  Cài OpenClaw thất bại. Kiểm tra Node/npm và chạy lại; 9Router vẫn được thử độc lập."
call :log_append "install | fail | npm | OpenClaw | %date% %time%"
exit /b 1

:npm_install_9router
set "NPM_RESULT_VERSION="
call :npm_prepare
if errorlevel 1 goto :npm_9router_fail
for /l %%a in (1,1,3) do (
  npm.cmd install -g 9router >nul 2>nul
  if not errorlevel 1 goto :npm_9router_verify
)
goto :npm_9router_fail
:npm_9router_verify
for /f "delims=" %%a in ('9router --version 2^>nul') do if not defined NPM_RESULT_VERSION set "NPM_RESULT_VERSION=%%a"
if not defined NPM_RESULT_VERSION goto :npm_9router_fail
for /f "delims=" %%a in ('powershell -NoProfile -Command "$m=[regex]::Match($env:NPM_RESULT_VERSION, '\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?');if($m.Success){$m.Value}"') do set "NPM_RESULT_VERSION=%%a"
if not defined NPM_RESULT_VERSION goto :npm_9router_fail
where 9router >nul 2>nul
if errorlevel 1 goto :npm_9router_fail
cmd /d /c "9router --version" >nul 2>nul
if errorlevel 1 goto :npm_9router_fail
call :manifest_append "9Router" "%NPM_RESULT_VERSION%" "%NPM_BIN%"
if errorlevel 1 goto :npm_9router_fail
call :log_append "install | ok | %NPM_RESULT_VERSION% | 9Router | %date% %time%"
call :color_echo "1;32m" "  9Router %NPM_RESULT_VERSION% đã cài xong."
exit /b 0
:npm_9router_fail
call :color_echo "1;31m" "  Cài 9Router thất bại. Kiểm tra Node/npm rồi chạy lại."
call :log_append "install | fail | npm | 9Router | %date% %time%"
exit /b 1

:install_vscode
rem --- VS Code User Setup x64, per-user only; installer must not auto-run ---
if not defined LOCALAPPDATA goto :ivsc_unknown
set "VSCODE_DIR=%LOCALAPPDATA%\Programs\Microsoft VS Code"
set "VSCODE_CODE=%VSCODE_DIR%\bin\code.cmd"
set "VSCODE_URL=https://update.code.visualstudio.com/latest/win32-x64-user/stable"
for /f "delims=" %%g in ('powershell -NoProfile -Command "[guid]::NewGuid().ToString('N')"') do set "VSCODE_TX_ID=%%g"
if not defined VSCODE_TX_ID goto :ivsc_backup_fail
set "VSCODE_INSTALLER=%TEMP%\aitools-vscode-user-%VSCODE_TX_ID%.exe"
set "VSCODE_BACKUP=%TEMP%\aitools-vscode-backup-%VSCODE_TX_ID%"
set "VSCODE_MANIFEST=%LOCALAPPDATA%\AITools\manifest.txt"
set "VSCODE_MANIFEST_BACKUP=%TEMP%\aitools-vscode-manifest-%VSCODE_TX_ID%.bak"
set "VSCODE_PATH_STATE=%TEMP%\aitools-vscode-path-%VSCODE_TX_ID%.xml"
set "VSCODE_OLD_PATH=%PATH%"
set "VSCODE_HAD_OLD=0"
if exist "%VSCODE_INSTALLER%" goto :ivsc_backup_fail
if exist "%VSCODE_BACKUP%\" goto :ivsc_backup_fail
if exist "%VSCODE_MANIFEST_BACKUP%" goto :ivsc_backup_fail
if exist "%VSCODE_PATH_STATE%" goto :ivsc_backup_fail
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$k=[Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment');try{if($null -eq $k){[pscustomobject]@{Exists=$false;Value='';Kind='ExpandString'}|Export-Clixml -LiteralPath $env:VSCODE_PATH_STATE}else{[pscustomobject]@{Exists=$true;Value=[string]$k.GetValue('Path','',[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames);Kind=$k.GetValueKind('Path').ToString()}|Export-Clixml -LiteralPath $env:VSCODE_PATH_STATE}}finally{if($k){$k.Dispose()}}" >nul 2>nul
if errorlevel 1 goto :ivsc_backup_fail
if exist "%VSCODE_DIR%\" (
  move /y "%VSCODE_DIR%" "%VSCODE_BACKUP%" >nul 2>nul
  if errorlevel 1 goto :ivsc_backup_fail
  set "VSCODE_HAD_OLD=1"
)
if exist "%VSCODE_MANIFEST%" (
  copy /b /y "%VSCODE_MANIFEST%" "%VSCODE_MANIFEST_BACKUP%" >nul 2>nul
  if errorlevel 1 goto :ivsc_backup_fail
  if not exist "%VSCODE_MANIFEST_BACKUP%" goto :ivsc_backup_fail
)
call :vscode_download
if errorlevel 1 goto :ivsc_package_fail
call :vscode_signature
if errorlevel 1 goto :ivsc_package_fail
rem Inno Setup User Setup flags: no UAC/all-users and suppress auto-run.
start "" /wait "%VSCODE_INSTALLER%" /VERYSILENT /NORESTART /MERGETASKS=!runcode >nul 2>nul
if errorlevel 1 goto :ivsc_install_fail
if not exist "%VSCODE_CODE%" goto :ivsc_verify_fail
call :path_append "%%LOCALAPPDATA%%\Programs\Microsoft VS Code\bin"
if errorlevel 1 goto :ivsc_path_fail
set "VSCODE_VERSION="
for /f "delims=" %%v in ('"%VSCODE_CODE%" --version 2^>nul') do if not defined VSCODE_VERSION set "VSCODE_VERSION=%%v"
if not defined VSCODE_VERSION goto :ivsc_verify_fail
call :manifest_append "VSCode" "%VSCODE_VERSION%" "%VSCODE_DIR%"
if errorlevel 1 goto :ivsc_manifest_fail
set "VSCODE_ROLLBACK_RC=0"
call :ivsc_cleanup
if errorlevel 1 exit /b 1
call :log_append "install | ok | %VSCODE_VERSION% | VSCode | %date% %time%"
call :color_echo "1;32m" "  Visual Studio Code đã cài xong (User Setup)."
exit /b 0

:vscode_download
for /l %%r in (1,1,3) do (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;Invoke-WebRequest -Uri $env:VSCODE_URL -OutFile $env:VSCODE_INSTALLER -UseBasicParsing" >nul 2>nul
  if not errorlevel 1 if exist "%VSCODE_INSTALLER%" exit /b 0
  if exist "%VSCODE_INSTALLER%" del /f /q "%VSCODE_INSTALLER%" >nul 2>nul
)
exit /b 1

:vscode_signature
rem Signature validation is mandatory when Authenticode is available.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$c=Get-Command Get-AuthenticodeSignature -ErrorAction SilentlyContinue;if($null -eq $c){exit 0};$s=Get-AuthenticodeSignature -LiteralPath $env:VSCODE_INSTALLER;if($s.Status -ne 'Valid' -or $s.SignerCertificate.Subject -notmatch 'Microsoft Corporation'){exit 1};exit 0" >nul 2>nul
exit /b %errorlevel%

:ivsc_unknown
call :color_echo "1;31m" "  Không xác định được thư mục dữ liệu người dùng. Bỏ qua VS Code."
call :log_append "install | fail | unknown-user-target | VSCode | %date% %time%"
exit /b 1
:ivsc_backup_fail
call :color_echo "1;31m" "  Không thể sao lưu VS Code hiện có; không thay đổi gì trên máy."
call :ivsc_rollback
call :log_append "install | fail | backup-failed | VSCode | %date% %time%"
exit /b 1
:ivsc_package_fail
call :color_echo "1;31m" "  Tải hoặc xác minh bộ cài VS Code thất bại sau 3 lần thử. Kiểm tra kết nối rồi chạy lại."
call :ivsc_rollback
call :log_append "install | fail | download-or-signature-failed | VSCode | %date% %time%"
exit /b 1
:ivsc_install_fail
call :color_echo "1;31m" "  Bộ cài VS Code không hoàn tất. Bản hiện có được phục hồi."
call :ivsc_rollback
call :log_append "install | fail | installer-failed | VSCode | %date% %time%"
exit /b 1
:ivsc_verify_fail
call :color_echo "1;31m" "  VS Code chưa sẵn sàng hoặc có thể cần User Setup không yêu cầu quản trị."
call :ivsc_rollback
call :log_append "install | fail | verify-failed | VSCode | %date% %time%"
exit /b 1
:ivsc_path_fail
call :ivsc_rollback
call :log_append "install | fail | path-write-failed | VSCode | %date% %time%"
exit /b 1
:ivsc_manifest_fail
call :ivsc_rollback
call :log_append "install | fail | manifest-write-failed | VSCode | %date% %time%"
exit /b 1
:ivsc_rollback
set "VSCODE_ROLLBACK_RC=0"
set "PATH=%VSCODE_OLD_PATH%"
if exist "%VSCODE_PATH_STATE%" powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$s=Import-Clixml -LiteralPath $env:VSCODE_PATH_STATE;$k=[Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Environment');try{if($s.Exists){$k.SetValue('Path',[string]$s.Value,[Microsoft.Win32.RegistryValueKind]::$($s.Kind))}else{$k.DeleteValue('Path',$false)}}finally{$k.Dispose()}" >nul 2>nul
if errorlevel 1 set "VSCODE_ROLLBACK_RC=1"
if "%VSCODE_HAD_OLD%"=="1" (
  if exist "%VSCODE_BACKUP%\" (
    if exist "%VSCODE_DIR%\" rmdir /s /q "%VSCODE_DIR%" >nul 2>nul
    move /y "%VSCODE_BACKUP%" "%VSCODE_DIR%" >nul 2>nul
    if errorlevel 1 set "VSCODE_ROLLBACK_RC=1"
  ) else set "VSCODE_ROLLBACK_RC=1"
) else if exist "%VSCODE_DIR%\" (
  rmdir /s /q "%VSCODE_DIR%" >nul 2>nul
  if exist "%VSCODE_DIR%\" set "VSCODE_ROLLBACK_RC=1"
)
if "%VSCODE_HAD_OLD%"=="0" if not exist "%VSCODE_MANIFEST_BACKUP%" if exist "%VSCODE_MANIFEST%" del /f /q "%VSCODE_MANIFEST%" >nul 2>nul
if exist "%VSCODE_MANIFEST_BACKUP%" (
  copy /b /y "%VSCODE_MANIFEST_BACKUP%" "%VSCODE_MANIFEST%" >nul 2>nul
  if errorlevel 1 set "VSCODE_ROLLBACK_RC=1"
)
call :ivsc_cleanup
if errorlevel 1 set "VSCODE_ROLLBACK_RC=1"
if "%VSCODE_ROLLBACK_RC%"=="1" call :color_echo "1;31m" "  Phục hồi VS Code chưa hoàn tất; tệp sao lưu được giữ lại để khôi phục thủ công."
exit /b %VSCODE_ROLLBACK_RC%
:ivsc_cleanup
set "VSCODE_CLEANUP_RC=0"
if exist "%VSCODE_INSTALLER%" del /f /q "%VSCODE_INSTALLER%" >nul 2>nul
if exist "%VSCODE_INSTALLER%" set "VSCODE_CLEANUP_RC=1"
if "%VSCODE_ROLLBACK_RC%"=="0" if exist "%VSCODE_MANIFEST_BACKUP%" del /f /q "%VSCODE_MANIFEST_BACKUP%" >nul 2>nul
if "%VSCODE_ROLLBACK_RC%"=="0" if exist "%VSCODE_PATH_STATE%" del /f /q "%VSCODE_PATH_STATE%" >nul 2>nul
if "%VSCODE_ROLLBACK_RC%"=="0" if exist "%VSCODE_BACKUP%\" rmdir /s /q "%VSCODE_BACKUP%" >nul 2>nul
if "%VSCODE_ROLLBACK_RC%"=="0" if exist "%VSCODE_MANIFEST_BACKUP%" set "VSCODE_CLEANUP_RC=1"
if "%VSCODE_ROLLBACK_RC%"=="0" if exist "%VSCODE_PATH_STATE%" set "VSCODE_CLEANUP_RC=1"
if "%VSCODE_ROLLBACK_RC%"=="0" if exist "%VSCODE_BACKUP%\" set "VSCODE_CLEANUP_RC=1"
exit /b %VSCODE_CLEANUP_RC%

:install_vscodeext
if not defined LOCALAPPDATA goto :ivse_missing
set "VSCODE_DIR=%LOCALAPPDATA%\Programs\Microsoft VS Code"
set "VSCODE_CODE=%LOCALAPPDATA%\Programs\Microsoft VS Code\bin\code.cmd"
if not exist "%VSCODE_CODE%" goto :ivse_missing
set "VSCODE_EXT_OLD_PATH=%PATH%"
set "PATH=%VSCODE_DIR%\bin;%PATH%"
"%VSCODE_CODE%" --install-extension anthropic.claude-code --force >nul 2>nul
if errorlevel 1 goto :ivse_fail
set "VSCODE_EXT_FOUND="
for /f "delims=" %%e in ('"%VSCODE_CODE%" --list-extensions 2^>nul') do if /i "%%e"=="anthropic.claude-code" set "VSCODE_EXT_FOUND=1"
if not defined VSCODE_EXT_FOUND goto :ivse_fail
call :manifest_append "VSCodeExt" "installed" "%USERPROFILE%\.vscode\extensions\anthropic.claude-code"
if errorlevel 1 goto :ivse_fail
call :log_append "install | ok | installed | VSCodeExt | %date% %time%"
call :color_echo "1;32m" "  Claude Code đã cài xong."
exit /b 0
:ivse_missing
call :color_echo "1;31m" "  Không tìm thấy VS Code; Claude Code sẽ được thử lại ở lần chạy sau."
:ivse_fail
set "PATH=%VSCODE_EXT_OLD_PATH%"
call :log_append "install | fail | extension-verify-failed | VSCodeExt | %date% %time%"
exit /b 1

:install_python
if not defined LOCALAPPDATA goto :ipy_unknown
if "%VL_Python%"=="" goto :ipy_unknown
if "%VL_Python%"=="-" goto :ipy_unknown
powershell -NoProfile -Command "if('%VL_Python%' -cmatch '^3\.13\.\d+$'){exit 0}else{exit 1}" >nul 2>nul
if errorlevel 1 goto :ipy_invalid
set "PY_VER=%VL_Python%"
set "PY_DIR=%LOCALAPPDATA%\Programs\Python\Python313"
set "PY_EXE=%PY_DIR%\python.exe"
set "PY_URL=https://www.python.org/ftp/python/%PY_VER%/python-%PY_VER%-amd64.exe"
set "PY_TX_ID="
for /f "delims=" %%g in ('powershell -NoProfile -Command "[guid]::NewGuid().ToString('N')"') do set "PY_TX_ID=%%g"
if not defined PY_TX_ID goto :ipy_prepare_fail
set "PY_INSTALLER=%TEMP%\python-%PY_VER%-%PY_TX_ID%-amd64.exe"
set "PY_PATH_STATE=%TEMP%\aitools-python-path-%PY_TX_ID%.xml"
set "PY_MANIFEST_BACKUP=%TEMP%\aitools-python-manifest-%PY_TX_ID%.bak"
set "PY_BACKUP=%LOCALAPPDATA%\Programs\Python\Python313.aitools-backup-%PY_TX_ID%"
set "PY_MANIFEST=%LOCALAPPDATA%\AITools\manifest.txt"
set "PY_OLD_PATH=%PATH%"
set "PY_HAD_MANIFEST=0"
set "PY_HAD_OLD=0"
set "PY_BACKUP_READY=0"
set "PY_WHERE_FIRST="
if exist "%PY_INSTALLER%" goto :ipy_prepare_fail
if exist "%PY_PATH_STATE%" goto :ipy_prepare_fail
if exist "%PY_MANIFEST_BACKUP%" goto :ipy_prepare_fail
echo.
if /i not "%PROCESSOR_ARCHITECTURE%"=="AMD64" if /i not "%PROCESSOR_ARCHITEW6432%"=="AMD64" goto :ipy_32bit
call :color_echo "1;97m" "  Đang tải Python %PY_VER% từ nguồn chính thức..."
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue';$ok=$false;for($i=1;$i -le 3;$i++){try{if(Test-Path -LiteralPath $env:PY_INSTALLER){Remove-Item -LiteralPath $env:PY_INSTALLER -Force};Invoke-WebRequest -Uri $env:PY_URL -OutFile $env:PY_INSTALLER -UseBasicParsing -TimeoutSec 120;if((Get-Item -LiteralPath $env:PY_INSTALLER).Length -le 0){throw 'empty'};$sig=Get-AuthenticodeSignature -LiteralPath $env:PY_INSTALLER;if($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notmatch '(?i)Python Software Foundation'){throw 'signature'};$ok=$true;break}catch{if(Test-Path -LiteralPath $env:PY_INSTALLER){Remove-Item -LiteralPath $env:PY_INSTALLER -Force -ErrorAction SilentlyContinue};if($i -lt 3){Start-Sleep -Milliseconds 500}}};if(-not $ok){exit 1}" >nul 2>nul
if errorlevel 1 goto :ipy_package_fail
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$k=[Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment');try{if($null -eq $k){$s=[pscustomobject]@{Exists=$false;Value='';Kind='ExpandString'}}else{try{$s=[pscustomobject]@{Exists=$true;Value=[string]$k.GetValue('Path','',[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames);Kind=$k.GetValueKind('Path').ToString()}}catch{$s=[pscustomobject]@{Exists=$false;Value='';Kind='ExpandString'}}};$s|Export-Clixml -LiteralPath $env:PY_PATH_STATE}finally{if($k){$k.Dispose()}}" >nul 2>nul
if errorlevel 1 goto :ipy_prepare_fail
if exist "%PY_MANIFEST%" (copy /b /y "%PY_MANIFEST%" "%PY_MANIFEST_BACKUP%" >nul 2>nul & if errorlevel 1 goto :ipy_prepare_fail & set "PY_HAD_MANIFEST=1")
if exist "%PY_DIR%" (
  set "PY_HAD_OLD=1"
  set "PY_BACKUP_READY=1"
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';if(Test-Path -LiteralPath $env:PY_BACKUP){throw 'collision'};Move-Item -LiteralPath $env:PY_DIR -Destination $env:PY_BACKUP;if(-not (Test-Path -LiteralPath (Join-Path $env:PY_BACKUP 'python.exe'))){throw 'backup-incomplete'}" >nul 2>nul
  if errorlevel 1 goto :ipy_prepare_fail
)
call :color_echo "1;97m" "  Đã xác minh chữ ký. Đang cài Python cho tài khoản hiện tại..."
start "" /wait "%PY_INSTALLER%" InstallAllUsers=0 Include_launcher=0 PrependPath=0 Shortcuts=0 Include_test=0 /quiet /norestart
if errorlevel 1 goto :ipy_install_fail
call :path_append "%%LOCALAPPDATA%%\Programs\Python\Python313"
if errorlevel 1 goto :ipy_path_fail
call :path_append "%%LOCALAPPDATA%%\Programs\Python\Python313\Scripts"
if errorlevel 1 goto :ipy_path_fail
call :python_path_prioritize
if errorlevel 1 goto :ipy_path_fail
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$expected=(Get-Item -LiteralPath $env:PY_EXE -ErrorAction Stop).FullName;$v=(& $expected --version 2^>^&1|Out-String).Trim();if($LASTEXITCODE -ne 0 -or $v -notmatch ('^Python\s+'+[regex]::Escape($env:PY_VER)+'$')){exit 1};$cmd=(Get-Command python -CommandType Application -ErrorAction Stop).Source;if((Get-Item -LiteralPath $cmd).FullName -ine $expected){exit 1};$v=(& python --version 2^>^&1|Out-String).Trim();if($LASTEXITCODE -ne 0 -or $v -notmatch ('^Python\s+'+[regex]::Escape($env:PY_VER)+'$')){exit 1}" >nul 2>nul
if errorlevel 1 goto :ipy_verify_fail
for /f "delims=" %%w in ('where.exe python 2^>nul') do if not defined PY_WHERE_FIRST set "PY_WHERE_FIRST=%%w"
if not defined PY_WHERE_FIRST goto :ipy_verify_fail
if /i not "%PY_WHERE_FIRST%"=="%PY_EXE%" goto :ipy_verify_fail
call :manifest_append "Python" "%PY_VER%" "%PY_DIR%"
if errorlevel 1 goto :ipy_manifest_fail
call :log_append "install | ok | %PY_VER% | %PY_DIR% | %date% %time%"
call :ipy_cleanup
call :color_echo "1;32m" "  Python %PY_VER% đã cài xong."
exit /b 0

:python_path_prioritize
set "PY_PATH_OUT=%TEMP%\aitools-python-session-%PY_TX_ID%.txt"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$root=[Environment]::ExpandEnvironmentVariables('%%LOCALAPPDATA%%\Programs\Python\Python313');$scripts=Join-Path $root 'Scripts';$old='';$kind='ExpandString';$k=[Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment');try{if($null -ne $k){try{$kind=$k.GetValueKind('Path').ToString();$old=[string]$k.GetValue('Path','',[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)}catch{}}}finally{if($k){$k.Dispose()}};$n={param($v)([Environment]::ExpandEnvironmentVariables([string]$v)).Trim().TrimEnd('\')};$keep=@($old.Split([char]';',[StringSplitOptions]::None)|?{(& $n $_) -ine $root -and (& $n $_) -ine $scripts});$value=@('%%LOCALAPPDATA%%\Programs\Python\Python313','%%LOCALAPPDATA%%\Programs\Python\Python313\Scripts')+$keep;$k=[Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Environment');try{$k.SetValue('Path',($value -join ';'),[Microsoft.Win32.RegistryValueKind]::$kind)}finally{$k.Dispose()};$session=@($root,$scripts)+@($env:Path.Split([char]';',[StringSplitOptions]::None)|?{(& $n $_) -ine $root -and (& $n $_) -ine $scripts});[IO.File]::WriteAllText($env:PY_PATH_OUT,($session -join ';'),[Text.UTF8Encoding]::new($false))" >nul 2>nul
if errorlevel 1 exit /b 1
for /f "usebackq delims=" %%p in ("%PY_PATH_OUT%") do set "PY_NEW_PATH=%%p"
del /f /q "%PY_PATH_OUT%" >nul 2>nul
if not defined PY_NEW_PATH exit /b 1
set "PATH=%PY_NEW_PATH%"
exit /b 0

:ipy_invalid
call :color_echo "1;33m" "  Phiên bản Python cần cài không hợp lệ. Không tải tệp cài đặt."
call :log_append "install | skip | invalid-version | Python | %date% %time%"
exit /b 1
:ipy_unknown
call :color_echo "1;31m" "  Không xác định được phiên bản Python để cài. Chạy lại để thử lần nữa."
call :log_append "install | fail | unknown-version | Python | %date% %time%"
exit /b 1
:ipy_prepare_fail
call :color_echo "1;31m" "  Không tạo được vùng phục hồi an toàn cho Python. Bản hiện có được giữ nguyên."
call :log_append "install | fail | %PY_VER% | backup-failed | %date% %time%"
if "%PY_BACKUP_READY%"=="1" (
  call :ipy_rollback
  if not errorlevel 1 call :ipy_cleanup
) else call :ipy_cleanup
exit /b 1
:ipy_package_fail
call :color_echo "1;31m" "  Tải hoặc xác minh Python thất bại sau 3 lần thử. Kiểm tra kết nối rồi chạy lại."
call :log_append "install | fail | %PY_VER% | download-or-signature-failed | %date% %time%"
call :ipy_cleanup
exit /b 1
:ipy_install_fail
call :color_echo "1;31m" "  Trình cài Python không hoàn tất. Bản Python đang hoạt động được giữ nguyên."
call :log_append "install | fail | %PY_VER% | installer-failed | %date% %time%"
call :ipy_rollback
if not errorlevel 1 call :ipy_cleanup
exit /b 1
:ipy_path_fail
set "PY_FAIL_REASON=path-write-failed"
goto :ipy_rollback_fail
:ipy_verify_fail
set "PY_FAIL_REASON=verify-failed"
goto :ipy_rollback_fail
:ipy_manifest_fail
set "PY_FAIL_REASON=manifest-write-failed"
:ipy_rollback_fail
call :color_echo "1;31m" "  Python chưa vượt qua bước hoàn tất. Đang phục hồi PATH và hồ sơ cài đặt."
call :ipy_rollback
if errorlevel 1 (call :color_echo "1;31m" "  Phục hồi chưa hoàn tất; giữ lại tệp sao lưu để khôi phục thủ công." & call :log_append "install | fail | %PY_VER% | %PY_FAIL_REASON%-rollback-failed | %date% %time%") else (call :log_append "install | fail | %PY_VER% | %PY_FAIL_REASON% | %date% %time%" & call :ipy_cleanup)
exit /b 1
:ipy_rollback
set "PY_ROLLBACK_RC=0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$backupReady=$env:PY_BACKUP_READY -eq '1';$hadOld=$env:PY_HAD_OLD -eq '1';if($backupReady -and -not (Test-Path -LiteralPath (Join-Path $env:PY_BACKUP 'python.exe'))){throw 'backup-missing'};if($hadOld){if(Test-Path -LiteralPath $env:PY_DIR){Remove-Item -LiteralPath $env:PY_DIR -Recurse -Force};Move-Item -LiteralPath $env:PY_BACKUP -Destination $env:PY_DIR}else{if(Test-Path -LiteralPath $env:PY_DIR){Remove-Item -LiteralPath $env:PY_DIR -Recurse -Force}};if(Test-Path -LiteralPath $env:PY_BACKUP){Remove-Item -LiteralPath $env:PY_BACKUP -Recurse -Force};if(Test-Path -LiteralPath $env:PY_BACKUP){throw 'backup-cleanup-failed'}" >nul 2>nul
if errorlevel 1 set "PY_ROLLBACK_RC=1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$s=Import-Clixml -LiteralPath $env:PY_PATH_STATE;$k=[Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Environment');try{if($s.Exists){$k.SetValue('Path',[string]$s.Value,[Microsoft.Win32.RegistryValueKind]::$($s.Kind))}else{$k.DeleteValue('Path',$false)}}finally{$k.Dispose()}" >nul 2>nul
if errorlevel 1 set "PY_ROLLBACK_RC=1"
set "PATH=%PY_OLD_PATH%"
if "%PY_HAD_MANIFEST%"=="1" (copy /b /y "%PY_MANIFEST_BACKUP%" "%PY_MANIFEST%" >nul 2>nul & if errorlevel 1 set "PY_ROLLBACK_RC=1") else if exist "%PY_MANIFEST%" (del /f /q "%PY_MANIFEST%" >nul 2>nul & if exist "%PY_MANIFEST%" set "PY_ROLLBACK_RC=1")
exit /b %PY_ROLLBACK_RC%
:ipy_cleanup
set "PY_CLEANUP_RC=0"
if exist "%PY_INSTALLER%" del /f /q "%PY_INSTALLER%" >nul 2>nul
if exist "%PY_INSTALLER%" set "PY_CLEANUP_RC=1"
if exist "%PY_PATH_STATE%" del /f /q "%PY_PATH_STATE%" >nul 2>nul
if exist "%PY_PATH_STATE%" set "PY_CLEANUP_RC=1"
if exist "%PY_MANIFEST_BACKUP%" del /f /q "%PY_MANIFEST_BACKUP%" >nul 2>nul
if exist "%PY_MANIFEST_BACKUP%" set "PY_CLEANUP_RC=1"
if exist "%PY_PATH_OUT%" del /f /q "%PY_PATH_OUT%" >nul 2>nul
if exist "%PY_PATH_OUT%" set "PY_CLEANUP_RC=1"
if "%PY_CLEANUP_RC%"=="1" call :color_echo "1;31m" "  Không dọn được toàn bộ tệp tạm Python; tệp còn lại được giữ để phục hồi."
exit /b %PY_CLEANUP_RC%

:ipy_32bit
call :color_echo "1;31m" "  Công cụ này chỉ hỗ trợ Windows 64-bit. Không có gì trên máy bị thay đổi."
call :log_append "install | fail | %PY_VER% | unsupported-32bit | %date% %time%"
exit /b 1

:install_git
rem --- MinGit per-user: mọi bước commit đều có snapshot để phục hồi khi lỗi ---
if not defined LOCALAPPDATA goto :igit_unknown
if "%VL_Git%"=="" goto :igit_unknown
if "%VL_Git%"=="-" goto :igit_unknown
powershell -NoProfile -ExecutionPolicy Bypass -Command "if('%VL_Git%' -cmatch '^\d+\.\d+\.\d+\.windows\.\d+$'){exit 0}else{exit 1}" >nul 2>nul
if errorlevel 1 goto :igit_unknown

set "GIT_VER=%VL_Git%"
set "GIT_ASSET_VER=%VL_Git:.windows=%"
set "GIT_URL=https://github.com/git-for-windows/git/releases/download/v%VL_Git%/MinGit-%GIT_ASSET_VER%-64-bit.zip"
set "GIT_TX_ID="
set "GIT_ZIP="
set "GIT_STAGE="
set "GIT_BACKUP="
set "GIT_PATH_STATE="
set "GIT_MANIFEST_BACKUP="
for /f "delims=" %%g in ('powershell -NoProfile -Command "[guid]::NewGuid().ToString('N')"') do set "GIT_TX_ID=%%g"
if not defined GIT_TX_ID goto :igit_prepare_fail
set "GIT_ZIP=%TEMP%\MinGit-%GIT_ASSET_VER%-%GIT_TX_ID%.zip"
set "GIT_DIR=%LOCALAPPDATA%\Programs\Git"
set "GIT_STAGE=%LOCALAPPDATA%\Programs\Git.aitools-stage-%GIT_TX_ID%"
set "GIT_BACKUP=%LOCALAPPDATA%\Programs\Git.aitools-backup-%GIT_TX_ID%"
set "GIT_PATH_STATE=%TEMP%\aitools-git-path-%GIT_TX_ID%.xml"
set "GIT_MANIFEST_BACKUP=%TEMP%\aitools-git-manifest-%GIT_TX_ID%.bak"
set "GIT_MANIFEST=%LOCALAPPDATA%\AITools\manifest.txt"
set "GIT_OLD_PATH=%PATH%"
set "GIT_HAD_OLD=0"
set "GIT_HAD_MANIFEST=0"
set "GIT_COMMIT_STARTED=0"
if exist "%GIT_ZIP%" goto :igit_collision_fail
if exist "%GIT_STAGE%" goto :igit_collision_fail
if exist "%GIT_BACKUP%" goto :igit_collision_fail
if exist "%GIT_PATH_STATE%" goto :igit_collision_fail
if exist "%GIT_MANIFEST_BACKUP%" goto :igit_collision_fail

echo.
call :color_echo "1;97m" "  Đang tải Git %GIT_VER% từ nguồn chính thức..."
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue';$ok=$false;for($i=1;$i -le 3;$i++){try{if(Test-Path -LiteralPath $env:GIT_ZIP){Remove-Item -LiteralPath $env:GIT_ZIP -Force};if(Test-Path -LiteralPath $env:GIT_STAGE){Remove-Item -LiteralPath $env:GIT_STAGE -Recurse -Force};Invoke-WebRequest -Uri $env:GIT_URL -OutFile $env:GIT_ZIP -UseBasicParsing -TimeoutSec 120;if((Get-Item -LiteralPath $env:GIT_ZIP).Length -le 0){throw 'empty'};New-Item -ItemType Directory -Path $env:GIT_STAGE|Out-Null;Expand-Archive -LiteralPath $env:GIT_ZIP -DestinationPath $env:GIT_STAGE -Force;$exe=Join-Path $env:GIT_STAGE 'cmd\git.exe';if(-not (Test-Path -LiteralPath $exe -PathType Leaf)){throw 'missing'};$out=& $exe --version 2^>^&1;if($LASTEXITCODE -ne 0 -or $out -notmatch ('^git version '+[regex]::Escape($env:GIT_VER)+'(?:\s|$)')){throw 'version'};$ok=$true;break}catch{if(Test-Path -LiteralPath $env:GIT_ZIP){Remove-Item -LiteralPath $env:GIT_ZIP -Force -ErrorAction SilentlyContinue};if(Test-Path -LiteralPath $env:GIT_STAGE){Remove-Item -LiteralPath $env:GIT_STAGE -Recurse -Force -ErrorAction SilentlyContinue};if($i -lt 3){Start-Sleep -Milliseconds 500}}};if(-not $ok){exit 1}" >nul 2>nul
if errorlevel 1 goto :igit_package_fail

call :color_echo "1;97m" "  Đã tải và kiểm tra xong. Đang thay bản Git mới..."

rem --- Snapshot PATH và manifest trước mutation đầu tiên ---
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$k=[Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment');try{if($null -eq $k){$s=[pscustomobject]@{Exists=$false;Value='';Kind='ExpandString'}}else{try{$v=$k.GetValue('Path','',[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames);$kind=$k.GetValueKind('Path').ToString();$s=[pscustomobject]@{Exists=$true;Value=[string]$v;Kind=$kind}}catch{$s=[pscustomobject]@{Exists=$false;Value='';Kind='ExpandString'}}};$s|Export-Clixml -LiteralPath $env:GIT_PATH_STATE}finally{if($k){$k.Dispose()}}" >nul 2>nul
if errorlevel 1 goto :igit_prepare_fail
if exist "%GIT_MANIFEST%" (
  copy /b /y "%GIT_MANIFEST%" "%GIT_MANIFEST_BACKUP%" >nul 2>nul
  if errorlevel 1 goto :igit_prepare_fail
  set "GIT_HAD_MANIFEST=1"
)

set "GIT_COMMIT_STARTED=1"
if exist "%GIT_DIR%" set "GIT_HAD_OLD=1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';if(Test-Path -LiteralPath $env:GIT_BACKUP){throw 'collision'};if(Test-Path -LiteralPath $env:GIT_DIR){Move-Item -LiteralPath $env:GIT_DIR -Destination $env:GIT_BACKUP};Move-Item -LiteralPath $env:GIT_STAGE -Destination $env:GIT_DIR" >nul 2>nul
if errorlevel 1 goto :igit_replace_fail

call :path_append "%%LOCALAPPDATA%%\Programs\Git\cmd"
if errorlevel 1 goto :igit_path_fail

powershell -NoProfile -ExecutionPolicy Bypass -Command "$expected=(Get-Item -LiteralPath (Join-Path $env:GIT_DIR 'cmd\git.exe') -ErrorAction Stop).FullName;$direct=& $expected --version 2^>^&1;if($LASTEXITCODE -ne 0 -or $direct -notmatch ('^git version '+[regex]::Escape($env:GIT_VER)+'(?:\s|$)')){exit 1};$cmd=(Get-Command git -CommandType Application -ErrorAction Stop).Source;if((Get-Item -LiteralPath $cmd).FullName -ine $expected){exit 1};$session=& git --version 2^>^&1;if($LASTEXITCODE -ne 0 -or $session -notmatch ('^git version '+[regex]::Escape($env:GIT_VER)+'(?:\s|$)')){exit 1}" >nul 2>nul
if errorlevel 1 goto :igit_verify_fail

call :manifest_append "Git" "%GIT_VER%" "%GIT_DIR%"
if errorlevel 1 goto :igit_manifest_fail

call :log_append "install | ok | %GIT_VER% | %GIT_DIR% | %date% %time%"
call :igit_cleanup
call :color_echo "1;32m" "  Git %GIT_VER% đã cài xong."
exit /b 0

:igit_unknown
call :color_echo "1;31m" "  Không xác định được phiên bản Git hoặc thư mục dữ liệu người dùng. Bỏ qua."
call :color_echo "2;90m" "  Kiểm tra kết nối và thiết lập Windows rồi chạy lại. Không có gì trên máy bị thay đổi."
call :log_append "install | skip | unknown-version | Git | %date% %time%"
exit /b 1

:igit_package_fail
call :color_echo "1;31m" "  Không tải hoặc chuẩn bị được Git hợp lệ sau 3 lần thử. Kiểm tra kết nối rồi chạy lại."
call :log_append "install | fail | %VL_Git% | package-prepare-failed | %date% %time%"
call :igit_cleanup
exit /b 1

:igit_collision_fail
call :color_echo "1;31m" "  Không tạo được vùng tạm an toàn cho Git. Hãy chạy lại để thử lần nữa."
call :log_append "install | fail | %VL_Git% | temporary-path-conflict | %date% %time%"
exit /b 1

:igit_prepare_fail
call :color_echo "1;31m" "  Không thể tạo điểm phục hồi an toàn cho Git. Bản hiện có được giữ nguyên."
call :log_append "install | fail | %VL_Git% | backup-failed | %date% %time%"
call :igit_cleanup
exit /b 1

:igit_replace_fail
set "GIT_FAIL_REASON=replace-failed"
set "GIT_FAIL_MESSAGE=Không thể thay bản Git mới. Bản Git trước sẽ được phục hồi."
goto :igit_rollback_fail
:igit_path_fail
set "GIT_FAIL_REASON=path-write-failed"
set "GIT_FAIL_MESSAGE=Không ghi được PATH người dùng. Bản Git trước sẽ được phục hồi."
goto :igit_rollback_fail
:igit_verify_fail
set "GIT_FAIL_REASON=verify-failed"
set "GIT_FAIL_MESSAGE=Bản Git mới không vượt qua kiểm tra. Bản Git trước sẽ được phục hồi."
goto :igit_rollback_fail
:igit_manifest_fail
set "GIT_FAIL_REASON=manifest-write-failed"
set "GIT_FAIL_MESSAGE=Không ghi được hồ sơ cài đặt. Bản Git trước sẽ được phục hồi."

:igit_rollback_fail
call :color_echo "1;31m" "  %GIT_FAIL_MESSAGE%"
call :igit_rollback
if errorlevel 1 (
  call :color_echo "1;31m" "  Phục hồi chưa hoàn tất. Không xóa thư mục sao lưu để bạn có thể khôi phục thủ công."
  call :log_append "install | fail | %VL_Git% | %GIT_FAIL_REASON%-rollback-failed | %date% %time%"
) else (
  call :log_append "install | fail | %VL_Git% | %GIT_FAIL_REASON% | %date% %time%"
  call :igit_cleanup
)
exit /b 1

:igit_rollback
set "GIT_ROLLBACK_RC=0"
rem --- Phục hồi filesystem độc lập. Có bản cũ thì chỉ xóa đích khi backup thật sự tồn tại. ---
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$hadOld=$env:GIT_HAD_OLD -eq '1';$hasBackup=Test-Path -LiteralPath $env:GIT_BACKUP;if($hadOld){if($hasBackup){if(Test-Path -LiteralPath $env:GIT_DIR){Remove-Item -LiteralPath $env:GIT_DIR -Recurse -Force};Move-Item -LiteralPath $env:GIT_BACKUP -Destination $env:GIT_DIR}elseif(-not (Test-Path -LiteralPath $env:GIT_DIR)){exit 1}}else{if(Test-Path -LiteralPath $env:GIT_DIR){Remove-Item -LiteralPath $env:GIT_DIR -Recurse -Force};if($hasBackup){exit 1}}" >nul 2>nul
if errorlevel 1 set "GIT_ROLLBACK_RC=1"

rem --- PATH được phục hồi dù filesystem có lỗi. ---
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$s=Import-Clixml -LiteralPath $env:GIT_PATH_STATE;$k=[Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Environment');try{if($s.Exists){$kind=[Microsoft.Win32.RegistryValueKind]::$($s.Kind);$k.SetValue('Path',[string]$s.Value,$kind)}else{$k.DeleteValue('Path',$false)}}finally{$k.Dispose()}" >nul 2>nul
if errorlevel 1 set "GIT_ROLLBACK_RC=1"
set "PATH=%GIT_OLD_PATH%"

rem --- Manifest được phục hồi dù hai miền trên có lỗi. ---
if "%GIT_HAD_MANIFEST%"=="1" (
  copy /b /y "%GIT_MANIFEST_BACKUP%" "%GIT_MANIFEST%" >nul 2>nul
  if errorlevel 1 set "GIT_ROLLBACK_RC=1"
) else if exist "%GIT_MANIFEST%" (
  del /f /q "%GIT_MANIFEST%" >nul 2>nul
  if exist "%GIT_MANIFEST%" set "GIT_ROLLBACK_RC=1"
)
exit /b %GIT_ROLLBACK_RC%

:igit_cleanup
if exist "%GIT_ZIP%" del /f /q "%GIT_ZIP%" >nul 2>nul
if exist "%GIT_STAGE%" rmdir /s /q "%GIT_STAGE%" >nul 2>nul
if exist "%GIT_BACKUP%" rmdir /s /q "%GIT_BACKUP%" >nul 2>nul
if exist "%GIT_PATH_STATE%" del /f /q "%GIT_PATH_STATE%" >nul 2>nul
if exist "%GIT_MANIFEST_BACKUP%" del /f /q "%GIT_MANIFEST_BACKUP%" >nul 2>nul
exit /b 0

:install_node
rem --- Tiền đề: cần phiên bản Node xác định và đúng định dạng x.y.z để cài (VL_Node) ---
if not defined LOCALAPPDATA set "LOCALAPPDATA=%TEMP%"
if "%VL_Node%"=="" goto :inode_unknown
if "%VL_Node%"=="-" goto :inode_unknown
powershell -NoProfile -ExecutionPolicy Bypass -Command "if('%VL_Node%' -match '^\d+\.\d+\.\d+$'){exit 0}else{exit 1}"
if errorlevel 1 goto :inode_unknown

echo.
call :color_echo "1;97m" "  Đang tải Node.js %VL_Node% từ nguồn chính thức..."

set "NODE_VER=%VL_Node%"
set "NODE_URL=https://nodejs.org/dist/v%VL_Node%/node-v%VL_Node%-win-x64.zip"
set "NODE_ZIP=%TEMP%\node-v%VL_Node%-win-x64.zip"
set "NODE_STAGE=%TEMP%\node-stage-%VL_Node%"
set "NODE_DIR=%LOCALAPPDATA%\node"

rem --- Tải ZIP (retry 3, $ProgressPreference='SilentlyContinue') ---
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue';$u='%NODE_URL%';$o='%NODE_ZIP%';$ok=$false;for($i=0;$i -lt 3;$i++){try{Invoke-WebRequest -Uri $u -OutFile $o -UseBasicParsing -TimeoutSec 120;if((Get-Item $o -ErrorAction SilentlyContinue).Length -gt 0){$ok=$true;break}}catch{if($i -ge 2){break};Start-Sleep -Milliseconds 500}};if(-not $ok){exit 1};exit 0"
if errorlevel 1 goto :inode_download_fail

echo.
call :color_echo "1;97m" "  Đã tải xong. Đang giải nén vào %LOCALAPPDATA%\node ..."

rem --- Giải nén qua thư mục tạm rồi thay thế %LOCALAPPDATA%\node (sạch, an toàn khi chạy lại) ---
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue';$stage='%NODE_STAGE%';if(Test-Path $stage){Remove-Item -LiteralPath $stage -Recurse -Force};New-Item -ItemType Directory -Path $stage|Out-Null;Expand-Archive -LiteralPath '%NODE_ZIP%' -DestinationPath $stage -Force;$inner=Get-ChildItem -LiteralPath $stage -Directory|Select-Object -First 1;if($null -eq $inner){exit 1};if(Test-Path '%NODE_DIR%'){Remove-Item -LiteralPath '%NODE_DIR%' -Recurse -Force};Move-Item -LiteralPath $inner.FullName -Destination '%NODE_DIR%';exit 0"
if errorlevel 1 goto :inode_extract_fail

rem --- Thêm PATH người dùng (PATH-controller, không setx) ---
call :path_append "%%LOCALAPPDATA%%\node"
if errorlevel 1 goto :inode_path_fail

rem --- Verify node + npm chạy ngay trong phiên (PATH đã refresh) ---
node --version >nul 2>nul
if errorlevel 1 goto :inode_verify_fail
call npm --version >nul 2>nul
if errorlevel 1 goto :inode_verify_fail

rem --- Ghi manifest (append nếu chưa có) ---
call :manifest_append "Node" "%NODE_VER%" "%NODE_DIR%"

call :log_append "install | ok | %NODE_VER% | %NODE_DIR% | %date% %time%"
if exist "%NODE_ZIP%" del /f /q "%NODE_ZIP%" >nul 2>nul
if exist "%NODE_STAGE%" rmdir /s /q "%NODE_STAGE%" >nul 2>nul
call :color_echo "1;32m" "  Node.js %NODE_VER% đã cài xong."
exit /b 0

:inode_unknown
call :color_echo "1;31m" "  Không xác định được phiên bản Node.js để cài. Bỏ qua."
call :color_echo "2;90m" "  Kiểm tra kết nối mạng rồi chạy lại. Không có gì trên máy bị thay đổi."
call :log_append "install | skip | unknown-version | - | %date% %time%"
exit /b 0

:inode_download_fail
call :color_echo "1;31m" "  Tải Node.js %VL_Node% thất bại. Kiểm tra kết nối mạng rồi chạy lại."
call :color_echo "2;90m" "  Lỗi tải một mục không làm ảnh hưởng các mục khác."
call :log_append "install | fail | %VL_Node% | download-failed | %date% %time%"
exit /b 1

:inode_extract_fail
call :color_echo "1;31m" "  Giải nén Node.js thất bại. Chạy lại để thử lần nữa."
call :log_append "install | fail | %VL_Node% | extract-failed | %date% %time%"
exit /b 1

:inode_verify_fail
call :color_echo "1;31m" "  Đã cài Node.js nhưng lệnh node/npm chưa chạy được. Kiểm tra PATH rồi chạy lại."
call :log_append "install | fail | %VL_Node% | verify-failed | %date% %time%"
exit /b 1

:inode_path_fail
call :color_echo "1;31m" "  Không ghi được PATH người dùng. Kiểm tra quyền rồi chạy lại."
call :log_append "install | fail | %VL_Node% | path-write-failed | %date% %time%"
exit /b 1

rem --------------------------- uninstall ---------------------------
:stub_uninstall
call :color_echo "1;97m" "Gỡ cài đặt chưa được hỗ trợ trong phiên bản %TOOL_VERSION%."
call :color_echo "2;90m" "Tính năng này sẽ có trong phiên bản tương lai. Công cụ thoát an toàn."
call :log_append "uninstall | skip | - | - | %date% %time%"
exit /b 0

rem --------------------------- self-update ---------------------------
:stub_update
call :color_echo "1;97m" "Cập nhật chưa được hỗ trợ trong phiên bản %TOOL_VERSION%."
call :color_echo "2;90m" "Tính năng này sẽ có trong phiên bản tương lai. Công cụ thoát an toàn."
call :log_append "update | skip | - | - | %date% %time%"
exit /b 0

rem --------------------------- mode không hợp lệ ---------------------------
:unknown_mode
call :color_echo "1;97m" "Chế độ không hợp lệ."
call :color_echo "2;90m" "Công cụ thoát an toàn. Chạy lại AI_Tools_Installer.bat để cài đặt."
call :log_append "router | fail | - | - | %date% %time%"
exit /b 0
