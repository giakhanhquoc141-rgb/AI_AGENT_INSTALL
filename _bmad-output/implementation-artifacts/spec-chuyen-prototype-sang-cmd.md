---
title: 'Chuyển prototype installer sang giao diện CMD'
type: 'refactor'
created: '2026-08-27'
status: 'done'
route: 'one-shot'
---

# Chuyển prototype installer sang giao diện CMD

## Intent

**Problem:** Prototype trước mô phỏng một wizard desktop có sidebar và nút bấm, không phản ánh tool thực tế chạy thuần CMD.

**Approach:** Thay giao diện bằng cửa sổ Command Prompt mô phỏng toàn bộ luồng chọn công cụ, dependency, quét phiên bản, xác nhận, tiến trình và báo cáo; thao tác chính bằng đúng các phím của batch tool và không thực thi thay đổi hệ thống.

## Suggested Review Order

**Luồng CMD**

- Bắt đầu tại màn hình terminal và chuỗi trạng thái thực tế.
  [`installer-wizard-preview.html:4`](../planning-artifacts/ux-designs/ux-AI_AGENT_INSTALL-2026-08-27/.working/installer-wizard-preview.html#L4)

- Kiểm tra ánh xạ phím và dependency tự chọn.
  [`installer-wizard-preview.html:17`](../planning-artifacts/ux-designs/ux-AI_AGENT_INSTALL-2026-08-27/.working/installer-wizard-preview.html#L17)

**Hợp đồng UX**

- Xác nhận bề mặt sản phẩm là CMD, không phải GUI.
  [`DESIGN.md:29`](../planning-artifacts/ux-designs/ux-AI_AGENT_INSTALL-2026-08-27/DESIGN.md#L29)

- Đối chiếu thứ tự các màn hình và mục đích của chúng.
  [`EXPERIENCE.md:16`](../planning-artifacts/ux-designs/ux-AI_AGENT_INSTALL-2026-08-27/EXPERIENCE.md#L16)

- Đối chiếu bộ phím điều khiển của tool thật.
  [`EXPERIENCE.md:45`](../planning-artifacts/ux-designs/ux-AI_AGENT_INSTALL-2026-08-27/EXPERIENCE.md#L45)
