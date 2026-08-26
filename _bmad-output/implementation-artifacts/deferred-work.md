# Deferred Work

Các mục phát hiện trong review nhưng không thuộc phạm vi story hiện tại — ghi lại để xử lý tập trung sau.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-1-khởi-tạo-tool-wizard-chào-mừng.md`
  summary: Thêm automated smoke test cho router dispatch và step-contract (exit code + log line) của `AI_Tools_Installer.bat`.
  evidence: Verification-gap review — không có test nào chạy bất kỳ nhánh `:router` hay đọc log/exit code; một thay đổi đảo nhánh `--uninstall`/`--update` sẽ ship không bị phát hiện. Repo chưa có test framework; quyết định dựng test harness là việc ngoài story 1.1.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-1-khởi-tạo-tool-wizard-chào-mừng.md`
  summary: Khôi phục console codepage (`chcp`) và VT mode sau khi tool thoát.
  evidence: Blind-hunter review — `chcp 65001` và `SetConsoleMode` (VT) để lại trạng thái sau khi batch thoát, ảnh hưởng cửa sổ console đang mở của người dùng khi chạy trong terminal có sẵn. Nên xử lý khi console work được mở rộng (các story sau).

- source_spec: `_bmad-output/implementation-artifacts/spec-1-2-quét-quyết-định-phiên-bản-7-mục.md`
  summary: Thêm test regression cho `Cur`/`RetryC`/`Latest` — các bộ lọc detection (Python Store-stub, portable-node OpenClaw) và chuẩn hóa từng format.
  evidence: Verification-gap review — `unit.ps1` chỉ test `S3`/`Cmp3`/`Decide`/`PickNodeLatest`, không chạy `Cur` (detection); fakebin tồn tại nhưng không được nối vào harness. AC-1/AC-2 (đã verify live) không có test chống hồi quy.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-2-quét-quyết-định-phiên-bản-7-mục.md`
  summary: Thêm assertion automated cho contract offline/network-failure — exit code 1 + log `scan | fail` trên đường thất bại thật.
  evidence: Verification-gap review — `scan-offline.ps1`/`offline-test.bat` không tái hiện format hàng thật (thiếu sentinel `Sen`), không chạy failure-counting thật, không assert exit-code chain.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-2-quét-quyết-định-phiên-bản-7-mục.md`
  summary: OpenClaw so version theo kiểu chuỗi (calendar, đúng AD-6) có bẫy khi tháng đạt 2 chữ số (vd `2026.10.1` vs `2026.9.30` sắp xếp chuỗi sai).
  evidence: Blind-hunter review — string-compare của `Decide` cho OpenClaw; ví dụ `0.10.0` vs `0.9.0` không áp dụng (calendar) nhưng việc vượt tháng 10 sẽ so sai. Kiến trúc AD-6 chọn so-chuỗi; cần rà lại khi OpenClaw ra phiên bản tháng ≥10.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-2-quét-quyết-định-phiên-bản-7-mục.md`
  summary: Xử lý GitHub API rate limit (429/403, 60 req/hr cho unauthenticated) cho Git/VSCode.
  evidence: Blind-hunter review — retry 3 với sleep 300ms không đủ; quét lặp có thể chạm trần và báo "không xác định được bản mới nhất" mà không phân biệt rate-limit với mất mạng. Degrade hiện tại đã an toàn; cải tiến để sau.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-2-quét-quyết-định-phiên-bản-7-mục.md`
  summary: Mở rộng detection ngoài PATH — `py` launcher, VSCode không có PATH alias (`code.cmd`/`code-insiders`).
  evidence: Blind-hunter review — `Cur` chỉ nhận diện qua `Get-Command` trên PATH; VSCode/Python cài không có alias PATH sẽ bị báo là chưa cài. Ít gặp với User Setup mặc định (có thêm PATH), để tinh chỉnh sau.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-2-quét-quyết-định-phiên-bản-7-mục.md`
  summary: Tái cấu trúc khối PowerShell scan (hiện ~4.6KB, 8 biến, gần giới hạn dòng cmd 8191 ký tự) — thêm comment, tách hàm, ghi chú protocol `item|cur|latest|decision`.
  evidence: Blind-hunter review — dòng lệnh đơn khổng lồ không comment, coupling giữa PS và `:scan_parse`/`:show_item` ngầm, rủi ro truncation khi mở rộng. Không chặn story; cải tiến maintainability để sau.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-3-kế-hoạch-cài-đặt-xác-nhận-y-n.md`
  summary: Cancel/insufficient-scan đều return exit 0 từ `plan_block` — pipeline chưa phân biệt "hủy" với "đã xác nhận"; khi execute phase xuất hiện (story 1.4), hủy vẫn sẽ chạy tiếp vào cài đặt.
  evidence: Intent-alignment + blind-hunter review — `:plan_block` (các nhánh cancel/guard tại `AI_Tools_Installer.bat:274-284`) exit /b 0; `:run_install` chỉ gate theo errorlevel 1. Intent yêu cầu "H → thoát sạch"; cần tín hiệu hủy riêng (flag hoặc RC) để pipeline dừng — xử lý khi story 1.4 thêm execute.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-3-kế-hoạch-cài-đặt-xác-nhận-y-n.md`
  summary: Thêm test regression cho surface plan/confirm (render 7 mục, tổng kết, nhánh `choice` C/H, dòng log ok/skip).
  evidence: Verification-gap review — `unit.ps1` chỉ assert helper quyết định version; `offline-test.bat`/`partial-test.bat` vẫn dừng ở stub plan cũ. Cùng khoảng trống test harness chung đã ghi ở các item story 1-1/1-2.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-4-cài-node-per-user-refresh-path-trong-phiên.md`
  summary: Node UPDATE xóa toàn bộ `%LOCALAPPDATA%\node` (gồm `node_modules`) — sẽ mất npm global (openclaw/9router) nếu chúng được cài vào đó trước khi Node cập nhật.
  evidence: Blind-hunter + design review — `:install_node` dùng staging + `Remove-Item %NODE_DIR%` khi UPDATE. Node cài trước npm-items (1.8) nên lần đầu không mất; lần chạy sau sẽ xóa sạch npm global. Cần npm prefix riêng (`%LOCALAPPDATA%\npm`) hoặc preserve `node_modules` khi xử lý story 1.8.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-4-cài-node-per-user-refresh-path-trong-phiên.md`
  summary: Tải về chưa xác minh SHA256 — chỉ check kích thước >0; file hỏng/truncate chỉ lộ khi giải nén.
  evidence: Blind-hunter — AD-7 yêu cầu "xác minh SHA256 nơi nguồn cung cấp hash" (nodejs.org có SHASUMS256.txt). Hiện file hỏng dừng ở `extract-fail` (có thông báo), không âm thầm; thêm check hash khi hardening chung.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-4-cài-node-per-user-refresh-path-trong-phiên.md`
  summary: Thêm test tự động cho execute surface — `:execute_block`/`:install_node`/`:path_append`/`:manifest_append` + guard `PLAN_ABORT`.
  evidence: Verification-gap review — scratch tay đã verify nhưng không commit; `unit.ps1`/`offline-test.bat`/`partial-test.bat` không chứa symbol mới. Cùng khoảng trống test harness chung ở các item 1-1/1-2/1-3.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-4-cài-node-per-user-refresh-path-trong-phiên.md`
  summary: Fallback `LOCALAPPDATA=%TEMP%` (nếu biến không tồn tại) khiến Node cài vào `%TEMP%\node` nhưng manifest/PATH ghi `%LOCALAPPDATA%\node` — hai đường dẫn lệch.
  evidence: Đọc `:install_node` và `:manifest_append`/`:path_append` — chỉ xảy ra khi LOCALAPPDATA thực sự undefined (hiếm trên Windows); rà khi mở rộng execute cho các mục khác.
