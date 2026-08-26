$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$batPath = if ($env:AI_TOOLS_BAT_UNDER_TEST) { $env:AI_TOOLS_BAT_UNDER_TEST } else { Join-Path $root 'AI_Tools_Installer.bat' }
$batPath = (Resolve-Path -LiteralPath $batPath).Path
$bat = [IO.File]::ReadAllText($batPath, [Text.Encoding]::UTF8)

function Assert([bool]$condition, [string]$message) {
  if (-not $condition) { throw "UI progress: $message" }
  Write-Output "PASS | $message"
}

Assert ($bat.Contains('TOOL_VERSION=0.3.0')) 'Phiên bản giao diện là 0.3.0'
Assert ($bat.Contains(':download_with_progress')) 'Có helper tải xuống dùng chung'
Assert ($bat.Contains('$res.ContentLength') -and $bat.Contains('$src.BeginRead($buf,')) 'Phần trăm tải dựa trên byte thực và Content-Length'
Assert ($bat.Contains("('{0:N1}' -f (`$read/1MB))")) 'Hiển thị dung lượng MiB thực đã nhận'
Assert ($bat.Contains('for($attempt=1;$attempt -le 3;$attempt++)')) 'Tải xuống có tối đa ba lần thử'
Assert ($bat.Contains("`$items=@('Git','Node','Python','VSCode','VSCodeExt','OpenClaw','9Router')")) 'Quét đủ bảy ứng dụng'
Assert ($bat.Contains("`$idx++;`$pct=[int][math]::Floor((`$idx*100)/`$items.Count)")) 'Phần trăm quét chỉ tăng sau khi mục thực sự hoàn thành'
Assert ($bat.Contains('Start-Job -ScriptBlock $cb') -and $bat.Contains('Start-Sleep -Milliseconds 120')) 'Kết nối mạng có hoạt ảnh trong thời gian chờ'
Assert ($bat.Contains("ForegroundColor Cyan") -and $bat.Contains("ForegroundColor Green") -and $bat.Contains("ForegroundColor Yellow")) 'Trạng thái có bảng màu dễ phân biệt'
Assert ($bat.Contains('Đang cài Visual Studio Code...') -and $bat.Contains('Đang cài Python...')) 'Trình cài im lặng có con quay và thời gian chờ'
Assert ($bat.Contains('--progress=true --loglevel=notice')) 'npm hiển thị tiến độ thật thay vì bị ẩn'
Assert ($bat.Contains('([char]13)')) 'Hoạt ảnh dùng carriage return thật'

$bytes = [IO.File]::ReadAllBytes($batPath)
$loneLf = 0
$loneCr = 0
for ($i = 0; $i -lt $bytes.Length; $i++) {
  if ($bytes[$i] -eq 10 -and ($i -eq 0 -or $bytes[$i - 1] -ne 13)) { $loneLf++ }
  if ($bytes[$i] -eq 13 -and ($i -eq $bytes.Length - 1 -or $bytes[$i + 1] -ne 10)) { $loneCr++ }
}
Assert ($loneLf -eq 0) 'File BAT chỉ dùng CRLF, không có LF đứng một mình'
Assert ($loneCr -eq 0) 'File BAT không có CR đứng một mình'
Assert (-not ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191)) 'File BAT là UTF-8 không BOM'

@('VSCODE_URL','PY_URL','GIT_URL','NODE_URL','UPDATE_URL') | ForEach-Object {
  Assert ($bat.Contains('call :download_with_progress "%' + $_ + '%"')) "Đường tải $_ dùng helper tiến độ thật"
}

$attributes = Get-Content -Raw -LiteralPath (Join-Path $root '.gitattributes')
Assert ($attributes -match '(?m)^\*\.bat text eol=crlf\r?$') '.gitattributes ép CRLF cho BAT'
Assert ($attributes -match '(?m)^\*\.cmd text eol=crlf\r?$') '.gitattributes ép CRLF cho CMD'

Write-Output 'UI progress harness: PASS'
