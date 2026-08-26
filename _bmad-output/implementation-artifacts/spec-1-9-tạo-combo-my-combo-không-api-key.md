---
title: 'Tạo combo my-combo không đụng API key'
type: 'feature'
created: '2026-08-26'
baseline_commit: 'ca330517a6fbd5dcf3bc55b18c20e85a0d412321'
status: 'done'
context: ['_bmad-output/implementation-artifacts/epic-1-context.md']
---

## Intent

Tạo đúng một combo `my-combo` qua API cục bộ 9Router với model `deepseek-v4-flash` và fallback theo thứ tự đã định; không đọc, ghi hoặc truyền API key.

## Tasks & Acceptance

- [x] Thêm pha configure sau execute, idempotent GET/POST/PUT combo.
- [x] Ghi manifest/log sau khi API trả thành công.
- [x] Thêm harness cô lập, không mutation máy thật.

Given combo đúng đã tồn tại, when chạy lại, then không tạo trùng. Given combo sai, when chạy, then PUT đúng cấu hình. Given thiếu combo, when chạy, then POST đúng payload.

## Verification

Harness `../scratch/story-1-9-combo-harness.ps1`: PASS toàn bộ; `git diff --check`: PASS.

## Suggested Review Order

- Configure phase sau execute.
  [`AI_Tools_Installer.bat:397`](../../AI_Tools_Installer.bat#L397)
- Payload, idempotency và API cục bộ.
  [`AI_Tools_Installer.bat:413`](../../AI_Tools_Installer.bat#L413)
- Harness không credential.
  [`story-1-9-combo-harness.ps1:1`](../scratch/story-1-9-combo-harness.ps1#L1)
