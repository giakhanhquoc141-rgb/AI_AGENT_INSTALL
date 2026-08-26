---
title: 'Cài Python silent per-user'
type: 'feature'
created: '2026-08-26'
baseline_commit: '6dbd4f33a1ccbef77d3003f1899dc760429fb06e'
status: 'done'
review_loop_iteration: 0
context: ['_bmad-output/implementation-artifacts/epic-1-context.md']
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Execute phase chưa cài Python; Store App Execution Alias có thể chiếm lệnh `python`, khiến người dùng không chạy được Python thật dù scan đã nhận diện đúng.

**Approach:** Thay stub Python bằng installer chính thức Python 3.13.x chạy silent per-user vào `%LOCALAPPDATA%\Programs\Python\Python313`, refresh PATH qua controller chung, xác minh đúng executable/version trong phiên và ghi manifest.

## Boundaries & Constraints

**Always:** Một file `.bat`, UI tiếng Việt/UTF-8; Windows 10/11 64-bit; nguồn `python.org`, retry tối đa 3; validate `VL_Python=3.13.x`; xác minh Authenticode hợp lệ và signer thuộc Python Software Foundation trước khi chạy; cài `InstallAllUsers=0 Include_launcher=0 PrependPath=0 Shortcuts=0 Include_test=0 /quiet /norestart`; target chính xác `%LOCALAPPDATA%\Programs\Python\Python313`; thêm cả root và `Scripts` qua PATH-controller, đặt trước WindowsApps trong phiên; verify executable trực tiếp và `python` qua PATH đều đúng `VL_Python`; mutation thành công mới ghi manifest; đúng một log kết quả; lỗi Python không chặn mục sau.

**Ask First:** Bất kỳ giải pháp nào cần xóa Python có sẵn, sửa App Execution Alias, ghi ngoài `%LOCALAPPDATA%`/HKCU, hoặc không thể giữ nguyên bản Python đang hoạt động khi update thất bại.

**Never:** Không launcher, Store/MSIX, winget, `%ProgramFiles%`, HKLM, UAC, `setx`; không cài VSCode/npm/configure; không chạm Python ngoài target do tool quản lý; không coi WindowsApps stub hay Python khác trên PATH là verify thành công.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Cài mới | `ST_Python=INSTALL`, `VL_Python=3.13.x` | Silent per-user; root+Scripts vào PATH; direct/PATH version đúng; manifest+1 log ok | Dọn temp; trả nonzero nếu lỗi |
| Cập nhật managed | `UPDATE`, target Python313 tồn tại | Installer nâng cấp không xóa trước; verify rồi cập nhật manifest | Giữ bản cũ nếu installer không commit được |
| Version không hợp lệ | trống, `-`, khác 3.13.x | Không tải/chạy installer | 1 log skip, trả nonzero |
| Store stub/Python khác | WindowsApps hoặc Python khác đứng trước | PATH phiên ưu tiên target; `Get-Command python` trỏ đúng target | Verify fail nếu không giành đúng resolution |
| Download/signature lỗi | mạng lỗi, file rỗng/signer sai | Tối đa 3 lần; không chạy file không tin cậy | Dọn temp, 1 log fail, tiếp tục mục sau |
| PATH/manifest lỗi | install xong nhưng hậu xử lý lỗi | Không báo ok; phục hồi PATH/manifest snapshot | Giữ artifact phục hồi nếu rollback lỗi |

</frozen-after-approval>

## Code Map

- `AI_Tools_Installer.bat:98` — `:path_append` dùng chung; phải giữ registry type/value, dấu `!`, empty segments và dedup.
- `AI_Tools_Installer.bat:124` — `:manifest_append`; kiểm tra errorlevel trước khi báo thành công.
- `AI_Tools_Installer.bat:193` — scan Python lọc Store stub, lấy latest 3.13.x và tạo `ST/VR/VL_Python`; execute chỉ đọc state này.
- `AI_Tools_Installer.bat:377` — `:execute_block` gọi Python sau Node/Git và tiếp tục các mục khác khi lỗi.
- `AI_Tools_Installer.bat:417` — `:try_install_python` hiện là stub cần thay bằng decision gate + installer.
- `AI_Tools_Installer.bat:438` — transaction Git là mẫu cho GUID temp, snapshot PATH/manifest, retry, cleanup và rollback; không sao chép logic ZIP/delete-directory.

## Tasks & Acceptance

**Execution:**
- [x] `AI_Tools_Installer.bat` — thay `:try_install_python` stub bằng INSTALL/UPDATE/SKIP dispatcher và `:install_python` silent per-user theo matrix.
- [x] `AI_Tools_Installer.bat` — thêm download/signature validation, snapshot+rollback PATH/manifest, exact direct/session verification và cleanup idempotent.
- [x] `_bmad-output/scratch/` — thêm harness cô lập hoặc kiểm tra tương đương cho version guard, retry, flags, Store-stub/PATH ordering và failure branches mà không mutation máy thật.

**Acceptance Criteria:**
- Given Python cần cài/cập nhật, when execute chạy, then Python 3.13.x nằm đúng target per-user, không UAC, không launcher/shortcut.
- Given Store alias hoặc Python khác có trên PATH, when install hoàn tất, then `python --version` trong phiên và console mới resolve target Python313 đúng version.
- Given một bước Python lỗi, when execute tiếp tục, then trạng thái tổng là lỗi nhưng các dispatcher sau vẫn chạy.

## Spec Change Log

### 2026-08-26 — Review pass
- patch: managed Python backup/restore, safe prepare-failure rollback, empty PATH preservation, 64-bit preflight, `where.exe` resolution and cleanup error reporting.
- defer: real installer/VM E2E remains pending because it requires a disposable Windows environment.

## Design Notes

Để tránh hai nguồn sửa PATH cạnh tranh, installer dùng `PrependPath=0`; controller chung sở hữu root+Scripts. Không xóa target trước update: installer chính thức chịu trách nhiệm nâng cấp in-place. Snapshot chỉ bảo vệ PATH/manifest; nếu update đòi destructive replacement hoặc rollback Python registration ngoài phạm vi per-user thì phải dừng theo Ask First.

## Verification

**Commands:**
- `cmd /d /c "echo HH| AI_Tools_Installer.bat"` — expected: hủy an toàn, exit 0, không install log.
- HEAD URL Python `https://www.python.org/ftp/python/<VL>/python-<VL>-amd64.exe` — expected: HTTP 200.
- Harness isolated — expected: guard/retry/flags/signature/PATH/rollback/continuation đều pass, không đổi HKCU PATH hay target thật.
- `git diff --check` — expected: sạch.
- Harness isolated (đã chạy) — PASS: managed target backup/restore, Windows 64-bit preflight, `where.exe` resolution, empty PATH components, cleanup-failure reporting; không mutation máy thật.
- Chưa chạy installer Python thật hoặc VM disposable; vì vậy chưa xác minh runtime Authenticode, UAC bằng 0, console mới và HTTP HEAD thực tế.

**Manual checks:**
- VM/user disposable: zero UAC; console mới `where python` dòng đầu là Python313 và version khớp; chạy lại SKIP, không trùng PATH/manifest.

## Suggested Review Order

**Điều phối**

- Bắt đầu tại dispatcher để thấy Python chạy sau Node/Git và vẫn tiếp tục mục sau.
  [`AI_Tools_Installer.bat:367`](../../AI_Tools_Installer.bat#L367)

**Installer và transaction**

- Kiểm tra guard version/kiến trúc, tải chính thức và xác minh chữ ký.
  [`AI_Tools_Installer.bat:445`](../../AI_Tools_Installer.bat#L445)

- Theo dõi backup target, flags silent per-user và PATH ordering.
  [`AI_Tools_Installer.bat:480`](../../AI_Tools_Installer.bat#L480)

- Xác nhận direct/PATH/where verification trước manifest.
  [`AI_Tools_Installer.bat:495`](../../AI_Tools_Installer.bat#L495)

- Rà rollback độc lập và giữ artifact khi phục hồi thất bại.
  [`AI_Tools_Installer.bat:548`](../../AI_Tools_Installer.bat#L548)

**Verification**

- Đọc harness cô lập cho guard, retry, PATH, rollback và cleanup.
  [`test-python-installer.ps1:1`](../scratch/test-python-installer.ps1#L1)

- Xác nhận story đã chuyển review mà backlog 1-7 vẫn nguyên trạng.
  [`sprint-status.yaml:44`](sprint-status.yaml#L44)
