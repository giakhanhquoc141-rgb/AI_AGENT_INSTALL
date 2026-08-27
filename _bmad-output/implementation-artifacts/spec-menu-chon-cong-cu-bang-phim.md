---
title: 'Điều khiển menu chọn công cụ bằng bàn phím'
type: 'feature'
created: '2026-08-27'
status: 'done'
route: 'one-shot'
---

# Điều khiển menu chọn công cụ bằng bàn phím

## Intent

**Problem:** Màn hình chọn công cụ dùng phím số và phím lệnh, chưa giống menu CMD có con trỏ di chuyển giữa các hàng.

**Approach:** Thêm con trỏ hàng có nền tô sáng, dùng mũi tên lên/xuống để di chuyển vòng, Space để check/uncheck và Enter để xác nhận khi còn ít nhất một công cụ được chọn.

## Suggested Review Order

**Tương tác menu**

- Xem trực tiếp hàng được tô sáng và hướng dẫn bàn phím.
  [`installer-wizard-preview.html:11`](../planning-artifacts/ux-designs/ux-AI_AGENT_INSTALL-2026-08-27/.working/installer-wizard-preview.html#L11)

- Kiểm tra con trỏ vòng, Space và Enter trong bộ xử lý phím.
  [`installer-wizard-preview.html:17`](../planning-artifacts/ux-designs/ux-AI_AGENT_INSTALL-2026-08-27/.working/installer-wizard-preview.html#L17)

**Hợp đồng UX**

- Đối chiếu chuỗi thao tác mới trên màn hình thành phần.
  [`EXPERIENCE.md:21`](../planning-artifacts/ux-designs/ux-AI_AGENT_INSTALL-2026-08-27/EXPERIENCE.md#L21)

- Xác nhận quy ước hình ảnh con trỏ và dòng hiện hành.
  [`DESIGN.md:55`](../planning-artifacts/ux-designs/ux-AI_AGENT_INSTALL-2026-08-27/DESIGN.md#L55)
