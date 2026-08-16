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
call :run_step "welcome" ":welcome_block"
if errorlevel 1 set "PIPELINE_RC=1"
call :scan_block
if errorlevel 1 set "PIPELINE_RC=1"
call :run_step "plan" ":plan_block"
if errorlevel 1 set "PIPELINE_RC=1"
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
set "S7=function Decide($it,$cur,$lat){if($it -eq 'VSCodeExt'){if($cur -ne ''){return 'SKIP'};return 'INSTALL'};if($cur -eq ''){return 'INSTALL'};if($lat -eq ''){return 'SKIP'};if($it -eq 'OpenClaw'){if($cur.CompareTo($lat) -ge 0){return 'SKIP'};return 'UPDATE'};$c=S3 $cur;$l=S3 $lat;if($c -eq '' -or $l -eq ''){return 'SKIP'};if((Cmp3 $c $l) -ge 0){return 'SKIP'};return 'UPDATE'};"
set "S8=[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$neterr=0;foreach($it in @('Git','Python','VSCode','VSCodeExt','OpenClaw','9Router')){$cur='';try{$cur=Cur $it}catch{$cur=''};$lat='';if($it -ne 'VSCodeExt'){try{$lat=Latest $it}catch{$lat='';$neterr++}};$dec=Decide $it $cur $lat;P ('{0}|{1}|{2}|{3}' -f $it,(Sen $cur),(Sen $lat),$dec)};P ('NETERR|{0}' -f $neterr)"

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
call :color_echo "1;97m" "Bước lập kế hoạch cài đặt chưa được hỗ trợ trong phiên bản %TOOL_VERSION%."
call :color_echo "2;90m" "Phiên bản mới sẽ có tính năng này. Công cụ thoát an toàn."
call :press_any_key
exit /b 0

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
