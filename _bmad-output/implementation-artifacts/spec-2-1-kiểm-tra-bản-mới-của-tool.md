---
title: 'Kiểm tra bản mới của tool'
type: 'feature'
created: '2026-08-26'
status: 'done'
review_loop_iteration: 0
context:
  - 'AI_Tools_Installer.bat'
  - '_bmad-output/scratch/story-2-1-update-harness.ps1'
---

## Intent

**Problem:** Người dùng chưa có cách an toàn để biết bản AI Tools Installer hiện tại có cũ hơn bản phát hành chính thức hay không.

**Approach:** Nhánh `--update` chỉ đọc GitHub Releases API chính thức qua PowerShell, chuẩn hóa tag phiên bản, so sánh với biến `TOOL_VERSION`, hiển thị rõ hiện tại/mới nhất và ghi log cục bộ.

## Boundaries & Constraints

**Always:** Chỉ gọi API `api.github.com/repos/giakhanhquoc141-rgb/AI_AGENT_INSTALL/releases/latest`; retry tối đa 3 lần; 404/trống là chưa có release; thông báo tiếng Việt; không tải file và không gửi telemetry.

**Ask First:** Không có quyết định cần hỏi trong phạm vi story này.

**Never:** Không tự tải, không thay thế file đang chạy, không đọc/ghi API key, không gọi nguồn ngoài GitHub Releases API.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|----------------------------|----------------|
| HAPPY_PATH | Release tag mới hơn | Hiển thị hiện tại → mới nhất; không tải | Ghi một dòng log `update | ok` |
| CURRENT | Tag bằng/thấp hơn | Báo đang dùng bản mới nhất | Ghi `update | skip` |
| NO_RELEASE | API 404 hoặc tag trống | Coi như chưa có bản mới, không crash | Ghi `update | skip` |
| NETWORK_ERROR | API lỗi liên tiếp | Giữ nguyên bản đang chạy | Retry 3 lần, báo tiếng Việt, ghi `update | fail` |

## Code Map

- `AI_Tools_Installer.bat` -- biến version/repository ở init; router `--update`; block `:self_update_check` gọi PowerShell, retry, so sánh, hiển thị và log.
- `_bmad-output/scratch/story-2-1-update-harness.ps1` -- harness cô lập kiểm tra router, API chính thức, retry, 404/trống, không tải và không credential; có kiểm tra API live không làm fail khi mạng bị chặn.
- `_bmad-output/implementation-artifacts/sprint-status.yaml` -- trạng thái story 2-1.

## Tasks & Acceptance

**Execution:**
- [x] `AI_Tools_Installer.bat` -- thay stub cập nhật bằng kiểm tra Releases API chỉ đọc -- cung cấp thông tin bản mới an toàn.
- [x] `_bmad-output/scratch/story-2-1-update-harness.ps1` -- kiểm thử cô lập các nhánh thành công/lỗi -- ngăn hồi quy và kiểm chứng ràng buộc bảo mật.
- [x] `_bmad-output/implementation-artifacts/sprint-status.yaml` -- đồng bộ trạng thái story -- phản ánh đã sẵn sàng review.

**Acceptance Criteria:**
- Given tool đang chạy, when gọi `--update`, then hiển thị rõ phiên bản hiện tại và bản phát hành mới nhất từ repo chính thức.
- Given có bản mới, when kiểm tra xong, then không có request tải xuống và người dùng vẫn kiểm soát việc cập nhật.
- Given API trả 404/trống, when kiểm tra, then tool báo chưa có release và thoát an toàn.
- Given mạng lỗi, when retry hết 3 lần, then giữ nguyên bản cũ, báo tiếng Việt và ghi log cục bộ.

## Verification

**Commands:**
- `powershell -NoProfile -ExecutionPolicy Bypass -File _bmad-output/scratch/story-2-1-update-harness.ps1` -- expected: tất cả kiểm tra PASS.
- `git diff --check` -- expected: không có whitespace lỗi.
