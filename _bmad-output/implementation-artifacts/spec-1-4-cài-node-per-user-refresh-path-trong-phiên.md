---
title: 'Cài Node per-user + refresh PATH trong phiên'
type: 'feature'
created: '2026-08-26'
baseline_revision: '90c8dbabd235d0f387fee0eadcd4f5e208ad67d0'
status: 'done'
review_loop_iteration: 0
followup_review_recommended: true
context: ['_bmad-output/implementation-artifacts/epic-1-context.md']
warnings: []
deferred:
  - summary: >-
      Node UPDATE xóa toàn bộ %LOCALAPPDATA%\node (gồm node_modules) — sẽ mất npm global
      (openclaw/9router) nếu chúng được cài vào đó trước khi Node cập nhật.
    evidence: |-
      :install_node dùng staging + Remove-Item %NODE_DIR% khi cập nhật. Trong luồng tool, Node cài
      trước npm-items (1.8) nên lần đầu không mất; nhưng lần chạy sau (Node có bản mới, npm-items
      đã cài vào node\node_modules) sẽ xóa sạch. Cần xử lý khi story 1.8 (npm prefix riêng) hoặc khi
      mở rộng execute.
    location: >-
      AI_Tools_Installer.bat:501
    severity: medium
  - summary: >-
      Tải về chưa xác minh SHA256 — chỉ check kích thước >0; file lỗi/truncate chỉ bị lộ khi giải nén.
    evidence: |-
      AD-7 yêu cầu "xác minh SHA256 nơi nguồn cung cấp hash". nodejs.org có SHASUMS256.txt;
      thêm check hash cho các bản tải khi hardening chung. Hiện file hỏng dừng ở extract-fail (có
      thông báo) nên không âm thầm.
    location: >-
      AI_Tools_Installer.bat:486
    severity: medium
  - summary: >-
      Không có test tự động nào chạy execute/install/PATH-controller/manifest + guard PLAN_ABORT;
      chỉ có scratch tay, không commit.
    evidence: |-
      Verification-gap review — unit.ps1/offline-test.bat/partial-test.bat không chứa các symbol mới.
      Cùng khoảng trống test harness chung đã ghi ở deferred-work cho 1-1/1-2/1-3.
    location: >-
      AI_Tools_Installer.bat:428
    severity: medium
  - summary: >-
      Fallback LOCALAPPDATA=%TEMP% (nếu biến không tồn tại) khiến Node cài vào %TEMP%\node nhưng
      manifest/PATH ghi %LOCALAPPDATA%\node — hai đường dẫn lệch nhau.
    evidence: |-
      Đọc :install_node (L472) và :manifest_append/:path_append — chỉ xảy ra khi LOCALAPPDATA thực
      sự undefined (hiếm trên Windows); edge case cần rà khi mở rộng.
    location: >-
      AI_Tools_Installer.bat:472
    severity: low
---

<intent-contract>

## Intent

**Problem:** Plan xác nhận xong nhưng chưa có execute phase — chưa cài được gì. Node là mục đầu tiên và là tiền đề cho npm (OpenClaw/9Router) và extension Claude Code.

**Approach:** Thêm pha execute (bước 4/6): nếu Node là INSTALL/UPDATE thì tải ZIP chính thức `nodejs.org/dist/v<ver>/node-v<ver>-win-x64.zip`, giải nén vào `%LOCALAPPDATA%\node`, thêm PATH người dùng qua PATH-controller (giữ `REG_EXPAND_SZ`, không `setx`), refresh PATH trong phiên từ registry, verify `node --version`/`npm --version` chạy ngay, ghi manifest. Node đứng trước các mục npm. Các mục khác chưa có installer trong story này → log `install | skip | not-supported-yet`. Sửa cancel-gating: hủy plan không được chạy execute.

## Boundaries & Constraints

**Always:**
- Một file `.bat` duy nhất (AD-3); UI tiếng Việt/UTF-8, zero tiếng Anh (AD-11).
- Execute là bước 4/6 trong pipeline cố định (AD-1); thứ tự topo: Node trước npm-items.
- Per-user/no-admin là gate cứng (AD-4): chỉ ghi `%LOCALAPPDATA%`, HKCU, user PATH; không `%ProgramFiles%`/HKLM/UAC. Toàn bộ phiên.
- Nguồn chính thức + retry 3 (AD-7); lỗi một mục không làm hỏng mục khác (AD-12 idempotent, chạy lại an toàn).
- PATH-controller: read → append-if-absent → write, giữ `REG_EXPAND_SZ`, không `setx`, không truncate >1024 ký tự; refresh PATH trong phiên từ registry (AD-10).
- Node chỉ cài phiên bản trong VL_Node (LTS 22/24 do scan chọn theo FR-8); không bao giờ Current 26.x.
- Mọi mutation ghi manifest `item | version | installed-at-YYYY-MM-DD | path` (AD-5; sở hữu schema ở Epic 3, ghi từng dòng trong các story install).
- Hợp đồng bước: đúng 1 dòng log `install | ok|fail|skip` (AD-9). Hủy plan (H) phải chặn execute — PLAN_ABORT export từ plan_block.

**Block If:** Không xác định được phiên bản Node để cài (VL_Node trống/`-`) → không đoán, báo lỗi tiếng Việt, log `install | skip | unknown-version`.

**Never:**
- Không configure/report (1.9–1.11); không cài Git/Python/VSCode/npm items (1.5–1.8) — các mục đó chưa có installer trong story này.
- Không `setx`/`%ProgramFiles%`/HKLM/UAC (AD-4); không nguồn không chính thức/telemetry/API key (AD-7/AD-8).
- Không ghi đè PATH hiện có hay cắt/truncate; không thêm trùng entry.

</intent-contract>

## Code Map

- `AI_Tools_Installer.bat` (project root) — thêm `:execute_block` (bước 4/6) + `:install_node` + PATH-controller `:path_append` + `:manifest_append`; sửa `:run_install` (gọi execute, chặn khi hủy); sửa `:plan_block` (export `PLAN_ABORT`). Các helper hiện có: `:color_echo`/`:log_append`/`:run_step`/`:press_any_key`.
- Run-state: `ST_Node`/`VR_Node`/`VL_Node` (từ scan), `PLAN_ABORT` (từ plan).
- `epic-1-context.md` — AD-1/AD-4/AD-7/AD-10/AD-12, stack cài Node (ZIP per-user), manifest.
- `spec-1-3-...md` — continuity: `:plan_block` cancel/confirm, `:run_install` wiring.

## Tasks & Acceptance

**Execution:**
- `AI_Tools_Installer.bat` -- Thêm `:execute_block`: header "Bước 4/6 — Cài đặt"; gọi `:install_node` nếu Node INSTALL/UPDATE, ngược lại log `install | skip`; với Git/Python/VSCode/VSCodeExt/OpenClaw/9Router mà INSTALL/UPDATE → log `install | skip | not-supported-yet` (stub cho các story sau).
- `AI_Tools_Installer.bat` -- Thêm `:install_node`: lấy `VL_Node`; tải ZIP qua PowerShell (retry 3, `$ProgressPreference='SilentlyContinue'`) về `%TEMP%`; giải nén `Expand-Archive` → `%LOCALAPPDATA%\node`; verify `node --version` + `npm --version`; ghi manifest `Node | <ver> | <date> | %LOCALAPPDATA%\node`; log `install | ok|fail`.
- `AI_Tools_Installer.bat` -- Thêm PATH-controller `:path_append`: đọc HKCU\Environment Path + type, append `%LOCALAPPDATA%\node` nếu chưa có (so sánh không phân biệt hoa thường), ghi lại bằng `reg add ... /t REG_EXPAND_SZ`, không `setx`; refresh `%PATH%` trong phiên đọc lại từ registry.
- `AI_Tools_Installer.bat` -- Sửa `:plan_block`: `plan_cancel`/guard export `PLAN_ABORT=1`, `plan_confirm` export `PLAN_ABORT=`; sửa `:run_install`: `if defined PLAN_ABORT goto :end` trước khi gọi execute.

**Acceptance Criteria:**
- Given Node INSTALL/UPDATE, when execute chạy, then `node --version` và `npm --version` chạy được ngay trong cùng phiên (PATH đã refresh).
- Given tool ghi PATH người dùng, when PATH-controller thêm `%LOCALAPPDATA%\node`, then PATH giữ kiểu `REG_EXPAND_SZ`, không dùng `setx`, không bị cắt/truncate.
- Given tải ZIP bị lỗi/gián đoạn, when tool tải lại, then retry tối đa 3 lần, lỗi được báo rõ và không làm hỏng mục khác.
- Given toàn bộ phiên cài Node, when thực hiện, then không xuất hiện UAC, không ghi `%ProgramFiles%` hay HKLM.
- Given tôi hủy ở plan (H), when execute được gọi, then pipeline dừng — không có mutation nào.
- Given Node chưa xác định version, when cài, then báo lỗi tiếng Việt rõ và log `install | skip | unknown-version`.

## Spec Change Log

## Review Triage Log

### 2026-08-26 — Review pass
- intent_gap: 0
- bad_spec: 0
- patch: 7: (high 1, medium 3, low 3)
- defer: 4: (high 0, medium 3, low 1)
- reject: 13
- addressed_findings:
  - `[high]` `[patch]` In-session PATH refresh giữ literal `%LOCALAPPDATA%\node` mà cmd không mở rộng khi tìm lệnh → node/npm không resolve được trên máy sạch (mọi cài mới báo verify-failed; scratch e2e cũ bị OpenClaw portable-node che). Sửa: refresh prepend đường dẫn đã mở rộng, registry giữ literal + REG_EXPAND_SZ. Verified: `where probe-node` resolve được từ scratch dir ở cả 2 loại key.
  - `[medium]` `[patch]` PATH type detection dead-code (REG_SZ bị ép thành REG_EXPAND_SZ). Sửa: seed REG_SZ → lưu dạng đã mở rộng; REG_EXPAND_SZ → lưu literal. Verified cả 2 trường hợp.
  - `[medium]` `[patch]` VL_Node chèn thẳng vào chuỗi PowerShell URL (injection/nhập sai) — thêm validation định dạng `^\d+\.\d+\.\d+$` trước khi tải.
  - `[medium]` `[patch]` `reg add` PATH không check errorlevel (lỗi âm thầm) — thêm check + nhánh `:inode_path_fail` (log `install | fail | path-write-failed`).
  - `[low]` `[patch]` execute_block in "Node.js — đang cài đặt..." cho cả nhánh skip và in "Bước cài đặt hoàn tất." dù có lỗi — di chuyển dòng vào nhánh cài thật, thêm "đã có sẵn — bỏ qua", "hoàn tất" chỉ khi EXEC_RC=0.
  - `[low]` `[patch]` ZIP + stage không được dọn sau khi cài xong — thêm `del`/`rmdir` sau thành công.
  - `[low]` `[patch]` manifest dedup theo cả dòng (kể cả ngày cài) — đổi `findstr` match theo `item | version |` (bỏ ngày).

## Auto Run Result

- **Summary:** Thêm pha execute (bước 4/6) cho Node: tải ZIP chính thức → giải nén `%LOCALAPPDATA%\node` → PATH-controller (REG_EXPAND_SZ, không setx) → refresh PATH trong phiên (dạng đã mở rộng) → verify node/npm → ghi manifest. Fix cancel-gating: hủy plan chặn execute. Các mục khác log `not-supported-yet` cho story 1.5–1.8.
- **Files changed:**
  - `AI_Tools_Installer.bat` — `:execute_block`, `:install_node` (+ nhánh lỗi unknown/download/extract/verify/path), PATH-controller `:path_append`, `:manifest_append`, `:run_install` gọi execute + gate `PLAN_ABORT`, `:plan_block` export `PLAN_ABORT`.
- **Review findings breakdown:** patches 7 (high 1, medium 3, low 3) · deferred 4 (medium 3, low 1) · rejected 13.
- **Follow-up review recommendation:** true (P1 high; score = 3×3 + 1×3 = 12 ≥ 5).
- **Verification performed:**
  - `cmd /c "echo HH| AI_Tools_Installer.bat"` → hủy plan, không có dòng `install` trong log, exit 0 (gate hoạt động).
  - URL Node 24.19.0 (`nodejs.org/dist/v24.19.0/node-v24.19.0-win-x64.zip`) → HTTP 200 (~37MB).
  - P1 scratch (redirect registry): sau `:path_append`, `where probe-node` tìm thấy entry từ thư mục scratch; registry giữ literal `%LOCALAPPDATA%\node` + REG_EXPAND_SZ.
  - P2 scratch: seed REG_SZ → lưu đường dẫn đã mở rộng (giữ REG_SZ); seed REG_EXPAND_SZ → lưu literal. Cả hai đều resolve được trong phiên.
  - Không mutation máy thật: `%LOCALAPPDATA%\node` không tồn tại, user PATH không đổi (307 ký tự), không có manifest thật.
- **Residual risks:**
  - Node UPDATE có thể xóa npm global (openclaw/9router) — deferred, xử lý khi story 1.8.
  - Chưa xác minh SHA256 cho tải về — deferred.
  - Chưa test tự động cho execute surface — deferred.

## Design Notes

Execute chỉ xử lý Node trong story này; các mục INSTALL/UPDATE khác (Git/Python/VSCode/OpenClaw/9Router) ghi `install | skip | not-supported-yet` — nhánh này bị thay bằng installer thật ở các story 1.5–1.8. Download qua PowerShell (AD-2) với `$ProgressPreference='SilentlyContinue'`; giải nén bằng `Expand-Archive`. PATH-controller đọc `reg query HKCU\Environment /v Path`, parse type + value, append-if-absent (so sánh `%LOCALAPPDATA%\node` không phân biệt hoa thường), ghi lại `reg add /t REG_EXPAND_SZ /f`, rồi `set "PATH=<giá trị mới>"` refresh trong phiên. Cancel-gating: `PLAN_ABORT` set trong plan_block và export qua `endlocal & set`; `:run_install` kiểm tra trước execute.

## Verification

**Commands:**
- `cmd /c "echo HH| AI_Tools_Installer.bat"` -- expected: hủy plan → không có execute (log không có dòng `install`), exit 0.
- Seeded SKIP integration (bản sao tạm seed ST_* = SKIP/INSTALL giả): execute_block chạy sạch, Node INSTALL trong bản sao dùng `%LOCALAPPDATA%` trỏ thư mục scratch + PATH-controller test trên biến ảo — không mutation máy thật.
- Verify URL Node: `curl -sI https://nodejs.org/dist/v<VL_Node>/node-v<VL_Node>-win-x64.zip` -- expected: HTTP 200.
- Unit logic PATH-append (append-if-absent, giữ REG_EXPAND_SZ) bằng scratch PS — expected: đúng, không trùng, không truncate.

**Manual checks (nếu cần):**
- Kiểm tra helper `:path_append` không `setx`, chỉ `reg add HKCU\Environment /v Path /t REG_EXPAND_SZ`.
