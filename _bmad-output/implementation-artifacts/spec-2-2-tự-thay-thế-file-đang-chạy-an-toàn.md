---
id: 2-2-tự-thay-thế-file-đang-chạy-an-toàn
title: Tự thay thế file đang chạy an toàn
status: done
created: 2026-08-26
updated: 2026-08-26
---

# Story 2.2: Tự thay thế file đang chạy an toàn

## Mục tiêu

Khi người dùng đồng ý cập nhật, công cụ tải bản `.bat` từ release chính thức vào file tạm cạnh bản đang chạy, kiểm tra nội dung tối thiểu, rồi trì hoãn thao tác đổi tên tới sau khi phiên hiện tại kết thúc. Bản cũ được giữ trong `.old` cho tới khi bản mới được đặt thành công; mọi lỗi đều giữ nguyên bản cũ.

## Acceptance Criteria

- Given người dùng đồng ý cập nhật, when tải asset thất bại hoặc file rỗng/không phải `.bat`, then file hiện tại không thay đổi và log ghi lỗi.
- Given asset hợp lệ, when phiên hiện tại kết thúc, then tiến trình con đổi bản hiện tại thành `.old`, đưa `.new` vào vị trí gốc, không ghi đè trực tiếp file đang thực thi.
- Given thao tác đổi tên thứ hai thất bại, when `.old` còn tồn tại, then tiến trình con khôi phục `.old` về vị trí gốc.
- Given bản mới chạy ổn định ở lần khởi động kế tiếp, then `.old` được dọn an toàn.

## Thiết kế và Code Map

- `AI_Tools_Installer.bat`: block `:self_update_replace`; tải asset qua HTTPS bằng PowerShell, ghi `.new.tmp`, kiểm tra kích thước và marker `@echo off`/`TOOL_VERSION`, đổi tên trì hoãn qua `cmd` con và rollback.
- `_bmad-output/scratch/story-2-2-self-replace-harness.ps1`: kiểm thử tĩnh các tên tệp tạm, backup, rollback, deferred rename, kiểm tra integrity và log.

## Bảo mật và độ tin cậy

Chỉ nhận URL asset do nhánh self-update lấy từ GitHub repo chính thức; không đọc API key. Tải lỗi hoặc kiểm tra nội dung thất bại sẽ xóa file tạm, không đụng bản đang chạy. Việc đổi tên diễn ra sau khi tiến trình hiện tại thoát; nếu bước thứ hai lỗi, bản `.old` được phục hồi.

## Verification

- `powershell -NoProfile -ExecutionPolicy Bypass -File _bmad-output/scratch/story-2-2-self-replace-harness.ps1` — tất cả kiểm tra PASS.
- `git diff --check` — không có lỗi khoảng trắng.

