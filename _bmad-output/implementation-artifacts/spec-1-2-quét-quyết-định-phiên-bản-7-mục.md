---
title: 'Quét & quyết định phiên bản 7 mục'
type: 'feature'
created: '2026-08-16'
status: 'done'
baseline_commit: '1b77f2d6767cdb72e8ad9dd3633c262c57f65504'
review_loop_iteration: 0
context: ['_bmad-output/implementation-artifacts/epic-1-context.md']
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Tool chỉ có stub scan (1.1) — chưa biết máy có gì, version nào, cần cài/skip/update gì.

**Approach:** Thay stub scan bằng pha scan+decide thật: phát hiện 7 mục (Git, Node, Python, VSCode, ext Claude Code, OpenClaw, 9Router), chuẩn hóa version qua helper dùng chung, so với bản mới nhất (nguồn chính thức, PowerShell) → mỗi mục đúng 1 trong INSTALL/SKIP/UPDATE; lọc Python Store-stub + portable-node OpenClaw; Node chọn LTS 22/24 tương thích; ghi run-state một lần.

## Boundaries & Constraints

**Always:**
- Một file `.bat` duy nhất (AD-3); UI tiếng Việt/UTF-8, zero tiếng Anh (AD-11).
- PowerShell sở hữu mọi network/JSON/so-version; batch chỉ điều phối (AD-2).
- Helper version-check dùng chung là nguồn duy nhất tạo chuỗi version (AD-6) — log/run-state ghi đúng chuỗi chuẩn hóa.
- Mỗi mục đúng 1 trong INSTALL/SKIP/UPDATE; không hạ cấp (AD-6, FR-7).
- Scan chỉ phát hiện + quyết định — không cài đặt/sửa PATH/registry/manifest (1.4–1.8).
- Run-state ghi một lần, chỉ đọc sau (AD-12); chạy lại an toàn.
- Nguồn chính thức, retry 3, lỗi một mục không chặn mục khác, offline báo lỗi tiếng Việt rõ (AD-7).

**Ask First:** Ngoài phạm vi story 1.2 → HALT hỏi trước.

**Never:**
- Không plan+confirm/execute/configure/report (1.3–1.11); không so phiên bản trong batch thuần (AD-2).
- Không nguồn không chính thức/telemetry/API key (AD-7, AD-8); không `setx`/`%ProgramFiles%`/HKLM/UAC (AD-4).

</frozen-after-approval>

## Code Map

- `AI_Tools_Installer.bat` (project root) — thay `:scan_block` stub bằng scan thật + PowerShell version-check; thêm `:plan_block` stub (1.3). File đã có [init]/[helpers]/[router] (1.1).
- `spec-1-1-khởi-tạo-tool-wizard-chào-mừng.md` (cùng thư mục) — continuity: hợp đồng `run_step`/`log_append`/`color_echo`.
- `epic-1-context.md` (cùng thư mục) — bảng chuẩn hóa version + nguồn latest.

## Tasks & Acceptance

**Execution:**
- [x] `AI_Tools_Installer.bat` — Thay `:scan_block` bằng scan thật: PowerShell version-check (7 format, lọc stub), phát hiện 7 mục + fetch latest (retry 3), quyết định INSTALL/SKIP/UPDATE (không hạ cấp; Node LTS 22/24; ext: có→SKIP, chưa→INSTALL), ghi run-state một lần, hiển thị từng mục tiếng Việt; thêm `:plan_block` stub "chưa hỗ trợ" + thoát; `:run_install`: welcome→scan→plan.

**Acceptance Criteria:**
- Given máy chỉ có stub Python (WindowsApps), when quét Python, then báo "chưa cài" (INSTALL) — không bị stub đánh lừa.
- Given `where node` trúng portable node của OpenClaw, when quét Node, then không kết luận nhầm "đã cài Node chính thức".
- Given 7 mục đã quét, when so current với latest (nguồn chính thức), then mỗi mục đúng 1 trong INSTALL/SKIP/UPDATE — không trạng thái mơ hồ.
- Given current ≥ latest, when quyết định, then SKIP — không bao giờ cài đè xuống bản thấp hơn.
- Given Node cần cài, when chọn phiên bản, then chọn LTS 22.x/24.x tương thích OpenClaw, không bao giờ Current 26.x.
- Given version đọc từ lệnh khác nhau (Node `v` đầu, VSCode 3 dòng, OpenClaw calendar, Git `windows.P`, Python/9Router sạch), when helper dùng chung xử lý, then mọi version chuẩn hóa đúng định dạng từng mục và log ghi đúng chuỗi chuẩn hóa.

## Spec Change Log

## Design Notes

Latest: nodejs.org/dist/index.json (chọn LTS mới nhất trong nhánh `[22.22.3,23)` ∪ `[24.15,25)` — nhánh `>=25.9` của engine range là Current, loại theo FR-8), python.org downloads (3.13.x stable — v1 pin 3.13, xem Deferred), GitHub latest (VSCode, MinGit), npm dist-tags (openclaw, 9router). Ext: có→SKIP, chưa→INSTALL. Lọc: Python `--version` không ra `Python X.Y.Z` (vd stub WindowsApps) → coi chưa cài; Node path chứa `openclaw` → portable. So sánh đúng kiểu (semver vs calendar-string). Run-state: `ST_<item>`/`VR_<item>`/`VL_<item>` set một lần, chỉ đọc sau.

## Verification

**Commands:**
- `cmd /c AI_Tools_Installer.bat` (piped keys) -- expected: scan từng mục tiếng Việt, plan stub "chưa hỗ trợ", thoát an toàn; không tiếng Anh; log `scan | ok`.
- Scratch harness edge cases (stub, portable, format, LTS, offline) -- expected: đúng ACs/Design Notes.

**Manual checks:**
- Chạy scan 2 lần → giống nhau (idempotent).

## Suggested Review Order

**Scan & decide (lõi thay đổi)**

- Cổng vào pha scan — chạy PowerShell version-check rồi hiển thị 7 mục
  [`AI_Tools_Installer.bat:134`](../../AI_Tools_Installer.bat#L134)

- Helper version-check: chuẩn hóa format, lọc stub/portable, fetch latest, Decide
  [`AI_Tools_Installer.bat:147`](../../AI_Tools_Installer.bat#L147)

**Run-state & parse**

- Guard validate đủ 7 mục sau parse — chống dòng thiếu hiện sai
  [`AI_Tools_Installer.bat:152`](../../AI_Tools_Installer.bat#L152)

- Parse `item|current|latest|decision` → biến ST_/VR_/VL_
  [`AI_Tools_Installer.bat:190`](../../AI_Tools_Installer.bat#L190)

**Presentation**

- Hiển thị từng mục tiếng Việt theo quyết định
  [`AI_Tools_Installer.bat:203`](../../AI_Tools_Installer.bat#L203)

**Pipeline**

- welcome→scan→plan, propagate RC từng bước (AD-1/AD-9)
  [`AI_Tools_Installer.bat:101`](../../AI_Tools_Installer.bat#L101)

- Plan stub — story 1.3 sẽ thay
  [`AI_Tools_Installer.bat:228`](../../AI_Tools_Installer.bat#L228)
