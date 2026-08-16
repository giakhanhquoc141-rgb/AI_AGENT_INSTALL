---
title: 'Khởi tạo tool & wizard chào mừng'
type: 'feature'
created: '2026-08-16'
status: 'done'
baseline_commit: '46fec9b5e6022918f4bd0e25a5e5e02cbf9e433a'
review_loop_iteration: 0
context: ['_bmad-output/implementation-artifacts/epic-1-context.md']
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Chưa có file tool; người dùng cần màn chào mừng tiếng Việt rõ ràng và khung sườn (helpers + router) để các story sau dựng lên.

**Approach:** Tạo file `.bat` duy nhất `AI_Tools_Installer.bat`: `chcp 65001`, banner tiếng Việt (logo ASCII 11 dòng, tên, phiên bản `0.1.0`, khẩu hiệu, giới thiệu 1 dòng), bấm phím bất kỳ để đi tiếp; dựng helpers (in màu, `log_append`, step-contract) và router dispatch theo mode.

## Boundaries & Constraints

**Always:**
- Một file `.bat` duy nhất, self-contained (AD-3).
- UI toàn tiếng Việt; `chcp 65001` đầu file; zero tiếng Anh hiển thị (AD-11, FR-4).
- Pipeline cố định welcome→scan→plan+confirm→execute→configure→report; router dispatch đúng 1 pipeline theo mode; block đúng thứ tự structural seed init→helpers→router (AD-1).
- Không cài đặt/PATH/registry/manifest/tải về; ghi máy duy nhất là log bước (AD-9) tại `%LOCALAPPDATA%\AITools\logs\`.

**Ask First:** Ngoài phạm vi story 1.1 → HALT hỏi trước.

**Never:**
- Không scan/plan/execute/configure/report (story 1.2–1.11); không uninstall/self-update thật — chỉ stub "chưa hỗ trợ" + thoát an toàn (Epic 2/3).
- Không tiếng Anh cho người dùng cuối; không so phiên bản trong batch thuần (AD-2).
- Không `setx`/`%ProgramFiles%`/HKLM/UAC/telemetry (AD-4, AD-8, AD-10).

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior |
|----------|--------------|---------------------------|
| HAPPY_PATH | Chạy `.bat` trên Win10/11 | `chcp 65001`; logo 11 dòng + thông tin + giới thiệu tiếng Việt, không vỡ cột |
| CONTINUE | Bấm phím bất kỳ | Sang bước kế tiếp (scan) — báo "chưa hỗ trợ" rồi thoát an toàn |
| MODE_FLAGS | `--uninstall` / `--update` | Báo "chưa hỗ trợ" tiếng Việt, thoát an toàn (exit 0) |
| UNKNOWN_MODE | Mode không nhận diện | Báo mode không hợp lệ, thoát an toàn |

</frozen-after-approval>

## Code Map

- `AI_Tools_Installer.bat` (project root) — file duy nhất cần tạo; chứa [init], [helpers], [router]. Greenfield.
- `_bmad-output/implementation-artifacts/epic-1-context.md` — context epic đã distill (ADs, structural seed, UX).

## Tasks & Acceptance

**Execution:**
- [x] `AI_Tools_Installer.bat` — `[init]`: `chcp 65001`, biến tên/phiên bản/khẩu hiệu, ký tự ESC; `[helpers]`: in-màu, `log_append`, step-contract (exit 0/nonzero + 1 dòng log, lỗi tiếng Việt); `[router]`: dispatch `%1` — install chạy welcome → scan stub "chưa hỗ trợ" + thoát; `--uninstall`/`--update` stub "chưa hỗ trợ" + thoát; mode lạ báo không hợp lệ.

**Acceptance Criteria:**
- Given chạy `.bat` trên Windows 10/11 mới tinh, when tool khởi động, then hiển thị logo ASCII đủ 11 dòng, tên, phiên bản, khẩu hiệu, giới thiệu 1 dòng tiếng Việt, không vỡ cột.
- Given tool khởi động, when kiểm tra, then console đã `chcp 65001` — tiếng Việt hiển thị đúng.
- Given màn chào mừng hiển thị, when bấm phím bất kỳ, then sang bước tiếp theo không cần gõ lệnh.
- Given tool khởi động, when kiểm tra nội bộ, then khung sườn có: helpers (in màu, `log_append`, step-contract), router nhánh install hoạt động, nhánh uninstall/self-update báo "chưa hỗ trợ" + thoát an toàn.
- Given tool chạy, when kiểm tra toàn bộ output, then không chuỗi tiếng Anh hiện cho người dùng cuối.

## Spec Change Log

## Design Notes

Màu ANSI (cam `38;5;214`, trắng đậm, xám): lấy ký tự ESC vào biến rồi in SGR; VT tắt thì màu degrade về mặc định — không in mã thô. Logo 11 dòng: art là visual polish — Deferred. `run_step <tên> <lệnh>` → 1 dòng log; `log_append` ghi `%LOCALAPPDATA%\AITools\logs\ai-tools-installer.log` (log đầy đủ ở story 1.11).

## Verification

**Commands:**
- `cmd /c AI_Tools_Installer.bat` -- expected: `chcp 65001`, banner tiếng Việt đúng không vỡ cột; bấm phím → "chưa hỗ trợ" rồi thoát.
- `cmd /c AI_Tools_Installer.bat --uninstall` / `--update` / `--xyz` -- expected: báo "chưa hỗ trợ"/"không hợp lệ", thoát an toàn.

**Manual checks:**
- Log `%LOCALAPPDATA%\AITools\logs\ai-tools-installer.log` có 1 dòng `welcome | ok | ...`.

## Suggested Review Order

**Routing & pipeline (entry point)**

- Cửa trước dispatch đúng 1 pipeline theo mode — ý đồ thiết kế (AD-1)
  [`AI_Tools_Installer.bat:93`](../../AI_Tools_Installer.bat#L93)

- Pipeline install theo dõi RC từng bước, exit nonzero khi có bước fail (AD-9)
  [`AI_Tools_Installer.bat:101`](../../AI_Tools_Installer.bat#L101)

**Welcome (presentation)**

- Banner 11 dòng + thông tin + chờ phím bất kỳ trước khi đi tiếp (AC-1/AC-3)
  [`AI_Tools_Installer.bat:109`](../../AI_Tools_Installer.bat#L109)

**Step contract & logging**

- run_step: đúng 1 dòng log ok/fail + propagate RC (AD-9)
  [`AI_Tools_Installer.bat:67`](../../AI_Tools_Installer.bat#L67)

- log_append: ghi log, fallback %TEMP% khi thiếu LOCALAPPDATA
  [`AI_Tools_Installer.bat:54`](../../AI_Tools_Installer.bat#L54)

**Color & encoding**

- ANSI màu degrade an toàn, không in mã thô ra màn hình
  [`AI_Tools_Installer.bat:40`](../../AI_Tools_Installer.bat#L40)

- UTF-8 tiếng Việt từ dòng đầu — không loạn ký tự (AC-2/AC-5)
  [`AI_Tools_Installer.bat:9`](../../AI_Tools_Installer.bat#L9)

**Stubs — Epic 2/3 (chưa implement)**

- uninstall/update/mode lạ: "chưa hỗ trợ" + thoát an toàn
  [`AI_Tools_Installer.bat:138`](../../AI_Tools_Installer.bat#L138)
