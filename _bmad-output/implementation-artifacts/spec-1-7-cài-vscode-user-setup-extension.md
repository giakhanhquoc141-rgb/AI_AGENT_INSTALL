---
title: 'Cài VS Code User Setup và extension Claude Code'
type: 'feature'
created: '2026-08-26'
baseline_commit: '056bcc99a25017f52158aa254b2e6d0117d5aa78'
status: 'done'
review_loop_iteration: 0
context: ['_bmad-output/implementation-artifacts/epic-1-context.md']
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** VS Code và extension Claude Code hiện còn là stub, nên người dùng phải tự cài và tự cấu hình trước khi dùng AI coding.

**Approach:** Tải VS Code User Setup từ feed chính thức, cài silent per-user vào `%LOCALAPPDATA%\Programs\Microsoft VS Code`, refresh PATH, cài extension `anthropic.claude-code` bằng `code.cmd`, rồi xác minh đúng binary/extension mà không mở cửa sổ VS Code.

## Boundaries & Constraints

**Always:** Một `.bat`, UI tiếng Việt/UTF-8; VS Code User Setup x64 từ `https://update.code.visualstudio.com/latest/win32-x64-user/stable`; flags `/VERYSILENT /NORESTART /MERGETASKS=!runcode`; target per-user chính xác; không UAC/Program Files/HKLM; VS Code trước extension; retry 3 cho tải; xác minh installer Authenticode Microsoft Corporation nếu khả dụng; PATH controller chung; verify `bin\code.cmd --version`, extension install exit 0 và `code --list-extensions` có `anthropic.claude-code`; manifest chỉ ghi sau thành công; lỗi một mục không chặn mục sau.

**Ask First:** Installer yêu cầu all-users/elevation, target managed không thể backup/khôi phục, hoặc extension cần outbound/source ngoài VS Code Marketplace.

**Never:** Không mở `Code.exe`; không full-system installer, winget, `%ProgramFiles%`, HKLM, `setx`, telemetry, API key; không cài extension khác; không ghi manifest trước verify.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Cài VS Code mới | `ST_VSCode=INSTALL`, target absent | Silent User Setup, target + code.cmd, PATH refreshed | Fail rõ, dọn temp |
| Cập nhật managed | `UPDATE`, target tồn tại | Backup target, installer thành công, verify version | Restore target/PATH/manifest nếu hậu xử lý lỗi |
| Extension | VS Code vừa cài/đã có | `code.cmd --install-extension ... --force` exit 0; list contains ID | Log fail, tiếp tục OpenClaw/9Router |
| Download lỗi | URL lỗi/rỗng | Retry tối đa 3, không chạy file | 1 log fail, không mutation |
| UAC/all-users | Installer hoặc flag bất thường | Không tiếp tục | Báo cần bản User Setup, giữ máy nguyên trạng |

</frozen-after-approval>

## Code Map

- `AI_Tools_Installer.bat:98` — PATH controller dùng chung, append và refresh session.
- `AI_Tools_Installer.bat:124` — manifest helper, kiểm tra errorlevel trước log ok.
- `AI_Tools_Installer.bat:367` — execute order Node → Git → Python → VSCode → extension → npm items.
- `AI_Tools_Installer.bat:427` — `:try_install_vscode` stub cần thay bằng dispatcher + installer.
- `AI_Tools_Installer.bat:430` — `:try_install_vscodeext` stub cần thay bằng extension step phụ thuộc VS Code.
- `AI_Tools_Installer.bat:583` — Git transaction mẫu cho backup/rollback; giữ các cải tiến an toàn từ stories trước.
- `_bmad-output/planning-artifacts/prds/prd-AI_AGENT_INSTALL-2026-08-14/addendum.md:40` — URL, flags và `code.cmd` contract chính thức.

## Tasks & Acceptance

**Execution:**
- [x] `AI_Tools_Installer.bat` — thay hai stub VS Code/extension bằng dispatcher, installer User Setup, PATH refresh và extension install theo matrix.
- [x] `AI_Tools_Installer.bat` — thêm retry/signature/backup-rollback/manifest transaction và exact verification; không mở VS Code.
- [x] `_bmad-output/scratch/` — thêm harness kiểm tra flags, URL, order, extension ID, no-UAC/ProgramFiles và failure continuation mà không mutation máy thật.

**Acceptance Criteria:**
- Given VS Code chưa cài, when execute chạy, then User Setup cài đúng target per-user, không tự mở cửa sổ và `code.cmd --version` chạy được.
- Given VS Code vừa cài, when extension step chạy, then extension ID có trong `code --list-extensions` và lệnh cài trả exit 0.
- Given VS Code/extension lỗi, when execute tiếp tục, then mục sau vẫn được gọi và log phản ánh đúng lỗi.

## Spec Change Log

### 2026-08-26 — Review pass
- patch: corrected Inno Setup task flag, initialized extension target path, protected manifest backup, hardened VS Code rollback, removed persistent PATH mutation from extension-only step, and recorded the real user extension path.
- defer: real VS Code/Marketplace E2E remains pending in disposable Windows VM.

## Design Notes

Download dùng `latest/win32-x64-user/stable` để lấy binary, còn version scan hiện tại tiếp tục dùng GitHub Releases API. Extension luôn gọi absolute `bin\code.cmd` sau PATH refresh để tránh nhầm `code` khác trên máy.

## Verification

**Commands:**
- `cmd /d /c "echo HH| AI_Tools_Installer.bat"` — expected: hủy an toàn, exit 0.
- Harness isolated — expected: flags/order/URL/extension/continuation/rollback checks PASS, không đổi máy thật.
- `git diff --check` — expected: sạch.

**Manual checks:**
- VM/user disposable: zero UAC, không Code.exe tự mở, `where code` trỏ User Setup, extension list đúng ID.

## Suggested Review Order

**Điều phối**

- Bắt đầu tại execute order để thấy VS Code hoàn tất trước extension và npm items.
  [`AI_Tools_Installer.bat:367`](../../AI_Tools_Installer.bat#L367)

**User Setup transaction**

- Kiểm tra URL, GUID transaction, backup và User Setup flags.
  [`AI_Tools_Installer.bat:459`](../../AI_Tools_Installer.bat#L459)

- Xác nhận code.cmd verify và manifest chỉ ghi sau thành công.
  [`AI_Tools_Installer.bat:494`](../../AI_Tools_Installer.bat#L494)

- Rà rollback khi backup, installer, PATH hoặc manifest thất bại.
  [`AI_Tools_Installer.bat:529`](../../AI_Tools_Installer.bat#L529)

**Extension**

- Theo dõi absolute code.cmd, session PATH và extension ID verification.
  [`AI_Tools_Installer.bat:591`](../../AI_Tools_Installer.bat#L591)

**Verification**

- Đọc harness tĩnh/cô lập cho flags, order, rollback và continuation.
  [`test-vscode-installer.ps1:1`](../scratch/test-vscode-installer.ps1#L1)

- Xác nhận story review và story 1-8 vẫn backlog.
  [`sprint-status.yaml:45`](sprint-status.yaml#L45)
