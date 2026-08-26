$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$bat = Get-Content -Raw (Join-Path $root "AI_Tools_Installer.bat")
function Assert([bool]$condition, [string]$message) {
  if (-not $condition) { throw "FAIL: $message" }
  Write-Output "PASS: $message"
}
Assert ($bat -match '(?m)^:manifest_append\s*$') "Có helper ghi manifest"
Assert ($bat -match 'f\.Count -eq 4') "Manifest yêu cầu đúng 4 trường"
Assert ($bat -match 'Get-Date -Format yyyy-MM-dd') "Manifest ghi ngày chuẩn ISO"
Assert ($bat -match '(?m)^:manifest_validate\s*$') "Có helper kiểm tra schema trước lifecycle"
Assert ($bat -match 'f\.Count -ne 4') "Helper phát hiện dòng sai schema"
Assert ($bat -match '(?m)^:manifest_clear\s*$') "Có helper dọn manifest và log"
Assert ($bat -match 'ai-tools-installer\.log') "Lifecycle chỉ dọn dữ liệu AI Tools"
Assert ($bat -match 'Autostart:') "Artifact autostart ghi kind và tên chính xác"
Assert ($bat -match 'MA_ITEM') "Helper kiểm tra trường manifest trước khi ghi"
Write-Output "PASS: Story 3.1 manifest schema/lifecycle contract."
