@echo off
if "%1"=="--version" (
  echo 9.9.9
  echo abcdef123
  echo x64
) else (
  rem no extensions
)
exit /b 0
