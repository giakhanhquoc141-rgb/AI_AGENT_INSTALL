---
title: 'Gỡ cài đặt theo manifest'
type: 'feature'
created: '2026-08-26'
status: 'done'
---

## Intent

Gỡ chỉ các artifact do manifest của AI Tools sở hữu, xác thực manifest trước khi xóa, rollback khi có lỗi và dọn metadata lifecycle sau khi hoàn tất.

## Verification

- Harness: `_bmad-output/scratch/story-3-2-uninstall-harness.ps1`
- Phạm vi xóa được giới hạn bởi path trong manifest; manifest/log chỉ được dọn sau khi xử lý artifact thành công.
