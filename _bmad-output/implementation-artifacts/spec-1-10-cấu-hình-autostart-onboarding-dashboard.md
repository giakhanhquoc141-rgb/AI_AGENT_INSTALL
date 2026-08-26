---
title: 'Cấu hình autostart, onboarding và dashboard'
type: 'feature'
created: '2026-08-26'
baseline_commit: 'b73145f2b74b2407a81dac36db15094f32bd77d8'
status: 'done'
---

## Intent

Đăng ký 9Router/OpenClaw tự chạy, hướng dẫn người dùng tự nhập API key trong dashboard và mở hai giao diện sau khi cài stack.

## Tasks & Acceptance

- [x] HKCU Run 9Router, gateway install OpenClaw, idempotent và hidden.
- [x] Ghi manifest artifact chính xác, mở dashboard, không đụng API key.
- [x] Harness cô lập.

Given chạy lại, when artifact đúng tồn tại, then không đăng ký trùng. Given hoàn tất, then mở localhost:20128 và 127.0.0.1:18789.

## Verification

`../scratch/story-1-10-autostart-harness.ps1`: PASS toàn bộ; `git diff --check`: PASS.

## Suggested Review Order

- Configure/autostart phase: [`AI_Tools_Installer.bat:441`](../../AI_Tools_Installer.bat#L441)
- Manifest artifacts: [`AI_Tools_Installer.bat:461`](../../AI_Tools_Installer.bat#L461)
- Dashboard/onboarding: [`AI_Tools_Installer.bat:485`](../../AI_Tools_Installer.bat#L485)
