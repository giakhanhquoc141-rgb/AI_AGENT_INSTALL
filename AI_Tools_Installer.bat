@echo off
rem ============================================================
rem  AI Tools Installer - Phien ban 0.4.4
rem  Cau truc mot file, tu bao gom: [init] -> [helpers] -> [router]
rem  Dinh dang file: UTF-8 (khong BOM), xuat dong CRLF, chcp 65001
rem ============================================================

setlocal
chcp 65001 >nul

rem --------------------------- [init] ---------------------------
set "TOOL_NAME=AI Tools Installer"
set "TOOL_VERSION=0.4.4"
set "TOOL_SLOGAN=Cài bộ AI · Tự kiểm tra · Gỡ sạch"
set "TOOL_INTRO=Công cụ giúp bạn cài bộ AI vào máy trong một lần chạy — không cần kiến thức kỹ thuật."

rem Early lifecycle routes stay outside the legacy parenthesized blocks.
if /i "%~1"=="--update" goto :early_update
if /i "%~1"=="--uninstall" goto :uninstall_manifest
goto :router

:early_update
set "UPDATE_STATE="
set "UPDATE_LATEST="
set "UPDATE_URL="
for /f "tokens=1-3 delims=|" %%a in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';try{$r=Invoke-RestMethod -Uri 'https://api.github.com/repos/giakhanhquoc141-rgb/AI_AGENT_INSTALL/releases/latest' -Headers @{'User-Agent'='AI-Tools-Installer'} -TimeoutSec 15;$a=$r.assets|?{$_.name -match '(?i)^AI_Tools_Installer\.bat$'}|Select-Object -First 1;if($null -eq $a){'none||'}else{'found|'+([string]$r.tag_name).TrimStart('v','V')+'|'+$a.browser_download_url}}catch{'error||'}"') do (set "UPDATE_STATE=%%a" & set "UPDATE_LATEST=%%b" & set "UPDATE_URL=%%c")
if /i "%UPDATE_STATE%"=="error" (echo Không thể kiểm tra cập nhật; bản hiện tại vẫn an toàn. & goto :installer_exit)
if /i not "%UPDATE_STATE%"=="found" (echo Chưa có bản phát hành có asset AI_Tools_Installer.bat. & goto :installer_exit)
for /f "delims=" %%v in ('powershell -NoProfile -Command "$a='%TOOL_VERSION%';$b='%UPDATE_LATEST%';try{if([version]$b -gt [version]$a){'new'}else{'current'}}catch{'new'}"') do set "UPDATE_COMPARE=%%v"
if /i not "%UPDATE_COMPARE%"=="new" (echo Bạn đang dùng bản mới nhất: %TOOL_VERSION%. & goto :installer_exit)
call :self_update_replace "%UPDATE_URL%" "%UPDATE_LATEST%"
goto :installer_exit

:early_uninstall
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$root=$env:LOCALAPPDATA;$m=Join-Path $root 'AITools\manifest.txt';if(-not (Test-Path -LiteralPath $m)){exit 0};$allowed=@((Join-Path $root 'node'),(Join-Path $root 'Programs\Git'),(Join-Path $root 'Programs\Python\Python313'),(Join-Path $root 'Programs\Microsoft VS Code'));foreach($line in [IO.File]::ReadLines($m)){ $f=$line -split ' \| ',4;if($f.Count -ne 4){continue};$p=[Environment]::ExpandEnvironmentVariables($f[3]).TrimEnd('\');if($allowed -contains $p -and (Test-Path -LiteralPath $p)){Remove-Item -LiteralPath $p -Recurse -Force}};Remove-Item -LiteralPath $m -Force -ErrorAction SilentlyContinue;Remove-Item -LiteralPath (Join-Path $root 'AITools\logs\ai-tools-installer.log') -Force -ErrorAction SilentlyContinue"
exit /b 0

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
rem  Nhãn bước cài "Mục i/7 · tên" — không vẽ phần trăm giả.
rem  Phần trăm thật xuất hiện ở tải (byte) và hoạt ảnh chờ cài/npm.
rem ------------------------------------------------------------
:progress_step
if "%~2"=="" exit /b
if not defined SEL_COUNT set "SEL_COUNT=7"
call :color_echo "1;36m" "  Mục %~1/%SEL_COUNT% · %~2"
exit /b

rem Tải theo luồng và hiển thị phần trăm byte thật. Nếu máy chủ không
rem trả Content-Length thì hiện số MiB cùng spinner cho đến khi hoàn tất.
:download_with_progress
setlocal
set "DL_URL=%~1"
set "DL_OUT=%~2"
set "DL_NAME=%~3"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$u=$env:DL_URL;$o=$env:DL_OUT;$n=$env:DL_NAME;$spin=@('|','/','-','\');for($attempt=1;$attempt -le 3;$attempt++){$req=$null;$res=$null;$src=$null;$dst=$null;try{if(Test-Path -LiteralPath $o){Remove-Item -LiteralPath $o -Force};$req=[Net.HttpWebRequest]::Create($u);$req.UserAgent='AI-Tools-Installer';$req.Timeout=120000;$req.ReadWriteTimeout=15000;$watch=[Diagnostics.Stopwatch]::StartNew();$ar=$req.BeginGetResponse($null,$null);$tick=0;while(-not $ar.AsyncWaitHandle.WaitOne(120)){Write-Host (([char]13)+'  '+$spin[$tick%%4]+' Đang kết nối '+$n+'...') -NoNewline -ForegroundColor Cyan;$tick++;if($watch.Elapsed.TotalSeconds -gt 120){$req.Abort();throw 'connect-timeout'}};$res=$req.EndGetResponse($ar);$total=[int64]$res.ContentLength;$src=$res.GetResponseStream();$src.ReadTimeout=15000;$dst=[IO.File]::Open($o,[IO.FileMode]::Create,[IO.FileAccess]::Write,[IO.FileShare]::None);$buf=New-Object byte[] 65536;$read=[int64]0;$lastPct=-1;$lastDraw=[Diagnostics.Stopwatch]::StartNew();while($true){$rr=$src.BeginRead($buf,0,$buf.Length,$null,$null);while(-not $rr.AsyncWaitHandle.WaitOne(120)){if($watch.Elapsed.TotalMinutes -gt 10){$req.Abort();throw 'transfer-timeout'};Write-Host (([char]13)+'  '+$spin[$tick%%4]+' Đang nhận '+$n+'  '+('{0:N1}' -f ($read/1MB))+' MiB') -NoNewline -ForegroundColor Cyan;$tick++};$count=$src.EndRead($rr);if($count -le 0){break};$dst.Write($buf,0,$count);$read+=$count;$tick++;if($total -gt 0){$pct=[int][math]::Min(100,[math]::Floor(($read*100)/$total));if($pct -ne $lastPct -and ($lastDraw.ElapsedMilliseconds -ge 100 -or $pct -eq 100)){$done=[int][math]::Floor($pct/5);$bar=('#'*$done)+('.'*(20-$done));Write-Host (([char]13)+'  '+$spin[$tick%%4]+' ['+$bar+'] '+$pct.ToString('D3')+([char]37)+'  '+$n+'  '+('{0:N1}' -f ($read/1MB))+'/'+('{0:N1}' -f ($total/1MB))+' MiB') -NoNewline -ForegroundColor Cyan;$lastPct=$pct;$lastDraw.Restart()}}elseif($lastDraw.ElapsedMilliseconds -ge 100){Write-Host (([char]13)+'  '+$spin[$tick%%4]+' '+$n+'  '+('{0:N1}' -f ($read/1MB))+' MiB') -NoNewline -ForegroundColor Cyan;$lastDraw.Restart()}};$dst.Flush();if($total -gt 0 -and $read -ne $total){throw ('truncated '+$read+'/'+$total)};if($read -le 0){throw 'empty'};Write-Host (([char]13)+'  OK [####################] 100'+([char]37)+'  '+$n+'                              ') -ForegroundColor Green;exit 0}catch{$reason=($_.Exception.Message -replace '[\r\n]+',' ');if($reason.Length -gt 72){$reason=$reason.Substring(0,72)};Write-Host (([char]13)+'  X Thử tải '+$attempt+'/3 thất bại: '+$n+' — '+$reason+'          ') -ForegroundColor Yellow;if(Test-Path -LiteralPath $o){Remove-Item -LiteralPath $o -Force -ErrorAction SilentlyContinue};if($attempt -lt 3){Start-Sleep -Milliseconds 600}}finally{if($null -ne $dst){$dst.Dispose()};if($null -ne $src){$src.Dispose()};if($null -ne $res){$res.Dispose()};if($null -ne $req){$req.Abort()}}};exit 1"
set "DL_RC=%errorlevel%"
endlocal & exit /b %DL_RC%

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

:read_raw_key
set "RAW_KEY="
if not defined AITEST_MODE goto :read_raw_key_console
if not defined AITEST_KEYS exit /b 1
set "RAW_KEY=!AITEST_KEYS:~0,1!"
set "AITEST_KEYS=!AITEST_KEYS:~1!"
if /i "!RAW_KEY!"=="U" set "RAW_KEY=UpArrow"
if /i "!RAW_KEY!"=="D" set "RAW_KEY=DownArrow"
if /i "!RAW_KEY!"=="S" set "RAW_KEY=Spacebar"
if /i "!RAW_KEY!"=="E" set "RAW_KEY=Enter"
if not defined RAW_KEY exit /b 1
exit /b 0
:read_raw_key_console
for /f "delims=" %%k in ('powershell -NoProfile -Command "$ErrorActionPreference='Stop';try{if([Console]::IsInputRedirected){exit 2};$k=[Console]::ReadKey($true);if($k.KeyChar -eq [char]0){$k.Key.ToString()}elseif($k.Key -eq [ConsoleKey]::Spacebar){'Spacebar'}elseif($k.Key -eq [ConsoleKey]::Enter){'Enter'}else{[string]$k.KeyChar}}catch{exit 2}"') do if not defined RAW_KEY set "RAW_KEY=%%k"
if not defined RAW_KEY exit /b 1
exit /b 0

:press_enter
call :read_raw_key
if errorlevel 1 exit /b 1
if /i not "%RAW_KEY%"=="Enter" goto :press_enter
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
if not defined MA_ITEM endlocal & exit /b 1
if not defined MA_VER endlocal & exit /b 1
if not defined MA_PATH endlocal & exit /b 1
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';$item=[string]$env:MA_ITEM;$ver=[string]$env:MA_VER;$raw=[string]$env:MA_PATH;if($item -match '[\r\n|]' -or $ver -match '[\r\n|]' -or $raw -match '[\r\n|]'){exit 2};$root=Join-Path $env:LOCALAPPDATA 'AITools';[IO.Directory]::CreateDirectory($root)|Out-Null;$file=Join-Path $root 'manifest.txt';$path=$raw;$local=$env:LOCALAPPDATA;if($path -ieq $local){$path='%%LOCALAPPDATA%%'}elseif($path.StartsWith($local+'\',[StringComparison]::OrdinalIgnoreCase)){$path='%%LOCALAPPDATA%%'+$path.Substring($local.Length)};$norm={param($v)([Environment]::ExpandEnvironmentVariables([string]$v)).Trim().TrimEnd('\')};if(Test-Path -LiteralPath $file){$found=[IO.File]::ReadLines($file)|?{$f=$_.Split(@(' | '),[StringSplitOptions]::None);$f.Count -eq 4 -and $f[0] -ieq $item -and $f[1] -ieq $ver -and (& $norm $f[3]) -ieq (& $norm $path)}|Select-Object -First 1;if($found){exit 0}};$line=$item+' | '+$ver+' | '+(Get-Date -Format yyyy-MM-dd)+' | '+$path+[Environment]::NewLine;[IO.File]::AppendAllText($file,$line,[Text.UTF8Encoding]::new($false))" >nul 2>nul
set "MA_RC=%errorlevel%"
endlocal & exit /b %MA_RC%

rem ------------------------------------------------------------
rem  Kiểm tra manifest theo schema 4 trường trước khi lifecycle tiếp tục.
rem  Không sửa dữ liệu và không chạm ngoài thư mục AITools.
rem ------------------------------------------------------------
:manifest_validate
setlocal DisableDelayedExpansion
if not defined LOCALAPPDATA endlocal & exit /b 1
set "MV_FILE=%LOCALAPPDATA%\AITools\manifest.txt"
if not exist "%MV_FILE%" endlocal & exit /b 0
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';$file=$env:MV_FILE;$bad=0;foreach($line in [IO.File]::ReadLines($file)){if([string]::IsNullOrWhiteSpace($line)){continue};$f=$line.Split(@(' | '),[StringSplitOptions]::None);if($f.Count -ne 4 -or [string]::IsNullOrWhiteSpace($f[0]) -or [string]::IsNullOrWhiteSpace($f[1]) -or $f[2] -notmatch '^\d{4}-\d{2}-\d{2}$' -or [string]::IsNullOrWhiteSpace($f[3]) -or $f[0] -match '[|\r\n]' -or $f[1] -match '[|\r\n]' -or $f[3] -match '[|\r\n]'){$bad++}};if($bad -gt 0){exit 1};exit 0" >nul 2>nul
set "MV_RC=%errorlevel%"
endlocal & exit /b %MV_RC%

rem ------------------------------------------------------------
rem  Dọn lifecycle metadata sau uninstall: chỉ xóa manifest và log
rem  của AI Tools, không xóa thư mục cài đặt hay dữ liệu ứng dụng khác.
rem ------------------------------------------------------------
:manifest_clear
setlocal DisableDelayedExpansion
if not defined LOCALAPPDATA endlocal & exit /b 1
set "MC_ROOT=%LOCALAPPDATA%\AITools"
if exist "%MC_ROOT%\manifest.txt" del /f /q "%MC_ROOT%\manifest.txt" >nul 2>nul
if exist "%MC_ROOT%\logs\ai-tools-installer.log" del /f /q "%MC_ROOT%\logs\ai-tools-installer.log" >nul 2>nul
if exist "%MC_ROOT%\manifest.txt" endlocal & exit /b 1
if exist "%MC_ROOT%\logs\ai-tools-installer.log" endlocal & exit /b 1
endlocal & exit /b 0

rem ========================= [router] ==========================

rem --- Single-instance guard ---
if not defined LOCALAPPDATA set "LOCALAPPDATA=%TEMP%"
set "AITOOLS_LOCK=%LOCALAPPDATA%\AITools\.install-lock"
if exist "%AITOOLS_LOCK%" (
  call :color_echo "1;33m" "Trình cài đặt đang chạy. Đóng cửa sổ đó trước hoặc đợi hoàn tất."
  goto :installer_exit
)
if not exist "%LOCALAPPDATA%\AITools" mkdir "%LOCALAPPDATA%\AITools" 2>nul
echo %~pid>"%AITOOLS_LOCK%"

rem --- Dọn temp file cũ từ các lần chạy trước ---
for %%F in ("%TEMP%\aitools-*" "%TEMP%\node-backup-*" "%TEMP%\node-stage-*" "%TEMP%\python-*" "%TEMP%\git-*") do if exist "%%~F" del /f /q "%%~F" >nul 2>nul

:router
if /i "%~1"=="--uninstall" goto :uninstall_manifest
if /i "%~1"=="--update"    goto :stub_update
if /i "%~1"=="--test-selector" goto :test_selector
if /i "%~1"=="--test-report" goto :test_report
if "%~1"==""               goto :startup_update_check
goto :unknown_mode

:startup_update_check
set "STARTUP_UPDATE_STATE="
set "STARTUP_UPDATE_LATEST="
set "STARTUP_UPDATE_URL="
for /f "tokens=1-3 delims=|" %%a in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';try{$r=Invoke-RestMethod -Uri 'https://api.github.com/repos/giakhanhquoc141-rgb/AI_AGENT_INSTALL/releases/latest' -Headers @{'User-Agent'='AI-Tools-Installer'} -TimeoutSec 8;$t=[string]$r.tag_name;if([string]::IsNullOrWhiteSpace($t)){'none||'}else{$a=$r.assets|?{$_.name -match '(?i)^AI_Tools_Installer\.bat$'}|Select-Object -First 1;if($null -eq $a){'found|'+$t.TrimStart('v','V')+'|'}else{'found|'+$t.TrimStart('v','V')+'|'+$a.browser_download_url}}}catch{'error||'}"') do (set "STARTUP_UPDATE_STATE=%%a" & set "STARTUP_UPDATE_LATEST=%%b" & set "STARTUP_UPDATE_URL=%%c")
goto :run_install

:test_selector
set "AITEST_MODE=1"
set "AITEST_KEYS=%~2"
if not defined AITEST_KEYS exit /b 64
call :tool_select_block
if not defined SEL_COUNT exit /b 65
echo CURSOR=%TOOL_CURSOR%;COUNT=%SEL_COUNT%;Git=%SEL_Git%;Node=%SEL_Node%;Python=%SEL_Python%;VSCode=%SEL_VSCode%;VSCodeExt=%SEL_VSCodeExt%;OpenClaw=%SEL_OpenClaw%;9Router=%SEL_9Router%
exit /b 0

:test_report
set "AITEST_MODE=1"
if "%~2"=="" (set "RESULT_Node=" & set "RESULT_Git=" & set "RESULT_Python=" & set "RESULT_VSCode=" & set "RESULT_VSCodeExt=" & set "RESULT_OpenClaw=" & set "RESULT_9Router=") else (for /f "tokens=1-7 delims=," %%a in ("%~2") do (set "RESULT_Node=%%a" & set "RESULT_Git=%%b" & set "RESULT_Python=%%c" & set "RESULT_VSCode=%%d" & set "RESULT_VSCodeExt=%%e" & set "RESULT_OpenClaw=%%f" & set "RESULT_9Router=%%g"))
if "%~3"=="" (set "RESULT_9Router_Combo=" & set "RESULT_9Router_Autostart=" & set "RESULT_9Router_Onboarding=" & set "RESULT_OpenClaw_Autostart=" & set "RESULT_OpenClaw_Onboarding=") else (for /f "tokens=1-5 delims=," %%a in ("%~3") do (set "RESULT_9Router_Combo=%%a" & set "RESULT_9Router_Autostart=%%b" & set "RESULT_9Router_Onboarding=%%c" & set "RESULT_OpenClaw_Autostart=%%d" & set "RESULT_OpenClaw_Onboarding=%%e"))
set "AITEST_KEYS=r"
call :report_block
if errorlevel 2 exit /b 0
exit /b 66

rem --------------------------- install ---------------------------
:run_install
set "PIPELINE_RC=0"
set "PLAN_ABORT="
call :run_step "welcome" ":welcome_block"
if errorlevel 1 set "PIPELINE_RC=1"
if not "%PIPELINE_RC%"=="0" goto :run_install_end
call :tool_select_block
if errorlevel 1 (set "PIPELINE_RC=1" & goto :run_install_end)
call :scan_block
if errorlevel 1 (set "PIPELINE_RC=1" & set "PLAN_ABORT=1")
if defined PLAN_ABORT goto :run_install_end
call :plan_block
if errorlevel 1 set "PIPELINE_RC=1"
if defined PLAN_ABORT goto :run_install_end
call :execute_block
if errorlevel 1 set "PIPELINE_RC=1"
call :configure_block
if errorlevel 1 set "PIPELINE_RC=1"
:run_install_report
call :report_block
if errorlevel 2 goto :run_install
if errorlevel 1 set "PIPELINE_RC=1"
:run_install_end
exit /b %PIPELINE_RC%

rem --------------------- offer self-update ---------------------
rem Chạy sau welcome. Chỉ hỏi khi có bản phát hành mới + asset chính
rem thức; chọn cập nhật sẽ tự thay thế file đang chạy rồi thoát.
:offer_update
if /i "%STARTUP_UPDATE_STATE%"=="error" (
  call :color_echo "1;33m" "Kiểm tra cập nhật tạm thời không khả dụng; tiếp tục an toàn."
  exit /b 0
)
if /i "%STARTUP_UPDATE_STATE%"=="none" (
  call :color_echo "2;90m" "Chưa có bản phát hành chính thức; tiếp tục cài đặt."
  exit /b 0
)
if /i not "%STARTUP_UPDATE_STATE%"=="found" exit /b 0
if "%STARTUP_UPDATE_URL%"=="" exit /b 0
set "STARTUP_UPDATE_COMPARE="
for /f "delims=" %%c in ('powershell -NoProfile -Command "$a='%TOOL_VERSION%';$b='%STARTUP_UPDATE_LATEST%';try{if([version]$b -gt [version]$a){'new'}else{'current'}}catch{'new'}"') do if not defined STARTUP_UPDATE_COMPARE set "STARTUP_UPDATE_COMPARE=%%c"
if /i not "%STARTUP_UPDATE_COMPARE%"=="new" (
  call :color_echo "1;32m" "Bạn đang dùng bản mới nhất: %TOOL_VERSION%."
  exit /b 0
)
echo.
call :color_echo "1;33m" "Có bản cập nhật mới: hiện tại %TOOL_VERSION% → mới nhất %STARTUP_UPDATE_LATEST%."
call :color_echo "1;97m" "Bạn có muốn cập nhật installer không? "
call :color_echo "1;33m" "(Y/N)"
call :read_raw_key
if errorlevel 1 exit /b 0
if /i "%RAW_KEY%"=="Y" (
  call :color_echo "1;32m" "Đang cập nhật..."
  call :self_update_replace "%STARTUP_UPDATE_URL%" "%STARTUP_UPDATE_LATEST%"
  if not errorlevel 1 goto :installer_exit
  call :color_echo "1;33m" "Cập nhật thất bại; tiếp tục với phiên bản hiện tại."
)
call :log_append "startup-update ^| deferred ^| %TOOL_VERSION% -> %STARTUP_UPDATE_LATEST% ^| %date% %time%"
exit /b 0

rem --------------------- tool selection ---------------------
rem Chọn công cụ cần quét/cài (kiểu bmad-method module picker).
rem Mặc định chọn cả 7; bấm số để bật/tắt, T/K/X để kết thúc.
:tool_select_block
setlocal EnableDelayedExpansion
set "SEL_Git=1"
set "SEL_Node=1"
set "SEL_Python=1"
set "SEL_VSCode=1"
set "SEL_VSCodeExt=1"
set "SEL_OpenClaw=1"
set "SEL_9Router=1"
set "SEL_COUNT=7"
set "TOOL_CURSOR=1"
set "DEPENDENCY_NOTE="

:tool_select_redraw
cls
call :color_echo "1;36m" "CHỌN CÔNG CỤ"
call :color_echo "2;90m" "────────────────────────────────────────────────────────────────────"
call :color_echo "2;90m" "↑/↓ di chuyển · SPACE bật/tắt · ENTER xác nhận"
echo.
call :tool_select_row 1 SEL_Git "Git"
call :tool_select_row 2 SEL_Node "Node.js"
call :tool_select_row 3 SEL_Python "Python"
call :tool_select_row 4 SEL_VSCode "Visual Studio Code"
call :tool_select_row 5 SEL_VSCodeExt "Claude Code extension"
call :tool_select_row 6 SEL_OpenClaw "OpenClaw"
call :tool_select_row 7 SEL_9Router "9Router"
echo.
if defined DEPENDENCY_NOTE call :color_echo "1;33m" "!DEPENDENCY_NOTE!"
call :color_echo "1;97m" "Dùng phím mũi tên để chọn:"
call :read_raw_key
if errorlevel 1 endlocal & exit /b 1
if /i "!RAW_KEY!"=="UpArrow" (set /a TOOL_CURSOR-=1 & if !TOOL_CURSOR! LSS 1 set "TOOL_CURSOR=7" & goto :tool_select_redraw)
if /i "!RAW_KEY!"=="DownArrow" (set /a TOOL_CURSOR+=1 & if !TOOL_CURSOR! GTR 7 set "TOOL_CURSOR=1" & goto :tool_select_redraw)
if /i "!RAW_KEY!"=="Spacebar" goto :tool_select_toggle
if /i "!RAW_KEY!"=="Enter" goto :tool_select_done
goto :tool_select_redraw

:tool_select_toggle
set "DEPENDENCY_NOTE="
if "!TOOL_CURSOR!"=="1" (if defined SEL_Git (set "SEL_Git=") else set "SEL_Git=1")
if "!TOOL_CURSOR!"=="2" (if defined SEL_Node (set "SEL_Node=") else set "SEL_Node=1")
if "!TOOL_CURSOR!"=="3" (if defined SEL_Python (set "SEL_Python=") else set "SEL_Python=1")
if "!TOOL_CURSOR!"=="4" (if defined SEL_VSCode (set "SEL_VSCode=") else set "SEL_VSCode=1")
if "!TOOL_CURSOR!"=="5" (if defined SEL_VSCodeExt (set "SEL_VSCodeExt=") else set "SEL_VSCodeExt=1")
if "!TOOL_CURSOR!"=="6" (if defined SEL_OpenClaw (set "SEL_OpenClaw=") else set "SEL_OpenClaw=1")
if "!TOOL_CURSOR!"=="7" (if defined SEL_9Router (set "SEL_9Router=") else set "SEL_9Router=1")
call :tool_select_dependencies
goto :tool_select_redraw

:tool_select_dependencies
if defined SEL_VSCodeExt if not defined SEL_VSCode (set "SEL_VSCode=1" & set "DEPENDENCY_NOTE=Đã tự chọn Visual Studio Code — Claude Code extension cần VS Code.")
if defined SEL_OpenClaw if not defined SEL_Node (set "SEL_Node=1" & set "DEPENDENCY_NOTE=Đã tự chọn Node.js — OpenClaw cần npm.")
if defined SEL_9Router if not defined SEL_Node (set "SEL_Node=1" & set "DEPENDENCY_NOTE=Đã tự chọn Node.js — 9Router cần npm.")
exit /b

:tool_select_row
set "ROW_BOX=[ ]"
if defined %~2 set "ROW_BOX=[✓]"
if "%TOOL_CURSOR%"=="%~1" if defined VT_OK (echo %ESC%[7m !ROW_BOX! %~3 %ESC%[0m) else (echo ^> !ROW_BOX! %~3)
if not "%TOOL_CURSOR%"=="%~1" echo   !ROW_BOX! %~3
exit /b

:tool_select_done
call :tool_select_dependencies
set "SEL_COUNT=0"
if defined SEL_Git set /a SEL_COUNT+=1
if defined SEL_Node set /a SEL_COUNT+=1
if defined SEL_Python set /a SEL_COUNT+=1
if defined SEL_VSCode set /a SEL_COUNT+=1
if defined SEL_VSCodeExt set /a SEL_COUNT+=1
if defined SEL_OpenClaw set /a SEL_COUNT+=1
if defined SEL_9Router set /a SEL_COUNT+=1
if "%SEL_COUNT%"=="0" (
  set "DEPENDENCY_NOTE=Bạn cần chọn ít nhất 1 công cụ."
  goto :tool_select_redraw
)
call :log_append "select | ok | %SEL_COUNT% mục | - | %date% %time%"
endlocal & set "SEL_Git=%SEL_Git%" & set "SEL_Node=%SEL_Node%" & set "SEL_Python=%SEL_Python%" & set "SEL_VSCode=%SEL_VSCode%" & set "SEL_VSCodeExt=%SEL_VSCodeExt%" & set "SEL_OpenClaw=%SEL_OpenClaw%" & set "SEL_9Router=%SEL_9Router%" & set "SEL_COUNT=%SEL_COUNT%" & set "TOOL_CURSOR=%TOOL_CURSOR%" & exit /b 0

:welcome_block
call :color_echo "38;5;214m" "           █████╗   ██╗ ████████╗ ██████╗  ██████╗  ██╗      ██████╗"
call :color_echo "38;5;214m" "           ██╔══██╗ ██║ ╚══██╔══╝ ██╔══██╗ ██╔══██╗ ██║      ██╔═══╝"
call :color_echo "38;5;214m" "           ███████║ ██║    ██║    ██║  ██║ ██║  ██║ ██║      ██████╗"
call :color_echo "38;5;214m" "           ██╔══██║ ██║    ██║    ██║  ██║ ██║  ██║ ██║      ╚═══██╗"
call :color_echo "38;5;214m" "           ██║  ██║ ██║    ██║    ██║  ██║ ██║  ██║ ██║      ██████╔╝"
call :color_echo "38;5;214m" "           ╚═╝  ╚═╝ ╚═╝    ╚═╝    ╚═════╝  ╚═════╝  ╚██████╗ ╚═════╝"
echo.
call :color_echo "38;5;214m" " ██╗ ███╗  ██╗ ██████╗  ████████╗ █████╗   ██╗      ██╗      ███████╗ ██████╗"
call :color_echo "38;5;214m" " ██║ ████╗ ██║ ██╔═══╝  ╚══██╔══╝ ██╔══██╗ ██║      ██║      ██╔════╝ ██╔══██╗"
call :color_echo "38;5;214m" " ██║ ██╔██╗██║ ██████╗     ██║    ███████║ ██║      ██║      █████╗   ██████╔╝"
call :color_echo "38;5;214m" " ██║ ██║╚████║ ╚═══██╗     ██║    ██╔══██║ ██║      ██║      ██╔══╝   ██╔══██╗"
call :color_echo "38;5;214m" " ██║ ██║  ╚██║ ██████╔╝    ██║    ██║  ██║ ██║      ██║      ███████╗ ██║  ██║"
call :color_echo "38;5;214m" " ╚═╝ ╚═╝   ╚═╝ ╚═════╝     ╚═╝    ╚═╝  ╚═╝ ╚██████╗ ╚██████╗ ╚══════╝ ╚═╝  ╚═╝"
echo.
call :color_echo "1;97m" "      %TOOL_NAME%"
call :color_echo "1;97m" "     ────────────────────"
call :color_echo "2;90m" "   %TOOL_SLOGAN%"
call :color_echo "1;97m" "     Phiên bản %TOOL_VERSION%"
echo.
call :color_echo "1;97m" "   %TOOL_INTRO%"
echo.
call :offer_update
echo.
call :color_echo "1;97m" "Trình cài đặt sẽ:"
echo   1. Cho bạn chọn công cụ
echo   2. Quét phiên bản đã có và phiên bản mới nhất
echo   3. Hiển thị kế hoạch trước khi thay đổi máy
echo   4. Cài, xác minh và báo cáo từng mục
echo.
call :color_echo "1;33m" "Nhấn ENTER để bắt đầu"
call :press_enter
exit /b %errorlevel%

:scan_block
setlocal EnableDelayedExpansion
set "NET_ERR="
for %%I in (Git Node Python VSCode VSCodeExt OpenClaw 9Router) do (set "ST_%%I=" & set "VR_%%I=" & set "VL_%%I=")
call :color_echo "1;97m" "Bước 3/7 — Quét máy — kiểm tra !SEL_COUNT! mục đã chọn..."
echo.

rem --- Chỉ quét mục đã chọn; mục không chọn gán SKIP trước ---
set "SCAN_ITEM_LIST="
if defined SEL_Git set "SCAN_ITEM_LIST=!SCAN_ITEM_LIST!'Git',"
if defined SEL_Node set "SCAN_ITEM_LIST=!SCAN_ITEM_LIST!'Node',"
if defined SEL_Python set "SCAN_ITEM_LIST=!SCAN_ITEM_LIST!'Python',"
if defined SEL_VSCode set "SCAN_ITEM_LIST=!SCAN_ITEM_LIST!'VSCode',"
if defined SEL_VSCodeExt set "SCAN_ITEM_LIST=!SCAN_ITEM_LIST!'VSCodeExt',"
if defined SEL_OpenClaw set "SCAN_ITEM_LIST=!SCAN_ITEM_LIST!'OpenClaw',"
if defined SEL_9Router set "SCAN_ITEM_LIST=!SCAN_ITEM_LIST!'9Router',"
if defined SCAN_ITEM_LIST set "SCAN_ITEM_LIST=!SCAN_ITEM_LIST:~0,-1!"
if not defined SEL_Git (set "ST_Git=SKIP" & set "VR_Git=-" & set "VL_Git=-")
if not defined SEL_Node (set "ST_Node=SKIP" & set "VR_Node=-" & set "VL_Node=-")
if not defined SEL_Python (set "ST_Python=SKIP" & set "VR_Python=-" & set "VL_Python=-")
if not defined SEL_VSCode (set "ST_VSCode=SKIP" & set "VR_VSCode=-" & set "VL_VSCode=-")
if not defined SEL_VSCodeExt (set "ST_VSCodeExt=SKIP" & set "VR_VSCodeExt=-" & set "VL_VSCodeExt=-")
if not defined SEL_OpenClaw (set "ST_OpenClaw=SKIP" & set "VR_OpenClaw=-" & set "VL_OpenClaw=-")
if not defined SEL_9Router (set "ST_9Router=SKIP" & set "VR_9Router=-" & set "VL_9Router=-")

rem --- PowerShell version-check: phát hiện, lấy bản mới nhất, quyết định (AD-2/AD-6) ---
set "S1=$ErrorActionPreference='SilentlyContinue';function P($s){[Console]::WriteLine($s)};function E($s){[Console]::Error.WriteLine($s)};function W($s){[Console]::Error.Write($s)};function Sen($x){if($x -eq ''){return '-'};return $x};"
set "S2=function S3($v){$m=[regex]::Match([string]$v,'\d+\.\d+\.\d+');if($m.Success){return $m.Value};return ''};"
set "S3=function Cmp3($a,$b){$A=($a -split '\.');$B=($b -split '\.');for($i=0;$i -lt 3;$i++){$x=[int]$A[$i];$y=[int]$B[$i];if($x -gt $y){return 1};if($x -lt $y){return -1}};return 0};"
set "S4=function RetryC($cb){for($i=0;$i -lt 3;$i++){$j=$null;try{$j=Start-Job -ScriptBlock $cb;$tick=0;$sw=[Diagnostics.Stopwatch]::StartNew();while($j.State -eq 'Running' -or $j.State -eq 'NotStarted'){W (([char]13)+'    '+@('|','/','-','\')[$tick%%4]+' Đang kết nối '+$script:active+' — lần '+($i+1)+'/3...');Start-Sleep -Milliseconds 120;$tick++;if($sw.Elapsed.TotalSeconds -gt 20){Stop-Job -Job $j -ErrorAction SilentlyContinue;throw 'network-timeout'}};if($j.State -ne 'Completed'){throw 'network-job-failed'};$r=@(Receive-Job -Job $j -ErrorAction Stop);W (([char]13)+'    OK Đã kiểm tra '+$script:active+'                         '+[Environment]::NewLine);return $r}catch{W (([char]13)+'    LỖI Kết nối '+$script:active+' chưa thành công.              '+[Environment]::NewLine);if($i -ge 2){throw};Start-Sleep -Milliseconds 300}finally{if($null -ne $j){Remove-Job -Job $j -Force -ErrorAction SilentlyContinue}}}};"
set "S5=function Cur($it){switch($it){'Git'{$c=Get-Command git -ErrorAction SilentlyContinue;if($null -eq $c){return ''};$o=(& git --version 2>$null)|Out-String;$m=[regex]::Match($o,'\d+\.\d+\.\d+(\.windows\.[0-9]+)?');if($m.Success){return $m.Value};return ''};'Node'{$c=Get-Command node -ErrorAction SilentlyContinue;if($null -eq $c){return ''};if($c.Source -match '(?i)openclaw'){return ''};$o=(& node --version 2>$null)|Out-String;return (S3 $o)};'Python'{$c=Get-Command python -ErrorAction SilentlyContinue;if($null -eq $c){return ''};$o=(& python --version 2>&1)|Out-String;$m=[regex]::Match($o,'Python\s+(\d+\.\d+(\.\d+)?)');if(-not $m.Success){return ''};return $m.Groups[1].Value};'VSCode'{$c=Get-Command code -ErrorAction SilentlyContinue;if($null -eq $c){return ''};$o=@(& code --version 2>$null);if($o.Count -ge 1){return ($o[0].Trim())};return ''};'VSCodeExt'{$c=Get-Command code -ErrorAction SilentlyContinue;if($null -eq $c){return ''};$o=@(& code --list-extensions --show-versions 2>$null);foreach($l in $o){if($l -match '(?i)anthropic\.claude-code'){$m=[regex]::Match($l,'@([0-9][^@ ]*)');if($m.Success){return $m.Groups[1].Value};return 'installed'}};return ''};'OpenClaw'{$c=Get-Command openclaw -ErrorAction SilentlyContinue;if($null -eq $c){return ''};$o=((& openclaw --version 2>$null)|Out-String).Trim();$t=@($o -split '\s+');if($t.Count -ge 2){return $t[1]};return $o};'9Router'{$c=Get-Command 9router -ErrorAction SilentlyContinue;if($null -eq $c){return ''};$o=(& 9router --version 2>$null)|Out-String;return (S3 $o)}};return ''};"
set "S6=function Latest($it){switch($it){'Git'{$d=RetryC {(Invoke-RestMethod -Uri 'https://api.github.com/repos/git-for-windows/git/releases/latest' -UseBasicParsing -ErrorAction Stop -TimeoutSec 15 -Headers @{'User-Agent'='AI-Tools-Installer'})};return ([string]$d.tag_name).TrimStart('v')};'Node'{$d=RetryC {(Invoke-RestMethod -Uri 'https://nodejs.org/dist/index.json' -UseBasicParsing -ErrorAction Stop -TimeoutSec 15)};$best='';foreach($e in @($d)){if($e.lts -eq $false){continue};$v=S3 $e.version;if($v -eq ''){continue};if((Cmp3 $v '22.22.3') -ge 0 -and (Cmp3 $v '23.0.0') -lt 0){}elseif((Cmp3 $v '24.15.0') -ge 0 -and (Cmp3 $v '25.0.0') -lt 0){}else{continue};if($best -eq '' -or (Cmp3 $v $best) -gt 0){$best=$v}};return $best};'Python'{$d=RetryC {(Invoke-RestMethod -Uri 'https://www.python.org/api/v2/downloads/release/' -UseBasicParsing -ErrorAction Stop -TimeoutSec 15)};$best='';foreach($e in @($d)){if($e.is_prerelease){continue};$v=S3 $e.name;if($v -notmatch '^3\.13\.'){continue};if($best -eq '' -or (Cmp3 $v $best) -gt 0){$best=$v}};return $best};'VSCode'{$d=RetryC {(Invoke-RestMethod -Uri 'https://api.github.com/repos/microsoft/vscode/releases/latest' -UseBasicParsing -ErrorAction Stop -TimeoutSec 15 -Headers @{'User-Agent'='AI-Tools-Installer'})};return ([string]$d.tag_name).TrimStart('v')};'OpenClaw'{$d=RetryC {(Invoke-RestMethod -Uri 'https://registry.npmjs.org/-/package/openclaw/dist-tags' -UseBasicParsing -ErrorAction Stop -TimeoutSec 15)};return ([string]$d.latest)};'9Router'{$d=RetryC {(Invoke-RestMethod -Uri 'https://registry.npmjs.org/-/package/9router/dist-tags' -UseBasicParsing -ErrorAction Stop -TimeoutSec 15)};return (S3 $d.latest)}};return ''};"
set "S7=function Decide($it,$cur,$lat){if($it -eq 'VSCodeExt'){if($cur -ne ''){return 'SKIP'};return 'INSTALL'};if($cur -eq ''){return 'INSTALL'};if($lat -eq ''){return 'SKIP'};if($it -eq 'OpenClaw'){if($cur.CompareTo($lat) -ge 0){return 'SKIP'};return 'UPDATE'};if($it -eq 'Git'){$gc=$cur -replace '\.windows\.','.';$gl=$lat -replace '\.windows\.','.';try{if(([version]$gc).CompareTo([version]$gl) -ge 0){return 'SKIP'};return 'UPDATE'}catch{return 'SKIP'}};$c=S3 $cur;$l=S3 $lat;if($c -eq '' -or $l -eq ''){return 'SKIP'};if((Cmp3 $c $l) -ge 0){return 'SKIP'};return 'UPDATE'};"
set "S8=[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$neterr=0;$items=@(!SCAN_ITEM_LIST!);$idx=0;foreach($it in $items){$script:active=$it;E ('    '+@('|','/','-','\')[$idx%%4]+' Đang rà '+$it+'...');$cur='';try{$cur=Cur $it}catch{$cur=''};$lat='';if($it -ne 'VSCodeExt'){try{$lat=Latest $it}catch{$lat='';$neterr++}};$dec=Decide $it $cur $lat;$idx++;$pct=[int][math]::Floor(($idx*100)/$items.Count);$done=[int][math]::Floor($pct/5);E ('    ['+('#'*$done)+('.'*(20-$done))+'] '+$pct.ToString('D3')+([char]37)+'  Đã rà '+$it);P ('{0}|{1}|{2}|{3}' -f $it,(Sen $cur),(Sen $lat),$dec)};P ('NETERR|{0}' -f $neterr)"

set "PSCMD=powershell -NoProfile -ExecutionPolicy Bypass -Command "!S1!!S2!!S3!!S4!!S5!!S6!!S7!!S8!""
for /f "usebackq delims=" %%L in (`!PSCMD!`) do call :scan_parse "%%L"

set "SCAN_MISSING="
if defined SEL_Git if not defined ST_Git set "SCAN_MISSING=1"
if defined SEL_Node if not defined ST_Node set "SCAN_MISSING=1"
if defined SEL_Python if not defined ST_Python set "SCAN_MISSING=1"
if defined SEL_VSCode if not defined ST_VSCode set "SCAN_MISSING=1"
if defined SEL_VSCodeExt if not defined ST_VSCodeExt set "SCAN_MISSING=1"
if defined SEL_OpenClaw if not defined ST_OpenClaw set "SCAN_MISSING=1"
if defined SEL_9Router if not defined ST_9Router set "SCAN_MISSING=1"
if defined SCAN_MISSING (
  call :color_echo "1;31m" "Không thể đọc kết quả quét máy. Công cụ thoát an toàn."
  call :log_append "scan | fail | - | - | %date% %time%"
  endlocal
  exit /b 1
)

echo.
call :color_echo "1;36m" "KẾT QUẢ QUÉT"
call :color_echo "2;90m" "────────────────────────────────────────────────────────────────────"
call :color_echo "2;90m" "  Công cụ                 Hiện tại       Mới nhất      Quyết định"
call :scan_table_row "Git" "!ST_Git!" "!VR_Git!" "!VL_Git!"
call :scan_table_row "Node.js" "!ST_Node!" "!VR_Node!" "!VL_Node!"
call :scan_table_row "Python" "!ST_Python!" "!VR_Python!" "!VL_Python!"
call :scan_table_row "Visual Studio Code" "!ST_VSCode!" "!VR_VSCode!" "!VL_VSCode!"
call :scan_table_row "Claude Code extension" "!ST_VSCodeExt!" "!VR_VSCodeExt!" "!VL_VSCodeExt!"
call :scan_table_row "OpenClaw" "!ST_OpenClaw!" "!VR_OpenClaw!" "!VL_OpenClaw!"
call :scan_table_row "9Router" "!ST_9Router!" "!VR_9Router!" "!VL_9Router!"

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
  echo.
  call :color_echo "1;33m" "Nhấn ENTER để xem kế hoạch"
  call :press_enter
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
rem %1 = tên hiển thị, %2 = quyết định, %3 = bản hiện tại, %4 = bản mới nhất, %5 = kiểm tra latest (1/0), %6 = biến SEL
setlocal EnableDelayedExpansion
set "NAME=%~1"
set "ST=%~2"
set "VR=%~3"
set "VL=%~4"
set "NO_LAT=%~5"
set "SELVAR=%~6"
if not "%SELVAR%"=="" if not defined %SELVAR% (
  call :color_echo "2;90m" "  !NAME! — không chọn — bỏ qua"
  endlocal
  exit /b 0
)
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

:scan_table_row
rem %1=Tên, %2=Hiện tại, %3=Mới nhất, %4=Quyết định
rem Cột: Tên=26chars, Hiện tại=16chars, Mới nhất=16chars, Quyết định=16chars
setlocal EnableDelayedExpansion
set "T_NAME=%~1"
set "T_CUR=%~2"
set "T_LAT=%~3"
set "T_DEC=%~4"
if "!T_CUR!"=="-" set "T_CUR=—"
if "!T_LAT!"=="-" set "T_LAT=—"
if /i "!T_DEC!"=="INSTALL" (
  set "T_ACT=CÀI MỚI"
  set "T_COL=1;32m"
) else if /i "!T_DEC!"=="UPDATE" (
  set "T_ACT=CẬP NHẬT"
  set "T_COL=1;33m"
) else (
  set "T_ACT=GIỮ NGUYÊN"
  set "T_COL=2;90m"
)
call :pad_right "T_NAME" 26
call :pad_right "T_CUR" 16
call :pad_right "T_LAT" 16
call :color_echo "2;90m" "  !T_NAME!!T_CUR!!T_LAT!"
call :color_echo "!T_COL!" "                                         !T_ACT!"
endlocal
exit /b 0

:plan_table_row
rem %1=Tên, %2=Quyết định, %3=Hiện tại, %4=Mới nhất
rem Cột: Tên=26chars, Hiện tại=16chars, Đích=16chars, Thao tác=16chars
setlocal EnableDelayedExpansion
set "P_NAME=%~1"
set "P_ST=%~2"
set "P_VR=%~3"
set "P_VL=%~4"
if "!P_VR!"=="-" set "P_VR=Chưa có"
if "!P_VL!"=="-" set "P_VL=latest"
if /i "!P_ST!"=="INSTALL" (
  set "P_ACT=CÀI MỚI"
  set "P_COL=1;32m"
) else if /i "!P_ST!"=="UPDATE" (
  set "P_ACT=CẬP NHẬT"
  set "P_COL=1;33m"
) else (
  set "P_ACT=BỎ QUA"
  set "P_COL=2;90m"
)
call :pad_right "P_NAME" 26
call :pad_right "P_VR" 16
call :pad_right "P_VL" 16
call :color_echo "2;90m" "  !P_NAME!!P_VR!!P_VL!"
call :color_echo "!P_COL!" "                                         !P_ACT!"
endlocal
exit /b 0

:pad_right
rem %1=variable name, %2=target width
setlocal EnableDelayedExpansion
set "PAD_VAL=!%~1!"
set "PAD_LEN=0"
:pad_right_loop
if defined PAD_VAL if not "!PAD_VAL:~%PAD_LEN%1!"=="" (
  set /a PAD_LEN+=1
  goto :pad_right_loop
)
set /a PAD_NEED=%~2 - PAD_LEN
if !PAD_NEED! gtr 0 (
  set "PAD_SPACES="
  for /l %%P in (1,1,!PAD_NEED!) do set "PAD_SPACES=!PAD_SPACES! "
  set "PAD_VAL=!PAD_VAL!!PAD_SPACES!"
)
endlocal & set "%~1=%PAD_VAL%"
exit /b 0

rem --------------------------- plan ---------------------------
:plan_block
setlocal EnableDelayedExpansion
rem --- Guard: cần đủ run-state scan (ST_*) mới lập kế hoạch ---
set "PLAN_MISSING="
if defined SEL_Git if not defined ST_Git set "PLAN_MISSING=1"
if defined SEL_Node if not defined ST_Node set "PLAN_MISSING=1"
if defined SEL_Python if not defined ST_Python set "PLAN_MISSING=1"
if defined SEL_VSCode if not defined ST_VSCode set "PLAN_MISSING=1"
if defined SEL_VSCodeExt if not defined ST_VSCodeExt set "PLAN_MISSING=1"
if defined SEL_OpenClaw if not defined ST_OpenClaw set "PLAN_MISSING=1"
if defined SEL_9Router if not defined ST_9Router set "PLAN_MISSING=1"
if defined PLAN_MISSING (
  call :color_echo "1;31m" "Không đủ dữ liệu quét máy để lập kế hoạch. Công cụ thoát an toàn."
  call :log_append "plan | skip | insufficient-scan | - | %date% %time%"
  endlocal & set "PLAN_ABORT=1" & exit /b 0
)

call :color_echo "1;97m" "Bước 4/7 — Kế hoạch cài đặt — còn 3 bước"
call :color_echo "2;90m" "Chưa có gì thay đổi trên máy cho tới khi bạn xác nhận."
echo.

set "PLAN_INSTALL=0"
set "PLAN_UPDATE=0"
set "PLAN_SKIP=0"
set "PLAN_SKIP_NAMES="

call :color_echo "1;36m" "KẾ HOẠCH CÀI ĐẶT"
call :color_echo "2;90m" "────────────────────────────────────────────────────────────────────"
call :color_echo "2;90m" "  Công cụ                 Hiện tại       Đích           Thao tác"

if defined SEL_Git (
  call :plan_table_row "Git" "!ST_Git!" "!VR_Git!" "!VL_Git!"
  call :plan_count "!ST_Git!"
) else (
  set "PLAN_SKIP_NAMES=!PLAN_SKIP_NAMES!Git, "
)
if defined SEL_Node (
  call :plan_table_row "Node.js" "!ST_Node!" "!VR_Node!" "!VL_Node!"
  call :plan_count "!ST_Node!"
) else (
  set "PLAN_SKIP_NAMES=!PLAN_SKIP_NAMES!Node.js, "
)
if defined SEL_Python (
  call :plan_table_row "Python" "!ST_Python!" "!VR_Python!" "!VL_Python!"
  call :plan_count "!ST_Python!"
) else (
  set "PLAN_SKIP_NAMES=!PLAN_SKIP_NAMES!Python, "
)
if defined SEL_VSCode (
  call :plan_table_row "Visual Studio Code" "!ST_VSCode!" "!VR_VSCode!" "!VL_VSCode!"
  call :plan_count "!ST_VSCode!"
) else (
  set "PLAN_SKIP_NAMES=!PLAN_SKIP_NAMES!Visual Studio Code, "
)
if defined SEL_VSCodeExt (
  call :plan_table_row "Claude Code ext" "!ST_VSCodeExt!" "!VR_VSCodeExt!" "!VL_VSCodeExt!"
  call :plan_count "!ST_VSCodeExt!"
) else (
  set "PLAN_SKIP_NAMES=!PLAN_SKIP_NAMES!Claude Code, "
)
if defined SEL_OpenClaw (
  call :plan_table_row "OpenClaw" "!ST_OpenClaw!" "!VR_OpenClaw!" "!VL_OpenClaw!"
  call :plan_count "!ST_OpenClaw!"
) else (
  set "PLAN_SKIP_NAMES=!PLAN_SKIP_NAMES!OpenClaw, "
)
if defined SEL_9Router (
  call :plan_table_row "9Router" "!ST_9Router!" "!VR_9Router!" "!VL_9Router!"
  call :plan_count "!ST_9Router!"
) else (
  set "PLAN_SKIP_NAMES=!PLAN_SKIP_NAMES!9Router, "
)
if defined PLAN_SKIP_NAMES set "PLAN_SKIP_NAMES=!PLAN_SKIP_NAMES:~0,-2!"

echo.
if defined PLAN_SKIP_NAMES call :color_echo "2;90m" "  Bỏ qua (không chọn): !PLAN_SKIP_NAMES!"
call :color_echo "1;97m" "Tổng kết: "
call :color_echo "1;32m" "!PLAN_INSTALL! cài mới"
call :color_echo "1;97m" " · "
call :color_echo "1;33m" "!PLAN_UPDATE! cập nhật"
call :color_echo "1;97m" " · "
call :color_echo "2;90m" "!PLAN_SKIP! bỏ qua"
echo.
call :color_echo "2;90m" "Phạm vi: tài khoản hiện tại · Không cần quyền Administrator"
call :color_echo "2;90m" "Manifest: %%LOCALAPPDATA%%\AITools\manifest.txt"
call :color_echo "1;33m" "Nhấn ENTER để bắt đầu cài đặt"
call :color_echo "2;90m" "Muốn hủy? Hãy đóng cửa sổ trước khi bắt đầu."
call :press_enter
if errorlevel 1 endlocal & set "PLAN_ABORT=1" & exit /b 1
call :color_echo "1;32m" "Đã xác nhận. Bắt đầu cài đặt..."
call :log_append "plan | ok | confirmed | - | %date% %time%"
endlocal & set "PLAN_ABORT=" & exit /b 0

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
setlocal EnableDelayedExpansion
set "EXEC_RC=0"
set "RESULT_Node="
set "RESULT_Git="
set "RESULT_Python="
set "RESULT_VSCode="
set "RESULT_VSCodeExt="
set "RESULT_OpenClaw="
set "RESULT_9Router="
set "EXEC_I=0"
call :color_echo "1;97m" "Bước 5/7 — Cài đặt — còn 2 bước"
echo.
call :color_echo "2;90m" "Đang cài đặt các mục trong kế hoạch..."
echo.
if defined SEL_Node (
  set /a EXEC_I+=1
  call :progress_step !EXEC_I! "Node.js"
  call :try_install_node
  if errorlevel 1 (set "RESULT_Node=fail") else if /i "!ST_Node!"=="SKIP" (set "RESULT_Node=keep") else set "RESULT_Node=ok"
  if errorlevel 1 set "EXEC_RC=1"
) else (
  set "RESULT_Node=skip"
)
if defined SEL_Git (
  set /a EXEC_I+=1
  call :progress_step !EXEC_I! "Git"
  call :try_install_git
  if errorlevel 1 (set "RESULT_Git=fail") else if /i "!ST_Git!"=="SKIP" (set "RESULT_Git=keep") else set "RESULT_Git=ok"
  if errorlevel 1 set "EXEC_RC=1"
) else (
  set "RESULT_Git=skip"
)
if defined SEL_Python (
  set /a EXEC_I+=1
  call :progress_step !EXEC_I! "Python"
  call :try_install_python
  if errorlevel 1 (set "RESULT_Python=fail") else if /i "!ST_Python!"=="SKIP" (set "RESULT_Python=keep") else set "RESULT_Python=ok"
  if errorlevel 1 set "EXEC_RC=1"
) else (
  set "RESULT_Python=skip"
)
if defined SEL_VSCode (
  set /a EXEC_I+=1
  call :progress_step !EXEC_I! "Visual Studio Code"
  call :try_install_vscode
  if errorlevel 1 (set "RESULT_VSCode=fail") else if /i "!ST_VSCode!"=="SKIP" (set "RESULT_VSCode=keep") else set "RESULT_VSCode=ok"
  if errorlevel 1 set "EXEC_RC=1"
) else (
  set "RESULT_VSCode=skip"
)
if defined SEL_VSCodeExt (
  set /a EXEC_I+=1
  call :progress_step !EXEC_I! "Claude Code extension"
  if /i "!RESULT_VSCode!"=="fail" (
    set "RESULT_VSCodeExt=fail"
    set "EXEC_RC=1"
    call :color_echo "1;31m" "  Claude Code extension — bị chặn vì Visual Studio Code cài thất bại."
  ) else (
    call :try_install_vscodeext
    if errorlevel 1 (set "RESULT_VSCodeExt=fail") else if /i "!ST_VSCodeExt!"=="SKIP" (set "RESULT_VSCodeExt=keep") else set "RESULT_VSCodeExt=ok"
    if errorlevel 1 set "EXEC_RC=1"
  )
) else (
  set "RESULT_VSCodeExt=skip"
)
if defined SEL_OpenClaw (
  set /a EXEC_I+=1
  call :progress_step !EXEC_I! "OpenClaw"
  if /i "!RESULT_Node!"=="fail" (
    set "RESULT_OpenClaw=fail" & set "EXEC_RC=1"
    call :color_echo "1;31m" "  OpenClaw — bị chặn vì Node.js cài thất bại."
  ) else (
    call :try_install_openclaw
    if errorlevel 1 (set "RESULT_OpenClaw=fail") else if /i "!ST_OpenClaw!"=="SKIP" (set "RESULT_OpenClaw=keep") else set "RESULT_OpenClaw=ok"
    if errorlevel 1 set "EXEC_RC=1"
  )
) else (
  set "RESULT_OpenClaw=skip"
)
if defined SEL_9Router (
  set /a EXEC_I+=1
  call :progress_step !EXEC_I! "9Router"
  if /i "!RESULT_Node!"=="fail" (
    set "RESULT_9Router=fail" & set "EXEC_RC=1"
    call :color_echo "1;31m" "  9Router — bị chặn vì Node.js cài thất bại."
  ) else (
    call :try_install_9router
    if errorlevel 1 (set "RESULT_9Router=fail") else if /i "!ST_9Router!"=="SKIP" (set "RESULT_9Router=keep") else set "RESULT_9Router=ok"
    if errorlevel 1 set "EXEC_RC=1"
  )
) else (
  set "RESULT_9Router=skip"
)
echo.
if "!EXEC_RC!"=="0" (
  call :color_echo "1;32m" "Bước cài đặt hoàn tất."
) else (
  call :color_echo "1;31m" "Bước cài đặt có lỗi ở một hoặc nhiều mục. Xem log để biết chi tiết."
)
endlocal & set "RESULT_Node=%RESULT_Node%" & set "RESULT_Git=%RESULT_Git%" & set "RESULT_Python=%RESULT_Python%" & set "RESULT_VSCode=%RESULT_VSCode%" & set "RESULT_VSCodeExt=%RESULT_VSCodeExt%" & set "RESULT_OpenClaw=%RESULT_OpenClaw%" & set "RESULT_9Router=%RESULT_9Router%" & set "EXEC_RC=%EXEC_RC%" & exit /b %EXEC_RC%

rem --------------------------- configure ---------------------------
rem Tạo đúng một combo qua API quản trị cục bộ của 9Router. API này chỉ
rem đọc/ghi danh sách combo; tuyệt đối không gửi hoặc đọc API key.
:configure_block
setlocal EnableDelayedExpansion
set "CONFIGURE_RC=0"
set "RESULT_9Router_Combo=skip"
set "RESULT_9Router_Autostart=skip"
set "RESULT_9Router_Onboarding=skip"
set "RESULT_OpenClaw_Autostart=skip"
set "RESULT_OpenClaw_Onboarding=skip"
call :color_echo "1;97m" "Bước 6/7 — Cấu hình lần đầu — combo, khởi động cùng Windows và dashboard"
echo.
if defined SEL_9Router if /i not "%RESULT_9Router%"=="fail" (
  call :configure_9router_combo
  if errorlevel 1 (
    set "RESULT_9Router_Combo=fail"
    set "CONFIGURE_RC=1"
    call :color_echo "1;33m" "  Chưa tạo được combo my-combo. Mở 9Router rồi chạy lại để thử lại; không có API key nào bị đụng tới."
  ) else (
    set "RESULT_9Router_Combo=ok"
    call :color_echo "1;32m" "  Combo my-combo đã sẵn sàng (deepseek-v4-flash + 3 đường dự phòng)."
  )
)
if defined SEL_9Router if /i not "%RESULT_9Router%"=="fail" (
  call :configure_autostart_for 9Router
  if errorlevel 1 (set "RESULT_9Router_Autostart=fail") else set "RESULT_9Router_Autostart=ok"
  if errorlevel 1 set "CONFIGURE_RC=1"
  call :configure_onboarding_for 9Router
  if errorlevel 1 (set "RESULT_9Router_Onboarding=fail") else set "RESULT_9Router_Onboarding=ok"
  if errorlevel 1 set "CONFIGURE_RC=1"
)
if defined SEL_OpenClaw if /i not "%RESULT_OpenClaw%"=="fail" (
  call :configure_autostart_for OpenClaw
  if errorlevel 1 (set "RESULT_OpenClaw_Autostart=fail") else set "RESULT_OpenClaw_Autostart=ok"
  if errorlevel 1 set "CONFIGURE_RC=1"
  call :configure_onboarding_for OpenClaw
  if errorlevel 1 (set "RESULT_OpenClaw_Onboarding=fail") else set "RESULT_OpenClaw_Onboarding=ok"
  if errorlevel 1 set "CONFIGURE_RC=1"
)
endlocal & exit /b %CONFIGURE_RC%

:configure_autostart_for
setlocal
if /i "%~1"=="9Router" set "SEL_OpenClaw="
if /i "%~1"=="OpenClaw" set "SEL_9Router="
call :configure_autostart
set "ONE_CONFIG_RC=%errorlevel%"
endlocal & exit /b %ONE_CONFIG_RC%

:configure_onboarding_for
setlocal
if /i "%~1"=="9Router" set "SEL_OpenClaw="
if /i "%~1"=="OpenClaw" set "SEL_9Router="
call :configure_onboarding
set "ONE_CONFIG_RC=%errorlevel%"
endlocal & exit /b %ONE_CONFIG_RC%

:configure_9router_combo
if not defined LOCALAPPDATA goto :configure_combo_fail
set "COMBO_URL=http://127.0.0.1:20128/api/combos"
set "COMBO_RESULT="
set "COMBO_ACTION="
set "COMBO_VERSION=deepseek-v4-flash"

rem 9Router quản lý combo qua /api/combos (GET/POST/PUT). Không gửi Authorization.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ErrorActionPreference='Stop';$u=$env:COMBO_URL;$want=@('oc/deepseek-v4-flash-free','openrouter/deepseek-v4-flash','ds/deepseek-v4-flash');$payload=[ordered]@{name='my-combo';models=$want}|ConvertTo-Json -Compress;$r=Invoke-RestMethod -Uri $u -Method Get -UseBasicParsing -TimeoutSec 10;$all=@();if($r.combos){$all=@($r.combos)}elseif($r -is [array]){$all=@($r)};$found=$all|?{$_.name -eq 'my-combo'}|Select-Object -First 1;if($found){$actual=@($found.models|ForEach-Object {[string]$_});$same=($actual.Count -eq $want.Count -and (($actual -join [char]0x1f) -ceq ($want -join [char]0x1f)));if(-not $same){if(-not $found.id){throw 'combo-id-missing'};Invoke-RestMethod -Uri ($u+'/'+[uri]::EscapeDataString([string]$found.id)) -Method Put -Body $payload -ContentType 'application/json' -UseBasicParsing -TimeoutSec 10|Out-Null;$action='updated'}else{$action='skipped'}}else{Invoke-RestMethod -Uri $u -Method Post -Body $payload -ContentType 'application/json' -UseBasicParsing -TimeoutSec 10|Out-Null;$action='created'};[IO.File]::WriteAllText($env:TEMP+'\aitools-combo-result.txt',$action,[Text.UTF8Encoding]::new($false))" >nul 2>nul
if errorlevel 1 goto :configure_combo_fail
if exist "%TEMP%\aitools-combo-result.txt" for /f "usebackq delims=" %%a in ("%TEMP%\aitools-combo-result.txt") do set "COMBO_ACTION=%%a"
if exist "%TEMP%\aitools-combo-result.txt" del /f /q "%TEMP%\aitools-combo-result.txt" >nul 2>nul
if not defined COMBO_ACTION goto :configure_combo_fail
call :manifest_append "9Router combo my-combo" "%COMBO_VERSION%" "%COMBO_URL%"
if errorlevel 1 goto :configure_combo_fail
call :log_append "configure | ok | %COMBO_VERSION% | my-combo (%COMBO_ACTION%) | %date% %time%"
exit /b 0

:configure_combo_fail
if exist "%TEMP%\aitools-combo-result.txt" del /f /q "%TEMP%\aitools-combo-result.txt" >nul 2>nul
call :log_append "configure | fail | %COMBO_VERSION% | my-combo | %date% %time%"
exit /b 1

rem --------------------- autostart + onboarding ---------------------
rem Run key dùng HKCU, không cần UAC. PowerShell được chạy ẩn và khởi
rem chạy tiến trình đích ẩn để không nhấp nháy cửa sổ console khi đăng nhập.
:configure_autostart
set "AUTOSTART_RC=0"
if not defined LOCALAPPDATA set "LOCALAPPDATA=%TEMP%"
set "AUTOSTART_ID="
for /f "delims=" %%g in ('powershell -NoProfile -Command "[guid]::NewGuid().ToString('N')"') do set "AUTOSTART_ID=%%g"
if not defined AUTOSTART_ID goto :autostart_fail
set "AUTOSTART_RESULT=%TEMP%\aitools-autostart-%AUTOSTART_ID%.txt"
set "AUTOSTART_9R_DONE="
set "AUTOSTART_OC_DONE="
set "NINE_CMD_PATH="
set "OC_CMD_PATH="
for /f "delims=" %%p in ('where.exe 9router.cmd 2^>nul') do if not defined NINE_CMD_PATH set "NINE_CMD_PATH=%%p"
for /f "delims=" %%p in ('where.exe openclaw.cmd 2^>nul') do if not defined OC_CMD_PATH set "OC_CMD_PATH=%%p"
if defined SEL_9Router if not defined NINE_CMD_PATH (
  call :color_echo "1;33m" "  Không tìm thấy 9router.cmd trong PATH; bỏ qua autostart 9Router."
  set "SEL_9Router="
)
if defined SEL_OpenClaw if not defined OC_CMD_PATH (
  call :color_echo "1;33m" "  Không tìm thấy openclaw.cmd trong PATH; bỏ qua autostart OpenClaw."
  set "SEL_OpenClaw="
)
set "AUTOSTART_9R_TARGET=powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command Start-Process -FilePath '%NINE_CMD_PATH%' -ArgumentList @('--no-browser','--skip-update') -WindowStyle Hidden"
set "AUTOSTART_OC_TARGET=%OC_CMD_PATH% gateway install"

rem 9Router (chỉ khi chọn): ghi HKCU Run khi value chưa có hoặc khác target đã quản lý.
if defined SEL_9Router (
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
   "$ErrorActionPreference='Stop';$name='AI Tools Installer - 9Router';$target=$env:AUTOSTART_9R_TARGET;$k=[Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Software\Microsoft\Windows\CurrentVersion\Run');try{$old=[string]$k.GetValue($name,'',[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames);$changed=($old -cne $target);if($changed){$k.SetValue($name,$target,[Microsoft.Win32.RegistryValueKind]::String)};[IO.File]::WriteAllText($env:AUTOSTART_RESULT,('9router|'+$(if($changed){'registered'}else{'existing'})+'|'+$target),[Text.UTF8Encoding]::new($false))}finally{$k.Dispose()}" >nul 2>nul
  if errorlevel 1 goto :autostart_fail
  if not exist "%AUTOSTART_RESULT%" goto :autostart_fail
  for /f "usebackq tokens=1,2,* delims=|" %%a in ("%AUTOSTART_RESULT%") do set "AUTOSTART_9R_STATE=%%b"
  if /i not "%AUTOSTART_9R_STATE%"=="existing" if /i not "%AUTOSTART_9R_STATE%"=="registered" goto :autostart_fail
  call :manifest_append "Autostart:HKCU Run:AI Tools Installer - 9Router" "registered" "%AUTOSTART_9R_TARGET%"
  if errorlevel 1 goto :autostart_fail
  call :log_append "configure | ok | registered | HKCU Run 9Router (%AUTOSTART_9R_TARGET%) | %date% %time%"
  set "AUTOSTART_9R_DONE=1"
)

rem OpenClaw (chỉ khi chọn): dùng cơ chế cài gateway chính thức; lệnh được chạy
rem ẩn và bản thân OpenClaw đảm bảo việc đăng ký lặp lại là idempotent.
if defined SEL_OpenClaw (
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
   "$ErrorActionPreference='Stop';$p=Start-Process -FilePath 'openclaw.cmd' -ArgumentList @('gateway','install') -WindowStyle Hidden -Wait -PassThru;if($p.ExitCode -ne 0){exit $p.ExitCode};[IO.File]::AppendAllText($env:AUTOSTART_RESULT,([Environment]::NewLine+'openclaw|installed|openclaw gateway install'),[Text.UTF8Encoding]::new($false))" >nul 2>nul
  if errorlevel 1 goto :autostart_fail
  call :manifest_append "Autostart:OpenClaw gateway" "registered" "%AUTOSTART_OC_TARGET%"
  if errorlevel 1 goto :autostart_fail
  call :log_append "configure | ok | registered | OpenClaw gateway (%AUTOSTART_OC_TARGET%) | %date% %time%"
  set "AUTOSTART_OC_DONE=1"
)

if exist "%AUTOSTART_RESULT%" del /f /q "%AUTOSTART_RESULT%" >nul 2>nul
if defined AUTOSTART_9R_DONE if defined AUTOSTART_OC_DONE call :color_echo "1;32m" "  Đã đăng ký 9Router và OpenClaw tự khởi động cùng Windows (không hiện cửa sổ console)."
if defined AUTOSTART_9R_DONE if not defined AUTOSTART_OC_DONE call :color_echo "1;32m" "  Đã đăng ký 9Router tự khởi động cùng Windows (không hiện cửa sổ console)."
if not defined AUTOSTART_9R_DONE if defined AUTOSTART_OC_DONE call :color_echo "1;32m" "  Đã đăng ký OpenClaw tự khởi động cùng Windows (không hiện cửa sổ console)."
exit /b 0

:autostart_fail
if exist "%AUTOSTART_RESULT%" del /f /q "%AUTOSTART_RESULT%" >nul 2>nul
call :log_append "configure | fail | autostart | HKCU Run/OpenClaw gateway | %date% %time%"
call :color_echo "1;33m" "  Chưa đăng ký được tự khởi động. Chạy lại công cụ để thử lại; các mục khác vẫn được giữ nguyên."
exit /b 1

:configure_onboarding
set "OB_RC=0"
if defined SEL_9Router call :color_echo "1;97m" "  Mở dashboard 9Router..."
if defined SEL_OpenClaw call :color_echo "1;97m" "  Mở giao diện OpenClaw..."
if defined SEL_9Router call :color_echo "2;90m" "  Trong 9Router, tự nhập API key của bạn trong dashboard. Công cụ không đọc hoặc lưu key."
call :color_echo "2;90m" "  Hoàn tất kết nối đầu tiên và onboarding ngay trên giao diện vừa mở."
if defined SEL_9Router (
  start "" "http://localhost:20128"
  if errorlevel 1 set "OB_RC=1"
)
if defined SEL_OpenClaw (
  start "" "http://127.0.0.1:18789"
  if errorlevel 1 set "OB_RC=1"
)
if not "%OB_RC%"=="0" goto :onboarding_fail
call :log_append "configure | ok | - | dashboards | %date% %time%"
exit /b 0

rem ----------------------------- report -----------------------------
rem Báo cáo cuối luôn chạy sau configure. Log cũ được giữ nguyên.
:report_block
setlocal EnableDelayedExpansion
set "REPORT_TOTAL=0"
set "REPORT_OK=0"
set "REPORT_KEEP=0"
set "REPORT_FAIL=0"
set "REPORT_ERRORS="
if /i "!RESULT_9Router_Combo!"=="fail" set "RESULT_9Router=fail"
if /i "!RESULT_9Router_Autostart!"=="fail" set "RESULT_9Router=fail"
if /i "!RESULT_9Router_Onboarding!"=="fail" set "RESULT_9Router=fail"
if /i "!RESULT_OpenClaw_Autostart!"=="fail" set "RESULT_OpenClaw=fail"
if /i "!RESULT_OpenClaw_Onboarding!"=="fail" set "RESULT_OpenClaw=fail"
for %%I in (Node Git Python VSCode VSCodeExt OpenClaw 9Router) do (
  if /i "!RESULT_%%I!"=="skip" (
    rem không chọn / không áp dụng — không đếm
  ) else (
    set /a REPORT_TOTAL+=1
    if /i "!RESULT_%%I!"=="ok" (
      set /a REPORT_OK+=1
    ) else if /i "!RESULT_%%I!"=="keep" (
      set /a REPORT_KEEP+=1
    ) else (
      set /a REPORT_FAIL+=1
      if defined REPORT_ERRORS (set "REPORT_ERRORS=!REPORT_ERRORS!, %%I") else set "REPORT_ERRORS=%%I"
    )
  )
)
if not defined LOCALAPPDATA set "LOCALAPPDATA=%TEMP%"
set "REPORT_LOG=%LOCALAPPDATA%\AITools\logs\ai-tools-installer.log"
set "REPORT_MANIFEST=%LOCALAPPDATA%\AITools\manifest.txt"
call :color_echo "1;36m" "HOÀN TẤT"
call :color_echo "2;90m" "────────────────────────────────────────────────────────────────────"
call :report_item "Node.js" "!RESULT_Node!"
call :report_item "Git" "!RESULT_Git!"
call :report_item "Python" "!RESULT_Python!"
call :report_item "Visual Studio Code" "!RESULT_VSCode!"
call :report_item "Claude Code extension" "!RESULT_VSCodeExt!"
call :report_item "OpenClaw" "!RESULT_OpenClaw!"
call :report_item "9Router" "!RESULT_9Router!"
echo.
if "!REPORT_FAIL!"=="0" (
  set "REPORT_STATUS=ok"
  call :color_echo "1;32m" "Kết quả: !REPORT_OK! thành công · !REPORT_KEEP! giữ nguyên · 0 lỗi"
) else (
  set "REPORT_STATUS=fail"
  call :color_echo "1;33m" "Kết quả: !REPORT_OK! thành công · !REPORT_KEEP! giữ nguyên · !REPORT_FAIL! lỗi"
  call :color_echo "1;31m" "  Mục lỗi: !REPORT_ERRORS!"
  call :color_echo "2;90m" "  Vui lòng chạy lại công cụ để thử lại các mục lỗi."
)
call :color_echo "2;90m" "  PATH được giữ hoặc cập nhật theo kết quả cài đặt ở trên."
call :color_echo "2;90m" "  Log: !REPORT_LOG!"
call :color_echo "2;90m" "  Manifest: !REPORT_MANIFEST!"
call :log_append "report | !REPORT_STATUS! | !REPORT_OK!/!REPORT_TOTAL! | !REPORT_LOG! | %date% %time%"
call :color_echo "1;33m" "Nhấn R để xem lại từ đầu"
:report_wait_review
call :read_raw_key
if errorlevel 1 endlocal & exit /b 1
if /i not "!RAW_KEY!"=="r" goto :report_wait_review
endlocal & exit /b 2

:report_item
if /i "%~2"=="skip" exit /b 0
if /i "%~2"=="keep" (call :color_echo "2;90m" "  — %~1 — đã có, giữ nguyên" & exit /b 0)
if /i "%~2"=="ok" (call :color_echo "1;32m" "  ✓ %~1 — đã hoàn tất và xác minh" & exit /b 0)
call :color_echo "1;31m" "  X %~1 — lỗi hoặc không xác định được kết quả"
exit /b 0

:onboarding_fail
call :log_append "configure | fail | - | dashboards | %date% %time%"
call :color_echo "1;33m" "  Không mở được trình duyệt tự động. Bạn có thể mở localhost:20128 và 127.0.0.1:18789 sau khi hoàn tất."
exit /b 1

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
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=[IO.Path]::GetFullPath($env:NPM_SOURCE);$u=[IO.Path]::GetFullPath($env:LOCALAPPDATA);$a=[IO.Path]::GetFullPath($env:APPDATA);if($p.StartsWith($u+'\',[StringComparison]::OrdinalIgnoreCase) -or ($a -and $p.StartsWith($a+'\',[StringComparison]::OrdinalIgnoreCase))){exit 0};exit 1" >nul 2>nul
if errorlevel 1 exit /b 1
set "NPM_CMD=npm.cmd"
for /f "delims=" %%p in ('npm.cmd prefix -g 2^>nul') do if not defined NPM_PREFIX set "NPM_PREFIX=%%p"
if not defined NPM_PREFIX exit /b 1
for /f "delims=" %%p in ('npm.cmd bin -g 2^>nul') do if not defined NPM_BIN set "NPM_BIN=%%p"
if not defined NPM_BIN set "NPM_BIN=%NPM_PREFIX%"
for /f "delims=" %%p in ("%NPM_PREFIX%") do set "NPM_PREFIX=%%p"
for /f "delims=" %%p in ("%NPM_BIN%") do set "NPM_BIN=%%p"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=[IO.Path]::GetFullPath($env:NPM_PREFIX);$u=[IO.Path]::GetFullPath($env:LOCALAPPDATA);$a=[IO.Path]::GetFullPath($env:APPDATA);if($p.StartsWith($u+'\',[StringComparison]::OrdinalIgnoreCase) -or ($a -and $p.StartsWith($a+'\',[StringComparison]::OrdinalIgnoreCase))){exit 0};exit 1" >nul 2>nul
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
  call :color_echo "1;36m" "  OpenClaw — npm đang tải, giải nén và liên kết gói (lần %%a/3)..."
  if "%NPM_ALLOW_SCRIPTS%"=="" (npm.cmd install -g openclaw@latest --progress=true --loglevel=notice) else (npm.cmd install -g openclaw@latest %NPM_ALLOW_SCRIPTS% --progress=true --loglevel=notice)
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
  call :color_echo "1;36m" "  9Router — npm đang tải, giải nén và liên kết gói (lần %%a/3)..."
  npm.cmd install -g 9router --progress=true --loglevel=notice
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
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';try{$p=Start-Process -FilePath $env:VSCODE_INSTALLER -ArgumentList @('/VERYSILENT','/NORESTART','/MERGETASKS=!runcode') -PassThru;if($null -eq $p){throw 'start-failed'};$s=@('|','/','-','\');$i=0;$sw=[Diagnostics.Stopwatch]::StartNew();while(-not $p.HasExited){if($sw.Elapsed.TotalMinutes -gt 30){Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue;Write-Host (([char]13)+'  X Visual Studio Code cài đặt quá thời gian.             ') -ForegroundColor Red;exit 124};Write-Host (([char]13)+'  '+$s[$i%%4]+' Đang cài Visual Studio Code... '+[int]$sw.Elapsed.TotalSeconds+'s') -NoNewline -ForegroundColor Cyan;Start-Sleep -Milliseconds 140;$i++};if($p.ExitCode -eq 0){Write-Host (([char]13)+'  OK Đã cài xong Visual Studio Code.                    ') -ForegroundColor Green}else{Write-Host (([char]13)+'  X Visual Studio Code cài lỗi, mã '+$p.ExitCode+'.      ') -ForegroundColor Red};exit $p.ExitCode}catch{Write-Host (([char]13)+'  X Không thể chạy trình cài Visual Studio Code.        ') -ForegroundColor Red;exit 1}"
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
call :download_with_progress "%VSCODE_URL%" "%VSCODE_INSTALLER%" "Visual Studio Code"
exit /b %errorlevel%

:vscode_signature
rem Signature validation is mandatory when Authenticode is available.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$c=Get-Command Get-AuthenticodeSignature -ErrorAction SilentlyContinue;if($null -eq $c){exit 1};$s=Get-AuthenticodeSignature -LiteralPath $env:VSCODE_INSTALLER;if($s.Status -ne 'Valid' -or $s.SignerCertificate.Subject -notmatch 'Microsoft Corporation'){exit 1};exit 0" >nul 2>nul
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
set "VSCODE_EXT_OLD_PATH=%PATH%"
if not defined LOCALAPPDATA goto :ivse_missing
set "VSCODE_DIR=%LOCALAPPDATA%\Programs\Microsoft VS Code"
set "VSCODE_CODE=%LOCALAPPDATA%\Programs\Microsoft VS Code\bin\code.cmd"
if not exist "%VSCODE_CODE%" goto :ivse_missing
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
for /l %%r in (1,1,3) do (
  call :download_with_progress "%PY_URL%" "%PY_INSTALLER%" "Python %PY_VER%"
  if not errorlevel 1 (
    call :color_echo "1;36m" "  Đang xác minh chữ ký Python Software Foundation..."
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$sig=Get-AuthenticodeSignature -LiteralPath $env:PY_INSTALLER;if($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notmatch '(?i)Python Software Foundation'){exit 1}" >nul 2>nul
    if not errorlevel 1 goto :ipy_package_ready
  )
  if exist "%PY_INSTALLER%" del /f /q "%PY_INSTALLER%" >nul 2>nul
  call :color_echo "1;33m" "  Gói Python chưa hợp lệ — tải lại toàn bộ (lần %%r/3)."
)
goto :ipy_package_fail
:ipy_package_ready
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
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';try{$p=Start-Process -FilePath $env:PY_INSTALLER -ArgumentList @('InstallAllUsers=0','Include_launcher=0','PrependPath=0','Shortcuts=0','Include_test=0','/quiet','/norestart') -PassThru;if($null -eq $p){throw 'start-failed'};$s=@('|','/','-','\');$i=0;$sw=[Diagnostics.Stopwatch]::StartNew();while(-not $p.HasExited){if($sw.Elapsed.TotalMinutes -gt 30){Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue;Write-Host (([char]13)+'  X Python cài đặt quá thời gian.                        ') -ForegroundColor Red;exit 124};Write-Host (([char]13)+'  '+$s[$i%%4]+' Đang cài Python... '+[int]$sw.Elapsed.TotalSeconds+'s') -NoNewline -ForegroundColor Cyan;Start-Sleep -Milliseconds 140;$i++};if($p.ExitCode -eq 0){Write-Host (([char]13)+'  OK Đã cài xong Python.                                ') -ForegroundColor Green}else{Write-Host (([char]13)+'  X Python cài lỗi, mã '+$p.ExitCode+'.                  ') -ForegroundColor Red};exit $p.ExitCode}catch{Write-Host (([char]13)+'  X Không thể chạy trình cài Python.                    ') -ForegroundColor Red;exit 1}"
if errorlevel 1 goto :ipy_install_fail
call :path_append "%%LOCALAPPDATA%%\Programs\Python\Python313"
if errorlevel 1 goto :ipy_path_fail
call :path_append "%%LOCALAPPDATA%%\Programs\Python\Python313\Scripts"
if errorlevel 1 goto :ipy_path_fail
call :python_path_prioritize
if errorlevel 1 goto :ipy_path_fail
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$expected=(Get-Item -LiteralPath $env:PY_EXE -ErrorAction Stop).FullName;$v=(& $expected --version|Out-String).Trim();if($LASTEXITCODE -ne 0 -or $v -notmatch ('^Python\s+'+[regex]::Escape($env:PY_VER)+'$')){exit 1};$cmd=(Get-Command python -CommandType Application -ErrorAction Stop|Select-Object -First 1).Source;if((Get-Item -LiteralPath $cmd).FullName -ine $expected){exit 1};$v=(& python --version|Out-String).Trim();if($LASTEXITCODE -ne 0 -or $v -notmatch ('^Python\s+'+[regex]::Escape($env:PY_VER)+'$')){exit 1}" >nul 2>nul
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
for /l %%r in (1,1,3) do (
  call :download_with_progress "%GIT_URL%" "%GIT_ZIP%" "Git %GIT_VER%"
  if not errorlevel 1 (
    call :color_echo "1;36m" "  Đang giải nén và xác minh Git..."
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';if(Test-Path -LiteralPath $env:GIT_STAGE){Remove-Item -LiteralPath $env:GIT_STAGE -Recurse -Force};New-Item -ItemType Directory -Path $env:GIT_STAGE|Out-Null;Expand-Archive -LiteralPath $env:GIT_ZIP -DestinationPath $env:GIT_STAGE -Force;$exe=Join-Path $env:GIT_STAGE 'cmd\git.exe';if(-not (Test-Path -LiteralPath $exe -PathType Leaf)){throw 'missing'};$out=& $exe --version;if($LASTEXITCODE -ne 0 -or $out -notmatch ('^git version '+[regex]::Escape($env:GIT_VER)+'(?:\s|$)')){throw 'version'}" >nul 2>nul
    if not errorlevel 1 goto :igit_package_ready
  )
  if exist "%GIT_ZIP%" del /f /q "%GIT_ZIP%" >nul 2>nul
  if exist "%GIT_STAGE%" rmdir /s /q "%GIT_STAGE%" >nul 2>nul
  call :color_echo "1;33m" "  Gói Git chưa hợp lệ — tải lại toàn bộ (lần %%r/3)."
)
goto :igit_package_fail
:igit_package_ready

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

powershell -NoProfile -ExecutionPolicy Bypass -Command "$expected=(Get-Item -LiteralPath (Join-Path $env:GIT_DIR 'cmd\git.exe') -ErrorAction Stop).FullName;$direct=& $expected --version;if($LASTEXITCODE -ne 0 -or $direct -notmatch ('^git version '+[regex]::Escape($env:GIT_VER)+'(?:\s|$)')){exit 1};$cmd=(Get-Command git -CommandType Application -ErrorAction Stop|Select-Object -First 1).Source;if((Get-Item -LiteralPath $cmd).FullName -ine $expected){exit 1};$session=& git --version;if($LASTEXITCODE -ne 0 -or $session -notmatch ('^git version '+[regex]::Escape($env:GIT_VER)+'(?:\s|$)')){exit 1}" >nul 2>nul
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
set "NODE_BACKUP=%TEMP%\node-backup-%RANDOM%-%RANDOM%"

rem --- Tải ZIP với phần trăm byte thật và retry 3 lần ---
call :download_with_progress "%NODE_URL%" "%NODE_ZIP%" "Node.js %NODE_VER%"
if errorlevel 1 goto :inode_download_fail

rem --- Xác minh hash SHA-256 ---
call :color_echo "1;36m" "  Đang xác minh tính toàn vẹn..."
set "NODE_SHASUM_URL=https://nodejs.org/dist/v%NODE_VER%/SHASUMS256.txt"
set "NODE_SHASUM=%TEMP%\node-v%NODE_VER%-SHASUMS256.txt"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;Invoke-RestMethod -Uri '%NODE_SHASUM_URL%' -OutFile '%NODE_SHASUM%' -TimeoutSec 15 -Headers @{'User-Agent'='AI-Tools-Installer'}" >nul 2>nul
if errorlevel 1 (
  call :color_echo "1;33m" "  Không tải được SHASUMS256.txt; bỏ qua xác minh hash."
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$zip='%NODE_ZIP%';$sums='%NODE_SHASUM%';$expected=(Get-Content -LiteralPath $sums)|?{$_ -match 'node-v%NODE_VER%-win-x64\.zip'}|Select-Object -First 1;if($null -eq $expected){throw 'no-hash-entry'};$hash=($expected -split '\s+')[0];$actual=(Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash;if($actual -ne $hash){throw 'hash-mismatch'}" >nul 2>nul
  if errorlevel 1 (
    call :color_echo "1;31m" "  Hash SHA-256 không khớp; file tải về có thể bị hỏng."
    del /f /q "%NODE_ZIP%" >nul 2>nul
    goto :inode_download_fail
  )
  call :color_echo "1;32m" "  Đã xác minh hash SHA-256."
)
if exist "%NODE_SHASUM%" del /f /q "%NODE_SHASUM%" >nul 2>nul

echo.
call :color_echo "1;97m" "  Đã tải xong. Đang giải nén vào %LOCALAPPDATA%\node ..."

if exist "%NODE_DIR%" move /y "%NODE_DIR%" "%NODE_BACKUP%" >nul 2>nul
if exist "%NODE_DIR%" goto :inode_extract_fail

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
if errorlevel 1 goto :inode_manifest_fail

call :log_append "install | ok | %NODE_VER% | %NODE_DIR% | %date% %time%"
if exist "%NODE_ZIP%" del /f /q "%NODE_ZIP%" >nul 2>nul
if exist "%NODE_STAGE%" rmdir /s /q "%NODE_STAGE%" >nul 2>nul
if exist "%NODE_BACKUP%" rmdir /s /q "%NODE_BACKUP%" >nul 2>nul
call :color_echo "1;32m" "  Node.js %NODE_VER% đã cài xong."
exit /b 0

:inode_unknown
call :color_echo "1;31m" "  Không xác định được phiên bản Node.js để cài. Bỏ qua."
call :color_echo "2;90m" "  Kiểm tra kết nối mạng rồi chạy lại. Không có gì trên máy bị thay đổi."
call :log_append "install | skip | unknown-version | - | %date% %time%"
exit /b 1

:inode_download_fail
if exist "%NODE_BACKUP%" move /y "%NODE_BACKUP%" "%NODE_DIR%" >nul 2>nul
call :color_echo "1;31m" "  Tải Node.js %VL_Node% thất bại. Kiểm tra kết nối mạng rồi chạy lại."
call :color_echo "2;90m" "  Lỗi tải một mục không làm ảnh hưởng các mục khác."
call :log_append "install | fail | %VL_Node% | download-failed | %date% %time%"
exit /b 1

:inode_extract_fail
if exist "%NODE_BACKUP%" move /y "%NODE_BACKUP%" "%NODE_DIR%" >nul 2>nul
call :color_echo "1;31m" "  Giải nén Node.js thất bại. Chạy lại để thử lần nữa."
call :log_append "install | fail | %VL_Node% | extract-failed | %date% %time%"
exit /b 1

:inode_verify_fail
if exist "%NODE_BACKUP%" move /y "%NODE_BACKUP%" "%NODE_DIR%" >nul 2>nul
call :color_echo "1;31m" "  Đã cài Node.js nhưng lệnh node/npm chưa chạy được. Kiểm tra PATH rồi chạy lại."
call :log_append "install | fail | %VL_Node% | verify-failed | %date% %time%"
exit /b 1

:inode_path_fail
if exist "%NODE_BACKUP%" move /y "%NODE_BACKUP%" "%NODE_DIR%" >nul 2>nul
call :color_echo "1;31m" "  Không ghi được PATH người dùng. Kiểm tra quyền rồi chạy lại."
call :log_append "install | fail | %VL_Node% | path-write-failed | %date% %time%"
exit /b 1

:inode_manifest_fail
if exist "%NODE_BACKUP%" move /y "%NODE_BACKUP%" "%NODE_DIR%" >nul 2>nul
call :color_echo "1;31m" "  Không ghi được manifest Node.js; bản cũ được phục hồi."
call :log_append "install | fail | %VL_Node% | manifest-failed | %date% %time%"
exit /b 1

rem --------------------------- uninstall ---------------------------
:uninstall_manifest
call :manifest_validate
if errorlevel 1 (
  call :color_echo "1;31m" "Manifest không hợp lệ; dừng gỡ cài đặt để bảo vệ dữ liệu."
  call :log_append "uninstall | fail | - | invalid-manifest | %date% %time%"
  exit /b 1
)
set "UNINSTALL_RESULT=%TEMP%\aitools-uninstall-%RANDOM%-%RANDOM%.txt"
if exist "%UNINSTALL_RESULT%" del /f /q "%UNINSTALL_RESULT%" >nul 2>nul
set "UNINSTALL_MANIFEST=%LOCALAPPDATA%\AITools\manifest.txt"
goto :uninstall_manifest_fixed2
:uninstall_manifest_fixed2
powershell -NoProfile -ExecutionPolicy Bypass -EncodedCommand JABFAHIAcgBvAHIAQQBjAHQAaQBvAG4AUAByAGUAZgBlAHIAZQBuAGMAZQA9ACcAUwB0AG8AcAAnADsAJABkAD0AWwBjAGgAYQByAF0AMQAyADQAOwAkAG0APQAkAGUAbgB2ADoAVQBOAEkATgBTAFQAQQBMAEwAXwBNAEEATgBJAEYARQBTAFQAOwAkAG8AdQB0AD0AJABlAG4AdgA6AFUATgBJAE4AUwBUAEEATABMAF8AUgBFAFMAVQBMAFQAOwAkAHIAZQBtAG8AdgBlAGQAPQAwADsAJABzAGsAaQBwAHAAZQBkAD0AMAA7ACQAZgBhAGkAbABlAGQAPQAwADsAJAByAG8AbwB0AD0AWwBFAG4AdgBpAHIAbwBuAG0AZQBuAHQAXQA6ADoARQB4AHAAYQBuAGQARQBuAHYAaQByAG8AbgBtAGUAbgB0AFYAYQByAGkAYQBiAGwAZQBzACgAJwAlAEwATwBDAEEATABBAFAAUABEAEEAVABBACUAJwApADsAJABhAGwAbABvAHcAZQBkAD0AQAAoACgASgBvAGkAbgAtAFAAYQB0AGgAIAAkAHIAbwBvAHQAIAAnAG4AbwBkAGUAJwApACwAKABKAG8AaQBuAC0AUABhAHQAaAAgACQAcgBvAG8AdAAgACcAUAByAG8AZwByAGEAbQBzAFwARwBpAHQAJwApACwAKABKAG8AaQBuAC0AUABhAHQAaAAgACQAcgBvAG8AdAAgACcAUAByAG8AZwByAGEAbQBzAFwAUAB5AHQAaABvAG4AXABQAHkAdABoAG8AbgAzADEAMwAnACkALAAoAEoAbwBpAG4ALQBQAGEAdABoACAAJAByAG8AbwB0ACAAJwBQAHIAbwBnAHIAYQBtAHMAXABNAGkAYwByAG8AcwBvAGYAdAAgAFYAUwAgAEMAbwBkAGUAJwApACkAOwBmAG8AcgBlAGEAYwBoACgAJABsAGkAbgBlACAAaQBuACAAWwBJAE8ALgBGAGkAbABlAF0AOgA6AFIAZQBhAGQATABpAG4AZQBzACgAJABtACkAKQB7ACQAcAA9ACQAbABpAG4AZQAuAFMAcABsAGkAdAAoAFsAcwB0AHIAaQBuAGcAWwBdAF0AQAAoACcAIAAnACsAJABkACsAJwAgACcAKQAsAFsAUwB0AHIAaQBuAGcAUwBwAGwAaQB0AE8AcAB0AGkAbwBuAHMAXQA6ADoATgBvAG4AZQApADsAaQBmACgAJABwAC4AQwBvAHUAbgB0ACAALQBuAGUAIAA0ACkAewAkAGYAYQBpAGwAZQBkACsAKwA7AGMAbwBuAHQAaQBuAHUAZQB9ADsAJABpAHQAZQBtAD0AJABwAFsAMABdADsAJAByAGEAdwA9AFsARQBuAHYAaQByAG8AbgBtAGUAbgB0AF0AOgA6AEUAeABwAGEAbgBkAEUAbgB2AGkAcgBvAG4AbQBlAG4AdABWAGEAcgBpAGEAYgBsAGUAcwAoACQAcABbADMAXQApAC4AVAByAGkAbQAoACkALgBUAHIAaQBtAEUAbgBkACgAWwBjAGgAYQByAF0AOQAyACkAOwBpAGYAKAAkAGkAdABlAG0AIAAtAGwAaQBrAGUAIAAnAEEAdQB0AG8AcwB0AGEAcgB0ADoAKgAnACAALQBvAHIAIAAkAGkAdABlAG0AIAAtAGwAaQBrAGUAIAAnADkAUgBvAHUAdABlAHIAIABjAG8AbQBiAG8AIAAqACcAKQB7ACQAcwBrAGkAcABwAGUAZAArACsAOwBjAG8AbgB0AGkAbgB1AGUAfQA7AGkAZgAoACQAYQBsAGwAbwB3AGUAZAAgAC0AYwBvAG4AdABhAGkAbgBzACAAJAByAGEAdwApAHsAaQBmACgAVABlAHMAdAAtAFAAYQB0AGgAIAAtAEwAaQB0AGUAcgBhAGwAUABhAHQAaAAgACQAcgBhAHcAKQB7AFIAZQBtAG8AdgBlAC0ASQB0AGUAbQAgAC0ATABpAHQAZQByAGEAbABQAGEAdABoACAAJAByAGEAdwAgAC0AUgBlAGMAdQByAHMAZQAgAC0ARgBvAHIAYwBlADsAJAByAGUAbQBvAHYAZQBkACsAKwB9AGUAbABzAGUAewAkAHMAawBpAHAAcABlAGQAKwArAH0AfQBlAGwAcwBlAHsAJABzAGsAaQBwAHAAZQBkACsAKwB9AH0AOwBbAEkATwAuAEYAaQBsAGUAXQA6ADoAVwByAGkAdABlAEEAbABsAFQAZQB4AHQAKAAkAG8AdQB0ACwAKAAnAG8AawAnACsAJABkACsAJAByAGUAbQBvAHYAZQBkACsAJABkACsAJABzAGsAaQBwAHAAZQBkACsAJABkACsAJABmAGEAaQBsAGUAZAApACwAWwBUAGUAeAB0AC4AVQBUAEYAOABFAG4AYwBvAGQAaQBuAGcAXQA6ADoAbgBlAHcAKAAkAGYAYQBsAHMAZQApACkA >nul 2>nul
goto :uninstall_manifest_result
:uninstall_manifest_fixed
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$d=[char]124;$m=$env:UNINSTALL_MANIFEST;$out=$env:UNINSTALL_RESULT;$removed=0;$skipped=0;$failed=0;$paths=@();$root=[Environment]::ExpandEnvironmentVariables('%LOCALAPPDATA%');$allowed=@((Join-Path $root 'node'),(Join-Path $root 'Programs\Git'),(Join-Path $root 'Programs\Python\Python313'),(Join-Path $root 'Programs\Microsoft VS Code'),(Join-Path $env:USERPROFILE '.vscode\extensions\anthropic.claude-code'));foreach($line in [IO.File]::ReadLines($m)){ $p=$line.Split([string[]]@(' '+$d+' '),[StringSplitOptions]::None);if($p.Count -ne 4){$failed++;continue};$item=$p[0];$raw=[Environment]::ExpandEnvironmentVariables($p[3]).Trim().TrimEnd([char]92);if($item -like 'Autostart:HKCU Run:*'){ $name=$item.Substring(24);$k=[Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Software\Microsoft\Windows\CurrentVersion\Run',$true);if($k){try{$v=$k.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames);if($null -ne $v -and ([string]$v -ceq $raw)){$k.DeleteValue($name,$false);$removed++}else{$skipped++}}finally{$k.Dispose()}}else{$skipped++};continue};if($item -like 'Autostart:*' -or $item -like '9Router combo *'){$skipped++;continue};if($item -eq 'OpenClaw' -or $item -eq '9Router'){if(Test-Path -LiteralPath $raw -PathType Container){$prefix=if($item -eq 'OpenClaw'){'openclaw'}else{'9router'};foreach($n in @($prefix+'.cmd',$prefix+'.ps1',$prefix+'.exe','node_modules\'+$prefix)){ $q=Join-Path $raw $n;if(Test-Path -LiteralPath $q){Remove-Item -LiteralPath $q -Recurse -Force;$removed++}}}else{$skipped++};continue};if($allowed -contains $raw){if(Test-Path -LiteralPath $raw){Remove-Item -LiteralPath $raw -Recurse -Force;$removed++}else{$skipped++};continue};$paths+=$raw;$skipped++};$old=[Environment]::GetEnvironmentVariable('Path','User');if($null -ne $old){$keep=New-Object Collections.Generic.List[string];foreach($v in $old.Split(';')){if($v -and ($paths -notcontains ([Environment]::ExpandEnvironmentVariables($v).Trim().TrimEnd([char]92)))){[void]$keep.Add($v)}};[Environment]::SetEnvironmentVariable('Path',($keep -join ';'),'User')};[IO.File]::WriteAllText($out,('ok'+$d+$removed+$d+$skipped+$d+$failed),[Text.UTF8Encoding]::new($false))" >nul 2>nul
goto :uninstall_manifest_result
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$m=$env:UNINSTALL_MANIFEST;$out=$env:UNINSTALL_RESULT;$removed=0;$skipped=0;$failed=0;$pathItems=@();$root=[Environment]::ExpandEnvironmentVariables('%LOCALAPPDATA%');$allowed=@((Join-Path $root 'node'),(Join-Path $root 'Programs\Git'),(Join-Path $root 'Programs\Python\Python313'),(Join-Path $root 'Programs\Microsoft VS Code'),(Join-Path $env:USERPROFILE '.vscode\extensions\anthropic.claude-code'));foreach($line in [IO.File]::ReadLines($m)){ $p=$line -split ' \| ',4;if($p.Count -ne 4){$failed++;continue};$item=$p[0];$raw=[Environment]::ExpandEnvironmentVariables($p[3]).Trim().TrimEnd('');if($item -like 'Autostart:HKCU Run:*'){ $name=$item.Substring('Autostart:HKCU Run:'.Length);$k=[Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Software\Microsoft\Windows\CurrentVersion\Run',$true);try{$v=$k.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames);if($null -ne $v -and ([string]$v -ceq $raw)){$k.DeleteValue($name,$false);$removed++}else{$skipped++}}finally{if($k){$k.Dispose()}};continue };if($item -eq 'Autostart:OpenClaw gateway'){$skipped++;continue};if($item -like '9Router combo *'){$skipped++;continue};if($item -eq 'OpenClaw' -or $item -eq '9Router'){if(-not (Test-Path -LiteralPath $raw -PathType Container)){$skipped++;continue};$names=if($item -eq 'OpenClaw'){@('openclaw.cmd','openclaw.ps1','openclaw.exe','node_modules\openclaw')}else{@('9router.cmd','9router.ps1','9router.exe','node_modules\9router')};foreach($n in $names){$q=Join-Path $raw $n;if(Test-Path -LiteralPath $q){Remove-Item -LiteralPath $q -Recurse -Force;$removed++}};continue};if($allowed -contains $raw){if(Test-Path -LiteralPath $raw){Remove-Item -LiteralPath $raw -Recurse -Force;$removed++}else{$skipped++};continue};$pathItems+=$raw;$skipped++ };$envPath=[Environment]::GetEnvironmentVariable('Path','User');if($null -ne $envPath){$parts=$envPath -split ';';$new=@($parts|?{$_ -and (($pathItems -notcontains ([Environment]::ExpandEnvironmentVariables($_).Trim().TrimEnd('')))}));if(($new -join ';') -cne $envPath){[Environment]::SetEnvironmentVariable('Path',($new -join ';'),'User')}};[IO.File]::WriteAllText($out,('ok|'+$removed+'|'+$skipped+'|'+$failed),[Text.UTF8Encoding]::new($false))" >nul 2>nul
:uninstall_manifest_result
if not exist "%UNINSTALL_RESULT%" (
  call :color_echo "1;31m" "Gỡ cài đặt thất bại; manifest được giữ nguyên."
  call :log_append "uninstall | fail | - | execution | %date% %time%"
  exit /b 1
)
for /f "usebackq tokens=1-4 delims=|" %%a in ("%UNINSTALL_RESULT%") do (set "UNINSTALL_STATE=%%a" & set "UNINSTALL_REMOVED=%%b" & set "UNINSTALL_SKIPPED=%%c" & set "UNINSTALL_FAILED=%%d")
del /f /q "%UNINSTALL_RESULT%" >nul 2>nul
if not "%UNINSTALL_STATE%"=="ok" if not "%UNINSTALL_FAILED%"=="0" (
  call :color_echo "1;31m" "Một số artifact không thể gỡ; manifest được giữ nguyên."
  call :log_append "uninstall | fail | %UNINSTALL_REMOVED% | artifact-failure | %date% %time%"
  exit /b 1
)
findstr /i /c:"Autostart:OpenClaw gateway" "%UNINSTALL_MANIFEST%" >nul 2>nul
if not errorlevel 1 openclaw.cmd gateway uninstall >nul 2>nul
call :manifest_clear
if errorlevel 1 (
  call :color_echo "1;31m" "Đã xử lý artifact nhưng không dọn được manifest/log."
  call :log_append "uninstall | fail | %UNINSTALL_REMOVED% | metadata-cleanup | %date% %time%"
  exit /b 1
)
call :color_echo "1;32m" "Đã gỡ %UNINSTALL_REMOVED% artifact do AI Tools sở hữu; bỏ qua %UNINSTALL_SKIPPED% mục an toàn."
call :log_append "uninstall | ok | %UNINSTALL_REMOVED% | manifest-owned-only | %date% %time%"
exit /b 0

rem --------------------------- self-update ---------------------------
:stub_update
setlocal EnableDelayedExpansion
call :init_colors
call :color_echo "1;97m" "Đang kiểm tra bản cập nhật..."
set "UPDATE_API=https://api.github.com/repos/giakhanhquoc141-rgb/AI_AGENT_INSTALL/releases/latest"
set "UPDATE_RESULT=%TEMP%\aitools-update-result-%RANDOM%-%RANDOM%.txt"
set "UPDATE_CURRENT=%TOOL_VERSION%"
if exist "!UPDATE_RESULT!" del /f /q "!UPDATE_RESULT!" >nul 2>nul
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';try{$r=Invoke-RestMethod -Uri $env:UPDATE_API -Headers @{'User-Agent'='AI-Tools-Installer'} -UseBasicParsing -TimeoutSec 15;$tag=[string]$r.tag_name;if([string]::IsNullOrWhiteSpace($tag)){[IO.File]::WriteAllText($env:UPDATE_RESULT,'none;')}else{$a=$r.assets|?{$_.name -match '(?i)^AI_Tools_Installer\.bat$'}|Select-Object -First 1;if($null -eq $a){[IO.File]::WriteAllText($env:UPDATE_RESULT,('found;'+$tag.TrimStart('v','V')+';'))}else{[IO.File]::WriteAllText($env:UPDATE_RESULT,('found;'+$tag.TrimStart('v','V')+';'+$a.browser_download_url))}}catch{[IO.File]::WriteAllText($env:UPDATE_RESULT,'error;')}" >nul 2>nul
if not exist "!UPDATE_RESULT!" (call :color_echo "1;31m" "Không thể kiểm tra bản cập nhật. Bản hiện tại vẫn an toàn." & call :log_append "update ^| fail ^| !UPDATE_CURRENT! ^| releases-api ^| %date% %time%" & goto :installer_exit)
set "UPDATE_STATE="
set "UPDATE_LATEST="
set "UPDATE_URL="
for /f "usebackq tokens=1-3 delims=;" %%a in ("!UPDATE_RESULT!") do (set "UPDATE_STATE=%%a" & set "UPDATE_LATEST=%%b" & set "UPDATE_URL=%%c")
del /f /q "!UPDATE_RESULT!" >nul 2>nul
if /i "!UPDATE_STATE!"=="error" (call :color_echo "1;31m" "Lỗi kết nối API. Thử lại sau." & call :log_append "update ^| fail ^| !UPDATE_CURRENT! ^| releases-api ^| %date% %time%" & goto :installer_exit)
if /i "!UPDATE_STATE!"=="none" (call :color_echo "1;32m" "Chưa có bản phát hành chính thức." & call :log_append "update ^| skip ^| !UPDATE_CURRENT! ^| no-release ^| %date% %time%" & goto :installer_exit)
set "UPDATE_COMPARE="
for /f "delims=" %%c in ('powershell -NoProfile -Command "$a='!UPDATE_CURRENT!';$b='!UPDATE_LATEST!';if([version]$b -gt [version]$a){'new'}else{'current'}"') do if not defined UPDATE_COMPARE set "UPDATE_COMPARE=%%c"
if /i "!UPDATE_COMPARE!"=="new" (
  call :color_echo "1;33m" "Có bản mới: hiện tại !UPDATE_CURRENT! → mới nhất !UPDATE_LATEST!."
  call :self_update_replace "!UPDATE_URL!" "!UPDATE_LATEST!"
  if not errorlevel 1 goto :installer_exit
  call :color_echo "1;31m" "Cập nhật thất bại. Bản hiện tại không bị thay đổi."
  call :log_append "update ^| fail ^| !UPDATE_CURRENT! -> !UPDATE_LATEST! ^| replace ^| %date% %time%"
) else (
  call :color_echo "1;32m" "Bạn đang dùng bản mới nhất: !UPDATE_CURRENT!."
  call :log_append "update ^| skip ^| !UPDATE_CURRENT! ^| latest=!UPDATE_LATEST! ^| %date% %time%"
)
goto :installer_exit

:self_update_check_fixed
call :init_colors
setlocal EnableDelayedExpansion
set "UPDATE_RESULT=%TEMP%\aitools-update-result-%RANDOM%-%RANDOM%.txt"
set "UPDATE_CURRENT=%TOOL_VERSION%"
if exist "!UPDATE_RESULT!" del /f /q "!UPDATE_RESULT!" >nul 2>nul
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';try{$r=Invoke-RestMethod -Uri $env:UPDATE_API -Headers @{'User-Agent'='AI-Tools-Installer'} -UseBasicParsing -TimeoutSec 15;$tag=[string]$r.tag_name;if([string]::IsNullOrWhiteSpace($tag)){[IO.File]::WriteAllText($env:UPDATE_RESULT,'none;')}else{[IO.File]::WriteAllText($env:UPDATE_RESULT,('found;'+$tag.TrimStart('v','V')))}}catch{[IO.File]::WriteAllText($env:UPDATE_RESULT,'error;')}" >nul 2>nul
if not exist "!UPDATE_RESULT!" (call :color_echo "1;31m" "Không thể kiểm tra bản cập nhật. Bản hiện tại vẫn an toàn." & call :log_append "update ^| fail ^| !UPDATE_CURRENT! ^| releases-api ^| %date% %time%" & endlocal & exit /b 1)
set "UPDATE_STATE="
set "UPDATE_LATEST="
for /f "usebackq tokens=1,2 delims=;" %%a in ("!UPDATE_RESULT!") do (set "UPDATE_STATE=%%a" & set "UPDATE_LATEST=%%b")
del /f /q "!UPDATE_RESULT!" >nul 2>nul
if /i "!UPDATE_STATE!"=="error" (call :color_echo "1;31m" "Không thể kiểm tra bản cập nhật. Bản hiện tại vẫn an toàn." & call :log_append "update ^| fail ^| !UPDATE_CURRENT! ^| releases-api-retry-exhausted ^| %date% %time%" & endlocal & exit /b 1)
if /i not "!UPDATE_STATE!"=="found" (call :color_echo "1;97m" "Chưa có bản phát hành chính thức nào. Phiên bản hiện tại: !UPDATE_CURRENT!." & call :log_append "update ^| skip ^| !UPDATE_CURRENT! ^| no-release ^| %date% %time%" & endlocal & exit /b 0)
set "UPDATE_COMPARE="
for /f "delims=" %%c in ('powershell -NoProfile -Command "$a='!UPDATE_CURRENT!';$b='!UPDATE_LATEST!';if([version]$b -gt [version]$a){'new'}else{'current'}"') do if not defined UPDATE_COMPARE set "UPDATE_COMPARE=%%c"
if /i "!UPDATE_COMPARE!"=="new" (call :color_echo "1;33m" "Có bản mới: hiện tại !UPDATE_CURRENT! → mới nhất !UPDATE_LATEST!." & call :color_echo "2;90m" "Chưa tải xuống tự động; bản hiện tại vẫn an toàn." & call :log_append "update ^| ok ^| !UPDATE_CURRENT! -> !UPDATE_LATEST! ^| !UPDATE_API! ^| %date% %time%") else (call :color_echo "1;32m" "Bạn đang dùng bản mới nhất: !UPDATE_CURRENT!." & call :log_append "update ^| skip ^| !UPDATE_CURRENT! ^| latest=!UPDATE_LATEST! ^| %date% %time%")
endlocal & exit /b 0

:self_update_check
setlocal EnableDelayedExpansion
set "UPDATE_RESULT=%TEMP%\aitools-update-result-%RANDOM%-%RANDOM%.txt"
set "UPDATE_CURRENT=%TOOL_VERSION%"
if not exist "!UPDATE_RESULT!" powershell -NoProfile -ExecutionPolicy Bypass -EncodedCommand JABFAHIAcgBvAHIAQQBjAHQAaQBvAG4AUAByAGUAZgBlAHIAZQBuAGMAZQA9ACIAUwB0AG8AcAAiADsAIAAkAHIAPQBJAG4AdgBvAGsAZQAtAFIAZQBzAHQATQBlAHQAaABvAGQAIAAtAFUAcgBpACAAJABlAG4AdgA6AFUAUABEAEEAVABFAF8AQQBQAEkAIAAtAFUAcwBlAEIAYQBzAGkAYwBQAGEAcgBzAGkAbgBnACAALQBIAGUAYQBkAGUAcgBzACAAQAB7ACIAVQBzAGUAcgAtAEEAZwBlAG4AdAAiAD0AIgBBAEkALQBUAG8AbwBsAHMALQBJAG4AcwB0AGEAbABsAGUAcgAiAH0AIAAtAFQAaQBtAGUAbwB1AHQAUwBlAGMAIAAxADUAOwAgACQAdAA9AFsAcwB0AHIAaQBuAGcAXQAkAHIALgB0AGEAZwBfAG4AYQBtAGUAOwAgACQAdgA9ACIAZgBvAHUAbgBkADsAIgArACQAdAA7ACAAJAB2AD0AJAB2ACAALQByAGUAcABsAGEAYwBlACAAIgBeAGYAbwB1AG4AZAA7AHYAIgAsACIAZgBvAHUAbmQ7ACIAOwAgAFMAZQB0AC0AQwBvAG4AdABlAG4AdAAgAC0ATABpAHQAZQByAGEAbABQAGEAdABoACAAJABlAG4AdgA6AFUAUABEAEEAVABFAFQAXwBSAEUAUwBVAEwAVAAgAC0AVgBhAGwAdQBlACAAJAB2ACAALQBFAG4AYwBvAGQAaQBuAGcAIAB1AHQAZgA4AA== >nul 2>nul
if not exist "!UPDATE_RESULT!" powershell -NoProfile -ExecutionPolicy Bypass -EncodedCommand JABFAHIAZwBvAHIAQQBjAHQAaQBvAG4AUAByAGUAZgBlAHIAZQBuAGMAZQA9ACIAUwB0AG8AcAAiADsAIAAkAHIAPQBJAG4AdgBvAGsAZQAtAFIAZQBzAHQATQBlAHQAaABvAGQAIAAtAFUAcgBpACAAJABlAG4AdgA6AFUAUABEAEEAVABFAF8AQQBQAEkAIAAtAFUAc2BlAEIAYQBzAGkAYwBQAGEAcgBzAGkAbgBnACAALQBIAGUAYQBkAGUAcgBzACAAQAB7ACIAVQBzAGUAcgAtAEEAZwBlAG4AdAAiAD0AIgBBAEkALQBUAG8AbwBsAHMALQBJAG4AcwB0AGEAbABsAGUAcgAiAH0AIAAtAFQAaQBtAGUAbwB1AHQAUwBlAGMAIAAxADUAOwAgACQAdAA9AFsAcwB0AHIAaQBuAGcAXQAkAHIALgB0AGEAZwBfAG4AYQBtAGUAOwAgACQAdgA9ACIAZgBvAHUAbgBkADsAIgArACQAdAA7ACAAJAB2AD0AJAB2ACAALQByAGUAcABsAGEAYwBlACAAIgBeAGYAbwB1AG4AZAA7AHYAIgAsACIAZgBvAHUAbgBkADsAIgA7ACAAUwBlAHQALQBDAG8AbgB0AGUAbnQgAC0ATABpAHQAZQByAGEAbABQAGEAdABoACAAJABlAG4AdgA6AFVQREFURV9SRVNVTFQgLQBWYWx1ZSAkdiAtAEVuY29kaW5nIHV0ZjgA== >nul 2>nul
if not exist "!UPDATE_RESULT!" powershell -NoProfile -ExecutionPolicy Bypass -EncodedCommand JABFAHIAZwBvAHIAQQBjAHQAaQBvAG4AUAByAGUAZgBlAHIAZQBuAGMAZQA9ACIAUwB0AG8AcAAiADsAIAAkAHIAPQBJAG4AdgBvAGsAZQAtAFIAZQBzAHQATQBlAHQAaABvAGQAIAAtAFUAcgBpACAAJABlAG4AdgA6AFUAUABEAEEAVABFAF8AQQBQAEkAIAAtAFUAc2BlAEIAYQBzAGkAYwBQAGEAcgBzAGkAbgBnACAALQBIAGUAYQBkAGUAcgBzACAAQAB7ACIAVQBzAGUAcgAtAEEAZwBlAG4AdAAiAD0AIgBBAEkALQBUAG8AbwBsAHMALQBJAG4AcwB0AGEAbABsAGUAcgAiAH0AIAAtAFQAaW1lAG8AdQB0AFMAZQBjACAAMTUAIwB3AHJvbmcA >nul 2>nul
if not exist "!UPDATE_RESULT!" (
  call :color_echo "1;31m" "Không thể kiểm tra bản cập nhật lúc này. Bản hiện tại vẫn an toàn."
  call :log_append "update ^| fail ^| !UPDATE_CURRENT! ^| releases-api ^| %date% %time%"
  endlocal & exit /b 1
)
set "UPDATE_STATE="
set "UPDATE_LATEST="
for /f "tokens=1,2 delims=;" %%a in (!UPDATE_RESULT!) do (set "UPDATE_STATE=%%a" & set "UPDATE_LATEST=%%b")
del /f /q "!UPDATE_RESULT!" >nul 2>nul
if /i "!UPDATE_STATE!"=="error" (
  call :color_echo "1;31m" "Không thể kiểm tra bản cập nhật sau 3 lần thử. Bản hiện tại vẫn an toàn."
  call :log_append "update ^| fail ^| !UPDATE_CURRENT! ^| releases-api-retry-exhausted ^| %date% %time%"
  endlocal & exit /b 1
)
if /i not "!UPDATE_STATE!"=="found" (
  call :color_echo "1;97m" "Chưa có bản phát hành chính thức nào. Phiên bản hiện tại: !UPDATE_CURRENT!."
  call :log_append "update ^| skip ^| !UPDATE_CURRENT! ^| no-release ^| %date% %time%"
  endlocal & exit /b 0
)
set "UPDATE_COMPARE="
for /f "delims=" %%c in ('powershell -NoProfile -Command "$a='!UPDATE_CURRENT!';$b='!UPDATE_LATEST!';try{if(([version]$b) -gt ([version]$a)){'new'}else{'current'}}catch{if($a -eq $b){'current'}else{'new'}}"') do if not defined UPDATE_COMPARE set "UPDATE_COMPARE=%%c"
if /i "!UPDATE_COMPARE!"=="new" (
  call :color_echo "1;33m" "Có bản mới: hiện tại !UPDATE_CURRENT! → mới nhất !UPDATE_LATEST!."
  call :color_echo "2;90m" "Chưa tải xuống. Chạy lại với xác nhận cập nhật khi tính năng này sẵn sàng."
  call :log_append "update ^| ok ^| !UPDATE_CURRENT! -> !UPDATE_LATEST! ^| !UPDATE_API! ^| %date% %time%"
) else (
  call :color_echo "1;32m" "Bạn đang dùng bản mới nhất: !UPDATE_CURRENT!. Bản phát hành mới nhất: !UPDATE_LATEST!."
  call :log_append "update ^| skip ^| !UPDATE_CURRENT! ^| latest=!UPDATE_LATEST! ^| %date% %time%"
)
endlocal & exit /b 0

rem ---------------------- safe self-replace ---------------------
rem %1 = URL asset .bat chính thức, %2 = phiên bản đích.
rem Tải cạnh file đang chạy, kiểm tra tối thiểu, rồi để tiến trình
rem con đổi tên sau khi cmd hiện tại đã thoát; không ghi đè trực tiếp.
:self_update_replace
setlocal EnableDelayedExpansion
set "UPDATE_URL=%~1"
set "UPDATE_VERSION=%~2"
set "UPDATE_TARGET=%~f0"
set "UPDATE_NEW=!UPDATE_TARGET!.new"
set "UPDATE_TMP=!UPDATE_TARGET!.new.tmp"
set "UPDATE_OLD=!UPDATE_TARGET!.old"
if not defined UPDATE_URL (
  call :color_echo "1;31m" "Không tìm thấy tệp cập nhật chính thức. Bản hiện tại vẫn an toàn."
  call :log_append "update-replace ^| fail ^| !TOOL_VERSION! ^| missing-asset ^| %date% %time%"
  endlocal & exit /b 1
)
del /f /q "!UPDATE_TMP!" "!UPDATE_NEW!" >nul 2>nul
call :download_with_progress "%UPDATE_URL%" "%UPDATE_TMP%" "Bản cập nhật %UPDATE_VERSION%"
if not errorlevel 1 powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$o=$env:UPDATE_TMP;$len=(Get-Item -LiteralPath $o).Length;if($len -lt 128){throw 'empty'};if($len -gt 5MB){throw 'too-large'};$s=[IO.File]::ReadAllText($o);if($s -notmatch '(?m)^@echo off'){throw 'not-batch'};if($s -notmatch 'TOOL_VERSION='){throw 'missing-version'};if($s -notmatch 'TOOL_VERSION=\d+\.\d+\.\d+'){throw 'invalid-version-format'};if($s -notmatch 'AI Tools Installer'){throw 'missing-name'};Move-Item -LiteralPath $o -Destination $env:UPDATE_NEW -Force" >nul 2>nul
if errorlevel 1 (
  call :color_echo "1;31m" "Tải bản cập nhật thất bại; bản hiện tại không bị thay đổi."
  call :log_append "update-replace ^| fail ^| !TOOL_VERSION! ^| download-or-verify ^| %date% %time%"
  endlocal & exit /b 1
)
if not exist "!UPDATE_NEW!" (
  call :color_echo "1;31m" "Không tạo được tệp cập nhật tạm; bản hiện tại vẫn an toàn."
  call :log_append "update-replace ^| fail ^| !TOOL_VERSION! ^| missing-temp ^| %date% %time%"
  endlocal & exit /b 1
)
set "UPDATE_NEW=!UPDATE_NEW!"
set "UPDATE_OLD=!UPDATE_OLD!"
set "UPDATE_LOG=%LOCALAPPDATA%\AITools\logs\ai-tools-installer.log"
start "" /b cmd /d /c "ping 127.0.0.1 -n 3 >nul & move /y \"!UPDATE_TARGET!\" \"!UPDATE_OLD!\" >nul && move /y \"!UPDATE_NEW!\" \"!UPDATE_TARGET!\" >nul || (if exist \"!UPDATE_OLD!\" move /y \"!UPDATE_OLD!\" \"!UPDATE_TARGET!\" >nul) & if exist \"!UPDATE_TARGET!\" del /f /q \"!UPDATE_OLD!\" >nul 2>nul & echo update-replace ^| ok ^| !TOOL_VERSION! -> !UPDATE_VERSION! ^| deferred-rename ^| %date% %time%>>\"!UPDATE_LOG!\""
call :color_echo "1;32m" "Đã tải bản cập nhật. Công cụ sẽ thay thế an toàn sau khi phiên này kết thúc."
call :log_append "update-replace ^| scheduled ^| !TOOL_VERSION! -> !UPDATE_VERSION! ^| deferred-rename ^| %date% %time%"
endlocal & exit /b 0

rem --------------------------- mode không hợp lệ ---------------------------
:unknown_mode
call :color_echo "1;97m" "Chế độ không hợp lệ."
call :color_echo "2;90m" "Công cụ thoát an toàn. Chạy lại AI_Tools_Installer.bat để cài đặt."
call :log_append "router | fail | - | - | %date% %time%"
exit /b 0

:installer_exit
if defined LOCALAPPDATA (if exist "%LOCALAPPDATA%\AITools\.install-lock" del /f /q "%LOCALAPPDATA%\AITools\.install-lock" >nul 2>nul) else (if exist "%TEMP%\aitools-install-lock" del /f /q "%TEMP%\aitools-install-lock" >nul 2>nul)
endlocal
exit /b 0
