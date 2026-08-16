@echo off
rem Scratch test 2: full assembly -> for/f -> parse -> export mechanism
setlocal
chcp 65001 >nul

:test_scan_block
setlocal EnableDelayedExpansion
echo [scan] begin
set "S1=function F($a){$r=& 'cmd.exe' /c 'echo fake'|Out-Null;$o=(& 'cmd.exe' /c 'echo 2.45.0.windows.1')|Out-String;$o2=(& 'cmd.exe' /c 'echo err')2>&1;return ($a+'|'+$o.Trim()+'|'+$o2.Trim())};"
set "S2=[Console]::WriteLine('Git|1.2.3|1.2.4|UPDATE');[Console]::WriteLine((F 'Node'));[Console]::WriteLine('NETERR|0');"
set "PSCMD=powershell -NoProfile -ExecutionPolicy Bypass -Command "!S1!!S2!""
echo PSCMD=[%PSCMD%]
for /f "usebackq delims=" %%L in (`!PSCMD!`) do call :scan_parse "%%L"
echo ST_Git=[!ST_Git!] VR_Git=[!VR_Git!] VL_Git=[!VL_Git!]
echo ST_Node=[!ST_Node!] VR_Node=[!VR_Node!] VL_Node=[!VL_Node!]
echo NET_ERR=[!NET_ERR!]
endlocal & set "ST_Git=%ST_Git%" & set "VR_Git=%VR_Git%" & set "VL_Git=%VL_Git%" & set "ST_Node=%ST_Node%" & set "VR_Node=%VR_Node%" & set "VL_Node=%VL_Node%" & set "NET_ERR=%NET_ERR%"
goto :after_scan

:scan_parse
for /f "tokens=1-4 delims=|" %%a in ("%~1") do (
  if /i "%%a"=="NETERR" (set "NET_ERR=%%b")
  if /i "%%a"=="Git" (set "ST_Git=%%d"&set "VR_Git=%%b"&set "VL_Git=%%c")
  if /i "%%a"=="Node" (set "ST_Node=%%d"&set "VR_Node=%%b"&set "VL_Node=%%c")
)
exit /b 0

:after_scan
echo === after scan block (outer scope) ===
echo OUTER ST_Git=[%ST_Git%] VR_Git=[%VR_Git%] VL_Git=[%VL_Git%]
echo OUTER ST_Node=[%ST_Node%] VR_Node=[%VR_Node%] VL_Node=[%VL_Node%]
echo OUTER NET_ERR=[%NET_ERR%]
echo === done ===
