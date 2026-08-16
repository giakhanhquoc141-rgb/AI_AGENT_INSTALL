# Deferred Work

Các mục phát hiện trong review nhưng không thuộc phạm vi story hiện tại — ghi lại để xử lý tập trung sau.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-1-khởi-tạo-tool-wizard-chào-mừng.md`
  summary: Thêm automated smoke test cho router dispatch và step-contract (exit code + log line) của `AI_Tools_Installer.bat`.
  evidence: Verification-gap review — không có test nào chạy bất kỳ nhánh `:router` hay đọc log/exit code; một thay đổi đảo nhánh `--uninstall`/`--update` sẽ ship không bị phát hiện. Repo chưa có test framework; quyết định dựng test harness là việc ngoài story 1.1.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-1-khởi-tạo-tool-wizard-chào-mừng.md`
  summary: Khôi phục console codepage (`chcp`) và VT mode sau khi tool thoát.
  evidence: Blind-hunter review — `chcp 65001` và `SetConsoleMode` (VT) để lại trạng thái sau khi batch thoát, ảnh hưởng cửa sổ console đang mở của người dùng khi chạy trong terminal có sẵn. Nên xử lý khi console work được mở rộng (các story sau).
