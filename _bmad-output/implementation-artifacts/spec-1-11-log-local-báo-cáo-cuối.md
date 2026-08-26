---
title: 'Log cục bộ và báo cáo cuối'
type: 'feature'
created: '2026-08-26'
baseline_commit: '9fad1a735f17bbbea95d1941d1fdb96b6f33929d'
status: 'done'
---

## Intent

Ghi log cục bộ cho từng bước và hiển thị báo cáo cuối bằng tiếng Việt với số mục thành công/thất bại cùng vị trí log.

## Tasks & Acceptance

- [x] Thêm `report_block` sau configure, tổng hợp 10 mục.
- [x] Append log dưới `%LOCALAPPDATA%\AITools\logs\` và giữ log cũ.
- [x] Harness cô lập không API key/telemetry.

Given pipeline hoàn tất, when report chạy, then hiển thị X/Y, mục lỗi và đường dẫn log; mỗi report append đúng một dòng.

## Verification

`../scratch/story-1-11-logging-report-harness.ps1`: PASS; `git diff --check`: PASS.

## Suggested Review Order

- Pipeline report call: [`AI_Tools_Installer.bat:159`](../../AI_Tools_Installer.bat#L159)
- Log helper: [`AI_Tools_Installer.bat:52`](../../AI_Tools_Installer.bat#L52)
- Final report: [`AI_Tools_Installer.bat:518`](../../AI_Tools_Installer.bat#L518)
