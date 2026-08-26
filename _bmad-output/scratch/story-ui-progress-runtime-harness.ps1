param([string]$BatPath)
$ErrorActionPreference = 'Stop'
# Ép UTF-8 khi bắt output từ child powershell để tiếng Việt không bị
# mojibake qua console codepage (cp437/ANSI) — không phụ thuộc chcp của máy.
$OutputEncoding = [Text.Encoding]::UTF8
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ([string]::IsNullOrWhiteSpace($BatPath)) { $BatPath = Join-Path $root 'AI_Tools_Installer.bat' }
$BatPath = (Resolve-Path -LiteralPath $BatPath).Path
$bat = [IO.File]::ReadAllText($BatPath, [Text.Encoding]::UTF8)
$line = ($bat -split "`r?`n" | Where-Object { $_ -like 'powershell *$ErrorActionPreference*BeginGetResponse*' } | Select-Object -First 1)
if (-not $line -or $line -notmatch '-Command "(.*)"$') { throw 'Không trích được mã tải xuống thực tế' }
$downloadCode = $Matches[1].Replace('%%', '%')
$tempRoot = Join-Path $env:TEMP ('aitools-progress-runtime-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot | Out-Null

function Assert([bool]$condition, [string]$message) {
  if (-not $condition) { throw "Runtime progress: $message" }
  Write-Output "PASS | $message"
}

function Get-FreePort {
  $listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
  $listener.Start()
  $port = ([Net.IPEndPoint]$listener.LocalEndpoint).Port
  $listener.Stop()
  return $port
}

function Start-TestServer([int]$port, [string]$mode, [byte[]]$payload) {
  Start-Job -ArgumentList $port,$mode,$payload -ScriptBlock {
    param($port,$mode,$payload)
    $listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, $port)
    $listener.Start()
    try {
      $requests = if ($mode -eq 'retry') { 2 } else { 1 }
      for ($request = 1; $request -le $requests; $request++) {
        $client = $listener.AcceptTcpClient()
        try {
          $stream = $client.GetStream()
          $reader = [IO.StreamReader]::new($stream, [Text.Encoding]::ASCII, $false, 1024, $true)
          while (($requestLine = $reader.ReadLine()) -ne $null -and $requestLine -ne '') {}
          if ($mode -eq 'chunked') {
            $head = [Text.Encoding]::ASCII.GetBytes("HTTP/1.1 200 OK`r`nTransfer-Encoding: chunked`r`nConnection: close`r`n`r`n")
            $stream.Write($head,0,$head.Length)
            for ($offset=0; $offset -lt $payload.Length; $offset+=4096) {
              $count=[Math]::Min(4096,$payload.Length-$offset)
              $prefix=[Text.Encoding]::ASCII.GetBytes(($count.ToString('X')+"`r`n"))
              $stream.Write($prefix,0,$prefix.Length);$stream.Write($payload,$offset,$count)
              $suffix=[Text.Encoding]::ASCII.GetBytes("`r`n");$stream.Write($suffix,0,$suffix.Length)
              $stream.Flush();Start-Sleep -Milliseconds 30
            }
            $end=[Text.Encoding]::ASCII.GetBytes("0`r`n`r`n");$stream.Write($end,0,$end.Length)
          } else {
            $head=[Text.Encoding]::ASCII.GetBytes("HTTP/1.1 200 OK`r`nContent-Length: $($payload.Length)`r`nConnection: close`r`n`r`n")
            $stream.Write($head,0,$head.Length)
            $limit = if ($mode -eq 'retry' -and $request -eq 1) { 17 } else { $payload.Length }
            for ($offset=0; $offset -lt $limit; $offset+=4096) {
              $count=[Math]::Min(4096,$limit-$offset);$stream.Write($payload,$offset,$count);$stream.Flush();Start-Sleep -Milliseconds 30
            }
          }
        } finally { $client.Dispose() }
      }
    } finally { $listener.Stop() }
  }
}

function Invoke-Case([string]$mode) {
  $payload = [Text.Encoding]::UTF8.GetBytes(('du-lieu-tien-do-' * 8192))
  $port = Get-FreePort
  $server = Start-TestServer $port $mode $payload
  $outFile = Join-Path $tempRoot ($mode + '.bin')
  $env:DL_URL = "http://127.0.0.1:$port/file"
  $env:DL_OUT = $outFile
  $env:DL_NAME = "Kiểm thử $mode"
  try {
    $output = (& powershell -NoProfile -ExecutionPolicy Bypass -Command $downloadCode 2>&1) -join "`n"
    $exitCode = $LASTEXITCODE
    Wait-Job -Job $server -Timeout 10 | Out-Null
    Receive-Job -Job $server -ErrorAction Stop | Out-Null
    Assert ($exitCode -eq 0) "$mode trả exit code 0"
    Assert ((Test-Path -LiteralPath $outFile)) "$mode tạo file đích"
    Assert ([Convert]::ToBase64String([IO.File]::ReadAllBytes($outFile)) -eq [Convert]::ToBase64String($payload)) "$mode giữ đúng từng byte"
    Assert ($output -match '100%') "$mode kết thúc ở 100%"
    if ($mode -eq 'chunked') { Assert ($output -match 'MiB') 'không Content-Length vẫn hiện byte thực' }
    if ($mode -eq 'retry') { Assert ($output -match '1/3 thất bại') 'dữ liệu bị cắt được phát hiện và thử lại' }
  } finally {
    Remove-Job -Job $server -Force -ErrorAction SilentlyContinue
  }
}

function Test-InstallerWait([string]$environmentName, [string]$displayName) {
  $installerLine = ($bat -split "`r?`n" | Where-Object { $_ -like "powershell *Start-Process -FilePath `$env:$environmentName*" } | Select-Object -First 1)
  if (-not $installerLine -or $installerLine -notmatch '-Command "(.*)"$') { throw "Không trích được wait loop $displayName" }
  $installerCode = $Matches[1].Replace('%%', '%')
  $stub = Join-Path $tempRoot 'wait-stub.exe'
  if (-not (Test-Path -LiteralPath $stub)) {
    $source = 'using System;using System.Threading;public class WaitStub{public static int Main(){Thread.Sleep(450);int n;return int.TryParse(Environment.GetEnvironmentVariable("AITEST_EXIT"),out n)?n:0;}}'
    Add-Type -TypeDefinition $source -OutputAssembly $stub -OutputType ConsoleApplication
  }
  [Environment]::SetEnvironmentVariable($environmentName, $stub, 'Process')
  foreach ($expected in 0,7) {
    $env:AITEST_EXIT = [string]$expected
    $output = (& powershell -NoProfile -ExecutionPolicy Bypass -Command $installerCode 2>&1) -join "`n"
    Assert ($LASTEXITCODE -eq $expected) "$displayName giữ nguyên exit code $expected"
    Assert ($output -match 'Đang cài') "$displayName có hoạt ảnh khi tiến trình còn chạy"
    if ($expected -eq 0) { Assert ($output -match 'OK') "$displayName chỉ báo xanh khi thành công" }
    else { Assert ($output -match 'cài lỗi, mã 7') "$displayName báo lỗi theo exit code thực" }
  }
}

try {
  Invoke-Case 'known'
  Invoke-Case 'chunked'
  Invoke-Case 'retry'
  Test-InstallerWait 'VSCODE_INSTALLER' 'Visual Studio Code'
  Test-InstallerWait 'PY_INSTALLER' 'Python'
  Write-Output 'UI progress runtime harness: PASS'
} finally {
  $resolvedTemp = (Resolve-Path -LiteralPath $tempRoot -ErrorAction SilentlyContinue).Path
  $tempBase = (Resolve-Path -LiteralPath $env:TEMP).Path.TrimEnd('\') + '\'
  if ($resolvedTemp -and $resolvedTemp.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase)) {
    Remove-Item -LiteralPath $resolvedTemp -Recurse -Force
  }
}
