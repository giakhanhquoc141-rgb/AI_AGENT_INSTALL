---
story: 3.1
title: Manifest — schema và vòng đời
status: in-review
---

# Story 3.1 — Manifest: schema và vòng đời

## Mục tiêu

Ghi lại chính xác mọi thay đổi do installer tạo ra để nhánh gỡ cài đặt có thể đọc, xác thực và dọn đúng dữ liệu của AI Tools mà không ảnh hưởng ứng dụng khác.

## Phạm vi

- Chuẩn hóa manifest tại `%LOCALAPPDATA%\AITools\manifest.txt` theo đúng bốn trường: `item | version | installed-at-YYYY-MM-DD | path`.
- Từ chối bản ghi thiếu trường, có ký tự phân cách hoặc xuống dòng trong dữ liệu đầu vào; không tạo bản ghi trùng cùng item/version/path.
- Ghi artifact tự khởi động bằng item có kind và tên chính xác; giữ version là chuỗi đã chuẩn hóa từ bước quét.
- Cung cấp helper kiểm tra schema trước lifecycle và helper dọn manifest/log của riêng AI Tools sau khi uninstall hoàn tất.

## Acceptance criteria

- Given installer thực hiện mutation, when gọi `manifest_append`, then manifest có đúng bốn trường và ngày ISO.
- Given input chứa `|`, CR hoặc LF, when ghi manifest, then thao tác thất bại và không thêm dòng hỏng.
- Given manifest có dòng sai schema, when gọi `manifest_validate`, then helper trả lỗi mà không sửa dữ liệu.
- Given artifact autostart được tạo, when ghi manifest, then item chứa kind, tên chính xác và target.
- Given lifecycle uninstall đã hoàn tất, when gọi `manifest_clear`, then chỉ manifest và log trong `%LOCALAPPDATA%\AITools` bị xóa.

## Code map

- `AI_Tools_Installer.bat`: `manifest_append`, `manifest_validate`, `manifest_clear`.
- `_bmad-output/scratch/story-3-1-manifest-harness.ps1`: kiểm thử hợp đồng schema/lifecycle không mutation máy.

## Verification

Harness đã chạy đạt toàn bộ kiểm tra tĩnh của schema, validation, autostart metadata và cleanup scope.
