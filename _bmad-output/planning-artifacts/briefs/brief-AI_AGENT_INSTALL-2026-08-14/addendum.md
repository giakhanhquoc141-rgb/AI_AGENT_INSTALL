# Addendum — Branding & Technical Notes

Nội dung bổ sung cho downstream: **Thương hiệu/Logo** → dùng cho PRD; **ghi chú kỹ thuật & cấu hình component** → dùng cho phase build.

## Thương hiệu / Logo (→ PRD)

**Tên sản phẩm:** AI Tools Installer *(đã chốt)*.

**Logo (ASCII, phong cách Claude Code CLI — chỉ ký tự, không hình ảnh):**

```
         *
        / \
       /   \
      /     \
     *********
      \     /
       \   /
        \ /
         *

      AI TOOLS INSTALLER
     ────────────────────
   Cài bộ AI · Tự kiểm tra · Gỡ sạch
```

**Màu sắc ANSI (nhúng vào .bat):**
- Ngôi sao: cam — `\x1b[38;5;214m` (hoặc `\x1b[1;33m`)
- "AI TOOLS INSTALLER": trắng đậm — `\x1b[1;97m`
- Khẩu hiệu: xám mờ — `\x1b[2;90m`
- Nền: mặc định của terminal (tối)

**Batch snippet lấy mã ESC + tô màu** *(minh họa cách dùng — build phase cần render đủ toàn bộ logo 11 dòng)*:
```bat
@echo off
for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
echo %ESC%[38;5;214m         *%ESC%[0m
echo %ESC%[38;5;214m        / \%ESC%[0m
echo %ESC%[1;97m      AI TOOLS INSTALLER%ESC%[0m
```

## Ghi chú kỹ thuật (cho phase build)

- **Download**: dùng `curl.exe` (có sẵn trên Win10 1803+ / Win11) hoặc `powershell -c "Invoke-WebRequest"` khi cần.
- **Version-check**: batch không đọc được JSON → nhờ PowerShell làm cầu nối gọi API chính thức của Node/Python/VSCode; với OpenClaw/9Router dùng `npm view <pkg> version`.
- **Silent installs — chọn cài per-user để không cần admin/UAC**:
  - Node.js: `msiexec /i node-vXX.x64.msi /qn`
  - Python: `python-3.13.x.exe /quiet InstallAllUsers=0 PrependPath=1 Include_test=0`
  - VSCode: `VSCodeUserSetup-x64-XX.exe /VERYSILENT /NORESTART /MERGETASKS=!runcode`
  - OpenClaw: `npm install -g openclaw@latest` *(cần Node 22.22.3+ / 24.15+ / 25.9+)*
  - ⚠️ Không cài OpenClaw qua pip — gói PyPI `openclaw` là gói squatter, không liên quan đến OpenClaw.
  - 9Router: `npm install -g 9router` *(repo chính thức `decolua/9router`; tránh fork `dreammaker97/99router`)*
- **Manifest gỡ cài**: lưu `%LocalAppData%\AITools\manifest.txt` — danh sách những gì tool đã cài + phiên bản → cơ sở cho chức năng Uninstall.

## Combo 9Router `my-combo` (→ build; trích từ máy tham chiếu, 2026-08-14)

- Tên combo: `my-combo`
- Model dùng chung: `deepseek-v4-flash` (DeepSeek v4 Flash) — chuỗi fallback gồm 3 nhà cung cấp:
  1. `oc/deepseek-v4-flash-free` — **OpenCode Free** (tầng miễn phí)
  2. `openrouter/deepseek-v4-flash` — **OpenRouter**
  3. `ds/deepseek-v4-flash` — **DeepSeek** (chính chủ)
- Tool cần tái tạo đúng combo này trên máy mới.
- ⚠️ API keys KHÔNG được lưu trong brief/addendum. Trên máy mới: OpenCode Free thường hoạt động không cần key; OpenRouter & DeepSeek cần người dùng nhập key trong bước cấu hình lần đầu.

## Extension Claude Code cho VSCode (→ build)

- Market ID: `anthropic.claude-code` — cài bằng `code --install-extension anthropic.claude-code`. Cần Claude Code CLI + đăng nhập tài khoản (xử lý trong bước cấu hình lần đầu).

## Khởi động cùng Windows (→ build; bước cấu hình lần đầu)

- 9Router: chạy gateway nền. Lệnh/đăng ký autostart cụ thể cần **xác minh khi build** (ứng viên: registry Run key `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`, startup shortcut, hoặc cơ chế service/autostart riêng của 9Router — kiểm tra `9router --help`).
- OpenClaw: gateway có cơ chế autostart riêng — **xác minh khi build** (`openclaw --help`, `openclaw gateway --help`).
- ⚠️ Không ghi cứng lệnh chưa kiểm chứng vào brief; build phase sẽ xác minh trên máy thật.

## Tự cập nhật tool (→ build)

- So sánh version local (biến trong .bat) với GitHub Releases API `api.github.com/repos/giakhanhquoc141-rgb/AI_AGENT_INSTALL/releases/latest` (qua PowerShell); nếu có bản mới → tải .bat mới và tự thay thế (ghi đè chính file đang chạy). Repo: **`giakhanhquoc141-rgb/AI_AGENT_INSTALL`** (https://github.com/giakhanhquoc141-rgb/AI_AGENT_INSTALL). Nếu chọn file version trong repo thay cho Releases API, ghi rõ đường dẫn.
